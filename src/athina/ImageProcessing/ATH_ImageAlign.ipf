#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_ImgAlign
#pragma version = 1.1

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


/// @module ATH_ImageAlign
/// @brief Module ATH_ImageAlign.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH ImageAlign functionality.

/// @function LinearDriftStackABCursors
/// @brief Correct linear drift through a stack using the displacement between cursors A and B.
/// @details
/// Linear drift correction w3d using wx and wy displacements. Drifts for ImageInterpolate should be in
/// pixels. Restore scale here.
/// @param w3d Input 3D wave or image stack.
/// @param wx Wave containing x drift or displacement values.
/// @param wy Wave containing y drift or displacement values.
/// @param intPx (optional) If nonzero, round calculated displacements to integer pixels.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function LinearDriftStackABCursors(WAVE w3d, WAVE wx, WAVE wy, [int intPx])
	/// Linear drift correction w3d using wx and wy displacements

	intPx = ParamIsDefault(intPx) ? 1 : intPx
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	variable i
	variable nlayers = DimSize(w3d, 2)
	variable nx = DimSize(wx, 0)
	variable ny = DimSize(wy, 0)
	if(!(nlayers == nx && nx == ny))
		return -1
	endif
	variable dx, dy
	// Drifts for ImageInterpolate should be in pixels.
	
	DFREF saveDF = GetWavesDataFolderDFR(w3d)
	DFREF currDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	MatrixOP/O getStacklayer_0 = layer(w3d, 0)
	
	for(i = 1; i < nlayers; i++)
		dx = intPx ? round(wx[i]) : wx[i]
		dy = intPx ? round(wy[i]) : wy[i]
		MatrixOP/O/FREE targetLayer = layer(w3d, i)
		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=$("getStacklayer_" + num2str(i)) Affine2D targetLayer
	endfor

	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales w3d, M_Stack
	Duplicate/O M_Stack, saveDF:$NameofWave(w3d)
	SetDataFolder currDF
	return 0
End

/// @function LinearDriftPlanesABCursors
/// @brief Correct linear drift over selected stack layers using cursors A and B.
/// @details
/// Linear drift correction w3d using wx and wy displacements WAVE wx - x coordinates WAVE wy - y
/// coordinates.
/// @param w3d Input 3D wave or image stack.
/// @param wx Wave containing x drift or displacement values.
/// @param wy Wave containing y drift or displacement values.
/// @param startL (optional) Lower or starting start l.
/// @param endL (optional) Upper or ending end l.
/// @param intPx (optional) If nonzero, round calculated displacements to integer pixels.
/// @returns Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.
static Function LinearDriftPlanesABCursors(WAVE w3d, WAVE wx, WAVE wy, [variable startL, variable endL, int intPx])
	/// Linear drift correction w3d using wx and wy displacements
	/// WAVE wx - x coordinates
	/// WAVE wy - y coordinates
	/// variable startL: start layer
	/// variable endL: end layer
	/// variable endL: use integer pixel drifts
	///
	/// Note: wx, wy: in pixels, not scaled coordinates
	/// We extract and restack all layers. Much faster 
	/// compared to RemovePlaneZ/InsertPlaneZ  
	variable nlayers = DimSize(w3d, 2)	
	startL = ParamIsDefault(startL) ? 0 : startL
	endL = (ParamIsDefault(endL) || endL >= nlayers)? (nlayers-1) : endL
	intPx = ParamIsDefault(intPx) ? 1 : intPx
	
	if(startL >= endL)
		return -1
	endif

	if(!(WaveType(w3d) & 0x02 || WaveType(w3d) & 0x04))
		Redimension/S w3d
	endif
	
	variable nx = DimSize(wx, 0)
	variable ny = DimSize(wy, 0)
	variable nL = endL - startL + 1
	if(!(nL == nx && nx == ny))
		return -1
	endif
	
	variable dx, dy, i
	// Drifts for ImageInterpolate should be in pixels.
	
	DFREF saveDF = GetWavesDataFolderDFR(w3d)
	DFREF currDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	variable cnt = 0
	for(i = 0; i < nlayers; i++)
		if(i >= startL && i <= endL)
			dx = intPx ? round(wx[cnt]) : wx[cnt]
			dy = intPx ? round(wy[cnt]) : wy[cnt]
			MatrixOP/O targetLayer = layer(w3d, i)
			ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=$("getStacklayer_" + num2str(i)) Affine2D targetLayer
			cnt++
		else
			MatrixOP/O $("getStacklayer_" + num2str(i)) = layer(w3d, i)
		endif
	endfor
	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"	
	WAVE M_Stack
	CopyScales w3d, M_Stack
	Duplicate/O M_Stack, saveDF:$NameofWave(w3d)
	SetDataFolder currDF
	return 0
