#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_Traces

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

/// @module ATH_Traces
/// @brief Module ATH_Traces.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH Traces functionality.


static Function/WAVE TopTraceToWaveRef([string grfName])
	// Return a wave reference from the top graph
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	string traceNameTopGraphStr = StringFromList(0, TraceNameList(grfName, ";", 5),";") // Omit hidden traces
	// if there is no image in the top graph strlen(imgNameTopGraphStr) = 0
	if(strlen(traceNameTopGraphStr))
		WAVE wRef = TraceNameToWaveRef(grfName, traceNameTopGraphStr) // full path of wave
		return wRef
	else 
		return $""
	endif
End

/// @function MarqueeToTraceOperation
/// @brief Description of MarqueeToTraceOperation.
/// @details
/// Auto-generated documentation stub for function `MarqueeToTraceOperation`.
/// @param op Parameter op.
/// @returns Variable Return value.

static Function MarqueeToTraceOperation(variable op)
	// op:  0: PullToZero
	//		1: Normalise to one
	//		2: Maximun to one
	//		3: Backup Traces
	//		4: Restore Traces
	//		5: Normalise to profile
	string grfName = WinName(0, 1, 1)
	string xaxis, yaxis
	[xaxis, yaxis] = ATH_Graph#GetAxes(grfName=grfName) // Use top graph
	GetMarquee/W=$grfName/K $xaxis, $yaxis
	OperationsOnGraphTracesWithMarquee(V_left, V_right, op)
End

/// @function OperationsOnGraphTracesWithMarquee
/// @brief Description of OperationsOnGraphTracesWithMarquee.
/// @details
/// Auto-generated documentation stub for function `OperationsOnGraphTracesWithMarquee`.
/// @param left Parameter left.
/// @param right Parameter right.
/// @param operationSelection Parameter operationSelection.
/// @returns Variable Return value.

static Function OperationsOnGraphTracesWithMarquee(variable left, variable right, variable operationSelection)
	// Trace calculations using graph marquee
	string waveListStr, traceNameStr
	waveListStr = TraceNameList("", ";", 1 + 4)
	string buffer, dfStr
	DFREF currDFR = GetDataFolderDFR()
	variable launchBrowserSwitch = 1
	variable i = 0
	do
		traceNameStr = StringFromList(i, waveListStr)
		if (strlen(traceNameStr) == 0)
			break
		endif
		WAVE wRef = TraceNameToWaveRef("", traceNameStr)
		if(WaveDims(wRef) != 1)
			Abort "Operates only on traces"
		endif
		WaveStats/Q/R=(left, right) wRef
		switch(operationSelection)
			case 0: // Pull to zero
				wRef -= V_avg
				break
			case 1: // Normalise to one
				wRef /= V_avg
				break
			case 2: // Max to one
				wRef /= V_max
				break
			case 3: // Backup traces
				DFREF dfr = GetWavesDataFolderDFR(TraceNameToWaveRef("", traceNameStr))
				buffer = NameOfWave(wref) + ksATHBackupWaveExtention
				Duplicate/O wref, dfr:$buffer
				break
			case 4: // Restore traces
				DFREF dfr = GetWavesDataFolderDFR(TraceNameToWaveRef("", traceNameStr))
				buffer = NameOfWave(wref) + ksATHBackupWaveExtention
				Duplicate/O dfr:$buffer, wref
				KillWaves/Z dfr:$buffer
				break
			case 5:
				if(launchBrowserSwitch)
					string selectedWaveStr = ATH_Dialog#SelectWavesInModalDataBrowser("Select notmalisation profile")
					WAVE waveProf = $StringFromList(0, selectedWaveStr)
					launchBrowserSwitch = 0
				endif
				
				ATH_WaveOp#NormaliseWaveWithWave(wRef, waveProf)		
				break
			default:
				print "Unknown ATH_OperatiosGraphTracesForXAS operationSelection"
				break
		endswitch
		i++
	while (1)
	SetDataFolder currDFR
End

/// @function AlignTracesDB
/// @brief Description of AlignTracesDB.
/// @details
/// Auto-generated documentation stub for function `AlignTracesDB`.
/// @returns Variable Return value.

static Function AlignTracesDB() // Experimental
	// Fix: For stitching to have sense as done here there should be 
	// an overlap between regions, i.e. region width should be larger
	// than the step between traces.
	
	// align traces, i.e match the last value of wave1d N-1
	// to the first value of wave1d N
	string buffer, listOfSelectedWaves= ""	
	variable i = 0
	do
		buffer = GetBrowserSelection(i)
		if(WaveExists($buffer) && WaveDims($buffer)==1)
			listOfSelectedWaves += buffer + ";" // Match stored at S_value
		endif
		i++
	while (strlen(GetBrowserSelection(i)))
	
	//Sort alphanumerically
	
	listOfSelectedWaves = SortList(listOfSelectedWaves,";", 16)
	variable nrwaves = ItemsInList(listOfSelectedWaves)
//	variable ntot = 0
//	for(i=0;i<nrwaves;i++)
//		WAVE wRef = $StringFromList(i, listOfSelectedWaves)
//		ntot+=DimSize(wRef, 0)
//	endfor
	
	//Make/N=(ntot) stitchWave
	variable shift
	for(i=1;i<nrwaves;i++)
		WAVE beforeW = $StringFromList(i-1,listOfSelectedWaves)
		WAVE afterW =  $StringFromList(i,listOfSelectedWaves)
		shift = beforeW[DimSize(afterW, 0)-1] - afterW[0]
		afterW += shift
	endfor
	WAVE wlistRef = ATH_WaveOp#WaveListStrToWaveRef(listOfSelectedWaves, isFREE=1)
	Concatenate/NP=0/O {wlistRef}, ATH_stitch
End