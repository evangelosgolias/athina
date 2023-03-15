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

/// Use Shift + Space row to assign there the top window.
/// Double click to Rename
/// New - Creates a new Space
/// Delete - Deletes a Space
/// All - Show/hide all windows (Graph, Table, Layout, Notebook or Panel)
/// TODO: Move linked Panel/Graphs to the same Space
/// TODO: Implement drag to rearrange spaces

Function MXP_MainMenuLaunchSpaces()
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	WAVE/Z/T/SDFR=dfr mxpSpacesTW
	NVAR/Z/SDFR=dfr gSelectedSpace
	NVAR/Z/SDFR=dfr gShowAllWindowsSwitch
	if(!WaveExists(mxpSpacesTW)) // If there is no text wave
		Make/T/N=1 dfr:mxpSpacesTW = "Default"
		variable/G dfr:gSelectedSpace = 0
		variable/G dfr:gShowAllWindowsSwitch = 0
	endif
	if(!(NVAR_Exists(gSelectedSpace) || NVAR_Exists(gShowAllWindowsSwitch)))
		variable/G dfr:gSelectedSpace = 0
		variable/G dfr:gShowAllWindowsSwitch = 0
	endif
	if(WinType("MXP_SpacesPanel")) // Will return 7 for a panel, 0 if it's not there 
		DoWindow/F MXP_SpacesPanel
	else
		MXP_MakeSpacesPanel()
	endif
	return 0
End

Function MXP_MakeSpacesPanel()
	// Scale with IgorOptions here
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	
	string igorInfoStr = StringByKey( "SCREEN1", IgorInfo(0)) // INFO: Change here if needed
	igorInfoStr = RemoveListItem(0, igorInfoStr, ",")		
	variable screenLeft, screenTop, screenRight, screenBottom, panelLeft, panelTop, panelRight, panelBottom
	sscanf igorInfoStr, "RECT=%d,%d,%d,%d", screenLeft, screenTop, screenRight, screenBottom
	variable screenWidth, screenLength, listlength, listwidth
	screenWidth = abs(screenRight - screenLeft)
	screenLength = abs(screenBottom - screenTop)

	
	// TODO: Experimental scaling -- Not great atm.
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

	NewPanel /N=MXP_SpacesPanel/W=(panelLeft, panelTop, panelRight, panelBottom) as "MXP Spaces"
	SetDrawLayer UserBack
	Button NewSpace,pos={5,8.00},size={listwidth * 0.25,20.00},help={"Create new space"}
	Button NewSpace,fColor=(3,52428,1),proc=MXP_ListBoxSpacesNewSpace
	Button DeleteSpace,pos={5 + listwidth * 0.05 + listwidth * 0.25,8.00},size={listwidth * 0.25,20.00},title="Delete"
	Button DeleteSpace,help={"Delete existing space"},fColor=(65535,16385,16385),proc=MXP_ListBoxSpacesDeleteSpace
	ListBox listOfspaces,pos={1.00,37.00},size={listwidth,listlength},proc=MXP_ListBoxSpacesHookFunction
	ListBox listOfspaces,fSize=14,frame=2,listWave=dfr:mxpSpacesTW,mode=2,selRow=0
	Button ShowAll,pos={5 + listwidth * 0.05 * 2 + listwidth * 0.25 * 2,8.00},size={listwidth * 0.25,20.00},title="All"
	Button ShowAll,help={"Show all windows"},fColor=(32768,40777,65535),proc=MXP_ListBoxSpacesShowAll
	return 0
End

// AfterWindowCreatedHook

Function AfterWindowCreatedHook(string windowNameStr, variable winTypevar)
	// Every window created is assigned to the active Space IF the panel is there
	if(WinType("MXP_SpacesPanel"))
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
		WAVE/Z/T/SDFR=dfr mxpSpacesTW
		NVAR/SDFR=dfr gSelectedSpace
		windowNameStr = WinName(0, 87, 1) // Window is created, visible only
		if(DimSize(mxpSpacesTW,0) && cmpstr(windowNameStr,"MXP_SpacesPanel")) // We have to have at least one space
			SetWindow $windowNameStr userdata(MXP_SpacesTag) = mxpSpacesTW[gSelectedSpace]
		endif
	endif
	return 0 // Ignored
