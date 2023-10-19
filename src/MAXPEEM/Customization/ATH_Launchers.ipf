#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

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

// Launchers

Function ATH_LaunchMake3DWaveUsingPattern()
	string wname3dStr, pattern
	[wname3dStr, pattern] = ATH_GenericDoubleStrPrompt("Stack name","Match waves (use * wildcard)", "Make a stack from waves using a pattern")
	
	ATH_Make3DWaveUsingPattern(wname3dStr, pattern)
End

Function ATH_LaunchMake3DWaveDataBrowserSelection([variable displayStack])
	displayStack = ParamIsDefault(displayStack) ? 0: displayStack // Give any non-zero to display the stack
	string wname3dStr
	wname3dStr = ATH_Make3DWaveDataBrowserSelection("ATH_stack", gotoFilesDFR = 0) // 0 - stack in cwd 1 - stack in files DFR
	// Do you want to display the stack?
	if(displayStack && strlen(wname3dStr)) // wname3dStr = "" when you select no or one wave
		ATH_DisplayImage($wname3dStr)
	else
		return 1
	endif
	return 0
End

Function ATH_LauncherLoadDATFilesFromFolder()
	string wNameStr = ATH_GenericSingleStrPrompt("Stack name, empty string to auto-name", "Before the selection dialog opens...")
	if(strlen(wNameStr))
		ATH_LoadDATFilesFromFolder("", "*", stack3d = 1, wname3d = wNameStr, autoscale = 1)
	else
		// default name, if wname3d is given, even if empty string, the ParamIsDefault will give 1.
		// wname3d = SelectString(ParamIsDefault(wname3d) ? 0: 1,"stack3d", wname3d)
		ATH_LoadDATFilesFromFolder("", "*", stack3d = 1, autoscale = 1) 
	endif
End

Function ATH_LauncherLoadHDF5GroupsFromFile()
	string selectedGroups = ATH_GenericSingleStrPrompt("Use single ScanID and/or ranges, e.g.  \"2-5,7,9-12,50\".  Leave string empty to load all entries.", "Before the .h5 selection dialog opens...")
	if(strlen(selectedGroups))
		ATH_LoadHDF5SpecificGroups(selectedGroups)
	else
		ATH_LoadHDF5File()
	endif
End

Function ATH_LaunchAverageStackToImageFromMenu()
	string waveListStr = Wavelist("*",";","DIMS:3"), selectWaveStr, waveNameStr
	string strPrompt1 = "Select stack"
	string strPrompt2 = "Enter averaged wave nane (leave empty for ATH_AvgStack)"
	string msgDialog = "Average a stack (3d wave) in working DF"
	[selectWaveStr, waveNameStr] = ATH_GenericSingleStrPromptAndPopup(strPrompt1, strPrompt2, waveListStr, msgDialog)
	if(!strlen(waveNameStr))
		ATH_AverageStackToImage($selectWaveStr)
	else
		ATH_AverageStackToImage($selectWaveStr, avgImageName = waveNameStr)
	endif
	KillWaves/Z M_StdvImage
End

Function ATH_LaunchAverageStackToImageFromTraceMenu()
	WAVE/Z w3dref = ATH_TopImageToWaveRef()
	if(!DimSize(w3dref, 2))
		Abort "Operation needs a stack"
	endif
	string strPrompt = "Averaged wave nane (leave empty for ATH_AvgStack)"
	string msgDialog = "Average stack along z"
	string waveNameStr
	waveNameStr = ATH_GenericSingleStrPrompt(strPrompt, msgDialog)
	if(!strlen(waveNameStr))
		ATH_AverageStackToImage(w3dref)
	else
		ATH_AverageStackToImage(w3dref, avgImageName = waveNameStr)
	endif
	KillWaves/Z M_StdvImage
End

Function ATH_LaunchAverageStackToImageFromBrowserMenu()
	string bufferStr, wavenameStr
	if(ATH_CountSelectedWavesInDataBrowser(waveDimemsions = 3) == 1\
	 && ATH_CountSelectedWavesInDataBrowser() == 1) // If we selected a single 3D wave
		string selected3DWaveStr = GetBrowserSelection(0)
		WAVE w3dRef = $selected3DWaveStr	
	else
		Abort "Operation needs an image stack (3d wave)"
	endif

