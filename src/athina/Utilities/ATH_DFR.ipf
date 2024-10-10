#pragma rtGlobals    = 3
#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_DFR
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

// N.B: Changed on 31.01.2024.
static Function/DF CreateDataFolderGetDFREF(string fullpath, [int setDF]) // Cornerstone function
	/// Create a data folder using fullpath and return a DF reference.
	/// If parent directories do not exist they are created.
	/// SetDF set the cwd to fullpath if set.
	/// N.B If the folder contains paths with liberal names without 
	/// enclosing single quotes then the path is sanitised
	
	setDF = ParamIsDefault(setDF) ? 0 : setDF
	
	//We can accept relative paths
	if(ATH_String#StartsWith(fullpath, ":"))
		// GetDataFolder(1) ends with ":"
		fullpath = GetDataFolder(1) + fullpath[1,inf]
	endif
	
	
	// If you omit root, the function will add it.
	if(cmpstr(ParsefilePath(0, fullpath, ":", 0, 0), "root"))
		fullpath = "root:" + fullpath
	endif
	
	// Sanitize path, liberal names
	// It is not always needed, 
	if(!ATH_String#isPathStringLegalQ(fullpath))
		fullpath = SanitizePath(fullpath)
	endif
	
	// If the directory exists
	if(DataFolderExists(ParseFilePath(2, fullpath, ":", 0, 0))) // ":" at the end needed to function properly
		DFREF dfr = $fullpath
		if (setDF)
			SetDataFolder dfr
		endif
		return dfr
	endif

	/// Create a list of missing paths, parents first.
	variable steps = ItemsInlist(ParseFilePath(2, fullpath, ":", 0, 0), ":"), i
	string fldrs = "", fldrstr
	for(i = 1; i < steps ; i++) // i = 0 & steps return NULL string
		fldrs += ParseFilePath(1, fullpath, ":", 0, i) + ";"
	endfor
	fldrs += ParseFilePath(2, fullpath, ":", 0, 0) // add the full path (last child folder is created here
	// now create the folder from parent to child
	variable fldrnum = ItemsInList(fldrs)
	for(i = 0; i < fldrnum; i++)
		fldrstr = StringFromList(i, fldrs)
		if(!DataFolderExists(fldrstr)) // ":" at the end needed to function properly - No! (08.01.23)
			NewDataFolder/O $RemoveEnding(fldrstr, ":") // Here the last ":" pops an error
		endif
	endfor

	DFREF dfr = $fullpath
	if (setDF)
		SetDataFolder dfr
	endif
	
	return dfr
End

static Function/S SanitizePath(string path)
	// Fix liberal relative pathnames in fullpath
	variable steps = ItemsInlist(path, ":"), i
	string spath = "", str
	for(i = 0; i < steps ; i++) // i = 0 & steps return NULL string
		str = StringFromList(i, path, ":")
		spath += PossiblyQuoteName(str) + ":"
	endfor
	return spath
End

static Function ZapDataInFolderTree(string path) 
	/// Kills the contents of a data folder and the contents of its 
	/// children without killing any data folders and without attempting 
	/// to kill any waves that may be in use.

	string saveDF = GetDataFolder(1) 
	SetDataFolder path

	KillWaves/A/Z 
	KillVariables/A/Z 
	KillStrings/A/Z

	variable numDataFolders = CountObjects(":", 4), i

	for(i=0; i<numDataFolders; i+=1)
		string nextPath = GetIndexedObjName(":", 4, i) 
		ZapDataInFolderTree(nextPath) 
	endfor

	SetDataFolder saveDF 
End

static Function ZapAllDataFoldersInPath(string path) 
	/// Kills all data folders in path.

	string saveDF = GetDataFolder(1) 
	SetDataFolder path

	variable numDataFolders = CountObjects(":", 4), i

	for(i=0; i<numDataFolders; i+=1)
		string nextPath = GetIndexedObjName(":", 4, i) 
		KillDataFolder $nextPath 
	endfor

	SetDataFolder saveDF 
End

static Function PrintFoldersAndFiles(string pathName, string extension, variable recurse, variable level)
	/// This is a Wavemetrics function
	/// Striwng pathName	Name of symbolic path in which to look for folders and files.
	/// String extensios File name extension (e.g., ".txt") or "????" for all files.
	/// Variable recurse True to recurse (do it for subfolders too).
	/// Variable level Recursion level. Pass 0 for the top level.
	
	Variable folderIndex, fileIndex
	String prefix
	
	// Build a prefix (a number of tabs to indicate the folder level by indentation)
	prefix = ""
	folderIndex = 0
	do
		if (folderIndex >= level)
			break
		endif
		prefix += "\t"	// Indent one more tab
		folderIndex += 1
	while(1)
	
	// Print folder
	String path
	PathInfo $pathName	// Sets S_path
	path = S_path
	Printf "%s%s\r", prefix, path

	// Print files
	fileIndex = 0
	do
		String fileName
		fileName = IndexedFile($pathName, fileIndex, extension)
		if (strlen(fileName) == 0)
			break
		endif
		Printf "%s\t%s%s\r", prefix, path, fileName
		fileIndex += 1
	while(1)
	
	if (recurse)		// Do we want to go into subfolder?
		folderIndex = 0
		do
			path = IndexedDir($pathName, folderIndex, 1)
			if (strlen(path) == 0)
				break	// No more folders
			endif

			String subFolderPathName = "tempPrintFoldersPath_" + num2istr(level+1)
			
			// Now we get the path to the new parent folder
			String subFolderPath
			subFolderPath = path
			
			NewPath/Q/O $subFolderPathName, subFolderPath
			ATH_DFR#PrintFoldersAndFiles(subFolderPathName, extension, recurse, level+1)
			KillPath/Z $subFolderPathName
			
			folderIndex += 1
		while(1)
	endif
End

static Function CleanGlobalWavesVarAndStrInFolder(DFREF dfr)
	/// Move from current working directory to dfr
	/// kill all global variables and strings and 
	/// return to the working directory
	
	DFREF cwd = GetDataFolderDFR()
	SetDataFolder dfr
	KillWaves/A
	KillVariables/A
	KillStrings/A
	SetDataFolder cwd
End

static Function DeleteEverythingButSomeFolders(string baseFolderPattern, string keepFolders)
	/// Delete waves and child folders in folders that match baseFolderPattern but keep keepFolders
	/// @param folderPattern string match folders pattern
	/// @param keepFolders string keepfolder list separated by ;
	
	DFREF dfr = GetDataFolderDFR()
	variable numDataFolders = CountObjectsDFR(dfr, 4), numChildDataFolders, i, j
	variable numFoldersToKeep = ItemsInList(keepFolders)
	
	string iterParentDataFolderStr, iterChildDataFolderStr
	for(i = 0; i < numDataFolders; i++)
		iterParentDataFolderStr = GetIndexedObjNameDFR(dfr, 4, i)
		if(stringmatch(iterParentDataFolderStr, baseFolderPattern))
			SetDataFolder dfr:$iterParentDataFolderStr
			KillWaves/A
			KillVariables/A
			KillStrings/A
			numChildDataFolders = CountObjectsDFR(dfr:$iterParentDataFolderStr, 4)
			for(j = 0; j < numChildDataFolders; j++)
				iterChildDataFolderStr = GetIndexedObjNameDFR(dfr:$iterParentDataFolderStr, 4, j)
				if(FindListItem(iterChildDataFolderStr, keepFolders) == -1)
					KillDataFolder/Z $iterChildDataFolderStr
				endif
			endfor
			break
		endif
		//WM_ZapDataInFolderTree(nextPath) 
	endfor
	SetDataFolder dfr
End

// ----------------------------------------

static Function FindBigWaves(variable minSizeInMB[,DFREF df,variable depth,variable noShow])
	/// See https://www.wavemetrics.com/code-snippet/find-big-waves
 
    if(ParamIsDefault(df))
        DFREF df=root:
    endif
     if(ParamIsDefault(noShow))
        noShow = 1
    endif   
    if(depth==0)
        DFREF packageDF = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:FindBigWaves")
        Make/O/T/N=0 packageDF:waveNamesW
        Make/O/N=0   packageDF:waveSizesW
    else
        DFREF packageDF = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:FindBigWaves")
    endif
    variable i
    wave /T/sdfr=packageDF waveNamesW
    wave /sdfr=packageDF waveSizesW
    variable points=numpnts(waveNamesW)
    variable numWaves = CountObjectsDFR(df,1)
    for(i=0;i<numWaves;i+=1)
        wave w=df:$getindexedobjnamedfr(df,1,i)
        variable size = ATH_WaveOp#sizeOfWave(w)
        if(size > minSizeInMB)
            waveNamesW[points]={GetWavesDataFolder(w,2)}
            waveSizesW[points]={size}
            points+=1
        endif
    endfor
    i=0
    Do
        string folder=GetIndexedObjNamedfr(df,4,i)
        if(strlen(folder))
            dfref subDF=df:$folder
            ATH_DFR#FindBigWaves(minSizeInMB,df=subDF,depth=depth+1)
        else
            break
        endif
        i+=1
    While(1)
    if(depth==0)
        sort /R waveSizesW, waveSizesW, waveNamesW
        if(!noShow)
            if(WinType("BigWaves"))
                dowindow /f BigWaves
            else
                edit /K=1 /N=BigWaves waveNamesW, waveSizesW as "Big Waves"
            endif
        endif
    endif
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

static Function/S GetAllWavesStrDF(DFREF dfr)
	// Return a string of all fullpaths of waves
	// in the data folder dfr
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder dfr
	string objName, listStr = ""
	variable index = 0
	do
		objName = GetIndexedObjNameDFR(dfr, 1, index)
		WAVE wref = $objName
		if (strlen(objName) == 0)
			break
		endif
		listStr+= GetWavesDataFolder(wRef,2) +";"
		index += 1
	while(1)
	SetDataFolder saveDF
	return listStr
End
