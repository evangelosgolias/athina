#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion= 9
#pragma ModuleName = InteractiveDriftCorrection
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


//Structure InteractiveWaveDriftStruct
//	variable mode			// [mandatory] 0: drift a 2D wave or 1: layer of a 3D wave
//	WAVE driftWave			// [mandatory] wave to drift - will NOT be modified in any way
//	WAVE refWave			// [mandatory] wave to compare - will NOT be modified in any way
//	WAVE cmpWave			// [optional] result of comparison between orgWave and refWave will be written here
//	WAVE modWave			// [optional] modified wave - saves the scaled and drifted version of driftWave
//	WAVE dichroismWave		// [optional] calculates the XMCD/XMLD from driftWave and refWave
//	variable xdrift 		// x drift	(default 0)
//	variable ydrift     	// y drift	(default 0)
//	variable driftStep  	// x position of the baseline		(default DimDelta(driftWave))
//EndStructure
//
//Function InitializeDriftCorrection(STRUCT InteractiveWaveDriftStruct &s)
//	// Initialise
//	string winNameStr = WinName(0, 1, 1)
//	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
//	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
//	s.xdrift = 1
//	s.ydrift = 1
//	s.driftStep = 1
//End

Function MXP_LaunchInteractiveImageDriftCorrectionInBrowserInBrowser() // Launch from DataBrowserObjectsPopup contexual menu
	variable nrSelectedWaves = MXP_CountSelectedObjectsInDataBrowser() // be sure you select ywo waves
End

Function MXP_LaunchInteractiveImageDriftCorrectionFromMenur() // FIX IT
	/// Function to interactively drift images and get an updated
	/// graph of the XMC(L)D contrast.
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	
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
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1Str, wave2Str
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE w1 = $wave1Str
	WAVE w2 = $wave2Str
	// Make a note for the XMC(L)D image
	string xmcdWaveNoteStr = "XMC(L)D = (img1 - img2)/(img1 + img2)\n"
	
	if(!(WaveType(w1) & 0x02))
		Redimension/S w1
	endif
	if(!(WaveType(w2) & 0x02))
		Redimension/S w2
	endif 

	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:InteractiveXMCD:")
	Make/O/N=(DimSize(w1, 0), DimSize(w1, 1)) dfr:MXP_XMCD_Interactive /WAVE = xmcdWAVERef // Is this ok to do?
	Duplicate/O w1, dfr:wave1XMCD
	Duplicate/O w2, dfr:wave2XMCD
	WAVE xmcd = MXP_WAVECalculateXMCD(dfr:wave1XMCD, dfr:wave2XMCD) // FREE WAVE, at the end of the funtion will be destroyed
	xmcdWAVERef = xmcd
	NewImage xmcdWAVERef
	ModifyGraph width={Plan,1,top,left}
	// TODO: Display the two images, find a good way of doing it.
	// Then prompt to move one with respect to the other and recalculate XMCD MXP_WAVECalculateXMCD(dfr:wave1XMCD, dfr:wave2XMCD)
	// Use MXP_InteractiveImageDriftWindowHook() to move the image
	// create a panel with two SetValues and 
End

Function MXP_InteractiveImageDriftWindowHook(STRUCT WMWinHookStruct &s)
	
	variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.

	switch(s.eventCode)
		case 11:					// Keyboard event
			switch (s.keycode)
				case 28:
					Print "Left arrow key pressed."
					hookResult = 1
					break
				case 29:
					Print "Right arrow key pressed."
					hookResult = 1
					break
				case 30:
					Print "Up arrow key pressed."
					hookResult = 1
					break
				case 31:
					Print "Down arrow key pressed."
					hookResult = 1
					break			
				default:
					// The keyText field requires Igor Pro 7 or later. See Keyboard Events.
					printf "Exit interactive drifting, pressed: %s\r", s.keyText
					break
			endswitch
			break
	endswitch

	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

Function DemoWindowHook()
	DoWindow/F DemoGraph				// Does graph exist?
	if (V_flag == 0)
		Display/N=DemoGraph			// Create graph
		SetWindow DemoGraph, hook(MyHook) = MyWindowHook	// Install window hook
	endif
End

// Variable pix = 72/ScreenResolution
// Variable TFTResX= Str2Num(StringFromList(3,StringByKey("SCREEN1",IgorInfo(0),":"),","))		// get the display resolution to align window better (center of full screen)
// Variable TFTResY= Str2Num(StringFromList(4,StringByKey("SCREEN1",IgorInfo(0),":"),","))
// Variable WinTop = 70, WinLeft = 200
// Variable WinBottom	= TFTResY - 150
// Variable WinRight	= TFTResX - 350
//
// Display/K=2/W=(WinLeft*pix, WinTop*pix, WinRight*pix, WinBottom*pix)/N=$gName as gTitle+NameOfWave(inwave)
// AppendImage inwave																		// don't append as RGB image
// ModifyImage ''#0 ctab= {*,*,Terrain,0}
// ModifyGraph quickdrag(LinesY)=1,live(LinesY)=1,rgb(LinesY)=(65535,0,0)						// lines can be dragged (act on S_TraceOffsetInfo)
//	
// SetWindow $gName hook(CreateProfile)=Profile_ProcessWindowEvent								// keeps track of window changes
// NVAR ProfileUpdateConnector = stg:ProfileUpdateConnector									// set formula for live update
// SetFormula ProfileUpdateConnector,"LinesIntegrateUpdate(root:WinGlobals:"+gName+":S_TraceOffsetInfo)"