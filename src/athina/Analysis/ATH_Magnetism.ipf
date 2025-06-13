#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_Magnetism
#pragma version = 1.2
// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: egolias@protonmail.com
//	
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//	
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
// ------------------------------------------------------- //

static Function/WAVE CalculateXMCD(WAVE w1, WAVE w2, [string outWave, WAVE wRef])
	/// Calculate XMCD/XMLD of two images and save it to 
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	/// NB: You have to provife either outWave or wRef
	
	// Calculation of XMC(L)D using SP waves
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02))
		Redimension/S w1, w2
	endif
	
	if(!(ParamIsDefault(outWave) %^ ParamIsDefault(wRef)))
		return $""
	endif
	
	if(!ParamIsDefault(outWave))
		Duplicate/O w1, $outWave
		WAVE w = $outWave
		w = (w1 - w2)/(w1 + w2)
		return w
	else
		Duplicate/O w1, wRef
		wRef = (w1 - w2)/(w1 + w2)
		return wRef
	endif
End


static Function StackToXMCD(WAVE w3d, [string wnameStr])
	/// Calculate XMCD/XMLD of two images
	/// @param w3d WAVE Wave with 2 layers.	
	if(DimSize(w3d, 2) != 2)
		return 1
	endif	
	if(WaveType(w3d) & 0x10) // if int16
		Redimension/S w3d
	endif
	MatrixOP/FREE w1 = layer(w3d,0)
	MatrixOP/FREE w2 = layer(w3d,1)	
	if(ParamIsDefault(wnameStr))
		MatrixOP/O wXMCD = (w1-w2)/(w1+w2)
	else
		MatrixOP/O $wnameStr = (w1-w2)/(w1+w2)
	endif
	return 0
End

static Function StackToWaveSum(WAVE w3d, WAVE wSum)
	
	if(DimSize(w3d, 2) != 2)
		return -1
	endif	
	if(!(WaveType(w3d) & 0x02 && WaveType(wSum) & 0x02))
		Redimension/S w3d, wSum
	endif

	MatrixOP/O wSum = (layer(w3d,0) + layer(w3d,1))/2
End

static Function CalculateXMCD3D(WAVE w3d1, WAVE w3d2)
	// Calculate XMC(L)D for 3D waves over layers.
	// XMC(L)D = (w3d1 - w3d2)/(w3d1 + w3d2)
	if(WaveDims(w3d1) != 3 || WaveDims(w3d2) != 3 || (DimSize(w3d1, 2) != DimSize(w3d2, 2)))
		return -1
	endif
	if((DimSize(w3d1, 0) != DimSize(w3d2, 0)) || (DimSize(w3d1, 1) != DimSize(w3d2, 1)) )
		return -1
	endif
	if(WaveType(w3d1) & 0x10) // If WORD (int16)
		Redimension/S w3d1
	endif

	if(WaveType(w3d2) & 0x10) // If WORD (int16)
		Redimension/S w3d2
	endif
	DFREF currDFR = GetDataFolderDFR()
	string saveWaveName = CreatedataObjectName(currDFR, "XMCD_3d", 1, 0, 1)
	MatrixOP $saveWaveName = (w3d1 - w3d2)/(w3d1 + w3d2)
	string noteStr = "XMC(L)D = (w1 - w2)/(w1 + w2)\nw1: " + GetWavesDataFolder(w3d1,2) + "\nw2: " + GetWavesDataFolder(w3d2,2)
	CopyScales w3d1, $saveWaveName
	Note $saveWaveName, noteStr
	return 0
End

static Function CalculateXMCDComb(WAVE w3d)
	/// Calculate XMC(L)D = (w3d1 - w3d2)/(w3d1 + w3d2)
	/// for all different layer combinations of w3d,
	if(WaveDims(w3d) != 3)
		return -1
	endif
	variable nlayers = DimSize(w3d, 2), i, j, cnt = 0
	variable nL = nlayers*(nlayers-1)/2 // all combinations
	string buffer = "" 
	string noteStr = "Source: " + GetWavesDataFolder(w3d, 2) + "\n"
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	for(i = 0; i < nlayers; i++)
		MatrixOP/FREE iLayer = layer(w3d, i)
		for(j = 0; j < i; j++)
			MatrixOP/FREE jLayer = layer(w3d, j)
			buffer = "ATHWaveToStack_idx_" + num2str(cnt)
			CalculateXMCD(iLayer, jLayer, outWave = buffer)
			noteStr += num2str(cnt) + ": (" + num2str(IndexToScale(w3d, i, 2)) \
					+", "+ num2str(IndexToScale(w3d, j, 2))+")\n"
			cnt += 1
		endfor	
	endfor
	ImageTransform/NP=(nL) stackImages $"ATHWaveToStack_idx_0"
	WAVE M_Stack
	CopyScales w3d, M_Stack
	Note M_stack, noteStr
	string saveStackNameStr = CreatedataObjectName(saveDF, "XMCD_Comb", 1, 0, 1)
	MoveWave M_stack, saveDF:$saveStackNameStr
	SetDataFolder saveDF
	return 0
