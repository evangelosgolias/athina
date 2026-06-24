#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_ImgOp
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

/// @module ATH_ImageOp
/// @brief Module ATH_ImageOp.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH ImageOp functionality.


/// @function RangeMeanSigmaTopImage
/// @brief Set the top image's color range to its mean plus or minus three standard deviations.
/// @details
/// Autoscale image of the top grap.
/// @returns Zero after updating the range; -1 when the top graph has no image wave.
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

/// @function GetLayerIndex
/// @brief Return layer index.
/// @param grfName Name of the graph window.
/// @param w (optional) Input wave.
/// @returns The zero-based index, or a negative value when no match is found.
static Function GetLayerIndex(string grfName, [Wave/Z w])
	if (ParamIsDefault(w))
		WAVE/Z w = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	endif
	if (!WaveExists(w) || WaveDims(w) != 3)
		return NaN
	endif
	
	return NumberByKey("plane", ImageInfo(grfName, PossiblyQuoteName(NameOfWave(w)), 0), "=")
End

/// @function AutoRangeTopImagePlane
/// @brief Autoscale the color range of the displayed image plane.
/// @details
/// Autoscale image of the top grap.
/// @returns Zero after completing the operation.
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

/// @function SetZScaleOfImageStack
/// @brief Set the layer-axis scale of the image stack in the top graph.
/// @returns Zero after completing the operation.
static Function SetZScaleOfImageStack() // Uses top graph
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE waveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable getScaleXY
	string cmdStr = "0, 0", setScaleZStr
	string msgDialog = "Scale Z direction of stack"
	string strPrompt = "Set firstVal,  lastVal in quotes (string).\n Leave \"\"  and press continue for autoscaling."
	if(WaveDims(waveRef) == 3)
		DoWindow/F $winNameStr
		setScaleZStr = ATH_Dialog#GenericSingleStrPrompt(strPrompt, msgDialog)
		string dataPathStr = GetWavesDataFolder(waveRef, 2)
		if(strlen(setScaleZStr))
		cmdStr = "SetScale/I z " + setScaleZStr + ", " + dataPathStr
		Execute/Z cmdStr
		endif
	endif
End

/// @function ImageSelectToCopyScale
/// @brief Copy dimension scales from a selected image to the top image.
/// @details
/// Select the first wave from browser selection.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function ImageSelectToCopyScale() // Uses top graph
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	// Select the first wave from browser selection
	string selectedWavesStr = ATH_Dialog#SelectWavesInModalDataBrowser("Select an image to set common dimension scaling")
	WAVE/Z sourceWaveRef = $StringFromList(0, selectedWavesStr)
	if(WaveExists(sourceWaveRef))
		CopyScales/P sourceWaveRef, wRef
		return 0
	endif
	return 1
End

/// @function NormaliseImageStackWithImage
/// @brief Divide every layer of an image stack by a two-dimensional reference image.
/// @param w3dRef Input image stack.
/// @param w2dRef Two-dimensional reference image used as the divisor.
/// @returns The full path of the normalized output stack.
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

/// @function NormaliseImageStackWithImageStack
/// @brief Divide an image stack pointwise by a second stack.
/// @param w3dRef1 Input image stack.
/// @param w3dRef2 Image stack used as the divisor.
/// @returns The full path of the normalized output stack.
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

/// @function NormaliseImageStackWithProfile
/// @brief Normalize each stack layer by the corresponding value of a one-dimensional profile.
/// @param w3dRef Input image stack.
/// @param profWaveRef One-dimensional normalization profile indexed by stack layer.
/// @returns The full path of the normalized output stack.
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

/// @function GetScaledZoominImageWindow
/// @brief Extract the visible graph region into a correctly scaled image wave.
/// @details
/// Get a the current window view as a new image with appropriate scaling. Works for 2D/3D waves. Added om
/// 12.05.2025.
/// @param grfName (optional) Name of the graph window.
/// @param w3d (optional) Input 3D wave or image stack.
/// @param evenNum (optional) If nonzero, force an even number of rows and columns.
/// @returns The scaled zoomin image window.
static Function GetScaledZoominImageWindow([string grfName, variable w3d, int evenNum])
	// Get a the current window view as a new image with appropriate scaling.
	// Works for 2D/3D waves
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	w3d = ParamIsDefault(w3d) ? 0 : !!w3d
	evenNum = ParamIsDefault(evenNum) ? 0 : !!evenNum
	
	string axisX, axisY, noteStr, wavenameStr
	variable minX, maxX, minY, maxY
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(grfName, ";"),";")
	WAVE wref = ImageNameToWaveRef(grfName, imgNameTopGraphStr) // full path of wave
	[axisX, minX, maxX, axisY, minY, maxY]  = ATH_Graph#GetAxesRange(grfName = grfName)
	DFREF cdfr = GetDataFolderDFR()
	if(WaveDims(wref) == 3)
		NVAR/Z gLayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(grfName):gLayer
		if(NVAR_Exists(gLayer))
			// Added om 12.05.2025
			if(w3d)
				wavenameStr = NameOfWave(wref) + "_PART"
				wavenameStr = CreateDataObjectName(cdfr, wavenameStr, 1, 0, 5)
				Duplicate/R=(minX, maxX)(minY, maxY) wRef, $wavenameStr
				//CopyScales/P wRef, $wavenameStr
				noteStr = NameOfWave(wref) + "_layer_" + num2str(gLayer) + "_ZM"
				sprintf noteStr, "CmdToZM:Duplicate/R=(%.4f, %.4f)(%.4f, %.4f) %s", minX, maxX, minY, maxY, GetWavesDataFolder(wRef,2)
			else
				wavenameStr = NameOfWave(wref) + "_ZM"
				wavenameStr = CreateDataObjectName(cdfr, wavenameStr, 1, 0, 5)
				MatrixOP/FREE getLayerFREE = layer(wRef, gLayer)
				CopyScales/P wRef, getLayerFREE
				Duplicate/R=(minX, maxX)(minY, maxY) getLayerFREE, $wavenameStr
				sprintf noteStr, "CmdToZM:Duplicate/R=(%.4f, %.4f)(%.4f, %.4f)[%d] %s ", minX, maxX, minY, maxY ,gLayer, GetWavesDataFolder(wRef,2)
			endif
		else
			print "Add a slider in your image stack (3d wave), I cannot guess the layer you want me to act on!"
			return -1
		endif
	elseif(WaveDims(wref) == 2)
		wavenameStr = NameOfWave(wref) + "_ZM"
		wavenameStr = CreateDataObjectName(cdfr, wavenameStr, 1, 0, 5)
		Duplicate/R=(minX, maxX)(minY, maxY) wRef, $wavenameStr
		//CopyScales/P wRef, $wavenameStr
		sprintf noteStr, "CmdToZM:Duplicate/R=(%.4f, %.4f)(%.4f, %.4f) %s ", minX, maxX, minY, maxY, GetWavesDataFolder(wRef,2)
	else
		print "Operation needs a image or image stack (2d/3d wave)"
		return -1
	endif
	if(evenNum)
		variable nRows = DimSize($wavenameStr,0)
		variable nCols = DimSize($wavenameStr,1)
		variable nlayers = DimSize(wref,2)
		if(mod(nRows,2))
			nRows -= 1
		endif
		if(mod(nCols,2))
			nCols -= 1
		endif
		if(w3d && nlayers)
			Redimension/N=(nRows, nCols, nlayers) $wavenameStr
		else
			Redimension/N=(nRows, nCols) $wavenameStr
		endif
	endif
	Note $wavenameStr, noteStr