End

/// ----------------------------- Multithreading ----------------------------- ///

// // Multithreaded Drift Correction using Correlation

/// @function MultiThreadCorrelationDriftCorrection
/// @brief Measure stack drift by multithreaded image correlation.
/// @details
/// Uses either normalized real-space correlation or phase correlation against a reference layer, then replaces
/// the input stack with the aligned layers. Saved drift values are expressed in pixels.
/// @param w3D Input 3D image stack.
/// @param w3DPart Preprocessed or cropped stack used to estimate alignment.
/// @param layerN Zero-based image-stack layer index.
/// @param saveDrift (optional) If nonzero, save the calculated per-layer drift parameters.
/// @param subpixel (optional) If nonzero, refine correlation peaks with a two-dimensional Gaussian fit.
/// @param method (optional) Algorithm or processing method.
/// @returns Zero after replacing the source stack with the aligned result.
static Function MultiThreadCorrelationDriftCorrection(WAVE w3D, 
	 WAVE w3DPart, variable layerN, [variable saveDrift, variable subpixel, variable method])
	// method 0 - real correlation
	// method 1 - phase correlation
	if(!(WaveType(w3D) & 0x02))
		Redimension/S w3D
	endif
	if(!(WaveType(w3DPart) & 0x02))
		Redimension/S w3DPart
	endif
	
	// Create a wave to hold wave references returned by DriftCorrelation_Worker.
	variable numPlanes = DimSize(w3D,2)
	Make/WAVE/N=(numPlanes) ww	
	
	if(saveDrift)
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(skATH_SaveImageStackDriftCorrections)
		Make/D/O/N=(2, numPlanes) dfr:ath_driftCorr /WAVE = wDC
		string noteStr = "Apply drift corrections: " + StringFromList(method, "Correlation (Real);Correlation(Phase)")
		noteStr += "with reference layer #"+num2str(layerN) + " of " + GetWavesDataFolder(w3D, 2)
		if(subpixel)
			noteStr += " using subpixel resolution.\n"
		else
			noteStr +=  " using pixel resolution.\n"
		endif
		Note/K wDC, noteStr
	else 
		WAVE wDC = $""
	endif

	// Get the reference layer from the partitioned wave
	ImageTransform/P=(layerN) getPlane w3DPart
	WAVE M_ImagePlane // Reference layer
	
	// Release the threads.
	MultiThreadingControl setMode=0
	if(method)		
		MatrixOP/FREE refImagPhase = imag(r2polar(fft(M_ImagePlane,2)))
		MultiThread ww = DriftPhaseCorrelationPartition_Worker(w3D, w3dPart, refImagPhase, p, wDC, subpixel = subpixel)			
	else
		MatrixOP/FREE refImg = scale(M_ImagePlane, 0 , 1)//M_ImagePlane - mean(M_ImagePlane)
		variable refP = DimSize(refImg,0)/2, refQ = DimSize(refImg,1)/2
		MultiThread ww = DriftCorrelationPartition_Worker(w3D, w3dPart, refImg, refP, refQ, p, wDC, subpixel = subpixel)			
	endif
	MultiThreadingControl setMode=1	
	// At this point, ww holds wave references to numplanes free waves
	// created by DriftCorrelation_Worker.
	// So, now repack all layers.
	Concatenate/O {ww}, $GetWavesDataFolder(w3D,2)
	// ww holds references to the free waves. By killing ww, we kill
	// the last reference to the free waves which causes them to be
	// automatically deleted.
	KillWaves/Z ww, M_ImagePlane
End

