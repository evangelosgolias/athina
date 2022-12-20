#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late

// ------------------------------------------------------- //
// Developed by Evangelos Golias.
// Contact: evangelos.golias@gmail.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, IN CONNECTION WITH THE USE OF SOFTWARE.
// ------------------------------------------------------- //

/// Line profile is plotted from cursor G to H.
/// Program based on MXP_ImageLineProfile.

Function MXP_MainMenuLaunchImagePlaneProfileZ()

	// Create the modal data browser but do not display it
	CreateBrowser/M prompt="Select an image or image stack and press OK"
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
	Wave selectedWave = $browserSelection
	if(exists(browserSelection) && (WaveDims(selectedWave) == 3 || WaveDims(selectedWave) == 2)) // if it is a 3d wave
		MXP_DisplayImage(selectedWave)
		string winNameStr = WinName(0, 1, 1)
		string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
		MXP_InitialiseImagePlaneProfileZFolder()
		//DoWindow/F $winNameStr // bring it to FG to set the cursors
		variable nrows = DimSize(selectedWave,0)
		variable ncols = DimSize(selectedWave,1)
		Cursor/I/C=(65535,0,0)/S=1/P G $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
		Cursor/I/C=(65535,0,0)/S=1/P H $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + NameOfWave(selectedWave)) // Change root folder if you want
		MXP_InitialiseImagePlaneProfileZGraph(dfr)
		SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionImagePlaneProfileZ // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedPlotStr) = "MXP_ImagePlaneZProf_" + winNameStr // Name of the plot we will make, used to communicate the
		// name to the windows hook to kill the plot after completion
	else
		Abort "Line profile needs an image or image stack."
	endif
	return 0
End

Function MXP_TraceMenuLaunchImagePlaneProfileZ()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	if(WaveDims(imgWaveRef) == 2 || WaveDims(imgWaveRef) == 3) // if it is not a 1d wave
		KillWindow $winNameStr
		MXP_DisplayImage(imgWaveRef)
		winNameStr = WinName(0, 1, 1) // update it just in case
		MXP_InitialiseImagePlaneProfileZFolder()
		DoWindow/F $winNameStr // bring it to FG to set the cursors
		variable nrows = DimSize(imgWaveRef,0)
		variable ncols = DimSize(imgWaveRef,1)
		Cursor/I/C=(65535,0,0,65535)/S=1/P G $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
		Cursor/I/C=(65535,0,0,65535)/S=1/P H $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + NameOfWave(imgWaveRef)) // Change root folder if you want
		MXP_InitialiseImagePlaneProfileZGraph(dfr)
		SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionImagePlaneProfileZ // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedPlotStr) = "MXP_ImagePlaneZProf_" + winNameStr // Name of the plot we will make, used to communicate the
		// name to the windows hook to kill the plot after completion
	else
		Abort "Line profile needs an image or image stack."
	endif
	return 0
End

Function MXP_BrowserMenuLaunchImagePlaneProfileZ()

	if(MXP_CountSelectedWavesInDataBrowser() == 1) // If we selected a single wave
		string selectedImageStr = GetBrowserSelection(0)
		WAVE imgWaveRef = $selectedImageStr
		if(WaveDims(imgWaveRef) == 2 || WaveDims(imgWaveRef) == 3)
			MXP_DisplayImage(imgWaveRef)
			string winNameStr = WinName(0, 1, 1) // update it just in case
			string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
			MXP_InitialiseImagePlaneProfileZFolder()
			DoWindow/F $winNameStr // bring it to FG to set the cursors
			variable nrows = DimSize(imgWaveRef,0)
			variable ncols = DimSize(imgWaveRef,1)
			Cursor/I/C=(65535,0,0,65535)/S=1/P G $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
			Cursor/I/C=(65535,0,0,65535)/S=1/P H $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
			DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + NameOfWave(imgWaveRef)) // Change root folder if you want
			MXP_InitialiseImagePlaneProfileZGraph(dfr)
			SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionImagePlaneProfileZ // Set the hook
			SetWindow $winNameStr userdata(MXP_LinkedPlotStr) = "MXP_ImagePlaneZProf_" + winNameStr // Name of the plot we will make, used to communicate the
		// name to the windows hook to kill the plot after completion
		else
			Abort "Line profile operation needs an image or an image stack."
		endif
	else
		Abort "Please select only one wave."
	endif
	return 0
