#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion= 9
#pragma ModuleName = ATH_iImgOps
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

static Function MainMenu()
	/// static Function to interactively drift images and get an updated
	/// graph of the XMC(L)D contrast.
	
	string msg = "Select two 2D waves to calculate f(w1, w2). Use Ctrl (Windows) or Cmd (Mac)."
	string selectedWavesInBrowserStr = ATH_Dialog#SelectWavesInModalDataBrowser(msg)
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
	string selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
	string wave1NameStr = StringFromList(0, selectedWavesStr)
	string wave2NameStr = StringFromList(1, selectedWavesStr)
	WAVE w1 = $wave1NameStr
	WAVE w2 = $wave2NameStr	
	if(nrSelectedWaves != 2 || !ATH_WaveOp#AllWaveDimensionsEqualQ(w1, w2) \
	   || WaveDims(w1) != 2 || WaveDims(w2) != 2)
		DoAlert/T="Please select only two 2d waves with equal dimensions sizes." 1,  ""+\
				  "Do you want a another chance with the browser selection?"
		if(V_flag == 1)
			MainMenu()
			return 0 
		elseif(V_flag > 1)
			Abort
		endif
	endif
	
	Prompt wave1NameStr, "w1", popup, selectedWavesStr
	Prompt wave2NameStr, "w2", popup, selectedWavesStr
	DoPrompt "f(w1, w2)", wave1NameStr, wave2NameStr
	if(V_flag) // User cancelled
		return -1
	endif
	
	if(!cmpstr(wave1NameStr, wave2NameStr))
		print "Ok, you are operating on the same wave! I hope you know what you are doing."
	endif
	// Create variables for the Panel. NB; Data Folders for panels can be overwritten
	// Better DFREF dfr = InitialisePanel()
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iImgOps:") 
	string folderNameStr = CreateDataObjectName(dfr, "iOP_DF",11, 0, 1)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iImgOps:" + folderNameStr)
	
	if(WaveType($wave1NameStr) & 0x10) // If WORD (int16)
		Redimension/S $wave1NameStr
	endif
	
	if(WaveType($wave2NameStr) & 0x10) // If WORD (int16)
		Redimension/S $wave2NameStr
	endif	
	
	Duplicate/O $wave1NameStr, dfr:w1
	Duplicate/O $wave2NameStr, dfr:w2, dfr:w2_undo,  dfr:wOpResult
	//Wave references
	WAVE w1 = dfr:w1
	WAVE w2 = dfr:w2	
	WAVE wOpResult = dfr:wOpResult
	// Set global variables
	variable/G dfr:gATH_driftStep = 1
	variable/G dfr:gATH_dx = 0	
	variable/G dfr:gATH_dy = 0
	string/G dfr:wName1Str = wave1NameStr
	string/G dfr:wName2Str = wave2NameStr
	string/G dfr:wOpResultStr = "root:Packages:ATH_DataFolder:iOpsImgs:" + folderNameStr + ":" + "wOpResult"
	wOpResult = w1 - w2 // Result calculated whan launched
	CreateiOpsImgsCalculationPanel(wOpResult)
End

static Function CreateiOpsImgsCalculationPanel(WAVE wOpResult)
	DFREF dfr = GetWavesDataFolderDFR(wOpResult) // Recover the dfr	
	NVAR/SDFR=dfr gATH_driftStep
	ATH_Display#NewImg(wOpResult)
	string winNameStr = WinName(0,1)
	DoWindow/T $winNameStr "iOperation"
	ControlBar/W=$winNameStr 40	
	string OpStr = "w1 - w2"
	Button SaveOpResult,win=$winNameStr,pos={20.00,10.00},size={90.00,20.00},proc=ATH_iImgOps#SaveOpResultButton
	Button SaveOpResult,win=$winNameStr,title="Save Result", help={"Save result in CWD"}, valueColor=(1,12815,52428)	
	SetVariable setDriftStep,win=$winNameStr,pos={130,10},size={120,20.00},title="Pixel step"
	SetVariable setDriftStep,win=$winNameStr,value=gATH_driftStep,help={"Set drift value for w2"}
	SetVariable setDriftStep,win=$winNameStr,fSize=14,limits={0,10,1},live=1,proc=ATH_iImgOps#SetDriftStepVar		
	SetVariable SetOpFormula,win=$winNameStr,fSize=14,pos={260,10},size={160,20.00},title="f(w1, w2)",value=_STR:OpStr
	SetVariable SetOpFormula,proc=ATH_iImgOps#SetOpFormula	
	string dfrStr = GetWavesDataFolder(wOpResult, 1)
	SetWindow $winNameStr userdata(ATH_iImgOpsDFPath) = dfrStr
	SetWindow $winNameStr userdata(ATH_iImgOpsWin) = winNameStr
	SetWindow $winNameStr, hook(MyiXMCDWinHook) = ATH_iImgOps#WindowHook // Set the hook
	return 0
End