/// @function DriftCorrelationPartition_Worker
/// @brief Register one stack layer by normalized cross-correlation.
/// @param w3D Input 3D image stack.
/// @param w3DPart Preprocessed or cropped stack used to estimate alignment.
/// @param w3DPartRef Reference image used for correlation or registration.
/// @param refP Reference-row location of the correlation maximum.
/// @param refQ Reference-column location of the correlation maximum.
/// @param plane Zero-based image-stack plane index.
/// @param wDC Optional wave that receives or supplies per-layer drift parameters.
/// @param subpixel (optional) If nonzero, refine correlation peaks with a two-dimensional Gaussian fit.
/// @returns Reference to the result wave; a null wave reference indicates failure where supported.
ThreadSafe static Function/WAVE DriftCorrelationPartition_Worker(WAVE w3D, WAVE w3DPart,
					WAVE w3DPartRef, variable refP, variable refQ, variable plane,
					WAVE/Z wDC, [variable subpixel])
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	variable pdrift, qdrift
	// Calculate drift
	ImageTransform/P=(plane) getPlane w3DPart // Get plane from partitioned wave
	Wave M_ImagePlane
	MatrixOP/O/FREE correlationW = correlate(w3DPartRef, scale(M_ImagePlane, 0 , 1), 0)
	ImageStats correlationW
	if(subpixel)
		variable rows = DimSize(M_ImagePlane,0), cols = DimSize(M_ImagePlane,1)
		variable pmin, pmax, qmin, qmax, fitWidthPixels = 20
		pmin = max(0,V_MaxRowLoc - fitWidthPixels)
		pmax = min(V_MaxRowLoc + fitWidthPixels, rows-1)
		qmin = max(0, V_MaxColLoc - fitWidthPixels)
		qmax = min(V_MaxColLoc + fitWidthPixels, cols-1)
		CurveFit/Q Gauss2D  correlationW[pmin,pmax][qmin,qmax] /D 
		WAVE W_coef
		pdrift = refP - W_coef[2]
		qdrift = refQ - W_coef[4]
		//print "SP: ", pdrift, qdrift, refP, W_coef[2], refQ, W_coef[4]		
	else
		pdrift = refP - V_MaxRowLoc
		qdrift = refQ - V_MaxColLoc
		//print "P: ", pdrift, qdrift, refP, V_MaxRowLoc, refQ, V_MaxColLoc
	endif
	
	if(WaveExists(wDC))
		wDC[0][plane] = pdrift
		wDC[1][plane] = qdrift
	endif
	// Drift the whole image
	ImageTransform/P=(plane) getPlane w3D
	Wave M_ImagePlane
	ImageInterpolate/APRM={1,0,pdrift,0,1,qdrift,1,0} Affine2D M_ImagePlane
	WAVE M_Affine
	// Restore the current data folder
	SetDataFolder dfSav

	// Since the only reference to the free data folder created above
	// was the current data folder, there are now no references it.
	// Therefore, Igor has automatically deleted it.
	// Since there IS a reference to the M_Affine wave in the free
	// data folder, M_Affine is not deleted but becomes a free wave.

	return M_Affine		// Return a reference to the free M_Affine wave
End

/// @function DriftPhaseCorrelationPartition_Worker
/// @brief Register one stack layer by phase correlation.
/// @param w3D Input 3D image stack.
/// @param w3DPart Preprocessed or cropped stack used to estimate alignment.
/// @param fftRef Phase spectrum of the reference image.
/// @param plane Zero-based image-stack plane index.
/// @param wDC Optional wave that receives or supplies per-layer drift parameters.
/// @param subpixel (optional) If nonzero, refine correlation peaks with a two-dimensional Gaussian fit.
/// @returns Reference to the result wave; a null wave reference indicates failure where supported.
ThreadSafe static Function/WAVE DriftPhaseCorrelationPartition_Worker(WAVE w3D, WAVE w3DPart,
					WAVE fftRef, variable plane, WAVE/Z wDC, [variable subpixel])
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	variable pD, qD, drfP, drfQ
	// Calculate drift
	ImageTransform/P=(plane) getPlane w3DPart // Get plane from partitioned wave
	Wave M_ImagePlane
	
	// See ATH_Transform#PhaseCorrelation 
	MatrixOP/FREE invFFT = sqrt(powR(ifft(p2rect(cmplx(1, fftRef - imag(r2polar(fft(M_ImagePlane,2))))), 5),2))
	ImageStats invFFT
	variable pdrift,qdrift
	variable rows = DimSize(M_ImagePlane,0), cols = DimSize(M_ImagePlane,1)
	if(subpixel)
		variable pmin, pmax, qmin, qmax, fitWidthPixels = 20
		pmin = max(0,V_MaxRowLoc - fitWidthPixels)
		pmax = min(V_MaxRowLoc + fitWidthPixels, rows-1)
		qmin = max(0, V_MaxColLoc - fitWidthPixels)
		qmax = min(V_MaxColLoc + fitWidthPixels, cols-1)
		CurveFit/Q Gauss2D  invfft[pmin,pmax][qmin,qmax] /D 
		WAVE W_coef
		pdrift = W_coef[2] - rows/2
		qdrift = W_coef[4] - cols/2
		//print "SP: ", pdrift, qdrift, rows/2, W_coef[2], cols/2, W_coef[4]
	else
		pdrift = V_MaxRowLoc - rows/2
		qdrift = V_MaxColLoc - cols/2
		//print "P: ", pdrift, qdrift, rows/2, V_MaxRowLoc, cols/2, V_MaxColLoc
	endif
	if(WaveExists(wDC))
		wDC[0][plane] = pdrift
		wDC[1][plane] = qdrift
	endif
	
	// Drift the whole image
	ImageTransform/P=(plane) getPlane w3D
	Wave M_ImagePlane
	ImageInterpolate/APRM={1,0,pdrift,0,1,qdrift,1,0} Affine2D M_ImagePlane
	WAVE M_Affine
	// Restore the current data folder
	SetDataFolder dfSav
	
	// Since the only reference to the free data folder created above
	// was the current data folder, there are now no references it.
	// Therefore, Igor has automatically deleted it.
	// Since there IS a reference to the M_Affine wave in the free
	// data folder, M_Affine is not deleted but becomes a free wave.

	return M_Affine		// Return a reference to the free M_Affine wave
