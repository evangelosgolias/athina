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

Function MXP_AutoRangeTopImage()
	// Autoscale image of the top grap
	WAVE wRef = MXP_TopImageToWaveRef()
	string matchPattern = "ctab= {%*f,%*f,%[A-Za-z],%d}" //%* -> Read but not store
	string colorScaleStr
	variable cmapSwitch
	sscanf StringByKey("RECREATION",Imageinfo("",NameOfWave(wRef),0)), matchPattern, colorScaleStr, cmapSwitch
	variable wmin =WaveMin(wRef)
	variable wmax =WaveMax(wRef)	
	ModifyImage $PossiblyQuoteName(NameOfWave(wRef)) ctab= {wmin,wmax,$colorScaleStr,cmapSwitch} // Autoscale Image
End

Function MXP_AutoRangeTopImagePerPlaneAndVisibleArea()
	// Autoscale image of the top grap
	WAVE wRef = MXP_TopImageToWaveRef()
	string matchPattern = "ctab= {%*f,%*f,%[A-Za-z],%d}" //%* -> Read but not store
	string colorScaleStr
	variable cmapSwitch
	sscanf StringByKey("RECREATION",Imageinfo("",NameOfWave(wRef),0)), matchPattern, colorScaleStr, cmapSwitch
	ModifyImage $PossiblyQuoteName(NameOfWave(wRef)) ctabAutoscale=3 // Autoscale Image	
	ModifyImage $PossiblyQuoteName(NameOfWave(wRef)) ctab= {*,*,$colorScaleStr,cmapSwitch} // Autoscale Image	
End

Function MXP_SetZScaleOfImageStack() // Uses top graph
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE waveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable getScaleXY
	string cmdStr = "0, 0", setScaleZStr
	string msgDialog = "Scale Z direction of stack"
	string strPrompt = "Set firstVal,  lastVal in quotes (string).\n Leave \"\"  and press continue for autoscaling."
	if(WaveDims(waveRef) == 2)
		getScaleXY = NumberByKey("FOV(µm)", note(waveRef), ":", "\n")
		if(numtype(getScaleXY) == 2)
			getScaleXY = 0
		endif
		SetScale/I x, 0, getScaleXY, waveRef
		SetScale/I y, 0, getScaleXY, waveRef
	elseif(WaveDims(waveRef) == 3)
		// We deal with the x, y scale when we import the wave
		//getScaleXY = NumberByKey("FOV(µm)", note(waveRef), ":", "\n")
		//SetScale/I x, 0, getScaleXY, waveRef
		//SetScale/I y, 0, getScaleXY, waveRef
		DoWindow/F $winNameStr
		setScaleZStr = MXP_GenericSingleStrPrompt(strPrompt, msgDialog)
		string dataPathStr = GetWavesDataFolder(waveRef, 2)
		if(strlen(setScaleZStr))
		cmdStr = "SetScale/I z " + setScaleZStr + ", " + dataPathStr
		Execute/Z cmdStr
		endif
	endif
End

Function MXP_ImageSelectToCopyScale() // Uses top graph
	WAVE wRef =MXP_TopImageToWaveRef()
	// Select the first wave from browser selection
	string selectedWavesStr = MXP_SelectWavesInModalDataBrowser("Select an image to set common dimension scaling")
	WAVE sourceWaveRef = $StringFromList(0, selectedWavesStr)
	CopyScales/I sourceWaveRef, wRef
End

Function MXP_Wave2RGBImage(WAVE wRef)
	ColorTab2Wave Grays
	WAVE M_Colors
	Wavestats/Q/M=1 wRef
	SetScale/I x, V_min, V_max, M_Colors
	ImageTransform/C=M_Colors cmap2rgb wRef
	WAVE M_RGBOut
	KillWaves/Z M_Colors
	string newnameStr = NameOfWave(wRef) + "_RGB"
	Rename M_RGBOut, $newnameStr
End

Function MXP_NormaliseImageStackWithImage(WAVE w3dRef, WAVE w2dRef)
	// If you have 16-bit waves then Redimension/S to SP
	if(WaveType(w3dRef) == 80 || WaveType(w3dRef) == 16)
		Redimension/S w3dRef
	endif
	if(WaveType(w2dRef) == 80 || WaveType(w2dRef) == 16)
		Redimension/S w2dRef
	endif
	string normWaveStr = NameOfWave(w3dRef) + "_norm"
	MatrixOP/O $normWaveStr = w3dRef / w2dRef
