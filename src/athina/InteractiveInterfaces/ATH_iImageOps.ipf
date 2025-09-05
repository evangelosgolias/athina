#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion= 9
#pragma ModuleName = ATH_iImgOps
#pragma version = 1.1

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

	variable waveN = ATH_Dialog#CountSelectedWavesInDataBrowser(wDim=2)
	if(waveN==2) // If you have selected two waves only then procceed without New Browser Selection.
		string wave1NameStr = GetBrowserSelection(0)
		string wave2NameStr = GetBrowserSelection(1)
		string selectedWavesStr = wave1NameStr + ";" + wave2NameStr
	else
		string msg = "Select two waves for custom interactive calculation. Use Ctrl (Windows) or Cmd (Mac)."
		string selectedWavesInBrowserStr = ATH_Dialog#SelectWavesInModalDataBrowser(msg)
		// S_fileName is a carriage-return-separated list of full paths to one or more files.
		waveN = ItemsInList(selectedWavesInBrowserStr)
		selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
		if(!strlen(selectedWavesStr))
			return NaN
		endif		
		wave1NameStr = StringFromList(0, selectedWavesStr)
		wave2NameStr = StringFromList(1, selectedWavesStr)
	endif
	WAVE w1 = $wave1NameStr
	WAVE w2 = $wave2NameStr
	if(waveN != 2 || !ATH_WaveOp#WaveDimensionsEqualQ(w1, w2) \
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
	Duplicate/O $wave2NameStr, dfr:w2, dfr:w2_undo,  dfr:wOpResult, dfr:wSecOpResult
	//Wave references
	WAVE w1 = dfr:w1
	WAVE w2 = dfr:w2	
	WAVE wOpResult = dfr:wOpResult
	// Set global variables
	variable/G dfr:gATH_driftStep = 1
	variable/G dfr:gATH_dx = 0	
	variable/G dfr:gATH_dy = 0
	variable/G dfr:gATH_secOp = 0	
	string/G dfr:wName1Str = wave1NameStr
	string/G dfr:wName2Str = wave2NameStr
	wOpResult = w1 - w2 // Result calculated whan launched
	CreateiOpsImgsCalculationPanel(wOpResult)
End

static Function CreateiOpsImgsCalculationPanel(WAVE wOpResult)
	DFREF dfr = GetWavesDataFolderDFR(wOpResult) // Recover the dfr	
	NVAR/SDFR=dfr gATH_driftStep
	string winNameStr = ATH_Display#NewImg(wOpResult)
	DoWindow/T $winNameStr "iOperation"
	ControlBar/W=$winNameStr 60	
	string OpStr = "w1 - w2"
	string SecOpStr = "w1 + w2"
	Button SaveOpResult,win=$winNameStr,pos={20.00,8},size={90.00,18},proc=ATH_iImgOps#SaveOpResultButton
	Button SaveOpResult,win=$winNameStr,title="Save Result", help={"Save result in CWD"}, valueColor=(1,12815,52428)	
	Button RestoreImgs,win=$winNameStr,title="Restore",pos={20.00,35},size={90.00,20.00},fColor=(3,52428,1),proc=ATH_iImgOps#RestoreImagesButton	
	SetVariable setDriftStep,win=$winNameStr,pos={130,8},size={120,20.00},title="Pixel step"
	SetVariable setDriftStep,win=$winNameStr,value=gATH_driftStep,help={"Set drift value for w2"}
	SetVariable setDriftStep,win=$winNameStr,fSize=14,limits={0,32,1},live=1,proc=ATH_iImgOps#SetDriftStepVar		
	SetVariable SetOpFormula,win=$winNameStr,fSize=14,pos={260,8},size={160,20.00},title="f(w1, w2)",value=_STR:OpStr
	SetVariable SetOpFormula,proc=ATH_iImgOps#SetOpFormula
	CheckBox SecOp, pos={130,35}, side=1, size={120.00,20}, proc=ATH_iImgOps#CheckBoxSecOp,title="Enable Sec. Op.", fSize=14, value= 0
	SetVariable SetSecOpFormula,win=$winNameStr,fSize=14,pos={260,35},size={160,20.00},title="secOp",value=_STR:SecOpStr, proc=ATH_iImgOps#SetSecOpFormula
	string dfrStr = GetWavesDataFolder(wOpResult, 1)
	SetWindow $winNameStr userdata(ATH_iImgOpsDFPath) = dfrStr
	SetWindow $winNameStr userdata(ATH_iImgOpsWin) = winNameStr
	SetWindow $winNameStr, hook(MyiXMCDWinHook) = ATH_iImgOps#WindowHook // Set the hook
	return 0
End

static Function WindowHook(STRUCT WMWinHookStruct &s)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iImgOpsDFPath"))
	DFREF saveDFR = GetDataFolderDFR()
	NVAR/SDFR=dfr gATH_driftStep, gATH_dx, gATH_dy
	WAVE/SDFR=dfr w1	, w2, w2_undo, wOpResult
	SVAR/SDFR=dfr wName2Str, wName1Str
	NVAR/Z/SDFR=dfr gATH_secOp
	
	variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
	string dfrStr = GetUserData(s.winName, "", "ATH_iImgOpsDFPath"), cmdStr
	SetDataFolder dfrStr
	if(s.specialKeyCode)	
		switch(s.specialKeyCode)
			case 100: //left arrow
				gATH_dx -= gATH_driftStep
				ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D w2_undo
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, w2
				hookResult = 1
				break
			case 101: //right arrow
				gATH_dx += gATH_driftStep
				ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D w2_undo
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, w2
				hookResult = 1
				break
			case 102: // up arrow
				gATH_dy -= gATH_driftStep
				ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D w2_undo
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, w2
				hookResult = 1
				break
			case 103: // down arrow
				gATH_dy += gATH_driftStep
				ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D w2_undo
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, w2
				hookResult = 1
				break
			default:
				break
		endswitch
		
		if(hookResult) // hookResult == 1, we handle the event so an arrow has been pressed. Calculate images
			ControlInfo/W=$s.winName SetOpFormula
			Execute/Q/Z ("MatrixOP/O wOpResult = " + S_value)
			if(gATH_secOp)
				ControlInfo/W=$s.winName SetSecOpFormula
				Execute/Q/Z ("MatrixOP/O wSecOpResult = " + S_value)
			endif
			CopyScales/I w1, w2 // Copy back the scale, M_Affine is pixel-scaled
		endif
	endif	

	if(s.eventCode == 2)
//		Duplicate/O w2_undo, $wName2Str // wName2Str is a full path
//		string note2ImgStr = "\nTotal drift dx:" + num2str(gATH_dx) \
//		+ " dy:" + num2str(gATH_dy) + " of " + wName2Str
//		Note w2, note2ImgStr
		string killwincmd = "KillWindow/Z "+ GetUserData(s.WinName,"", "ATH_iSecOpWinName")
		Execute/P/Q killWinCmd
		string killDFCmd = "KillDataFolder/Z "+ GetDataFolder(1, dfr)
		Execute/P/Q killDFCmd
		hookresult = 1
	endif
	SetDataFolder saveDFR
	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

static Function RestoreImagesButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgOpsDFPath"))
			DFREF saveDFR = GetDataFolderDFR()
			NVAR/SDFR=dfr gATH_dx, gATH_dy
			NVAR/Z/SDFR=dfr gATH_secOp
			WAVE/SDFR=dfr w1, w2, w2_undo, wOpResult
			SetDataFolder dfr
			Duplicate/O w2_undo, w2
			gATH_dx = 0; gATH_dy = 0
			ControlInfo/W=$B_Struct.win SetOpFormula
			Execute/Q/Z ("MatrixOP/O wOpResult = " + S_value)
			if(gATH_secOp)
				ControlInfo/W=$B_Struct.win SetSecOpFormula
				Execute/Q/Z ("MatrixOP/O wSecOpResult = " + S_value)
			endif
			SetDataFolder saveDFR
			break
	endswitch
	return 0
End

static Function SaveOpResultButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable postfix = 0
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgOpsDFPath"))
			WAVE/SDFR=dfr w1, w2, wOpResult, w2_undo
			SVAR/SDFR=dfr wName1Str, wName2Str
			NVAR/SDFR=dfr gATH_dx, gATH_dy

			ControlInfo/W=$B_Struct.win SetOpFormula
			string note2WaveStr = "Operation: " + S_value + "\nimg1 (w1): " \
			+ wName1Str + "\nimg2 (w2): " + wName2Str + "\nTotal w2 drift dx:" + num2str(gATH_dx) \
			+ " dy:" + num2str(gATH_dy) +"\n"
			note2WaveStr += "Copy to command line: \nImageInterpolate/APRM={1,0,"+num2str(gATH_dx)+",0,1,"+num2str(gATH_dy)+\
			",1,0} Affine2D " + wName2Str
			DFREF sourceDF = GetWavesDataFolderDFR($wName2Str)
			string saveOpResWaveStr = CreatedataObjectName(sourceDF, "iOp", 1, 0, 1)
			Duplicate wOpResult, sourceDF:$saveOpResWaveStr
			Note sourceDF:$saveOpResWaveStr, note2WaveStr
			break
	endswitch
	return 0
End

static Function SetDriftStepVar(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch (sva.eventCode)
		case 1: 							// Mouse up
		case 2:							// Enter key
		case 3: 							// Live update
			string dfrStr = GetUserData(sva.win, "", "ATH_iImgOpsDFPath")
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)
			NVAR/SDFR=dfr gATH_driftStep
			gATH_driftStep = sva.dval
			break
		case -1: 							// Control being killed
			break
	endswitch

	return 0
End

static Function SetOpFormula(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch (sva.eventCode)
		case 1:
		case 2:
		case 3: 							// Live update
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sva.win, "", "ATH_iImgOpsDFPath"))
			DFREF saveDFR = GetDataFolderDFR()
			SetDataFolder dfr
			Execute/Q/Z ("MatrixOP/O wOpResult = " + sva.sval)
			SetDataFolder saveDFR
			break
		case -1: 							// Control being killed
			break
	endswitch
	return 0
