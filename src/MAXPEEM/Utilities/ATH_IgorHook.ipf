#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9


Function BeforeFileOpenHook(variable refNum, string fileNameStr, string pathNameStr, string fileTypeStr, string fileCreatorStr, variable fileKind)

    PathInfo $pathNameStr
    string fileToOpen = S_path + fileNameStr
    if(StringMatch(fileNameStr, "*.dat") && fileKind == 7) // Igor treats .dat files is a General text (fileKind == 7)
        try	
        	// ATH_WAVELoadSingleDATFile(fileToOpen, "", autoscale = 1)
        	WAVE wIn = ATH_Uview#WAVELoadSingleDATFile(fileToOpen, "", autoscale = 1)
        	AbortOnRTE
        catch
        	// Added on the 17.03.2023 to deal with a corrupted file. 
        	print "!",fileNameStr, "metadataReadError"
        	variable err = GetRTError(1) // Clears the error
        	WAVE wIn = ATH_Uview#WAVELoadSingleCorruptedDATFile(fileToOpen, "")
        	//Abort // Removed to stop the "Encoding window" from popping all the time.
        endtry
        ATH_Display#NewImg(wIn)
        return 1
    endif
//    if(StringMatch(fileNameStr, "*.dav") && fileKind == 0) // fileKind == 0, unknown
//    	DoAlert/T="Dropped a .dav file in Igror" 1, "Do you want to load the .dav file in a stack?"
//        try
//        if(V_flag == 1)
//        	ATH_Uview#LoadSingleDAVFile(fileToOpen, "", skipmetadata = 1, autoscale = 1, stack3d = 1)
//        else
//        	ATH_Uview#LoadSingleDAVFile(fileToOpen, "", autoscale = 1)
//        endif
//        	AbortOnRTE
//        catch
//        	print "Are you sure you are not trying to load a text file with .dav extention?"
//        	Abort
//        endtry
//        return 1
//    endif
    return 0
End

// AfterWindowCreatedHook
Function AfterWindowCreatedHook(string windowNameStr, variable winTypevar)
	// Every window created is assigned to the active Space if the panel is there
	if(WinType("ATH_SpacesPanel"))
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Spaces")
		WAVE/Z/T/SDFR=dfr ATHSpacesTW
		NVAR/SDFR=dfr gSelectedSpace
		windowNameStr = WinName(0, 87, 1) // Window is created, visible only
		if(DimSize(ATHSpacesTW,0) && cmpstr(windowNameStr,"ATH_SpacesPanel")) // We have to have at least one space
			//Sanitize names
			if(GrepString(ATHSpacesTW[gSelectedSpace], "^\*"))
				SetWindow $windowNameStr userdata(ATH_SpacesTag) = ATH_Spaces#SanitiseATHSpaceName(ATHSpacesTW[gSelectedSpace])
			else
				SetWindow $windowNameStr userdata(ATH_SpacesTag) = ATHSpacesTW[gSelectedSpace]
			endif
		endif
	endif
	return 0 // Ignored
End