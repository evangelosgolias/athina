#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion= 9
#pragma ModuleName = InteractiveDriftCorrection
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// ------------------------------------------------------- //
// Developed by Evangelos Golias.
// Contact: evangelos.golias@gmail.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, IN CONNECTION WITH THE USE OF SOFTWARE.
// ------------------------------------------------------- //

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
	string wave1NameStr = StringFromList(0, selectedWavesStr)
	string wave2NameStr = StringFromList(1, selectedWavesStr)
	if(nrSelectedWaves != 2 || WaveDims($wave1NameStr) != 2 || WaveDims($wave2NameStr) != 2)
		DoAlert/T="MAXPEEM would like you to know that you have to ..." 1, "Please " +\
				  "select two false-color images, i.e two 2d waves, non-RGB. \n" + \
				  "Do you want a another chance with the browser selection?"
		if(V_flag == 1)
			MXP_LaunchInteractiveImageDriftCorrectionFromMenu()
		elseif(V_flag == 2)
			Abort
		endif
	endif
	
	Prompt wave1NameStr, "img1", popup, selectedWavesStr
	Prompt wave2NameStr, "img2", popup, selectedWavesStr
	DoPrompt "XMC(L)D = (img1 - img2)/(img1 + img2)", wave1NameStr, wave2NameStr
	if(V_flag) // User cancelled
		return 1
	endif
	// Create variables for the Panel. NB; Data Folders for panels can be overwritten
	string uniquePanelNameStr = UniqueName("iXMCDPanel", 9, 0)
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:InteractiveXMCD:" + uniquePanelNameStr)
	Duplicate/O $wave1NameStr, dfr:iImg1
	Duplicate/O $wave2NameStr, dfr:iImg2
	Duplicate/O $wave1NameStr, dfr:iXMCD
	WAVE img1WaveRef = dfr:iImg1
	WAVE img2WaveRef = dfr:iImg2
	WAVE iXMCDWaveRef = dfr:iXMCD
	// Add wave origin information
	Note img1WaveRef, "Source: " + wave1NameStr
	Note img2WaveRef, "Source: " + wave2NameStr
	Note/K iXMCDWaveRef, "XMC(L)D = (iImg1 - iImg2)/(iImg1 + iImg2)"
	// Set global variables
	string/G dfr:gMXP_wave1NameStr = wave1NameStr
	string/G dfr:gMXP_wave2NameStr = wave2NameStr
	variable/G dfr:gMXP_driftStep = 1
	variable/G dfr:gMXP_CursorAlignSwitch = 0

	MXP_CalculateXMCDToWaveRef(img1WaveRef, img2WaveRef, iXMCDWaveRef)
	MXP_CreateInteractiveXMCDCalculationPanel(img1WaveRef, img2WaveRef, iXMCDWaveRef, uniquePanelNameStr)
	DoWindow/F $uniquePanelNameStr
	SetWindow $uniquePanelNameStr, hook(MyHook) = MXP_InteractiveImageDriftWindowHook // Set the hook

End