End

Function MXP_NormaliseImageStackWithImageStack(WAVE w3dRef1, WAVE w3dRef2)
	// If you have 16-bit waves then Redimension/S to SP
	if(WaveType(w3dRef1) == 80 || WaveType(w3dRef1) == 16)
		Redimension/S w3dRef1
	endif
	if(WaveType(w3dRef2) == 80 || WaveType(w3dRef2) == 16)
		Redimension/S w3dRef2
	endif
	string normWaveStr = NameOfWave(w3dRef1) + "_norm"
	MatrixOP/O $normWaveStr = w3dRef1 / w3dRef2
End

Function MXP_NormaliseImageStackWithProfile(WAVE w3dRef, WAVE profWaveRef)
	// Normalise a 3d wave (stack) with a line profile (1d wave) along the layer (z) direction
	if(WaveType(w3dRef) == 80 || WaveType(w3dRef) == 16)
		Redimension/S w3dRef
	endif
	if(WaveType(profWaveRef) == 80 || WaveType(profWaveRef) == 16)
		Redimension/S profWaveRef
	endif
		
	string normWaveStr = NameOfWave(w3dRef) + "_norm"
	variable nlayers = DimSize(w3dRef, 2) 
	variable npnts = DimSize(profWaveRef, 0)
	
	if(nlayers != npnts)
		Duplicate/O/FREE profWaveRef, profWaveRefFREE
		Redimension/N=(1, 1, nlayers) profWaveRefFREE
		if(nlayers > npnts)
			profWaveRefFREE[0][0][npnts,] = profWaveRef[npnts-1]
			MatrixOP/O $normWaveStr = w3dRef * rec(profWaveRefFREE)
		else
			profWaveRefFREE = profWaveRef[r]
			MatrixOP/O $normWaveStr = w3dRef * rec(profWaveRefFREE)
		endif
		return 0
	else 
		Duplicate/O/FREE profWaveRef, profWaveRefFREE
		Redimension/N=(1, 1, nlayers) profWaveRefFREE
		MatrixOP/O $normWaveStr = w3dRef * rec(profWaveRefFREE)
		return 0
	endif
End