//	string strPrompt = "Averaged wave nane (leave empty for ATH_AvgStack)"
//	string msgDialog = "Average stack along z"
//	string waveNameStr
//	waveNameStr = ATH_GenericSingleStrPrompt(strPrompt, msgDialog)
//	if(!strlen(waveNameStr))
//		ATH_AverageStackToImage(w3dref)
//	else
//		ATH_AverageStackToImage(w3dref, avgImageName = waveNameStr)
//	endif
	// Changed and we give a unique name with an WaveName_avg suffix
	DFREF cdfr = GetDataFolderDFR()
	bufferStr = NameOfWave(w3dRef) + "_avg"
	waveNameStr = CreateDataObjectName(cdfr, bufferStr, 1, 0, 1)
	ATH_AverageStackToImage(w3dref, avgImageName = waveNameStr)
	KillWaves/Z M_StdvImage
End

Function ATH_LaunchRegisterQCalculateXRayDichroism()
	string msg = "Select two waves for XMC(L)D calculation. Use Ctrl (Windows) or Cmd (Mac)."
	string selectedWavesInBrowserStr = ATH_SelectWavesInModalDataBrowser(msg)
	
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
	string selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
	if(nrSelectedWaves != 2)
		DoAlert/T="MAXPEEM would like you to know" 1, "Select two (2) .dat files only.\n" + \
				"Do you want a another chance with the browser selection?"
		if(V_flag == 1)
			ATH_LaunchRegisterQCalculateXRayDichroism()
		elseif(V_flag == 2)
			Abort
		else
			print "ATH_RegisterQCalculateXRayDichroism()! Abormal behavior."
		endif
		
		Abort // Abort the running instance otherwise the code that follows will run 
			  // as many times as the dialog will be displayed. Equavalenty, it can 
			  // be placed in the if (V_flag == 1) branch.
	endif
	string wave1Str = StringFromList(0, selectedWavesStr) // The last dat has been eliminated when importing waves, so we are ok
	string wave2Str = StringFromList(1, selectedWavesStr)
	WAVE wimg1 = $wave1Str
	WAVE wimg2 = $wave2Str
	
	if(WaveDims(wimg1) != 2 || WaveDims(wimg2) != 2)
		Abort "Operation need two images"
	endif	
	string selectedWavesPopupStr = wave1Str + ";" + wave2Str
	variable registerImageQ
	string saveWaveName = ""
	//Set defaults 
	Prompt wave1Str, "img1", popup, selectedWavesPopupStr
	Prompt wave2Str, "img2", popup, selectedWavesPopupStr
	Prompt registerImageQ, "Automatic image registration?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt saveWaveName, "Name of the XMC(L)D wave (default: ATHxmcd)"
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1Str, wave2Str, registerImageQ, saveWaveName
	if(V_flag) // User cancelled
		return 1
	endif
	
	// Make a note for the XMC(L)D image
	string xmcdWaveNoteStr = "XMC(L)D = (img1 - img2)/(img1 + img2)\n"
	xmcdWaveNoteStr += "img1: "
	xmcdWaveNoteStr += note(wimg1)
	xmcdWaveNoteStr += "\n"
	xmcdWaveNoteStr += "\nimg2: "
	xmcdWaveNoteStr += note(wimg2)
	
	if(!(WaveType(wimg1) & 0x02))
		Redimension/S wimg1
	endif
	
	if(!(WaveType(wimg2) & 0x02))
		Redimension/S wimg2
	endif 
	
	Duplicate/FREE wimg2, wimg2copy
	if(registerImageQ == 1)
		ATH_ImageAlignmentByRegistration(wimg1, wimg2copy)
	endif
	if(!strlen(saveWaveName))
		saveWaveName = "ATHxmcd"
	endif
	ATH_CalculateXMCD(wimg1, wimg2copy, saveWaveName)
	// if you use /P, the dimension scaling is copied in slope/intercept format 
	// so that if srcWaveName  and the other waves have differing dimension size 
	// (number of points if the wave is a 1D wave), then their dimension values 
	// will still match for the points they have in common
	CopyScales wimg1, $saveWaveName 
	Note/K $saveWaveName, xmcdWaveNoteStr
	return 0
End

