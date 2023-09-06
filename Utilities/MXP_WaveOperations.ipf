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
Function MXP_Make3DWaveUsingPattern(string wname3dStr, string pattern)
	// Make a 3d wave named wname3d using the RegEx pattern
	// Give "*" to match all waves

	string ListofMatchedWaves = WaveList(pattern, ";", "")
	variable nrwaves = ItemsInList(ListofMatchedWaves)
	if(!nrwaves)
		Abort "No matching 2D waves"
	endif
	
	if(!strlen(wname3dStr))
		wname3dStr = "MXP_Stack"
	endif
	// if name in use by a global wave/variable 
	DFREF currDF = GetDataFolderDFR()
	wname3dStr = CreatedataObjectName(currDFR, "MXP_stack", 1, 0, 0)

	variable i
	
	Make/FREE/WAVE/N=(nrwaves) mxp_FREEwaveListWaveRef
	 
	for(i = 0; i < nrwaves; i++)
		mxp_FREEwaveListWaveRef[i] = $(StringFromList(i,ListofMatchedWaves))
	endfor
	
	Concatenate/NP=2 {mxp_FREEwaveListWaveRef}, $wname3dStr
		
	return 0
End

Function/S MXP_Make3DWaveDataBrowserSelection(string wname3dStr, [variable gotoFilesDFR])

	// Make a 3d wave using waves selected
	// in the browser window. No check for selection
	// type, so if you select a folder or variable
	// you will get an error.
	// Returns a string with the name of the created wave, as wname3dStr
	// might be already taken
	
	gotoFilesDFR = ParamIsDefault(gotoFilesDFR) ? 0: gotoFilesDFR
	string listOfSelectedWaves = ""
	
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
	
	DFREF currDFR = GetDataFolderDFR()
	if(gotoFilesDFR)
		SetDataFolder GetWavesDataFolderDFR(wref)
		currDFR = GetDataFolderDFR()
	endif
	
	if(exists(wname3dStr) == 1)
		// We need a unique wave name
		wname3dStr = CreatedataObjectName(currDFR, "MXP_stack", 1, 0, 0)
	endif
	
	Make/FREE/WAVE/N=(nrwaves) mxp_FREEwaveListWaveRef
	 
	for(i = 0; i < nrwaves; i++)
		mxp_FREEwaveListWaveRef[i] = $(StringFromList(i,listOfSelectedWaves))
	endfor
	
	Concatenate/NP=2 {mxp_FREEwaveListWaveRef}, $wname3dStr
	
	// if you use /P, the dimension scaling is copied in slope/intercept format 
	// so that if srcWaveName  and the other waves have differing dimension size 
	// (number of points if the wave is a 1D wave), then their dimension values 
	// will still match for the points they have in common
	//CopyScales t2dwred, w3dref 
	// Add a note about the stacked waves
	Note/K $wname3dStr, listOfSelectedWaves
	// Go back to the cwd
	SetDataFolder currDFR
	return wname3dStr
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
	string nameofWaveStr = NameOfWave(w3d)
	string w3dNoteStr = nameofWaveStr + " average (" + num2str(nlayers) + ")\n"
	w3dNoteStr += "Copy of " + nameofWaveStr + " note:\n"
	w3dNoteStr += note(w3d)
	Note/K $avgImageName w3dNoteStr
	return 0
End

Function MXP_3DWavePartition(WAVE w3d, string partitionNameStr, variable startX, variable endX, variable startY, variable endY, [variable evenNum, variable tetragonal])
	/// Partition a 3D to get an orthorhombic 3d wave
	/// @param startP int
	/// @param endP int
	/// @param startQ int
	/// @param endQ
	/// @param evenNum int optional set rows, cols to the closest even number
	/// @param tetragonal int optional When set the number of rows and columns of the partition equals max(rows, cols).

	evenNum = ParamIsDefault(evenNum) ? 0: evenNum
	tetragonal = ParamIsDefault(tetragonal) ? 0: tetragonal 

	variable nrows = DimSize(w3d, 0)
	variable ncols = DimSize(w3d, 1)
	variable rowsOff = DimOffset(w3d, 0)
	variable colsOff = DimOffset(w3d, 1)
	
	variable xmin = rowsOff
	variable ymin = colsOff
	variable xmax = rowsOff + (nrows - 1) * DimDelta(w3d, 0)
	variable ymax = colsOff + (ncols - 1) * DimDelta(w3d, 1)
	
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
	
	if (!(startX < endX && startY < endY && startX >= rowsOff && startY >= colsOff))
		Abort "Error: Out of bounds p, q values or X_min >= X_max."
	endif
	
	variable startP, endP, startQ, endQ
	// P, Q values might come from scaled images
	startP = ScaleToIndex(w3d, startX, 0)
	endP   = ScaleToIndex(w3d, endX, 0)
	startQ = ScaleToIndex(w3d, startY, 1)
	endQ   = ScaleToIndex(w3d, endY, 1)
	
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
	Duplicate/RMD=[startP, startP + nWaveRows][startQ, startQ + nWaveCols][] w3d, $partitionNameStr
	return 0
