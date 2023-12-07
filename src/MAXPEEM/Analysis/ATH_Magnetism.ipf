#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_Magnetism
#pragma version = 1.01
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

static Function/WAVE WAVECalculateXMCD(WAVE w1, WAVE w2)
	/// Calculate XMCD/XMLD of two images
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02)) // if your wave are not 32-bit integers /SP
		Redimension/S w1, w2
	endif
	Duplicate/FREE w1, wxmcd
	wxmcd = (w1 - w2)/(w1 + w2)
	return wxmcd
End

static Function CalculateXMCD(WAVE w1, WAVE w2, string wxmcdStr)
	/// Calculate XMCD/XMLD of two images and save it to 
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	/// @param wxmcd string Wavemane of calculated XMCD/XMLD
	
	// Calculation of XMC(L)D using SP waves
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02))
		Redimension/S w1, w2
	endif
	Duplicate/O w1, $wxmcdStr
	WAVE wref = $wxmcdStr
	wref = (w1 - w2)/(w1 + w2)
End

static Function CalculateXMCDToWave(WAVE w1, WAVE w2, WAVE wXMCD)
	/// Calculate XMCD/XMLD of two images and save it to 
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	/// @param wXMCD WAVE Calculated XMCD/XMLD wave 
	
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02))
		Redimension/S w1, w2
	endif

	wXMCD = (w1 - w2)/(w1 + w2)
End

static Function CalculateXMCDFromStackToWave(WAVE w3d, WAVE wXMCD)
	/// Calculate XMCD/XMLD of two images and save it to 
	/// @param w13d WAVE Wave with 2 layers.
	/// @param wXMCD WAVE Calculated XMCD/XMLD wave 
	
	if(DimSize(w3d, 2) != 2)
		return -1
	endif	
	if(!(WaveType(w3d) & 0x02 && WaveType(wXMCD) & 0x02))
		Redimension/S w3d, wXMCD
	endif

	MatrixOP/O wXMCD = (layer(w3d,0) - layer(w3d,1))/(layer(w3d,0) + layer(w3d,1))
End

static Function CalculateWaveSumFromStackToWave(WAVE w3d, WAVE wSum)
	
	if(DimSize(w3d, 2) != 2)
		return -1
	endif	
	if(!(WaveType(w3d) & 0x02 && WaveType(wSum) & 0x02))
		Redimension/S w3d, wSum
	endif

	MatrixOP/O wSum = (layer(w3d,0) + layer(w3d,1))/2
End

static Function CalculateXMCD3D(WAVE w3d1, WAVE w3d2)
	// Calculate XMC(L)D for 3D waves over layers.
	// XMC(L)D = (w3d1 - w3d2)/(w3d1 + w3d2)
	if(WaveDims(w3d1) != 3 || WaveDims(w3d2) != 3 || (DimSize(w3d1, 2) != DimSize(w3d2, 2)))
		return -1
	endif
	if((DimSize(w3d1, 0) != DimSize(w3d2, 0)) || (DimSize(w3d1, 1) != DimSize(w3d2, 1)) )
		return -1
	endif
	if(WaveType(w3d1) & 0x10) // If WORD (int16)
		Redimension/S w3d1
	endif

	if(WaveType(w3d2) & 0x10) // If WORD (int16)
		Redimension/S w3d2
	endif
	DFREF currDFR = GetDataFolderDFR()
	string saveWaveName = CreatedataObjectName(currDFR, "XMCD3d", 1, 0, 1)
	MatrixOP $saveWaveName = (w3d1 - w3d2)/(w3d1 + w3d2)
	string noteStr = "XMC(L)D = (w1 - w2)/(w1 + w2)\nw1: " + NameOfWave(w3d1) + "\nw2: " + NameOfWave(w3d2)
	CopyScales w3d1, $saveWaveName
	Note $saveWaveName, noteStr
	return 0
End

static Function XMCDCombinations(WAVE w3d)
	/// Calculate XMC(L)D = (w3d1 - w3d2)/(w3d1 + w3d2)
	/// for all different layer combinations of w3d,
	if(WaveDims(w3d) != 3)
		return -1
	endif
	variable nlayers = DimSize(w3d, 2), i, j, cnt = 0
	variable nL = nlayers*(nlayers-1)/2 // all combinations
	string buffer = "" 
	string noteStr = "Source: " + GetWavesDataFolder(w3d, 2) + "\n"
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	for(i = 0; i < nlayers; i++)
		MatrixOP/FREE iLayer = layer(w3d, i)
		for(j = 0; j < i; j++)
			MatrixOP/FREE jLayer = layer(w3d, j)
			buffer = "ATHWaveToStack_idx_" + num2str(cnt)
			CalculateXMCD(iLayer, jLayer, buffer)
			noteStr += num2str(cnt) + ": (" + num2str(IndexToScale(w3d, i, 2)) \
					+", "+ num2str(IndexToScale(w3d, j, 2))+")\n"
			cnt += 1
		endfor	
	endfor
	ImageTransform/NP=(nL) stackImages $"ATHWaveToStack_idx_0"
	WAVE M_Stack
	CopyScales w3d, M_Stack
	Note M_stack, noteStr
	string saveStackNameStr = CreatedataObjectName(saveDF, "XMCD_Comb", 1, 0, 1)
	MoveWave M_stack, saveDF:$saveStackNameStr
	SetDataFolder saveDF
	return 0
End

