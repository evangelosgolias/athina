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

Function ATH_LoadNewestFileInPathTreeAndDisplay(string extension)
	//variable timerRefNum = StartMSTimer
	/// Load the last file found in the directory tree with root at pathName
	string latestfile = ""
	variable latestctime = 0
	string filepathStr = ATH_GetNewestCreatedFileInPathTree("pATH_LoadFilesBeamtimeIgorPath", extension, latestfile, latestctime, 1, 0)
	//variable microSeconds = StopMSTimer(timerRefNum)
	//print "Time elapsed: ", microSeconds/1e6, " sec"
	WAVE wRef = ATH_WAVELoadSingleDATFile(filepathStr, "")
	ATH_DisplayImage(wRef)
	print "File loaded: ", filepathStr
	return 0
End

Function/S ATH_GetNewestCreatedFileInPathTree(string pathName, 
		   string extension, string &latestfile, variable &latestctime, 
		   variable recurse, variable level)
	//  ATH_GetNewestCreatedFileInPathTree is a modified WM code of
	//	PrintFoldersAndFiles(pathName, extension, recurse, level)
	//	It recursively finds all files in a folder and subfolders looking for 
	//  the creation date of each file, catching the newest one.
	//	pathName is the name of an Igor symbolic path that you created
	//	using NewPath or the Misc->New Path menu item.
	//	extension is a file name extension like ".txt" or "????" for all files.
	//	recurse is 1 to recurse or 0 to list just the top-level folder.
	//	level is the recursion level - pass 0 when calling ATH_GetNewestCreatedFileInPathTree.
	//  latestfile and latestctime are called by reference as the recursive function call would 
	//  reset pass-by-value arguments. We could alternatively use SVAR and NVAR.
	/// DO NOT CALL THE FUNCTION DIRECTLY.

	PathInfo $pathName
	string path = S_path	
	if(!V_flag) // If path not defined
		print "pATH_LoadFilesBeamtimeIgorPath is not set!"
		path = ATH_SetOrResetBeamtimeRootFolder()
	endif
	
	// Reset or make the string variable
	variable folderIndex, fileIndex

	// Add files
	fileIndex = 0
	string fileNames = IndexedFile($pathName, -1, extension)
	do
		string fileName
		filename = StringFromList(fileIndex, fileNames)
		if (strlen(fileName) == 0)
			break
		endif
			
		GetFileFolderInfo/P=$pathName/Z/Q fileName
		
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
			ATH_GetNewestCreatedFileInPathTree(subFolderPathName, extension, latestfile, latestctime, recurse, level+1)
			KillPath/Z $subFolderPathName
			
			folderIndex += 1
		while(1)
	endif
	return latestfile
End

Function ATH_LoadNewestFolderInPathTreeAndDisplay()
	/// Load the last file found in the directory tree with root at pathName
	/// If you haven't set the Igor path (NewPath ... ) a folder selection window 
	/// will pop to set pathName. The path name is saved as pATH_LoadLastFileIgorPath

	string latestfolder = ""
	variable latestctime = 0
	string folderPathStr = ATH_GetNewestCreatedFolderInPathTree("pATH_LoadFilesBeamtimeIgorPath", latestfolder, latestctime)
	WAVE wRef = ATH_WAVELoadDATFilesFromFolder(folderPathStr, "*", stack3d = 1, autoscale = 1, wname3dStr = "autoLoadStack")
	ATH_DisplayImage(wRef)
	print "Folder loaded: ", folderPathStr	
	return 0
End

