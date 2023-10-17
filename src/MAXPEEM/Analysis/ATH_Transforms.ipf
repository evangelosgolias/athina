#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function ATH_2DFFT(WAVE wRef)
	/// FFT of a 2D wave
	
	Duplicate/FREE wref, wRefFree
	//MatrixFilter/N=5 gauss, wRefFree	
	Redimension/C wRefFree 	
	string destWaveNameStr = NameOfWave(wRef) + "_FFT"
	//ImageFilter/N=3/P=2 gauss wRefFree
	FFT/OUT=3/DEST=$destWaveNameStr wRefFree
End