﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma ModuleName = ATH_LineProfile
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late
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
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph."
		return -1
	endif
	WAVE imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string LinkedPlotStr = GetUserData(winNameStr, "", "ATH_LinkedWinImageLPP")
	if(strlen(LinkedPlotStr))
		DoWindow/F $LinkedPlotStr
		return 0
	endif
	DFREF dfr = InitialiseFolder(winNameStr)
	variable nrows = DimSize(imgWaveRef,0)
	variable ncols = DimSize(imgWaveRef,1)
	
	string cmdStr, axisStr, dumpStr, val1Str, val2Str
	string axisTopRangeStr = StringByKey("SETAXISCMD", AxisInfo("", "top"))
	SplitString/E="\s*([A-Z,a-z,^a-zA-Z0-9]*)\s*([A-Z,a-z]*)\s*([-]?[0-9]*[.]?[0-9]+)\s*(,)\s*([-]?[0-9]*[.]?[0-9]+)\s*"\
	axisTopRangeStr, cmdStr, axisStr, val1Str, dumpStr, val2Str
	variable midOfImageX = 0.5 * (str2num(val1Str) + str2num(val2Str))
	string axisLeftRangeStr = StringByKey("SETAXISCMD", AxisInfo("", "left"))
	SplitString/E="\s*([A-Z,a-z,^a-zA-Z0-9]*)\s*([A-Z,a-z]*)\s*([-]?[0-9]*[.]?[0-9]+)\s*(,)\s*([-]?[0-9]*[.]?[0-9]+)\s*"\
	axisLeftRangeStr, cmdStr, axisStr, val1Str, dumpStr, val2Str
	variable midOfImageY = 0.5 * (str2num(val1Str) + str2num(val2Str))
	// When autoscaled then SETAXISCMD is SetAxis/A
	if(numtype(midOfImageX)) // if NaN
		Cursor/W=$winNameStr/I/C=(65535,0,0)/S=1/P/N=1 E $imgNameTopGraphStr nrows*0.6, ncols*0.4
		Cursor/W=$winNameStr/I/C=(65535,0,0)/S=1/P/N=1 F $imgNameTopGraphStr nrows*0.4, ncols*0.6
	else
		Cursor/W=$winNameStr/I/C=(65535,0,0)/S=1/N=1 E $imgNameTopGraphStr midOfImageX*1.1, midOfImageY*0.9
		Cursor/W=$winNameStr/I/C=(65535,0,0)/S=1/N=1 F $imgNameTopGraphStr midOfImageX*0.9, midOfImageY*1.1
	endif
	InitialiseGraph(dfr)
	SetWindow $winNameStr, hook(MyLineProfileHook) = ATH_LineProfile#CursorsHookFunction // Set the hook
	SetWindow $winNameStr userdata(ATH_LinkedWinImageLPP) = "ATH_LineProfilePlot_" + winNameStr // Name of the plot we will make, used to communicate the
	SetWindow $winNameStr userdata(ATH_ShowSavedGraphsWindow) = "ATH_LineProf_" + winNameStr //  Same as gATH_WindowNameStr, see InitialiseFolder
	SetWindow $winNameStr userdata(ATH_LineProfRootDF) = GetDataFolder(1, dfr)
	return 0
End

static Function/DF InitialiseFolder(string winNameStr)
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
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:LineProfiles:" + winNameStr) // Root folder here
	DFREF dfr0 = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:LineProfiles:DefaultSettings:") // Settings here

	variable nrows = DimSize(imgWaveRef,0)
	variable ncols = DimSize(imgWaveRef,1)

	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_ImagePathname = GetWavesDataFolder(imgWaveRef, 2)
	string/G dfr:gATH_ImagePath = GetWavesDataFolder(imgWaveRef, 1)
	string/G dfr:gATH_ImageNameStr = NameOfWave(imgWaveRef)
	variable/G dfr:gATH_dx = DimDelta(imgWaveRef,0)
	variable/G dfr:gATH_dy = DimDelta(imgWaveRef,1)
	variable/G dfr:gATH_xOff = DimOffset(imgWaveRef,0)
	variable/G dfr:gATH_yOff = DimOffset(imgWaveRef,1)	
	variable/G dfr:gATH_C1x = round(1.1 * nrows/2)
	variable/G dfr:gATH_C1y = round(0.9 * ncols/2)
	variable/G dfr:gATH_C2x = round(0.9 * nrows/2)
	variable/G dfr:gATH_C2y = round(1.1 * ncols/2)
	variable/G dfr:gATH_profileWidth = 0
	variable/G dfr:gATH_selectedLayer = 0
	variable/G dfr:gATH_updateCursorsPositions = 0
	// Switches and indicators
	variable/G dfr:gATH_PlotSwitch = 1
	variable/G dfr:gATH_MarkLinesSwitch = 1
	variable/G dfr:gATH_updateSelectedLayer = 1	
	variable/G dfr:gATH_colorcnt = 0
	variable/G dfr:gATH_mouseTrackV
	// Default settings
	NVAR/Z/SDFR=dfr0 gATH_profileWidth0
	if(!NVAR_Exists(gATH_profileWidth0)) // init only once and do not overwrite
		variable/G dfr0:gATH_C1x0 = round(1.1 * nrows/2)
		variable/G dfr0:gATH_C1y0 = round(0.9 * ncols/2)
		variable/G dfr0:gATH_C2x0 = round(0.9 * nrows/2)
		variable/G dfr0:gATH_C2y0 = round(1.1 * ncols/2)
		variable/G dfr0:gATH_profileWidth0 = 0
	endif
	return dfr
