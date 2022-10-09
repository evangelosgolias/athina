#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function MarqueeToMask(): GraphMarquee
	GetMarquee/K left, top;
	MXP_CoordinatesToROIMask(V_left, V_top, V_right, V_bottom)
End

Function MXP_CoordinatesToROIMask(variable left, variable top, variable right, variable bottom)
	/// Generate a SP Mask from Marquee
	/// The graph should have left, top axes
	string wnamestr = WMTopImageName()
	string winNameStr = WinName(0, 1, 1)
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,16385,16385), fillpat = 0, linethick = 0.5, xcoord = top, ycoord = left
	DrawRect/W=$winNameStr left, top, right, bottom
	ImageGenerateROIMask $wnamestr
	DrawAction  delete
	SetDrawLayer UserFront
	Wave M_ROIMask
	Duplicate/O M_ROIMask, MXP_ROIMask
	Redimension/S MXP_ROIMask
	KillWaves/Z M_ROIMask
End


Function MXP_OperationsOnGraphTracesForXAS(variable left, variable right, variable operationSelection)
	// Trace calculations using graph marquee
	string waveListStr, traceNameStr
	waveListStr = TraceNameList("", ";", 1 + 4)
	variable i = 0
	do
		traceNameStr = StringFromList(i, waveListStr)
		if (strlen(traceNameStr) == 0)
			break
		endif
		WAVE wRef = TraceNameToWaveRef("", traceNameStr)
		WaveStats/Q/R=(left, right) wRef
		switch(operationSelection)
			case 0: // Pull to zero
				wRef -= V_avg
				break
			case 1: // Normalise to one
				wRef /= V_avg
				break
			case 2: // Pull to zero
				//code
				break
			case 3:
				//Code
				break
			default:
				print "Unkwokn MXP_OperatiosGraphTracesForXAS operationSelection"
				break
		endswitch
		i++
	while (1)
End