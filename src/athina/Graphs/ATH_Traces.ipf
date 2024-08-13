#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_Traces


static Function/WAVE TopTraceToWaveRef([string graphName])
	// Return a wave reference from the top graph
	
	graphName = SelectString(ParamIsDefault(graphName) ? 0: 1, WinName(0, 1, 1), graphName) // Empty case will be handled below
	string traceNameTopGraphStr = StringFromList(0, TraceNameList(graphName, ";", 4),";") // Omit hidden traces
	// if there is no image in the top graph strlen(imgNameTopGraphStr) = 0
	if(strlen(traceNameTopGraphStr))
		WAVE wRef = TraceNameToWaveRef("", traceNameTopGraphStr) // full path of wave
		return wRef
	else 
		return $""
	endif
End

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
				buffer = NameOfWave(wref) + "_undo"
				Duplicate/O wref, dfr:$buffer
				break
			case 4: // Restore traces
				DFREF dfr = GetWavesDataFolderDFR(TraceNameToWaveRef("", traceNameStr))
				buffer = NameOfWave(wref) + "_undo"
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

