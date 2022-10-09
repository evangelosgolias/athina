#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// Launchers
Function MXP_Launchake3DWaveUsingPattern()
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
	MXP_LoadDATFilesFromFolder("", "*", switch3d = 1, wname3d = wNameStr)

End

Function MXP_LaunchAverageStackToImage()
	string waveListStr = Wavelist("*",";","DIMS:3"), selectWaveStr, waveNameStr
	string strPrompt1 = "Select stack"
	string strPrompt2 = "Enter averaged wave nane (leave empty for MXP_AvgStack)"
	string msgDialog = "Average a stack (3d wave) in working DF"
	[selectWaveStr, waveNameStr] = MXP_GenericSingleStrPromptAndPopup(strPrompt1, strPrompt2, waveListStr, msgDialog)
	MXP_AverageStackToImage($selectWaveStr, avgImageName = waveNameStr)
End

Function MXP_LaunchMXP_ImageStackAlignmentByCorrelation()
	string waveListStr = Wavelist("*",";","DIMS:3"), selectWaveStr
	variable printMode = 2
	variable useThreads = 2
	variable layerN = 0
	Prompt selectWaveStr, "img1", popup, waveListStr
	Prompt printMode, "Print layer drift", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt layerN, "Reference layer"
	Prompt useThreads, "Use threads", popup, "Yes;No" // Yes = 1, No = 2!
	DoPrompt "Align image stack by (auto)correlation (int pixel drift)", selectWaveStr, layerN, printMode, useThreads
	
	if(V_flag) // User cancelled
		return 1
	endif
	MXP_ImageStackAlignmentByCorrelation($selectWaveStr, layerN = layerN, printMode = printMode - 2, useThreads = useThreads - 2)
	print PossiblyQuoteName(selectWaveStr + "_undo") + " has been created. To restore " + PossiblyQuoteName(selectWaveStr) + " run the command:\n"
	print "Duplicate/O " + PossiblyQuoteName(selectWaveStr + "_undo") + ", " +  PossiblyQuoteName(selectWaveStr) + "; " + \
		  "KillWaves/Z " + PossiblyQuoteName(selectWaveStr + "_undo")
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