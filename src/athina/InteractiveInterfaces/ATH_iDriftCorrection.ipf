#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_iDriftCorrection
#pragma version = 2.4

// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: egolias@protonmail.com
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

/// Note: We cannot launch the operation without having a slider on at the moment
/// the problem is the Wavemetrics functions used in ATH_Display. "GetWindow kwTopWin, property" fails
/// as it acts on the /EXT panel with "error: this operation is for graphs only"
/// static Function Append3DImageSlider() is the source of error.
/// Exterior windows are on top

/// Revised and now can handle single images 04.10.2024
/// Revised to use relative coordinate to save Ref. Coord.
/// to be independent from scale/img size and only drift
/// to the same spot wrt to the axes.
///
static Function CreatePanel()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")

	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph"
		return -1
	endif

	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	//Check if you have already created the panel
	string pnlNameStr = winNameStr + "#iDriftCorrection"
	if(WinType(pnlNameStr) == 7)
		return 1
	endif

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
		midOfImageX = 0.5
		midOfImageY = 0.5
		Cursor/W=$winNameStr/I/F/L=0/H=1/C=(1,65535,33232)/S=2/N=1/P I $imgNameTopGraphStr 0.5, 0.5
	else
		Cursor/W=$winNameStr/I/F/L=0/H=1/C=(1,65535,33232)/S=2/N=1 I $imgNameTopGraphStr midOfImageX, midOfImageY
	endif
	//Duplicate the wave for backup
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveDriftCorrection:" + winNameStr) // Root folder here
	string backupNameStr = NameOfWave(w3dref) + "_undo"
	Duplicate/O w3dref, dfr:$backupNameStr
	ModifyImage/W=$winNameStr $imgNameTopGraphStr ctabAutoscale=3
	// Create the global variables for panel
	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gATH_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gATH_w3dNameStr = NameOfWave(w3dref)
	string/G dfr:gATH_w3dBackupPathNameStr = GetWavesDataFolder(dfr:$backupNameStr, 2)
	string/G dfr:gATH_w3dBackupNameStr = PossiblyQuoteName(backupNameStr)
	variable/G dfr:gATH_w3dnlayers = DimSize(w3dref, 2) // 0 for 2D wave
	variable/G dfr:gATH_AnchorPositionX = NaN // Not set
	variable/G dfr:gATH_AnchorPositionY = NaN
	variable/G dfr:gATH_CursorPositionX = midOfImageX
	variable/G dfr:gATH_CursorPositionY = midOfImageY
	variable/G dfr:gATH_dx = DimDelta(w3dref, 0)
	variable/G dfr:gATH_dy = DimDelta(w3dref, 1)
	variable/G dfr:gATH_SubPixelMode = 0
	variable/G dfr:gATH_FastMode = 0
	variable/G dfr:gATH_LDCstartL = NaN
	variable/G dfr:gATH_LDCendL = NaN
	variable/G dfr:gATH_LDCstartX = NaN
	variable/G dfr:gATH_LDCstartY = NaN
	variable/G dfr:gATH_LDCendX = NaN
	variable/G dfr:gATH_LDCendY = NaN
	variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
	NewPanel/K=1/EXT=0/N=iDriftCorrection/W=(0,0,165*pntConv,490*pntConv)/HOST=$winNameStr
	SetDrawLayer UserBack
	SetDrawEnv/W=iDriftCorrection fsize= 13*pntConv,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=iDriftCorrection 2*pntConv,16*pntConv,"Interactive drift correction"
	Button ToggleSubPixelMode,title="Sub-pixel drift = OFF",font="Menlo",fSize=11*pntConv,fColor=(65535,0,0),valueColor=(0,0,0),win=$pnlNameStr
	Button ToggleSubPixelMode,pos={10*pntConv,20*pntConv},size={150*pntConv,20*pntConv},proc=ATH_iDriftCorrection#ToggleSubPixelModeButton,win=$pnlNameStr
	SetDrawLayer UserBack
	DrawLine 15*pntConv,50*pntConv,150*pntConv,50*pntConv
	Button SetAnchorCursor,pos={23.00*pntConv,57*pntConv},size={120.00*pntConv,20.00*pntConv},title="Set anchor",fSize=12*pntConv,fstyle=1,win=$pnlNameStr 
	Button SetAnchorCursor,valueColor=(65535,0,0),fColor=(61166,61166,61166),proc=ATH_iDriftCorrection#SetAnchorCursorButton,win=$pnlNameStr
	Button SetAnchorCursor fColor=(61166,61166,61166),help={"You have to set an anchor (reference) point to start drift correction."},win=$pnlNameStr
	//All buttons, except RestoreWave and LDC, are disabled until the anchor is set
	Button DriftImage,pos={32.00*pntConv,90*pntConv},size={100.00*pntConv,20.00*pntConv},title="Drift Image",disable=2, win=$pnlNameStr
	Button DriftImage,fSize=12*pntConv,fColor=(65535,49151,49151),proc=ATH_iDriftCorrection#DriftImageButton, win=$pnlNameStr
	Button SelectedLayersDrift3D,pos={32.00*pntConv,125*pntConv},size={100.00*pntConv,20.00*pntConv},fColor=(52428,52425,1),disable=2, win=$pnlNameStr
	Button SelectedLayersDrift3D,title="Drift N images",fSize=12,proc=ATH_iDriftCorrection#DriftSelectedLayers3DWaveButton,win=$pnlNameStr
	Button CascadeDrift3D,pos={32.00*pntConv,160*pntConv},size={100.00*pntConv,20.00*pntConv},fColor=(65535,49157,16385),disable=2, win=$pnlNameStr
	Button CascadeDrift3D,title="Cascade drift",fSize=12*pntConv,proc=ATH_iDriftCorrection#CascadeDrift3DWaveButton,win=$pnlNameStr
	// Draw the region for linear Drift correction
	SetDrawEnv dash= 3,fillpat= 0;DrawRect 15*pntConv,195*pntConv,150*pntConv,280*pntConv
	SetDrawEnv fsize= 10
	DrawText 30*pntConv,210*pntConv,"\\F'Menlo'Linear Drift Corr"
	string helpStrLinearDC = "Press Start and End after setting the layer using the slider/keys/mousewheel.\n"
	helpStrLinearDC += "Press Drift to perform linear drift between Start and End layers."
	Button LinearDC title="Drift",font="Menlo",fSize=12*pntConv,fColor=(51664,44236,58982),proc=ATH_iDriftCorrection#LinearDCButton,win=$pnlNameStr
	Button LinearDC pos={45*pntConv,215*pntConv},size={65*pntConv,24*pntConv}, help={helpStrLinearDC}, disable=2, win=$pnlNameStr
	Button FirstL title="Start",pos={26*pntConv,250*pntConv},size={50*pntConv,20*pntConv},proc=ATH_iDriftCorrection#SetStartLayerButton,win=$pnlNameStr
	Button LastL title="End",pos={85*pntConv,250*pntConv},size={50*pntConv,20*pntConv},proc=ATH_iDriftCorrection#SetEndLayerButton,win=$pnlNameStr
	//	
	Button Checkpoint,pos={32.00*pntConv,290*pntConv},size={100.00*pntConv,20.00*pntConv},fColor=(65535,49151,55704),win=$pnlNameStr
	Button Checkpoint,title="Checkpoint",fSize=12*pntConv,proc=ATH_iDriftCorrection#CheckpointButton,win=$pnlNameStr
	Button RestoreWave,pos={32.00*pntConv,320.00*pntConv},size={100.00*pntConv,20.00*pntConv},fColor=(32768,54615,65535),win=$pnlNameStr
	Button RestoreWave,title="Restore",fSize=15*pntConv,proc=ATH_iDriftCorrection#RestoreWaveButton,win=$pnlNameStr
	//		
	string helpStrShiftClick = "1. (Re)Set anchor.\n2. Use arrows/mousewheel to change between layers \n3. Use SHIFT+right-click"
	helpStrShiftClick+= " to drift a layer and move to the next.\n4. Use Del/Bksp to restore a layer."	
	Checkbox FastMode,pos={12.00*pntConv,350*pntConv},title="SHIFT+Click & drift",fSize=11*pntConv,font="Menlo", win=$pnlNameStr
	Checkbox FastMode,value=0,disable=2,proc=ATH_iDriftCorrection#FastModeCheckbox,help={helpStrShiftClick},win=$pnlNameStr
	// Save point as reference in the database
	SetDrawEnv linefgc= (1,12815,52428),dash= 3,fillpat= 0; DrawRect 15*pntConv,395*pntConv,150*pntConv,480*pntConv
	SetDrawEnv textrgb= (65535,0,0), fname= "Arial", fSize=13*pntConv,fstyle= 1
	DrawText 17*pntConv,390*pntConv,"Inter-stack alignment"
	SetDrawEnv textrgb= (0,0,0),fname= "Menlo",fstyle= 4,fsize= 10*pntConv;DrawText 20*pntConv,415*pntConv,"Global Ref. (anchor)"
	
	Button SaveReferenceCoordB,title="Save",fSize=12*pntConv,pos={18*pntConv,420*pntConv},size={60*pntConv,20.00*pntConv},win=$pnlNameStr
	Button SaveReferenceCoordB, proc=ATH_iDriftCorrection#InterStackAlignmentButton,disable=2,win=$pnlNameStr
	Button ShowReferenceCoordB,title="Show",fSize=12*pntConv,pos={87*pntConv,420*pntConv},size={60*pntConv,20.00*pntConv},win=$pnlNameStr
	Button ShowReferenceCoordB, proc=ATH_iDriftCorrection#InterStackAlignmentButton,win=$pnlNameStr,help={"SHIFT+click to use axes instead of relative coordinates."}
	Button DriftReferenceCoordB,title="Drift wrt global Ref.",fSize=12*pntConv,pos={22.00*pntConv,455*pntConv},size={120.00*pntConv,20.00*pntConv}, win=$pnlNameStr
	Button DriftReferenceCoordB,proc=ATH_iDriftCorrection#InterStackAlignmentButton, win=$pnlNameStr,help={"SHIFT+click to use axes instead of relative coordinates."}
	// Let's sort button status and colors
	DFREF dfrS = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveDriftCorrection:SavedReferenceCoords:")
	NVAR/SDFR=dfrS/Z gATH_SavedRefRelCoordX
	if(NVAR_Exists(gATH_SavedRefRelCoordX))
		Button DriftReferenceCoordB,disable = 0,fColor=(2,39321,1),win=$pnlNameStr
	else
		Button DriftReferenceCoordB,disable = 2,fColor=(65535,16385,16385),win=$pnlNameStr
		Button ShowReferenceCoordB,disable = 2,win=$pnlNameStr		
	endif
	
	// Disable controls not needed by 2D waves
	NVAR/SDFR=dfr gATH_w3dnlayers
	if(!gATH_w3dnlayers)
		ModifyControlList ControlNameList(pnlNameStr, ";", "*3D") disable = 2
	endif
	//Tranfer info re dfr to controls
	SetWindow $winNameStr#iDriftCorrection userdata(ATH_iImgAlignFolder) = "root:Packages:ATH_DataFolder:InteractiveDriftCorrection:" + winNameStr
	SetWindow $winNameStr#iDriftCorrection hook(iDriftPanelHook) = ATH_iDriftCorrection#PanelHookFunction
	// Set hook to the graph, killing the graph kills the iDriftCorrection linked folder
	SetWindow $winNameStr userdata(ATH_iImgAlignFolder) = "root:Packages:ATH_DataFolder:InteractiveDriftCorrection:" + winNameStr
	SetWindow $winNameStr, hook(iDriftWindowHook) = ATH_iDriftCorrection#GraphHookFunction // Set the hook
