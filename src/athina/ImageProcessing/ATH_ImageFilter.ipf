#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_ImgFilter
#pragma version = 1.0

// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: egolias@protonmail.com
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


static Function ThresholdImageRangeToMask([string grfName, variable minV, variable maxV])
	// Apply custom ImageThreshold to top image based on current ctab values
	// Mask created with 0 and 1 values. The operation is applied on mag, real, imag or phase
	// space depending on the mode the complex FFT wave is displayed.
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	//DFREF dfr = GetWavesDataFolderDFR(wRef)
	//string makeWaveName = CreateDataObjectName(dfr, NameOfWave(wRef)+"_Mask" , 1, 0, 5)
	string makeWaveName = NameOfWave(wRef)+"_Mask"
	string infoStr = ImageInfo(grfName, StringFromList(0,ImageNameList(grfName, ";"),";"), 0)	
	string ctabStr = StringByKey("RECREATION",infoStr)
	variable minCTV, maxCTV, reverseCmap, valMin, valMax; string cmap
	sscanf ctabStr, "ctab= {%g,%g,%[^,],%g}", minCTV, maxCTV, cmap, reverseCmap
	valMin = minV ? minV : minCTV
	valMax = maxV ? maxV : maxCTV

	int isCmplx = WaveType(wRef) & 0x01
	int is3D = WaveDims(wRef) == 3
	
	variable plane = NumberByKey("plane", infoStr, "=")
	int mode = NumberByKey("imCmplxMode", infoStr, "=")

	if (is3D)
		MatrixOP/FREE tw0 = layer(wRef, plane)
	else
		//	If "Wave tw0 = w" is used, pnlHookParent in SIDAM_range.ipf is called
		//	repeately for real 2D waves, and causes a trouble.
		MatrixOP/FREE tw0 = wRef
	endif
	// Complex wave display mode
	if (isCmplx)
		switch (mode)
			case 0:	//	magnitude
				MatrixOP/FREE tw1 = mag(tw0) // Default with /C and NewImg
				break
			case 1:	//	real
				MatrixOP/FREE tw1 = real(tw0)
				break
			case 2:	//	imaginary
				MatrixOP/FREE tw1 = imag(tw0)
				break
			case 3:	//	phase
				MatrixOP/FREE tw1 = phase(tw0)
				break
		endswitch
	else
		Wave tw1 = tw0
	endif
	MatrixOP/S/O $makeWaveName = within(tw1, valMin, valMax)
	Redimension/S $makeWaveName	
	CopyScales wRef, $makeWaveName
	string wnote = "ATH_ImgFilter#ThresholdImageCTabToMask(grfName="+grfName+",minV="+num2str(valMin)+",maxV="+num2str(valMax)+")"
	Note $makeWaveName, wnote
End

	