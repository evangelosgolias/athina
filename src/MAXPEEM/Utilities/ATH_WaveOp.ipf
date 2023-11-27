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

// Utilities

/// Make waves ///
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

static Function/S Make3DWaveDataBrowserSelection(string wname3dStr, [variable makeInSourceDFR, variable autoPath])

	// Make a 3d wave using waves selected
	// in the browser window. No check for selection
	// type, so if you select a folder or variable you will get an error.
	// Returns a string with the name of the created wave, as wname3dStr
	// might be already taken
	// makeInSourceDFR: Created stack in the cwd or in the sourceDir?
	// autoPath: The program sets makeInSourceDFR. If all waves in the same
	// folder the makeInSourceDFR = 1, otherwise makeInSourceDFR = 0
	
	makeInSourceDFR = ParamIsDefault(makeInSourceDFR) ? 0: makeInSourceDFR
	autoPath = ParamIsDefault(autoPath) ? 0: autoPath
	string listOfSelectedWaves = ""
	
	// Test not needed here -- Called from ATH_LaunchMake3DWaveDataBrowserSelection()
	//
	// if name in use by a global wave/variable 
	//	if(!exists(wname3d) == 0) // 0 - Name not in use, or does not conflict with a wave, numeric variable or string variable in the specified data folder.
	//		print "ATH: Renamed your wave to \"" + (wname3d + "_rn") + "\" to avoid conflicts"
	//		wname3d += "_rn"
	//	endif
		
	variable i = 0
	do
		if(strlen(GetBrowserSelection(i)))
			listOfSelectedWaves += GetBrowserSelection(i) + ";" // Match stored at S_value
		endif
		i++
	while (strlen(GetBrowserSelection(i)))
	
	//Sort alphanumerically

	listOfSelectedWaves = SortList(listOfSelectedWaves,";", 16)
	
	variable nrwaves = ItemsInList(listOfSelectedWaves)
	if (nrwaves < 2)
		return "" // No wave or one wave is selected
	endif
	
	string wname = StringFromList(0, listOfSelectedWaves)

	WAVE wref = $wname
	
	variable nx = DimSize(wref,0)
	variable ny = DimSize(wref,1)
	// List of all waves
	WAVE/WAVE waveListFree = ATH_WaveOp#StringWaveListToWaveRef(listOfSelectedWaves, isFree = 1)	
	// Checks if all waves are in the same folder
	if(autoPath)
		makeInSourceDFR = ATH_WaveOp#AllWavesSamePathQ(waveListFree)
	endif
	if(makeInSourceDFR)
		DFREF saveDF = GetDataFolderDFR()
		SetDataFolder GetWavesDataFolderDFR(wref)
		DFREF currDFR = GetDataFolderDFR()
	else
		DFREF currDFR = GetDataFolderDFR()	
	endif
	// Here get the path wheret the wave will be created
	string folder = GetDataFolder(1)
	wname3dStr = CreatedataObjectName(currDFR, "ATH_stack", 1, 0, 0)
	
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
	//CopyScales t2dwred, w3dref 
	// Add a note about the stacked waves
	Note/K $wname3dStr, ReplaceString(";", listOfSelectedWaves, "\n")
	// Go back to the cwd
	if(makeInSourceDFR)
		SetDataFolder saveDF
	endif
	return (folder + wname3dStr)
End

static Function/WAVE StringWaveListToWaveRef(string wavelistStr, [int isFree])
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

static Function AllWavesSamePathQ(WAVE/WAVE wWAVEList)
	// Function checks whether all have are in the same data folder
	// 0 - no, 1 - yes.  
	variable nrwaves = DimSize(wWAVEList, 0), i
	if(nrwaves < 2)
		return -1
	endif
	DFREF dfr0 = GetWavesDataFolderDFR(wWAVEList[0]), dfr1
	for(i = 1; i < nrwaves; i++)
		dfr1 = GetWavesDataFolderDFR(wWAVEList[i])
		if(!DataFolderRefsEqual(dfr0 , dfr1))
			return 0
		endif
	endfor
	return 1
End
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

