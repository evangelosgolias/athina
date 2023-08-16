﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late

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

constant kMXPEnergyPerPixel = 0.00780685 // energy per pixel - default setting 30.04.2023


Function MXP_MainMenuLaunchPESExtractor()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph."
		return -1
	endif
	WAVE imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string LinkedPlotStr = GetUserData(winNameStr, "", "MXP_LinkedPESExtractorPlotStr")
	if(strlen(LinkedPlotStr))
		DoWindow/F LinkedPlotStr
		return 0
	endif
	MXP_InitialisePESExtractorFolder(winNameStr)
	variable nrows = DimSize(imgWaveRef,0)
	variable ncols = DimSize(imgWaveRef,1)
	// Cursors to set the scale
	Cursor/I/C=(0,65535,0)/H=1/P/N=1 A $imgNameTopGraphStr round(1.8 * nrows/2), round(0.2 * ncols/2)
	Cursor/I/C=(0,65535,0)/H=1/P/N=1 B $imgNameTopGraphStr round(0.2 * nrows/2), round(1.8 * ncols/2)
	// Cursors to get the profile
	Cursor/I/C=(65535,0,0)/S=1/P/N=1 E $imgNameTopGraphStr round(1.6 * nrows/2), round(0.4 * ncols/2)
	Cursor/I/C=(65535,0,0)/S=1/P/N=1 F $imgNameTopGraphStr round(0.4 * nrows/2), round(1.6 * ncols/2)
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESExtractor:" + NameOfWave(imgWaveRef)) // Change root folder if you want
	MXP_InitialisePESExtractorGraph(dfr)
	SetWindow $winNameStr, hook(MyPESExtractorHook) = MXP_CursorHookFunctionPESExtractor // Set the hook
	SetWindow $winNameStr userdata(MXP_LinkedPESExtractorPlotStr) = "MXP_PESProfPlot_" + winNameStr // Name of the plot we will make, used to communicate the
	SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_PESProf_" + winNameStr //  Same as gMXP_WindowNameStr, see MXP_InitialisePESExtractorFolder
	return 0
End

Function MXP_InitialisePESExtractorFolder(string winNameStr)
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here. Use the 3D wave in top window.

	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string msg // Error reporting
	if(!strlen(imgNameTopGraphStr)) // we do not have an image in top graph
		Abort "No image in top graph. Start the PES extractor with an image or image stack in top window."
	endif
	
	if(WaveDims(imgWaveRef) != 2 && WaveDims(imgWaveRef) != 3)
		sprintf msg, "PES extractor works with images or image stacks.  Wave %s is in top window", imgNameTopGraphStr
		Abort msg
	endif
	
	if(stringmatch(AxisList(winNameStr),"*bottom*")) // Check if you have a NewImage left;top axes
		sprintf msg, "Reopen as Newimage %s", imgNameTopGraphStr
		KillWindow $winNameStr
		NewImage/K=1/N=$winNameStr imgWaveRef
		ModifyGraph/W=$winNameStr width={Plan,1,top,left}
	endif
	
	if(WaveDims(imgWaveRef) == 3)
		WMAppend3DImageSlider() // Everything ok now, add a slider to the 3d wave
	endif
    
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESExtractor:" + imgNameTopGraphStr) // Root folder here
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESExtractor:DefaultSettings:") // Settings here

	variable nrows = DimSize(imgWaveRef,0)
	variable ncols = DimSize(imgWaveRef,1)

	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_ImagePathname = GetWavesDataFolder(imgWaveRef, 2)
	string/G dfr:gMXP_ImagePath = GetWavesDataFolder(imgWaveRef, 1)
	string/G dfr:gMXP_ImageNameStr = NameOfWave(imgWaveRef)
	variable/G dfr:gMXP_dx = DimDelta(imgWaveRef,0)
	variable/G dfr:gMXP_dy = DimDelta(imgWaveRef,1)
	variable/G dfr:gMXP_C1x = round(1.1 * nrows/2)
	variable/G dfr:gMXP_C1y = round(0.9 * ncols/2)
	variable/G dfr:gMXP_C2x = round(0.9 * nrows/2)
	variable/G dfr:gMXP_C2y = round(1.1 * ncols/2)
	variable/G dfr:gMXP_profileWidth = 0
	variable/G dfr:gMXP_selectedLayer = 0
	variable/G dfr:gMXP_updateSelectedLayer = 0
	variable/G dfr:gMXP_updateCursorsPositions = 0
	// PES scaling values
	variable/G dfr:gMXP_hv = MXP_GetPhotonEnergyFromFilename(imgNameTopGraphStr)
	variable/G dfr:gMXP_Wf = 4.5
	variable/G dfr:gMXP_epp = kMXPEnergyPerPixel
	variable/G dfr:gMXP_Ax = 0
	variable/G dfr:gMXP_Ay = 0	
	variable/G dfr:gMXP_Bx = 0
	variable/G dfr:gMXP_By = 0
	variable/G dfr:gMXP_STV = NumberByKey("STV(V)",note(imgWaveRef),":","\n" ) // Start voltage from metadata
	variable/G dfr:gMXP_Eoffset = 0
	variable/G dfr:gMXP_linepx
	variable/G dfr:gMXP_lowBE // bottom left part is the low BE.
	
	// Switches and indicators
	variable/G dfr:gMXP_PlotSwitch = 1
	variable/G dfr:gMXP_MarkPESLineSwitch = 0
	variable/G dfr:gMXP_SelectLayer = 0
	variable/G dfr:gMXP_colorcnt = 0
	variable/G dfr:gMXP_mouseTrackV
	variable/G dfr:gMXP_CursorABSwitch = 0 // Have you set the cursors ?=
	// Default settings
	NVAR/Z/SDFR=dfr0 gMXP_profileWidth0
	if(!NVAR_Exists(gMXP_profileWidth0)) // init only once and do not overwrite
		variable/G dfr0:gMXP_C1x0 = round(1.1 * nrows/2)
		variable/G dfr0:gMXP_C1y0 = round(0.9 * ncols/2)
		variable/G dfr0:gMXP_C2x0 = round(0.9 * nrows/2)
		variable/G dfr0:gMXP_C2y0 = round(1.1 * ncols/2)
		variable/G dfr0:gMXP_profileWidth0 = 0
		variable/G dfr0:gMXP_Ax0
		variable/G dfr0:gMXP_Ay0	
		variable/G dfr0:gMXP_Bx0
		variable/G dfr0:gMXP_By0
		variable/G dfr0:gMXP_linepx0
		variable/G dfr0:gMXP_epp0
		variable/G dfr0:gMXP_Wf0	
	endif
	return 0
