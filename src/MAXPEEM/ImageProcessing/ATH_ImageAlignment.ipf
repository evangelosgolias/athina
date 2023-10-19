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

Function/WAVE ATH_WAVEImageAlignmentByRegistration(WAVE w1, WAVE w2)
	/// Align two images using ImageRegistration operation. 
	/// Only x, y translations are allowed.
	/// @param w1 wave reference First wave (reference wave)
	/// @param w2 wave reference Second wave (test wave)
	/// @return alignedW w2 aligned with w1 as reference.
	if(!(WaveType(w1) & 0x02))
		Redimension/S w1
	endif
	if(!(WaveType(w2) & 0x02))
		Redimension/S w2
	endif
	Duplicate/FREE w2, w2copy
	ImageRegistration/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/TSTM=0/BVAL=0 refWave = w1, testWave = w2copy
	WAVE M_RegOut, M_RegOut, M_RegMaskOut
	Duplicate/FREE M_RegOut, alignedW
	KillWaves/Z M_RegOut, M_RegOut, M_RegMaskOut
	return alignedW
End

Function ATH_ImageAlignmentByRegistration(WAVE w1, WAVE w2)
	/// Align two images using ImageRegistration operation. 
	/// Only x, y translations are allowed.
	/// @param w1 wave reference First wave (reference wave)
	/// @param w2 wave reference Second wave (test wave)
	string msg
	sprintf msg, "ImageRegistration with refWave = %s and testWave = %s.", NameOfWave(w1), NameOfWave(w2)
	print msg		

	if(!(WaveType(w1) & 0x02))	
		Redimension/S w1
	endif
	if(!(WaveType(w2) & 0x02))
		Redimension/S w2
	endif 
	ImageRegistration/Q/TRNS={1,1,0}/ROT={0,0,1}/TSTM=0/BVAL=0 refWave = w1, testWave = w2
	WAVE M_RegOut
	Duplicate/O M_RegOut, w2	
	KillWaves/Z M_RegOut, M_RegMaskOut, W_RegParams
	return 0
End

Function ATH_ImageStackAlignmentByRegistration(WAVE w3d, [variable layerN, 
		 variable cutoff, int selfDrift, int printMode, int convMode])
	/// Align a 3d wave using ImageRegistration. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise 
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param layerN int optional Reference layer for ImageRegistration.
	/// @param cutoff max drift allowed
 	/// @param printMode int optional print drift of each layer
	/// @param convMode int optional Select convergence method /CONV = 0, 1 for Gravity (fast) or Marquardt (slow), respectively.
	/// @param selfDrift Drift original or a copy of the wave
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then 0 is your choice
	convMode = ParamIsDefault(convMode) ? 0: convMode // convMode = 0, 1 
	printMode = ParamIsDefault(printMode) ? 0: printMode
	cutoff = ParamIsDefault(cutoff) ? 0: cutoff
	selfDrift = ParamIsDefault(selfDrift) ? 1 : 0 // Default: 1, drift-correct the original wave w3d (unprocessed).
	
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	
	MatrixOP/FREE refLayerWave = layer(w3d, layerN) 

	ImageRegistration/Q/STCK/PSTK/TRNS={1,1,0}/ROT={0,0,0}/TSTM=0/BVAL=0/CSNR=0/CONV=(convMode) refwave = refLayerWave, testwave = w3d	

	WAVE M_RegOut, M_RegMaskOut, M_RegParams
	MatrixOP/FREE dxL = row(M_RegParams, 0)
	MatrixOP/FREE dyL = row(M_RegParams, 1)	
	
	if(cutoff) // Cutoff only if set, if 0 pass
		dxL = (abs(dxL) > cutoff) ? 0 : dxL
		dyL = (abs(dyL) > cutoff) ? 0 : dyL
	endif
	
	variable nlayers = DimSize(w3d, 2)
	
	if(!selfDrift) // Do not drift w3d, drift the unprocessed copy
		string backupWavePathStr = GetWavesDataFolder(w3d, 1) + PossiblyQuoteName(NameOfWave(w3d) + "_undo")
		if(WaveExists($backupWavePathStr)) // If you use the original wave for drifting and the backup wave exists
			WAVE wRefCopy = $backupWavePathStr
			if(!(WaveType(wRefCopy) & 0x02))
				Redimension/S wRefCopy
			endif
		else
			print backupWavePathStr + " not found"
			return -1
		endif
		variable dx, dy, i
		DFREF saveDF = GetDataFolderDFR()
		SetDataFolder NewFreeDataFolder()
		for(i = 0; i < nlayers; i++)
			dx = dxL[i]; dy = dyL[i]
			if(dx == 0 && dy == 0)
				MatrixOP/O $("getStacklayer_" + num2str(i)) = layer(wRefCopy, i)
			else
				MatrixOP/O targetLayer = layer(wRefCopy, i)
				ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D targetLayer
				WAVE M_Affine
				Rename M_Affine, $("getStacklayer_" + num2str(i))
			endif
		endfor
		ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
		WAVE M_Stack
		// Restore scale here
		CopyScales wRefCopy, M_Stack
		Duplicate/O M_Stack, saveDF:$NameofWave(w3d)
		SetDataFolder saveDF
	else
		CopyScales w3d, M_RegOut
		Duplicate/O M_RegOut, w3d
		KillWaves/Z M_RegOut, M_RegMaskOut, M_RegParams
	endif
	
	if(printmode)
		string driftLog = ""
		driftLog = "Called ATH_ImageStackAlignmentByRegistration\n"
		driftLog += "Ref. Layer = " + num2str(layerN) + "\n"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
		if(cutoff && selfdrift)
			driftLog +=  ">>> Cutoff skipped <<<\n"
		endif
		for(i = 0; i < nlayers; i++)
			if(dxL[i] == 0 && dyL[i] == 0)
				driftLog +=  num2str(i) + ": Pass [cutoff: " + num2str(cutoff) +"]" + "\n"
			else
				driftLog +=  num2str(i) + ": "+ num2str(dxL[i]) + "    " + num2str(dyL[i]) + "\n"
			endif
		endfor
	endif
	
	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif	
	
	return 0