Function MXP_GetScaledZoominImageWindow()
	// Get a the current window view as a new image with appropriate scaling.
	// Works for 2D/3D waves
	// CAUTION: If axes have different configuration the function will not work properly. 
	// You should have left and top axis with the origin at the too left corner so 
	// GetAxis/Q/W=$winNameStr left // MAXPEEM images V_min > V_max
	// and
	// GetAxis/Q/W=$winNameStr top // MAXPEEM images V_min < V_max


	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE wref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string msg, wavenameStr, bufferStr
	variable newLeftAxisLen, newTopAxisLen, P0, Q0, P1, Q1, PMax, QMax, dx, dy, nrows, ncols
	//Left axis
	GetAxis/Q/W=$winNameStr top // MAXPEEM images V_min < V_max, see P0, P1
	if(V_flag)
		return -1
	endif
	dx = DimDelta(wref, 0)
	P0 = ScaleToIndex(wref, V_min, 0)
	P1 = ScaleToIndex(wref, V_max, 0)
	PMax = DimSize(wref, 0) 
	
	if(P0 < 0)
		P0 = 0
	endif
			
	if(P1 > Pmax)
		P1 = PMax
	endif
	
	if((P0 < 0 && P1 < 0) || (P0 > PMax && P1 > PMax))
		return -1
	endif
	
	nrows = abs(P0-P1)
	newTopAxisLen = (nrows - 1) * dx
	//Top axis
	GetAxis/Q/W=$winNameStr left // MAXPEEM images V_min > V_max, see Q0, Q1
	if(V_flag)
		return -1
	endif
	dy = DimDelta(wref, 1)
	Q0 = ScaleToIndex(wref, V_max, 1)
	Q1 = ScaleToIndex(wref, V_min, 1)	
	QMax = DimSize(wref, 1)
	if(Q0 < 0)
		Q0 = 0
	endif
		
	if(Q1 > Qmax)
		Q1 = QMax
	endif
	
	ncols = abs(Q0-Q1)
	newLeftAxisLen = (ncols - 1)* dy
		
	if((Q0 < 0 && Q1 < 0) || (Q0 > QMax && Q1 > QMax))
		return -1
	endif
	
	DFREF cdfr = GetDataFolderDFR()
	
	// Reset now P0, Q0 use them as offsets
	P0 = min(P0, P1)
	Q0 = min(Q0, Q1)	
	if(WaveDims(wref) == 3)
		NVAR/Z gLayer = root:Packages:WM3DImageSlider:$(winNameStr):gLayer	
		if(NVAR_Exists(gLayer))
			bufferStr = NameOfWave(wref) + "_layer_" + num2str(gLayer) + "_ZM"
			wavenameStr = CreateDataObjectName(cdfr, bufferStr, 1, 0, 4)
			Make/N=(nrows, ncols) $wavenameStr /WAVE = wReftmp
			SetScale/I x, 0, newTopAxisLen, wReftmp
			SetScale/I y, 0, newLeftAxisLen, wReftmp
			wReftmp = wref[P0 + p][Q0 + q][gLayer]
			sprintf msg, "Part(R/C) of %s: (%d, %d, %d, %d) layer%d", NameOfWave(wref), P0, P1, Q0, Q1, gLayer
		else
			Abort "Add a slider in your image stack (3d wave), I cannot guess the layer you want me to act on!"
		endif
	elseif(WaveDims(wref) == 2)
		bufferStr = NameOfWave(wref) + "_ZM"
		wavenameStr = CreateDataObjectName(cdfr, bufferStr, 1, 0, 4)
		Make/N=(nrows, ncols) $wavenameStr /WAVE = wReftmp
		SetScale/I x, 0, newTopAxisLen, wReftmp
		SetScale/I y, 0, newLeftAxisLen, wReftmp
		wReftmp = wref[P0 + p][Q0 + q]
		sprintf msg, "Part(R/C) of %s: (%d, %d, %d, %d)", NameOfWave(wref), P0, P1, Q0, Q1
	else
		Abort "Operation needs a image or image stack (2d/3d wave)"
	endif
	Note wReftmp, msg
End

Function MXP_GetLayerFromImageStack()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string msg
	NVAR gLayer = root:Packages:WM3DImageSlider:$(winNameStr):gLayer	
	if(NVAR_Exists(gLayer) && WaveDims(w3dref) == 3)
		string layerSaveStr = NameOfWave(w3dref) + "_layer_" + num2str(gLayer)
		MatrixOP/O $layerSaveStr = layer(w3dref, gLayer)
		sprintf msg, "Slice %d from wave %s", gLayer, imgNameTopGraphStr
		CopyScales/I w3dref, $layerSaveStr
		Note $layerSaveStr, msg
	else
		Abort "Operation needs a stack (3d wave) with a slider activated"
	endif
End

Function MXP_StackImageToImageStack(WAVE w3dref, WAVE w2dRef) 
	if((DimSize(w3dref, 0) == DimSize(w2dRef, 0)) && DimSize(w3dref, 1) == DimSize(w2dRef, 1))
		variable lastLayerNr = DimSize(w3dRef, 2)
		if(lastLayerNr)
			variable x0, y0, z0, dx, dy, dz
			[x0, y0, z0, dx, dy, dz] = MXP_GetScalesP(w3dRef)
			ImageTransform/O/INSW=w2dref/P=(lastLayerNr) insertZplane w3dRef
			MXP_SetScalesP(w3dRef, x0, y0, z0, dx, dy, dz)
		endif
	else
		Abort "Image and stack must have the same lateral dimensions."
	endif
End

