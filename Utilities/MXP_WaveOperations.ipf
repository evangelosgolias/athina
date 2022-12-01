#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// Utilities

/// Make waves ///
Function MXP_Make3DWaveUsingPattern(string wname3d, string pattern)
	// Make a 3d wave named wname3d using the RegEx pattern
	// Give "*" to match all waves

	string ListofMatchedWaves = WaveList(pattern, ";", "")
	variable nrwaves = ItemsInList(ListofMatchedWaves)
	if(!nrwaves)
		Abort "No matching 2D waves"
	endif
	
	if(!strlen(wname3d))
		wname3d = "MXP_Stack"
	endif
	// if name in use by a global wave/variable 
	if(!exists(wname3d) == 0) // 0 - Name not in use, or does not conflict with a wave, numeric variable or string variable in the specified data folder.
		print "MXP: Renamed your wave to \"" + (wname3d + "_rn") + "\" to avoid conflicts"
		wname3d += "_rn"
	endif
	
	WAVE wref = $(StringFromList(0,ListofMatchedWaves))
	variable nx = DimSize(wref,0)
	variable ny = DimSize(wref,1)

	Make/N = (nx, ny, nrwaves) $wname3d /WAVE = w3dref
	variable ii

	for(ii = 0; ii < nrwaves; ii += 1)
		WAVE t2dwred = $(StringFromList(ii,ListofMatchedWaves))
		w3dref[][][ii] = t2dwred[p][q]
	endfor
	return 0
End

Function MXP_Make3DWaveDataBrowserSelection(string wname3d)

	// Like EGMake3DWave, but now waves are selected
	// in the browser window. No check for selection
	// type, so if you select a folder or variable
	// you will get an error.

	//String wname3d //name of the output 3d wave
	//DFREF cwd = GetDataFolderDFR()
	string listOfSelectedWaves = ""


	// CAUTION: We use this RegEx to avoid catching single quotes for waves with literal names.
	// Because this will create problems when trying to use $wnamestr as returned from
	// StringFromList(n,ListofMatchedWaves).

	//String RegEx = "(\w+:)*('?)(\w+[^:?]+)\2$" // Match any character after the last colon!
	if(!strlen(wname3d))
		wname3d = "MXP_Stack"
	endif
	// if name in use by a global wave/variable 
	if(!exists(wname3d) == 0) // 0 - Name not in use, or does not conflict with a wave, numeric variable or string variable in the specified data folder.
		print "MXP: Renamed your wave to \"" + (wname3d + "_rn") + "\" to avoid conflicts"
		wname3d += "_rn"
	endif
		
	variable i = 0
	do
		if(strlen(GetBrowserSelection(i)))
			listOfSelectedWaves += GetBrowserSelection(i) + ";" // Match stored at S_value
		endif
		i++
	while (strlen(GetBrowserSelection(i)))

	variable nrwaves = ItemsInList(listOfSelectedWaves)
	if (nrwaves < 2)
		return -1 // No wave or one wave is selected
	endif
	
	string wname = StringFromList(0,listOfSelectedWaves)

	WAVE wref = $wname
	variable nx = DimSize(wref,0)
	variable ny = DimSize(wref,1)
	
	if(WaveType(wref) & 2) // 32-bit float
		Make/I/N = (nx, ny, nrwaves) $wname3d
	elseif(WaveType(wref) & 2^2) // 64-bit float
		Make/D/N = (nx, ny, nrwaves) $wname3d
	elseif(WaveType(wref) & 2^4 && !(WaveType(wref) & 2^6)) // 16-bit integer signed
		Make/W/N = (nx, ny, nrwaves) $wname3d
	elseif(WaveType(wref) & 2^4 && (WaveType(wref) & 2^6)) // 16-bit integer unsigned
		Make/W/U/N = (nx, ny, nrwaves) $wname3d
	else
		Make/N = (nx, ny, nrwaves) $wname3d //default
	endif
	
	WAVE w3dref = $wname3d
	
	for(i = 0; i < nrwaves; i += 1)
		Wave t2dwred = $(StringFromList(i,listOfSelectedWaves))
		w3dref[][][i] = t2dwred[p][q]
	endfor
	return 0
End

Function MXP_AverageStackToImage(WAVE w3d, [string avgImageName])
	/// Average a 3d wave along z.
	/// @param w3d WAVW Wave name to average (3d wave)
	/// @param avgImageName string optional Name of the output wave, default MXP_AvgStack.
	avgImageName = SelectString(ParamIsDefault(avgImageName) ? 0: 1,"MXP_AvgStack", avgImageName)
	ImageTransform averageImage w3d
	WAVE M_AveImage
	Duplicate/O M_AveImage, $avgImageName
	KillWaves/Z M_AveImage
	variable layers = DimSize(w3d, 2)
	string w3dNoteStr = "Average of " + num2str(layers) + " images.\n"
	w3dNoteStr += "Copy of " + NameOfWave(w3d) + "note:\n"
	w3dNoteStr += note(w3d)
	Note/K $avgImageName w3dNoteStr
	return 0
End