End

static Function GraphHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed
	//Cleanup when window is closed
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gATH_WindowNameStr
	SVAR/Z/SDFR=dfr gATH_w3dPathName
	WAVE/Z w3dRef = $gATH_w3dPathName
	SVAR/Z/SDFR=dfr gATH_w3dBackupPathNameStr
	WAVE/Z w3dBackUpRef = $gATH_w3dBackupPathNameStr
	SVAR/Z/SDFR=dfr gATH_imgNameTopWindowStr
	NVAR/Z/SDFR=dfr gATH_FastMode
	NVAR/Z/SDFR=dfr	gATH_SubPixelMode
	NVAR/Z/SDFR=dfr gATH_w3dnlayers
	NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(gATH_WindowNameStr):gLayer
	NVAR/SDFR=dfr gATH_AnchorPositionX
	NVAR/SDFR=dfr gATH_AnchorPositionY
	NVAR/SDFR=dfr gATH_CursorPositionX
	NVAR/SDFR=dfr gATH_CursorPositionY	
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	variable dx, dy
	
	if(!NVAR_Exists(gLayer) && gATH_w3dnlayers)
		ATH_Display#Append3DImageSlider()
	endif
	
	if(gATH_FastMode && s.specialKeyCode)
		if((s.specialKeyCode == 203 ||s.specialKeyCode == 101 || s.specialKeyCode == 102) && gLayer < gATH_w3dnlayers-1) // backtab (shift + tab) right or up
			gLayer+=1
		elseif((s.specialKeyCode == 100 || s.specialKeyCode == 103) && gLayer) // left or down
			gLayer-=1
		endif
		ModifyImage/W=$gATH_WindowNameStr $gATH_imgNameTopWindowStr plane=gLayer
		if(s.specialKeyCode == 300 || s.specialKeyCode == 301) // Delete or Backspace- Restore original layer
			w3dRef[][][gLayer] = w3dBackUpRef[p][q][gLayer]
		endif
		hookresult = 1
	endif
	
	switch(s.eventCode)
		case 0:
			gATH_CursorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_CursorPositionY = vcsr(I, gATH_WindowNameStr)
			hookresult = 1
			break
		case 2: // Kill the window
			Cursor/K I
			KillDataFolder/Z dfr
			SetWindow $s.winName, hook(iDriftWindowHook) = $""
			hookresult = 1
			break
		case 5:
			if(gATH_FastMode && s.eventMod==2 && gLayer < gATH_w3dnlayers && !numtype(gATH_AnchorPositionX)) //if SHIFT is pressed and Fast Mode is on
				dx = (gATH_AnchorPositionX - AxisValFromPixel(gATH_WindowNameStr, "top", s.mouseLoc.h))/gATH_dx
				dy = (gATH_AnchorPositionY - AxisValFromPixel(gATH_WindowNameStr, "left", s.mouseLoc.v))/gATH_dy
				if(!gATH_SubPixelMode)
					dx = round(dx); dy = round(dy)
				endif
				MatrixOP/O/FREE layerFREE = layer(w3dRef, gLayer)
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=dfr:M_Affine2D Affine2D layerFREE // Will overwrite M_Affine
				WAVE ATH_Affine2D = dfr:M_Affine2D
				w3dRef[][][gLayer] = ATH_Affine2D[p][q]
				if(gLayer < gATH_w3dnlayers-1)
					gLayer += 1
				endif
				ModifyImage/W=$gATH_WindowNameStr $gATH_imgNameTopWindowStr plane=gLayer
			endif
			hookresult = 1
			break
		case 7:
			// Same behavior with /F or not
			gATH_CursorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_CursorPositionY = vcsr(I, gATH_WindowNameStr)
			break
		case 22: // mouse wheel
				gLayer += s.WheelDy
				if(gLayer < 0)
					gLayer = 0
				endif
				if(gLayer > gATH_w3dnlayers - 1)
					gLayer = gATH_w3dnlayers - 1
				endif				
				ModifyImage/W=$gATH_WindowNameStr $gATH_imgNameTopWindowStr plane=gLayer
				hookresult = 1
			break
	endswitch
	return hookresult
