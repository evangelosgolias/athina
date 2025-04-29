#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion= 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_iXMCD
#pragma version = 2.0

// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: egolias@protonmail.com
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

static Function MenuLaunch()
	/// Function to interactively drift images and get an updated
	/// graph of the XMC(L)D contrast.
	variable waveN = ATH_Dialog#CountSelectedWavesInDataBrowser(wDims=2)
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
		wave1NameStr = StringFromList(0, selectedWavesStr)
		wave2NameStr = StringFromList(1, selectedWavesStr)
	endif
	
	if(waveN != 2 || WaveDims($wave1NameStr) != 2 || WaveDims($wave2NameStr) != 2)
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
	Duplicate/O $wave2NameStr, dfr:wImg2, dfr:wImg2_undo, dfr:wXMCD, dfr:wImg2_orig
	//Wave references
	WAVE wImg1 = dfr:wImg1
	WAVE wImg2 = dfr:wImg2	
	WAVE wXMCD = dfr:wXMCD
	// Set global variables
	variable/G dfr:gATH_driftStep = 1
	variable/G dfr:gATH_dx = 0	
	variable/G dfr:gATH_dy = 0
	string/G dfr:wName1Str = wave1NameStr
	string/G dfr:wName2Str = wave2NameStr
	wXMCD = (wImg1 - wImg2)/(wImg1 + wImg2)

	CreateiXMCDPanel(wXMCD)
End

static Function CreateiXMCDPanel(WAVE wXMCD)
	DFREF dfr = GetWavesDataFolderDFR(wXMCD) // Recover the dfr	
	NVAR/SDFR=dfr gATH_driftStep
	ATH_Display#NewImg(wXMCD)
	string winiXMCDNameStr = WinName(0,1)
	DoWindow/T $winiXMCDNameStr "iXMC(L)D"		
	ControlBar/W=$winiXMCDNameStr 40	
	string pixelationList = "\""+"1;" + num2str(DimSize(wXMCD,0)/16) + ";" + num2str(DimSize(wXMCD,0)/8)
	pixelationList += ";" + num2str(DimSize(wXMCD,0)/4) + ";" + num2str(DimSize(wXMCD,0)/2) + ";" + "\""
	variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
	SetVariable setDriftStep,win=$winiXMCDNameStr,pos={100*pntConv,10*pntConv},size={100*pntConv,20*pntConv},title="Step (px)"
	SetVariable setDriftStep,win=$winiXMCDNameStr,value=gATH_driftStep,help={"Set drift value for img2"}
	SetVariable setDriftStep,win=$winiXMCDNameStr,fSize=12,limits={0,100,1},live=1,proc=ATH_iXMCD#SetDriftStepVar	

	PopupMenu DownScaleFactor,mode=1,fSize=10,title="PX:",pos={275*pntConv,10*pntConv}
	PopupMenu DownScaleFactor,help={"Pixelate image to the selected size for ImageRegistration. If set to 1 use native size."}
	PopupMenu DownScaleFactor,value=#pixelationList,proc=ATH_iXMCD#DownScaleFactorPopup
	
	Button SaveXMCDImage,win=$winiXMCDNameStr,pos={5*pntConv,10*pntConv},size={90*pntConv,20*pntConv},proc=ATH_iXMCD#SaveXMCDImageButton
	Button SaveXMCDImage,win=$winiXMCDNameStr,title="Save XMCD", help={"Save XMCD image in CWD"}, valueColor=(1,12815,52428)
	Button RegistreImgs title="Register",fColor=(32768,54615,65535),size={60*pntConv,20*pntConv},pos={210*pntConv,10*pntConv},valueColor=(0,0,0)
	Button RegistreImgs help={"Align the image before registration, use marquee to register using a specific region."},proc=ATH_iXMCD#RegisterImageButton
	Button RestoreImgs title="Restore",fColor=(3,52428,1),size={60*pntConv,20*pntConv},pos={365*pntConv,10*pntConv},valueColor=(0,0,0),proc=ATH_iXMCD#RestoreImagesButton
	
	// Set the path to all windows
	string dfrStr = GetWavesDataFolder(wXMCD, 1)
	SetWindow $winiXMCDNameStr userdata(ATH_iXMCDPath) = dfrStr
	SetWindow $winiXMCDNameStr userdata(ATH_iXMCDWin) = winiXMCDNameStr
	SetWindow $winiXMCDNameStr hook(MyiXMCDWinHook) = ATH_iXMCD#iXMCDWindowHook // Set the hook
	return 0
