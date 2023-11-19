#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

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

Function/WAVE ATH_WAVECalculateXMCD(WAVE w1, WAVE w2)
	/// Calculate XMCD/XMLD of two images
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02)) // if your wave are not 32-bit integers /SP
		Redimension/S w1, w2
	endif
	Duplicate/FREE w1, wxmcd
	wxmcd = (w1 - w2)/(w1 + w2)
	return wxmcd
End

Function ATH_CalculateXMCD(WAVE w1, WAVE w2, string wxmcdStr)
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

Function ATH_CalculateXMCDToWave(WAVE w1, WAVE w2, WAVE wXMCD)
	/// Calculate XMCD/XMLD of two images and save it to 
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	/// @param wXMCD WAVE Calculated XMCD/XMLD wave 
	
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02))
		Redimension/S w1, w2
	endif

	wXMCD = (w1 - w2)/(w1 + w2)
End

Function ATH_CalculateXMCDFromStackToWave(WAVE w3d, WAVE wXMCD)
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

Function ATH_CalculateWaveSumFromStackToWave(WAVE w3d, WAVE wSum)
	
	if(DimSize(w3d, 2) != 2)
		return -1
	endif	
	if(!(WaveType(w3d) & 0x02 && WaveType(wSum) & 0x02))
		Redimension/S w3d, wSum
	endif

	MatrixOP/O wSum = (layer(w3d,0) + layer(w3d,1))/2
End

Function ATH_CalculateXMCD3D(WAVE w3d1, WAVE w3d2)
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

Function ATH_XMCDCombinations(WAVE w3d)
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
			ATH_CalculateXMCD(iLayer, jLayer, buffer)
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
//	angleStep : variable
// 		Angular step along the z-direction in **degrees**.
//
//	## Returns
//	variable
//		A unique 2D wave NameOfWave(wRef) + "_XMLDMap" is created (+num2str(N)))
//		0 - map calculations completed
//		1 - input wave was not a 3D wave
//@
Function ATH_CalculateXMLDMap(WAVE wRef, variable angleStep)

	variable angleStepRad = angleStep * pi/180
	variable rows = DimSize(wRef, 0)
	variable cols = DimSize(wRef, 1)
	variable layers = DimSize(wRef, 2)
	if(!layers)
		return 1
	endif
	variable i, j
	string mapBaseNameStr = NameofWave(wRef) + "_XMLDMap"
	string mapNameStr = CreateDataObjectName(dfr, mapBaseNameStr, 1, 0 ,1)
	Make/N=(rows, cols) $mapNameStr, $(mapNameStr+"_offset"), $(mapNameStr+"_factor")
	WAVE wxmld = $mapNameStr
	WAVE woff = $(mapNameStr+"_offset")
	WAVE wfact = $(mapNameStr+"_factor")
	// Get the fitting stuff ready
	Make/FREE/D/N=3 ATH_Coef
	Make/FREE/T/N=3 ATH_Constraints
	ATH_Constraints[0] = {"K2 > -pi/2", "K2 <= pi/2"} // angular constrain and Julian's comment re K1.
	Make/FREE/N=(layers) freeData
	SetScale/P x, (-pi/2 + angleStepRad), angleStepRad, freeData
	Make/FREE/N=(layers) xScaleW = pnt2x(freeData, p)
	variable meanV, minV, maxV // use these to make a reasonable initial conditions guess

	for(i = 0; i < rows; i++)
		for(j = 0; j < cols; j++)
			// /S keeps scaling. 
			// NOTE: If you add /FREE here the scaling will be lost!!!
			MatrixOP/O/S freeData = beam(wRef, i, j)
			meanV = mean(freeData)
			[minV, maxV] = WaveMinAndMax(freeData)
			ATH_Coef[0] = meanV
			ATH_Coef[1] = (maxV - minV)/2
			ATH_Coef[2] = freeData[9] > meanV ? -pi/4 : pi/4
			FuncFit/Q ATH_FuncFit#XMLDIntensity, ATH_Coef, freeData /D /C=ATH_Constraints /X=xScaleW
			wxmld[i][j] = ATH_Coef[2]*180/pi
			woff[i][j] = ATH_Coef[0]
			wfact[i][j] = ATH_Coef[1]
		endfor
	endfor
	KillWaves/Z W_sigma, fit__free_ // Cleanup the garbage
End