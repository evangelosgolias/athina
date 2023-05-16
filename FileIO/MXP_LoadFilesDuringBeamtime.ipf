#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
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

Function MXP_LoadNewestFileInPathTreeAndDisplay(string extension)
	/// Load the last file found in the directory tree with root at pathName
	string latestfile = ""
	variable latestctime = 0
	string filepathStr = MXP_GetNewestCreatedFileInPathTree("pMXP_LoadFilesBeamtimeIgorPath", extension, latestfile, latestctime, 1, 0)
	WAVE wRef = MXP_WAVELoadSingleDATFile(filepathStr, "")
	MXP_DisplayImage(wRef)
	print "File loaded: ", filepathStr
	return 0
End

Function/S MXP_GetNewestCreatedFileInPathTree(string pathName, 
		   string extension, string &latestfile, variable &latestctime, 
		   variable recurse, variable level)
	//  MXP_GetNewestCreatedFileInPathTree is a modified WM code of
	//	PrintFoldersAndFiles(pathName, extension, recurse, level)
	//	It recursively finds all files in a folder and subfolders looking for 
	//  the creation date of each file, catching the newest one.
	//	pathName is the name of an Igor symbolic path that you created
	//	using NewPath or the Misc->New Path menu item.
	//	extension is a file name extension like ".txt" or "????" for all files.
	//	recurse is 1 to recurse or 0 to list just the top-level folder.
	//	level is the recursion level - pass 0 when calling MXP_GetNewestCreatedFileInPathTree.
	//  latestfile and latestctime are called by reference as the recursive function call would 
	//  reset pass-by-value arguments. We could alternatively use SVAR and NVAR.
	/// DO NOT CALL THE FUNCTION DIRECTLY.

	PathInfo $pathName
	string path = S_path	
	if(!V_flag) // If path not defined
		print "pMXP_LoadFilesBeamtimeIgorPath is not set!"
		path = MXP_SetOrResetBeamtimeRootFolder()
	endif
	
	// Reset or make the string variable
	variable folderIndex, fileIndex

	// Add files
	fileIndex = 0
	do
		string fileName
		fileName = IndexedFile($pathName, fileIndex, extension)
		if (strlen(fileName) == 0)
			break
		endif
			
		GetFileFolderInfo/Z/Q (path + fileName)
		
		if(V_creationDate > latestctime)
			latestfile = (path + fileName)
			latestctime = V_creationDate
		endif
	
		fileIndex += 1
	while(1)
	
	if (recurse)		// Do we want to go into subfolder?
		folderIndex = 0
		do
			path = IndexedDir($pathName, folderIndex, 1)
			if (strlen(path) == 0)
				break	// No more folders
			endif

			string subFolderPathName = "tempPrintFoldersPath_" + num2istr(level+1)
			
			// Now we get the path to the new parent folder
			string subFolderPath
			subFolderPath = path
			
			NewPath/Q/O $subFolderPathName, subFolderPath
			MXP_GetNewestCreatedFileInPathTree(subFolderPathName, extension, latestfile, latestctime, recurse, level+1)
			KillPath/Z $subFolderPathName
			
			folderIndex += 1
		while(1)
	endif
	return latestfile
End


Function MXP_LoadNewestFolderInPathTreeAndDisplay()
	/// Load the last file found in the directory tree with root at pathName
	/// If you haven't set the Igor path (NewPath ... ) a folder selection window 
	/// will pop to set pathName. The path name is saved as pMXP_LoadLastFileIgorPath

	string latestfolder = ""
	variable latestctime = 0
	string folderPathStr = MXP_GetNewestCreatedFolderInPathTree("pMXP_LoadFilesBeamtimeIgorPath", latestfolder, latestctime)
	WAVE wRef = MXP_WAVELoadDATFilesFromFolder(folderPathStr, "*", stack3d = 1, autoscale = 1)
	MXP_DisplayImage(wRef)
	print "Folder loaded: ", folderPathStr	
	return 0
