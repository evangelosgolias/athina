#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function MXP_ScaleImage() // Uses top graph
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE waveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable getScaleXY
	string cmdStr = "0, 0", setScaleZStr
	string msgDialog = "Scale Z direction of stack"
	string strPrompt = "Set firstVal,  lastVal in quotes (string).\n Leave \"\"  and press continue for autoscaling."
	if(WaveDims(waveRef) == 2)
		getScaleXY = NumberByKey("FOV(µm)", note(waveRef), ":", "\n")
		if(numtype(getScaleXY) == 2)
			getScaleXY = 0
		endif
		SetScale/I x, 0, getScaleXY, waveRef
		SetScale/I y, 0, getScaleXY, waveRef
	elseif(WaveDims(waveRef) == 3)
		// We deal with the x, y scale when we import the wave
		//getScaleXY = NumberByKey("FOV(µm)", note(waveRef), ":", "\n")
		//SetScale/I x, 0, getScaleXY, waveRef
		//SetScale/I y, 0, getScaleXY, waveRef
		DoWindow/F $winNameStr
		setScaleZStr = MXP_GenericSingleStrPrompt(strPrompt, msgDialog)
		string dataPathStr = GetWavesDataFolder(waveRef, 2)
		if(strlen(setScaleZStr))
		cmdStr = "SetScale/I z " + setScaleZStr + ", " + dataPathStr
		Execute/Z cmdStr
		endif
	endif
End

Function MXP_ImageSelectToCopyScale() // Uses top graph
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	// Select the first wave from browser selection
	string selectedWavesStr = MXP_SelectWavesInModalDataBrowser("Select an image to set common dimension scaling")
	string firstWaveStr = StringFromList(0, selectedWavesStr)
	CopyScales/I $firstWaveStr, $imgNameTopGraphStr // NB Use P if have an extended image with common parts
End

Function MXP_Wave2RGBImage(WAVE wRef)
	ColorTab2Wave Grays
	WAVE M_Colors
	Wavestats/Q/M=1 wRef
	SetScale/I x, V_min, V_max, M_Colors
	ImageTransform/C=M_Colors cmap2rgb wRef
	WAVE M_RGBOut
	KillWaves/Z M_Colors
	string newnameStr = NameOfWave(wRef) + "_RGB"
	Rename M_RGBOut, $newnameStr
End

Function MXP_NormaliseImageStackWithProfile()
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE w3d = ImageNameToWaveRef(winNameStr, imgNameTopGraphStr)
	// Normalisation does not work if the image stack is Uint16.
	// Check if this is the case and Redimension/S the 3D wave
	if(WaveDims(w3d) != 3)
		print "Operation needs a image stack (3d wave) in top graph!"
		return -1
	endif
	
	if(WaveType(w3d) == 80) // if UInt16 (0x50)
		Redimension/S w3d
	endif
	// Select the profile wave from browser
	string selectedWavesStr = MXP_SelectWavesInModalDataBrowser("Select profile to normalise image stack")
	string profileWaveStr = StringFromList(0, selectedWavesStr)
	WAVE profWave = $profileWaveStr
	MXP_Normalise3DWaveWithProfile(w3d, profWave)
	return 0
End