End

/// @function MultiThreadRegistrationDriftCorrection
/// @brief Measure stack drift using multithreaded image registration.
/// @details
/// Registers each normalized layer to the selected reference layer and replaces the input stack with the
/// aligned result.
/// @param w3D Input 3D image stack.
/// @param w3DPart Preprocessed or cropped stack used to estimate alignment.
/// @param layerN Zero-based image-stack layer index.
/// @param RotZ (optional) If nonzero, allow rotation about the z axis.
/// @param saveDrift (optional) If nonzero, save the calculated per-layer drift parameters.
/// @returns Zero after replacing the source stack with the registered result.
static Function MultiThreadRegistrationDriftCorrection(WAVE w3D, 
	 WAVE w3DPart, variable layerN, [variable RotZ, variable saveDrift])

	if(!(WaveType(w3D) & 0x02))
		Redimension/S w3D
	endif
	if(!(WaveType(w3DPart) & 0x02))
		Redimension/S w3DPart
	endif
	
	// Normalize the stack to avoid issues with ImageRegistration
	MatrixOP/FREE w3DPart_n = scale(w3DPart,0,1)
	// Create a wave to hold wave references returned by DriftCorrelation_Worker.
	variable numPlanes = DimSize(w3D,2)
	Make/WAVE/N=(numPlanes) ww	
	//
	if(saveDrift)
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(skATH_SaveImageStackDriftCorrections)
		Make/D/O/N=(22, numPlanes) dfr:ath_driftCorr /WAVE = wDC
		SetDimLabel 0,0, dx,wDC;SetDimLabel 0,1, dy,wDC;SetDimLabel 0,2, dz,wDC
		SetDimLabel 0,3, a11,wDC;SetDimLabel 0,4, a12,wDC;SetDimLabel 0,5, a13,wDC
		SetDimLabel 0,6, a21,wDC;SetDimLabel 0,7, a22,wDC;SetDimLabel 0,8, a23,wDC
		SetDimLabel 0,9, a31,wDC;SetDimLabel 0,10, a32,wDC;SetDimLabel 0,11, a33,wDC
		SetDimLabel 0,12, gammma,wDC;SetDimLabel 0,13, phi,wDC;SetDimLabel 0,14, theta,wDC
		SetDimLabel 0,15, psi,wDC;SetDimLabel 0,16, lambda,wDC;SetDimLabel 0,17, origin_x,wDC
		SetDimLabel 0,18, origin_y,wDC;SetDimLabel 0,19, origin_z,wDC;SetDimLabel 0,20, MSE,wDC
		SetDimLabel 0,21, SNR,wDC
		string noteStr = "Apply drift corrections: Registration with reference layer #"+num2str(layerN)
		noteStr += " of " + GetWavesDataFolder(w3D, 2) + "\n"
		Note/K wDC, noteStr 
	endif	
	// Get the reference layer from the partitioned wave
	ImageTransform/P=(layerN) getPlane w3DPart
	Wave M_ImagePlane // Reference layer
	
	Make/FREE/N=(DimSize(w3D,0),DimSize(w3D,1)) ATH_ROIMask
	FastOp ATH_ROIMask = 1
	// Release the threads.
	MultiThreadingControl setMode=0	
	MultiThread ww = DriftRegistrationPartition_Worker(w3D, w3DPart_n, M_ImagePlane, ATH_ROIMask, p, RotZ = RotZ, wDC = wDC)	
	MultiThreadingControl setMode=1	
	// At this point, ww holds wave references to numplanes free waves
	// created by DriftCorrelation_Worker.
	// So, now repack all layers.
	Concatenate/O {ww}, $GetWavesDataFolder(w3D,2)
	
	// ww holds references to the free waves. By killing ww, we kill
	// the last reference to the free waves which causes them to be
	// automatically deleted.
	KillWaves ww, M_ImagePlane