static Function AverageStackToImage(WAVE w3d, [string avgImageName])
	/// Average a 3d wave along z.
	/// @param w3d WAVE Wave name to average (3d wave)
	/// @param avgImageName string optional Name of the output wave, default ATH_AvgStack.
	avgImageName = SelectString(ParamIsDefault(avgImageName) ? 0: 1, "ATH_AvgStack", avgImageName)
	variable nlayers = DimSize(w3d, 2)
	ImageTransform sumplanes w3d // averageImage does not work for two layers!
	WAVE M_SumPlanes
	M_SumPlanes /= nlayers
	Duplicate/O M_SumPlanes, $avgImageName
	KillWaves/Z M_SumPlanes
	string nameofWaveStr = NameOfWave(w3d)
	string w3dNoteStr = nameofWaveStr + " average (" + num2str(nlayers) + ")\n"
	CopyScales w3d, $avgImageName 
	Note/K $avgImageName w3dNoteStr
	return 0
End

static Function WavePartition(WAVE wRef, string partitionNameStr, variable startX, variable endX, variable startY, variable endY, [variable evenNum, variable tetragonal])
	/// Partition a 3D to get an orthorhombic 3d wave
	/// @param startP int
	/// @param endP int
	/// @param startQ int
	/// @param endQ
	/// @param evenNum int optional set rows, cols to the closest even number
	/// @param tetragonal int optional When set the number of rows and columns of the partition equals max(rows, cols).

	evenNum = ParamIsDefault(evenNum) ? 0: evenNum
	tetragonal = ParamIsDefault(tetragonal) ? 0: tetragonal 

	variable nrows = DimSize(wRef, 0)
	variable ncols = DimSize(wRef, 1)
	variable rowsOff = DimOffset(wRef, 0)
	variable colsOff = DimOffset(wRef, 1)
	
	variable xmin = rowsOff
	variable ymin = colsOff
	variable xmax = rowsOff + (nrows - 1) * DimDelta(wRef, 0)
	variable ymax = colsOff + (ncols - 1) * DimDelta(wRef, 1)
	
	if(startX < xmin)
		startX = xmin
	endif
	
	if(endX > xmax)
		endX = xmax
	endif
	
	if(startY < ymin)
		startY = ymin
	endif
	
	if(endY > ymax)
		endY = ymax
	endif	
	
	if (!(startX < endX && startY < endY && startX >= xmin && startY >= ymin \
		&& endX <= xmax && endY <= ymax))
		Abort "Error: Out of bounds p, q values or X_min >= X_max."
	endif
	
	variable startP, endP, startQ, endQ
	// P, Q values might come from scaled images
	startP = ScaleToIndex(wRef, startX, 0)
	endP   = ScaleToIndex(wRef, endX, 0)
	startQ = ScaleToIndex(wRef, startY, 1)
	endQ   = ScaleToIndex(wRef, endY, 1)
	
	variable nWaveRows = endP-startP
	variable nWaveCols = endQ-startQ
	
	if(evenNum)
		if(mod(nWaveRows, 2))
			nWaveRows += 1
		endif
		if(mod(nWaveCols, 2))
			nWaveCols += 1
		endif
	endif

	if(tetragonal) // should follow evenNum, so no need to add extra conditions here
		nWaveRows = max(nWaveRows, nWaveCols)
		nWaveCols = nWaveRows
	endif
	MatrixOP $partitionNameStr = subrange(wRef, startP, startP + nWaveRows + 1, startQ, startQ + nWaveCols + 1) // Need to add 1 to have even number of rows/cols with MatrixOP subrange
	Note $partitionNameStr, ("Partition of " + GetWavesDataFolder(wRef, 2)+": ["+num2str(startX)+","+num2str(endX)+"]"+"["+num2str(startY)+","+num2str(endY)+"]")
	return 0
End