End

static Function InitialiseGraph(DFREF dfr)
	/// Here we will create the profile plot and graph and plot the profile
	string plotNameStr = "ATH_LineProf_" + GetDataFolder(0, dfr)
	if (WinType(plotNameStr) == 0) // line profile window is not displayed
		CreatePlot(dfr)
	else
		DoWindow/F $plotNameStr // if it is bring it to the FG
	endif
	return 0
End

static Function CreatePlot(DFREF dfr)
	string rootFolderStr = GetDataFolder(1, dfr)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/SDFR=dfr gATH_WindowNameStr
	NVAR profileWidth = dfr:gATH_profileWidth
	string profilePlotStr = "ATH_LineProfilePlot_" + gATH_WindowNameStr
	Make/O/N=0  dfr:W_LineProfileDisplacement, dfr:W_ImageLineProfile // Make a dummy wave to display 
	variable pix = 72/ScreenResolution
	Display/W=(0*pix,0*pix,500*pix,300*pix)/K=1/N=$profilePlotStr dfr:W_ImageLineProfile vs dfr:W_LineProfileDisplacement as "Line profile " + gATH_WindowNameStr
	AutoPositionWindow/E/M=0/R=$gATH_WindowNameStr
	ModifyGraph rgb=(1,12815,52428), tick(left)=2, tick(bottom)=2, fSize=14, lsize=1.5
	ModifyGraph/Z cbRGB=(49151,65535,49151)
	//ModifyGraph mode=7,useNegRGB=1,usePlusRGB=1,hbFill=5,negRGB=(65535,32768,32768),plusRGB=(32768,40777,65535) // delay at 4K?
	Label left "\\u#2 Intensity (arb. u.)"
	Label bottom "\\u#2 \$WMTEX$ d_{E \\ \to \\ F} \\ (u.)$/WMTEX$"
	
	SetWindow $profilePlotStr userdata(ATH_LineProfRootDF) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePlotStr userdata(ATH_ShowSavedGraphsWindow) = "ATH_LineProf_" + gATH_WindowNameStr 
	SetWindow $profilePlotStr userdata(ATH_LinkedWinImageSource) = gATH_WindowNameStr 
	SetWindow $profilePlotStr, hook(MyLineProfileGraphHook) = ATH_LineProfile#GraphHookFunction // Set the hook
	
	ControlBar 70	
	Button SaveProfileButton,pos={18.00,8.00},size={90.00,20.00},title="Save Profile",valueColor=(1,12815,52428),help={"Save displayed profile"},proc=ATH_LineProfile#SaveProfile
	Button SaveCursorPositions,pos={118.00,8.00},size={95.00,20.00},title="Save settings",valueColor=(1,12815,52428),help={"Save cursor positions and profile wifth as defaults"},proc=ATH_LineProfile#SaveDefaultSettings
	Button RestoreCursorPositions,pos={224.00,8.00},size={111.00,20.00},valueColor=(1,12815,52428),title="Restore settings",help={"Restore default cursor positions and line width"},proc=ATH_LineProfile#RestoreDefaultSettings
	Button ShowProfileWidth,valueColor=(1,12815,52428), pos={344.00,8.00},size={111.00,20.00},title="Show width",fcolor=(65535,32768,32768),help={"Show width of integrated area while button is pressed"},proc=ATH_LineProfile#ShowProfileWidth
	CheckBox PlotProfiles,pos={19.00,40.00},size={98.00,17.00},title="Plot profiles ",fSize=14,value=1,side=1,proc=ATH_LineProfile#CheckboxPlotProfile
	CheckBox MarkLines,pos={127.00,40.00},size={86.00,17.00},title="Mark lines ",fSize=14,value=1,side=1,proc=ATH_LineProfile#CheckboxMarkLines
	CheckBox ProfileLayer3D,pos={227.00,40.00},size={86.00,17.00},title="Stack layer ",fSize=14,side=1,value=1,proc=ATH_LineProfile#ProfileLayer3D
	SetVariable setWidth,pos={331.00,40.00},size={123.00,20.00},title="Width", fSize=14,fColor=(65535,0,0),value=profileWidth,limits={0,inf,1},proc=ATH_LineProfile#SetVariableWidth
	return 0
