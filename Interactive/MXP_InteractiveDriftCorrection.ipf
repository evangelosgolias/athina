#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

/// Interactive drift correction of a 3D wave

Function MXP_CreateInteractiveDriftCorrectionPanel()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable midOfImageX = 0.5 * DimSize(w3dref,0) * DimDelta(w3dref,0)
	variable midOfImageY = 0.5 * DimSize(w3dref,1) * DimDelta(w3dref,1)
	Cursor/W=$winNameStr/I/F/L=0/H=1/C=(65535,65535,0)/S=2 I $imgNameTopGraphStr midOfImageX, midOfImageY
	
	if(WaveDims(w3dref) != 3)
		Abort "Operation needs an image stack (3d wave)"
	endif
	//Duplicate the wave for backup
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:InteractiveDriftCorrection:" + winNameStr) // Root folder here
	string backupNameStr = NameOfWave(w3dref) + "_undo"
	Duplicate/O w3dref, dfr:$backupNameStr
	if(!(WaveType(w3dref) & 0x02 || WaveType(w3dref) & 0x04)) // if not 32- or 64-bit float
		Redimension/S w3dref
	endif
	// Create the global variables for panel
	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gMXP_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gMXP_w3dNameStr = NameOfWave(w3dref)
	string/G dfr:gMXP_w3dBackupPathNameStr = GetWavesDataFolder(dfr:$backupNameStr, 2)
	string/G dfr:gMXP_w3dBackupNameStr = PossiblyQuoteName(backupNameStr)
	variable/G dfr:gMXP_nrCascadeImages = 1
	variable/G dfr:gMXP_AnchorPositionX = midOfImageX
	variable/G dfr:gMXP_AnchorPositionY = midOfImageY
	variable/G dfr:gMXP_CursorPositionX
	variable/G dfr:gMXP_CursorPositionY
	
	NewPanel/K=1/EXT=0/N=iDriftCorrection/W=(0,0,165,260)/HOST=$winNameStr
	ShowInfo/CP=0/W=$winNameStr
	SetDrawLayer UserBack
	SetDrawEnv/W=iDriftCorrection fsize= 13,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=iDriftCorrection 2,16,"Interactive drift correction"
	SetDrawEnv/W=iDriftCorrection dash= 3,fillpat= 0
	DrawRect/W=iDriftCorrection 19,120,144,216
	SetDrawEnv/W=iDriftCorrection textrgb= (1,12815,52428)
	DrawText/W=iDriftCorrection 27,209,"N < 0 cascades until\r    the end of stack"
	Button SetAnchorCursor,pos={23.00,38.00},size={120.00,20.00}
	Button SetAnchorCursor,title="(Re)Set anchor (I)",fSize=12
	Button SetAnchorCursor,fColor=(65535,32768,32768), proc=MXP_SetAnchorCursorButton
	Button DriftImage,pos={32.00,78.00},size={100.00,20.00},title="DriftImage"
	Button DriftImage,fSize=12,proc=MXP_DriftImageButton
	Button CascadeDrift,pos={32.00,124.00},size={100.00,20.00},title="Cascade Drift"
	Button CascadeDrift,fSize=12,proc=MXP_CascadeDriftrButton
	SetVariable NrImages,pos={33.00,157.00},size={100.00,18.00},title="N =",fSize=12
	SetVariable NrImages, limits={-1,inf,1}, value=_NUM:1,live=1, proc=MXP_SetNrCascadeImagesVar
	Button Restore3dwave,pos={32.00,230.00},size={100.00,20.00}
	Button Restore3dwave,title="Restore stack",fSize=12,proc=Restore3DWaveButton
	
	//Tranfer info re dfr to controls
	SetWindow $winNameStr#iDriftCorrection userdata(MXP_DFREF_iAlign) = "root:Packages:MXP_DataFolder:InteractiveDriftCorrection:" + PossiblyQuoteName(winNameStr)
	// Set hook to the graph, killing the graph kills the iDriftCorrection linked folder
	SetWindow $winNameStr userdata(MXP_DFREF_iAlign) = "root:Packages:MXP_DataFolder:InteractiveDriftCorrection:" + PossiblyQuoteName(winNameStr)
	SetWindow $winNameStr, hook(MyHook) = MXP_iDriftCorrectionGraphHookFunction // Set the hook
EndMacro

Function MXP_iDriftCorrectionGraphHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed
	//Cleanup when window is closed
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(s.winName, "", "MXP_DFREF_iAlign"))
    switch(s.eventCode)
		case 2: // Kill the window
			KillDataFolder/Z dfr
			SetWindow $s.winName, hook(MyHook) = $""
			hookresult = 1
			break
	endswitch
	return hookresult
End

Function MXP_SetAnchorCursorButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_DFREF_iAlign"))
	SVAR/SDFR=dfr gMXP_WindowNameStr
	NVAR/SDFR=dfr gMXP_AnchorPositionX
	NVAR/SDFR=dfr gMXP_AnchorPositionY
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			gMXP_AnchorPositionX = hcsr(I, gMXP_WindowNameStr)
			gMXP_AnchorPositionY = vcsr(I, gMXP_WindowNameStr)
			hookresult =  1
		break
	endswitch
	return hookresult
End

