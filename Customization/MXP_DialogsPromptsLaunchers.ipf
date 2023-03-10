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
Function MXP_LaunchMake3DWaveUsingPattern()
	string wname3dStr, pattern
	[wname3dStr, pattern] = MXP_GenericDoubleStrPrompt("Stack name","Match waves (use * wildcard)", "Make a stack from waves using a pattern")
	
	MXP_Make3DWaveUsingPattern(wname3dStr, pattern)
End

Function MXP_LaunchMake3DWaveDataBrowserSelection([variable displayStack])
	displayStack = ParamIsDefault(displayStack) ? 0: displayStack // Give any non-zero to display the stack
	string wname3dStr = ""
	//20.02.2023 changed to "" to bypass dialog. Uncomment to restore		
	//wname3dStr = MXP_GenericSingleStrPrompt("Stack name", "Make a stack of pre-selected waves in data browser")
	
	if(!strlen(wname3dStr))
		wname3dStr = "MXP_stack"
	endif
	
	MXP_Make3DWaveDataBrowserSelection(wname3dStr, gotoFilesDFR = 0) // 0 - stack in cwd 1 - stack in files DFR
	// Do you want to display the stack?
	if(displayStack)
		MXP_DisplayImage($wname3dStr)
	endif
End

Function MXP_LauncherLoadDATFilesFromFolder()
	string wNameStr = MXP_GenericSingleStrPrompt("Stack name, empty string to auto-name", "Before the selection dialog opens...")
	if(strlen(wNameStr))
		MXP_LoadDATFilesFromFolder("", "*", stack3d = 1, wname3d = wNameStr, autoscale = 1)
	else
		// default name, if wname3d is given, even if empty string, the ParamIsDefault will give 1.
		// wname3d = SelectString(ParamIsDefault(wname3d) ? 0: 1,"stack3d", wname3d)
		MXP_LoadDATFilesFromFolder("", "*", stack3d = 1, autoscale = 1) 
	endif
End

Function MXP_LauncherLoadHDF5GroupsFromFile()
	string selectedGroups = MXP_GenericSingleStrPrompt("Use single ScanID and/or ranges, e.g.  \"2-5,7,9-12,50\".  Leave string empty to load all entries.", "Before the .h5 selection dialog opens...")
	if(strlen(selectedGroups))
		MXP_LoadHDF5SpecificGroups(selectedGroups)
	else
		MXP_LoadHDF5File()
	endif
End

Function MXP_LaunchAverageStackToImageFromMenu()
	string waveListStr = Wavelist("*",";","DIMS:3"), selectWaveStr, waveNameStr
	string strPrompt1 = "Select stack"
	string strPrompt2 = "Enter averaged wave nane (leave empty for MXP_AvgStack)"
	string msgDialog = "Average a stack (3d wave) in working DF"
	[selectWaveStr, waveNameStr] = MXP_GenericSingleStrPromptAndPopup(strPrompt1, strPrompt2, waveListStr, msgDialog)
	if(!strlen(waveNameStr))
		MXP_AverageStackToImage($selectWaveStr)
	else
		MXP_AverageStackToImage($selectWaveStr, avgImageName = waveNameStr)
	endif
	KillWaves/Z M_StdvImage
End

Function MXP_LaunchAverageStackToImageFromTraceMenu()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	if(!DimSize(w3dref, 2))
		Abort "Operation needs a stack"
	endif
	string strPrompt = "Averaged wave nane (leave empty for MXP_AvgStack)"
	string msgDialog = "Average stack along z"
	string waveNameStr
	waveNameStr = MXP_GenericSingleStrPrompt(strPrompt, msgDialog)
	if(!strlen(waveNameStr))
		MXP_AverageStackToImage(w3dref)
	else
		MXP_AverageStackToImage(w3dref, avgImageName = waveNameStr)
	endif
	KillWaves/Z M_StdvImage
End