Function/S ATH_GetNewestCreatedFolderInPathTree(string pathName, string &latestfolder, variable &latestctime)
	//  ATH_GetNewestCreatedFileInPathTree is a modified WM code of
	//	PrintFoldersAndFiles(pathName, extension, recurse, level)
	//	It recursively searches for the newest folder in a folder tree.
	//	pathName is the name of an Igor symbolic path that you created
	//	using NewPath or the Misc->New Path menu item.
	/// DO NOT CALL THE FUNCTION DIRECTLY.

	PathInfo $pathName
	string path = S_path	
	if(!V_flag) // If path not defined
		print "pATH_LoadFilesBeamtimeIgorPath is not set!"
		path = ATH_SetOrResetBeamtimeRootFolder()
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
		
		string subFolderPathName = "tempATH_SetFoldersPath_"

		// Now we get the path to the new parent folder
		string subFolderPath
		subFolderPath = path
		
		GetFileFolderInfo/Z/Q path

		if(V_creationDate > latestctime)
			latestfolder = path
			latestctime = V_creationDate
		endif
		
		NewPath/Q/O $subFolderPathName, subFolderPath
		ATH_GetNewestCreatedFolderInPathTree(subFolderPathName, latestfolder, latestctime)
		KillPath/Z $subFolderPathName

		folderIndex += 1
	while(1)
	return latestfolder
End


Function ATH_LoadNewestFileInPathTreeAndDisplayPython(string ext)
	/// Load the last file found in the directory tree with root set at pathName
	/// If you haven't set the Igor path (NewPath ... ) a folder selection window 
	/// will pop to set pathName. The path name is saved as pATH_LoadLastFileIgorPath.

	string filepathStr = ATH_GetLastSavedFileInFolderTreePython("pATH_LoadFilesBeamtimeIgorPath", ext) // Change path!
	#ifdef MACINTOSH
		filepathStr = ParseFilePath(10, filepathStr, "*", 0, 0)
	#endif	
	WAVE wRef = ATH_WAVELoadSingleDATFile(filepathStr, "")
	ATH_DisplayImage(wRef)
	print "File loaded: ", filepathStr
	return 0
End

Function/S ATH_GetLastSavedFileInFolderTreePython(string pathName, string ext)
	// valid shell script
	// do shell script "python3 -c \"from pathlib import Path;from os.path import getmtime;
	// print(max(list(Path('/Users/evangelosgolias/Desktop/MAXPEEM March 2023').rglob('*.dat')),key=getmtime))\""
	// For WINDOWS python interpreter and runtime is needed.
	
	//variable timerRefNum = StartMSTimer

	PathInfo $pathName
	string path = S_path	
	if(!V_flag) // If path not defined, set it and call the function again
		print "pATH_LoadFilesBeamtimeIgorPath is not set!"
		path = ATH_SetOrResetBeamtimeRootFolder()
	endif
	
	#ifdef WINDOWS
		path = RemoveEnding(ParseFilePath(5, path, "\\", 0, 0))// Remove last backslash because it is interpreted as escape character \'
	#else // MACINTOSH
		path = ParseFilePath(5, path, "/", 0, 0)
	#endif	
	string 	unixCmd, igorCmd, unixCmdBase
	
	#ifdef WINDOWS
		unixCmdBase = "python -c \"from pathlib import Path;from os.path import getmtime;print(max(list(Path('%s').rglob('*%s')),key=getmtime))\""
		sprintf unixCmd, unixCmdBase, path, ext
		sprintf igorCmd, "cmd.exe /C \"%s\"", unixCmd	
	#else // MACINTOSH
		unixCmdBase = "python3 -c \\\"from pathlib import Path;from os.path import getmtime;print(max(list(Path('%s').rglob('*%s')),key=getmtime))\\\""
		sprintf unixCmd, unixCmdBase, path, ext
		sprintf igorCmd, "do shell script \"%s\" ", unixCmd
	#endif	
	ExecuteScriptText/Z/B/UNQ igorCmd
	//variable microSeconds = StopMSTimer(timerRefNum)
	//print "Time elapsed: ", microSeconds/1e6, " sec"
	return S_value
End