static Function/WAVE WAVEWavePartition(WAVE wRef, variable startX, variable endX, variable startY, variable endY, [variable evenNum, variable tetragonal])
	/// Partition a 3D to get an orthorhombic 3d wave
	/// @param startX int
	/// @param endX int
	/// @param startY int
	/// @param endY
	/// @param evenNum int optional set rows, cols to the closest even number
	/// @param tetragonal int optional When set the number of rows and columns of the partition equals max(rows, cols).
	evenNum = ParamIsDefault(evenNum) ? 0: evenNum
	tetragonal = ParamIsDefault(tetragonal) ? 0: tetragonal 

	variable nrows = DimSize(wRef, 0)
	variable ncols = DimSize(wRef, 1)
	variable rowsOff = DimOffset(wRef, 0)
	variable colsOff = DimOffset(wRef, 1)
	
	variable xmin = rowsOff
	variable ymin = colsOff
	variable xmax = rowsOff + (nrows - 1) * DimDelta(wRef, 0)
	variable ymax = colsOff + (ncols - 1) * DimDelta(wRef, 1)
	
	if(startX < xmin)
		startX = xmin
	endif
	
	if(endX > xmax)
		endX = xmax
	endif
	
	if(startY < ymin)
		startY = ymin
	endif
	
	if(endY > ymax)
		endY = ymax
	endif	
	
	if (!(startX < endX && startY < endY && startX >= xmin && startY >= ymin \
		&& endX <= xmax && endY <= ymax))
		Abort "Error: Out of bounds p, q values or X_min >= X_max."
	endif
	
	variable startP, endP, startQ, endQ
	// P, Q if image is scaled
	startP = ScaleToIndex(wRef, startX, 0)
	endP   = ScaleToIndex(wRef, endX, 0)
	startQ = ScaleToIndex(wRef, startY, 1)
	endQ   = ScaleToIndex(wRef, endY, 1)
	
	variable nWaveRows = endP-startP
	variable nWaveCols = endQ-startQ
	
	if(evenNum)
		if(mod(nWaveRows, 2))
			nWaveRows += 1			
		endif
		if(mod(nWaveCols, 2))
			nWaveCols += 1
		endif
	endif

	if(tetragonal) // should follow evenNum, so no need to add extra conditions here
		nWaveRows = max(nWaveRows, nWaveCols)
		nWaveCols = nWaveRows
	endif

	variable nlayers = DimSize(wRef, 2)
	MatrixOP/FREE wFreeRef = subrange(wRef, startP, startP + nWaveRows + 1, startQ, startQ + nWaveCols + 1) // Need to add 1 to have even number of rows/cols with MatrixOP subrange
	Note wFreeRef, ("Partition of " + GetWavesDataFolder(wRef, 2)+": ["+num2str(startX)+","+num2str(endX)+"]"+"["+num2str(startY)+","+num2str(endY)+"]")
	return wFreeRef
End

static Function ZapNaNAndInfWithValue(WAVE waveRef, variable val)
	//numtype = 1, 2 for NaN, Inf
	waveRef= (numtype(waveRef)) ? val : waveRef
End

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

static Function NormaliseWaveToUnitRange(WAVE waveRef)
	/// Normalise wave in unit range [0, 1]
	/// Works with waves of any dimensionality.
	MatrixOP/O/FREE minvalsFreeW = minval(waveRef)
	MatrixOP/O/FREE maxvalsFreeW = maxval(waveRef)
	Duplicate/O/FREE waveRef, waveRefFREE
	
	string normWaveNameStr = NameOfWave(waveRef) + "_n1"
	variable numvals = numpnts(minvalsFreeW), i, layerMin
	
	for(i = 0; i < numvals; i++)
		layerMin = minvalsFreeW[i]
		waveRefFREE[][][i] -= layerMin
	endfor
	
	MatrixOP/O $normWaveNameStr = waveRefFREE/maxvalsFreeW
	CopyScales waveRef, $normWaveNameStr
End

static Function [variable x0, variable y0, variable z0, variable dx, variable dy, variable dz] GetScalesP(WAVE wRef)
	// Get the scales of waves per point. 
	x0 = DimOffset(wRef, 0)
	y0 = DimOffset(wRef, 1)
	y0 = DimOffset(wRef, 2)
	dx = DimDelta(wRef, 0)
	dy = DimDelta(wRef, 1)
	dz = DimDelta(wRef, 2)
	return [x0, y0, z0, dx, dy, dz]
End

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

