#pragma TextEncoding = "UTF-8"
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

/// Line profile is plotted from cursor E to F.
/// 25032023
/// Added to all Launchers: SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_LineProf_" + gMXP_WindowNameStr 
/// We have to unlink the profile plot window in case the profiler and source wave are killed. That 
/// way another launch that could associate the same Window names is not anymore possible.
/// We will use the metadata to change Window's name after the soruce/profiler are killed
/// 
/// 29032023
/// We changed the save directory to the current working directory
/// DFREF savedfr = GetDataFolderDFR() //MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:SavedLineProfiles")


Function MXP_MainMenuLaunchLineProfile()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph."
		return -1
	endif
	WAVE imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string LinkedPlotStr = GetUserData(winNameStr, "", "MXP_LinkedLineProfilePlotStr")
	if(strlen(LinkedPlotStr))
		DoWindow/F LinkedPlotStr
		return 0
	endif
	MXP_InitialiseLineProfileFolder(winNameStr)
	variable nrows = DimSize(imgWaveRef,0)
	variable ncols = DimSize(imgWaveRef,1)
	Cursor/I/C=(65535,0,0)/S=1/P/N=1 E $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
	Cursor/I/C=(65535,0,0)/S=1/P/N=1 F $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:" + NameOfWave(imgWaveRef)) // Change root folder if you want
	MXP_InitialiseLineProfileGraph(dfr)
	SetWindow $winNameStr, hook(MyLineProfileHook) = MXP_CursorHookFunctionLineProfile // Set the hook
	SetWindow $winNameStr userdata(MXP_LinkedLineProfilePlotStr) = "MXP_LineProfPlot_" + winNameStr // Name of the plot we will make, used to communicate the
	SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_LineProf_" + winNameStr //  Same as gMXP_WindowNameStr, see MXP_InitialiseLineProfileFolder
	return 0
End

Function MXP_TraceMenuLaunchLineProfile() // Not in use

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	if(WaveDims(imgWaveRef) == 2 || WaveDims(imgWaveRef) == 3) // if it is not a 1d wave
		KillWindow $winNameStr
		MXP_DisplayImage(imgWaveRef)
		MXP_InitialiseLineProfileFolder(winNameStr)
		DoWindow/F $winNameStr // bring it to FG to set the cursors
		variable nrows = DimSize(imgWaveRef,0)
		variable ncols = DimSize(imgWaveRef,1)
		Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 E $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
		Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 F $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:" + NameOfWave(imgWaveRef)) // Change root folder if you want
		MXP_InitialiseLineProfileGraph(dfr)
		SetWindow $winNameStr, hook(MyLineProfileHook) = MXP_CursorHookFunctionLineProfile // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedLineProfilePlotStr) = "MXP_LineProfPlot_" + winNameStr // Name of the plot we will make, used to communicate the
		SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_LineProf_" + winNameStr //  Same as gMXP_WindowNameStr, see MXP_InitialiseLineProfileFolder	
		// name to the windows hook to kill the plot after completion
	else
		Abort "Line profile needs an image or image stack."
	endif
	return 0
End

Function MXP_BrowserMenuLaunchLineProfile() // Not in use 

	if(MXP_CountSelectedWavesInDataBrowser() == 1) // If we selected a single wave
		string selectedImageStr = GetBrowserSelection(0)
		WAVE imgWaveRef = $selectedImageStr
		if(WaveDims(imgWaveRef) == 2 || WaveDims(imgWaveRef) == 3)
			MXP_DisplayImage(imgWaveRef)
			string winNameStr = WinName(0, 1, 1) // update it just in case
			string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
			MXP_InitialiseLineProfileFolder(winNameStr)
			DoWindow/F $winNameStr // bring it to FG to set the cursors
			variable nrows = DimSize(imgWaveRef,0)
			variable ncols = DimSize(imgWaveRef,1)
			Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 E $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
			Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 F $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
			DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:" + NameOfWave(imgWaveRef)) // Change root folder if you want
			MXP_InitialiseLineProfileGraph(dfr)
			SetWindow $winNameStr, hook(MyLineProfileHook) = MXP_CursorHookFunctionLineProfile // Set the hook
			SetWindow $winNameStr userdata(MXP_LinkedLineProfilePlotStr) = "MXP_LineProfPlot_" + winNameStr // Name of the plot we will make, used to communicate the
			SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_LineProf_" + winNameStr //  Same as gMXP_WindowNameStr, see MXP_InitialiseLineProfileFolder		
		// name to the windows hook to kill the plot after completion
		else
			Abort "Line profile needs an image or an image stack."
		endif
	else
		Abort "Please select only one wave."
	endif
	return 0
End