End

Function/WAVE MXP_WAVE3DWavePartition(WAVE w3d, variable startX, variable endX, variable startY, variable endY, [variable evenNum, variable tetragonal])
	/// Partition a 3D to get an orthorhombic 3d wave
	/// @param startX int
	/// @param endX int
	/// @param startY int
	/// @param endY
	/// @param evenNum int optional set rows, cols to the closest even number
	/// @param tetragonal int optional When set the number of rows and columns of the partition equals max(rows, cols).
	evenNum = ParamIsDefault(evenNum) ? 0: evenNum
	tetragonal = ParamIsDefault(tetragonal) ? 0: tetragonal 

	variable nrows = DimSize(w3d, 0)
	variable ncols = DimSize(w3d, 1)
	variable rowsOff = DimOffset(w3d, 0)
	variable colsOff = DimOffset(w3d, 1)
	
	variable xmin = rowsOff
	variable ymin = colsOff
	variable xmax = rowsOff + (nrows - 1) * DimDelta(w3d, 0)
	variable ymax = colsOff + (ncols - 1) * DimDelta(w3d, 1)
	
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
	
	if (!(startX < endX && startY < endY && startX >= rowsOff && startY >= colsOff))
		Abort "Error: Out of bounds p, q values or X_min >= X_max."
	endif
	
	variable startP, endP, startQ, endQ
	// P, Q values might come from scaled images
	startP = ScaleToIndex(w3d, startX, 0)
	endP   = ScaleToIndex(w3d, endX, 0)
	startQ = ScaleToIndex(w3d, startY, 1)
	endQ   = ScaleToIndex(w3d, endY, 1)
	
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

	variable nlayers = DimSize(w3d, 2)
	Make/FREE/N=(nWaveRows, nWavecols, nlayers) wFreeRef
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

Function MXP_NormaliseWaveToUnitRange(WAVE waveRef)
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

Function [variable x0, variable y0, variable z0, variable dx, variable dy, variable dz] MXP_GetScalesP(WAVE wRef)
	// Get the scales of waves per point. 
	x0 = DimOffset(wRef, 0)
	y0 = DimOffset(wRef, 1)
	y0 = DimOffset(wRef, 2)
	dx = DimDelta(wRef, 0)
	dy = DimDelta(wRef, 1)
	dz = DimDelta(wRef, 2)
	return [x0, y0, z0, dx, dy, dz]
End

Function MXP_SetScalesP(WAVE wRef, variable x0, variable y0, variable z0, variable dx, variable dy, variable dz)
	// Set scale of waves per point
	// Usage:
	// 		variable x0, y0, z0, dx, dy, dz
	// 		[x0, y0, z0, dx, dy, dz] = MXP_GetScalesP(wRef)
	// 		MXP_SetScalesP(wRef, x0, y0, z0, dx, dy, dz)
	
	SetScale/P x, x0, dx, wRef
	SetScale/P y, y0, dy, wRef
	SetScale/P z, z0, dz, wRef
End

