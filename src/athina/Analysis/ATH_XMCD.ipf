#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_XMCD
#pragma version = 1.2
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

static Function/WAVE CalculateXMCDWAVE(WAVE w1, WAVE w2, [string outWave, WAVE wRef])
	/// Calculate XMCD/XMLD of two images and save it to 
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	/// NB: You have to provife either outWave or wRef
	
	// Calculation of XMC(L)D using SP waves
	if(!(WaveType(w1) & 0x02 && WaveType(w2) & 0x02))
		Redimension/S w1, w2
	endif
	
	if(!(ParamIsDefault(outWave) %^ ParamIsDefault(wRef)))
		return $""
	endif
	
	if(!ParamIsDefault(outWave))
		Duplicate/O w1, $outWave
		WAVE w = $outWave
		w = (w1 - w2)/(w1 + w2)
		return w
	else
		Duplicate/O w1, wRef
		wRef = (w1 - w2)/(w1 + w2)
		return wRef
	endif
End

static Function CalculateXMCD(WAVE w1, WAVE w2)
	/// Calculate XMCD/XMLD of two images and save it to 
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	/// NB: You have to provife either outWave or wRef
	if(!ATH_WaveOp#WaveDimensionsEqualQ(w1,w2))
		return -1
	endif
	DFREF currDFR = GetDataFolderDFR()
	string saveWaveName = CreatedataObjectName(currDFR, "xmcd_", 1, 0, 5)
	MatrixOP $saveWaveName = (w1 - w2)/(w1 + w2)
	CopyScales w1, $saveWaveName
	string noteStr = "ATH_Magnetism#CalculateXMCD("+ GetWavesDataFolder(w1,2) + ","+\
	GetWavesDataFolder(w2,2) +")\n"
	Note $saveWaveName, noteStr
	return 0
End

static Function StackToXMCD(WAVE w3d, [string wnameStr])
	/// Calculate XMCD/XMLD of two images
	/// @param w3d WAVE Wave with 2 layers.	
	if(DimSize(w3d, 2) != 2)
		return 1
	endif	
	if(WaveType(w3d) & 0x10) // if int16
		Redimension/S w3d
	endif
	MatrixOP/FREE w1 = layer(w3d,0)
	MatrixOP/FREE w2 = layer(w3d,1)	
	if(ParamIsDefault(wnameStr))
		MatrixOP/O wXMCD = (w1-w2)/(w1+w2)
	else
		MatrixOP/O $wnameStr = (w1-w2)/(w1+w2)
	endif
	return 0
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
	string saveWaveName = CreatedataObjectName(currDFR, "XMCD_3d", 1, 0, 1)
	variable timerRefNum = StartMSTimer
	if(DimSize(w3d1, 2) > 99)
		MatrixOP/NTHR=2 $saveWaveName = (w3d1 - w3d2)/(w3d1 + w3d2)
	else
		MatrixOP $saveWaveName = (w3d1 - w3d2)/(w3d1 + w3d2)
	endif
	variable 	microSeconds = StopMSTimer(timerRefNum)
	Print microSeconds/10000, "microseconds per iteration"	
	string noteStr = "XMC(L)D = (w1 - w2)/(w1 + w2)\nw1: " + GetWavesDataFolder(w3d1,2) + "\nw2: " + GetWavesDataFolder(w3d2,2)
	CopyScales w3d1, $saveWaveName
	Note $saveWaveName, noteStr
	return 0
End

static Function CalculateXMCDComb(WAVE w3d)
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
			CalculateXMCDWAVE(iLayer, jLayer, outWave = buffer)
			noteStr += num2str(cnt) + "> (" + num2str(IndexToScale(w3d, i, 2)) \
					+", "+ num2str(IndexToScale(w3d, j, 2))+")\n"
			cnt += 1
		endfor	
	endfor
	ImageTransform/NP=(nL) stackImages $"ATHWaveToStack_idx_0"
	WAVE M_Stack
	CopyScales w3d, M_Stack
	Note M_stack, "XMCD = (w0-w1)/(w0+w1) for (w0, w1)\n---* Stacked waves *---\n" + \
	noteStr + "*--------------------------*\n"
	string saveStackNameStr = CreatedataObjectName(saveDF, "XMCD_Comb", 1, 0, 1)
	MoveWave M_stack, saveDF:$saveStackNameStr
	SetDataFolder saveDF
	return 0
End

static Function XMCDStack4L(WAVE wRef, [string order, int overwrite, string outWave])
	// wRef comprises four layers.
	// Calculate xmcd between stack l0, l1 and l2, l3
	// then subtract the two xmcd images.
	// if order is specified then l1 = order[0], ... l4 = order[3]
	overwrite = ParamIsDefault(overwrite) ? 0 : overwrite
	order = SelectString(ParamIsDefault(order)? 0 : 1, "0123", order)
	if(ParamIsDefault(outWave))
		DFREF dfr = GetDataFolderDFR()
		outWave = CreateDataObjectName(dfr, NameOfWave(wRef) + "_xmcd", 1, 0, 1)
	endif
	string regex = "^(?=[0-3]{4}$)(?!.*(.).*\1).*$" // Matches 0123, 2134, ... all combinations
	if(!GrepString(order, regex))
		print order + " is not a permutation of 0123"
		return -1
	endif
	variable l0 = str2num(order[0])
	variable l1 = str2num(order[1])
	variable l2 = str2num(order[2])
	variable l3 = str2num(order[3])
	string noteStr = "Source: " + GetWavesDataFolder(wRef, 2) + ".\n"
	noteStr += "Layers:" + note(wRef) + "\n"
	noteStr += "XMCD calculation (w1-w2)/(w1+w2) between layers "+order[0]+","+order[1]+" (xmcd0) and " + order[2]+","+order[3]+" (xmcd0). "
	noteStr += "Then the two xmcd images are subtracted xmcd0 - xmcd1"
	MatrixOP/FREE w0 = layer(wRef, l0)
	MatrixOP/FREE w1 = layer(wRef, l1)
	MatrixOP/FREE w2 = layer(wRef, l2)
	MatrixOP/FREE w3 = layer(wRef, l3)
	Duplicate/FREE w0, xmcd0, xmcd1, wDest
	CalculateXMCDWAVE(w0, w1, wRef=xmcd0)
	CalculateXMCDWAVE(w2, w3, wRef=xmcd1)
	variable errCode, flag
	if(overwrite)
		Duplicate/O w0, $outWave; errCode = GetRTError(1);
	else
		Duplicate w0, $outWave; errCode = GetRTError(1);
	endif
	flag = V_flag
	if(errCode)
		print GetErrMessage(errCode)
		return -1
	endif
	WAVE wOut = $outWave
	wOut = xmcd0 - xmcd1
	Note wOut, noteStr
	return 0
End

//// ----- Multithreading ------- ////

static Function MultiThreadXMLDComb(WAVE w3D)

	if(!(WaveType(w3D) & 0x02 || WaveType(w3D) & 0x04))
		Redimension/S w3D
	endif
	
	// Create a wave to hold wave references returned by DriftCorrelation_Worker.
	variable numPlanes = DimSize(w3D,2), i, j, cnt = 0
	string combStr = "", noteStr = ""
	for(i = 0; i < numPlanes; i++)
		for(j = 0; j < i; j++)	
			combStr += num2str(i) + "," + num2str(j) + ";"
			noteStr += num2str(cnt) + "> (" + num2str(IndexToScale(w3D, i, 2)) \
					+", "+ num2str(IndexToScale(w3D, j, 2))+")\n"
			cnt++	
		endfor
	endfor
					
	Make/WAVE/N=(ItemsInList(combStr)) ww	
	// Release the threads.
	MultiThread ww = XMCDCalculation_Worker(w3D, StringFromList(p,combStr))
	// At this point, ww holds wave references to numplanes free waves
	// created by DriftCorrelation_Worker.
	// So, now repack all layers.
	DFREF saveDF = GetWavesDataFolderDFR(w3D)
	string combStackNameStr = CreatedataObjectName(saveDF, "XMCD_Comb", 1, 0, 1)	
	Concatenate/O {ww}, saveDF:$combStackNameStr
	CopyScales w3D, saveDF:$combStackNameStr
	Note saveDF:$combStackNameStr, "XMCD = (w0-w1)/(w0+w1) for (w0, w1)\n---* Stacked waves *---\n" + \
	noteStr + "*--------------------------*\n"
	// ww holds references to the free waves. By killing ww, we kill
	// the last reference to the free waves which causes them to be
	// automatically deleted.
	KillWaves ww
End
	
// Multithreaded Registration
ThreadSafe static Function/WAVE XMCDCalculation_Worker(WAVE w3D, string idxStr)
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	variable l0 = str2num(StringFromList(0, idxStr, ","))
	variable l1 = str2num(StringFromList(1, idxStr, ","))	
	MatrixOP/FREE w0 = layer(w3d, l0)
	MatrixOP/FREE w1 = layer(w3d, l1)
	MatrixOP/FREE xmcd = (w0-w1)/(w1+w0)
	// Restore the current data folder
	SetDataFolder dfSav
	return xmcd
End
