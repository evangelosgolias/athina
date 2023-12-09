#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_iDriftCorrection
#pragma version = 2.0

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

/// Note: We cannot launch the operation without having a slider on at the moment
/// the problem is the WM functions used in ATH_Display. "GetWindow kwTopWin, property" fails
/// as it acts on the /EXT panel with "error: this operation is for graphs only"
/// static Function Append3DImageSlider() is the source of error.
/// Exterior windows are on top

static Function CreatePanel()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")

	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph"
		return -1
	endif

	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	//Check if you have already created the panel
	if(WinType(winNameStr + "#iDriftCorrection") == 7)
		return 1
	endif
	// We need a 3d wave
	if(WaveDims(w3dref) != 3)
		Abort "Operation needs an image stack (3d wave)"
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
		Cursor/W=$winNameStr/I/F/L=0/H=1/C=(1,65535,33232)/S=2/N=1/P I $imgNameTopGraphStr 0.5, 0.5
	else
		Cursor/W=$winNameStr/I/F/L=0/H=1/C=(1,65535,33232)/S=2/N=1 I $imgNameTopGraphStr midOfImageX, midOfImageY
	endif
	//Duplicate the wave for backup
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveDriftCorrection:" + winNameStr) // Root folder here
	string backupNameStr = NameOfWave(w3dref) + "_undo"
	Duplicate w3dref, dfr:$backupNameStr
	ModifyImage/W=$winNameStr $imgNameTopGraphStr ctabAutoscale=3
	// Create the global variables for panel
	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gATH_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gATH_w3dNameStr = NameOfWave(w3dref)
	string/G dfr:gATH_w3dBackupPathNameStr = GetWavesDataFolder(dfr:$backupNameStr, 2)
	string/G dfr:gATH_w3dBackupNameStr = PossiblyQuoteName(backupNameStr)
	variable/G dfr:gATH_w3dnlayers = DimSize(w3dref, 2)
	variable/G dfr:gATH_AnchorPositionX = NaN // Not set
	variable/G dfr:gATH_AnchorPositionY = NaN
	variable/G dfr:gATH_CursorPositionX
	variable/G dfr:gATH_CursorPositionY
	variable/G dfr:gATH_dx = DimDelta(w3dref, 0)
	variable/G dfr:gATH_dy = DimDelta(w3dref, 1)
	variable/G dfr:gATH_CursorPositionY
	variable/G dfr:gATH_FastMode = 0
	variable/G dfr:gATH_LDCstartL = NaN
	variable/G dfr:gATH_LDCendL = NaN
	variable/G dfr:gATH_LDCstartX = NaN
	variable/G dfr:gATH_LDCstartY = NaN
	variable/G dfr:gATH_LDCendX = NaN
	variable/G dfr:gATH_LDCendY = NaN
	NewPanel/K=1/EXT=0/N=iDriftCorrection/W=(0,0,165,380)/HOST=$winNameStr
	SetDrawLayer UserBack
	SetDrawEnv/W=iDriftCorrection fsize= 13,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=iDriftCorrection 2,16,"Interactive drift correction"
	Checkbox FastMode,pos={12.00,17.50},title="SHIFT+Click & drift",fSize=11,font="Menlo"
	Checkbox FastMode,value=0,disable=2,proc=ATH_iDriftCorrection#FastModeCheckbox
	SetDrawEnv textrgb= (2,39321,1), fname= "Menlo", fSize=9
	DrawText 7,85,"1. ---- Set anchor ----\n2. Arrows/wheel to ±layer \n3. SHIFT+click drifts layer+\n4. Shift+r restores layer."	
	Button SetAnchorCursor,pos={23.00,90.00},size={120.00,20.00},title="(Re)Set anchor",fSize=12,fColor=(39321,39321,39321)
	Button SetAnchorCursor,valueColor=(65535,0,0), proc=ATH_iDriftCorrection#SetAnchorCursorButton
	//All buttons, except restore3dwave and LDC, are disabled until the anchor is set
	Button DriftImage,pos={32.00,125.00},size={100.00,20.00},title="Drift Image",disable=2
	Button DriftImage,fSize=12,fColor=(0,65535,0),proc=ATH_iDriftCorrection#DriftImageButton
	Button SelectedLayersDrift,pos={32.00,160.00},size={100.00,20.00},fColor=(52428,52425,1),disable=2
	Button SelectedLayersDrift,title="Drift N images",fSize=12,proc=ATH_iDriftCorrection#DriftSelectedLayers3DWaveButton	
	Button CascadeDrift,pos={32.00,195.00},size={100.00,20.00},fColor=(65535,49157,16385),disable=2
	Button CascadeDrift,title="Cascade drift",fSize=12,proc=ATH_iDriftCorrection#CascadeDrift3DWaveButton
	// Draw the region for linear Drift correction
	SetDrawEnv dash= 3,fillpat= 0;DrawRect 18,225,144,310
	SetDrawEnv fsize= 10
	DrawText 30,242,"\\F'Menlo'Linear Drift Corr"
	Button LinearDC title="Drift",font="Menlo",fSize=12,fColor=(51664,44236,58982),proc=ATH_iDriftCorrection#LinearDCButton
	Button LinearDC pos={45,245},size={65,24}, help={"Linear Drift correct between start and end layers"}, disable=2
	Button FirstL title="Start",pos={26,280},size={50,20},proc=ATH_iDriftCorrection#SetStartLayerButton
	Button LastL title="End",pos={85,280},size={50,20},proc=ATH_iDriftCorrection#SetEndLayerButton
	//	
	Button Checkpointw3d,pos={32.00,320.00},size={100.00,20.00},fColor=(65535,49151,55704)
	Button Checkpointw3d,title="Checkpoint",fSize=12,proc=ATH_iDriftCorrection#Checkpointw3dButton	
	Button Restore3dwave,pos={32.00,355.00},size={100.00,20.00},fColor=(32768,54615,65535)
	Button Restore3dwave,title="Restore stack",fSize=12,proc=ATH_iDriftCorrection#Restore3DWaveButton
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
	NVAR/Z/SDFR=dfr gATH_w3dnlayers
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gATH_WindowNameStr):gLayer
	NVAR/SDFR=dfr gATH_AnchorPositionX
	NVAR/SDFR=dfr gATH_AnchorPositionY
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	variable dx, dy
	switch(s.eventCode)
		case 2: // Kill the window
			//CopyScales/I $gATH_w3dBackupPathNameStr, $gATH_w3dPathName
			Cursor/K I
			KillDataFolder/Z dfr
			SetWindow $s.winName, hook(iDriftWindowHook) = $""
			hookresult = 1
			break
		case 5:
			if(gATH_FastMode && s.eventMod==2 && gLayer < gATH_w3dnlayers && !numtype(gATH_AnchorPositionX)) //if SHIFT is pressed and Fast Mode is on
				dx = (gATH_AnchorPositionX - AxisValFromPixel(gATH_WindowNameStr, "top", s.mouseLoc.h))/gATH_dx
				dy = (gATH_AnchorPositionY - AxisValFromPixel(gATH_WindowNameStr, "left", s.mouseLoc.v))/gATH_dy
				MatrixOP/O/FREE layerFREE = layer(w3dRef, gLayer)
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=dfr:M_Affine2D Affine2D layerFREE // Will overwrite M_Affine
				//ImageTransform/O/P=(gLayer) removeZplane w3dRef
				//ImageTransform/O/P=(gLayer)/INSW=M_Affine insertZplane w3dRef
				WAVE ATH_Affine2D = dfr:M_Affine2D
				w3dRef[][][gLayer] = ATH_Affine2D[p][q]
				gLayer += 1
				ModifyImage/W=$gATH_WindowNameStr $gATH_imgNameTopWindowStr plane=gLayer
			endif
			hookresult = 1
			break
		case 11:
			// This will keep the slider always on. It has to be here and not before the switch
			// branch as GetWindow kwTopWin, property in Append3DImageSlider() will see the /EXT
			// window as top and cannot act on it!
			if(!NVAR_Exists(gLayer))
				ATH_Display#Append3DImageSlider()
			endif
			if(gATH_FastMode && s.eventMod==2)
				if((s.keyCode == 29 || s.keyCode == 30 || s.keyCode == 32) && gLayer < gATH_w3dnlayers) // right or up or SPACE
					gLayer+=1
				elseif((s.keyCode == 28 || s.keyCode == 31) && gLayer) // left or down
					gLayer-=1
				endif
				ModifyImage/W=$gATH_WindowNameStr $gATH_imgNameTopWindowStr plane=gLayer
			endif
			if(s.keyCode == 82) // if R (SHIFT+r) is pressed - Restore original layer
				w3dRef[][][gLayer] = w3dBackUpRef[p][q]
			endif		
			hookresult = 1
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
	//Cleanup when window is closed
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iImgAlignFolder"))
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/Z/SDFR=dfr gATH_w3dPathName
	SVAR/Z/SDFR=dfr gATH_w3dBackupPathNameStr

	switch(s.eventCode)
		case 2: // Kill the window
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
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/SDFR=dfr gATH_w3dPathname
	NVAR/SDFR=dfr gATH_AnchorPositionX
	NVAR/SDFR=dfr gATH_AnchorPositionY
	NVAR/SDFR=dfr gATH_FastMode
	variable xmax = DimSize($gATH_w3dPathname, 0)
	variable x0 = Dimoffset($gATH_w3dPathname, 0)
	variable ymax = DimSize($gATH_w3dPathname, 1)
	variable y0 = Dimoffset($gATH_w3dPathname, 1)
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			gATH_AnchorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_AnchorPositionY = vcsr(I, gATH_WindowNameStr)
			SetDrawLayer/W=$gATH_WindowNameStr Overlay
			DrawAction/W=$gATH_WindowNameStr delete
			SetDrawEnv/W=$gATH_WindowNameStr xcoord= top, ycoord= left, linefgc= (65535,0,0), dash=3
			DrawLine/W=$gATH_WindowNameStr x0, gATH_AnchorPositionY, xmax, gATH_AnchorPositionY
			SetDrawEnv/W=$gATH_WindowNameStr xcoord= top, ycoord= left, linefgc= (65535,0,0), dash=3
			DrawLine/W=$gATH_WindowNameStr gATH_AnchorPositionX, y0, gATH_AnchorPositionX, ymax
			SetDrawLayer/W=$gATH_WindowNameStr UserFront
			if(!numtype(gATH_AnchorPositionX))
				CheckBox FastMode, win = $B_Struct.win, disable = 0
				Button DriftImage, win=$B_Struct.win, disable = 0
				Button CascadeDrift, win=$B_Struct.win, disable = 0
				Button SelectedLayersDrift, win=$B_Struct.win,  disable = 0
			endif
			hookresult =  1
			break
	endswitch
	return hookresult
