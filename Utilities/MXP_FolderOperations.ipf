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