End

static Function XMCDStack4L(WAVE wRef, [string order, int overwrite, string outWave])
	// wRef comprises four layers.
	// Calculate xmcd between stack l0, l1 and l2, l3
	// then subtract the two xmcd images.
	// if order is specified then l1 = order[0], ... l4 = order[3]
	overwrite = ParamIsDefault(overwrite) ? 0 : overwrite
	order = SelectString(ParamIsDefault(order)? 0 : 1, "0123", order)
	if(ParamIsDefault(outWave))
		DFREF dfr = GetDataFolderDFR()
		outWave = CreateDataObjectName(dfr, NameOfWave(wRef) + "_xmcd", 1, 0, 1)
	endif
	string regex = "^(?=[0-3]{4}$)(?!.*(.).*\1).*$" // Matches 0123, 2134, ... all combinations
	if(!GrepString(order, regex))
		print order + " is not a permutation of 0123"
		return -1
	endif
	variable l0 = str2num(order[0])
	variable l1 = str2num(order[1])
	variable l2 = str2num(order[2])
	variable l3 = str2num(order[3])
	string noteStr = "Source: " + GetWavesDataFolder(wRef, 2) + ".\n"
	noteStr += "Layers:" + note(wRef) + "\n"
	noteStr += "XMCD calculation (w1-w2)/(w1+w2) between layers "+order[0]+","+order[1]+" (xmcd0) and " + order[2]+","+order[3]+" (xmcd0). "
	noteStr += "Then the two xmcd images are subtracted xmcd0 - xmcd1"
	MatrixOP/FREE w0 = layer(wRef, l0)
	MatrixOP/FREE w1 = layer(wRef, l1)
	MatrixOP/FREE w2 = layer(wRef, l2)
	MatrixOP/FREE w3 = layer(wRef, l3)
	Duplicate/FREE w0, xmcd0, xmcd1, wDest
	CalculateXMCD(w0, w1, wRef=xmcd0)
	CalculateXMCD(w2, w3, wRef=xmcd1)
	variable errCode, flag
	if(overwrite)
		Duplicate/O w0, $outWave; errCode = GetRTError(1);
	else
		Duplicate w0, $outWave; errCode = GetRTError(1);
	endif
	flag = V_flag
	if(errCode)
		print GetErrMessage(errCode)
		return -1
	endif
	WAVE wOut = $outWave
	wOut = xmcd0 - xmcd1
	Note wOut, noteStr
	return 0
End

