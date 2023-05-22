#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion= 9
#pragma ModuleName = InteractiveDriftCorrection
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
		return -1
	endif
	// Create variables for the Panel. NB; Data Folders for panels can be overwritten
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:InteractiveXMCD:") 
	string folderNameStr = CreateDataObjectName(dfr, "iXMCD",11, 0, 0)
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:InteractiveXMCD:" + folderNameStr) 
	Duplicate/O $wave1NameStr, dfr:iImg1
	Duplicate/O $wave2NameStr, dfr:iImg2
	Duplicate/O $wave1NameStr, dfr:iXMCD
	Duplicate/O $wave1NameStr, dfr:iSum
	//Wave references
	WAVE iImg1 = dfr:iImg1
	WAVE iImg2 = dfr:iImg2	
	WAVE iXMCD = dfr:iXMCD
	WAVE iSum = dfr:iSum
	// Add wave origin information
	Note/K iXMCD, "XMC(L)D = (img1 - img2)/(img1 + img2)\n" + "img1: " + NameOfWave(iImg1) + "\nimg2: " + NameOfWave(iImg2)
	// Set global variables
	variable/G dfr:gMXP_driftStep = 0.1
	variable/G dfr:gMXP_dx = 0	
	variable/G dfr:gMXP_dy = 0	
	//MXP_CalculateWaveSumFromStackToWave(imgStack, iSum)
	//MXP_CalculateXMCDFromStackToWave(imgStack, iXMCD)
//	SetFormula dfr:iXMCD, "(dfr:iImg1 - dfr:iImg2)/(dfr:iImg1 + dfr:iImg2)"
//	SetFormula dfr:iSum, "dfr:iImg1 + dfr:iImg2"
	SetFormula iXMCD, "(iImg1 - iImg2)/(iImg1 + iImg2)"
	SetFormula iSum, "iImg1 + iImg2"

	MXP_CreateInteractiveXMCDCalculationPanel(iImg1, iImg2, iXMCD, iSum)
End

Function MXP_CreateInteractiveXMCDCalculationPanel(WAVE iImg1, WAVE iImg2, WAVE iXMCD, WAVE iSum)
	DFREF dfr = GetWavesDataFolderDFR(iXMCD) // Recover the dfr	
	NVAR/SDFR=dfr gMXP_driftStep
//	Display/N=iXMCD /K=1 
//	string winiXMCDNameStr = S_name
	MXP_DisplayImage(iXMCD)
	string winiXMCDNameStr = WinName(0,1)
	//string winiXMCDNameStr = S_name	
//	AppendImage iXMCD
//	ModifyGraph width={Plan,1,top,left}
	// Fix the axes DisplayHelpTopic "ModifyGraph for Axes"
//	Display/N=iSum/K=1 
//	AppendImage iSum
//	ModifyGraph width={Plan,1,top,left}
//	string winiSumNameStr = S_name	
	MXP_DisplayImage(iSum)
	string winiSumNameStr = WinName(0,1)
//	AppendImage/T /b=bb iSum
//	AppendImage/T /b=bc /R iXMCD
//	ModifyImage '' ctab= {*,*,Grays,0}
//	ModifyImage ''#1 ctab= {*,*,Grays,0}
//	ModifyImage ''#2 ctab= {*,*,Grays,0}
//	ModifyGraph axisEnab(top)={0,0.3},axisEnab(bb)={0.33,0.63}
//	ModifyGraph axisEnab(bc)={0.66,1},freePos(bb)=0,freePos(bc)=0
//	ModifyGraph lblPos(bb)=0,lblPos(bc)=0 // Not needed?
//	ModifyGraph tick=2
//	ModifyGraph width={Plan,1,top,left}
	ControlBar/W=$winiXMCDNameStr 40	
	// Add buttons
//	Button ShowOtherImage,win=$winiStackNameStr, pos={20.00,10.00}, size={90.00,20.00}, proc=MXP_ShowOtherImageButton
//	Button ShowOtherImage,win=$winiStackNameStr, title="Show img1/2", help={"Display img1 or img2"}, valueColor=(1,12815,52428)
	
	SetVariable setDriftStep,win=$winiXMCDNameStr,pos={150,10},size={200.00,20.00},title="Set drift step"
	SetVariable setDriftStep,win=$winiXMCDNameStr,value=gMXP_driftStep,help={"Set drift value for img2"}
	SetVariable setDriftStep,win=$winiXMCDNameStr,fSize=14,limits={0,10,1},live=1,proc=MXP_SetDriftStepVar	

	Button SaveXMCDImage,win=$winiXMCDNameStr,pos={20.00,10.00},size={90.00,20.00},proc=MXP_SaveXMCDImageButton
	Button SaveXMCDImage,win=$winiXMCDNameStr,title="Save", help={"Save XMCD image in CWD"}, valueColor=(1,12815,52428)
	
	// Set the path to all windows
	string dfrStr = GetWavesDataFolder(iXMCD, 1)
	SetWindow $winiSumNameStr userdata(MXP_iXMCDPath) = dfrStr // winiSumNameStr and winiXMCDNameStr have the same tag
	SetWindow $winiXMCDNameStr userdata(MXP_iXMCDPath) = dfrStr
	//
	SetWindow $winiSumNameStr userdata(MXP_iXMCDWin) = winiXMCDNameStr // winiSumNameStr and winiXMCDNameStr have the same tag
	SetWindow $winiSumNameStr userdata(MXP_iSumWin) = winiSumNameStr
	SetWindow $winiXMCDNameStr userdata(MXP_iXMCDWin) = winiXMCDNameStr // winiSumNameStr and winiXMCDNameStr have the same tag
	SetWindow $winiXMCDNameStr userdata(MXP_iSumWin) = winiSumNameStr
	
	SetWindow $winiXMCDNameStr, hook(MyiXMCDWinHook) = MXP_InteractiveXMCDWindowHook // Set the hook
	
