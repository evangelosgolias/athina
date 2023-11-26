#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_iFastDriftCorrection
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

/// Design: Change slide number using the arrows, click-register
/// for drift. You have to press the first layer you want to drift
/// to use it as your reference. gLayer is the reference layer (acti-
/// ve layer when launched).

// How to find the position to drift
// variable xpos =  AxisValFromPixel("", "Bottom", s.mouseLoc.h)
// variable ypos = AxisValFromPixel("", "Left", s.mouseLoc.v)

static Function MakePanel()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph"
		return -1
	endif
		
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	//Check if you have already created the panel
	if(WinType(winNameStr + "#iFastDriftCorrection") == 7)
		print "iDriftCorrection panel already active"
		return 1
	endif
	// We need a 3d wave	
	if(WaveDims(w3dref) != 3)
		Abort "Operation needs an image stack (3d wave)"
	endif	

	//Duplicate the wave for backup
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveFastDriftCorrection:" + winNameStr) // Root folder here
	string backupNameStr = NameOfWave(w3dref) + "_undo"
	Duplicate/O w3dref, dfr:$backupNameStr
	SetScale/P x, 0, 1, w3dref
	SetScale/P y, 0, 1, w3dref
	// Create the global variables for panel
	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gATH_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gATH_w3dNameStr = NameOfWave(w3dref)
	string/G dfr:gATH_w3dBackupPathNameStr = GetWavesDataFolder(dfr:$backupNameStr, 2)
	string/G dfr:gATH_w3dBackupNameStr = PossiblyQuoteName(backupNameStr)
	variable/G dfr:gATH_AnchorPositionX = -1 // Not set
	variable/G dfr:gATH_AnchorPositionY = -1
	variable/G dfr:gATH_CursorPositionX
	variable/G dfr:gATH_CursorPositionY

	variable midOfImageX = 0.5 * DimSize(w3dref,0) * DimDelta(w3dref,0)
	variable midOfImageY = 0.5 * DimSize(w3dref,1) * DimDelta(w3dref,1)
	Cursor/W=$winNameStr/I/F/L=0/H=1/C=(1,65535,33232)/S=2 I $imgNameTopGraphStr midOfImageX, midOfImageY

	variable nlayers = DimSize(w3dref, 2)
	Make/N=(nlayers) dfr:xDrift = 0
	Make/N=(nlayers) dfr:yDrift = 0

	NewPanel/K=1/EXT=0/N=iFastDriftCorrection/W=(0,0,165,180)/HOST=$winNameStr
	//ShowInfo/CP=0/W=$winNameStr
	SetDrawLayer UserBack

	SetDrawEnv/W=iFastDriftCorrection fsize= 13,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=iFastDriftCorrection 2,16,"Interactive drift correction"
	SetDrawEnv textrgb= (2,39321,1)
	DrawText 5,74,"  Set the reference with the\rcursor & press \"Set Anchor\"\r use arrows to change layer \r and click to register drifts."
	//SetDrawEnv/W=iDriftCorrection dash= 3,fillpat= 0
	Button SetAnchor,pos={32.00,85.00},size={100.00,20.00},title="Set anchor",fSize=12,fColor=(0,0,0)//,proc=ATH_FastDriftSetAnchorCursorButton			
	Button ApplyDrifts,pos={32.00,115.00},size={100.00,20.00},fColor=(0,0,0),title="Apply drifts",fSize=12//,proc=ATH_FastDriftImageStackButton
	Button RestoreImgStack,pos={32.00,145.00},size={100.00,20.00},title="Restore stack",fSize=12,fColor=(0,0,0)//,proc=ATH_FastDriftRestore3DWaveButton	
	//Tranfer info re dfr to controls
	SetWindow $winNameStr#iFastDriftCorrection userdata(ATH_iImgFastAlignFolder) = "root:Packages:ATH_DataFolder:InteractiveFastDriftCorrection:" + winNameStr
	SetWindow $winNameStr#iFastDriftCorrection hook(MyFastDriftCorrPanelHook) = ATH_iFastDriftCorrection#PanelHookFunction
	// Set hook to the graph, killing the graph kills the iDriftCorrection linked folder
	SetWindow $winNameStr userdata(ATH_iImgFastAlignFolder) = "root:Packages:ATH_DataFolder:InteractiveFastDriftCorrection:" + winNameStr
	SetWindow $winNameStr, hook(MyFastDriftCorrGraphHook) = ATH_iFastDriftCorrection#GraphHookFunction // Set the hook