End

/// @function GetLayerFromImageStack
/// @brief Return layer from image stack.
/// @returns The zero-based index, or a negative value when no match is found.
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

/// @function RemoveImagesFromImageStack
/// @brief Remove images from image stack.
/// @details
/// Remove nrLayers starting at startLayer from w3dRef. Use it to change wave notes.
/// @param wRef Input wave.
/// @param startLayer Lower or starting start layer.
/// @param nrLayers Number of image-stack layers.
/// @returns NaN if input validation fails; otherwise zero after completing the operation.
static Function RemoveImagesFromImageStack(WAVE wRef, variable startLayer, variable nrLayers)
	// Remove nrLayers starting at startLayer from w3dRef
	variable nL = DimSize(wRef, 2)
	if(nl < 2 || startLayer > nL)
		return NaN
	elseif(startLayer + nrLayers > nL)
		nrLayers = nL - startLayer
	endif
	string rmRangeStr = num2str(startLayer)+"-"+num2str(startLayer+nrLayers-1)
	string notesStr = note(wRef) // Get the note
	if(startLayer + nrLayers > DimSize(wRef,2)-1 && !startLayer) // startLayer is also removed
		print "You want to remove all layers, so it's better to delete the stack!"
		return -1
	elseif(startLayer + nrLayers > DimSize(wRef,2))
		ImageTransform/O/P=(startLayer)/NP=(DimSize(wRef,2)-startLayer) removeZplane wRef // remove till the end
	else
		ImageTransform/O/P=(startLayer)/NP=(nrLayers) removeZplane wRef
	endif
	ATH_String#UpdateStackWaveNote(wRef, 1, rangeStr=rmRangeStr, noteStr=notesStr)
	// Use it to change wave notes
	return 0
End

/// @function RemoveRangeOfImagesFromImageStack
/// @brief Remove range of images from image stack.
/// @details
/// You need to remove from the end if the list maybe you are trying to remove all the layers?.
/// @param wRef Input wave.
/// @param layerRangeList Layer range list.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function RemoveRangeOfImagesFromImageStack(WAVE wRef, string layerRangeList)
	// You need to remove from the end if the list
	// Tranlst
	string rangeStr = ATH_String#ExpandRangeStr(layerRangeList)
	string notesStr = note(wRef) // Get the note because ImageTransform will delete it!

	variable i, imax = ItemsInList(rangeStr), layerN, nLayers = DimSize(wRef, 2)
	// maybe you are trying to remove all the layers?
	if(imax >= nLayers)
		print "You want to remove all layers, so it's better to delete the stack!"
		return -1
	endif
	for(i = imax-1; i > -1 ; i--)
		layerN = str2num(StringFromList(i, rangeStr))
		if(layerN  <= nLayers - 1)
			ImageTransform/O/P=(layerN) removeZplane wRef
		endif
	endfor
	//ATH_String#UpdateStackWaveNote needs layerRangeList, not the expanded string
	ATH_String#UpdateStackWaveNote(wRef, 1, rangeStr=layerRangeList, noteStr=notesStr)
	return 0
End

/// @function InsertImagesToImageStack
/// @brief Insert images to image stack.
/// @details
/// Insert an image at the position layerN of an image stack. Here the z dimension will change, as the
/// DimDelta for rescaling. Note that the layerN stack will bethe first image after the insering stacks.
/// @param wRef Wave to modify in place.
/// @param wIn Input wave or window name, as required by the operation.
/// @param layerN Zero-based image-stack layer index.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function InsertImagesToImageStack(WAVE wRef, WAVE wIn, variable layerN)
	// Insert an image at the position layerN of an image stack.
	// Here the z dimension will change, as the DimDelta for rescaling
	// Note that the layerN stack will bethe first image after the insering stacks.
	// Given that, you cannot insert an image at the end of the stack, you will just
	// replace the last image and shift it. If you want to add after the last image 
	// you have to use the append operation.
	
	if((DimSize(wRef, 0) == DimSize(wIn, 0)) && DimSize(wRef, 1) == DimSize(wRef, 1))
		variable x0, y0, z0, dx, dy, dz
		[x0, y0, z0, dx, dy, dz] = ATH_WaveOp#GetScalesP(wRef)
		//ImageTransform/O/INSW=wIn/P=(layerN) insertZplane wRef
		//ATH_WaveOp#SetScalesP(wRef, x0, y0, z0, dx, dy, dz)
		if(!layerN)
			Concatenate/O/KILL/NP=2/FREE {wIn, wRef}, bufferWaveFree
			Duplicate/O bufferWaveFree, $GetWavesDataFolder(wRef,2)
		elseif(layerN >= DimSize(wRef,2)) // append
			Concatenate/O/KILL/NP=2/FREE {wRef, wIn}, bufferWaveFree
			Duplicate/O bufferWaveFree, $GetWavesDataFolder(wRef,2)			
		else
			ImageTransform/P=(layerN)/NP=(DimSize(wRef,2)-layerN) removeZplane wRef
			WAVE M_ReducedWave
			ImageTransform/O/P=0/NP=(layerN) removeZplane wRef		
			Concatenate/O/KILL/NP=2/FREE {M_ReducedWave, wIn, wRef}, bufferWaveFree
			Duplicate/O bufferWaveFree, $GetWavesDataFolder(wRef,2)
		endif
	else
		print "Image and stack must have the same lateral dimensions."
		return -1
	endif
	return 0
End

/// @function AppendImagesToImageStack
/// @brief Append images to image stack.
/// @details
/// Append images in waveListStr to wRef.
/// @param wRef Input wave.
/// @param waveListStr Wave used by the operation.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
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

