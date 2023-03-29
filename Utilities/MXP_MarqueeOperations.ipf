﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
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

Function MXP_MarqueeToMask()
	if(CheckActiveAxis("", "top") && CheckActiveAxis("", "left"))
		GetMarquee/K left, top;
		MXP_CoordinatesToROIMask(V_left, V_top, V_right, V_bottom)
		string noteToMaskStr 
		sprintf noteToMaskStr, "V_left, V_top, V_right, V_bottom: %s, %s, %s, %s", num2str(V_left), num2str(V_top), num2str(V_right), num2str(V_right)
		WAVE MXP_ROIMask
		Note/K MXP_ROIMask, noteToMaskStr
	else
		print "Operation needs an image with left and top axes"
	endif
End

Function MXP_PullToZero()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		MXP_OperationsOnGraphTracesWithMarquee(V_left, V_right, 0)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

Function MXP_NormalizeToOne()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		MXP_OperationsOnGraphTracesWithMarquee(V_left, V_right, 1)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

Function MXP_MaximumToOne()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		MXP_OperationsOnGraphTracesWithMarquee(V_left, V_right, 2)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

Function MXP_BackupTraces()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		MXP_OperationsOnGraphTracesWithMarquee(V_left, V_right, 3)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

Function MXP_RestoreTraces()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		MXP_OperationsOnGraphTracesWithMarquee(V_left, V_right, 4)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

Function MXP_NormaliseTracesWithProfile()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		MXP_OperationsOnGraphTracesWithMarquee(V_left, V_right, 5)
	else
		print "Operation needs a graph with left and bottom axes"
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

Function/WAVE MXP_WAVECoordinatesToROIMask(variable left, variable top, variable right, variable bottom)
	/// Generate a SP Mask from Marquee and return a WAVE reference
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
	Duplicate/O/FREE M_ROIMask, MXP_ROIMask
	Redimension/S MXP_ROIMask
	KillWaves/Z M_ROIMask
	return MXP_ROIMask
End

Function MXP_OperationsOnGraphTracesWithMarquee(variable left, variable right, variable operationSelection)
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
			case 5:
				if(launchBrowserSwitch)
					string selectedWaveStr = MXP_SelectWavesInModalDataBrowser("Select notmalisation profile")
					WAVE waveProf = $StringFromList(0, selectedWaveStr)
					launchBrowserSwitch = 0
				endif
				
				MXP_NormaliseWaveWithWave(wRef, waveProf)
				
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

Function MXP_GetMarqueeWaveStats()
	/// Wavestats for a marquee region in a 2D wave. In case of a 3D wave the stats 
	/// are calculated for all layers.
	GetMarquee left, top;
	string imgNameTopGraphStr = StringFromList(0, ImageNameList("", ";"),";")
	WAVE waveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	if(WaveDims(waveRef) == 2 || WaveDims(waveRef) == 3)
		variable x0 = ceil(DimOffset(waveRef, 0))
		variable dx = ceil(DimDelta(waveRef, 0))
		variable y0 = ceil(DimOffset(waveRef, 1))
		variable dy = ceil(DimDelta(waveRef, 1))
		variable startP, endP, startQ, endQ
		startP = (V_left - x0)/dx
		endP = (V_right - x0)/dx
		startQ = (V_top - y0)/dy
		endQ = (V_bottom - y0)/dy
		WaveStats/RMD=[startP, endP][startQ, endQ][]/M=1 waveRef
	endif
End

static Function CheckActiveAxis(string graphname, string axis)
	/// If axis is present, return 1 otherwise 0
	/// graphnname = "" we refer to the top window
	if (strlen(AxisInfo(graphname, axis)))
		return 1
	else 
		return 0
	endif
End
