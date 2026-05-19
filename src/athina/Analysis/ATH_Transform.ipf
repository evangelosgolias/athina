#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Transform
#pragma version = 1.01

/// @module ATH_Transform
/// @brief Fourier and affine-transformation helpers for image processing.
/// @details
/// This module contains utility routines for 2D FFT generation, value scaling,
/// affine mapping estimation from three point pairs, and conversion of affine
/// coefficients into the parameter-wave format expected by Igor's image-registration tools.
///

/// @function FFT2D
/// @brief Compute the 2D FFT.
/// @details
/// Performs a 2D FFT, and stores the result in the source wave's data 
/// folder using the suffix `_FFT`.
/// @param wRef WAVE Input 2D wave.
/// @param [mode] Variable Optional FFT output mode:
/// mode = 1:	Default for complex output (default)
/// mode = 2:	Real output
/// mode = 3:	Magnitude
/// mode = 4:	Magnitude square
/// mode = 5:	Phase
/// mode = 6:	Scaled magnitude
/// mode = 7:	Scaled magnitude squared
/// @returns WAVE Reference to the generated FFT wave
///
static Function/WAVE FFT2D(WAVE wRef, [int mode])
	///
	/// FFT of a 2D wave
	///
    mode = ParamIsDefault(mode) ? 1 : mode 
	DFREF dfr = GetWavesDataFolderDFR(wRef)
	Duplicate/FREE wref, wRefFree
	Redimension/C wRefFree 	
	string  basenameStr = NameOfWave(wRef) + "_FFT"
	string destWaveNameStr = CreatedataObjectName(dfr, basenameStr, 1, 0, 1)
	// FFT - power spectrum (magnitude)
	FFT/OUT=(mode)/DEST=$destWaveNameStr wRefFree // dfr:$destWaveNameStr doesn't work
	return $destWaveNameStr
End

/// @function PhaseCorrelation
/// @brief Compute the phase correlation between two images.
/// @details
/// 
/// Add documentation here 
///
/// @param wRef WAVE Reference image
/// @param [mode] WAVE Test image
/// @returns /C Cmplx row (real) and col (imag) drift
///
static Function/C PhaseCorrelation(WAVE wRef, WAVE wTest, [variable subpixel, 
				   variable filter, variable smth])
	
	if (filter==1) 
	    ImageFilter findEdges wRef
		ImageFilter findEdges wTest
	elseif (filter==2) 
		ImageFilter sharpen wRef
		ImageFilter sharpen wTest
	endif
	
	//    Combine all these statements in a single MatrixOP operation
	//    FFT/OUT=1/DEST=fftR/WINF=Hanning wRef
	//	  FFT/OUT=1/DEST=fftT/WINF=Hanning wTest	
	//	  Combine all in one MatrixOP
	//    fftR = r2polar(fftR)
	//    fftT = r2polar(fftT)
	//    fftR = cmplx(1, imag(fftR)-imag(fftT))
	//    fftR = p2rect(fftR)
	//    IFFT/DEST=invFFT/R fftR
	//    ImageTransform Swap invfft // Put the cross-correalation peak at the center
	//    invfft = sqrt(invfft^2)	
	//
	
	MatrixOP/FREE/O invFFT = sqrt(powR(ifft(p2rect(cmplx(1, imag(r2polar(fft(wRef,1))) - imag(r2polar(fft(wTest,1))))), 5),2))
	
	if (smth)
		Smooth/DIM=0 (smth), invFFT
		Smooth/DIM=1 (smth), invFFT
	endif

	//Find local maximum
	ImageStats invFFT
	variable pdrift,qdrift
	variable rows = DimSize(wRef,0), cols = DimSize(wRef,1)
	if(subpixel)
		variable pmin, pmax, qmin, qmax, fitWidthPixels = max(10, max(rows, cols)*0.1)
		pmax = max(0,V_MaxRowLoc - fitWidthPixels)
		pmin = min(V_MaxRowLoc + fitWidthPixels, rows-1)
		qmax = max(0, V_MaxColLoc - fitWidthPixels)
		qmin = min(V_MaxColLoc + fitWidthPixels, cols-1)
		CurveFit/Q Gauss2D  invfft[pmin,pmax][qmin,qmax] /D 
		WAVE W_coef
		pdrift = rows/2 - W_coef[2]
		qdrift = cols/2 - W_coef[4]
	else
		pdrift = rows/2 - V_MaxRowLoc	
		qdrift = cols/2 - V_MaxColLoc
	endif
	KillWaves/Z W_coef, W_sigma
	return cmplx(pdrift,qdrift)
