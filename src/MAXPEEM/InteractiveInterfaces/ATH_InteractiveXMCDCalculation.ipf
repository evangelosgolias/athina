#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion= 9
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

Function ATH_LaunchInteractiveXMCDCalculationFromMenu()
	/// Function to interactively drift images and get an updated
	/// graph of the XMC(L)D contrast.
	
	string msg = "Select two waves for XMC(L)D calculation. Use Ctrl (Windows) or Cmd (Mac)."
	string selectedWavesInBrowserStr = ATH_SelectWavesInModalDataBrowser(msg)
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
			ATH_LaunchInteractiveXMCDCalculationFromMenu()
			return 0 
		elseif(V_flag > 1)
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
	DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveXMCD:") 
	string folderNameStr = CreateDataObjectName(dfr, "iXMCD_DF",11, 0, 0)
	DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveXMCD:" + folderNameStr)
	
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
	// Set global variables
	variable/G dfr:gATH_driftStep = 1
	variable/G dfr:gATH_dx = 0	
	variable/G dfr:gATH_dy = 0
	string/G dfr:wName1Str = wave1NameStr
	string/G dfr:wName2Str = wave2NameStr
	wXMCD = (wImg1 - wImg2)/(wImg1 + wImg2)
	wSum = wImg1 + wImg2
	ATH_CreateInteractiveXMCDCalculationPanel(wXMCD, wSum)
End

Function ATH_CreateInteractiveXMCDCalculationPanel(WAVE wXMCD, WAVE wSum)
	DFREF dfr = GetWavesDataFolderDFR(wXMCD) // Recover the dfr	
	NVAR/SDFR=dfr gATH_driftStep

	ATH_DisplayImage(wSum)
	string winiSumNameStr = WinName(0,1)
	DoWindow/T $winiSumNameStr "iSum"	
	ATH_DisplayImage(wXMCD)
	string winiXMCDNameStr = WinName(0,1)
	DoWindow/T $winiXMCDNameStr "iXMC(L)D"		
	ControlBar/W=$winiXMCDNameStr 40	
	
	SetVariable setDriftStep,win=$winiXMCDNameStr,pos={130,10},size={160,20.00},title="Drift step (px)"
	SetVariable setDriftStep,win=$winiXMCDNameStr,value=gATH_driftStep,help={"Set drift value for img2"}
	SetVariable setDriftStep,win=$winiXMCDNameStr,fSize=14,limits={0,10,1},live=1,proc=ATH_SetDriftStepVar	

	Button SaveXMCDImage,win=$winiXMCDNameStr,pos={20.00,10.00},size={90.00,20.00},proc=ATH_SaveXMCDImageButton
	Button SaveXMCDImage,win=$winiXMCDNameStr,title="Save XMCD", help={"Save XMCD image in CWD"}, valueColor=(1,12815,52428)

	// Set the path to all windows
	string dfrStr = GetWavesDataFolder(wXMCD, 1)
	SetWindow $winiXMCDNameStr userdata(ATH_iXMCDPath) = dfrStr
	SetWindow $winiXMCDNameStr userdata(ATH_iXMCDWin) = winiXMCDNameStr
	SetWindow $winiXMCDNameStr userdata(ATH_iSumWin) = winiSumNameStr
	SetWindow $winiXMCDNameStr, hook(MyiXMCDWinHook) = ATH_InteractiveXMCDWindowHook // Set the hook
	return 0
End

