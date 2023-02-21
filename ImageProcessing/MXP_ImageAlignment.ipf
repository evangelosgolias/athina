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

Function/WAVE MXP_WAVEImageAlignmentByRegistration(WAVE w1, WAVE w2)
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

Function MXP_ImageAlignmentByRegistration(WAVE w1, WAVE w2)
	/// Align two images using ImageRegistration operation. 
	/// Only x, y translations are allowed.
	/// @param w1 wave reference First wave (reference wave)
	/// @param w2 wave reference Second wave (test wave)
	string msg
	sprintf msg, "ImageRegistration with refWave = %s and testWave = %s.", NameOfWave(w1), NameOfWave(w2)
	print msg		

	if(!(WaveType(w1) & 0x02))
		sprintf msg, "ImageRegistration needs SP precision waves. Converting %s to SP", NameOfWave(w1)
		print msg		
		Redimension/S w1
	endif
	if(!(WaveType(w2) & 0x02))
		sprintf msg, "ImageRegistration needs SP precision waves. Converting %s to SP", NameOfWave(w2)
		print msg	
		Redimension/S w2
	endif 
	ImageRegistration/Q/STCK/PSTK/ROT={0,0,0}/TSTM=0/BVAL=0 refWave = w1, testWave = w2
	WAVE M_RegOut
	Duplicate/O M_RegOut, w2	
	KillWaves/Z M_RegOut, M_RegMaskOut, M_RegParams
	return 0
End

Function MXP_ImageStackAlignmentByPartitionRegistration(WAVE w3d, WAVE partitionW3d, [variable layerN, variable printMode]) // Used in menu
	/// Align a 3d wave using ImageRegistration of a partition of the target 3d wave. 
	/// The partition 3d wave calls MXP_ImageStackAlignmentByFullRegistration
	/// By default the function will  use the 0-th layer as a wave reference, uncless user chooses otherwise.
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.
	/// @param convMode int optional Select convergence method /CONV = 0, 1 for Gravity (fast) or Marquardt (slow), respectively.
	/// Note: When illumination conditions change considerably, (XAS along an edge)
	/// it is better to use a mask to isolate a characteristic feature. 
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then default is 0
	printMode = ParamIsDefault(printMode) ? 0: printMode
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	if(!(WaveType(partitionW3d) & 0x02))
		Redimension/S partitionW3d
	endif
	MatrixOP/FREE refLayerWave = layer(partitionW3d, layerN)
	variable rows = DimSize(w3d, 0)
	variable cols = DimSize(w3d, 1)
	variable layers = DimSize(w3d, 2)
	if(!WaveExists($(NameOfWave(w3d) + "_undo")))
		Duplicate/O w3d, $(NameOfWave(w3d) + "_undo")
	endif
	ImageRegistration/Q/STCK/PSTK/ROT={0,0,0}/TSTM=0/BVAL=0 refwave = refLayerWave, testwave = partitionW3d
	WAVE M_RegParams
	MatrixOP/FREE dx = row(M_RegParams,0)
	MatrixOP/FREE dy = row(M_RegParams,1)
	if(printMode)
		string driftLog = ""
		driftLog += "Ref. Layer = " + num2str(layerN) + "\n"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
	endif
	//Now translate each wave in the stack
	variable i
	for(i = 0; i < layers; i++)
		MatrixOP/O/FREE getfreelayer = layer(w3d, i)
		ImageTransform/IOFF={dx[i], dy[i], 0} offsetImage getfreelayer
		WAVE M_OffsetImage
		if(printMode)
			driftLog +=  num2str(i) + ": "+ num2str(dx[i]) + "    " + num2str(dy[i]) + "\n"
		endif
		w3d[][][i] = M_OffsetImage[p][q]
	endfor
	KillWaves/Z M_RegOut, M_RegMaskOut, M_RegParams, M_OffsetImage
	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif
	return 0
End


