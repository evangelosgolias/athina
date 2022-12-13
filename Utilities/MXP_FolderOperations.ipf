#pragma rtGlobals    = 3
#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later


// ------------------------------------------------------- //
// Developed by Evangelos Golias.
// Contact: evangelos.golias@gmail.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, IN CONNECTION WITH THE USE OF SOFTWARE.
// ------------------------------------------------------- //

Function WM_ZapDataInFolderTree(string path) 
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
		WM_ZapDataInFolderTree(nextPath) 
	endfor

	SetDataFolder saveDF 
End

Function MXP_ZapAllDataFoldersInPath(string path) 
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

Function/DF MXP_CreateDataFolderGetDFREF(string fullpath)
	/// Create a data folder using fullpath and return a DF reference. 
	/// If parent directories do not exist they will be created.
	/// CAUTION: Problems with libearl names might occur

	// First take care of liberal names in path string. eg root:A folder will become root:'A folder'.
	
	variable steps = ItemsInlist(ParseFilePath(2, fullpath, ":", 0, 0), ":"), i // ParseFilePath adds potentially missing : ending.
	string correctFullPath = ""
	for(i = 0; i < steps ; i++) // i = 0 & steps return NULL string
		correctFullPath += PossiblyQuoteName(ParseFilePath(0, fullpath, ":", 0, i)) + ":"
	endfor
	
	// If the directory exists, avoid all the trouble	
	if(DataFolderExists(ParseFilePath(2, correctFullPath, ":", 0, 0))) // ":" at the end needed to function properly
		DFREF dfr = $correctFullPath
		return dfr
	endif 
	
	/// Create a list of missing paths, parents first.
	string fldrs = "", fldrstr
	for(i = 1; i < steps ; i++) // i = 0 & steps return NULL string
		fldrs += ParseFilePath(1, correctFullPath, ":", 0, i) + ";"
	endfor
	fldrs += ParseFilePath(2, correctFullPath, ":", 0, 0) // add the full path (last child folder is created here
	// now create the folder from parent to child
	variable fldrnum = ItemsInList(fldrs)
	for(i = 0; i < fldrnum; i++)
		fldrstr = StringFromList(i, fldrs)
		if(!DataFolderExists(fldrstr)) // ":" at the end needed to function properly
			NewDataFolder/O $RemoveEnding(fldrstr) // Here the last ":" pops an error
		endif
	endfor
	
	DFREF dfr = $correctFullPath
	return dfr
End


Function/DF MXP_CreateDataFolderGetDFREF_bak(string fullpath)
	/// Create a data folder using fullpath and return a DF reference. 
	/// If parent directories do not exist they will be created.
	/// CAUTION: Problems with libearl names might occur
	// If the directory exists, avoid all the trouble
	// First take care of liberal names
	
	
	if(DataFolderExists(ParseFilePath(2, fullpath, ":", 0, 0))) // ":" at the end needed to function properly
		DFREF dfr = $fullpath
		return dfr
	endif 
	
	/// Create a list of missing path, parent first.
	variable steps = ItemsInlist(ParseFilePath(2, fullpath, ":", 0, 0), ":"), i // ParseFilePath adds potentially missing : ending.
	string fldrs = "" // You will get an error if you do not initialise to "", you cannot fldrs += "another string"
	for(i = 1; i < steps ; i++) // i = 0 & steps return NULL string
		fldrs += ParseFilePath(1, fullpath, ":", 0, i) + ";"
	endfor
	fldrs += ParseFilePath(2, fullpath, ":", 0, 0)
	// folder tree list created
	print fldrs
	// now create the folder from parent to child
	string fldrstr
	variable fldrnum = ItemsInList(fldrs)
	for(i = 0; i < fldrnum; i++)
		fldrstr = StringFromList(i, fldrs)
		if(!DataFolderExists(fldrstr)) // ":" at the end needed to function properly
			NewDataFolder/O $RemoveEnding(fldrstr) // Here the last ":" pops an error
		endif
	endfor
	
	DFREF dfr = $fullpath
	return dfr
End

Function WM_PrintFoldersAndFiles(string pathName, string extension, variable recurse, variable level)
	/// This is a WM function
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
			WM_PrintFoldersAndFiles(subFolderPathName, extension, recurse, level+1)
			KillPath/Z $subFolderPathName
			
			folderIndex += 1
		while(1)
	endif
End

Function MXP_CleanGlobalWavesVarAndStrInFolder(DFREF dfr)
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

Function MXP_DeleteEverythingButSomeFolders(string baseFolderPattern, string keepFolders)
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