End

static Function iXMCDWindowHook(STRUCT WMWinHookStruct &s)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iXMCDPath"))
	NVAR/SDFR=dfr gATH_driftStep
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	WAVE/SDFR=dfr wImg1	
	WAVE/SDFR=dfr wImg2
	WAVE/SDFR=dfr wImg2_undo	
	WAVE/SDFR=dfr wXMCD
	SVAR/SDFR=dfr wName2Str
	
	variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
	string dfrStr = GetUserData(s.winName, "", "ATH_iXMCDPath"), cmdStr
	// deal with arrows
	if(s.specialKeyCode)
		switch(s.specialKeyCode)
			case 100: //left arrow
				gATH_dx -= gATH_driftStep
				ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wImg2_undo
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, wImg2
				hookResult = 1
				break
			case 101: //right arrow
				gATH_dx += gATH_driftStep
				ImageInterpolate/APRM={1,0, gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wImg2_undo
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, wImg2
				hookResult = 1
				break
			case 102: // up arrow
				gATH_dy -= gATH_driftStep
				ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wImg2_undo
				WAVE/SDFR=dfr M_Affine
				Duplicate/O M_Affine, wImg2
				hookResult = 1
				break
			case 103: // down arrow
				gATH_dy += gATH_driftStep
				ImageInterpolate/APRM={1,0,gATH_dx,0,1,gATH_dy,1,0}/DEST=dfr:M_Affine Affine2D wImg2_undo
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
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iXMCDPath"))
	WAVE/SDFR=dfr wImg1
	WAVE/SDFR=dfr wImg2
	WAVE/SDFR=dfr wXMCD
	WAVE/SDFR=dfr wImg2_orig
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			Duplicate/O dfr:wImg2_orig, dfr:wImg2
			Duplicate/O dfr:wImg2_orig, dfr:wImg2_undo
			wXMCD = (wImg1 - wImg2)/(wImg1 + wImg2)
			KillWaves/Z dfr:W_RegParams
			gATH_dx = 0; gATH_dy = 0
			break
	endswitch
	return 0
End


static Function RegisterImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iXMCDPath"))
	WAVE/SDFR=dfr wImg1
	WAVE/SDFR=dfr wImg2
	WAVE/SDFR=dfr wXMCD
	WAVE/SDFR=dfr wimg2_undo
	NVAR/SDFR=dfr gATH_dx, gATH_dy	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			DFREF saveDF = GetDataFolderDFR() 
			//SetDataFolder GetWavesDataFolderDFR(wimg2_undo)
			ControlInfo/W=$B_Struct.win DownScaleFactor
			variable scaleFactor = str2num(S_Value)
			variable px = 1; variable py = 1

			string axisX, axisY
			[axisX, axisY] = ATH_Graph#GetAxes(grfName = B_Struct.win)
			GetMarquee/W=$B_Struct.win/Z/K $axisX, $axisY; // Generalise here.
			variable marqueeQ = V_flag			
						
			if(scaleFactor==1 || marqueeQ)
				WAVE wRefp = wImg1
				WAVE wtestp = wImg2
			else
				px = DimSize(wimg2_undo, 0)/scaleFactor
				py = DimSize(wimg2_undo, 1)/scaleFactor
				ImageInterpolate/PXSZ={px,py} Pixelate wImg1
				WAVE M_PixelatedImage
				Duplicate/FREE M_PixelatedImage, wRefp
				ImageInterpolate/PXSZ={px,py} Pixelate wImg2
				Duplicate/FREE M_PixelatedImage, wtestp
			endif
			//ImageRegistration/USER=W_RegParams/TSTM=0 testWave=w1
			// Error handling in case axes are different


			if(!marqueeQ)
				ImageRegistration/Q/CONV=1/PRDL=1/TRNS={1,1,1}/ISOS/TSTM=0/BVAL=0 testwave=wtestp, refwave=wRefp
			else
				ATH_Marquee#CoordinatesToROIMask(V_left, V_top, V_right, V_bottom, interior = 0, exterior = 1, spW = 1)
				WAVE M_ROIMask
				if(px*py)					
					ImageInterpolate/PXSZ={px,py} Pixelate M_ROIMask
					WAVE refM = M_PixelatedImage
				else
					WAVE refM = M_ROIMask
				endif
				ImageRegistration/Q/CONV=1/PRDL=1/ISOS/TRNS={1,1,1}/BVAL=0 refMask=refM, testwave=wtestp, refwave=wRefp
			endif

			WAVE M_RegOut, W_RegParams

			W_RegParams[0] *= px==0 ? 1 : px
			W_RegParams[1] *= py==0 ? 1 : py

			ImageRegistration/Q/USER=W_RegParams/TSTM=0/BVAL=0 testwave=wImg2

			Duplicate/O M_RegOut, wImg2_undo // Overwire the undo that is translated

			wXMCD = (wImg1 - wImg2_undo)/(wImg1 + wImg2_undo)
			gATH_dx = 0; gATH_dy = 0
			SetDataFolder saveDF
			break
	endswitch
	return 0
End

static Function SaveXMCDImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iXMCDPath"))
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
			+ wName1Str + "\nimg2: " + wName2Str + "\nTotal img2 pixel drift dx:" + num2str(gATH_dx) \
			+ " dy:" + num2str(gATH_dy) + "\n"
			note2WaveStr += "Copy to command line: \nImageInterpolate/APRM={1,0,"+num2str(gATH_dx)+",0,1,"+num2str(gATH_dy)+\
			",1,0} Affine2D " + wName2Str
			if(WaveExists(dfr:W_RegParams))
				string imgRegStr = ATH_String#WaveToString(dfr:W_RegParams,sep=",")
				note2WaveStr += "\nMake/N=22 W_RegParams = {" + RemoveEnding(imgRegStr) +"};"
				note2WaveStr += "ImageRegistration/USER=W_RegParams/TSTM=0/BVAL=0 testwave="+wName2Str
				note2WaveStr += "\nNote:After the Affine/Registration drift correction might be needed for alignmemt"
			endif
			DFREF sourceDF = GetWavesDataFolderDFR($wName2Str)
			string savexmcdWaveStr = CreatedataObjectName(sourceDF, "iXMCD", 1, 0, 1)
			Duplicate wXMCD, sourceDF:$savexmcdWaveStr
			ATH_DFR#BackupWaveInWaveDF($wName2Str) // Create backup
			Duplicate/O dfr:wImg2, $wName2Str		// and ovewrite original
			Note sourceDF:$savexmcdWaveStr, note2WaveStr
			break
	endswitch
	return 0
End

static Function SetDriftStepVar(STRUCT WMSetVariableAction &sva) : SetVariableControl
	string dfrStr = GetUserData(sva.win, "", "ATH_iXMCDPath")
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

static Function DownScaleFactorPopup (STRUCT WMPopupAction &PU_Struct) : PopupMenuControl
	string dfrStr = GetUserData(PU_Struct.win, "", "ATH_iXMCDPath")
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)
	switch (PU_Struct.eventCode)
		case 2:
			PopupMenu DownScaleFactor, win=$PU_Struct.win, popvalue=PU_Struct.popStr
			break
		case -1: 							// Control being killed
			break
	endswitch

	return 0
End