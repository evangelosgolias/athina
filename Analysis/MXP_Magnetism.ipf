 #pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()

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
			MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()
		elseif(V_flag == 2)
			Abort
		else
			print "Check MXP_MenuLoadTwoImagesRegisterMagContrast()! Abormal behavior."
		endif
		
		Abort // Abort the running instance otherwise the code that follows will run 
			  // as many times as the dialog will be displayed. Equavalenty, it can 
			  // be placed in the if (V_flag == 1) branch.
	endif
	//string selectedFilesStr = ""
	selectedFilesInDialogStr = ReplaceString("\r", selectedFilesInDialogStr, ";")

	string wave1Str = ParseFilePath(3, StringFromList(0, selectedFilesInDialogStr), ":", 0, 0)
	string wave2Str = ParseFilePath(3, StringFromList(1, selectedFilesInDialogStr), ":", 0, 0)
	string selectedFilesPopupStr = wave1Str + ";" + wave2Str
	variable registerImageQ
	string saveWaveName = ""
	//Set defaults 
	Prompt wave1Str, "img1", popup, selectedFilesPopupStr
	Prompt wave2Str, "img2", popup, selectedFilesPopupStr
	Prompt registerImageQ, "Automatic image registration?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt saveWaveName, "Name of the XMC(L)D wave (default: MXPxmcd)"
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1Str, wave2Str, registerImageQ, saveWaveName
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE wimg1 = MXP_WAVELoadSingleDATFile(StringFromList(0, selectedFilesInDialogStr), "")
	WAVE wimg2 = MXP_WAVELoadSingleDATFile(StringFromList(1, selectedFilesInDialogStr), "")
	// Make a note for the XMC(L)D image
	string xmcdWaveNoteStr = "XMC(L)D = (img1 - img2)/(img1 + img2)\n"
	xmcdWaveNoteStr += "img1: "
	xmcdWaveNoteStr += note(wimg1)
	xmcdWaveNoteStr += "\n"
	xmcdWaveNoteStr += "\nimg2: "
	xmcdWaveNoteStr += note(wimg2)
		
	if(!(WaveType(wimg1) & 0x02))
		Redimension/S wimg1
	endif
	if(!(WaveType(wimg2) & 0x02))
		Redimension/S wimg2
	endif 
	
	Duplicate/FREE wimg2, wimg2copy
	if(registerImageQ == 1)
		MXP_ImageAlignmentByRegistration(wimg1, wimg2copy)
	endif
	if(!strlen(saveWaveName))
		saveWaveName = "MXPxmcd"
	endif
	MXP_CalculateXMCD(wimg1, wimg2copy, saveWaveName)
	Note/K $saveWaveName, xmcdWaveNoteStr
	return 0
End

Function MXP_LaunchRegisterQCalculateXRayDichroism()
	string msg = "Select two waves for XMC(L)D calculation. Use Ctrl (Windows) or Cmd (Mac)."
	string selectedWavesInBrowserStr = MXP_SelectWavesInModalDataBrowser(msg)
	
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
	string selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
	if(nrSelectedWaves != 2)
		DoAlert/T="MAXPEEM would like you to know" 1, "Select two (2) .dat files only.\n" + \
				"Do you want a another chance with the browser selection?"
		if(V_flag == 1)
			MXP_LaunchRegisterQCalculateXRayDichroism()
		elseif(V_flag == 2)
			Abort
		else
			print "MXP_RegisterQCalculateXRayDichroism()! Abormal behavior."
		endif
		
		Abort // Abort the running instance otherwise the code that follows will run 
			  // as many times as the dialog will be displayed. Equavalenty, it can 
			  // be placed in the if (V_flag == 1) branch.
	endif
	string wave1Str = StringFromList(0, selectedWavesStr) // The last dat has been eliminated when importing waves, so we are ok
	string wave2Str = StringFromList(1, selectedWavesStr)
	string selectedWavesPopupStr = wave1Str + ";" + wave2Str
	variable registerImageQ
	string saveWaveName = ""
	//Set defaults 
	Prompt wave1Str, "img1", popup, selectedWavesPopupStr
	Prompt wave2Str, "img2", popup, selectedWavesPopupStr
	Prompt registerImageQ, "Automatic image registration?", popup, "Yes;No" // Yes = 1, No = 2!
	Prompt saveWaveName, "Name of the XMC(L)D wave (default: MXPxmcd)"
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1Str, wave2Str, registerImageQ, saveWaveName
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE wimg1 = $wave1Str
	WAVE wimg2 = $wave2Str
	// Make a note for the XMC(L)D image
	string xmcdWaveNoteStr = "XMC(L)D = (img1 - img2)/(img1 + img2)\n"
	xmcdWaveNoteStr += "img1: "
	xmcdWaveNoteStr += note(wimg1)
	xmcdWaveNoteStr += "\n"
	xmcdWaveNoteStr += "\nimg2: "
	xmcdWaveNoteStr += note(wimg2)
	
	if(!(WaveType(wimg1) & 0x02))
		Redimension/S wimg1
	endif
	if(!(WaveType(wimg2) & 0x02))
		Redimension/S wimg2
	endif 
	
	Duplicate/FREE wimg2, wimg2copy
	if(registerImageQ == 1)
		MXP_ImageAlignmentByRegistration(wimg1, wimg2copy)
	endif
	if(!strlen(saveWaveName))
		saveWaveName = "MXPxmcd"
	endif
	MXP_CalculateXMCD(wimg1, wimg2copy, saveWaveName)
	Note/K $saveWaveName, xmcdWaveNoteStr
	return 0
End

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
	
	// Calculation of XMC(L)D using SP waves
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02))
		Redimension/S w1, w2
	endif
	Duplicate/O w1, $wxmcdStr
	Wave wref = $wxmcdStr
	wref = (w1 - w2)/(w1 + w2)
End

Function MXP_CalculateXMCD3D(WAVE w3d)
	/// Calculate XMCD/XMLD of two images in a 3d wave
End
