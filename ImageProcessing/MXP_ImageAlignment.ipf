#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function/WAVE MXP_WAVEImageAlignmentByRegistration(WAVE w1, WAVE w2)
	/// Align two images using ImageRegistration operation. 
	/// Only x, y translations are allowed.
	/// @param w1 wave reference First wave (reference wave)
	/// @param w2 wave reference Second wave (test wave)
	/// @return alignedW w2 aligned with w1 as reference.
	Duplicate/FREE w2, w2copy
	ImageRegistration/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/TSTM=0 refWave = w1, testWave = w2copy
	WAVE M_RegOut, M_RegOut, M_RegMaskOut
	Duplicate/FREE M_RegOut, alignedW
	KillWaves/Z M_RegOut, M_RegOut, M_RegMaskOut
	return alignedW
End

Function MXP_ImageAlignmentByRegistration(WAVE w1, WAVE w2)
	/// Align two images using ImageRegistration operation. 
	/// Only x, y translations are allowed.
	/// @param w1 wave reference First wave (reference wave)
	/// @param w2 wave reference Second wave (test wave)
	string msg
	sprintf msg, "ImageRegistration needs SP precision waves. Converting %s, %s to SP", NameOfWave(w1), NameOfWave(w2)
	print msg		
	sprintf msg, "ImageRegistration with refWave = %s and testWave = %s.", NameOfWave(w1), NameOfWave(w2)
		
	if(!(WaveType(w1) & 0x02))
		Redimension/S w1
	endif
	if(!(WaveType(w2) & 0x02))
		Redimension/S w1
	endif 
	ImageRegistration/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/TSTM=0 refWave = w1, testWave = w2
	WAVE M_RegOut
	Duplicate/O M_RegOut, w2	
	KillWaves/Z M_RegOut, M_RegOut, M_RegMaskOut, W_RegParams
	return 0
End

Function MXP_ImageStackAlignmentByFullRegistration(WAVE w3d, [variable layerN])
	/// Align a 3d wave using ImageRegistration. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise 
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.
	/// Note: When illumination conditions change considerably, (XAS along an edge)
	/// it is better to use a mask to isolate a characteristic feature. 
	//TODO: Fix the function
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then 0 is your choice
	MatrixOP/FREE refLayerWave = layer(w3d, layerN) 
	// HERE /CONV=0 accelerates a lot the process in a 3d stack but you lose in accuracy?
	ImageRegistration/Q/STCK/PSTK/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/TSTM=0/CONV=0 refwave = refLayerWave, testwave = w3d
	WAVE M_RegOut, M_RegMaskOut, M_RegParams
	MatrixOP/FREE/P=1 dx = row(M_RegParams,0) // Print dx
	MatrixOP/FREE/P=1 dy = row(M_RegParams,1) // Print dy
	Duplicate/O w3d, $NameOfWave(w3d)+"_undo"
	Duplicate/O M_RegOut, w3d
	KillWaves/Z M_RegOut, M_RegMaskOut, M_RegParams
	return 0
End

Function MXP_ImageStackAlignmentByMaskRegistration(WAVE w3d, WAVE MaskWaveRef, [variable layerN, variable convMode, variable printMode])
	/// Align a 3d wave using ImageRegistration. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise 
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.
	/// @param convMode int optional Select convergence method /CONV = 0, 1 for Gravity (fast) or Marquardt (slow), respectively.
	/// Note: When illumination conditions change considerably, (XAS along an edge)
	/// it is better to use a mask to isolate a characteristic feature. 
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then 0 is your choice
	convMode = ParamIsDefault(convMode) ? 0: convMode // convMode = 0, 1 
	printMode = ParamIsDefault(printMode) ? 0: printMode // convMode = 0, 1 
	if(!(WaveType(MaskWaveRef) & 0x02))
		Redimension/S MaskWaveRef
	endif
	MatrixOP/FREE refLayerWave = layer(w3d, layerN)
	variable rows = DimSize(w3d, 0)
	variable cols = DimSize(w3d, 1)
	variable layers = DimSize(w3d, 2)
	Make/FREE/N=(rows, cols, layers) MaskWave3d
	MaskWave3d[][][] = MaskWaveRef[p][q]
	ImageRegistration/Q/STCK/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/CONV=(convMode) refMask = MaskWaveRef testMask = MaskWave3d refwave = refLayerWave, testwave = w3d
	WAVE M_RegOut, M_RegMaskOut, M_RegParams
	if(printMode)
		MatrixOP/FREE/P=1 dx = row(M_RegParams,0) // Print dx
		MatrixOP/FREE/P=1 dy = row(M_RegParams,1) // Print dy
	else
		MatrixOP/FREE dx = row(M_RegParams,0) // Print dx
		MatrixOP/FREE dy = row(M_RegParams,1) // Print dy
	endif
	Duplicate/O w3d, $NameOfWave(w3d)+"_undo"
	//Now translate each wave in the stack
	variable i 
	for(i = 0; i < layers; i++)
		MatrixOP/FREE getfreelayer = layer(w3d, i)
		ImageTransform/IOFF={dx[i], dy[i], 0} offsetImage getfreelayer
		w3d[][][i] = getfreelayer[p][q]
	endfor
	KillWaves/Z M_RegOut, M_RegMaskOut, M_RegParams
	return 0
End