End

Function MXP_InteractiveXMCDWindowHook(STRUCT WMWinHookStruct &s)

	string winiXMCDNameStr = GetUserData(s.winName, "", "MXP_iXMCDWin")
	string winiSumNameStr = GetUserData(s.winName, "", "MXP_iSumWin")	
	string dfrStr = GetUserData(s.winName, "", "MXP_iXMCDPath")
	DFREF dfr = MXP_CreateDataFolderGetDFREF(dfrStr)
	NVAR/SDFR=dfr gMXP_driftStep
	NVAR/SDFR=dfr gMXP_dx
	NVAR/SDFR=dfr gMXP_dy
	WAVE/SDFR=dfr iImg1	
	WAVE/SDFR=dfr iImg2
	WAVE/SDFR=dfr iXMCD
	WAVE/SDFR=dfr iSum
	DFREF saveDFR = GetDataFolderDFR()
	variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.

	switch(s.eventCode)
		case 0: //activate window rescales the profile to the layer scale of the 3d wave
			hookresult = 1
			break
		case 2: // Kill the window
			SetFormula iXMCD, ""
			SetFormula iSum, ""
			SetWindow $winiXMCDNameStr, hook(MyiXMCDWinHook) = $"" 
			KillWindow $winiXMCDNameStr
			KillWindow $winiSumNameStr			
			KillDataFolder dfr
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
			//
		case 11:					// Keyboard event
			switch (s.keycode)
				case 28: //left arrow
					SetDataFolder dfr
					ImageInterpolate/APRM={1,0,-gMXP_driftStep,0,1,0,1,0} Affine2D iImg2
					WAVE M_Affine
					Duplicate/O M_Affine, iImg2
					hookResult = 1
					break
				case 29: //right arrow
					SetDataFolder dfr
					ImageInterpolate/APRM={1,0,gMXP_driftStep,0,1,0,1,0} Affine2D iImg2
					WAVE M_Affine
					Duplicate/O M_Affine, iImg2
					hookResult = 1
					break
				case 30: // up arrow
					SetDataFolder dfr
					ImageInterpolate/APRM={1,0,0,0,1,-gMXP_driftStep,1,0} Affine2D iImg2
					WAVE M_Affine
					Duplicate/O M_Affine, iImg2
					hookResult = 1
					break
				case 31: // down arrow
					SetDataFolder dfr
					ImageInterpolate/APRM={1,0,0,0,1,gMXP_driftStep,1,0} Affine2D iImg2
					WAVE M_Affine
					Duplicate/O M_Affine, iImg2
					hookResult = 1
					break
				default:
					// The keyText field requires Igor Pro 7 or later. See Keyboard Events.
					printf "Exit interactive drifting, pressed: %s\r", s.keyText
					break
			endswitch
			DoUpdate // Update dependencies
			break
	endswitch
	SetDataFolder saveDFR
	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

Function MXP_SaveXMCDImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_iXMCDPath"))

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
		break
	endswitch
	return 0
End

//Function MXP_ShowOtherImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl
//	string winNameStr = GetUserData(B_Struct.win, "", "MXP_iStackWindowNameStr")
//	string dfrStr = GetUserData(B_Struct.win, "", "MXP_iStackPath")
//	DFREF dfr = MXP_CreateDataFolderGetDFREF(dfrStr)
//	NVAR/SDFR=dfr gMXP_planeCnt
//	WAVE imgStack = dfr:imgStack
//	string imgTagStr
//	switch(B_Struct.eventCode)	// numeric switch
//		case 2:	// "mouse up after mouse down"
//			ModifyImage/W=$winNameStr imgStack plane=mod(gMXP_planeCnt, 2)
//			imgTagStr = "\k(65535,0,0)\\Z14img" + num2str(mod(gMXP_planeCnt, 2) + 1)
//			//TextBox/K/N=imgTag
//			//TextBox/W=$winNameStr /B=1/N=imgTag/F=0/S=3/A=LT/X=1.00/Y=1.0  //imgStack
//			gMXP_planeCnt+=1
//		break
//	endswitch
//	return 0
//End

Function MXP_RestoreImagesButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
		break
	endswitch
	return 0
End

Function MXP_SetDriftStepVar(STRUCT WMSetVariableAction &sva) : SetVariableControl
	string dfrStr = GetUserData(sva.win, "", "MXP_iXMCDPath")
	DFREF dfr = MXP_CreateDataFolderGetDFREF(dfrStr)
	NVAR/SDFR=dfr gMXP_driftStep
	switch (sva.eventCode)
		case 1: 							// Mouse up
		case 2:							// Enter key
		case 3: 							// Live update
			gMXP_driftStep = sva.dval
			break
		case -1: 							// Control being killed
			break
	endswitch

	return 0
End
