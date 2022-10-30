#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// Launchers
Function MXP_LaunchMake3DWaveUsingPattern()
	string wname3dStr, pattern
	[wname3dStr, pattern] = MXP_GenericDoubleStrPrompt("Stack name","Match waves (use * wildcard)", "Make a stack from waves using a pattern")
	
	MXP_Make3DWaveUsingPattern(wname3dStr, pattern)
End

Function MXP_LaunchMake3DWaveDataBrowserSelection()
	string wname3dStr
	wname3dStr = MXP_GenericSingleStrPrompt("Stack name", "Make a stack of pre-selected waves in data browser")
	MXP_Make3DWaveDataBrowserSelection(wname3dStr)
End

Function MXP_LauncherLoadDATFilesFromFolder()
	string wNameStr = MXP_GenericSingleStrPrompt("Stack name, empty string to auto-name", "Before the selection dialog opens...")
	if(strlen(wNameStr))
		MXP_LoadDATFilesFromFolder("", "*", switch3d = 1, wname3d = wNameStr, autoscale = 1)
	else
		// default name, if wname3d is given, even if empty string, the ParamIsDefault will give 1.
		MXP_LoadDATFilesFromFolder("", "*", switch3d = 1, autoscale = 1) 
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
	NewImage $xmcdWaveStr
	ModifyGraph width={Plan,1,top,left}
End
Function MXP_LaunchInteractiveImageDriftCorrectionXMCD() // FIX IT
	/// Function to interactively drift images and get an updated
	/// graph of the XMC(L)D contrast.
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	
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
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1Str, wave2Str
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE w1 = $wave1Str
	WAVE w2 = $wave2Str
	// Make a note for the XMC(L)D image
	string xmcdWaveNoteStr = "XMC(L)D = (img1 - img2)/(img1 + img2)\n"
	
	if(!(WaveType(w1) & 0x02))
		Redimension/S w1
	endif
	if(!(WaveType(w2) & 0x02))
		Redimension/S w2
	endif 

	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:InteractiveXMCD:")
	Make/O/N=(DimSize(w1, 0), DimSize(w1, 1)) dfr:MXP_XMCD_Interactive /WAVE = xmcdWAVERef // Is this ok to do?
	Duplicate/O w1, dfr:wave1XMCD
	Duplicate/O w2, dfr:wave2XMCD
	WAVE xmcd = MXP_WAVECalculateXMCD(dfr:wave1XMCD, dfr:wave2XMCD) // FREE WAVE, at the end of the funtion will be destroyed
	xmcdWAVERef = xmcd
	NewImage xmcdWAVERef
	ModifyGraph width={Plan,1,top,left}
	// TODO: Display the two images, find a good way of doing it.
	// Then prompt to move one with respect to the other and recalculate XMCD MXP_WAVECalculateXMCD(dfr:wave1XMCD, dfr:wave2XMCD
End

Function MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()

	variable numRef
	string fileFilters = "dat File (*.dat):.dat;"
	fileFilters += "All Files:.*;"
	string msgStr = "Select two images for XMC(L)D calculation."
	Open/D/R/MULT=1/M=msgStr/F=fileFilters numRef
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
	variable registerImageQ
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
	WAVE wimg1 = MXP_WAVELoadSingleDATFile(StringFromList(0, selectedFilesInDialogStr), "")
	WAVE wimg2 = MXP_WAVELoadSingleDATFile(StringFromList(1, selectedFilesInDialogStr), "")
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
	Note/K $saveWaveName, xmcdWaveNoteStr
	return 0
End

Function MXP_LaunchImageStackAlignmentByFullImage()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // MXP_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable method = 2
	variable printMode = 2
	variable layerN = 0
	variable windowing = 2
	variable algo = 1
	string msg = "Align " + imgNameTopGraphStr + " using the full image."
	Prompt method, "Method", popup, "Registration (sub-pixel); Correlation (pixel)"
	Prompt layerN, "Reference layer"
	Prompt algo, "Convergence (Registration only)", popup, "Gravity (fast); Marquardt (slow)"
	Prompt windowing, "Hanning windowing (Correlation only)", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt printMode, "Print layer drift", popup, "Yes;No" // Yes = 1, No = 2!
	DoPrompt msg, method, layerN, algo, windowing, printMode
	if(V_flag) // User cancelled
		return -1
	endif
	if(!WaveExists($(imgNameTopGraphStr + "_undo")))
		print PossiblyQuoteName(imgNameTopGraphStr + "_undo") + " has been created. To restore " + PossiblyQuoteName(imgNameTopGraphStr) + " run the command:\n"
		print "Duplicate/O " + PossiblyQuoteName(imgNameTopGraphStr + "_undo") + ", " +  PossiblyQuoteName(imgNameTopGraphStr) + "; " + \
		"KillWaves/Z " + PossiblyQuoteName(imgNameTopGraphStr + "_undo")
	endif
	// CheckDisplayed $selectWaveStr -- add automations later, assume now we act on the top graph
	//MXP_ImageStackAlignmentByPartitionRegistration
	if(method == 1)
		MXP_ImageStackAlignmentByRegistration(w3dRef, layerN = layerN, printMode = printMode - 2, convMode = algo - 1)
	else
		MXP_ImageStackAlignmentByCorrelation(w3dRef, layerN = layerN, printMode = printMode - 2, windowing = windowing - 2)
	endif

