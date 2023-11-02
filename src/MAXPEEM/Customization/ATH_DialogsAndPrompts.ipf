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

// ----------
// The following three function let you wait until you complete an operation on a window
// For sUserMarqueePositions check ATH_MarqueeOperations.ipf
//
// Code does not work, check similar function in ATH_MarqueeOperations.ipf

Function ATH_WaitForUserActions(STRUCT sUserMarqueePositions &s, [variable vWinType])
	// vWinType = 1 (default) graphs
	// vWinType = 2 Tables
	// vWinType = 4 Layout
	// vWinType = 16 Notebooks
	// vWinType = 16 Panels	
	vWinType = ParamIsDefault(vWinType) ? 1 : vWinType
	string winNameStr = WinName(0, vWinType, 1)	
	DoWindow/F $winNameStr			// Bring graph to front
//	if (V_Flag == 0)					// Verify that graph exists
//		Abort "WM_UserSetMarquee: No image in top window."
//	endif
	string structStr
	string panelNameStr = UniqueName("PauseforDecision", 9, 0)
	NewPanel/N=$panelNameStr/K=2/W=(139,341,382,450) as "Athina"
	AutoPositionWindow/E/M=1/R=$winNameStr			// Put panel near the graph
	
	StructPut /S s, structStr
	DrawText 15,20,"Continue or cancel ?"
	Button buttonContinue, win=$panelNameStr, pos={80,50},size={92,20}, title="Continue", proc=ATH_WaitForUserActions_ContButtonProc 
	Button buttonCancel, win=$panelNameStr, pos={80,80},size={92,20}, title="Cancel", proc=ATH_WaitForUserActions_CancelBProc
	SetWindow $winNameStr userdata(sATH_Coords)=structStr 
	SetWindow $winNameStr userdata(sATH_panelNameStr)= panelNameStr
	SetWindow $panelNameStr userdata(sATH_winNameStr) = winNameStr 
	SetWindow $panelNameStr userdata(sATH_panelNameStr) = panelNameStr
	PauseForUser $panelNameStr, $winNameStr
	StructGet/S s, GetUserData(winNameStr, "", "sATH_Coords")
	
	if(s.canceled)
		return 1
	endif
	return 0
End

Function ATH_WaitForUserActions_ContButtonProc(STRUCT WMButtonAction &B_Struct): ButtonControl
	STRUCT sUserMarqueePositions s
	string winNameStr = GetUserData(B_Struct.win, "", "sATH_winNameStr")
	StructGet/S s, GetUserData(winNameStr, "", "sATH_Coords")	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			s.canceled = 0
			KillWindow/Z $GetUserData(B_Struct.win, "", "sATH_panelNameStr")
			break
	endswitch
	return 0
End

Function ATH_WaitForUserActions_CancelBProc(STRUCT WMButtonAction &B_Struct) : ButtonControl
	STRUCT sUserMarqueePositions s
	string winNameStr = GetUserData(B_Struct.win, "", "sATH_winNameStr")
	StructGet/S s, GetUserData(winNameStr, "", "sATH_Coords")
	string structStr	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			s.canceled = 1
			StructPut/S s, structStr
			SetWindow $winNameStr userdata(sATH_Coords) = structStr	
			KillWindow/Z $GetUserData(B_Struct.win, "", "sATH_panelNameStr")			
			break
	endswitch
	return 0
End
// End of wait to complete operations