#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_WaveOp
#pragma version = 1.01

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

/// @module ATH_WaveOp
/// @brief Module ATH_WaveOp.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH WaveOp functionality.


/// @function Make3DWaveUsingPattern
/// @brief Create a 3D wave by stacking waves whose names match a pattern.
/// @details
/// Make a 3d wave named wname3d using the RegEx pattern. Give "*" to match all waves.
/// @param wname3dStr Wname3d str.
/// @param pattern Pattern used to select names or files.
/// @returns Zero after completing the operation.
static Function Make3DWaveUsingPattern(string wname3dStr, string pattern)
	// Make a 3d wave named wname3d using the RegEx pattern
	// Give "*" to match all waves

	string ListofMatchedWaves = WaveList(pattern, ";", "")
	variable nrwaves = ItemsInList(ListofMatchedWaves)
	if(!nrwaves)
		Abort "No matching 2D waves"
	endif
	
	if(!strlen(wname3dStr))
		wname3dStr = "ATH_Stack"
	endif
	// if name in use by a global wave/variable 
	DFREF currDF = GetDataFolderDFR()
	wname3dStr = CreatedataObjectName(currDFR, "ATH_stack", 1, 0, 0)

	variable i
	
	Make/FREE/WAVE/N=(nrwaves) ATH_FREEwaveListWaveRef
	 
	for(i = 0; i < nrwaves; i++)
		ATH_FREEwaveListWaveRef[i] = $(StringFromList(i,ListofMatchedWaves))
	endfor
	
	Concatenate/NP=2 {ATH_FREEwaveListWaveRef}, $wname3dStr
		
	return 0
End

