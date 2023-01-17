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
		// Flush scales
		SetScale/P x, 0, 1, selectedWave
		SetScale/P y, 0, 1, selectedWave
		SetScale/P z, 0, 1, selectedWave	
		//DoWindow/F $winNameStr // bring it to FG to set the cursors
		variable nrows = DimSize(selectedWave,0)
		variable ncols = DimSize(selectedWave,1)
		Cursor/I/C=(65535,0,0,65535)/S=1/P G $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
		Cursor/I/C=(65535,0,0,65535)/S=1/P H $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
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
		//Flush scales
		SetScale/P x, 0, 1, imgWaveRef
		SetScale/P y, 0, 1, imgWaveRef
		SetScale/P z, 0, 1, imgWaveRef
		DoWindow/F $winNameStr // bring it to FG to set the cursors
		variable nrows = DimSize(imgWaveRef,0)
		variable ncols = DimSize(imgWaveRef,1)
		Cursor/I/C=(65535,0,0,65535)/S=1/P G $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
		Cursor/I/C=(65535,0,0,65535)/S=1/P H $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
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
			//Flush scales
			SetScale/P x, 0, 1, imgWaveRef
			SetScale/P y, 0, 1, imgWaveRef
			SetScale/P z, 0, 1, imgWaveRef
			DoWindow/F $winNameStr // bring it to FG to set the cursors
			variable nrows = DimSize(imgWaveRef,0)
			variable ncols = DimSize(imgWaveRef,1)
			Cursor/I/C=(65535,0,0,65535)/S=1/P G $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
			Cursor/I/C=(65535,0,0,65535)/S=1/P H $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
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
    
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + imgNameTopGraphStr) // Root folder here
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:DefaultSettings:") // Settings here

	variable nrows = DimSize(imgWaveRef, 0)
	variable ncols = DimSize(imgWaveRef, 1)

	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_ImagePathname = GetWavesDataFolder(imgWaveRef, 2)
	string/G dfr:gMXP_ImagePath = GetWavesDataFolder(imgWaveRef, 1)
	string/G dfr:gMXP_ImageNameStr = NameOfWave(imgWaveRef)
	variable/G dfr:gMXP_nLayers =  DimSize(imgWaveRef,2)
	variable/G dfr:gMXP_Nx = 100 // Startup value
	variable/G dfr:gMXP_Ny = DimSize(imgWaveRef,2)
	variable/G dfr:gMXP_C1x = round(0.9 * nrows/2)
	variable/G dfr:gMXP_C1y = round(1.1 * ncols/2)
	variable/G dfr:gMXP_C2x = round(1.1 * nrows/2)
	variable/G dfr:gMXP_C2y = round(0.9 * ncols/2)
	// Set scale
	variable/G dfr:gMXP_Ystart = 0
	variable/G dfr:gMXP_Yend = 0
	variable/G dfr:gMXP_XScale = 0
	variable/G dfr:gMXP_Xfactor = 1
	// Switches and indicators
	variable/G dfr:gMXP_PlotSwitch = 1
	variable/G dfr:gMXP_MarkLinesSwitch = 0
	variable/G dfr:gMXP_OverrideNxy = 0
	//Restore scale of original wave
	variable/G dfr:gMXP_Scale_x0 = DimOffset(imgWaveRef, 0)
	variable/G dfr:gMXP_Scale_dx = DimDelta(imgWaveRef, 0)
	variable/G dfr:gMXP_Scale_y0 = DimOffset(imgWaveRef, 1)
	variable/G dfr:gMXP_Scale_dy = DimDelta(imgWaveRef, 1)
	variable/G dfr:gMXP_Scale_z0 = DimOffset(imgWaveRef, 2)
	variable/G dfr:gMXP_Scale_dz = DimDelta(imgWaveRef, 2)	
	// Misc
	variable/G dfr:gMXP_colorcnt = 0
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
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z Nx = dfr:gMXP_Nx
	NVAR/Z Ny = dfr:gMXP_Ny
	NVAR/Z nLayers = dfr:gMXP_nLayers
	NVAR/Z PlotSwitch = dfr:gMXP_PlotSwitch
	NVAR/Z MarkLinesSwitch = dfr:gMXP_MarkLinesSwitch
	NVAR/Z OverrideNxy = dfr:gMXP_OverrideNxy
	string profilePlotStr = "MXP_ImagePlaneZProf_" + gMXP_WindowNameStr
	WAVE wRef = $gMXP_ImagePathname
	
	DFREF cdfr = GetDataFolderDFR()
	SetDataFolder dfr
	ImageTransform/X={ Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface wRef
	SetDataFolder cdfr 
	
	NewImage/G=1/K=1/N=$profilePlotStr dfr:M_ExtractedSurface
	ModifyGraph/W=$profilePlotStr width = 330, height = 470
	AutoPositionWindow/E/M=0/R=$gMXP_WindowNameStr
	
	SetWindow $profilePlotStr userdata(MXP_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePlotStr userdata(MXP_targetGraphWin) = "MXP_LineProf_" + gMXP_WindowNameStr 
	ControlBar 50	

	SetVariable setNx,pos={10,5},size={80,20.00},title="N\\Bx", fSize=14,fColor=(65535,0,0),value=Nx,limits={1,inf,1},proc=MXP_ImagePlaneProfileZSetVariableNx
	SetVariable setNy,pos={97,5},size={70,20.00},title="N\\By", fSize=14,fColor=(65535,0,0),value=Ny,limits={1,inf,1},proc=MXP_ImagePlaneProfileZSetVariableNy
	Button SetScaleButton,pos={175,6},size={70.00,20.00},title="Set Scale",valueColor=(1,12815,52428),help={"Scale X, Y coordinates. "+\
	"Place markers and press button. Then set X and Y scales as intervals (Xmin, Xmax)"},proc=MXP_ImagePlaneProfileZButtonSetScale
	Button SaveProfileButton,pos={252.00,6},size={90.00,20.00},title="Save Profile",valueColor=(1,12815,52428),help={"Save displayed image profile"},proc=MXP_ImagePlaneProfileZButtonSaveProfile
	CheckBox DisplayProfiles,pos={153,30.00},size={98.00,17.00},title="Display profiles",fSize=12,value=PlotSwitch,side=1,proc=MXP_ImagePlaneProfileZCheckboxPlotProfile
	CheckBox MarkLines,pos={269,30.00},size={86.00,17.00},title="Mark lines",fSize=12,value=MarkLinesSwitch,side=1,proc=MXP_ImagePlaneProfileZCheckboxMarkLines
	CheckBox OverrideNxy,pos={37,30.00},size={86.00,17.00},title="Override N\\Bx\M, N\\By",fSize=12,fColor=(65535,0,0),value=OverrideNxy,side=1,proc=MXP_ImagePlaneProfileZOverrideNxy
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
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	WAVE/Z w3dRef = $ImagePathname
	NVAR/Z nlayers = dfr:gMXP_nLayers 
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z Nx = dfr:gMXP_Nx
	NVAR/Z Ny = dfr:gMXP_Ny	
	NVAR/Z nLayers =  dfr:gMXP_nLayers
	NVAR/Z OverrideNxy = dfr:gMXP_OverrideNxy
	// Set scale
	NVAR/Z Xfactor = dfr:gMXP_Xfactor	
	NVAR/Z Ystart = dfr:gMXP_Ystart
	NVAR/Z Yend = dfr:gMXP_Yend
	variable normGHCursors = round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2))
	SetdataFolder dfr
	switch(s.eventCode)
		case 2: // Kill the window
			// Restore original wave scaling
			NVAR/SDFR=dfr gMXP_Scale_x0
			NVAR/SDFR=dfr gMXP_Scale_dx
			NVAR/SDFR=dfr gMXP_Scale_y0
			NVAR/SDFR=dfr gMXP_Scale_dy
			NVAR/SDFR=dfr gMXP_Scale_z0
			NVAR/SDFR=dfr gMXP_Scale_dz
			SetScale/P x, gMXP_Scale_x0, gMXP_Scale_dx, w3dRef
			SetScale/P y, gMXP_Scale_y0, gMXP_Scale_dy, w3dRef
			SetScale/P z, gMXP_Scale_z0, gMXP_Scale_dz, w3dRef
			// Kill window and folder
			KillWindow/Z $(GetUserData(s.winName, "", "MXP_LinkedPlotStr"))
			KillDataFolder/Z dfr
			hookresult = 1
			break
	    case 7: // cursor moved
			if(!cmpstr(s.cursorName, "G") || !cmpstr(s.cursorName, "H")) // It should work only with G, H you might have other cursors on the image
				SetDrawLayer ProgFront
			    DrawAction delete
	   			SetDrawEnv linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	   			C1x = hcsr(G)
				C1y = vcsr(G)
				C2x = hcsr(H) 
		       	C2y = vcsr(H)
		       	if(C1x == C2x && C1y == C2y) // Cursors G, H cannot overlap
		       		break
		       	endif	
		       	if(!OverrideNxy) // Do not override
		       		Nx = normGHCursors
		       		Ny = nLayers					
				endif
				DrawLine C1x, C1y, C2x, C2y
		       	ImageTransform/X={Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface w3dRef
		       	WAVE ww = M_ExtractedSurface
		       	if(OverrideNxy)
		       		SetScale/I x, 0, (normGHCursors * Xfactor), ww
		       	else
		      		SetScale/I x, 0, (Nx * Xfactor), ww
		       	endif
		     	
		       	SetScale/I y, Yend, Ystart, ww
				hookResult = 1
				break
			endif
			hookResult = 0    
			break
    endswitch
    SetdataFolder currdfr
    return hookResult       // 0 if nothing done, else 1
End

Function MXP_ImagePlaneProfileZButtonSaveProfile(STRUCT WMButtonAction &B_Struct): ButtonControl // Change using UniqueName for displaying

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "MXP_targetGraphWin")
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_ImageNameStr
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	Wave/SDFR=dfr M_ExtractedSurface  
	NVAR/Z PlotSwitch = dfr:gMXP_PlotSwitch
	NVAR/Z MarkLinesSwitch = dfr:gMXP_MarkLinesSwitch
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z Nx = dfr:gMXP_Nx
	NVAR/Z Ny = dfr:gMXP_Ny
	NVAR/Z nLayers =  dfr:gMXP_nLayers
	NVAR/Z colorcnt = dfr:gMXP_colorcnt
	string recreateCmdStr
	DFREF savedfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:SavedImagePlaneProfileZ")
	variable red, green, blue
	variable postfix = 0
	string saveImageStr
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			do
				string saveWaveNameStr = w3dNameStr + "_plane" + num2str(postfix)
				if(WaveExists(savedfr:$saveWaveNameStr) == 1)
					postfix++
				else
					Duplicate dfr:M_ExtractedSurface, savedfr:$saveWaveNameStr
					if(PlotSwitch)
						saveImageStr = targetGraphWin + num2str(postfix)
						NewImage/G=1/K=1/N=$saveImageStr savedfr:$saveWaveNameStr
						ModifyGraph/W=$saveImageStr width = 330, height = 470
						colorcnt += 1
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
		sprintf recreateCmdStr, "Cmd:ImageTransform/X={%d, %d, %d, %d, 0, %d, %d, 0, %d, "+\
		"%d, %d} extractSurface %s\nSource: %s",  Nx, Ny, C1x, C1y, C2x, C2y, C2x, C2y, nLayers, w3dNameStr, ImagePathname
		Note savedfr:$saveWaveNameStr, recreateCmdStr
		break
	endswitch
	return 0