Function MXP_InitialiseLineProfileFolder(string winNameStr)
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here. Use the 3D wave in top window.

	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string msg // Error reporting
	if(!strlen(imgNameTopGraphStr)) // we do not have an image in top graph
		Abort "No image in top graph. Start the line profile with an image or image stack in top window."
	endif
	
	if(WaveDims(imgWaveRef) != 2 && WaveDims(imgWaveRef) != 3)
		sprintf msg, "Z-profile works with images or image stacks.  Wave %s is in top window", imgNameTopGraphStr
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
    
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:" + imgNameTopGraphStr) // Root folder here
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:DefaultSettings:") // Settings here

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
	// Switches and indicators
	variable/G dfr:gMXP_PlotSwitch = 1
	variable/G dfr:gMXP_MarkLinesSwitch = 0
	variable/G dfr:gMXP_SelectLayer = 0
	variable/G dfr:gMXP_colorcnt = 0
	variable/G dfr:gMXP_mouseTrackV
	// Default settings
	NVAR/Z/SDFR=dfr0 gMXP_profileWidth0
	if(!NVAR_Exists(gMXP_profileWidth0)) // init only once and do not overwrite
		variable/G dfr0:gMXP_C1x0 = round(1.1 * nrows/2)
		variable/G dfr0:gMXP_C1y0 = round(0.9 * ncols/2)
		variable/G dfr0:gMXP_C2x0 = round(0.9 * nrows/2)
		variable/G dfr0:gMXP_C2y0 = round(1.1 * ncols/2)
		variable/G dfr0:gMXP_profileWidth0 = 0
	endif
	return 0
End

Function MXP_InitialiseLineProfileGraph(DFREF dfr)
	/// Here we will create the profile plot and graph and plot the profile
	string plotNameStr = "MXP_LineProf_" + GetDataFolder(0, dfr)
	if (WinType(plotNameStr) == 0) // line profile window is not displayed
		MXP_CreateLineProfilePlot(dfr)
	else
		DoWindow/F $plotNameStr // if it is bring it to the FG
	endif
	return 0
End