End

static Function PanelHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when panel is closed

	switch(s.eventCode)
		case 2: // Kill the window
			variable hookresult = 0
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iImgAlignFolder"))
			SVAR/SDFR=dfr gATH_WindowNameStr, gATH_w3dBackupPathNameStr, gATH_w3dPathName
			CopyScales/I $gATH_w3dBackupPathNameStr, $gATH_w3dPathName
			SetWindow $s.winName, hook(iDriftPanelHook) = $""
			SetWindow $gATH_WindowNameStr, hook(iDriftWindowHook) = $""
			Cursor/K I
			SetDrawLayer/W=$gATH_WindowNameStr Overlay
			DrawAction/W=$gATH_WindowNameStr delete
			SetDrawLayer/W=$gATH_WindowNameStr UserFront
			KillDataFolder/Z dfr
			hookresult = 1
			break
	endswitch
	return hookresult
End

static Function SetAnchorCursorButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable hookresult = 0
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			DFREF dfrS = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveDriftCorrection:SavedReferenceCoords:")
			// String variables
			SVAR/SDFR=dfr gATH_WindowNameStr, gATH_w3dPathname
			// Wave and numeric variables
			WAVE/Z w3dRef = $gATH_w3dPathname
			NVAR/SDFR=dfr gATH_AnchorPositionX, gATH_AnchorPositionY, gATH_FastMode
			NVAR/SDFR=dfrS/Z gATH_SavedRefRelCoordX
			// Image dimensions
			variable xmax = DimSize($gATH_w3dPathname, 0), x0 = Dimoffset($gATH_w3dPathname, 0)
			variable ymax = DimSize($gATH_w3dPathname, 1), y0 = Dimoffset($gATH_w3dPathname, 1)
			gATH_AnchorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_AnchorPositionY = vcsr(I, gATH_WindowNameStr)
			variable relx, rely
			[relx, rely] = ATH_Graph#AxisValToRel2D(w3dRef, gATH_AnchorPositionX, gATH_AnchorPositionY)
			DrawTheRefCross(w3dRef, relx, rely, grfName=B_Struct.win)
			Button SetAnchorCursor fColor=(3,52428,1),valueColor=(0,0,0), win=$B_Struct.win
			if(!numtype(gATH_AnchorPositionX))
				CheckBox FastMode, win = $B_Struct.win,disable = 0
				Button DriftImage, win=$B_Struct.win,disable = 0
				Button CascadeDrift3D, win=$B_Struct.win,disable = 0
				Button SelectedLayersDrift3D,win=$B_Struct.win,disable = 0
				Button SaveReferenceCoordB,win=$B_Struct.win,disable = 0
				Button SetAnchorCursor,valueColor=(1,26214,0),title="Anchor is set",win=$B_Struct.win
				if(NVAR_Exists(gATH_SavedRefRelCoordX))
					Button DriftReferenceCoordB,win=$B_Struct.win,fColor=(2,39321,1),disable = 0
				endif
			endif
			hookresult =  1
			break
	endswitch
	return hookresult