Function ATH_LaunchCalculateXMCDFromStack()
	WAVE/Z w3dref = ATH_TopImageToWaveRef()
	if(DimSize(w3dref,2) != 2)
		Abort "A stack with two layers in needed"
	endif
	MatrixOP/O/FREE w1free = layer(w3dref, 0)
	MatrixOP/O/FREE w2free = layer(w3dref, 1)
	string xmcdWaveStr = NameofWave(w3dref) + "_xmcd"
	ATH_CalculateXMCD(w1free, w2free, xmcdWaveStr)
	// if you use /P, the dimension scaling is copied in slope/intercept format 
	// so that if srcWaveName  and the other waves have differing dimension size 
	// (number of points if the wave is a 1D wave), then their dimension values 
	// will still match for the points they have in common
	CopyScales w3dref, $xmcdWaveStr 
	ATH_DisplayImage($xmcdWaveStr)
End

Function ATH_DialogLoadTwoImagesAndRegisterQ()

	variable numRef
	string fileFilters = "dat File (*.dat):.dat;"
	fileFilters += "All Files:.*;"
	string msgStr = "Select two images for XMC(L)D calculation."
	Open/D/R/MULT=1/M=msgStr/F=fileFilters numRef
	if(!strlen(S_filename))//If you cancel, i.e nothing selected.
		return 1
	endif
	if(ItemsInList(S_filename, "\r") != 2)
		Abort "Select exactly two .dat files"
	endif

	WAVE wimg1 = ATH_WAVELoadSingleDATFile(StringFromList(0,S_filename, "\r"), "",  autoscale = 1)
	WAVE wimg2 = ATH_WAVELoadSingleDATFile(StringFromList(1,S_filename, "\r"), "",  autoscale = 1)
	
	if(WaveType(wimg1) & 0x10) // If WORD (int16)
		Redimension/S wimg1
	endif

	if(WaveType(wimg2) & 0x10) // If WORD (int16)
		Redimension/S wimg2
	endif
	string wave1Str = NameOfWave(wimg1)	
	string wave2Str = NameOfWave(wimg2)
	string selectedFilesPopupStr = wave1Str + ";" + wave2Str
	variable registerImageQ = 2 // Default: Yes
	string saveWaveName = ""
	//Set defaults 
	Prompt wave1Str, "img1", popup, selectedFilesPopupStr
	Prompt wave2Str, "img2", popup, selectedFilesPopupStr
	Prompt registerImageQ, "Automatic image registration?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt saveWaveName, "Name of the image stack (default: ATH_XMCD_stk)"
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1Str, wave2Str, registerImageQ, saveWaveName
	if(V_flag) // User cancelled
		return 1
	endif
		
	if(registerImageQ == 1)
		ATH_ImageAlignmentByRegistration(wimg1, wimg2) // NB: wimg2 is overwritten here
	endif
	
	if(!strlen(saveWaveName))
		// We need a unique wave name
		DFREF currDF = GetDataFolderDFR()
		saveWaveName = CreatedataObjectName(currDF, "ATH_XMCD_stk", 1, 0, 1)
	endif
	variable nrows = DimSize(wimg1, 0)
	variable ncols = DimSize(wimg1, 1)	
	Make/N=(nrows, ncols, 2) $saveWaveName
	CopyScales wimg1, $saveWaveName
	WAVE w3d = $saveWaveName
	w3d[][][0] = wimg1[p][q]
	w3d[][][1] = wimg2[p][q]
	KillWaves wimg1, wimg2
	ATH_DisplayImage(w3d)
	return 0
End

Function ATH_LaunchCalculationXMCD3D()
	string msg = "Select two 3d waves for XMC(L)D calculation. Use Ctrl (Windows) or Cmd (Mac)."
	string selectedWavesInBrowserStr = ATH_SelectWavesInModalDataBrowser(msg)
	
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
	string selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
	if(nrSelectedWaves != 2)
		DoAlert/T="MAXPEEM would like you to know" 1, "Select two (2) 3d waves only.\n" + \
				"Do you want a another chance with the browser selection?"
		if(V_flag == 1)
			ATH_LaunchCalculationXMCD3d()
		elseif(V_flag == 2)
			Abort
		else
			print "ATH_LaunchCalculationXMCD3d(). Abormal behavior."
		endif
		
		Abort // Abort the running instance otherwise the code that follows will run 
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
	ATH_CalculateXMCD3D(w3d1, w3d2)
	return 0
