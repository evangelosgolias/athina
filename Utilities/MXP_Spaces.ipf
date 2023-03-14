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
/// TODO: Move linked windows to the same Space
/// TODO: Implement drag to rearrange spaces

Function MXP_MainMenuLaunchSpaces()
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	WAVE/Z/T/SDFR=dfr mxpSpacesTextWave
	NVAR/Z/SDFR=dfr gSelectedSpace
	NVAR/Z/SDFR=dfr gShowAllWindowsSwitch
	if(!WaveExists(mxpSpacesTextWave)) // If there is no text wave
		Make/T/N=1 dfr:mxpSpacesTextWave = "Default"
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
	NewPanel /N=MXP_SpacesPanel /W=(1232,119,1440,681) as "MXP Spaces"
	SetDrawLayer UserBack
	Button NewSpace,pos={7.00,8.00},size={61.00,20.00},help={"Create new space"}
	Button NewSpace,fColor=(3,52428,1),proc=MXP_ListBoxSpacesNewSpace
	Button DeleteSpace,pos={81.00,8.00},size={61.00,20.00},title="Delete"
	Button DeleteSpace,help={"Delete existing space"},fColor=(65535,16385,16385),proc=MXP_ListBoxSpacesDeleteSpace
	ListBox listOfspaces,pos={1.00,37.00},size={197.00,516.00},proc=MXP_ListBoxSpacesHookFunction
	ListBox listOfspaces,fSize=12,frame=2,listWave=dfr:mxpSpacesTextWave,mode=2,selRow=0
	Button ShowAll,pos={156.00,8.00},size={40.00,20.00},title="All"
	Button ShowAll,help={"Show all windows"},fColor=(32768,40777,65535),proc=MXP_ListBoxSpacesShowAll
End

// AfterWindowCreatedHook

Function AfterWindowCreatedHook(string windowNameStr, variable winTypevar)
	// Every window created is assigned to the active Space IF the panel is there
	if(WinType("MXP_SpacesPanel"))
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
		WAVE/Z/T/SDFR=dfr mxpSpacesTextWave
		NVAR/SDFR=dfr gSelectedSpace
		windowNameStr = WinName(0, 87, 1) // Window is created, visible only
		if(DimSize(mxpSpacesTextWave,0) && cmpstr(windowNameStr,"MXP_SpacesPanel")) // We have to have at least one space
			SetWindow $windowNameStr userdata(MXP_SpaceTag) = mxpSpacesTextWave[gSelectedSpace]
		endif
	endif
	return 0 // Ignored
End

Function MXP_ListBoxSpacesHookFunction(STRUCT WMListboxAction &LB_Struct)

	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	WAVE/T/SDFR=dfr mxpSpacesTextWave
	NVAR/SDFR=dfr gSelectedSpace
	string msg, newSpaceNameStr, winNameStr
	variable maxListEntries = DimSize(mxpSpacesTextWave, 0)
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
			msg = "Rename Space \"" + mxpSpacesTextWave[gSelectedSpace] + "\""
			newSpaceNameStr = MXP_GenericSingleStrPrompt("New name", msg)
			if(!UniqueSpaceNameQ(mxpSpacesTextWave, newSpaceNameStr)) // if the name is not unique
				do
					newSpaceNameStr = MXP_GenericSingleStrPrompt("Space already exists ...", "Enter a *unique* name for the new Space")
				while(!UniqueSpaceNameQ(mxpSpacesTextWave, newSpaceNameStr))
			endif
			mxpSpacesTextWave[gSelectedSpace] = newSpaceNameStr
			hookresult = 1
			break
		case 4: // Cell selection (mouse or arrow keys)
			gSelectedSpace = LB_Struct.row
			if (gSelectedSpace > maxListEntries - 1)
				hookresult = 1
				break
			endif
			MXP_ShowWindowsOfSpaceTag(mxpSpacesTextWave[gSelectedSpace], 1)			
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
			SetWindow $winNameStr userdata(MXP_SpaceTag) = mxpSpacesTextWave[gSelectedSpace] // Assign tag to window
			hookresult = 1
			break
	endswitch
	return hookresult
End

