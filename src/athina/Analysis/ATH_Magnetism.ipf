#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_Magnetism
#pragma version = 1.1
// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: evangelos.golias@gmail.com
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

static Function/WAVE XMCD(WAVE w1, WAVE w2, [string outWave, WAVE wRef])
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

static Function XMCD3D(WAVE w3d1, WAVE w3d2)
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
	string saveWaveName = CreatedataObjectName(currDFR, "XMCD3d", 1, 0, 1)
	MatrixOP $saveWaveName = (w3d1 - w3d2)/(w3d1 + w3d2)
	string noteStr = "XMC(L)D = (w1 - w2)/(w1 + w2)\nw1: " + NameOfWave(w3d1) + "\nw2: " + NameOfWave(w3d2)
	CopyScales w3d1, $saveWaveName
	Note $saveWaveName, noteStr
	return 0
End

static Function XMCDComb(WAVE w3d)
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
			XMCD(iLayer, jLayer, outWave = buffer)
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
	XMCD(w0, w1, wRef=xmcd0)
	XMCD(w2, w3, wRef=xmcd1)
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

/// -------------------------------------- XMLD Map --------------------------------------------//

//@
//	Function to calculate an XMLD map. The function ATH_FuncFit#XMLDIntensity is fitted to 
//  all beams of a 3D wave containing data from XMLD images obtained with different inclination
//  angles (direction of the E-field of x-rays). Model assumets that XMLD singal follows the 
//  relationship I = A + B * cos(2*x + φ)^2, where A, B and φ are the fitting parameters.
//
//	## Parameters
//	wRef : WAVE
//		A 3D wave that contains the data of all inclination angles in ascending order.
//		The codes assumes that all angles from -90 to 90 are included. Note that -90 and 90
//		refer to the same angle.
//
//		!!! Here the angle 90 should be the last layer of the stack. For example if you have
//			taken the full map (-80, 90) with angular step of 10° then your first stack is for
//		-80 degrees angle and the last at 90 (18 layers in total)
//
//		lowAngleDeg : variable
// 		Lowest angle for XMLD map in **degrees** (expected -90 or -80 deg)
//
//	angleStep : variable
// 		Angular step along the z-direction in **degrees**.
//
//	## Returns
//	variable
//		A unique 2D wave NameOfWave(wRef) + "_XMLDMap" is created (+num2str(N)))
//		0 - map calculations completed
//		1 - input wave was not a 3D wave
//@

// The main challenge here is the initial conditions as we have a non-linear fit.
// Function CalculateXMLDMap tries different initial conditions for the phase shift
// and picks up the solution for the minimum of the cost function. Of course this increases
// the time needed to complete the operation by N, where N is the number of phase tries.
//
//
// NOTE: The program is not yet fully tested and optimised. 
//

