#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Dialog
#pragma version = 1.01
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

/// @module ATH_Dialog
/// @brief Module ATH_Dialog.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH Dialog functionality.


/// @function GenericSinglePopupStrPrompt
/// @brief Prompt for one value chosen from a pop-up list.
/// @param strPrompt Prompt text shown beside the input control.
/// @param popupStrSelection Semicolon-separated choices for the pop-up control.
/// @param msgDialog Title or explanatory text for the prompt dialog.
/// @returns The selected pop-up item, or an empty string if the dialog is cancelled.
static Function/S GenericSinglePopupStrPrompt(string strPrompt, string popupStrSelection, string msgDialog)
	string returnStrVar 
	Prompt returnStrVar, strPrompt, popup, popupStrSelection
	DoPrompt msgDialog, returnStrVar
	if(V_flag)
		Abort
	endif
	return returnStrVar
End

/// @function GenericSingleStrPrompt
/// @brief Prompt for one text value.
/// @param strPrompt Prompt text shown beside the input control.
/// @param msgDialog Title or explanatory text for the prompt dialog.
/// @returns The entered text, or an empty string if the dialog is cancelled.
static Function/S GenericSingleStrPrompt(string strPrompt, string msgDialog)
	string returnStrVar 
	Prompt returnStrVar, strPrompt
	DoPrompt msgDialog, returnStrVar
	if(V_flag)
		Abort
	endif
	return returnStrVar
End

/// @function GenericSingleStrPromptAndPopup
/// @brief Prompt for one pop-up selection and one text value.
/// @param strPrompt1 Prompt text for the first value.
/// @param strPrompt2 Prompt text for the second value.
/// @param popupStrSelection1 Choices for the first pop-up control.
/// @param msgDialog Title or explanatory text for the prompt dialog.
/// @returns The entered text and the selected pop-up item.
static Function [string returnStrVar1, string returnStrVar2] GenericSingleStrPromptAndPopup(string strPrompt1,string strPrompt2, string popupStrSelection1, string msgDialog)
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

/// @function GenericDoubleStrPromptPopup
/// @brief Prompt for two values chosen from pop-up lists.
/// @param strPrompt1 Prompt text for the first value.
/// @param strPrompt2 Prompt text for the second value.
/// @param popupStrSelection1 Choices for the first pop-up control.
/// @param popupStrSelection2 Choices for the second pop-up control.
/// @param msgDialog Title or explanatory text for the prompt dialog.
/// @returns The two selected pop-up items.
static Function [string returnStrVar1, string returnStrVar2] GenericDoubleStrPromptPopup(string strPrompt1, string strPrompt2, string popupStrSelection1, string popupStrSelection2, string msgDialog)
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

/// @function GenericDoubleStrPrompt
/// @brief Prompt for two text values.
/// @param strPrompt1 Prompt text for the first value.
/// @param strPrompt2 Prompt text for the second value.
/// @param msgDialog Title or explanatory text for the prompt dialog.
/// @returns The two entered text values.
static Function [string returnStrVar1, string returnStrVar2] GenericDoubleStrPrompt(string strPrompt1, string strPrompt2, string msgDialog)
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

// Browser selection

/// @function SelectWavesInModalDataBrowser
/// @brief Open a modal Data Browser and return the selected waves.
/// @param msg Message displayed to the user.
/// @returns A semicolon-separated list of selected wave paths, or an empty string if none are selected.
static Function/S SelectWavesInModalDataBrowser(string msg)
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
		return ""
	endif
	
	return S_BrowserList
End

/// Helper function

/// @function CountSelectedObjectsInDataBrowser
/// @brief Count all objects selected in the Data Browser.
/// @details
/// Return how many objects of any kind you have selected in the data browser.
/// @returns The number of matching items.
static Function CountSelectedObjectsInDataBrowser()
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

/// @function CountSelectedWavesInDataBrowser
/// @brief Count waves selected in the Data Browser, optionally by dimensionality.
/// @details
/// Return how many waves are selected in the data browser. Function returns selected waves of dimensionality
/// wDims.
/// @param wDim (optional) Wave dimensionality to require; zero counts waves of any dimensionality.
/// @returns The number of matching items.
static Function CountSelectedWavesInDataBrowser([variable wDim])
	/// return how many waves are selected in the data browser
	/// Function returns selected waves of dimensionality wDims
	/// if the optional argument is set.
	
	wDim = ParamIsDefault(wDim) ? 0: wDim
	if(wDim < 0 || wDim > 5)
		return NaN // Bad arguments
	endif
	
	string selectedItemStr
	variable cnt = 0 , i = 0
	if(!strlen(GetBrowserSelection(0)))
		return 0
	endif
	do
		selectedItemStr = GetBrowserSelection(i)
		i++
		if((exists(selectedItemStr) == 1 && !wDim) \
		|| (exists(selectedItemStr) == 1 && WaveDims($selectedItemStr) == wDim))
			cnt++
		endif
	while (strlen(GetBrowserSelection(i)))
	return cnt