/// @function ConcatenateImages
/// @brief Concatenate images.
/// @details
/// Concatenate wave to destWaveStr.
/// @param destWaveStr Wave used by the operation.
/// @param waveListStr Wave used by the operation.
/// @returns Zero after completing the operation.
static Function ConcatenateImages(string destWaveStr, string waveListStr) 
	//
	// Concatenate wave to destWaveStr
	//
	WAVE/WAVE wRefw = ATH_WaveOp#WaveListStrToWaveRef(waveListStr, isFree = 1)
	Concatenate/O/NP=2 {wRefw}, $destWaveStr
End

/// @function ImageEdgeDetectionToStack
/// @brief Apply an edge-detection command to every layer of an image stack.
/// @details
/// Applied the edge detection operation to w3dref and outputs a wave with name NameofWave(w3dref) + "_ed".
/// You can optionally ovewrite the input wave.
/// @param w3dref Input 3D image stack.
/// @param cmd Igor command or operation string.
/// @param overwrite (optional) If nonzero, replace the source or an existing destination.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function ImageEdgeDetectionToStack(WAVE w3dref, string cmd, [variable overwrite])
	/// Applied the edge detection operation to w3dref
	/// and outputs a wave with name NameofWave(w3dref) + "_ed"
	/// You can optionally ovewrite the input wave
	
	overwrite = ParamIsDefault(overwrite) ? 0: overwrite

	if(WaveType(w3dref) & 0x10) // If WORD (int16)
		Redimension/S w3dref
	endif
	
	variable nlayers = DimSize(w3dref, 2), i
	
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	
	string cmdExe, dumpStr, errMessage
	SplitString/E="(^.*(?=\s+\S+\s*$))(.*)" cmd, cmdExe, dumpStr
	//If user gives the command without the wave name
	string methods = "canny;frei;kirsch;marr;prewitt;roberts;shen;sobel"
	dumpStr = ATH_String#RemoveCharFromString(dumpStr, " ")
	if(WhichListItem(dumpStr, methods,";", 0, 0) == - 1)
		cmdExe += " M_ImagePlane"
	else
		cmdExe = cmd +" M_ImagePlane"
	endif
	
	for(i = 0; i < nlayers; i++)
		ImageTransform/P=(i) getPlane w3dref
		WAVE M_ImagePlane
		Execute/Q/Z cmdExe
		WAVE M_ImageEdges		
		Rename M_ImageEdges, $("ATHWaveToStack_idx_" + num2str(i))
	endfor
	variable err = GetRTError(1)
	if(err)
		SetDataFolder saveDF
		return -1
	endif
	ImageTransform/NP=(nlayers) stackImages $"ATHWaveToStack_idx_0"
	WAVE M_Stack
	string stacknameStr = CreateDataObjectName(saveDF, NameofWave(w3dref) + "_edgeD", 1, 0, 1)
	if(overwrite)
		Duplicate/O M_stack, w3dref
	else
		MoveWave M_stack, saveDF:$stacknameStr
		CopyScales/I w3dref, saveDF:$stacknameStr
	endif
	SetDataFolder saveDF
	return 0
End

/// @function ImageRotateAndScale
/// @brief Rotate and rescale an image while preserving its physical coordinates.
/// @details
/// Math: If the side of the image is a, then the rotated image will have side a_rot = a * (cos(angle) +
/// sin(angle)).
/// @param wRef Wave to modify in place.
/// @param angle Angle.
/// @param backup (optional) If nonzero, preserve a backup of the source image.
/// @param flipY (optional) If nonzero, flip the result along y.
/// @returns Zero after completing the operation.
static Function ImageRotateAndScale(WAVE wRef, variable angle, [variable backup, variable flipY])
	/// Math: If the side of the image is a, then the rotated image
	/// will have side a_rot = a * (cos(angle) + sin(angle))
	/// @param wRef: 2d or 3d wave	
	/// @param angle: counter clockwise rotation in degrees
	/// @param backup: backup wave before rotation
	/// @param fliY: flip cols
	
	/// flipY = 0 when Mirror in ON ? 
	backup = ParamIsDefault(backup) ? 0 : backup
	flipY = ParamIsDefault(flipY) ? 0 : flipY
	if(backup)
		string backupWaveNameStr = NameOfWave(wRef) + ksATHBackupWaveExtention
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
		ImageTransform flipCols wRef // flip the y-axis
		noteStr += "Flipped  y-axis (rows)\n"
	endif
	ImageRotate/O/E=0/A=(-angle) wRef
	noteStr +="Image rotated by " + num2str(angle) + " deg\n"
	Note wRef, noteStr
	if(backup)
		CopyScales/P wRefbck, wRef // /P needed here to prevent on image distances.	
	else
		SetScale/P x, x0, dx, wRef
		SetScale/P y, y0, dy, wRef
		SetScale/P z, z0, dz, wRef				
	endif
End

/// @function BackupTopImage
/// @brief Backup top image.
/// @details
/// Backup wave in the top window, the backup is created in the sourcewave datafolder (to be able to
/// restore).
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function BackupTopImage()
	/// Backup wave in the top window, the backup is created in the 
	/// sourcewave datafolder (to be able to restore)
	
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef()
	if(!WaveExists(wRef))
		print "Operation needs an image or image stack"
		return -1
	endif
	DFREF wDFR = GetWavesDataFolderDFR(wRef)
	WAVE/Z backupWave = wDFR:$(NameOfWave(wRef) + ksATHBackupWaveExtention)
	if(WaveExists(backupWave))
		DoAlert/T="Overwite backup wave?", 1, ("Do you want to overwite " + GetWavesDataFolder(backupWave,2) + "?")
		if(V_flag == 1)
			Duplicate/O wref, backupWave
			print "Backup/O wave: ", backupWave
		endif
	else
		Duplicate wRef, wDFR:$(NameOfWave(wRef) + ksATHBackupWaveExtention)
		WAVE backupWave	= wDFR:$(NameOfWave(wRef) + ksATHBackupWaveExtention)
		print "Backup wave: ", GetWavesDataFolder(backupWave,2)
	endif
	return 0
End

