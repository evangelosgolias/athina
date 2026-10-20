#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Launch
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

/// @module ATH_Launch
/// @brief Module ATH_Launch.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH Launch functionality.

// --- Add quick actions to Data Browser ----

/// @function BrowserActionDoXMDC
/// @brief Calculate XMCD from the two waves selected in the Data Browser.
/// @returns NaN if input validation fails; otherwise zero after completing the operation.
Function BrowserActionNewImg()
	string img = GetBrowserSelection(0)
	if(!strlen(img))
		return NaN
	endif
	WAVE wRef = $GetBrowserSelection(0)
	if(WAVEExists(wRef)) // works only with two selected waves
		ATH_Display#NewImg(wRef)
	endif
End

/// @function BrowserActionDoXMDC
/// @brief Calculate XMCD from the two waves selected in the Data Browser.
/// @returns NaN if input validation fails; otherwise zero after completing the operation.
Function BrowserActionDoXMDC()
	string img1, img2
	img1 = GetBrowserSelection(0)
	img2 = GetBrowserSelection(1)
	if(!strlen(img1) || !strlen(img2))
		return NaN
	endif
	if(!WaveExists($img1) || !WaveExists($img2))
		return NaN
	endif
	WAVE w1 = $GetBrowserSelection(0)
	WAVE w2 = $GetBrowserSelection(1)
	if(!strlen(GetBrowserSelection(2))) // works only with two selected waves
		ATH_XMCD#CalculateXMCD(w1, w2)
	endif
End

/// @function BrowserActionMakeStack
/// @brief Create a stack from the waves selected in the Data Browser.
/// @returns Zero after completing the operation.
Function BrowserActionMakeStack()
	string wNameStr
	Prompt wNameStr, "Name your stack"
	DoPrompt "Stacking waves ...", wNameStr
	wNameStr = ATH_WaveOp#ConcatenateWavesInDataBrowserSelection(wNameStr) // stack in sourcedir if all waves in the same folder, otherwise in cwd
	return 0
End

// --- End of quick actions -----

/// @function Make3DWaveUsingPattern
/// @brief Create a 3D wave by stacking waves whose names match a pattern.
/// @returns Zero after completing the operation.
static Function Make3DWaveUsingPattern()
	string wname3dStr, pattern
	[wname3dStr, pattern] = ATH_Dialog#GenericDoubleStrPrompt("Stack name","Match waves (use * wildcard)", "Make a stack from waves using a pattern")
	
	ATH_WaveOp#Make3DWaveUsingPattern(wname3dStr, pattern)
End

/// @function Make3DWaveDataBrowserSelection
/// @brief Create a 3D wave from the waves selected in the Data Browser.
/// @param displayStack (optional) If nonzero, display the newly assembled stack.
/// @param transientStack (optional) If nonzero, mark the stack as temporary in the graph metadata.
/// @returns Zero when a stack is created and displayed; one when no displayable stack is available.
static Function Make3DWaveDataBrowserSelection([int displayStack, int transientStack])
	displayStack = ParamIsDefault(displayStack) ? 0: displayStack // Give any non-zero to display the stack
	transientStack = ParamIsDefault(transientStack) ? 0: transientStack 
	if(transientStack)
		string wname3dStr = ATH_WaveOp#ConcatenateWavesInDataBrowserSelection(ksATH_TransientStackPrefix)
	else
		wname3dStr = ATH_WaveOp#ConcatenateWavesInDataBrowserSelection(ksATH_StackPrefix) // stack in sourcedir if all waves in the same folder, otherwise in cwd
	endif
	// Do you want to display the stack?
	if(displayStack && strlen(wname3dStr)) // wname3dStr = "" when you select no or one wave
		string grfName = ATH_Display#NewImg($wname3dStr)
	else
		return 1
	endif
	// If you want a transient stack, tag it
	if(transientStack)
		SetWindow $grfName userdata(ATH_isTransientStack) = "1"
	endif
	return 0
End

/// @function LoadHDF5GroupsFromFile
/// @brief Load selected groups from an HDF5 file.
/// @returns Zero after completing the operation.
static Function LoadHDF5GroupsFromFile()
	string selectedGroups = ATH_Dialog#GenericSingleStrPrompt("Use single ScanID and/or ranges, e.g.  \"2-5,7,9-12,50\".  Leave string empty to load all entries.", "Before the .h5 selection dialog opens...")
	if(strlen(selectedGroups))
		ATH_HDF5#LoadHDF5SpecificGroupsNamesIndexed(selectedGroups, strFix = "entry")
	else
		ATH_HDF5#LoadHDF5File("") // Load all.
	endif
End

/// @function AverageStackToImageFromMenu
/// @brief Average a selected 3D stack into an image from a menu command.
/// @returns Zero after completing the operation.
static Function AverageStackToImageFromMenu()
	string waveListStr = Wavelist("*",";","DIMS:3"), selectWaveStr, waveNameStr
	string strPrompt1 = "Select stack"
	string strPrompt2 = "Enter averaged wave nane (leave empty for ATH_AvgStack)"
	string msgDialog = "Average a stack (3d wave) in working DF"
	[selectWaveStr, waveNameStr] = ATH_Dialog#GenericSingleStrPromptAndPopup(strPrompt1, strPrompt2, waveListStr, msgDialog)
	if(!strlen(waveNameStr))
		ATH_WaveOp#AverageImageStack($selectWaveStr)
	else
		ATH_WaveOp#AverageImageStack($selectWaveStr, outWaveStr = waveNameStr)
	endif
End

/// @function AverageStackToImageFromTraceMenu
/// @brief Average the stack associated with the active trace-menu command.
/// @returns Zero after completing the operation.
static Function AverageStackToImageFromTraceMenu()
	WAVE/Z w3dref = ATH_Graph#TopImageToWaveRef()
	if(!DimSize(w3dref, 2))
		Abort "Operation needs a stack"
	endif
	string strPrompt = "Averaged wave nane (leave empty for ATH_AvgStack)"
	string msgDialog = "Average stack along z"
	string waveNameStr
	waveNameStr = ATH_Dialog#GenericSingleStrPrompt(strPrompt, msgDialog)
	if(!strlen(waveNameStr))
		ATH_WaveOp#AverageImageStack(w3dref)
	else
		ATH_WaveOp#AverageImageStack(w3dref, outWaveStr = waveNameStr)
	endif
End

