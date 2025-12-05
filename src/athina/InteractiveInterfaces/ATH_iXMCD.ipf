#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion= 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_iXMCD
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


// TODO:
// Note 05.12.2025: Changed the code quickly to scale intensities instead of doing a radial interpolation
// I cannot check now, but wImg2_drift might be redundant and it might be more effecttive to 
// remove it. Have a check when you have time!


static Function MenuLaunch()
	/// Function to interactively drift images and get an updated
	/// graph of the XMC(L)D contrast.
	variable waveN = ATH_Dialog#CountSelectedWavesInDataBrowser(wDim=2)
	if(waveN==2) // If you have selected two waves only then procceed without New Browser Selection.
		string wave1NameStr = GetBrowserSelection(0)
		string wave2NameStr = GetBrowserSelection(1)
		string selectedWavesStr = wave1NameStr + ";" + wave2NameStr
	else
		string msg = "Select two waves for XMC(L)D calculation. Use Ctrl (Windows) or Cmd (Mac)."
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
		DoAlert/T="athina would like you to know that you have to ..." 1, "Please " +\
				  "select two images, i.e two 2d waves, non-RGB. \n" + \
				  "Do you want a another chance with the browser selection?"
		if(V_flag == 1)
			MenuLaunch()
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
	
	// Create variables for the Panel. NB; Data Folders for panels can be overwritten
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveXMCD:") 
	string folderNameStr = CreateDataObjectName(dfr, "iXMCD_DF",11, 0, 0)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveXMCD:" + folderNameStr)
	
	if(WaveType($wave1NameStr) & 0x10) // If WORD (int16)
		Redimension/S $wave1NameStr
	endif
	
	if(WaveType($wave2NameStr) & 0x10) // If WORD (int16)
		Redimension/S $wave2NameStr
	endif	
	
	Duplicate/O $wave1NameStr, dfr:wImg1
	Duplicate/O $wave2NameStr, dfr:wImg2, dfr:wimg2_drift, dfr:wXMCD
	//Wave references
	WAVE wImg1 = dfr:wImg1
	WAVE wImg2 = dfr:wImg2	
	WAVE wXMCD = dfr:wXMCD
	// Set global variables
	variable/G dfr:gATH_driftStep = 1, dfr:gATH_dx = 0, dfr:gATH_dy = 0, dfr:gATH_IntensityScale = 1
	string/G dfr:wName1Str = wave1NameStr, dfr:wName2Str = wave2NameStr
	wXMCD = (wImg1 - wImg2)/(wImg1 + wImg2)

	CreateiXMCDPanel(wXMCD)
End

static Function CreateiXMCDPanel(WAVE wXMCD)
	DFREF dfr = GetWavesDataFolderDFR(wXMCD) // Recover the dfr	
	NVAR/SDFR=dfr gATH_driftStep, gATH_IntensityScale

	string winiXMCDNameStr = ATH_Display#NewImg(wXMCD)
	DoWindow/T $winiXMCDNameStr "iXMC(L)D"		
	ControlBar/W=$winiXMCDNameStr 40	

	SetVariable setDriftStep,win=$winiXMCDNameStr,pos={120,10},size={140,20},title="Drift step (px)"
	SetVariable setDriftStep,win=$winiXMCDNameStr,value=gATH_driftStep,help={"Set drift value for img2"}
	SetVariable setDriftStep,win=$winiXMCDNameStr,fSize=14,limits={0,64,1},live=1,proc=ATH_iXMCD#SetDriftStepVar	

	SetVariable setImgScale,win=$winiXMCDNameStr,pos={270,10},size={120,20},title="I_scaling"
	SetVariable setImgScale,win=$winiXMCDNameStr,value=gATH_IntensityScale,help={"Intensity scaling of img2 (img2 x factor)"}
	SetVariable setImgScale,win=$winiXMCDNameStr,fSize=14,limits={0,10,0.01},live=1,proc=ATH_iXMCD#SetRadialScale

	Button SaveXMCDImage,win=$winiXMCDNameStr,pos={20,10},size={90,20},proc=ATH_iXMCD#SaveXMCDImageButton
	Button SaveXMCDImage,win=$winiXMCDNameStr,title="Save XMCD", help={"Save XMCD image in CWD"}, valueColor=(1,12815,52428)
	Button RestoreImgs title="Restore",fColor=(3,52428,1),size={70,20},pos={400,10},valueColor=(0,0,0),proc=ATH_iXMCD#RestoreImagesButton
	
	// Set the path to all windows
	string dfrStr = GetWavesDataFolder(wXMCD, 1)
	SetWindow $winiXMCDNameStr userdata(ATH_iXMCDPath) = dfrStr
	SetWindow $winiXMCDNameStr userdata(ATH_iXMCDWin) = winiXMCDNameStr
	SetWindow $winiXMCDNameStr hook(MyiXMCDWinHook) = ATH_iXMCD#iXMCDWindowHook // Set the hook
	return 0
End

