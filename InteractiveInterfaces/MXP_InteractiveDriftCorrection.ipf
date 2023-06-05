#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

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

/// Interactive drift correction of a 3D wave

Function MXP_CreateInteractiveDriftCorrectionPanel()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph"
		return -1
	endif
		
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	//Check if you have already created the panel
	if(WinType(winNameStr + "#iDriftCorrection") == 7)
		print "iDriftCorrection panel already active"
		return 1
	endif
	// We need a 3d wave	
	if(WaveDims(w3dref) != 3)
		Abort "Operation needs an image stack (3d wave)"
	endif
	//Set cursor
	variable midOfImageX = 0.5 * DimSize(w3dref,0) * DimDelta(w3dref,0)
	variable midOfImageY = 0.5 * DimSize(w3dref,1) * DimDelta(w3dref,1)
	Cursor/W=$winNameStr/I/F/L=0/H=1/C=(1,65535,33232,20000)/S=2 I $imgNameTopGraphStr midOfImageX, midOfImageY
	

	//Duplicate the wave for backup
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:InteractiveDriftCorrection:" + winNameStr) // Root folder here
	string backupNameStr = NameOfWave(w3dref) + "_undo"
	Duplicate/O w3dref, dfr:$backupNameStr
	SetScale/P x, 0, 1, w3dref
	SetScale/P y, 0, 1, w3dref
	// Create the global variables for panel
	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gMXP_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gMXP_w3dNameStr = NameOfWave(w3dref)
	string/G dfr:gMXP_w3dBackupPathNameStr = GetWavesDataFolder(dfr:$backupNameStr, 2)
	string/G dfr:gMXP_w3dBackupNameStr = PossiblyQuoteName(backupNameStr)
	variable/G dfr:gMXP_AnchorPositionX = -1 // Not set
	variable/G dfr:gMXP_AnchorPositionY = -1
	variable/G dfr:gMXP_CursorPositionX
	variable/G dfr:gMXP_CursorPositionY
	
	NewPanel/K=1/EXT=0/N=iDriftCorrection/W=(0,0,165,250)/HOST=$winNameStr
	//ShowInfo/CP=0/W=$winNameStr
	SetDrawLayer UserBack

	SetDrawEnv/W=iDriftCorrection fsize= 13,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=iDriftCorrection 2,16,"Interactive drift correction"
	SetDrawEnv textrgb= (2,39321,1)
	DrawText 5,44,"Selected layer drifts towards \r        the anchor point set"
	//SetDrawEnv/W=iDriftCorrection dash= 3,fillpat= 0
	Button SetAnchorCursor,pos={23.00,50.00},size={120.00,20.00}
	Button SetAnchorCursor,title="(Re)Set anchor (I)",fSize=12
	Button SetAnchorCursor,fColor=(65535,0,0), proc=MXP_SetAnchorCursorButton
	Button DriftImage,pos={32.00,90.00},size={100.00,20.00},title="Drift Image"
	Button DriftImage,fSize=12,fColor=(0,65535,0),proc=MXP_DriftImageButton
	Button CascadeDrift,pos={32.00,130.00},size={100.00,20.00},fColor=(65535,49157,16385)
	Button CascadeDrift,title="Cascade drift",fSize=12,proc=CascadeDrift3DWaveButton
	Button SelectedLayersDrift,pos={32.00,170.00},size={100.00,20.00},fColor=(52428,52425,1)
	Button SelectedLayersDrift,title="Drift N layers",fSize=12,proc=DriftSelectedLayers3DWaveButton
	Button Restore3dwave,pos={32.00,210.00},size={100.00,20.00},fColor=(32768,54615,65535)
	Button Restore3dwave,title="Restore stack",fSize=12,proc=Restore3DWaveButton	
	//Tranfer info re dfr to controls
	SetWindow $winNameStr#iDriftCorrection userdata(MXP_iImgAlignFolder) = "root:Packages:MXP_DataFolder:InteractiveDriftCorrection:" + winNameStr
	SetWindow $winNameStr#iDriftCorrection hook(MyHook) = MXP_iDriftCorrectionPanelHookFunction
	// Set hook to the graph, killing the graph kills the iDriftCorrection linked folder
	SetWindow $winNameStr userdata(MXP_iImgAlignFolder) = "root:Packages:MXP_DataFolder:InteractiveDriftCorrection:" + winNameStr
	SetWindow $winNameStr, hook(MyHook) = MXP_iDriftCorrectionGraphHookFunction // Set the hook
End

Function MXP_iDriftCorrectionGraphHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed
	//Cleanup when window is closed
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(s.winName, "", "MXP_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gMXP_w3dPathName
	SVAR/Z/SDFR=dfr gMXP_w3dBackupPathNameStr
    switch(s.eventCode)
		case 2: // Kill the window
			//Restore wave scaling here as ImageTransform works better with non-scaled waves
			CopyScales/I $gMXP_w3dBackupPathNameStr, $gMXP_w3dPathName
			KillDataFolder/Z dfr
			SetWindow $s.winName, hook(MyHook) = $""
			Cursor/K I
			hookresult = 1
			break
	endswitch
	return hookresult
End

Function MXP_iDriftCorrectionPanelHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed
	//Cleanup when window is closed
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(s.winName, "", "MXP_iImgAlignFolder"))
	SVAR/SDFR=dfr gMXP_WindowNameStr
	SVAR/Z/SDFR=dfr gMXP_w3dPathName
	SVAR/Z/SDFR=dfr gMXP_w3dBackupPathNameStr

    switch(s.eventCode)
		case 2: // Kill the window
			//Restore wave scaling here as ImageTransform works better with non-scaled waves
			CopyScales/I $gMXP_w3dBackupPathNameStr, $gMXP_w3dPathName
			SetWindow $s.winName, hook(MyHook) = $""
			Cursor/K I
			SetDrawLayer/W=$gMXP_WindowNameStr Overlay
			DrawAction/W=$gMXP_WindowNameStr delete
			SetDrawLayer/W=$gMXP_WindowNameStr UserFront
			hookresult = 1
			break
	endswitch
	return hookresult
End

Function MXP_SetAnchorCursorButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_iImgAlignFolder"))
	SVAR/SDFR=dfr gMXP_WindowNameStr
	SVAR/SDFR=dfr gMXP_w3dPathname
	NVAR/SDFR=dfr gMXP_AnchorPositionX
	NVAR/SDFR=dfr gMXP_AnchorPositionY
	variable xmax = DimSize($gMXP_w3dPathname, 0)
	variable x0 = Dimoffset($gMXP_w3dPathname, 0)
	variable ymax = DimSize($gMXP_w3dPathname, 1)
	variable y0 = Dimoffset($gMXP_w3dPathname, 1)
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			gMXP_AnchorPositionX = hcsr(I, gMXP_WindowNameStr)
			gMXP_AnchorPositionY = vcsr(I, gMXP_WindowNameStr)
			SetDrawLayer/W=$gMXP_WindowNameStr Overlay
			DrawAction/W=$gMXP_WindowNameStr delete
			SetDrawEnv/W=$gMXP_WindowNameStr xcoord= top, ycoord= left, linefgc= (65535,0,0,20000), dash=0
			DrawLine/W=$gMXP_WindowNameStr x0, gMXP_AnchorPositionY, xmax, gMXP_AnchorPositionY
			SetDrawEnv/W=$gMXP_WindowNameStr xcoord= top, ycoord= left, linefgc= (65535,0,0,20000), dash=0
			DrawLine/W=$gMXP_WindowNameStr gMXP_AnchorPositionX, y0, gMXP_AnchorPositionX, ymax
			SetDrawLayer/W=$gMXP_WindowNameStr UserFront
			hookresult =  1
		break
	endswitch
	return hookresult
End

Function MXP_DriftImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gMXP_WindowNameStr
	SVAR/Z/SDFR=dfr gMXP_w3dPathName
	WAVE/Z w3dRef = $gMXP_w3dPathName
	NVAR/SDFR=dfr gMXP_AnchorPositionX
	NVAR/SDFR=dfr gMXP_AnchorPositionY
	NVAR/SDFR=dfr gMXP_CursorPositionX
	NVAR/SDFR=dfr gMXP_CursorPositionY
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gMXP_WindowNameStr):gLayer
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			if(gMXP_AnchorPositionX < 0 || gMXP_AnchorPositionY < 0)
				print "You have first to set a reference position (anchor)"
			endif
			gMXP_CursorPositionX = hcsr(I, gMXP_WindowNameStr)
			gMXP_CursorPositionY = vcsr(I, gMXP_WindowNameStr)
			ImageTransform/P=(gLayer) getPlane w3dRef // get the image
			WAVE M_ImagePlane
			variable dx = gMXP_AnchorPositionX - gMXP_CursorPositionX
			variable dy = gMXP_AnchorPositionY - gMXP_CursorPositionY 
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