End

Function MXP_ListBoxSpacesHookFunction(STRUCT WMListboxAction &LB_Struct)

	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	WAVE/T/SDFR=dfr mxpSpacesTW
	NVAR/SDFR=dfr gSelectedSpace
	string msg, newSpaceNameStr, oldSpaceNameStr, winNameStr
	variable maxListEntries = DimSize(mxpSpacesTW, 0)
	variable hookresult = 0
	switch(LB_Struct.eventCode)
		case -1: // Control being killed
			//Do nothing
			break
		case 1: // Mouse down
			gSelectedSpace = LB_Struct.row			
			hookresult = 1
			break
		case 2: // Mouse up
			gSelectedSpace = LB_Struct.row
			hookresult = 1
			break
		case 3: // Double click
			gSelectedSpace = LB_Struct.row
			if (gSelectedSpace > maxListEntries - 1)
				hookresult = 1
				break
			endif			
			msg = "Rename Space \"" + mxpSpacesTW[gSelectedSpace] + "\""
			oldSpaceNameStr = mxpSpacesTW[gSelectedSpace]
			newSpaceNameStr = TrimString(MXP_GenericSingleStrPrompt("New name", msg))
			if(!UniqueSpaceNameQ(mxpSpacesTW, newSpaceNameStr) || !strlen(TrimString(newSpaceNameStr))) // if the name is not unique or empty string
				do
					newSpaceNameStr = TrimString(MXP_GenericSingleStrPrompt("Space name already exists or you entered empty string.", "Enter a *unique* name for the new Space"))
				while(!UniqueSpaceNameQ(mxpSpacesTW, newSpaceNameStr))
			endif
			mxpSpacesTW[gSelectedSpace] = newSpaceNameStr
			MXP_RenameSpaceTagOnWindows(oldSpaceNameStr, newSpaceNameStr)
			hookresult = 1
			break
		case 4: // Cell selection (mouse or arrow keys)
			//oldSelectedSpace = gSelectedSpace
			gSelectedSpace = LB_Struct.row
			if (gSelectedSpace > maxListEntries - 1)
				hookresult = 1
				break
			endif
			// If you press Option (Mac) or Alt (Windows) -- DEV
//			if(LB_Struct.eventMod == 5)
//				TODO
//			endif	
			//Otherwise handle cell selection without pressed Alt
			MXP_ShowWindowsOfSpaceTag(mxpSpacesTW[gSelectedSpace], 1)			
			DoWindow/F $LB_Struct.win // Bring panel to the FG
			hookresult = 1
			break
		case 5: // Cell selection plus Shift key (Assign window to Space)
			// WinName(0, 87) is the "MXP Spaces" panel
			gSelectedSpace = LB_Struct.row
			if (gSelectedSpace > maxListEntries - 1)
				hookresult = 1
				break
			endif
			winNameStr = WinName(1, 87, 0) // Top Window: Graph, Table, Layout, Notebook or Panel
			gSelectedSpace = LB_Struct.row
			SetWindow $winNameStr userdata(MXP_SpacesTag) = mxpSpacesTW[gSelectedSpace] // Assign tag to window
			hookresult = 1
			break
	endswitch
	return hookresult
End