Function MXP_CreateLineProfilePlot(DFREF dfr)
	string rootFolderStr = GetDataFolder(1, dfr)
	DFREF dfr = MXP_CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/SDFR=dfr gMXP_WindowNameStr
	NVAR profileWidth = dfr:gMXP_profileWidth
	string profilePlotStr = "MXP_LineProfPlot_" + gMXP_WindowNameStr
	Make/O/N=0  dfr:W_LineProfileDisplacement, dfr:W_ImageLineProfile // Make a dummy wave to display 
	variable pix = 72/ScreenResolution
	Display/W=(0*pix,0*pix,500*pix,300*pix)/K=1/N=$profilePlotStr dfr:W_ImageLineProfile vs dfr:W_LineProfileDisplacement as "Line profile " + gMXP_WindowNameStr
	AutoPositionWindow/E/M=0/R=$gMXP_WindowNameStr
	ModifyGraph rgb=(1,12815,52428), tick(left)=2, tick(bottom)=2, fSize=12, lsize=1.5
	Label left "Intensity (arb. u.)"
	Label bottom "\\u#2 Distance (µm) / [Kinetic Energy (eV)]"
	
	SetWindow $profilePlotStr userdata(MXP_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePlotStr userdata(MXP_targetGraphWin) = "MXP_LineProf_" + gMXP_WindowNameStr 
	SetWindow $profilePlotStr userdata(MXP_parentGraphWin) = gMXP_WindowNameStr 
	SetWindow $profilePlotStr, hook(MyLineProfileGraphHook) = MXP_LineProfileGraphHookFunction // Set the hook
	
	ControlBar 70	
	Button SaveProfileButton,pos={18.00,8.00},size={90.00,20.00},title="Save Profile",valueColor=(1,12815,52428),help={"Save displayed profile"},proc=MXP_LineProfilePlotSaveProfile
	Button SaveCursorPositions,pos={118.00,8.00},size={95.00,20.00},title="Save settings",valueColor=(1,12815,52428),help={"Save cursor positions and profile wifth as defaults"},proc=MXP_LineProfilePlotSaveDefaultSettings
	Button RestoreCursorPositions,pos={224.00,8.00},size={111.00,20.00},valueColor=(1,12815,52428),title="Restore settings",help={"Restore default cursor positions and line width"},proc=MXP_LineProfilePlotRestoreDefaultSettings
	Button ShowProfileWidth,valueColor=(1,12815,52428), pos={344.00,8.00},size={111.00,20.00},title="Show width",fcolor=(65535,32768,32768),help={"Show width of integrated area while button is pressed"},proc=MXP_LineProfilePlotShowProfileWidth
	CheckBox PlotProfiles,pos={19.00,40.00},size={98.00,17.00},title="Plot profiles ",fSize=14,value=1,side=1,proc=MXP_LineProfilePlotCheckboxPlotProfile
	CheckBox MarkLines,pos={127.00,40.00},size={86.00,17.00},title="Mark lines ",fSize=14,value=0,side=1,proc=MXP_LineProfilePlotCheckboxMarkLines
	CheckBox ProfileLayer3D,pos={227.00,40.00},size={86.00,17.00},title="Stack layer ",fSize=14,side=1,proc=MXP_LineProfilePlotProfileLayer3D
	SetVariable setWidth,pos={331.00,40.00},size={123.00,20.00},title="Width", fSize=14,fColor=(65535,0,0),value=profileWidth,limits={0,inf,1},proc=MXP_LineProfilePlotSetVariableWidth
	return 0
End

Function MXP_ClearLineMarkings()
	SetDrawLayer UserFront
	DrawAction delete
	SetDrawLayer ProgFront
	return 0
End

Function MXP_DrawLineUserFront(variable x0, variable y0, variable x1, variable y1, variable red, variable green, variable blue)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 1, dash= 2, xcoord= top, ycoord= left
	DrawLine x0, y0, x1, y1
	return 0
End

Function MXP_CursorHookFunctionLineProfile(STRUCT WMWinHookStruct &s)
	/// Window hook function
	/// The line profile is drawn from E to F
    variable hookResult = 0
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:" + imgNameTopGraphStr) // imgNameTopGraphStr will have '' if needed.
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:DefaultSettings") // Settings here
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
	variable xc, yc
	switch(s.eventCode)
		case 0: // Use activation to update the cursors if you request defaults
			if(updateCursorsPositions)
				SetDrawLayer ProgFront
			    DrawAction delete
	   			SetDrawEnv linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
				Cursor/I/C=(65535,0,0,30000)/S=1/N=1 E $imgNameTopGraphStr C1x0, C1y0
				Cursor/I/C=(65535,0,0,30000)/S=1/N=1 F $imgNameTopGraphStr C2x0, C2y0
				DrawLine C1x0, C1y0, C2x0, C2y0
				Make/O/FREE/N=2 xTrace={C1x0, C2x0}, yTrace = {C1y0, C2y0}
				ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = profileWidth
				updateCursorsPositions = 0
			endif
			break
		case 2: // Kill the window
			KillWindow/Z $(GetUserData(s.winName, "", "MXP_LinkedLineProfilePlotStr"))
			if(WinType(GetUserData(s.winName, "", "MXP_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "MXP_targetGraphWin")) $UniqueName("LineProf_unlnk_",6,0) // Change name of profile graph
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
					DrawLine xc, yc, s.pointNumber * dx, s.ypointNumber * dy
	   				Make/O/FREE/N=2 xTrace={xc, s.pointNumber * dx}, yTrace = {yc, s.ypointNumber * dy}
	   			endif
	   			ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = profileWidth
	   			hookResult = 1
	   			break
			endif
			hookresult = 0
			break
    endswitch
    SetdataFolder currdfr
    return hookResult       // 0 if nothing done, else 1
End

Function MXP_LineProfileGraphHookFunction(STRUCT WMWinHookStruct &s)
	string parentGraphWin = GetUserData(s.winName, "", "MXP_parentGraphWin")
	switch(s.eventCode)
		case 2: // Kill the window
			// parentGraphWin -- winNameStr
			// Kill the MyLineProfileHook
			SetWindow $parentGraphWin, hook(MyLineProfileHook) = $""
			// We need to reset the link between parentGraphwin (winNameStr) and MXP_LinkedLineProfilePlotStr
			// see MXP_MainMenuLaunchLineProfile() when we test if with strlen(LinkedPlotStr)
			SetWindow $parentGraphWin userdata(MXP_LinkedLineProfilePlotStr) = ""
			Cursor/W=$parentGraphWin/K E
			Cursor/W=$parentGraphWin/K F
			SetDrawLayer/W=$parentGraphWin ProgFront
			DrawAction/W=$parentGraphWin delete
			break
	endswitch
End


Function MXP_LineProfilePlotSaveProfile(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "MXP_targetGraphWin")
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_ImageNameStr
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	Wave/SDFR=dfr W_ImageLineProfile
	Wave/SDFR=dfr W_LineProfileDisplacement
	NVAR/Z PlotSwitch = dfr:gMXP_PlotSwitch
	NVAR/Z MarkLinesSwitch = dfr:gMXP_MarkLinesSwitch
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	NVAR/Z selectedLayer = dfr:gMXP_selectedLayer
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z colorcnt = dfr:gMXP_colorcnt
	string recreateDrawStr
	DFREF savedfr = GetDataFolderDFR() //MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:SavedLineProfiles")
	
	variable postfix = 0
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			do
				string saveWaveNameStr = w3dNameStr + "_prof" + num2str(postfix)
				if(WaveExists(savedfr:$saveWaveNameStr) == 1)
					postfix++
				else
					Duplicate dfr:W_ImageLineProfile, savedfr:$saveWaveNameStr
					variable xRange = W_LineProfileDisplacement[DimSize(W_LineProfileDisplacement,0)-1] - W_LineProfileDisplacement[0]
					SetScale/I x, 0, xRange, savedfr:$saveWaveNameStr
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
					endif
					
					if(MarkLinesSwitch)
						if(!PlotSwitch)
							[red, green, blue] = MXP_GetColor(colorcnt)
							colorcnt += 1
						endif
						DoWindow/F $WindowNameStr
						MXP_DrawLineUserFront(C1x, C1y, C2x, C2y, red, green, blue) // Draw on UserFront and return to ProgFront
					endif
				break // Stop if you go through the else branch
				endif	
			while(1)
		sprintf recreateDrawStr, "pathName:%s;DrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, dash= 2, xcoord= top, ycoord= left;" + \
								 "DrawCmd:DrawLine %f, %f, %f, %f;ProfileCmd:Make/O/N=2 xTrace={%f, %f}, yTrace = {%f, %f}\nImageLineProfile/P=(%d) srcWave=%s," +\
								 "xWave=xTrace, yWave=yTrace, width = %f\nDisplay/K=1 W_ImageLineProfile vs W_LineProfileDisplacement" + \
								 "", ImagePathname, red, green, blue, C1x, C1y, C2x, C2y, C1x, C2x, C1y, C2y, selectedLayer, ImagePathname, profileWidth
		Note savedfr:$saveWaveNameStr, recreateDrawStr
		break
	endswitch
	return 0
End

Function MXP_LineProfilePlotSaveDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:DefaultSettings") // Settings here
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
	switch(B_Struct.eventCode)	// numeric switch
			case 2:	// "mouse up after mouse down"
			string msg = "Overwite the default cursor positions and profile linewidth?"
			DoAlert/T="MAXPEEM would like to ask you" 1, msg
			if(V_flag == 1)
				C1x0 = C1x
				C1y0 = C1y
				C2x0 = C2x
				C2y0 = C2y
				profileWidth0 = profileWidth
			endif
			break
	endswitch
End

Function MXP_LineProfilePlotRestoreDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:DefaultSettings") // Settings here
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
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
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			C1x = C1x0
			C1y = C1y0
			C2x = C2x0
			C2y = C2y0
			profileWidth = profileWidth0
			updateCursorsPositions = 1
			DoWindow/F $WindowNameStr
			break		
	endswitch
End

Function MXP_LineProfilePlotShowProfileWidth(STRUCT WMButtonAction &B_Struct): ButtonControl
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
			SetDrawEnv/W=$WindowNameStr gstart,gname= lineProfileWidth
			SetDrawEnv/W=$WindowNameStr linefgc = (65535,16385,16385,32767), fillbgc= (65535,16385,16385,32767), fillpat = -1, linethick = 0, xcoord = top, ycoord = left
			DrawPoly/W=$WindowNameStr x1, y1, 1, 1, {x1, y1, x2, y2, x3, y3, x4, y4}
			SetDrawEnv/W=$WindowNameStr gstop
			break
		case 2: // "mouse up"
		case 3: // "mouse up outside button"
			SetDrawLayer/W=$WindowNameStr ProgFront
			DrawAction/W=$WindowNameStr getgroup = lineProfileWidth
			DrawAction/W=$WindowNameStr delete = V_startPos, V_endPos
			break
	endswitch
End

Function MXP_LineProfilePlotCheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

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

Function MXP_LineProfilePlotProfileLayer3D(STRUCT WMCheckboxAction& cb) : CheckBoxControl
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

Function MXP_LineProfilePlotCheckboxMarkLines(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrStr"))
	NVAR/Z MarkLinesSwitch = dfr:gMXP_MarkLinesSwitch
	switch(cb.checked)
		case 1:
			MarkLinesSwitch = 1
			break
		case 0:
			MarkLinesSwitch = 0
			break
	endswitch
	return 0
End

Function MXP_LineProfilePlotSetVariableWidth(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sv.win, "", "MXP_rootdfrStr"))
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	NVAR/Z selectedLayer = dfr:gMXP_selectedLayer
	SetDataFolder dfr
	Make/O/FREE/N=2 xTrace={C1x, C2x}, yTrace = {C1y, C2y}
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	WAVE/Z imgWaveRef = $ImagePathname
	switch(sv.eventCode)
		case 6:
			ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = profileWidth
			break
	endswitch
	SetDataFolder currdfr
	return 0
End


