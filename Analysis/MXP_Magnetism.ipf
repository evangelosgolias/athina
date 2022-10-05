#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// Menu launchers //
Menu "MAXPEEM", hideable
	"XMC(L)D.../5", MXP_MenuLoadTwoImagesInFolderRegisterForMagContrast()
End
Function MXP_MenuLoadTwoImagesInFolderRegisterForMagContrast()

	variable numRef
	string fileFilters = "dat File (*.dat):.dat;"
	fileFilters += "All Files:.*;"
	string msgStr = "Select two images for XMC(L)D calculation."
	Open/D/R/MULT=1/M=msgStr/F=fileFilters numRef
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedFiles = ItemsInList(S_filename, "\r")
	string selectedFilesInDialogStr = SortList(S_fileName, "\r", 16)
	if(nrSelectedFiles != 2)
		DoAlert/T="MAXPEEM would like you to know" 1, "Select two (2) .dat files only.\n" + \
				"Do you want a another chance with the dialog selection?"
		if(V_flag == 1)
			MXP_MenuLoadTwoImagesInFolderRegisterForMagContrast()
		elseif(V_flag == 2)
			Abort
		else
			print "Check MXP_MenuLoadTwoImagesRegisterMagContrast()! Abormal behavior."
		endif
		
		Abort // Abort the running instance otherwise the code that follows will run 
			  // as many times as the dialog will be displayed. Equavalenty, it can 
			  // be placed in the if (V_flag == 1) branch.
	endif
	string selectedFilesStr = ""
	selectedFilesStr += ParseFilePath(3, StringFromList(0, selectedFilesInDialogStr, "\r"), ":", 0, 0)
	selectedFilesStr += ";"
	selectedFilesStr += ParseFilePath(3, StringFromList(1, selectedFilesInDialogStr, "\r"), ":", 0, 0)
	
	string wavePathStr = ParseFilePath(1, StringFromList(0, selectedFilesInDialogStr, "\r"), ":", 1, 0)
	string waveExtStr = ParseFilePath(4, StringFromList(0, selectedFilesInDialogStr, "\r"), ":", 0, 0)
	// Extentions are needed to load the files correctly, adding the extra step so we are not restricted to .dat only
	if(strlen(waveExtStr)) // add the dot
		string waveExtensionStr = "." + waveExtStr
	endif
	string wave1Str = ParseFilePath(3, StringFromList(0, selectedFilesInDialogStr, "\r"), ":", 0, 0)
	string wave2Str = ParseFilePath(3, StringFromList(1, selectedFilesInDialogStr, "\r"), ":", 0, 0)
	variable registerImageQ
	string saveWaveName = ""
	//Set defaults 
	Prompt wave1Str, "img1", popup, selectedFilesStr
	Prompt wave2Str, "img2", popup, selectedFilesStr
	Prompt registerImageQ, "Automatic image registration?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt saveWaveName, "Name of the XMC(L)D wave (default: MXPxmcd)"
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1Str, wave2Str, registerImageQ, saveWaveName
	WAVE wimg1 = MXP_WAVELoadSingleDATFile(wavePathStr + wave1Str + waveExtensionStr, "")
	WAVE wimg2 = MXP_WAVELoadSingleDATFile(wavePathStr + wave2Str + waveExtensionStr, "")
	Duplicate/O wimg2, SecWavBak // DELETE
	if(registerImageQ == 1)
		MXP_ImageAlignmentByRegistration(wimg1, wimg2)
	endif
	if(!strlen(saveWaveName))
		saveWaveName = "MXPxmcd"
	endif
	MXP_CalculateXMCD(wimg1, wimg2, saveWaveName)
End


// -------------- //

Function/WAVE MXP_WAVECalculateXMCD(WAVE w1, WAVE w2)
	/// Calculate XMCD/XMLD of two images
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02)) // if your wave are not 32-bit integers /SP
		Redimension/S w1, w2
	endif
	Duplicate/FREE w1, wxmcd
	wxmcd = (w1 - w2)/(w1 + w2)
	return wxmcd
End

Function MXP_CalculateXMCD(WAVE w1, WAVE w2, string wxmcdStr)
	/// Calculate XMCD/XMLD of two images and save it to 
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	/// @param wxmcd string Wavemane of calcualted XMCD/XMLD
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02) || !(WaveType(w1) & 0x04 && WaveType(w2) & 0x04)) // if your waves are not 32-bit or 64-bit floats
		Redimension/S w1, w2
	endif
	Duplicate/O w1, $wxmcdStr
	Wave wref = $wxmcdStr
	wref = (w1 - w2)/(w1 + w2)
End

Function MXP_CalculateXMCD3D(WAVE w1, WAVE w2)
	/// Calculate XMCD/XMLD of two images in a 3d wave
End
