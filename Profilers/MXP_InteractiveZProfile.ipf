#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
//#pragma rtFunctionErrors = 1 // Debug mode
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late

#include <Image common>
#include <Imageslider>


/// TODO: Can you extend functionality so you can have many windows but one panel?
/// 	  Might be handy to user SetWindow userdata(UDName )=UDStr, to give the handle.
///		  You need to improve the whole stability and functionality. There are issues
///		  and the programs has bugs, lots.
///			

Function MXP_MainMenuLaunchZBeamProfiler()

	// Create the modal data browser but do not display it
	CreateBrowser/M prompt="Select a 3d wave to start the z-profiler:"
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
		CheckDisplayed/A $browserSelection
		NewImage/K=1 selected3DWave
		MXP_InitialiseZProfilerFolder()
		MXP_InitialiseZProfilerGraph()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles") // Change root folder if you want
		SVAR winNameStr = dfr:gMXP_WindowNameStr
		SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionBeamProfiler // Set the hook
	else
		Abort "z-profiler need a 3d wave"
	endif
End

Function MXP_InitialiseZProfilerFolder()
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here. Use the 3D wave in top window.

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopWindowStr = RemoveEnding(ImageNameList("", ";"))
	Wave w3dref = ImageNameToWaveRef("", imgNameTopWindowStr) // full path of wave

	string msg // Error reporting
	if(!strlen(imgNameTopWindowStr)) // we do not have an image in top graph
		Abort "No image in top graph. Startup profile with an 3d wave in your active window."
	endif
	
	if(WaveDims(w3dref) != 3)
		sprintf msg, "Z-profiler works with 3d waves only.  Wave %s is in top window", imgNameTopWindowStr
		Abort msg
	endif
	
	if(stringmatch(AxisList(winNameStr),"*bottom*")) // Check if you have a NewImage left;top axes
		sprintf msg, "Reopen as Newimage %s", imgNameTopWindowStr
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
    
    
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles") // Root folder here
	string zprofilestr = "wZLineProfilesPlot"//NameOfWave(w3dref) + "_Zprofile"
	Make/O/N=(nlayers) dfr:$zprofilestr /Wave = profile // Store the line profile 
	SetScale/P x, z0, dz, profile
	
	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopWindowStr
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
End

Function MXP_InitialiseZProfilerGraph()
	/// Here we will create the profile panel and graph and plot the profile
	if (WinType("MXP_ZBeamLineProfilePanel") == 0) // line profile window is not displayed
		MXP_CreateProfilePanel()
	else
		DoWindow/F ZLineProfilesPlot // if it is bring it to the FG
	endif
End

Function MXP_StartZProfiler()
	MXP_InitialiseZProfilerFolder()
	MXP_InitialiseZProfilerGraph()
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles") // Change root folder if you want
	SVAR winNameStr = dfr:gMXP_WindowNameStr // Does not work for multiply windows
	//string winNameStr = WinName(0, 1, 1)
	SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionBeamProfiler // Set the hook
End


Function MXP_DrawImageROICursor(variable left, variable top, variable right, variable bottom) // Function used by the hook
	/// Here we use ProgFront to get a mask from ImageGenerateROIMask
	
	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine
	string winNameStr = WinName(0, 1, 1)
	// Have you closed the Z profiler window? If yes relaunch it.
	MXP_InitialiseZProfilerGraph()
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 0.5, xcoord = top, ycoord = left
	DrawOval left, top, right, bottom
	Cursor/I/L=0/C=(65535, 0, 0, 30000)/S=2 J $wnamestr 0.5 * (left + right), 0.5 * (top + bottom)
End

Function MXP_DrawImageROI(variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 0.5, xcoord= top, ycoord= left
	DrawOval left, top, right, bottom
End

Function MXP_CleanROIMarkings()
	SetDrawLayer UserFront
	DrawAction delete
End

Function MXP_CursorHookFunctionBeamProfiler(STRUCT WMWinHookStruct &s)
	/// Window hook function
	    
    variable hookResult = 0
	DFREF dfr = root:Packages:MXP_datafldr:ZBeamProfiles
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

		case 2: // Kill the window
			KillWaves/Z M_ROIMask
			KillWindow/Z MXP_ZBeamLineProfilePanel
			KillWindow/Z MXP_LineProfileGraph
			MXP_CleanGlobalWavesVarAndStrInFolder(dfr)
			//hookresult = 1
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
		    //hookresult = 1	// TODO: Return 0 here, i.e delete line?
	 		break
        case 5: // mouse up
			KillWaves/Z M_ROIMask // Cleanup		
			//hookresult = 1
			break
    endswitch
    return hookResult       // 0 if nothing done, else 1
End


Function MXP_CreateProfilePanel()
	
	DFREF dfr = root:Packages:MXP_datafldr:ZBeamProfiles
	SVAR/Z/SDFR=dfr gMXP_LineProfileWaveStr
	if(!SVAR_Exists(gMXP_LineProfileWaveStr))
		Abort "Launch z-profiler from the MAXPEEM > Plot menu and then use the 'Oval ROI z profile' Marquee Operation."
	endif
		 
	NewPanel/N=MXP_ZBeamLineProfilePanel /W=(580,53,995,316) // Linked to MXPInitializeAreaIntegrationProfiler()
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
End

Function MXP_SaveProfilePanel(STRUCT WMButtonAction &B_Struct): ButtonControl
	/// Save profile wave
	NVAR/Z V_left, V_right, V_top, V_bottom
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles")
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
						if(WinType("MXP_LineProfileGraph") == 1)
							AppendToGraph/W=MXP_LineProfileGraph savedfr:$saveWaveNameStr
							[red, green, blue] = MXP_GetColor(colorcnt)
							Modifygraph/W=MXP_LineProfileGraph rgb($saveWaveNameStr) = (red, green, blue)
							colorcnt += 1 // i++ does not work with globals?
						else
							Display/K=1/N=MXP_LineProfileGraph savedfr:$saveWaveNameStr
							[red, green, blue] = MXP_GetColor(colorcnt)
							Modifygraph/W=MXP_LineProfileGraph rgb($saveWaveNameStr) = (red, green, blue)
							AutopositionWindow/R=MXP_ZBeamLineProfilePanel MXP_LineProfileGraph
							DoWindow/F MXP_LineProfileGraph
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
						SetDrawLayer/W= $WindowNameStr ProgFront // Return to ProgFront
					endif
				break // Stop if you go through the else branch
				endif	
			while(1)
		sprintf recreateDrawStr, "waveName:%s;DrawEnv:SetDrawEnv linefgc = (%d, %d, %d),fillpat = 0,linethick = 0.5 xcoord= top,ycoord= left;" + \
								 "DrawCmd:DrawOval %f, %f, %f, %f", w3dNameStr, red, green, blue, V_left, V_top, V_right, V_bottom
		Note savedfr:$saveWaveNameStr, recreateDrawStr
		break
	endswitch
End


Function MXP_ProfilePanelCheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles")
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
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles")
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
