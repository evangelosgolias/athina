#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Launch
#pragma version = 1.01
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

// Launchers



static Function Make3DWaveUsingPattern()
	string wname3dStr, pattern
	[wname3dStr, pattern] = ATH_Dialog#GenericDoubleStrPrompt("Stack name","Match waves (use * wildcard)", "Make a stack from waves using a pattern")
	
	ATH_WaveOp#Make3DWaveUsingPattern(wname3dStr, pattern)
End

static Function Make3DWaveDataBrowserSelection([variable displayStack])
	displayStack = ParamIsDefault(displayStack) ? 0: displayStack // Give any non-zero to display the stack
	string wname3dStr = ATH_WaveOp#ConcatenateWavesInDataBrowserSelection("ATH_stack", autoPath = 1) // stack in sourcedir if all waves in the same folder, otherwise in cwd
	// Do you want to display the stack?
	if(displayStack && strlen(wname3dStr)) // wname3dStr = "" when you select no or one wave
		ATH_Display#NewImg($wname3dStr)
	else
		return 1
	endif
	return 0
End

static Function LoadHDF5GroupsFromFile()
	string selectedGroups = ATH_Dialog#GenericSingleStrPrompt("Use single ScanID and/or ranges, e.g.  \"2-5,7,9-12,50\".  Leave string empty to load all entries.", "Before the .h5 selection dialog opens...")
	if(strlen(selectedGroups))
		ATH_HDF5#LoadHDF5SpecificGroupsNamesIndexed(selectedGroups, strFix = "entry")
	else
		ATH_HDF5#LoadHDF5File() // Load all.
	endif
End

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