End

Function MXP_ImagePlaneProfileZButtonSetScale(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrStr"))
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z Xfactor = dfr:gMXP_Xfactor
	NVAR/Z Ystart = dfr:gMXP_Ystart
	NVAR/Z Yend = dfr:gMXP_Yend
	variable Xstart_l, Xend_l, Ystart_l, Yend_l, Xscale
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			Prompt Xscale, "X-scale: set cursors and enter the calibrating value"
			Prompt Ystart_l, "Y start (top)"			
			Prompt Yend_l, "Y end (bottom)"
			DoPrompt "Set X, Y scale (All zeros remove scale)", Xscale, Ystart_l, Yend_l
			if(V_flag) // User cancelled
				return -1
			endif
			Ystart = Ystart_l
			Yend   = Yend_l
			Xfactor = Xscale / round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2))
		break
	endswitch
	return 0
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

Function MXP_ImagePlaneProfileZOverrideNxy(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrStr"))
	NVAR/Z OverrideNxy = dfr:gMXP_OverrideNxy
	switch(cb.checked)
		case 1:
			OverrideNxy = 1
			break
		case 0:
			OverrideNxy = 0
			break
	endswitch
	return 0
End

Function MXP_ImagePlaneProfileZSetVariableNx(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sv.win, "", "MXP_rootdfrStr"))
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z Nx = dfr:gMXP_Nx
	NVAR/Z Ny = dfr:gMXP_Ny
	NVAR/Z Ystart = dfr:gMXP_Ystart
	NVAR/Z Yend = dfr:gMXP_Yend
	NVAR/Z Xfactor = dfr:gMXP_Xfactor
	NVAR/Z nLayers =  dfr:gMXP_nLayers
	NVAR/Z OverrideNxy = dfr:gMXP_OverrideNxy
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	WAVE/Z w3dRef = $ImagePathname
	variable normGHCursors
	SetDataFolder dfr
	switch(sv.eventCode)
		case 6:
			if(OverrideNxy)
				Nx = sv.dval
				normGHCursors = round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2))
				ImageTransform/X={Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface w3dRef
				WAVE ww = M_ExtractedSurface
				SetScale/I x, 0, (normGHCursors * Xfactor), ww
				SetScale/I y, Yend, Ystart, ww
			else
		       	Nx = round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2))
		    endif
		break
		print "Nx in SetVariable", Nx
	endswitch
	SetDataFolder currdfr
	return 0
