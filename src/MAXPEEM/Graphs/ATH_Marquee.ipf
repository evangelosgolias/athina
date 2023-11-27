﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Marquee
#pragma version = 1.01

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

Structure sUserMarqueePositions
	// Used in ATH_UserGetMarqueePositions
	variable left
	variable right
	variable top
	variable bottom
	variable canceled
EndStructure

static Function MarqueeToMask()
	if(CheckActiveAxis("", "top") && CheckActiveAxis("", "left"))
		GetMarquee/K left, top;
		CoordinatesToROIMask(V_left, V_top, V_right, V_bottom)
		string noteToMaskStr 
		sprintf noteToMaskStr, "V_left, V_top, V_right, V_bottom: %s, %s, %s, %s", num2str(V_left), num2str(V_top), num2str(V_right), num2str(V_right)
		WAVE M_ROIMask
		Note/K M_ROIMask, noteToMaskStr
	else
		print "Operation needs an image with left and top axes"
	endif
End

static Function PullToZero()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		OperationsOnGraphTracesWithMarquee(V_left, V_right, 0)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

static Function NormalizeToOne()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		OperationsOnGraphTracesWithMarquee(V_left, V_right, 1)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

static Function MaximumToOne()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		OperationsOnGraphTracesWithMarquee(V_left, V_right, 2)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

static Function BackupTraces()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		OperationsOnGraphTracesWithMarquee(V_left, V_right, 3)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

static Function RestoreTraces()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		OperationsOnGraphTracesWithMarquee(V_left, V_right, 4)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

static Function NormaliseTracesWithProfile()
	if(CheckActiveAxis("", "bottom") && CheckActiveAxis("", "left"))
		GetMarquee/K left, bottom;
		OperationsOnGraphTracesWithMarquee(V_left, V_right, 5)
	else
		print "Operation needs a graph with left and bottom axes"
	endif
End

static Function CoordinatesToROIMask(variable left, variable top, variable right, variable bottom, [variable interior, variable exterior])
	/// Generate a Mask from Marquee
	/// The graph should have left, top axes
	/// By default the mask generated by ImageGenerateROIMask has 1 interior and 0 exterio values
	/// you can change the mask values with the optional parameters.
	
	/// Creates the wave M_ROIMask
	interior = ParamIsDefault(interior) ? 1: interior // if set do not read metadata
	exterior = ParamIsDefault(exterior) ? 0: exterior // if set do not read metadata
	
	string wnamestr = WMTopImageName()
	string winNameStr = WinName(0, 1, 1)
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,16385,16385), fillpat = 0, linethick = 0.5, xcoord = top, ycoord = left
	DrawRect/W=$winNameStr left, top, right, bottom
	ImageGenerateROIMask/i=(interior)/e=(exterior) $wnamestr
	DrawAction  delete
	SetDrawLayer UserFront
	return 0
End

static Function/WAVE WAVECoordinatesToROIMask(variable left, variable top, variable right, variable bottom)
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
	Duplicate/O/FREE M_ROIMask, ATH_ROIMask
	Redimension/S ATH_ROIMask
	KillWaves/Z M_ROIMask
	return ATH_ROIMask
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
					string selectedWaveStr = ATH_Dialog#SelectWavesInModalDataBrowser("Select notmalisation profile")
					WAVE waveProf = $StringFromList(0, selectedWaveStr)
					launchBrowserSwitch = 0
				endif
				
				ATH_WaveOp#NormaliseWaveWithWave(wRef, waveProf)
				
				break
			default:
				print "Unkwokn ATH_OperatiosGraphTracesForXAS operationSelection"
				break
		endswitch
		i++
	while (1)
	SetDataFolder currDFR
End

static Function Partition3DRegion()
	GetMarquee/K left, top;
	string imgNameTopGraphStr = StringFromList(0, ImageNameList("", ";"),";")
	WAVE waveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	DFREF saveDF = GetDataFolderDFR()
	string stacknameStr = CreateDataObjectName(saveDF, imgNameTopGraphStr + "_PART", 1, 0, 1)
	ATH_WaveOp#WavePartition(waveRef, stacknameStr, V_left, V_right, V_top, V_bottom, evenNum = 1)
	WAVE wavePRT = $stacknameStr
	CopyScales/P waveRef, wavePRT
	return 0
End

static Function GetMarqueeWaveStats()
	/// Wavestats for a marquee region in a 2D wave. In case of a 3D wave the stats 
	/// are calculated for all layers.
	GetMarquee left, top;
	string imgNameTopGraphStr = StringFromList(0, ImageNameList("", ";"),";")
	WAVE waveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	if(WaveDims(waveRef) == 2 || WaveDims(waveRef) == 3)
		WaveStats/RMD=(V_left, V_right)(V_top, V_bottom)[]/M=1 waveRef
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