//@
//	Function to calculate an XMLD map. The function ATH_FuncFit#XMLDIntensity is fitted to 
//  all beams of a 3D wave containing data from XMLD images obtained with different inclination
//  angles (direction of the E-field of x-rays). Model assumets that XMLD singal follows the 
//  relationship I = A + B * sin(x + φ)^2, where A, B and φ are the fitting parameters.
//
//	## Parameters
//	wRef : WAVE
//		A 3D wave that contains the data of all inclination angles in ascending order.
//		The codes assumes that all angles from -90 to 90 are included. Note that -90 and 90
//		refer to the same angle.
//
//		!!! Here the angle 90 should be the last layer of the stack. For example if you have
//			taken the full map (-80, 90) with angular step of 10° then your first stack is for
//		-80 degrees angle and the last at 90 (18 layers in total)
//
//		lowAngleDeg : variable
// 		Lowest angle for XMLD map in **degrees** (expected -90 or -80 deg)
//
//	angleStep : variable
// 		Angular step along the z-direction in **degrees**.
//
//	## Returns
//	variable
//		A unique 2D wave NameOfWave(wRef) + "_XMLDMap" is created (+num2str(N)))
//		0 - map calculations completed
//		1 - input wave was not a 3D wave
//@

// The main challenge here is the initial conditions as we have a non-linear fit.
// Function CalculateXMLDMap tries different initial conditions for the phase shift
// and picks up the solution for the minimum of the cost function. Of course this increases
// the time needed to complete the operation by N, where N is the number of phase tries.
//
//
// NOTE: The program is not yet fully tested and optimised. 
//

static Function CalculateXMLDMap(WAVE wRef, variable lowAngleDeg, variable angleStepDeg)

	// In FuncFit if you want to use Trust-region Levenberg-Marquardt ordinary least-squares method
	// Do the folowing
	// variable V_FitError
	// V_FitError = 0 // Set it to zero before the fit
	// FuncFit/Q/ODR=1 ...
	// if(V_FitError)
	//     // deal with the erroe
	//     continue
	// endif
	//	
	// For more info:
	//
	// DisplayHelpTopic "Special Variables for Curve Fitting"
	//
	//
	//
	// -------------------------------------------------------------------------------------
	// Bit 1: Robust Fitting
	// You can get a form of robust fitting where the sum of the absolute deviations is 
	// minimized rather than the squares of the deviations, which tends to de-emphasize 
	// outlier values. To do this, create V_FitOptions and set bit 1 (variable V_fitOptions=2).
	// Warning 1: No attempt to adjust the results returned for the estimated errors or 
	// for the correlation matrix has been made. You are on your own.
	// Warning 2: Don't set this bit and then forget about it.
	// Warning 3: Setting Bit 1 has no effect on line, poly or poly2D fits.
	// -------------------------------------------------------------------------------------
	//
	// So after the fir set V_fitOptions=0
	//
	//
	variable angleStepRad = angleStepDeg * pi/180
	variable lowAngleRad = lowAngleDeg * pi/180
	variable rows = DimSize(wRef, 0)
	variable cols = DimSize(wRef, 1)
	variable layers = DimSize(wRef, 2)
	if(!layers)
		return 1
	endif
	variable i, j, cnt
	string mapBaseNameStr = NameofWave(wRef) + "_XMLDMap"
	string mapNameStr = CreateDataObjectName(dfr, mapBaseNameStr, 1, 0 ,1)
	Make/N=(rows, cols) $mapNameStr, $(mapNameStr+"_Off"), $(mapNameStr+"_y0")
	WAVE wphase = $mapNameStr
	WAVE woff = $(mapNameStr+"_Off")
	WAVE wfact = $(mapNameStr+"_y0")
	// Get the fitting stuff ready
	// K0 + K1 * sin(x + K2)^2
	Make/FREE/D/N=3 ATH_Coef
	Make/FREE/T/N=3 ATH_Constraints = {"K1 > 1.0e-5", "K2 > -pi/2", "K2 <= pi/2"}
	Make/FREE/N=(layers) freeData
	SetScale/P x, lowAngleDeg , angleStepRad, freeData // Careful here
	variable V_chisq
	Make/FREE seedW = {0, 0.5, -0.5, 1, -1, 2, -2} // EDIT HERE: Add your initial guesses
	variable numSeeds = DimSize(seedW, 0)
	Make/O/D/N=(numSeeds, 4, 1024, 1024) ATH_FitCoeff
	for(i = 0; i < rows; i++)
		for(j = 0; j < cols; j++)
			// /S keeps scaling.
			// NOTE: If you add /FREE here the scaling will be lost!!!
			MatrixOP/O/S freeData = beam(wRef, i, j)
			cnt = 0
			for(cnt = 0;cnt < numSeeds; cnt++)
				ATH_Coef = {1, 1, seedW[cnt]} // Initialise
				FuncFit/Q ATH_FuncFit#XMLDIntensity, ATH_Coef, freeData /D /C=ATH_Constraints	
				ATH_FitCoeff[cnt][,][i][j] = {{ATH_Coef[0]}, {ATH_Coef[1]}, {ATH_Coef[2]}, {V_chisq}} // Fill in ATH_FitCoeff
			endfor
		endfor
	endfor
	WaveStats/M=1/PCST ATH_FitCoeff
	WAVE M_WaveStats
	for(i = 0; i < rows; i++)
		for(j = 0; j < cols; j++)
			cnt = M_WaveStats[%minLoc][3][i][j] // Min V_chisq
			// Fill in the 2D waves with y0, A, and φ.
			woff[i][j] =  ATH_FitCoeff[cnt][0][i][j]
			wfact[i][j] = ATH_FitCoeff[cnt][1][i][j]
			wphase[i][j] = ATH_FitCoeff[cnt][2][i][j]*180/pi
		endfor
	endfor
	KillWaves/Z W_sigma, fit__free_ // Cleanup the garbage
End
