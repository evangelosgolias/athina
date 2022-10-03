#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function MXP_Make3DWaveUsingPattern(String wname3d, String pattern)
	// Make a 3d wave named wname3d using the RegEx pattern
	// Give "*" to match all waves

	String ListofMatchedWaves = WaveList(pattern, ";", "")
	Variable nrwaves = ItemsInList(ListofMatchedWaves)
	if(!nrwaves)
		Abort "No matching 2D waves"
	endif
	Wave wref = $(StringFromList(0,ListofMatchedWaves))
	Variable nx = DimSize(wref,0)
	Variable ny = DimSize(wref,1)

	Make/N = (nx, ny, nrwaves) $wname3d /WAVE = w3dref
	Variable ii

	for(ii = 0; ii < nrwaves; ii += 1)
		Wave t2dwred = $(StringFromList(ii,ListofMatchedWaves))
		w3dref[][][ii] = t2dwred[p][q]
	endfor
End

Function MXP_Make3DWaveDataBrowserSelection(String wname3d)

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

	variable i = 0
	do
		if(strlen(GetBrowserSelection(i)))
			listOfSelectedWaves += GetBrowserSelection(i) + ";" // Match stored at S_value
		endif
		i++
	while (strlen(GetBrowserSelection(i)))

	if (!strlen(listOfSelectedWaves))
		return -1 // No wave selected
	endif

	Variable nrwaves = ItemsInList(listOfSelectedWaves)

	String wname = StringFromList(0,listOfSelectedWaves)

	Wave wref = $wname
	Variable nx = DimSize(wref,0)
	Variable ny = DimSize(wref,1)

	Make/N = (nx, ny, nrwaves) $wname3d /WAVE = w3dref

	for(i = 0; i < nrwaves; i += 1)
		Wave t2dwred = $(StringFromList(i,listOfSelectedWaves))
		w3dref[][][i] = t2dwred[p][q]
	endfor

End