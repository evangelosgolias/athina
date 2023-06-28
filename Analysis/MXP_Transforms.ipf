#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function MXP_2DFFT(WAVE wRef)
	/// FFT of a 2D wave
	
	Duplicate/FREE wref, wRefFree
	Redimension/C wRefFree 	
	string destWaveNameStr = NameOfWave(wRef) + "_FFT"
	FFT/OUT=3/WINF=Hanning/DEST=$destWaveNameStr wRefFree
End