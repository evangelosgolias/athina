#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_ImgOp
#pragma version = 1.01

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

static Function RangeMeanSigmaTopImage()
	// Autoscale image of the top grap
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE wRef = ImageNameToWaveRef("", imgNameTopGraphStr)
	if(!WaveExists(wRef))
		return -1
	endif
	string matchPattern = "ctab= {%*f,%*f,%[A-Za-z],%d}" //%* -> Read but not store	
	string colorScaleStr
	variable cmapSwitch
	string infoStr = Imageinfo(winNameStr, NameOfWave(wRef), 0)
	sscanf StringByKey("RECREATION",infoStr), matchPattern, colorScaleStr, cmapSwitch
	GetAxis/W=$winNameStr/Q $StringByKey("XAXIS", infoStr)
	variable xmin = V_min, xmax = V_max
	GetAxis/W=$winNameStr/Q $StringByKey("YAXIS", infoStr)
	variable ymin = V_min, ymax = V_max, plane, flag, left, right, top, bottom
	int is3D = WaveDims(wRef) == 3
	plane = GetLayerIndex(winNameStr)
	[flag, left, right, top, bottom] = ATH_Marquee#GetMarqueeToIndex()	
	if(is3D)
		if(flag)
			WaveStats/Q/RMD=[left, right][top, bottom][plane] wref
		else
			WaveStats/Q/RMD=[][][plane] wref		
		endif
	else 
		if(flag)
			WaveStats/Q/RMD=[left, right][top, bottom] wref
		else
			WaveStats/Q wref		
		endif
	endif
	variable meanV = V_avg
	variable stdV = V_sdev
	ModifyImage $PossiblyQuoteName(NameOfWave(wRef)) ctab= {meanV-3*stdV,meanV+3*stdV,$colorScaleStr,cmapSwitch} // Autoscale Image
End

static Function GetLayerIndex(string grfName, [Wave/Z w])
	if (ParamIsDefault(w))
		WAVE/Z w = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	endif
	if (!WaveExists(w) || WaveDims(w) != 3)
		return NaN
	endif
	
	return NumberByKey("plane", ImageInfo(grfName, PossiblyQuoteName(NameOfWave(w)), 0), "=")
End

static Function AutoRangeTopImagePlane()
	// Autoscale image of the top grap
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	string matchPattern = "ctab= {%*f,%*f,%[A-Za-z],%d}" //%* -> Read but not store
	string colorScaleStr
	variable cmapSwitch
	sscanf StringByKey("RECREATION",Imageinfo("",NameOfWave(wRef),0)), matchPattern, colorScaleStr, cmapSwitch
	ModifyImage $PossiblyQuoteName(NameOfWave(wRef)) ctabAutoscale=3 // Autoscale Image	
	ModifyImage $PossiblyQuoteName(NameOfWave(wRef)) ctab= {*,*,$colorScaleStr,cmapSwitch} // Autoscale Image	
End

static Function SetZScaleOfImageStack() // Uses top graph
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
		setScaleZStr = ATH_Dialog#GenericSingleStrPrompt(strPrompt, msgDialog)
		string dataPathStr = GetWavesDataFolder(waveRef, 2)
		if(strlen(setScaleZStr))
		cmdStr = "SetScale/I z " + setScaleZStr + ", " + dataPathStr
		Execute/Z cmdStr
		endif
	endif
End

static Function ImageSelectToCopyScale() // Uses top graph
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	// Select the first wave from browser selection
	string selectedWavesStr = ATH_Dialog#SelectWavesInModalDataBrowser("Select an image to set common dimension scaling")
	WAVE sourceWaveRef = $StringFromList(0, selectedWavesStr)
	CopyScales/P sourceWaveRef, wRef // 
End

static Function/S NormaliseImageStackWithImage(WAVE w3dRef, WAVE w2dRef)
	// If you have 16-bit waves then Redimension/S to SP
//	if(WaveType(w3dRef) == 80 || WaveType(w3dRef) == 16)
//		Redimension/S w3dRef
//	endif
//	if(WaveType(w2dRef) == 80 || WaveType(w2dRef) == 16)
//		Redimension/S w2dRef
//	endif
// Not needed, MatrixOP will transform it
	DFREF currDF = GetDataFolderDFR()	
	string normWaveBaseNameStr = NameOfWave(w3dRef) + "_norm"
	string normWaveStr = CreateDataObjectName(currDF, normWaveBaseNameStr, 1, 0, 1)	
	MatrixOP/O $normWaveStr = w3dRef / w2dRef
	CopyScales w3dRef, $normWaveStr
	return normWaveStr
End

static Function/S NormaliseImageStackWithImageStack(WAVE w3dRef1, WAVE w3dRef2)
	// If you have 16-bit waves then Redimension/S to SP
