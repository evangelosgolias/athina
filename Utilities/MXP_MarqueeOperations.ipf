#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function MXP_MarqueeToMask()
	GetMarquee/K left, top;
	MXP_CoordinatesToROIMask(V_left, V_top, V_right, V_bottom)
	string noteToMaskStr 
	sprintf noteToMaskStr, "V_left, V_top, V_right, V_bottom:%s, %s, %s, %s", num2str(V_left), num2str(V_top), num2str(V_right), num2str(V_right)
	WAVE MXP_ROIMask
	Note/K MXP_ROIMask, noteToMaskStr
End

Function MXP_BackupTraces()
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 3)
End

Function MXP_RestoreTraces()
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 4)
End

Function MXP_PullToZero()
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 0)
End

Function MXP_NormalizeToOne()
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 1)
End

Function MXP_MaximumToOne()
	GetMarquee/K left, bottom;
	MXP_OperationsOnGraphTracesForXAS(V_left, V_right, 2)
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

Function MXP_Partition3DRegion()
	GetMarquee/K left, top;
	string imgNameTopGraphStr = StringFromList(0, ImageNameList("", ";"),";")
	WAVE waveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	MXP_3DWavePartition(waveRef, "MXP_Partition3D", V_left, V_right, V_top, V_bottom, tetragonal = 1, poweroftwo = 1)
End