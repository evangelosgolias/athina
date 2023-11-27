#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
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
// ------------------------------------------------------- //

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