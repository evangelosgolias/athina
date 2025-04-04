#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Transform
#pragma version = 1.01



Function/WAVE GetAffine2DMapping(WAVE src, WAVE dest)

	// Calculate an affine transformation that maps img0 to img1.
	// The mapping is calculated based on three points (x, y) from 
	// img0 (x) and and three img1 (X).
	// We have (X1;X2;X3;Y1;Y2;Y3) = (B, 0 ; 0, B) * (a11,a12,tx,a21,a22,ty)
	// Where B = (x1,y1,1; x2,y2,1; x3,y3,1).
	//
	// src : (x1,y1,x2,y2,x3,y3)
	// dest: (X1,Y1,X2,Y2,X3,Y3)
	//
	// res: a7 = a8 = 0 & a9 = 1
	//
	//      | a1 a2 a3 |
	//  A = | a4 a5 a6 |
    //  	| a7 a8 a9 |	
	//
	// https://stackoverflow.com/questions/1114257/transform-a-triangle-to-another-triangle
	Make/FREE srcM = {src[0],src[2],src[4],src[1],src[3],src[5]}
	Make/FREE destM = {{dest[0],dest[2],dest[4],0,0,0},{dest[1],dest[3],dest[5],0,0,0},{1,1,1,0,0,0},\
					   {0,0,0,dest[0],dest[2],dest[4]},{0,0,0,dest[1],dest[3],dest[5]},{0,0,0,1,1,1}}
	MatrixOP/FREE res = inv(destM) x srcM
	
	return res
	
End


static Function/WAVE FFT2D(WAVE wRef)
	///
	/// FFT of a 2D wave
	///
	DFREF dfr = GetWavesDataFolderDFR(wRef)
	Duplicate/FREE wref, wRefFree
	Redimension/C wRefFree 
	string  basenameStr = NameOfWave(wRef) + "_FFT"
	string destWaveNameStr = CreatedataObjectName(dfr, basenameStr, 1, 0, 1)
	//ImageFilter/N=3/P=2 gauss wRefFree
	FFT/OUT=3/DEST=$destWaveNameStr wRefFree // dfr:$destWaveNameStr doesn't work
	return $destWaveNameStr
End