Function MXP_LaunchAverageStackToImageFromBrowserMenu()
	string bufferStr, wavenameStr
	if(MXP_CountSelectedWavesInDataBrowser(waveDimemsions = 3) == 1\
	 && MXP_CountSelectedWavesInDataBrowser() == 1) // If we selected a single 3D wave
		string selected3DWaveStr = GetBrowserSelection(0)
		WAVE w3dRef = $selected3DWaveStr	
	else
		Abort "Operation needs an image stack (3d wave)"
	endif

//	string strPrompt = "Averaged wave nane (leave empty for MXP_AvgStack)"
//	string msgDialog = "Average stack along z"
//	string waveNameStr
//	waveNameStr = MXP_GenericSingleStrPrompt(strPrompt, msgDialog)
//	if(!strlen(waveNameStr))
//		MXP_AverageStackToImage(w3dref)
//	else
//		MXP_AverageStackToImage(w3dref, avgImageName = waveNameStr)
//	endif
	// Changed and we give a unique name with an WaveName_avg suffix
	DFREF cdfr = GetDataFolderDFR()
	bufferStr = NameOfWave(w3dRef) + "_avg"
	waveNameStr = CreateDataObjectName(cdfr, bufferStr, 1, 0, 4)
	MXP_AverageStackToImage(w3dref, avgImageName = waveNameStr)
	KillWaves/Z M_StdvImage
End

Function MXP_LaunchRegisterQCalculateXRayDichroism()
	string msg = "Select two waves for XMC(L)D calculation. Use Ctrl (Windows) or Cmd (Mac)."
	string selectedWavesInBrowserStr = MXP_SelectWavesInModalDataBrowser(msg)
	
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
	string selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
	if(nrSelectedWaves != 2)
		DoAlert/T="MAXPEEM would like you to know" 1, "Select two (2) .dat files only.\n" + \
				"Do you want a another chance with the browser selection?"
		if(V_flag == 1)
			MXP_LaunchRegisterQCalculateXRayDichroism()
		elseif(V_flag == 2)
			Abort
		else
			print "MXP_RegisterQCalculateXRayDichroism()! Abormal behavior."
		endif
		
		Abort // Abort the running instance otherwise the code that follows will run 
			  // as many times as the dialog will be displayed. Equavalenty, it can 
			  // be placed in the if (V_flag == 1) branch.
	endif
	string wave1Str = StringFromList(0, selectedWavesStr) // The last dat has been eliminated when importing waves, so we are ok
	string wave2Str = StringFromList(1, selectedWavesStr)
	string selectedWavesPopupStr = wave1Str + ";" + wave2Str
	variable registerImageQ
	string saveWaveName = ""
	//Set defaults 
	Prompt wave1Str, "img1", popup, selectedWavesPopupStr
	Prompt wave2Str, "img2", popup, selectedWavesPopupStr
	Prompt registerImageQ, "Automatic image registration?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt saveWaveName, "Name of the XMC(L)D wave (default: MXPxmcd)"
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1Str, wave2Str, registerImageQ, saveWaveName
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE wimg1 = $wave1Str
	WAVE wimg2 = $wave2Str
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
		MXP_ImageAlignmentByRegistration(wimg1, wimg2copy)
	endif
	if(!strlen(saveWaveName))
		saveWaveName = "MXPxmcd"
	endif
	MXP_CalculateXMCD(wimg1, wimg2copy, saveWaveName)
	// if you use /P, the dimension scaling is copied in slope/intercept format 
	// so that if srcWaveName  and the other waves have differing dimension size 
	// (number of points if the wave is a 1D wave), then their dimension values 
	// will still match for the points they have in common
	CopyScales wimg1, $saveWaveName 
	Note/K $saveWaveName, xmcdWaveNoteStr
	return 0
End