static Function AverageStackToImageFromBrowserMenu()
	string bufferStr, wavenameStr
	if(ATH_Dialog#CountSelectedWavesInDataBrowser(wDims = 3) == 1\
	 && ATH_Dialog#CountSelectedWavesInDataBrowser() == 1) // If we selected a single 3D wave
		string selected3DWaveStr = GetBrowserSelection(0)
		WAVE wRef = $selected3DWaveStr	
	else
		Abort "Operation needs an image stack (3d wave)"
	endif
	ATH_WaveOp#AverageImageStack(wRef)
End

static Function CalculateXMCDFromStack()
	WAVE/Z w3d = ATH_Graph#TopImageToWaveRef()
	if(!WaveExists(w3d))
		return 1
	endif
	string basename = NameofWave(w3d) + "_xmcd"
	DFREF dfr = GetWavesDataFolderDFR(w3d)
	DFREF saveDF = GetDataFolderDFR()
	string xmcdWaveStr = CreatedataObjectName(currDFR, basename, 1, 0, 1)
	SetDataFolder dfr
	if(ATH_Magnetism#StackToXMCD(w3d, wnameStr=xmcdWaveStr))
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
	ATH_Magnetism#CalculateXMCD(w2d1, w2d2, outWave = saveWaveName)
	string noteStr = "ATH_Magnetism#XMCD("+ wave1Str + ","+\
	wave2Str+", outWave=" + saveWaveName + ")"
	Note $saveWaveName, noteStr
	return 0
End

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
	ATH_Magnetism#CalculateXMCD3D(w3d1, w3d2)
	return 0
End

static Function ImageStackAlignmentFullImage([int backupWave])
	///
	backupWave = ParamIsDefault(backupWave) ? 1 : backupWave
	///
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif	
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // ATH_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable convMode = 1
	variable printMode = 2
	variable layerN = 0
	variable edgeAlgo = 0	
	variable histEq = 2	
	variable windowing = 0
	variable algo = 1
	variable cutoff = 0
	variable intPixels = 2
	string msg = "Align " + imgNameTopGraphStr + " using the full image."
	Prompt algo, "Method", popup, "Registration (sub-pixel); Correlation (pixel)"
	Prompt layerN, "Reference layer"
	Prompt edgeAlgo, "Edge detection method", popup, "None;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei"
	Prompt histEq, "Apply histogram equalization?", popup, "Yes;No" // Yes = 1, No = 2!	
	Prompt convMode, "Convergence (Registration only)", popup, "Gravity (fast); Marquardt (slow)"
	Prompt windowing, "Windowing", popup, "None;Hanning;Hamming;Bartlett;Blackman"
	Prompt intPixels, "Sub-pixel drift (Registation)",  popup, "Yes;No" // Yes = 1, No = 2!	
	Prompt cutoff, "Cutoff drift (pixels) "
	Prompt printMode, "Print layer drift", popup, "Yes;No" // Yes = 1, No = 2!
	DoPrompt msg, algo, layerN, edgeAlgo, histEq, convMode, windowing, cutoff, intPixels, printMode
	
	if(V_flag) // User cancelled
		return -1
	endif
	string driftCorrectionOriginalNoteStr = note(w3dRef), driftCorrectionNoteStr // Grab early the original wave note
	if(backupWave)
		ATH_DFR#BackupWaveInWaveDF(w3dref)
	endif
	int switchWaveCopy = 0

	if(histEq == 1)
		ImageHistModification/O/I w3dref
		switchWaveCopy = 1
	endif	
	
	if(windowing > 1)
		string windowingMethods = "None;Hanning;Hamming;Bartlett;Blackman" // Prompt first item returns 1!
		string applywindowingMethods = StringFromList(windowing, windowingMethods)
		ATH_ImgOp#ImageWindow3D(w3dRef, applywindowingMethods)
		switchWaveCopy = 1
	endif
	if(edgeAlgo > 1)
		string edgeDetectionAlgorithms = "None;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei" // Prompt first item returns 1!
		string applyEdgeDetectionAlgo = StringFromList(edgeAlgo, edgeDetectionAlgorithms)
		ATH_ImgOp#ImageEdgeDetectionToStack(w3dref, applyEdgeDetectionAlgo, overwrite = 1)
		switchWaveCopy = 1	
	endif
	if(algo == 1)
		if(switchWaveCopy)
			ATH_ImgAlign#ImgStackRegistration(w3dRef, layerN = layerN, printMode = printMode - 2, convMode = convMode - 1,\
			selfDrift = 0, cutoff = cutoff, intPixels = intPixels - 1)
		else
			ATH_ImgAlign#ImgStackRegistration(w3dRef, layerN = layerN, printMode = printMode - 2, convMode = convMode - 1,\
			intPixels = intPixels - 1)
		endif
	elseif(algo == 2)
		if(switchWaveCopy)
			ATH_ImgAlign#ImgStackCorrelation(w3dRef, layerN = layerN, printMode = printMode - 2, \
			selfDrift = 0, cutoff = cutoff)
		else
			ATH_ImgAlign#ImgStackCorrelation(w3dRef, layerN = layerN, printMode = printMode - 2, cutoff = cutoff)
		endif
	else 
		Abort "Please check ImageStackAlignmentFullImage(), method error."
	endif
	//Restore the note
	driftCorrectionNoteStr = "Drift correction using " + StringFromList(algo, "dummy;Registration;Correlation") + " with reference layer #"+num2str(layerN)+"\n"
	driftCorrectionNoteStr += "Apply histogram equalization: " + StringFromList(histEq, "dummy;Yes;No")+"\n"
	driftCorrectionNoteStr += "Edge detection method: " + StringFromList(edgeAlgo, "dummy;None;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei")+"\n"
	driftCorrectionNoteStr += "Sub-pixel corrections: " + StringFromList(intPixels, "dummy;Yes;No") + "\n"
	driftCorrectionNoteStr += "Cutoff drift (pixels): " + num2str(cutoff)+"\n\n" + driftCorrectionOriginalNoteStr
	Note w3dref,driftCorrectionNoteStr
End