End

/// @function GetSelectedWavesInDataBrowser
/// @brief Return waves selected in the Data Browser, optionally filtered by dimensionality.
/// @param wDim (optional) Required wave dimensionality; zero accepts any dimensionality.
/// @returns A semicolon-separated list of selected wave paths matching the dimensionality filter.
static Function/S GetSelectedWavesInDataBrowser([variable wDim])
	/// returns a string list with selected wave in the data browser
	/// selects only waves with wDim if variable is set.
	
	wDim = ParamIsDefault(wDim) ? 0: wDim

	if(wDim < 0 || wDim > 5)
		return "" // Bad arguments
	endif
	
	string selectedItemStr, allItemsStr= ""
	variable i = 0
	if(!strlen(GetBrowserSelection(0)))
		return ""
	endif
	do
		selectedItemStr = GetBrowserSelection(i)
		i++
		if((exists(selectedItemStr) == 1 && !wDim) \
		|| (exists(selectedItemStr) == 1 && WaveDims($selectedItemStr) == wDim))
			allItemsStr += selectedItemStr +";"
		endif
	while (strlen(GetBrowserSelection(i)))
	return allItemsStr
End

// ----------
// The following three function let you wait until you complete an operation on a window
// For sUserMarqueePositions check MarqueeOperations.ipf
//
// Code does not work, check similar function in MarqueeOperations.ipf

/// @function WaitForUserActions
/// @brief Open a modal panel and wait for the user to continue or cancel.
/// @param s Input/output structure carrying the operation's settings and results.
/// @param vWinType (optional) Igor window-type code used to choose the parent window; defaults to a graph.
/// @returns One if the user cancels; zero if the user continues.
static Function WaitForUserActions(STRUCT sUserMarqueePositions &s, [variable vWinType])
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
	Button buttonContinue, win=$panelNameStr, pos={80,50},size={92,20}, title="Continue", proc=ATH_Dialog#WaitForUserActions_ContButtonProc 
	Button buttonCancel, win=$panelNameStr, pos={80,80},size={92,20}, title="Cancel", proc=ATH_Dialog#WaitForUserActions_CancelBProc
	SetWindow $winNameStr userdata(sCoords)=structStr 
	SetWindow $winNameStr userdata(spanelNameStr)= panelNameStr
	SetWindow $panelNameStr userdata(swinNameStr) = winNameStr 
	SetWindow $panelNameStr userdata(spanelNameStr) = panelNameStr
	PauseForUser $panelNameStr, $winNameStr
	StructGet/S s, GetUserData(winNameStr, "", "sCoords")
	
	if(s.canceled)
		return 1
	endif
	return 0
End

/// @function WaitForUserActions_ContButtonProc
/// @brief Handle the continue button in the modal user-action panel.
/// @details
/// Dispatches the relevant Igor control event and ignores unsupported event codes.
/// @param B_Struct Igor action structure describing the control or window event.
/// @returns Igor callback status; nonzero indicates that the event was handled.
static Function WaitForUserActions_ContButtonProc(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			STRUCT sUserMarqueePositions s
			string winNameStr = GetUserData(B_Struct.win, "", "swinNameStr")
			StructGet/S s, GetUserData(winNameStr, "", "sCoords")
			s.canceled = 0
			KillWindow/Z $GetUserData(B_Struct.win, "", "spanelNameStr")
			break
	endswitch
	return 0
End

/// @function WaitForUserActions_CancelBProc
/// @brief Handle the cancel button in the modal user-action panel.
/// @details
/// End of wait to complete operations.
/// @param B_Struct Igor action structure describing the control or window event.
/// @returns Igor callback status; nonzero indicates that the event was handled.
static Function WaitForUserActions_CancelBProc(STRUCT WMButtonAction &B_Struct) : ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			STRUCT sUserMarqueePositions s
			string winNameStr = GetUserData(B_Struct.win, "", "swinNameStr")
			StructGet/S s, GetUserData(winNameStr, "", "sCoords")
			string structStr
			s.canceled = 1
			StructPut/S s, structStr
			SetWindow $winNameStr userdata(sCoords) = structStr
			KillWindow/Z $GetUserData(B_Struct.win, "", "spanelNameStr")
			break
	endswitch
	return 0
End
// End of wait to complete operations
