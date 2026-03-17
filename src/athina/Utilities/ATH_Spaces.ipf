#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Spaces
#pragma version = 1.2

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

/// @module ATH_Spaces
/// @brief Module ATH_Spaces.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH Spaces functionality.

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
// 10. Use Ctlr + click to mark/unmark a space with an asterisk and link it to the selected data folder in the data browser. 
// When selecting a Space with an asterisk the current data folder changes to the linked data folder.
// ------------------------------------------------------- //
///
/// TL;DR:
/// SHIFT+Click: on a Space to associate with the top window.
/// Double-click: Rename the Space.
/// ALT+click (on an enpty row NOT a space): Pin top window to all Spaces.
/// SHIFT+ALT+click: unpin top window and make (now with no Space link, i.e. orphan).
/// CTRL+click (CMD+click on MacOS): link space to the selected data folder in Data Browser 
/// (now marked with an asterisk). Current data folder changes when you select spaces with asterisk.

/// @function MenuLaunch
/// @brief Description of MenuLaunch.
/// @details
/// Auto-generated documentation stub for function `MenuLaunch`.
/// @returns Variable Return value.

static Function MenuLaunch()
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
	WAVE/Z/T/SDFR=dfr ATHSpacesTW
	NVAR/Z/SDFR=dfr gSelectedSpace
	NVAR/Z/SDFR=dfr gShowAllWindowsSwitch
	if(!WaveExists(ATHSpacesTW)) // If there is no text wave
		Make/T/N=1 dfr:ATHSpacesTW = "Main"
		Make/T/N=1 dfr:ATHSpacesTWDF
		variable/G dfr:gSelectedSpace = 0
		variable/G dfr:gShowAllWindowsSwitch = 0
		variable/G dfr:gShowOrphanWindowsSwitch = 0
	endif
	if(!(NVAR_Exists(gSelectedSpace) || NVAR_Exists(gShowAllWindowsSwitch)))
		variable/G dfr:gSelectedSpace = 0
		variable/G dfr:gShowAllWindowsSwitch = 0
		variable/G dfr:gShowOrphanWindowsSwitch = 0		
	endif
	if(WinType("ATH_SpacesPanel")) // Will return 7 for a panel, 0 if it's not there 
		DoWindow/F ATH_SpacesPanel
	else
		MakePanel()
	endif
	return 0
End

/// @function MakePanel
/// @brief Description of MakePanel.
/// @details
/// Auto-generated documentation stub for function `MakePanel`.
/// @returns Variable Return value.

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
	panelLeft = screenWidth * 0.85
	panelRight = screenWidth
	panelTop = screenLength * 0.2
	panelBottom = screenLength * 0.8
	listlength = abs(panelBottom - panelTop) * 0.925
	listwidth = abs(panelRight - panelLeft)
	NVAR/Z/SDFR=dfr gSelectedSpace
	NewPanel /N=ATH_SpacesPanel/W=(panelLeft, panelTop, panelRight, panelBottom) as "ATH Spaces"
	SetDrawLayer UserBack
	Button NewSpaceB, pos={20,8.00},size={listwidth * 0.3333,20.00},help={"Create new space"},fColor=(3,52428,1)
	Button DeleteSpaceB, pos={(20 + listwidth * 0.5),8.00},size={listwidth * 0.3333,20.00},title="Delete"
	Button DeleteSpaceB, help={"Delete existing space"},fColor=(65535,16385,16385)
	Button ShowAllB, pos={20,35},size={listwidth * 0.3333,20.00},title="All"
	Button ShowAllB, help={"Show all windows"},fColor=(32768,40777,65535)
	Button ShowOrphansB, help={"Show windows with no tag"}, title = "Orphans", fColor=(65535,65533,32768)
	Button ShowOrphansB, pos={(20 + listwidth * 0.5),35},size={listwidth * 0.3333,20.00}
	ListBox listOfspaces, pos={1.00,60},size={listwidth,listlength},proc=ATH_Spaces#ListBoxFunction
	ListBox listOfspaces, fSize=14,frame=2,listWave=dfr:ATHSpacesTW,mode=2,selRow=gSelectedSpace
	// Add a help string
	string helpStr = "- SHIFT+Click: on a Space to associate with the top window.\n- Double-click: Rename the Space.\n- " +\
	"ALT+click (on an enpty row NOT a space): Pin top window to all Spaces.\n- SHIFT+ALT+click: unpin top window and make it an orphan.\n- "+\
	"CTRL+click(CMD+click): link space to the selected data folder in Data Browser (now marked with an asterisk).\nCurrent data folder changes when you select spaces with asterisk."
	TitleBox HelpTitle, title = "?", pos={(20 + listwidth * 0.4),20}, frame=0, fSize=14,fstyle=1, fColor=(65535,0,0), labelBack=(65535,49151,55704), help={helpStr}
	
	ModifyControlList ControlNameList("ATH_SpacesPanel",";","*B") proc=ATH_Spaces#SpacesButton,win=ATH_SpacesPanel

	return 0