//	if(WaveType(w3dRef1) == 80 || WaveType(w3dRef1) == 16)
//		Redimension/S w3dRef1
//	endif
//	if(WaveType(w3dRef2) == 80 || WaveType(w3dRef2) == 16)
//		Redimension/S w3dRef2
//	endif
	DFREF currDF = GetDataFolderDFR()	
	string normWaveBaseNameStr =  NameOfWave(w3dRef1) + "_norm"
	string normWaveStr = CreateDataObjectName(currDF, normWaveBaseNameStr, 1, 0, 1)	
	MatrixOP/O $normWaveStr = w3dRef1 / w3dRef2
	CopyScales w3dRef1, $normWaveStr
	return normWaveStr
End

static Function/S NormaliseImageStackWithProfile(WAVE w3dRef, WAVE profWaveRef)
	// Normalise a 3d wave (stack) with a line profile (1d wave) along the layer (z) direction
//	if(WaveType(w3dRef) == 80 || WaveType(w3dRef) == 16)
//		Redimension/S w3dRef
//	endif
//	if(WaveType(profWaveRef) == 80 || WaveType(profWaveRef) == 16)
//		Redimension/S profWaveRef
//	endif
//		
	DFREF currDF = GetDataFolderDFR()	
	string normWaveBaseNameStr = NameOfWave(w3dRef) + "_norm"
	string normWaveStr = CreateDataObjectName(currDF, normWaveBaseNameStr, 1, 0, 1)	
		
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
	else 
		Duplicate/O/FREE profWaveRef, profWaveRefFREE
		Redimension/N=(1, 1, nlayers) profWaveRefFREE		
		MatrixOP/O $normWaveStr = w3dRef * rec(profWaveRefFREE)
	endif
	CopyScales w3dRef, $normWaveStr
	return normWaveStr
End

static Function GetScaledZoominImageWindow()
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
		NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(winNameStr):gLayer	
		if(NVAR_Exists(gLayer))
			bufferStr = NameOfWave(wref) + "_layer_" + num2str(gLayer) + "_ZM"
			wavenameStr = CreateDataObjectName(cdfr, bufferStr, 1, 0, 5)
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

static Function GetLayerFromImageStack()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string msg
	NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(winNameStr):gLayer	
	if(NVAR_Exists(gLayer) && WaveDims(w3dref) == 3)
		string layerSaveStr = NameOfWave(w3dref) + "_layer_" + num2str(gLayer)
		MatrixOP/O $layerSaveStr = layer(w3dref, gLayer)
		sprintf msg, "Slice %d from wave %s", gLayer, imgNameTopGraphStr
		CopyScales/I w3dref, $layerSaveStr
		Note $layerSaveStr, msg
	else
		Abort "Operation needs a stack (3d wave) with an active slider."
	endif
End

static Function RemoveImagesFromImageStack(WAVE w3dref, variable startLayer, variable nrLayers)
	// Remove nrLayers starting at startLayer from w3dRef
	variable nL = DimSize(w3dref, 2)
	if(nl < 2 || startLayer > nL)
		return -1
	endif
	ImageTransform/O/P=(startLayer)/NP=(nrLayers) removeZplane w3dRef
	return 0
End

static Function InsertImageToImageStack(WAVE w3dref, WAVE w2dRef, variable layerN)
	// Insert an image at the position layerN of an image stack
	// Here the z dimension will change, as the DimDelta is used to scale the resulting 
	// image stack
	if((DimSize(w3dref, 0) == DimSize(w2dRef, 0)) && DimSize(w3dref, 1) == DimSize(w2dRef, 1))
		variable x0, y0, z0, dx, dy, dz
		[x0, y0, z0, dx, dy, dz] = ATH_WaveOp#GetScalesP(w3dRef)
		ImageTransform/O/INSW=w2dref/P=(layerN) insertZplane w3dRef
		ATH_WaveOp#SetScalesP(w3dRef, x0, y0, z0, dx, dy, dz)
	else
		Abort "Image and stack must have the same lateral dimensions."
	endif
End