Function MXP_LaunchCalculateXMCDFromStack()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	if(DimSize(w3dref,2) != 2)
		Abort "A stack with two layers in needed"
	endif
	MatrixOP/O/FREE w1free = layer(w3dref, 0)
	MatrixOP/O/FREE w2free = layer(w3dref, 1)
	string xmcdWaveStr = NameofWave(w3dref) + "_xmcd"
	MXP_CalculateXMCD(w1free, w2free, xmcdWaveStr)
	// if you use /P, the dimension scaling is copied in slope/intercept format 
	// so that if srcWaveName  and the other waves have differing dimension size 
	// (number of points if the wave is a 1D wave), then their dimension values 
	// will still match for the points they have in common
	CopyScales w3dref, $xmcdWaveStr 
	MXP_DisplayImage($xmcdWaveStr)
End

Function MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()

	variable numRef
	string fileFilters = "dat File (*.dat):.dat;"
	fileFilters += "All Files:.*;"
	string msgStr = "Select two images for XMC(L)D calculation."
	Open/D/R/MULT=1/M=msgStr/F=fileFilters numRef
	if(!strlen(S_filename))
		Abort
	endif
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedFiles = ItemsInList(S_filename, "\r")
	string selectedFilesInDialogStr = SortList(S_fileName, "\r", 16)
	if(nrSelectedFiles != 2)
		DoAlert/T="MAXPEEM would like you to know" 1, "Select two (2) .dat files only.\n" + \
				"Do you want a another chance with the dialog selection?"
		if(V_flag == 1)
			MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()
		elseif(V_flag == 2)
			Abort
		else
			print "Check MXP_MenuLoadTwoImagesRegisterMagContrast()! Abormal behavior."
		endif
		
		Abort // Abort the running instance otherwise the code that follows will run 
			  // as many times as the dialog will be displayed. Equavalenty, it can 
			  // be placed in the if (V_flag == 1) branch.
	endif
	//string selectedFilesStr = ""
	selectedFilesInDialogStr = ReplaceString("\r", selectedFilesInDialogStr, ";")

	string wave1Str = ParseFilePath(3, StringFromList(0, selectedFilesInDialogStr), ":", 0, 0)
	string wave2Str = ParseFilePath(3, StringFromList(1, selectedFilesInDialogStr), ":", 0, 0)
	string selectedFilesPopupStr = wave1Str + ";" + wave2Str
	variable registerImageQ = 2 // Default: No
	string saveWaveName = ""
	//Set defaults 
	Prompt wave1Str, "img1", popup, selectedFilesPopupStr
	Prompt wave2Str, "img2", popup, selectedFilesPopupStr
	Prompt registerImageQ, "Automatic image registration?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt saveWaveName, "Name of the XMC(L)D wave (default: MXPxmcd)"
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1Str, wave2Str, registerImageQ, saveWaveName
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE wimg1 = MXP_WAVELoadSingleDATFile(StringFromList(0, selectedFilesInDialogStr), "", autoScale = 1)
	WAVE wimg2 = MXP_WAVELoadSingleDATFile(StringFromList(1, selectedFilesInDialogStr), "", autoScale = 1)
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
	
	if(registerImageQ == 1)
		MXP_ImageAlignmentByRegistration(wimg1, wimg2) // wimg2 is overwritten here
	endif
	if(!strlen(saveWaveName))
		// We need a unique wave name
		DFREF currDF = GetDataFolderDFR()
		saveWaveName = CreatedataObjectName(currDF, "MXP_xmcd", 1, 0, 0)
	endif
	MXP_CalculateXMCD(wimg1, wimg2, saveWaveName)
	// if you use /P, the dimension scaling is copied in slope/intercept format 
	// so that if srcWaveName  and the other waves have differing dimension size 
	// (number of points if the wave is a 1D wave), then their dimension values 
	// will still match for the points they have in common
	CopyScales wimg1, $saveWaveName
	Note/K $saveWaveName, xmcdWaveNoteStr	
	return 0