End

Function ATH_LaunchImageStackAlignmentFullImage()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // ATH_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable convMode = 1
	variable printMode = 2
	variable layerN = 0
	variable edgeAlgo = 0	
	variable histEq = 2	
	variable windowing = 0
	variable algo = 1
	variable normalise = 2
	variable cutoff = 0
	string msg = "Align " + imgNameTopGraphStr + " using the full image."
	Prompt algo, "Method", popup, "Registration (sub-pixel); Correlation (pixel)"
	Prompt layerN, "Reference layer"
	Prompt normalise, "Normalise range [0, 1]?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt edgeAlgo, "Edge detection method", popup, "None;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei"
	Prompt histEq, "Apply histogram equalization?", popup, "Yes;No" // Yes = 1, No = 2!	
	Prompt convMode, "Convergence (Registration only)", popup, "Gravity (fast); Marquardt (slow)"
	Prompt windowing, "Windowing", popup, "None;Hanning;Hamming;Bartlett;Blackman"
	Prompt cutoff, "Cutoff drift (pixels) "	
	Prompt printMode, "Print layer drift", popup, "Yes;No" // Yes = 1, No = 2!
	DoPrompt msg, algo, layerN, normalise, edgeAlgo, histEq, convMode, windowing, cutoff, printMode
	
	if(V_flag) // User cancelled
		return -1
	endif
	
	string backupWavePathStr = ATH_BackupWaveInWaveDF(w3dref)
	int switchWaveCopy = 0
	if(normalise == 1)
		ATH_ScalePlanesBetweenZeroAndOne(w3dRef)
		switchWaveCopy = 1
	endif

	if(histEq == 1)
		ImageHistModification/O/I w3dref
		switchWaveCopy = 1
	endif	
	
	if(windowing > 1)
		string windowingMethods = "None;Hanning;Hamming;Bartlett;Blackman" // Prompt first item returns 1!
		string applywindowingMethods = StringFromList(windowing, windowingMethods)
		ATH_ImageWindow3D(w3dRef, applywindowingMethods)
		switchWaveCopy = 1
	endif
	if(edgeAlgo > 1)
		string edgeDetectionAlgorithms = "None;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei" // Prompt first item returns 1!
		string applyEdgeDetectionAlgo = StringFromList(edgeAlgo, edgeDetectionAlgorithms)
		ATH_ImageEdgeDetectionToStack(w3dref, applyEdgeDetectionAlgo, overwrite = 1)
		switchWaveCopy = 1	
	endif
	if(algo == 1)
		if(switchWaveCopy)
			ATH_ImageStackAlignmentByRegistration(w3dRef, layerN = layerN, printMode = printMode - 2, convMode = convMode - 1,\
			selfDrift = 0, cutoff = cutoff)
		else
			ATH_ImageStackAlignmentByRegistration(w3dRef, layerN = layerN, printMode = printMode - 2, convMode = convMode - 1)
		endif
	elseif(algo == 2)
		if(switchWaveCopy)
			ATH_ImageStackAlignmentByCorrelation(w3dRef, layerN = layerN, printMode = printMode - 2, \
			selfDrift = 0, cutoff = cutoff)
		else
			ATH_ImageStackAlignmentByCorrelation(w3dRef, layerN = layerN, printMode = printMode - 2, cutoff = cutoff)
		endif
	else 
		Abort "Please check ATH_LaunchImageStackAlignmentFullImage(), method error."
	endif
	//Restore the note
	string copyNoteStr = note($backupWavePathStr)
	Note/K w3dref,copyNoteStr
End


