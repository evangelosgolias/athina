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
	variable nrSelectedWaves = MXP_CountSelectedObjectsInDataBrowser() // be sure you select two waves
End

Function MXP_LaunchInteractiveImageDriftCorrectionFromMenu()
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
		DoAlert/T="MAXPEEM would like you to know" 1, "Select two (2) images only.\n" + \
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
	if(WaveDims($wave1Str) * WaveDims($wave1Str) != 4)
		Abort "Operation needs two images (2d waves)."
	endif
	
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

	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:InteractiveXMCD:")
	Make/O/N=(DimSize($wave1Str, 0), DimSize($wave1Str, 1)) dfr:MXP_iXMCLD /WAVE = ixmcld // Is this ok to do?
	Duplicate/O $wave1Str, dfr:iimg1
	WAVE w1 = dfr:iimg1
	Duplicate/O $wave2Str, dfr:iimg2
	WAVE w2 = dfr:iimg2
	string ixmcldStr = NameOfWave(ixmcld)
	MXP_CalculateXMCD(w1, w2, ixmcldStr)
	NewImage/N=MXP_iXMCLD ixmcld
	ModifyGraph width={Plan,1,top,left}

	NewImage/N=MXP_iImg1 w1
	AutoPositionWindow/R=MXP_iXMCLD MXP_iImg1
	NewImage/N=MXP_iImg2 w2
	AutoPositionWindow/R=MXP_iImg1 MXP_iImg2
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


Function MXP_CreateInteractiveXMCDCalculationPanel()
 	string panelNamestr = UniqueName("iXMCLDPanel", 9, 0) // Unique Name for Panel to avoid /HOST=panelName conflicts
	NewPanel/N=$panelNamestr/K=1 /W=(1239,97,2036,876)
	SetDrawLayer UserBack
	WAVE m1,m2,m3
	SetDrawEnv linefgc= (1,12815,52428),linejoin= 1,fillpat= 3,fillfgc= (65535,65534,49151),fillbgc= (65535,65534,49151)
	Display/N=Img1/W=(30,10,390,370)/HOST=$panelNamestr;AppendImage m1;ModifyGraph margin=15,tick=2,nticks=5,fSize=10
	TextBox/W=$panelNamestr#Img1/B=1/N=text0/F=0/S=3/A=LT/X=1.00/Y=1.00 "\\Z14Img1"  //img1
	Display/N=Img2/W=(426,10,786,370)/HOST=$panelNamestr;AppendImage m2;ModifyGraph margin=15,tick=2,nticks=5,fSize=10 //img2
	TextBox/W=$panelNamestr#Img2/B=1/N=text0/F=0/S=3/A=LT/X=1.00/Y=1.00 "\\Z14Img2"  //img1
	Display/N=XMCLD/W=(30,409,390,769)/HOST=$panelNamestr;AppendImage m3;ModifyGraph margin=15,tick=2,nticks=5,fSize=10 //xmcd
	TextBox/W=$panelNamestr#XMCLD/B=1/N=text0/F=0/S=3/A=LT/X=1.00/Y=1.00 "\\Z14XMC(L)D" 
	DrawRect/W=$panelNamestr 424,409,784,769
	SetDrawEnv/W=$panelNamestr fsize= 16,textrgb= (1,12815,52428)
	DrawText/W=$panelNamestr 442,431,"MAXPEEM: Interactive XMC(L)D calculation"
	SetDrawEnv/W=$panelNamestr fsize= 11,textrgb= (1,12815,52428)
	DrawText/W=$panelNamestr 528,447,"Use buttons or arrow keys"
	SetDrawEnv/W=$panelNamestr fillpat= 0
	DrawRect/W=$panelNamestr 473,451,722,590
	SetDrawEnv/W=$panelNamestr fillpat= 0
	DrawRect/W=$panelNamestr 449,601,754,691
	
	CheckBox UseCursorsForAlignment,pos={460.00,607.00},size={283.00,17.00}
	CheckBox UseCursorsForAlignment,title="Use Cursors to align (img1 - A,  img2 - B) "
	CheckBox UseCursorsForAlignment,help={"Place Cursor A on both images to align img2 relative to img1. Hint: Mark a feature!"}
	CheckBox UseCursorsForAlignment,fSize=14,value=0
	SetVariable setDriftStep,pos={496.00,458.00},size={200.00,20.00}
	SetVariable setDriftStep,title="Set drift step"
	SetVariable setDriftStep,help={"Set drift value for img2.  Decimal values (sub-pixel drift) are valid."}
	SetVariable setDriftStep,fSize=14,limits={-50,50,1},live=1
	Button moveLeft,pos={517.00,537.00},size={40.00,40.00},title="Left",fSize=11
	Button moveRight,pos={629.00,537.00},size={40.00,40.00},title="Right",fSize=11
	Button moveUp,pos={574.00,486.00},size={40.00,40.00},title="Up",fSize=11
	Button moveDown,pos={573.00,537.00},size={40.00,40.00},title="Down",fSize=11
	Button MoveToCursors,pos={460.00,644.00},size={150.00,20.00}
	Button MoveToCursors,title="Move cursor B to A",fColor=(61166,61166,61166)
	Button RestoreImages,pos={648.00,739.00},size={110.00,20.00}
	Button RestoreImages,title="Restore Images",fColor=(49163,65535,32768)
	Button SaveImages,pos={648.00,705.00},size={110.00,20.00},title="Save Images"
	Button SaveImages,help={"Save drifed images and XMC(L)D result."}
	Button SaveImages,fColor=(32768,54615,65535)
	Button ScaleXMCLD,pos={444.00,740.00},size={150.00,20.00}
	Button ScaleXMCLD,title="Scale XMC(L)D range"
	Button ScaleXMCLD,help={"Adjuct XMC(L)D range around maximum contrast."}
	Button ScaleXMCLD,fColor=(65535,54611,49151)
	Button ReloadImages,pos={444.00,705.00},size={150.00,20.00}
	Button ReloadImages,title="Reload images",help={"Load another pair of images."}
	Button ReloadImages,fColor=(32768,40777,65535)
	ValDisplay CursorsDifference,pos={651.00,644.00},size={80.00,18.00}
	ValDisplay CursorsDifference,title="\\$WMTEX$ \\Delta\\$/WMTEX$x\\BA-B"
	ValDisplay CursorsDifference,help={"Pixel difference between cursor A and B"}
	ValDisplay CursorsDifference,fSize=13,limits={0,0,0},barmisc={0,1000},value=#"0"
End