#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Transform
#pragma version = 1.01

static Function/WAVE FFT2D(WAVE wRef)
	/// FFT of a 2D wave
	DFREF dfr = GetWavesDataFolderDFR(wRef)
	Duplicate/FREE wref, wRefFree
	Redimension/C wRefFree 
	string  basenameStr = NameOfWave(wRef) + "_FFT"
	string destWaveNameStr = CreatedataObjectName(dfr, basenameStr, 1, 0, 1)
	//ImageFilter/N=3/P=2 gauss wRefFree
	FFT/OUT=3/DEST=$destWaveNameStr wRefFree // dfr:$destWaveNameStr doesn't work
	return $destWaveNameStr
End