static Function CalculateXMLDMap(WAVE wRef, [variable firstAngle, variable angleStep, variable FoVRot])

	/// -------------------------------------- XMLD Map --------------------------------------------//
	
	//@
	//	Function to calculate an XMLD map. The function ATH_FuncFit#XMLDIntensity is fitted to 
	//  all beams of a 3D wave containing data from XMLD images obtained with different inclination
	//  angles (direction of the E-field of x-rays). Model assumets that XMLD singal follows the 
	//  relationship I = A + B * sin(x + φ)^2, where A, B and φ are the fitting parameters.
	//
	//	## Parameters
	//	wRef : WAVE
	//		A 3D wave that contains the data of all inclination angles in ascending order.
	//      A full XMLD map contains angles in [-90, 90] range.
	//
	//		firstAngle : optional variable (default -90 deg)
	//
	//	angleStep : optional variable in deg
	// 		Angular step along the z-direction in **degrees**, default 10 deg
	//
	// FoVRot: optional variable in deg
	//      Anglular offset for the fit. Why? Because LH light usually does not coincide with x-axis!
	//
	// About FoVRot:
	//
	// In PEEM the magnetic objective rotates the image wrt to lab reference frame. The x-ray beam polarization
	// refers to the lab frame, LH is paralled to the floor (x-axis of the lab frame) and LV is perpendicular to
	// the floor (y-axis of the lab frame). The preset of the microscope (written in metadata) gives an angle for
	// the rotation you have to do in order to align the image with the lab reference. Prior to this rotation, the 
	// y-axis should be flipped (mirror reflextion over the x-axis) in order the image to correspond to the x-ray 
	// beam view of the sample. Therefore *FoVRot* has to be set so that the program can calculate the starting angle
	// correctly. *FoVRot* contained in the metadata!
	// Here the first angle is set so that the LH light has theta = 0, i.e parallel to x-axis. 
	//
	//
	//	## Returns
	//	variable
	//		A unique 2D wave NameOfWave(wRef) + "_XMLDMap" is created (+num2str(N)))
	//		0 - map calculations completed
	//		1 - input wave was not a 3D wave
	//--------------------------------------------------------------------------------------------------------------
	//
	// Advanced curve fitting
	//
	// DisplayHelpTopic "Special Variables for Curve Fitting"
	
	variable firstAngleRad = ParamIsDefault(firstAngle) ? -90 * pi/180 : firstAngle * pi/180
	variable angleStepRad = ParamIsDefault(angleStep) ? 10*pi/180 : angleStep * pi/180
	variable FoVRotRad = ParamIsDefault(FoVRot) ? 0 : FoVRot * pi/180
	// Calculate the angular offset, rotate by -FoVRotRad and apply mirror operation over x-axis
	
	variable rows = DimSize(wRef, 0)
	variable cols = DimSize(wRef, 1)
	variable layers = DimSize(wRef, 2)

	if(!layers)
		return 1
	endif
	variable i, j, cnt
	string mapBaseNameStr = NameofWave(wRef) + "_map"
	string mapNameStr = CreateDataObjectName(dfr, mapBaseNameStr, 1, 0 ,1)
	Make/N=(rows, cols) $mapNameStr, $(mapNameStr+"_offset"), $(mapNameStr+"_amplitude")
	WAVE wphase = $mapNameStr
	WAVE woff = $(mapNameStr+"_offset")
	WAVE wfact = $(mapNameStr+"_amplitude")
	// Make the fitting waves:  K0 + K1 * sin(x + K2)^2
	Make/FREE/D/N=3 ATH_Coef
	// Fit can be very sensity to contrains! Read the manual!
	// ********************YOU NEED TO TUNE HERE************************
	//
	// Choose carefully the parameter K1, if it's zero then a lot of errors will occur
	// as K1->0 reduces the functional dependency to a constant function!
	// We will assume of K1 hits the lowest value then K2 == 0!
	//
	Make/FREE/T ATH_Constraints = {"K1>1e-3","K2 > -1.5708", "K2 <= 1.5708"} 
	// *****************************************************************
	Make/FREE/N=(layers) freeData
	SetScale/P x, (firstAngleRad+FoVRotRad) , angleStepRad, freeData // Set the scale!
	Make/O/D/N=(rows, cols, 3) ATH_FitCoeff // Fit coefficients per pixel
	variable V_FitError
	variable errorCnt = 0
	variable V_FitOptions = 0
	for(i = 0; i < rows; i++)
		for(j = 0; j < cols; j++)
			// /S keeps scaling in MatrixOP
			// N.B. If you add /FREE here the scaling will be lost!!!
			MatrixOP/O/S freeData = beam(wRef, i, j)
			WaveStats/M=1/Q freeData // Makes it slower, but initial guess is better. Is it helpful?
			V_FitError = 0 // Set it to zero before the fit
			ATH_Coef = {V_avg, 0.5*(V_max-V_min),0.1} // N.B!! You might need to play a bit with the initial guess
			FuncFit/Q ATH_FuncFit#XMLDSinSqIntensity, kwCWave=ATH_Coef, freeData /D /C=ATH_Constraints
			if(V_FitError)
				// Deal with error here....
				errorCnt++
			endif			
			ATH_FitCoeff[i][j][] = ATH_Coef[r]
		endfor
	endfor
	// Write the coefficients to waves
	woff[][] =  ATH_FitCoeff[p][q][0]
	wfact[][] = ATH_FitCoeff[p][q][1]
	wphase[][] = ATH_FitCoeff[p][q][2]*57.29577951 // From rad to deg
	print "Total fit errors ", errorCnt
	string metadata = "Fitting variables: firstAngle="+num2str(firstangle)+" ,angleStep="+num2str(angleStep)
	metadata += ", FoVRot="+num2str(FoVRot)+"\n"+"Total fit errors: "+num2str(errorCnt)+"\n"
	metadata += "Fitting constrains: {"+RemoveEnding(ATH_TWave#TextWaveToString(ATH_Constraints, sep=","))+"}\n"
	Note wphase, metadata
	Note wfact, metadata
	Note woff, metadata
	KillWaves/Z W_sigma, ATH_FitCoeff, fit__free_ // Cleanup the garbage
End

/// Helping functions moved from ATH_Cursors
/// Beam fitting map
/// Generic interaction using a cursor and a CallbackFunction

static Function InteractiveXMLDFitInspection(WAVE wSrc, WAVE wRef, [variable FoVRot])
	/// Interactive operation using a callback function
	/// ATH_Cursors#CursorCallBack(WAVE wSrc, WAVE wRef, variable p0, variable q0)
	//
	// WAVE wSrc - 3D Wave with XMLD images for different angles
	// WAVE wRef - Wave calculated using CalculateXMLDMap
	//
	string winNameStr = ATH_Display#NewImg(wRef)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	variable nrows = DimSize(wRef, 0)
	variable ncols = DimSize(wRef, 1)	
	Cursor/I/C=(65535,0,0)/S=1/P/N=1 J $imgNameTopGraphStr nrows/2, ncols/2
	// Make folder in database
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr) // Root folder here
	// Store globals
	string/G dfr:gATH_wRefPath = GetWavesDataFolder(wRef, 2)
	string/G dfr:gATH_wSrcPath = GetWavesDataFolder(wSrc, 2)
	// Hook and metadata
	SetWindow $winNameStr, hook(MyiCursorActionHook) = ATH_Magnetism#iCursorUsingCallbackHookFunction // Set the hook
	SetWindow $winNameStr, userdata(MyiCursorWin) = winNameStr
	SetWindow $winNameStr, userdata(FoVRotRad) = num2str(FoVRot*0.01745329)
	SetWindow $winNameStr, userdata(ATH_iCursorDFR) = "root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr
	Display/N=$(winNameStr + "_iFitPlot")/K=1
	DoWindow/F $winNameStr
	SetWindow $winNameStr, userdata(MyiplotWin) = winNameStr + "_iFitPlot"
	return 0