static Function ImageStackAlignmentPartition([int backupWave])
	///
	backupWave = ParamIsDefault(backupWave) ? 1 : backupWave
	///
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // ATH_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable method = 2
	variable printMode = 2
	variable layerN = 0
	variable histEq = 2
	variable edgeAlgo = 1
	variable filter = 1
	variable filterN = 3	
	variable nrTimes = 1
	variable intPixels = 2
	variable cutoff = 0
	string msg = "Align " + imgNameTopGraphStr + " using part of the image."
	
	Prompt method, "Method", popup, "Registration (sub-pixel); Correlation (pixel)" // Registration = 1, Correlation = 2
	Prompt layerN, "Reference layer"
	Prompt filter, "Apply filter", popup, "None;gauss;avg;median;max;min" // gauss = 2
	Prompt filterN, "Filter N = 3 ... 15 (odd N is better)"	
	Prompt nrTimes, "Apply filter 1...5 times"	
	Prompt histEq, "Apply histogram equalization?", popup, "Yes;No" // Yes = 1, No = 2!	
	Prompt edgeAlgo, "Edge detection method", popup, "None;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei"
	Prompt intPixels, "Sub-pixel drift (Registation)",  popup, "Yes;No" // Yes = 1, No = 2!	
	Prompt cutoff, "Cutoff drift (pixels) "
	Prompt printMode, "Print layer drift", popup, "Yes;No" // Yes = 1, No = 2!
	
	DoPrompt msg, method, layerN, filter, filterN, nrTimes, histEq, edgeAlgo, intPixels, cutoff, printMode
	if(V_flag) // User cancelled
		return -1
	endif
	
	if(backupWave)
		ATH_DFR#BackupWaveInWaveDF(w3dref)
	endif
	string driftCorrectionOriginalNoteStr = note(w3dRef), driftCorrectionNoteStr // Grab early the original wave note
	variable left, right, top, bottom

	STRUCT sUserMarqueePositions s
	[left, right, top, bottom] = ATH_Marquee#UserGetMarqueePositions(s)
	DFREF currDFR = GetDataFolderDFR()
	string partitionWaveStr =  CreatedataObjectName(currDFR, "ATH_DRFCorr_partition", 1, 0, 0)
	ATH_WaveOp#WavePartition(w3dref, partitionWaveStr, left, right, top, bottom, evenNum = 1)
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
		ATH_ImgOp#MatrixFilter3D(partitionWave, filterStr, filterN, nrTimes)
	endif

	if(histEq == 1)
		ImageHistModification/O/I partitionWave
	endif

	// Edge detection is applied last
	if(edgeAlgo > 1)
		string edgeDetectionAlgorithms = "dummy;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei" // Prompt first item returns 1!
		string applyEdgeDetectionAlgo = StringFromList(edgeAlgo, edgeDetectionAlgorithms)
		ATH_ImgOp#ImageEdgeDetectionToStack(partitionWave, applyEdgeDetectionAlgo, overwrite = 1)
	endif
	
	if(method == 1)
		ATH_ImgAlign#ImgStackPartitionRegistration(w3dRef, partitionWave, layerN = layerN, printMode = printMode - 2, cutoff = cutoff, intPixels = intPixels - 1)
	elseif(method == 2)
		ATH_ImgAlign#ImgStackPartitionCorrelation(w3dRef, partitionWave, layerN = layerN, printMode = printMode - 2, cutoff = cutoff)
	else
		Abort "Please check ImageStackAlignmentUsingAFeature(), method error."
	endif
	//Restore the note, here backup wave exists or it have been created above, chgeck: if(!WaveExists($backupWave))

	driftCorrectionNoteStr = "Drift correction using " + StringFromList(method, "dummy;Registration;Correlation") + " with reference layer #"+num2str(layerN)+"\n"
	driftCorrectionNoteStr += "Apply filter:" + StringFromList(filter, "dummy;None;gauss;avg;median;max;min") + ", N = " + num2str(filterN) + ", repeated "+num2str(nrTimes)+" times\n"
	driftCorrectionNoteStr += "Apply histogram equalization: " + StringFromList(histEq, "dummy;Yes;No")+"\n"
	driftCorrectionNoteStr += "Edge detection method: " + StringFromList(edgeAlgo, "dummy;None;shen;kirsch;sobel;prewitt;canny;roberts;marr;frei")+"\n"
	driftCorrectionNoteStr += "Sub-pixel corrections: " + StringFromList(intPixels, "dummy;Yes;No") + "\n"
	driftCorrectionNoteStr += "Cutoff drift (pixels): " + num2str(cutoff)+"\n\n" + driftCorrectionOriginalNoteStr
	KillWaves partitionWave
	Note w3dref,driftCorrectionNoteStr