Function MXP_ImageEdgeDetectionToStack(WAVE w3dref, string method, [variable overwrite])
	/// Applied the edge detection operation to w3dref
	/// and outputs a wave with name NameofWave(w3dref) + "_ed"
	/// You can optionally ovewrite the input wave
	
	overwrite = ParamIsDefault(overwrite) ? 0: overwrite
	
	variable numlayers = DimSize(w3dref, 2), i
	
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	
	for(i = 0; i < numlayers; i++)
		ImageEdgeDetection/P=(i)/M=-1 $method w3dref
		WAVE M_ImageEdges		
		Rename M_ImageEdges, $("MXPWaveToStack_idx_" + num2str(i))
	endfor
	
	ImageTransform/NP=(numlayers) stackImages $"MXPWaveToStack_idx_0"
	WAVE M_Stack
	string stacknameStr = CreateDataObjectName(saveDF, NameofWave(w3dref) + "_ed", 1, 0, 1)
	if(overwrite)
		MoveWave M_stack, saveDF:$stacknameStr
		CopyScales/I w3dref, saveDF:$stacknameStr
	else
		Duplicate/O M_stack, w3dref
	endif
	SetDataFolder saveDF
	return 0
End

Function/WAVE MXP_WAVEImageEdgeDetectionToStack(WAVE w3dref, string method)
	/// Applied the edge detection operation to w3dref
	/// and returns a wave to NameofWave(w3dref) + "_ed"
	
	variable numlayers = DimSize(w3dref, 2), i
	
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	
	for(i = 0; i < numlayers; i++)
		ImageEdgeDetection/P=(i)/M=-1 $method w3dref
		WAVE M_ImageEdges		
		Rename M_ImageEdges, $("MXPWaveToStack_idx_" + num2str(i))
	endfor
	
	ImageTransform/NP=(numlayers) stackImages $"MXPWaveToStack_idx_0"
	WAVE M_Stack
	Duplicate/O M_Stack, wRefFREE
	CopyScales/I w3dref, wRefFREE
	SetDataFolder saveDF
	return wRefFREE
End


Function MXP_ImageRotateAndScale(WAVE wRef, variable angle)
	/// Rotate the wave wRef (2d or 3d) and scale it to 
	/// conserve on image distances.
	/// Math: If the side of the image is a, then the rotated image
	/// will have side a_rot = a * (cos(angle) + sin(angle))
	/// @param wRef: 2d or 3d wave
	/// @param angle: clockwise rotation in degrees
	
	variable angleRad = angle * pi / 180
	string rotWaveNameStr = NameOfWave(wRef) + "_rot"
	Duplicate/O wRef, $rotWaveNameStr
	WAVE wRefRot = $rotWaveNameStr
	ImageRotate/O/E=0/A=(angle) wRefRot
	string noteStr = NameOfWave(wRef) + " rotated by " + num2str(angle) + " deg"
	Note/K wRefRot, noteStr
	CopyScales/P wRef, wRefRot // /P needed here to prevent on image distances.	
End

Function MXP_ImageBackupRotateAndScale(Wave wRef, variable angle)
	/// Backup and rotate image
	/// Math: If the side of the image is a, then the rotated image
	/// will have side a_rot = a * (cos(angle) + sin(angle))
	/// @param wRef: 2d or 3d wave	
	/// @param angle: clockwise rotation in degrees
	variable angleRad = angle * pi / 180
	string backupWaveNameStr = NameOfWave(wRef) + "_undo"
	Duplicate/O wRef, $backupWaveNameStr
	ImageRotate/O/E=0/A=(angle) wRef
	WAVE wRefbck = $backupWaveNameStr
	string noteStr ="Image rotated by " + num2str(angle) + " deg"
	Note/K wRef, noteStr
	CopyScales/P wRef, wRefbck // /P needed here to prevent on image distances.	
End

Function MXP_BackupTopImage()
	/// Backup wave in the top window
	
	WAVE wRef = MXP_TopImageToWaveRef()
	Duplicate/O wRef, $(NameOfWave(wRef) + "_undo")	
	return 0
End

Function MXP_RestoreTopImageFromBackup()
	/// Restore the top image if there is a backup wave.
	/// Backup wave's name is *assummed* to be NameOfWave(wRef) + "_undo" !!!!
	///
	/// Math: If the side of the image is a, then the rotated image
	/// will have side a_rot = a * (cos(angle) + sin(angle))
	/// @param angle: clockwise rotation in degrees
	
	WAVE wRef = MXP_TopImageToWaveRef()
	string backupWaveNameStr = NameOfWave(wRef) + "_undo"
	WAVE/Z wRefbck = $backupWaveNameStr
	if(WaveExists(wRefbck))
		Duplicate/O wRefbck, wRef
		KillWaves wRefbck
	else
		print backupWaveNameStr, " not found."
	endif
	
	return 0