End

static Function DriftImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
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
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gATH_WindowNameStr):gLayer

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			gATH_CursorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_CursorPositionY = vcsr(I, gATH_WindowNameStr)
			variable dx = (gATH_AnchorPositionX - gATH_CursorPositionX)/gATH_dx
			variable dy = (gATH_AnchorPositionY - gATH_CursorPositionY)/gATH_dy
			MatrixOP/O/FREE layerFREE = layer(w3dRef, gLayer)
			ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=dfr:M_Affine2D Affine2D layerFREE
			WAVE ATH_Affine2D = dfr:M_Affine2D
			w3dRef[][][gLayer] = ATH_Affine2D[p][q]
			hookresult =  1
			break
	endswitch
	return hookresult
End


				
static Function SetStartLayerButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gATH_WindowNameStr
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gATH_WindowNameStr):gLayer
	NVAR/Z/SDFR=dfr gATH_LDCstartL
	NVAR/Z/SDFR=dfr gATH_LDCendL	
	NVAR/Z/SDFR=dfr gATH_LDCstartX
	NVAR/Z/SDFR=dfr	gATH_LDCstartY
	NVAR/Z/SDFR=dfr gATH_LDCendX
	NVAR/Z/SDFR=dfr	gATH_LDCendY
	variable nlayers	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
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
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gATH_WindowNameStr
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gATH_WindowNameStr):gLayer
	NVAR/Z/SDFR=dfr gATH_LDCstartL
	NVAR/Z/SDFR=dfr gATH_LDCendL	
	NVAR/Z/SDFR=dfr gATH_LDCstartX
	NVAR/Z/SDFR=dfr	gATH_LDCstartY
	NVAR/Z/SDFR=dfr gATH_LDCendX
	NVAR/Z/SDFR=dfr	gATH_LDCendY
	variable nlayers
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
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
	variable hookresult = 0
	DFREF currDF = GetDataFolderDFR()
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gATH_WindowNameStr
	NVAR/Z/SDFR=dfr gATH_LDCstartL
	NVAR/Z/SDFR=dfr gATH_LDCendL
	SVAR/Z/SDFR=dfr gATH_w3dPathName
	WAVE/Z w3dRef = $gATH_w3dPathName
	NVAR/Z/SDFR=dfr gATH_LDCstartX
	NVAR/Z/SDFR=dfr	gATH_LDCstartY
	NVAR/Z/SDFR=dfr gATH_LDCendX
	NVAR/Z/SDFR=dfr	gATH_LDCendY
	NVAR/SDFR=dfr gATH_dx
	NVAR/SDFR=dfr gATH_dy
	variable x0, y0, x1, y1, slope, shift, nlayers
	nlayers = gATH_LDCendL - gATH_LDCstartL + 1
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
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
				ATH_ImgAlign#LinearDriftPlanesABCursors(w3dref, wx, wy, startL = gATH_LDCstartL, endL = gATH_LDCendL)
				hookresult =  1
			endif
			break
	endswitch
	SetDataFolder currDF
	return hookresult
