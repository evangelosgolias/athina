#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late

#include <Imageslider>


/// Profiler can now have several instances.

// TODO: Check if you have DoWindow/F for actions on graphs/panels. Use /W=Name instead.

Function MXP_MainMenuLaunchZBeamProfiler()

	// Create the modal data browser but do not display it
	CreateBrowser/M prompt="Select an image stack and press OK"
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
	WAVE w3dref = $browserSelection
	// When plotting waves from calculations we might have NaNs or Infs.
	// Remove them before starting and replace them with zeros
	Wavestats/M=1/Q w3dref
	if(V_numNaNs || V_numInfs)
		printf "Replaced %d NaNs and %d Infs in %s", V_numNaNs, V_numInfs, NameOfWave(w3dref)
		w3dref = (numtype(w3dref)) ? 0 : w3dref // numtype = 1, 2 for NaNs, Infs
	endif
	if(exists(browserSelection) && WaveDims(w3dref) == 3) // if it is a 3d wave
		NewImage/K=1 w3dref
		ModifyGraph width={Plan,1,top,left}
		MXP_InitialiseZProfilerFolder()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		MXP_InitialiseZProfilerGraph(dfr)
		SVAR winNameStr = dfr:gMXP_WindowNameStr
		SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionBeamProfiler // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedPanelStr) = "MXP_ZProfPanel_" + winNameStr // Name of the panel we will make, used to send the kill signal to the panel
		SetWindow $winNameStr userdata(MXP_DFREF) = "root:Packages:MXP_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
	else
		Abort "z-profiler needs a 3d wave. N.B Select only one wave"
	endif
	return 0
End

Function MXP_TraceMenuLaunchZBeamProfiler() // Trace menu launcher, inactive

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	if(WaveDims(w3dref) == 3) // if it is a 3d wave
		KillWindow $winNameStr
		// When plotting waves from calculations we might have NaNs or Infs.
		// Remove them before starting and replace them with zeros
		Wavestats/M=1/Q w3dref
		if(V_numNaNs || V_numInfs)
			printf "Replaced %d NaNs and %d Infs in %s", V_numNaNs, V_numInfs, NameOfWave(w3dref)
			w3dref = (numtype(w3dref)) ? 0 : w3dref // numtype = 1, 2 for NaNs, Infs
		endif
		NewImage/K=1 w3dref
		winNameStr = WinName(0, 1, 1)
		ModifyGraph width={Plan,1,top,left}
		MXP_InitialiseZProfilerFolder()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		MXP_InitialiseZProfilerGraph(dfr)
		SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionBeamProfiler // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedPanelStr) = "MXP_ZProfPanel_" + winNameStr // Name of the panel we will make, used to send the kill signal to the panel
		SetWindow $winNameStr userdata(MXP_DFREF) = "root:Packages:MXP_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
	else
		Abort "z-profiler needs a 3d wave"
	endif
	return 0
End

Function MXP_BrowserMenuLaunchZBeamProfiler() // Browser menu launcher, active

	// Check if you have selected a single 3D wave
	if(MXP_CountSelectedWavesInDataBrowser(waveDimemsions = 3) == 1\
	 && MXP_CountSelectedWavesInDataBrowser() == 1) // If we selected a single 3D wave		
	 	string selected3DWaveStr = GetBrowserSelection(0)
		WAVE w3dRef = $selected3DWaveStr
		// When plotting waves from calculations we might have NaNs or Infs.
		// Remove them before starting and replace them with zeros
		Wavestats/M=1/Q w3dref
		if(V_numNaNs || V_numInfs)
			printf "Replaced %d NaNs and %d Infs in %s", V_numNaNs, V_numInfs, NameOfWave(w3dref)
			w3dref = (numtype(w3dref)) ? 0 : w3dref // numtype = 1, 2 for NaNs, Infs
		endif
		NewImage/K=1 w3dRef
		string winNameStr = WinName(0, 1, 1)
		ModifyGraph width={Plan,1,top,left}
		MXP_InitialiseZProfilerFolder()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		MXP_InitialiseZProfilerGraph(dfr)
		SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionBeamProfiler // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedPanelStr) = "MXP_ZProfPanel_" + winNameStr // Name of the panel we will make, used to send the kill signal to the panel
		SetWindow $winNameStr userdata(MXP_DFREF) = "root:Packages:MXP_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
	else
		Abort "Z profile opearation needs only one 3d wave."
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
		Abort "No image in top graph. Start profiler with an image stack in top window."
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
    
    
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + imgNameTopGraphStr) // Root folder here
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
	variable/G dfr:gMXP_ROI_dx = dx
	variable/G dfr:gMXP_ROI_dy = dy
	variable/G dfr:gMXP_left = 0
	variable/G dfr:gMXP_right = 0
	variable/G dfr:gMXP_top = 0
	variable/G dfr:gMXP_bottom = 0	
	variable/G dfr:gMXP_DoPlotSwitch = 0
	variable/G dfr:gMXP_colorcnt = 0
	variable/G dfr:gMXP_MarkAreasSwitch = 0
	variable/G dfr:gMXP_mouseTrackV
	return 0