static Function AppendImagesToImageStack(WAVE wRef, string waveListStr) 
	//
	// Append images in waveListStr to wRef
	//
	WAVE/WAVE wRefw = ATH_WaveOp#WaveListStrToWaveRef(waveListStr, isFree = 1)
	InsertPoints 0, 1, wRefw
	Duplicate/FREE wRef, wRefFREE
	wRefw[0] = wRefFREE
	string destWave = GetWavesDataFolder(wRef, 2)
	if(ATH_WaveOp#AllImagesEqualDimensionsQ(wRefw))
		Concatenate/O/NP=2 {wRefw}, $destWave
		return 0
	else
		print "Dimension mismatch, no op!"
		return -1
	endif
End

static Function ConcatenateImages(string destWaveStr, string waveListStr) 
	//
	// Concatenate wave to destWaveStr
	//
	WAVE/WAVE wRefw = ATH_WaveOp#WaveListStrToWaveRef(waveListStr, isFree = 1)
	Concatenate/O/NP=2 {wRefw}, $destWaveStr
End

static Function ImageEdgeDetectionToStack(WAVE w3dref, string method, [variable overwrite])
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
		Rename M_ImageEdges, $("ATHWaveToStack_idx_" + num2str(i))
	endfor
	
	ImageTransform/NP=(numlayers) stackImages $"ATHWaveToStack_idx_0"
	WAVE M_Stack
	string stacknameStr = CreateDataObjectName(saveDF, NameofWave(w3dref) + "_ed", 1, 0, 1)
	if(overwrite)
		Duplicate/O M_stack, w3dref
	else
		MoveWave M_stack, saveDF:$stacknameStr
		CopyScales/I w3dref, saveDF:$stacknameStr
	endif
	SetDataFolder saveDF
	return 0
End

static Function/WAVE WAVEImageEdgeDetectionToStack(WAVE w3dref, string method)
	/// Applied the edge detection operation to w3dref
	/// and returns a wave to NameofWave(w3dref) + "_ed"
	
	variable numlayers = DimSize(w3dref, 2), i
	
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	
	for(i = 0; i < numlayers; i++)
		ImageEdgeDetection/P=(i)/M=-1 $method w3dref
		WAVE M_ImageEdges		
		Rename M_ImageEdges, $("ATHWaveToStack_idx_" + num2str(i))
	endfor
	
	ImageTransform/NP=(numlayers) stackImages $"ATHWaveToStack_idx_0"
	WAVE M_Stack
	Duplicate/O M_Stack, wRefFREE
	CopyScales/I w3dref, wRefFREE
	SetDataFolder saveDF
	return wRefFREE
End


static Function ImageRotateAndScale(WAVE wRef, variable angle, [variable backup, variable flipY])
	/// Backup and rotate image. Create backup in the source wave folder.
	/// Math: If the side of the image is a, then the rotated image
	/// will have side a_rot = a * (cos(angle) + sin(angle))
	/// @param wRef: 2d or 3d wave	
	/// @param angle: clockwise rotation in degrees
	/// @param backup: backup wave before rotation
	/// @param fliY: flip cols
	
	/// flipY = 1 when Mirror in ON
	backup = ParamIsDefault(backup) ? 0 : backup
	flipY = ParamIsDefault(flipY) ? 0 : flipY
	if(backup)
		string backupWaveNameStr = NameOfWave(wRef) + "_undo"
		DFREF wDFR = GetWavesDataFolderDFR(wRef)
		Duplicate/O wRef, wDFR:$backupWaveNameStr
		WAVE wRefbck = wDFR:$backupWaveNameStr
	else
		variable x0 = DimOffset(wRef, 0)
		variable y0 = DimOffset(wRef, 1)	
		variable z0 = DimOffset(wRef, 2)			
		variable dx = DimDelta(wRef, 0)
		variable dy = DimDelta(wRef, 1)
		variable dz = DimDelta(wRef, 2)				
	endif
	string noteStr = ""
	if(flipY)
		ImageTransform flipCols wRef // flip the y-axis, MatrixOP reverseRows is equivalent!
		noteStr += "Flipped  y-axis (rows)\n"
	endif
	ImageRotate/O/E=0/A=(angle) wRef
	noteStr +="Image rotated by " + num2str(angle) + " deg\n"
	Note/K wRef, noteStr
	if(backup)
		CopyScales/P wRefbck, wRef // /P needed here to prevent on image distances.	
	else
		SetScale/P x, x0, dx, wRef
		SetScale/P y, y0, dy, wRef
		SetScale/P z, z0, dz, wRef				
	endif
End

static Function BackupTopImage()
	/// Backup wave in the top window, the backup is created in the 
	/// sourcewave datafolder (to be able to restore)
	
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(!WaveExists(wRef))
		print "Operation needs an image or image stack"
		return -1
	endif
	DFREF wDFR = GetWavesDataFolderDFR(wRef)
	Duplicate/O wRef, wDFR:$(NameOfWave(wRef) + "_undo")	
	return 0
End

static Function RestoreTopImageFromBackup([string wname])
	/// Restore an image from backup. When ParamIsDefault (wavenameStr = "")
	/// the image on the top window is used, otherwise WAVE $wavenameStr.
	/// Backup wave's name is *assummed* to be NameOfWave(wRef) + "_undo"
	/// and it is located on the same folder as the source image
	
	wname = SelectString(ParamIsDefault(wname) ? 0: 1,"", wname)
	if(!ParamIsDefault(wname))
		WAVE wRef = $wname
	else
		WAVE wRef = ATH_Graph#TopImageToWaveRef()
	endif
	
	if(!WaveExists(wRef))
		return -1
	endif
	
	DFREF wdfr = GetWavesDataFolderDFR(wRef)
	string backupWaveNameStr = NameOfWave(wRef) + "_undo"
	WAVE/SDFR=wdfr/Z wRefbck = $backupWaveNameStr
	if(WaveExists(wRefbck))
		Duplicate/O wRefbck, wRef
		CheckDisplayed/A wRefbck
		if(V_Flag) // if wave is displayed
			print "Cannot kill " + backupWaveNameStr + ". CheckDisplayed == 1."
		else
			KillWaves wRefbck
		endif
	else
		return -1
	endif
	return 0
End

static Function ScalePlanesByMinMaxRange(WAVE w3d, [variable f64])
	// f64: Return a float64 wave. 
	// By default return a float32, unless w3d is float64
	// 
	f64 = ParamIsDefault(f64) ? 0: 1 //
	
	if((!ATH_Num#IsFloat32Q(w3d) && !ATH_Num#IsFloat64Q(w3d)))
		Redimension/S w3d
	elseif(f64 && !ATH_Num#IsFloat64Q(w3d))
		Redimension/D w3d
	endif
	MatrixOP/FREE zRangeFree = 1/(maxVal(w3d) - minVal(w3d))
	ImageTransform/BEAM={0, 0} getBeam zRangeFree
	WAVE W_Beam
	ImageTransform/O/D=W_Beam scalePlanes w3d
	KillWaves W_Beam
End

static Function ScalePlanesByMaxRange(WAVE w3d, [variable f64])
	// f64: Return a float64 wave. 
	// By default return a float32, unless w3d is float64
	// 
	f64 = ParamIsDefault(f64) ? 0: 1 //
	
	if((!ATH_Num#IsFloat32Q(w3d) && !ATH_Num#IsFloat64Q(w3d)))
		Redimension/S w3d
	elseif(f64 && !ATH_Num#IsFloat64Q(w3d))
		Redimension/D w3d
	endif
	MatrixOP/FREE zRangeFree = 1/maxVal(w3d)
	ImageTransform/BEAM={0, 0} getBeam zRangeFree
	WAVE W_Beam
	ImageTransform/O/D=W_Beam scalePlanes w3d
	KillWaves W_Beam
End

static Function ScalePlanesBetweenZeroAndOne(WAVE w3d, [variable f64])
	// Each plane is normalised between [0, 1]
	// f64: Return a float64 wave. 
	// By default return a float32, unless w3d is float64
	// 
	f64 = ParamIsDefault(f64) ? 0: 1 //
	
	if((!ATH_Num#IsFloat32Q(w3d) && !ATH_Num#IsFloat64Q(w3d)))
		Redimension/S w3d
	elseif(f64 && !ATH_Num#IsFloat64Q(w3d))
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

static Function ExtractLayerRangeToStack(WAVE w3d, variable NP0, variable NP1)
	/// Average image range NP0-NP1, including endpoints
	variable  nlayers = DimSize(w3d, 2), i
	if(NP1 > nlayers - 1 || NP1 < NP0 || WaveDims(w3d) != 3)
		Abort "Dimension mismatch."
	endif
	variable imax = NP1 - NP0 + 1// include endpoints
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	for(i = 0; i < imax; i++)
		MatrixOP/O $("getLayer_" + num2str(i)) = layer(w3d, NP0 + i)
	endfor
	ImageTransform/NP=(imax) stackImages $"getLayer_0"
	WAVE M_Stack
	CopyScales w3d, M_Stack
	SetScale/P z, 0, 1, M_Stack
	string basenameStr = NameOfWave(w3d) + "_stkL_" + num2str(NP0) + "_" + num2str(NP1)
	string saveStackNameStr = CreatedataObjectName(saveDF,basenameStr , 1, 0, 1)
	Duplicate/O M_Stack, saveDF:$saveStackNameStr
	SetDataFolder saveDF
	return 0
End

static Function/WAVE WAVEAverageImageRangeToStack(WAVE w3d, variable NP0, variable NPL)
	/// Average NPL image planes in stack starting from N0 
	variable  nlayers = DimSize(w3d, 2), i
	if(NP0 + NPL > nlayers)
		Abort "Dimension mismatch."
	endif
	MatrixOP/FREE calcLayer = layer(w3d, 0)
	calcLayer = 0
	for(i = 0; i < NPL; i++)
		MatrixOP/O/FREE gLayerFree = layer(w3d, NP0 + i)
		MatrixOP/O calcLayer = calcLayer + gLayerFree
	endfor
	return calcLayer
End

static Function AverageImageRangeToStackOffset(WAVE w3d, variable NP0, variable NPL)
	/// Average NPL image planes in stack starting from N0	
	variable  nlayers = DimSize(w3d, 2), i
	if(NP0 + NPL > nlayers)
		Abort "Dimension mismatch."
	endif
	MatrixOP/O $(NameOfWave(w3d) + "_avgPL_" + num2str(NP0) + "_" + num2str((NP0 + NPL))) = layer(w3d, 0)
	WAVE resW2d = $(NameOfWave(w3d) + "_avgPL_" + num2str(NP0) + "_" + num2str((NP0 + NPL)))
	for(i = 0; i < NPL; i++)
		MatrixOP/O/FREE gLayerFree = layer(w3d, NP0 + i)
		MatrixOP/O resW2d = resW2d + gLayerFree
	endfor
	CopyScales w3d, resW2d
	return 0
End

static Function AverageImageRangeToStack(WAVE w3d, variable NP0, variable NP1)
	/// Average image range NP0-NP1, including endpoints
	variable  nlayers = DimSize(w3d, 2), i
	if(NP1 > nlayers - 1 || NP1 < NP0)
		Abort "Dimension mismatch."
	endif
	MatrixOP/O $(NameOfWave(w3d) + "_avgPL_" + num2str(NP0) + "_" + num2str(NP1)) = layer(w3d, 0)
	WAVE resW2d = $(NameOfWave(w3d) + "_avgPL_" + num2str(NP0) + "_" + num2str(NP1))
	variable imax = NP1 - NP0 + 1// include endpoints

	for(i = 0; i < imax; i++)
		MatrixOP/O/FREE gLayerFree = layer(w3d, NP0 + i)
		MatrixOP/O resW2d = resW2d + gLayerFree
	endfor
	MatrixOP/O resW2d = resW2d/imax
	CopyScales w3d, resW2d
	return 0
End


static Function HistogramShiftToGaussianCenter(WAVE w2d, [variable overwrite])
	/// Move the histogram center to the center of the fitted gaussian
	/// Useful for symmetrising XMCD/XMLD images
	
	overwrite = ParamIsDefault(overwrite) ? 0: overwrite
	DFREF currDF = GetDataFolderDFR()
	variable nrows = DimSize(w2d, 0)
	variable ncols = DimSize(w2d, 1)
	SetDataFolder NewFreeDataFolder()
	
	Make/N=(nrows, ncols)/B/U ATH_ROIMask = 0
	ImageHistogram/R=ATH_ROIMask w2d
	WAVE W_ImageHist
	CurveFit/Q gauss W_ImageHist /D 
	WAVE W_coef
	variable x0 = W_coef[2] // Gaussian center
	// Add the value to w2d
	if(overwrite)
		w2d -= x0
	else
		string wRefNoteStr = note(w2d)
		string baseWaveNameStr = NameofWave(w2d) + "_GaussCen"
		string saveWaveNameStr = CreatedataObjectName(currDF, baseWaveNameStr, 1, 0, 0)	
		Duplicate w2d, currDF:$saveWaveNameStr
		WAVE wref = currDF:$saveWaveNameStr
		wref -= x0
		CopyScales w2d, wRef
		Note wRef, wRefNoteStr
	endif
	SetDataFolder currDF
	return 0
End

static Function HistogramShiftToGaussianCenterStack(WAVE w3d, [variable overwrite])
	/// Move the histogram center to the center of the fitted gaussian
	/// Useful for symmetrising XMCD/XMLD images
	/// The function returns the applies shift
	overwrite = ParamIsDefault(overwrite) ? 0: overwrite
	DFREF currDF = GetDataFolderDFR()
	variable nrows = DimSize(w3d, 0)
	variable ncols = DimSize(w3d, 1)
	variable nlayers = DimSize(w3d, 2), i, x0
	SetDataFolder NewFreeDataFolder()
	
	Make/N=(nrows, ncols)/B/U ATH_ROIMask = 0
	for(i = 0; i < nlayers; i++)
		MatrixOP $("layerToStack_" + num2str(i)) = layer(w3d, i)
		WAVE wRef = $("layerToStack_" + num2str(i))
		ImageHistogram/R=ATH_ROIMask wRef
		WAVE W_ImageHist
		CurveFit/Q gauss W_ImageHist /D
		WAVE W_coef
		x0 = W_coef[2] // Gaussian center
		wRef -= x0
	endfor
	// Stack all planes
	ImageTransform/NP=(nlayers) stackImages $"layerToStack_0"
	WAVE M_Stack
	CopyScales w3d, M_Stack
	// Add note to stack
	string noteStr = note(w3d)
	noteStr += "Gaussian centered histogram per layer of " + GetWavesDataFolder(w3d, 2)
	Note M_Stack , noteStr
	if(overwrite)
		Duplicate/O M_Stack, w3d
	else
		string baseWaveNameStr = NameofWave(w3d) + "_GaussCen"
		string saveWaveNameStr = CreatedataObjectName(currDF, baseWaveNameStr, 1, 0, 1)	
		Duplicate M_Stack, currDF:$saveWaveNameStr
	endif
	SetDataFolder currDF
	return x0 // Return the shift!
End

static Function GrayToRGBImage(WAVE wRef)
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

static Function RGB2Gray8Image(WAVE wRef)
	// Convert a 3D RGB image to grayscale (8-bit)
	if(WaveDims(wRef) != 3)
		return -1
	endif
	string wnaneStr = NameOfWave(wRef) + "_u8"
	ImageTransform rgb2gray wRef
	WAVE M_RGB2Gray
	Rename M_RGB2Gray, $wnaneStr
	return 0
End

static Function RGB2Gray16Image(WAVE wRef)
	// Convert a 3D RGB image to grayscale (16-bit) /W/U
	//The RGB values are converted into the luminance Y of the YIQ standard using:
	// Y = 0.299R + 0.587G + 0.114B
	
	if(WaveDims(wRef) != 3)
		return -1
	endif
	string basewnaneStr = NameOfWave(wRef) + "_u16"
	variable nrows = DimSize(wref, 0)
	variable ncols = DimSize(wref, 1)
	DFREF cwdfr = GetDataFolderDFR()
	string waveNameStr = CreateDataObjectName(cwdfr, basewnaneStr, 1, 0, 1)
	Make/N=(nrows, ncols) $waveNameStr /WAVE=img
	CopyScales wRef, img
	img = 0.299*wRef[p][q][0] + 0.587*wRef[p][q][1] + 0.11*wRef[p][q][2]
	return 0
End

static Function FlattenImage(WAVE wRef, string method, variable kernelN, variable iterN, [int overwrite])
	// Flatten image using a
	overwrite = ParamIsDefault(overwrite) ? 0 : overwrite
	string allmethods = "gauss;avg;median:max;min"
	variable ifunc = WhichListItem(method, allmethods)
	if(ifunc == -1)
		return -1
	endif

	Duplicate/O/FREE wRef, bkgFREE
	MatrixFilter/P=(iterN)/N=(kernelN) $method bkgFREE // MatrixFilter operation overwrites source
	if(overwrite)
		wRef -= bkgFREE
	else
		string waveNameStr = NameOfWave(wRef)
		DFREF dfr = GetDataFolderDFR()
		string flattenWaveStr = CreateDataObjectName(dfr, waveNameStr + "_flt", 1, 0, 1)
		MatrixOP $flattenWaveStr = wRef - bkgFREE
	endif
	return 0
End

static Function ImgRemoveBackground(WAVE wRef, [variable order, WAVE wMask, variable layerN, variable w3d])
	// Remove background of an image (default 1st order)
	// Use order = n, n > 1 for higher order polynomial
	// Use overwite = 1 to overwite the original wave
	order = ParamIsDefault(order) ? 1: order
	layerN = ParamIsDefault(layerN) ? 0: layerN
	w3d = ParamIsDefault(w3d) ? 0: w3d

	variable nrows, ncols
	nrows = DimSize(wRef,0)
	ncols = DimSize(wRef,1)

	if(ParamIsDefault(wMask)) // Reserved for arbitrary masks
		Make/O/FREE/N=(nrows,ncols)/B/U maskWFree = 1
	endif

	if(WaveType(wRef) & 0x02) // We need a 32-bit float for better results
		Redimension/S wRef
	endif
	if(WaveDims(wRef) == 3)
		if(w3d)
			variable nlayers = DimSize(wRef, 2), i
			DFREF saveDF = GetDataFolderDFR()
			SetDataFolder NewFreeDataFolder()
			string buffer = "layer_", waveNameStr
			for(i = 0; i < nlayers; i++)
				waveNameStr = buffer + num2str(i)
				MatrixOP/O $waveNameStr = layer(wRef, i)
				WAVE w = $waveNameStr
				ImageRemoveBackground/O/R=maskWFree/P=(order) w
			endfor
			ImageTransform/NP=(nlayers) stackImages $"layer_0"
			WAVE M_Stack
			// Restore scale here
			CopyScales wRef, M_Stack
			Duplicate/O M_Stack, wRef
			SetDataFolder saveDF
		else
			// Code to replace plane in 3d wave
			MatrixOP/FREE getLayer = layer(wRef, layerN)
			ImageRemoveBackground/O/R=maskWFree/P=(order) getLayer
			ImageTransform/O/P=(layerN) removeZplane wRef
			ImageTransform/O/INSW=getLayer/P=(layerN) insertZplane wRef
		endif
	elseif(WaveDims(wRef) == 2)
		ImageRemoveBackground/O/R=maskWFree/P=(order) wRef
		return 0
	else
		return 1
	endif
End

static Function ImgRemoveBackgroundCols(WAVE wRef, variable orderN) //TODO! Fix
	// Image Remove 1-d background from each column
	//Make/O/N=(DimSize(wRef,1), orderN) fitCoeff
	if(WaveType(wRef) & 0x10) // If WORD (int16)
		Redimension/S wRef
	endif
	variable y0 = DimSize(wRef, 1); variable dy = DimDelta(wRef, 1)
	variable i, imax =DimSize(wRef,1)
	Wave/Z W_coef
	variable fitErrorCode
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	MatrixOP/FREE getCol = col(wRef, 0) // Get one and scale it.
	SetScale/I x, y0, dy, getCol
	for(i=0;i<imax;i++)
		MatrixOP/S/FREE getCol = col(wRef, i) // /S prevent scaling
		CurveFit/Q/M=0/W=2 poly_XOffset orderN, getCol/D
		NVAR/Z V_fitError
		fitErrorCode = V_fitError
		if(fitErrorCode)
			print "FitError col:", num2str(i)
		endif
		//fitCoeff[i][] = W_coef[q]
		wRef[i][] -= poly(W_coef, x)
	endfor
	SetDataFolder saveDF
	return 0
End

static Function ImageResampling(WAVE wRef,  string func, variable xOffset, variable yOffset,
							 [int newWave, variable xscale, variable yscale])
	// Calculate image interpolation using scaleShift and one of the following intepolating functions.
	//
	//	nn	Nearest neighbor interpolation uses the value of the nearest neighbor without interpolation. 
	//		This is the fastest function.
	//	bilinear	Bilinear interpolation uses the immediately surrounding pixels and computes a linear 
	//				interpolation in each dimension. This is the second fastest function.
	//	cubic	Cubic polynomial (photoshop-like) uses a 4x4 neighborhood value to compute the sampled pixel value.
	//	spline	Spline smoothed sampled value uses a 4x4 neighborhood around the pixel.
	//	sinc		Slowest function using a 16x16 neighborhood.
	//
	// Image is shifted by xOffset and yOffset. 
	// Optional parameters: int newWave -- Create a new wave by adding _rsl at the working directory
	// xscale, yscale: over/undersampling parameters
	
	string funcMethods = "bilinear;nn;cubic;spline;sinc"
	variable ifunc = WhichListItem(func, funcMethods)
	
	if(ifunc == -1 || WaveDims(wRef) != 2)
		return -1
	endif
	
	
	newWave =  ParamIsDefault(newWave) ? 0: newWave
	xscale = ParamIsDefault(xscale) ? 1: xscale
	yscale = ParamIsDefault(yscale) ? 1: yscale
	string wRefStr = GetWavesDataFolder(wRef, 2), cmdTemplateStr, cmdStr

	if(newWave) // New wave is createed at the working directory
		DFREF cwdfr = GetDataFolderDFR()
		STRING baseWaveNameStr = NameOfWave(wRef) + "_rsl"
		string newWaveNameStr = CreateDataObjectName(cwdfr, baseWaveNameStr, 1, 0, 1)
		cmdTemplateStr = "ImageInterpolate/FUNC=%s/TRNS={scaleShift, %.4f, %.4f, %.4f, %.4f}/DEST=%s Resample %s"
		sprintf cmdStr, cmdTemplateStr, func, xOffset, xscale, yOffset, yscale, PossiblyQuoteName(newWaveNameStr), wRefStr
		Execute/Z/Q cmdStr
		CopyScales/I wRef, $newWaveNameStr
	else
		cmdTemplateStr = "ImageInterpolate/FUNC=%s/TRNS={scaleShift, %.4f, %.4f, %.4f, %.4f} Resample %s"
		sprintf cmdStr, cmdTemplateStr, func, xOffset, xscale, yOffset, yscale, wRefStr
		Execute/Z/Q cmdStr
		WAVE M_InterpolatedImage
		CopyScales/I wRef, M_InterpolatedImage
		Duplicate/O M_InterpolatedImage, wRef
		KillWaves M_InterpolatedImage
	endif
	return 0
End

static Function PixelateImage(WAVE wRef, variable nx, variable ny, [variable i16])
	/// Pixalate a 2D image using a (nx, ny) binning
	/// Set i16 to preserve a 16-bit integer wave.
	if(WaveDims(wRef) != 2)
		return -1
	endif
	
	if(WaveType(wRef) & 0x10 && ParamIsDefault(i16)) // If WaveType is 16-bit integer and not i16
		Redimension/S wRef // 32-bit float
	endif 
	
	DFREF saveDF = GetWavesDataFolderDFR(wRef)

	string wnameStr = NameofWave(wRef) + "_" + num2str(nx) + "x" + num2str(ny) + "_px"
	ImageInterpolate/PXSZ={nx, ny}/DEST=saveDF:$wnameStr Pixelate wRef
	string noteStr = "Source:" + GetWavesDataFolder(wRef, 2) + " . Dimensions:("+ num2str(DimSize(wRef,0))+ ", " + num2str(DimSize(wRef,1)) + ")" + \
	".Pixelated factors:[" + num2str(nx) + ", " + num2str(ny) + "]/n" + note(wRef)
	CopyScales/I wRef, saveDF:$wnameStr
	Note saveDF:$wnameStr, noteStr
	return 0
End

static Function PixelateImageStack(WAVE wRef, variable nx, variable ny, variable nz, [variable i16])
	/// Pixalate a 3D image stack using a (nx, ny, nz) binning
	/// Set i16 to preserve a 16-bit integer wave.

	if(WaveDims(wRef) != 3)
		return -1
	endif
	
	if(WaveType(wRef) & 0x10 && ParamIsDefault(i16)) // If WaveType is 16-bit integer and not i16
		Redimension/S wRef // 32-bit float
	endif
	DFREF saveDF = GetWavesDataFolderDFR(wRef) 
	string wnameStr = NameofWave(wRef) + "_" + num2str(nx) + "x" + num2str(ny) + "x" + num2str(nz)
	ImageInterpolate/PXSZ={nx, ny, nz}/DEST=saveDF:$wnameStr Pixelate wRef
	string noteStr = "Source:" + GetWavesDataFolder(wRef, 2) + ".Dimensions:("+ num2str(DimSize(wRef,0))+ ", " + num2str(DimSize(wRef,1)) + \
	", " + num2str(DimSize(wRef,2)) + ")" +".Pixelated factors:[" + num2str(nx) + ", " + num2str(ny) + ", " + num2str(nz) + "]/n"+note(wRef)
	CopyScales/I wRef, saveDF:$wnameStr
	Note saveDF:$wnameStr, noteStr
	return 0
End

static Function MatrixFilter3D(WAVE wRef, string method, variable size, variable passes, [int overwite])
	/// Applies the MatrixFilter/N=size/P=passes method wRef
	/// to each layer of wRef
	overwite = ParamIsDefault(overwite) ? 1 : overwite // default overwite (used in drift correction)
	string allmethods = "gauss;avg;median:max;min"
	variable ifunc = WhichListItem(method, allmethods)
	if(ifunc == -1 || WaveDims(wRef) != 3)
		return -1
	endif
	variable nlayers = DimSize(wRef, 2), i
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	string buffer = "getStacklayer_", waveNameStr
	for(i = 0; i < nlayers; i++)
		waveNameStr = buffer + num2str(i)
		MatrixOP $waveNameStr = layer(wRef, i)
		MatrixFilter/N=(size)/P=(passes) $method $waveNameStr
	endfor
	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales wRef, M_Stack
	if(overwite)
		Duplicate/O M_Stack, saveDF:$NameofWave(wRef)
	else
		string newWaveNameStr = NameofWave(wRef) + "_flt"
		Duplicate/O M_Stack, saveDF:$newWaveNameStr
	endif		
	SetDataFolder saveDF
	return 0
End

static Function FlattenImage3D(WAVE wRef, string method, variable size, variable passes, [int overwrite])
	/// Applies the MatrixFilter/N=size/P=passes method wRef
	/// to each layer of wRef
	overwrite = ParamIsDefault(overwrite) ? 1 : overwrite // default overwite (used in drift correction)
	string allmethods = "gauss;avg;median:max;min"
	variable ifunc = WhichListItem(method, allmethods)
	if(ifunc == -1 || WaveDims(wRef) != 3)
		return -1
	endif
	variable nlayers = DimSize(wRef, 2), i
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	string buffer = "getStacklayer_", waveNameStr
	for(i = 0; i < nlayers; i++)
		waveNameStr = buffer + num2str(i)
		MatrixOP/FREE/O layerFree = layer(wRef, i)
		MatrixFilter/N=(size)/P=(passes) $method layerFree
		MatrixOP $waveNameStr = layer(wRef, i) - layerFree	
	endfor
	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales wRef, M_Stack
	if(overwrite)
		Duplicate/O M_Stack, saveDF:$NameofWave(wRef)
	else
		string newWaveNameStr = NameofWave(wRef) + "_flt"
		Duplicate/O M_Stack, saveDF:$newWaveNameStr
	endif		
	SetDataFolder saveDF
	return 0
End

static Function ImageWindow3D(WAVE wRef, string method)
	string allmethods = "Hanning;Hamming;Bartlett;Blackman"
	variable ifunc = WhichListItem(method, allmethods)
	if(ifunc == -1 || WaveDims(wRef) != 3)
		return -1
	endif
	variable nlayers = DimSize(wRef, 2), i
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	string buffer = "getStacklayer_", waveNameStr
	for(i = 0; i < nlayers; i++)
		waveNameStr = buffer + num2str(i)
		MatrixOP $waveNameStr = layer(wRef, i)
		ImageWindow/O $method $waveNameStr
	endfor
	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales wRef, M_Stack
	Duplicate/O M_Stack, saveDF:$NameofWave(wRef)		
	SetDataFolder saveDF
	return 0
End

static Function ShiftWaveUsingCursors(string graphStr)
	// Shift wave wRef relative to the A cursor difference between
	// the top graph (wRef) and graphStr
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE wRef = ImageNameToWaveRef(winNameStr, imgNameTopGraphStr)
	if(!strlen(imgNameTopGraphStr))
		return -1
	endif
	variable x0 = hcsr(A, winNameStr)
	variable y0 = vcsr(A, winNameStr)	
	variable x1 = hcsr(A, graphStr)
	variable y1 = vcsr(A, graphStr)
	if(numtype(x0) == 2 || numtype(x1) == 2)
		return -1
	endif
	variable dx = x1 - x0
	variable dy = y1 - y0
	string destWave = NameOfWave(wRef) + "_shift"
	ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=$destWave Affine2D wRef
	Note/K $destWave, "Source: "+ NameOfWave(wRef) + "\ndx: " + num2str(dx) + "\ndy: " + num2str(dy)
	return 0 	
End

static Function AffineTransformationThreePoint(WAVE src, WAVE dest, WAVE srcP, WAVE destP, WAVE coeff)
	variable a11, a12, tx, a21, a22, ty
	WAVE w  = ATH_Transform#GetAffine2DMapping(srcP, destP)
	ImageInterpolate/APRM={w[0],w[1],w[2],w[3],w[4],w[5],1,0}/DEST=dest Affine2D src
	return 0
End
