#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late
#pragma IgorVersion  = 9
#pragma ModuleName = ATH_PlaneZProfile
#pragma version = 1.1

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

/// @module ATH_PlaneZProfile
/// @brief Module ATH_PlaneZProfile.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH PlaneZProfile functionality.


/// @function MainMenu
/// @brief Description of MainMenu.
/// @details
/// Auto-generated documentation stub for function `MainMenu`.
/// @returns Variable Return value.

static Function MainMenu()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")

	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph."
		return -1
	endif
	
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string LinkedPlotStr = GetUserData(winNameStr, "", "ATH_LinkedWinImagePPZ")
	if(strlen(LinkedPlotStr))
		DoWindow/F LinkedPlotStr
		return 0
	endif
	
	// User selected a wave, check if it's 3d
	if(WaveDims(w3dRef) == 3) // if it is a 3d wave
		DFREF dfr = InitialiseFolder()
		variable nrows = DimSize(w3dRef,0)
		variable ncols = DimSize(w3dRef,1)
		Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 G $imgNameTopGraphStr round(0.9 * nrows/2), round(1.1 * ncols/2)
		Cursor/I/C=(65535,0,0,65535)/S=1/P/N=1 H $imgNameTopGraphStr round(1.1 * nrows/2), round(0.9 * ncols/2)
		InitialiseGraph(dfr)
		SetWindow $winNameStr, hook(MyImagePlaneProfileZHook) = ATH_PlaneZProfile#CursorHookFunction // Set the hook
		SetWindow $winNameStr userdata(ATH_LinkedWinImagePPZ) = "ATH_ImagePlaneZProf_" + winNameStr // Name of the plot we will make, used to communicate the
		SetWindow $winNameStr userdata(ATH_rootdfrStr) = GetDataFolder(1, dfr)
		// name to the windows hook to kill the plot after completion
	else
		Abort "Plane profile operation needs a stack."
	endif
	return 0
End

static Function/DF InitialiseFolder()
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

    DFREF rootDF = $("root:Packages:ATH_DataFolder:ImagePlaneProfileZ:")
    string UniqueimgNameTopGraphStr = CreateDataObjectName(rootDF, imgNameTopGraphStr, 11, 0, 1)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ImagePlaneProfileZ:" + PossiblyQuoteName(UniqueimgNameTopGraphStr)) // Root folder here

	variable nrows = DimSize(imgWaveRef, 0)
	variable ncols = DimSize(imgWaveRef, 1)
	variable nlayers = DimSize(imgWaveRef,2)
	variable p1 = round(0.9 * nrows/2)
	variable q1 = round(1.1 * ncols/2)
	variable p2 = round(1.1 * nrows/2)
	variable q2 = round(0.9 * ncols/2)
	variable dx = DimDelta(imgWaveRef, 0)
	variable dy = DimDelta(imgWaveRef, 1)
	variable dz = DimDelta(imgWaveRef, 2)
	variable x0 = DimOffset(imgWaveRef, 0)
	variable y0 = DimOffset(imgWaveRef, 1)
	variable z0 = DimOffset(imgWaveRef, 2)			
	// Use them to alculate default scale if wave is scaled
	variable NxGH = sqrt((p1-p2)^2+(q1-q2)^2)
	variable normGHCursors = sqrt(((p1-p2)*dx)^2+((q1-q2)*dy)^2)
	
	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_ImagePathname = GetWavesDataFolder(imgWaveRef, 2)
	string/G dfr:gATH_ImagePath = GetWavesDataFolder(imgWaveRef, 1)
	string/G dfr:gATH_ImageNameStr = NameOfWave(imgWaveRef)
	variable/G dfr:gATH_nLayers =  DimSize(imgWaveRef,2)
	variable/G dfr:gATH_Nx = NxGH // Startup value
	variable/G dfr:gATH_Ny = nlayers
	variable/G dfr:gATH_C1x = p1
	variable/G dfr:gATH_C1y = q1
	variable/G dfr:gATH_C2x = p2
	variable/G dfr:gATH_C2y = q2
	//Restore scale of original wave
	variable/G dfr:gATH_x0 = x0
	variable/G dfr:gATH_dx = dx
	variable/G dfr:gATH_y0 = y0
	variable/G dfr:gATH_dy = dy
	variable/G dfr:gATH_z0 = z0
	variable/G dfr:gATH_dz = dz
	// Flush scales here
	SetScale/P x, 0, 1, imgWaveRef
	SetScale/P y, 0, 1, imgWaveRef
	SetScale/P z, 0, 1, imgWaveRef		
	// Set the default scale if there is one already
	if(dx!=1 && dy!=1)
		variable/G dfr:gATH_Ystart = z0
		variable/G dfr:gATH_Yend = z0 + (nlayers - 1) * dz
		variable/G dfr:gATH_Xfactor = normGHCursors/NxGH // assume homogenous kx, ky
	else
		variable/G dfr:gATH_Ystart = 0
		variable/G dfr:gATH_Yend = 0
		variable/G dfr:gATH_Xfactor = 1
	endif
	
	// Switches and indicators
	variable/G dfr:gATH_PlotSwitch = 1
	variable/G dfr:gATH_MarkLinesSwitch = 1
	variable/G dfr:gATH_OverrideNx = 0
	variable/G dfr:gATH_OverrideNy = 0
	// Misc
	variable/G dfr:gATH_colorcnt = 0
	return dfr
