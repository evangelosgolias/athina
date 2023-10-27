// --------------------------- Helper functions ------------------------------------//
// Dialogs
Function/S ATH_GenericSinglePopupStrPrompt(string strPrompt, string popupStrSelection, string msgDialog)
	string returnStrVar 
	Prompt returnStrVar, strPrompt, popup, popupStrSelection
	DoPrompt msgDialog, returnStrVar
	if(V_flag)
		Abort
	endif
	return returnStrVar
End

Function/S ATH_GenericSingleStrPrompt(string strPrompt, string msgDialog)
	string returnStrVar 
	Prompt returnStrVar, strPrompt
	DoPrompt msgDialog, returnStrVar
	if(V_flag)
		Abort
	endif
	return returnStrVar
End

Function [string returnStrVar1, string returnStrVar2] ATH_GenericSingleStrPromptAndPopup(string strPrompt1,string strPrompt2, string popupStrSelection1, string msgDialog)
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

Function [string returnStrVar1, string returnStrVar2] ATH_GenericDoubleStrPromptPopup(string strPrompt1, string strPrompt2, string popupStrSelection1, string popupStrSelection2, string msgDialog)
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

Function [string returnStrVar1, string returnStrVar2] ATH_GenericDoubleStrPrompt(string strPrompt1, string strPrompt2, string msgDialog)
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

Function ATH_GenericSingleVarPrompt(string strPrompt, string msgDialog)
	variable returnVar 
	Prompt returnVar, strPrompt
	DoPrompt msgDialog, returnVar
	if(V_flag)
		return -1
	endif
	return returnVar
End

// Browser selection

Function/S ATH_SelectWavesInModalDataBrowser(string msg)
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

Function ATH_CountSelectedObjectsInDataBrowser()
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

Function ATH_CountSelectedWavesInDataBrowser([variable waveDimemsions])
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
