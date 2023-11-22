#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9

// AfterWindowCreatedHook
Function AfterWindowCreatedHook(string windowNameStr, variable winTypevar)
	// Every window created is assigned to the active Space if the panel is there
	if(WinType("ATH_SpacesPanel"))
		DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
		WAVE/Z/T/SDFR=dfr ATHSpacesTW
		NVAR/SDFR=dfr gSelectedSpace
		windowNameStr = WinName(0, 87, 1) // Window is created, visible only
		if(DimSize(ATHSpacesTW,0) && cmpstr(windowNameStr,"ATH_SpacesPanel")) // We have to have at least one space
			//Sanitize names
			if(GrepString(ATHSpacesTW[gSelectedSpace], "^\*"))
				SetWindow $windowNameStr userdata(ATH_SpacesTag) = SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace])
			else
				SetWindow $windowNameStr userdata(ATH_SpacesTag) = ATHSpacesTW[gSelectedSpace]
			endif
		endif
	endif
	return 0 // Ignored
End