End

Function ATH_ImageStackAlignmentByCorrelation(WAVE w3d, [variable layerN, int printMode, variable cutoff, int selfDrift])
	/// Align a 3d wave using (auto)correlation. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise. 
	/// Only integer x, y translations are calculated.
	/// @param w3d wave 3d we want to aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.
	/// @param printMode int optional print the drift corrections in pixels
	/// @param cutoff max drift allowed
	/// @param selfDrift Drift original (1) or a copy of the wave (0)
	/// When selfDrift is True, w3d is wave to drift-corrrect, assumed unpreprocessed.
	/// Otherwise, we drift correct  the backup of w3d, (NameOfWave(w3d)+"_undo"), which is
	/// created by the Launcher ATH_LaunchImageStackAlignmentFullImage() before entering here.
	
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then 0 is your choice
	printMode = ParamIsDefault(printMode) ? 0: printMode
	selfDrift = ParamIsDefault(selfDrift) ? 1 : 0
	
	string backupWavePathStr = GetWavesDataFolder(w3d, 1) + PossiblyQuoteName(NameOfWave(w3d) + "_undo")
	if(!selfDrift) // We want to drift the copy
		if(WaveExists($backupWavePathStr)) // If you use the original wave for drifting and the backup wave exists
			WAVE wRefCopy = $backupWavePathStr
		else
			print backupWavePathStr + " not found"
			return -1
		endif
	endif
	
	variable i 
	if(printMode)
		string driftLog = "Called ATH_ImageStackAlignmentByCorrelation\n "
		driftLog += "Ref. Layer = " + num2str(layerN) + "\n"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
	endif

	DFREF saveDF = GetDataFolderDFR()
	DFREF saveWaveDF = GetWavesDataFolderDFR(w3d) // Location of w3d
	SetDataFolder NewFreeDataFolder()
	
	MatrixOP/O refLayerFreeWave = layer(w3d, layerN) // This layer is not FREE, we have to stack it using ImageTransform at the end
	
	if(!selfDrift)
		MatrixOP/O $("getStacklayer_" + num2str(layerN)) = layer(wRefCopy, layerN)
	else
		Duplicate refLayerFreeWave, $("getStacklayer_" + num2str(layerN))
	endif
	
	MatrixOP/FREE autocorrelationW = correlate(refLayerFreeWave, refLayerFreeWave, 0)
	WaveStats/M=1/Q autocorrelationW
	variable x0 = V_maxRowLoc, y0 = V_maxColLoc, x1, y1, dx, dy // x, y -> p, q
	variable nlayers = DimSize(w3d, 2)

	for(i = 0; i < nlayers; i++)
		if(i != layerN)
			MatrixOP/O freeLayer = layer(w3d, i)
			MatrixOP/O correlationW = correlate(refLayerFreeWave, freeLayer, 0)
			WaveStats/M=1/Q correlationW
			x1 = V_maxRowLoc
			y1 = V_maxColLoc
			dx = x0 - x1
			dy = y0 - y1
			if(cutoff)
				dx = (abs(dx) > cutoff) ? 0 : dx
				dy = (abs(dy) > cutoff) ? 0 : dy
			endif
			if(!selfDrift)
				if(dx||dy)
					MatrixOP/O freeLayer = layer(wRefCopy, i)
					ImageTransform/IOFF={dx, dy, 0} offsetImage freeLayer
					WAVE M_OffsetImage
					Rename M_OffsetImage, $("getStacklayer_" + num2str(i))
				else
					MatrixOP/O $("getStacklayer_" + num2str(i)) = layer(wRefCopy, i)
				endif
			else
				if(dx||dy)
					ImageTransform/IOFF={dx, dy, 0} offsetImage freeLayer
					WAVE M_OffsetImage
					Rename M_OffsetImage, $("getStacklayer_" + num2str(i))
				else
					Duplicate freeLayer, $("getStacklayer_" + num2str(i))
				endif
			endif
		endif
		if(printMode)
			if(dx == 0 && dy == 0)
				driftLog +=  num2str(i) + ": Pass [cutoff: " + num2str(cutoff) +"]" + "\n"
			else
				driftLog +=  num2str(i) + ": "+ num2str(dx) + "    " + num2str(dy) + "\n"
			endif
		endif
	endfor
	
	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales w3d, M_Stack
	Duplicate/O M_Stack, saveWaveDF:$NameofWave(w3d)
	
	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif
	SetDataFolder saveDF
	return 0
