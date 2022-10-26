#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late



Function MXP_TraceMenuLaunchLineProfiler()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	if(WaveDims(imgWaveRef) == 2 || WaveDims(imgWaveRef) == 3) // if it is not a 1d wave
		KillWindow $winNameStr
		NewImage/K=1 imgWaveRef
		ModifyGraph width={Plan,1,top,left}
		MXP_InitialiseLineProfilerFolder()
		DoWindow/F $winNameStr // bring it to FG to set the cursors
		variable nrows = DimSize(imgWaveRef,0)
		variable ncols = DimSize(imgWaveRef,1)
		Cursor/I/C=(65535,0,0,30000)/S=1/P G $imgNameTopGraphStr nrows/2 + 20, ncols/2 - 20
		Cursor/I/C=(65535,0,0,30000)/S=1/P H $imgNameTopGraphStr nrows/2 - 20 , ncols/2 + 20
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:" + NameOfWave(imgWaveRef)) // Change root folder if you want
		MXP_InitialiseLineProfilerGraph(dfr)
		SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionLineProfiler // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedPanelStr) = "MXP_LineProfPanel_" + NameOfWave(imgWaveRef) // Name of the panel we will make, used to communicate the
		// name to the windows hook to kill the panel after completion
	else
		Abort "Line profiler needs an image or image stack."
	endif
	return 0
End

Function MXP_InitialiseLineProfilerFolder()
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here. Use the 3D wave in top window.

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string msg // Error reporting
	if(!strlen(imgNameTopGraphStr)) // we do not have an image in top graph
		Abort "No image in top graph. Start the line profiler with an image or image stack in top window."
	endif
	
	if(WaveDims(imgWaveRef) != 2 && WaveDims(imgWaveRef) != 3)
		sprintf msg, "Z-profiler works with images or image stacks.  Wave %s is in top window", imgNameTopGraphStr
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
	variable/G dfr:gMXP_C1x = nrows/2 + 20
	variable/G dfr:gMXP_C1y = ncols/2 - 20
	variable/G dfr:gMXP_C2x = nrows/2 - 20 
	variable/G dfr:gMXP_C2y = ncols/2 + 20
	// Default settings
	variable/G dfr0:gMXP_C1x0 = 0
	variable/G dfr0:gMXP_C1y0 = 0
	variable/G dfr0:gMXP_C2x0 = 0
	variable/G dfr0:gMXP_C2y0 = 0

	variable/G dfr:gMXP_PlotSwitch = 0
	variable/G dfr:gMXP_SelectLayer = NaN // numtype == 2
	return 0
End

Function MXP_ClearLineMarkings()
	SetDrawLayer ProgFront
	DrawAction delete
	SetDrawLayer UserFront
	return 0
End

Function MXP_CursorHookFunctionLineProfiler(STRUCT WMWinHookStruct &s)
	/// Window hook function
    variable hookResult = 0
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF dfr = root:Packages:MXP_DataFolder:LineProfiles:$imgNameTopGraphStr // Do not call the function MXP_CreateDataFolderGetDFREF here	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	SVAR/Z ImagePath = dfr:gMXP_ImagePath
	SVAR/Z ImageNameStr = dfr:gMXP_ImageNameStr
	NVAR/Z dx = dfr:gMXP_dx
	NVAR/Z dy = dfr:gMXP_dy
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
    WAVE/Z imgWaveRef = $ImageNameStr
	variable x1, y1
	if(cmpstr(s.cursorName, "G"))
		x1 = hcsr(G)
		y1 = vcsr(G)
	endif
	if(cmpstr(s.cursorName, "H"))
		x1 = hcsr(H)
		y1 = vcsr(H)
	endif
    switch(s.eventCode)
		case 2: // Kill the window
			hookresult = 1
			break
	    case 7: // cursor moved
	    	DrawAction delete
	    	SetDrawLayer ProgFront
	    	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	    	DrawLine x1, y1, s.pointNumber * dx, s.ypointNumber*dy
	    	Make/O/FREE/N=2 xTrace={x1, s.pointNumber * dx}, yTrace = {y1, s.ypointNumber * dy}
	    	ImageLineProfile srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = 0
	    	hookResult = 1
	    	break
        case 5: // mouse up
        	SetDrawLayer UserFront
       		hookResult = 1
			break
    endswitch
    return hookResult       // 0 if nothing done, else 1
