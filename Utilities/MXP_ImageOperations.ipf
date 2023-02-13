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

Function MXP_NormaliseImageStackWithImage(WAVE w3dRef, WAVE w2dRef)
	// If you have 16-bit waves then Redimension/S to SP
	if(WaveType(w3dRef) == 80 || WaveType(w3dRef) == 16)
		Redimension/S w3dRef
	endif
	if(WaveType(w2dRef) == 80 || WaveType(w2dRef) == 16)
		Redimension/S w2dRef
	endif
	string normWaveStr = NameOfWave(w3dRef) + "_norm"
	MatrixOP/O $normWaveStr = w3dRef / w2dRef
End

Function MXP_NormaliseImageStackWithImageStack(WAVE w3dRef1, WAVE w3dRef2)
	// If you have 16-bit waves then Redimension/S to SP
	if(WaveType(w3dRef1) == 80 || WaveType(w3dRef1) == 16)
		Redimension/S w3dRef1
	endif
	if(WaveType(w3dRef2) == 80 || WaveType(w3dRef2) == 16)
		Redimension/S w3dRef2
	endif
	string normWaveStr = NameOfWave(w3dRef1) + "_norm"
	MatrixOP/O $normWaveStr = w3dRef1 / w3dRef2
End

Function MXP_NormaliseImageStackWithProfile(WAVE w3dRef, WAVE profWaveRef)
	// Normalise a 3d wave (stack) with a line profile (1d wave) along the layer (z) direction
	if(WaveType(w3dRef) == 80 || WaveType(w3dRef) == 16)
		Redimension/S w3dRef
	endif
	if(WaveType(profWaveRef) == 80 || WaveType(profWaveRef) == 16)
		Redimension/S profWaveRef
	endif
		
	string normWaveStr = NameOfWave(w3dRef) + "_norm"
	variable nlayers = DimSize(w3dRef, 2) 
	variable npnts = DimSize(profWaveRef, 0)
	
	if(nlayers != npnts)
		Duplicate/O/FREE profWaveRef, profWaveRefFREE
		Redimension/N=(1, 1, nlayers) profWaveRefFREE
		if(nlayers > npnts)
			profWaveRefFREE[0][0][npnts,] = profWaveRef[npnts-1]
			MatrixOP/O $normWaveStr = w3dRef * rec(profWaveRefFREE)
		else
			profWaveRefFREE = profWaveRef[r]
			MatrixOP/O $normWaveStr = w3dRef * rec(profWaveRefFREE)
		endif
		return 0
	else 
		Duplicate/O/FREE profWaveRef, profWaveRefFREE
		Redimension/N=(1, 1, nlayers) profWaveRefFREE
		MatrixOP/O $normWaveStr = w3dRef * rec(profWaveRefFREE)
		return 0
	endif
End

Function MXP_GetLayerFromImageStack()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string msg
	NVAR gLayer = root:Packages:WM3DImageSlider:$(winNameStr):gLayer	
	if(NVAR_Exists(gLayer) && WaveDims(w3dref) == 3)
		string layerSaveStr = NameOfWave(w3dref) + "_layer_" + num2str(gLayer)
		MatrixOP/O $layerSaveStr = layer(w3dref, gLayer)
		sprintf msg, "Slice %d from wave %s", gLayer, imgNameTopGraphStr
		CopyScales/I w3dref, $layerSaveStr
		Note $layerSaveStr, msg
	else
		Abort "Operation needs a stack (3d wave) with a slider activated"
	endif
End

Function MXP_StackImageToImageStack(WAVE w3dref, WAVE w2dRef)
	if((DimSize(w3dref, 0) == DimSize(w2dRef, 0)) && DimSize(w3dref, 1) == DimSize(w2dRef, 1))
		variable lastLayerNr = DimSize(w3dRef, 2)
		if(lastLayerNr)
			ImageTransform/O/INSW=w2dref/P=(lastLayerNr) insertZplane w3dRef
		endif
	else
		Abort "Image and stack must have the same lateral dimensions."
	endif
End