/// @function AverageStackToImageFromBrowserMenu
/// @brief Average a stack selected in the Data Browser into an image.
/// @returns NaN if input validation fails; otherwise zero after completing the operation.
static Function AverageStackToImageFromBrowserMenu()
	string bufferStr, wavenameStr
	if(ATH_Dialog#CountSelectedWavesInDataBrowser(wDim = 3) == 1\
	 && ATH_Dialog#CountSelectedWavesInDataBrowser() == 1) // If we selected a single 3D wave
		string selected3DWaveStr = GetBrowserSelection(0)
		WAVE wRef = $selected3DWaveStr	
	else
		print "Operation needs an image stack (3d wave)"
		return NaN
	endif
	ATH_WaveOp#AverageImageStack(wRef)
End

/// @function CalculateXMCDFromStack
/// @brief Calculate XMCD from a selected two-layer stack.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function CalculateXMCDFromStack()
	WAVE/Z w3d = ATH_Graph#TopImageToWaveRef()
	if(!WaveExists(w3d))
		return 1
	endif
	string basename = NameofWave(w3d) + "_xmcd"
	DFREF dfr = GetWavesDataFolderDFR(w3d)
	DFREF saveDF = GetDataFolderDFR()
	string xmcdWaveStr = CreatedataObjectName(dfr, basename, 1, 0, 1)
	SetDataFolder dfr
	if(ATH_XMCD#StackToXMCD(w3d, wnameStr=xmcdWaveStr))
		return 1 // return if you have more than two layers
	endif
	string noteStr = "Source: " + GetWavesDataFolder(w3d, 2) + "\n"
	noteStr += note(w3d)
	Note $xmcdWaveStr, noteStr
	CopyScales w3d, $xmcdWaveStr 
	ATH_Display#NewImg($xmcdWaveStr)
	SetDataFolder saveDF
	return 0
End

/// @function CalculationXMCD
/// @brief Calculate XMCD.
/// @details
/// S_fileName is a carriage-return-separated list of full paths to one or more files. as many times as the
/// dialog will be displayed. Equavalenty, it can. Set defaults.
/// @returns The calculated calculation XMCD.
static Function CalculationXMCD()
	string msg = "Select two 2d waves for XMC(L)D calculation. Use Ctrl (Windows) or Cmd (Mac)."
	string selectedWavesInBrowserStr = ATH_Dialog#SelectWavesInModalDataBrowser(msg)
	
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
	string selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
	if(nrSelectedWaves != 2)
		DoAlert/T="MAXPEEM would like you to know" 1, "Select two (2) 2d waves only.\n" + \
				"Do you want a another chance with the browser selection?"
		if(V_flag == 1)
			CalculationXMCD()
			return 0
		elseif(V_flag == 2)
			return -1
		else
			print "CalculationXMCD(). Abormal behavior."
		endif
		
		return -1 // Abort the running instance otherwise the code that follows will run 
			  // as many times as the dialog will be displayed. Equavalenty, it can 
			  // be placed in the if (V_flag == 1) branch.
	endif
	string wave1Str = StringFromList(0, selectedWavesStr) // The last dat has been eliminated when importing waves, so we are ok
	string wave2Str = StringFromList(1, selectedWavesStr)
	string selectedWavesPopupStr = wave1Str + ";" + wave2Str
	//Set defaults 
	Prompt wave1Str, "w1", popup, selectedWavesPopupStr
	Prompt wave2Str, "w2", popup, selectedWavesPopupStr
	DoPrompt "XMC(L)D = (w1 - w2)/(w1 + w2)", wave1Str, wave2Str
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE w2d1 = $wave1Str
	WAVE w2d2 = $wave2Str
	DFREF currDFR = GetDataFolderDFR()
	string saveWaveName = CreatedataObjectName(currDFR, "XMCD", 1, 0, 1)
	ATH_XMCD#CalculateXMCDWAVE(w2d1, w2d2, outWave = saveWaveName)
	string noteStr = "ATH_Magnetism#CalculateXMCDWAVE("+ wave1Str + ","+\
	wave2Str+", outWave=" + saveWaveName + ")"
	Note $saveWaveName, noteStr
	return 0
End

/// @function CalculationXMCD3D
/// @brief Calculate XMCD 3D.
/// @details
/// S_fileName is a carriage-return-separated list of full paths to one or more files. as many times as the
/// dialog will be displayed. Equavalenty, it can. Set defaults.
/// @returns The calculated calculation XMCD 3D.
static Function CalculationXMCD3D()
	string msg = "Select two 3d waves for XMC(L)D calculation. Use Ctrl (Windows) or Cmd (Mac)."
	string selectedWavesInBrowserStr = ATH_Dialog#SelectWavesInModalDataBrowser(msg)
	
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
	string selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
	if(nrSelectedWaves != 2)
		DoAlert/T="MAXPEEM would like you to know" 1, "Select two (2) 3d waves only.\n" + \
				"Do you want a another chance with the browser selection?"
		if(V_flag == 1)
			CalculationXMCD3d()
			return 0
		elseif(V_flag == 2)
			return -1
		else
			print "CalculationXMCD3d(). Abormal behavior."
		endif
		
		return -1 // Abort the running instance otherwise the code that follows will run 
			  // as many times as the dialog will be displayed. Equavalenty, it can 
			  // be placed in the if (V_flag == 1) branch.
	endif
	string wave1Str = StringFromList(0, selectedWavesStr) // The last dat has been eliminated when importing waves, so we are ok
	string wave2Str = StringFromList(1, selectedWavesStr)
	string selectedWavesPopupStr = wave1Str + ";" + wave2Str
	//Set defaults 
	Prompt wave1Str, "w1", popup, selectedWavesPopupStr
	Prompt wave2Str, "w2", popup, selectedWavesPopupStr
	DoPrompt "XMC(L)D = (w1 - w2)/(w1 + w2)", wave1Str, wave2Str
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE w3d1 = $wave1Str
	WAVE w3d2 = $wave2Str
	ATH_XMCD#CalculateXMCD3D(w3d1, w3d2)
	return 0
End

/// @function ImageRegistrationStack
/// @brief Register all layers of an image stack to a reference layer.
/// @returns NaN if input validation fails; otherwise zero after completing the operation.
static Function ImageRegistrationStack()
	WAVE wRef = ATH_Graph#TopGraphToWaveRef()
	if(!WaveExists(wRef))
		return NaN
	endif
	variable nlayers = DimSize(wRef, 2)
	if(nlayers > 9)
		DoAlert 1, "Image Registration is a time-consuming operation for big stacks, do you want to continue?"
		if(V_flag == 2)
			return NaN
		endif
	endif
	string wRef_backStr = ATH_DFR#BackupWaveInWaveDF(wRef)
	variable layerN = ATH_Graph#GetgLayer("")
	string waveNoteStr = note(wRef)
	ATH_ImgAlign#MultiThreadImageRegistration(wRef, layerN)
	Note wRef, waveNoteStr
	CopyScales $wRef_backStr, wRef
	return 0
End

/// @function ImageStackAlignmentPartition
/// @brief Align an image stack in independently processed spatial partitions.
/// @details
/// Save drift correction parameters. Local variables only, not saved. Save settings, use zero/non-zero for
/// flags.
/// @returns NaN if input validation fails; otherwise zero after completing the operation.
static Function ImageStackAlignmentUsingAFeature() // Key function for the package
	//
	WAVE wRef = ATH_Graph#TopGraphToWaveRef()
	if(!WaveExists(wRef) || WaveDims(wRef) < 3)
		return NaN
	endif
	
	variable method, RotZ, subpixel, filter, windowing
	// Save drift correction parameters
	if(!DataFolderExists(skATH_DriftCorrectionSettings))
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(skATH_DriftCorrectionSettings)
		variable/G dfr:gATH_method = 2
		variable/G dfr:gATH_RotZ = 2
		variable/G dfr:gATH_subpixel = 2
		variable/G dfr:gATH_filter = 1
		variable/G dfr:gATH_windowing = 1
	else
		DFREF dfr = $skATH_DriftCorrectionSettings
	endif
	
	NVAR/SDFR=dfr gATH_method, gATH_RotZ, gATH_subpixel
	method = gATH_method
	RotZ = gATH_RotZ
	subpixel = gATH_subpixel
	// Local variables only, not saved.
	variable saveDrift = 2
	variable layerN =  ATH_Graph#GetgLayer("")
	
	string msg = "Align " + NameOfWave(wRef) + " using part of the image."
	
	DFREF dfrSave = $skATH_SaveImageStackDriftCorrections
	WAVE/Z/SDFR=dfrSave wDC = ath_driftCorr
	if(WaveExists(wDC) && (DimSize(wDC, 1) == DimSize(wRef, 2)))	
		string methodStr = "Registration (sub-pixel); Correlation (pixel/sub-pixel); Phase Correlation (pixel/sub-pixel); Apply Saved Drift Corrections"
	else
		methodStr = "Registration (sub-pixel); Correlation (pixel/sub-pixel); Phase Correlation (pixel/sub-pixel)"
	endif
	
	
	Prompt method, "Method", popup, methodStr // Registration = 1, Correlation (Real) = 2, , Correlation (Phase) = 3, SavedDrifts = 4
	Prompt layerN, "Reference layer"
	Prompt subpixel, "Sub-pixel drift", popup, "Yes;No" // Yes = 1, No = 2!			
	Prompt RotZ, "Rotation (Registration)",  popup, "Yes;No" // Yes = 1, No = 2!
	Prompt saveDrift, "Save Drifts",  popup, "Yes;No" // Yes = 1, No = 2!
	
	DoPrompt msg, method, layerN, subpixel, RotZ, saveDrift
			
	if(V_flag) // User cancelled
		return -1
	endif
	
	// Save settings, use zero/non-zero for flags
	gATH_method = method
	gATH_RotZ = RotZ // Yes = 1, No = 2!	
	gATH_subpixel = subpixel // Yes = 1, No = 2!	
	//
	
	ATH_DFR#BackupWaveInWaveDF(wRef)
	string driftCorrectionOriginalNoteStr = note(wRef), driftCorrectionNoteStr // Grab early the original wave note
	variable left, right, top, bottom
	string xaxis, yaxis
	[xaxis, yaxis] = ATH_Graph#GetAxes()
	GetMarquee $xaxis, $yaxis
	if(V_flag)
		left = V_left
		right = V_right
		top = V_top
		bottom = V_bottom
	elseif(method==4)
		// Do nothing
	else
		STRUCT sUserMarqueePositions s
		[left, right, top, bottom] = ATH_Marquee#UserGetMarqueePositions(s)		
	endif

	string partitionWaveStr =  CreatedataObjectName(GetDataFolderDFR()	, "ATH_DRFCorr_PART", 1, 0, 0)
	ATH_WaveOp#WavePartition(wRef, partitionWaveStr, left, right, top, bottom, evenNum = 1)
	WAVE partitionWave = $partitionWaveStr

	//Multithreaded drift alignemnt won't keep wave scaling
	variable x0, y0, z0, dx, dy, dz
	[x0, y0, z0, dx, dy, dz] = ATH_WaveOp#GetScalesP(wRef)
	variable nlayers = DimSize(wRef, 2)
	if(method == 1)
		ATH_ImgAlign#MultiThreadRegistrationDriftCorrection(wRef, partitionWave, layerN, RotZ = gATH_RotZ - 2, \
			saveDrift = saveDrift - 2)
	elseif(method == 2 || method == 3)
		ATH_ImgAlign#MultiThreadCorrelationDriftCorrection(wRef, partitionWave, layerN, saveDrift = 1, \
			method = gATH_method-2, subpixel = gATH_subpixel - 2)	
	elseif(method == 4)
			ATH_ImgAlign#MultiThreadApplySavedDriftCorrections(wRef, cDriftW = wDC)
	else
		print "Please check ATH_Launch#ImageStackAlignmentPartition() method."
		return NaN
	endif
	ATH_WaveOp#SetScalesP(wRef,x0, y0, z0, dx, dy, dz)
	if(method == 4)
		driftCorrectionNoteStr = "\n(Drift Correction from saved parameters: " + note(wDc)
		driftCorrectionOriginalNoteStr += driftCorrectionNoteStr		
	else
		driftCorrectionNoteStr = "\nDrift correction using " + StringFromList(gATH_method, "dummy;Registration;Correlation (Real);Correlation (Phase)")
		driftCorrectionNoteStr += " with reference layer #"+num2str(layerN)+" and "+StringFromList(gATH_subpixel,"dummy;sub-pixel;pixel")+" resolution.\n"
		driftCorrectionNoteStr += "z-rotation: " + StringFromList(RotZ, "dummy;Yes;No") + "\n"
		driftCorrectionOriginalNoteStr += driftCorrectionNoteStr		
	endif
	KillWaves partitionWave
	Note wRef, driftCorrectionOriginalNoteStr
	return 0
End

/// @function LinearDriftCorrestionStackABCursors
/// @brief Correct linear stack drift from the displacement between cursors A and B.
/// @details
/// Use AB to linearly correct an image stack drift WAVE/Z wx, wy ImageInterpolate needs pixels, multiply by
/// -1 to have the proper behavior in /ARPM={...}.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function LinearDriftCorrestionStackABCursors()
	// Use AB to linearly correct an image stack drift
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif	
	WAVE wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // ATH_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable nlayers = DimSize(wRef, 2)
	
	if(nlayers < 3)
		return -1
	endif
	
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0)/N=1/P A $imgNameTopGraphStr 0.25, 0.5
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0)/N=1/P B $imgNameTopGraphStr 0.75, 0.5
	variable slope, shift
	
	string backupWavePathStr = ATH_DFR#BackupWaveInWaveDF(wRef)	
	
	variable x0, y0, x1, y1
	STRUCT sUserCursorPositions s
	[x0, y0, x1, y1] = ATH_Cursors#UserGetCursorPositions(s, "A", "B")
	[slope, shift] = ATH_Geometry#LineEquationFromTwoPoints(x0, y0, x1, y1)
	
	
	//WAVE/Z wx, wy // x, y drifts for each layer
	[WAVE wx, WAVE wy] = ATH_Geometry#XYWavesOfLineFromTwoPoints(x0, y0, x1, y1, nlayers)
	wx -= x0 // Relative xshift
	wy -= y0 // Relative yshift
	// ImageInterpolate needs pixels, multiply by -1 to have the proper behavior in /ARPM={...}
	variable dx = DimDelta(wRef, 0) ; variable dy = DimDelta(wRef, 1)
	wx /= (-dx) ; wy /= (-dy)
	string waveNoteStr = note(wRef)
	ATH_ImgAlign#LinearDriftStackABCursors(wRef, wx, wy)
	Note wRef, waveNoteStr
	return 0
End