End

Function MXP_ImagePlaneProfileZSetVariableNy(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sv.win, "", "MXP_rootdfrStr"))
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z Nx = dfr:gMXP_Nx
	NVAR/Z Ny = dfr:gMXP_Ny
	NVAR/Z nLayers =  dfr:gMXP_nLayers
	NVAR/Z OverrideNxy = dfr:gMXP_OverrideNxy
	NVAR/Z Ystart = dfr:gMXP_Ystart
	NVAR/Z Yend = dfr:gMXP_Yend
	NVAR/Z Xfactor = dfr:gMXP_Xfactor
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	WAVE/Z w3dRef = $ImagePathname
	variable normGHCursors
	SetDataFolder dfr
	switch(sv.eventCode)
		case 6:
			if(OverrideNxy)
				Ny = sv.dval
				ImageTransform/X={Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface w3dRef
				WAVE ww = M_ExtractedSurface
				normGHCursors = round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2))
				SetScale/I y, Yend, Ystart, ww
				SetScale/I x, 0, (normGHCursors * Xfactor), ww
			else
		      	Ny = nLayers
		    endif	 
       	break
	endswitch
	SetDataFolder currdfr
	return 0
End

//static Function ExtractSurfaceDFR(DFREF tdfr, WAVE wRef, variable Nx, variable Ny, variable x0, variable y0, variable z0, variable x1, variable y1, variable z1,  variable x2, variable y2, variable z2)
//	DFREF cdfr = GetDataFolderDFR()
//	SetDataFolder tdfr
//	ImageTransform/X={Nx, Ny, x0, y0, z0, x1, y1, z1, x2, y2, z2} extractSurface wRef
//	SetDataFolder cdfr 
//End