End

static Function SetSecOpFormula(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch (sva.eventCode)
		case 1:
		case 2:
		case 3: 							// Live update
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sva.win, "", "ATH_iImgOpsDFPath"))
			DFREF saveDFR = GetDataFolderDFR()			
			SetDataFolder dfr
			Execute/Q/Z ("MatrixOP/O wSecOpResult = " + sva.sval)
			SetDataFolder saveDFR
			break
		case -1: 							// Control being killed
			break
	endswitch
	return 0
End

static Function CheckBoxSecOp(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_iImgOpsDFPath"))
	NVAR/Z/SDFR=dfr gATH_secOp
	DFREF saveDFR = GetDataFolderDFR()
	switch(cb.checked)
		case 1:		// Mouse up
			// Create the twinwave plot
			gATH_secOp = 1
			WAVE/SDFR=dfr wSecOpResult
			SetDataFolder dfr
			ControlInfo/W=$cb.win SetSecOpFormula
			Execute/Q/Z ("MatrixOP/O wSecOpResult = " + S_value)
			if(!strlen(GetUserData(cb.win,"", "ATH_iSecOpWinName")))
				string iSecOpWinName = UniqueName(cb.win+"_secOp", 6, 0)
				ATH_Display#NewImg(wSecOpResult, grfName=iSecOpWinName)
				SetWindow $cb.win userdata(ATH_iSecOpWinName) = iSecOpWinName
				DoWindow/T $iSecOpWinName "iSecOperation"			
			endif
			SetDataFolder saveDFR
			break
		case 0:
			KillWindow/Z $GetUserData(cb.win,"", "ATH_iSecOpWinName")
			SetWindow $cb.win userdata(ATH_iSecOpWinName) = ""
			gATH_secOp = 0			
			break
	endswitch
	return 0
End