End

static Function iCursorUsingCallbackHookFunction(STRUCT WMWinHookStruct &s)
	variable hookResult = 0
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr)
	string plotNameStr = GetUserData(s.winName, "", "MyiplotWin")
	SVAR/SDFR=dfr gATH_wRefPath, gATH_wSrcPath
	WAVE/Z wRef = $gATH_wRefPath
	WAVE/Z wSrc = $gATH_wSrcPath
	switch(s.eventCode)
		case 2:
			KillWindow/Z $plotNameStr
			KillDataFolder/Z dfr
			break
		case 7: // cursor moved
			if(!cmpstr(s.cursorName, "J")) // It should work only with E, F you might have other cursors on the image
				CursorCallBack(wSrc, wRef, s.pointNumber, s.ypointNumber) // Function using row, column
				//CursorCallBack3(wRef, s.pointNumber, s.ypointNumber) // Function using row, column
			endif
			hookResult = 1
			break
		case 11: // Keyboard event
			if(s.specialKeyCode == 204) //  Esc
				SetWindow $s.winName, hook(MyiCursorActionHook) = $""
				Cursor/K/W=$s.winName B
				KillDataFolder/Z dfr
			endif
	endswitch
	return hookResult       // 0 if nothing done, else 1
End

static Function CursorCallBack(WAVE wSrc, WAVE wRef, variable p0, variable q0)
	
	DFREF dfr = $GetUserData("", "", "ATH_iCursorDFR")
	DFREF wdfr = GetWavesDataFolderDFR(wRef)
	string winNameStr = GetUserData("", "", "MyiCursorWin")
	string plotNameStr = GetUserData("", "", "MyiplotWin")
	variable FoVRotRad = str2num(GetUserData("", "", "FoVRotRad"))

	MatrixOP/O dfr:cursorBeamProfile = beam(wSrc, p0, q0)
	WAVE wOff = wdfr:$(NameOfWave(wRef)+"_offset")
	WAVE wA = wdfr:$(NameOfWave(wRef)+"_amplitude")
	Make/O dfr:fitPlotW /WAVE=wsin
	SetScale/I x, -pi/2+FoVRotRad, pi/2+FoVRotRad, wsin, dfr:cursorBeamProfile
	variable x0 = wOff[p0][q0]
	variable A = wA[p0][q0]
	variable phase = wRef[p0][q0]*0.01745329 // Phase to rad
	wsin = x0 + A * sin(x + phase)^2
	RemoveFromGraph/W=$plotNameStr/ALL
	AppendToGraph/W=$plotNameStr dfr:cursorBeamProfile
	ModifyGraph/W=$plotNameStr mode(cursorBeamProfile)=3,marker(cursorBeamProfile)=19,msize(cursorBeamProfile)=4
	AppendToGraph/W=$plotNameStr wsin 
	ModifyGraph/W=$plotNameStr lsize(fitPlotW)=2,rgb(fitPlotW)=(1,16019,65535)
	return 0
End