End

//Entry point
Function MXP_DrawROIAndWaitHookToAct() // Function used by the hook
	/// Here we use ProgFront to get a mask from ImageGenerateROIMask
	
	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine
	string winNameStr = WinName(0, 1, 1)
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	GetMarquee/K left, top
	string dfrStr = GetUserData(winNameStr, "", "MXP_DFREF")
	DFREF dfr = MXP_CreateDataFolderGetDFREF(dfrStr)
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom
	gMXP_left = V_left
	gMXP_right = V_right
	gMXP_top = V_top
	gMXP_bottom = V_bottom
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawOval gMXP_left, gMXP_top, gMXP_right, gMXP_bottom
	ImageGenerateROIMask $wnamestr
	Cursor/I/L=0/C=(65535,65535,0)/S=2 J $wnamestr 0.5 * (gMXP_left + gMXP_right), 0.5 * (gMXP_top + gMXP_bottom)
	return 0
End

Function MXP_DrawImageROI(variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	// Use MXP_DrawImageROI to draw on UserFront and then return the ProgFront (used by the hook function and ImageGenerateROIMask)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 1, xcoord= top, ycoord= left
	DrawOval left, top, right, bottom
	SetDrawLayer ProgFront 
	return 0
End

Function MXP_ClearROIMarkings()
	SetDrawLayer UserFront
	DrawAction delete
	SetDrawLayer ProgFront
	return 0
End

Function MXP_InitialiseZProfilerGraph(DFREF dfr)
	/// Here we will create the profile panel and graph and plot the profile
	string panelNameStr = "MXP_ZProf_" + GetDataFolder(0, dfr)
	if (WinType(panelNameStr) == 0) // line profile window is not displayed
		MXP_CreateZProfilePanel(dfr)
	else
		DoWindow/F $panelNameStr // if it is bring it to the FG
	endif
	return 0
End

Function MXP_CreateZProfilePanel(DFREF dfr)
	string rootFolderStr = GetDataFolder(1, dfr)
	DFREF dfr = MXP_CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/Z/SDFR=dfr gMXP_LineProfileWaveStr
	SVAR/Z/SDFR=dfr gMXP_WindowNameStr 
	if(!SVAR_Exists(gMXP_LineProfileWaveStr))
		Abort "Launch z-profiler from the MAXPEEM > Plot menu and then use the 'Oval ROI z profile' Marquee Operation."
	endif
	string profilePanelStr = "MXP_ZProfPanel_" + gMXP_WindowNameStr 
	NewPanel/N=$profilePanelStr /W=(580,53,995,316) // Linked to MXP_InitialiseZProfilerGraph()
	SetWindow $profilePanelStr userdata(MXP_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePanelStr userdata(MXP_targetGraphWin) = "MXP_AreaProf_" + gMXP_WindowNameStr
	ModifyPanel cbRGB=(61166,61166,61166), frameStyle=3
	SetDrawLayer UserBack
	Button SaveProfileButton, pos={20.00,10.00}, size={90.00,20.00}, proc=MXP_SaveZProfileButton, title="Save Profile", help={"Save current profile"}, valueColor=(1,12815,52428)
	CheckBox ShowProfile, pos={150.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ZProfilePanelCheckboxPlotProfile,title="Plot profiles ", fSize=14, value= 0
	CheckBox ShowSelectedAread, pos={270.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ZProfilePanelCheckboxMarkAreas,title="Mark areas ", fSize=14, value= 0
	WAVE profile = dfr:$gMXP_LineProfileWaveStr
	if (WaveExists(profile))
		Display/N=MXP_ZLineProfilesPlot/W=(15,38,391,236)/HOST=# profile
		ModifyGraph rgb=(1,12815,52428), tick(left)=2, fSize=12, lsize=1.5
		Label left "\\u#2 Intensity (arb. u.)";DelayUpdate
		Label bottom "\\u#2 Energy (eV)"
		AutoPositionWindow/E/M=0/R=$gMXP_WindowNameStr

	else
		Abort "Unknown error!"
	endif

	SetDrawLayer UserFront
	return 0
End

Function MXP_CursorHookFunctionBeamProfiler(STRUCT WMWinHookStruct &s)
	/// Window hook function
    variable hookResult = 0, i
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + imgNameTopGraphStr) // imgNameTopGraphStr will have '' if needed.
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom
	NVAR/Z dx = dfr:gMXP_ROI_dx
	NVAR/Z dy = dfr:gMXP_ROI_dy
	NVAR/Z mouseTrackV = dfr:gMXP_mouseTrackV
	variable axisxlen = gMXP_right - gMXP_left
	variable axisylen = gMXP_bottom - gMXP_top
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
	SVAR/Z w3dPath = dfr:gMXP_w3dPath
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	DFREF wrk3dwave = $w3dPath
	Wave/SDFR=wrk3dwave w3d = $w3dNameStr
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	Wave/Z M_ROIMask
	
	SetDrawLayer/W=$WindowNameStr ProgFront // We need it for ImageGenerateROIMask
	
    switch(s.eventCode)
		case 0: //activate window rescales the profile to the layer scale of the 3d wave
			SetScale/P x, DimOffset(w3d,2), DimDelta(w3d,2), profile // Remove it, not needed here.
			hookresult = 1
			break
		case 2: // Kill the window
			KillWindow/Z $(GetUserData(s.winName, "", "MXP_LinkedPanelStr"))
			KillDataFolder/Z dfr
			KillWaves/Z M_ROIMask // Cleanup
			hookresult = 1
			break
		case 4:
			mouseTrackV = s.mouseLoc.v
			hookresult = 0 // Here hookresult = 1, supresses Marquee
			break
		case 5: // mouse up
			KillWaves/Z M_ROIMask // Cleanup		
			hookresult = 1
			break
        case 7: // cursor moved
        	if(!cmpstr(s.CursorName,"J")) // acts only on the J cursor
        		DrawAction/W=$WindowNameStr delete // TODO: Here add the env commands of MXP_DrawImageROICursor before switch and here only the draw command 
        		SetDrawEnv/W=$WindowNameStr linefgc = (65535,65535,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
				DrawOval/W=$WindowNameStr -axisxlen * 0.5 + s.pointNumber * dx, axisylen * 0.5 + s.yPointNumber * dy, \
					  axisxlen * 0.5 + s.pointNumber * dx,  -(axisylen * 0.5) + s.yPointNumber * dy
				Cursor/I/L=0/C=(65535,65535,0)/S=2 J $w3dNameStr, s.pointNumber * dx, s.yPointNumber * dy
				ImageGenerateROIMask/W=$WindowNameStr $w3dNameStr // Here we need name of a wave, not a wave reference!
				if(WaveExists(M_ROIMask))
					MatrixOP/FREE/O/NTHR=4 buffer = sum(w3d*M_ROIMask) // Use two threads
		   		 	MatrixOP/O profile = beam(buffer,0,0)
		    			gMXP_left = -axisxlen * 0.5 + s.pointNumber * dx
					gMXP_right = axisxlen * 0.5 + s.pointNumber * dx
					gMXP_top = axisylen * 0.5 + s.yPointNumber * dy
					gMXP_bottom = -(axisylen * 0.5) + s.yPointNumber * dy
		    		endif
		    endif
		    hookresult = 1
	 		break
	 	case 8: // We have a Window modification eveny
	 		if(mouseTrackV < 0) // mouse outside of plot area
	 			NVAR/Z glayer = root:Packages:WM3DImageSlider:$(WindowNameStr):gLayer
	 			string panelNameStr = GetUserData(s.winName, "", "MXP_LinkedPanelStr")
	 			variable linePos = DimOffset(profile, 0) + glayer * DimDelta(profile, 0)
	 			DrawAction/W=$(panelNameStr+"#MXP_ZLineProfilesPlot") delete
	 			SetDrawEnv/W=$(panelNameStr+"#MXP_ZLineProfilesPlot") xcoord= bottom, ycoord= prel,linefgc = (65535,0,0) //It should be after the draw action
            	DrawLine/W=$(panelNameStr+"#MXP_ZLineProfilesPlot") linePos, 0, linePos, 1
	 		endif
	 		hookresult = 1
	 		break
    endswitch
    return hookResult       // If non-zero, we handled event and Igor will ignore it.
End


Function MXP_SaveZProfileButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "MXP_targetGraphWin")
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
	SVAR/Z w3dPathName = dfr:gMXP_w3dPathName
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	NVAR/Z DoPlotSwitch = dfr:gMXP_DoPlotSwitch
	NVAR/Z MarkAreasSwitch = dfr:gMXP_MarkAreasSwitch
	NVAR/Z colorcnt = dfr:gMXP_colorcnt
	
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom

	string recreateDrawStr
	DFREF savedfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:SavedZProfiles")
	
	variable postfix = 0
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			do
				string saveWaveNameStr = w3dNameStr + "_prof" + num2str(postfix) // deal here with liberal name
				//WAVE/Z waveRefToSave = $saveWaveNameStr // Some operation like Duplicate need a wref insted of a $("literalNameStr")
				if(WaveExists(savedfr:$saveWaveNameStr) == 1)
					postfix++
				else
					Duplicate dfr:$LineProfileWaveStr, savedfr:$saveWaveNameStr // here waveRef is needed instead of $saveWaveNameStr
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
						MXP_DrawImageROI(gMXP_left, gMXP_top, gMXP_right, gMXP_bottom, red, green, blue) // Draw on UserFront and return to ProgFront
					endif
				break // Stop if you go through the else branch
				endif
			while(1)
		sprintf recreateDrawStr, "pathName:%s;DrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= top, ycoord= left;" + \
								 "DrawCmd:DrawOval %f, %f, %f, %f", w3dPathName, red, green, blue, gMXP_left, gMXP_top, gMXP_right, gMXP_bottom
		Note savedfr:$saveWaveNameStr, recreateDrawStr
		return 1
		break
	endswitch
	return 0
End


Function MXP_ZProfilePanelCheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

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


Function MXP_ZProfilePanelCheckboxMarkAreas(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
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

// Alternative to MatrixOP in Window Hook function, currently (01.12.2022) disabled.
// ---------------------------------------------------------------------------------
//static Function/WAVE MXP_WAVESumOverBeamsMasked(Wave w3d, Wave wMask)
//	// No consistency checks here, we want to be fast and efficient
//	// as the function is called in the MXP_CursorHookFunctionBeamProfiler
//	Make/N=(DimSize(w3d,2))/FREE retWave = 0
//	variable nrows =DimSize(w3d, 0), i
//	variable ncols =DimSize(w3d, 1), j
//	for(i = 0; i < nrows; i++)
//		for(j = 0; j < ncols; j++)
//			if(wMask[i][j] > 0)
//				retWave += w3d[i][j][p]
//			endif
//		endfor
//	endfor
//	return retWave
//End
//
//
//static Function MXP_MakeWaveWithMaskCoordinates(DFREF dfr, WAVE wMask) // Not used 
//	// wMask should have 0 and 1 only, otherwise the wave dimensions of mxpBeamCoordinates will be wrong.
//	WaveStats/Q/M=1 wMask
//	variable ntot = V_Sum
//	Make/O/N=(ntot, 2) dfr:mxpBeamCoordinates	/WAVE=wRef
//	variable nrows =DimSize(wMask, 0), i
//	variable ncols =DimSize(wMask, 1), j
//	variable cnt = 0
//	for(i = 0; i < nrows; i++)
//		for(j = 0; j < ncols; j++)
//			if(wMask[i][j] > 0) 
//				wRef[cnt][0] = i // p
//				wRef[cnt][1] = j // q
//				cnt++
//			endif
//		endfor
//	endfor
//	if (cnt > ntot)
//		Abort "Check MXP_MakeWaveWithMaskCoordinates, critical error!"
//	endif
//End
//
//static Function/WAVE MXP_WAVESumBeamsFromWave(WAVE w3d, WAVE wROI) // Not used
//	Make/FREE/O/N=(DimSize(w3d,2)) waveProfile = 0
//	variable nrows =DimSize(wROI, 0), i //wROI: Make/O/N=(ntot, 2) dfr:mxpBeamCoordinates	/WAVE=wRef
//
//	for(i = 0; i < nrows; i++)
//		MatrixOP/O/FREE beamFree = beam(w3d, wROI[i][0], wROI[i][1])
//		waveProfile += beamFree
//	endfor
//	return waveProfile
//End