Function ATH_LaunchImageStackAlignmentPartition()
	///
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // ATH_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable method = 1
	variable printMode = 2
	variable layerN = 0
	variable histEq = 2
	variable edgeAlgo = 1
	variable filter = 1
	variable filterN = 3	
	variable nrTimes = 1
	variable normalise = 2
	variable cutoff = 0
	string msg = "Align " + imgNameTopGraphStr + " using part of the image."
	
	Prompt method, "Method", popup, "Registration (sub-pixel); Correlation (pixel)" // Registration = 1, Correlation = 2
	Prompt layerN, "Reference layer"
	Prompt filter, "Apply filter", popup, "None;gauss;avg;median;max;min" // gauss = 2
	Prompt filterN, "Filter N = 3 ... 15 (odd N is better)"	
	Prompt nrTimes, "Apply filter 1...5 times"	
	Prompt normalise, "Normalise range [0, 1]?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt histEq, "Apply histogram equalization?", popup, "Yes;No" // Yes = 1, No = 2!	
	Prompt edgeAlgo, "Edge detection method", popup, "None;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei"
	Prompt cutoff, "Cutoff drift (pixels) "
	Prompt printMode, "Print layer drift", popup, "Yes;No" // Yes = 1, No = 2!
	
	DoPrompt msg, method, layerN, filter, filterN, nrTimes, normalise, histEq, edgeAlgo, cutoff, printMode
	if(V_flag) // User cancelled
		return -1
	endif
	
	string backupWavePathStr = ATH_BackupWaveInWaveDF(w3dref)

	variable left, right, top, bottom

	STRUCT sUserMarqueePositions s
	[left, right, top, bottom] = ATH_UserGetMarqueePositions(s)
	DFREF currDFR = GetDataFolderDFR()
	string partitionWaveStr =  CreatedataObjectName(currDFR, "ATH_DRFCorr_partition", 1, 0, 0)
	ATH_WavePartition(w3dref, partitionWaveStr, left, right, top, bottom, evenNum = 1)
	WAVE partitionWave = $partitionWaveStr

	if(filter > 1)
		if(nrTimes > 5)
			nrTimes = 5
		elseif(nrTimes < 1)
			nrTimes = 1
		endif
		if(filterN < 3)
			filterN = 3
		elseif(filterN > 15)
			filterN = 15
		endif
		string filterStr = StringFromList(filter, "None;gauss;avg;median;max;min")
		ATH_MatrixFilter3D(partitionWave, filterStr, filterN, nrTimes)
	endif

	if(histEq == 1)
		ImageHistModification/O/I partitionWave
	endif
	
	if(normalise == 1)
		ATH_ScalePlanesBetweenZeroAndOne(partitionWave)
	endif

	// Edge detection is applied last
	if(edgeAlgo > 1)
		string edgeDetectionAlgorithms = "dummy;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei" // Prompt first item returns 1!
		string applyEdgeDetectionAlgo = StringFromList(edgeAlgo, edgeDetectionAlgorithms)
		ATH_ImageEdgeDetectionToStack(partitionWave, applyEdgeDetectionAlgo, overwrite = 1)
	endif
	
	if(method == 1)
		ATH_ImageStackAlignmentByPartitionRegistration(w3dRef, partitionWave, layerN = layerN, printMode = printMode - 2, cutoff = cutoff)
	elseif(method == 2)
		ATH_ImageStackAlignmentByPartitionCorrelation(w3dRef, partitionWave, layerN = layerN, printMode = printMode - 2, cutoff = cutoff)
	else
		Abort "Please check ATH_LaunchImageStackAlignmentUsingAFeature(), method error."
	endif
	//Restore the note, here backup wave exists or it have been created above, chgeck: if(!WaveExists($backupWave))
	string copyNoteStr = note($backupWavePathStr)
	KillWaves partitionWave
	Note/K w3dref,copyNoteStr
End

Function ATH_LaunchLinearImageStackAlignmentUsingABCursors()
	// Use AB to linearly correct an image stack drift
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // ATH_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable nlayers = DimSize(w3dref, 2)
	
	if(nlayers < 3)
		return -1
	endif
	
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0,30000)/P A $imgNameTopGraphStr 0.25, 0.5
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0,30000)/P B $imgNameTopGraphStr 0.75, 0.5
	variable slope, shift
	
	string backupWavePathStr = ATH_BackupWaveInWaveDF(w3dref)	
	
	variable x0, y0, x1, y1
	STRUCT sUserCursorPositions s
	[x0, y0, x1, y1] = ATH_UserGetABCursorPositions(s)
	[slope, shift] = ATH_LineEquationFromTwoPoints(x0, y0, x1, y1)
	
	
	//WAVE/Z wx, wy // x, y drifts for each layer
	[WAVE wx, WAVE wy] = ATH_XYWavesOfLineFromTwoPoints(x0, y0, x1, y1, nlayers)
	wx -= x0 // Relative xshift
	wy -= y0 // Relative yshift
	// ImageInterpolate needs pixels, multiply by -1 to have the proper behavior in /ARPM={...}
	variable dx = DimDelta(w3dref, 0) ; variable dy = DimDelta(w3dref, 1)
	wx /= (-dx) ; wy /= (-dy)
	ATH_LinearDriftCorrectionUsingABCursors(w3dref, wx, wy)
	return 0