End

static Function LinearDriftCorrestionStackABCursors()
	// Use AB to linearly correct an image stack drift
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif	
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // ATH_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable nlayers = DimSize(w3dref, 2)
	
	if(nlayers < 3)
		return -1
	endif
	
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0,30000)/N=1/P A $imgNameTopGraphStr 0.25, 0.5
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0,30000)/N=1/P B $imgNameTopGraphStr 0.75, 0.5
	variable slope, shift
	
	string backupWavePathStr = ATH_DFR#BackupWaveInWaveDF(w3dref)	
	
	variable x0, y0, x1, y1
	STRUCT sUserCursorPositions s
	[x0, y0, x1, y1] = ATH_Cursors#UserGetABCursorPositions(s)
	[slope, shift] = ATH_Geometry#LineEquationFromTwoPoints(x0, y0, x1, y1)
	
	
	//WAVE/Z wx, wy // x, y drifts for each layer
	[WAVE wx, WAVE wy] = ATH_Geometry#XYWavesOfLineFromTwoPoints(x0, y0, x1, y1, nlayers)
	wx -= x0 // Relative xshift
	wy -= y0 // Relative yshift
	// ImageInterpolate needs pixels, multiply by -1 to have the proper behavior in /ARPM={...}
	variable dx = DimDelta(w3dref, 0) ; variable dy = DimDelta(w3dref, 1)
	wx /= (-dx) ; wy /= (-dy)
	ATH_ImgAlign#LinearDriftStackABCursors(w3dref, wx, wy)
	return 0