Function MXP_ImageStackAlignmentByRegistration(WAVE w3d, [variable layerN, variable printMode, variable convMode])
	/// Align a 3d wave using ImageRegistration. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise 
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param layerN int optional Reference layer for ImageRegistration.
 	/// @param printMode int optional print drift of each layer
	/// @param convMode int optional Select convergence method /CONV = 0, 1 for Gravity (fast) or Marquardt (slow), respectively.
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then 0 is your choice
	convMode = ParamIsDefault(convMode) ? 0: convMode // convMode = 0, 1 
	printMode = ParamIsDefault(printMode) ? 0: printMode
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	MatrixOP/FREE refLayerWave = layer(w3d, layerN) 
	// HERE /CONV=0 accelerates a lot the process in a 3d stack but you lose in accuracy?
	variable timerRefNum, microSeconds
	ImageRegistration/Q/STCK/PSTK/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/TSTM=0/BVAL=0/CONV=(convMode) refwave = refLayerWave, testwave = w3d
	WAVE M_RegOut, M_RegMaskOut, M_RegParams
	if(printmode)
		MatrixOP/FREE dx = row(M_RegParams, 0)
		MatrixOP/FREE dy = row(M_RegParams, 1)
		string driftLog = ""
		driftLog += "Ref. Layer = " + num2str(layerN) + "\n"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
		variable ncols = DimSize(dx, 1), i
		for(i = 0; i < ncols; i++)
			driftLog +=  num2str(i) + ": "+ num2str(dx[i]) + "    " + num2str(dy[i]) + "\n"		
		endfor
	endif
	if(!WaveExists($(NameOfWave(w3d)+"_undo")))
		Duplicate/O w3d, $(NameOfWave(w3d)+"_undo")
	endif	
	Duplicate/O M_RegOut, w3d
	KillWaves/Z M_RegOut, M_RegMaskOut, M_RegParams
	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif
	return 0
End

Function MXP_ImageStackAlignmentByMaskRegistration(WAVE w3d, WAVE MaskWaveRef, [variable layerN, variable convMode, variable printMode]) // not in use, slow
	/// Align a 3d wave using ImageRegistration. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise 
	/// Only x, y translations are allowed.
	/// @param w3d wave 3d we want to register for aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.
	/// @param convMode int optional Select convergence method /CONV = 0, 1 for Gravity (fast) or Marquardt (slow), respectively.
	/// Note: When illumination conditions change considerably, (XAS along an edge)
	/// it is better to use a mask to isolate a characteristic feature. 
	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then 0 is your choice
	convMode = ParamIsDefault(convMode) ? 1: convMode // NB. Use the /CONV = 1 as default
	printMode = ParamIsDefault(printMode) ? 0: printMode //
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	if(!(WaveType(MaskWaveRef) & 0x02))
		Redimension/S MaskWaveRef
	endif
	MatrixOP/FREE refLayerWave = layer(w3d, layerN)
	variable rows = DimSize(w3d, 0)
	variable cols = DimSize(w3d, 1)
	variable layers = DimSize(w3d, 2)
	Make/FREE/N=(rows, cols, layers) MaskWave3d
	MaskWave3d[][][] = MaskWaveRef[p][q] // Assume here is the bottleneck
	ImageRegistration/Q/STCK/TRNS={1,1,0}/ROT={0,0,0}/SKEW={0,0,0}/CONV=(convMode) refMask = MaskWaveRef testMask = MaskWave3d refwave = refLayerWave, testwave = w3d
	WAVE M_RegOut, M_RegMaskOut, M_RegParams
	if(printMode)
		MatrixOP/FREE dx = row(M_RegParams,0) // Print dx
		MatrixOP/FREE dy = row(M_RegParams,1) // Print dy
		string driftLog = ""
		driftLog += "Ref. Layer = " + num2str(layerN) + "\n"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
	endif
	if(!WaveExists($(NameOfWave(w3d)+"_undo")))
		Duplicate/O w3d, $(NameOfWave(w3d)+"_undo")
	endif		
	//Now translate each wave in the stack
	variable i 
	for(i = 0; i < layers; i++)
		MatrixOP/O/FREE getfreelayer = layer(w3d, i)
		ImageTransform/IOFF={dx[i], dy[i], 0} offsetImage getfreelayer
		WAVE M_OffsetImage
		w3d[][][i] = M_OffsetImage[p][q]
		if(printMode)
			driftLog +=  num2str(i) + ": "+ num2str(dx[i]) + "    " + num2str(dy[i]) + "\n"
		endif
	endfor
	KillWaves/Z M_RegOut, M_RegMaskOut, M_RegParams, M_OffsetImage
	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif
	return 0
End