End

Function MXP_InitialiseImagePlaneProfileZFolder()
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here. Use the 3D wave in top window.

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

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
    
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + imgNameTopGraphStr) // Root folder here
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:DefaultSettings:") // Settings here

	variable nrows = DimSize(imgWaveRef,0)
	variable ncols = DimSize(imgWaveRef,1)

	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_ImagePathname = GetWavesDataFolder(imgWaveRef, 2)
	string/G dfr:gMXP_ImagePath = GetWavesDataFolder(imgWaveRef, 1)
	string/G dfr:gMXP_ImageNameStr = NameOfWave(imgWaveRef)
	variable/G dfr:gMXP_nLayers =  DimSize(imgWaveRef,2)
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
	variable/G dfr:gMXP_PlotSwitch = 0
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

Function MXP_InitialiseImagePlaneProfileZGraph(DFREF dfr)
	/// Here we will create the profile plot and graph and plot the profile
	string plotNameStr = "MXP_ImagePlaneZProf_" + GetDataFolder(0, dfr)
	if (WinType(plotNameStr) == 0) // line profile window is not displayed
		MXP_CreateImagePlaneProfileZ(dfr)
	else
		DoWindow/F $plotNameStr // if it is bring it to the FG
	endif
	return 0
End

Function MXP_CreateImagePlaneProfileZ(DFREF dfr)
	string rootFolderStr = GetDataFolder(1, dfr)
	DFREF dfr = MXP_CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/SDFR=dfr gMXP_WindowNameStr
	SVAR/SDFR=dfr gMXP_ImagePathname
	NVAR profileWidth = dfr:gMXP_profileWidth
	NVAR/Z nlayers = dfr:gMXP_nLayers 
	string profilePlotStr = "MXP_ImagePlaneZProf_" + gMXP_WindowNameStr
	WAVE wRef = $gMXP_ImagePathname	
	ExtractSurfaceDFR(dfr, wRef, 100, 8, 5, 5, 0, 10, 10, 0, 10, 10, 8)

	//variable distCM = ScreenResolution/72/2.54 // 1 cm
	NewImage/K=1/N=$profilePlotStr dfr:M_ExtractedSurface
	ModifyGraph/W=$profilePlotStr width = 330, height = 480 //TODO: Fix it
	AutoPositionWindow/E/M=0/R=$gMXP_WindowNameStr
	
	SetWindow $profilePlotStr userdata(MXP_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePlotStr userdata(MXP_targetGraphWin) = "MXP_LineProf_" + gMXP_WindowNameStr 
	ControlBar 70	
	Button SaveProfileButton,pos={18.00,8.00},size={90.00,20.00},title="Save Profile",valueColor=(1,12815,52428),help={"Save displayed profile"},proc=MXP_ImagePlaneProfileZSaveProfile
//	Button SaveCursorPositions,pos={118.00,8.00},size={95.00,20.00},title="Save settings",valueColor=(1,12815,52428),help={"Save cursor positions and profile wifth as defaults"},proc=MXP_ImagePlaneProfileZSaveDefaultSettings
//	Button RestoreCursorPositions,pos={224.00,8.00},size={111.00,20.00},valueColor=(1,12815,52428),title="Restore settings",help={"Restore default cursor positions and line width"},proc=MXP_ImagePlaneProfileZRestoreDefaultSettings
	CheckBox DisplayProfiles,pos={19.00,41.00},size={98.00,17.00},title="Display",fSize=14,value=0,side=1,proc=MXP_ImagePlaneProfileZCheckboxPlotProfile
	CheckBox MarkLines,pos={90,41.00},size={86.00,17.00},title="Mark ",fSize=14,value=0,side=1,proc=MXP_ImagePlaneProfileZCheckboxMarkLines
	Button EDCProfile,pos={146,40.00},size={60,20.00},title="EDC",valueColor=(1,12815,52428),help={"Save cursor positions and profile wifth as defaults"},proc=MXP_ImagePlaneProfileZSaveDefaultSettings
	Button MDCProfile,pos={213.00,40.00},size={60.00,20.00},valueColor=(1,12815,52428),title="MDC",help={"Restore default cursor positions and line width"},proc=MXP_ImagePlaneProfileZRestoreDefaultSettings
	SetVariable setWidth,pos={280,40.00},size={60,20.00},title="W", fSize=14,fColor=(65535,0,0),value=profileWidth,limits={0,inf,1},proc=MXP_ImagePlaneProfileZSetVariableWidth
	return 0
End

// MXP_ClearLineMarkings & MXP_DrawLineUserFront called from MXP_ImageLineProfile.ipf

Function MXP_CursorHookFunctionImagePlaneProfileZ(STRUCT WMWinHookStruct &s)
	/// Window hook function
	/// The line profile is drawn from G to H
    variable hookResult = 0
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + imgNameTopGraphStr) // imgNameTopGraphStr will have '' if needed.
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:DefaultSettings") // Settings here
	DFREF savedfr = root:Packages:MXP_DataFolder:ImagePlaneProfileZ:SavedImagePlaneProfileZ // Hard coded
	SetdataFolder dfr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	SVAR/Z ImagePath = dfr:gMXP_ImagePath
	SVAR/Z ImageNameStr = dfr:gMXP_ImageNameStr
	WAVE/Z w3dRef = $ImagePathname