/// @function RestoreTopImageFromBackup
/// @brief Restore top image from backup.
/// @details
/// Restore an image from backup. When ParamIsDefault (wavenameStr = "") the image on the top window is used,
/// otherwise WAVE $wavenameStr. Backup wave's name is *assummed* to be NameOfWave(wRef) +
/// ksATHBackupWaveExtention.
/// @param grfName (optional) Name of the graph window.
/// @param keepBackup (optional) If nonzero, retain the backup after restoration.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function RestoreTopImageFromBackup([string grfName, variable keepBackup])
	/// Restore an image from backup. When ParamIsDefault (wavenameStr = "")
	/// the image on the top window is used, otherwise WAVE $wavenameStr.
	/// Backup wave's name is *assummed* to be NameOfWave(wRef) + ksATHBackupWaveExtention
	/// and it is located on the same folder as the source image
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1,"", grfName)
	keepBackup = ParamIsDefault(keepBackup) ? 0: !!keepBackup
	if(ParamIsDefault(grfName))
		WAVE wRef = ATH_Graph#TopImageToWaveRef()
	else
		WAVE wRef = $grfName		
	endif
	
	if(!WaveExists(wRef))
		return -1
	endif
	
	DFREF wdfr = GetWavesDataFolderDFR(wRef)
	string backupWaveNameStr = NameOfWave(wRef) + ksATHBackupWaveExtention
	WAVE/SDFR=wdfr/Z wRefbck = $backupWaveNameStr
	if(WaveExists(wRefbck))
		if(!keepBackup)
			CheckDisplayed/A wRefbck
			if(V_Flag) // if wave is displayed
				Duplicate/O wRefbck, wRef
				print "Cannot kill " + backupWaveNameStr + ". CheckDisplayed == 1."
			else
				Duplicate/O wRefbck, wRef
				KillWaves wRefbck
			endif
		else
			Duplicate/O wRefbck, wRef
		endif
	else
		return -1
	endif
	return 0
End

/// @function ExtractLayerRange
/// @brief Extract a contiguous layer range as a new stack or as individual image waves.
/// @details
/// When `doStack` is nonzero, the result is a scaled 3D stack. Otherwise the layers are written into a new data
/// folder, optionally using names stored in the source wave note.
/// @param w3d Input 3D image stack.
/// @param startL (optional) Zero-based first layer to extract.
/// @param endL (optional) Zero-based last layer to extract, inclusive.
/// @param doStack (optional) If nonzero, combine the selected layers into one 3D stack.
/// @param nameNote (optional) If nonzero, name extracted layers from the source wave note when possible.
/// @returns The full path of the output stack or data folder; an empty string indicates invalid bounds.
static Function/S ExtractLayerRange(WAVE w3d, [variable startL, variable endL, 
				variable doStack, variable nameNote])
	// Extract layers to a new stack
	variable  nlayers = DimSize(w3d, 2), i
	startL = ParamIsDefault(startL) ? 0 : startL
	endL = ParamIsDefault(endL) ? nlayers - 1 : endL	
	
	if(endL > nlayers - 1 || endL < startL || startL < 0 || WaveDims(w3d) != 3)
		print "Error in layer range, check your input (ATH_ImgOp#ExtractLayerRange)"
		return ""
	endif
	variable totL = endL - startL + 1 // include endpoints
	DFREF saveDF = GetDataFolderDFR()
	if(doStack)
		SetDataFolder NewFreeDataFolder()
		for(i = startL; i < endL+1; i++)
			MatrixOP/O $("getLayer_" + num2str(i)) = layer(w3d, i)
		endfor
		ImageTransform/NP=(totL) stackImages $("getLayer_"+num2str(startL))
		WAVE M_Stack
		CopyScales w3d, M_Stack
		variable dz = DimDelta(w3d,2)
		variable offset = DimOffset(w3d,2) + startL*dz
		string basenameStr = NameOfWave(w3d) + "_stkL_" + num2str(startL) + "_" + num2str(endL)
		string saveStackNameStr = CreatedataObjectName(saveDF,basenameStr , 1, 0, 1)
		Duplicate/O M_Stack, saveDF:$saveStackNameStr
		SetScale/P z, offset, dz, saveDF:$saveStackNameStr
		Note saveDF:$saveStackNameStr, "Layers=[" + num2str(startL) +","+\
		num2str(endL) + "], source: " + GetWavesDataFolder(w3d,2)
		SetDataFolder saveDF
		return GetWavesDataFolder(saveDF:$saveStackNameStr,2)
	else
		string folder = CreateDataObjectName(saveDF, NameOfWave(w3d) + " layers", 11, 0, 1)
		NewDataFolder/S $folder
		if(nameNote)
			string wavelistStr = ATH_string#GetStackNamesFromNote(w3d), wname
			waveListStr = ATH_String#RemoveIndexKeysFromList(waveListStr, keySep=">", listSep="\n")
			// TODO: Make a better checking on notes and wavenames
			if(ItemsInList(waveListStr, "\n") != nlayers) // No matching notes so extraxt 
				print "Number of wavenote names not equal to number of layers, extracting all layers without names."
				for(i = startL; i < endL+1; i++)
					MatrixOP $("layer" + num2str(i)) = layer(w3d, i)
					WAVE wRef = $("layer" + num2str(i))
					CopyScales/P w3d, wRef
					Note wRef, "Layer=" + num2str(i) + ", source: " + GetWavesDataFolder(w3d,2)				
				endfor
			else
				waveListStr = ATH_String#GetRangeItemsFromList(waveListStr, "\n", startL, endL)
				// Assume here all are extracted as it should
				print "Else\n", waveListStr
				for(i = startL; i < endL+1; i++)
					wname = ParseFilePath(0, StringFromList(i-startL, waveListStr,"\n"), ":", 1, 0) // !!!!!
					wname = ATH_String#RemoveCharFromString(wname,"'") // Remove single quotes if any
					MatrixOP $wname = layer(w3d, i)					   // otherwise MatrixOP $wavename pops an error
					CopyScales/P w3d, $wname
					Note $wname, "Layer=" + num2str(i) + ", source: " + GetWavesDataFolder(w3d,2)
				endfor
			endif
		else
			for(i = startL; i < endL+1; i++)
				MatrixOP $("layer" + num2str(i)) = layer(w3d, i)
				WAVE wRef = $("layer" + num2str(i))
				CopyScales/P w3d, wRef
				Note wRef, "Layer=" + num2str(i) + ", source: " + GetWavesDataFolder(w3d,2)				
			endfor
		endif
		SetDataFolder saveDF
		return folder
	endif
	
End

/// @function AverageImageRangeToStackOffset
/// @brief Average image range to stack offset.
/// @details
/// Average NPL image planes in stack starting from N0.
/// @param w3d Input 3D wave or image stack.
/// @param NP0 First point index.
/// @param NPL Number of points or final point index.
/// @returns Zero after completing the operation.
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

/// @function AverageImageRangeToStack
/// @brief Average image range to stack.
/// @details
/// Average image range NP0-NP1, including endpoints.
/// @param w3d Input 3D wave or image stack.
/// @param NP0 First point index.
/// @param NP1 Second point index.
/// @returns Zero after completing the operation.
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

/// @function HistogramShiftToGaussianCenter
/// @brief Histogram shift to gaussian center.
/// @details
/// Move the histogram center to the center of the fitted gaussian. Useful for symmetrising XMCD/XMLD images.
/// Add the value to w2d.
/// @param w2d Input 2D image.
/// @param overwrite (optional) If nonzero, replace the source or an existing destination.
/// @returns Zero after completing the operation.
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