Function MXP_ImageStackAlignmentByCorrelation(WAVE w3d, [variable layerN, variable printMode, variable useThreads])
	/// Align a 3d wave using (auto)correlation. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise. 
	/// Only integer x, y translations are calculated.
	/// @param w3d wave 3d we want to aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.
	/// @param printMode int optional print the drift corrections in pixels
	/// @param useThreads int optional use MultiThread for some wave assignments

	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then 0 is your choice
	printMode = ParamIsDefault(printMode) ? 0: printMode // print if not 0
	useThreads = ParamIsDefault(useThreads) ? 0: useThreads // print if not 0
	MatrixOP/FREE refLayerWave = layer(w3d, layerN)
	MatrixOP/FREE autocorrelationW = correlate(refLayerWave, refLayerWave, 0)
	WaveStats/M=1/Q autocorrelationW
	variable x0 = V_maxRowLoc, y0 = V_maxColLoc, x1, y1, dx, dy
	variable layers = DimSize(w3d, 2)
	Duplicate/O w3d, $NameOfWave(w3d)+"_undo"
	//Now translate each wave in the stack
	variable i 
	if(printMode)
		print "Ref. Layer = ", layerN
		print "---- Drift ----"
		print "layer  dx  dy"
	endif

	for(i = 0; i < layers; i++)
		if(i != layerN)
			MatrixOP/FREE freeLayer = layer(w3d, i)
			MatrixOP/FREE correlationW = correlate(refLayerWave, freeLayer, 0)
			WaveStats/M=1/Q correlationW
			x1 = V_maxRowLoc
			y1 = V_maxColLoc
			dx = x1 - x0
			dy = y1 - y0
			if(printMode)
				print i, dx, dy
			endif
			if(dx * dy) // Replace a slice only if you have to offset
				ImageTransform/IOFF={-dx, -dy, 0} offsetImage freeLayer
				Wave M_OffsetImage
				if(useThreads)
					MultiThread w3d[][][i] = M_OffsetImage[p][q] //Might be instable
				else
					w3d[][][i] = M_OffsetImage[p][q] //Might be instable
				endif
			endif
			// interp2D(getfreelayer, x + dx, y + dy) works but we need an extra step MatrixOP/FREE XXX = zapNaNs()			
		endif
	endfor
	KillWaves/Z M_OffsetImage
	WaveClear M_OffsetImage
	return 0
End

Function/WAVE MXP_WAVEImageAlignmentByCorrelation(WAVE w1, WAVE w2, [variable printMode])
	/// Align two images using Correlation/Autocorrelation operations. 
	/// @param w1 wave reference First wave (reference wave) for which its autocorrelation 
	/// is our reference.
	/// @param w2 wave reference Second wave (test wave), which will be tranlated with respect
	/// to w1.
	/// @param printMode int optional print the drift corrections in pixels
	/// The MXP_ImageAlignmentByCorrelation function allow only for integer pixed translations.
	
	printMode = ParamIsDefault(printMode) ? 0: printMode // print if not 0 
	MatrixOP/FREE autocorr = correlate(w1, w1, 0)
	MatrixOP/FREE corr = correlate(w1, w2, 0)
	WaveStats/Q autocorr // /P flag: report Loc in p, q instead of x, y
	variable x0 = V_maxRowLoc
	variable y0 = V_maxColLoc
	WaveStats/Q corr // /P flag: report Loc in p, q instead of x, y
	variable x1 = V_maxRowLoc
	variable y1 = V_maxColLoc
	variable dx = x1 - x0
	variable dy = y1 - y0
	Duplicate/FREE w1, driftCorrW
	Wave M_OffsetImage
	ImageTransform/IOFF={-dx, -dy, 0} offsetImage driftCorrW
	if(printMode)
		print "dx=", dx,",dy=", dy
	endif
	Duplicate/FREE M_OffsetImage waveRef
	KillWaves/Z M_OffsetImage
	WaveClear M_OffsetImage
	return waveRef
End

Function MXP_ImageAlignmentByCorrelation(WAVE w1, WAVE w2, string alignedImageStr, [variable printMode])
	/// Align two images using Correlation/Autocorrelation operations. 
	/// @param w1 wave reference First wave (reference wave) for which its autocorrelation 
	/// is our reference.
	/// @param w2 wave reference Second wave (test wave), which will be tranlated with respect
	/// to w1.
	/// @param alignedImageStr string Name of the alinged image.
	/// @param printMode int optional print the drift corrections in pixels
	/// The MXP_ImageAlignmentByCorrelation function allow only for integer pixed translations.
	
	// Take into account wave scaling.
		printMode = ParamIsDefault(printMode) ? 0: printMode // print if not 0 
	MatrixOP/FREE autocorr = correlate(w1, w1, 0)
	MatrixOP/FREE corr = correlate(w1, w2, 0)
	WaveStats/Q autocorr // /P flag: report Loc in p, q instead of x, y
	variable x0 = V_maxRowLoc
	variable y0 = V_maxColLoc
	WaveStats/Q corr // /P flag: report Loc in p, q instead of x, y
	variable x1 = V_maxRowLoc
	variable y1 = V_maxColLoc
	variable dx = x1 - x0
	variable dy = y1 - y0
	Duplicate/FREE w1, driftCorrW
	Wave M_OffsetImage
	ImageTransform/IOFF={-dx, -dy, 0} offsetImage driftCorrW
	Duplicate/O M_OffsetImage, $alignedImageStr
	WaveClear M_OffsetImage
	if(printMode)
		print "dx=", dx,",dy=", dy
	endif
	return 0
End