End

// ---- ///

Function ATH_LaunchNewImageFromBrowserSelection()
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
		
		ATH_DisplayImage($ATHImage)
		i++
	while (strlen(GetBrowserSelection(i)))
End

Function ATH_LaunchImageBackupFromBrowserSelection()
	string ATHImage = GetBrowserSelection(0)
	if(WaveDims($ATHImage) != 3 && WaveDims($ATHImage) != 2)
		Abort "Operation needs an image or image stack"
	endif
	ATH_RestoreTopImageFromBackup(wname = ATHImage)
	return 0
End

// -------

Function ATH_LaunchNormalisationImageStackWithImage()
		
	if(ATH_CountSelectedWavesInDataBrowser(waveDimemsions=3) != 1)
		Abort "Please select an image stack (3d wave)"
	endif
	string wave3dStr = StringFromList(0, GetBrowserSelection(0))
	WAVE w3dRef = $wave3dStr
	string imageNameStr = StringFromList(0, ATH_SelectWavesInModalDataBrowser("Select an image (2d wave) for normalisation"))
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
	ATH_NormaliseImageStackWithImage(w3dRef, imageWaveRef)
End

Function ATH_LaunchNormalisationImageStackWithProfile()
	
	if(ATH_CountSelectedWavesInDataBrowser(waveDimemsions=3) != 1)
		Abort "Please select an image stack (3d wave)"
	endif
	string wave3dStr = StringFromList(0, GetBrowserSelection(0))
	WAVE w3dRef = $wave3dStr
	string selectProfileStr = StringFromList(0, ATH_SelectWavesInModalDataBrowser("Select a profile (1d wave) for normalisation"))
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
	ATH_NormaliseImageStackWithProfile(w3dRef, profWaveRef)
End

Function ATH_LaunchNormalisationImageStackWithImageStack()

	if(ATH_CountSelectedWavesInDataBrowser(waveDimemsions=3) != 1)
		Abort "Please select an image stack (3d wave)"
	endif
	string wave3d1Str = StringFromList(0, GetBrowserSelection(0))
	WAVE w3d1Ref = $wave3d1Str
	string wave3d2Str = StringFromList(0, ATH_SelectWavesInModalDataBrowser("Select an image stack (3d wave) for normalisation"))
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
	string promptStr = "0 : Use first layer (default if nothing set)\nn1-n2 : Use  n1, ..., n2 layers (average), \n-1 : Layer by layer in 3d waves (in case of layer number"+\
					   " operation will continue based on defaults of Igor pro)\n" +\
					   " NB: zero-based layer indexing."
	string inputStr = ATH_GenericSingleStrPrompt(promptStr, "How many layers would you like to use for Normalisation?")
	string rangeStr = ATH_ExpandRangeStr(inputStr)
	string normWaveStr = wave3d1Str + "_norm"
	variable nLayer, minLayer, maxLayer, totLayers
	if(!strlen(inputStr) || (ItemsInList(rangeStr) == 1 && !cmpstr(StringFromList(0, rangeStr), "0")))
		nLayer = str2num(StringFromList(0, rangeStr))
		MatrixOP/O/FREE normLayerFree= layer(w3d2Ref, 0)
		normWaveStr = wave3d1Str + "_norm"
		MatrixOP/O $normWaveStr = w3d1Ref/normLayerFree
	elseif(ItemsInList(rangeStr) == 1 && !cmpstr(StringFromList(0, rangeStr), "-1"))
		MatrixOP/O $normWaveStr = w3d1Ref/w3d2Ref
	else
		totLayers = ItemsInList(rangeStr)
		minLayer = str2num(StringFromList(0,rangeStr))
		maxLayer = str2num(StringFromList(totLayers-1,rangeStr))
		if(minLayer < 0 || maxLayer > totLayers - 1)
		endif
		MatrixOP/O/FREE getWaveLayersFree = w3d2Ref[][][minLayer, maxLayer]
		MatrixOP/O/FREE normLayerFree = sumBeams(getWaveLayersFree)/(maxLayer - minlayer + 1) 
		MatrixOP/O $normWaveStr = w3d1Ref / normLayerFree
	endif
	