static Function CalculateXMLDMap(WAVE wRef, variable lowAngleDeg, variable angleStepDeg)
	
	// In FuncFit if you want to use Trust-region Levenberg-Marquardt ordinary least-squares method
	// Do the folowing
	// variable V_FitError
	// V_FitError = 0 // Set it to zero before the fit
	// FuncFit/Q/ODR=1 ...
	// if(V_FitError)
	//     // deal with the error
	//     continue
	// endif
	//	
	// For more info:
	//
	// DisplayHelpTopic "Special Variables for Curve Fitting"
	//
	//
	//
	// -------------------------------------------------------------------------------------
	// Bit 1: Robust Fitting
	// You can get a form of robust fitting where the sum of the absolute deviations is 
	// minimized rather than the squares of the deviations, which tends to de-emphasize 
	// outlier values. To do this, create V_FitOptions and set bit 1 (variable V_fitOptions=2).
	// Warning 1: No attempt to adjust the results returned for the estimated errors or 
	// for the correlation matrix has been made. You are on your own.
	// Warning 2: Don't set this bit and then forget about it.
	// Warning 3: Setting Bit 1 has no effect on line, poly or poly2D fits.
	// -------------------------------------------------------------------------------------
	//
	// So after the fir set V_fitOptions=0
	//
	//
	variable angleStepRad = angleStepDeg * pi/180
	variable lowAngleRad = lowAngleDeg * pi/180
	variable rows = DimSize(wRef, 0)
	variable cols = DimSize(wRef, 1)
	variable layers = DimSize(wRef, 2)
	if(!layers)
		return 1
	endif
	variable i, j, cnt
	string mapBaseNameStr = NameofWave(wRef) + "_XMLDMap"
	string mapNameStr = CreateDataObjectName(dfr, mapBaseNameStr, 1, 0 ,1)
	Make/N=(rows, cols) $mapNameStr, $(mapNameStr+"_Off"), $(mapNameStr+"_y0")
	WAVE wphase = $mapNameStr
	WAVE woff = $(mapNameStr+"_Off")
	WAVE wfact = $(mapNameStr+"_y0")
	// Get the fitting stuff ready
	// K0 + K1 * sin(x + K2)^2
	Make/FREE/D/N=3 ATH_Coef
	Make/FREE/T/N=2 ATH_Constraints = {"K2 > -1.55334", "K2 <= 1.5708"}
	Make/FREE/N=(layers) freeData
	SetScale/P x, lowAngleRad , angleStepRad, freeData // Careful here
	Make/O/D/N=(rows, cols, 3) ATH_FitCoeff
	for(i = 0; i < rows; i++)
		for(j = 0; j < cols; j++)
			// /S keeps scaling.
			MatrixOP/O/S freeData = beam(wRef, i, j) // N.B. If you add /FREE here the scaling will be lost!!!
			WaveStats/M=1/Q freeData // Makes it slower, but initial guess is better. Is it helpful?
			// Initialise, with something reasonable
			// Note sin(x+pw[2])^2, that why -V_maxloc/pi
			ATH_Coef = {V_avg, V_max-V_min, -V_maxloc/pi} 
			FuncFit/Q ATH_Magnetism#XMLDIntensity, ATH_Coef, freeData /D /C=ATH_Constraints	
			ATH_FitCoeff[i][j][] = ATH_Coef[r] // Fill in ATH_FitCoeff			
		endfor
	endfor
	for(i = 0; i < rows; i++)
		for(j = 0; j < cols; j++)
			woff[i][j] =  ATH_FitCoeff[i][j][0]
			wfact[i][j] = ATH_FitCoeff[i][j][1]
			wphase[i][j] = ATH_FitCoeff[i][j][2]*180/pi
		endfor
	endfor
	KillWaves/Z W_sigma, ATH_FitCoeff, fit__free_ // Cleanup the garbage
End

/// Helping functions moved from ATH_Cursors
/// Beam fitting map
/// Generic interaction using a cursor and a CallbackFunction

static Function InteractiveXMLDFitInspection(WAVE wSrc, WAVE wRef)
	/// Interactive operation using a callback function
	/// ATH_Cursors#CursorCallBack(WAVE wSrc, WAVE wRef, variable p0, variable q0)
	//
	// WAVE wSrc - 3D Wave with XMLD images for different angles
	//
	ATH_Display#NewImg(wRef)
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	// Use cursor C
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
			hookresult = 1
			break
		case 11: // Keyboard event
			if(s.keycode == 27) //  Esc
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
	MatrixOP/O dfr:cursorBeamProfile = beam(wSrc, p0, q0)
	WAVE wOff = wdfr:$(NameOfWave(wRef)+"_Off")
	WAVE wy0 = wdfr:$(NameOfWave(wRef)+"_y0")
	Make/O dfr:fitPlotW /WAVE=wsin
	SetScale/I x, -pi/2, pi/2, wsin, dfr:cursorBeamProfile // EDIT HERE
	variable xOff = wOff[p0][q0]
	variable xy0 = wy0[p0][q0]
	variable phase = wRef[p0][q0]*pi/180 // sin() needs rad
	wsin = xOff + xy0 * sin(x + phase)^2
	RemoveFromGraph/W=$plotNameStr/ALL
	AppendToGraph/W=$plotNameStr dfr:cursorBeamProfile
	ModifyGraph/W=$plotNameStr mode(cursorBeamProfile)=3,marker(cursorBeamProfile)=19,msize(cursorBeamProfile)=4
	AppendToGraph/W=$plotNameStr wsin 
	ModifyGraph/W=$plotNameStr lsize(fitPlotW)=2,rgb(fitPlotW)=(1,16019,65535)
	return 0
End

static Function XMLDIntensity(WAVE pw, WAVE yw, WAVE xw) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ I(E) =pw[0] + pw[1] * sin(x + yw[2])
	//CurveFitDialog/ 	
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ E	
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = baseline
	//CurveFitDialog/ w[1] = Amplitute
	//CurveFitDialog/ w[2] = phase
	yw = pw[0] + pw[1] * sin(xw + pw[2])^2
End