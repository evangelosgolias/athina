#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Spaces
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
// ------------------------------------------------------- //
// Igor Spaces organises windows (Graphs, Tables, Layouts, Notebooks or Panels) in separate 
// Spaces. When a Space is selected in the panel, only windows linked to it are shown. 
// 
// Igor Spaces organises windows (Graphs, Tables, Layouts, Notebooks or Panels) in separate Spaces. 
// When a Space is selected in the panel, only windows linked to it are shown. 
// How it works: 
// 1. Launch Igor Spaces from "Windows/Packages" submenu. 
// 2. Press the "New" button to create a new Space, name should be unique, otherwise you will be 
// prompted to change your input. When a new "Space" is created it becomes your active working Space. 
// New Spaces are created below the active row selection, and at the moment you cannot change their order.
// 3.Press "Delete" to delete the selected space. Windows associated with the space are released and not 
// linked to any space ("" tag)
// 4. Press "All" to show/hide all windows whether linked to a Space or not.
// 5. When the Igor Spaces Panel is open any window you create is associated with the active Space.
// 6. Double click on a row to rename the Space
// 7. Press Shift + Click on a row of the ListBox to move the top window to the selected space
// 8. Press Alt + Click anywhere in the ListBox of the panel (rows or empty space below) to pin the top 
// window to all spaces (visible everywhere)
// 9. To unpin press Shift + Alt + Click anywhere in the ListBox to unpin the window (becomes free floating).
// You can also make a normal window free-floating using the same procedure. Alternatively, if you want to 
// unpin and link it to a space goto 7.
// 10. Use Ctlr + click to mark/unmark a space with an asterisk
// ------------------------------------------------------- //
///
/// TL;DR:
/// Use Shift + Click row to assign there the top window.
/// Double click: Rename
/// Alt + Click (empty space): Pin window
/// Shift + Alt + Click; unpin
/// Ctlr + click to mark/unmark a space with an asterisk
///
/// TODO: Move linked Panel/Graphs to the same Space
/// TODO: Change all the function and use the same algorithm as ATH_ShowWindowsOfSpaceTag

static Function MenuLauch()
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
	WAVE/Z/T/SDFR=dfr ATHSpacesTW
	NVAR/Z/SDFR=dfr gSelectedSpace
	NVAR/Z/SDFR=dfr gShowAllWindowsSwitch
	if(!WaveExists(ATHSpacesTW)) // If there is no text wave
		Make/T/N=1 dfr:ATHSpacesTW = "Main"
		variable/G dfr:gSelectedSpace = 0
		variable/G dfr:gShowAllWindowsSwitch = 0
	endif
	if(!(NVAR_Exists(gSelectedSpace) || NVAR_Exists(gShowAllWindowsSwitch)))
		variable/G dfr:gSelectedSpace = 0
		variable/G dfr:gShowAllWindowsSwitch = 0
	endif
	if(WinType("ATH_SpacesPanel")) // Will return 7 for a panel, 0 if it's not there 
		DoWindow/F ATH_SpacesPanel
	else
		MakePanel()
	endif
	return 0
End

static Function MakePanel()
	// Scale with IgorOptions here
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
	
	string igorInfoStr = StringByKey( "SCREEN1", IgorInfo(0)) // INFO: Change here if needed
	igorInfoStr = RemoveListItem(0, igorInfoStr, ",")		
	variable screenLeft, screenTop, screenRight, screenBottom, panelLeft, panelTop, panelRight, panelBottom
	sscanf igorInfoStr, "RECT=%d,%d,%d,%d", screenLeft, screenTop, screenRight, screenBottom
	variable screenWidth, screenLength, listlength, listwidth
	screenWidth = abs(screenRight - screenLeft)
	screenLength = abs(screenBottom - screenTop)
	
	// Tune 0.XXX coefficients
	if(screenWidth < 2000)
		panelLeft = screenWidth * 0.85
		panelRight = screenWidth
		panelTop = screenLength * 0.2
		panelBottom = screenLength * 0.8
		listlength = abs(panelBottom - panelTop) * 0.925
		listwidth = abs(panelRight - panelLeft)
	else
		panelLeft = screenWidth * 0.9
		panelRight = screenWidth
		panelTop = screenLength * 0.3
		panelBottom = screenLength * 0.7
		listlength = abs(panelBottom - panelTop) * 0.925
		listwidth = abs(panelRight - panelLeft)
	endif
	
	NVAR/Z/SDFR=dfr gSelectedSpace

	NewPanel /N=ATH_SpacesPanel/W=(panelLeft, panelTop, panelRight, panelBottom) as "ATH Spaces"
	SetDrawLayer UserBack
	Button NewSpace,pos={10,8.00},size={listwidth * 0.25,20.00},help={"Create new space"}
	Button NewSpace,fColor=(3,52428,1),proc=ATH_Spaces#NewSpaceButton
	Button DeleteSpace,pos={10 + listwidth * 0.075 + listwidth * 0.25,8.00},size={listwidth * 0.25,20.00},title="Delete"
	Button DeleteSpace,help={"Delete existing space"},fColor=(65535,16385,16385),proc=ATH_Spaces#DeleteSpaceButton
	Button ShowAll,pos={10 + listwidth * 0.075 * 2 + listwidth * 0.25 * 2,8.00},size={listwidth * 0.25,20.00},title="All"
	Button ShowAll,help={"Show all windows"},fColor=(32768,40777,65535),proc=ATH_Spaces#ShowAllButton
	ListBox listOfspaces,pos={1.00,37.00},size={listwidth,listlength},proc=ATH_Spaces#ListBoxFunction
	ListBox listOfspaces,fSize=14,frame=2,listWave=dfr:ATHSpacesTW,mode=2,selRow=gSelectedSpace
	return 0