End

static Function ClearLineMarkings(string winNameStr)
	SetDrawLayer/W=$winNameStr UserFront
	DrawAction/W=$winNameStr delete
	SetDrawLayer/W=$winNameStr ProgFront
	return 0
End

static Function DrawLineUserFront(string winNameStr, variable x0, variable y0, variable x1, variable y1, variable red, variable green, variable blue)
	SetDrawLayer/W=$winNameStr UserFront 
	SetDrawEnv/W=$winNameStr linefgc = (red, green, blue), fillpat = 0, linethick = 2, dash= 2, xcoord= top, ycoord= left
	DrawLine/W=$winNameStr x0, y0, x1, y1
	return 0
End

static Function CursorsHookFunction(STRUCT WMWinHookStruct &s)
	/// Window hook function
	/// The line profile is drawn from E to F
    variable hookResult = 0
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_LineProfRootDF"))
	DFREF dfr0 = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:LineProfiles:DefaultSettings") // Settings here
	SetdataFolder dfr
	SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr
	SVAR/Z ImagePathname = dfr:gATH_ImagePathname
	SVAR/Z ImagePath = dfr:gATH_ImagePath
	SVAR/Z ImageNameStr = dfr:gATH_ImageNameStr
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy
	NVAR/Z xOff = dfr:gATH_xOff
	NVAR/Z yOff = dfr:gATH_yOff	
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z mouseTrackV = dfr:gATH_mouseTrackV
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z selectedLayer = dfr:gATH_selectedLayer
	NVAR/Z updateSelectedLayer = dfr:gATH_updateSelectedLayer
	NVAR/Z updateCursorsPositions = dfr:gATH_updateCursorsPositions
	NVAR/Z C1x0 = dfr0:gATH_C1x0
	NVAR/Z C1y0 = dfr0:gATH_C1y0
	NVAR/Z C2x0 = dfr0:gATH_C2x0
	NVAR/Z C2y0 = dfr0:gATH_C2y0
	NVAR/Z profileWidth0 = dfr0:gATH_profileWidth0
	WAVE/Z imgWaveRef = $ImagePathname
	variable xc, yc
	switch(s.eventCode)
		case 0: // Use activation to update the cursors if you request defaults
			if(updateCursorsPositions)
				SetDrawLayer/W=$s.winName ProgFront
			    DrawAction/W=$s.winName delete
	   			SetDrawEnv/W=$s.winName linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
				Cursor/I/C=(65535,0,0,30000)/S=1/N=1 E $ImageNameStr C1x0, C1y0
				Cursor/I/C=(65535,0,0,30000)/S=1/N=1 F $ImageNameStr C2x0, C2y0
				DrawLine/W=$s.winName C1x0, C1y0, C2x0, C2y0
				Make/O/FREE/N=2 xTrace={C1x0, C2x0}, yTrace = {C1y0, C2y0}
				ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = profileWidth
				updateCursorsPositions = 0
			endif
			break
		// To revise. Case 17 is not recommended to use for killing windows. See JW's email.
		case 17: // case 2: ATH_LinkedWinImageLPP in not killed when another hook kills s.winName
			KillWindow/Z $(GetUserData(s.winName, "", "ATH_LinkedWinImageLPP"))			
			if(WinType(GetUserData(s.winName, "", "ATH_ShowSavedGraphsWindow")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "ATH_ShowSavedGraphsWindow")) $UniqueName("LineProf_unlnk_",6,0) // Change name of profile graph
			endif
			KillDataFolder/Z dfr
			hookresult = 0 // Prevent another case 17 somewhere to stop the window from being killed
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
				SetDrawLayer/W=$s.winName ProgFront
			    DrawAction/W=$s.winName delete
	   			SetDrawEnv/W=$s.winName linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	   			if(!cmpstr(s.cursorName, "E")) // if you move E
	   				xc = hcsr(F)
					yc = vcsr(F)
					C1x = xc
					C1y = yc
					C2x = hcsr(E)
					C2y = vcsr(E)
					DrawLine/W=$s.winName xOff + s.pointNumber * dx, yOff + s.ypointNumber * dy, xc, yc
	   				Make/O/FREE/N=2 xTrace={xOff + s.pointNumber * dx, xc}, yTrace = {yOff + s.ypointNumber * dy, yc}
	   			elseif(!cmpstr(s.cursorName, "F")) // if you move F
	   				xc = hcsr(E)
					yc = vcsr(E)
					C1x = hcsr(F)
					C1y = vcsr(F)					
					C2x = xc
					C2y = yc
					DrawLine/W=$s.winName xc, yc, xoff + s.pointNumber * dx, yOff + s.ypointNumber * dy
	   				Make/O/FREE/N=2 xTrace={xc, xOff + s.pointNumber * dx}, yTrace = {yc, yOff + s.ypointNumber * dy}
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