End

Function MXP_LaunchImageStackAlignmentByFullImage()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // MXP_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable convMode = 1
	variable printMode = 2
	variable layerN = 0
	variable windowing = 2
	variable algo = 1
	string msg = "Align " + imgNameTopGraphStr + " using the full image."
	Prompt algo, "Method", popup, "Registration (sub-pixel); Correlation (pixel)"
	Prompt layerN, "Reference layer"
	Prompt convMode, "Convergence (Registration only)", popup, "Gravity (fast); Marquardt (slow)"
	Prompt windowing, "Hanning windowing (Correlation only)", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt printMode, "Print layer drift", popup, "Yes;No" // Yes = 1, No = 2!
	DoPrompt msg, algo, layerN, convMode, windowing, printMode
	if(V_flag) // User cancelled
		return -1
	endif
	string backupWave = NameOfWave(w3dref) + "_undo"
	if(!WaveExists($backupWave))
		print GetWavesDataFolder(w3dref, 1) + PossiblyQuoteName(backupWave) + " has been created. To restore " + GetWavesDataFolder(w3dref, 2) + " run the command:\n"
		print "Duplicate/O " + GetWavesDataFolder(w3dref, 1) + PossiblyQuoteName(backupWave) + ", " +  GetWavesDataFolder(w3dref, 2) + "; " + \
		"KillWaves/Z " + GetWavesDataFolder(w3dref, 1) + PossiblyQuoteName(backupWave)
		Duplicate $GetWavesDataFolder(w3dref, 2), $(GetWavesDataFolder(w3dref, 1) + PossiblyQuoteName(backupWave))
	endif
	// CheckDisplayed $selectWaveStr -- add automations later, assume now we act on the top graph
	//MXP_ImageStackAlignmentByPartitionRegistration
	if(algo == 1)
		MXP_ImageStackAlignmentByRegistration(w3dRef, layerN = layerN, printMode = printMode - 2, convMode = convMode - 1)
	else
		MXP_ImageStackAlignmentByCorrelation(w3dRef, layerN = layerN, printMode = printMode - 2, windowing = windowing - 2)
	endif

End


Function MXP_LaunchImageStackAlignmentUsingAFeature()
	//string waveListStr = Wavelist("*",";","DIMS:3"), selectWaveStr
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // MXP_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable method = 1
	variable printMode = 2
	variable layerN = 0
	string msg = "Align " + imgNameTopGraphStr + " using part of the image."
	Prompt method, "Method", popup, "Registration (sub-pixel); Correlation (pixel)" // Registration = 1, Correlation = 2
	Prompt layerN, "Reference layer"
	Prompt printMode, "Print layer drift", popup, "Yes;No" // Yes = 1, No = 2!
	DoPrompt msg, method, layerN, printMode
	if(V_flag) // User cancelled
		return -1
	endif
	string backupWave = NameOfWave(w3dref) + "_undo"
	if(!WaveExists($backupWave))
		print GetWavesDataFolder(w3dref, 1) + PossiblyQuoteName(backupWave) + " has been created. To restore " + GetWavesDataFolder(w3dref, 2) + " run the command:\n"
		print "Duplicate/O " + GetWavesDataFolder(w3dref, 1) + PossiblyQuoteName(backupWave) + ", " +  GetWavesDataFolder(w3dref, 2) + "; " + \
		"KillWaves/Z " + GetWavesDataFolder(w3dref, 1) + PossiblyQuoteName(backupWave)
		Duplicate $GetWavesDataFolder(w3dref, 2), $(GetWavesDataFolder(w3dref, 1) + PossiblyQuoteName(backupWave))
	endif
	// CheckDisplayed $selectWaveStr -- add automations later, assume now we act on the top graph
	// MXP_ImageStackAlignmentByPartitionRegistration
	WAVE partiotionWave = WM_UserSetMarquee(winNameStr) // partitionWave might be a 2D wave to be used as a Mask

	if(method == 1)
		ImageFilter/O gauss3d partiotionWave // Apply a 3x3x3 gaussian filter
		MatrixOP/FREE/O partiotionFreeWaveGaussNorm = normalize(partiotionWave)	
		MXP_ImageStackAlignmentByPartitionRegistration(w3dRef, partiotionFreeWaveGaussNorm, layerN = layerN, printMode = printMode - 2)
	elseif(method == 2)
		ImageFilter/O gauss3d partiotionWave // Apply a 3x3x3 gaussian filter
		MatrixOP/FREE/O partiotionFreeWaveGaussNorm = normalize(partiotionWave)	
		MXP_ImageStackAlignmentByPartitionCorrelation(w3dRef, partiotionFreeWaveGaussNorm, layerN = layerN, printMode = printMode - 2)
	else 
		Abort "Please check MXP_LaunchImageStackAlignmentUsingAFeature(), method error."
	endif
