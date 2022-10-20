#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late

#include <Imageslider>


/// Profiler can now have several instances.

Function MXP_MainMenuLaunchZBeamProfiler()

	// Create the modal data browser but do not display it
	CreateBrowser/M prompt="Select a 3d wave to launch the z-profiler:"
	// Show waves but not variables in the modal data browser
	ModifyBrowser/M showWaves=1, showVars=0, showStrs=0
	// Set the modal data browser to sort by name 
	ModifyBrowser/M sort=1, showWaves=1, showVars=0, showStrs=0
	// Hide the info and plot panes in the modal data browser 
	ModifyBrowser/M showInfo=0, showPlot=1
	// Display the modal data browser, allowing the user to make a selection
	ModifyBrowser/M showModalBrowser

	if (V_Flag == 0)
		return 0			// User cancelled
	endif
	// User selected a wave, check if it's 3d
	string browserSelection = StringFromList(0, S_BrowserList)
	Wave selected3DWave = $browserSelection
	if(exists(browserSelection) && WaveDims(selected3DWave) == 3) // if it is a 3d wave
		NewImage/K=1 selected3DWave
		ModifyGraph width={Plan,1,top,left}
		MXP_InitialiseZProfilerFolder()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles:" + NameOfWave(selected3DWave)) // Change root folder if you want
		MXP_InitialiseZProfilerGraph(dfr)
		SVAR winNameStr = dfr:gMXP_WindowNameStr
		SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionBeamProfiler // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedPanelStr) = "MXP_ProfPanel_" + NameOfWave(selected3DWave) // Name of the panel we will make, used to communicate the
		// name to the windows hook to kill the panel after completion
	else
		Abort "z-profiler needs a 3d wave. N.B Select only one wave"
	endif
	return 0
End

Function MXP_TraceMenuLaunchZBeamProfiler()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	if(WaveDims(w3dref) == 3) // if it is a 3d wave
		KillWindow $winNameStr
		NewImage/K=1 w3dref
		ModifyGraph width={Plan,1,top,left}
		MXP_InitialiseZProfilerFolder()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		MXP_InitialiseZProfilerGraph(dfr)
		SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionBeamProfiler // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedPanelStr) = "MXP_ProfPanel_" + NameOfWave(w3dref) // Name of the panel we will make, used to communicate the
		// name to the windows hook to kill the panel after completion
	else
		Abort "z-profiler needs a 3d wave"
	endif
	return 0
End

Function MXP_InitialiseZProfilerFolder()
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here. Use the 3D wave in top window.

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string msg // Error reporting
	if(!strlen(imgNameTopGraphStr)) // we do not have an image in top graph
		Abort "No image in top graph. Startup profile with an 3d wave in your active window."
	endif
	
	if(WaveDims(w3dref) != 3)
		sprintf msg, "Z-profiler works with 3d waves only.  Wave %s is in top window", imgNameTopGraphStr
		Abort msg
	endif
	
	if(stringmatch(AxisList(winNameStr),"*bottom*")) // Check if you have a NewImage left;top axes
		sprintf msg, "Reopen as Newimage %s", imgNameTopGraphStr
		KillWindow $winNameStr
		NewImage/K=1/N=$winNameStr w3dref
		ModifyGraph/W=$winNameStr width={Plan,1,top,left}
	endif
	
	WMAppend3DImageSlider() // Everything ok now, add a slider to the 3d wave
	
	// Initialise the Package folder
	variable nlayers = DimSize(w3dref, 2)
	variable dx = DimDelta(w3dref, 0)
	variable dy = DimDelta(w3dref, 1)
	variable dz = DimDelta(w3dref, 2)
    variable z0 = DimOffset(w3dref, 2)
    
    
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles:" + imgNameTopGraphStr) // Root folder here
	string zprofilestr = "wZLineProfileWave"
	Make/O/N=(nlayers) dfr:$zprofilestr /Wave = profile // Store the line profile 
	SetScale/P x, z0, dz, profile
	
	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_LineProfileWaveStr = zprofilestr // image profile wave
	string/G dfr:gMXP_ProfileMetadata
	string/G dfr:gMXP_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gMXP_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gMXP_w3dNameStr = NameOfWave(w3dref)
	string/G dfr:gMXP_ProfileAreaOvalCoord
	variable/G dfr:gMXP_ROI_dx = dx
	variable/G dfr:gMXP_ROI_dy = dy
	variable/G dfr:gMXP_DoPlotSwitch = 0
	variable/G dfr:gMXP_colorcnt = 0
	variable/G dfr:gMXP_MarkAreasSwitch = 0
	return 0