End

static Function DriftImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable hookresult = 0
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			// String variables
			SVAR/Z/SDFR=dfr gATH_WindowNameStr, gATH_w3dPathName, gATH_w3dBackupPathNameStr
			// Wave references
			WAVE/Z w3dRef = $gATH_w3dPathName, wRefbackup = $gATH_w3dBackupPathNameStr
			// Numeric variables
			NVAR/SDFR=dfr gATH_w3dnlayers, gATH_AnchorPositionX, gATH_AnchorPositionY
			NVAR/SDFR=dfr gATH_CursorPositionX, gATH_CursorPositionY
			NVAR/SDFR=dfr gATH_dx, gATH_dy, gATH_SubPixelMode
			NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(gATH_WindowNameStr):gLayer
			gATH_CursorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_CursorPositionY = vcsr(I, gATH_WindowNameStr)
			variable dx = (gATH_AnchorPositionX - gATH_CursorPositionX)/gATH_dx
			variable dy = (gATH_AnchorPositionY - gATH_CursorPositionY)/gATH_dy
			dx = gATH_SubPixelMode ? dx : round(dx)
			dy = gATH_SubPixelMode ? dy : round(dy)
			if(gATH_w3dnlayers)
				MatrixOP/O/FREE layerFREE = layer(w3dRef, gLayer)
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=dfr:M_Affine2D Affine2D layerFREE
				WAVE ATH_Affine2D = dfr:M_Affine2D
				w3dRef[][][gLayer] = ATH_Affine2D[p][q]
			else
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=$gATH_w3dPathName Affine2D wRefbackup
			endif
			hookresult =  1
			break
	endswitch
	return hookresult
End

