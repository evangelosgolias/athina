#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3                           // Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}           // Set default tab width in Igor Pro 9 and later
#pragma IgorVersion  = 9
#pragma ModuleName = ATH_Export

static function TracesToGeneralTextDB()
	// Export all traces selected in Data Browser

	if(!strlen(GetBrowserSelection(0)))
		return 1
	endif
	string wname
	variable i = 0
	NewPath/Q/O/M="Select folder to export traces..." ATH_EXPORT_TRACES_PATH
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
		Save/G/M="\n"/P=ATH_EXPORT_TRACES_PATH wavescaleFree, wRef as NameOfWave(wRef)
		i++
	while(strlen(GetBrowserSelection(i)))
	KillPath/Z ATH_EXPORT_TRACES_PATH
	return 0
end