/// @function HistogramShiftToGaussianCenterStack
/// @brief Histogram shift to gaussian center stack.
/// @details
/// Move the histogram center to the center of the fitted gaussian. Useful for symmetrising XMCD/XMLD images.
/// The function returns the applies shift.
/// @param w3d Input 3D wave or image stack.
/// @param overwrite (optional) If nonzero, replace the source or an existing destination.
/// @returns The Gaussian-center shift applied to the final processed layer.
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

/// @function GrayToRGBImage
/// @brief Convert a grayscale image into an RGB image using the Grays color table.
/// @param wRef Input wave.
/// @returns Zero after completing the operation.
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
	return 0	
End

/// @function RGB2Gray8Image
/// @brief Convert an RGB image to 8-bit grayscale.
/// @details
/// Convert a 3D RGB image to grayscale (8-bit).
/// @param wRef Input wave.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
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

/// @function RGB2Gray16Image
/// @brief Convert an RGB image to 16-bit grayscale.
/// @details
/// Convert a 3D RGB image to grayscale (16-bit) /W/U. The RGB values are converted into the luminance Y of
/// the YIQ standard using.
/// @param wRef Wave to modify in place.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function RGB2Gray16Image(WAVE wRef)
	// Convert a 3D RGB image to grayscale (16-bit) /W/U
	//The RGB values are converted into the luminance Y of the YIQ standard using:
	// Y = 0.299R + 0.587G + 0.114B
	
	
	// Y = 0.299*R + 0.587*G + 0.114*B  /B/U
	// I = 0.596*R – 0.275*G – 0.321*B  /B
	// Q = 0.212*R – 0.523*G + 0.311*B	/B
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

/// @function FlattenImage
/// @brief Flatten image.
/// @param wRef Wave to modify in place.
/// @param method Algorithm or processing method to apply.
/// @param kind Filter or morphology operation to apply.
/// @param kernelN Kernel width in points.
/// @param iterN Number of processing iterations.
/// @param overwrite (optional) If nonzero, replace the source or an existing destination.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function FlattenImage(WAVE wRef, string method, string kind, variable kernelN, variable iterN, [int overwrite])
	// Flatten image
	overwrite = ParamIsDefault(overwrite) ? 0 : overwrite
	string allmethods = "gauss;avg;median:max;min" // method
	variable ifunc = WhichListItem(method, allmethods)
	string allkinds = "additive;multiplicative" // kind
	variable ikind = WhichListItem(kind, allkinds)	
	if(ifunc == -1)
		return -1
	endif

	Duplicate/O/FREE wRef, bkgFREE
	MatrixFilter/P=(iterN)/N=(kernelN) $method bkgFREE // MatrixFilter operation overwrites source
	if(overwrite)
		if(ikind)
			WaveStats/Q/M=1 bkgFREE
			bkgFREE = (bkgFREE-V_min)/(V_max-V_min)
			WaveStats/Q/M=1 bkgFREE
			MatrixOP/O bkgFREE = bkgFREE+V_avg*equal(bkgFREE,0)
			wRef /= bkgFREE
		else
			wRef -= bkgFREE
		endif		
	else
		string waveNameStr = NameOfWave(wRef)
		DFREF dfr = GetDataFolderDFR()
		string flattenWaveStr = CreateDataObjectName(dfr, waveNameStr + "_flt", 1, 0, 1)
		if(ikind)
			WaveStats/Q/M=1 bkgFREE
			bkgFREE = (bkgFREE-V_min)/(V_max-V_min)
			WaveStats/Q/M=1 bkgFREE		
			MatrixOP/O bkgFREE = bkgFREE+V_avg*equal(bkgFREE,0)
			MatrixOP $flattenWaveStr = wRef / bkgFREE
		else
			MatrixOP $flattenWaveStr = wRef - bkgFREE
		endif
	endif
	return 0
End

/// @function ImgRemoveBackground
/// @brief Image remove background.
/// @details
/// Remove background of an image (default 1st order). Use order = n, n > 1 for higher order polynomial. Use
/// overwite = 1 to overwite the original wave.
/// @param wRef Wave to modify in place.
/// @param order (optional) Interpolation or polynomial order.
/// @param useMask (optional) If nonzero, restrict the calculation to the supplied mask.
/// @param layerN (optional) Zero-based image-stack layer index.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function ImgRemoveBackground(WAVE wRef, [variable order, int useMask, variable layerN])
	// Remove background of an image (default 1st order)
	// Use order = n, n > 1 for higher order polynomial
	// Use overwite = 1 to overwite the original wave
	order = ParamIsDefault(order) ? 1: order
	useMask = ParamIsDefault(useMask) ? 0: !!useMask
	layerN = ParamIsDefault(layerN) ? -1 : layerN // if you do not define layer, apply to all

	variable nrows, ncols
	nrows = DimSize(wRef,0)
	ncols = DimSize(wRef,1)
	
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder GetWavesDataFolderDFR(wRef)
	
	if(useMask) // Reserved for arbitrary masks
		WAVE maskW = M_ROIMask // if you provide a mask - use default mask name
		string maskNote = note(maskW)
	else
		Make/O/FREE/N=(nrows,ncols)/B/U maskWFree = 1
		WAVE maskW = maskWFree
		maskNote = ""
	endif
	
	SetDataFolder saveDF
	
	if(WaveType(wRef) & 0x02) // We need a 32-bit float for better results
		Redimension/S wRef
	endif
	
	// If you have a 2D wave
	if(WaveDims(wRef) == 2)
		ImageRemoveBackground/O/R=maskW/P=(order) wRef
		Note wRef, "\nImageRemoveBackground/P=" + num2str(order) + "\n" + maskNote	
		return 0
	endif	
	
	variable nlayers = DimSize(wRef, 2)
	// If you have a 3D wave
	if(WaveDims(wRef) == 3)
		if(layerN < 0) // layerN < 0 to apply to all layers
			variable i
			DFREF saveDF = GetDataFolderDFR()
			SetDataFolder NewFreeDataFolder()
			string buffer = "layer_", waveNameStr
			for(i = 0; i < nlayers; i++)
				waveNameStr = buffer + num2str(i)
				MatrixOP/O $waveNameStr = layer(wRef, i)
				WAVE w = $waveNameStr
				ImageRemoveBackground/O/R=maskW/P=(order) w
			endfor
			ImageTransform/NP=(nlayers) stackImages $"layer_0"
			WAVE M_Stack
			// Restore scale here
			CopyScales wRef, M_Stack
			Duplicate/O M_Stack, wRef
			Note wRef, "\nImageRemoveBackground/P=" + num2str(order) + "\n" + maskNote			
			SetDataFolder saveDF
		elseif(layerN < nlayers)
			// Code to replace plane in 3d wave
			MatrixOP/FREE getLayer = layer(wRef, layerN)
			ImageRemoveBackground/O/R=maskW/P=(order) getLayer
			ImageTransform/O/P=(layerN) removeZplane wRef
			ImageTransform/O/INSW=getLayer/P=(layerN) insertZplane wRef
			Note wRef, "\nImageRemoveBackground/P=" + num2str(order) + "layer="+num2str(layerN)+"\n" + maskNote				
		else
			return 1
		endif
	endif
	return 0
