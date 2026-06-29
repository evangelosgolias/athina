#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_MagDom
#pragma version = 2.0

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

/// @module ATH_MagDom
/// @brief Tools for XMLD magnetic-domain analysis and interactive inspection.
/// @details
/// This module provides routines for fitting angular XMLD image stacks pixel by
/// pixel and for interactively inspecting the fitted phase, offset, and amplitude
/// at selected image positions.
///

/// @function FitXMLDMap
/// @brief Fit an angular XMLD model to every pixel in a 3D image stack.
/// @details
/// For each `(row, column)` beam in the 3D input wave, this routine fits an XMLD
/// angular model along the layer axis and generates three 2D output maps:
/// phase, offset, and amplitude. By default it uses
/// `ATH_FuncFit#XMLDCos2xIntensity`.
/// @param wRef Wave Input 3D wave whose third dimension contains images acquired at different angles.
/// @param fitFunc (optional) String Optional fully qualified fit-function name. Defaults to `ATH_FuncFit#XMLDCos2xIntensity`.
/// @param firstAngle (optional) Variable Optional angle in degrees assigned to the first layer. Defaults to -90.
/// @param angleStep (optional) Variable Optional angular increment in degrees between successive layers. Defaults to 10.
/// @param fastFit (optional) Variable Optional flag controlling the fitting strategy. Non-zero uses one initial phase guess; zero tests multiple initial phases.
/// @returns Variable Returns 0 on completion. Returns 1 if the input has no layers.
/// @note Creates output waves named `<input>_map`, `<input>_map_offset`, and `<input>_map_amplitude`.
///
static Function FitXMLDMap(WAVE wRef, [string fitFunc,
				variable firstAngle, variable angleStep, int fastFit])
	
	/// -------------------------------------------  XMLD Map  --------------------------------------------
	///
	/// Calculates an XMLD-intensity map by fitting **ATH_FuncFit#XMLDIntensity** to every beam
	/// (pixel) along the *z*-axis of a 3-D wave containing XMLD images acquired at different x-ray
	/// inclination angles.
	///
	/// The model assumes that the XMLD signal follows:
	///
	///     I(x) = A + B·cos(2(x + φ)) // default, user can set any function
	///
	/// with *A*, *B*, and *φ* as the fitting parameters.
	///
	/// ### Parameters
	/// | Name           | Type     | Default| Description                                                                                           |
	/// |-------------   |----------|--------|-------------------------------------------------------------------------------------------------------|
	/// | **wRef**       | WAVE     |    -   | 3-D wave whose *z* dimension lists the inclination angles in ascending order (typically −90° to +90°) |
	/// | **fitFunx   ** | string   | Cos(2x)| Fuction to fit, defaults to ATH_FuncFit#XMLDCos2xIntensity, see ATH_FuncFit module for more options   |                                             |	
	/// | **firstAngle** | variable | −90 °  | Inclination (degrees) corresponding to the first plane of the stack                                                |
	/// | **angleStep**  | variable |  10 °  | Angular increment (degrees) between successive *z* planes                                             |
	/// | **fastFit**    | variable |    0   | If non-zero, tests several phase values and keeps the one with the lowest χ² (≈ N × slower)           |
	///
	/// ---
	/// **Advanced curve-fitting tip**  
	/// To weight individual angles, create a sigma wave of length `DimSize(wRef,2)` and pass it to
	/// **FuncFit** via the `/W=<sigmaWave>` flag.
	///
	/// *See also*: *DisplayHelpTopic* “Special Variables for Curve Fitting”.
	///
	/// Note: You have to set the firstAngle correctly if you want to have the spin axis for θ = 0 along the x-axis.
	/// 
	/// Use the FoVRot = θ value (in deg) as set in the metadata to set the -90 or 90 (LV light) light orientation in the lab reference to
	/// -90 + θ, 90 + θ, respectively. In this setting the LH axis will be at θ or 180+θ. The resulting NameOfWave(wRef)+"_map" wave will 
	/// have the axis x corresponsing to φ = 0 for the spin axis.
	///
	/// Update 29.06.2026: Function is now MT, see previous commits for the ST mode.
	fastFit = ParamIsDefault(fastFit) ? 1 : fastFit
	
	variable firstAngleRad = ParamIsDefault(firstAngle) ? -90 * pi/180 : firstAngle * pi/180
	variable angleStepRad = ParamIsDefault(angleStep) ? 10*pi/180 : angleStep * pi/180
	
	// Which model do you like to fit? Check functions in the module ATH_FuncFit
	if(ParamIsDefault(fitFunc))
		fitFunc = "ATH_FuncFit#XMLDCos2xIntensity" // default
	endif
	
	variable rows = DimSize(wRef, 0), cols = DimSize(wRef, 1), layers = DimSize(wRef, 2)
	
	if(!layers)
		return 1
	endif
	
	string mapBaseNameStr = NameofWave(wRef) + "_map"
	string mapNameStr = CreateDataObjectName(dfr, mapBaseNameStr, 1, 0 ,1)

	// Make the fitting waves:  K0 + K1 * Cos(2*(x + K2))
	// Fit can be very sensity to contrains! Read the manual!
	// ********************YOU NEED TO TUNE HERE************************
	//
	// Choose carefully the parameter K1, if it's zero then a lot of errors will occur
	// as K1->0 reduces the functional dependency to a constant function!
	// We will assume of K1 hits the lowest value then K2 == 0!
	//
	Make/FREE/N=(layers) xScale = (firstAngleRad + p * angleStepRad)
	// *****************************************************************
	// Use it only for the wave note
	Make/FREE/T ATH_Constraints = {"K1>1e-3","K2 > -pi/2", "K2 <= pi/2"} // N.B: Set here constrains
	// ThreadSafe Function needs CMatrix, DVector (see CurveFit/FuncFit doc). To get the correct matrix run
	// FuncFit/C ATH_FuncFit#XMLDCos2xIntensity, kwCWave=ATH_Coef, dataW /D /C=ATH_Constraints
	// variable nParam = 3 // How many fitting parameters? Drop and hard code them
	Make/FREE CMatrix = {{0,0,0}, {-1,0,0},{0,-1,1}} 
	Make/FREE DVector = {-1e-03, pi/2, pi/2}
	// End of preparation stage
	
	// Flatted 0 & 1 dims to use MultiThread w = f(p). Make the destination wave and a dummy one to iterate.
	Make/FREE/D/N=(rows*cols, 3) fitCoeff, dummy
	Duplicate/FREE wRef, wRef_flat
	Redimension/E=1/N=(rows*cols, layers) wRef_flat
	MultiThreadingControl setMode=0		
	if(fastFit)
		MultiThread dummy = ATH_MagDom#XMLDFit_Worker(wRef_flat, p, fitFunc, fastfit, xScale, CMatrix, DVector, fitCoeff) // Use dummy to iterate
	else	
		// *****************************************************************
		// How many initial guesses for phase do you want to try?
		// Enter the values in curly brackets.
		// ******************************************************
		Make/FREE guessW = {-pi/4,0,pi/4}; // <<<<<<<
		MultiThread dummy = ATH_MagDom#XMLDFit_Worker(wRef_flat, p, fitFunc, fastfit, xScale, CMatrix, DVector, fitCoeff, guessW=guessW) // Use dummy to iterate
	endif
	
	MultiThreadingControl setMode=1
	// Produce the output waves
	Redimension/E=1/N=(rows, cols, 3) fitCoeff
	MatrixOP $(mapNameStr+"_amplitude") = layer(fitCoeff,0)
	MatrixOP $(mapNameStr+"_offset") = layer(fitCoeff,1)		
	MatrixOP $mapNameStr = layer(fitCoeff,2)*57.29577951 // From rad to deg
	// Add metadata
	string metadata = "FuncFit: "+ fitFunc + "."
	metadata += "Fitting constrains: {"+RemoveEnding(ATH_TWave#TextWaveToString(ATH_Constraints, sep=","))+"}."
	metadata += "Function parameters: firstAngle="+num2str(firstangle)+" ,angleStep="+num2str(angleStep)
	metadata += ", fastFit="+num2str(fastFit)
	Note $mapNameStr, metadata
	Note $(mapNameStr+"_offset"), metadata
	Note $(mapNameStr+"_amplitude"), metadata
	// Restore scaling
	CopyScales wRef, $mapNameStr, $(mapNameStr+"_offset"), $(mapNameStr+"_amplitude")
	return 0
End

ThreadSafe static Function XMLDFit_Worker(WAVE wRef, variable j, string fitFunc, variable fastfit,
						   WAVE xScale,WAVE CMatrix, WAVE DVector, WAVE fitCoeff, [WAVE/Z guessW])
	// Get the data in a row
	MatrixOP/FREE getdata = row(wRef, j)^t
	WaveStats/M=1/Q getdata
	if(fastfit)
		Make/D/FREE ATH_Coef = {V_avg, 0.5*(V_max-V_min),0.1} // N.B!! You might need to play a bit with the initial guess
		FuncFit/Q $fitFunc, kwCWave=ATH_Coef, getdata /D /C={CMatrix, DVector} /X=xScale
		fitCoeff[j][] = ATH_Coef[q]
	else
		variable imax = numpnts(guessW), i = 0
		Make/FREE/D/N=(imax, 3) ATH_Coef_list
		Make/FREE/N=3 chisqW
		for(i = 0; i < imax; i+=1)
			Make/O/D/FREE ATH_Coef = {V_avg, 0.5*(V_max-V_min),guessW[i]}
			FuncFit/Q $fitFunc, kwCWave=ATH_Coef, getdata /D /C={CMatrix, DVector} /X=xScale
			ATH_Coef_list[i][] = ATH_Coef[q]
			chisqW[i] = V_chisq
		endfor
		variable imim = chisqW[0]
		for(i=1;i<3;i+=1) // 3 is hardcoded here
			if(chisqW[i] < imim)
			imim = wRef[i]
			endif
		endfor
		fitCoeff[j][] = ATH_Coef_list[imim][q]
	endif
	return 0		// Return a reference to the free M_RegOut wave
End


/// Helping functions moved from ATH_Cursors
/// Beam fitting map
/// Generic interaction using a cursor and a CallbackFunction

/// @function InteractiveXMLDFitInspection
/// @brief Launch interactive inspection of an XMLD fit map.
/// @details
/// Displays the fitted map and opens a companion plot window. Moving cursor `J`
/// over the image updates the beam profile and overlayed fit curve for the selected pixel.
/// @param wSrc Wave Source 3D XMLD image stack used to extract beam profiles.
/// @param wRef Wave 2D phase map produced by `FitXMLDMap`.
/// @param firstAngle (optional) Variable Optional first angle in degrees for the source stack. Defaults to -90.
/// @param angleStep (optional) Variable Optional angle increment in degrees. Defaults to 10.
/// @returns Variable Returns 0 on completion.
///
static Function InteractiveXMLDFitInspection(WAVE wSrc, WAVE wRef,[variable firstAngle, variable angleStep])
	/// Interactive operation using a callback function
	/// ATH_Cursors#CursorCallBack(WAVE wSrc, WAVE wRef, variable p0, variable q0)
	//
	// WAVE wSrc - 3D Wave with XMLD images for different angles
	// WAVE wRef - Wave calculated using CalculateXMLDMap
	//
	variable firstAngleRad = ParamIsDefault(firstAngle) ? -90 * pi/180 : firstAngle * pi/180
	variable angleStepRad = ParamIsDefault(angleStep) ? 10*pi/180 : angleStep * pi/180
		
	string winNameStr = ATH_Display#NewImg(wRef)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	variable nrows = DimSize(wRef, 0)
	variable ncols = DimSize(wRef, 1)	
	Cursor/I/C=(65535,65535,0)/S=1/P/N=1 J $imgNameTopGraphStr nrows/2, ncols/2
	// Make folder in database
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr) // Root folder here
	// Store globals
	string/G dfr:gATH_wRefPath = GetWavesDataFolder(wRef, 2)
	string/G dfr:gATH_wSrcPath = GetWavesDataFolder(wSrc, 2)
	variable/G dfr:gATH_firstAngleRad = firstAngleRad
	variable/G dfr:gATH_angleStepRad = angleStepRad
	// Hook and metadata
	SetWindow $winNameStr, hook(MyiCursorActionHook) = ATH_MagDom#iCursorUsingCallbackHookFunction // Set the hook
	SetWindow $winNameStr, userdata(MyiCursorWin) = winNameStr
	SetWindow $winNameStr, userdata(ATH_iCursorDFR) = "root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr
	Display/N=$(winNameStr + "_iFitPlot")/K=1
	DoWindow/F $winNameStr
	SetWindow $winNameStr, userdata(MyiplotWin) = winNameStr + "_iFitPlot"
	return 0