End

/// @function HighLowScale
/// @brief Scale wave values into a specified numeric range.
/// @details
/// Creates a new wave named `NameOfWave_scaled` using `MatrixOP scale(wRef, low, high)`.
/// @param wRef Wave Input wave to scale.
/// @param low Variable Lower bound of the target range
/// @param high Variable Upper bound of the target range
/// @returns Variable 0
///
Function HighLowScale(WAVE wRef, variable low, variable high)
    // Find min and max values of the wave
    string waveNormStr = NameOfWave(wRef)+"_scaled"
   	MatrixOP $waveNormStr = scale(wRef, low , high)
    return 0
End

/// @function GetAffine2DMapping
/// @brief Compute an affine transform from three source and destination point pairs.
/// @details
/// Solves for the six affine coefficients that map the three points in `src` onto
/// the corresponding three points in `dest`.
/// @param src Wave Six-element source coordinate wave `{x1,y1,x2,y2,x3,y3}`.
/// @param dest Wave Six-element destination coordinate wave `{X1,Y1,X2,Y2,X3,Y3}`.
/// @returns Wave Wave containing the affine transformation coefficients.
///
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

/// @function MakeImageRegistrationParamsWave
/// @brief Brief here.
/// @details
/// Add details here
/// @param wname String wPathName Path name for t
/// @returns Variable Returns 0 on completion.
///
static Function MakeImageRegistrationParamsWave(string wPathName, [variable nlayers])

	// wRef comes from the affine transformation matrix	
	// W_ParamsOut={xDrift,yDrift,0,invXscale,-ySkew,0,-xSkew,invYscale,0,0,0,1,0,0,0,0,0,0,0,0,0,0}
	//	0		dx			11		a33
	//	1		dy			12		gamma
	//	2		dz			13		phi
	//	3		a11			14		theta
	//	4		a12			15		psi
	//	5		a13			16		lambda
	//	6		a21			17		origin_x
	//	7		a22			18		origin_y
	//	8		a23			19		origin_z
	//	9		a31			20		MSE
	//	10		a32			21		SNR
	if(nlayers)
		Make/D/N=(22,nlayers) $wPathName
	else
		Make/D/N=22 $wPathName
	endif
	WAVE wRef = $wPathName
	SetDimLabel 0,0, dx,wRef;SetDimLabel 0,1, dy,wRef;SetDimLabel 0,2, dz,wRef
	SetDimLabel 0,3, a11,wRef;SetDimLabel 0,4, a12,wRef;SetDimLabel 0,5, a13,wRef
	SetDimLabel 0,6, a21,wRef;SetDimLabel 0,7, a22,wRef;SetDimLabel 0,8, a23,wRef
	SetDimLabel 0,9, a31,wRef;SetDimLabel 0,10, a32,wRef;SetDimLabel 0,11, a33,wRef
	SetDimLabel 0,12, gamma,wRef;SetDimLabel 0,13, phi,wRef;SetDimLabel 0,14, theta,wRef
	SetDimLabel 0,15, psi,wRef;SetDimLabel 0,16, lambda,wRef;SetDimLabel 0,17, origin_x,wRef
	SetDimLabel 0,18, origin_y,wRef;SetDimLabel 0,19, origin_z,wRef
	SetDimLabel 0,20, MSE,wRef;SetDimLabel 0,21, SNR,wRef
	return 0
End

