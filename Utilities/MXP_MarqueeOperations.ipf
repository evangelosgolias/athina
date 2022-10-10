#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function MarqueeToMask(): GraphMarquee
	GetMarquee/K left, bottom;
	MXP_CoordinatesToROIMask(V_left, V_top, V_right, V_bottom)
End

Function BackupTraces(): GraphMarquee
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 3)
End

Function RestoreTraces(): GraphMarquee
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 4)
End

Function PullToZero(): GraphMarquee
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 0)
End

Function NormalizeToOne(): GraphMarquee
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 1)
End

Function MaximumToOne(): GraphMarquee
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 2)
End

Function ScaleThisImage(): GraphMarquee
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE waveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	variable getScaleXY
	string cmdStr = "0, 0", setScaleZStr
	string msgDialog = "Scale Z direction of stack"
	string strPrompt = "Set firstVal,  lastVal in quotes (string).\n Leave \"\"  and press continue for autoscaling."
	if(MXP_WaveDimensionsQ(waveRef, 2))
		getScaleXY = NumberByKey("FOV(µm)", note(waveRef), ":", "\n")
		SetScale/I x, 0, getScaleXY, waveRef
		SetScale/I y, 0, getScaleXY, waveRef
	elseif(MXP_WaveDimensionsQ(waveRef, 3))
		// We deal with the x, y scale when we import the wave
		//getScaleXY = NumberByKey("FOV(µm)", note(waveRef), ":", "\n")
		//SetScale/I x, 0, getScaleXY, waveRef
		//SetScale/I y, 0, getScaleXY, waveRef
		setScaleZStr = MXP_GenericSingleStrPrompt(strPrompt, msgDialog)
		if(strlen(setScaleZStr))
		cmdStr = "SetScale/I z " + setScaleZStr + ", " + NameofWave(waveRef)
		Execute/Z cmdStr
		endif
	endif
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
	WAVE M_ROIMask
	Duplicate/O M_ROIMask, MXP_ROIMask
	Redimension/S MXP_ROIMask
	KillWaves/Z M_ROIMask
End


Function MXP_OperationsOnGraphTracesForXAS(variable left, variable right, variable operationSelection)
	// Trace calculations using graph marquee
	string waveListStr, traceNameStr
	waveListStr = TraceNameList("", ";", 1 + 4)
	string buffer, dfStr
	DFREF currDFR = GetDataFolderDFR()
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
			case 2: // Max to one
				wRef /= V_max
				break
			case 3: // Backup traces
				dfStr = GetWavesDataFolder(TraceNameToWaveRef("", traceNameStr), 1)
				SetDataFolder $dfStr
				buffer = NameOfWave(wref) + "_undo"
				Duplicate/O wref, $buffer
				break
			case 4: // Restore traces
				dfStr = GetWavesDataFolder(TraceNameToWaveRef("", traceNameStr), 1)
				SetDataFolder $dfStr
				buffer = NameOfWave(wref) + "_undo"
				Duplicate/O $buffer, wref
				break
			default:
				print "Unkwokn MXP_OperatiosGraphTracesForXAS operationSelection"
				break
		endswitch
		i++
	while (1)
	SetDataFolder currDFR
End