End

/// @function iCursorUsingCallbackHookFunction
/// @brief Window hook for interactive XMLD fit inspection.
/// @details
/// Handles window close, cursor movement, and keyboard events for the interactive
/// XMLD inspection workflow.
/// @param s Struct Igor window hook structure supplied by the event system.
/// @returns Variable Hook return code. Returns 1 when the event is handled, otherwise 0.
///
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
			//hookResult = 1
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

/// @function CursorCallBack
/// @brief Update the fit-inspection plot for the selected pixel.
/// @details
/// Extracts the beam profile at `(p0, q0)`, reconstructs the fitted angular dependence
/// from the stored fit maps, and redraws the inspection plot.
/// @param wSrc Wave Source 3D XMLD image stack.
/// @param wRef Wave Phase map returned by `FitXMLDMap`.
/// @param p0 Variable Row index of the selected pixel.
/// @param q0 Variable Column index of the selected pixel.
/// @returns Variable Returns 0 on completion.
///
static Function CursorCallBack(WAVE wSrc, WAVE wRef, variable p0, variable q0)
	
	DFREF dfr = $GetUserData("", "", "ATH_iCursorDFR")
	DFREF wdfr = GetWavesDataFolderDFR(wRef)
	string winNameStr = GetUserData("", "", "MyiCursorWin")
	string plotNameStr = GetUserData("", "", "MyiplotWin")
	NVAR/SDFR=dfr gATH_firstAngleRad, gATH_angleStepRad
	
	MatrixOP/O dfr:cursorBeamProfile = beam(wSrc, p0, q0)
	WAVE wOff = wdfr:$(NameOfWave(wRef)+"_offset")
	WAVE wA = wdfr:$(NameOfWave(wRef)+"_amplitude")
	Make/O dfr:fitPlotW /WAVE=wcos // 128 points, that's why SetScal/I
	variable lastAngleRad = gATH_firstAngleRad + gATH_angleStepRad * (numpnts(dfr:cursorBeamProfile)-1)
	SetScale/I x, gATH_firstAngleRad, lastAngleRad, wcos, dfr:cursorBeamProfile
	variable x0 = wOff[p0][q0]
	variable A = wA[p0][q0]
	variable phase = wRef[p0][q0] // in degrees!
	// N.B: Change here if you change the fitting function
	wcos = x0 + A * cos(2*(x + phase*0.01745329)) // Phase to rad
	RemoveFromGraph/W=$plotNameStr/ALL
	AppendToGraph/W=$plotNameStr dfr:cursorBeamProfile
	ModifyGraph/W=$plotNameStr mode(cursorBeamProfile)=3,marker(cursorBeamProfile)=19,msize(cursorBeamProfile)=4
	AppendToGraph/W=$plotNameStr wcos 
	ModifyGraph/W=$plotNameStr lsize(fitPlotW)=2,rgb(fitPlotW)=(1,16019,65535)
	TextBox/W=$plotNameStr/C/F=0/N=phaseTag "\\Z16φ="+num2str(phase)		
	return 0
End

/// @function SortMapPerPolarAngle
/// @brief Reorder an angular map by increasing polar angle.
/// @param wRef Angular map whose rows are reordered in place.
/// @param angleRange (optional) Angular interval represented by the map.
/// @returns Zero after completing the operation.
static Function SortMapPerPolarAngle(WAVE wRef, [variable angleRange])
	// Sort spin axis angles to create a polar plot
	// angle will come from spin axis and will be set in the x-wave scaling
	// 90, 180 or 360. The radius will be another wave you select, for example 
	// amplitutde or XMLD singnal (default). The latter should come from another wave.
	angleRange = ParamIsDefault(angleRange) ? 180 : angleRange
	
	// You need to wrap a histogram around, if its
	
	// Check /P option of Histogram
End