End

static Function ListBoxFunction(STRUCT WMListboxAction &LB_Struct)

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
	WAVE/T/SDFR=dfr ATHSpacesTW
	NVAR/SDFR=dfr gSelectedSpace
	string msg, newSpaceNameStr, oldSpaceNameStr, winNameStr, buffer, prefix, listLinkedPP
	variable numSpaces = DimSize(ATHSpacesTW, 0)
	variable hookresult = 0, i
	switch(LB_Struct.eventCode)
		// INFO: When you click outside of entry cells in the ListBox you get maxListEntries as row selection!
		case -1: // Control being killed
			//Do nothing
			break
		case 1: // Mouse down
			gSelectedSpace = LB_Struct.row	
			if(gSelectedSpace > numSpaces - 1)
				gSelectedSpace = numSpaces - 1
			endif
			// Press Option (Mac) or Alt (Windows) and click anywhere in the Listbox to
			// pin the top window (show in all spaces).
			if(LB_Struct.eventMod == 5)
				winNameStr = WinName(1, 87, 0) // Top Window: Graph, Table, Layout, Notebook or Panel
				SetWindow $winNameStr userdata(ATH_SpacesTag) = "ATH__PinnedWindow__ATH" // Assign special tag for pinned window			
			endif
			// Press Shift+Option (Mac) or Shift+Alt (Windows) and click in the Listbox to
			// unpin the top window by setting an empty tag "" 
			if(LB_Struct.eventMod == 7)
				winNameStr = WinName(1, 87, 0) // Top Window: Graph, Table, Layout, Notebook or Panel
				SetWindow $winNameStr userdata(ATH_SpacesTag) = "" // Assign special tag for pinned window			
			endif	
			hookresult = 1
			break
		case 2: // Mouse up
			gSelectedSpace = LB_Struct.row
			if(gSelectedSpace > numSpaces - 1)
				gSelectedSpace = numSpaces - 1
			endif	
			hookresult = 1
			break
		case 3: // Double click
			gSelectedSpace = LB_Struct.row
			if (gSelectedSpace > numSpaces - 1)
				hookresult = 1
				break
			endif			
			msg = "Rename Space \"" + SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace]) + "\""
			oldSpaceNameStr = ATHSpacesTW[gSelectedSpace] // Do not sanitise now
			if(GrepString(oldSpaceNameStr, "^\*"))
				prefix = "*"
			else
				prefix = ""
			endif
			oldSpaceNameStr = SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace])
			newSpaceNameStr = TrimString(ATH_Dialog#GenericSingleStrPrompt("New name", msg))
			if(!UniqueSpaceNameQ(ATHSpacesTW, newSpaceNameStr) || !strlen(TrimString(newSpaceNameStr))|| GrepString(newSpaceNameStr, "^\*")) // if the name is not unique or empty string
				do
					newSpaceNameStr = TrimString(ATH_Dialog#GenericSingleStrPrompt("Space name already exists or string is empty or starts with *, enter a valid name:", \
																			"Enter a *unique* name for the new Space"))
				while(!UniqueSpaceNameQ(ATHSpacesTW, newSpaceNameStr) || !strlen(TrimString(newSpaceNameStr))|| GrepString(newSpaceNameStr, "^\*"))
			endif
			
			ATHSpacesTW[gSelectedSpace] = prefix + newSpaceNameStr
			
			RenameSpaceTagOnWindows(oldSpaceNameStr, newSpaceNameStr) // newSpaceNameStr has no * prefix!
			hookresult = 1
			break
		case 4: // Cell selection (mouse or arrow keys)
			gSelectedSpace = LB_Struct.row
			if(gSelectedSpace > numSpaces - 1)
				gSelectedSpace = numSpaces - 1
			endif
			if(LB_Struct.eventMod == 9) // If CTRL+click or CMD+click (Mac) is pressed in a row
				if(GrepString(ATHSpacesTW[gSelectedSpace], "^\*"))
					buffer = ATHSpacesTW[gSelectedSpace] 
					ATHSpacesTW[gSelectedSpace] = buffer[1, inf]
				else
					buffer = "*" + ATHSpacesTW[gSelectedSpace]
					ATHSpacesTW[gSelectedSpace] = buffer
				endif
			else
				ShowWindowsOfSpaceTag(SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace]), 1)	
			endif
			DoWindow/F $LB_Struct.win // Bring panel to the FG
			hookresult = 1
			break
		case 5: // Cell selection plus Shift key (Assign window to Space)
			// WinName(0, 87) is the "ATH Spaces" panel
			gSelectedSpace = LB_Struct.row
			if (gSelectedSpace > numSpaces - 1)
				hookresult = 1
				break
			endif
			winNameStr = WinName(1, 87, 0) // Top Window: Graph, Table, Layout, Notebook or Panel
			gSelectedSpace = LB_Struct.row
			SetWindow $winNameStr userdata(ATH_SpacesTag) = SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace]) // Assign tag to window
			// Do we have a linked panel?
			// List of known linked profile extensions (SumBeamsProfile, LineProfile, PlaneProfileZ)	
			listLinkedPP = "ImageSource;ImageSBP;ImageLPP;ImagePPZ" 
			for(i = 0; i < 4; i++) // Manually add here maxVal as ItemsInList(listLinkedPP)
				buffer = GetUserData(winNameStr, "", "ATH_LinkedWin" + StringFromList(i, listLinkedPP))
				if(strlen(buffer))
					SetWindow $buffer userdata(ATH_SpacesTag) = SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace]) // Assign tag to window
				endif
			endfor
			hookresult = 1
			break
	endswitch
	return hookresult
