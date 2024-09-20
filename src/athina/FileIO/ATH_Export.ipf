#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3                           // Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}           // Set default tab width in Igor Pro 9 and later
#pragma IgorVersion  = 9
#pragma ModuleName = ATH_Export

static function WavesToTIFFDB([int byte32])
	// Export all traces selected in Data Browser
	byte32 = ParamIsDefault(byte32) ? 1 : byte32 // Use max 32 bits per pixel -- Default TRUE
	if(!strlen(GetBrowserSelection(0)))
		return 1
	endif
	string wname
	variable i = 0
	NewPath/Q/O/M="Select folder to export traces..." ATH_EXPORT_IMAGES_PATH__
	do
		wname = GetBrowserSelection(i)
		WAVE wRef = $wname
		if(!WaveExists(wRef))
			break
		elseif(WaveDims(wRef) == 1 || WaveDims(wRef) == 4)
			i++
			continue
		endif
		int bytesN = ATH_WaveOp#GetWaveType(wRef)
		if(byte32 && bytesN > 32)
			bytesN = 32
		endif
		if(WaveDims(wRef) == 2)
			ImageSave/DS=(bytesN)/P=ATH_EXPORT_IMAGES_PATH__ wRef as NameOfWave(wRef) // /T omitted so .itff
		endif
		if(WaveDims(wRef) == 3)
			ImageSave/S/DS=(bytesN)/P=ATH_EXPORT_IMAGES_PATH__ wRef as NameOfWave(wRef)
		endif		
		i++
	while(strlen(GetBrowserSelection(i)))
	KillPath/Z ATH_EXPORT_IMAGES_PATH__
	return 0
end

static function Wave3DToTIFFsDB([int byte32])
	// Export all layers of a 3D wave to a folder
	byte32 = ParamIsDefault(byte32) ? 0 : byte32  // Use max 32 bits per pixel -- Default TRUE

	if(!strlen(GetBrowserSelection(0)))
		return 1
	endif
	string wname
	NewPath/Q/O/M="Select folder to export traces..." ATH_EXPORT_IMAGES_PATH__
	wname = GetBrowserSelection(0)
	WAVE wRef = $wname
	variable nLayers = DimSize(wRef, 2), i, bytesN
	if(!WaveExists(wRef) || !nLayers)
		return 1
	endif
	for(i = 0; i < nLayers; i++)		
		bytesN = ATH_WaveOp#GetWaveType(wRef)
		if(byte32 && bytesN > 32)
			bytesN = 32
		endif		
		MatrixOP/FREE layerFree = layer(wRef, i)
		ImageSave/DS=(bytesN)/P=ATH_EXPORT_IMAGES_PATH__ layerFree as (NameOfWave(wRef)+"_"+num2str(i)) // /T omitted so .itff
	endfor
	KillPath/Z ATH_EXPORT_IMAGES_PATH__
	return 0
end

static function TracesToGeneralTextDB()
	// Export all traces selected in Data Browser

	if(!strlen(GetBrowserSelection(0)))
		return 1
	endif
	string wname
	variable i = 0
	NewPath/Q/O/M="Select folder to export traces..." ATH_EXPORT_TRACES_PATH__
	do
		wname = GetBrowserSelection(i)
		WAVE wRef = $wname
		if(!WaveExists(wRef))
			break
		elseif(WaveDims(wRef) != 1)
			i++
			continue
		endif
		Duplicate/FREE/O wRef, wavescaleFree
		wavescaleFree = x
		Save/G/M="\n"/P=ATH_EXPORT_TRACES_PATH__ wavescaleFree, wRef as NameOfWave(wRef)
		i++
	while(strlen(GetBrowserSelection(i)))
	KillPath/Z ATH_EXPORT_TRACES_PATH__
	return 0
end