static Function GraphHookFunction(STRUCT WMWinHookStruct &s)
	string parentImageWinStr = GetUserData(s.winName, "", "ATH_LinkedWinImageSource")
	switch(s.eventCode)
		case 2: // Kill the window
			// parentImageWinStr -- winNameStr
			// Kill the MyLineProfileHook
			DoWindow $parentImageWinStr
			//if(WinType(GetUserData(parentImageWinStr, "", "ATH_ShowSavedGraphsWindow")) == 1)
			if(V_flag)
				SetWindow $parentImageWinStr, hook(MyLineProfileHook) = $""
				// We need to reset the link between parentImageWinStr (winNameStr) and ATH_LinkedWinImageLPP
				// see ATH_MainMenuLaunchLineProfile() when we test if with strlen(LinkedPlotStr)	
				SetWindow $parentImageWinStr userdata(ATH_LinkedWinImageLPP) = ""
				if(WinType(GetUserData(s.winName, "", "ATH_ShowSavedGraphsWindow")) == 1)
					DoWindow/C/W=$(GetUserData(s.winName, "", "ATH_ShowSavedGraphsWindow")) $UniqueName("LineProf_unlnk_",6,0) // Change name of profile graph
				endif
				Cursor/W=$parentImageWinStr/K E
				Cursor/W=$parentImageWinStr/K F
				SetDrawLayer/W=$parentImageWinStr ProgFront
				DrawAction/W=$parentImageWinStr delete	
			endif
			break
	endswitch
End