End

// ---- ///
Function MXP_LaunchImageStackAlignmentByPartition()
	//string waveListStr = Wavelist("*",";","DIMS:3"), selectWaveStr
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // MXP_ImageStackAlignmentByPartitionRegistration needs a wave reference
	variable method = 1
	variable printMode = 2
	variable layerN = 0
	string msg = "Align " + imgNameTopGraphStr + " using part of the image."
	Prompt method, "Method", popup, "Registration (sub-pixel); Correlation (pixel)"
	Prompt printMode, "Print layer drift", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt layerN, "Reference layer"
	DoPrompt msg, method, layerN, printMode
	if(V_flag) // User cancelled
		return -1
	endif
	if(!WaveExists($(imgNameTopGraphStr + "_undo"))) // if you put this later it makes a problem with the function calls that have the same if statement
		print PossiblyQuoteName(imgNameTopGraphStr + "_undo") + " has been created. To restore " + PossiblyQuoteName(imgNameTopGraphStr) + " run the command:\n"
		print "Duplicate/O " + PossiblyQuoteName(imgNameTopGraphStr + "_undo") + ", " +  PossiblyQuoteName(imgNameTopGraphStr) + "; " + \
		"KillWaves/Z " + PossiblyQuoteName(imgNameTopGraphStr + "_undo")
	endif
	// CheckDisplayed $selectWaveStr -- add automations later, assume now we act on the top graph
	// MXP_ImageStackAlignmentByPartitionRegistration
	WAVE partiotionWave = WM_UserSetMarquee(winNameStr)
	ImageFilter/O gauss3d partiotionWave // Apply a 3x3x3 gaussian filter
	MatrixOP/O partiotionFreeWaveGaussNorm = normalize(partiotionWave) // Normalise wave here FIX: SET TO FREE
	if(method == 1)
		MXP_ImageStackAlignmentByPartitionRegistration(w3dRef, partiotionFreeWaveGaussNorm, layerN = layerN, printMode = printMode - 2)
	else
		MXP_ImageStackAlignmentByPartitionCorrelation(w3dRef, partiotionFreeWaveGaussNorm, layerN = layerN, printMode = printMode - 2)
	endif
End

Function/WAVE WM_UserSetMarquee(graphName)
	/// Modified WM procedure to return a Free WAVE to MXP_LaunchMXP_ImageStackAlignmentByPartitionRegistration()
	String graphName

	DoWindow/F $graphName			// Bring graph to front
	if (V_Flag == 0)					// Verify that graph exists
		Abort "WM_UserSetMarquee: No such graph."
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
	//print num2str(left)+","+num2str(top)+","+num2str(right)+","+num2str(bottom) // DEBUG
	NVAR/Z gCanceled= root:tmp_PauseforCursorDF:canceled
	Variable canceled= gCanceled			// Copy from global to local before global is killed
	if(canceled)
		GetMarquee/K
		Abort
	endif
		
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(graphName, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	WAVE partiotionWave = MXP_WAVE3DWavePartition(w3dref, "MXP_Partition", left, right, top, bottom)
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
	variable i = 0
	string mxpImage
	if(!strlen(GetBrowserSelection(0)))
		Abort "No image selected"
	endif
	
	do
		mxpImage = GetBrowserSelection(i) 
		print WaveDims($mxpImage)
		if(WaveDims($mxpImage) != 3 && WaveDims($mxpImage) != 2)
			Abort "Operation needs an image or image stack"
		endif
		NewImage $mxpImage
		ModifyGraph width={Plan,1,top,left}, expand=0.667
		if(WaveDims($mxpImage)==3)
			WMAppend3DImageSlider()
		endif
		i++
	while (strlen(GetBrowserSelection(i)))
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