Function Restore3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	//Complete
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_iImgAlignFolder"))
	SVAR/SDFR=dfr gMXP_w3dBackupPathNameStr
	SVAR/SDFR=dfr gMXP_w3dPathname
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			Duplicate/O $gMXP_w3dBackupPathNameStr, $gMXP_w3dPathname
			hookresult =  1
		break
	endswitch
	return hookresult
End


Function DriftSelectedLayers3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gMXP_WindowNameStr
	SVAR/Z/SDFR=dfr gMXP_w3dPathName
	WAVE/Z w3dRef = $gMXP_w3dPathName
	NVAR/SDFR=dfr gMXP_AnchorPositionX
	NVAR/SDFR=dfr gMXP_AnchorPositionY
	NVAR/SDFR=dfr gMXP_CursorPositionX
	NVAR/SDFR=dfr gMXP_CursorPositionY
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gMXP_WindowNameStr):gLayer
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			if(gMXP_AnchorPositionX < 0 || gMXP_AnchorPositionY < 0)
				print "You have first to set a reference position (anchor)"
			endif
			gMXP_CursorPositionX = hcsr(I, gMXP_WindowNameStr)
			gMXP_CursorPositionY = vcsr(I, gMXP_WindowNameStr)

			variable dx = gMXP_AnchorPositionX - gMXP_CursorPositionX
			variable dy = gMXP_AnchorPositionY - gMXP_CursorPositionY 
			variable i, nLayerL
			variable nlayers = DimSize(w3dRef, 2)
			string layersListStr
			string inputStr = MXP_GenericSingleStrPrompt("Select layers to drift, e.g \"2-5,7,9-12,50\", operation is slow for many layers", "Drift selected layers")
			if(strlen(inputStr))	
				layersListStr = MXP_ExpandRangeStr(inputStr)
			else
				hookresult =  1
				return 1
			endif
			variable imax = ItemsInList(layersListStr)
			print "Drift operation started (it might take some time)"
			for(i = 0; i < imax; i++)
				nLayerL = str2num(StringFromList(i, layersListStr))
				if(nLayerL > nlayers)
					print "Layer number out of range: ", num2str(nLayerL)
					Abort
				endif
				ImageTransform/P=(nLayerL) getPlane w3dRef // get the image
				WAVE M_ImagePlane				
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D M_ImagePlane // Will overwrite M_Affine
				WAVE M_Affine
				ImageTransform/O/P=(nLayerL) removeZplane w3dRef
				ImageTransform/O/P=(nLayerL)/INSW=M_Affine insertZplane w3dRef
			endfor
			KillWaves/Z M_Affine, M_ImagePlane
			print "Operation completed. Drifted layers " + inputStr
		hookresult =  1
		break
	endswitch
	return hookresult
End

Function CascadeDrift3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_iImgAlignFolder"))
	SVAR/Z/SDFR=dfr gMXP_WindowNameStr
	SVAR/Z/SDFR=dfr gMXP_w3dPathName
	WAVE/Z w3dRef = $gMXP_w3dPathName
	NVAR/SDFR=dfr gMXP_AnchorPositionX
	NVAR/SDFR=dfr gMXP_AnchorPositionY
	NVAR/SDFR=dfr gMXP_CursorPositionX
	NVAR/SDFR=dfr gMXP_CursorPositionY
	NVAR gLayer = root:Packages:WM3DImageSlider:$(gMXP_WindowNameStr):gLayer // Do not use /Z here.
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			if(gMXP_AnchorPositionX < 0 || gMXP_AnchorPositionY < 0)
				print "You have first to set a reference position (anchor)"
			endif
			variable nlayers = DimSize(w3dRef, 2)
			if(gLayer==0 || gLayer == nlayers)
				hookresult =  1
				return hookresult
			endif
			gMXP_CursorPositionX = hcsr(I, gMXP_WindowNameStr)
			gMXP_CursorPositionY = vcsr(I, gMXP_WindowNameStr)

			variable dx = gMXP_AnchorPositionX - gMXP_CursorPositionX
			variable dy = gMXP_AnchorPositionY - gMXP_CursorPositionY 
			// TODO: IP bug, program crashes
			// Remove the first glayer layers
//			ImageTransform/P=0/NP=(gLayer) removeZplane w3dRef
//			WAVE M_ReducedWave
//			ImageTransform/O/P=(gLayer)/NP=(nlayers-gLayer) removeZplane w3dRef
//			ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D w3dRef
//			WAVE M_Affine
//			Concatenate/O/KILL/NP=2 {M_ReducedWave, M_Affine}, $gMXP_w3dPathName
		hookresult =  1
		break
	endswitch
	return hookresult
End