End

/// @function ImgRemoveBackgroundCols
/// @brief Remove a fitted background independently from each image column.
/// @details
/// Image Remove 1-d background from each column. Make/O/N=(DimSize(wRef,1), orderN) fitCoeff fitCoeff[i][] =
/// W_coef[q].
/// @param wRef Wave to modify in place.
/// @param orderN Interpolation or polynomial order.
/// @returns Zero after completing the operation.
static Function ImgRemoveBackgroundCols(WAVE wRef, variable orderN) //TODO! Fix it!
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

/// @function PixelateImage
/// @brief Pixelate image.
/// @details
/// Pixalate a 2D image using a (nx, ny) binning. Set i16 to preserve a 16-bit integer wave.
/// @param wRef Wave to modify in place.
/// @param nx Number of points along the x dimension.
/// @param ny Number of points along the y dimension.
/// @param i16 (optional) If nonzero, produce a 16-bit integer image.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
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
	".Pixelated factors:[" + num2str(nx) + ", " + num2str(ny) + "]\n" + note(wRef)
	SetScale/P x, DimOffset(wRef,0), DimDelta(wRef,0)*nx,saveDF:$wnameStr
	SetScale/P y, DimOffset(wRef,1), DimDelta(wRef,1)*ny,saveDF:$wnameStr
	Note saveDF:$wnameStr, noteStr
	return 0
End

/// @function PixelateImageStack
/// @brief Pixelate image stack.
/// @details
/// Pixalate a 3D image stack using a (nx, ny, nz) binning. Set i16 to preserve a 16-bit integer wave.
/// @param wRef Wave to modify in place.
/// @param nx Number of points along the x dimension.
/// @param ny Number of points along the y dimension.
/// @param nz Number of points or layers along the z dimension.
/// @param i16 (optional) If nonzero, produce a 16-bit integer image.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
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
	string wnameStr = NameofWave(wRef) + "_" + num2str(nx) + "x" + num2str(ny)
	if(nz)
		wnameStr += "x" + num2str(nz)
		ImageInterpolate/PXSZ={nx, ny, nz}/DEST=saveDF:$wnameStr Pixelate wRef
	else
		ImageInterpolate/PXSZ={nx, ny}/DEST=saveDF:$wnameStr Pixelate wRef // Average only in rows/columns not layers!!!
	endif
	string noteStr = "Source:" + GetWavesDataFolder(wRef, 2) + ". Source dimensions:("+ num2str(DimSize(wRef,0))+ ", " + num2str(DimSize(wRef,1)) + \
	", " + num2str(DimSize(wRef,2)) + ")" +". Pixelated factors:[" + num2str(nx) + ", " + num2str(ny)
	if(nz) 
		noteStr += ", " + num2str(nz) + "]\n"+note(wRef)	
	else
		noteStr += "]\n"+note(wRef)	
	endif
	SetScale/P x, DimOffset(wRef,0), DimDelta(wRef,0)*nx,saveDF:$wnameStr
	SetScale/P y, DimOffset(wRef,1), DimDelta(wRef,1)*ny,saveDF:$wnameStr
	if(nz)
		SetScale/P z, DimOffset(wRef,2), DimDelta(wRef,2)*nz,saveDF:$wnameStr
	else
		SetScale/P z, DimOffset(wRef,2), DimDelta(wRef,2),saveDF:$wnameStr // Keep the scale as is.
	endif
	Note saveDF:$wnameStr, noteStr
	return 0
End

/// @function ImageFilter3D
/// @brief Apply an Igor matrix filter independently to every layer of a 3D image stack.
/// @details
/// Reassembles the filtered planes with the original scaling and wave note. By default the source is overwritten; otherwise a new wave with a `_filter` suffix is created.
/// @param wRef Input 3D image stack.
/// @param method Matrix-filter method: `gauss`, `avg`, `median`, `max`, or `min`.
/// @param size Filter-kernel size in points.
/// @param passes Number of filter passes.
/// @param overwrite (optional) If nonzero, replace `wRef`; defaults to one.
/// @returns Zero on success; -1 for an unsupported method or a non-3D input wave.
static Function ImageFilter3D(WAVE wRef, string method, variable size, variable passes, [int overwrite])
	/// Applies the MatrixFilter/N=size/P=passes method wRef
	/// to each layer of wRef
	overwrite = ParamIsDefault(overwrite) ? 1 : overwrite // default overwite (used in drift correction)
	string allmethods = "gauss;avg;median;max;min"
	variable ifunc = WhichListItem(method, allmethods)
	if(ifunc == -1 || WaveDims(wRef) != 3)
		return -1
	endif
	variable nlayers = DimSize(wRef, 2), i
	DFREF currDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	string buffer = "getStacklayer_", waveNameStr
	for(i = 0; i < nlayers; i++)
		waveNameStr = buffer + num2str(i)
		MatrixOP $waveNameStr = layer(wRef, i)
		MatrixFilter/N=(size)/P=(passes) $method $waveNameStr
	endfor
	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	DFREF saveDF = GetWavesDataFolderDFR(wRef)
	// Restore scale here
	CopyScales wRef, M_Stack
	Note M_Stack, note(wRef) // Get the note of the wave, see ATH_String#WaveLogging below
	string noteStr = "Applied MatrixFilter/N="+num2str(size)+"/P="+num2str(passes)+ " " + method + " " + NameofWave(wRef)
	if(overwrite)
		Duplicate/O M_Stack, saveDF:$NameofWave(wRef)
		ATH_String#WaveLogging(saveDF:$NameofWave(wRef), noteStr, prepend=1)
	else
		string newWaveNameStr = CreateDataObjectName(saveDF, NameofWave(wRef) + "_filter", 1, 0, 1)
		Duplicate/O M_Stack, saveDF:$newWaveNameStr
		ATH_String#WaveLogging(saveDF:$newWaveNameStr, noteStr,prepend=1)
	endif
	SetDataFolder currDF
	return 0
End