Function MXP_MakeWaveFromROI(WAVE wRef)
	// Extracts the ROI from wRef using the saved ROI coordinates in the database
	// Works with 2D and 3D waves
	DFREF dfrROI = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:SavedROI")
	NVAR/Z/SDFR=dfrROI gMXP_Sleft
	if(!NVAR_Exists(gMXP_Sleft))
		Abort "No Saved ROI found. Use the Marquee to set the ROI first."
	endif
	NVAR/SDFR=dfrROI gMXP_Sleft
	NVAR/SDFR=dfrROI gMXP_Sright
	NVAR/SDFR=dfrROI gMXP_Stop
	NVAR/SDFR=dfrROI gMXP_Sbottom
	string wnameStr = NameOfWave(wRef) + "_roi"
	variable p0, p1, q0, q1
	p0 = scaleToIndex(wRef, gMXP_Sleft, 0)
	p1 = scaleToIndex(wRef, gMXP_Sright, 0)
	q0 = scaleToIndex(wRef, gMXP_Stop, 1)
	q1 = scaleToIndex(wRef, gMXP_SBottom, 1)
	Duplicate/RMD=[p0, p1][q0, q1] wRef, $wnameStr
	MXP_SetWaveOffsetZero(wRef, dim = 0)
	MXP_SetWaveOffsetZero(wRef, dim = 1)	
	string noteStr
	sprintf noteStr, "Image: %s, ROI:[%d, %d][%d, %d]", NameOfWave(wRef), gMXP_Sleft, gMXP_SRight, gMXP_Stop, gMXP_SBottom
	Note $wnameStr, noteStr
	return 0
End

Function MXP_SetWaveOffsetZero(WAVE wRef, [int dim])
	// Zero the offset for dimension dim
	dim = ParamIsDefault(dim) ? 0: dim
	variable dx = DimDelta(wRef, dim)
	string dimStr = "x;y;z;t"
	if(dim < 0 || dim > 3)
		return -1
	endif
	string selDim = StringFromList(dim, dimStr)
	string cmd = "SetScale/P " + selDim + " 0, " + num2str(dx) + ", " + PossiblyQuoteName(NameOfWave(wRef))
	Execute cmd
	return 0
End

// Helper functions
Function MXP_NextPowerOfTwo(variable num)
	 /// Return the first power of two after num.
	 /// @param num double 
	variable bufferVar
	variable result = 1
	do
		result *= 2
	while (result < num)
	return result
End


// ----------------------------------------

Function MXP_FindBigWaves(minSizeInMB[,df,depth,noShow])
	/// Copy of https://www.wavemetrics.com/code-snippet/find-big-waves
    Variable minSizeInMB // Minimum size in MB, e.g. 100 
    variable depth // Used by the function recursion.  Ignore.  
    variable noShow // Don't show the table at the end.  
    dfref df // A folder to use as the top level of the search.  Default is root:  
 
    if(paramisdefault(df))
        dfref df=root:
    endif
    if(depth==0)
        NewDataFolder /O root:Packages
        NewDataFolder /O root:Packages:MXP_FindBigWaves
        dfref packageDF=root:Packages:MXP_FindBigWaves
        Make /o/T/n=0 packageDF:names
        Make /o/n=0 packageDF:sizes
    else
        dfref packageDF=root:Packages:MXP_FindBigWaves
    endif
    variable i
    wave /T/sdfr=packageDF names
    wave /sdfr=packageDF sizes
    variable points=numpnts(names)
    for(i=0;i<CountObjectsDFR(df,1);i+=1)
        wave w=df:$getindexedobjnamedfr(df,1,i)
        variable size = MXP_sizeOfWave(w)
        if(size > minSizeInMB)
            names[points]={GetWavesDataFolder(w,2)}
            sizes[points]={size}
            points+=1
        endif
    endfor
    i=0
    Do
        string folder=GetIndexedObjNamedfr(df,4,i)
        if(strlen(folder))
            dfref subDF=df:$folder
            MXP_FindBigWaves(minSizeInMB,df=subDF,depth=depth+1)
        else
            break
        endif
        i+=1
    While(1)
    if(depth==0)
        sort /R sizes,sizes,names
        if(!noShow)
            if(wintype("BigWaves"))
                dowindow /f BigWaves
            else
                edit /K=1 /N=BigWaves names,sizes as "Big Waves"
            endif
        endif
    endif
End

Function MXP_SizeOfWave(wv)
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
            total += MXP_SizeOfWave(elem)
        endfor
    endif

    return total / 1024 / 1024
End

Function MXP_IsFloatQ(WAVE wRef)
	// Returns true of wRef is 32 or 64 bit float wave
	return ((WaveType(wRef) & 0x02) || (WaveType(wRef) & 0x04))
End

Function MXP_IsFloat32Q(WAVE wRef)
	// Returns true of wRef is 32 bit float wave
	return WaveType(wRef) & 0x02 
End

Function MXP_IsFloat64Q(WAVE wRef)
	// Returns true of wRef is 64 bit float wave
	return WaveType(wRef) & 0x04 
End
