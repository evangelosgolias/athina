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
	
	if(WaveType($wave1NameStr) & 0x10) // If WORD (int16)
		Redimension/S $wave1NameStr
	endif
	
	if(WaveType($wave2NameStr) & 0x10) // If WORD (int16)
		Redimension/S $wave2NameStr
	endif	
	
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
	variable/G dfr:calculationMethod = 0 // 0=sub/add, 1=div
	string/G dfr:wName1Str = wave1NameStr
	string/G dfr:wName2Str = wave2NameStr
	SetFormula wXMCD, "(wImg1 - wImg2)/(wImg1 + wImg2)"
	SetFormula wSum, "wImg1 + wImg2"	
	MXP_CreateInteractiveXMCDCalculationPanel(wXMCD, wSum)
End

Function MXP_CreateInteractiveXMCDCalculationPanel(WAVE wXMCD, WAVE wSum)
	DFREF dfr = GetWavesDataFolderDFR(wXMCD) // Recover the dfr	
	NVAR/SDFR=dfr gMXP_driftStep

	MXP_DisplayImage(wSum)
	string winiSumNameStr = WinName(0,1)
	DoWindow/T $winiSumNameStr "iSum"	
	MXP_DisplayImage(wXMCD)
	string winiXMCDNameStr = WinName(0,1)
	DoWindow/T $winiXMCDNameStr "iXMC(L)D"		
	ControlBar/W=$winiXMCDNameStr 40	
	
	SetVariable setDriftStep,win=$winiXMCDNameStr,pos={130,10},size={160,20.00},title="Drift step (px)"
	SetVariable setDriftStep,win=$winiXMCDNameStr,value=gMXP_driftStep,help={"Set drift value for img2"}
	SetVariable setDriftStep,win=$winiXMCDNameStr,fSize=14,limits={0,10,1},live=1,proc=MXP_SetDriftStepVar	

	Button SaveXMCDImage,win=$winiXMCDNameStr,pos={20.00,10.00},size={90.00,20.00},proc=MXP_SaveXMCDImageButton
	Button SaveXMCDImage,win=$winiXMCDNameStr,title="Save XMCD", help={"Save XMCD image in CWD"}, valueColor=(1,12815,52428)

	CheckBox CalcWithDivision,pos={310, 10.00},size={100,20.00},title="Use img1/img2 ",fSize=14,value=0,side=1,proc=MXP_XMCDCalcWithDivision

	// Set the path to all windows
	string dfrStr = GetWavesDataFolder(wXMCD, 1)
	SetWindow $winiXMCDNameStr userdata(MXP_iXMCDPath) = dfrStr
	SetWindow $winiXMCDNameStr userdata(MXP_iXMCDWin) = winiXMCDNameStr
	SetWindow $winiXMCDNameStr userdata(MXP_iSumWin) = winiSumNameStr
	SetWindow $winiXMCDNameStr, hook(MyiXMCDWinHook) = MXP_InteractiveXMCDWindowHook // Set the hook
	return 0
End

Function MXP_InteractiveXMCDWindowHook(STRUCT WMWinHookStruct &s)
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
		case 0: // activate
			SetFormula wXMCD, "(wImg1 - wImg2)/(wImg1 + wImg2)"
			SetFormula wSum, "wImg1 + wImg2"
			hookresult = 1
			break
		case 1: // deactivate
			SetFormula wXMCD, ""
			SetFormula wSum, ""
			hookresult = 1
			break
	// Window is about to be killed case 17. 
	// Needed if you want more than one hook functions to be able to cleanup/close 
	// windows linked a parent window.
		case 2: 
			SetFormula wXMCD, ""
			SetFormula wSum, ""
			string sumWinStr = GetUserData(s.winName, "", "MXP_iSumWin")
			if (WinType(sumWinStr) == 1)
				string killwincmd = "KillWindow "+sumWinStr
				Execute/P/Q killWinCmd
			endif
			string killDFCmd = "KillDataFolder "+ GetDataFolder(1, dfr)
			Execute/P/Q killDFCmd
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
			CopyScales/I wimg1, wimg2 // Copy back the scale, M_Affine is pixel-scaled
			break
	endswitch
	//SetDataFolder saveDFR
	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

Function MXP_SaveXMCDImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_iXMCDPath"))
	DFREF currDF = GetDataFolderDFR()
	WAVE/SDFR=dfr wImg1
	WAVE/SDFR=dfr wImg2
	WAVE/SDFR=dfr wXMCD
	NVAR/SDFR=dfr calculationMethod
	SVAR/SDFR=dfr wName1Str
	SVAR/SDFR=dfr wName2Str	
	string saveWaveNameStr, backupWaveNameStr, note2WaveStr, basenameStr

	variable postfix = 0
	switch(B_Struct.eventCode)	// numeric switch	
		case 2:	// "mouse up after mouse down"	
			if(calculationMethod)
				note2WaveStr = "XMC(L)D = img1/img2\n" + "img1: " \
				+ wName1Str + "\nimg2: " + wName2Str
			else
				 note2WaveStr = "XMC(L)D = (img1 - img2)/(img1 + img2)\n" + "img1: " \
				+ wName1Str + "\nimg2: " + wName2Str
			endif
			saveWaveNameStr = CreatedataObjectName(currDF, "iXMCD", 1, 0, 0)			
			Duplicate wXMCD, $saveWaveNameStr
			Note/K $saveWaveNameStr, note2WaveStr
			//Copy the interpolated wave
			backupWaveNameStr = NameofWave($wName2Str) + "_iDrift_undo"
//			if(WaveExists($basenameStr))
//				backupWaveNameStr = CreatedataObjectName(currDF, basenameStr, 1, 0, 1)
//			else
//				backupWaveNameStr = basenameStr
//			endif
			Duplicate/O $wName2Str, $backupWaveNameStr
			Note $backupWaveNameStr, ("Backup of " + wName2Str)
			//CopyScales/I wimg2, $backupWaveNameStr
			Duplicate/O wimg2, $wName2Str
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

Function MXP_XMCDCalcWithDivision(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_iXMCDPath"))
	WAVE/SDFR=dfr wImg1
	WAVE/SDFR=dfr wImg2
	WAVE/SDFR=dfr wXMCD	
	WAVE/SDFR=dfr wSum
	NVAR/SDFR=dfr calculationMethod
	string sumWinNameStr = GetUserData(cb.win.win, "", "MXP_iSumWin")
	string xmcdWinNameStr = GetUserData(cb.win.win, "", "MXP_iXMCDWin")
	switch(cb.checked)
		case 1:
			calculationMethod = 1
			SetFormula wXMCD, "wImg1/wImg2"
			SetFormula wSum, "wImg1 - wImg2"
			DoWindow/T $sumWinNameStr, "iDifference"
			DoWindow/T $xmcdWinNameStr, "iRatio"
			break
		case 0:
			calculationMethod = 0
			SetFormula wXMCD, "(wImg1 - wImg2)/(wImg1 + wImg2)"
			SetFormula wSum, "wImg1 + wImg2"
			DoWindow/T $sumWinNameStr, "iSum"
			DoWindow/T $xmcdWinNameStr, "iXMC(L)D"
			break
	endswitch
	return 0
End
