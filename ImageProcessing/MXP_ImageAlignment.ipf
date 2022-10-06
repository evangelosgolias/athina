#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function/WAVE MXP_WAVEImageAlignmentByRegistration(WAVE w1, WAVE w2)
	/// Align two images using ImageRegistration operation. 
	/// Only x, y translations are allowed.
	/// @param w1 wave reference First wave (reference wave)
	/// @param w2 wave reference Second wave (test wave)
	ImageRegistration/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/TSTM=0 refWave = w1, testWave = w2
	WAVE M_RegOut, M_RegOut, M_RegMaskOut
	string w2Backup = NameofWave(w2) + "_bak"
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
	// Do you want to create a backup? Uncomment. 
	//string w2Backup = NameofWave(w2) + "_bak"
	//Duplicate/O w2, $w2Backup
	Duplicate/O M_RegOut, w2	
	KillWaves/Z M_RegOut, M_RegOut, M_RegMaskOut, W_RegParams
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
End

Function MXP_ImageStackAlignmentByMaskedRegistration(WAVE w3d, WAVE MaskWaveRef, [variable layerN, variable convMode])
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
	MatrixOP/FREE refLayerWave = layer(w3d, layerN)
	variable rows = DimSize(w3d, 0)
	variable cols = DimSize(w3d, 1)
	variable layers = DimSize(w3d, 2)
	Make/FREE/N=(rows, cols, layers) MaskWave3d
	MaskWave3d[][][] = MaskWaveRef[p][q]
	ImageRegistration/Q/STCK/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/CONV=(convMode) refMask = MaskWaveRef testMask = MaskWave3d refwave = refLayerWave, testwave = w3d
	WAVE M_RegOut, M_RegMaskOut, M_RegParams
	MatrixOP/FREE/P=1 dx = row(M_RegParams,0) // Print dx
	MatrixOP/FREE/P=1 dy = row(M_RegParams,1) // Print dy
	Duplicate/O w3d, $NameOfWave(w3d)+"_undo"
	//Now translate each wave in the stack
	variable i 
	for(i = 0; i < layers; i++)
		MatrixOP/FREE getfreelayer = layer(w3d, i)
		ImageTransform/IOFF={dx[i], dy[i], 0} offsetImage getfreelayer
		w3d[][][i] = getfreelayer[p][q]
	endfor
	KillWaves/Z M_RegOut, M_RegMaskOut, M_RegParams
End

// Develop in the future (note on 06.10.22) the function below the line
// --------------------------------------------------------------------
Function/WAVE MXP_WAVEImageAlignmentByCorrelation(WAVE w1, WAVE w2)
	/// Align two images using Correlation/Autocorrelation operations. 
	/// @param w1 wave reference First wave (reference wave) for which its autocorrelation 
	/// is our reference.
	/// @param w2 wave reference Second wave (test wave), which will be tranlated with respect
	/// to w1.
	/// The MXP_ImageAlignmentByCorrelation function allow only for integer pixed translations.
	
	// Take into account wave scaling.
	double dx = DimDelta(w1, 0)
	double dy = DimDelta(w1, 1)
	if(dx != DimDelta(w2, 0) || dy != DimDelta(w2, 1))
		string msgError
		sprintf msgError "Waves %s, %s have different scaling. \n Please rescale your waves and try again.", NameOfWave(w1), NameOfWave(w2)
		Abort msgError
	endif
	MatrixOP/FREE autocorr = correlate(w1, w1, 0)
	MatrixOP/FREE corr = correlate(w1, w2, 0)
	WaveStats/Q/P autocorr
	variable w1Row = V_maxRowLoc
	variable w1Col = V_maxColLoc
	WaveStats/Q/P corr // /P flag: report Loc in p, q instead of x, y
	variable w2Row = V_maxRowLoc
	variable w2Col = V_maxColLoc
	variable rowDrift = w1Row - w2Row
	variable colDrift = w1Col - w2Col
	variable dxDrift = dx * rowDrift
	variable dyDrift = dy * colDrift
	Duplicate/FREE w1, driftCorrW
	driftCorrW = interp2D(w2, x - dxDrift, y - dyDrift)
	return driftCorrW
End

Function MXP_ImageAlignmentByCorrelation(WAVE w1, WAVE w2, string alignedImageStr)
	/// Align two images using Correlation/Autocorrelation operations. 
	/// @param w1 wave reference First wave (reference wave) for which its autocorrelation 
	/// is our reference.
	/// @param w2 wave reference Second wave (test wave), which will be tranlated with respect
	/// to w1.
	/// @param alignedImageStr string Name of the alinged image.
	/// The MXP_ImageAlignmentByCorrelation function allow only for integer pixed translations.
	
	// Take into account wave scaling.
	double dx = DimDelta(w1, 0)
	double dy = DimDelta(w1, 1)
	if(dx != DimDelta(w2, 0) || dy != DimDelta(w2, 1))
		string msgError
		sprintf msgError "Waves %s, %s have different scaling. \n Please rescale your waves and try again.", NameOfWave(w1), NameOfWave(w2)
		Abort msgError
	endif
	MatrixOP/FREE autocorr = correlate(w1, w1, 0)
	MatrixOP/FREE corr = correlate(w1, w2, 0)
	WaveStats/Q/P autocorr
	variable w1Row = V_maxRowLoc
	variable w1Col = V_maxColLoc
	WaveStats/Q/P corr // /P flag: report Loc in p, q instead of x, y
	variable w2Row = V_maxRowLoc
	variable w2Col = V_maxColLoc
	variable rowDrift = w1Row - w2Row
	variable colDrift = w1Col - w2Col
	variable dxDrift = dx * rowDrift
	variable dyDrift = dy * colDrift
	Duplicate w1, $alignedImageStr
	Wave wref = $alignedImageStr
	wref = interp2D(w2, x - dxDrift, y - dyDrift)
End