Function MXP_3DWavePartition(WAVE w3d, string partitionNameStr, variable startP, variable endP, variable startQ, variable endQ, [variable tetragonal, variable powerOfTwo])
	/// Partition a 3D to get an orthorhombic 3d wave
	/// @param startP int
	/// @param endP int
	/// @param startQ int
	/// @param endQ
	/// @param tetragonal int optional When set the number of rows and columns of the partition equals max(rows, cols).
	/// @param powerOfTwo int optional set the rows, cols to the next 2^n
	/// @param filter int optional apply an image filter to the stack
	tetragonal = ParamIsDefault(tetragonal) ? 0: tetragonal 
	powerOfTwo = ParamIsDefault(powerOfTwo) ? 0: powerOfTwo

	// P, Q values might come from scaled images
	startP = ScaleToIndex(w3d, startP, 0)
	endP   = ScaleToIndex(w3d, endP, 0)
	startQ = ScaleToIndex(w3d, startQ, 1)
	endQ   = ScaleToIndex(w3d, endQ, 1)
	// Check boundaries
	variable nrows = DimSize(w3d, 0)
	variable ncols = DimSize(w3d, 1)
	variable rowsOff = DimOffset(w3d, 0)
	variable colsOff = DimOffset(w3d, 1)
	variable nlayer = DimSize(w3d, 2)
	// assume that startP < endP && startQ < endQ
	if (!(startP < endP && startQ < endQ && endP < nrows && endQ < ncols && startP > rowsOff && startQ > colsOff))
		Abort "Error: Out of bounds p, q values or X_min >= X_max."
	endif
	variable nWaveRows = endP-startP
	variable nWaveCols = endQ-startQ
	if(tetragonal) //
		nWaveRows = max(nWaveRows, nWaveCols)
		if(mod(nWaveRows, 2))
		nWaveRows += 1 //should be even
		endif
		nWaveCols = nWaveRows
	endif
	if(powerOfTwo)
		nWaveCols = MXP_NextPowerOfTwo(nWaveCols)
		nWaveRows = nWaveCols
	endif
	Make/O/N=(nWaveRows, nWavecols, nlayer) $partitionNameStr /WAVE=wRef // MT here?
	wRef[][][] = w3d[startP + p][startQ + q][r]

	return 0
End

Function/WAVE MXP_WAVE3DWavePartition(WAVE w3d, variable startP, variable endP, variable startQ, variable endQ, [variable evenNum, variable tetragonal, variable powerOfTwo])
	/// Partition a 3D to get an orthorhombic 3d wave
	/// @param startP int
	/// @param endP int
	/// @param startQ int
	/// @param endQ
	/// @param evenNum int optional set rows, cols to the closest even number
	/// @param tetragonal int optional When set the number of rows and columns of the partition equals max(rows, cols).
	/// @param powerOfTwo int optional set the rows, cols to the next 2^n
	evenNum = ParamIsDefault(evenNum) ? 0: evenNum
	tetragonal = ParamIsDefault(tetragonal) ? 0: tetragonal 
	powerOfTwo = ParamIsDefault(powerOfTwo) ? 0: powerOfTwo

	// P, Q values might come from scaled images
	startP = ScaleToIndex(w3d, startP, 0)
	endP   = ScaleToIndex(w3d, endP, 0)
	startQ = ScaleToIndex(w3d, startQ, 1)
	endQ   = ScaleToIndex(w3d, endQ, 1)
	// Check boundaries
	variable nrows = DimSize(w3d, 0)
	variable ncols = DimSize(w3d, 1)
	variable rowsOff = DimOffset(w3d, 0)
	variable colsOff = DimOffset(w3d, 1)
	variable nlayer = DimSize(w3d, 2)
	// assume that startP < endP && startQ < endQ
	if (!(startP < endP && startQ < endQ && endP < nrows && endQ < ncols && startP > rowsOff && startQ > colsOff))
		Abort "Error: Out of bounds p, q values or X_min >= X_max."
	endif
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
	
	if(powerOfTwo)
		nWaveCols = MXP_NextPowerOfTwo(nWaveCols)
		nWaveRows = nWaveCols
	endif
	
	Make/FREE/N=(nWaveRows, nWavecols, nlayer) wFreeRef
	wFreeRef[][][] = w3d[startP + p][startQ + q][r]
	return wFreeRef
End

Function MXP_ZapNaNsWithValue(WAVE w)
	variable nlayers = DimSize(w, 2)
	variable ncols = DimSize(w, 1)
	if(nlayers)
		Multithread w = (numtype(w[p][q][r]) == 2) ? 0: w
	elseif(ncols && !nlayers)
		w = (numtype(w[p][q]) == 2) ? 0: w 
	else
		w = (numtype(w[p]) == 2) ? 0: w 
	endif
	
End


Function MXP_Normalise3DWaveWithProfile(WAVE w3dRef, WAVE profWaveRef)
	// Normalise a 3d wave (stack) with a line profile (1d wave) along the z direction
	
	// consistency check
	if(DimSize(w3dRef, 2) != DimSize(profWaveRef, 0))
		printf "Number of layers in %s is different from number of points in %s", NameOfWave(w3dRef), NameOfWave(profWaveRef)
		return -1
	endif
	w3dRef /= profWaveRef[r]
	return 0
End

Function MXP_NormaliseWaveWithProfile(WAVE wRef, WAVE profWaveRef)
	// Normalise a wave 
	
	// consistency check
	if(DimSize(wRef, 0) != DimSize(profWaveRef, 0))
		printf "numpoints(%s) != numpoints(%s) \n", NameOfWave(wRef), NameOfWave(profWaveRef)
		return -1
	endif
	wRef /= profWaveRef
	return 0
End

// Helper functions
static Function MXP_NextPowerOfTwo(variable num)
	 /// Return the first power of two after num.
	 /// @param num double 
	variable bufferVar
	variable result = 1
	do
		result *= 2
	while (result < num)
	return result
End