Function MXP_ListBoxSpacesNewSpace(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	WAVE/T/SDFR=dfr mxpSpacesTW
	variable index
	variable numEntries = DimSize(mxpSpacesTW, 0)
	NVAR/SDFR=dfr gSelectedSpace
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			string newSpaceNameStr = TrimString(MXP_GenericSingleStrPrompt("Create a new Space", "Enter the name of the new Space"))
			if(!UniqueSpaceNameQ(mxpSpacesTW, newSpaceNameStr) || !strlen(TrimString(newSpaceNameStr))) // if the name is not unique or empty string
				do
					newSpaceNameStr = TrimString(MXP_GenericSingleStrPrompt("Space name already exists or you entered empty string.", "Enter a *unique* name for the new Space"))
				while(!UniqueSpaceNameQ(mxpSpacesTW, newSpaceNameStr))
			endif
			
			
			if (!numEntries) // If you have deleted all spaces
				index = 0
			else 
				index = gSelectedSpace + 1
			endif
			InsertPoints index,1, mxpSpacesTW
			mxpSpacesTW[index] = newSpaceNameStr
			// Set the space you created as active
			ListBox listOfspaces, selRow = index
			gSelectedSpace = index
			MXP_ShowWindowsOfSpaceTag(newSpaceNameStr, 1) // Show windows of the new Space - No windows to show!
			break
	endswitch
End

Function MXP_ListBoxSpacesDeleteSpace(STRUCT WMButtonAction &B_Struct): ButtonControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	WAVE/T/SDFR=dfr mxpSpacesTW
	variable numSpaces = DimSize(mxpSpacesTW, 0)
	NVAR/SDFR=dfr gSelectedSpace
	string msg
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			if(numSpaces)
				msg = "Do you want to delete \"" + mxpSpacesTW[gSelectedSpace] + "\""
				DoAlert/T="You are about to delete a Space", 1, msg
				if(V_flag == 1)
					MXP_ClearWindowsFromSpaceTag(mxpSpacesTW[gSelectedSpace]) // has to come first!
					DeletePoints gSelectedSpace, 1, mxpSpacesTW
					ListBox listOfspaces, selRow = gSelectedSpace - 1
				endif
			endif
			break
	endswitch
End

Function MXP_ShowWindowsOfSpaceTag(string spaceTagStr, variable showSwitch)
	// showSwitch = 0 (hide window) 
	// showSwitch = 1 (show window)
	string winNameStr, getSpacetagStr
	variable i = 0 
	do
		i++
		winNameStr = WinName(i, 87, 0) // i = 0 is the MXP_SpacesPanel, so we skip checking it
		if(!strlen(winNameStr))
			break
		endif
		getSpacetagStr = GetUserData(winNameStr, "", "MXP_SpacesTag")
		if(!cmpstr(getSpacetagStr, spacetagStr, 0)) // comparison is case-insensitive. 		
			SetWindow $winNameStr hide = 1 - showSwitch // Match
		else
			SetWindow $winNameStr hide = showSwitch
		endif
	while(strlen(winNameStr))
	return 0

End

Function MXP_RenameSpaceTagOnWindows(string oldspaceTagStr, string newspaceTagStr)


	string winNameStr = "", getSpacetagStr
	variable i = 0 
	do
		i++
		winNameStr = WinName(i, 87, 0) // i = 0 is the MXP_SpacesPanel, so we skip checking it
		getSpacetagStr = GetUserData(winNameStr, "", "MXP_SpacesTag")
		if(!cmpstr(getSpacetagStr, oldspaceTagStr, 0)) // comparison is case-insensitive. 		
			SetWindow $winNameStr userdata(MXP_SpacesTag) = newspaceTagStr
		endif
	while(strlen(winNameStr))
	return 0
End

Function MXP_ClearWindowsFromSpaceTag(string spaceTagStr)

	string winNameStr = "", getSpacetagStr
	variable i = 0 
	do
		i++
		winNameStr = WinName(i, 87, 0) // i = 0 is the MXP_SpacesPanel, so we skip checking it
		// Catch "" from setting SetWindow $"" hide = 1/0
		if(!strlen(winNameStr))
			break
		endif
		getSpacetagStr = GetUserData(winNameStr, "", "MXP_SpacesTag")
		if(!cmpstr(getSpacetagStr, spacetagStr, 0)) // comparison is case-insensitive. 		
			SetWindow $winNameStr userdata(MXP_SpacesTag) = ""
		endif
	while(strlen(winNameStr))
	return 0
End

Function MXP_ListBoxSpacesShowAll(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	NVAR/SDFR=dfr gShowAllWindowsSwitch
	variable showSwitch
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			showSwitch = 1 - gShowAllWindowsSwitch
			if(showSwitch)
				gShowAllWindowsSwitch = 1
				MXP_ShowAllWindows(0)
			else
				gShowAllWindowsSwitch = 0
				MXP_ShowAllWindows(1)
			endif
			break
	endswitch
End

Function MXP_ShowAllWindows(variable showSwitch)
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
		if(!cmpstr(winNameStr, "MXP_SpacesPanel", 0))
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
		if(!cmpstr(textW[i], spaceNameStr))
			return 0
		endif
	endfor
	return 1
End