Function ATH_InteractiveXMCDWindowHook(STRUCT WMWinHookStruct &s)
	DFREF dfr = ATH_CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iXMCDPath"))
	NVAR/SDFR=dfr gATH_driftStep
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	WAVE/SDFR=dfr wImg1	
	WAVE/SDFR=dfr wImg2
	WAVE/SDFR=dfr wImg2_undo	
	WAVE/SDFR=dfr wXMCD
	WAVE/SDFR=dfr wSum
	SVAR/SDFR=dfr wName2Str

	variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
	string dfrStr = GetUserData(s.winName, "", "ATH_iXMCDPath"), cmdStr
	switch(s.eventCode)
	// Window is about to be killed case 17. 
	// Needed if you want more than one hook functions to be able to cleanup/close 
	// windows linked a parent window.
		case 2:
			Duplicate/O wimg2, $wName2Str // wName2Str is a full path
			string note2ImgStr = "\nTotal drift dx:" + num2str(gATH_dx) \
			+ " dy:" + num2str(gATH_dy) + " of " + wName2Str
			Note wimg2, note2ImgStr
			string sumWinStr = GetUserData(s.winName, "", "ATH_iSumWin")
			string killwincmd = "KillWindow/Z "+sumWinStr // keep Z in case you've killed the iSum
			Execute/P/Q killWinCmd
			WaveClear wImg1, wImg2, wXMCD, wSum, wImg2_undo
			string killDFCmd = "KillDataFolder "+ GetDataFolder(1, dfr)
			Execute/P/Q killDFCmd
			hookresult = 1
			break
		case 11:					// Keyboard event
			switch (s.keycode)
				case 28: //left arrow
					gATH_dx -= gATH_driftStep
					ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wImg2_undo
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, wImg2
					hookResult = 1
					break
				case 29: //right arrow
					gATH_dx += gATH_driftStep
					ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wImg2_undo
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, wImg2				
					hookResult = 1
					break
				case 30: // up arrow
					gATH_dy -= gATH_driftStep
					ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wImg2_undo
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, wImg2			
					hookResult = 1
					break
				case 31: // down arrow
					gATH_dy += gATH_driftStep
					ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wImg2_undo
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
			wXMCD = (wImg1 - wImg2)/(wImg1 + wImg2)
			wSum = wImg1 + wImg2
			CopyScales/I wimg1, wimg2 // Copy back the scale, M_Affine is pixel-scaled
			break
	endswitch
	//SetDataFolder saveDFR
	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

Function ATH_SaveXMCDImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = ATH_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iXMCDPath"))
	WAVE/SDFR=dfr wImg1
	WAVE/SDFR=dfr wImg2
	WAVE/SDFR=dfr wXMCD
	WAVE/SDFR=dfr wimg2_undo
	SVAR/SDFR=dfr wName1Str
	SVAR/SDFR=dfr wName2Str
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	
	variable postfix = 0
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			string note2WaveStr = "XMC(L)D = (img1 - img2)/(img1 + img2)\n" + "img1: " \
			+ wName1Str + "\nimg2: " + wName2Str + "\nTotal drift dx:" + num2str(gATH_dx) \
			+ " dy:" + num2str(gATH_dy)
			DFREF sourceDF = GetWavesDataFolderDFR($wName2Str)		
			string savexmcdWaveStr = CreatedataObjectName(sourceDF, "iXMCD", 1, 0, 1)
			Duplicate wXMCD, sourceDF:$savexmcdWaveStr
			Note sourceDF:$savexmcdWaveStr, note2WaveStr
			//Copy the interpolated wave
			string backupWaveNameStr = NameOfWave($wName2Str) + "_noDrift"
			//string saveWave2NameStr = CreatedataObjectName(sourceDF, wname2BaseStr, 1, 0, 1)
			if(!WaveExists(sourceDF:$backupWaveNameStr))
				Duplicate/O wimg2_undo, sourceDF:$backupWaveNameStr // Restore original image when done.
				note2WaveStr = "Backup before iDrift of: " + wName2Str
				Note sourceDF:$backupWaveNameStr, note2WaveStr
			endif
			break
	endswitch
	return 0
End

Function ATH_SetDriftStepVar(STRUCT WMSetVariableAction &sva) : SetVariableControl
	string dfrStr = GetUserData(sva.win, "", "ATH_iXMCDPath")
	DFREF dfr = ATH_CreateDataFolderGetDFREF(dfrStr)
	NVAR/SDFR=dfr gATH_driftStep	
	switch (sva.eventCode)
		case 1: 							// Mouse up
		case 2:							// Enter key
		case 3: 							// Live update
			gATH_driftStep = sva.dval
			break
		case -1: 							// Control being killed
			break
	endswitch

	return 0
End

