#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// TODO: Develop code here.

static Function MTFitXMLDMap(WAVE wRef [string fitFunc,
				variable firstAngle, variable angleStep, int fastFit])
	
	fastFit = ParamIsDefault(fastFit) ? 1 : fastFit
	
	variable firstAngleRad = ParamIsDefault(firstAngle) ? -90 * pi/180 : firstAngle * pi/180
	variable angleStepRad = ParamIsDefault(angleStep) ? 10*pi/180 : angleStep * pi/180
	// Which model do you like to fit? Check functions in the module ATH_FuncFit
	if(ParamIsDefault(fitFunc))
		fitFunc = "ATH_FuncFit#XMLDCos2xIntensity" // default
	endif
	// Calculate the angular offset, rotate by -FoVRotRad and apply mirror operation over x-axis
	
	variable rows = DimSize(wRef, 0)
	variable cols = DimSize(wRef, 1)
	variable layers = DimSize(wRef, 2)

	if(!layers)
		return 1
	endif

	// Redimension wRef
	Redimension/E=1/N=(rows * cols, layers) wRef
	variable i, j, k, cnt
	// Make the fitting waves:  K0 + K1 * Cos(2*(x + K2))
	Make/FREE/D/N=3 ATH_Coef
	// Fit can be very sensity to contrains! Read the manual!
	// ********************YOU NEED TO TUNE HERE************************
	//
	// Choose carefully the parameter K1, if it's zero then a lot of errors will occur
	// as K1->0 reduces the functional dependency to a constant function!
	// We will assume of K1 hits the lowest value then K2 == 0!
	//
	Make/FREE/N=(layers) freeData // Get data per beam to fit
	SetScale/P x, firstAngleRad, angleStepRad, freeData // Set the scale, and FoVRot
	Make/O/D/N=(rows * cols, 3) ATH_FitCoeff // Fit coefficients per pixel
	variable V_FitError
	variable errorCnt = 0
	// *****************************************************************	
	Make/FREE/T ATH_Constraints = {"K1>1e-3","K2 > -pi/2", "K2 <= pi/2"} // N.B: Set here constrains
	// Let's fit all pixels in the image
	if(fastFit)
//		for(i = 0; i < rows; i++)
//			for(j = 0; j < cols; j++)
//				// /S keeps scaling in MatrixOP
//				// N.B. If you add /FREE here the scaling will be lost!!!
//				MatrixOP/O/S freeData = beam(wRef, i, j)
//				WaveStats/M=1/Q freeData // Makes it slower, but initial guess is better. Is it helpful?
//				V_FitError = 0 // Set it to zero before the fit
//				ATH_Coef = {V_avg, 0.5*(V_max-V_min),0.1} // N.B!! You might need to play a bit with the initial guess
//				FuncFit/Q $fitFunc, kwCWave=ATH_Coef, freeData /D /C=ATH_Constraints
//				if(V_FitError)
//					// Deal with error here....
//					errorCnt++
//				endif
//				ATH_FitCoeff[i][j][] = ATH_Coef[r]
//			endfor
//		endfor

		MultiThreadingControl setMode=0	
		MultiThread ATH_FitCoeff = MyWorkerFitFunc(wRef, p, fitFunc, firstAngle, angleStep, fastFit, ATH_Constraints)
		MultiThreadingControl setMode=1	
	
	else
		// *****************************************************************
		// How many initial guesses for phase do you want to try?
		// Enter the values in curly brackets.
		// ******************************************************
		Make/FREE initialGuessPhaseW = {-pi/4,0,pi/4}; // <<<<<<<
		// ******************************************************
		variable kmax = numpnts(initialGuessPhaseW)
		Make/FREE/N=(kmax) chisqList
		Make/FREE/N=(kmax,3) coeffW
		for(i = 0; i < rows; i++)
			for(j = 0; j < cols; j++)
				// /S keeps scaling in MatrixOP
				// N.B. If you add /FREE here the scaling will be lost!!!
				MatrixOP/O/S freeData = beam(wRef, i, j)
				WaveStats/M=1/Q freeData // Makes it slower, but initial guess is better.
				V_FitError = 0 // Set it to zero before the fit
				for(k=0;k<kmax;k++)
					ATH_Coef = {V_avg, 0.5*(V_max-V_min),initialGuessPhaseW[k]} // N.B!! You might need to play a bit with the initial guess
					FuncFit/Q $fitFunc, kwCWave=ATH_Coef, freeData /D /C=ATH_Constraints
					coeffW[k][] = ATH_Coef[q]
					chisqList[k] = V_chisq // Goodness of fit
				endfor
				if(V_FitError)
					// Deal with error here....
					errorCnt++
				endif
				ATH_FitCoeff[i][j][] = coeffW[ATH_WaveOp#GetWaveMinPos(chisqList)][r] // Get the fitted coeff with the lower V_chisq
			endfor
		endfor
	endif
	// ---
	string mapBaseNameStr = NameofWave(wRef) + "_map"
	string mapNameStr = CreateDataObjectName(dfr, mapBaseNameStr, 1, 0 ,1)	
	// Write the coefficients to waves		
	MatrixOP $(mapNameStr+"_offset") = layer(ATH_FitCoeff, 0)
	MatrixOP $(mapNameStr+"_amplitude") = layer(ATH_FitCoeff, 1)
	MatrixOP $mapNameStr = layer(ATH_FitCoeff, 2)*57.29577951 // From rad to deg
	print "Total fit errors ", errorCnt
	string metadata = "FuncFit: "+ fitFunc + "."
	metadata += "Fitting constrains: {"+RemoveEnding(ATH_TWave#TextWaveToString(ATH_Constraints, sep=","))+"}."
	metadata += "Function parameters: firstAngle="+num2str(firstangle)+" ,angleStep="+num2str(angleStep)
	metadata += ", fastFit="+num2str(fastFit)+". Total fit errors: "+num2str(errorCnt)	
	Note $(mapNameStr+"_offset"), metadata
	Note $(mapNameStr+"_amplitude") , metadata
	Note $mapNameStr, metadata
	CopyScales wRef, $mapNameStr, $(mapNameStr+"_amplitude"), $(mapNameStr+"_offset")
	KillWaves/Z W_sigma, ATH_FitCoeff, fit__free_ // Cleanup the garbage
End	

ThreadSafe static Function MyWorkerFitFunc(WAVE wRef, variable j, string fitFunc, variable firstAngle, 
variable angleStep, variable fastFit, WAVE/T Constraints)
	// Fill in here
	// N.B. If you add /FREE here the scaling will be lost!!!
	variable V_FitError, errorCnt = 0
	string fdW = "freeData_" + num2str(j)
	MatrixOP/O/S $fdW = col(wRef, j)
	SetScale/P x, firstAngle, angleStep, $fdW // Set the scale, and FoVRot	
	WaveStats/M=1/Q $fdW // Makes it slower, but initial guess is better. Is it helpful?
	V_FitError = 0 // Set it to zero before the fit
	Make/FREE ATH_Coef = {V_avg, 0.5*(V_max-V_min),0.1} // N.B!! You might need to play a bit with the initial guess
	// Add the fit here.
	FuncFit/Q $fitFunc, kwCWave=ATH_Coef, $fdW /D /C=Constraints
	if(V_FitError)
		// Deal with error here....
		errorCnt++
	endif
	return 0
End