static Function ImageDimensionsEqualQ(WAVE w1, WAVE w2)
	// Return 1 if images have equal number of rows, cols and 0 otherwise.
	// Works for 2D and 3D waves.
	if(WaveDims(w1) > 1 && WaveDims(w1) < 4 && WaveDims(w2) > 1 && WaveDims(w2) < 4)
		return ((DimSize(w1, 0) == DimSize(w2, 0)) && (DimSize(w1, 1) == DimSize(w2, 1)) ? 1: 0)
	endif
End

static Function AllImagesEqualDimensionsQ(WAVE/WAVE wRefw)
	// Check whether all images have the same rows, cols
	variable nwaves = DimSize(wRefw, 0), i
	if(nwaves < 2)
		return -1
	endif
	WAVE w1 = wRefw[0]
	for(i = 1; i < nwaves; i++)
		WAVE w2 = wRefw[i]
		if(!ATH_WaveOp#ImageDimensionsEqualQ(w1, w2))
			return 0
		endif
	endfor
	return 1
End

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

static Function SetSameWaveTypes(WAVE wRef, WAVE wDest)
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

static Function SetWaveType(WAVE wRef, int wType)
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

static Function/S BackupWaveInWaveDF(WAVE wref)
	// Backup a wave in the same DF. If a wave with wavename_undo exists, nothing is done
	// If a backup wave is created a message is printed in the command window.
	// The function returns a string of backupWavePathStr
	string backupWavePathStr = GetWavesDataFolder(wref, 1) + PossiblyQuoteName(NameOfWave(wref) + "_undo")

	if(!WaveExists($backupWavePathStr))
		Duplicate wref, $backupWavePathStr
		print "Backup wave: ", backupWavePathStr
	endif
	return backupWavePathStr
End

static Function/S BackupWaveInWaveDFQ(WAVE wref)
	// Backup a wave in the same DF. If a wave with wavename_undo exists
	// the user is prompted to proceed and overwrite the destination wave or not.
	// If a backup wave is created a message is printed in the command window.
	// The function returns a string of backupWavePathStr
	string backupWavePathStr = GetWavesDataFolder(wref, 1) + PossiblyQuoteName(NameOfWave(wref) + "_undo")

	if(WaveExists($backupWavePathStr))
		DoAlert/T="Overwite backup wave?", 1, ("Do you want to overwite " + backupWavePathStr + "?")
		if(V_flag == 1)
			Duplicate/O wref, $backupWavePathStr
			print "Backup/O wave: ", backupWavePathStr
		endif
	else
		Duplicate wref, $backupWavePathStr
		print "Backup wave: ", backupWavePathStr
	endif
	return backupWavePathStr // return the backup wavename in either case.
End

static Function/S BackupWave3DLayerInWaveDF(WAVE wref, variable layerN)
	// Backup a layer from a 3d wave in the same DF as wavename_p2_undo if /P=2 is used
	// If a wave with wavename_pN_undo exists, nothing is done
	// If a backup wave is created a message is printed in the command window.
	// The function returns a string of backupWavePathStr
	string backupWavePathStr = GetWavesDataFolder(wref, 1) + PossiblyQuoteName(NameOfWave(wref)\
						       + "_p" + num2str(layerN) + "_undo")
	if(!WaveExists($backupWavePathStr))
		MatrixOP $backupWavePathStr = layer(wRef, layerN)
		print "Backup of layer ", num2str(layerN), " ", backupWavePathStr
	endif
	return backupWavePathStr
End

static Function/S BackupWave3DLayerInWaveDFQ(WAVE wref, variable layerN)
	// Backup a layer from a 3d wave in the same DF as wavename_p2_undo if /P=2 
	// is used. If a wave with wavename_pN_undo exists the user is prompted
	// to proceed and overwrite the destination wave or not.
	// If a backup wave is created a message is printed in the command window.
	// The function returns a string of backupWavePathStr
	string backupWavePathStr = GetWavesDataFolder(wref, 1) + PossiblyQuoteName(NameOfWave(wref)\
						       + "_p" + num2str(layerN) + "_undo")
	if(WaveExists($backupWavePathStr))
		DoAlert/T="Overwite backup wave?", 1, ("Do you want to overwite " + backupWavePathStr + "?")
		if(V_flag == 1)
			MatrixOP/O $backupWavePathStr = layer(wRef, layerN)
			print "Backup/O of layer ", num2str(layerN), " ", backupWavePathStr
		endif
	else
		MatrixOP $backupWavePathStr = layer(wRef, layerN)
		print "BackupRestore of layer ", num2str(layerN), " ", backupWavePathStr
	endif
	return backupWavePathStr // return the backup wavename in either case.
		
End

static Function RestoreWaveFromBackup(WAVE wRef)
	// Restore image from wRef_undo if it exists. wRef and WRef_undo 
	// should be in the same DF.
	string waveNameStr = NameOfWave(wref)
	string backupWavePathStr = GetWavesDataFolder(wref, 1) + PossiblyQuoteName(waveNameStr + "_undo")
	if(WaveExists($backupWavePathStr))
		Duplicate $backupWavePathStr, wRef
		print waveNameStr, " restored from backup"
	endif
	return 0
End

static Function RestoreWave3DLayerFromBackup(WAVE wref, variable layerN)
	// Restore image from wRef_pN_undo if it exists. wRef and wRef_pN_undo 
	// should be in the same DF.
	string waveNameStr = NameOfWave(wref)
	string backupWavePathStr = GetWavesDataFolder(wref, 1) + PossiblyQuoteName(wavenameStr\
						       + "_p" + num2str(layerN) + "_undo")
	if(WaveExists($backupWavePathStr))
		ImageTransform/P=(layerN)/D=$backupWavePathStr setplane wRef
		print "Backup of layer ", num2str(layerN), " ", backupWavePathStr
	endif
	return 0
End

static Function RightDimVal(WAVE w, int dim)
	// Return the last value of dimension dim
	return DimOffSet(w, dim) + DimDelta(w, dim) * (DimSize(w, dim) - 1 ) 
End

static Function NextPowerOfTwo(variable num)
	 /// Return the first power of two after num.
	 /// @param num double 
	variable bufferVar
	variable result = 1
	do
		result *= 2
	while (result < num)
	return result
End

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

static Function IsFloatQ(WAVE wRef)
	// Returns true of wRef is 32 or 64 bit float wave
	return ((WaveType(wRef) & 0x02) || (WaveType(wRef) & 0x04))
End

static Function IsFloat32Q(WAVE wRef)
	// Returns true of wRef is 32 bit float wave
	return WaveType(wRef) & 0x02 
End

static Function IsFloat64Q(WAVE wRef)
	// Returns true of wRef is 64 bit float wave
	return WaveType(wRef) & 0x04 
End

static Function TWaveRemoveEntriesFromPatters(WAVE/T textW, string patternStr, [WAVE otherW])
	// Remove entries from textW that start with pathbase
	// Optionally we can remove the same entries from another wave otherW
	// We use this in ATH_LaunchDeleteBigWaves
	variable otherWQ = ParamIsDefault(otherW) ? 0 : 1
	variable numpts = DimSize(textW, 0), i
	for(i = numpts - 1; i > 0; i--)
		if(Stringmatch(textW[i], patternStr))
			DeletePoints i, 1, textW
			if(otherWQ)
				DeletePoints i, 1, otherW
			endif
		endif
	endfor
	return 0
End

static Function DeleteWavesInTextWave(WAVE/T textW)
	// Delete big waves listed in textW
	variable nw = DimSize(textW, 0), i
	for(i = 0; i < nw; i++)			
		KillWaves/Z $textW[i]
	endfor
	return 0
End

// Dev -- need testing
static Function TWaveRemoveEntriesFromStringList(WAVE/T textW, string stringListStr, [WAVE otherW])
	// Remove entries from textW in stringListStr
	// Optionally we can remove the same entries from another wave otherW
	// We use this in ATH_LaunchDeleteBigWavesDisplayed
	
	variable otherWQ = ParamIsDefault(otherW) ? 0 : 1
	variable numpts = DimSize(textW, 0), i
	for(i = numpts - 1; i > 0; i--)
		if(1)
			DeletePoints i, 1, textW
			if(otherWQ)
				DeletePoints i, 1, otherW
			endif
		endif
	endfor
	return 0
End

//// Numerical helper functions 

static Function IntegerQ(variable num)
	/// Check in a number is integer
	if(num == trunc(num))
		return 1
	else
		return 0
	endif
End