Function MXP_DriftImageButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_DFREF_iAlign"))
	SVAR/Z/SDFR=dfr gMXP_WindowNameStr
	SVAR/Z/SDFR=dfr gMXP_w3dPathName
	SVAR/Z/SDFR=dfr gMXP_w3dBackupPathNameStr
	WAVE/Z w3dRef = $gMXP_w3dPathName
	NVAR/SDFR=dfr gMXP_AnchorPositionX
	NVAR/SDFR=dfr gMXP_AnchorPositionY
	NVAR/SDFR=dfr gMXP_CursorPositionX
	NVAR/SDFR=dfr gMXP_CursorPositionY
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gMXP_WindowNameStr):gLayer
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			gMXP_CursorPositionX = hcsr(I, gMXP_WindowNameStr)
			gMXP_CursorPositionY = vcsr(I, gMXP_WindowNameStr)
			ImageTransform/P=(gLayer) getPlane w3dRef // get the image
			WAVE/Z M_ImagePlane
			variable dx = gMXP_CursorPositionX - gMXP_AnchorPositionX
			variable dy = gMXP_CursorPositionY - gMXP_AnchorPositionY
			ImageTransform/IOFF={-dx, -dy, 0} offsetImage M_ImagePlane
			WAVE/Z M_OffsetImage
			ImageTransform/O/P=(gLayer) removeZplane w3dRef
			ImageTransform/O/P=(gLayer)/INSW=M_OffsetImage insertZplane w3dRef
			// ImageTransform/P=(gLayer)/IOFF={dx, dy, 0} offsetImage w3dRef
			// is short but cannot /O, creates M_OffsetImage, so you need to duplicate
			// test it to see if it's faster
			KillWaves/Z M_ImagePlane, M_OffsetImage
			// Restore wave scaling, ImageTranform changes to unit step and zero offset
			CopyScales/I $gMXP_w3dBackupPathNameStr, $gMXP_w3dPathName
		hookresult =  1
		break
	endswitch
	return hookresult
End

Function MXP_CascadeDriftrButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	//Complete
	variable hookresult = 0, i
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_DFREF_iAlign"))
	SVAR/Z/SDFR=dfr gMXP_WindowNameStr
	SVAR/Z/SDFR=dfr gMXP_w3dPathName
	SVAR/Z/SDFR=dfr gMXP_w3dBackupPathNameStr
	WAVE w3dRef = $gMXP_w3dPathName
	NVAR/SDFR=dfr gMXP_AnchorPositionX
	NVAR/SDFR=dfr gMXP_AnchorPositionY
	NVAR/SDFR=dfr gMXP_CursorPositionX
	NVAR/SDFR=dfr gMXP_CursorPositionY
	NVAR/Z/SDFR=dfr gMXP_nrCascadeImages
	NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(gMXP_WindowNameStr):gLayer
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			gMXP_AnchorPositionX = hcsr(I, gMXP_WindowNameStr)
			gMXP_AnchorPositionY = vcsr(I, gMXP_WindowNameStr)
			variable dx = gMXP_CursorPositionX - gMXP_AnchorPositionX
			variable dy = gMXP_CursorPositionY - gMXP_AnchorPositionY
			if(gMXP_nrCascadeImages < 0)
				variable nlayers = DimSize(w3dRef, 2)
				variable itercnt = nlayers - gLayer
			endif
			for(i = 0;i < itercnt; i++)
				ImageTransform/P=(gLayer + i) getPlane w3dRef // get the image
				WAVE/Z M_ImagePlane
				ImageTransform/IOFF={-dx, -dy, 0} offsetImage M_ImagePlane
				WAVE/Z M_OffsetImage
				ImageTransform/O/P=(gLayer + i) removeZplane w3dRef
				ImageTransform/O/P=(gLayer + i)/INSW=M_OffsetImage insertZplane w3dRef
				print gLayer + i
			endfor
			KillWaves/Z M_ImagePlane, M_OffsetImage
			CopyScales/I $gMXP_w3dBackupPathNameStr, $gMXP_w3dPathName
			hookresult =  1
		break
	endswitch
	return hookresult
End

Function Restore3DWaveButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	//Complete
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_DFREF_iAlign"))
	SVAR/SDFR=dfr gMXP_w3dBackupNameStr
	SVAR/SDFR=dfr gMXP_w3dPathname
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			Duplicate/O $gMXP_w3dBackupNameStr, $gMXP_w3dPathname
			hookresult =  1
		break
	endswitch
	return hookresult
End

Function MXP_SetNrCascadeImagesVar(STRUCT WMSetVariableAction &sva) : SetVariableControl
	//Complete
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sva.win, "", "MXP_DFREF_iAlign"))
	NVAR/SDFR=dfr nrCascadeImages = dfr:gMXP_nrCascadeImages
	switch (sva.eventCode)
		case 1: 							// Mouse up
		case 2:							// Enter key
		case 3: 							// Live update
			nrCascadeImages = sva.dval
			// Alternative
			// SetVariable $(sva.ctrlname), win=$(sva.win), value=_NUM:sva.dval
			// ControlInfo/W=Graph0#iDriftCorrection NrImages
			hookresult = 1
			break
		case -1: 							// Control being killed
			break
	endswitch

	return hookresult
End