Function MXP_CreateInteractiveXMCDCalculationPanel(WAVE Img1WaveRef, WAVE Img2WaveRef,WAVE XMCDWaveRef, string panelNameStr)
 	
	NewPanel/N=$panelNamestr /W=(1239,97,2036,876)
	SetDrawLayer UserBack
	SetDrawEnv linefgc= (1,12815,52428),linejoin= 1,fillpat= 3,fillfgc= (65535,65534,49151),fillbgc= (65535,65534,49151)
	Display/N=Img1/W=(30,10,390,370)/HOST=$panelNamestr;AppendImage Img1WaveRef;ModifyGraph margin=15,tick=2,nticks=5,fSize=10
	TextBox/W=$panelNamestr#Img1/B=1/N=text0/F=0/S=3/A=LT/X=1.00/Y=1.0 "\\Z14Img1"  //img1
	Display/N=Img2/W=(426,10,786,370)/HOST=$panelNamestr;AppendImage Img2WaveRef;ModifyGraph margin=15,tick=2,nticks=5,fSize=10 //img2
	TextBox/W=$panelNamestr#Img2/B=1/N=text0/F=0/S=3/A=LT/X=1.00/Y=1.00 "\\Z14Img2"  //img1
	Display/N=XMCLD/W=(30,409,390,769)/HOST=$panelNamestr;AppendImage XMCDWaveRef;ModifyGraph margin=15,tick=2,nticks=5,fSize=10 //xmcd
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
	CheckBox UseCursorsForAlignment,fSize=14,value=0,proc=MXP_ActivateImageDriftWithCursors
	SetVariable setDriftStep,pos={496.00,458.00},size={200.00,20.00}
	SetVariable setDriftStep,title="Set drift step"
	SetVariable setDriftStep,help={"Set drift value for img2.  Decimal values (sub-pixel drift) are valid."}
	SetVariable setDriftStep,fSize=14,limits={-50,50,1},live=1,proc=MXP_SetDriftStepVar
	Button moveLeft,pos={517.00,537.00},size={40.00,40.00},title="Left",fSize=11,proc=MXP_DriftImageWithCursorsButton
	Button moveRight,pos={629.00,537.00},size={40.00,40.00},title="Right",fSize=11,proc=MXP_DriftImageWithCursorsButton
	Button moveUp,pos={574.00,486.00},size={40.00,40.00},title="Up",fSize=11,proc=MXP_DriftImageWithCursorsButton
	Button moveDown,pos={573.00,537.00},size={40.00,40.00},title="Down",fSize=11,proc=MXP_DriftImageWithCursorsButton
	Button MoveToCursors,pos={460.00,644.00},size={150.00,20.00}
	Button MoveToCursors,title="Move cursor B to A",fColor=(61166,61166,61166),proc=MXP_DriftImageWithCursorsButton
	Button RestoreImages,pos={648.00,739.00},size={110.00,20.00}
	Button RestoreImages,title="Restore Images",fColor=(49163,65535,32768),proc=MXP_RestoreImagesButton
	Button SaveImages,pos={648.00,705.00},size={110.00,20.00},title="Save Images"
	Button SaveImages,help={"Save drifed images and XMC(L)D result."}
	Button SaveImages,fColor=(32768,54615,65535),proc=MXP_SaveImagesButton
	Button ScaleXMCLD,pos={444.00,740.00},size={150.00,20.00}
	Button ScaleXMCLD,title="Scale XMC(L)D range"
	Button ScaleXMCLD,help={"Adjuct XMC(L)D range around maximum contrast."}
	Button ScaleXMCLD,fColor=(65535,54611,49151),proc=MXP_SetImageRangeButton
	Button ReloadImages,pos={444.00,705.00},size={150.00,20.00}
	Button ReloadImages,title="Reload images",help={"Load another pair of images."}
	Button ReloadImages,fColor=(32768,40777,65535),proc=MXP_ReloadImagesButton
	ValDisplay CursorsDifference,pos={651.00,644.00},size={80.00,18.00}
	ValDisplay CursorsDifference,title="\\$WMTEX$ \\Delta\\$/WMTEX$x\\BA-B"
	ValDisplay CursorsDifference,help={"Pixel difference between cursor A and B"}
	ValDisplay CursorsDifference,fSize=13,limits={0,0,0},barmisc={0,1000},value=#"0"
End

Function MXP_InteractiveImageDriftWindowHook(STRUCT WMWinHookStruct &s)
	
	variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
	
	switch(s.eventCode)
		case 0: //activate window rescales the profile to the layer scale of the 3d wave
			hookresult = 1
			break
		case 2: // Kill the window

			hookresult = 1
			break
		case 4:
			hookresult = 0 // Here hookresult = 1, supresses Marquee
			break
		case 5: // mouse up
			hookresult = 1
			break
        case 7: // cursor moved
		    hookresult = 1	// TODO: Return 0 here, i.e delete line?
	 		break
	 	case 8: // We have a Window modification eveny
	 		hookresult = 1
	 		break
    endswitch
    
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

Function MXP_SaveImagesButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
		break
	endswitch
	return 0
End

Function MXP_ReloadImagesButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
		break
	endswitch
	return 0
End

Function MXP_RestoreImagesButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
		break
	endswitch
	return 0
End

Function MXP_SetImageRangeButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
		break
	endswitch
	return 0
End

Function MXP_DriftImageButtons(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
		break
	endswitch
	return 0
End

Function MXP_DriftImageWithCursorsButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
		break
	endswitch
	return 0
End

Function MXP_SetDriftStepVar(STRUCT WMSetVariableAction &sva) : SetVariableControl
	SVAR/Z dvar
	switch (sva.eventCode)
		case 1: 							// Mouse up
		case 2:							// Enter key
		case 3: 							// Live update
			Variable dval = sva.dval
			break
		case -1: 							// Control being killed
			break
	endswitch

	return 0
End

Function MXP_ActivateImageDriftWithCursors(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	switch(cb.checked)
		case 1:		// Mouse up
			//MarkAreasSwitch = 1
			break
		case 0:
			//MarkAreasSwitch = 0
			break
	endswitch
	return 0
End