End

Function MXP_InitialisePESExtractorGraph(DFREF dfr)
	/// Here we will create the profile plot and graph and plot the profile
	string plotNameStr = "MXP_PESProf_" + GetDataFolder(0, dfr)
	if (WinType(plotNameStr) == 0) // PES profile window is not displayed
		MXP_CreatePESExtractorPlot(dfr)
	else
		DoWindow/F $plotNameStr // if it is bring it to the FG
	endif
	return 0
End

Function MXP_CreatePESExtractorPlot(DFREF dfr)
	string rootFolderStr = GetDataFolder(1, dfr)
	DFREF dfr = MXP_CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/SDFR=dfr gMXP_WindowNameStr
	NVAR profileWidth = dfr:gMXP_profileWidth
	NVAR hv = dfr:gMXP_hv
	NVAR Wf = dfr:gMXP_Wf
	NVAR epp = dfr:gMXP_epp
	NVAR stv = dfr:gMXP_STV
	string profilePlotStr = "MXP_PESProfPlot_" + gMXP_WindowNameStr
	Make/O/N=0  dfr:W_ImageLineProfile // Make a dummy wave to display 
	variable pix = 72/ScreenResolution
	Display/W=(0*pix,0*pix,520*pix,300*pix)/K=1/N=$profilePlotStr dfr:W_ImageLineProfile as "PES spectrum " + gMXP_WindowNameStr
	AutoPositionWindow/E/M=0/R=$gMXP_WindowNameStr
	ModifyGraph rgb=(1,12815,52428), tick(left)=2, tick(bottom)=2, fSize=12, lsize=1.5
	Label left "Intensity (arb. u.)"
	Label bottom "\\u#2Kinetic Energy (eV)"
	
	SetWindow $profilePlotStr userdata(MXP_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePlotStr userdata(MXP_targetGraphWin) = "MXP_PESProf_" + gMXP_WindowNameStr 
	SetWindow $profilePlotStr userdata(MXP_parentGraphWin) = gMXP_WindowNameStr 
	SetWindow $profilePlotStr, hook(MyPESExtractorGraphHook) = MXP_PESExtractorGraphHookFunction // Set the hook
	
	ControlBar 100	
	Button SaveProfileButton,pos={18.00,8.00},size={90.00,20.00},title="Save Profile",valueColor=(1,12815,52428),help={"Save current profile"},proc=MXP_PESExtractorPlotSaveProfile
	Button SaveCursorPositions,pos={118.00,8.00},size={95.00,20.00},title="Save settings",valueColor=(1,12815,52428),help={"Save cursor positions and profile width as defaults"},proc=MXP_PESExtractorPlotSaveDefaultSettings
	Button RestoreCursorPositions,pos={224.00,8.00},size={111.00,20.00},valueColor=(1,12815,52428),title="Restore settings",help={"Restore default cursor positions and line width"},proc=MXP_PESExtractorPlotRestoreDefaultSettings
	Button ShowProfileWidth,valueColor=(1,12815,52428), pos={344.00,8.00},size={111.00,20.00},title="Show width",help={"Shows width of integrated area while button is pressed"},proc=MXP_PESExtractorPlotShowProfileWidth
	CheckBox PlotProfiles,pos={19.00,40.00},size={98.00,17.00},title="Plot profiles ",fSize=14,value=1,side=1,proc=MXP_PESExtractorPlotCheckboxPlotProfile
	CheckBox MarkPESs,pos={127.00,40.00},size={86.00,17.00},title="Mark Lines ",fSize=14,value=0,side=1,proc=MXP_PESExtractorPlotCheckboxMarkPES
	CheckBox ProfileLayer3D,pos={227.00,40.00},size={86.00,17.00},title="Stack layer ",fSize=14,side=1,proc=MXP_PESExtractorPlotProfileLayer3D
	SetVariable setWidth,pos={331.00,40.00},size={123.00,20.00},title="Width", fSize=14,fColor=(1,39321,19939),value=profileWidth,limits={0,inf,1},proc=MXP_PESExtractorPlotSetVariableWidth
	Button SetCursorsAB,valueColor=(1,12815,52428), pos={462,17},size={50,70.00},title="Set\nCsr\nA & B",fcolor=(65535,0,0),help={"Set cursors A (top right), B (lower left) and press button to calibrate the energy scale"},proc=MXP_PESExtractorPlotSSetCursorsAB // Change here	
	SetVariable setSTV,pos={20,72.00},size={100,20.00},title="STV", fSize=14,fColor=(0,0,65535),value=stv,limits={0,inf,1},proc=MXP_PESExtractorPlotSetSTV // Energy per pixel
	SetVariable sethv,pos={135,72.00},size={90,20.00},title="hv", fSize=14,fColor=(65535,0,0),value=hv,limits={0,inf,1},proc=MXP_PESExtractorPlotSethv
	SetVariable setWf,pos={235,72.00},size={90,20.00},title="Wf", fSize=14,fColor=(1,39321,19939),value=Wf,limits={0,inf,0.1},proc=MXP_PESExtractorPlotSetWf
	SetVariable setEPP,pos={335,72.00},size={118,20.00},title="EPP", fSize=14,fColor=(0,0,65535),value=epp,limits={0,10,0.01},proc=MXP_PESExtractorPlotSetEPP // Energy per pixel
	return 0
End

Function MXP_ClearPESMarkings()
	SetDrawLayer UserFront
	DrawAction delete
	SetDrawLayer ProgFront
	return 0
End

Function MXP_DrawPESUserFront(variable x0, variable y0, variable x1, variable y1, variable red, variable green, variable blue)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 1, dash= 2, xcoord= top, ycoord= left
	DrawLine x0, y0, x1, y1
	return 0
End

Function MXP_CursorHookFunctionPESExtractor(STRUCT WMWinHookStruct &s)
	/// Window hook function
	/// The PES profile is plotted from E to F
    variable hookResult = 0
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESExtractor:" + imgNameTopGraphStr) // imgNameTopGraphStr will have '' if needed.
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESExtractor:DefaultSettings") // Settings here
	SetdataFolder dfr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	SVAR/Z ImagePath = dfr:gMXP_ImagePath
	SVAR/Z ImageNameStr = dfr:gMXP_ImageNameStr
	NVAR/Z dx = dfr:gMXP_dx
	NVAR/Z dy = dfr:gMXP_dy
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	
	NVAR/Z Ax = dfr:gMXP_Ax	
	NVAR/Z Ay = dfr:gMXP_Ay	
	NVAR/Z Bx = dfr:gMXP_Bx	
	NVAR/Z By = dfr:gMXP_By	
	NVAR/Z linepx = dfr:gMXP_linepx
	NVAR/Z epp = dfr:gMXP_epp
	NVAR/Z stv = dfr:gMXP_stv
	NVAR/Z Wf = dfr:gMXP_Wf
	NVAR/Z hv = dfr:gMXP_hv
	NVAR/Z Eoffset = dfr:gMXP_Eoffset	
	NVAR/Z lowBE = dfr:gMXP_lowBE
	
	NVAR/Z mouseTrackV = dfr:gMXP_mouseTrackV
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	NVAR/Z selectedLayer = dfr:gMXP_selectedLayer
	NVAR/Z updateSelectedLayer = dfr:gMXP_updateSelectedLayer
	NVAR/Z updateCursorsPositions = dfr:gMXP_updateCursorsPositions
	NVAR/Z C1x0 = dfr0:gMXP_C1x0
	NVAR/Z C1y0 = dfr0:gMXP_C1y0
	NVAR/Z C2x0 = dfr0:gMXP_C2x0
	NVAR/Z C2y0 = dfr0:gMXP_C2y0
	NVAR/Z profileWidth0 = dfr0:gMXP_profileWidth0
	WAVE/Z imgWaveRef = $ImagePathname
	WAVE/Z/SDFR=dfr W_ImageLineProfile 
	variable xc, yc, dAE, dEF
	
	linepx = sqrt((Ax-Bx)^2+(Ay-By)^2)

	switch(s.eventCode)
		case 0: // Use activation to update the cursors if you request defaults
			if(updateCursorsPositions)
				SetDrawLayer ProgFront
			    DrawAction delete
	   			SetDrawEnv Linefgc = (65535,0,0,65535), fillpat = 0, Linethick = 1, xcoord = top, ycoord = left
				Cursor/I/C=(65535,0,0,30000)/S=1/N=1 E $imgNameTopGraphStr C1x0, C1y0
				Cursor/I/C=(65535,0,0,30000)/S=1/N=1 F $imgNameTopGraphStr C2x0, C2y0
				DrawLine C1x0, C1y0, C2x0, C2y0
				Make/O/FREE/N=2 xTrace={C1x0, C2x0}, yTrace = {C1y0, C2y0}
				ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = profileWidth
				updateCursorsPositions = 0
			endif
			break
		case 2: // Kill the window
			KillWindow/Z $(GetUserData(s.winName, "", "MXP_LinkedPESExtractorPlotStr"))
			if(WinType(GetUserData(s.winName, "", "MXP_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "MXP_targetGraphWin")) $UniqueName("PESProf_unlnk_", 6, 0) // Change name of profile graph
			endif
			KillDataFolder/Z dfr
			hookresult = 1
			break
		case 4:
			mouseTrackV = s.mouseLoc.v
			break
       	case 5: // mouse up
       		C1x = hcsr(E) 
       		C1y = vcsr(E)
       		C2x = hcsr(F)
       		C2y = vcsr(F)
       		// E is the low KE part (higher BE)
       		// N.B Line profile is taken from E to F
       		dAE = sqrt((C1x - Ax)^2 + (C1y - Ay)^2)
       		dEF = sqrt((C2x - C1x)^2 + (C2y - C1y)^2)
       		Eoffset = stv - (linepx/2 - dAE) * epp // offset in eV from the top right energy (lowest KE)
       		//SetScale/I x, Eoffset, (Eoffset + dEF*epp), W_ImageLineProfile
       		SetScale/P x, Eoffset, epp, W_ImageLineProfile
       		//WaveFromKE2BE(W_ImageLineProfile, hv, Wf)
       		hookResult = 1
			break
		case 8: // modifications, either move the slides or the cursors
			// NB: s.cursorName gives "" in the switch but "-" outside for no cursor under cursor or CursorName (A,B,...J)
			if(WaveDims(imgWaveRef) == 3 && DataFolderExists("root:Packages:WM3DImageSlider:" + WindowNameStr) && updateSelectedLayer && mouseTrackV < 0)
				NVAR/Z glayer = root:Packages:WM3DImageSlider:$(WindowNameStr):gLayer
				selectedLayer = glayer
				Make/O/FREE/N=2 xTrace={C1x, C2x}, yTrace = {C1y, C2y}
				ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = profileWidth
			endif
			break
	    case 7: // cursor moved
			if(!cmpstr(s.cursorName, "E") || !cmpstr(s.cursorName, "F")) // It should work only with E, F you might have other cursors on the image
				SetDrawLayer ProgFront
			    DrawAction delete
	   			SetDrawEnv linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	   			if(!cmpstr(s.cursorName, "E")) // if you move E
	   				xc = hcsr(F)
					yc = vcsr(F)
					DrawLine s.pointNumber * dx, s.ypointNumber * dy, xc, yc
	   				Make/O/FREE/N=2 xTrace={s.pointNumber * dx, xc}, yTrace = {s.ypointNumber * dy, yc}
	   			elseif(!cmpstr(s.cursorName, "F")) // if you move F
	   				xc = hcsr(E)
					yc = vcsr(E)
					DrawLine  xc, yc, s.pointNumber * dx, s.ypointNumber * dy
	   				Make/O/FREE/N=2 xTrace={xc, s.pointNumber * dx}, yTrace = {yc, s.ypointNumber * dy}
	   			endif
	   			ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = profileWidth
	   			C1x = hcsr(E) 
       			C1y = vcsr(E)
    	   		C2x = hcsr(F)
	       		C2y = vcsr(F)
    	   		dAE = sqrt((C1x - Ax)^2 + (C1y - Ay)^2)
   	    		//dEF = sqrt((C2x - C1x)^2 + (C2y - C1y)^2)
  	     		Eoffset = stv - (linepx/2 - dAE) * epp // offset in eV from the top right energy (lowest KE)
  	     		SetScale/P x, Eoffset, epp, W_ImageLineProfile
  	     		//WaveFromKE2BE(W_ImageLineProfile, hv, Wf)
	   			hookResult = 1
	   			break
			endif
			hookresult = 0
			break
    endswitch
    SetdataFolder currdfr
    return hookResult       // 0 if nothing done, else 1
End

Function MXP_PESExtractorGraphHookFunction(STRUCT WMWinHookStruct &s)
	string parentGraphWin = GetUserData(s.winName, "", "MXP_parentGraphWin")
	switch(s.eventCode)
		case 2: // Kill the window
			// parentGraphWin -- winNameStr
			// Kill the MyPESExtractorHook
			SetWindow $parentGraphWin, hook(MyPESExtractorHook) = $""
			// We need to reset the link between parentGraphwin (winNameStr) and MXP_LinkedPESExtractorPlotStr
			// see MXP_MainMenuLaunchPESExtractor() when we test if with strlen(LinkedPlotStr)
			SetWindow $parentGraphWin userdata(MXP_LinkedPESExtractorPlotStr) = ""
			if(WinType(GetUserData(parentGraphWin, "", "MXP_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "MXP_targetGraphWin")) $UniqueName("PESProf_unlnk_",6,0) // Change name of profile graph
			endif
			Cursor/W=$parentGraphWin/K A
			Cursor/W=$parentGraphWin/K B
			Cursor/W=$parentGraphWin/K E
			Cursor/W=$parentGraphWin/K F
			SetDrawLayer/W=$parentGraphWin ProgFront
			DrawAction/W=$parentGraphWin delete
			SetDrawLayer/W=$parentGraphWin Overlay
			DrawAction/W=$parentGraphWin delete			
			break
	endswitch
End


Function MXP_PESExtractorPlotSaveProfile(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "MXP_targetGraphWin")
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_ImageNameStr
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	Wave/SDFR=dfr W_ImageLineProfile
	NVAR/Z PlotSwitch = dfr:gMXP_PlotSwitch
	NVAR/Z MarkPESsSwitch = dfr:gMXP_MarkPESLineSwitch
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	NVAR/Z selectedLayer = dfr:gMXP_selectedLayer
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z colorcnt = dfr:gMXP_colorcnt
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	NVAR/Z Ax = dfr:gMXP_Ax	
	NVAR/Z Ay = dfr:gMXP_Ay
	NVAR/Z Bx = dfr:gMXP_Bx	
	NVAR/Z By = dfr:gMXP_By	
	NVAR/Z dx = dfr:gMXP_dx	
	NVAR/Z dy = dfr:gMXP_dy	
	NVAR/Z Eoffset = dfr:gMXP_Eoffset
	NVAR/Z epp = dfr:gMXP_epp
	NVAR/Z stv = dfr:gMXP_stv
	NVAR/Z linepx = dfr:gMXP_linepx		
	NVAR/Z hv = dfr:gMXP_hv
	NVAR/Z Wf = dfr:gMXP_Wf
		
	string recreateDrawStr
	DFREF savedfr = GetDataFolderDFR() //MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESExtractor:SavedPESExtractor")
	
	variable postfix = 0, dAE
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			do
				string saveWaveNameStr = w3dNameStr + "_prof" + num2str(postfix)
				if(WaveExists(savedfr:$saveWaveNameStr) == 1)
					postfix++
				else
					Duplicate dfr:W_ImageLineProfile, savedfr:$saveWaveNameStr
					dAE = sqrt((C1x - Ax)^2/dx^2 + (C1y - Ay)^2/dy^2)
					Eoffset = stv - (linepx/2 - dAE) * epp
					SetScale/P x, Eoffset, epp, savedfr:$saveWaveNameStr
					if(hv > Wf)
						WaveFromKE2BE(savedfr:$saveWaveNameStr, hv, Wf)
					endif
					if(PlotSwitch)
						if(WinType(targetGraphWin) == 1)
							AppendToGraph/W=$targetGraphWin savedfr:$saveWaveNameStr
							[red, green, blue] = MXP_GetColor(colorcnt)
							Modifygraph/W=$targetGraphWin rgb($saveWaveNameStr) = (red, green, blue)
							colorcnt += 1 // i++ does not work with globals?
						else
							Display/N=$targetGraphWin savedfr:$saveWaveNameStr // Do not kill the graph windows, user might want to save the profiles
							[red, green, blue] = MXP_GetColor(colorcnt)
							Modifygraph/W=$targetGraphWin rgb($saveWaveNameStr) = (red, green, blue)
							AutopositionWindow/R=$B_Struct.win $targetGraphWin
							DoWindow/F $targetGraphWin
							colorcnt += 1
						endif
						if(PlotSwitch && hv > Wf) // Reverse x-axis and add label
							SetAxis/W=$targetGraphWin/A/R bottom
							Label/W=$targetGraphWin bottom "\\u#2Binding Energy (eV)"
						endif
					endif
					
					if(MarkPESsSwitch)
						if(!PlotSwitch)
							[red, green, blue] = MXP_GetColor(colorcnt)
							colorcnt += 1
						endif
						DoWindow/F $WindowNameStr
						MXP_DrawPESUserFront(C1x, C1y, C2x, C2y, red, green, blue) // Draw on UserFront and return to ProgFront
					endif
				break // Stop if you go through the else branch
				endif	
			while(1)
		sprintf recreateDrawStr, "pathName:%s\nCursor A:%d,%d\nCursor B:%d,%d\nCursor E:%d,%d\nCursor F:%d,%d\nWidth(px):%d\nSTV(V):%d\n" + \
								 "hv(eV):%d\nWf(eV):%d\nEPP(eV/px):%f", ImagePathname,  C1x, C1y, C2x, C2y, Ax, Ay, Bx, By, profileWidth, stv, hv, Wf, epp
		Note savedfr:$saveWaveNameStr, recreateDrawStr
		// Add metadata
		break
	endswitch
	return 0
End

Function MXP_PESExtractorPlotSaveDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESExtractor:DefaultSettings") // Settings here
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	NVAR/Z Ax = dfr:gMXP_Ax
	NVAR/Z Ay = dfr:gMXP_Ay	
	NVAR/Z Bx = dfr:gMXP_Bx
	NVAR/Z By = dfr:gMXP_By
	NVAR/Z dx = dfr:gMXP_dx
	NVAR/Z dy = dfr:gMXP_dy
	NVAR/Z linepx = dfr:gMXP_linepx
	NVAR/Z epp = dfr:gMXP_epp
	// --------------------------//
	NVAR/Z C1x0 = dfr0:gMXP_C1x0
	NVAR/Z C1y0 = dfr0:gMXP_C1y0
	NVAR/Z C2x0 = dfr0:gMXP_C2x0
	NVAR/Z C2y0 = dfr0:gMXP_C2y0
	NVAR/Z profileWidth0 = dfr0:gMXP_profileWidth0	
	NVAR/Z Ax0 = dfr0:gMXP_Ax0
	NVAR/Z Ay0 = dfr0:gMXP_Ay0	
	NVAR/Z Bx0 = dfr0:gMXP_Bx0
	NVAR/Z By0 = dfr0:gMXP_By0
	NVAR/Z Wf0 = dfr0:gMXP_Wf0
	NVAR/Z epp0 = dfr0:gMXP_epp0
	NVAR/Z linepx0 = dfr0:gMXP_linepx0

	switch(B_Struct.eventCode)	// numeric switch
			case 2:	// "mouse up after mouse down"
			string msg = "Overwite the default cursor positions and profile PESwidth?"
			DoAlert/T="MAXPEEM would like to ask you" 1, msg
			if(V_flag == 1)
				C1x0 = C1x
				C1y0 = C1y
				C2x0 = C2x
				C2y0 = C2y
				profileWidth0 = profileWidth
				Ax0 = Ax
				Ay0 = Ay
				Bx0 = Bx
				By0 = By
				linepx0 = linepx
				epp0 = epp
			endif
			break
	endswitch
End

Function MXP_PESExtractorPlotRestoreDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESExtractor:DefaultSettings") // Settings here
	string parentWindow = GetUserData(B_Struct.win, "", "MXP_parentGraphWin")
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	NVAR/Z C1x0 = dfr0:gMXP_C1x0
	NVAR/Z C1y0 = dfr0:gMXP_C1y0
	NVAR/Z C2x0 = dfr0:gMXP_C2x0
	NVAR/Z C2y0 = dfr0:gMXP_C2y0
	NVAR/Z profileWidth0 = dfr0:gMXP_profileWidth0
	NVAR/Z updateCursorsPositions = dfr:gMXP_updateCursorsPositions

	NVAR/Z Ax0 = dfr0:gMXP_Ax0
	NVAR/Z Ay0 = dfr0:gMXP_Ay0	
	NVAR/Z Bx0 = dfr0:gMXP_Bx0
	NVAR/Z By0 = dfr0:gMXP_By0
	NVAR/Z Wf0 = dfr0:gMXP_Wf0
	NVAR/Z epp0 = dfr0:gMXP_epp0
	NVAR/Z linepx0 = dfr0:gMXP_linepx0
	
	NVAR/Z Ax = dfr:gMXP_Ax
	NVAR/Z Ay = dfr:gMXP_Ay	
	NVAR/Z Bx = dfr:gMXP_Bx
	NVAR/Z By = dfr:gMXP_By
	NVAR/Z dx = dfr:gMXP_dx
	NVAR/Z dy = dfr:gMXP_dy
	NVAR/Z linepx = dfr:gMXP_linepx
	NVAR/Z epp = dfr:gMXP_epp

	NVAR/Z CursorABSwitch = dfr:gMXP_CursorABSwitch
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			C1x = C1x0
			C1y = C1y0
			C2x = C2x0
			C2y = C2y0
			profileWidth = profileWidth0
			Ax = Ax0
			Ay = Ay0
			Bx = Bx0
			By = By0
			linepx = linepx0
			epp = epp0
			Cursor/K/W=$parentWindow A
			Cursor/K/W=$parentWindow B
			Button SetCursorsAB fcolor=(0,65535,0)
			ControlUpdate/W=$B_Struct.win SetCursorsAB
			SetDrawLayer/W=$parentWindow Overlay
			DrawAction/W=$parentWindow delete
			SetDrawEnv/W=$parentWindow linefgc = (0, 65535, 0, 32767), fillpat = 0, linethick = 0.5, dash= 3, xcoord= top, ycoord= left
			DrawLine/W=$parentWindow Ax, Ay, Bx, By
			SetDrawEnv/W=$parentWindow linefgc = (0, 65535, 0, 32767), fillfgc= (0,65535,0, 32767), fillpat = 1, linethick = 1, dash= 1, xcoord= top, ycoord= left
			DrawOval/W=$parentWindow (Ax + Bx)/2 + 3 * dx, (Ay + By)/2 + 3 * dy, (Ax + Bx)/2 - 3 * dx, (Ay + By)/2 - 3 * dy
			SetDrawLayer/W=$parentWindow ProgFront
			CursorABSwitch = 1
			updateCursorsPositions = 1
			DoWindow/F $parentWindow
			break
	endswitch
End

Function MXP_PESExtractorPlotShowProfileWidth(STRUCT WMButtonAction &B_Struct): ButtonControl
	/// We have to find the vertices of the polygon representing
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	SVAR/Z WindowNameStr= dfr:gMXP_WindowNameStr
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z width = dfr:gMXP_profileWidth
	NVAR/Z dx = dfr:gMXP_dx
	NVAR/Z dy = dfr:gMXP_dy // assume here that dx = dy
	variable x1, x2, x3, x4, y1, y2, y3, y4, xs, ys
	variable slope = MXP_SlopePerpendicularToLineSegment(C1x, C1y,C2x, C2y)
	if(slope == 0)
		x1 = C1x
		x2 = C1x
		x3 = C2x
		x4 = C2x
		y1 = C1y + 0.5 * width * dy
		y2 = C1y - 0.5 * width * dy
		y3 = C2y - 0.5 * width * dy
		y4 = C2y + 0.5 * width * dy
	elseif(slope == inf)
		y1 = C1y
		y2 = C1y
		y3 = C2y
		y4 = C2y
		x1 = C1x + 0.5 * width * dx
		x2 = C1x - 0.5 * width * dx
		x3 = C2x - 0.5 * width * dx
		x4 = C2x + 0.5 * width * dx
	else
		[xs, ys] = MXP_GetVerticesPerpendicularToLine(width * dx/2, slope)
		x1 = C1x + xs
		x2 = C1x - xs
		x3 = C2x - xs
		x4 = C2x + xs
		y1 = C1y + ys
		y2 = C1y - ys
		y3 = C2y - ys
		y4 = C2y + ys
	endif
	switch(B_Struct.eventCode)	// numeric switch
		case 1:	// "mouse down"
			SetDrawLayer/W=$WindowNameStr ProgFront
			SetDrawEnv/W=$WindowNameStr gstart,gname= PESExtractorWidth
			SetDrawEnv/W=$WindowNameStr linefgc = (65535,16385,16385,32767), fillbgc= (65535,16385,16385,32767), fillpat = -1, linethick = 0, xcoord = top, ycoord = left
			DrawPoly/W=$WindowNameStr x1, y1, 1, 1, {x1, y1, x2, y2, x3, y3, x4, y4}
			SetDrawEnv/W=$WindowNameStr gstop
			break
		case 2: // "mouse up"
		case 3: // "mouse up outside button"
			SetDrawLayer/W=$WindowNameStr ProgFront
			DrawAction/W=$WindowNameStr getgroup = PESExtractorWidth
			DrawAction/W=$WindowNameStr delete = V_startPos, V_endPos
			break
	endswitch
End

Function MXP_PESExtractorPlotCheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrStr"))
	NVAR/Z PlotSwitch = dfr:gMXP_PlotSwitch
	switch(cb.checked)
		case 1:		// Mouse up
			PlotSwitch = 1
			break
		case 0:
			PlotSwitch = 0
			break
	endswitch
	return 0
End

Function MXP_PESExtractorPlotProfileLayer3D(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrStr"))
	NVAR/Z selectedLayer = dfr:gMXP_selectedLayer
	NVAR/Z updateSelectedLayer = dfr:gMXP_updateSelectedLayer
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	if(DataFolderExists("root:Packages:WM3DImageSlider:" + WindowNameStr))
		NVAR/Z glayer = root:Packages:WM3DImageSlider:$(WindowNameStr):gLayer
		if(NVAR_Exists(glayer))
			selectedLayer = glayer
		endif
	else
		return 1
	endif
	switch(cb.checked)
		case 1:
			updateSelectedLayer = 1
			break
		case 0:
			updateSelectedLayer = 0
			break
	endswitch
	return 0
End

Function MXP_PESExtractorPlotCheckboxMarkPES(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrStr"))
	NVAR/Z MarkPESsSwitch = dfr:gMXP_MarkPESLineSwitch
	switch(cb.checked)
		case 1:
			MarkPESsSwitch = 1
			break
		case 0:
			MarkPESsSwitch = 0
			break
	endswitch
	return 0
End

Function MXP_PESExtractorPlotSetVariableWidth(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sv.win, "", "MXP_rootdfrStr"))
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	NVAR/Z selectedLayer = dfr:gMXP_selectedLayer
	NVAR/Z Ax = dfr:gMXP_Ax	
	NVAR/Z Ay = dfr:gMXP_Ay
	NVAR/Z stv = dfr:gMXP_stv	
	NVAR/Z epp = dfr:gMXP_epp	
	NVAR/Z linepx = dfr:gMXP_linepx
	SetDataFolder dfr
	Make/O/FREE/N=2 xTrace={C1x, C2x}, yTrace = {C1y, C2y}
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	WAVE/Z imgWaveRef = $ImagePathname
	WAVE/Z/SDFR=dfr W_ImageLineProfile
	variable dAE, Eoffset
	switch(sv.eventCode)
		case 6:		
			ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = profileWidth
    	   	dAE = sqrt((C1x - Ax)^2 + (C1y - Ay)^2)
  	     	Eoffset = stv - (linepx/2 - dAE) * epp // offset in eV from the top right energy (lowest KE)
  	     	SetScale/P x, Eoffset, epp, W_ImageLineProfile	
			break
	endswitch
	SetDataFolder currdfr
	return 0
End


Function MXP_PESExtractorPlotSSetCursorsAB(STRUCT WMButtonAction &B_Struct): ButtonControl)

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	string parentWindow = GetUserData(B_Struct.win, "", "MXP_parentGraphWin")
	NVAR/Z Ax = dfr:gMXP_Ax
	NVAR/Z Ay = dfr:gMXP_Ay	
	NVAR/Z Bx = dfr:gMXP_Bx
	NVAR/Z By = dfr:gMXP_By
	NVAR/Z stv = dfr:gMXP_STV
	NVAR/Z dx = dfr:gMXP_dx
	NVAR/Z dy = dfr:gMXP_dy
	NVAR/Z linepx = dfr:gMXP_linepx
	NVAR/Z CursorABSwitch = dfr:gMXP_CursorABSwitch
	
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(parentWindow, ";"),";")

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			if(!CursorABSwitch) // if not yet set
				Ax = hcsr(A, parentWindow)
				Ay = vcsr(A, parentWindow)
				Bx = hcsr(B, parentWindow)
				By = vcsr(B, parentWindow)
				linepx = sqrt(((Ax-Bx)/dx)^2 + ((Ay-By)/dy)^2)
				// 
				Cursor/K/W=$parentWindow A
				Cursor/K/W=$parentWindow B
				Button SetCursorsAB fcolor=(0,65535,0)
				ControlUpdate/W=$B_Struct.win SetCursorsAB
				SetDrawLayer/W=$parentWindow Overlay 
				SetDrawEnv/W=$parentWindow linefgc = (1,39321,19939, 32767), fillpat = 0, linethick = 0.5, dash= 3, xcoord= top, ycoord= left
				DrawLine/W=$parentWindow Ax, Ay, Bx, By
				SetDrawEnv/W=$parentWindow linefgc = (1,39321,19939, 32767), fillfgc= (0,65535,0, 32767), fillpat = 1, linethick = 1, dash= 1, xcoord= top, ycoord= left	
				DrawOval/W=$parentWindow (Ax + Bx)/2 + 3 * dx, (Ay + By)/2 + 3 * dy, (Ax + Bx)/2 - 3 * dx, (Ay + By)/2 - 3 * dy
				SetDrawLayer/W=$parentWindow ProgFront 
				CursorABSwitch = 1
			else
				Cursor/W=$parentWindow/I/C=(0,65535,0)/H=1/P/N=1 A $imgNameTopGraphStr Ax, Ay
				Cursor/W=$parentWindow/I/C=(0,65535,0)/H=1/P/N=1 B $imgNameTopGraphStr Bx, By
				SetDrawLayer/W=$parentWindow Overlay
				DrawAction/W=$parentWindow delete
				Button SetCursorsAB fcolor=(65535,0,0)
				ControlUpdate/W=$B_Struct.win SetCursorsAB
				SetDrawLayer/W=$parentWindow ProgFront 
				CursorABSwitch = 0
			endif
			break
	endswitch
	
End

Function MXP_PESExtractorPlotSethv(STRUCT WMSetVariableAction& sv) : SetVariableControl	

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sv.win, "", "MXP_rootdfrStr"))
	NVAR/Z hv = dfr:gMXP_hv
	switch(sv.eventCode)
		case 6:
			hv = sv.dval
			break
	endswitch
	return 0
End

Function MXP_PESExtractorPlotSetWf(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sv.win, "", "MXP_rootdfrStr"))
	NVAR/Z wf = dfr:gMXP_Wf
	switch(sv.eventCode)
		case 6:
			wf = sv.dval
			break
	endswitch
	return 0
End

Function MXP_PESExtractorPlotSetEPP(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sv.win, "", "MXP_rootdfrStr"))
	NVAR/Z epp = dfr:gMXP_epp
	switch(sv.eventCode)
		case 6:
			epp = sv.dval
			break
	endswitch
	return 0
End

Function MXP_PESExtractorPlotSetSTV(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sv.win, "", "MXP_rootdfrStr"))
	NVAR/Z stv = dfr:gMXP_STV
	switch(sv.eventCode)
		case 6:
			stv = sv.dval
			break
	endswitch
	return 0
End

static Function WaveFromKE2BE(WAVE wRef, variable hv, variable Wf)
	variable dx = DimDelta(wRef, 0)
	variable offset = DimOffset(wRef, 0)
	variable nsteps = DimSize(wRef, 0) - 1
	variable newoffset = hv - (offset + nsteps * dx) - Wf
	SetScale/P x, newoffset, dx, wRef
End