End

Function MXP_ScalePlanesByMinMaxRange(WAVE w3d, [variable f64])
	// f64: Return a float64 wave. 
	// By default return a float32, unless w3d is float64
	// 
	f64 = ParamIsDefault(f64) ? 0: 1 //
	
	if((!MXP_IsFloat32Q(w3d) && !MXP_IsFloat64Q(w3d)))
		Redimension/S w3d
	elseif(f64 && !MXP_IsFloat64Q(w3d))
		Redimension/D w3d
	endif
	MatrixOP/FREE zRangeFree = 1/(maxVal(w3d) - minVal(w3d))
	ImageTransform/BEAM={0, 0} getBeam zRangeFree
	WAVE W_Beam
	ImageTransform/O/D=W_Beam scalePlanes w3d
	KillWaves W_Beam
End

Function MXP_ScalePlanesByMaxRange(WAVE w3d, [variable f64])
	// f64: Return a float64 wave. 
	// By default return a float32, unless w3d is float64
	// 
	f64 = ParamIsDefault(f64) ? 0: 1 //
	
	if((!MXP_IsFloat32Q(w3d) && !MXP_IsFloat64Q(w3d)))
		Redimension/S w3d
	elseif(f64 && !MXP_IsFloat64Q(w3d))
		Redimension/D w3d
	endif
	MatrixOP/FREE zRangeFree = 1/maxVal(w3d)
	ImageTransform/BEAM={0, 0} getBeam zRangeFree
	WAVE W_Beam
	ImageTransform/O/D=W_Beam scalePlanes w3d
	KillWaves W_Beam
End

Function MXP_ScalePlanesBetweenZeroAndOne(WAVE w3d, [variable f64])
	// f64: Return a float64 wave. 
	// By default return a float32, unless w3d is float64
	// 
	f64 = ParamIsDefault(f64) ? 0: 1 //
	
	if((!MXP_IsFloat32Q(w3d) && !MXP_IsFloat64Q(w3d)))
		Redimension/S w3d
	elseif(f64 && !MXP_IsFloat64Q(w3d))
		Redimension/D w3d
	endif
	
	MatrixOP/FREE minValsZ = minVal(w3d)
	MatrixOP/FREE maxValsZ = maxVal(w3d)
	w3d -= minValsZ[0][0][r]
	MatrixOP/FREE zRangeFree = 1/(maxValsZ - minValsZ)
	ImageTransform/BEAM={0, 0} getBeam zRangeFree
	WAVE W_Beam
	ImageTransform/O/D=W_Beam scalePlanes w3d
	KillWaves W_Beam
End

//TODO
//Function MXP_ApplyOperationToFilesInFolderTree(string pathName, 
//		   string extension, variable recurse, variable level)
//	///
//	///  
//
//	PathInfo $pathName
//	string path = S_path	
//	if(!V_flag) // If path not defined
//		print "pathName not set!"
//		NewPath/O pathName
//	endif
//	
//	// Reset or make the string variable
//	variable folderIndex, fileIndex
//
//	// Add files
//	fileIndex = 0
//	do
//		string fileName
//		fileName = IndexedFile($pathName, fileIndex, extension)
//		if (strlen(fileName) == 0)
//			break
//		endif
//		WAVE datWave = MXP_WAVELoadSingleDATFile(fileName, "", skipmetadata = 1)
//		ImageSave/P=$pathName datWave
//		KillWaves datWave
//		fileIndex += 1
//	while(1)
//	
//	if (recurse)		// Do we want to go into subfolder?
//		folderIndex = 0
//		do
//			path = IndexedDir($pathName, folderIndex, 1)
//			if (strlen(path) == 0)
//				break	// No more folders
//			endif
//
//			string subFolderPathName = "tempPrintFoldersPath_" + num2istr(level+1)
//			
//			// Now we get the path to the new parent folder
//			string subFolderPath
//			subFolderPath = path
//			
//			NewPath/Q/O $subFolderPathName, subFolderPath
//			MXP_ApplyOperationToFilesInFolderTree(subFolderPathName, extension, recurse, level+1)
//			KillPath/Z $subFolderPathName
//			
//			folderIndex += 1
//		while(1)
//	endif
//	return 0
//End