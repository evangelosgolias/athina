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


/// @function ImgRegistration
/// @brief Description of ImgRegistration.
/// @details
/// Auto-generated documentation stub for function `ImgRegistration`.
/// @param w1 Parameter w1.
/// @param w2 Parameter w2.
/// @returns Variable Return value.

static Function ImgRegistration(WAVE w1, WAVE w2)
	/// Align two images using ImageRegistration operation. 
	/// Note: w2 in overwritten
	/// @param w1 wave reference First wave (reference wave)
	/// @param w2 wave reference Second wave (test wave)

	if(!(WaveType(w1) & 0x02))	
		Redimension/S w1
	endif
	if(!(WaveType(w2) & 0x02))
		Redimension/S w2
	endif 
	ImageRegistration/Q/CONV=1/TRNS={1,1,0}/ROT={0,0,1}/ISOS/TSTM=0/BVAL=0 refWave = w1, testWave = w2
	WAVE M_RegOut
	Duplicate/O M_RegOut, w2	
	KillWaves/Z M_RegOut, M_RegMaskOut, W_RegParams
	return 0
End

/// @function ImgStackRegistration
/// @brief Description of ImgStackRegistration.
/// @details
/// Auto-generated documentation stub for function `ImgStackRegistration`.
/// @param wRef Parameter wRef.
/// @param layerN Parameter layerN.
/// @returns Variable Return value.

static Function ImgStackRegistration(WAVE wRef, variable layerN)
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	
	if(!(WaveType(wRef) & 0x02))
		Redimension/S wRef
	endif
		
	MatrixOP/FREE refLayerW = layer(wRef, layerN)
	ImageRegistration/Q/CONV=1/STCK/PSTK/TRNS={1,1,0}/ROT={0,0,1}/CSNR=0/TSTM=0/BVAL=0 refwave = refLayerW, testwave = wRef
	WAVE M_RegOut
	Duplicate/O M_RegOut, wRef
	SetDataFolder saveDF
	return 0
End