/// @function MakeImageRegistrationParamsWave
/// @brief Convert affine coefficients to an image-registration parameter wave.
/// @details
/// Fills `W_ParamsOut` with the 22-element parameter layout used by Igor's
/// `ImageRegistration` operation, based on the affine coefficients in `wRef`.
/// @param wRef Wave Input wave containing affine transform coefficients.
/// @returns Variable Returns 0 on completion.
/// @note Creates `W_ParamsOut` if it does not already exist and overwrites its contents.
///
static Function MakeImageRegistrationParamsWaveForImageRegistration(WAVE wRef)

	// wRef comes from the affine transformation matrix	
	// W_ParamsOut={xDrift,yDrift,0,invXscale,-ySkew,0,-xSkew,invYscale,0,0,0,1,0,0,0,0,0,0,0,0,0,0}
	//	0		dx			11		a33
	//	1		dy			12		gamma
	//	2		dz			13		phi
	//	3		a11			14		theta
	//	4		a12			15		psi
	//	5		a13			16		lambda
	//	6		a21			17		origin_x
	//	7		a22			18		origin_y
	//	8		a23			19		origin_z
	//	9		a31			20		MSE
	//	10		a32			21		SNR
	WAVE/D/Z W_ParamsOut
	if(!WaveExists(W_ParamsOut))
		Make/O/D/N=22 W_ParamsOut
		SetDimLabel 0,0, dx,W_ParamsOut;SetDimLabel 0,1, dy,W_ParamsOut;SetDimLabel 0,2, dz,W_ParamsOut
		SetDimLabel 0,3, a11,W_ParamsOut;SetDimLabel 0,4, a12,W_ParamsOut;SetDimLabel 0,5, a13,W_ParamsOut
		SetDimLabel 0,6, a21,W_ParamsOut;SetDimLabel 0,7, a22,W_ParamsOut;SetDimLabel 0,8, a23,W_ParamsOut
		SetDimLabel 0,9, a31,W_ParamsOut;SetDimLabel 0,10, a32,W_ParamsOut;SetDimLabel 0,11, a33,W_ParamsOut
		SetDimLabel 0,12, gamma,W_ParamsOut;SetDimLabel 0,13, phi,W_ParamsOut;SetDimLabel 0,14, theta,W_ParamsOut
		SetDimLabel 0,15, psi,W_ParamsOut;SetDimLabel 0,16, lambda,W_ParamsOut;SetDimLabel 0,17, origin_x,W_ParamsOut
		SetDimLabel 0,18, origin_y,W_ParamsOut;SetDimLabel 0,19, origin_z,W_ParamsOut
		SetDimLabel 0,20, MSE,W_ParamsOut;SetDimLabel 0,21, SNR,W_ParamsOut
	endif
	W_ParamsOut={wRef[4],wRef[5],0,1/wRef[0],-wRef[3],0,-wRef[2],1/wRef[1],0,0,0,1,0,0,0,0,0,0,0,0,0,0}
	return 0
End


//Function D_ResolveDistMatrix(V_1,V_2)
//	wave V_1,V_2  
//	
//	//calculate the distortion matrix components by solving a linear system of equations
//	//V_1 and V_2 are the undistorted and distorted vectors in the form:
//	//{x1,y1,x2,y2,x3,y3}, where xn,yn is the n-vector 
//	//the components of the undistorted vector V_1 are put into the matrix M_input that defines the linear system 
//	                          
//	variable x1=V_1[0],y1=V_1[1],x2=V_1[2],y2=V_1[3],x3=V_1[4],y3=V_1[5]
//	
//	make/O M_input={{x1,0,x2,0,x3,0},{0,y1,0,y2,0,y3},{0,x1,0,x2,0,x3},{y1,0,y2,0,y3,0},{1,0,1,0,1,0},{0,1,0,1,0,1}}
//	
//	matrixLinearSolve/Z M_input,V_2
//	//solution is in M_b
//	
//	return V_flag
//End