Function ATH_LoadNewestTwoFilesInPathTreeAndDisplayPython(string ext)
	/// Load the last two saved files in the tree with pathName as root folder
	/// If you haven't set the Igor path (NewPath ... ) a folder selection window 
	/// will pop do so. The path name is saved as pATH_LoadLastFileIgorPath.

	string filepathsStr = ATH_GetLastTwoSavedFileInFolderTreePython("pATH_LoadFilesBeamtimeIgorPath", ext) // Change path!
	string filepath1Str = StringFromList(0, filepathsStr)
	string filepath2Str = StringFromList(1, filepathsStr)	
	#ifdef MACINTOSH
		filepath1Str = ParseFilePath(10, filepath1Str, "*", 0, 0)
		filepath2Str = ParseFilePath(10, filepath2Str, "*", 0, 0)		
	#endif
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	WAVE w1Ref = ATH_WAVELoadSingleDATFile(filepath1Str, "pyWave0", autoscale = 1)
	WAVE w2Ref = ATH_WAVELoadSingleDATFile(filepath2Str, "pyWave1", autoscale = 1)
	Imagetransform stackImages $"pyWave0"
	WAVE M_Stack
	string w3dStr = CreateDataObjectName(saveDF, "autoLoadL2F", 1, 0, 5)
	MoveWave M_stack, saveDF:$w3dStr
	SetDataFolder saveDF
	ATH_DisplayImage($w3dStr)
	Note $w3dStr, ("file1: " + filepath1Str + "\nfile2: " + filepath2Str)
	print "Files loaded: \n1.", filepath1Str, "\n2.", filepath2Str, "\n", "◊ Stacked in: ", w3dStr
	return 0
End

Function/S ATH_GetLastTwoSavedFileInFolderTreePython(string pathName, string ext)
//	unixCmdBase = "python3 -c \"from pathlib import Path;from os.path import getmtime;"\
//			  + "listFiles = sorted(Path('%s').rglob('*%s'), "\
//			  + "key = getmtime);print(listFiles[-2], end='');print(';');print(listFiles[-1], end='');print(';')\""	
//
//		
	
	//variable timerRefNum = StartMSTimer

	PathInfo $pathName
	string path = S_path	
	if(!V_flag) // If path not defined, set it and call the function again
		print "pATH_LoadFilesBeamtimeIgorPath is not set!"
		path = ATH_SetOrResetBeamtimeRootFolder()
	endif
	
	#ifdef WINDOWS
		path = RemoveEnding(ParseFilePath(5, path, "\\", 0, 0))// Remove last backslash because it is interpreted as escape character \'
	#else // MACINTOSH
		path = ParseFilePath(5, path, "/", 0, 0)
	#endif	
	string 	unixCmd, igorCmd, unixCmdBase
	
	#ifdef WINDOWS
		unixCmdBase = "python -c \"from pathlib import Path;from os.path import getmtime;"\
					  + "listFiles = sorted(Path('%s').rglob('*%s'), "\
					  + "key = getmtime);print(listFiles[-2], end='');print(';',end='');print(listFiles[-1], end='');print(';',end='')\""		
		sprintf unixCmd, unixCmdBase, path, ext	
		sprintf igorCmd, "cmd.exe /C \"%s\"", unixCmd
	#else // MACINTOSH, python3 is for my Mac! You could use python instead
		unixCmdBase = "python3 -c \\\"from pathlib import Path;from os.path import getmtime;"\
					  + "listFiles = sorted(Path('%s').rglob('*%s'), "\
					  + "key = getmtime);print(listFiles[-2], end='');print(';',end='');print(listFiles[-1], end='');print(';',end='')\\\""	
		sprintf unixCmd, unixCmdBase, path, ext	
		sprintf igorCmd, "do shell script \"%s\" ", unixCmd
	#endif	
	
	ExecuteScriptText/Z/B/UNQ igorCmd
	//variable microSeconds = StopMSTimer(timerRefNum)
	//print "Time elapsed: ", microSeconds/1e6, " sec"
	return S_value
End