End

// Multithreaded Drift Correction using Registration
/// @function DriftRegistrationPartition_Worker
/// @brief Register one stack layer and optionally record its transformation parameters.
/// @param w3D Input 3D image stack.
/// @param w3DPart Preprocessed or cropped stack used to estimate alignment.
/// @param w3DPartRef Reference image used for correlation or registration.
/// @param wROIMask Mask defining pixels used by ImageRegistration.
/// @param plane Zero-based image-stack plane index.
/// @param RotZ (optional) If nonzero, allow rotation about the z axis.
/// @param wDC (optional) Optional wave that receives or supplies per-layer drift parameters.
/// @returns Reference to the result wave; a null wave reference indicates failure where supported.
ThreadSafe static Function/WAVE DriftRegistrationPartition_Worker(WAVE w3D, WAVE w3DPart,
					WAVE w3DPartRef, WAVE wROIMask, variable plane, [variable RotZ, WAVE/Z wDC])
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	// Calculate drift
	MatrixOP testPartitionW = layer(w3DPart,plane)
	
	if(RotZ)
		ImageRegistration/Q/CONV=1/TRNS={1,1,0}/ROT={0,0,1}/TSTM=0/BVAL=0 refwave = w3DPartRef, testwave = testPartitionW
	else
		ImageRegistration/Q/CONV=0/TRNS={1,1,0}/ROT={0,0,0}/TSTM=0/BVAL=0 refwave = w3DPartRef, testwave = testPartitionW	
	endif
	WAVE W_RegParams
	Duplicate W_RegParams, ATH_RegParams
	if(WaveExists(wDC))
		wDC[][plane] = ATH_RegParams[p]
	endif	
	// Drift the whole image
	MatrixOP regPlane = layer(w3D, plane)
	ImageRegistration/Q/USER=ATH_RegParams/BVAL=0 testMask=wROIMask testwave=regPlane
	WAVE M_RegOut
	// Restore the current data folder
	SetDataFolder dfSav

	// Since the only reference to the free data folder created above
	// was the current data folder, there are now no references it.
	// Therefore, Igor has automatically deleted it.
	// Since there IS a reference to the M_Affine wave in the free
	// data folder, M_Affine is not deleted but becomes a free wave.

	return M_RegOut		// Return a reference to the free M_Affine wave
End

/// ---------- ////
// TODO: We can accelerate by noop when there is no drift for a layer
// Filter before Concatenate with a loop over all layers.
//
// TODO: We can accumulate drifts to allow user to drift correct more
// than once if needed.

/// @function MultiThreadApplySavedDriftCorrections
/// @brief Apply stored drift corrections to an image stack in parallel.
/// @details
/// Accepts either the two-row translation format produced by correlation or the 22-row transformation format
/// produced by ImageRegistration.
/// @param w3D Input 3D image stack.
/// @param cDriftW (optional) Wave containing saved translation or ImageRegistration parameters.
/// @returns Igor status code; zero indicates success and nonzero values report failure or cancellation.
static Function MultiThreadApplySavedDriftCorrections(WAVE w3D, [WAVE/Z cDriftW])
	
	if(!(WaveType(w3D) & 0x02))
		Redimension/S w3D
	endif

	variable numPlanes = DimSize(w3D,2)
	Make/WAVE/N=(numPlanes) ww	
		
	Make/FREE/N=(DimSize(w3D,0),DimSize(w3D,1)) ATH_ROIMask
	FastOp ATH_ROIMask = 1
	if(ParamIsDefault(cDriftW))
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(skATH_SaveImageStackDriftCorrections)
		WAVE/SDFR=dfr wDC = ath_driftCorr
	else
		WAVE wDC = cDriftW // Apply another way with drift parameters
	endif
	if(DimSize(w3D, 2) != DimSize(wDC,1))
		print "Dimension mismatch ... MultiThreadApplySavedDriftCorrections exits."
		return 1
	endif
	// Release the threads.
	MultiThreadingControl setMode=0
	MultiThread ww = ApplySavedDriftCorrections_Worker(w3D, ATH_ROIMask, wDC, p)	
	MultiThreadingControl setMode=1	
	// At this point, ww holds wave references to numplanes free waves
	// created by DriftCorrelation_Worker.
	// So, now repack all layers.
	Concatenate/O {ww}, $GetWavesDataFolder(w3D,2)
	
	// ww holds references to the free waves. By killing ww, we kill
	// the last reference to the free waves which causes them to be
	// automatically deleted.
	KillWaves ww
	return 0