static Function iXMCDWindowHook(STRUCT WMWinHookStruct &s)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iXMCDPath"))
	if(s.specialKeyCode)
		NVAR/SDFR=dfr gATH_driftStep, gATH_dx, gATH_dy
		WAVE/SDFR=dfr wImg1, wImg2, wimg2_drift, wXMCD
		SVAR/SDFR=dfr wName2Str

		variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
		string dfrStr = GetUserData(s.winName, "", "ATH_iXMCDPath"), cmdStr
		switch(s.specialKeyCode)
			case 100: //left arrow
				gATH_dx -= gATH_driftStep
				ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wimg2_drift
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, wImg2
				hookResult = 1
				break
			case 101: //right arrow
				gATH_dx += gATH_driftStep
				ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wimg2_drift
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, wImg2
				hookResult = 1
				break
			case 102: // up arrow
				gATH_dy -= gATH_driftStep
				ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wimg2_drift
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, wImg2
				hookResult = 1
				break
			case 103: // down arrow
				gATH_dy += gATH_driftStep
				ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wimg2_drift
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, wImg2
				hookResult = 1
				break
			default:
				break
		endswitch
		if(hookResult)
			CopyScales/I wimg1, wimg2 // Copy back the scale, M_Affine is pixel-scaled
			// has to be first so wXMCD, do not need rescaling
			wXMCD = (wImg1 - wImg2)/(wImg1 + wImg2)
		endif
	endif

	if(s.eventCode == 2)
		// Window is about to be killed case 17.
		// Needed if you want more than one hook functions to be able to cleanup/close
		// windows linked a parent window.
		string killDFCmd = "KillDataFolder "+ GetDataFolder(1, dfr)
		Execute/P/Q killDFCmd
		hookresult = 1
	endif
	//SetDataFolder saveDFR
	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

static Function RestoreImagesButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iXMCDPath"))
			NVAR/SDFR=dfr gATH_dx, gATH_dy, gATH_IntensityScale
			WAVE/SDFR=dfr wImg1, wImg2, wImg2_drift, wXMCD
			SVAR/SDFR=dfr wName2Str
			Duplicate/O $wName2Str, wImg2, wImg2_drift
			wXMCD = (wImg1 - wImg2)/(wImg1 + wImg2)
			gATH_dx = 0; gATH_dy = 0; gATH_IntensityScale = 1
			break
	endswitch
	return 0
End

static Function SaveXMCDImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iXMCDPath"))
			WAVE/SDFR=dfr wImg1, wImg2, wXMCD, wimg2_drift
			SVAR/SDFR=dfr wName1Str, wName2Str
			NVAR/SDFR=dfr gATH_dx, gATH_dy, gATH_IntensityScale
			variable postfix = 0
			string note2WaveStr = "XMC(L)D = (img1 - img2)/(img1 + img2)\n" + "img1: " \
			+ wName1Str + "\nimg2: " + wName2Str + "\nTotal img2 pixel drift dx:" + num2str(gATH_dx) \
			+ " dy:" + num2str(gATH_dy) + "\n"
			if(gATH_IntensityScale != 1)
				note2WaveStr += "Scaled (factor x wimg2) "+wName2Str+" with "+num2str(gATH_IntensityScale)+"\n"		
			endif
//			note2WaveStr += "Copy to command line: \nImageInterpolate/APRM={1,0,"+num2str(gATH_dx)+",0,1,"+num2str(gATH_dy)+\
//			",1,0} Affine2D " + wName2Str
			DFREF sourceDF = GetWavesDataFolderDFR($wName2Str)
			string savexmcdWaveStr = CreatedataObjectName(sourceDF, "iXMCD", 1, 0, 1)
			Duplicate wXMCD, sourceDF:$savexmcdWaveStr
			Note/K sourceDF:$savexmcdWaveStr, note2WaveStr
			break
	endswitch
	return 0
End

static Function SetDriftStepVar(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch (sva.eventCode)
		case 1: 							// Mouse up
		case 2:							// Enter key
		case 3: 							// Live update
			string dfrStr = GetUserData(sva.win, "", "ATH_iXMCDPath")
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)
			NVAR/SDFR=dfr gATH_driftStep
			gATH_driftStep = sva.dval
			break
		case -1: 							// Control being killed
			break
	endswitch

	return 0
End


static Function SetRadialScale(STRUCT WMSetVariableAction &sva) : SetVariableControl
	switch (sva.eventCode)
		case 1: 							// Mouse up
		case 2:							// Enter key
		case 3: 							// Live update
			string dfrStr = GetUserData(sva.win, "", "ATH_iXMCDPath")
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)
			NVAR/SDFR=dfr gATH_IntensityScale, gATH_dx, gATH_dy
			SVAR/SDFR=dfr wName1Str, wName2Str
			gATH_IntensityScale = sva.dval			
			WAVE/SDFR=dfr wImg1, wImg2, wXMCD, wimg2_drift
			if(gATH_IntensityScale) //should't be zero!
				Duplicate/O $wName2Str, wImg2, wImg2_drift
				wimg2 *= gATH_IntensityScale
				wimg2_drift *= gATH_IntensityScale
				wXMCD = (wImg1 - wImg2)/(wImg1 + wImg2)
			endif
			// Give info about the ratio of signals in marquee if present
			variable flag, left, right, top, bottom
			[flag, left, right, top, bottom] = ATH_Marquee#GetMarqueeToIndex()

			if(flag)
				variable avg1, avg2
				WaveStats/Q/RMD=[left, right][top, bottom] wImg2
				avg1 = V_avg
				WaveStats/Q/RMD=[left, right][top, bottom] wImg1
				avg2 = V_avg
				//print "Avg intensity ratio " + wName1Str + " / " + wName2Str + " = " + num2str(avg1/avg2)
				string baseTextStr, cmdStr
				baseTextStr = "TextBox/W="+PossiblyQuoteName(sva.win)+"/C/N=IntRatioLog \"\\Z12I\B1\M\Z12/I\B2\M\Z12 = " + "%.4f\""
				sprintf cmdStr, baseTextStr, avg1/avg2
				Execute/Q/Z cmdStr
			else
				TextBox/K/N=IntRatioLog/W=$sva.win		
			endif
			
			break
		case -1: 							// Control being killed
			break
	endswitch
	return 0
End