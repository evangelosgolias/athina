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

/// Line profile is plotted from cursor G to H.
/// Program based on MXP_ImageLineProfile.
/// N.B: *Works with default wave scaling.*
///
// TODO: Add averaging over a px width when you change Nx, Ny
// without the need to move the cursors
// Improvement(?): Make it work with scaled 3D wave. You need to check 
// ImageLineProfile.ipf and change here accordingly.
/// 
/// 29032023
/// We changed the save directory to the current working directory
/// DFREF savedfr = GetDataFolderDFR() //MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:SavedLineProfiles")



Function MXP_MainMenuLaunchImagePlaneProfileZ()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")

	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph."
		return -1
	endif
	
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string LinkedPlotStr = GetUserData(winNameStr, "", "MXP_LinkedImagePlaneProfileZPlotStr")
	if(strlen(LinkedPlotStr))
		DoWindow/F LinkedPlotStr
		return 0
	endif
	
	// User selected a wave, check if it's 3d
	if(WaveDims(w3dRef) == 3) // if it is a 3d wave
		MXP_InitialiseImagePlaneProfileZFolder()
		// Flush scales
		SetScale/P x, 0, 1, w3dRef
		SetScale/P y, 0, 1, w3dRef
		SetScale/P z, 0, 1, w3dRef	
		variable nrows = DimSize(w3dRef,0)
		variable ncols = DimSize(w3dRef,1)
		Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 G $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
		Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 H $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + NameOfWave(w3dRef)) // Change root folder if you want
		MXP_InitialiseImagePlaneProfileZGraph(dfr)
		SetWindow $winNameStr, hook(MyImagePlaneProfileZHook) = MXP_CursorHookFunctionImagePlaneProfileZ // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedImagePlaneProfileZPlotStr) = "MXP_ImagePlaneZProf_" + winNameStr // Name of the plot we will make, used to communicate the
		// name to the windows hook to kill the plot after completion
	else
		Abort "Plane profile operation needs a stack."
	endif
	return 0
End

Function MXP_TraceMenuLaunchImagePlaneProfileZ()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	if(WaveDims(imgWaveRef) == 3) // if it is not a 1d wave
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
		Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 G $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
		Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 H $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + NameOfWave(imgWaveRef)) // Change root folder if you want
		MXP_InitialiseImagePlaneProfileZGraph(dfr)
		SetWindow $winNameStr, hook(MyImagePlaneProfileZHook) = MXP_CursorHookFunctionImagePlaneProfileZ // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedImagePlaneProfileZPlotStr) = "MXP_ImagePlaneZProf_" + winNameStr // Name of the plot we will make, used to communicate the
		// name to the windows hook to kill the plot after completion
	else
		Abort "Plane profile operation needs a stack."
	endif
	return 0
End