End

Function ATH_ImageStackAlignmentByPartitionRegistration(WAVE w3d, WAVE partitionW3d, [variable layerN, variable cutoff, variable printMode]) // Used in menu
	/// Align a 3d wave using ImageRegistration of a partition of the target 3d wave.
	/// The partition 3d wave calls ATH_ImageStackAlignmentByFullRegistration
	/// By default the function will  use the 0-th layer as a wave reference, uncless user chooses otherwise.
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param partitionW3d WAVE partition of w3d
	/// @layerN set the reference layer
	/// @printMode if set x, y drifts are printed in a notebook
	/// @cutoff if set max drift in pixels allowed
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then default is 0
	printMode = ParamIsDefault(printMode) ? 0: printMode
	cutoff = ParamIsDefault(cutoff) ? 0: abs(cutoff)
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	if(!(WaveType(partitionW3d) & 0x02))
		Redimension/S partitionW3d
	endif

	if(printMode)
		string driftLog = "Called ATH_ImageStackAlignmentByPartitionRegistration\n"
		driftLog += "Ref. Layer = " + num2str(layerN) + "\n"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
	endif

	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()

	MatrixOP/FREE refLayerWave = layer(partitionW3d, layerN)
	variable rows = DimSize(w3d, 0)
	variable cols = DimSize(w3d, 1)
	variable layers = DimSize(w3d, 2)
	ImageRegistration/Q/STCK/PSTK/TRNS={1,1,0}/ROT={0,0,0}/CSNR=0/TSTM=0/BVAL=0 refwave = refLayerWave, testwave = partitionW3d
	WAVE M_RegParams
	MatrixOP/FREE dx = row(M_RegParams,0)
	MatrixOP/FREE dy = row(M_RegParams,1)
	if(cutoff) // Cutoff only if set
		dx = (abs(dx) > cutoff) ? 0 : dx
		dy = (abs(dy) > cutoff) ? 0 : dy
	endif
	variable i
	for(i = 0; i < layers; i++)
		if((dx[i] == 0 && dy[i] == 0) || layerN == i)
			MatrixOP/O $("getStacklayer_" + num2str(i)) = layer(w3d, i) // Scaled in pixels!
		else
			MatrixOP/O getLayer = layer(w3d, i) // Scaled in pixels!
			ImageInterpolate/APRM={1,0,dx[i],0,1,dy[i],1,0}/DEST=$("getStacklayer_" + num2str(i)) Affine2D getLayer
		endif
		if(printMode)
			if(dx[i] == 0 && dy[i] == 0)
				driftLog +=  num2str(i) + ": Pass [cutoff: " + num2str(cutoff) +"]" + "\n"
			else
				driftLog +=  num2str(i) + ": "+ num2str(dx[i]) + "    " + num2str(dy[i]) + "\n"
			endif
		endif
	endfor
	ImageTransform/NP=(layers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales w3d, M_Stack
	Duplicate/O M_Stack, saveDF:$NameofWave(w3d)

	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif
	SetDataFolder saveDF
	return 0
End

Function ATH_ImageStackAlignmentByPartitionCorrelation(WAVE w3d, WAVE partitionW3d, [variable layerN, variable cutoff, int printMode, int windowing]) // Used in menu
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
	printMode = ParamIsDefault(printMode) ? 0: printMode
	windowing = ParamIsDefault(windowing) ? 0: windowing
	cutoff = ParamIsDefault(cutoff) ? 0: abs(cutoff)
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	if(!(WaveType(partitionW3d) & 0x02))
		Redimension/S partitionW3d
	endif

	DFREF saveDF = GetDataFolderDFR()
	DFREF saveWaveDF = GetWavesDataFolderDFR(w3d) // Location of w3d
	SetDataFolder NewFreeDataFolder()

	MatrixOP/FREE refLayerWave = layer(partitionW3d, layerN)
	if(windowing)
		ImageWindow/O Hanning refLayerWave
	endif
	MatrixOP/FREE autocorrelationW = correlate(refLayerWave, refLayerWave, 0)
	WaveStats/M=1/Q/P autocorrelationW
	variable p0 = V_maxRowLoc, q0 = V_maxColLoc, p1, q1, i
	variable layers = DimSize(w3d, 2)
	Make/FREE/N=(layers) dp, dq

	for(i = 0; i < layers; i++)
		if(i != layerN)
			MatrixOP/O/FREE freeLayer = layer(partitionW3d, i)
			if(windowing)
				ImageWindow/O Hanning freeLayer
			endif
			MatrixOP/O/FREE correlationW = correlate(refLayerWave, freeLayer, 0)
			WaveStats/M=1/Q/P correlationW
			p1 = V_maxRowLoc
			q1 = V_maxColLoc
			dp[i] = p0 - p1
			dq[i] = q0 - q1
		endif
	endfor

	if(printMode)
		string driftLog = "Called ATH_ImageStackAlignmentByPartitionCorrelation\n"
		driftLog += "Ref. Layer = " + num2str(layerN) + "\n"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
	endif

	if(cutoff) // Cutoff only if set
		dp = (abs(dp) > cutoff) ? 0 : dp
		dq = (abs(dq) > cutoff) ? 0 : dq
	endif

	//Now translate each wave in the stack (w3d)
	for(i = 0; i < layers; i++)
		if(dp[i] == 0 && dq[i] == 0)
			MatrixOP/O $("getStacklayer_" + num2str(i)) = layer(w3d, i)
		else
			MatrixOP/O/FREE getfreelayer = layer(w3d, i)
			ImageTransform/IOFF={dp[i], dq[i], 0} offsetImage getfreelayer
			WAVE M_OffsetImage
			Rename M_OffsetImage, $("getStacklayer_" + num2str(i))
		endif

		if(printMode)
			if(dp[i] == 0 && dq[i] == 0)
				driftLog +=  num2str(i) + ": Pass [cutoff: " + num2str(cutoff) +"]" + "\n"
			else
				driftLog +=  num2str(i) + ": "+ num2str(dp[i]) + "    " + num2str(dq[i]) + "\n"
			endif
		endif
	endfor
	ImageTransform/NP=(layers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales w3d, M_Stack
	Duplicate/O M_Stack, saveWaveDF:$NameofWave(w3d)

	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif
	SetDataFolder saveDF
	return 0
End


Function/WAVE ATH_WAVEImageAlignmentByCorrelation(WAVE w1, WAVE w2, [variable printMode, int windowing])
	/// Align two images using Correlation/Autocorrelation operations. 
	/// @param w1 wave reference First wave (reference wave) for which its autocorrelation 
	/// is our reference.
	/// @param w2 wave reference Second wave (test wave), which will be tranlated with respect
	/// to w1.
	/// @param printMode int optional print the drift corrections in pixels
	/// The ATH_ImageAlignmentByCorrelation function allow only for integer pixed translations.
	
	printMode = ParamIsDefault(printMode) ? 0: printMode // print if not 0
	windowing = ParamIsDefault(windowing) ? 0: windowing // print if not 0
	if(!(WaveType(w1) & 0x02))
		Redimension/S w1
	endif
	if(!(WaveType(w2) & 0x02))
		Redimension/S w2
	endif
	if(windowing)
		ImageWindow/O Hanning w1
		ImageWindow/O Hanning w2
	endif
	MatrixOP/O/FREE autocorr = correlate(w1, w1, 0)
	MatrixOP/O/FREE corr = correlate(w1, w2, 0)
	WaveStats/Q autocorr // /P flag: report Loc in p, q instead of x, y
	variable x0 = V_maxRowLoc
	variable y0 = V_maxColLoc
	WaveStats/Q corr // /P flag: report Loc in p, q instead of x, y
	variable x1 = V_maxRowLoc
	variable y1 = V_maxColLoc
	variable dx = x1 - x0
	variable dy = y1 - y0
	Duplicate/FREE w1, driftCorrW
	ImageTransform/IOFF={-dx, -dy, 0} offsetImage driftCorrW
	WAVE M_OffsetImage
	if(printMode)
		print "dx=", dx,",dy=", dy
	endif
	Duplicate/FREE M_OffsetImage waveRef
	KillWaves M_OffsetImage
	return waveRef
End

Function ATH_ImageAlignmentByCorrelation(WAVE w1, WAVE w2, string alignedImageStr, [int printMode, int windowing])
	/// Align two images using Correlation/Autocorrelation operations. 
	/// @param w1 wave reference First wave (reference wave) for which its autocorrelation 
	/// is our reference.
	/// @param w2 wave reference Second wave (test wave), which will be tranlated with respect
	/// to w1.
	/// @param alignedImageStr string Name of the alinged image.
	/// @param printMode int optional print the drift corrections in pixels
	/// The ATH_ImageAlignmentByCorrelation function allow only for integer pixed translations.
	
	// Take into account wave scaling.
	printMode = ParamIsDefault(printMode) ? 0: printMode // print if not 0
	windowing = ParamIsDefault(windowing) ? 0: windowing // print if not 0
	if(!(WaveType(w1) & 0x02))
		Redimension/S w1
	endif
	if(!(WaveType(w2) & 0x02))
		Redimension/S w2
	endif
	if(windowing)
		ImageWindow/O Hanning w1
		ImageWindow/O Hanning w2
	endif
	MatrixOP/O/FREE autocorr = correlate(w1, w1, 0)
	MatrixOP/O/FREE corr = correlate(w1, w2, 0)
	WaveStats/Q autocorr // /P flag: report Loc in p, q instead of x, y
	variable x0 = V_maxRowLoc
	variable y0 = V_maxColLoc
	WaveStats/Q corr // /P flag: report Loc in p, q instead of x, y
	variable x1 = V_maxRowLoc
	variable y1 = V_maxColLoc
	variable dx = x1 - x0
	variable dy = y1 - y0
	Duplicate/FREE w1, driftCorrW
	ImageTransform/IOFF={-dx, -dy, 0} offsetImage driftCorrW
	WAVE M_OffsetImage
	Duplicate/O M_OffsetImage, $alignedImageStr
	if(printMode)
		print "dx=", dx,",dy=", dy
	endif
	KillWaves M_OffsetImage
	return 0
End


Function ATH_LinearDriftCorrectionUsingABCursors(WAVE w3d, WAVE wx, WAVE wy)
	/// Linear drift correction w3d using wx and wy displacements
	
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
		dx = wx[i]
		dy = wy[i]
		MatrixOP/O/FREE targetLayer = layer(w3d, i)
		CopyScales w3d, targetLayer
		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D targetLayer	// New reference layer, M_Affine
		WAVE M_Affine
		Rename M_Affine, $("getStacklayer_" + num2str(i)) 
	endfor

	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
	WAVE M_Stack
	// Restore scale here
	CopyScales w3d, M_Stack
	Duplicate/O M_Stack, saveDF:$NameofWave(w3d)
	SetDataFolder currDF
	return 0
End

//// Not in use since 02.10.2023
//Function ATH_CascadeImageStackAlignmentByCorrelation(WAVE w3d, [int printMode])
//	/// Align a 3d wave using Correlation of the full image	
//	/// We align sequentially with reference layer the previous layer of the stack. 
//	/// Only x, y translations are allowed.
//	/// @param w3d WAVE 3d we want to register for aligment
//	
//	printMode = ParamIsDefault(printMode) ? 0: printMode
//	
//	if(!(WaveType(w3d) & 0x02))
//		Redimension/S w3d
//	endif
//
//	variable nlayers = DimSize(w3d, 2)
//	variable  i, x0, y0, x1, y1, dx, dy
//	
//	if(printMode)
//		string driftLog = "Called ATH_CascadeImageStackAlignmentByCorrelation\n"
//		driftLog +=  "---- Drift correction (relative to previous layer)----\n"
//		driftLog +=  "layer  dx  dy\n"
//	endif
//	
//	DFREF saveDF = GetDataFolderDFR()
//	DFREF saveWaveDF = GetWavesDataFolderDFR(w3d) // Location of w3d			
//	SetDataFolder NewFreeDataFolder() // Change folder
//	
//	MatrixOP/O getStacklayer_0 = layer(w3d, 0) // ImageTransform doesn't work with /FREE
//	Duplicate/FREE/O getStacklayer_0, M_Affine
//	for(i = 0; i < nlayers - 1; i++)
//		MatrixOP/O/FREE autocorrelationW = correlate(M_Affine, M_Affine, 0)
//		WaveStats/M=1/Q autocorrelationW
//		x0 = V_maxRowLoc
//		y0 = V_maxColLoc
//		MatrixOP/FREE/O targetLayer = layer(w3d, i + 1)
//		MatrixOP/O/FREE correlationW = correlate(M_Affine, targetLayer, 0)
//		WaveStats/M=1/Q correlationW
//		x1 = V_maxRowLoc
//		y1 = V_maxColLoc
//		dx = x0 - x1
//		dy = y0 - y1
//		if(printMode)
//			driftLog +=  num2str(i + 1) + ": "+ num2str(dx) + "    " + num2str(dy) + "\n"
//		endif
//		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D targetLayer	// New reference layer, M_Affine
//		MatrixOP/O/FREE w3dLayer = layer(w3d, i + 1)
//		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=$("getStacklayer_" + num2str(i + 1)) Affine2D w3dLayer	
//		endfor
//	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
//	WAVE M_Stack
//	// Restore scale here
//	CopyScales w3d, M_Stack
//	Duplicate/O M_Stack, saveWaveDF:$NameofWave(w3d)	
//	if(printMode)
//		string notebookName = NameOfWave(w3d)
//		KillWindow/Z notebookName
//		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
//		Notebook notebookName, text = driftLog
//	endif
//	SetDataFolder saveDF
//	return 0
//End
//
//// Not in use since 02.10.2023
//Function ATH_CascadeImageStackAlignmentByRegistration(WAVE w3d, [int convMode, int printMode])
//	/// Align a 3d wave using ImageRegistration using the full image
//	/// We align sequentially with reference layer the previous layer of the stack. 
//	/// Only x, y translations are allowed.
//	/// @param w3d WAVE 3d we want to register for aligment
//	
//	printMode = ParamIsDefault(printMode) ? 0: printMode
//	convMode = ParamIsDefault(convMode) ? 0: convMode // convMode = 0, 1 
//	
//	if(!(WaveType(w3d) & 0x02))
//		Redimension/S w3d
//	endif
//
//	variable rows = DimSize(w3d, 0)
//	variable cols = DimSize(w3d, 1)
//	variable layers = DimSize(w3d, 2)
//	
//	if(printMode)
//		string driftLog = "Called ATH_CascadeImageStackAlignmentByRegistration\n"
//		driftLog +=  "---- Drift correction (relative to previous layer)----\n"
//		driftLog +=  "layer  dx  dy\n"
//	endif
//	
//	DFREF saveDF = GetDataFolderDFR()
//	DFREF saveWaveDF = GetWavesDataFolderDFR(w3d) // Location of w3d	
//	SetDataFolder NewFreeDataFolder()
//	variable i, dx, dy
//	// Get the first layer out
//	MatrixOP/O getStacklayer_0 = layer(w3d, 0) 
//	Duplicate/FREE getStacklayer_0, M_Affine
//	for(i = 0; i < layers - 1; i++) // (layers - 1)
//		MatrixOP/FREE/O targetLayer = layer(w3d, i + 1) 
//		ImageRegistration/Q/TRNS={1,1,0}/ROT={0,0,0}/TSTM=0/BVAL=0/CONV=(convMode) refwave = M_Affine, testwave = targetLayer // Correct!!!!:Error here. M_Affine differs by one!
//		WAVE W_RegParams
//		dx = W_RegParams[0]; dy = W_RegParams[1]
//		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D targetLayer // Will overwrite M_Affine
//		MatrixOP/O/FREE w3dLayer = layer(w3d, i + 1)
//		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=$("getStacklayer_" + num2str(i + 1)) Affine2D w3dLayer
//		if(printMode)
//			driftLog +=  num2str(i + 1) + ": "+ num2str(dx) + "    " + num2str(dy) + "\n" // Layer 0 is not shifted
//		endif
//	endfor
//	ImageTransform/NP=(layers) stackImages $"getStacklayer_0"
//	WAVE M_Stack
//	// Restore scale here
//	CopyScales w3d, M_Stack
//	Duplicate/O M_Stack, saveWaveDF:$NameofWave(w3d)	
//	if(printMode)
//		string notebookName = NameOfWave(w3d)
//		KillWindow/Z notebookName
//		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
//		Notebook notebookName, text = driftLog
//	endif
//	SetDataFolder saveDF
//	return 0
//End

//Function ATH_CascadeImageStackAlignmentByPartitionRegistration(WAVE w3d, WAVE partitionW3d, [variable printMode]) // Used in menu
//	/// Align a 3d wave using ImageRegistration using a partition of the target 3d wave.
//	/// We align sequentially with reference layer the previous layer of the stack. 
//	/// Only x, y translations are allowed.
//	/// @param w3d WAVE 3d we want to register for aligment
//	/// @param partitionW3d WAVE partition of w3d 
//	/// Note: When illumination conditions change considerably, (XAS along an edge)
//	/// it is better to use a mask to isolate a characteristic feature. 
//	printMode = ParamIsDefault(printMode) ? 0: printMode
//	if(!(WaveType(w3d) & 0x02))
//		Redimension/S w3d
//	endif
//	if(!(WaveType(partitionW3d) & 0x02))
//		Redimension/S partitionW3d
//	endif
//	
//	variable rows = DimSize(w3d, 0)
//	variable cols = DimSize(w3d, 1)
//	variable layers = DimSize(w3d, 2)
//	
//	if(printMode)
//		string driftLog = "Called ATH_CascadeImageStackAlignmentByPartitionRegistration\n"
//		driftLog +=  "---- Drift correction (relative to previous layer)----\n"
//		driftLog +=  "layer  dx  dy\n"
//	endif
//	
//	DFREF saveDF = GetDataFolderDFR()
//	DFREF saveWaveDF = GetWavesDataFolderDFR(w3d) // Location of w3d	
//	SetDataFolder NewFreeDataFolder()
//	variable i, dx, dy
//	// Get the first layer out
//	MatrixOP/O getStacklayer_0 = layer(w3d, 0) 
//	MatrixOP/O M_Affine = layer(partitionW3d, i) // Get the first layer from partitionW3d, name is M_Affine (ImageInterpolate default  output for Affine2D)
//	
//	for(i = 0; i < layers - 1; i++) // (layers - 1)
//		MatrixOP/O/FREE targetLayer = layer(partitionW3d, i + 1)
//		ImageRegistration/Q/TRNS={1,1,0}/ROT={0,0,0}/TSTM=0/BVAL=0 refwave = M_Affine, testwave = targetLayer
//		WAVE W_RegParams	
//		dx = W_RegParams[0]; dy = W_RegParams[1]		
//		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D targetLayer // Will overwrite M_Affine
//		MatrixOP/O/FREE w3dLayer = layer(w3d, i + 1)
//		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=$("getStacklayer_" + num2str(i + 1)) Affine2D w3dLayer
//		if(printMode)
//			driftLog +=  num2str(i + 1) + ": "+ num2str(dx) + "    " + num2str(dy) + "\n" // Layer 1 is not shi
//		endif
//	endfor
//	ImageTransform/NP=(layers) stackImages $"getStacklayer_0"
//	WAVE M_Stack
//	// Restore scale here
//	CopyScales w3d, M_Stack
//	Duplicate/O M_Stack, saveWaveDF:$NameofWave(w3d)	
//	//MoveWave M_Stack, saveDF:$NameofWave(w3d) // Move, do not duplicate
//	if(printMode)
//		string notebookName = NameOfWave(w3d)
//		KillWindow/Z notebookName
//		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
//		Notebook notebookName, text = driftLog
//	endif
//	SetDataFolder saveDF
//	return 0
//End

//Function ATH_CascadeImageStackAlignmentByPartitionCorrelation(WAVE w3d, WAVE partitionW3d, [int printMode])
//	/// Align a 3d wave using ImageRegistration using a partition of the target 3d wave.
//	/// We align sequentially with reference layer the previous layer of the stack. 
//	/// Only x, y translations are allowed.
//	/// @param w3d WAVE 3d we want to register for aligment
//	/// @param partitionW3d WAVE partition of w3d
//	/// Note: When illumination conditions change considerably, (XAS along an edge)
//	/// it is better to use a mask to isolate a characteristic feature. 
//	
//	printMode = ParamIsDefault(printMode) ? 0: printMode
//	
//	if(!(WaveType(w3d) & 0x02))
//		Redimension/S w3d
//	endif
//	if(!(WaveType(partitionW3d) & 0x02))
//		Redimension/S partitionW3d
//	endif
//	variable nlayers = DimSize(w3d, 2)
//	variable  i, x0, y0, x1, y1, dx, dy
//	// Calculate drifts
//	if(printMode)
//		string driftLog = "Called ATH_CascadeImageStackAlignmentByPartitionCorrelation\n"
//		driftLog +=  "---- Drift correction (relative to previous layer)----\n"
//		driftLog +=  "layer  dx  dy\n"
//	endif
//	DFREF saveDF = GetDataFolderDFR()
//	DFREF saveWaveDF = GetWavesDataFolderDFR(w3d) // Location of w3d					
//	SetDataFolder NewFreeDataFolder() // Change folder
//	MatrixOP/O getStacklayer_0 = layer(w3d, 0) // "getStacklayer_0" - ImageTransform doesn't work with /FREE
//	MatrixOP/O M_Affine = layer(partitionW3d, 0)
//	for(i = 0; i < nlayers - 1; i++)
//		MatrixOP/O/FREE targetLayer = layer(partitionW3d, i + 1)
//		MatrixOP/O/FREE autocorrelationW = correlate(M_Affine, M_Affine, 0)
//		WaveStats/M=1/Q autocorrelationW
//		x0 = V_maxRowLoc
//		y0 = V_maxColLoc
//		MatrixOP/O/FREE correlationW = correlate(M_Affine, targetLayer, 0)
//		WaveStats/M=1/Q correlationW
//		x1 = V_maxRowLoc
//		y1 = V_maxColLoc
//		dx = x0 - x1
//		dy = y0 - y1
//		if(printMode)
//			driftLog +=  num2str(i + 1) + ": "+ num2str(dx) + "    " + num2str(dy) + "\n"
//		endif
//		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0} Affine2D targetLayer	// New reference layer, M_Affine
//		MatrixOP/O/FREE w3dLayer = layer(w3d, i + 1)
//		ImageInterpolate/APRM={1,0,dx,0,1,dy,1,0}/DEST=$("getStacklayer_" + num2str(i + 1)) Affine2D w3dLayer	
//		endfor
//	ImageTransform/NP=(nlayers) stackImages $"getStacklayer_0"
//	WAVE M_Stack
//	// Restore scale here
//	CopyScales w3d, M_Stack
//	Duplicate/O M_Stack, saveWaveDF:$NameofWave(w3d)	
//	if(printMode)
//		string notebookName = NameOfWave(w3d)
//		KillWindow/Z notebookName
//		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
//		Notebook notebookName, text = driftLog
//	endif
//	SetDataFolder saveDF
//	return 0
//End