End

Function/WAVE WM_UserSetMarquee(string graphName)
	/// Modified WM procedure to return a Free WAVE to MXP_LaunchMXP_ImageStackAlignmentByPartitionRegistration()
	/// method = 0:partition wave 3d, method = 1, create a mask
	DoWindow/F $graphName			// Bring graph to front
	if (V_Flag == 0)					// Verify that graph exists
		Abort "WM_UserSetMarquee: No image in top window."
	endif

	NewDataFolder/O root:tmp_PauseforCursorDF
	Variable/G root:tmp_PauseforCursorDF:canceled= 0

	NewPanel/K=2 /W=(139,341,382,450) as "Set marquee on image"
	DoWindow/C tmp_PauseforCursor					// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=$graphName			// Put panel near the graph

	DrawText 15,20,"Draw marquee and press continue..."
	DrawText 15,35,"Can also use a marquee to zoom-in"
	Button button0, pos={80,50},size={92,20}, title="Continue"
	Button button0, proc=WM_UserSetMarquee_ContButtonProc
	Button button1, pos={80,80},size={92,20}
	Button button1, proc=WM_UserSetMarquee_CancelBProc, title="Cancel"

	PauseForUser tmp_PauseforCursor,$graphName
	NVAR/Z left = root:tmp_PauseforCursorDF:left
	NVAR/Z right = root:tmp_PauseforCursorDF:right
	NVAR/Z top = root:tmp_PauseforCursorDF:top
	NVAR/Z bottom = root:tmp_PauseforCursorDF:bottom
	NVAR/Z gCanceled= root:tmp_PauseforCursorDF:canceled
	Variable canceled= gCanceled			// Copy from global to local before global is killed
	if(canceled)
		GetMarquee/K
		Abort
	endif
		
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(graphName, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	WAVE partiotionWave = MXP_WAVE3DWavePartition(w3dref, left, right, top, bottom, evenNum = 1) // Change here the partition
	KillDataFolder root:tmp_PauseforCursorDF // Kill folder here, you have to use the left, right, top, bottom in MXP_WAVE3DWavePartition
	return partiotionWave
End


Function WM_UserSetMarquee_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
	GetMarquee/K left, top
	variable/G root:tmp_PauseforCursorDF:left = V_left
	variable/G root:tmp_PauseforCursorDF:right = V_right
	variable/G root:tmp_PauseforCursorDF:top = V_top
	variable/G root:tmp_PauseforCursorDF:bottom = V_bottom	
	KillWindow/Z tmp_PauseforCursor			// Kill self
End

Function WM_UserSetMarquee_CancelBProc(ctrlName) : ButtonControl
	String ctrlName
	Variable/G root:tmp_PauseforCursorDF:canceled = 1
	KillWindow/Z tmp_PauseforCursor			// Kill self
End

// ---- ///

Function MXP_LaunchNewImageFromBrowserSelection()
	// Display selected images
	variable i = 0, cnt = 0, promptOnceSwitch = 1
	string mxpImage
	if(!strlen(GetBrowserSelection(0)))
		Abort "No image selected"
	endif
	
	do
		mxpImage = GetBrowserSelection(i) 
		if(WaveDims($mxpImage) != 3 && WaveDims($mxpImage) != 2)
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
		
		MXP_DisplayImage($mxpImage)
		i++
	while (strlen(GetBrowserSelection(i)))
End

// -------

Function MXP_LaunchNormalisationImageStackWithImage()
		
	if(MXP_CountSelectedWavesInDataBrowser(waveDimemsions=3) != 1)
		Abort "Please select an image stack (3d wave)"
	endif
	string wave3dStr = StringFromList(0, GetBrowserSelection(0))
	WAVE w3dRef = $wave3dStr
	string imageNameStr = StringFromList(0, MXP_SelectWavesInModalDataBrowser("Select an image (2d wave) for normalisation"))
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
	MXP_NormaliseImageStackWithImage(w3dRef, imageWaveRef)
End

Function MXP_LaunchNormalisationImageStackWithProfile()
	
	if(MXP_CountSelectedWavesInDataBrowser(waveDimemsions=3) != 1)
		Abort "Please select an image stack (3d wave)"
	endif
	string wave3dStr = StringFromList(0, GetBrowserSelection(0))
	WAVE w3dRef = $wave3dStr
	string selectProfileStr = StringFromList(0, MXP_SelectWavesInModalDataBrowser("Select a profile (1d wave) for normalisation"))
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
	MXP_NormaliseImageStackWithProfile(w3dRef, profWaveRef)
End

Function MXP_LaunchNormalisationImageStackWithImageStack()

	if(MXP_CountSelectedWavesInDataBrowser(waveDimemsions=3) != 1)
		Abort "Please select an image stack (3d wave)"
	endif
	string wave3d1Str = StringFromList(0, GetBrowserSelection(0))
	WAVE w3d1Ref = $wave3d1Str
	string wave3d2Str = StringFromList(0, MXP_SelectWavesInModalDataBrowser("Select an image stack (3d wave) for normalisation"))
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
	string inputStr = MXP_GenericSingleStrPrompt(promptStr, "How many layers would you like to use for Normalisation?")
	string rangeStr = MXP_StrExpandRange(inputStr)
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

Function MXP_LaunchStackImageToImageStack()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string selectImageStr = StringFromList(0, MXP_SelectWavesInModalDataBrowser("Select an image (2d wave) to add to stack"))
	WAVE imageWaveRef = $selectImageStr
	if(WaveDims(imageWaveRef) == 2)
		MXP_StackImageToImageStack(w3dref, imageWaveRef)
		KillWindow/Z $winNameStr
		MXP_DisplayImage(w3dref)
		ModifyGraph width={Plan,1,top,left}
		WMAppend3DImageSlider()
	endif
End
// Dialogs
Function/S MXP_GenericSinglePopupStrPrompt(string strPrompt, string popupStrSelection, string msgDialog)
	string returnStrVar 
	Prompt returnStrVar, strPrompt, popup, popupStrSelection
	DoPrompt msgDialog, returnStrVar
	if(V_flag)
		Abort
	endif
	return returnStrVar
End

Function/S MXP_GenericSingleStrPrompt(string strPrompt, string msgDialog)
	string returnStrVar 
	Prompt returnStrVar, strPrompt
	DoPrompt msgDialog, returnStrVar
	if(V_flag)
		Abort
	endif
	return returnStrVar
End

Function [string returnStrVar1, string returnStrVar2] MXP_GenericSingleStrPromptAndPopup(string strPrompt1,string strPrompt2, string popupStrSelection1, string msgDialog)
	string strVar1, strVar2
	Prompt strVar1, strPrompt1, popup, popupStrSelection1
	Prompt strVar2, strPrompt2
	DoPrompt msgDialog, strVar1, strVar2
	if(V_flag)
		Abort
	endif
	returnStrVar1 = strVar1
	returnStrVar2 = strVar2
	return [returnStrVar1, returnStrVar2] 
End

Function [string returnStrVar1, string returnStrVar2] MXP_GenericDoubleStrPromptPopup(string strPrompt1, string strPrompt2, string popupStrSelection1, string popupStrSelection2, string msgDialog)
	string strVar1, strVar2
	Prompt strVar1, strPrompt1, popup, popupStrSelection1
	Prompt strVar2, strPrompt2, popup, popupStrSelection2
	DoPrompt msgDialog, strVar1, strVar2
	if(V_flag)
		Abort
	endif
	returnStrVar1 = strVar1
	returnStrVar2 = strVar2
	return [returnStrVar1, returnStrVar2] 
End

Function [string returnStrVar1, string returnStrVar2] MXP_GenericDoubleStrPrompt(string strPrompt1, string strPrompt2, string msgDialog)
	string strVar1, strVar2
	Prompt strVar1, strPrompt1
	Prompt strVar2, strPrompt2
	DoPrompt msgDialog, strVar1, strVar2
	if(V_flag)
		Abort
	endif
	returnStrVar1 = strVar1
	returnStrVar2 = strVar2
	return [returnStrVar1, returnStrVar2] 
End

Function MXP_GenericSingleVarPrompt(string strPrompt, string msgDialog)
	variable returnVar 
	Prompt returnVar, strPrompt
	DoPrompt msgDialog, returnVar
	if(V_flag)
		return 1
	endif
	return returnVar
End

// Browser selection

Function/S MXP_SelectWavesInModalDataBrowser(string msg)
	/// Launch modal browser to select waves
	
	// Create the modal data browser but do not display it
	CreateBrowser/M prompt = msg
	// Show waves but not variables in the modal data browser
	ModifyBrowser/M showWaves = 1, showVars = 0, showStrs = 0
	// Set the modal data browser to sort by name 
	ModifyBrowser/M sort = 1, showWaves = 1, showVars = 0, showStrs = 0
	// Hide the info and plot panes in the modal data browser 
	ModifyBrowser/M showInfo = 1, showPlot = 1
	// Display the modal data browser, allowing the user to make a selection
	ModifyBrowser/M showModalBrowser
	
	if(!V_flag) // user cancelled
		Abort
	endif
	
	return S_BrowserList
End

/// Helper function

Function MXP_CountSelectedObjectsInDataBrowser()
	/// return how many objects of any kind you have 
	/// selected in the data browser 
	string selectedItemStr
	variable cnt = 0 , i = 0
	if(!strlen(GetBrowserSelection(0)))
		return 0
	endif
	do
		selectedItemStr = GetBrowserSelection(i)
		i++
		cnt++
	while (strlen(GetBrowserSelection(i)))
	return cnt
End

Function MXP_CountSelectedWavesInDataBrowser([variable waveDimemsions])
	/// return how many waves are selected in the data browser
	/// Function returns selected waves of dimensionality waveDimemsions
	/// if the optional argument is set.
	
	waveDimemsions = ParamIsDefault(waveDimemsions) ? 0: waveDimemsions
	if(waveDimemsions < 0 || waveDimemsions > 5)
		return -1 // Bad arguments
	endif
	
	string selectedItemStr
	variable cnt = 0 , i = 0
	if(!strlen(GetBrowserSelection(0)))
		return 0
	endif
	do
		selectedItemStr = GetBrowserSelection(i)
		i++
		if((exists(selectedItemStr) == 1 && !waveDimemsions) \
		|| (exists(selectedItemStr) == 1 && WaveDims($selectedItemStr) == waveDimemsions))
			cnt++
		endif
	while (strlen(GetBrowserSelection(i)))
	return cnt
End