End

static Function Checkpointw3dButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
	SVAR/SDFR=dfr gATH_w3dBackupPathNameStr
	SVAR/SDFR=dfr gATH_w3dPathname
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			Duplicate/O $gATH_w3dPathname, $gATH_w3dBackupPathNameStr
			hookresult =  1
			break
	endswitch
	return hookresult
End

static Function Restore3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	//Complete
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgAlignFolder"))
	SVAR/SDFR=dfr gATH_w3dBackupPathNameStr
	SVAR/SDFR=dfr gATH_w3dPathname
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			Duplicate/O $gATH_w3dBackupPathNameStr, $gATH_w3dPathname
			hookresult =  1
			break
	endswitch
	return hookresult
End

static Function DriftSelectedLayers3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	variable hookresult = 0
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
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gATH_WindowNameStr):gLayer

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			SetDataFolder dfr
			gATH_CursorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_CursorPositionY = vcsr(I, gATH_WindowNameStr)
			variable dx = (gATH_AnchorPositionX - gATH_CursorPositionX)/gATH_dx
			variable dy = (gATH_AnchorPositionY - gATH_CursorPositionY)/gATH_dy
			variable lastlayerN = DimSize(w3dRef, 2) - 1
			string rangeStr = ATH_Dialog#GenericSingleStrPrompt("Set a range of layers to drift (e.g 4-12)", "Drift N layers")
			string sval1, sval2, separatorStr
			SplitString/E="\s*([0-9]+)\s*(-|,)\s*([0-9]+)" rangeStr, sval1, separatorStr, sval2
			variable val1 = str2num(sval1), val2 = str2num(sval2)
			if(val1 < 0 || val1 > val2 || val2 > lastlayerN)
				print "Skipped"
				return -1
			endif
			Duplicate/FREE/RMD=[][][0, val1-1] w3dRef, waveFree0
			Duplicate/FREE/RMD=[][][val1, val2] w3dRef, waveFreeToAffine
			Duplicate/FREE/RMD=[][][val2+1, lastlayerN] w3dRef, waveFree1
			ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D waveFreeToAffine
			WAVE M_Affine
			Concatenate/O/KILL/NP=2 {waveFree0, M_Affine, waveFree1}, $gATH_w3dPathName
			hookresult =  1
			break
	endswitch
	SetDataFolder currDF
	return hookresult
