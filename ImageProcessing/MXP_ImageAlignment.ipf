#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function MXP_ImageAlignmentByRegistration(WAVE w1, WAVE w2)
	/// Align two images using ImageRegistration operation. 
	/// Only x, y translations are allowed.
	/// @param w1 wave reference First wave (reference wave)
	/// @param w2 wave reference Second wave (test wave)
	ImageRegistration/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/TSTM=0 refWave = w1, testWave = w2
	WAVE M_RegOut, M_RegOut, M_RegMaskOut
	string w2Backup = NameofWave(w2) + "_bak"
	Duplicate/O w2, $w2Backup
	Duplicate/O M_RegOut, w2	
	KillWaves/Z M_RegOut, M_RegOut, M_RegMaskOut
End

//UNDER CONTSRUCTION
Function MXP_ImageAlignment3DByRegistration(WAVE w3d, [int refLayer])
	/// Align a 3d wave using ImageRegistration. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise 
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.

	//TODO: Fix the function
	refLayer = ParamIsDefault(refLayer) ? 0: refLayer // If you don't select reference layer then 0 is your choice
	
	//ImageRegistration/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/TSTM=0 refwave = w1, testwave = w2
	WAVE M_RegOut, M_RegOut, M_RegMaskOut
End

Function/Wave MXP_ImageAlignmentByCorrelation(WAVE w1, WAVE w2)
	/// Align two images using Correlation/Autocorrelation operations. 
	/// @param w1 wave reference First wave (reference wave) for which its autocorrelation 
	/// is our reference.
	/// @param w2 wave reference Second wave (test wave), which will be tranlated with respect
	/// to w1.
	/// The current function allow only for integer pixed translations.
	
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
	Duplicate/O w2, w2_drift
	w2_drift = interp2D(w2, x - dxDrift, y - dyDrift)
End