static Function ImgStackPartitionRegistration(WAVE wRef, WAVE partwRef, [variable layerN,
				variable RotZ, variable savedrift]) // Used in menu
	/// Align a 3d wave using ImageRegistration of a partition of the target 3d wave.
	/// The partition 3d wave calls ATH_ImageStackAlignmentByFullRegistration
	/// By default the function will  use the 0-th layer as a wave reference, uncless user chooses otherwise.
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param partitionW3d WAVE partition of w3d
	/// @layerN set the reference layer
	/// @savedrift if set the drift paramers are saved.
	/// @cutoff if set max drift in pixels allowed
	/// @intPixels Drift an integer number of pixels
	
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then default is 0
	savedrift = ParamIsDefault(savedrift) ? 0: savedrift
	RotZ = ParamIsDefault(RotZ) ? 0 : !!RotZ
	
	if(!(WaveType(wRef) & 0x02))
		Redimension/S wRef
	endif
	if(!(WaveType(partwRef) & 0x02))
		Redimension/S partwRef
	endif

	DFREF currDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	
	MatrixOP/FREE partwRef_n = scale(partwRef,0,1)
	MatrixOP/FREE refLayerWave = layer(partwRef_n, layerN)
	
	variable rows = DimSize(wRef, 0)
	variable cols = DimSize(wRef, 1)
	variable layers = DimSize(wRef, 2)
	if(RotZ)
		ImageRegistration/Q/CONV=1/STCK/PSTK/TRNS={1,1,0}/ROT={0,0,1}/CSNR=0/TSTM=0/BVAL=0 refwave = refLayerWave, testwave = partwRef_n		
	else
		ImageRegistration/Q/CONV=1/STCK/PSTK/TRNS={1,1,0}/ROT={0,0,0}/CSNR=0/TSTM=0/BVAL=0 refwave = refLayerWave, testwave = partwRef_n
	endif
	WAVE M_RegParams

	MatrixOP/FREE dx = row(M_RegParams, 0)
	MatrixOP/FREE dy = row(M_RegParams, 1)			

	if(savedrift)
		DFREF saveDF = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:DriftCorrectionDataSets:")
		string dcWaveName = CreateDataObjectName(saveDF, NameOfWave(wRef), 1, 0, 1)
		Duplicate M_RegParams, saveDF:$dcWaveName
		string driftLog
		sprintf driftLog, "***** Drift Parameters of %s *****\n", GetWavesDataFolder(wRef, 2)
		Note/K saveDF:$dcWaveName, driftLog
		sprintf driftLog, "***** Drift Parameters in %s *****\n", GetWavesDataFolder(saveDF:$dcWaveName, 2)
		ATH_String#WaveLogging(wRef, driftLog, prepend = 1)
	endif
	
	variable i
	Make/FREE/N=(DimSize(wRef,0), DimSize(wRef,0)) ATH_ROIMask
	FastOP ATH_ROIMask = 1
	for(i = 0; i < layers; i++)
		if((dx[i] == 0 && dy[i] == 0) || layerN == i)
			MatrixOP/O $("getStacklayer_" + num2str(i)) = layer(wRef, i) // Scaled in pixels!
		else
			MatrixOP/O getLayer = layer(wRef, i) // Scaled in pixels!
			MatrixOP/O getRegParams = col(M_RegParams, i) // Scaled in pixels!
			ImageRegistration/Q/USER=getRegParams/BVAL=0 testMask=ATH_ROIMask testwave=getLayer
			WAVE M_RegOut			
			Rename M_RegOut $("getStacklayer_" + num2str(i))
		endif
	endfor
	ImageTransform/NP=(layers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales wRef, M_Stack
	Duplicate/O M_Stack, saveDF:$NameofWave(wRef)

	SetDataFolder currDF
	return 0
End

/// @function ImgStackPartitionCorrelation
/// @brief Description of ImgStackPartitionCorrelation.
/// @details
/// Auto-generated documentation stub for function `ImgStackPartitionCorrelation`.
/// @param w3d Parameter w3d.
/// @param partitionW3d Parameter partitionW3d.
/// @param layerN] Parameter layerN].
/// @returns Variable Return value.

static Function ImgStackPartitionCorrelation(WAVE w3d,
	   WAVE partitionW3d, [variable layerN, variable savedrift]) // Used in menu
	/// Align a 3d wave using ImageRegistration of a partition of the target 3d wave.
	/// The partition 3d wave calls ATH_ImageStackAlignmentByFullRegistration
	/// By default the function will  use the 0-th layer as a wave reference, uncless user chooses otherwise.
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.
	/// @param convMode int optional Select convergence method /CONV = 0, 1 for Gravity (fast) or Marquardt (slow), respectively.
	/// Note: When illumination conditions change considerably, (XAS along an edge)
	/// it is better to use a mask to isolate a characteristic feature.
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then default is 0
	savedrift = ParamIsDefault(savedrift) ? 0: savedrift
	
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	if(!(WaveType(partitionW3d) & 0x02))
		Redimension/S partitionW3d
	endif

	DFREF currDF = GetDataFolderDFR()
	DFREF saveWaveDF = GetWavesDataFolderDFR(w3d) // Location of w3d
	SetDataFolder NewFreeDataFolder()

	MatrixOP/FREE refLayerWave = layer(partitionW3d, layerN)
	ImageWindow/O Hanning refLayerWave
	MatrixOP/FREE autocorrelationW = correlate(refLayerWave, refLayerWave, 0)
	WaveStats/M=1/Q/P autocorrelationW
	variable p0 = V_maxRowLoc, q0 = V_maxColLoc, p1, q1, i
	variable layers = DimSize(w3d, 2)
	Make/FREE/N=(layers) dp, dq

	for(i = 0; i < layers; i++)
		if(i != layerN)
			MatrixOP/O/FREE freeLayer = layer(partitionW3d, i)
			ImageWindow/O Hanning freeLayer
			MatrixOP/O/FREE correlationW = correlate(refLayerWave, freeLayer, 0)
			WaveStats/M=1/Q/P correlationW
			p1 = V_maxRowLoc
			q1 = V_maxColLoc
			dp[i] = p0 - p1
			dq[i] = q0 - q1
		endif
	endfor
	
	//Now translate each wave in the stack (w3d)
	for(i = 0; i < layers; i++)
		if(dp[i] == 0 && dq[i] == 0)
			MatrixOP/O $("getStacklayer_" + num2str(i)) = layer(w3d, i)
		else
			MatrixOP/O/FREE getfreelayer = layer(w3d, i)
			ImageInterpolate/APRM={1,0,dp[i],0,1,dq[i],1,0} Affine2D getfreelayer
			WAVE M_Affine
			Rename M_Affine, $("getStacklayer_" + num2str(i))
		endif
	endfor
	ImageTransform/NP=(layers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales w3d, M_Stack
	Duplicate/O M_Stack, saveWaveDF:$NameofWave(w3d)
	// -----------------
	if(savedrift)
		DFREF saveDF = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:DriftCorrectionDataSets:")
		string dcWaveName = CreateDataObjectName(saveDF, NameOfWave(w3d), 1, 0, 1)
		Concatenate/NP=1 {dp, dq}, saveDF:$dcWaveName
		string driftLog
		sprintf driftLog, "***** Drift Parameters of %s *****\n", GetWavesDataFolder(w3d, 2)
		Note/K saveDF:$dcWaveName, driftLog
		sprintf driftLog, "***** Drift Parameters in %s *****\n", GetWavesDataFolder(saveDF:$dcWaveName, 2)
		ATH_String#WaveLogging(w3d, driftLog, prepend = 1)
	endif
	// -----------------
	SetDataFolder currDF
	return 0
End

/// @function LinearDriftStackABCursors
/// @brief Description of LinearDriftStackABCursors.
/// @details
/// Auto-generated documentation stub for function `LinearDriftStackABCursors`.
/// @param w3d Parameter w3d.
/// @param wx Parameter wx.
/// @param wy Parameter wy.
/// @param intPx] Parameter intPx].
/// @returns Variable Return value.

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
/// @brief Description of LinearDriftPlanesABCursors.
/// @details
/// Auto-generated documentation stub for function `LinearDriftPlanesABCursors`.
/// @param w3d Parameter w3d.
/// @param wx Parameter wx.
/// @param wy Parameter wy.
/// @param startL Parameter startL.
/// @param endL Parameter endL.
/// @param intPx] Parameter intPx].
/// @returns Variable Return value.

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

static Function MultiThreadCorrelationDriftCorrection(WAVE w3D, 
	 WAVE w3DPart, variable layerN, [variable saveDrift, variable filter, variable upscale, variable windowing])

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
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:SavedDriftCorrections:")
		Make/D/O/N=(2, numPlanes) dfr:ath_driftCorr /WAVE = wDC
		string noteStr = "Apply drift corrections: Correlation with reference layer #"+num2str(layerN)
		noteStr += " of " + GetWavesDataFolder(w3D, 2)
		if(upscale > 1)
			noteStr += " using Upscale Factor="+num2str(upscale)+ "\n"
		else
			noteStr +=  "\n"
		endif
		Note/K wDC, noteStr
	else 
		WAVE wDC = $""
	endif

	// Get the reference layer from the partitioned wave
	ImageTransform/P=(layerN) getPlane w3DPart
	WAVE M_ImagePlane // Reference layer

	
	if(upscale > 1)		
		ImageInterpolate/FUNC=bilinear/TRNS={scaleShift, 0, upscale, 0, upscale}/DEST=ATH_RefImg Resample M_ImagePlane
	else
		WAVE ATH_RefImg = M_ImagePlane
	endif
	
	if(filter)
		MatrixFilter /N=3 avg ATH_RefImg
	endif
	
	if(windowing)
		ImageWindow/O Hanning ATH_RefImg
	endif
	MatrixOP/FREE correlationW = correlate(ATH_RefImg, ATH_RefImg, 0)
	WaveStats/M=1/Q/P correlationW	
	variable refP = V_maxRowLoc
	variable refQ = V_maxColLoc	
	// Release the threads.
	MultiThreadingControl setMode=0
	MultiThread ww = DriftCorrelationPartition_Worker(w3D, w3dPart, ATH_RefImg, refP, refQ, p, wDC, upscale = upscale, filter = filter)	
	MultiThreadingControl setMode=1	
	// At this point, ww holds wave references to numplanes free waves
	// created by DriftCorrelation_Worker.
	// So, now repack all layers.
	Concatenate/O {ww}, $GetWavesDataFolder(w3D,2)
	// ww holds references to the free waves. By killing ww, we kill
	// the last reference to the free waves which causes them to be
	// automatically deleted.
	KillWaves/Z ww, M_ImagePlane, ATH_RefImg
End

ThreadSafe static Function/WAVE DriftCorrelationPartition_Worker(WAVE w3D, WAVE w3DPart,
					WAVE w3DPartRef, variable refP, 
					variable refQ, variable plane, WAVE/Z wDC, [variable upscale, variable filter, variable windowing])
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	variable pD, qD, drfP, drfQ
	// Calculate drift
	ImageTransform/P=(plane) getPlane w3DPart // Get plane from partitioned wave
	Wave M_ImagePlane

	if(upscale > 1)		
		ImageInterpolate/FUNC=bilinear/TRNS={scaleShift, 0, upscale, 0, upscale}/DEST=ATH_RefImg Resample M_ImagePlane
	else
		WAVE ATH_RefImg = M_ImagePlane
	endif
	
	if(filter)
		MatrixFilter /N=3 avg ATH_RefImg
	endif
	
	if(windowing)
		ImageWindow/O Hanning ATH_RefImg
	endif
		
	MatrixOP/O/FREE correlationW = correlate(w3DPartRef, ATH_RefImg, 0)
	WaveStats/M=1/Q/P correlationW
	pD = V_maxRowLoc 
	qD = V_maxColLoc
	// If there is an upscale, save the upscaled drifts
	drfP = upscale > 1 ? (refP - pD)/upscale : refP - pD // Calculate drifts
	drfQ = upscale > 1 ? (refQ - qD)/upscale : refQ - qD
	//
	if(WaveExists(wDC))
		wDC[0][plane] = drfP
		wDC[1][plane] = drfQ
	endif
	// Drift the whole image
	ImageTransform/P=(plane) getPlane w3D
	Wave M_ImagePlane
	ImageInterpolate/APRM={1,0,drfP,0,1,drfQ,1,0} Affine2D M_ImagePlane
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

static Function MultiThreadRegistrationDriftCorrection(WAVE w3D, 
	 WAVE w3DPart, variable layerN, [variable RotZ, variable saveDrift, variable filter])

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
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:SavedDriftCorrections:")
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
	
	if(filter)
		MatrixFilter /N=3 avg M_ImagePlane
	endif

	Make/FREE/N=(DimSize(w3D,0),DimSize(w3D,1)) ATH_ROIMask
	FastOp ATH_ROIMask = 1
	// Release the threads.
	MultiThreadingControl setMode=0	
	MultiThread ww = DriftRegistrationPartition_Worker(w3D, w3DPart_n, M_ImagePlane, ATH_ROIMask, p, RotZ = RotZ, wDC = wDC, filter = filter)	
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
ThreadSafe static Function/WAVE DriftRegistrationPartition_Worker(WAVE w3D, WAVE w3DPart,
					WAVE w3DPartRef, WAVE wROIMask, variable plane, [variable RotZ, WAVE/Z wDC, variable filter])
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	// Calculate drift
	MatrixOP testPartitionW = layer(w3DPart,plane)
	
	if(filter)
		MatrixFilter /N=3 avg testPartitionW
	endif	
	
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

static Function MultiThreadApplySavedDriftCorrections(WAVE w3D, [WAVE/Z cDriftW])
	
	if(!(WaveType(w3D) & 0x02))
		Redimension/S w3D
	endif

	variable numPlanes = DimSize(w3D,2)
	Make/WAVE/N=(numPlanes) ww	
		
	Make/FREE/N=(DimSize(w3D,0),DimSize(w3D,1)) ATH_ROIMask
	FastOp ATH_ROIMask = 1
	if(ParamIsDefault(cDriftW))
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:SavedDriftCorrections:")
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