End

Function ATH_LaunchRemoveImagesFromImageStack()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable startLayer, nrLayers
	if(WaveDims(w3dref) == 3 && DataFolderExists("root:Packages:WM3DImageSlider:" + winNameStr))
		NVAR glayer = root:Packages:WM3DImageSlider:$(winNameStr):gLayer
		startLayer = glayer
	else
		return -1
	endif
	nrLayers = ATH_GenericSingleVarPrompt("How many layers you want to remove (start from top image)?", "ATH_RemoveImagesFromImageStack")
	if(nrLayers)
		ATH_RemoveImagesFromImageStack(w3dref, startLayer, nrLayers)
		ATH_RestartWM3DImageSlider(winNameStr)
	endif
	return 0
End

Function ATH_LaunchStackImagesToImageStack()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string selectImagesStr = ATH_SelectWavesInModalDataBrowser("Select image(s) (2d, 3d waves) to append to image(stack)"), imageStr
	variable imagesNr = ItemsInList(selectImagesStr), i
	
	if(!ItemsInList(selectImagesStr))
		return 1
	endif
	if(!ATH_AppendImagesToImageStack(w3dref, selectImagesStr))
		ATH_RestartWM3DImageSlider(winNameStr)
	endif	
	return 0
End

Function ATH_LaunchInsertImageToStack()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable layerN
	if(WaveDims(w3dref) == 3 && DataFolderExists("root:Packages:WM3DImageSlider:" + winNameStr))
		NVAR glayer = root:Packages:WM3DImageSlider:$(winNameStr):gLayer
		layerN = glayer
	else
		return -1
	endif
	string selectImagesStr = ATH_SelectWavesInModalDataBrowser("Select one image to insert to stack."), imageStr
	imageStr = StringFromList(0, selectImagesStr)
	if(!strlen(imageStr))
		return 1
	endif
	WAVE w2dref = $imageStr
	variable wType = WaveType(w3dref)
	if(wType == WaveType(w2dref))
		ATH_InsertImageToImageStack(w3dref, w2dref, layerN)
	else
		ATH_MatchWaveTypes(w3dref, w2dref)
		ATH_InsertImageToImageStack(w3dref, w2dref, layerN)
	endif
	ATH_RestartWM3DImageSlider(winNameStr)
	return 0	

End

Function ATH_LaunchImageRemoveBackground()
	WAVE wRef = ATH_TopImageToWaveRef()
	ATH_ImageRemoveBackground(wRef)
End

Function ATH_LaunchRotate3DWaveAxes()
	WAVE/Z wRef = ATH_TopImageToWaveRef()
	if(WaveDims(wRef) !=3)
		Abort "Operation needs a 3d wave (image stack)!"
	endif
	variable num = 0
	string modeStr = "XZY;ZXY;ZYX;YZX;YXZ"
	Prompt num, "Select axes rotation", popup, modeStr 
	DoPrompt "Rotate 3d wave axes",num
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
	CopyScales/P srcDFR:$wnameStr, dfr:$newwaveNameStr
	Note $newwaveNameStr, noteStr
End

Function ATH_LaunchImageRotateAndScale()
	/// Rotated/scaled wave in created in the working dfr.
	WAVE/Z wRef = ATH_TopImageToWaveRef()
	variable angle = ATH_GenericSingleVarPrompt("Angle (deg)", "Image rotate and scale")
	if(WaveExists(wRef))
		ATH_ImageRotateAndScale(wRef, angle)
	endif
	return 0
End

Function ATH_LaunchImageRotateAndScaleFromMetadata()
	/// Rotated/scaled wave in created in the working dfr.
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	
	if(!strlen(imgNameTopGraphStr))
		//print "No image in top graph!"
		return -1
	endif
	
	WAVE wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable angle = NumberByKey("FOVRot(deg)", note(wRef), ":", "\n")
	ATH_ImageBackupRotateAndScale(wRef, angle)
End


Function ATH_LaunchImageFFTTransform()
	// FFT of the top image
	WAVE/Z wRef = ATH_TopImageToWaveRef()
	if(WaveExists(wRef))
		ATH_2DFFT(wRef)
		WAVE wREF_FFT = $(NameOfWave(wRef) + "_FFT")
		ATH_DisplayImage(wREF_FFT)
	endif
	