End

Static Function SpacesButton(STRUCT WMButtonAction &s)

	if (s.eventCode != 2)
		return 0
	endif

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
	WAVE/T/SDFR=dfr ATHSpacesTW, ATHSpacesTWDF
	variable index, showSwitchAll, showSwitchOrphans
	variable numSpaces = DimSize(ATHSpacesTW, 0)
	string msg
	NVAR/SDFR=dfr gSelectedSpace
	NVAR/SDFR=dfr gShowAllWindowsSwitch
	NVAR/SDFR=dfr gShowOrphanWindowsSwitch
	strswitch (s.ctrlName)
		case "NewSpaceB":
			string newSpaceNameStr = TrimString(ATH_Dialog#GenericSingleStrPrompt("New space name (not empty or starting with *):", "Enter the name of the new Space"))
			if(!UniqueSpaceNameQ(ATHSpacesTW, newSpaceNameStr) || !strlen(TrimString(newSpaceNameStr)) || GrepString(newSpaceNameStr, "^\*")) // if the name is not unique or empty string
				do
					newSpaceNameStr = TrimString(ATH_Dialog#GenericSingleStrPrompt("New space name (not empty or starting with *):", "Enter a *different* name for the new Space"))
				while(!UniqueSpaceNameQ(ATHSpacesTW, newSpaceNameStr) || !strlen(TrimString(newSpaceNameStr)) || GrepString(newSpaceNameStr, "^\*"))
			endif
			if (!numSpaces) // If you have deleted all spaces
				index = 0
			else
				index = gSelectedSpace + 1
			endif
			InsertPoints index, 1, ATHSpacesTW
			InsertPoints index, 1, ATHSpacesTWDF
			ATHSpacesTW[index] = newSpaceNameStr
			// Set the space you created as active
			ListBox listOfspaces, selRow = index
			gSelectedSpace = index
			ShowWindowsOfSpaceTag(newSpaceNameStr, 1) // Show windows of the new Space - No windows to show!
			break
		case "DeleteSpaceB":
			if(numSpaces)
				if(gSelectedSpace > numSpaces - 1)
					gSelectedSpace = numSpaces - 1
				endif
				msg = "Do you want to delete \"" + SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace]) + "\""
				DoAlert/T="You are about to delete a Space", 1, msg
				if(V_flag == 1)
					ClearWindowsFromSpaceTag(SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace])) // has to come first!
					DeletePoints gSelectedSpace, 1, ATHSpacesTW
					DeletePoints gSelectedSpace, 1, ATHSpacesTWDF
					gSelectedSpace = gSelectedSpace == 0 ? 0: (gSelectedSpace - 1)
					ListBox listOfspaces, selRow = gSelectedSpace
				endif
			endif
			break
		case "ShowAllB":
			showSwitchAll = 1 - gShowAllWindowsSwitch
			ModifyControl ShowOrphansB, valueColor=(0,0,0), win=ATH_SpacesPanel
			if(showSwitchAll)
				gShowAllWindowsSwitch = 1
				ModifyControl ShowAllB, valueColor=(65535,0,0), win=ATH_SpacesPanel			
				ShowAllWindows(0)
			else
				gShowAllWindowsSwitch = 0
				ModifyControl ShowAllB, valueColor=(2,39321,1), win=ATH_SpacesPanel			
				ShowAllWindows(1)
			endif
			break
		case "ShowOrphansB":
			showSwitchOrphans = 1 - gShowOrphanWindowsSwitch
			ModifyControl ShowAllB, valueColor=(0,0,0), win=ATH_SpacesPanel	
			if(showSwitchOrphans)
				gShowOrphanWindowsSwitch = 1
				ModifyControl ShowOrphansB, valueColor=(65535,0,0), win=ATH_SpacesPanel
				ShowOrphanWindows(0)
			else
				gShowOrphanWindowsSwitch = 0
				ModifyControl ShowOrphansB, valueColor=(2,39321,1), win=ATH_SpacesPanel
				ShowOrphanWindows(1)
			endif
			break
	endswitch
	return 0
End

/// @function ListBoxFunction
/// @brief Description of ListBoxFunction.
/// @details
/// Auto-generated documentation stub for function `ListBoxFunction`.
/// @param &LB_Struct Parameter &LB_Struct.
/// @returns Variable Return value.