/// @function FlattenImage3D
/// @brief Flatten image 3D.
/// @details
/// Applies the MatrixFilter/N=size/P=passes method wRef to each layer of wRef. Restore scale here.
/// @param wRef Input wave.
/// @param method Algorithm or processing method to apply.
/// @param kind Filter or morphology operation to apply.
/// @param size Size.
/// @param passes Number of filter passes to apply.
/// @param overwrite (optional) If nonzero, replace the source or an existing destination.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function FlattenImage3D(WAVE wRef, string method, string kind, variable size, variable passes, [int overwrite])
	/// Applies the MatrixFilter/N=size/P=passes method wRef
	/// to each layer of wRef
	overwrite = ParamIsDefault(overwrite) ? 1 : overwrite // default overwite (used in drift correction)
	string allmethods = "gauss;avg;median;max;min"
	variable ifunc = WhichListItem(method, allmethods)
	string allkinds = "additive;multiplicative" // kind
	variable ikind = WhichListItem(kind, allkinds)	
		
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
		if(ikind) // 1
			WaveStats/Q/M=1 layerFree
			layerFree = (layerFree-V_min)/(V_max-V_min)
			WaveStats/Q/M=1 layerFree
			MatrixOP/O layerFree = layerFree+V_avg*equal(layerFree,0)
			MatrixOP $waveNameStr = layer(wRef, i) / layerFree
		else // 0
			MatrixOP $waveNameStr = layer(wRef, i) - layerFree
		endif
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

/// @function ImageWindow3D
/// @brief Image window 3D.
/// @details
/// Restore scale here.
/// @param wRef Input wave.
/// @param method Algorithm or processing method to apply.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
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

/// @function ImageResampling
/// @brief Resample and translate an image with a selected interpolation method.
/// @details
/// Supported interpolation functions are `bilinear`, `nn`, `cubic`, `spline`, and `sinc`. Offsets and scale
/// factors are passed to Igor's `ImageInterpolate` operation.
/// @param wRef Input wave.
/// @param func Interpolation function: `bilinear`, `nn`, `cubic`, `spline`, or `sinc`.
/// @param xOffset Horizontal translation in source pixels.
/// @param yOffset Vertical translation in source pixels.
/// @param overwrite (optional) If nonzero, replace the source or existing destination.
/// @param xscale (optional) Horizontal resampling factor.
/// @param yscale (optional) Vertical resampling factor.
/// @returns The full path of the resampled image, or an empty string for invalid input.
static Function/S ImageResampling(WAVE wRef,  string func, variable xOffset, variable yOffset,
							 [int overwrite, variable xscale, variable yscale])
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
		return ""	
	endif
	
	
	overwrite =  ParamIsDefault(overwrite) ? 0: !!overwrite
	xscale = ParamIsDefault(xscale) ? 1: xscale
	yscale = ParamIsDefault(yscale) ? 1: yscale
	string wRefStr = GetWavesDataFolder(wRef, 2), cmdTemplateStr, cmdStr

	if(overwrite) // New wave is createed at the working directory
		cmdTemplateStr = "ImageInterpolate/FUNC=%s/TRNS={scaleShift, %.4f, %.4f, %.4f, %.4f} Resample %s"
		sprintf cmdStr, cmdTemplateStr, func, xOffset, xscale, yOffset, yscale, wRefStr
		Execute/Z/Q cmdStr
		WAVE M_InterpolatedImage
		CopyScales/I wRef, M_InterpolatedImage
		Duplicate/O M_InterpolatedImage, wRef
		Note wRef, cmdStr
		KillWaves M_InterpolatedImage
		return GetWavesDataFolder(wRef,2)		
	else
		DFREF cwdfr = GetDataFolderDFR()
		STRING baseWaveNameStr = NameOfWave(wRef) + "_rsl"
		string newWaveNameStr = CreateDataObjectName(cwdfr, baseWaveNameStr, 1, 0, 1)
		cmdTemplateStr = "ImageInterpolate/FUNC=%s/TRNS={scaleShift, %.4f, %.4f, %.4f, %.4f}/DEST=%s Resample %s"
		sprintf cmdStr, cmdTemplateStr, func, xOffset, xscale, yOffset, yscale, PossiblyQuoteName(newWaveNameStr), wRefStr
		Execute/Z/Q cmdStr
		WAVE wDest = cwdfr:$newWaveNameStr
		CopyScales/I wRef, wDest
		Note wDest, cmdStr	
		return GetWavesDataFolder(wDest,2)		
	endif
	
End

/// @function ScaleImagePreserveDims
/// @brief Scale image preserve dims.
/// @param wRef Input wave.
/// @param factor Factor.
/// @param factorY (optional) Factor y.
/// @returns Zero after completing the operation.
static Function ScaleImagePreserveDims(WAVE wRef, variable factor, [variable factorY])
	
	variable nrows = DimSize(wRef, 0), ncols = DimSize(wRef, 1)
	string wnameStr = CreateDataObjectName(GetDataFolderDFR(),NameOfWave(wRef)+"_scld",1,0,1)
	if(ParamIsDefault(factorY))
		ImageInterpolate/APRM={factor,0,0,0,factor,0,1,0}/DEST=$wnameStr Affine2D wRef
	else
		ImageInterpolate/APRM={factor,0,0,0,factorY,0,1,0}/DEST=$wnameStr Affine2D wRef
	endif
	WAVE wScaled = $wnameStr
	Redimension/N=(nrows, ncols) wScaled
	CopyScales/I wRef, wScaled
	string wNote = note(wRef)
	if(ParamIsDefault(factorY))
		Note wScaled, wNote + "\n"+"ScaleImageSameDims with factor = " + num2str(factor)
	else
		Note wScaled, wNote + "\n"+"ScaleImageSameDims with factor = (" + num2str(factor) + ", "+ num2str(factorY) + ")"
	endif	
	
End

/// @function ScaleFoVWithFactor
/// @brief Scale an image's field of view by a multiplicative factor.
/// @details
/// Scale image with factor.
/// @param wRef Wave to modify in place.
/// @param factor Factor.
/// @param interval (optional) Sampling interval for the generated or rescaled data.
/// @returns Zero after completing the operation.
static Function ScaleFoVWithFactor(WAVE wRef, variable factor,[int interval])
	// Scale image with factor 
	variable x0 = DimOffset(wRef, 0), y0 = DimOffset(wRef, 1)
	variable dx = DimDelta(wRef, 0), dy = DimDelta(wRef, 1)
	if(interval)
		variable lenx = (DimSize(wRef, 0) - 1) * dx
		variable leny = (DimSize(wRef, 1) - 1) * dy		
		SetScale/I x, x0, x0+lenx*factor, wRef
		SetScale/I y, y0, y0+leny*factor, wRef	
	else
		SetScale/P x, x0, dx*factor, wRef
		SetScale/P y, y0, dy*factor, wRef	
	endif
	return 0
End