static Function WindowHook(STRUCT WMWinHookStruct &s)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iImgOpsDFPath"))
	DFREF saveDFR = GetDataFolderDFR()
	NVAR/SDFR=dfr gATH_driftStep
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	WAVE/SDFR=dfr w1	
	WAVE/SDFR=dfr w2
	WAVE/SDFR=dfr w2_undo	
	WAVE/SDFR=dfr wOpResult
	SVAR/SDFR=dfr wName2Str
	SVAR/SDFR=dfr wName1Str
	SVAR/SDFR=dfr wOpResultStr
	
	variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
	string dfrStr = GetUserData(s.winName, "", "ATH_iImgOpsDFPath"), cmdStr
	switch(s.eventCode)
	// Window is about to be killed case 17. 
	// Needed if you want more than one hook functions to be able to cleanup/close 
	// windows linked a parent window.
		case 2:
			Duplicate/O w2, $wName2Str // wName2Str is a full path
			string note2ImgStr = "\nTotal drift dx:" + num2str(gATH_dx) \
			+ " dy:" + num2str(gATH_dy) + " of " + wName2Str
			Note w2, note2ImgStr
			string sumWinStr = GetUserData(s.winName, "", "ATH_iSumWin")
			string killwincmd = "KillWindow/Z "+sumWinStr // keep Z in case you've killed the iSum
			Execute/P/Q killWinCmd
			string killDFCmd = "KillDataFolder "+ GetDataFolder(1, dfr)
			Execute/P/Q killDFCmd
			hookresult = 1
			break
		case 11:					// Keyboard event
			SetDataFolder dfr
			switch (s.keycode)
				case 28: //left arrow
					gATH_dx -= gATH_driftStep
					ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D w2_undo
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, w2
					hookResult = 1
					break
				case 29: //right arrow
					gATH_dx += gATH_driftStep
					ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D w2_undo
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, w2				
					hookResult = 1
					break
				case 30: // up arrow
					gATH_dy -= gATH_driftStep
					ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D w2_undo
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, w2			
					hookResult = 1
					break
				case 31: // down arrow
					gATH_dy += gATH_driftStep
					ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D w2_undo
					WAVE/SDFR=dfr M_Affine
					Duplicate/O M_Affine, w2				
					hookResult = 1
					break
				case 82: // R to restore.
					Duplicate/O w2_undo, w2		
					gATH_dx = 0; gATH_dy = 0		
					hookResult = 1
					break
				default:
					hookResult = 1
					break
			endswitch
			ControlInfo/W=$s.winName SetOpFormula
			Execute/Q/Z ("MatrixOP/O wOpResult = " + S_value)
			CopyScales/I w1, w2 // Copy back the scale, M_Affine is pixel-scaled
			hookResult = 1
			break
	endswitch
	SetDataFolder saveDFR
	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

static Function SaveOpResultButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgOpsDFPath"))
	WAVE/SDFR=dfr w1
	WAVE/SDFR=dfr w2
	WAVE/SDFR=dfr wOpResult
	WAVE/SDFR=dfr w2_undo
	SVAR/SDFR=dfr wName1Str
	SVAR/SDFR=dfr wName2Str
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	
	variable postfix = 0
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			ControlInfo/W=$B_Struct.win SetOpFormula
			string note2WaveStr = "Operation: " + S_value + "\nimg1: " \
			+ wName1Str + "\nimg2: " + wName2Str + "\nTotal drift dx:" + num2str(gATH_dx) \
			+ " dy:" + num2str(gATH_dy)
			DFREF sourceDF = GetWavesDataFolderDFR($wName2Str)		
			string saveOpResWaveStr = CreatedataObjectName(sourceDF, "iOp", 1, 0, 1)
			Duplicate wOpResult, sourceDF:$saveOpResWaveStr
			Note sourceDF:$saveOpResWaveStr, note2WaveStr
			//Copy the interpolated wave
			string backupWaveNameStr = NameOfWave($wName2Str) + "_undo"
			if(!WaveExists(sourceDF:$backupWaveNameStr))
				Duplicate/O w2_undo, sourceDF:$backupWaveNameStr // Restore original image when done.
				note2WaveStr = "Backup before iImgOps of: " + wName2Str
				Note sourceDF:$backupWaveNameStr, note2WaveStr
			endif
			break
	endswitch
	return 0
End

static Function SetDriftStepVar(STRUCT WMSetVariableAction &sva) : SetVariableControl
	string dfrStr = GetUserData(sva.win, "", "ATH_iImgOpsDFPath")
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)
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

static Function SetOpFormula(STRUCT WMSetVariableAction &sva) : SetVariableControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sva.win, "", "ATH_iImgOpsDFPath"))
	DFREF saveDFR = GetDataFolderDFR()	
	string gval
	switch (sva.eventCode)
		case 1:
		case 2:
		case 3: 							// Live update
			SetDataFolder dfr
			Execute/Q/Z ("MatrixOP/O wOpResult = " + sva.sval)
			break
		case -1: 							// Control being killed
			break
	endswitch
	SetDataFolder saveDFR
	return 0
End