Function MXP_ImageStackAlignmentByCorrelation(WAVE w3d, [variable layerN, int printMode, int windowing])
	/// Align a 3d wave using (auto)correlation. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise. 
	/// Only integer x, y translations are calculated.
	/// @param w3d wave 3d we want to aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.
	/// @param printMode int optional print the drift corrections in pixels

	layerN = ParamIsDefault(layerN) ? 0: layerN // If you don't select reference layer then 0 is your choice
	printMode = ParamIsDefault(printMode) ? 0: printMode // print if not 0
	windowing = ParamIsDefault(windowing) ? 0: windowing // print if not 0
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	MatrixOP/O/FREE refLayerFreeWave = layer(w3d, layerN)
	if(windowing)
		ImageWindow/O Hanning refLayerFreeWave
	endif
	MatrixOP/FREE autocorrelationW = correlate(refLayerFreeWave, refLayerFreeWave, 0)
	WaveStats/M=1/Q autocorrelationW
	variable x0 = V_maxRowLoc, y0 = V_maxColLoc, x1, y1, dx, dy
	variable layers = DimSize(w3d, 2)
	if(!WaveExists($(NameOfWave(w3d)+"_undo")))
		Duplicate/O w3d, $(NameOfWave(w3d)+"_undo")
	endif		
	//Now translate each wave in the stack
	variable i 
	if(printMode)
		string driftLog = ""
		driftLog += "Ref. Layer = " + num2str(layerN) + "\n"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
	endif

	for(i = 0; i < layers; i++)
		if(i != layerN)
			MatrixOP/O/FREE freeLayer = layer(w3d, i)
			if(windowing)
				Duplicate/O/FREE freeLayer, freeLayerCopy
				ImageWindow/O Hanning freeLayer
			endif			
			MatrixOP/O/FREE correlationW = correlate(refLayerFreeWave, freeLayer, 0)
			WaveStats/M=1/Q correlationW
			x1 = V_maxRowLoc
			y1 = V_maxColLoc
			dx = x0 - x1
			dy = y0 - y1
			if(printMode)
				//print i,": ", dx, dy
				driftLog +=  num2str(i) + ": "+ num2str(dx) + "    " + num2str(dy) + "\n"
			endif
			if(dx * dy) // Replace a slice only if you have to offset
				if(windowing)
					ImageTransform/IOFF={dx, dy, 0} offsetImage freeLayerCopy
				else
					ImageTransform/IOFF={dx, dy, 0} offsetImage freeLayer
				endif
				WAVE M_OffsetImage
				w3d[][][i] = M_OffsetImage[p][q]
			endif
		endif
	endfor
	KillWaves/Z M_OffsetImage
	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif
	return 0
End

Function MXP_ImageStackAlignmentByPartitionCorrelation(WAVE w3d, WAVE partitionW3d, [variable layerN, int printMode, int windowing]) // Used in menu
	/// Align a 3d wave using ImageRegistration of a partition of the target 3d wave. 
	/// The partition 3d wave calls MXP_ImageStackAlignmentByFullRegistration
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
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	if(!(WaveType(partitionW3d) & 0x02))
		Redimension/S partitionW3d
	endif
	MatrixOP/FREE refLayerWave = layer(partitionW3d, layerN)
	if(windowing)
		ImageWindow/O Hanning refLayerWave
	endif
	MatrixOP/FREE autocorrelationW = correlate(refLayerWave, refLayerWave, 0)
	WaveStats/M=1/Q autocorrelationW
	variable x0 = V_maxRowLoc, y0 = V_maxColLoc, x1, y1, i
	variable layers = DimSize(w3d, 2)
	if(!WaveExists($(NameOfWave(w3d)+"_undo")))
		Duplicate/O w3d, $(NameOfWave(w3d)+"_undo")
	endif	// Calculate drifts
	Make/FREE/N=(layers) dx, dy 
	for(i = 0; i < layers; i++)
		MatrixOP/O/FREE freeLayer = layer(partitionW3d, i)
		if(windowing)
			ImageWindow/O Hanning freeLayer
		endif
		MatrixOP/O/FREE correlationW = correlate(refLayerWave, freeLayer, 0)
		WaveStats/M=1/Q correlationW
		x1 = V_maxRowLoc
		y1 = V_maxColLoc
		dx[i] = x0 - x1
		dy[i] = y0 - y1
	endfor
	if(printMode)
		string driftLog = ""
		driftLog += "Ref. Layer = " + num2str(layerN) + "\n"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
	endif
	//Now translate each wave in the stack (w3d)
	for(i = 0; i < layers; i++)
		MatrixOP/O/FREE getfreelayer = layer(w3d, i)
		ImageTransform/IOFF={dx[i], dy[i], 0} offsetImage getfreelayer
		WAVE M_OffsetImage
		w3d[][][i] = M_OffsetImage[p][q]
		if(printMode)
			driftLog +=  num2str(i) + ": "+ num2str(dx[i]) + "    " + num2str(dy[i]) + "\n"
		endif
	endfor
	KillWaves/Z M_OffsetImage
	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif
	return 0