static Function SaveROICoordinatesToDatabase([variable rect])
	// Save ROI to database and draw it on image's UserFront
	rect = ParamIsDefault(rect) ? 0: rect
	string dfrStr = "root:Packages:ATH_DataFolder:SavedROI"
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)
	GetMarquee/K left, top
	variable/G dfr:gATH_Sleft = V_left
	variable/G dfr:gATH_Sright = V_right
	variable/G dfr:gATH_Stop = V_top
	variable/G dfr:gATH_Sbottom = V_bottom
	variable/G dfr:gATH_SrectQ = rect
	SetDrawLayer UserFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, dash= 2, xcoord = top, ycoord = left
	if(rect)
		DrawRect V_left, V_top, V_right, V_bottom
	else
		DrawOval V_left, V_top, V_right, V_bottom	
	endif
	return 0
End

// The following three function let you select an area on a 2d/3d wave and return the coordinates.
static Function [variable leftR, variable rightR, variable topR, variable bottomR] UserGetMarqueePositions(STRUCT sUserMarqueePositions &s)
	//
	string winNameStr = WinName(0, 1, 1)	
	DoWindow/F $winNameStr			// Bring graph to front
	if (V_Flag == 0)					// Verify that graph exists
		Abort "WM_UserSetMarquee: No image in top window."
	endif
	string structStr
	string panelNameStr = UniqueName("PauseforCursor", 9, 0)
	NewPanel/N=$panelNameStr/K=2/W=(139,341,382,450) as "Set marquee on image"
	AutoPositionWindow/E/M=1/R=$winNameStr			// Put panel near the graph
	
	StructPut /S s, structStr
	DrawText 15,20,"Draw marquee and press continue..."
	DrawText 15,35,"Can also use a marquee to zoom-in"
	Button buttonContinue, win=$panelNameStr, pos={80,50},size={92,20}, title="Continue", proc=ATH_Marquee#UserSetMarquee_ContButtonProc 
	Button buttonCancel, win=$panelNameStr, pos={80,80},size={92,20}, title="Cancel", proc=ATH_Marquee#UserSetMarquee_CancelBProc
	SetWindow $winNameStr userdata(sATH_Coords)=structStr 
	SetWindow $winNameStr userdata(sATH_panelNameStr)= panelNameStr
	SetWindow $panelNameStr userdata(sATH_winNameStr) = winNameStr 
	SetWindow $panelNameStr userdata(sATH_panelNameStr) = panelNameStr
	PauseForUser $panelNameStr, $winNameStr
	StructGet/S s, GetUserData(winNameStr, "", "sATH_Coords")
	
	if(s.canceled)
		GetMarquee/W=$winNameStr/K
		Abort
	endif
	leftR = s.left
	rightR = s.right
	topR = s.top
	bottomR = s.bottom
	return [leftR, rightR , topR, bottomR]
End

static Function UserSetMarquee_ContButtonProc(STRUCT WMButtonAction &B_Struct): ButtonControl
	STRUCT sUserMarqueePositions s
	string winNameStr = GetUserData(B_Struct.win, "", "sATH_winNameStr")
	StructGet/S s, GetUserData(winNameStr, "", "sATH_Coords")
	string structStr
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			GetMarquee/W=$winNameStr/K left, top
			s.left = V_left
			s.right = V_right
			s.top = V_top
			s.bottom = V_bottom
			s.canceled = 0
			StructPut/S s, structStr
			SetWindow $winNameStr userdata(sATH_Coords) = structStr
			KillWindow/Z $GetUserData(B_Struct.win, "", "sATH_panelNameStr")
			break
	endswitch
	return 0
End

static Function UserSetMarquee_CancelBProc(STRUCT WMButtonAction &B_Struct) : ButtonControl
	STRUCT sUserMarqueePositions s
	string winNameStr = GetUserData(B_Struct.win, "", "sATH_winNameStr")
	StructGet/S s, GetUserData(winNameStr, "", "sATH_Coords")
	string structStr	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			s.left = 0
			s.right = 0
			s.top = 0
			s.bottom = 0
			s.canceled = 1
			StructPut/S s, structStr
			SetWindow $winNameStr userdata(sATH_Coords) = structStr
			KillWindow/Z $GetUserData(B_Struct.win, "", "sATH_panelNameStr")			
			break
	endswitch
	return 0
End
// End of marquee coordinates