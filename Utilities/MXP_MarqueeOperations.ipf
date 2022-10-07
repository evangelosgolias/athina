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


// WK Function


Function MXP_OperatiosGraphTracesForXAS(variable left, variable right, variable operationSelection)
	// Inspired from Wolfgang's Kuch Igor routines
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
			case 0: // subtract average
				wRef -= V_avg
				break
			case 1: // Normalise to one
				wRef /= V_avg
				break
			case 2:
				wRef /= V_avg
				break
			case 3:
				<code>
				break
			default:
				print "Unkwokn MXP_OperatiosGraphTracesForXAS operationSelection"
				break
		endswitch
		
		i++
	while (1)
End
	
Function PullFirstToZero() : GraphMarquee
	GetMarquee/K left, bottom
	PullF(V_left, V_right)
End

Function PullF(V_left, V_right)
	Variable V_left, V_right
	String waveListStr, traceNameStr
	waveListStr = TraceNameList("", ";", 1)
	Variable i = 0, zero
	do
		traceNameStr = StringFromList(i, waveListStr)
		if (strlen(traceNameStr) == 0)
			break					//exit loop
		endif
		Wave w = TraceNameToWaveRef("", traceNameStr)
		if (i == 0)
			WaveStats /Q /R=(V_left, V_right) w
			zero = V_avg
		endif
		w = w - zero
		i += 1
	while (1)
End

Function NormToOne() : GraphMarquee
	GetMarquee/K left, bottom
	Norm1(V_left, V_right)
End

Function Norm1(V_left, V_right)
	Variable V_left, V_right
	String waveListStr, tracename
	waveListStr = TraceNameList("", ";", 1)
	Variable i = 0
	do
		tracename = StringFromList(i, waveListStr)
		if (strlen(tracename) == 0)
			break					//exit loop
		endif
		Wave w = TraceNameToWaveRef("", tracename)
		WaveStats /Q /R=(V_left, V_right) w
		w = w / V_avg
		i += 1
	while (1)
End


Function NormToFirst() : GraphMarquee
	GetMarquee/K left, bottom
	FNorm(V_left, V_right)
End

Function FNorm(V_left, V_right)
	Variable V_left, V_right
	String waveListStr, tracename
	Variable height
	waveListStr = TraceNameList("", ";", 1)
	Variable i = 0
	do
		tracename = StringFromList(i, waveListStr)
		if (strlen(tracename) == 0)
			break					//exit loop
		endif
		Wave w = TraceNameToWaveRef("", tracename)
		WaveStats /Q /R=(V_left, V_right) w
		if (i == 0)
			height = V_avg
		endif
		w = w / V_avg * height
		i += 1
	while (1)
End


Function FirstToOne() : GraphMarquee
	GetMarquee/K left, bottom
	FOne(V_left, V_right)
End

Function FOne(V_left, V_right)
	Variable V_left, V_right
	String waveListStr, tracename
	Variable height
	waveListStr = TraceNameList("", ";", 1)
	Variable i = 0
	do
		tracename = StringFromList(i, waveListStr)
		if (strlen(tracename) == 0)
			break					//exit loop
		endif
		Wave w = TraceNameToWaveRef("", tracename)
		if (i == 0)
			WaveStats /Q /R=(V_left, V_right) w
		endif
		w = w / V_avg
		i += 1
	while (1)
End