End

Function MXP_ImageStackAlignmentByIterativeCorrelation(WAVE w3d,  [variable printMode, int windowing]) // EXPERIMENTAL 10.10.22
	/// Align a 3d wave using (auto)correlation. By default the function will
	/// use the 0-th layer as a wave reference, uncless user chooses otherwise. 
	/// Only integer x, y translations are calculated.
	/// @param w3d wave 3d we want to aligment
	/// @param refLayer int optional Select refWave = refLayer for ImageRegistration.
	/// @param printMode int optional print the drift corrections in pixels

	printMode = ParamIsDefault(printMode) ? 0: printMode
	windowing = ParamIsDefault(windowing) ? 0: windowing
	if(!(WaveType(w3d) & 0x02))
		Redimension/S w3d
	endif
	variable x0, y0, x1, y1, dx, dy
	variable layers = DimSize(w3d, 2)
	if(!WaveExists($(NameOfWave(w3d)+"_undo")))
		Duplicate/O w3d, $(NameOfWave(w3d)+"_undo")
	endif	
	//Now translate each wave in the stack
	variable i 
	
	if(printMode)
		string driftLog = ""
		driftLog += "Ref. Layer = 0"
		driftLog +=  "---- Drift ----\n"
		driftLog +=  "layer  dx  dy\n"
	endif

	for(i = 1; i < layers; i++)
			MatrixOP/O/FREE freeLayer = layer(w3d, i)
			MatrixOP/O/FREE refLayerWave = layer(w3d, i-1)
			if(windowing)
				ImageWindow/O Hanning freeLayer
				ImageWindow/O Hanning refLayerWave
			endif
			MatrixOP/O/FREE autocorrelationW = correlate(refLayerWave, refLayerWave, 0)
			WaveStats/M=1/Q autocorrelationW
			x0 = V_maxRowLoc
			y0 = V_maxColLoc
			MatrixOP/FREE correlationW = correlate(refLayerWave, freeLayer, 0)
			WaveStats/M=1/Q correlationW
			x1 = V_maxRowLoc
			y1 = V_maxColLoc
			dx = x1 - x0
			dy = y1 - y0
			if(printMode)
				driftLog +=  num2str(i) + ": "+ num2str(dx) + "    " + num2str(dy) + "\n"
			endif
			if(dx * dy) // Replace a slice only if you have to offset
				ImageTransform/IOFF={-dx, -dy, 0} offsetImage freeLayer
				WAVE M_OffsetImage
				w3d[][][i] = M_OffsetImage[p][q] //Might be instable
			endif
			// interp2D(getfreelayer, x + dx, y + dy) works but we need an extra step MatrixOP/FREE XXX = zapNaNs()			
	endfor
	KillWaves/Z M_OffsetImage
	if(printMode)
		string notebookName = NameOfWave(w3d)
		KillWindow/Z notebookName
		NewNotebook/K=1/F=0/N=notebookName as (notebookName + " drift correction")
		Notebook notebookName, text = driftLog
	endif
	return 0
End

Function/WAVE MXP_WAVEImageAlignmentByCorrelation(WAVE w1, WAVE w2, [variable printMode, int windowing])
	/// Align two images using Correlation/Autocorrelation operations. 
	/// @param w1 wave reference First wave (reference wave) for which its autocorrelation 
	/// is our reference.
	/// @param w2 wave reference Second wave (test wave), which will be tranlated with respect
	/// to w1.
	/// @param printMode int optional print the drift corrections in pixels
	/// The MXP_ImageAlignmentByCorrelation function allow only for integer pixed translations.
	
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

Function MXP_ImageAlignmentByCorrelation(WAVE w1, WAVE w2, string alignedImageStr, [int printMode, int windowing])
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