Function MXP_BrowserMenuLaunchImagePlaneProfileZ()

	if(MXP_CountSelectedWavesInDataBrowser() == 1) // If we selected a single wave
		string selectedImageStr = GetBrowserSelection(0)
		WAVE imgWaveRef = $selectedImageStr
		if(WaveDims(imgWaveRef) == 3)
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
			Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 G $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
			Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 H $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
			DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + NameOfWave(imgWaveRef)) // Change root folder if you want
			MXP_InitialiseImagePlaneProfileZGraph(dfr)
			SetWindow $winNameStr, hook(MyImagePlaneProfileZHook) = MXP_CursorHookFunctionImagePlaneProfileZ // Set the hook
			SetWindow $winNameStr userdata(MXP_LinkedImagePlaneProfileZPlotStr) = "MXP_ImagePlaneZProf_" + winNameStr // Name of the plot we will make, used to communicate the
		// name to the windows hook to kill the plot after completion
		else
			Abort "Plane profile operation needs a stack."
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
		sprintf msg, "Plane profile operation needs a stack.  Wave %s is in top window", imgNameTopGraphStr
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
	variable/G dfr:gMXP_OverrideNx = 0
	variable/G dfr:gMXP_OverrideNy = 0
	// Profile width
	variable/G dfr:gMXP_profileWidth = 1
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
	NVAR/Z OverrideNx = dfr:gMXP_OverrideNx
	NVAR/Z OverrideNy = dfr:gMXP_OverrideNy
	NVAR/Z profileWidth = dfr:gMXP_profileWidth	
	string profilePlotStr = "MXP_ImagePlaneZProf_" + gMXP_WindowNameStr
	WAVE wRef = $gMXP_ImagePathname
	
	DFREF cdfr = GetDataFolderDFR()
	SetDataFolder dfr
	ImageTransform/X={ Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface wRef
	SetDataFolder cdfr 
	variable pix = 72/ScreenResolution
	NewImage/F/G=1/K=1/N=$profilePlotStr dfr:M_ExtractedSurface // Flip image (/F) to get higher Ek
	ModifyGraph/W=$profilePlotStr width = 340 * pix, height = 470 * pix

	ControlBar/W=$profilePlotStr 50	
	AutoPositionWindow/E/M=0/R=$gMXP_WindowNameStr
		
	SetWindow $profilePlotStr userdata(MXP_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePlotStr userdata(MXP_targetGraphWin) = "MXP_ImagePlaneProfileZ_" + gMXP_WindowNameStr 
	SetWindow $profilePlotStr userdata(MXP_parentGraphWin) = gMXP_WindowNameStr 	
	SetWindow $profilePlotStr, hook(MyImagePlaneProfileZHook) = MXP_ImagePlaneProfileZGraphHookFunction // Set the hook

	SetVariable setNx,pos={10,5},size={85,20.00},title="N\\Bx", fSize=14,fColor=(65535,0,0),value=Nx,limits={1,inf,1},proc=MXP_ImagePlaneProfileZSetVariableNx
	SetVariable setNy,pos={97,5},size={70,20.00},title="N\\By", fSize=14,fColor=(65535,0,0),value=Ny,limits={1,inf,1},proc=MXP_ImagePlaneProfileZSetVariableNy
	SetVariable profileWidth,pos={135,30.00},size={105,30.00},title="Width (px)", fSize=12,fColor=(65535,0,0),value=profileWidth,limits={1,51,1},proc=MXP_ImagePlaneProfileZSetVariableProfileWidth

	Button SetScaleButton,pos={180,6},size={70.00,20.00},title="Set Scale",valueColor=(1,12815,52428),help={"Scale X, Y coordinates. "+\
	"Place markers and press button. Then set X and Y scales as intervals (Xmin, Xmax)"},proc=MXP_ImagePlaneProfileZButtonSetScale
	Button SaveProfileButton,pos={260.00,6},size={90.00,20.00},title="Save Profile",valueColor=(1,12815,52428),help={"Save displayed image profile"},proc=MXP_ImagePlaneProfileZButtonSaveProfile
	CheckBox DisplayProfiles,pos={250,30.0},size={98.00,17.00},title="Display profiles",fSize=12,value=PlotSwitch,side=1,proc=MXP_ImagePlaneProfileZCheckboxPlotProfile
	CheckBox OverrideNx,pos={8,30.00},size={86.00,17.00},title="Override N\\Bx",fSize=12,fColor=(65535,0,0),value=OverrideNx,side=1,proc=MXP_ImagePlaneProfileZOverrideNx
	CheckBox OverrideNy,pos={100,30.00},size={86.00,17.00},title="N\\By",fSize=12,fColor=(65535,0,0),value=OverrideNy,side=1,proc=MXP_ImagePlaneProfileZOverrideNy
	
	return 0
End

// MXP_ClearLineMarkings & MXP_DrawLineUserFront called from MXP_ImageLineProfile.ipf

Function MXP_CursorHookFunctionImagePlaneProfileZ(STRUCT WMWinHookStruct &s)
	/// Window hook function
	/// The line profile is drawn from G to H
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:" + imgNameTopGraphStr) // imgNameTopGraphStr will have '' if needed.
	DFREF dfr0 = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:DefaultSettings") // Settings here
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
	NVAR/Z OverrideNx = dfr:gMXP_OverrideNx
	NVAR/Z OverrideNy = dfr:gMXP_OverrideNy
	// Set scale
	NVAR/Z Xfactor = dfr:gMXP_Xfactor	
	NVAR/Z Ystart = dfr:gMXP_Ystart
	NVAR/Z Yend = dfr:gMXP_Yend
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	variable normGHCursors
	variable x1, x2, x3, x4, y1, y2, y3, y4, xs, ys, slp, i
	variable makeWaveSwitch = 1
	variable hookResult = 0
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
			KillWindow/Z $(GetUserData(s.winName, "", "MXP_LinkedImagePlaneProfileZPlotStr"))
			KillDataFolder/Z dfr
			hookresult = 1
			break
		case 7:
			if(!cmpstr(s.cursorName, "G") || !cmpstr(s.cursorName, "H")) // It should work only with G, H you might have other cursors on the image
				SetDrawLayer ProgFront
			    DrawAction delete
	   			SetDrawEnv linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	   			C1x = hcsr(G)
				C1y = vcsr(G)
				C2x = hcsr(H) 
		       	C2y = vcsr(H)
		       	DrawLine C1x, C1y, C2x, C2y
		       	if(C1x == C2x && C1y == C2y) // Cursors G, H cannot overlap
		       		break
		       	endif
		    endif
		    	WAVE/Z M_ExtractedSurface, MXP_WaveSumProfiles
			if(profileWidth == 1)
				ImageTransform/X={Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface w3dRef
			else
				slp = MXP_SlopePerpendicularToLineSegment(C1x, C1y, C2x, C2y)
				if(slp == 0)
					for(i = -(profileWidth/2 -0.5);i < profileWidth/2;i++)
						x1 = C1x
						x2 = C2x
						y1 = C1y + i // assume dx = dy = 1
						y2 = C2y + i
						ImageTransform/X={Nx, Ny, x1, y1, 0, x2, y2, 0, x2, y2, nLayers} extractSurface w3dRef
						if(makeWaveSwitch)
							Duplicate/O M_ExtractedSurface, MXP_WaveSumProfiles
							makeWaveSwitch = 0
						else
							MXP_WaveSumProfiles += M_ExtractedSurface
						endif
					endfor
					MXP_WaveSumProfiles /= profileWidth
				endif
						
				if(slp == inf)
					for(i = -(profileWidth/2 -0.5);i < profileWidth/2;i++)
						x1 = C1x + i // assume dx = dy = 1
						x2 = C2x + i
						y1 = C1y
						y2 = C2y
						ImageTransform/X={Nx, Ny, x1, y1, 0, x2, y2, 0, x2, y2, nLayers} extractSurface w3dRef
						if(makeWaveSwitch)
							Duplicate/O M_ExtractedSurface, MXP_WaveSumProfiles
							makeWaveSwitch = 0
						else
							MXP_WaveSumProfiles += M_ExtractedSurface
						endif
					endfor
					MXP_WaveSumProfiles /= profileWidth
				endif
				
				// If s is not 0 or inf do the work here	
				if(slp != 0 && slp != inf)			
					for(i = -(profileWidth/2 -0.5);i < profileWidth/2;i++)
						[x1, y1] = MXP_GetSinglePointWithDistanceFromLine(C1x, C1y, slp, i)
						[x2, y2] = MXP_GetSinglePointWithDistanceFromLine(C2x, C2y, slp, i)
						ImageTransform/X={Nx, Ny, x1, y1, 0, x2, y2, 0, x2, y2, nLayers} extractSurface w3dRef
						if(makeWaveSwitch)
							Duplicate/O M_ExtractedSurface, MXP_WaveSumProfiles
							makeWaveSwitch = 0
						else
							MXP_WaveSumProfiles += M_ExtractedSurface
						endif
						// Debug
						// print x1,y1,x2,y2, "(",C1x, C1y, C2x, C2y,")", "√ ",sqrt((C1x-x1)^2 + (C1y-y1)^2), " | ", sqrt((C2x-x2)^2 + (C2y-y2)^2)
						// print "Slope: ", slp, "Calc: ", (y2-y1)/(x2-x1), " x", slp * (y2-y1)/(x2-x1)
						// print i, ":", (y2-y1)/(x2-x1)
					endfor
				endif
				MXP_WaveSumProfiles /= profileWidth
				Duplicate/O MXP_WaveSumProfiles, M_ExtractedSurface
			endif

			normGHCursors = round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2))
		    if(!OverrideNx) // Do not override
		   		Nx = normGHCursors	
			endif
	       	if(!OverrideNy) // Do not override
		      	Ny = nLayers					
			endif				
		    if(OverrideNx)
		       	SetScale/I x, 0, (normGHCursors * Xfactor), M_ExtractedSurface
		    else
		      	SetScale/I x, 0, (Nx * Xfactor), M_ExtractedSurface
		    endif		    
		    SetScale/I y, Yend, Ystart, M_ExtractedSurface
		    SetDrawLayer UserFront
			hookResult = 1
		break
		case 5:
			SetDrawLayer ProgFront
			DrawAction delete
	   		SetDrawEnv linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left			
			DrawLine C1x, C1y, C2x, C2y
			slp = MXP_SlopePerpendicularToLineSegment(C1x, C1y, C2x, C2y)
			if(slp == 0)
				x1 = C1x
				x2 = C1x
				x3 = C2x
				x4 = C2x
				y1 = C1y + 0.5 * profileWidth
				y2 = C1y - 0.5 * profileWidth
				y3 = C2y - 0.5 * profileWidth
				y4 = C2y + 0.5 * profileWidth 
			elseif(slp == inf)
			print "inf"
				y1 = C1y
				y2 = C1y
				y3 = C2y
				y4 = C2y
				x1 = C1x + 0.5 * profileWidth
				x2 = C1x - 0.5 * profileWidth
				x3 = C2x - 0.5 * profileWidth
				x4 = C2x + 0.5 * profileWidth
			else
				[xs, ys] = MXP_GetVerticesPerpendicularToLine(profileWidth * 0.5, slp)
				x1 = C1x + xs
				x2 = C1x - xs
				x3 = C2x - xs
				x4 = C2x + xs
				y1 = C1y + ys
				y2 = C1y - ys
				y3 = C2y - ys
				y4 = C2y + ys
			endif
			SetDrawEnv gstart, gname=lineProfileWidth
			SetDrawEnv linefgc = (65535,16385,16385,32767), fillbgc= (65535,16385,16385,32767), fillpat = -1, linethick = 0, xcoord = top, ycoord = left
			DrawPoly x1, y1, 1, 1, {x1, y1, x2, y2, x3, y3, x4, y4}
			SetDrawEnv gstop
			SetDrawLayer UserFront
			hookResult = 1
		break		
	endswitch
    SetdataFolder currdfr
    return hookResult       // 0 if nothing done, else 1
End

Function MXP_ImagePlaneProfileZGraphHookFunction(STRUCT WMWinHookStruct &s)
	string parentGraphWin = GetUserData(s.winName, "", "MXP_parentGraphWin")
	switch(s.eventCode)
		case 2: // Kill the window
			// parentGraphWin -- winNameStr
			// Kill the MyLineProfileHook
			SetWindow $parentGraphWin, hook(MyImagePlaneProfileZHook) = $""
			// We need to reset the link between parentGraphwin (winNameStr) and MXP_LinkedLineProfilePlotStr
			// see MXP_MainMenuLaunchLineProfile() when we test if with strlen(LinkedPlotStr)
			SetWindow $parentGraphWin userdata(MXP_LinkedImagePlaneProfileZPlotStr) = ""
			Cursor/W=$parentGraphWin/K G
			Cursor/W=$parentGraphWin/K H			
			SetDrawLayer/W=$parentGraphWin ProgFront
			DrawAction/W=$parentGraphWin delete
			break
	endswitch
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
	DFREF savedfr = GetDataFolderDFR()//MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ImagePlaneProfileZ:SavedImagePlaneProfileZ")
	variable red, green, blue
	variable postfix = 0
	string saveImageStr
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			do
				string saveWaveNameStr = w3dNameStr + num2str(postfix)
				if(WaveExists(savedfr:$saveWaveNameStr) == 1)
					postfix++
				else
					Duplicate dfr:M_ExtractedSurface, savedfr:$saveWaveNameStr
					if(PlotSwitch)
						saveImageStr = targetGraphWin + "_s" + num2str(postfix)
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
			Prompt Ystart_l, "Y_top [if Y_top > Y_bottom flip the left axis!]"			
			Prompt Yend_l, "Y_bottom"
			DoPrompt "Set X, Y scale (Zero removes scale)", Xscale, Ystart_l, Yend_l
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

Function MXP_ImagePlaneProfileZOverrideNx(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrStr"))
	NVAR/Z OverrideNx = dfr:gMXP_OverrideNx
	switch(cb.checked)
		case 1:
			OverrideNx = 1
			break
		case 0:
			OverrideNx = 0
			break
	endswitch
	return 0
End

Function MXP_ImagePlaneProfileZOverrideNy(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrStr"))
	NVAR/Z OverrideNy = dfr:gMXP_OverrideNy
	switch(cb.checked)
		case 1:
			OverrideNy = 1
			break
		case 0:
			OverrideNy = 0
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
	NVAR/Z OverrideNx = dfr:gMXP_OverrideNx
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	WAVE/Z w3dRef = $ImagePathname
	variable normGHCursors
	SetDataFolder dfr
	switch(sv.eventCode)
		case 6:
			if(OverrideNx)
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
	NVAR/Z OverrideNy = dfr:gMXP_OverrideNy	
	NVAR/Z Ystart = dfr:gMXP_Ystart
	NVAR/Z Yend = dfr:gMXP_Yend
	NVAR/Z Xfactor = dfr:gMXP_Xfactor
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	WAVE/Z w3dRef = $ImagePathname
	variable normGHCursors
	SetDataFolder dfr
	switch(sv.eventCode)
		case 6:
			if(OverrideNy)
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

Function MXP_ImagePlaneProfileZSetVariableProfileWidth(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sv.win, "", "MXP_rootdfrStr"))
	NVAR/Z C1x = dfr:gMXP_C1x
	NVAR/Z C1y = dfr:gMXP_C1y
	NVAR/Z C2x = dfr:gMXP_C2x
	NVAR/Z C2y = dfr:gMXP_C2y
	NVAR/Z Nx = dfr:gMXP_Nx
	NVAR/Z Ny = dfr:gMXP_Ny
	NVAR/Z nLayers =  dfr:gMXP_nLayers
	NVAR/Z Ystart = dfr:gMXP_Ystart
	NVAR/Z Yend = dfr:gMXP_Yend
	NVAR/Z Xfactor = dfr:gMXP_Xfactor
	NVAR/Z profileWidth = dfr:gMXP_profileWidth
	SVAR/Z ImagePathname = dfr:gMXP_ImagePathname
	SVAR/Z WindowsNameStr = dfr:gMXP_WindowNameStr
	WAVE/Z w3dRef = $ImagePathname
	variable x1, x2, x3, x4, y1, y2, y3, y4, xs, ys,slp, i
	
	variable makeWaveSwitch = 1

	SetDataFolder dfr
	WAVE/Z M_ExtractedSurface
	switch(sv.eventCode)
		case 6:
			profileWidth = sv.dval
			if(profileWidth == 1)
				ImageTransform/X={Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface w3dRef
			else
				slp = MXP_SlopePerpendicularToLineSegment(C1x, C1y, C2x, C2y)
				if(slp == 0)
					for(i = -(profileWidth/2 -0.5);i < profileWidth/2;i++)
						x1 = C1x
						x2 = C2x
						y1 = C1y + i // assume dx = dy = 1
						y2 = C2y + i
						ImageTransform/X={Nx, Ny, x1, y1, 0, x2, y2, 0, x2, y2, nLayers} extractSurface w3dRef
						if(makeWaveSwitch)
							Duplicate/O M_ExtractedSurface, MXP_WaveSumProfiles
							makeWaveSwitch = 0
						else
							MXP_WaveSumProfiles += M_ExtractedSurface
						endif
					endfor
					MXP_WaveSumProfiles /= profileWidth
				endif				
				if(slp == inf)
					for(i = -(profileWidth/2 -0.5);i < profileWidth/2;i++)
						y1 = C1y
						y2 = C2y
						x1 = C1x + i // assume dx = dy = 1
						x2 = C2x + i
						ImageTransform/X={Nx, Ny, x1, y1, 0, x2, y2, 0, x2, y2, nLayers} extractSurface w3dRef
						if(makeWaveSwitch)
							Duplicate/O M_ExtractedSurface, MXP_WaveSumProfiles
							makeWaveSwitch = 0
						else
							MXP_WaveSumProfiles += M_ExtractedSurface
						endif
					endfor
					MXP_WaveSumProfiles /= profileWidth
				endif
				
				// If s is not 0 or inf do the work here	
				if(slp != 0 && slp != inf)			
					for(i = -(profileWidth/2 -0.5);i < profileWidth/2;i++)
						[x1, y1] = MXP_GetSinglePointWithDistanceFromLine(C1x, C1y, slp, i)
						[x2, y2] = MXP_GetSinglePointWithDistanceFromLine(C2x, C2y, slp, i)
						ImageTransform/X={Nx, Ny, x1, y1, 0, x2, y2, 0, x2, y2, nLayers} extractSurface w3dRef
						if(makeWaveSwitch)
							Duplicate/O M_ExtractedSurface, MXP_WaveSumProfiles
							makeWaveSwitch = 0
						else
							MXP_WaveSumProfiles += M_ExtractedSurface
						endif
					endfor
				endif
				MXP_WaveSumProfiles /= profileWidth
				Duplicate/O MXP_WaveSumProfiles, M_ExtractedSurface
				//KillWaves/Z waveSumProfiles
			endif
			SetDrawLayer/W=$WindowsNameStr ProgFront
			DrawAction/W=$WindowsNameStr delete
	   		SetDrawEnv/W=$WindowsNameStr linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left			
			DrawLine/W=$WindowsNameStr C1x, C1y, C2x, C2y
			slp = MXP_SlopePerpendicularToLineSegment(C1x, C1y, C2x, C2y)
			if(slp == 0)
				x1 = C1x
				x2 = C1x
				x3 = C2x
				x4 = C2x
				y1 = C1y + 0.5 * profileWidth
				y2 = C1y - 0.5 * profileWidth
				y3 = C2y - 0.5 * profileWidth
				y4 = C2y + 0.5 * profileWidth 
			elseif(slp == inf)
			print "inf"
				y1 = C1y
				y2 = C1y
				y3 = C2y
				y4 = C2y
				x1 = C1x + 0.5 * profileWidth
				x2 = C1x - 0.5 * profileWidth
				x3 = C2x - 0.5 * profileWidth
				x4 = C2x + 0.5 * profileWidth
			else
				[xs, ys] = MXP_GetVerticesPerpendicularToLine(profileWidth * 0.5, slp)
				x1 = C1x + xs
				x2 = C1x - xs
				x3 = C2x - xs
				x4 = C2x + xs
				y1 = C1y + ys
				y2 = C1y - ys
				y3 = C2y - ys
				y4 = C2y + ys
			endif
			SetDrawEnv/W=$WindowsNameStr gstart, gname=lineProfileWidth
			SetDrawEnv/W=$WindowsNameStr linefgc = (65535,16385,16385,32767), fillbgc= (65535,16385,16385,32767), fillpat = -1, linethick = 0, xcoord = top, ycoord = left
			DrawPoly/W=$WindowsNameStr x1, y1, 1, 1, {x1, y1, x2, y2, x3, y3, x4, y4}
			SetDrawEnv/W=$WindowsNameStr gstop
			SetDrawLayer/W=$WindowsNameStr UserFront
			SetScale/I y, Yend, Ystart, M_ExtractedSurface
			SetScale/I x, 0, (round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2)) * Xfactor), M_ExtractedSurface
       	break
	endswitch
	SetDataFolder currdfr
	return 0
End