/// @function LinearDriftCorrestionPlanesABCursors
/// @brief Correct linear drift across selected layers using cursors A and B.
/// @details
/// Use AB to linearly correct planes in an image stack. Set the slider to the starting layer before
/// launching the operation. Set cursors and the last layer using the.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function LinearDriftCorrestionPlanesABCursors()
	// Use AB to linearly correct planes in an image stack
	// Set the slider to the starting layer before launching 
	// the operation. Set cursors and the last layer using the
	// slide.
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif	
	WAVE wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // ATH_ImageStackAlignmentByPartitionRegistration needs a wave reference
	
	if(DimSize(wRef, 2) < 3)
		return -1
	endif
	string backupWavePathStr = ATH_DFR#BackupWaveInWaveDF(wRef)
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0,30000)/N=1/P A $imgNameTopGraphStr 0.25, 0.5
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0,30000)/N=1/P B $imgNameTopGraphStr 0.75, 0.5
	variable slope, shift, x0, y0, x1, y1, startL, endL, nlayers

	if(ATH_Graph#GetgLayer(winNameStr)==-1)
		ATH_Display#Append3DImageSlider()
	endif
	DFREF sliderDFR = $(skATH_W3DImageSliderParentDFR + winNameStr)
	NVAR/SDFR=sliderDFR gLayer
	startL = gLayer

	STRUCT sUserCursorPositions s
	[x0, y0, x1, y1] = ATH_Cursors#UserGetCursorPositions(s, "A", "B")
	endL = gLayer
	nlayers = endL - startL + 1

	// Deal with ill cases, or fix it to work in reverse 
	if(nlayers <= 0)
		return -1
	endif
	//WAVE/Z wx, wy // x, y drifts for each layer
	[WAVE wx, WAVE wy] = ATH_Geometry#XYWavesOfLineFromTwoPoints(x0, y0, x1, y1, nlayers)
	wx -= x0 // Relative xshift
	wy -= y0 // Relative yshift
	// ImageInterpolate needs pixels, multiply by -1 to have the proper behavior in /ARPM={...}
	variable dx = DimDelta(wRef, 0) ; variable dy = DimDelta(wRef, 1)
	wx /= (-dx) ; wy /= (-dy)
	string waveNoteStr = note(wRef)
	ATH_ImgAlign#LinearDriftPlanesABCursors(wRef, wx, wy, startL = startL, endL = endL)
	Note wRef, waveNoteStr
	return 0
End

// ---- ///

/// @function NewImageFromBrowserSelection
/// @brief New image from browser selection.
/// @details
/// Display selected images. Verify that you did not misclicked and prevent opening many images (bummer).
/// @returns Zero after completing the operation.
static Function NewImageFromBrowserSelection()
	// Display selected images
	variable i = 0, cnt = 0, promptOnceSwitch = 1
	string ATHImage
	if(!strlen(GetBrowserSelection(0)))
		Abort "No image selected"
	endif
	
	do
		ATHImage = GetBrowserSelection(i) 
		if(WaveDims($ATHImage) != 3 && WaveDims($ATHImage) != 2)
			Abort "Operation needs an image or image stack"
		endif
		// Verify that you did not misclicked and prevent opening many images (bummer)
		cnt++
		if(cnt > 2 && promptOnceSwitch)
			DoAlert/T="MAXPEEM would like to ask you ..." 1, "You "+ \
					   "are trying open more than two images at once, do you want to continue?"
			if(V_flag == 1)
				promptOnceSwitch = 0
			else
				break
			endif
		endif
		
		ATH_Display#NewImg($ATHImage)
		i++
	while (strlen(GetBrowserSelection(i)))
End

/// @function ImageBackupFromBrowserSelection
/// @brief Image backup from browser selection.
/// @returns Zero after completing the operation.
static Function ImageBackupFromBrowserSelection()
	string ATHImage = GetBrowserSelection(0)
	if(WaveDims($ATHImage) != 3 && WaveDims($ATHImage) != 2)
		Abort "Operation needs an image or image stack"
	endif
	ATH_ImgOp#RestoreTopImageFromBackup(grfName = ATHImage)
	return 0
End

/// @function XPSProfileFromDefaultSettings
/// @brief Generate an XPS profile using the saved default settings.
/// @details
/// Extract selected PES profiles for selected images in DB.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function XPSProfileFromDefaultSettings()
	// extract selected PES profiles for selected images in DB
	string wname = GetBrowserSelection(0)
	if(!strlen(wname) && !WaveExists($wname)) // no wave is selected
		return 1
	endif
	variable i = 0
	do
		wname = GetBrowserSelection(i)
		WAVE/Z wRef = $wname
		if(WaveExists(wRef) && WaveDims(wRef)==2)
			ATH_iXPS#GetProfileUsingDefaults(wRef)
		endif
		i++
	while(strlen(GetBrowserSelection(i)))
	return 0
End

// -------

/// @function NormalisationImageStackWithImage
/// @brief Normalize every stack layer by a selected 2D reference image.
/// @details
/// Consistency check.
/// @returns Zero after completing the operation.
static Function NormalisationImageStackWithImage()
		
	if(ATH_Dialog#CountSelectedWavesInDataBrowser(wDim=3) != 1)
		Abort "Please select an image stack (3d wave)"
	endif
	string wave3dStr = StringFromList(0, GetBrowserSelection(0))
	WAVE w3dRef = $wave3dStr
	string imageNameStr = StringFromList(0, ATH_Dialog#SelectWavesInModalDataBrowser("Select an image (2d wave) for normalisation"))
	WAVE imageWaveRef = $imageNameStr
	// consistency check
	if((DimSize(w3dRef, 0) != DimSize(imageWaveRef, 0)) || (DimSize(w3dRef, 1) != DimSize(imageWaveRef, 1)) ||\
		WaveDims(imageWaveRef) != 2 )
		string msg
		sprintf msg, "Number of rows or columns in *%s* is different from *%s*, " +\
					 "or you did not select an image (2d wave).\n" +\
					 "Aborting operation.", NameOfWave(w3dRef), NameOfWave(imageWaveRef)
		Abort msg
	endif
	string waveNormStr = ATH_ImgOp#NormaliseImageStackWithImage(w3dRef, imageWaveRef)
	string noteStr = "Normalised with " + GetWavesDataFolder(imageWaveRef, 2)
	Note $waveNormStr, noteStr
End

/// @function NormalisationImageStackWithProfile
/// @brief Normalize stack layers by the corresponding values of a 1D profile.
/// @details
/// Consistency check.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function NormalisationImageStackWithProfile()
	
	if(ATH_Dialog#CountSelectedWavesInDataBrowser(wDim=3) != 1)
		Abort "Please select an image stack (3d wave)"
	endif
	string wave3dStr = StringFromList(0, GetBrowserSelection(0))
	WAVE w3dRef = $wave3dStr
	string selectProfileStr = StringFromList(0, ATH_Dialog#SelectWavesInModalDataBrowser("Select a profile (1d wave) for normalisation"))
	WAVE profWaveRef = $selectProfileStr
	// consistency check
	variable nlayers = DimSize(w3dRef, 2) 
	variable npnts = DimSize(profWaveRef, 0)
	if(nlayers != npnts)
		string msg
		sprintf msg, "Number of layers in *%s* is different from number of points in *%s*.\n" +\
					 "Would you like to continue anyway?", NameOfWave(w3dRef), NameOfWave(profWaveRef)
		DoAlert/T="MAXPEEM would like you to make an informed decision", 1, msg
		if (V_flag == 2 || V_flag == 3)
			return -1
		endif
	endif
	string waveNormStr = ATH_ImgOp#NormaliseImageStackWithProfile(w3dRef, profWaveRef)
	string noteStr = "Normalised with " + GetWavesDataFolder(profWaveRef, 2)
	Note $waveNormStr, noteStr	
End

/// @function NormalisationImageStackWithImageStack
/// @brief Normalize one image stack by a second stack.
/// @details
/// Consistency check. Select how many layers would you like to use for normalisation. Handle here unique
/// output name.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function NormalisationImageStackWithImageStack()

	if(ATH_Dialog#CountSelectedWavesInDataBrowser(wDim=3) != 1)
		Abort "Please select an image stack (3d wave)"
	endif
	string wave3d1Str = StringFromList(0, GetBrowserSelection(0))
	WAVE w3d1Ref = $wave3d1Str
	string wave3d2Str = StringFromList(0, ATH_Dialog#SelectWavesInModalDataBrowser("Select an image stack (3d wave) for normalisation"))
	WAVE w3d2Ref = $wave3d2Str
	if(WaveDims(w3d2Ref) != 3)
		Abort "You have to select an image stack (3d wave)"
	endif
	// consistency check
	if((DimSize(w3d1Ref, 0) != DimSize(w3d2Ref, 0)) || (DimSize(w3d1Ref, 1) != DimSize(w3d2Ref, 1)))
		string msg
		sprintf msg, "Number of rows or columns in *%s* is different from *%s*. " +\
					 " Aborting operation.", NameOfWave(w3d1Ref), NameOfWave(w3d2Ref)
		Abort msg
	endif
	// Select how many layers would you like to use for normalisation
	string promptStr = "N : Use Nth layer (NB: zero-based layer indexing)\n"+\
					   "N1-N2 : Use average of N1, ..., N2 layers, \n"+\
	 				   "Leave empty: Layer by layer in 3d waves\n"
	string inputStr = ATH_Dialog#GenericSingleStrPrompt(promptStr, "How many layers would you like to use for Normalisation?")
	string rangeStr = ATH_String#ExpandRangeStr(inputStr)
	string normWaveBaseNameStr = wave3d1Str + "_norm", normWaveStr
	DFREF currDF = GetDataFolderDFR()
	variable nLayer, minLayer, maxLayer, totLayers
	string noteStr = "Normalised with " + GetWavesDataFolder(w3d2Ref, 2)	
	if(ItemsInList(rangeStr) == 1)
		nLayer = str2num(StringFromList(0, rangeStr))
		noteStr += " using layer " + num2str(nLayer)
		MatrixOP/O/FREE normLayerFree= layer(w3d2Ref, 0)
		// Handle here unique output name
		normWaveStr = CreateDataObjectName(currDF, normWaveBaseNameStr, 1, 0, 1)		
		MatrixOP $normWaveStr = w3d1Ref/normLayerFree
	elseif(!strlen(inputStr)) // Empty string do layer by layer normalisation
		normWaveStr = ATH_ImgOp#NormaliseImageStackWithImageStack(w3d1Ref, w3d2Ref)
		noteStr += " on a layer-by-layer basis"
	else // If you give a range n1 - n2
		totLayers = ItemsInList(rangeStr)
		minLayer = str2num(StringFromList(0,rangeStr))
		maxLayer = str2num(StringFromList(totLayers-1,rangeStr))
		if(minLayer < 0 || maxLayer > totLayers - 1)
			return -1
		endif
		noteStr += " using layers " + num2str(minLayer)	+ "-" + 	num2str(maxLayer) + " average"
		MatrixOP/O/FREE getWaveLayersFree = w3d2Ref[][][minLayer, maxLayer]
		MatrixOP/O/FREE normLayerFree = sumBeams(getWaveLayersFree)/(maxLayer - minlayer + 1)
		normWaveStr = CreateDataObjectName(currDF, normWaveBaseNameStr, 1, 0, 1)				
		MatrixOP $normWaveStr = w3d1Ref / normLayerFree
	endif
	Note $normWaveStr, noteStr	
End

/// @function RemoveImagesFromImageStack
/// @brief Remove images from image stack.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function RemoveImagesFromImageStack()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif	
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable flag
	string layerList, msg
	if(WaveDims(w3dref) == 3 && DataFolderExists(skATH_W3DImageSliderParentDFR + winNameStr))
		NVAR glayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(winNameStr):gLayer
	else
		return -1
	endif
	msg = "Remove layers from stack: \n1. \"N\" to remove N layers starting from top image\n"
	msg += "2. \"2-5,6,9\" to remove a range of images, here 2,3,4,5,6,9"
	Prompt layerList, msg
	DoPrompt "ATH_RemoveImagesFromImageStack", layerList
	if(!V_flag) // TODO: Use negative for backward removal
		if(strsearch(layerList, "-", 0) == -1)
			ATH_ImgOp#RemoveImagesFromImageStack(w3dref, gLayer, str2num(layerList))
		else
			ATH_ImgOp#RemoveRangeOfImagesFromImageStack(w3dref,layerList)
		endif
		ATH_Display#RestartW3DImageSlider(grfName=winNameStr)
	endif
	return 0
End

/// @function InsertImagesToStack
/// @brief Insert images to stack.
/// @details
/// We selected at least an image. Let's sort things here a bit. First lets expand the wave note when we
/// insert a 3D wave.
/// @param extend (optional) If nonzero, extend the destination rather than replacing its current extent.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function InsertImagesToStack([variable extend]) // Needs fixing

	extend = ParamIsDefault(extend) ? 0 : extend 
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif	
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable layerN
	if(WaveDims(w3dref) == 3 && DataFolderExists(skATH_W3DImageSliderParentDFR + winNameStr))
		NVAR glayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(winNameStr):gLayer
		layerN = glayer
	else
		return -1
	endif
	
	string selectImagesStr = ATH_Dialog#SelectWavesInModalDataBrowser("Select image(s)/stack(s) to insert before top laeyer.")
	
	// We selected at least an image
	if(!strlen(StringFromList(0, selectImagesStr)))
		return 1
	endif
		
	WAVE/WAVE waveListFree = ATH_WaveOp#WaveListStrToWaveRef(selectImagesStr, isFree = 1)		
	if(ATH_WaveOp#AllImagesEqualDimensionsQ(waveListFree))
		Concatenate/FREE/NP=2 {waveListFree}, wInsertFree
	endif
	
	variable wType = WaveType(wInsertFree)
	string getWaveListStr = ATH_String#GetStackNamesForWaveNote(w3dref,-1) // separator = "\n" 
	// Let's sort things here a bit.
	// First lets expand the wave note when we insert a 3D wave
	string expandedWaveList = ATH_String#ComposeWaveListsFromWaveNotes(selectImagesStr) // separator = ";"

	// Clear here the layerN to avoid if branches
	// This is because of the behaviour of ATH_ImgOp#InsertImagesToImageStack
	// see there to get the points
	if(extend)
		layerN = DimSize(w3dref,2)
	endif
	
	string fullWaveListStr = ATH_String#InsertListAtPosition(ReplaceString("\n", getWaveListStr, ";"), expandedWaveList, layerN)

	fullWaveListStr = ReplaceString(";", fullWaveListStr, "\n")
	

	if(wType == WaveType(wInsertFree))
		ATH_ImgOp#InsertImagesToImageStack(w3dref, wInsertFree, layerN)
	else
		ATH_WaveOp#MatchWaveTypes(w3dref, wInsertFree)
		ATH_ImgOp#InsertImagesToImageStack(w3dref, wInsertFree, layerN)
	endif
	ATH_Display#RestartW3DImageSlider(grfName=winNameStr)
	// use the default option, list should have "\n" separator
	ATH_String#UpdateStackWaveNote(w3dref, -1, explicitWaveList = fullWaveListStr)
	return 0	
End

/// @function ImgRGB2Gray16
/// @brief Convert the top RGB image to 16-bit grayscale.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function ImgRGB2Gray16()
	string ATHImage = GetBrowserSelection(0)
	WAVE/Z wRef = $ATHImage
	if(WaveExists(wRef))
		ATH_ImgOp#RGB2Gray16Image(wRef)
	else 
		return -1
	endif
	return 0
End

/// @function Rotate3DWaveAxes
/// @brief Rotate 3D wave axes.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function Rotate3DWaveAxes()
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(WaveDims(wRef) !=3)
		Abort "Operation needs a 3d wave (image stack)!"
	endif
	variable num = 0
	string modeStr = "XZY;ZXY;ZYX;YZX;YXZ"
	Prompt num, "Select axes rotation", popup, modeStr 
	DoPrompt "Rotate 3d wave axes",num
	if(V_flag)
		return 1
	endif
	string newwaveNameStr = NameOfWave(wRef) + "_" + StringFromList((num-1),modeStr)
	if(WaveExists($newwaveNameStr))
		print "Wave", newwaveNameStr, "already exists."
		return -1
	endif	
	ImageTransform/G=(num) transposeVol wRef
	WAVE M_VolumeTranspose
	string wnameStr = NameOfWave(wRef)
	DFREF srcDFR = GetWavesDataFolderDFR(wRef)
	DFREF dfr = GetDataFolderDFR()	
	string noteStr = "ImageTransform/G=" + num2str(num)+ " transposeVol " + wnameStr	
	Rename M_VolumeTranspose, $newwaveNameStr
	Note $newwaveNameStr, noteStr
	return 0
End

/// @function ImageRotateAndScaleFromMetadata
/// @brief Restore microscope orientation and field-of-view scaling from image metadata.
/// @details
/// This operation transform the image as seen in the microscope when the angular compensation is on for
/// different FoVs. The combination of ImageRotation and ImageTransform flipRows wRef restores the image.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function ImageRotateAndScaleFromMetadata()
	/// This operation transform the image as seen in the microscope
	/// when the angular compensation is on for different FoVs. The combination
	/// of ImageRotation and ImageTransform flipRows wRef restores the image 
	/// as seen in the live-image.
	/// Rotated/scaled wave in created in the working dfr.
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif	
	Wave wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	
	if(!strlen(imgNameTopGraphStr))
		//print "No image in top graph!"
		return -1
	endif	
	WAVE wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave	
	variable angle = NumberByKey("FOVRot(deg)", note(wRef), ":", "\n")
	string noteStr = note(wRef)
	// angle you see in the panel
	// angle < 0 rotate clock-wise
	// angle > 0 rotate counter clock-wise
	// This is because image cols (x-axis) is flipped before rotation
	ATH_ImgOp#ImageRotateAndScale(wRef, angle, flipY = 1, backup=1) // Flip rows and rotate clock-wise
	Note wRef, noteStr
End

/// @function ImageFFTTransform
/// @brief Calculate the Fourier transform of the active image.
/// @details
/// FFT of the top image. If Marquee is present the transform happends at the marked region FFT wave in the
/// cwd.
/// @param noPlot (optional) If nonzero, suppress creation of a result graph.
/// @param sourceDF (optional) Source data-folder reference or path.
/// @param mode (optional) Mode selector.
/// @returns Zero after completing the operation.
static Function ImageFFTTransform([int noPlot, int sourceDF, int mode])
	// FFT of the top image. If Marquee is present
	// the transform happends at the marked region
	// ATH_Transform#FFT2D creates the FFT wave in wRef DF.
	
	// FFT wave in the cwd
	noPlot = ParamIsDefault(noPlot) ? 0 : noPlot
	sourceDF = ParamIsDefault(sourceDF) ? 0 : sourceDF // Create the FFT in the source DF
	string grfName = WinName(0, 1, 1), noteStr
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	variable plane = ATH_ImgOp#GetLayerIndex(grfName)
	string marqueeNoteStr = ""
	if(WaveExists(wRef))
		if(sourceDF)
			DFREF saveDF = GetDataFolderDFR()
			SetDataFolder $GetWavesDataFolder(wRef, 1)
		endif
		string xaxis, yaxis				
		[xaxis, yaxis] = ATH_Graph#GetAxes(grfName=grfName)				
		GetMarquee/W=$grfName/K $xaxis, $yaxis
		if(V_flag) // if there is a Marquee
			marqueeNoteStr += "Marquee: " + num2str(V_left)+","+ num2str(V_right)
			marqueeNoteStr += "," + num2str(V_top) + "," + num2str(V_bottom)		
			DFREF dfr = GetDataFolderDFR()			
			if(numtype(plane)==0)
				MatrixOP/FREE getLayerFREE = layer(wRef, plane)
				WAVE wPlanePart = ATH_WaveOp#WavePartition(getLayerFREE, "", V_left, V_right, V_top, V_bottom, \
				evenNum = 1, WaveFREE = 1)		
				WAVE wPart = ATH_Transform#FFT2D(wPlanePart,mode=3)
			else
				WAVE wPart = ATH_WaveOp#WavePartition(wRef, "", V_left, V_right, V_top, V_bottom, \
				evenNum = 1, WaveFREE = 1) // FREE WAVE
			endif			
			// N.B. ATH_WaveOp#WavePartition returns pixel scaled image
			CopyScales/P wRef, wPart
			WAVE wFFT = ATH_Transform#FFT2D(wPart,mode=3) // WPart is a FREE wave
			// We have to do it here as ATH_Transform#FFT2D will return  free wave witn name _free__FFT.
		else
			if(numtype(plane)==0)
				MatrixOP/FREE getLayerFREE = layer(wRef, plane)
				WAVE wFFT = ATH_Transform#FFT2D(getLayerFREE,mode=3)
			else
				WAVE wFFT = ATH_Transform#FFT2D(wRef,mode=3)
			endif
		endif
		string destWaveNameStr = CreatedataObjectName(dfr, NameOfWave(wRef)+"_FFT", 1, 0, 1)
		Rename wFFT, $destWaveNameStr		
		noteStr = "FFT of " + GetWavesDataFolder(wRef, 2)
		if(numtype(plane)==0)
			noteStr += " (plane " + num2str(plane) + ").\n"
		else
			noteStr += ".\n" 
		endif
		if(strlen(marqueeNoteStr))
			noteStr += marqueeNoteStr
		endif
		Note wFFT, noteStr
		if(!noPlot)
			ATH_Display#NewImg(wFFT)
		endif
		if(sourceDF)
			SetDataFolder saveDF
		endif
	endif
	return 0
End

/// @function AverageLayersRange
/// @brief Average a user-selected range of image-stack layers.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function AverageLayersRange()
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveDims(wRef) == 0) //  WaveDims(wRef) == 0 when wRef is NULL
		print "AverageLayersRange() needs an image stack in top graph."
		return -1
	endif
	string rangeStr = ATH_Dialog#GenericSingleStrPrompt("Enter a range as 3-7 or 3,7. Zero-based indexing.", "Average image range")
	string sval1, sval2, separatorStr
	SplitString/E="\s*([0-9]+)\s*(-|,)\s*([0-9]+)" rangeStr, sval1, separatorStr, sval2
	ATH_ImgOp#AverageImageRangeToStack(wRef, str2num(sval1), str2num(sval2))
End

/// @function ExtractLayerRangeToStack
/// @brief Extract a selected layer range into a new image stack.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function ExtractLayerRangeToStack()

	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveExists(wRef) == 0) //  WaveDims(wRef) == 0 when wRef is NULL
		print "ExtractLayersToStack() needs an image stack in top graph."
		return -1
	endif
	string rangeStr = ATH_Dialog#GenericSingleStrPrompt("Enter layer range as \"3-7\" to extract to a stack or \"3,7\" to "+\
	"extract to a folder (zero-based indexing).\nLeave empty to extract all layers to a folder using the stack"+\
	" names (see wave note) or enter a dash \"-\" or comma \",\" for auto-naming using indices.",\
	"Extract image range from stack")
	string sval1, sval2, separatorStr
	if(!strlen(rangeStr)) // empty
		ATH_ImgOp#ExtractLayerRange(wRef,doStack=0,nameNote=1)
	elseif(!cmpstr(rangeStr,"-") || !cmpstr(rangeStr,","))
		ATH_ImgOp#ExtractLayerRange(wRef,doStack=0)
	else
		SplitString/E="\s*([0-9]+)\s*(-|,)\s*([0-9]+)" rangeStr, sval1, separatorStr, sval2
		if(!cmpstr(separatorStr,","))
			ATH_ImgOp#ExtractLayerRange(wRef, startL=str2num(sval1), endL=str2num(sval2), doStack=0, nameNote = 1)
		elseif(!cmpstr(separatorStr,"-"))
			string wRef_stck = ATH_ImgOp#ExtractLayerRange(wRef, startL=str2num(sval1), endL=str2num(sval2), doStack=1)
			if(WaveExists($wRef_stck))
				ATH_String#SetStackNamesInNote($wRef_stck,ATH_String#GetStackNamesForWaveNote(wRef, 0, rangeStr = sval1+"-"+sval2),listSepW="\n")
			endif
		else
			print "Wrong input, please check ExtractLayerRangeToStack() in ATH_Launch module"
		endif
	endif
	return 0
End

/// @function FlipStackPlanes
/// @brief Reverse the layer order of the active image stack.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function FlipStackPlanes()

	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveDims(wRef) == 0) //  WaveDims(wRef) == 0 when wRef is NULL
		print "SumImagePlanes() needs an image stack in top graph."
		return -1
	endif
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder GetWavesDataFolderDFR(wRef)
	ImageTransform flipPlanes wRef
	ATH_String#UpdateStackWaveNote(wRef, 2)
	SetDataFolder saveDF
	return 0
End

/// @function AverageImageStack
/// @brief Average image stack.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function AverageImageStack()
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	variable nlayers = DimSize(wRef,2)	
	if(WaveDims(wRef) != 3 || nlayers < 2)
		return -1
	endif	
	ATH_WaveOp#AverageImageStack(wRef)
	return 0
End

/// @function HistogramShiftToGaussianCenter
/// @brief Histogram shift to gaussian center.
/// @returns Zero after completing the operation.
static Function HistogramShiftToGaussianCenter()
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(!WaveExists(wRef))
		Abort "Wave Reference is NULL"
	endif
	ATH_DFR#BackupWaveInWaveDF(wRef) // backup the wave, we will overwrite
	variable shift
	// ATH_ImgOp#HistogramShiftToGaussianCenterStack returns the applied shift
	if(WaveDims(wRef) == 3)	
		shift = ATH_ImgOp#HistogramShiftToGaussianCenterStack(wRef, overwrite=1)
	else
		shift= ATH_ImgOp#HistogramShiftToGaussianCenter(wRef, overwrite=1)
	endif
	Note wref, "Histogram shift num = " + num2str(shift) + " [w -= num]"
End

/// @function TwoTraceCalcs
/// @brief Perform a selected arithmetic operation on two graph traces.
/// @details
/// Creates a separate result wave, leaving the input wave available to the caller.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function TwoTraceCalcs()
	string winNameStr = WinName(0, 1, 1), cmdStr, resNameStr, noteStr
	string traceNameListStr = TraceNameList(winNameStr, ";", 1 + 4)
	string traceName1Str = StringFromList(0, traceNameListStr)
	string traceName2Str = StringFromList(1, traceNameListStr)
	if(!strlen(traceName1Str) || !strlen(traceName2Str))
		print "You need two traces on top graph."
		return -1
	endif
	WAVE w1 = TraceNameToWaveRef(winNameStr, traceName1Str)
	WAVE w2 = TraceNameToWaveRef(winNameStr, traceName2Str)
	DFREF currDF = GetDataFolderDFR()
	string w1Str = GetWavesDataFolder(w1, 2)
	string w2Str = GetWavesDataFolder(w2, 2)	
	resNameStr = CreateDataObjectName(currDF, "ATH_op", 1, 0, 1)
	Duplicate w1, currDF:$resNameStr
	WAVE wR = currDF:$resNameStr	
	string wResStr = GetWavesDataFolder(wR, 2)
	string inputStr = "wR = w1 - w2 "	
	Prompt inputStr, "Enter operation as wR = f(w1, w2) [e.g wR=w1-w2 or MatrixOP wR = w1/w2]"
	DoPrompt "Operation between two traces", inputStr
	if(!V_flag)
		cmdStr = ReplaceString("w1", inputStr, w1Str)
		cmdStr = ReplaceString("w2", cmdStr, w2Str)
		cmdStr = ReplaceString("wR", cmdStr, wResStr, 0, 1) // Esssential otherwise all w are replaced!
		Execute/Q/Z cmdStr
		noteStr = "Operation: " + inputStr + "\n"
		noteStr += "wR->"+wResStr + "\n"	
		noteStr += "w1->"+w1Str + "\n"
		noteStr += "w2->"+w2Str + "\n"
		Note wR, noteStr
	endif
	return 0
End

/// @function QuickTextAnnotation
/// @brief Prompt for text and add it as an annotation to the active graph.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function QuickTextAnnotation()
	string textStr = "" 
	string color ="black"
	variable fSize = 4 // Forth selectio, fSize = 12
	string fSizeList = "9;10;11;12;13;14;16;18;20;22;24"
	Prompt textStr, "Text"
	Prompt color, "Color", popup, "black;red;green;blue"
	Prompt fSize, "Font Size", popup, fSizeList
	DoPrompt "Enter text annotation for the top graph", textStr, color, fSize
	if(V_flag)
		return 1
	endif
	fSize = str2num(StringFromList(fSize, fSizeList))
	ATH_Graph#TextAnnotationOnTopGraph(textStr, fSize = fSize, color = color)
	return 0
End

/// @function MakeWaveFromSavedROI
/// @brief Create wave from saved ROI.
/// @returns Zero after completing the operation.
static Function MakeWaveFromSavedROI()
	WAVE/Z wref = ATH_Graph#TopImageToWaveRef()
	ATH_WaveOp#MakeWaveFromROI(wRef)
End

/// @function XMCDCombinations
/// @brief Calculate XMCD for all layer pairs in the active image stack.
/// @details
/// S_fileName is a carriage-return-separated list of full paths to one or more files.
/// @returns Zero after completing the operation.
static Function XMCDCombinations()
	
	string msg = "Select one 3D wave for XMC(L)D combinations calculation." 
	string selectedWavesInBrowserStr = ATH_Dialog#SelectWavesInModalDataBrowser(msg)
	
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
	string selectedWavesStr = StringFromList(0, selectedWavesInBrowserStr)
	WAVE w3d = $selectedWavesStr
	variable nlayers = DimSize(w3d, 2)	
	if(nrSelectedWaves != 1 || WaveDims(w3d) != 3)
		Abort "You must select only one 3D wave (image stack)"
	endif
	if(nlayers > 40)
		string abortmsg = "This operation will need a large amount of memory and " \
						 + "I will not continue.\nIf you want to perform the operation " \
						 + " check the function ATH_XMCD#Combinations."
		DoAlert 0, abortmsg
	elseif(nlayers > 10)
		string alertStr = "Operation will create a 3D wave with " + num2str((nlayers-1)*nlayers/2)\
						+ "layers. \nDo you want to continue?"
		DoAlert/T="Too many layers will be created ...", 1, alertStr
		if(V_flag == 1)
			ATH_XMCD#MultiThreadXMLDComb(w3d)
		endif	
	else 
		ATH_XMCD#CalculateXMCDComb(w3d)
	endif
	return 0
End

/// @function DeleteBigWaves
/// @brief Find and optionally remove waves above a user-selected size threshold.
/// @details
/// Delete filter larger than minFileSizeMB. The textWave that pops to check the waves can be edited to
/// remove the waves you want to keep (an invalid path.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function DeleteBigWaves()
	/// Delete filter larger than minFileSizeMB.
	/// The textWave that pops to check the waves can be edited
	/// to remove the waves you want to keep (an invalid path
	/// will also lead to the same result as the function 
	/// ATH_DeleteWavesInTextWave that clears big waves will
	/// not give any error (/Z). Only the total freed space will
	/// be reported incorreclty.

	variable minFileSizeMB = 100 // Threshhold in MB
	Prompt minFileSizeMB, "Enter threshold value in MegaBytes (MB)"
	DoPrompt "Delete big files", minFileSizeMB
	if(minFileSizeMB <= 0 || V_flag)
		return 1
	endif
	ATH_DFR#FindBigWaves(minFileSizeMB)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:FindBigWaves")
	WAVE/SDFR=dfr/T waveNamesW
	WAVE/SDFR=dfr waveSizesW 
	ATH_TWave#TWaveRemoveEntriesFromPatters(waveNamesW, "root:Packages:*", otherW = waveSizesW) // Do not operate on root:Packages !
	variable totalSizeMB = sum(waveSizesW)
	variable nwaves = DimSize(waveNamesW, 0)
	string editWindowName = UniqueName("BigWaves", 7, 0)
	Edit/K=2/N=$editWindowName waveNamesW, waveSizesW as "Big Waves" // Prevent window from being killed here!
	STRUCT sUserMarqueePositions s
	variable cancel = ATH_Dialog#WaitForUserActions(s, vWinType = 2)
	
	// Here clear the empty entries
	variable i
	for(i = nwaves - 1; i > 0; i--) // we have to do it backwards!
		if(!strlen(waveNamesW[i]))
			DeletePoints i, 1, waveNamesW
			DeletePoints i, 1, waveSizesW
		endif
	endfor
	
	if(cancel)
		KillWindow/Z $editWindowName
		KillDataFolder/Z dfr
		return 1
	else
		ATH_TWave#DeleteWavesInTextWave(waveNamesW)
		KillWindow/Z $editWindowName
		// Here DimSize(waveNamesW, 0) as nwaves might have changed
		print "Deleted " + num2str(DimSize(waveNamesW, 0)) + " waves. Total space freed: " + num2str(totalSizeMB) + " MBs"
		KillDataFolder/Z dfr // prevents error in case you have open one of the waves 
		return 0
	endif
End

/// @function DeleteBigWavesDisplayed
/// @brief Close displays of oversized waves before removing those waves.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function DeleteBigWavesDisplayed()
	variable minFileSizeMB = 100 // Threshhold in MB
	Prompt minFileSizeMB, "Enter threshold value in MegaBytes (MB)"
	DoPrompt "Delete big files", minFileSizeMB
	if(minFileSizeMB <= 0)
		return 1
	endif
	ATH_DFR#FindBigWaves(minFileSizeMB)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:FindBigWaves")
	WAVE/SDFR=dfr/T waveNamesW
	WAVE/SDFR=dfr waveSizesW 
	ATH_TWave#TWaveRemoveEntriesFromPatters(waveNamesW, "root:Packages:*", otherW = waveSizesW) // Do not operate on root:Packages !
	variable totalSizeMB = sum(waveSizesW)
	variable nwaves = DimSize(waveNamesW, 0)
	string editWindowName = UniqueName("BigWaves", 7, 0)
	Edit/K=2/N=$editWindowName waveNamesW, waveSizesW as "Big Waves"
	STRUCT sUserMarqueePositions s
	variable cancel = ATH_Dialog#WaitForUserActions(s, vWinType = 2)
	if(cancel)
		KillWindow/Z $editWindowName
		KillDataFolder/Z dfr
		return 1
	else	
		ATH_TWave#DeleteWavesInTextWave(waveNamesW)
		KillWindow/Z $editWindowName
		print "Deleted " + num2str(nwaves) + " waves. Total space freed: " + num2str(totalSizeMB) + " MBs"
		KillDataFolder dfr		
		return 0
	endif
End

/// @function PixelateSingleImageOrStack
/// @brief Pixelate either a single image or every layer of an image stack.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function PixelateSingleImageOrStack()
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	variable nx = 1, ny = 1, nz = 0 // Added om 28.06.2025!!
	if(WaveDims(wRef) == 3)
		Prompt nx, "Pixelate X:"
		Prompt ny, "Pixelate Y:"	
		Prompt nz, "Pixelate Z (= 0, 1 to average over row, cols only!):"
		DoPrompt "Pixelate image stack", nx, ny, nz
		if(V_flag)
			return -1
		endif	
		if(!ATH_Num#IntegerQ(nx))
			print "Truncate nx: ", num2str(trunc(nx))
		endif
		if(!ATH_Num#IntegerQ(ny))
			print "Truncate ny: ", num2str(trunc(ny))			
		endif
		if(!ATH_Num#IntegerQ(nz))
			print "Truncate nz: ", num2str(trunc(nz))			
		endif
		ATH_ImgOp#PixelateImageStack(wRef, nx, ny, nz)
	elseif(WaveDims(wRef) == 2)
		Prompt nx, "Pixelate X:"
		Prompt ny, "Pixelate Y:"
		DoPrompt "Pixelate image", nx, ny
		if(V_flag)
			return -1
		endif
		if(!ATH_Num#IntegerQ(nx))
			print "Truncate nx: ", num2str(trunc(nx))
		endif
		if(!ATH_Num#IntegerQ(ny))
			print "Truncate ny: ", num2str(trunc(ny))			
		endif		
		ATH_ImgOp#PixelateImage(wRef, nx, ny)
	else
		Abort "Operation needs an image or an image stack"
	endif
			
	return 0
End

/// @function SetTopGraphDF
/// @brief Switch the current data folder to the top graph's source folder.
/// @details
/// Sets the DF of the top image or top trace. Remove background.
/// @returns Zero after completing the operation.
static Function SetTopGraphDF()
	// Sets the DF of the top image or top trace
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(WaveExists(wRef))
		SetDataFolder GetWavesDataFolderDFR(wRef)
	else
		Wave wRef = ATH_Traces#TopTraceToWaveRef()
		SetDataFolder GetWavesDataFolderDFR(wRef)
	endif
	return 0
End

// Remove background

/// @function ImgRemoveBackground
/// @brief Launch background removal for the active image or stack.
/// @details
/// Return 1 for successful Mask creation, 0 otherwise. Flatten Image.
/// @param w3d (optional) Input 3D wave or image stack.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function ImgRemoveBackground([variable w3d]) // ImageRemoveBackground is an Igor operation
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	variable order = 1
	variable doFullStack = 2
	if(WaveDims(wRef) == 3)
		Prompt order, "Background order (plane = 1, op. overwrites destination wave)"
		Prompt doFullStack, "Apply to all layers?", popup "No;Yes" // 1-No, 2-Yes
		DoPrompt "Background subtraction ", order, doFullStack
	else
		Prompt order, "Background order (plane = 1, op. overwrites destination wave)"
		DoPrompt "Background subtraction ", order
	endif
	
	order = trunc(order)
	if(V_flag || order < 1 || order > 12)
		return -1
	endif
	ATH_DFR#BackupWaveInWaveDFQ(wRef)
	string noteStr = note(wRef)
	
	// If there is a marquee use it to mask the wave
	// Return 1 for successful Mask creation, 0 otherwise
	string maskPathStr = ATH_Marquee#MarqueeToMask() // If there is no Marquee isMask is Nan. !NaN = 0
	variable isMask = strlen(maskPathStr)
	variable gLayer = ATH_Graph#GetgLayer("")
	if(doFullStack==2) // apply to the whole stack OR a single 2D wave 
		ATH_ImgOp#ImgRemoveBackground(wRef, order = order, layerN = - 1, useMask = isMask)	
	elseif(doFullStack==1) // apply to one layer of a stack
		ATH_ImgOp#ImgRemoveBackground(wRef, order = order, layerN = gLayer, useMask = isMask)
	else
		print "--> Check ATH_Launch#ImgRemoveBackground <--"
		return -1
	endif
	Note wRef, "\nImageRemoveBackground/P=" + num2str(order) + "\n" + noteStr
	KillWaves/Z $maskPathStr
	return 0
End

// Flatten Image

/// @function FlattenImage
/// @brief Flatten image.
/// @details
/// Create backup here. Resolve the. Get and set image range and ctab.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function FlattenImage()
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	variable kernelN = 2^5, iterN = 1
	string method, kind, notestr
	string msg = "Flatten: img-bkg (layer-wise)"
	Prompt method, "Method", popup, "gauss;avg;median;max;min"
	Prompt kind, "Background type", popup, "additive;multiplicative"
	Prompt kernelN, "Kernel size"
	Prompt iterN, "Iterations"
	DoPrompt msg, method, kind, kernelN, iterN
	// Create backup here
	
	// Resolve the 
	if(WaveDims(wRef) == 2)
		ATH_ImgOp#BackupTopImage()
		ATH_ImgOp#FlattenImage(wRef, method, kind, kernelN, iterN, overwrite = 1)
	elseif(WaveDims(wRef) == 3)
		ATH_ImgOp#BackupTopImage()
		ATH_ImgOp#FlattenImage3D(wRef, method, kind, kernelN, iterN, overwrite = 1)
	else
		return -1
	endif
	notestr = "Background removal using ATH_ImgOp#FlattenImage("+method+","
	notestr += kind+","+num2str(kernelN)+","+num2str(iterN)+", overwrite = 1)\n"
	ATH_String#WaveLogging(wRef, notestr, prepend = 1)
	return 0
End

// Get and set image range and ctab

/// @function SaveAxesRangeAndCtab
/// @brief Save axes range and color table.
/// @param grfName (optional) Name of the graph window.
/// @returns Zero after completing the operation.
static Function SaveAxesRangeAndCtab([string grfName])
	//
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:SavedAxesRangeCtab" ) // Root folder here
	string axisX, axisY
	variable minXV, maxXV, minYV, maxYV
	[axisX, minXV, maxXV, axisY, minYV, maxYV] = ATH_Graph#GetAxesRange(grfName = grfName)
	string graphCtabStr = ATH_Graph#GetGraphCtabStr(grfName = grfName)
	NVAR/Z/SDFR=dfr gATH_AxisMinX
	if(!NVAR_Exists(gATH_AxisMinX))
		variable/G dfr:gATH_AxisMinX = minXV
		variable/G dfr:gATH_AxisMaxX = maxXV
		variable/G dfr:gATH_AxisMinY = minYV
		variable/G dfr:gATH_AxisMaxY = maxYV
		string/G dfr:gATH_AxisX = axisX
		string/G dfr:gATH_AxisY = axisY		
		string/G dfr:gATH_GraphCtabStr = graphCtabStr
	else
		NVAR/Z/SDFR=dfr gATH_AxisMinX
		NVAR/Z/SDFR=dfr gATH_AxisMaxX
		NVAR/Z/SDFR=dfr gATH_AxisMinY
		NVAR/Z/SDFR=dfr gATH_AxisMaxY
		SVAR/Z/SDFR=dfr gATH_AxisX
		SVAR/Z/SDFR=dfr gATH_AxisY
		SVAR/Z/SDFR=dfr gATH_GraphCtabStr
		gATH_AxisX = axisX
		gATH_AxisY = axisY		
		gATH_AxisMinX = minXV
		gATH_AxisMaxX = maxXV
		gATH_AxisMinY = minYV
		gATH_AxisMaxY = maxYV
		gATH_GraphCtabStr = graphCtabStr
	endif
	return 0
End

/// @function SetAxesRangeAndCtabFromSaved
/// @brief Set axes range and color table from saved.
/// @param grfName (optional) Name of the graph window.
/// @param setCtab (optional) If nonzero, restore the saved image color table.
/// @param printCmd (optional) If nonzero, print the generated Igor command to history.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function SetAxesRangeAndCtabFromSaved([string grfName, variable setCtab, variable printCmd])
	//
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:SavedAxesRangeCtab" ) // Root folder here
	NVAR/Z/SDFR=dfr gATH_AxisMinX
	if(!NVAR_Exists(gATH_AxisMinX))
		return 1
	elseif(WaveDims(ATH_Graph#TopImageToWaveRef(grfName=grfName)) < 2)
		return -1
	else
		NVAR/Z/SDFR=dfr gATH_AxisMinX
		NVAR/Z/SDFR=dfr gATH_AxisMaxX
		NVAR/Z/SDFR=dfr gATH_AxisMinY
		NVAR/Z/SDFR=dfr gATH_AxisMaxY
		SVAR/Z/SDFR=dfr gATH_AxisX
		SVAR/Z/SDFR=dfr gATH_AxisY		
		SVAR/Z/SDFR=dfr gATH_GraphCtabStr
		SetAxis/W=$grfName $gATH_AxisX gATH_AxisMinX, gATH_AxisMaxX
		SetAxis/R/W=$grfName $gATH_AxisY gATH_AxisMinY, gATH_AxisMaxY
		if(printCmd)
			print "----  Set position on " + grfName + " ----"
			print "SetAxis/W="+grfName+" "+gATH_AxisX+" "+num2str(gATH_AxisMinX)+", "+num2str(gATH_AxisMaxX)		
			print "SetAxis/R/W="+grfName+" "+gATH_AxisY+" "+num2str(gATH_AxisMinY)+", "+num2str(gATH_AxisMaxY)
			print "- - - - - - - - - - - - - - - - -"
		endif
		if(setCtab) // Default = 0
			ATH_Graph#SetGraphCtabStr(gATH_GraphCtabStr, grfName = grfName)
		endif
	endif
	return 0
End

/// @function HistogramEqualisation
/// @brief Apply histogram equalization to the active image.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function HistogramEqualisation()
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	if(WaveDims(wRef)==1 || WaveDims(wRef)==4)
		return -1
	endif
	ATH_DFR#BackupWaveInWaveDF(wRef) // backup the wave, we will overwrite
	ImageHistModification/O/I wRef
	Note wRef, ("ImageHistModification/O/I " + NameOfWave(wRef))
	return 0
End

/// @function CloseTopWindowAndDeleteSource
/// @brief Close the active graph and delete its displayed source wave.
/// @details
/// Close topwindow and delete the top image or trace.
/// @param deleteBackUp (optional) If nonzero, delete the image's backup wave as well.
/// @param grfName (optional) Name of the graph window.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function CloseTopWindowAndDeleteSource([int deleteBackUp, string grfName])
	// Close topwindow and delete the top image or trace
	deleteBackUp = ParamIsDefault(deleteBackUp) ? 0 : deleteBackUp
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef(grfName = grfName)
	if(!WaveExists(wRef))
		return -1
	else
		KillWindow/Z $grfName
	endif	
	if(deleteBackUp) // Check first and then delete the wRef!!
		DFREF saveDF = GetDataFolderDFR()
		SetDataFolder $GetWavesDataFolder(wRef, 1)
		WAVE/Z wRefBck = $(NameOfWave(wRef) + ksATHBackupWaveExtention)
		if(WaveExists(wRefBck))
			Killwaves/Z wRefBck, wRef
			SetDataFolder saveDF
		else
			Killwaves/Z wRef
			SetDataFolder saveDF
		endif
	endif	

	return 0
End

/// @function DeleteBackupWave
/// @brief Remove backup wave.
/// @param grfName (optional) Name of the graph window.
/// @returns Zero after completing the operation.
static Function DeleteBackupWave([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wref = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	WAVE/Z wRefBck = $(NameOfWave(wRef) + ksATHBackupWaveExtention)
	if(WaveExists(wRefBck))
		Killwaves/Z wRefBck
	endif
	return 0
End

/// @function MirrorPositionToWaveValues
/// @brief Mirror the current graph position into stored wave values.
/// @details
/// S_fileName is a carriage-return-separated list of full paths to one or more files.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function MirrorPositionToWaveValues()

	string msg = "Select a wave to mirror the cursor values." 
	string selectedWavesInBrowserStr = ATH_Dialog#SelectWavesInModalDataBrowser(msg)
	if(!strlen(selectedWavesInBrowserStr))
		return -1
	endif
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
	string selectedWavesStr = StringFromList(0, selectedWavesInBrowserStr)
	WAVE wRef = $selectedWavesStr
	ATH_Cursors#MirrorCursorPositionToWaveValues(wRef)
	GetWindow/Z kwTopWin wtitle
	string logmsg = "Mirror value display for "+GetWavesDataFolder(wRef, 2)
	logmsg += " in "+WinName(0,1,1)+" titled "+S_value+". ** Press ESC to exit **."
	print logmsg
End

/// @function DrawSavedROIOnGraph
/// @brief Draw a saved ROI on the active graph.
/// @details
/// Draw the ROI saved in wRef on grfName set bypass to draw ROI on any graph.
/// @param grfName Name of the graph window.
/// @param wRef Input wave.
/// @param bypass (optional) If nonzero, skip the normal validation or selection step.
/// @returns Zero after completing the operation.
static Function DrawSavedROIOnGraph(string grfName, WAVE wRef, [variable bypass])
	/// Draw the ROI saved in wRef on grfName
	/// set bypass to draw ROI on any graph
	DoWindow/F grfName	
	SetDrawLayer/W=$grfName UserFront
	// Do we mathch saved ROI reference and wave displayed in grfName?
	WAVE/Z w1 = $StringByKey("WavePath", note(wRef), ":", "\n")
	WAVE/Z w2 = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	if(!WaveRefsEqual(w1,w2) && !bypass)
		Execute/Q/Z/P StringByKey("DrawEnv", note(wRef), ":", "\n")
		Execute/Q/Z/P StringByKey("DrawCmd", note(wRef), ":", "\n")
	endif
	return 0
End

/// @function iImgFFTFilter
/// @brief Launch the interactive FFT filter for the active image.
/// @param grfName (optional) Name of the graph window.
/// @returns Zero after completing the operation.
static Function iImgFFTFilter([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wref = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	ATH_ImgFilter#iFFTImgFilter(wref)
	return 0
End

/// @function UnpackStackToSources
/// @brief Restore image-stack layers to their source waves using stack metadata.
/// @param grfName (optional) Name of the graph window.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function UnpackStackToSources([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	if(WaveDims(wRef)!=3)
		return -1
	endif
	string msg = "!!!!!!!!!!! A T T E N T I O N !!!!!!!!!!!\nYou will overwrite the source waves listed"+\
	" in the wave note.\nThis operation cannot be undone.\nThe destination waves will be overwritten.\n"+\
	"I hope you know what you are doing."
	DoAlert/T="!!!athina wants to unpack stack to source waves!!!", 1, msg
	if(V_flag == 1) // Click yes
		ATH_WaveOp#UnpackLayersToSources(wRef)
	endif
	
End

/// @function ImageResample
/// @brief Resample the active image using a selected interpolation method and scale.
/// @details
/// Resample and offset image. Copyscales/I wRef, $resampledWaveName.
/// @returns NaN if input validation fails; otherwise zero after completing the operation.
static Function ImageResample()
	// Resample and offset image
	string msg = "Resample and offset image"
	string funcMethodList = "None;bilinear;nn;cubic;spline;sinc"
	variable funcMethod = 2, xOffset = 0,  yOffset = 0, imgSel = 2, xscale = 1, yscale = 1
	Prompt funcMethod, "Interpolatiing method", popup, "bilinear;nn;cubic;spline;sinc" // bilinear = 1
	Prompt xOffset, "x-offset"
	Prompt yOffset, "y-offset"
	Prompt xscale, "Scale factor (x)"
	Prompt yscale, "Scale factor (y)"
	Prompt imgSel, "Select image to match lateral dims?", popup, "Yes;No" // Yes = 1, No = 2!	
	DoPrompt msg, funcMethod, imgSel, xOffset, yOffset, xscale, yscale
	if(V_flag)
		return 0
	endif
	WAVE wRef = ATH_Graph#TopGraphToWaveRef()
	string waveNoteStr = note(wRef)
	if(imgSel != 2) // If any of the scales is zero, select an image to match dims
		msg = "Select a 2D or 3D to match lateral dimensions"
		string selectWaveStr = StringFromList(0, ATH_Dialog#SelectWavesInModalDataBrowser(msg))
		if(!strlen(selectWaveStr))
			return NaN
		endif
		WAVE wDest = $selectWaveStr
		if(WaveExists(wDest) && ( WaveDims(wDest)==2 || WaveDims(wDest)==3))
			xscale = DimSize(wDest,0)/DimSize(wRef,0)
			yscale = DimSize(wDest,1)/DimSize(wRef,1)
		else
			return NaN
		endif
	endif
	string resampledWaveName = ATH_ImgOp#ImageResampling(wRef, StringFromList(funcMethod-1, funcMethodList), xOffset, yOffset,\
	xscale = xscale, yscale = yscale)
	Note wRef, waveNoteStr
	//Copyscales/I wRef, $resampledWaveName
	return 0
End

/// @function DrawScaleBar
/// @brief Prompt for a physical length and draw a scale bar on the active image graph.
/// @details
/// String axisX, axisY variable minVX, maxVX, minVY, maxVY, sf.
/// @param grfName (optional) Name of the graph window.
/// @returns The scale-bar width as a fraction of the visible x-axis range, or -1 if the prompt is cancelled or invalid.
static Function DrawScaleBar([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	variable scale
	Prompt scale, "Scale bar length"	
	DoPrompt "Draw a scale bar in x-axis units", scale
	if(V_flag || scale <= 0)
		return -1
	endif
	variable scaleFactor = ATH_Draw#ImageScaleBar(scale) // non-zero is ok
	if(scaleFactor)
		SetWindow $grfName userdata(ATH_DrawBarInGraphNominalScale) = num2str(scale)
//		string axisX, axisY
//		variable minVX, maxVX, minVY, maxVY, sf
//		[axisX, minVX, maxVX, axisY, minVY, maxVY] = ATH_Graph#GetAxesRange(grfName=grfName)
//		variable xlen = abs(maxVX - minVX)
		SetWindow $grfName userdata(ATH_DrawBarInGraphScaleFactor) = num2str(scaleFactor)		
	endif
	return scaleFactor
End

/// @function ImageZScore
/// @brief Create a z-score-normalized copy of the active image.
/// @param grfName (optional) Name of the graph window.
/// @returns Zero after completing the operation.
static Function ImageZScore([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	WAVE wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	ATH_ImgOp#ComputeImageZScore(wRef, grfName=grfName)
	return 0
End

/// @function SetRangeAndCTabForAllGraphsInSpace
/// @brief Apply saved axis ranges and color tables to every graph in an ATH space.
/// @param spaceTagStr (optional) ATH space tag selecting graph windows.
/// @param setCtab (optional) If nonzero, also apply the saved color table.
/// @returns Zero after completing the operation.
static Function SetRangeAndCTabForAllGraphsInSpace([string spaceTagStr, variable setCtab])
	
	if(ParamIsDefault(spaceTagStr))
		string grfName = WinName(0, 1, 1)
		spaceTagStr = GetUserData(grfName, "", "ATH_SpacesTag")
	endif
	string winNameStr, getSpacetagStr
	string allWindowsStr = SortList(RemoveFromList("ATH_SpacesPanel",WinList("*",";","WIN:1,VISIBLE:1")), ";", 16)
	variable i, imax = ItemsInList(allWindowsStr)
	for(i = 0; i < imax; i++)
		winNameStr = StringFromList(i, allWindowsStr)
		getSpacetagStr = GetUserData(winNameStr, "", "ATH_SpacesTag") // Do not apply it to pinned windows
		if(!cmpstr(getSpacetagStr, "ATH__PinnedWindow__ATH", 0))
			continue
		endif
		if(WaveExists(ATH_Graph#TopGraphToWaveRef(grfName=winNameStr)))
			ATH_Launch#SetAxesRangeAndCtabFromSaved(grfName=winNameStr,setCtab=setCtab)
		endif
	endfor
	return 0
End

/// @function ApplyEdgeDetectionCommandToStack
/// @brief Apply an edge-detection command to the active image stack.
/// @param grfName (optional) Name of the graph window.
/// @returns Igor status code; zero indicates success and nonzero values report failure or cancellation.
static Function ApplyEdgeDetectionCommandToStack([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	if(WaveDims(wRef) != 3 || DimSize(wRef, 2) == 1)
		return 1
	endif
	string cmd 
	Prompt cmd, "Paste edge detection command"
	DoPrompt "Edge detection 3D", cmd
	if(V_flag || !strlen(cmd))
		return -1
	endif
	ATH_DFR#BackupWaveInWaveDF(wRef)
	ATH_ImgOp#ImageEdgeDetectionToStack(wRef, cmd, overwrite = 1)
	return 0
End

/// @function ImageFilter3D
/// @brief Apply a selected matrix filter to every layer of an image stack.
/// @param grfName (optional) Name of the graph window.
/// @returns Zero after completing the operation.
static Function ImageFilter3D([string grfName])
	// Implement it here and add it to the menu
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	
	string msg = "Image filter 3D"
	variable method = 1, size = 3,  passes = 1, overwrite = 2
	Prompt method, "Filtering method", popup, "gauss;avg;median;max;min" // gauss == 1
	Prompt size, "Size"
	Prompt passes, "Passes"
	Prompt overwrite, "Overwrite", popup, "Yes;No" // Yes = 1, No = 2!	
	DoPrompt msg, method, size, passes, overwrite
	if(V_flag)
		return 0
	endif
	string applyMethod = StringFromList(method,"dummy;gauss;avg;median;max;min")
	
	if(overwrite-2)
		ATH_DFR#BackupWaveInWaveDF(wRef) // backup the wave
	endif
	
	if(WaveDims(wRef) == 2) // Deal with 2D waves here
		DFREF saveDF = GetWavesDataFolderDFR(wRef)
		string noteStr = "Applied MatrixFilter/N="+num2str(size)+"/P="+num2str(passes)+ " " + applyMethod + " " + NameofWave(wRef)
		if(overwrite-2)
			MatrixFilter/N=(size)/P=(passes) $applyMethod wRef
			ATH_String#WaveLogging(wRef, noteStr, prepend=1)
		else
			string newWaveNameStr = CreateDataObjectName(saveDF, NameofWave(wRef) + "_filter", 1, 0, 1)
			Duplicate wRef, saveDF:$newWaveNameStr
			MatrixFilter/N=(size)/P=(passes) $applyMethod saveDF:$newWaveNameStr
			ATH_String#WaveLogging(saveDF:$newWaveNameStr, noteStr, prepend=1)
		endif
	endif
	ATH_ImgOp#ImageFilter3D(wRef, applyMethod, size, passes, overwrite = overwrite-2)
	return 0
End


/// @function ImageSmooth3D
/// @brief Smooth every layer of an image stack.
/// @param grfName (optional) Name of the graph window.
/// @returns Igor status code; zero indicates success and nonzero values report failure or cancellation.
static Function ImageSmooth3D([string grfName])
	// Loess image smoothing
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	
	string msg = "Image Smoothing (Loess)"
	variable radius = 1.5, order = 3,  extrapolate = 2, robust = 2, passes = 4, overwrite = 1
	Prompt radius, "Radius r (npts ~ π * r^2)"
	Prompt order, "Order",  popup, "Constant;Lowess;Loess"  // 0->1, 1->2, 2->3	
	Prompt passes, "Passes"		
	Prompt extrapolate, "Extrapolate", popup, "Yes;No"  // Yes = 1, No = 2!	
	Prompt robust, "Robust", popup, "Yes;No"  // Yes = 1, No = 2!	
	Prompt overwrite, "Overwrite", popup, "Yes;No" // Yes = 1, No = 2!	
	DoPrompt msg, radius, order, passes, extrapolate, robust, overwrite
	if(V_flag)
		return 0
	endif
	variable npts = floor(pi*radius^2)
	variable totalPnts = numpnts(wRef)
	npts = npts > totalPnts ? npts : npts
	
	// Filter parameters
	
	if(overwrite-2)
		ATH_DFR#BackupWaveInWaveDF(wRef) // backup the wave
	endif	
	
	DFREF saveDF = GetWavesDataFolderDFR(wRef)
	string noteStr = "Applied Smoothing: Loess/NORM=0/N="+num2str(npts)+"/R="+num2str(robust-2)+"/E="+\
	num2str(extrapolate-2) + "/PASS="+num2str(passes) + "/ORD="+num2str(order-1) + " srcWave=" + GetWavesDataFolder(wRef,2)
	
	if(WaveDims(wRef) == 2) // Deal with 2D waves here
		DFREF saveDF = GetWavesDataFolderDFR(wRef)
		if(overwrite-2)
			Loess/NORM=0/N=(npts)/R=(robust-2)/E=(extrapolate-2)/PASS=(passes)/ORD=(order-1) srcWave=wRef
			ATH_String#WaveLogging(wRef, noteStr, prepend=1)
		else
			string newWaveNameStr = CreateDataObjectName(saveDF, NameofWave(wRef) + "_filter", 1, 0, 1)
			Duplicate wRef, saveDF:$newWaveNameStr
			Loess/NORM=0/N=(npts)/R=(robust-2)/E=(extrapolate-2)/PASS=(passes)/ORD=(order-1) srcWave=saveDF:$newWaveNameStr
			ATH_String#WaveLogging(saveDF:$newWaveNameStr, noteStr, prepend=1)
		endif
	elseif(WaveDims(wRef) == 3)
		string waveNameStr = ATH_ImgOp#MultiThreadLoess3D(wRef, npts, order-1, passes, extrapolate-2, robust-2, overwrite = overwrite-2)
		ATH_String#WaveLogging($waveNameStr, noteStr, prepend=1)
	else
		return -1
	endif
	return 0
End



/// @function SmoothWave
/// @brief Smooth the selected wave using user-provided settings.
/// @param grfName (optional) Name of the graph window.
/// @returns Zero after completing the operation.
static Function SmoothWave([string grfName])
	// The Smooth operation smooths the named waves using binomial (Gaussian) smoothing, 
	// boxcar (sliding average) smoothing, Savitzky-Golay (polynomial) smoothing, or 
	// running-median filtering.
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	
	string msg = "Smooth Wave"
	variable method = 1, SGorder = 1,  points = 3, percentile= 50, dim = -1, overwrite = 1
	Prompt method, "Smoothing method", popup, "Gauss;Sliding average;Polynomial;Running median" // gauss == 1
	Prompt points, "Points"
	Prompt SGorder, "Polynomial algorithm",  popup, "2;4"
	Prompt percentile, "Running median percentile"
	Prompt dim, "Operate (dim)"	
	Prompt overwrite, "Overwrite", popup, "Yes;No" // Yes = 1, No = 2!	
	DoPrompt msg, method, points, SGorder, percentile, dim, overwrite
	if(V_flag)
		return 0
	endif
	string commandStr = "Smooth " + StringFromList(method,"dummy; ;/B ;/S ;/M ")
	
	// Filter parameters
	
		
	if(dim >= 0)
		dim = dim > 4 ? -1 : dim
		commandStr += "/DIM="+num2str(dim) + " "
	endif
	
	if(method == 1) // box
		points = (points < 4) ? 3 : points
		commandStr += num2str(points)
	elseif(method == 2)
		points = (points < 2) ? 2 : points
		if(!mod(points,2))
			commandStr += "/EVEN "
		endif
		commandStr += num2str(points)
	elseif(method == 3)
		if(SGorder==1)
			points = points < 5 ? 5 : points
			points = points > 5 ? 25 : points
			commandStr += "=2 " + num2str(points)
		elseif(SGorder==2)
			points = points < 7 ? 7 : points
			points = points > 5 ? 25 : points
			commandStr += "=4 " + num2str(points)
		else
			Abort
		endif
	elseif(method == 4)
		points = points < 2 ? 2 : points
		points = points > 32767 ? 32767 : points
		percentile = (percentile > 0 && percentile < 100) ? percentile : 50
		if(percentile!=50)
			commandStr += "=0/MPCT="+num2str(percentile) // =0 to add to /M
		endif
		commandStr += " " + num2str(points)
	else
		Abort
	endif
	
	if(overwrite-2)
		ATH_DFR#BackupWaveInWaveDF(wRef) // backup the wave
	endif	
		
	DFREF saveDF = GetWavesDataFolderDFR(wRef)
	string noteStr = "Applied Smoothing: " + commandStr
	if(overwrite-2)
		Execute/P/Q (commandStr + ", " + GetWavesDataFolder(wRef,2))
		ATH_String#WaveLogging(wRef, noteStr, prepend=1)
	else
		string newWaveNameStr = CreateDataObjectName(saveDF, NameofWave(wRef) + "_smth", 1, 0, 1)
		Duplicate wRef, saveDF:$newWaveNameStr
		Execute/P/Q (commandStr + ", " + GetWavesDataFolder(saveDF:$newWaveNameStr,2))
		ATH_String#WaveLogging(saveDF:$newWaveNameStr, noteStr, prepend=1)
	endif
	
	return 0
End

static Function XMLDMapFit([string grfName])
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	
	string msg = "Fit XM(N)L map"
	variable firstAngle = -90, anglestep = 15, fastfit = 1, FoVRot = 0
	Prompt firstAngle, "First angle in stack (deg)"
	Prompt anglestep, "Angle step (deg)"
	Prompt fastfit, "Fast fit?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt FoVRot, "FoV rotation"
	DoPrompt msg, firstAngle, anglestep, fastfit, FoVRot
	if(V_flag)
		return 0
	endif
	if(FoVRot)
		firstAngle += FoVRot
	endif
	ATH_MagDom#FitXMLDMap(wRef, firstAngle = firstAngle, anglestep = anglestep, fastfit = fastfit)
	return 0
End

static Function InteractiveXMLDFitInpection([string grfName])
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	if(DimSize(wRef,2))
		return 1 // this is not the map
	endif
	// Extract the parameters
	string noteStr = note(wRef), sourceStr
	string firstAngleStr, angleStepStr
	SplitString/E="firstAngle\\s*=\\s*([^,]+)" noteStr, firstAngleStr
	SplitString/E="angleStep\\s*=\\s*([^,]+)" noteStr, angleStepStr
	variable firstAngle = str2num(firstAngleStr)
	variable angleStep = str2num(angleStepStr)
	//Launch here
	ATH_MagDom#InteractiveXMLDFitInspection(wRef, firstAngle = firstAngle, angleStep = angleStep)
	return 0
End