End

// Multithreaded Drift Correction using Registration
/// @function ApplySavedDriftCorrections_Worker
/// @brief Apply saved correlation or registration parameters to one stack layer.
/// @param w3D Input 3D image stack.
/// @param wROIMask Mask defining pixels used by ImageRegistration.
/// @param wDC Optional wave that receives or supplies per-layer drift parameters.
/// @param plane Zero-based image-stack plane index.
/// @returns Reference to the result wave; a null wave reference indicates failure where supported.
ThreadSafe static Function/WAVE ApplySavedDriftCorrections_Worker(WAVE w3D, WAVE wROIMask, WAVE wDC, variable plane)
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	// Retrieve drift
	// Drift the whole image
	MatrixOP regPlane = layer(w3D, plane)	
	if(DimSize(wDC,0) == 22)
		MatrixOP ATH_RegParams = col(wDC, plane)	
		ImageRegistration/Q/USER=ATH_RegParams/BVAL=0 testMask=wROIMask testwave=regPlane
	else
		ImageInterpolate/APRM={1,0,wDC[0][plane],0,1,wDC[1][plane],1,0}/DEST=M_RegOut Affine2D regPlane
	endif
	WAVE M_RegOut
	// Restore the current data folder
	SetDataFolder dfSav

	// Since the only reference to the free data folder created above
	// was the current data folder, there are now no references it.
	// Therefore, Igor has automatically deleted it.
	// Since there IS a reference to the M_Affine wave in the free
	// data folder, M_Affine is not deleted but becomes a free wave.

	return M_RegOut		// Return a reference to the free M_Affine wave
End

// Added for ATH_Launch#ImageRegistrationStack()
/// @function MultiThreadImageRegistration
/// @brief Register image-stack layers in parallel.
/// @param w3D Input 3D image stack.
/// @param ref Zero-based index of the reference layer.
/// @returns Zero after replacing the source stack with the registered result.
static Function MultiThreadImageRegistration(WAVE w3D, variable ref)

	if(!(WaveType(w3D) & 0x02))
		Redimension/S w3D
	endif
	
	// Create a wave to hold wave references returned by DriftCorrelation_Worker.
	variable numPlanes = DimSize(w3D,2)
	Make/WAVE/N=(numPlanes) ww	
	// Get the reference layer from the partitioned wave
	ImageTransform/P=(ref) getPlane w3D
	Wave M_ImagePlane // Reference layer
	// Release the threads.
	MultiThreadingControl setMode=0	
	MultiThread ww = ImageRegistration_Worker(w3D, M_ImagePlane, p)
	MultiThreadingControl setMode=1	
	// At this point, ww holds wave references to numplanes free waves
	// created by DriftCorrelation_Worker.
	// So, now repack all layers.
	Concatenate/O {ww}, $GetWavesDataFolder(w3D,2)
	
	// ww holds references to the free waves. By killing ww, we kill
	// the last reference to the free waves which causes them to be
	// automatically deleted.
	KillWaves ww, M_ImagePlane
End

/// @function ImageRegistration_Worker
/// @brief Register one stack layer to a reference image.
/// @param w3D Input 3D image stack.
/// @param wRef Reference image used to register the selected layer.
/// @param plane Zero-based image-stack plane index.
/// @returns Reference to the result wave; a null wave reference indicates failure where supported.
ThreadSafe static Function/WAVE ImageRegistration_Worker(WAVE w3D, WAVE wRef, variable plane)
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	ImageTransform/P=(plane) getPlane w3D
	Wave M_ImagePlane
	ImageRegistration/Q/CONV=1/TRNS={1,1,1}/ROT={0,0,1}/PRDL=1/TSTM=0/BVAL=0 refwave = wRef, testwave = M_ImagePlane
	WAVE M_RegOut	
	// Restore the current data folder
	SetDataFolder dfSav

	return M_RegOut		// Return a reference to the free M_RegOut wave
End