End

static Function NewSpaceButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
	WAVE/T/SDFR=dfr ATHSpacesTW
	variable index
	variable numEntries = DimSize(ATHSpacesTW, 0)
	NVAR/SDFR=dfr gSelectedSpace
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			string newSpaceNameStr = TrimString(ATH_Dialog#GenericSingleStrPrompt("New space name (not empty or starting with *):", "Enter the name of the new Space"))
			if(!UniqueSpaceNameQ(ATHSpacesTW, newSpaceNameStr) || !strlen(TrimString(newSpaceNameStr)) || GrepString(newSpaceNameStr, "^\*")) // if the name is not unique or empty string
				do
					newSpaceNameStr = TrimString(ATH_Dialog#GenericSingleStrPrompt("New space name (not empty or starting with *):", "Enter a *different* name for the new Space"))
				while(!UniqueSpaceNameQ(ATHSpacesTW, newSpaceNameStr) || !strlen(TrimString(newSpaceNameStr)) || GrepString(newSpaceNameStr, "^\*"))
			endif
			if (!numEntries) // If you have deleted all spaces
				index = 0
			else 
				index = gSelectedSpace + 1
			endif
			InsertPoints index, 1, ATHSpacesTW
			ATHSpacesTW[index] = newSpaceNameStr
			// Set the space you created as active
			ListBox listOfspaces, selRow = index
			gSelectedSpace = index
			ShowWindowsOfSpaceTag(newSpaceNameStr, 1) // Show windows of the new Space - No windows to show!
			break
	endswitch
End

static Function DeleteSpaceButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
	WAVE/T/SDFR=dfr ATHSpacesTW
	variable numSpaces = DimSize(ATHSpacesTW, 0)
	NVAR/SDFR=dfr gSelectedSpace
	string msg
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			if(numSpaces)
				if(gSelectedSpace > numSpaces - 1)
					gSelectedSpace = numSpaces - 1
				endif	
				msg = "Do you want to delete \"" + SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace]) + "\""
				DoAlert/T="You are about to delete a Space", 1, msg
				if(V_flag == 1)
					ClearWindowsFromSpaceTag(SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace])) // has to come first!
					DeletePoints gSelectedSpace, 1, ATHSpacesTW
					gSelectedSpace = gSelectedSpace == 0 ? 0: (gSelectedSpace - 1)
					ListBox listOfspaces, selRow = gSelectedSpace
				endif
			endif
			break
	endswitch