//	NVAR/Z dx = dfr:gMXP_dx
//	NVAR/Z dy = dfr:gMXP_dy
	NVAR/Z nlayers = dfr:gMXP_nLayers 
//	NVAR/Z C1x = dfr:gMXP_C1x
//	NVAR/Z C1y = dfr:gMXP_C1y
//	NVAR/Z C2x = dfr:gMXP_C2x
//	NVAR/Z C2y = dfr:gMXP_C2y
//	NVAR/Z profileWidth = dfr:gMXP_profileWidth
//	NVAR/Z selectedLayer = dfr:gMXP_selectedLayer
//	NVAR/Z updateCursorsPositions = dfr:gMXP_updateCursorsPositions
//	NVAR/Z C1x0 = dfr0:gMXP_C1x0
//	NVAR/Z C1y0 = dfr0:gMXP_C1y0
//	NVAR/Z C2x0 = dfr0:gMXP_C2x0
//	NVAR/Z C2y0 = dfr0:gMXP_C2y0
	WAVE/Z imgWaveRef = $ImagePathname
	variable xc, yc, xcp, ycp
	variable nrNxPoints
	switch(s.eventCode)
//		case 0: // Use activation to update the cursors if you request defaults
//			if(updateCursorsPositions)
//				SetDrawLayer ProgFront
//			    DrawAction delete
//	   			SetDrawEnv linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
//				Cursor/I/C=(65535,0,0,30000)/S=1 G $imgNameTopGraphStr C1x0, C1y0
//				Cursor/I/C=(65535,0,0,30000)/S=1 H $imgNameTopGraphStr C2x0, C2y0
//				DrawLine C1x0, C1y0, C2x0, C2y0
//       			ImageTransform/X={nrNxPoints, nlayers, C1x0, C1y0, 0, C2x0, C2y0, 0, C2x0, C2y0, nlayers} extractSurface w3dRef
//				updateCursorsPositions = 0
//			endif
//			break
		case 2: // Kill the window
			KillWindow/Z $(GetUserData(s.winName, "", "MXP_LinkedPlotStr"))
			KillDataFolder/Z dfr
			hookresult = 1
			break
//       	case 5: // mouse up
//       		C1x = hcsr(G) 
//       		C1y = vcsr(G)
//       		C2x = hcsr(H)
//       		C2y = vcsr(H)
//       		hookResult = 1
//			break
	    case 7: // cursor moved
			if(!cmpstr(s.cursorName, "G") || !cmpstr(s.cursorName, "H")) // It should work only with G, H you might have other pointers on the image
				SetDrawLayer ProgFront
			    DrawAction delete
	   			SetDrawEnv linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	   			xc = hcsr(G)
				yc = vcsr(G)
				xcp = hcsr(H) 
		       	ycp = vcsr(H)
		       	nrNxPoints = round(sqrt((xc - xcp)^2 + (yc - ycp)^2))
       			DrawLine xcp, ycp, xc, yc
       			ImageTransform/X={nrNxPoints, 300, xc, yc, 0, xcp, ycp, 0, xcp, ycp, nlayers} extractSurface w3dRef
				hookResult = 1
				break
			endif
			hookResult = 0	    
			break
    endswitch
    SetdataFolder currdfr
    return hookResult       // 0 if nothing done, else 1