//Function D_Distort(wImage,W_ParamsIn,M_RoiMask)
//	wave wImage,W_ParamsIn,M_RoiMask
//	//apply the distortion to the image using imageregistration 
//	//the roimask should be Single Precision and have non-zero numbers in the selected area
//	//normally we do the opposite, so you should invert the mask (M_roiTmp= !M_roiMask[p][q])
//	
//	//duplicate/O/S M_roiMask M_roiTmp
//	//M_roiTmp = (M_roiMask[p][q]==0)
//	
//	if ((wavetype(wImage)==2)&&(wavetype(W_ParamsIn)==4)&&(wavetype(M_RoiMask)==2))
//		imageregistration/Q/CONV=1/USER=W_ParamsIn testMask=M_roiMask  testWave=wImage
//	else 
//		duplicate/O wImage, wImageS
//		duplicate/O M_RoiMask, M_RoiS
//		redimension/S wImageS,M_Rois
//		duplicate/O W_ParamsIn, W_ParamsInD
//		redimension/D W_ParamsInD	
//		imageregistration/Q/CONV=1/CSNR=0/USER=W_ParamsInD testMask=M_roiS testWave=wImageS
//		killwaves W_paramsInD
//	endif
//	
//	//killwaves M_roiTmp
//	
//	//wave/Z M_RegOut
//	OP_CleanNan(M_RegOut)   //testMask=M_roiMask 
//End	



// TODO: FIXME
// A quick solution for affineTransform
// It does not work well, fix it