End

/// @function InitialiseGraph
/// @brief Description of InitialiseGraph.
/// @details
/// Auto-generated documentation stub for function `InitialiseGraph`.
/// @param dfr Parameter dfr.
/// @returns Variable Return value.

static Function InitialiseGraph(DFREF dfr)
	/// Here we will create the profile plot and graph and plot the profile
	string plotNameStr = "ATH_ImagePlaneZProf_" + GetDataFolder(0, dfr)
	if (WinType(plotNameStr) == 0) // line profile window is not displayed
		CreatePanel(dfr)
	else
		DoWindow/F $plotNameStr // if it is bring it to the FG
	endif
	return 0
End

/// @function CreatePanel
/// @brief Description of CreatePanel.
/// @details
/// Auto-generated documentation stub for function `CreatePanel`.
/// @param dfr Parameter dfr.
/// @returns Variable Return value.

static Function CreatePanel(DFREF dfr)
	string rootFolderStr = GetDataFolder(1, dfr)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/SDFR=dfr gATH_ImagePathname
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z Nx = dfr:gATH_Nx
	NVAR/Z Ny = dfr:gATH_Ny
	NVAR/Z dz = dfr:gATH_dz 
	NVAR/Z nLayers = dfr:gATH_nLayers
	NVAR/Z PlotSwitch = dfr:gATH_PlotSwitch
	NVAR/Z MarkLinesSwitch = dfr:gATH_MarkLinesSwitch
	NVAR/Z OverrideNx = dfr:gATH_OverrideNx
	NVAR/Z OverrideNy = dfr:gATH_OverrideNy
	string grfname = "ATH_ImagePlaneZProf_" + gATH_WindowNameStr
	WAVE wRef = $gATH_ImagePathname
	DFREF cdfr = GetDataFolderDFR()
	SetDataFolder dfr
	ImageTransform/X={Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface wRef
	SetDataFolder cdfr 
	ATH_Display#NewImg(dfr:M_ExtractedSurface, grfname = grfname)
	// Not good idea to use it now as long as the "i" options interferes with the ControlBar of the profilert
	// Fix it? ATH_Display#NewImg(dfr:M_ExtractedSurface, grfname = grfname)
	SetAxis/A left
	ModifyGraph/W=$grfname width = 350, height = 470
	Execute/P/Q "ModifyGraph width=0,height=0"
	ModifyGraph/Z cbRGB=(65535,65534,49151)

	ControlBar/W=$grfname 80	
	AutoPositionWindow/E/M=0/R=$gATH_WindowNameStr
		
	SetWindow $grfname userdata(ATH_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $grfname userdata(ATH_targetGraphWin) = "ATH_ImagePlaneProfileZ_" + gATH_WindowNameStr 
	SetWindow $grfname userdata(ATH_LinkedWinImageSource) = gATH_WindowNameStr 	
	SetWindow $grfname, hook(MyImagePlaneProfileZHook) = ATH_PlaneZProfile#GraphHookFunction// Set the hook

	SetVariable setNx,pos={10,5},size={85,20.00},title="N\\Bx", fSize=14,fColor=(65535,0,0),value=Nx,limits={1,inf,1},proc=ATH_PlaneZProfile#SetVariableNx,win=$grfName	
	SetVariable setNy,pos={97,5},size={70,20.00},title="N\\By", fSize=14,fColor=(65535,0,0),value=Ny,limits={1,inf,1},proc=ATH_PlaneZProfile#SetVariableNy,win=$grfName	

	Button SetScaleButton,pos={180,6},size={70.00,20.00},title="Set Scale",valueColor=(1,12815,52428),help={"Scale X, Y coordinates. "+\
	"Place markers and press button. Then set X and Y scales as intervals (Xmin, Xmax)"},proc=ATH_PlaneZProfile#SetScaleButton,win=$grfName	
	Button SaveProfileButton,pos={260.00,6},size={90.00,20.00},title="Save Profile",valueColor=(1,12815,52428),help={"Save displayed image profile"},proc=ATH_PlaneZProfile#SaveProfileButton,win=$grfName	
	CheckBox DisplayProfiles,pos={10,55},size={98.00,17.00},title="Display Profiles",fSize=13,value=PlotSwitch,side=1,proc=ATH_PlaneZProfile#CheckboxPlotProfile,win=$grfName	
	CheckBox OverrideNx,pos={10,35},size={86.00,17.00},title="Override: N\\Bx",fSize=13,fColor=(65535,0,0),value=OverrideNx,side=1,proc=ATH_PlaneZProfile#OverrideNx,win=$grfName	
	CheckBox OverrideNy,pos={110,35},size={86.00,17.00},title="N\\By",fSize=13,fColor=(65535,0,0),value=OverrideNy,side=1,proc=ATH_PlaneZProfile#OverrideNy,win=$grfName	

	ValDisplay GcoordX title="G\\Bx:",pos={150,35},size={80,10},value=_NUM:NaN,fSize=13,help={"Scaled X value of the G cursor"},win=$grfName
	ValDisplay GcoordY title="G\\By:",pos={230,35},size={80,10},value=_NUM:NaN,fSize=13,help={"Scaled Y value of the G cursor"},win=$grfName	
	ValDisplay HcoordX title="H\\Bx:",pos={150,55},size={80,10},value=_NUM:NaN,fSize=13,help={"Scaled X value of the H cursor"},win=$grfName
	ValDisplay HcoordY title="H\\By:",pos={230,55},size={80,10},value=_NUM:NaN,fSize=13,help={"Scaled Y value of the H cursor"},win=$grfName		
	ValDisplay normGH title="",pos={320,45},size={50,10},format="%.2f",value=_NUM:NaN,fSize=13,help={"GH norm"},win=$grfName		

	return 0
End

/// @function CursorHookFunction
/// @brief Description of CursorHookFunction.
/// @details
/// Auto-generated documentation stub for function `CursorHookFunction`.
/// @param &s Parameter &s.
/// @returns Variable Return value.

static Function CursorHookFunction(STRUCT WMWinHookStruct &s)
	/// Window hook function
	/// The line profile is drawn from G to H
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_rootdfrStr"))
	SVAR/Z ImagePathname = dfr:gATH_ImagePathname
	WAVE/Z w3dRef = $ImagePathname
	NVAR/Z nlayers = dfr:gATH_nLayers
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z Nx = dfr:gATH_Nx
	NVAR/Z Ny = dfr:gATH_Ny
	NVAR/Z x0 = dfr:gATH_x0
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z y0 = dfr:gATH_y0
	NVAR/Z dy = dfr:gATH_dy
	NVAR/Z z0 = dfr:gATH_z0
	NVAR/Z dz = dfr:gATH_dz
	NVAR/Z nLayers =  dfr:gATH_nLayers
	NVAR/Z OverrideNx = dfr:gATH_OverrideNx
	NVAR/Z OverrideNy = dfr:gATH_OverrideNy
	// Set scale
	NVAR/Z Xfactor = dfr:gATH_Xfactor
	NVAR/Z Ystart = dfr:gATH_Ystart
	NVAR/Z Yend = dfr:gATH_Yend
	variable normGHCursors, NxScale
	variable hookResult = 0
	string PlaneProfileWin = GetUserData(s.winName, "", "ATH_LinkedWinImagePPZ")
	switch(s.eventCode)
		case 2: // Kill the window
			// Restore original wave scaling
			NVAR/SDFR=dfr gATH_x0
			NVAR/SDFR=dfr gATH_dx
			NVAR/SDFR=dfr gATH_y0
			NVAR/SDFR=dfr gATH_dy
			NVAR/SDFR=dfr gATH_z0
			NVAR/SDFR=dfr gATH_dz
			SetScale/P x, gATH_x0, gATH_dx, w3dRef
			SetScale/P y, gATH_y0, gATH_dy, w3dRef
			SetScale/P z, gATH_z0, gATH_dz, w3dRef
			// Kill window and folder
			KillWindow/Z $PlaneProfileWin
			KillDataFolder/Z dfr
			hookresult = 1
			break
		case 5:
			SetDrawLayer/W=$s.winName ProgFront
			DrawAction/W=$s.winName delete
			SetDrawEnv/W=$s.winName linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
			DrawLine/W=$s.winName C1x, C1y, C2x, C2y
			SetDrawLayer/W=$s.winName UserFront
			hookResult = 1
			break
		case 7:
			if(!cmpstr(s.cursorName, "G") || !cmpstr(s.cursorName, "H")) // It should work only with G, H you might have other cursors on the image
				SetDrawLayer/W=$s.winName ProgFront
				DrawAction/W=$s.winName delete
				SetDrawEnv/W=$s.winName linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
				// Scale here is p, q
				C1x = hcsr(G,s.winName)
				C1y = vcsr(G,s.winName)
				C2x = hcsr(H,s.winName)
				C2y = vcsr(H,s.winName)
				DrawLine/W=$s.winName C1x, C1y, C2x, C2y
				if(C1x == C2x && C1y == C2y) // Cursors G, H cannot overlap
					break
				endif
			else
				break
			endif
			DFREF currdfr = GetDataFolderDFR()
			SetdataFolder dfr
			WAVE/Z M_ExtractedSurface // it is in dfr!
			ImageTransform/X={Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface w3dRef
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
				if(!strlen(GetUserData(PlaneProfileWin, "SetScaleButton", "SetScalePlaneZProfile")))
					variable originalScale = sqrt( ((C2x-C1x)*dx)^2 + ((C2y-C1y)*dy)^2 )
					SetScale/I x, 0, originalScale,  M_ExtractedSurface
				else
					SetScale/I x, 0, (Nx * Xfactor), M_ExtractedSurface
				endif
			endif
			SetScale/I y, Ystart, Yend, M_ExtractedSurface
			SetDrawLayer/W=$s.winName UserFront
			ValDisplay GcoordX, value=_NUM:(x0 + C1x*dx),win=$PlaneProfileWin
			ValDisplay GcoordY, value=_NUM:(y0 + C1y*dy),win=$PlaneProfileWin
			ValDisplay HcoordX, value=_NUM:(x0 + C2x*dx),win=$PlaneProfileWin
			ValDisplay HcoordY, value=_NUM:(y0 + C2y*dy),win=$PlaneProfileWin
			originalScale = sqrt( ((C2x-C1x)*dx)^2 + ((C2y-C1y)*dy)^2 )
			ValDisplay normGH, value=_NUM:originalScale,win=$PlaneProfileWin
			hookResult = 1
			SetdataFolder currdfr
			break
		case 8: // We have a Window modification event
			if(strlen(PlaneProfileWin)) // if profile plot exists (deleted mouseTrackV < 0 condition)
				NVAR/Z glayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(s.winName):gLayer
				//SetDrawLayer/W=$PlaneProfileWin ProgFront
				DrawAction/W=$PlaneProfileWin delete
				SetDrawEnv/W=$PlaneProfileWin xcoord=prel, ycoord=left,linefgc = (65535,0,0) //It should be after the draw action
				variable zPos = z0 + glayer * dz
				WAVE/Z extSurfaceW = dfr:M_ExtractedSurface
				variable yExtSurfPos = DimOffset(extSurfaceW, 1) + gLayer * DimDelta(extSurfaceW, 1)
				DrawLine/W=$PlaneProfileWin 0, yExtSurfPos, 1, yExtSurfPos
				TextBox/W=$PlaneProfileWin/F=0/A=LT/C/N=zScaleProfileTag "\\Z12z\Bsc\M\Z12 = " + num2str(yExtSurfPos)
			//	hookresult = 1				
			endif
			break
	endswitch

	return hookResult       // 0 if nothing done, else 1
End

/// @function GraphHookFunction
/// @brief Description of GraphHookFunction.
/// @details
/// Auto-generated documentation stub for function `GraphHookFunction`.
/// @param &s Parameter &s.
/// @returns Variable Return value.

static Function GraphHookFunction(STRUCT WMWinHookStruct &s)
	string parentGraphWin = GetUserData(s.winName, "", "ATH_LinkedWinImageSource")
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_rootdfrStr"))
	switch(s.eventCode)
		case 2: // Kill the window
			// parentGraphWin -- winNameStr
			// Kill the MyLineProfileHook
			SetWindow $parentGraphWin, hook(MyImagePlaneProfileZHook) = $""
			// We need to reset the link between parentGraphwin (winNameStr) and ATH_LinkedLineProfilePlotStr
			// see ATH_MainMenuLaunchLineProfile() when we test if with strlen(LinkedPlotStr)
			SetWindow $parentGraphWin userdata(ATH_LinkedWinImagePPZ) = ""
			Cursor/W=$parentGraphWin/K G
			Cursor/W=$parentGraphWin/K H			
			SetDrawLayer/W=$parentGraphWin ProgFront
			DrawAction/W=$parentGraphWin delete
			SVAR/Z ImagePathname = dfr:gATH_ImagePathname
			WAVE/Z w3dRef = $ImagePathname				
			NVAR/SDFR=dfr gATH_x0
			NVAR/SDFR=dfr gATH_dx
			NVAR/SDFR=dfr gATH_y0
			NVAR/SDFR=dfr gATH_dy
			NVAR/SDFR=dfr gATH_z0
			NVAR/SDFR=dfr gATH_dz
			SetScale/P x, gATH_x0, gATH_dx, w3dRef
			SetScale/P y, gATH_y0, gATH_dy, w3dRef
			SetScale/P z, gATH_z0, gATH_dz, w3dRef
			Execute/P/Q "KillDataFolder/Z " + GetUserData(s.winName, "", "ATH_rootdfrStr")
			break
	endswitch
End

/// @function SaveProfileButton
/// @brief Description of SaveProfileButton.
/// @details
/// Auto-generated documentation stub for function `SaveProfileButton`.
/// @param &B_Struct Parameter &B_Struct.
/// @returns Variable Return value.

static Function SaveProfileButton(STRUCT WMButtonAction &B_Struct): ButtonControl // Change using UniqueName for displaying

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_rootdfrStr"))
			DFREF currdfr = GetDataFolderDFR()
			string targetGraphWin = GetUserData(B_Struct.win, "", "ATH_targetGraphWin")
			SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr, w3dNameStr = dfr:gATH_ImageNameStr, ImagePathname = dfr:gATH_ImagePathname
			Wave/SDFR=dfr M_ExtractedSurface
			NVAR/Z PlotSwitch = dfr:gATH_PlotSwitch, MarkLinesSwitch = dfr:gATH_MarkLinesSwitch
			NVAR/Z C1x = dfr:gATH_C1x, C1y = dfr:gATH_C1y, C2x = dfr:gATH_C2x, C2y = dfr:gATH_C2y
			NVAR/Z Nx = dfr:gATH_Nx, Ny = dfr:gATH_Ny, nLayers = dfr:gATH_nLayers
			NVAR/Z colorcnt = dfr:gATH_colorcnt
			string recreateCmdStr
			DFREF savedfr = GetDataFolderDFR()
			variable red, green, blue
			variable postfix = 0
			string saveImageStr
			string saveWaveBaseNameStr = w3dNameStr + "_PPZ"
			string saveWaveNameStr = CreatedataObjectName(savedfr, saveWaveBaseNameStr, 1, 0, 5)
			Duplicate dfr:M_ExtractedSurface, savedfr:$saveWaveNameStr
			if(PlotSwitch)
				saveImageStr = CreatedataObjectName(savedfr, targetGraphWin + "_s", 1, 0, 5)
				ATH_Display#NewImg(savedfr:$saveWaveNameStr, grfName = saveImageStr)
				ModifyGraph/W=$saveImageStr width = 350, height = 470
				SetAxis/A left
				Execute/P/Q "ModifyGraph/W=$\""+saveImageStr+"\" width=0,height=0"
				colorcnt += 1
			endif

			if(MarkLinesSwitch)
				if(!PlotSwitch)
					[red, green, blue] = ATH_Graph#GetColor(colorcnt)
					colorcnt += 1
				endif
				DrawLineUserFront(WindowNameStr,C1x, C1y, C2x, C2y, red, green, blue) // Draw on UserFront and return to ProgFront
			endif
			sprintf recreateCmdStr, "Source: %s\nCmd:ImageTransform/X={%d, %d, %d, %d, 0, %d, %d, 0, %d, "+\
			"%d, %d} extractSurface %s\n",  ImagePathname, Nx, Ny, C1x, C1y, C2x, C2y, C2x, C2y, nLayers, w3dNameStr
			Note savedfr:$saveWaveNameStr, recreateCmdStr
			break
	endswitch
	return 0
End

/// @function SetScaleButton
/// @brief Description of SetScaleButton.
/// @details
/// Auto-generated documentation stub for function `SetScaleButton`.
/// @param &B_Struct Parameter &B_Struct.
/// @returns Variable Return value.

static Function SetScaleButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_rootdfrStr"))
			NVAR/Z C1x = dfr:gATH_C1x, C1y = dfr:gATH_C1y, C2x = dfr:gATH_C2x, C2y = dfr:gATH_C2y
			NVAR/Z Xfactor = dfr:gATH_Xfactor, Ystart = dfr:gATH_Ystart, Yend = dfr:gATH_Yend
			variable Xstart_l, Xend_l, Ystart_l, Yend_l, Xscale
			Prompt Xscale, "X-scale: set cursors and enter the calibrating value \n(0: pixel scale,  > 0: user scale,  < 0 : original scale)"
			Prompt Ystart_l, "Y top value"
			Prompt Yend_l, "Y bottom value (Y_bottom < Y_top)"
			DoPrompt "Set X, Y scale (Zero removes scale)", Xscale, Ystart_l, Yend_l
			if(V_flag) // User cancelled
				return -1
			endif
			Ystart = Ystart_l
			Yend   = Yend_l
			if(Ystart_l > Yend_l)
				Ystart = Yend_l
				Yend = Ystart_l
			endif
			if(Xscale == 0)
				Xfactor = 1
				Button SetScaleButton, userdata(SetScalePlaneZProfile) = "0", win=$B_Struct.win // pixel scale
			elseif(Xscale > 0)
				Xfactor = Xscale / sqrt((C1x - C2x)^2 + (C1y - C2y)^2)
				Button SetScaleButton, userdata(SetScalePlaneZProfile) = "1", win=$B_Struct.win // user scale
			else // give a negative number
				Xfactor = 1
				Button SetScaleButton, userdata(SetScalePlaneZProfile) = "", win=$B_Struct.win // original scale
			endif
			break
	endswitch
	return 0
End

/// @function CheckboxPlotProfile
/// @brief Description of CheckboxPlotProfile.
/// @details
/// Auto-generated documentation stub for function `CheckboxPlotProfile`.
/// @param cb Parameter cb.
/// @returns Variable Return value.

static Function CheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_rootdfrStr"))
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

/// @function CheckboxMarkLines
/// @brief Description of CheckboxMarkLines.
/// @details
/// Auto-generated documentation stub for function `CheckboxMarkLines`.
/// @param cb Parameter cb.
/// @returns Variable Return value.


static Function CheckboxMarkLines(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_rootdfrStr"))
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

/// @function OverrideNx
/// @brief Description of OverrideNx.
/// @details
/// Auto-generated documentation stub for function `OverrideNx`.
/// @param cb Parameter cb.
/// @returns Variable Return value.

static Function OverrideNx(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_rootdfrStr"))
	NVAR/Z OverrideNx = dfr:gATH_OverrideNx
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

/// @function OverrideNy
/// @brief Description of OverrideNy.
/// @details
/// Auto-generated documentation stub for function `OverrideNy`.
/// @param cb Parameter cb.
/// @returns Variable Return value.

static Function OverrideNy(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_rootdfrStr"))
	NVAR/Z OverrideNy = dfr:gATH_OverrideNy
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

/// @function SetVariableNx
/// @brief Description of SetVariableNx.
/// @details
/// Auto-generated documentation stub for function `SetVariableNx`.
/// @param sv Parameter sv.
/// @returns Variable Return value.

static Function SetVariableNx(STRUCT WMSetVariableAction& sv) : SetVariableControl

	switch(sv.eventCode)
		case 6:
			DFREF currdfr = GetDataFolderDFR()
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sv.win, "", "ATH_rootdfrStr"))
			NVAR/Z C1x = dfr:gATH_C1x, C1y = dfr:gATH_C1y, C2x = dfr:gATH_C2x, C2y = dfr:gATH_C2y
			NVAR/Z Nx = dfr:gATH_Nx, Ny = dfr:gATH_Ny, Ystart = dfr:gATH_Ystart, Yend = dfr:gATH_Yend
			NVAR/Z Xfactor = dfr:gATH_Xfactor, nLayers = dfr:gATH_nLayers, OverrideNx = dfr:gATH_OverrideNx
			SVAR/Z ImagePathname = dfr:gATH_ImagePathname
			WAVE/Z w3dRef = $ImagePathname
			variable normGHCursors
			SetDataFolder dfr
			if(OverrideNx)
				Nx = sv.dval
				normGHCursors = round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2))
				ImageTransform/X={Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface w3dRef
				WAVE ww = M_ExtractedSurface
				SetScale/I x, 0, (normGHCursors * Xfactor), ww
				//SetScale/I y, Ystart, Yend, ww
			else
				Nx = round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2))
			endif
			SetDataFolder currdfr
			break
	endswitch
	return 0
End

/// @function SetVariableNy
/// @brief Description of SetVariableNy.
/// @details
/// Auto-generated documentation stub for function `SetVariableNy`.
/// @param sv Parameter sv.
/// @returns Variable Return value.

static Function SetVariableNy(STRUCT WMSetVariableAction& sv) : SetVariableControl

	switch(sv.eventCode)
		case 6:
			DFREF currdfr = GetDataFolderDFR()
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sv.win, "", "ATH_rootdfrStr"))
			NVAR/Z C1x = dfr:gATH_C1x, C1y = dfr:gATH_C1y, C2x = dfr:gATH_C2x, C2y = dfr:gATH_C2y
			NVAR/Z Nx = dfr:gATH_Nx, Ny = dfr:gATH_Ny, nLayers = dfr:gATH_nLayers, OverrideNy = dfr:gATH_OverrideNy
			NVAR/Z Ystart = dfr:gATH_Ystart, Yend = dfr:gATH_Yend, Xfactor = dfr:gATH_Xfactor
			SVAR/Z ImagePathname = dfr:gATH_ImagePathname
			WAVE/Z w3dRef = $ImagePathname
			variable normGHCursors
			SetDataFolder dfr
			if(OverrideNy)
				Ny = sv.dval
				ImageTransform/X={Nx, Ny, C1x, C1y, 0, C2x, C2y, 0, C2x, C2y, nLayers} extractSurface w3dRef
				WAVE ww = M_ExtractedSurface
				normGHCursors = round(sqrt((C1x - C2x)^2 + (C1y - C2y)^2))
				SetScale/I y, Ystart, Yend, ww
				//SetScale/I x, 0, (normGHCursors * Xfactor), ww
			else
				Ny = nLayers
			endif
			SetDataFolder currdfr
			break
	endswitch
	return 0
End

/// @function DrawLineUserFront
/// @brief Description of DrawLineUserFront.
/// @details
/// Auto-generated documentation stub for function `DrawLineUserFront`.
/// @param winNameStr Parameter winNameStr.
/// @param x0 Parameter x0.
/// @param y0 Parameter y0.
/// @param x1 Parameter x1.
/// @param y1 Parameter y1.
/// @param red Parameter red.
/// @param green Parameter green.
/// @param blue Parameter blue.
/// @returns Variable Return value.

static Function DrawLineUserFront(string winNameStr, variable x0, variable y0, variable x1, variable y1, variable red, variable green, variable blue)
	SetDrawLayer/W=$winNameStr UserFront 
	SetDrawEnv/W=$winNameStr linefgc = (red, green, blue), fillpat = 0, linethick = 1, dash= 2, xcoord= top, ycoord= left
	DrawLine/W=$winNameStr x0, y0, x1, y1
	SetDrawLayer/W=$winNameStr ProgFront
	return 0
End