static Function ToggleSubPixelModeButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable hookresult = 0
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			// String variables
			SVAR/Z/SDFR=dfr gATH_WindowNameStr, gATH_imgNameTopWindowStr, gATH_w3dPathName
			// Wave reference
			WAVE/Z w3dRef = $gATH_w3dPathName
			// Numeric variables
			NVAR/Z/SDFR=dfr gATH_SubPixelMode, gATH_FastMode, gATH_CursorPositionX, gATH_CursorPositionY
			gATH_SubPixelMode = !gATH_SubPixelMode // Flip mode!
			variable relx, rely
			//	When used with the /I flag, x_value and y_value are row and column numbers.
			//	When used with the /F flag, x_value and y_value are relative graph coordinates (0-1).
			if(gATH_SubPixelMode)
				[relx, rely] = ATH_Graph#AxisValToRel2D(w3dRef, gATH_CursorPositionX, gATH_CursorPositionY)
				Cursor/W=$gATH_WindowNameStr/I/F/L=0/H=1/C=(1,65535,33232)/S=2/P I $gATH_imgNameTopWindowStr relx, rely
				Button ToggleSubPixelMode title="Sub-pixel drift = ON",fColor=(0,65535,0),win=$B_Struct.win
			else
				relx = ScaleToIndex(w3dRef, gATH_CursorPositionX, 0)
				rely = ScaleToIndex(w3dRef, gATH_CursorPositionY, 1)
				Cursor/W=$gATH_WindowNameStr/I/L=0/H=1/C=(1,65535,33232)/S=2/P I $gATH_imgNameTopWindowStr relx, rely
				Button ToggleSubPixelMode title="Sub-pixel drift = OFF",fColor=(65535,0,0),win=$B_Struct.win
			endif
			if(gATH_FastMode) //We are in FastMode. We don't need Cursor!
				Cursor/K I
			endif
			hookresult =  1
			break
	endswitch
	return hookresult
End
				
static Function SetStartLayerButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable hookresult = 0, nlayers
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			SVAR/Z/SDFR=dfr gATH_WindowNameStr
			NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(gATH_WindowNameStr):gLayer
			NVAR/Z/SDFR=dfr gATH_LDCstartL
			NVAR/Z/SDFR=dfr gATH_LDCendL
			NVAR/Z/SDFR=dfr gATH_LDCstartX
			NVAR/Z/SDFR=dfr	gATH_LDCstartY
			NVAR/Z/SDFR=dfr gATH_LDCendX
			NVAR/Z/SDFR=dfr	gATH_LDCendY
			gATH_LDCstartL = gLayer
			gATH_LDCstartX = hcsr(I, gATH_WindowNameStr)
			gATH_LDCstartY = vcsr(I, gATH_WindowNameStr)
			Button FirstL win=$B_Struct.win, title=("L: " + num2str(gATH_LDCstartL))
			ControlUpdate/W=$B_Struct.win FirstL
			nlayers = gATH_LDCendL - gATH_LDCstartL
			if(!numtype(gATH_LDCstartX) && !numtype(gATH_LDCendX) && nlayers > 0)
				Button LinearDC,win=$B_Struct.win, disable = 0
				ControlUpdate/W=$B_Struct.win LinearD
			else
				Button LinearDC,win=$B_Struct.win, disable = 2
				ControlUpdate/W=$B_Struct.win LinearD
			endif
			hookresult =  1
			break
	endswitch
	return hookresult
End

static Function SetEndLayerButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable hookresult = 0, nlayers
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			// String variable
			SVAR/Z/SDFR=dfr gATH_WindowNameStr
			// External numeric variable
			NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(gATH_WindowNameStr):gLayer
			// Numeric variables from dfr
			NVAR/Z/SDFR=dfr gATH_LDCstartL, gATH_LDCendL
			NVAR/Z/SDFR=dfr gATH_LDCstartX, gATH_LDCstartY, gATH_LDCendX, gATH_LDCendY
			gATH_LDCendL = gLayer
			gATH_LDCendX = hcsr(I, gATH_WindowNameStr)
			gATH_LDCendY = vcsr(I, gATH_WindowNameStr)
			Button LastL,win=$B_Struct.win, title=("L: " + num2str(gATH_LDCendL))
			ControlUpdate/W=$B_Struct.win LastL
			nlayers = gATH_LDCendL - gATH_LDCstartL
			if(!numtype(gATH_LDCstartX) && !numtype(gATH_LDCendX) && nlayers > 0)
				Button LinearDC,win=$B_Struct.win, disable = 0
				ControlUpdate/W=$B_Struct.win LinearD
			else
				Button LinearDC,win=$B_Struct.win, disable = 2
				ControlUpdate/W=$B_Struct.win LinearD
			endif
			hookresult =  1
			break
	endswitch
	return hookresult
End

static Function LinearDCButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable hookresult = 0
			DFREF currDF = GetDataFolderDFR()
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			SVAR/Z/SDFR=dfr gATH_WindowNameStr, gATH_w3dPathName
			WAVE/Z w3dRef = $gATH_w3dPathName
			NVAR/Z/SDFR=dfr gATH_LDCstartL, gATH_LDCendL
			NVAR/Z/SDFR=dfr gATH_LDCstartX, gATH_LDCstartY, gATH_LDCendX, gATH_LDCendY
			NVAR/SDFR=dfr gATH_dx, gATH_dy, gATH_SubPixelMode
			variable x0, y0, x1, y1, slope, shift, nlayers
			nlayers = gATH_LDCendL - gATH_LDCstartL + 1
			SetDataFolder dfr
			if(numtype(gATH_LDCstartX) || numtype(gATH_LDCendX))
				break
			endif
			if(nlayers > 0)
				[WAVE wx, WAVE wy] = ATH_Geometry#XYWavesOfLineFromTwoPoints(gATH_LDCstartX, gATH_LDCstartY,\
				gATH_LDCendX, gATH_LDCendY, nlayers)
				// Relative s, y shifts for Drift Correction
				wx -= gATH_LDCstartX ; wy -= gATH_LDCstartY
				// ImageInterpolate needs pixels, multiply by -1 to have the proper behavior in /ARPM={...}
				wx /= (-gATH_dx) ; wy /= (-gATH_dy)
				ATH_ImgAlign#LinearDriftPlanesABCursors(w3dref, wx, wy, startL = gATH_LDCstartL, \
				endL = gATH_LDCendL, intPx = 1 - gATH_SubPixelMode)
				hookresult =  1
			endif
			break
	endswitch
	SetDataFolder currDF
	return hookresult