End

Function/S MXP_GetNewestCreatedFolderInPathTree(string pathName, string &latestfolder, variable &latestctime)
	//  MXP_GetNewestCreatedFileInPathTree is a modified WM code of
	//	PrintFoldersAndFiles(pathName, extension, recurse, level)
	//	It recursively searches for the newest folder in a folder tree.
	//	pathName is the name of an Igor symbolic path that you created
	//	using NewPath or the Misc->New Path menu item.
	/// DO NOT CALL THE FUNCTION DIRECTLY.

	PathInfo $pathName
	string path = S_path	
	if(!V_flag) // If path not defined
		print "pMXP_LoadFilesBeamtimeIgorPath is not set!"
		path = MXP_SetOrResetBeamtimeRootFolder()
	endif
	
	// Reset or make the string variable
	variable folderIndex
	
	string allsubFolders = IndexedDir($pathName, -1, 1)
	folderIndex = 0
	do
		path = StringFromList(folderIndex, allsubFolders) //IndexedDir($pathName, folderIndex, 1)
		if (strlen(path) == 0)
			break	// No more folders
		endif
		
		string subFolderPathName = "tempMXP_SetFoldersPath_"

		// Now we get the path to the new parent folder
		string subFolderPath
		subFolderPath = path
		
		GetFileFolderInfo/Z/Q path

		if(V_creationDate > latestctime)
			latestfolder = path
			latestctime = V_creationDate
		endif
		
		NewPath/Q/O $subFolderPathName, subFolderPath
		MXP_GetNewestCreatedFolderInPathTree(subFolderPathName, latestfolder, latestctime)
		KillPath/Z $subFolderPathName

		folderIndex += 1
	while(1)
	return latestfolder
End

Function MXP_LoadNewestFileInPathTreeAndDisplayPython(string ext) // TODO
	/// Load the last file found in the directory tree with root set at pathName
	/// If you haven't set the Igor path (NewPath ... ) a folder selection window 
	/// will pop to set pathName. The path name is saved as pMXP_LoadLastFileIgorPath.

	string filepathStr = MXP_GetLastSavedFileInFolderTreePython("pMXP_LoadFilesBeamtimeIgorPath", ext) // Change path!
	//WAVE wRef = MXP_WAVELoadSingleDATFile(filepathStr, "")
	//MXP_DisplayImage(wRef)
	print "File loaded: ", filepathStr
	return 0
End

Function/S MXP_GetLastSavedFileInFolderTreePython(string pathName, string ext)
	// valid shell script
	// do shell script "python3 -c \"from pathlib import Path;from os.path import getmtime;
	// print(max(list(Path('/Users/evangelosgolias/Desktop/MAXPEEM March 2023').rglob('*.dat')),key=getmtime))\""
	// For WINDOWS python interpreter and runtime is needed.
	PathInfo $pathName
	string path = S_path	
	if(!V_flag) // If path not defined, set it and call the function again
		print "pMXP_LoadFilesBeamtimeIgorPath is not set!"
		path = MXP_SetOrResetBeamtimeRootFolder()
	endif
	
	#ifdef WINDOWS
		path = RemoveEnding(ParseFilePath(5, path, "\\", 0, 0))// Remove last backslash because it is interpreted as escape character \'
	#else // MACINTOSH
		path = ParseFilePath(5, path, "/", 0, 0)
	#endif	
	string 	unixCmd, igorCmd
	string unixCmdBase = "python3 -c \\\"from pathlib import Path;from os.path import getmtime;print(max(list(Path('%s').rglob('*%s')),key=getmtime))\\\""
	sprintf unixCmd, unixCmdBase, path, ext
	
	#ifdef WINDOWS
		sprintf igorCmd, "cmd.exe /C \"%s\"", unixCmd
	#else // MACINTOSH
		sprintf igorCmd, "do shell script \"%s\" ", unixCmd
	#endif	
	ExecuteScriptText/Z/B/UNQ igorCmd
	return S_value
End