static Function SaveProfile(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_LineProfRootDF"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "ATH_ShowSavedGraphsWindow")
	SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gATH_ImageNameStr
	SVAR/Z ImagePathname = dfr:gATH_ImagePathname
	Wave/SDFR=dfr W_ImageLineProfile
	Wave/SDFR=dfr W_LineProfileDisplacement
	NVAR/Z PlotSwitch = dfr:gATH_PlotSwitch
	NVAR/Z MarkLinesSwitch = dfr:gATH_MarkLinesSwitch
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z selectedLayer = dfr:gATH_selectedLayer
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z colorcnt = dfr:gATH_colorcnt
	string recreateDrawStr
	DFREF savedfr = GetDataFolderDFR() //ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:LineProfiles:SavedLineProfiles")

	variable postfix = 0
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			string saveWaveBaseNameStr = w3dNameStr + "_Lprof"
			string saveWaveNameStr = CreatedataObjectName(savedfr, saveWaveBaseNameStr, 1, 0, 5)
			Duplicate dfr:W_ImageLineProfile, savedfr:$saveWaveNameStr
			variable xRange = W_LineProfileDisplacement[DimSize(W_LineProfileDisplacement,0)-1] - W_LineProfileDisplacement[0]
			SetScale/I x, 0, xRange, savedfr:$saveWaveNameStr
			if(PlotSwitch)
				if(WinType(targetGraphWin) == 1)
					AppendToGraph/W=$targetGraphWin savedfr:$saveWaveNameStr
					[red, green, blue] = ATH_Graph#GetColor(colorcnt)
					Modifygraph/W=$targetGraphWin rgb($saveWaveNameStr) = (red, green, blue)
					colorcnt += 1 // i++ does not work with globals?
				else
					Display/N=$targetGraphWin savedfr:$saveWaveNameStr // Do not kill the graph windows, user might want to save the profiles
					[red, green, blue] = ATH_Graph#GetColor(colorcnt)
					Modifygraph/W=$targetGraphWin rgb($saveWaveNameStr) = (red, green, blue)
					AutopositionWindow/R=$B_Struct.win $targetGraphWin
					DoWindow/F $targetGraphWin
					colorcnt += 1
				endif
			endif

			if(MarkLinesSwitch)
				if(!PlotSwitch)
					[red, green, blue] = ATH_Graph#GetColor(colorcnt)
					colorcnt += 1
				endif
				DrawLineUserFront(WindowNameStr,C1x, C1y, C2x, C2y, red, green, blue) // Draw on UserFront and return to ProgFront
			endif
			sprintf recreateDrawStr, "pathName:%s;DrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, dash= 2, xcoord= top, ycoord= left;" + \
			"DrawCmd:DrawLine %f, %f, %f, %f;ProfileCmd:Make/O/N=2 xTrace={%f, %f}, yTrace = {%f, %f}\nImageLineProfile/P=(%d) srcWave=%s," +\
			"xWave=xTrace, yWave=yTrace, width = %f\nDisplay/K=1 W_ImageLineProfile vs W_LineProfileDisplacement" + \
			"", ImagePathname, red, green, blue, C1x, C1y, C2x, C2y, C1x, C2x, C1y, C2y, selectedLayer, ImagePathname, profileWidth
			Note savedfr:$saveWaveNameStr, recreateDrawStr
			break
	endswitch
	return 0
End

static Function SaveDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_LineProfRootDF"))
	DFREF dfr0 = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:LineProfiles:DefaultSettings") // Settings here
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z C1x0 = dfr0:gATH_C1x0
	NVAR/Z C1y0 = dfr0:gATH_C1y0
	NVAR/Z C2x0 = dfr0:gATH_C2x0
	NVAR/Z C2y0 = dfr0:gATH_C2y0
	NVAR/Z profileWidth0 = dfr0:gATH_profileWidth0
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

static Function RestoreDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_LineProfRootDF"))
	DFREF dfr0 = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:LineProfiles:DefaultSettings") // Settings here
	SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z C1x0 = dfr0:gATH_C1x0
	NVAR/Z C1y0 = dfr0:gATH_C1y0
	NVAR/Z C2x0 = dfr0:gATH_C2x0
	NVAR/Z C2y0 = dfr0:gATH_C2y0
	NVAR/Z profileWidth0 = dfr0:gATH_profileWidth0
	NVAR/Z updateCursorsPositions = dfr:gATH_updateCursorsPositions
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

static Function ShowProfileWidth(STRUCT WMButtonAction &B_Struct): ButtonControl
	/// We have to find the vertices of the polygon representing
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_LineProfRootDF"))
	SVAR/Z WindowNameStr= dfr:gATH_WindowNameStr
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z width = dfr:gATH_profileWidth
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy // assume here that dx = dy
	variable x1, x2, x3, x4, y1, y2, y3, y4, xs, ys
	variable slope = ATH_Geometry#SlopePerpendicularToLineSegment(C1x, C1y,C2x, C2y)
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
		[xs, ys] = ATH_Geometry#GetVerticesPerpendicularToLine(width * dx/2, slope)
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

static Function CheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_LineProfRootDF"))
	NVAR/Z PlotSwitch = dfr:gATH_PlotSwitch
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

static Function ProfileLayer3D(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_LineProfRootDF"))
	NVAR/Z selectedLayer = dfr:gATH_selectedLayer
	NVAR/Z updateSelectedLayer = dfr:gATH_updateSelectedLayer
	SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr
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

static Function CheckboxMarkLines(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_LineProfRootDF"))
	NVAR/Z MarkLinesSwitch = dfr:gATH_MarkLinesSwitch
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

static Function SetVariableWidth(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sv.win, "", "ATH_LineProfRootDF"))
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z selectedLayer = dfr:gATH_selectedLayer
	SetDataFolder dfr
	Make/O/FREE/N=2 xTrace={C1x, C2x}, yTrace = {C1y, C2y}
	SVAR/Z ImagePathname = dfr:gATH_ImagePathname
	WAVE/Z imgWaveRef = $ImagePathname
	switch(sv.eventCode)
		case 6:
			ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = profileWidth
			break
	endswitch
	SetDataFolder currdfr
	return 0
End