End

static Function CheckpointButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable hookresult = 0
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			SVAR/SDFR=dfr gATH_w3dBackupPathNameStr
			SVAR/SDFR=dfr gATH_w3dPathname
			Duplicate/O $gATH_w3dPathname, $gATH_w3dBackupPathNameStr
			hookresult =  1
			break
	endswitch
	return hookresult
End

static Function RestoreWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	//Complete

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable hookresult = 0
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			SVAR/SDFR=dfr gATH_w3dBackupPathNameStr
			SVAR/SDFR=dfr gATH_w3dPathname
			Duplicate/O $gATH_w3dBackupPathNameStr, $gATH_w3dPathname
			hookresult =  1
			break
	endswitch
	return hookresult
End

static Function DriftSelectedLayers3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			variable hookresult = 0
			DFREF currDF = GetDataFolderDFR()
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			SVAR/Z/SDFR=dfr gATH_WindowNameStr, gATH_w3dPathName
			WAVE/Z w3dRef = $gATH_w3dPathName
			NVAR/SDFR=dfr gATH_AnchorPositionX, gATH_AnchorPositionY
			NVAR/SDFR=dfr gATH_CursorPositionX, gATH_CursorPositionY
			NVAR/SDFR=dfr gATH_dx, gATH_dy, gATH_SubPixelMode
			NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(gATH_WindowNameStr):gLayer
			SetDataFolder dfr
			gATH_CursorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_CursorPositionY = vcsr(I, gATH_WindowNameStr)
			variable dx = (gATH_AnchorPositionX - gATH_CursorPositionX)/gATH_dx
			variable dy = (gATH_AnchorPositionY - gATH_CursorPositionY)/gATH_dy
			dx = gATH_SubPixelMode ? dx : round(dx)
			dy = gATH_SubPixelMode ? dy : round(dy)
			variable lastlayerN = DimSize(w3dRef, 2) - 1
			string rangeStr = ATH_Dialog#GenericSingleStrPrompt("Set a range of layers to drift (e.g 4-12)", "Drift N layers")
			string sval1, sval2, separatorStr
			SplitString/E="\s*([0-9]+)\s*(-|,)\s*([0-9]+)" rangeStr, sval1, separatorStr, sval2
			variable val1 = str2num(sval1), val2 = str2num(sval2)
			if(val1 < 0 || val1 > val2 || val2 > lastlayerN || (val1==0 && val2==lastlayerN))
				return -1
			endif
			if(val1==0)
				Duplicate/FREE/RMD=[][][0, val2] w3dRef, waveFreeToAffine
				Duplicate/FREE/RMD=[][][val2+1, lastlayerN] w3dRef, waveFree1
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D waveFreeToAffine
				WAVE M_Affine
				Concatenate/O/KILL/NP=2 {M_Affine, waveFree1}, $gATH_w3dPathName
			elseif(val2==lastlayerN)
				Duplicate/FREE/RMD=[][][0, val1-1] w3dRef, waveFree0
				Duplicate/FREE/RMD=[][][val1, lastlayerN] w3dRef, waveFreeToAffine
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D waveFreeToAffine
				WAVE M_Affine
				Concatenate/O/KILL/NP=2 {waveFree0, M_Affine}, $gATH_w3dPathName
			else
				Duplicate/FREE/RMD=[][][0, val1-1] w3dRef, waveFree0
				Duplicate/FREE/RMD=[][][val1, val2] w3dRef, waveFreeToAffine
				Duplicate/FREE/RMD=[][][val2+1, lastlayerN] w3dRef, waveFree1
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D waveFreeToAffine
				WAVE M_Affine
				Concatenate/O/KILL/NP=2 {waveFree0, M_Affine, waveFree1}, $gATH_w3dPathName
			endif
			hookresult =  1
			break
	endswitch
	SetDataFolder currDF
	return hookresult
End

static Function CascadeDrift3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			DFREF currDF = GetDataFolderDFR()
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
			SVAR/Z/SDFR=dfr gATH_WindowNameStr
			SVAR/Z/SDFR=dfr gATH_w3dPathName
			WAVE/Z w3dRef = $gATH_w3dPathName
			NVAR/SDFR=dfr gATH_AnchorPositionX
			NVAR/SDFR=dfr gATH_AnchorPositionY
			NVAR/SDFR=dfr gATH_CursorPositionX
			NVAR/SDFR=dfr gATH_CursorPositionY
			NVAR/SDFR=dfr gATH_dx
			NVAR/SDFR=dfr gATH_dy
			NVAR/SDFR=dfr gATH_SubPixelMode
			NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(gATH_WindowNameStr):gLayer // Do not use /Z here.
			SetDataFolder dfr
			if(gATH_AnchorPositionX < 0 || gATH_AnchorPositionY < 0)
				print "You have first to set a reference position (anchor)"
			endif
			variable nlayers = DimSize(w3dRef, 2)
			if(gLayer==0 || gLayer == nlayers)
				hookresult =  1
				return hookresult
			endif
			gATH_CursorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_CursorPositionY = vcsr(I, gATH_WindowNameStr)
			variable dx = (gATH_AnchorPositionX - gATH_CursorPositionX)/gATH_dx
			variable dy = (gATH_AnchorPositionY - gATH_CursorPositionY)/gATH_dy
			dx = gATH_SubPixelMode ? dx : round(dx)
			dy = gATH_SubPixelMode ? dy : round(dy)			
			ImageTransform/P=(gLayer)/NP=(nlayers-gLayer) removeZplane w3dRef
			WAVE M_ReducedWave
			ImageTransform/O/P=0/NP=(gLayer) removeZplane w3dRef
			ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D w3dRef
			WAVE M_Affine
			Concatenate/O/KILL/NP=2 {M_ReducedWave, M_Affine}, $gATH_w3dPathName
			hookresult =  1
			SetDataFolder currDF
			break
	endswitch
	return hookresult