End

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
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // ATH_ImageStackAlignmentByPartitionRegistration needs a wave reference
	
	if(DimSize(w3dref, 2) < 3)
		return -1
	endif
	string backupWavePathStr = ATH_DFR#BackupWaveInWaveDF(w3dref)
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0,30000)/N=1/P A $imgNameTopGraphStr 0.25, 0.5
	Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0,30000)/N=1/P B $imgNameTopGraphStr 0.75, 0.5
	variable slope, shift, x0, y0, x1, y1, startL, endL, nlayers

	if(ATH_Windows#GetgLayerValue(winNameStr)==-1)
		ATH_Display#Append3DImageSlider()
	endif
	DFREF sliderDFR = $(skATH_W3DImageSliderParentDFR + winNameStr)
	NVAR/SDFR=sliderDFR gLayer
	startL = gLayer

	STRUCT sUserCursorPositions s
	[x0, y0, x1, y1] = ATH_Cursors#UserGetABCursorPositions(s)
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
	variable dx = DimDelta(w3dref, 0) ; variable dy = DimDelta(w3dref, 1)
	wx /= (-dx) ; wy /= (-dy)
	ATH_ImgAlign#LinearDriftPlanesABCursors(w3dref, wx, wy, startL = startL, endL = endL)
	return 0
End

// ---- ///

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

static Function ImageBackupFromBrowserSelection()
	string ATHImage = GetBrowserSelection(0)
	if(WaveDims($ATHImage) != 3 && WaveDims($ATHImage) != 2)
		Abort "Operation needs an image or image stack"
	endif
	ATH_ImgOp#RestoreTopImageFromBackup(wname = ATHImage)
	return 0
End

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

static Function NormalisationImageStackWithImage()
		
	if(ATH_Dialog#CountSelectedWavesInDataBrowser(wDims=3) != 1)
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

static Function NormalisationImageStackWithProfile()
	
	if(ATH_Dialog#CountSelectedWavesInDataBrowser(wDims=3) != 1)
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

static Function NormalisationImageStackWithImageStack()

	if(ATH_Dialog#CountSelectedWavesInDataBrowser(wDims=3) != 1)
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

static Function RemoveImagesFromImageStack()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif	
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable startLayer, nrLayers, flag
	if(WaveDims(w3dref) == 3 && DataFolderExists(skATH_W3DImageSliderParentDFR + winNameStr))
		NVAR glayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(winNameStr):gLayer
		startLayer = glayer
	else
		return -1
	endif
	Prompt nrLayers, "How many layers you want to remove (start from top image)?"
	DoPrompt "ATH_RemoveImagesFromImageStack", nrLayers
	if(nrLayers > 0 && !V_flag) // TODO: Use negative for backward removal
		ATH_ImgOp#RemoveImagesFromImageStack(w3dref, startLayer, nrLayers)
		ATH_Display#RestartW3DImageSlider(grfName=winNameStr)
	endif
	return 0
End

static Function StackImagesToImageStack()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif	
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string selectImagesStr = ATH_Dialog#SelectWavesInModalDataBrowser("Select image(s) (2d, 3d waves) to append to image(stack)"), imageStr
	variable imagesNr = ItemsInList(selectImagesStr), i
	
	if(!ItemsInList(selectImagesStr))
		return 1
	endif
	if(!ATH_ImgOp#AppendImagesToImageStack(w3dref, selectImagesStr))
		ATH_Display#RestartW3DImageSlider(grfName=winNameStr)
	endif	
	return 0
End

static Function InsertImageToStack()
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
	string selectImagesStr = ATH_Dialog#SelectWavesInModalDataBrowser("Select one image to insert to stack."), imageStr
	imageStr = StringFromList(0, selectImagesStr)
	if(!strlen(imageStr))
		return 1
	endif
	WAVE w2dref = $imageStr
	variable wType = WaveType(w3dref)
	if(wType == WaveType(w2dref))
		ATH_ImgOp#InsertImageToImageStack(w3dref, w2dref, layerN)
	else
		ATH_WaveOp#MatchWaveTypes(w3dref, w2dref)
		ATH_ImgOp#InsertImageToImageStack(w3dref, w2dref, layerN)
	endif
	ATH_Display#RestartW3DImageSlider(grfName=winNameStr)
	return 0	
End

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
	ATH_ImgOp#ImageRotateAndScale(wRef, angle, flipY = 1, backup=1) // Flip rows and rotate counter clock-wise
	Note wRef, noteStr
End


static Function ImageFFTTransform([int noPlot, int sourceDF])
	// FFT of the top image. If Marquee is present
	// the transform happends at the marked region
	// ATH_Transform#FFT2D creates the FFT wave in wRef DF.
	
	// FFT wave in the cwd
	noPlot = ParamIsDefault(noPlot) ? 0 : noPlot
	sourceDF = ParamIsDefault(sourceDF) ? 0 : sourceDF // Create the FFT in the source DF
	string grfName = WinName(0, 1, 1), noteStr
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	if(WaveExists(wRef))
		if(sourceDF)
			DFREF saveDF = GetDataFolderDFR()
			SetDataFolder $GetWavesDataFolder(wRef, 1)
		endif
		GetMarquee/W=$grfName
		if(V_flag) // if there is a Marquee a free wave will be used.
			string xaxis, yaxis
			DFREF dfr = GetDataFolderDFR()
			[xaxis, yaxis] = ATH_Graph#GetAxes(grfName=grfName)
			GetMarquee/W=$grfName/K $xaxis, $yaxis
			WAVE wPart = ATH_WaveOp#WavePartition(wRef, "", V_left, V_right, V_top, V_bottom, \
	evenNum = 1, WaveFREE = 1) // FREE WAVE
			// N.B. ATH_WaveOp#WavePartition returns pixel scaled image
			CopyScales/P wRef, wPart
			WAVE wFFT = ATH_Transform#FFT2D(wPart) // WPart is a FREE wave
			// We have to do it here as ATH_Transform#FFT2D will return  free wave witn name _free__FFT.
			string destWaveNameStr = CreatedataObjectName(dfr, NameOfWave(wRef)+"_FFT", 1, 0, 1)
			Rename wFFT, $destWaveNameStr
		else
			WAVE wFFT = ATH_Transform#FFT2D(wRef)
		endif
		noteStr = "FFT of " + GetWavesDataFolder(wRef, 2) + "\n"
		noteStr += "Marquee: " + num2str(V_left)+","+ num2str(V_right)
		noteStr += "," + num2str(V_top) + "," + num2str(V_bottom)
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


static Function ScalePlanesBetweenZeroAndOne()
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	MatrixOP/FREE wFree = scale(wRef, 0, 1)
	CopyScales/P wRef, wFree
	Duplicate/O wFree, wRef
	ATH_ImgOp#AutoRangeTopImagePlane() // Autoscale the image
	return 0
End

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

static Function ExtractLayerRangeToStack()

	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveDims(wRef) == 0) //  WaveDims(wRef) == 0 when wRef is NULL
		print "ExtractLayersToStack() needs an image stack in top graph."
		return -1
	endif
	string rangeStr = ATH_Dialog#GenericSingleStrPrompt("Enter a range as 3-7 or 3,7. Zero-based indexing.", "Extract image range from stack")
	string sval1, sval2, separatorStr
	SplitString/E="\s*([0-9]+)\s*(-|,)\s*([0-9]+)" rangeStr, sval1, separatorStr, sval2
	ATH_ImgOp#ExtractLayerRange(wRef, startL=str2num(sval1), endL=str2num(sval2), doStack=1)
End

static Function SumImagePlanes()

	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveDims(wRef) == 0) //  WaveDims(wRef) == 0 when wRef is NULL
		print "SumImagePlanes() needs an image stack in top graph."
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

static Function FlipStackPlanes()

	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(WaveDims(wRef) != 3 || WaveDims(wRef) == 0) //  WaveDims(wRef) == 0 when wRef is NULL
		print "SumImagePlanes() needs an image stack in top graph."
		return -1
	endif
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder GetWavesDataFolderDFR(wRef)
	ImageTransform flipPlanes wRef
	SetDataFolder saveDF
	return 0
End

static Function AverageImageStack()
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	variable nlayers = DimSize(wRef,2)	
	if(WaveDims(wRef) != 3 || nlayers < 2)
		return -1
	endif	
	ATH_WaveOp#AverageImageStack(wRef)
	return 0
End

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

static Function MakeWaveFromSavedROI()
	WAVE/Z wref = ATH_Graph#TopImageToWaveRef()
	ATH_WaveOp#MakeWaveFromROI(wRef)
End

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
	if(nlayers > 30)
		string abortmsg = "This operation will need a large amount of memory and long calculation" \
						 + " time,  I will not continue.\nIf you want to perform the operation " \
						 + " check the function ATH_XMCDCombinations."
		DoAlert 0, abortmsg
	elseif(nlayers > 10)
		string alertStr = "Operation will create a 3D wave with " + num2str((nlayers-1)*nlayers/2)\
						+ "layers. \nDo you want to continue?"
		DoAlert/T="Too many layers will be created ...", 1, alertStr
		if(V_flag == 1)
			ATH_Magnetism#CalculateXMCDComb(w3d)
		endif	
	else 
		ATH_Magnetism#CalculateXMCDComb(w3d)
	endif
	return 0
End

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

static Function PixelateSingleImageOrStack()
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	variable nx = 1, ny = 1, nz = 1
	if(WaveDims(wRef) == 3)
		Prompt nx, "Pixelate X:"
		Prompt ny, "Pixelate Y:"	
		Prompt nz, "Pixelate Z:"
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

static Function ScaleXPSSpectrum()
	///	Add description here.
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:PESSpectrumScale" ) // Root folder here
	variable STV, hv, wf, Escale, BE_min, BE_max
	NVAR/Z/SDFR=dfr gATH_PhotonEnergy
	if(!NVAR_Exists(gATH_PhotonEnergy))
		variable/G dfr:gATH_PhotonEnergy
		variable/G dfr:gATH_StartVoltage
		variable/G dfr:gATH_WorkFunction
		variable/G dfr:gATH_EnergyScale
	else
		NVAR/Z/SDFR=dfr gATH_StartVoltage
		NVAR/Z/SDFR=dfr gATH_WorkFunction
		NVAR/Z/SDFR=dfr gATH_EnergyScale
		NVAR/Z/SDFR=dfr gATH_PhotonEnergy
		hv = gATH_PhotonEnergy
		STV = gATH_StartVoltage
		Wf = gATH_WorkFunction
		Escale = gATH_EnergyScale
	endif

	
	string waveListStr = TraceNameList("", ";", 1)
	string wavenameStr = StringFromList(0, waveListStr)
	
	Prompt wavenameStr, "Select wave", popup, waveListStr
	Prompt hv, "Photon energy"
	Prompt STV, "Start Voltage"
	Prompt Wf, "Work function"
	Prompt Escale, "Energy scale"
	DoPrompt "Scale to binding energy (all zeros for no scale)", wavenameStr, hv, STV, Wf, Escale
		
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE wRef = TraceNameToWaveRef("", wavenameStr)

	BE_min = hv - STV - Wf - Escale/2
	BE_max = hv - STV - Wf + Escale/2

	SetScale/I x, BE_max, BE_min, wRef
	string noteStr = "hv = " + num2str(hv) + " eV," + "STV = " + num2str(STV) + " V," +\
					 "Wf = " + num2str(Wf) + " eV," + "Escale = " + num2str(Escale) + " eV"
	Note/K wRef, noteStr // Clear the note. 
	noteStr = "SetScale/I x," + num2str(BE_max) + "," + num2str(BE_min) + ","+ NameofWave(wRef)
	Note wRef, noteStr
	
	// plot  
	SetAxis/A/R bottom
	Label bottom "Binding Energy (eV)"
	Label left "\\u#2Intensity (arb. u.)"
	//
	gATH_PhotonEnergy = hv
	gATH_StartVoltage = STV
	gATH_WorkFunction = Wf
	gATH_EnergyScale  = Escale
End

static Function ScalePartialXPSSpectrum()
	/// In some measurements one of the edges of the dispersive plane is clippeda and
	/// ATH_LaunchScalePESSpectrum() cannot scale the PES spectrum. We can recover the
	/// PES spectrum if we can see one of the two edges and we know how many pixels make 
	/// full scale. 
	/// NB. Use one edge and set the A pointer, usually the end at the hight kinetic energy is seen
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:PESPartialSpectrumScale" ) // Root folder here
	variable STV, hv, wf, Escale, FullEnergyScale, BE_min, BE_max
	NVAR/Z/SDFR=dfr gATH_PhotonEnergy
	if(!NVAR_Exists(gATH_PhotonEnergy))
		variable/G dfr:gATH_PhotonEnergy
		variable/G dfr:gATH_StartVoltage
		variable/G dfr:gATH_WorkFunction
		variable/G dfr:gATH_EnergyScale
		variable/G dfr:gATH_FullEnergyScale
	else
		NVAR/Z/SDFR=dfr gATH_StartVoltage
		NVAR/Z/SDFR=dfr gATH_WorkFunction
		NVAR/Z/SDFR=dfr gATH_EnergyScale
		NVAR/Z/SDFR=dfr gATH_PhotonEnergy
		NVAR/Z/SDFR=dfr gATH_FullEnergyScale
		hv = gATH_PhotonEnergy
		STV = gATH_StartVoltage
		Wf = gATH_WorkFunction
		Escale = gATH_EnergyScale
		FullEnergyScale = gATH_FullEnergyScale
	endif

	
	string waveListStr = TraceNameList("", ";", 1)
	string wavenameStr = StringFromList(0, waveListStr)
	
	Prompt wavenameStr, "Select wave", popup, waveListStr
	Prompt hv, "Photon energy"
	Prompt STV, "Start Voltage"
	Prompt Wf, "Work function"
	Prompt Escale, "Energy scale"
	Prompt FullEnergyScale, "Full Energy scale"
	DoPrompt "Scale to binding energy (all zeros for no scale)", wavenameStr, hv, STV, Wf, Escale
		
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE wRef = TraceNameToWaveRef("", wavenameStr)

	BE_min = hv - STV - Wf - Escale/2
	BE_max = hv - STV - Wf + Escale/2

	SetScale/I x, BE_max, BE_min, wRef
	string noteStr = "hv = " + num2str(hv) + " eV," + "STV = " + num2str(STV) + " V," +\
					 "Wf = " + num2str(Wf) + " eV," + "Escale = " + num2str(Escale) + " eV"
	Note/K wRef, noteStr // Clear the note. 
	noteStr = "SetScale/I x," + num2str(BE_max) + "," + num2str(BE_min) + ","+ NameofWave(wRef)
	Note wRef, noteStr
	
	// plot  
	SetAxis/A/R bottom
	Label bottom "Binding Energy (eV)"
	Label left "\\u#2Intensity (arb. u.)"
	//
	gATH_PhotonEnergy = hv
	gATH_StartVoltage = STV
	gATH_WorkFunction = Wf
	gATH_EnergyScale  = Escale
End

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

static Function ImgRemoveBackground([variable w3d]) // ImageRemoveBackground is an Igor operation
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	variable order = 1
	variable do3D = 1
	if(WaveDims(wRef) == 3)
		Prompt order, "Background order (plane = 1, op. overwrites destination wave)"
		Prompt do3D, "Apply to all layers?", popup "No;Yes"
		DoPrompt "Background subtraction ", order, do3D
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
	if(do3D==2)
		ATH_ImgOp#ImgRemoveBackground(wRef, order = order, w3d=1)
		Note wRef, "\nImageRemoveBackground/P=" + num2str(order) + "\n" + noteStr		
		return 0
	endif
	if(ATH_Windows#GetgLayerValue("")!=-1) // Do we have active axis in top window?
		variable layerN = ATH_Windows#GetgLayerValue("")
		ATH_ImgOp#ImgRemoveBackground(wRef, order = order, layerN = layerN)
	else
		ATH_ImgOp#ImgRemoveBackground(wRef, order = order)
	endif
	Note wRef, "\nImageRemoveBackground/P=" + num2str(order) + "\n" + noteStr
	return 0
End

// Flatten Image

static Function FlattenImage([string method, variable kernelN, variable iterN])
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	kernelN = ParamIsDefault(kernelN) ? 2^5 : kernelN
	iterN = ParamIsDefault(iterN) ? 1 : iterN		
	string msg = "Flatten: img-bkg (layer-wise)"
	Prompt method, "Method", popup, "avg;gauss;median;max;min"
	Prompt kernelN, "Kernel size"
	Prompt iterN, "Iterations"
	DoPrompt msg, method, kernelN, iterN
	// Create backup here
	if(WaveDims(wRef) == 2)
		ATH_ImgOp#BackupTopImage()
		ATH_ImgOp#FlattenImage(wRef, method, kernelN, iterN, overwrite = 1)
	elseif(WaveDims(wRef) == 3)
		ATH_ImgOp#BackupTopImage()
		ATH_ImgOp#FlattenImage3D(wRef, method, kernelN, iterN, overwrite = 1)
	else
		return -1
	endif
	return 0
End

// Get and set image range and ctab

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

static Function SetAxesRangeAndCtabFromSaved([string grfName, variable setCtab])
	//
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:SavedAxesRangeCtab" ) // Root folder here
	NVAR/Z/SDFR=dfr gATH_AxisMinX
	if(!NVAR_Exists(gATH_AxisMinX))
		return 1
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
		if(setCtab)
			ATH_Graph#SetGraphCtabStr(gATH_GraphCtabStr, grfName = grfName)
		endif
	endif
	return 0
End

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
		WAVE/Z wRefBck = $(NameOfWave(wRef) + "_undo")
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