End

Function MXP_ImagePlaneProfileZSaveProfile(STRUCT WMButtonAction &B_Struct): ButtonControl // Change using UniqueName for displaying

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "MXP_targetGraphWin")
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_ImageNameStr
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	Wave/SDFR=dfr M_ExtractedSurface  
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
	DFREF savedfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:SavedImagePlaneProfileZ")
	
	variable postfix = 0
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			do
				string saveWaveNameStr = w3dNameStr + "_plane" + num2str(postfix)
				if(WaveExists(savedfr:$saveWaveNameStr) == 1)
					postfix++
				else
					Duplicate dfr:M_ExtractedSurface, savedfr:$saveWaveNameStr
					//variable xRange = W_LineProfileDisplacement [DimSize(W_ImageLineProfile,0)-1] - W_ImageLineProfile[0]
					//SetScale/I x, 0, xRange, savedfr:$saveWaveNameStr
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
								 "DrawCmd:DrawLine %f, %f, %f, %f;ProfileCmd:Make/O/N=2 xTrace={%f, %f}, yTrace = {%f, %f}\nImageImagePlaneProfileZ/P=(%d) srcWave=%s," +\
								 "xWave=xTrace, yWave=yTrace, width = %f\nDisplay/K=1 W_ImageImagePlaneProfileZ vs W_ImagePlaneProfileZDisplacement" + \
								 "", ImagePathname, red, green, blue, C1x, C1y, C2x, C2y, C1x, C2x, C1y, C2y, selectedLayer, ImagePathname, profileWidth
		Note savedfr:$saveWaveNameStr, recreateDrawStr
		break
	endswitch
	return 0
End

Function MXP_ImagePlaneProfileZSaveDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:DefaultSettings") // Settings here
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

Function MXP_ImagePlaneProfileZRestoreDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:DefaultSettings") // Settings here
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

Function MXP_ImagePlaneProfileZShowProfileWidth(STRUCT WMButtonAction &B_Struct): ButtonControl
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
	variable slope = SlopePerpendicularToLineSegment(C1x, C2x, C1y, C2y)
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
		[xs, ys] = GetVerticesPerpendicularToLine(width * dx/2, slope)
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

Function MXP_ImagePlaneProfileZCheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

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

Function MXP_ImagePlaneProfileZProfileLayer3D(STRUCT WMCheckboxAction& cb) : CheckBoxControl
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

Function MXP_ImagePlaneProfileZCheckboxMarkLines(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
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

Function MXP_ImagePlaneProfileZSetVariableWidth(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
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

static Function ExtractSurfaceDFR(DFREF tdfr, WAVE wRef, variable Nx, variable Ny, variable x0, variable y0, variable z0, variable x1, variable y1, variable z1,  variable x2, variable y2, variable z2)
	DFREF cdfr = GetDataFolderDFR()
	SetDataFolder tdfr
	ImageTransform/X={Nx, Ny, x0, y0, z0, x1, y1, z1, x2, y2, z2} extractSurface wRef
	SetDataFolder cdfr 
End

static Function PreviousOddNumPositiveEven(variable num)
	// return a negative number when num < 0
	// accepts decimals and uses rounding to closest integer
	num = round(num)
	num = num > 0 && !mod(num, 2)? num-1: num
	return num
end

static Function SlopePerpendicularToLineSegment(variable x1, variable x2, variable y1, variable y2)
	// Return the slope of a line perpendicular to the line segment defined by (x1, y1) and (x2, y2)
	if (y1 == y2)
		return 0
	elseif (x1 == x2)
		return inf
	else
		return -(x2 - x1)/(y2 - y1)
	endif
End

static Function [variable xshift, variable yshift] GetVerticesPerpendicularToLine(variable radius, variable slope)
	// Return the part of the solution of an intersection between a circly of radius = radius
	// with a line with slope = slope. If the center has coordinates (x0, y0) the two point that
	// the line intersects the cicle have x =  x0 ± sqrt(radius^2 / (1 + slope^2)) and 
	// y = slope * sqrt(radius^2 / (1 + slope^2)). 
	// The funtion returns only the second terms.
	 xshift = sqrt(radius^2 / (1 + slope^2))
	 yshift = slope * sqrt(radius^2 / (1 + slope^2))
	 return [xshift, yshift]
End