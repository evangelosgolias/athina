#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_ImgFilter
#pragma version = 1.0

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


/// @module ATH_ImageFilter
/// @brief Module ATH_ImageFilter.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH ImageFilter functionality.

static constant kCBOFFSET = 30 // height slider in 3d waves

static Function/WAVE ThresholdImageRangeToMask([string grfName, variable minV, variable maxV, int complexM])
	// Apply custom ImageThreshold to top image based on current ctab values
	// Mask created with 0 and 1 values. The operation is applied on mag, real, imag or phase
	// space depending on the mode the complex FFT wave is displayed.
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName=grfName)
	//DFREF dfr = GetWavesDataFolderDFR(wRef)
	//string makeWaveName = CreateDataObjectName(dfr, NameOfWave(wRef)+"_Mask" , 1, 0, 1)
	//string makeWaveName = NameOfWave(wRef)+"_Mask"
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
	variable low = min(valMin, valMax)
	variable high = max(valMin, valMax)
	MatrixOP/FREE athThresholdMask = within(tw1, low, high)
	CopyScales wRef, athThresholdMask
	if(complexM)
		Redimension/S/C athThresholdMask
	endif
	return athThresholdMask
End

//// -----------------------------------------------------------------
//// iFFTFilter Panel

/// @function iFFTImgFilter
/// @brief Description of iFFTImgFilter.
/// @details
/// Auto-generated documentation stub for function `iFFTImgFilter`.
/// @param wRef Parameter wRef.
/// @returns Variable Return value.

static Function iFFTImgFilter(WAVE wRef)
	DFREF saveDF = GetDataFolderDFR()
	string winNameStr = ATH_Display#NewImg(wRef)
	KillWindow $winNameStr
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iImgFFTFilter:"+winNameStr, setDF=1)
	Duplicate/O wRef, wSrc, wSrc_undo
	ATH_Display#NewImg(wSrc,grfName=winNameStr) // Restart using the same winName
	FFT/DEST=wSrc_fft wSrc	// FFT simple										
	Duplicate/O wSrc_fft, wSrc_fft_undo
	SetDataFolder saveDF
	//Note wRef_fft, "FFT " + GetWavesDataFolder(wRef,2)												
	string fftWinNameStr = ATH_Display#NewImg(wSrc_fft) // Display the FFT transfomed image
	ModifyImage/W=$fftWinNameStr wSrc_fft minRGB=(65535,16385,16385),maxRGB=(65535,0,0)
	//Set globals
	variable/G dfr:gATH_Gx = 0
	variable/G dfr:gATH_Gy = 0
	string/G dfr:gATH_meta = ""
	// End of globals
	DoWindow/T $fftWinNameStr, "FFT -" +  NameOfWave(wRef)
	AutopositionWindow/M=0/R=$winNameStr $fftWinNameStr
	variable lCBOFFSET 
	ControlInfo kwControlBar
	lCBOFFSET = V_height	
	ControlBar/W=$fftWinNameStr lCBOFFSET + kCBOFFSET
	NVAR/SDFR=dfr gATH_Gx, gATH_Gy
	variable maxFrequency = 1 / (2 * DimDelta(wRef, 1))
	// Add two SetVariables for Gx, Gy
	SetVariable IFsetGxSV, title ="Gx", pos={10,(4+lCBOFFSET)},help={"σ_x of Guassian"},value = gATH_Gx,win=$fftWinNameStr
	SetVariable IFsetGySV,  title ="Gy", pos={90,(4+lCBOFFSET)},help={"σ_y of Guassian"},value = gATH_Gy,win=$fftWinNameStr
	Button ifDenoiseB pos={170,(4+lCBOFFSET)}, size={60,20}, title="Denoise",win=$fftWinNameStr
	Button ifDenoiseB help = {"Filter image, IFFT of the Fourier image."},win=$fftWinNameStr
	Button ifMaskB pos={240,(4+lCBOFFSET)}, size={50,20}, title="Mask",win=$fftWinNameStr
	Button ifMaskB help = {"Apply threshold (Range panel) or Gaussian windowing (Gx, Gy)"},win=$fftWinNameStr
	Button ifrestoreB pos={300,(4+lCBOFFSET)}, title="Restore", size={60,20},help = {"Restore image and FFT"},win=$fftWinNameStr
	Button ifsaveB pos={370,(4+lCBOFFSET)}, title="Save", size={50,20},help = {"Save filtered image"},win=$fftWinNameStr
	// Modifications
	ModifyControlList ControlNameList(fftWinNameStr,";","if*B") mode=1, proc=ATH_ImgFilter#iImgFilterButton, fsize=13, win=$fftWinNameStr
	ModifyControlList ControlNameList(fftWinNameStr,";","IF*SV") size={75,20}, limits={0,maxFrequency,0}
	ModifyControlList ControlNameList(fftWinNameStr,";","IF*SV") proc=ATH_ImgFilter#iImgFilterSetGValues, fsize=13, win=$fftWinNameStr
	SetWindow $fftWinNameStr userdata(iImgFilterDFREF) = "root:Packages:ATH_DataFolder:iImgFFTFilter:"+winNameStr
	SetWindow $fftWinNameStr userdata(iImgFilterSourceImagePath) = GetWavesDataFolder(wRef, 2)
	SetWindow $fftWinNameStr userdata(iImgFilterSourceImgWindow) = winNameStr
	SetWindow $fftWinNameStr hook(iImgFilterHookFunction) = ATH_ImgFilter#iImgFilterHookFunction