static Function ListBoxFunction(STRUCT WMListboxAction &LB_Struct)

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
	WAVE/T/SDFR=dfr ATHSpacesTW, ATHSpacesTWDF
	NVAR/SDFR=dfr gSelectedSpace
	string msg, newSpaceNameStr, oldSpaceNameStr, winNameStr, buffer, prefix, listLinkedPP, linkedFolder
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
			if(GrepString(ATHSpacesTW[gSelectedSpace], "^\*") && strlen(ATHSpacesTWDF[gSelectedSpace]))
				SetDataFolder ATHSpacesTWDF[gSelectedSpace]
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
			newSpaceNameStr = oldSpaceNameStr // start with the old string, help with correcting typos
			Prompt newSpaceNameStr, "New name"
			DoPrompt "Change name of Space", newSpaceNameStr
			if(V_flag)
				return 1
			endif
			newSpaceNameStr = TrimString(newSpaceNameStr)
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
				winNameStr = WinName(1, 87, 0) // Top Window: Graph, Table, Layout, Notebook or Panel
				if(GrepString(ATHSpacesTW[gSelectedSpace], "^\*"))
					buffer = ATHSpacesTW[gSelectedSpace] 
					ATHSpacesTW[gSelectedSpace] = buffer[1, inf]
					ATHSpacesTWDF[gSelectedSpace] = ""
				else
					linkedFolder = GetBrowserSelection(0);variable errorCode = GetRTError(1)
					if(errorCode)
						print "athinaSpacesError: " + GetErrMessage(errorCode, 3)
					else
						buffer = "*" + ATHSpacesTW[gSelectedSpace]
						ATHSpacesTW[gSelectedSpace] = buffer
						if(exists(linkedFolder)==1)
							ATHSpacesTWDF[gSelectedSpace] = GetWavesDataFolder($linkedFolder,1)
						elseif(exists(linkedFolder)==2)
							ATHSpacesTWDF[gSelectedSpace] = ParseFilePath(1, linkedFolder, ":", 1, 0)
						elseif(DataFolderExists(linkedFolder))
							ATHSpacesTWDF[gSelectedSpace] = linkedFolder
						else // Remove asterisk, did not catch a directory
							buffer = ATHSpacesTW[gSelectedSpace] 
							ATHSpacesTW[gSelectedSpace] = buffer[1, inf]
							ATHSpacesTWDF[gSelectedSpace] = ""
						endif
					endif
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
			listLinkedPP = "ImageSource;ImageZPP;ImageLPP;ImagePPZ;iXPSPP" 
			for(i = 0; i < 5; i++) // Manually add here maxVal as ItemsInList(listLinkedPP)
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

/// @function ShowWindowsOfSpaceTag
/// @brief Description of ShowWindowsOfSpaceTag.
/// @details
/// Auto-generated documentation stub for function `ShowWindowsOfSpaceTag`.
/// @param spaceTagStr Parameter spaceTagStr.
/// @param showSwitch Parameter showSwitch.
/// @returns Variable Return value.

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

/// @function RenameSpaceTagOnWindows
/// @brief Description of RenameSpaceTagOnWindows.
/// @details
/// Auto-generated documentation stub for function `RenameSpaceTagOnWindows`.
/// @param oldspaceTagStr Parameter oldspaceTagStr.
/// @param newspaceTagStr Parameter newspaceTagStr.
/// @returns Variable Return value.


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

/// @function ClearWindowsFromSpaceTag
/// @brief Description of ClearWindowsFromSpaceTag.
/// @details
/// Auto-generated documentation stub for function `ClearWindowsFromSpaceTag`.
/// @param spaceTagStr Parameter spaceTagStr.
/// @returns Variable Return value.

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

/// @function UniqueSpaceNameQ
/// @brief Description of UniqueSpaceNameQ.
/// @details
/// Auto-generated documentation stub for function `UniqueSpaceNameQ`.
/// @param textW Parameter textW.
/// @param spaceNameStr Parameter spaceNameStr.
/// @returns Variable Return value.

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

/// @function SanitiseATHSpaceName
/// @brief Description of SanitiseATHSpaceName.
/// @details
/// Auto-generated documentation stub for function `SanitiseATHSpaceName`.
/// @param spaceNameStr Parameter spaceNameStr.
/// @returns String Return value.

static Function/S SanitiseATHSpaceName(string spaceNameStr)
	if(GrepString(spaceNameStr, "^\*"))
		return spaceNameStr[1,inf]
	else
		return spaceNameStr
	endif
End

/// @function ShowAllWindows
/// @brief Description of ShowAllWindows.
/// @details
/// Auto-generated documentation stub for function `ShowAllWindows`.
/// @param showSwitch Parameter showSwitch.
/// @returns Variable Return value.

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

/// @function ShowOrphanWindows
/// @brief Description of ShowOrphanWindows.
/// @details
/// Auto-generated documentation stub for function `ShowOrphanWindows`.
/// @param showSwitch Parameter showSwitch.
/// @returns Variable Return value.

static Function ShowOrphanWindows(variable showSwitch)
	// Show windows with no tag
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
		if(!strlen(getSpacetagStr))
			SetWindow $winNameStr hide = 1 - showSwitch
		else 
			SetWindow $winNameStr hide = showSwitch
		endif
	while(strlen(winNameStr))
	return 0
End