/// @function ConcatenateWavesInDataBrowserSelection
/// @brief Concatenate waves in Data Browser selection.
/// @details
/// Concatenate wave from data folder selection. Use it to stack 2D, 3D waves. Returns a string with the name
/// of the created wave, as wname3dStr.
/// @param wname3dStr Wname3d str.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S ConcatenateWavesInDataBrowserSelection(string wname3dStr)
	// Concatenate wave from data folder selection
	// For 2D, 3D waves:
	// Use it to stack 2D, 3D waves
	// Returns a string with the name of the created wave, as wname3dStr
	// might be already taken
	//
	// For 1D waves:
	// Use it to concatenate over columns

	// Comment out to sort as seen in DB, not alphanumeically because
	// it fails with decimals
	// listOfSelectedWaves = SortList(listOfSelectedWaves,";", 16)
	
	string listOfSelectedWaves = ATH_String#GetSelectedImagesinDB()
	
	variable nrwaves = ItemsInList(listOfSelectedWaves)
	if (nrwaves < 2)
		return "" // No wave or one wave is selected
	endif
	
	string wname = StringFromList(0, listOfSelectedWaves)

	WAVE wref = $wname
	
	// List of all waves
	WAVE/WAVE waveListFree = ATH_WaveOp#WaveListStrToWaveRef(listOfSelectedWaves, isFree = 1)	
	// Checks if all waves are in the same folder

	// Here get the path where the wave will be created
	string folder = GetDataFolder(1)
	
	wname3dStr = CreatedataObjectName(GetDataFolderDFR(), wname3dStr, 1, 0, 0)
	
	// Works for 1D waves because AllImagesEqualDimensionsQ
	// returns true for 1D waves even when the DimSize is not
	// equal. AllImagesEqualDimensionsQ calls Wave2DDimensionsEqualQ
	// which returns 0 for 1D. Here ATH_WaveOp#AllImagesEqualDimensionsQ
	// will always return 1 (true) for 1D waves.
	if(ATH_WaveOp#AllImagesEqualDimensionsQ(waveListFree))
		Concatenate/NP=2 {waveListFree}, $wname3dStr
	else
		print "Dimension mismatch. Aborting stacking ..."
		return ""
	endif
	
	// if you use /P, the dimension scaling is copied in slope/intercept format 
	// so that if srcWaveName  and the other waves have differing dimension size 
	// (number of points if the wave is a 1D wave), then their dimension values 
	// will still match for the points they have in common
	// CopyScales t2dwred, w3dref 

	// Add a note about the stacked waves
	
	string expandedWaveList = ATH_String#ComposeWaveListsFromWaveNotes(listOfSelectedWaves)
	if(strlen(expandedWaveList) && !AllWaves2DQ(waveListFree)) // ATH_String#ComposeWaveListsFromWaveNotes return "" if it cannot resolve all the wave names (incl. 3D)
		// This slows down the whole process
		ATH_String#UpdateStackWaveNote($wname3dStr, -1, explicitWaveList = ReplaceString(";", expandedWaveList, "\n"))	// use the default option
	else
		ATH_String#SetStackNamesInNote($wname3dStr, listOfSelectedWaves)	// use the default option
	endif

	return (folder + wname3dStr)
End

/// @function WaveListStrToWaveRef
/// @brief Convert a wave-name list into a wave-reference wave.
/// @details
/// Gets a wavelist and retuns a Wave reference Wave. Wave is free is isFree is set.
/// @param wavelistStr Wave used by the operation.
/// @param isFree (optional) If nonzero, create a free wave rather than a data-folder wave.
/// @returns Reference to the result wave; a null reference indicates failure where supported.
static Function/WAVE WaveListStrToWaveRef(string wavelistStr, [int isFree])
	// Gets a wavelist and retuns a Wave reference Wave.
	// Wave is free is isFree is set
	
	variable nrwaves = ItemsInList(wavelistStr), i
	if(!nrwaves)
		return $""
	endif
	
	if(ParamIsDefault(isFree)) // if you do not set then it is not free
		Make/WAVE/N=(nrwaves) wRefw
	else
		Make/FREE/WAVE/N=(nrwaves) wRefw
	endif
	
	for(i = 0; i < nrwaves; i++)
		wRefw[i] = $(StringFromList(i, wavelistStr))
	endfor
	return wRefw
End

/// @function UnpackLayersToSources
/// @brief Unpack layers to sources.
/// @details
/// Unpack layers to destination waves as grabbed from wave note.
/// @param wRef Input wave.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function UnpackLayersToSources(WAVE wRef)
	// Unpack layers to destination waves
	// as grabbed from wave note.
	string wavelistStr = ATH_string#GetStackNamesFromNote(wRef)
	waveListStr = ATH_String#RemoveIndexKeysFromList(waveListStr, keySep=">", listSep="\n")
	string wavePaths = ReplaceString("\n", waveListStr, ";") // Wavepaths in list
	WAVE/WAVE wlist = ATH_WaveOp#WaveListStrToWaveRef(wavePaths, isFree = 1)
	variable nlayers = DimSize(wRef,2)
	if(DimSize(wlist,0) != nlayers) // it will work only for 2d waves
		return -1
	endif
	string wnoteStr
	variable i = 0
	for(i=0; i < nlayers; i++)
		MatrixOP/FREE getLayer = layer(wRef, i)
		WAVE w = wlist[i]
		wnoteStr = note(wlist[i])
		CopyScales w, getLayer
		Note getLayer, "Unpacked layer "+num2str(i)+" from "+GetWavesDataFolder(wRef,2)+"\n"+wnoteStr
		// Debug
		// print "Uncpacking layer = "+num2str(i), "of ",GetWavesDataFolder(wRef,2) , " to ", GetWavesDataFolder(w,2)
		Duplicate/O getLayer, w
	endfor
End

/// @function MakeSquare3DWave
/// @brief Create square 3D wave.
/// @details
/// Creates a 3d waves with the same rows, cols by interpolation of w3d. The wave scaling using the interval
/// /I.
/// @param w3d Input 3D wave or image stack.
/// @param size (optional) Size.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function MakeSquare3DWave(WAVE w3d, [variable size])
	/// Creates a 3d waves with the same rows, cols by interpolation of w3d.
	/// The wave scaling using the interval /I.
	if(WaveDims(w3d) != 3)
		return -1
	endif
	size = ParamIsDefault(size) ? max(DimSize(w3d, 0), DimSize(w3d, 1)) : size
	string wavenameStr = NameOfWave(w3d) + "_ip3d"
	Make/N=(size, size, DimSize(w3d, 2))/O $wavenameStr /WAVE=wRef
	CopyScales/I w3d, wRef
	wRef = interp3D(w3d, x, y, z)
	return 0
End

/// @function AverageImageStack
/// @brief Average image stack.
/// @details
/// Average a 3d wave along z.
/// @param wRef Input wave.
/// @param outWaveStr (optional) Wave used by the operation.
/// @returns Reference to the result wave; a null reference indicates failure where supported.
static Function/WAVE AverageImageStack(WAVE wRef, [string outWaveStr])
	/// Average a 3d wave along z.
	/// @param w3d WAVE Wave name to average (3d wave)
	/// @param avgWaveNameStr string optional: Name of the output wave, default NameOfWave(wRef) + "_avg".
	/// if outWaveStr is given and the wave exists it will be overwritten
	DFREF dfr = GetDataFolderDFR()
	string basenameStr = NameOfWave(wRef) + "_avg"	
	outWaveStr = SelectString(ParamIsDefault(outWaveStr) ? 0: 1, CreatedataObjectName(dfr, basenameStr, 1, 0, 1), outWaveStr)
	variable nlayers = DimSize(wRef, 2)
	MatrixOP/O $outWaveStr = sumBeams(wRef)/nlayers
	string waveNoteStr = note(wRef)
	waveNoteStr += GetWavesDataFolder(wRef, 2) + " layer average (" +num2str(nlayers) + ")"
	CopyScales wRef, $outWaveStr 
	Note/K $outWaveStr waveNoteStr
	return $outWaveStr
End

/// @function WavePartition
/// @brief Partition a wave into regularly sized subwaves.
/// @details
/// Each output wave contains points `aX` through `zX`; successive partitions advance by `partitionIncrement`
/// points.
/// @param wRef Source wave to partition.
/// @param partitionNameStr Base name for generated partition waves.
/// @param aX First source index in the x dimension.
/// @param zX Last source index in the x dimension.
/// @param aY First source index in the y dimension.
/// @param zY Last source index in the y dimension.
/// @param evenNum (optional) If nonzero, force an even number of partitions.
/// @param square (optional) If nonzero, use equal x and y partition extents.
/// @param WaveFREE (optional) Optional destination wave used for each partition.
/// @returns Reference to the result wave; a null wave reference indicates failure where supported.
static Function/WAVE WavePartition(WAVE wRef, string partitionNameStr, variable aX, variable zX,
	variable aY, variable zY, [int evenNum, int square, int WaveFREE])
	///
	/// N.B Assume that startX, endX, startY and endY are scaled coordinates, not points (we usually work with scaled images)
	///
	/// Partition a 3D to get an orthorhombic 3d wave
	/// @param startP int
	/// @param endP int
	/// @param startQ int
	/// @param endQ
	/// @param evenNum int optional set rows, cols to the closest even number
	/// @param square int optional When set the number of rows and columns of the partition equals min(rows, cols) and even!
	/// @param free int optional - generate and return a free wave

	evenNum = ParamIsDefault(evenNum) ? 0: evenNum
	square = ParamIsDefault(square) ? 0: square
	WaveFREE = ParamIsDefault(WaveFREE) ? 0 : WaveFREE

	variable nRows, nCols, nLayers, minSide

	//N.B. Square is always even!!!
	if(square)
		evenNum = 0
	endif

	if(WaveFREE)
		Duplicate/FREE/RMD=(aX, zX)(aY, zY) wRef, wFreeRef
		nRows = DimSize(wFreeRef,0)
		nCols = DimSize(wFreeRef,1)
		nlayers = DimSize(wFreeRef,2)
		if(square)
			minSide = min(nRows, nCols)
			if(mod(minSide,2))
				minSide -= 1
			endif
			if(nlayers)
				Redimension/N=(minSide, minSide, nlayers) wFreeRef
			else
				Redimension/N=(minSide, minSide) wFreeRef
			endif
		endif
		if(evenNum)
			if(mod(nRows,2))
				nRows -= 1
			endif
			if(mod(nCols,2))
				nCols -= 1
			endif
			if(nlayers)
				Redimension/N=(nRows, nCols, nlayers) wFreeRef
			else
				Redimension/N=(nRows, nCols) wFreeRef
			endif
		endif
		return wFreeRef
	else
		Duplicate/RMD=(aX, zX)(aY, zY) wRef, $partitionNameStr
		WAVE partWRef = $partitionNameStr
		nRows = DimSize(partWRef,0)
		nCols = DimSize(partWRef,1)
		nlayers = DimSize(partWRef,2)		
		if(square)
			minSide = min(nRows, nCols)
			if(mod(minSide,2))
				minSide -= 1
			endif
			if(nlayers)
				Redimension/N=(minSide, minSide, nlayers) partWRef
			else
				Redimension/N=(minSide, minSide) partWRef
			endif
		endif
		if(evenNum)
			if(mod(nRows,2))
				nRows -= 1
			endif
			if(mod(nCols,2))
				nCols -= 1
			endif
			if(nlayers)
				Redimension/N=(nRows, nCols, nlayers) partWRef
			else
				Redimension/N=(nRows, nCols) partWRef
			endif
		endif
		variable lastX = ATH_WaveOp#LastDimVal(partWRef,0)
		variable lastY = ATH_WaveOp#LastDimVal(partWRef,1)
		Note partWRef, ("Redimension/RMD=("+num2str(DimOffSet(partWRef,0))+","+num2str(lastX)+")"+"("+num2str(DimOffSet(partWRef,1))\
		+","+num2str(lastY)+") "+GetWavesDataFolder(wRef, 2)+" .EvenNum="+num2str(evenNum)+",Square="+num2str(square)+".\n")
		return partWRef
	endif
End

/// @function ZapNaNAndInfWithValue
/// @brief Replace NaN and infinite wave values with a specified value.
/// @param waveRef Wave used by the operation.
/// @param val Scalar value to assign or compare.
/// @returns Zero after completing the operation.
static Function ZapNaNAndInfWithValue(WAVE waveRef, variable val)
	//numtype = 1, 2 for NaN, Inf
	waveRef= (numtype(waveRef)) ? val : waveRef
End

/// @function NormaliseWaveWithWave
/// @brief Normalize wave with wave.
/// @details
/// Normalise a wave with another consistency check static Function NormaliseWaveToUnitRange(WAVE waveRef).
/// @param wRef1 First wave to modify in place.
/// @param wRef2 Second input wave.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function NormaliseWaveWithWave(WAVE wRef1, WAVE wRef2)
	/// Normalise a wave with another
	// consistency check
	if(DimSize(wRef1, 0) != DimSize(wRef2, 0))
		printf "numpoints(%s) != numpoints(%s) \n", NameOfWave(wRef1), NameOfWave(wRef2)
		return -1
	endif
	wRef1 /= wRef2
	return 0
End

//static Function NormaliseWaveToUnitRange(WAVE waveRef)
//	/// Normalise wave in unit range [0, 1]
//	/// Works with waves of any dimensionality.
//	MatrixOP/O/FREE minvalsFreeW = minval(waveRef)
//	MatrixOP/O/FREE maxvalsFreeW = maxval(waveRef)
//	Duplicate/O/FREE waveRef, waveRefFREE
//	
//	string normWaveNameStr = NameOfWave(waveRef) + "_n1"
//	variable numvals = numpnts(minvalsFreeW), i, layerMin
//	
//	for(i = 0; i < numvals; i++)
//		layerMin = minvalsFreeW[i]
//		waveRefFREE[][][i] -= layerMin
//	endfor
//	
//	MatrixOP/O $normWaveNameStr = waveRefFREE/maxvalsFreeW
//	CopyScales waveRef, $normWaveNameStr
//End

/// @function GetScalesP
/// @brief Return wave dimension offsets and point intervals.
/// @details
/// Returns the offset and point interval for the first three dimensions of the input wave.
/// @param wRef Input wave.
/// @returns The x, y, and z dimension offsets followed by their point intervals.
static Function [variable x0, variable y0, variable z0, variable dx, variable dy, variable dz] GetScalesP(WAVE wRef)
	// Get the scales of waves per point. 
	x0 = DimOffset(wRef, 0)
	y0 = DimOffset(wRef, 1)
	z0 = DimOffset(wRef, 2)
	dx = DimDelta(wRef, 0)
	dy = DimDelta(wRef, 1)
	dz = DimDelta(wRef, 2)
	return [x0, y0, z0, dx, dy, dz]
End

/// @function SetScalesP
/// @brief Set dimension offsets and intervals for a wave.
/// @details
/// Set scale of waves per point variable x0, y0, z0, dx, dy, dz [x0, y0, z0, dx, dy, dz] =
/// ATH_GetScalesP(wRef).
/// @param wRef Wave to modify in place.
/// @param x0 First x coordinate or range bound.
/// @param y0 First y coordinate or range bound.
/// @param z0 First layer coordinate or range bound.
/// @param dx Sampling interval along x.
/// @param dy Sampling interval along y.
/// @param dz Sampling interval along z.
/// @returns Zero after completing the operation.
static Function SetScalesP(WAVE wRef, variable x0, variable y0, variable z0, variable dx, variable dy, variable dz)
	// Set scale of waves per point
	// Usage:
	// 		variable x0, y0, z0, dx, dy, dz
	// 		[x0, y0, z0, dx, dy, dz] = ATH_GetScalesP(wRef)
	// 		ATH_SetScalesP(wRef, x0, y0, z0, dx, dy, dz)
	
	SetScale/P x, x0, dx, wRef
	SetScale/P y, y0, dy, wRef
	SetScale/P z, z0, dz, wRef
End

/// @function MakeWaveFromROI
/// @brief Create wave from ROI.
/// @details
/// Extracts the ROI from wRef using the saved ROI coordinates in the database. Works with 2D and 3D waves.
/// @param wRef Input wave.
/// @returns Zero after completing the operation.
static Function MakeWaveFromROI(WAVE wRef)
	// Extracts the ROI from wRef using the saved ROI coordinates in the database
	// Works with 2D and 3D waves
	DFREF dfrROI = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:SavedROI")
	NVAR/Z/SDFR=dfrROI gATH_Sleft
	if(!NVAR_Exists(gATH_Sleft))
		Abort "No Saved ROI found. Use the Marquee to set the ROI first."
	endif
	NVAR/SDFR=dfrROI gATH_Sleft
	NVAR/SDFR=dfrROI gATH_Sright
	NVAR/SDFR=dfrROI gATH_Stop
	NVAR/SDFR=dfrROI gATH_Sbottom
	string basewavenameStr = NameOfWave(wRef) + "_roi"
	variable p0, p1, q0, q1
	p0 = scaleToIndex(wRef, gATH_Sleft, 0)
	p1 = scaleToIndex(wRef, gATH_Sright, 0)
	q0 = scaleToIndex(wRef, gATH_Stop, 1)
	q1 = scaleToIndex(wRef, gATH_SBottom, 1)
	DFREF currDF = GetDataFolderDFR()
	string wnameStr = CreatedataObjectName(currDFR, basewavenameStr, 1, 0, 0)	
	Duplicate/RMD=[p0, p1][q0, q1] wRef, $wnameStr
	ATH_WaveOp#SetWaveOffsetZero(wRef, dim = 0)
	ATH_WaveOp#SetWaveOffsetZero(wRef, dim = 1)	
	string noteStr
	string waveNameStr = GetWavesDataFolder(wRef, 2)
	sprintf noteStr, "Image: %s, ROI:[%.4f, %.4f][%.4f, %.4f]", waveNameStr, gATH_Sleft, gATH_SRight, gATH_Stop, gATH_SBottom
	Note $wnameStr, noteStr
	return 0
End

/// @function SetWaveOffsetZero
/// @brief Set wave offset zero.
/// @details
/// Zero the offset for dimension dim.
/// @param wRef Input wave.
/// @param dim (optional) Zero-based wave-dimension index.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function SetWaveOffsetZero(WAVE wRef, [int dim])
	// Zero the offset for dimension dim
	dim = ParamIsDefault(dim) ? 0: dim
	variable dx = DimDelta(wRef, dim)
	string dimStr = "x;y;z;t"
	if(dim < 0 || dim > 3)
		return -1
	endif
	string selDim = StringFromList(dim, dimStr)
	string waveNameStr = GetWavesDataFolder(wRef, 2)
	string cmd = "SetScale/P " + selDim + " 0, " + num2str(dx) + ", " + waveNameStr
	Execute/Q cmd
	return 0
End



/// @function AllWaves2DQ
/// @brief Test whether all waves 2D.
/// @details
/// Check whether all images have the same rows, cols.
/// @param wRefw Reference wave supplying values or scaling.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function AllWaves2DQ(WAVE/WAVE wRefw)
	// Check whether all images have the same rows, cols
	for(WAVE w: wRefW)
		if(DimSize(w,2))
			return 0
		endif
	endfor
	return 1
End


/// @function AllImagesEqualDimensionsQ
/// @brief Test whether all images equal dimensions.
/// @details
/// Check whether all images have the same rows, cols.
/// @param wRefw Reference wave supplying values or scaling.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function AllImagesEqualDimensionsQ(WAVE/WAVE wRefw)
	// Check whether all images have the same rows, cols
	variable nwaves = DimSize(wRefw, 0), i
	if(nwaves < 2)
		return -1
	endif
	WAVE w1 = wRefw[0]
	for(i = 1; i < nwaves; i++)
		WAVE w2 = wRefw[i]
		if(!ATH_WaveOp#ImagesDimensionsEqualQ(w1, w2))
			return 0
		endif
	endfor
	return 1
End

/// @function WaveDimensionsEqualQ
/// @brief Test whether wave dimensions equal.
/// @details
/// Return 1 if waves have the same num of elements in all dims. Works for any wave.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function ImagesDimensionsEqualQ(WAVE w1, WAVE w2)
	// Return 1 if waves have the same num of elements in all dims
	// Works for any wave
	return ((DimSize(w1, 0) == DimSize(w2, 0)) && (DimSize(w1, 1) == DimSize(w2, 1)) ? 1 : 0)
End

/// @function WaveDimensionsEqualQ
/// @brief Test whether wave dimensions equal.
/// @details
/// Return 1 if waves have the same num of elements in all dims. Works for any wave.
/// @param w1 First input wave.
/// @param w2 Second input wave.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function WaveDimensionsEqualQ(WAVE w1, WAVE w2)
	// Return 1 if waves have the same num of elements in all dims
	// Works for any wave
	return ((DimSize(w1, 0) == DimSize(w2, 0)) && (DimSize(w1, 1) == DimSize(w2, 1)\
	&& DimSize(w1, 2) == DimSize(w2, 2)) && (DimSize(w1, 3) == DimSize(w2, 3)) ? 1 : 0)
End

/// @function WaveDimensionsEqualQ
/// @brief Test whether wave dimensions equal.
/// @details
/// Return 1 if waves have the same num of elements in all dims. Works for any wave.
/// @param w1 First input wave.
/// @param w2 Second input wave.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function AllWavesEqualDimensionsQ(WAVE/WAVE wRefw)
	// Return 1 if waves have the same num of elements in all dims
	// Works for any wave
	variable nwaves = DimSize(wRefw, 0), i
	WAVE w1 = wRefw[0]
	for(i = 1; i < nwaves; i++)
		WAVE w2 = wRefw[i]
		if(!WaveDimensionsEqualQ(w1, w2))
			return 0
		endif
	endfor
	return 1
End

/// @function MatchWaveTypes
/// @brief Match wave types.
/// @details
/// Change WaveType of wDest to the one of wRef.
/// @param wRef Input wave.
/// @param wDest Destination wave to populate.
/// @returns Zero after completing the operation.
static Function MatchWaveTypes(WAVE wRef, WAVE wDest)
	// Change WaveType of wDest to the one of wRef
	variable wTypeRef = WaveType(wRef)
	switch(wTypeRef)
		case 2: // 32-bit float
			Redimension/S wDest
			break
		case 4: // 64-bit float
			Redimension/D wDest
			break
		case 8: // 8-bit integer
			Redimension/B wDest
			break
		case 16: // 16-bit integer
			Redimension/W wDest
			break
		case 32: // 32-bit integer
			Redimension/I wDest
			break
		case 72: // 8-bit unsigned integer
			Redimension/B/U wDest
			break
		case 80: // 16-bit unsigned integer
			Redimension/W/U wDest
			break
		case 96: // 32-bit unsigned integer
			Redimension/I/U wDest
			break
		case 128: // 64-bit integer
			Redimension/L wDest
			break
		case 196: // 64-bit unsigned integer
			Redimension/L/U wDest
			break
	endswitch
	return 0
End

/// @function WaveCasting
/// @brief Convert a numeric wave to a requested Igor wave type.
/// @details
/// Change to WaveType.
/// @param wRef Wave to modify in place.
/// @param wType Igor numeric wave-type code.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function WaveCasting(WAVE wRef, int wType)
	// Change to WaveType
	switch(wType)
		case 2: // 32-bit float
			Redimension/S wRef
			break
		case 4: // 64-bit float
			Redimension/D wRef
			break
		case 8: // 8-bit integer
			Redimension/B wRef
			break
		case 16: // 16-bit integer
			Redimension/W wRef
			break
		case 32: // 32-bit integer
			Redimension/I wRef
			break
		case 72: // 8-bit unsigned integer
			Redimension/B/U wRef
			break
		case 80: // 16-bit unsigned integer
			Redimension/W/U wRef
			break
		case 96: // 32-bit unsigned integer
			Redimension/I/U wRef
			break
		case 128: // 64-bit integer
			Redimension/L wRef
			break
		case 196: // 64-bit unsigned integer
			Redimension/L/U wRef
			break
		default:
			print "Invalid WaveType " + num2str(wType)
			return -1
			break
	endswitch
	return 0
End

/// @function LastDimVal
/// @brief Return the scaled coordinate of a dimension's final point.
/// @details
/// Return the last value of dimension dim.
/// @param w Input wave.
/// @param dim Zero-based wave-dimension index.
/// @returns The scaled coordinate of the final point along the selected dimension.
static Function LastDimVal(WAVE w, int dim)
	// Return the last value of dimension dim
	return DimOffSet(w, dim) + DimDelta(w, dim) * (DimSize(w, dim) - 1 ) 
End

/// @function SizeOfWave
/// @brief Size of wave.
/// @param wv Wave whose memory footprint is calculated.
/// @returns Size of wave.
static Function SizeOfWave(wv)
    wave/Z wv

    variable i, numEntries
    
    variable total = NumberByKey("SIZEINBYTES", WaveInfo(wv, 0))

    if(WaveType(wv, 1) == 4)
        WAVE/WAVE temp = wv
        numEntries = numpnts(wv)
        for(i = 0; i < numEntries; i += 1)
            WAVE/Z elem = temp[i]
            if(!WaveExists(elem))
                continue
            endif
            total += ATH_WaveOp#SizeOfWave(elem)
        endfor
    endif

    return total / 1024 / 1024
End

/// @function SumLateralWaveDims
/// @brief Sum lateral dimensions to reduce a 2D or 3D wave to a 1D profile.
/// @details
/// Sum cols (assumed energy axis) in 2D or sum rows and cols in 3D waves to make a 1D wave.
/// @param w Input wave.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
Function SumLateralWaveDims(WAVE w)
	// Sum cols (assumed energy axis) in 2D or
	// sum rows and cols in 3D waves to make a 1D  wave.
	string namew = Nameofwave(w) + "_DOS"
	if(WaveDims(w)==2)
		MatrixOp $namew = sumcols (w)
		WAVE WRef = $namew
		Redimension/N=(DimSize(wRef,1)) wRef
	elseif (WaveDims (w) ==3)
		Matrixop $namew = sumRows(sumCols(w))
		WAVE WRef = $namew
		Redimension/N=(Dimsize(wRef,2)) wRef
	else
		return -1
	endif
	Note WRef, GetwavesDataFolder(w, 2)
	return 0
End

/// @function GetWaveType
/// @brief Return the number of bytes per wave element.
/// @details
/// Return the number of bytes per element of wave wRef.
/// @param wRef Input wave.
/// @returns The wave type.
static Function GetWaveType(WAVE wRef)
	// Return the number of bytes per element of wave wRef
	variable wTypeRef = WaveType(wRef)
	switch(wTypeRef)
		case 2: // 32-bit float
			return 32
		case 4: // 64-bit float
			return 64
		case 8: // 8-bit integer
			return 8
		case 16: // 16-bit integer
			return 16
		case 32: // 32-bit integer
			return 32
		case 72: // 8-bit unsigned integer
			return 8
		case 80: // 16-bit unsigned integer
			return 16
		case 96: // 32-bit unsigned integer
			return 32
		case 128: // 64-bit integer
			return 64
		case 196: // 64-bit unsigned integer
			return 64
	endswitch
	return 0 // if nothing matches
End

/// @function RemoveLineFromWave1D
/// @brief Remove line from wave 1d.
/// @details
/// Remove a line from a 1D wave. Line is defined from points x0 and x1. Here scaling is taken into account.
/// The function is structured to give.
/// @param wRef Wave to modify in place.
/// @param x0 (optional) First x coordinate or range bound.
/// @param x1 (optional) Second x coordinate or range bound.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function RemoveLineFromWave1D(WAVE wRef, [variable x0, variable x1])
	
	//
	// Remove a line from a 1D wave. Line is defined from points x0 and x1.
	// Here scaling is taken into account. The function is structured to give
	// 
	
	if(WaveDims(wRef) > 1)
		return -1
	endif
	
	variable firstX = leftx(wRef)
	variable lastX = pnt2x(wRef,numpnts(wRef)-1)
	
	x0 = ParamIsDefault(x0) ? firstX : x0
	x1 = ParamIsDefault(x1) ? lastX : x1
	
	if(x0 >= x1 || x0 < firstX || x1 > lastX) // = catches also slope = inf
		return -1
	endif

	variable slope = (wRef(x1) - wRef(x0))/(x1 - x0)
	variable shift = wRef(x0) - slope * x0
	Make/N=2/D/FREE coeffW = {shift, slope}
	Duplicate/FREE wRef, lineW // keep scale, needed for poly below
	lineW = poly(coeffW, x)
	wRef -= lineW
	return 0
End

/// @function RemoveZLineWave3D
/// @brief Remove z line wave 3D.
/// @details
/// Remove a line defined by z0, z1 for every wRef beam we use the wave scaling along z, but it's not needed.
/// Unscaled wave will give the same results.
/// @param wRef Wave to modify in place.
/// @param z0 (optional) First layer coordinate or range bound.
/// @param z1 (optional) Second layer coordinate or range bound.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function RemoveZLineWave3D(Wave wRef, [variable z0, variable z1])
	// Remove a line defined by z0, z1 for every wRef beam
	// we use the wave scaling along z, but it's not needed. 
	// Unscaled wave will give the same results.
	
	if(WaveDims(wRef) != 3)
		return -1
	endif
	
	variable firstZ = DimOffSet(wRef, 2)
	variable lastZ = DimOffSet(wRef, 2) +  (DimSize(wRef, 2) - 1) * DimDelta(wRef, 2)
	
	z0 = ParamIsDefault(z0) ? firstZ : Z0
	z1 = ParamIsDefault(z1) ? lastZ : z1
	
	if(z0 >= z1 || z0 < firstZ || z1 > lastZ) // = catches also slope = inf
		return -1
	endif
	
	variable imax = DimSize(wRef, 0), jmax = DimSize(wRef, 0), i, j, shift, slope
	MatrixOP/S/O/FREE beamFREE = beam(wRef, 0, 0) // Get a beam to scale it
	SetScale/I x, firstZ, lastZ, beamFREE
	
	for(i=0;i<imax;i++)
		for(j=0;j<jmax;j++)
			MatrixOP/S/O/FREE beamFREE = beam(wRef, i, j)
			ATH_WaveOP#RemoveLineFromWave1D(beamFREE, x0 = z0, x1 = z1)
			wRef[i][j][] = beamFREE[r]
		endfor
	endfor
End

/// @function GetWaveMinPos
/// @brief Return the scaled position of a wave's minimum value.
/// @details
/// Return the position of the maximun value of wave.
/// @param wRef Wave to modify in place.
/// @returns The wave min pos.
static Function GetWaveMinPos(WAVE wRef)
	// Return the position of the maximun value of wave
	variable items = numpnts(WRef), i, imim
	imim = wRef[0]
	for(i=1;i<items;i++)
		if(wRef[i] < imim)
			imim = wRef[i]
		endif
	endfor
	return imim
End

/// @function GetWaveMaxPos
/// @brief Return the scaled position of a wave's maximum value.
/// @details
/// Return the position of the maximun value of wave.
/// @param wRef Wave to modify in place.
/// @returns The wave max pos.
static Function GetWaveMaxPos(WAVE wRef)
	// Return the position of the maximun value of wave
	variable items = numpnts(WRef), i, imax
	imax = wRef[0]
	for(i=1;i<items;i++)
		if(wRef[i] > imax)
			imax = wRef[i]
		endif
	endfor
	return imax
End

/// @function AverageEvenOddLayers
/// @brief Average even odd layers.
/// @details
/// Not absolute even/odd referenence when offset!=0.
/// @param wRef Input wave.
/// @param offset (optional) Offset.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function AverageEvenOddLayers(WAVE wRef, [variable offset])
	// Not absolute even/odd referenence when offset!=0
	if(WaveDims(wRef) != 3)
		return 1
	endif
	
	SplitWave/FREE/OREF=ATH_wRefListFree wRef
	DFREF dfr = GetDataFolderDFR()
	string wNameOdd = CreateDataObjectName(dfr, NameOfWave(wRef)+"_odd", 1, 0, 1)	
	string wNameEven = CreateDataObjectName(dfr, NameOfWave(wRef)+"_even", 1, 0, 1)
	MatrixOP $wNameOdd = layer(wRef,0)
	Duplicate $wNameOdd, $wNameEven
	WAVE w0 = $wNameEven	
	WAVE w1 = $wNameOdd
	w0 = 0
	w1 = 0
	variable nlayers = DimSize(wRef, 2), i
	for(i = offset; i < nlayers- 1; i = i + 2)
		WAVE wE = ATH_wRefListFree[i]
		FastOP w0 += wE
		WAVE wO = ATH_wRefListFree[i+1]
		FastOP w1 += wO
	endfor
	CopyScales/I wRef, w0, w1
	KillWaves/Z ATH_wRefListFree
	return 0
End

/// @function AverageSplitStack
/// @brief Split an image stack into two halves and average each half.
/// @details
/// Creates sibling waves with suffixes `_half1` and `_half2`; an unmatched first layer is skipped for odd-sized stacks.
/// @param wRef Input 3D image stack.
/// @returns Zero on success; one if the input is not a multi-layer 3D wave.

static Function AverageSplitStack(WAVE wRef)
	// Not absolute even/odd referenence when offset!=0
	if(WaveDims(wRef) != 3 || DimSize(wRef,2) == 1)
		return 1
	endif
		
	DFREF dfr = GetDataFolderDFR()
	string wfNameStr = CreateDataObjectName(dfr, NameOfWave(wRef)+"_half1", 1, 0, 1)	
	string wlNameStr = CreateDataObjectName(dfr, NameOfWave(wRef)+"_half2", 1, 0, 1)
	variable nlayers = DimSize(wRef, 2)
	variable startLayer = mod(nlayers,2) ? 1 : 0
	variable nl = mod(nlayers,2) ? (nlayers-1)/2 : nlayers/2 
	
	Duplicate/FREE/RMD=[][][startLayer, startLayer+nl - 1] wRef, wFree
	MatrixOP $wfNameStr = sumbeams(wFree)/nl
	Duplicate/O/FREE/RMD=[][][startLayer+nl, nlayers - 1] wRef, wFree
	MatrixOP $wlNameStr = sumbeams(wFree)/nl	
	CopyScales/I wRef, $wfNameStr, $wlNameStr	
	return 0
End

/// @function AverageRandomStackSample
/// @brief Average a random subset of layers from an image stack.
/// @details
/// Selects layers without replacement, records their indices in the result note, and preserves the input scaling.
/// @param wRef Input 3D image stack.
/// @param sampleN Number of layers to sample; must not exceed 75 percent of the stack.
/// @returns Zero on success; one if the input has no layers or the requested sample is too large.

static Function AverageRandomStackSample(WAVE wRef, variable sampleN)

	variable nlayers = DimSize(wRef, 2)
	if(!nlayers || sampleN > 0.75*nlayers)
		return 1
	endif
		
	DFREF dfr = GetDataFolderDFR()
	string waveNameStr = CreateDataObjectName(dfr, NameOfWave(wRef)+"_rndSample", 1, 0, 1)
	variable cnt
	string listRangeStr = ATH_String#ExpandRangeStr("0-"+num2str(nlayers-1))
	string listStr = ATH_String#RandomSampleStringList(listRangeStr, sampleN)
	SetDataFolder NewFreeDataFolder()
	variable i, layerN
	string rList = ""
	for(i = 0 ; i < sampleN; i++)
		layerN = str2num(StringFromList(i,listStr))
		ImageTransform/P=(layerN) getPlane wRef
		WAVE M_ImagePlane
		Rename M_ImagePlane, $("Img2Stack_"+num2str(i))
	endfor
	ImageTransform/NP=(sampleN) stackImages $"Img2Stack_0"	
	WAVE M_Stack
	MatrixOP $waveNameStr = sumbeams(M_Stack)/sampleN
	WAVE wRndSample = $waveNameStr
	CopyScales wRef, wRndSample
	Note wRndSample, "Average of "+num2str(sampleN)+" randomly selected layers (" +listStr+ ") of wave " + GetWavesDataFolder(wRef, 2) + "\n"
	MoveWave wRndSample, dfr
	SetDataFolder dfr
	return 0
End