End

/// @function iImgFilterHookFunction
/// @brief Description of iImgFilterHookFunction.
/// @details
/// Auto-generated documentation stub for function `iImgFilterHookFunction`.
/// @param &s Parameter &s.
/// @returns Variable Return value.

Function iImgFilterHookFunction(STRUCT WMWinHookStruct &s)
		
	variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.
	
	switch(s.eventCode)
		case 2:	// Keyboard event
			DFREF dfr = $GetUserData(s.winName,"","iImgFilterDFREF")
			KillWindow/Z $GetUserData(s.winName,"","iImgFilterSourceImgWindow")
			Execute/Q/Z/P ("KillDataFolder/Z " + GetUserData(s.winName,"","iImgFilterDFREF"))
			break
	endswitch
	return hookResult		// If non-zero, we handled event and Igor will ignore it.
End

/// @function iImgFilterButton
/// @brief Description of iImgFilterButton.
/// @details
/// Auto-generated documentation stub for function `iImgFilterButton`.
/// @param &ba Parameter &ba.
/// @returns Variable Return value.

static Function iImgFilterButton(STRUCT WMButtonAction &ba) : ButtonControl
	if (ba.eventCode != 2)
		return 0
	endif
	DFREF dfr = $GetUserData(ba.win,"","iImgFilterDFREF")
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder dfr
	WAVE wSrc_fft, wSrc, WSrc_undo, wSrc_fft_undo
	WAVE/Z athThresholdMask
	NVAR gATH_Gx, gATH_Gy
	SVAR gATH_meta
	strswitch (ba.ctrlName)
		case "ifDenoiseB":
			Duplicate/O wSrc_fft, wSrc
			IFFT wSrc
			break
		case "ifMaskB":
			if(WinType(ba.win+"#ATH_Range") == 7)
				WAVE tMask = ATH_ImgFilter#ThresholdImageRangeToMask(grfName=ba.win,complexM=1)
				MatrixOP/O wSrc_fft= wSrc_fft*tMask
			endif
			if(gATH_Gx*gATH_Gy) // Both have to be non-zero
				Make/FREE/N=(DimSize(wSrc_fft,0),DimSize(wSrc_fft,1)) gaussWindow
				Copyscales wSrc_fft,gaussWindow
				gaussWindow = gauss(x,0,gATH_Gx,y,0,gATH_Gy)
				MatrixOP/O wSrc_fft= wSrc_fft*gaussWindow
			endif
			variable minCTV, maxCTV, reverseCmap, valMin, valMax
			string infoStr = ImageInfo(ba.win, StringFromList(0,ImageNameList(ba.win, ";"),";"), 0), cmap
			string ctabStr = StringByKey("RECREATION",infoStr)
			sscanf ctabStr, "ctab= {%g,%g,%[^,],%g}", minCTV, maxCTV, cmap, reverseCmap			
			gATH_meta="ATH_ImgFilter#ThresholdImageCTabToMask(minV="+num2str(minCTV)+",maxV="+num2str(maxCTV)+",complexM=1) " 
			gATH_meta +="of the result from •FFT " + GetUserData(ba.win,"","iImgFilterSourceImagePath") + ", " 
			gATH_meta +="after gaussian windowing with σx="+num2str(gATH_Gx)+" and σy="+num2str(gATH_Gy)
			break
		case "ifrestoreB":
			gATH_Gx = 0; gATH_Gy = 0
			Duplicate/O wSrc_undo, wSrc
			Duplicate/O wSrc_fft_undo, wSrc_fft
			break
		case "ifsaveB":
			string srcImgName = ParseFilePath(0, GetUserData(ba.win,"","iImgFilterSourceImagePath"), ":", 1, 0)
			DFREF srcDF = $ParseFilePath(1, GetUserData(ba.win,"","iImgFilterSourceImagePath"), ":", 1, 0)
			string saveNameStr = CreateDataObjectName(srcDF, srcImgName + "_iFFTFilter", 1, 0, 1)
			Duplicate dfr:wSrc, srcDF:$saveNameStr
			Note srcDF:$saveNameStr, gATH_meta
			break
	endswitch
	SetDataFolder saveDF
	return 0
End

/// @function iImgFilterSetGValues
/// @brief Description of iImgFilterSetGValues.
/// @details
/// Auto-generated documentation stub for function `iImgFilterSetGValues`.
/// @param &sva Parameter &sva.
/// @returns Variable Return value.

static Function iImgFilterSetGValues(STRUCT WMSetVariableAction &sva) : SetVariableControl
	DFREF dfr = $GetUserData(sva.win,"","iImgFilterDFREF")
	NVAR/SDFR=dfr gATH_Gx, gATH_Gy	
	switch (sva.eventCode)
		case 1:
		case 2:
		case 3: 							// Live update
	strswitch (sva.ctrlName)
		case "IFsetGxSV":
			gATH_Gx = sva.dval
			break
		case "IFsetGySV":
			gATH_Gy = sva.dval
			break
		endswitch			
			break
		case -1: 							// Control being killed
			break
	endswitch
	return 0
End
	
End
//// -----------------------------------------------------------------
//// End of  iFFTFilter Panel 
