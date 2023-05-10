#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function MXP_2DFFT(WAVE wRef)
	/// FFT of a 2D wave
	
	// WaveStats/M=1/Q wRef
	variable nrows = MXP_NextPowerOfTwo(DimSize(wRef, 0))
	variable ncols = MXP_NextPowerOfTwo(DimSize(wRef, 1))	
	Make/D/FREE/N=(nrows, ncols) wRefFree
	CopyScales/I wRef, wRefFree
	wRefFree = interp2D(wRef, x, y)
	// wRefFree -= V_avg // subtract the average first
	// We need a complex wave to get the FFT at the center of the image (pos and neg frequencies)	
	Redimension/C wRefFree 	
	string destWaveNameStr = NameOfWave(wRef) + "_FFT"
	FFT/OUT=3/WINF=Hanning/DEST=$destWaveNameStr wRefFree
End