/// @function ComputeImageZScore
/// @brief Create a z-score-normalized copy of an image wave.
/// @details
/// Uses statistics from the graph ROI when one exists, or from the complete wave otherwise, and saves the result beside the source with a `_zscr` suffix.
/// @param wRef Input image wave.
/// @param grfName (optional) Graph containing the ROI; defaults to the active graph.
/// @returns Zero after completing the operation.
static Function ComputeImageZScore(Wave wRef, [string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	SetDrawLayer/W=$grfName ProgFront
	ImageGenerateROIMask/E=1/I=0/W=$grfName $NameOfWave(wRef)
	if(V_flag) 
		WAVE M_ROIMask
		ImageStats/R=M_ROIMask wRef
		KillWaves M_ROIMask
	else // 0 no M_ROIMask
		ImageStats wRef
	endif
	SetDrawLayer/W=$grfName UserFront
	DFREF dfr = GetWavesDataFolderDFR(wRef)
	string basename = NameOfWave(wRef) + "_zscr"
	string w_zcsr = CreateDataObjectName(dfr, basename, 1, 0 , 1)
	Duplicate wRef, dfr:$w_zcsr
	WAVE wz = dfr:$w_zcsr
	wz = (wRef - V_avg)/V_sdev
	string noteStr = "Z-score of " + GetWavesDataFolder(wRef, 2) + "\nV_avg = " + num2str(V_avg)
	noteStr += " , V_sdev = "+ num2str(V_sdev)
	Note/K wz, noteStr
	return 0
End

// generic function, implement it properly
//static Function ApplyCommand3D(WAVE wRef, string cmdStr, [variable overwrite, string endStr])
//
//	overwrite = ParamIsDefault(overwrite) ? 1 : overwrite // default overwite (used in drift correction)
//	if(WaveDims(wRef) != 3)
//		return -1
//	endif
//	variable nlayers = DimSize(wRef, 2), i
//	DFREF currDF = GetDataFolderDFR()
//	string folderNameStr = CreateDataObjectName(currDF, "ApplyCommand3D_buffer_folder_", 11, 0, 1)
//	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(":"+folderNameStr, setDF=1)
//	string buffer = "getStacklayer_", waveNameStr
//	for(i = 0; i < nlayers; i++)
//		waveNameStr = buffer + num2str(i)
//		MatrixOP $waveNameStr = layer(wRef, i)
//		Execute/P/Q cmdStr +GetWavesDataFolder($waveNameStr, 2)
//	endfor
//	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
//	WAVE M_Stack
//	DFREF saveDF = GetWavesDataFolderDFR(wRef)
//	// Restore scale here
//	CopyScales wRef, M_Stack
//	Note M_Stack, note(wRef) // Get the note of the wave, see ATH_String#WaveLogging below
//	string noteStr = "ApplyCommand3D: " + cmdStr
//	if(overwrite)
//		Duplicate/O M_Stack, saveDF:$NameofWave(wRef)
//		ATH_String#WaveLogging(saveDF:$NameofWave(wRef), noteStr, prepend=1)
//	else
//		string newWaveNameStr = CreateDataObjectName(saveDF, NameofWave(wRef) + endStr, 1, 0, 1)
//		Duplicate/O M_Stack, saveDF:$newWaveNameStr
//		ATH_String#WaveLogging(saveDF:$newWaveNameStr, noteStr,prepend=1)
//	endif
//	SetDataFolder currDF
//	//KillDataFolder/Z dfr
//	return 0
//End

/// We will make the function MT as it can be slow
/// @function MultiThreadLoess3D
/// @brief Apply LOESS smoothing to every image-stack layer using Igor's worker threads.
/// @details
/// Collects the free waves returned by `Loess3D_Worker`, concatenates them into a 3D result, and preserves the source note.
/// @param wRef Input 3D image stack.
/// @param npts LOESS neighborhood size.
/// @param order Polynomial order used by LOESS.
/// @param passes Number of robust-fitting passes.
/// @param extrapolate Extrapolation mode passed to Igor's `Loess` operation.
/// @param robust Robust-fitting mode passed to Igor's `Loess` operation.
/// @param overwrite (optional) If nonzero, replace the input stack; otherwise create a wave with a `_loess` suffix.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S MultiThreadLoess3D(WAVE wRef, variable npts,variable order, variable passes,
				 variable extrapolate, variable robust, [variable overwrite])

	if(!(WaveType(wRef) & 0x02 || WaveType(wRef) & 0x04))
		Redimension/S wRef
	endif
	
	// Create a wave to hold wave references returned by DriftCorrelation_Worker.
	variable numPlanes = DimSize(wRef,2)
	Make/WAVE/N=(numPlanes) ww	
	// Release the threads.
	MultiThreadingControl setMode=0	
	MultiThread ww = Loess3D_Worker(wRef, npts, order, passes, extrapolate, robust, p)
	MultiThreadingControl setMode=1	
	// At this point, ww holds wave references to numplanes free waves
	// created by DriftCorrelation_Worker.
	// So, now repack all layers.
	string wRefNote = note(wRef), returnWave
	if(overwrite)
		returnWave = GetWavesDataFolder(wRef,2)
		Concatenate/O {ww}, $returnWave
		Note $returnWave, wRefNote
	else
		string waveNameStr = CreateDataObjectName(currDF, NameOfWave(wRef)+"_loess", 1, 0, 1)
		returnWave = GetWavesDataFolder($waveNameStr,2)
		Concatenate {ww}, $returnWave
		Note $returnWave, wRefNote
	endif
	// ww holds references to the free waves. By killing ww, we kill
	// the last reference to the free waves which causes them to be
	// automatically deleted.	
	KillWaves ww
	return returnWave
End

/// @function Loess3D_Worker
/// @brief Apply LOESS smoothing to one image-stack layer.
/// @param wRef Input wave.
/// @param npts Number of output points or LOESS neighborhood size, as applicable.
/// @param order Polynomial order used by LOESS.
/// @param passes Number of robust-fitting passes.
/// @param extrapolate Extrapolation mode passed to Igor's `Loess` operation.
/// @param robust Robust-fitting mode passed to Igor's `Loess` operation.
/// @param plane Zero-based image-stack plane index.
/// @returns Reference to the result wave; a null wave reference indicates failure where supported.
ThreadSafe static Function/WAVE Loess3D_Worker(WAVE wRef, variable npts,variable order, variable passes,
				 variable extrapolate, variable robust, variable plane)
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	ImageTransform/P=(plane) getPlane wRef
	Wave M_ImagePlane
	Loess/NORM=0/N=(npts)/R=(robust)/E=(extrapolate)/PASS=(passes)/ORD=(order) srcWave=M_ImagePlane
	// Restore the current data folder
	SetDataFolder dfSav
	return M_ImagePlane		// Return a reference to the free M_RegOut wave
End
