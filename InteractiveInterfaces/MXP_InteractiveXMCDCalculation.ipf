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
				  "select two images, i.e two 2d waves, non-RGB. \n" + \
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
	
	if(!cmpstr(wave1NameStr, wave2NameStr))
		print "Ok, you are subtracting a wave from itself! I hope you know what you are doing."
	endif
	
	// Create variables for the Panel. NB; Data Folders for panels can be overwritten
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:InteractiveXMCD:") 
	string folderNameStr = CreateDataObjectName(dfr, "iXMCD",11, 0, 0)
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:InteractiveXMCD:" + folderNameStr) 
	Duplicate/O $wave1NameStr, dfr:wImg1
	Duplicate/O $wave2NameStr, dfr:wImg2, dfr:wImg2_undo,  dfr:wXMCD, dfr:wSum
	//Wave references
	WAVE wImg1 = dfr:wImg1
	WAVE wImg2 = dfr:wImg2	
	WAVE wXMCD = dfr:wXMCD
	WAVE wSum = dfr:wSum
	// Add wave origin information
	Note/K dfr:wXMCD, "XMC(L)D = (img1 - img2)/(img1 + img2)\n" + "img1: " \
	+ NameOfWave(wImg1) + "\nimg2: " + NameOfWave(wImg2)
	// Set global variables
	variable/G dfr:gMXP_driftStep = 1
	variable/G dfr:gMXP_dx = 0	
	variable/G dfr:gMXP_dy = 0	
	//MXP_CalculateWaveSumFromStackToWave(imgStack, iSum)
	//MXP_CalculateXMCDFromStackToWave(imgStack, iXMCD)
//	SetFormula dfr:iXMCD, "(dfr:iImg1 - dfr:iImg2)/(dfr:iImg1 + dfr:iImg2)"
//	SetFormula dfr:iSum, "dfr:iImg1 + dfr:iImg2"
	SetFormula wXMCD, "(wImg1 - wImg2)/(wImg1 + wImg2)"
	SetFormula wSum, "wImg1 + wImg2"
	MXP_CreateInteractiveXMCDCalculationPanel(wXMCD, wSum)
End

Function MXP_CreateInteractiveXMCDCalculationPanel(WAVE wXMCD, WAVE wSum)
	DFREF dfr = GetWavesDataFolderDFR(wXMCD) // Recover the dfr	
	NVAR/SDFR=dfr gMXP_driftStep

	MXP_DisplayImage(wSum)
	string winiSumNameStr = WinName(0,1)
	MXP_DisplayImage(wXMCD)
	string winiXMCDNameStr = WinName(0,1)
	ControlBar/W=$winiXMCDNameStr 40	
	
	SetVariable setDriftStep,win=$winiXMCDNameStr,pos={120,10},size={180,20.00},title="Drift step (px)"
	SetVariable setDriftStep,win=$winiXMCDNameStr,value=gMXP_driftStep,help={"Set drift value for img2"}
	SetVariable setDriftStep,win=$winiXMCDNameStr,fSize=14,limits={0,10,1},live=1,proc=MXP_SetDriftStepVar	

	Button SaveXMCDImage,win=$winiXMCDNameStr,pos={20.00,10.00},size={90.00,20.00},proc=MXP_SaveXMCDImageButton
	Button SaveXMCDImage,win=$winiXMCDNameStr,title="Save", help={"Save XMCD image in CWD"}, valueColor=(1,12815,52428)
	
	// Set the path to all windows
	string dfrStr = GetWavesDataFolder(wXMCD, 1)
	SetWindow $winiXMCDNameStr userdata(MXP_iXMCDPath) = dfrStr
	SetWindow $winiXMCDNameStr userdata(MXP_iXMCDWin) = winiXMCDNameStr
	SetWindow $winiXMCDNameStr userdata(MXP_iSumWin) = winiSumNameStr
	
	SetWindow $winiXMCDNameStr, hook(MyiXMCDWinHook) = MXP_InteractiveXMCDWindowHook // Set the hook
	return 0
End

Function MXP_InteractiveXMCDWindowHook(STRUCT WMWinHookStruct &s)
	string winiXMCDNameStr = GetUserData(s.winName, "", "MXP_iXMCDWin")
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(s.winName, "", "MXP_iXMCDPath"))
	NVAR/SDFR=dfr gMXP_driftStep
	NVAR/SDFR=dfr gMXP_dx
	NVAR/SDFR=dfr gMXP_dy
	WAVE/SDFR=dfr wImg1	
	WAVE/SDFR=dfr wImg2
	WAVE/SDFR=dfr wImg2_undo	
	WAVE/SDFR=dfr wXMCD
	WAVE/SDFR=dfr wSum
	variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
	string dfrStr = GetUserData(s.winName, "", "MXP_iXMCDPath"), cmdStr
	switch(s.eventCode)
		case 2: // Window is about to be killed
			SetFormula wXMCD, ""
			SetFormula wSum, ""
			KillWindow/Z $GetUserData(s.winName, "", "MXP_iSumWin")		
			KillWindow/Z $winiXMCDNameStr
			cmdStr = "KillDataFolder " + dfrStr
			// Runs when everything else has finished (Execute/P).
			// Avoid issues with killing a graph or folder with wave in use (iXMCD here)
			Execute/P/Q  cmdStr  
			hookresult = 1
			break
		case 11:					// Keyboard event
			switch (s.keycode)
				case 28: //left arrow
					ImageInterpolate/APRM={1,0,-gMXP_driftStep,0,1,0,1,0}/DEST=dfr:M_Affine Affine2D wImg2
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, wImg2
					hookResult = 1
					break
				case 29: //right arrow
					ImageInterpolate/APRM={1,0,gMXP_driftStep,0,1,0,1,0}/DEST=dfr:M_Affine Affine2D wImg2
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, wImg2
					hookResult = 1
					break
				case 30: // up arrow
					ImageInterpolate/APRM={1,0,0,0,1,-gMXP_driftStep,1,0}/DEST=dfr:M_Affine Affine2D wImg2
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, wImg2
					hookResult = 1
					break
				case 31: // down arrow
					ImageInterpolate/APRM={1,0,0,0,1,gMXP_driftStep,1,0}/DEST=dfr:M_Affine Affine2D wImg2
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, wImg2
					hookResult = 1
					break
				case 82: // R to restore.
					Duplicate/O wImg2_undo, wImg2
					hookResult = 1
					break
				default:
					// The keyText field requires Igor Pro 7 or later. See Keyboard Events.
					hookResult = 1
					break
			endswitch
			break
	endswitch
	//SetDataFolder saveDFR
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