End

/// Everything below this point needs fixing

Function MXP_InitialiseLineProfilerGraph(DFREF dfr)
	/// Here we will create the profile panel and graph and plot the profile
	string panelNameStr = "MXP_LineProf_" + GetDataFolder(0, dfr)
	if (WinType(panelNameStr) == 0) // line profile window is not displayed
		MXP_CreateLineProfilePanel(dfr)
	else
		DoWindow/F $panelNameStr // if it is bring it to the FG
	endif
	return 0
End

Function MXP_CreateLineProfilePanel(DFREF dfr)
	string rootFolderStr = GetDataFolder(1, dfr)
	string waveNameStr = GetDataFolder(0, dfr) // Convention
	DFREF dfr = MXP_CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/Z/SDFR=dfr gMXP_LineProfileWaveStr
//	if(!SVAR_Exists(gMXP_LineProfileWaveStr))
//		Abort "Launch z-profiler from the MAXPEEM > Plot menu and then use the 'Oval ROI z profile' Marquee Operation."
//	endif
	string profilePanelStr = "MXP_LineProfPanel_" + GetDataFolder(0, dfr)
	NewPanel/N=$profilePanelStr /W=(580,53,995,316) // Linked to MXP_InitialiseZProfilerGraph()
	SetWindow $profilePanelStr userdata(MXP_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePanelStr userdata(MXP_targetGraphWin) = "MXP_AreaProf_" + waveNameStr
	ModifyPanel cbRGB=(61166,61166,61166), frameStyle=3
	SetDrawLayer UserBack
	Button SaveProfileButton, pos={20.00,10.00}, size={90.00,20.00}, proc=MXP_SaveProfilePanel, title="Save Profile", help={"Save current profile"}, valueColor=(1,12815,52428)
	CheckBox ShowProfile, pos={150.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ProfilePanelCheckboxPlotProfile,title="Plot profiles ", fSize=14, value= 0
	CheckBox ShowSelectedAread, pos={270.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ProfilePanelCheckboxMarkAreas,title="Mark areas ", fSize=14, value= 0
	Wave/Z  W_LineProfileDisplacement, W_ImageLineProfile
	Display/N=MXP_ZLineProfilesPlot/W=(15,38,391,236)/HOST=# W_ImageLineProfile vs W_LineProfileDisplacement
	ModifyGraph rgb=(1,12815,52428), tick(left)=2, fSize=12, lsize=1.5
	//Label left "\\u#2 Intensity (arb. u.)";DelayUpdate
	//Label bottom "\\u#2 Energy (eV)"


	SetDrawLayer UserFront
	return 0
End

Function MXP_SaveLineProfilePanel(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "MXP_targetGraphWin")
	NVAR/Z V_left, V_right, V_top, V_bottom
	SVAR/Z profilemetadata = dfr:gMXP_ProfileMetadata
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_ImageNameStr
	SVAR/Z w3dPath = dfr:gMXP_ImagePath
	SVAR/Z ProfileAreaOvalCoord = dfr:gMXP_ProfileAreaOvalCoord
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	NVAR/Z DoPlotSwitch = dfr:gMXP_DoPlotSwitch
	NVAR/Z MarkAreasSwitch = dfr:gMXP_MarkAreasSwitch
	NVAR/Z colorcnt = dfr:gMXP_colorcnt
	
	variable axisxlen = V_right - V_left 
	variable axisylen = V_bottom - V_top
	string recreateDrawStr
	DFREF savedfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:SavedProfiles")
	
	variable postfix = 0
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			do
				string saveWaveNameStr = w3dNameStr + "_prof" + num2str(postfix)
				if(WaveExists(savedfr:$saveWaveNameStr) == 1)
					postfix++
				else
					Duplicate dfr:$LineProfileWaveStr, savedfr:$saveWaveNameStr
							
					if(DoPlotSwitch)
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
					
					if(MarkAreasSwitch)
						if(!DoPlotSwitch)
							[red, green, blue] = MXP_GetColor(colorcnt)
							colorcnt += 1
						endif
						DoWindow/F $WindowNameStr
						MXP_DrawImageROI(V_left, V_top, V_right, V_bottom, red, green, blue) // Draw on UserFront and return to ProgFront
					endif
				break // Stop if you go through the else branch
				endif	
			while(1)
		sprintf recreateDrawStr, "pathName:%s;DrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= top, ycoord= left;" + \
								 "DrawCmd:DrawOval %f, %f, %f, %f", w3dPath + w3dNameStr, red, green, blue, V_left, V_top, V_right, V_bottom
		Note savedfr:$saveWaveNameStr, recreateDrawStr
		break
	endswitch
	return 0
End


Function MXP_LineProfilePanelCheckboxPlotLineProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrStr"))
	NVAR/Z DoPlotSwitch = dfr:gMXP_DoPlotSwitch
	switch(cb.checked)
		case 1:		// Mouse up
			DoPlotSwitch = 1
			break
		case 0:
			DoPlotSwitch = 0
			break
	endswitch
	return 0
End


Function MXP_LineProfilePanelCheckboxMarkAreas(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrStr"))
	NVAR/Z MarkAreasSwitch = dfr:gMXP_MarkAreasSwitch
	switch(cb.checked)
		case 1:		// Mouse up
			MarkAreasSwitch = 1
			break
		case 0:
			MarkAreasSwitch = 0
			break
	endswitch
	return 0
End


// Mon CW43 : Develop on Tuesday and Wednesday

Function MXP_GetLineProfile(Wave waveRef)
	// ImageLineProfile srcWave=sampleData, xWave=xTrace, yWave=yTrace
	// We will use Igor's Imagelineprofile here
	
	variable pmin, pmax, qmin, qmax
	
	Variable x1 = hcsr(A), x2 = hcsr(B), y1 = vcsr(A), y2 = vcsr(B)
	
	if (pcsr(A)<pcsr(B))	
		pmin = pcsr(A)
		pmax = pcsr(B)
	else
		pmin = pcsr(B)
		pmax = pcsr(A)
	endif
	
	if (qcsr(A)<qcsr(B))	
		qmin = qcsr(A)
		qmax = qcsr(B)
	else
		qmin = qcsr(B)
		qmax = qcsr(A)
	endif
	
	variable ptot = pmax - pmin, qtot = qmax - qmin
	
	variable xtot = abs(x2 - x1), ytot = abs(y2 - y1)
		
	variable linelen = sqrt(xtot^2+ytot^2) // len in x, y scale
	
	string lineProfileNameStr = NameofWave(waveRef) + "_egprof"
	
	variable ii, xstart, xend, ystart, yend, linegrad = inf	
		 
	linegrad = (y2 - y1)/(x2-x1) // Cartetian system rotated be -90 deg

	Variable pwidth
		if (linegrad < 0)
				xstart = max(x1, x2)
				xend = min(x1, x2)
				ystart =  min(y1, y2)
				yend = max(y1, y2) 
				Make/O/FREE/N=2 xTrace={xstart, xend}, yTrace = {ystart, yend}
		else
				xstart = min(x1, x2)
				xend = max(x1, x2)
				ystart =  min(y1, y2)
				yend = max(y1, y2)
				Make/O/FREE/N=2 xTrace={xstart, xend}, yTrace = {ystart, yend}
		endif
			
		Prompt pwidth, "Line profile widht (pixels)" 
		DoPrompt "Width ", pwidth
		if (V_flag == 1)
			return -1
		endif
		ImageLineProfile/SC srcWave=waveRef, xWave=xTrace, yWave=yTrace, width = pwidth	
	
	// Here add the case when you have a 3d wave and you can get the profile at any plane /P
	
	WAVE/Z W_ImageLineProfile, W_LineProfileDisplacement
	Duplicate/O W_ImageLineProfile, $lineProfileNameStr
	SetScale/I x, W_LineProfileDisplacement[0], W_LineProfileDisplacement[numpnts(W_LineProfileDisplacement) - 1], $lineProfileNameStr
	WAVEClear W_ImageLineProfile, W_LineProfileDisplacement
	// Add details of the line profile
	Note/K $lineProfileNameStr 
	string coordstart = "Start ["+num2str(pmin)+"]"+"["+num2str(qmin)+"] " + "x: " + num2str(xstart) + ", " + "y: " + num2str(ystart) 
	string coordend = "End ["+num2str(pmax)+"]"+"["+num2str(qmax)+"] " + "x: " + num2str(xend) + ", " + "y: " + num2str(yend)
	string gradient = "Gradient: " + num2str(linegrad)+", Line length: " + num2str(linelen) 
	Note $lineProfileNameStr, coordstart
	Note $lineProfileNameStr, coordend
	Note $lineProfileNameStr, gradient
	Note $lineProfileNameStr, "Profile width in pixels: " + num2str(pwidth) +" ("+ num2str(2*(pwidth+0.5)) +" points)"
	Note $lineProfileNameStr, "Profile extracted from " + NameOfWave(waveRef)
End

//Under development
Function dummy()
//	string winNameStr = WinName(0, 1, 1)
//	SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionLineProfiler // Set the hook
//	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
//	Wave imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
//	String/G waveStr = NameOfWave(imgWaveRef)
SetWindow $"", hook(MyHook) = MXP_CursorHookFunctionLineProfiler 
End

Function MXP_CursorHookFunctionLineProfilerTMP(STRUCT WMWinHookStruct &s)
	/// Window hook function
//	s.doSetCursor = 1
//	s.cursorCode = 3
    variable hookResult = 0
//    if(!cmpstr(s.cursorName,"Α"))
//    	print s.cursorName
//		s.doSetCursor = 1
//		s.cursorCode = 9
//	endif
	//SVAR wrStr = waveStr
	WAVE/Z imgWaveRef
	variable x1 = hcsr(A)
	//variable x2 = hcsr(B)
	variable y1 = vcsr(A)
	//variable y2 = xcsr(B)
	Wave s3d = $"LEEM at 10p3eV FoV 1p25um Mirror off"
	variable dx = DimDelta(imgWaveRef,0)
	variable dy = DimDelta(imgWaveRef,1)
    switch(s.eventCode)
		case 2: // Kill the window
			hookresult = 1
			break
	    case 7: // cursor moved
	    	DrawAction delete
	    	SetDrawLayer ProgFront
	    	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	    	DrawLine x1, y1, s.pointNumber * dx, s.ypointNumber*dy
	    	Make/O/FREE/N=2 xTrace={x1, s.pointNumber * dx}, yTrace = {y1, s.ypointNumber * dy}
	    	ImageLineProfile/SC srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = 0	

	    		//break
//	    	switch(s.eventMod)
//	    		case 1: // Drag it like this. Set A a cursor to start, drag and draw line
//	    		//print s.pointNumber, s.ypointNumber
//
//	    	endswitch
	    	hookResult = 1
	 		break
	 	//case 3:
//	 	case 4:
//	 		//print s.pointNumber, s.ypointNumber
//	 		print s.mouseLoc.h, s.mouseLoc.v
//	 		hookResult = 1
//	 		break
        case 5: // mouse up
        	print "mouseup"
       		hookResult = 1
			break
    endswitch
    return hookResult       // 0 if nothing done, else 1
End