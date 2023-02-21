#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
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
	variable i

	for(i = 0; i < nrwaves; i += 1)
		WAVE t2dwred = $(StringFromList(i,ListofMatchedWaves))
		w3dref[][][i] = t2dwred[p][q]
	endfor
	return 0
End

Function MXP_Make3DWaveDataBrowserSelection(string wname3d)

	// Like EGMake3DWave, but now waves are selected
	// in the browser window. No check for selection
	// type, so if you select a folder or variable
	// you will get an error.

	string listOfSelectedWaves = ""

	if(!strlen(wname3d))
		wname3d = "MXP_Stack"
	endif
	// Test not needed here -- Called from MXP_LaunchMake3DWaveDataBrowserSelection()
	//
	// if name in use by a global wave/variable 
	//	if(!exists(wname3d) == 0) // 0 - Name not in use, or does not conflict with a wave, numeric variable or string variable in the specified data folder.
	//		print "MXP: Renamed your wave to \"" + (wname3d + "_rn") + "\" to avoid conflicts"
	//		wname3d += "_rn"
	//	endif
		
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
	
	string wname = StringFromList(0, listOfSelectedWaves)

	WAVE wref = $wname
	variable nx = DimSize(wref,0)
	variable ny = DimSize(wref,1)
	// TODO: Change here with ImageTransform stackImages
	if(WaveType(wref) == 2) // 32-bit float
		Make/R/N = (nx, ny, nrwaves) $wname3d
	elseif(WaveType(wref) == 4) // 64-bit float
		Make/D/N = (nx, ny, nrwaves) $wname3d
	elseif(WaveType(wref) == 16) // 16-bit integer signed
		Make/W/N = (nx, ny, nrwaves) $wname3d
	elseif(WaveType(wref) == 80) // 16-bit integer unsigned
		Make/W/U/N = (nx, ny, nrwaves) $wname3d
	else
		Make/N = (nx, ny, nrwaves) $wname3d //default
	endif
	
	WAVE w3dref = $wname3d
	
	for(i = 0; i < nrwaves; i += 1) // TODO: Change and use ImageTransform ...
		Wave t2dwred = $(StringFromList(i,listOfSelectedWaves))
		w3dref[][][i] = t2dwred[p][q]
	endfor
	// if you use /P, the dimension scaling is copied in slope/intercept format 
	// so that if srcWaveName  and the other waves have differing dimension size 
	// (number of points if the wave is a 1D wave), then their dimension values 
	// will still match for the points they have in common
	CopyScales t2dwred, w3dref 
	return 0
End

Function MXP_AverageStackToImage(WAVE w3d, [string avgImageName])
	/// Average a 3d wave along z.
	/// @param w3d WAVE Wave name to average (3d wave)
	/// @param avgImageName string optional Name of the output wave, default MXP_AvgStack.
	avgImageName = SelectString(ParamIsDefault(avgImageName) ? 0: 1,"MXP_AvgStack", avgImageName)
	variable nlayers = DimSize(w3d, 2)
	ImageTransform sumplanes w3d // averageImage does not work for two layers!
	WAVE M_SumPlanes
	M_SumPlanes /= nlayers
	Duplicate/O M_SumPlanes, $avgImageName
	KillWaves/Z M_SumPlanes
	string w3dNoteStr = "Average of " + num2str(nlayers) + " images.\n"
	w3dNoteStr += "Copy of " + NameOfWave(w3d) + " note:\n"
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

Function MXP_ZapNaNAndInfWithValue(WAVE waveRef, variable val)
	//numtype = 1, 2 for NaN, Inf
	waveRef= (numtype(waveRef)) ? val : waveRef
End

Function MXP_NormaliseWaveWithWave(WAVE wRef1, WAVE wRef2)
	/// Normalise a wave with another
	// consistency check
	if(DimSize(wRef1, 0) != DimSize(wRef2, 0))
		printf "numpoints(%s) != numpoints(%s) \n", NameOfWave(wRef1), NameOfWave(wRef2)
		return -1
	endif
	wRef1 /= wRef2
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