End

Function ATH_LaunchScalePlanesBetweenZeroAndOne()
	WAVE wRef = ATH_TopImageToWaveRef() 
	// If you have 2D do it fast here and return
	if(WaveDims(wRef) == 2)
		ImageTransform/O scalePlanes wRef
		return 0
	endif
	ATH_ScalePlanesBetweenZeroAndOne(wRef)
	print NameOfWave(wRef) + " scaled to [0, 1]"
	ATH_AutoRangeTopImage() // Autoscale the image
	return 0
End

Function ATH_LaunchAverageLayersRange()
	WAVE/Z wRef = ATH_TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveDims(wRef) == 0) //  WaveDims(wRef) == 0 when wRef is NULL
		print "ATH_LaunchAverageLayersRange() needs an image stack in top graph."
		return -1
	endif
	string rangeStr = ATH_GenericSingleStrPrompt("Enter range as e.g. 3-7 or 7,11. First layer is 0!", "Average image range")
	string sval1, sval2, separatorStr
	SplitString/E="\s*([0-9]+)\s*(-|,)\s*([0-9]+)" rangeStr, sval1, separatorStr, sval2
	ATH_AverageImageRangeToStack(wRef, str2num(sval1), str2num(sval2))
End

Function ATH_LaunchExtractLayerRangeToStack()

	WAVE/Z wRef = ATH_TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveDims(wRef) == 0) //  WaveDims(wRef) == 0 when wRef is NULL
		print "ATH_LaunchExtractLayersToStack() needs an image stack in top graph."
		return -1
	endif
	string rangeStr = ATH_GenericSingleStrPrompt("Enter range as e.g. 3-7 or 7,11. First layer is 0!", "Average image range")
	string sval1, sval2, separatorStr
	SplitString/E="\s*([0-9]+)\s*(-|,)\s*([0-9]+)" rangeStr, sval1, separatorStr, sval2
	ATH_ExtractLayerRangeToStack(wRef, str2num(sval1), str2num(sval2))
End

Function ATH_LaunchSumImagePlanes()

	WAVE/Z wRef = ATH_TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveDims(wRef) == 0) //  WaveDims(wRef) == 0 when wRef is NULL
		print "ATH_LaunchSumImagePlanes() needs an image stack in top graph."
		return -1
	endif
	DFREF dfr = GetDataFolderDFR()
	ImageTransform sumPlanes wRef
	WAVE M_SumPlanes
	string basenameStr = NameOfWave(wRef) + "sum"
	string sumPlanesNameStr = CreatedataObjectName(dfr, basenameStr, 1, 0, 1)
	Duplicate M_SumPlanes, $sumPlanesNameStr
	CopyScales wRef, $sumPlanesNameStr
	KillWaves/Z M_SumPlanes
	return 0
End

Function ATH_LaunchAverageImagePlanes()

	WAVE/Z wRef = ATH_TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveDims(wRef) == 0 || !DimSize(wRef,2) > 2) //  WaveDims(wRef) == 0 when wRef is NULL
		print "ATH_LaunchAverageImagePlanes() needs an image stack with at least three layers in the top graph."
		return -1
	endif
	DFREF dfr = GetDataFolderDFR()
	ImageTransform averageImage wRef // At least three layers!
	WAVE M_AveImage
	string basenameStr = NameOfWave(wRef) + "_avg"
	string avgPlanesNameStr = CreatedataObjectName(dfr, basenameStr, 1, 0, 1)
	Duplicate M_AveImage, $avgPlanesNameStr
	CopyScales wRef, $avgPlanesNameStr
	KillWaves/Z M_StdvImage, M_AveImage
End

Function ATH_LaunchHistogramShiftToGaussianCenter()
	WAVE/Z wRef = ATH_TopImageToWaveRef()
	ATH_HistogramShiftToGaussianCenter(wRef, overwrite=1)
End

Function ATH_LaunchQuickTextAnnotation()
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
	ATH_TextAnnotationOnTopGraph(textStr, fSize = fSize, color = color)
	return 0
End

Function ATH_LaunchMakeWaveFromSavedROI()
	WAVE wref = ATH_TopImageToWaveRef()
	ATH_MakeWaveFromROI(wRef)
End