End

static Function ShowWindowsOfSpaceTag(string spaceTagStr, variable showSwitch)
	// showSwitch = 0 (hide window) 
	// showSwitch = 1 (show window)
	string winNameStr, getSpacetagStr
	string allWindowsStr = SortList(RemoveFromList("ATH_SpacesPanel",WinList("*",";","WIN:87")), ";", 16)
	variable i, imax = ItemsInList(allWindowsStr)
	
	for(i = 0; i < imax; i++)
		winNameStr = StringFromList(i, allWindowsStr)
		getSpacetagStr = GetUserData(winNameStr, "", "ATH_SpacesTag")
		if(!cmpstr(getSpacetagStr, spacetagStr, 0)) // comparison is case-insensitive. 		
			SetWindow $winNameStr hide = 1 - showSwitch // Match
		elseif(!cmpstr(getSpacetagStr, "ATH__PinnedWindow__ATH", 0)) // Pinned window
			SetWindow $winNameStr hide = 0 // Always show
		else
			SetWindow $winNameStr hide = showSwitch
		endif
	endfor
	return 0
End


static Function RenameSpaceTagOnWindows(string oldspaceTagStr, string newspaceTagStr)

	string winNameStr = "", getSpacetagStr
	variable i = 0 
	do
		i++
		winNameStr = WinName(i, 87, 0) // i = 0 is the ATH_SpacesPanel, so we skip checking it
		getSpacetagStr = GetUserData(winNameStr, "", "ATH_SpacesTag")
		if(!cmpstr(getSpacetagStr, oldspaceTagStr, 0)) // comparison is case-insensitive. 		
			SetWindow $winNameStr userdata(ATH_SpacesTag) = newspaceTagStr
		endif
	while(strlen(winNameStr))
	return 0
End

static Function ClearWindowsFromSpaceTag(string spaceTagStr)

	string winNameStr = "", getSpacetagStr
	variable i = 0 
	do
		i++
		winNameStr = WinName(i, 87, 0) // i = 0 is the ATH_SpacesPanel, so we skip checking it
		// Catch "" from setting SetWindow $"" hide = 1/0
		if(!strlen(winNameStr))
			break
		endif
		getSpacetagStr = GetUserData(winNameStr, "", "ATH_SpacesTag")
		if(!cmpstr(getSpacetagStr, spacetagStr, 0)) // comparison is case-insensitive. 		
			SetWindow $winNameStr userdata(ATH_SpacesTag) = ""
		endif
	while(strlen(winNameStr))
	return 0
End

static Function ShowAllButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
	NVAR/SDFR=dfr gShowAllWindowsSwitch
	variable showSwitch
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			showSwitch = 1 - gShowAllWindowsSwitch
			if(showSwitch)
				gShowAllWindowsSwitch = 1
				ShowAllWindows(0)
			else
				gShowAllWindowsSwitch = 0
				ShowAllWindows(1)
			endif
			break
	endswitch
End

static Function ShowAllWindows(variable showSwitch)
	// showSwitch = 0 (hide window) 
	// showSwitch = 1 (show window)
	string winNameStr
	variable i = 0 
	do
		i++
		winNameStr = WinName(i, 87, 0)
		// Catch "" from setting SetWindow $"" hide = 1/0
		if(!strlen(winNameStr))
			break
		endif
		if(!cmpstr(winNameStr, "ATH_SpacesPanel", 0))
			continue
		endif
		SetWindow $winNameStr hide = 1 - showSwitch
	while(strlen(winNameStr))
	return 0
End

static Function UniqueSpaceNameQ(WAVE/T textW, string spaceNameStr)
	/// Return true of spaceNameStr in not an element of textW (case-insensitive), i.e it is Unique
	variable numEntries = DimSize(textW, 0), i
	
	for(i = 0; i < numEntries; i++)
		if(!cmpstr(SanitiseATHSpaceName(textW[i]), spaceNameStr))
			return 0
		endif
	endfor
	return 1
End

static Function/S SanitiseATHSpaceName(string spaceNameStr)
	if(GrepString(spaceNameStr, "^\*"))
		return spaceNameStr[1,inf]
	else
		return spaceNameStr
	endif
End