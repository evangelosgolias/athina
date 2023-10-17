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
	Wave wref = $wxmcdStr
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