End

static Function CascadeDrift3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
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
	NVAR gLayer = root:Packages:WM3DImageSlider:$(gATH_WindowNameStr):gLayer // Do not use /Z here.

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
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
			ImageTransform/P=(gLayer)/NP=(nlayers-gLayer) removeZplane w3dRef
			WAVE M_ReducedWave
			ImageTransform/O/P=0/NP=(gLayer) removeZplane w3dRef
			ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D w3dRef
			WAVE M_Affine
			Concatenate/O/KILL/NP=2 {M_ReducedWave, M_Affine}, $gATH_w3dPathName
			hookresult =  1
			break
	endswitch
	SetDataFolder currDF
	return hookresult
End

static Function FastModeCheckbox(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gATH_WindowNameStr
	SVAR/Z/SDFR=dfr gATH_imgNameTopWindowStr
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
			Button DriftImage, win=$cb.win, disable = 2
			Button CascadeDrift, win=$cb.win, disable = 2
			Button SelectedLayersDrift, win=$cb.win,  disable = 2
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
				Button CascadeDrift, win=$cb.win, disable = 0
				Button SelectedLayersDrift, win=$cb.win,  disable = 0
			endif
			Button FirstL, win=$cb.win, disable = 0
			Button LastL, win=$cb.win,  disable = 0
			Button LinearDC, win=$cb.win, disable = 0
			hookresult = 1
			break
	endswitch
	return hookresult
End