End

static Function GraphHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed
	//Cleanup when window is closed
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iImgFastAlignFolder"))
	SVAR/Z/SDFR=dfr gATH_w3dPathName
	SVAR/Z/SDFR=dfr gATH_w3dBackupPathNameStr
    switch(s.eventCode)
		case 2: // Kill the window
			//Restore wave scaling here as ImageTransform works better with non-scaled waves
			CopyScales/I $gATH_w3dBackupPathNameStr, $gATH_w3dPathName
			SetWindow $s.winName, hook(MyFastDriftCorrGraphHook) = $""
			KillDataFolder/Z dfr
			hookresult = 1
			break
	endswitch
	return hookresult
End

static Function PanelHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed
	//Cleanup when window is closed
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iImgFastAlignFolder"))
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/Z/SDFR=dfr gATH_w3dPathName
	SVAR/Z/SDFR=dfr gATH_w3dBackupPathNameStr

    switch(s.eventCode)
		case 2: // Kill the window
			//Restore wave scaling here as ImageTransform works better with non-scaled waves
			CopyScales/I $gATH_w3dBackupPathNameStr, $gATH_w3dPathName
			Cursor/K I
			SetWindow $s.winName, hook(MyFastDriftCorrPanelHook) = $""
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
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgFastAlignFolder"))
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/SDFR=dfr gATH_w3dPathname
	NVAR/SDFR=dfr gATH_AnchorPositionX
	NVAR/SDFR=dfr gATH_AnchorPositionY
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
			SetDrawEnv/W=$gATH_WindowNameStr xcoord= top, ycoord= left, linefgc= (65535,43690,0), dash=0
			DrawLine/W=$gATH_WindowNameStr x0, gATH_AnchorPositionY, xmax, gATH_AnchorPositionY
			SetDrawEnv/W=$gATH_WindowNameStr xcoord= top, ycoord= left, linefgc= (65535,43690,0), dash=0
			DrawLine/W=$gATH_WindowNameStr gATH_AnchorPositionX, y0, gATH_AnchorPositionX, ymax
			SetDrawLayer/W=$gATH_WindowNameStr UserFront
			hookresult =  1
		break
	endswitch
	return hookresult
End

static Function DriftImageStackButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgFastAlignFolder"))
	SVAR/Z/SDFR=dfr gATH_WindowNameStr
	SVAR/Z/SDFR=dfr gATH_w3dPathName
	WAVE/Z w3dRef = $gATH_w3dPathName
	NVAR/SDFR=dfr gATH_AnchorPositionX
	NVAR/SDFR=dfr gATH_AnchorPositionY
	NVAR/SDFR=dfr gATH_CursorPositionX
	NVAR/SDFR=dfr gATH_CursorPositionY
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gATH_WindowNameStr):gLayer
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			if(gATH_AnchorPositionX < 0 || gATH_AnchorPositionY < 0)
				print "You have first to set a reference position (anchor)"
			endif
			gATH_CursorPositionX = hcsr(I, gATH_WindowNameStr)
			gATH_CursorPositionY = vcsr(I, gATH_WindowNameStr)
			ImageTransform/P=(gLayer) getPlane w3dRef // get the image
			WAVE M_ImagePlane
			variable dx = gATH_AnchorPositionX - gATH_CursorPositionX
			variable dy = gATH_AnchorPositionY - gATH_CursorPositionY 
			MatrixOP/O/FREE layerFREE = layer(w3dRef, gLayer)
			ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D layerFREE // Will overwrite M_Affine	
			WAVE M_Affine
			ImageTransform/O/P=(gLayer) removeZplane w3dRef
			ImageTransform/O/P=(gLayer)/INSW=M_Affine insertZplane w3dRef
			KillWaves/Z M_Affine, M_ImagePlane
		hookresult =  1
		break
	endswitch
	return hookresult
End

static Function Restore3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	//Complete
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImgFastAlignFolder"))
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