End

Function MXP_DrawImageROICursor(variable left, variable top, variable right, variable bottom) // Function used by the hook
	/// Here we use ProgFront to get a mask from ImageGenerateROIMask
	
	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine
	string winNameStr = WinName(0, 1, 1)
	// Have you closed the Z profiler window? If yes relaunch it.
	//MXP_InitialiseZProfilerGraph() // Add this here?
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawOval left, top, right, bottom
	Cursor/I/L=0/C=(65535, 0, 0, 30000)/S=2 J $wnamestr 0.5 * (left + right), 0.5 * (top + bottom)
	return 0
End

Function MXP_DrawImageROI(variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 1, xcoord= top, ycoord= left
	DrawOval left, top, right, bottom
	return 0
End

Function MXP_CleanROIMarkings()
	SetDrawLayer ProgFront
	DrawAction delete
	return 0
End

Function MXP_CursorHookFunctionBeamProfiler(STRUCT WMWinHookStruct &s)
	/// Window hook function
    variable hookResult = 0
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF dfr = root:Packages:MXP_datafldr:ZBeamProfiles:$imgNameTopGraphStr // Do not call the function MXP_CreateDataFolderGetDFREF here
	NVAR/Z V_left, V_top, V_right, V_bottom
	NVAR/Z dx = dfr:gMXP_ROI_dx
	NVAR/Z dy = dfr:gMXP_ROI_dy
	variable axisxlen = V_right - V_left 
	variable axisylen = V_bottom - V_top
	SVAR/Z profilemetadata = dfr:gMXP_ProfileMetadata
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
	SVAR/Z w3dPath = dfr:gMXP_w3dPath
	DFREF wrk3dwave = $w3dPath
	Wave/SDFR=wrk3dwave w3d = $w3dNameStr
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	Wave/Z M_ROIMask
	
    switch(s.eventCode)
		case 0: //activate window rescales the profile to the layer scale of the 3d wave
			SetScale/P x, DimOffset(w3d,2), DimDelta(w3d,2), profile
			break
		case 2: // Kill the window
			KillWindow/Z $(GetUserData(s.winName, "", "MXP_LinkedPanelStr"))
			KillDataFolder/Z dfr
			hookresult = 1
			break
        case 7: // cursor moved
        	DrawAction delete
			MXP_DrawImageROICursor(-axisxlen * 0.5 + s.pointNumber * dx, axisylen * 0.5 + s.yPointNumber * dy, \
							 axisxlen * 0.5 + s.pointNumber * dx, -(axisylen * 0.5) + s.yPointNumber * dy)
			// We need to update the values here if we want to redraw later
			V_left = -axisxlen * 0.5 + s.pointNumber * dx
        	V_top = axisylen * 0.5 + s.yPointNumber * dy
        	V_right = axisxlen * 0.5 + s.pointNumber * dx
        	V_bottom = -(axisylen * 0.5) + s.yPointNumber * dy
			ImageGenerateROIMask $w3dNameStr // Here we need name of a wave, not a wave reference!
			if(WaveExists(M_ROIMask))
				MatrixOP/FREE/O/NTHR=4 buffer = sum(w3d*M_ROIMask) // Use two threads
		   	 	MatrixOP/FREE/O profile_free = beam(buffer,0,0) 
		    		profile = profile_free
		    endif
		    hookresult = 1	// TODO: Return 0 here, i.e delete line?
	 		break
        case 5: // mouse up
			KillWaves/Z M_ROIMask // Cleanup		
			hookresult = 1
			break
    endswitch
    return hookResult       // 0 if nothing done, else 1
End

Function MXP_InitialiseZProfilerGraph(DFREF dfr)
	/// Here we will create the profile panel and graph and plot the profile
	string panelNameStr = "MXP_ZProf_" + GetDataFolder(0, dfr)
	if (WinType(panelNameStr) == 0) // line profile window is not displayed
		MXP_CreateProfilePanel(dfr)
	else
		DoWindow/F $panelNameStr // if it is bring it to the FG
	endif
	return 0
End

Function MXP_CreateProfilePanel(DFREF dfr)
	string rootFolderStr = GetDataFolder(1, dfr)
	string waveNameStr = GetDataFolder(0, dfr) // Convention
	DFREF dfr = MXP_CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/Z/SDFR=dfr gMXP_LineProfileWaveStr
	if(!SVAR_Exists(gMXP_LineProfileWaveStr))
		Abort "Launch z-profiler from the MAXPEEM > Plot menu and then use the 'Oval ROI z profile' Marquee Operation."
	endif
	string profilePanelStr = "MXP_ProfPanel_" + GetDataFolder(0, dfr)
	NewPanel/N=$profilePanelStr /W=(580,53,995,316) // Linked to MXP_InitialiseZProfilerGraph()
	SetWindow $profilePanelStr userdata(MXP_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePanelStr userdata(MXP_targetGraphWin) = "MXP_AreaProf_" + waveNameStr
	ModifyPanel cbRGB=(61166,61166,61166), frameStyle=3
	SetDrawLayer UserBack
	Button SaveProfileButton, pos={20.00,10.00}, size={90.00,20.00}, proc=MXP_SaveProfilePanel, title="Save Profile", help={"Save current profile"}, valueColor=(1,12815,52428)
	CheckBox ShowProfile, pos={150.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ProfilePanelCheckboxPlotProfile,title="Plot profiles ", fSize=14, value= 0
	CheckBox ShowSelectedAread, pos={270.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ProfilePanelCheckboxMarkAreas,title="Mark areas ", fSize=14, value= 0
	Wave profile = dfr:$gMXP_LineProfileWaveStr
	if (WaveExists(profile))
		Display/N=MXP_ZLineProfilesPlot/W=(15,38,391,236)/HOST=#  profile
		ModifyGraph rgb=(1,12815,52428), tick(left)=2, fSize=12, lsize=1.5
		Label left "\\u#2 Intensity (arb. u.)";DelayUpdate
		Label bottom "\\u#2 Energy (eV)"
	else
		Abort "Unknown error!"
	endif

	SetDrawLayer UserFront
	return 0
End

Function MXP_SaveProfilePanel(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "MXP_targetGraphWin")
	NVAR/Z V_left, V_right, V_top, V_bottom
	SVAR/Z profilemetadata = dfr:gMXP_ProfileMetadata
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
	SVAR/Z w3dPath = dfr:gMXP_w3dPath
	SVAR/Z ProfileAreaOvalCoord = dfr:gMXP_ProfileAreaOvalCoord
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	NVAR/Z DoPlotSwitch = dfr:gMXP_DoPlotSwitch
	NVAR/Z MarkAreasSwitch = dfr:gMXP_MarkAreasSwitch
	NVAR/Z colorcnt = dfr:gMXP_colorcnt
	
	variable axisxlen = V_right - V_left 
	variable axisylen = V_bottom - V_top
	string recreateDrawStr
	DFREF savedfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles:SavedProfiles")
	
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
						MXP_DrawImageROI(V_left, V_top, V_right, V_bottom, red, green, blue)
						SetDrawLayer/W=$WindowNameStr ProgFront // Return to ProgFront
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


Function MXP_ProfilePanelCheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

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


Function MXP_ProfilePanelCheckboxMarkAreas(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
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
