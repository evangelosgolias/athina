#pragma rtGlobals    = 3
#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma rtFunctionErrors=1 // DEGUB. Remove on release
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later


Function ZapDataInFolderTree(string path) 
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

Function/DF MXP_CreatePackageData(string subfolder) // Called only from GetPackageDFREF

	// Create the package data folder 
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:MXP_Datafdr
	NewDataFolder/O root:Packages:MXP_Datafdr:$subfolder

	// Create a data folder reference variable
	DFREF dfr = root:Packages

	// Create and initialize package data 
	// Your code goes here

	return dfr 
End

Function/DF MXP_GetPackageDFREF(string subfolder)

	DFREF dfr = root:Packages:MXP_Datafdr:$subfolder

	if (DataFolderRefStatus(dfr) != 1) 
		DFREF dfr = MXP_CreatePackageData(subfolder) 
	endif 
	
	return dfr 
End

Function/DF MXP_InitPackageDFREF(string subfolder) // Call to init a directory
	
	DFREF dfr = MXP_GetPackageDFREF(subfolder)

	// Read a package variable 
	// 

	// Write to a package variable 
	// 
	
	return dfr
End

Function MXP_PrintFoldersAndFiles(string pathName, string extension, variable recurse, variable level)
	/// This is a WM function
	/// String pathName	Name of symbolic path in which to look for folders and files.
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
			MXP_PrintFoldersAndFiles(subFolderPathName, extension, recurse, level+1)
			KillPath/Z $subFolderPathName
			
			folderIndex += 1
		while(1)
	endif
End
