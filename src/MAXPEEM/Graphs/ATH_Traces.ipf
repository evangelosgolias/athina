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