End

static Function FastModeCheckbox(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gATH_WindowNameStr
	SVAR/Z/SDFR=dfr gATH_imgNameTopWindowStr
	SVAR/Z/SDFR=dfr gATH_w3dPathName
	WAVE/Z w3dRef = $gATH_w3dPathName	
	NVAR/SDFR=dfr gATH_AnchorPositionX
	NVAR/SDFR=dfr gATH_AnchorPositionY
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	NVAR/SDFR=dfr gATH_FastMode
	switch(cb.checked)
		case 1:	// When we are in the fast mode, anchor will be a red do				
			gATH_FastMode = 1
			DoWindow/F $gATH_WindowNameStr
			Cursor/W=$gATH_WindowNameStr/K I
			DrawAction/L=Overlay/W=$gATH_WindowNameStr delete
			SetDrawLayer/W=$gATH_WindowNameStr Overlay
			DrawAction/W=$gATH_WindowNameStr delete
			SetDrawEnv/W=$gATH_WindowNameStr xcoord= top, ycoord= left, linefgc= (65535,0,0), fillbgc= (65535,0,0),fillfgc= (65535,0,0), fillpat= 1
			DrawOval (gATH_AnchorPositionX - gATH_dx/2),  (gATH_AnchorPositionY - gATH_dy/2), (gATH_AnchorPositionX + gATH_dx/2), (gATH_AnchorPositionY + gATH_dy/2)
			SetDrawLayer/W=$gATH_WindowNameStr UserFront
			//DrawTheRefCross(w3dRef,gATH_AnchorPositionX, gATH_AnchorPositionY,grfName=gATH_WindowNameStr)
			Button DriftImage, win=$cb.win, disable = 2
			Button CascadeDrift3D, win=$cb.win, disable = 2
			Button SelectedLayersDrift3D, win=$cb.win,  disable = 2
			Button FirstL, win=$cb.win, disable = 2
			Button LastL, win=$cb.win,  disable = 2
			Button LinearDC, win=$cb.win, disable = 2
			hookresult = 1
			break
		case 0:
			gATH_FastMode = 0
			DrawAction/L=Overlay/W=$gATH_WindowNameStr delete
			// Copy code here
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
			if(numtype(midOfImageX)) // If we have a Nan!
				Cursor/W=$gATH_WindowNameStr/I/F/L=0/H=1/C=(1,65535,33232)/S=2/P I $gATH_imgNameTopWindowStr 0.5, 0.5
			else
				Cursor/W=$gATH_WindowNameStr/I/F/L=0/H=1/C=(1,65535,33232)/S=2 I $gATH_imgNameTopWindowStr midOfImageX, midOfImageY
			endif
			if(!numtype(gATH_AnchorPositionX))
				Button DriftImage, win=$cb.win, disable = 0
				Button CascadeDrift3D, win=$cb.win, disable = 0
				Button SelectedLayersDrift3D, win=$cb.win,  disable = 0
			endif
			Button FirstL, win=$cb.win, disable = 0
			Button LastL, win=$cb.win,  disable = 0
			Button LinearDC, win=$cb.win, disable = 0
			hookresult = 1
			break
	endswitch
	return hookresult
End

static Function InterStackAlignmentButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	// fast exit if not eventCode is not 2
	if (B_Struct.eventCode != 2)
		return 0
	endif
	if (B_Struct.eventMod & 2) // If you press shift use axis coordinates
		variable useTopLeftAxes = 1
	endif
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
	DFREF dfrS = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveDriftCorrection:SavedReferenceCoords:")	
	SVAR/Z/SDFR=dfr gATH_WindowNameStr
	SVAR/Z/SDFR=dfr gATH_w3dPathName
	SVAR/Z/SDFR=dfr gATH_w3dBackupPathNameStr
	WAVE/Z w3dRef = $gATH_w3dPathName
	NVAR/SDFR=dfr gATH_CursorPositionX
	NVAR/SDFR=dfr gATH_CursorPositionY
	NVAR/SDFR=dfr/Z gATH_AnchorPositionX
	NVAR/SDFR=dfr/Z gATH_AnchorPositionY	
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	NVAR/SDFR=dfr gATH_SubPixelMode
	NVAR/SDFR=dfrS/Z gATH_SavedRefRelCoordX, gATH_SavedRefRelCoordY
	NVAR/SDFR=dfrS/Z gATH_SavedRefCoordX, gATH_SavedRefCoordY
	SVAR/SDFR=dfrS/Z gATH_SavedRefRelCoordSource
	NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(gATH_WindowNameStr):gLayer
	WAVE/Z w3dBackupRef = $gATH_w3dBackupPathNameStr
	WAVE/Z sourceWaveRef = $gATH_SavedRefRelCoordSource
	
	strswitch (B_Struct.ctrlName)
		case "SaveReferenceCoordB":
			variable relx, rely
			// NB: Save coordinates in pixels! We shouldn't depend on wave scaling
			if(!numtype(gATH_AnchorPositionX) && !NVAR_Exists(gATH_SavedRefRelCoordX)) // If anchor is not nan and we haven't saved before
				[relx, rely] = ATH_Graph#AxisValToRel2D(w3dRef, gATH_AnchorPositionX, gATH_AnchorPositionY)
				variable/G dfrS:gATH_SavedRefRelCoordX = relx
				variable/G dfrS:gATH_SavedRefRelCoordY = rely			
				variable/G dfrS:gATH_SavedRefCoordX =  gATH_AnchorPositionX // 25JUL25: Use axes reference in case waves do not have the same DimSize
				variable/G dfrS:gATH_SavedRefCoordY =  gATH_AnchorPositionY			
				string/G dfrS:gATH_SavedRefRelCoordSource = gATH_w3dPathname
			elseif(!numtype(gATH_AnchorPositionX) && NVAR_Exists(gATH_SavedRefRelCoordX)) // if anchor is a num and we've already saved a ref point
				[relx, rely] = ATH_Graph#AxisValToRel2D(w3dRef, gATH_AnchorPositionX, gATH_AnchorPositionY)
				gATH_SavedRefRelCoordX = relx
				gATH_SavedRefRelCoordY = rely
				gATH_SavedRefCoordX = gATH_AnchorPositionX
				gATH_SavedRefCoordY = gATH_AnchorPositionY
				gATH_SavedRefRelCoordSource = gATH_w3dPathname				
			endif
			Button ShowReferenceCoordB,disable=0,win=$B_Struct.win
			hookresult =  1			
			break
		case "ShowReferenceCoordB":
			//-------
			if(useTopLeftAxes)
				DrawTheRefCross(w3dRef, gATH_SavedRefCoordX, gATH_SavedRefCoordY, grfName=gATH_WindowNameStr,axisRel=0) // Axes coords
			else
				DrawTheRefCross(w3dRef, gATH_SavedRefRelCoordX, gATH_SavedRefRelCoordY, grfName=gATH_WindowNameStr, axisRel=1) // Relative coords				
			endif
			break
		// Reference should be relative, between 0 and 1 as the number of pixels and scale might be different. 
		case "DriftReferenceCoordB":
			gATH_CursorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_CursorPositionY = vcsr(I, gATH_WindowNameStr)	
			if(useTopLeftAxes)
				variable dx = (gATH_SavedRefCoordX - gATH_CursorPositionX)/gATH_dx
				variable dy = (gATH_SavedRefCoordY - gATH_CursorPositionY)/gATH_dy
				dx = gATH_SubPixelMode ? dx : round(dx)
				dy = gATH_SubPixelMode ? dy : round(dy)			
			else
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=w3dRef Affine2D w3dBackupRef			
				variable axisVx, axisVy
				[axisVx, axisVy] = ATH_Graph#RelToAxisVal2D(w3dRef, gATH_SavedRefRelCoordX, gATH_SavedRefRelCoordY)
				dx = (axisVx - gATH_CursorPositionX)/gATH_dx
				dy = (axisVy - gATH_CursorPositionY)/gATH_dy
				dx = gATH_SubPixelMode ? dx : round(dx)
				dy = gATH_SubPixelMode ? dy : round(dy)					
			endif
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=w3dRef Affine2D w3dBackupRef
				hookresult =  1					
			break
	endswitch
End

static Function DrawTheRefCross(WAVE wRef, variable xv, variable yv, [string grfName, int axisRel])
	// Draw the ref line
	string axisX, axisY
	grfName = StringFromList(0, grfName, "#") // Called from sub-window!
	[axisX, axisY] = ATH_Graph#GetAxes(grfName=grfName)
	if(axisRel)
		variable dx = DimDelta(wRef, 0)
		variable dy = DimDelta(wRef, 1)	
		variable axisValX = DimOffset(wRef, 0) + xv * DimSize(wRef,0) * dx
		variable axisValY = DimOffset(wRef, 1) + yv * DimSize(wRef,1) * dy
	else
		axisValX = xv
		axisValY = yv
	endif
	variable dr =  0.05 * DimDelta(wRef, 0) * DimSize(wRef,0)	
	SetDrawLayer/W=$grfName Overlay
	DrawAction/W=$grfName delete
	SetDrawEnv/W=$grfName xcoord= $axisX, ycoord= $axisY, linefgc= (65535,65535*axisRel,0), fillbgc= (65535,65535*axisRel,0),fillfgc= (65535,65535*axisRel,0), dash=2
	DrawLine/W=$grfName axisValX, axisValY-dr, axisValX, axisValY+dr
	SetDrawEnv/W=$grfName xcoord= $axisX, ycoord= $axisY, linefgc= (65535,65535*axisRel,0), fillbgc= (65535,65535*axisRel,0),fillfgc= (65535,65535*axisRel,0), dash=2
	DrawLine/W=$grfName axisValX-dr, axisValY, axisValX+dr, axisValY
	return 0
End