//static Function AffineTransformationThreePoints()
//	// Launch a panel and select two images, src and dest
//	// Use cursors A, B & C to mark three points
//	// Use the affine transform to the dest wrt src image
//	// *_affine2d in created.
//	
//	
//	string msg = "Select two 2d waves (images). Use Ctrl (Windows) or Cmd (Mac)."
//	string selectedWavesInBrowserStr = ATH_Dialog#SelectWavesInModalDataBrowser(msg)
//	// S_fileName is a carriage-return-separated list of full paths to one or more files.
//	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
//	string selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
//	string wave1NameStr = StringFromList(0, selectedWavesStr)
//	string wave2NameStr = StringFromList(1, selectedWavesStr)
//	if(nrSelectedWaves != 2 || WaveDims($wave1NameStr) != 2 || WaveDims($wave2NameStr) != 2)
//		DoAlert/T="athina would like you to know that you have to ..." 1, "Please " +\
//				  "select two images, i.e two 2d waves, non-RGB. \n" + \
//				  "Do you want a another chance with the browser selection?"
//		if(V_flag == 1)
//			AffineTransformationThreePoints()
//			return 0 
//		elseif(V_flag > 1)
//			Abort
//		endif
//	endif
//	
//	Prompt wave1NameStr, "src", popup, selectedWavesStr
//	Prompt wave2NameStr, "dest", popup, selectedWavesStr
//	DoPrompt "dest image will be transformed wrt to src", wave1NameStr, wave2NameStr
//	if(V_flag) // User cancelled
//		return -1
//	endif
//	
//	WAVE wImg1 =  $wave1NameStr // src
//	WAVE wImg2 = $wave2NameStr  // dest
//	string winNameStr1 = UniQueName("Affine_src", 6, 0) // T
//	string winNameStr2 = UniQueName("Affine_dest", 6, 0)	
//	ATH_Display#NewImg(wImg1, grfName = winNameStr1)
//	ATH_Display#NewImg(wImg2, grfName = winNameStr2)
//	// Transfer to the hook the dest wave
//	SetWindow $winNameStr1 userdata(destWavePathStr) = wave2NameStr
//	SetWindow $winNameStr2 userdata(destWavePathStr) = wave2NameStr	
//	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Affine2D_3pnts")
//	variable/G dfr:gATH_pntN = NaN 	
//	Make/O/N=3/D dfr:srcX, dfr:srcY; WAVE srcX = dfr:srcX; WAVE srcY = dfr:srcY
//	variable xOff = DimOffset(wImg1, 0), dx = DimDelta(wImg1, 0), xN = DimSize(wImg1, 0)
//	variable yOff = DimOffset(wImg1, 1), dy = DimDelta(wImg1, 1), yN = DimSize(wImg1, 1)
//	srcX[0] = xOff + 0.25 * xN * dx
//	srcY[0] = yOff + 0.25 * yN * dy
//	srcX[1] = xOff + 0.5 * xN * dx
//	srcY[1] = yOff + 0.5 * yN * dy
//	srcX[2] = xOff + 0.75 * xN * dx
//	srcY[2] = yOff + 0.75 * yN * dy
//	AppendToGraph/W=$winNameStr1 /T srcY vs srcX
//	ModifyGraph/W=$winNameStr1 mode=3,msize=5
//	Make/O/N=3/D dfr:destX, dfr:destY; WAVE destX = dfr:destX; WAVE destY = dfr:destY
//	xOff = DimOffset(wImg2, 0); dx = DimDelta(wImg2, 0); xN = DimSize(wImg2, 0)
//	yOff = DimOffset(wImg2, 1); dy = DimDelta(wImg2, 1); yN = DimSize(wImg2, 1)
//	SetWindow $winNameStr1,hook(DragTheMarkers) = ATH_Launch#Affine2DWindowHook // Set the hook
//	
//	destX[0] = xOff + 0.25 * xN * dx
//	destY[0] = yOff + 0.25 * yN * dy
//	destX[1] = xOff + 0.5 * xN * dx
//	destY[1] = yOff + 0.5 * yN * dy
//	destX[2] = xOff + 0.75 * xN * dx
//	destY[2] = yOff + 0.75 * yN * dy
//	AppendToGraph/W=$winNameStr2 /T destY vs destX
//	ModifyGraph/W=$winNameStr2 mode=3,msize=5,rgb=(0,65535,65535)
//	SetWindow $winNameStr2,hook(DragTheMarkers) = ATH_Launch#Affine2DWindowHook // Set the hook	
//End
//
//static Function Affine2DWindowHook(STRUCT WMWinHookStruct &s)
//	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Affine2D_3pnts")
//	WAVE/SDFR=dfr srcX, srcY, destX, destY
//	NVAR/SDFR=dfr gATH_pntN
//	variable hookResult
//
//	switch (s.eventCode)
//		case 3:
//			gATH_pntN = str2num(StringByKey("HITPOINT",TraceFromPixel(s.mouseLoc.h,s.mouseLoc.v,""),":"))
//			hookResult = 1 // 1 here supresses long press, INTENTIONAL ... but also right click!
//			break
//		case 4:
//			if(!numtype(gATH_pntN))
//				if(StringMatch(s.winName, "Affine_src*"))
//					srcX[gATH_pntN] = AxisValFromPixel(s.winName, "top", s.mouseLoc.h)
//				 	srcY[gATH_pntN] = AxisValFromPixel(s.winName, "left", s.mouseLoc.v)
//				elseif(StringMatch(s.winName, "Affine_dest*"))
//					destX[gATH_pntN] = AxisValFromPixel(s.winName, "top", s.mouseLoc.h)
//				 	destY[gATH_pntN] = AxisValFromPixel(s.winName, "left", s.mouseLoc.v)
//				endif
//			endif
//			hookResult = 1 // 1 here supresses the marquee. INTENTIONAL
//			break
//		case 5:
//			gATH_pntN = NaN
//			break
//		case 2: // kill
//			// If you are not in a duplicate window
//			break
//	endswitch
//	
//	if(s.specialKeyCode)
//		switch(s.specialKeyCode)
//			case 200: // Enter or Return
//			case 201:
//				if(WaveExists(srcX))
//					Make/N=6/FREE scrF = {srcX[0],srcY[0],srcX[1],srcY[1],srcX[2],srcY[2]}
//					Make/N=6/FREE destF = {destX[0],destY[0],destX[1],destY[1],destX[2],destY[2]}
//					WAVE wC = ATH_Transform#GetAffine2DMapping(scrF,destF)
//					if(numtype(wC[0]))
//						break
//					endif
//				endif
//				string destWaveStr = GetUserData(s.winName, "", "destWavePathStr")
//				ImageInterpolate/APRM={wC[0],wC[1],wC[2],wC[3],wC[4],wC[5],1,0}/DEST=Affine_3pnts Affine2D $destWaveStr
//				WAVE Affine_3pnts
//				Note Affine_3pnts, "Original wave: " + destWaveStr
//				break
//		endswitch
//	endif
//	return hookResult
//End