Function MXP_ListBoxSpacesNewSpace(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	WAVE/T/SDFR=dfr mxpSpacesTextWave
	variable index
	variable numEntries = DimSize(mxpSpacesTextWave, 0)
	NVAR/SDFR=dfr gSelectedSpace
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			string newSpaceNameStr = MXP_GenericSingleStrPrompt("Create a new Space", "Enter the name of the new Space")
			if(!UniqueSpaceNameQ(mxpSpacesTextWave, newSpaceNameStr)) // if the name is not unique
				do
					newSpaceNameStr = MXP_GenericSingleStrPrompt("Space already exists ...", "Enter a *unique* name for the new Space")
				while(!UniqueSpaceNameQ(mxpSpacesTextWave, newSpaceNameStr))
			endif
			if (!numEntries) // If you have deleted all spaces
				index = 0
			else 
				index = gSelectedSpace + 1
			endif
			InsertPoints index,1, mxpSpacesTextWave
			mxpSpacesTextWave[index] = newSpaceNameStr
			// Set the space you created as active
			ListBox listOfspaces, selRow = index
			break
	endswitch
End

Function MXP_ListBoxSpacesDeleteSpace(STRUCT WMButtonAction &B_Struct): ButtonControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:Spaces")
	WAVE/T/SDFR=dfr mxpSpacesTextWave
	variable numSpaces = DimSize(mxpSpacesTextWave, 0)
	NVAR/SDFR=dfr gSelectedSpace
	string msg
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			if(numSpaces)
				msg = "Do you want to delete \"" + mxpSpacesTextWave[gSelectedSpace] + "\""
				DoAlert/T="You are about to delete a Space", 1, msg
				if(V_flag == 1)
					MXP_ClearWindowsFromSpaceTag(mxpSpacesTextWave[gSelectedSpace]) // has to come first!
					DeletePoints gSelectedSpace,1, mxpSpacesTextWave
				endif			
				
			endif
			break
	endswitch
End

Function MXP_ListBoxSpacesShowAll(STRUCT WMButtonAction &B_Struct): ButtonControl
	// FIXIT: When double clicking on All button Panel hides
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

Function MXP_ShowWindowsOfSpaceTag(string spaceTagStr, variable showSwitch)
	// showSwitch = 0 (hide window) 
	// showSwitch = 1 (show window)
	string winNameStr = "", getSpacetagStr
	variable i = 0 
	do
		i++
		winNameStr = WinName(i, 87, 0) // i = 0 is the MXP_SpacesPanel, so we skip checking it
		getSpacetagStr = GetUserData(winNameStr, "", "MXP_SpaceTag")
		if(!cmpstr(getSpacetagStr, spacetagStr, 0)) // comparison is case-insensitive. 		
			SetWindow $winNameStr hide = 1 - showSwitch // Match
		else
			SetWindow $winNameStr hide = showSwitch
	
		endif
	while(strlen(WinName(i, 87, 0)))
End

Function MXP_ClearWindowsFromSpaceTag(string spaceTagStr)

	string winNameStr = "", getSpacetagStr
	variable i = 0 
	do
		i++
		winNameStr = WinName(i, 87, 0) // i = 0 is the MXP_SpacesPanel, so we skip checking it
		getSpacetagStr = GetUserData(winNameStr, "", "MXP_SpaceTag")
		if(!cmpstr(getSpacetagStr, spacetagStr, 0)) // comparison is case-insensitive. 		
			SetWindow $winNameStr userdata(MXP_SpaceTag) = ""
		endif
	while(strlen(WinName(i, 87, 0)))
End

Function MXP_ShowAllWindows(variable showSwitch)
	// showSwitch = 0 (hide window) 
	// showSwitch = 1 (show window)
	string winNameStr
	variable i = 0 
	do
		i++
		// Catch "" from setting SetWindow $"" hide = 1/0
		if(!strlen(WinName(i, 87, 0))) // i = 0 is the MXP_SpacesPanel, so we skip it
			break
		endif
		winNameStr = WinName(i, 87, 0) // i = 0 is the MXP_SpacesPanel, so we skip it
		SetWindow $winNameStr hide = 1 - showSwitch
	while(strlen(WinName(i, 87, 0)))
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