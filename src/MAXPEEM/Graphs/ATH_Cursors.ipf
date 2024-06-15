#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_Cursors
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

static constant kCBOFFSET = 30 // height of WM plane slider in 3d waves


static Function/S GetActiveCursors([string grfName])
	grfName = SelectString(ParamIsDefault(grfName), grfName, WinName(0,1,1))
	if (WinType(grfName) != 1)
		return ""
	endif
	
	String list = "ABCDEFGHIJ", active = "", info
	int i, n
	for (i = 0, n = strlen(list); i < n; i++)
		info = CsrInfo($(list[i]), grfName)
		if (!strlen(info) || strsearch(info, "A=0", 0)!=-1)
			continue
		endif
		active += list[i]
	endfor
	return active
End

static Function GetDistanceFromCursors(string C1, string C2)
	/// Returns the distance between C1 and C2 if given.
	return sqrt((hcsr($C1) - hcsr($C2))^2 + (vcsr($C1) - vcsr($C2))^2)
End

static Function GetDistanceFromABCursors()
	/// Returns the distance between cursors A & B.
	return sqrt((hcsr(A) - hcsr(B))^2 + (vcsr(A) - vcsr(B))^2)
End

static Function MeasureDistanceUsingFreeCursors()
	/// Use Cursors C, D (Free) to measure distances in a graph
	/// Uses ATH_MeasureDistanceUsingFreeCursorsCDHook.
	string winNameStr = WinName(0, 1, 1) //Top graph
	string topTraceNameStr = StringFromList(0, TraceNameList(winNameStr,";",1))
	if(strlen(topTraceNameStr)) // If you have a trace
		Cursor/A=1/F/H=1/S=1/C=(0,65535,0)/N=1/P C $topTraceNameStr 0.25, 0.45
		Cursor/A=1/F/H=1/S=1/C=(65535,0,0)/N=1/P D $topTraceNameStr 0.75, 0.55
	else
		string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
		Cursor/I/A=1/F/H=1/S=1/C=(0,65535,0)/N=1/P C $imgNameTopGraphStr 0.25, 0.45
		Cursor/I/A=1/F/H=1/S=1/C=(65535,0,0)/N=1/P D $imgNameTopGraphStr 0.75, 0.55
	endif
	variable lCBOFFSET 
	ControlInfo kwControlBar
	lCBOFFSET = V_height
	if(ATH_Windows#IsWM3DAxisActiveQ(winNameStr))
		lCBOFFSET = kCBOFFSET
		ControlBar V_height + lCBOFFSET
	else
		ControlBar V_height
	endif
	Button scaleB pos={10,4+lCBOFFSET}, size={65,20}, title="Scale", win=$winNameStr, help = {"Place cursots C, D and set scale"}, win=$winNameStr,proc=ATH_Cursors#MeasureDistanceButton
	Button drawscaleB pos={85, 4+lCBOFFSET}, size={80,20}, title="Draw Scale", win=$winNameStr, help = {"Save current scale for future use"}, win=$winNameStr,proc=ATH_Cursors#MeasureDistanceButton
	Button modeB pos={175,4+lCBOFFSET}, title="Direct", size={80,20}, win=$winNameStr, help = {"Change between direct and reciprocal mode"}, win=$winNameStr,proc=ATH_Cursors#MeasureDistanceButton
	Button markB pos={265,4+lCBOFFSET}, title="Mark", size={65,20}, win=$winNameStr, help = {"Change between direct and reciprocal mode"}, win=$winNameStr,proc=ATH_Cursors#MeasureDistanceButton
	Button closeB pos={340,4+lCBOFFSET}, title="Close", size={65,20}, fcolor=(65535,0,0), win=$winNameStr, help = {"Removes control bar"}, win=$winNameStr,proc=ATH_Cursors#MeasureDistanceButton	
	SetWindow $winNameStr, hook(ATH_MeasureDistanceCsrDCHook) = ATH_Cursors#MeasureDistanceUsingFreeCursorsHook

	string userdataStrQ = GetUserData(winNameStr, "", "ATH_SavedDistanceForScale")

	if(!strlen(userdataStrQ)) // If data were saved previously used them
		SetWindow $winNameStr userdata(ATH_DistanceForScale) = "1"
		SetWindow $winNameStr userdata(ATH_SetScale) = "1"
		SetWindow $winNameStr userdata(ATH_CursorDistanceMode) = "0"
		SetWindow $winNameStr userdata(ATH_SavedDistanceForScale) = ""
	endif

	if(!str2num(GetUserData(winNameStr, "", "ATH_CursorDistanceMode"))) // 0 - direct, 1 - reciprocal
		Button modeB, title = "Direct", fcolor=(65535,43690,0), win=$winNameStr
	else
		Button modeB, title = "Reciprocal", fcolor=(0,65535,26586), win=$winNameStr
	endif
	if(strlen(GetUserData(winNameStr, "", "ATH_SavedDistanceForScale"))) // 1 -- default scale, set the button green
		Button scaleB, fcolor=(0,65535,0), win=$winNameStr
	endif	
End

static Function MeasureDistanceUsingFreeCursorsHook(STRUCT WMWinHookStruct &s)
	/// Hook function for ATH_MeasureDistanceUsingFreeCursorsCD()
	variable hookResult = 0
	variable x1, x2, y1, y2, z1, z2, distance, vbuffer, inverseD, imgQ
	variable sscale = str2num(GetUserData(s.winName, "", "ATH_SetScale"))
	variable sdist = str2num(GetUserData(s.winName, "", "ATH_DistanceForScale"))
	variable factor = sscale / sdist
	x1 = hcsr(C, s.WinName);x2 = hcsr(D, s.WinName);y1 = vcsr(C, s.WinName);y2 = vcsr(D, s.WinName);z1 = zcsr(C, s.WinName);z2 = zcsr(D, s.WinName)
	distance = sqrt((x1-x2)^2 + (y1-y2)^2)
	string baseTextStr, cmdStr, notXStr, notYStr, notDStr, notscDStr, notZStr, axisX, axisY, scaleDrawCmd, sdamp
	if(abs(x1-x2) < 1e-4)
		notXStr = "%.3e"
	else
		notXStr = "%.4f"
	endif
	if(abs(y1-y2) < 1e-4)
		notYStr = "%.3e"
	else
		notYStr = "%.4f"
	endif
	if(abs(z1-z2) < 1e-4)
		notZStr = "%.3e"
	else
		notZStr = "%.4f"
	endif
	if(distance < 1e-4)
		notDStr = "%.3e"
	else
		notDStr = "%.4f"
	endif
	if(factor * distance < 1e-4)
		notscDStr = "%.3e"
	else
		notscDStr = "%.4f"
	endif
	//variable imgSwitch = 0
	//string topTraceNameStr = StringFromList(0, TraceNameList(s.WinName,";",1))
	inverseD = str2num(GetUserData(s.winName, "", "ATH_CursorDistanceMode")) // 0 - normal, 1 - inverse
	imgQ = !strlen(StringFromList(0, TraceNameList(s.WinName,";",1))) // 0 - trace, 1 - image

	if(!imgQ) // If you have a trace
		if(inverseD)
			baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceCD \"\\Z121/d\Bh\M\Z12 = " + notXStr + "\n1/d\Bv\M\Z12  = "+ notYStr +"\""
			sprintf cmdStr, baseTextStr, 1/abs(x1-x2), 1/abs(y1-y2)
		else
			baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceCD \"\\Z12d\Bh\M\Z12 = " +\
			notXStr + "\nd\Bv\M\Z12 = "+ notYStr +"\""
		endif
	else // if you have an image
		if(inverseD)
			baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceCD \"\\Z121/d\Bh\M\Z12 = " +\
			notXStr + "\n1/d\Bv\M\Z12 = "+ notYStr + "\n1/d\B\M\Z12 = "+ notDStr + "\n1/d\Bsc\M\Z12 = " +\
			notscDStr +"\nΔz\BCD\M\Z12 = "+ notZStr +"\""
		else
			baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceCD \"\\Z12d\Bh\M\Z12 = " +\
			notXStr + "\nd\Bv\M\Z12 = "+ notYStr + "\nd\B\M\Z12 = " + notDStr + "\nd\Bsc\M\Z12 = " + notscDStr +\
			"\nΔz\BCD\M\Z12 = " + notZStr + "\""
		endif
	endif
	
	switch(s.eventCode)
		case 7:
			if(imgQ)
				if(inverseD)
					sprintf cmdStr, baseTextStr, 1/abs(x1-x2), 1/abs(y1-y2), 1/distance, sscale * sdist/distance, (zcsr(D) - zcsr(C))
				else
					sprintf cmdStr, baseTextStr, abs(x1-x2), abs(y1-y2), distance, factor * distance, (zcsr(D) - zcsr(C))
				endif
			else
				if(inverseD)
					sprintf cmdStr, baseTextStr, 1/abs(x1-x2), 1/abs(y1-y2)
				else
					sprintf cmdStr, baseTextStr, abs(x1-x2), abs(y1-y2)
				endif

			endif
			Execute/Q/Z cmdStr
			hookResult = 1
			break
	endswitch
	return hookResult
End

Static Function MeasureDistanceButton(STRUCT WMButtonAction &s) // Todo: change this behavior

	if (s.eventCode != 2) // If not pressed return
		return 0
	endif

	variable x1, x2, y1, y2, z1, z2, distance, vbuffer, inverseD, imgQ, x1s, x2s, y1s, y2s
	variable sscale = str2num(GetUserData(s.win, "", "ATH_SetScale"))
	variable sdist = str2num(GetUserData(s.win, "", "ATH_DistanceForScale"))
	variable factor = sscale / sdist
	x1 = hcsr(C, s.win);x2 = hcsr(D, s.win);y1 = vcsr(C, s.win);y2 = vcsr(D, s.win);z1 = zcsr(C, s.win);z2 = zcsr(D, s.win)
	distance = sqrt((x1-x2)^2 + (y1-y2)^2)
	string baseTextStr, cmdStr, notXStr, notYStr, notDStr, notscDStr, notZStr, axisX, axisY, scaleDrawCmd, sdamp

	inverseD = str2num(GetUserData(s.win, "", "ATH_CursorDistanceMode")) // 0 - normal, 1 - inverse
	imgQ = !strlen(StringFromList(0, TraceNameList(s.win,";",1))) // 0 - trace, 1 - image
	[axisX, axisY] = ATH_Graph#GetAxes(graphName=s.win)
	strswitch (s.ctrlName)
		case "scaleB":
			if(imgQ) // scaling only for images
				Prompt vbuffer, "Enter value to scale"
				DoPrompt "Scale C, D cursor distance", vbuffer
				if(V_flag) // if you cancel
					return 1
				endif
				if(!vbuffer) // if you set scale to 0
					vbuffer = 1
					SetWindow $s.win userdata(ATH_SavedDistanceForScale) = ""
					Button scaleB, fcolor=(0,0,0)
					return 1
				endif
				SetWindow $s.win userdata(ATH_SetScale) = num2str(vbuffer)
				SetWindow $s.win userdata(ATH_DistanceForScale) = num2str(distance)
				scaleDrawCmd = "DrawLine/W=" + s.win + "  " + num2str(x1)+"," + num2str(y1) +"," + num2str(x2) +"," + num2str(y2)
				SetWindow $s.win userdata(ATH_SavedDistanceForScale) = scaleDrawCmd
				if(str2num(GetUserData(s.win, "", "ATH_SetScale")))
					Button scaleB, fcolor=(0,65535,26586)
				endif
			endif
			break
		case "drawscaleB":
			scaleDrawCmd = GetUserData(s.win, "", "ATH_SavedDistanceForScale")
			if(strlen(scaleDrawCmd)) // If a scale is saved
				sscanf scaleDrawCmd, ("DrawLine/W=%s %f,%f,%f,%f"), sdamp, x1s, y1s, x2s, y2s // Restored the saved positions
				SetDrawLayer/W=$s.win UserFront
				SetDrawEnv/W=$s.win textrgb= (65535,0,0), xcoord =$axisX, ycoord = $axisY, textrot = -(atan((y2s-y1s)/(x2s-x1s))*180/pi)
				DrawText/W=$s.win (x1s+x2s)/2, (y1s+y2s)/2, "Ss: "+ num2str(sscale)
				SetDrawEnv/W=$s.win arrow = 3, linefgc= (65535,0,0), xcoord =$axisX, ycoord = $axisY
				Execute/Q/Z scaleDrawCmd
			endif
			break
		case "modeB": // direct/reciprocal
			SetWindow $s.win userdata(ATH_CursorDistanceMode) = num2str(!inverseD)
			if(!str2num(GetUserData(s.win, "", "ATH_CursorDistanceMode"))) // 0 - direct, 1 - reciprocal
				Button modeB, title = "Direct", fcolor=(65535,43690,0), win=$s.win
			else
				Button modeB, title = "Reciprocal", fcolor=(65535,65535,0), win=$s.win
			endif
			break
		case "markB": // direct/reciprocal
			if(!imgQ)  // Traces
				SetDrawLayer/W=$s.win UserFront
				if(!str2num(GetUserData(s.win, "", "ATH_CursorDistanceMode"))) // 0 - direct, 1 - reciprocal
					SetDrawEnv/W=$s.win textrgb=(0,0,65535),xcoord =$axisX, ycoord = $axisY
					DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, num2str(abs(x2-x1))
					SetDrawEnv/W=$s.win linefgc=(0,0,65535), arrow = 3, xcoord =$axisX, ycoord = $axisY
					DrawLine/W=$s.win x1, (y1+y2)/2, x2, (y1+y2)/2
				else
					SetDrawEnv/W=$s.win textrgb=(0,0,65535), xcoord=$axisX, ycoord = $axisY,  textrot= 90
					DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, num2str(abs(y2-y1))
					SetDrawEnv/W=$s.win linefgc= (0,0,65535), arrow = 3, xcoord =$axisX, ycoord = $axisY
					DrawLine/W=$s.win (x1+x2)/2, y1, (x1+x2)/2, y2
				endif
			else  // Images
				if(!str2num(GetUserData(s.win, "", "ATH_CursorDistanceMode"))) // 0 - direct, 1 - reciprocal
					SetDrawLayer/W=$s.win UserFront
					SetDrawEnv/W=$s.win linefgc= (0,0,65535), arrow = 3, xcoord =$axisX, ycoord = $axisY
					DrawLine/W=$s.win x1, y1, x2, y2
					SetDrawEnv/W=$s.win textrgb= (0,0,65535), xcoord =$axisX, ycoord = $axisY, textrot = -(atan((y2-y1)/(x2-x1))*180/pi)
					if(strlen(GetUserData(s.win, "", "ATH_SavedDistanceForScale")))
						DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, "sD:"+num2str(factor * distance)
					else
						DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, "D:"+num2str(distance)
					endif
				else
					SetDrawLayer/W=$s.win UserFront
					SetDrawEnv/W=$s.win linefgc= (0,0,65535),arrow = 3,xcoord =$axisX, ycoord = $axisY
					DrawLine/W=$s.win x1, y1, x2, y2
					SetDrawEnv/W=$s.win textrgb=(0,0,65535), xcoord =$axisX, ycoord = $axisY, textrot = -(atan((y2-y1)/(x2-x1))*180/pi)
					if(strlen(GetUserData(s.win, "", "ATH_SavedDistanceForScale")))
						DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, "sR:"+num2str(sscale * sdist/distance)
					else
						DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, "R:"+num2str(1/distance)
					endif
				endif
			endif
			break
		case "closeB":
			TextBox/W=$s.win/K/N=DistanceCD
			TextBox/W=$s.win/K/N=DistanceCDInfo
			SetWindow $s.win, hook(ATH_MeasureDistanceCsrDCHook) = $""
			Cursor/W=$s.win/K C
			Cursor/W=$s.win/K D
			KillControl/W=$s.win scaleB
			KillControl/W=$s.win drawscaleB
			KillControl/W=$s.win modeB
			KillControl/W=$s.win markB
			KillControl/W=$s.win closeB
			if(ATH_Windows#IsWM3DAxisActiveQ(s.win))
				ControlInfo/W=$s.win kwControlBar
				ControlBar V_Height - kCBOFFSET
			else
				ControlBar/W=$s.win 0
			endif
			break
	endswitch
	return 0
End

Structure sUserCursorPositions
	// Used in UserGetMarqueePositions
	variable xstart
	variable ystart
	variable xend
	variable yend
	variable canceled
EndStructure

// The following three function let you set two cursors (AB) on an image stack
static Function [variable xstart, variable ystart , variable xend, variable yend] UserGetABCursorPositions(STRUCT sUserCursorPositions &s)
	//
	string winNameStr = WinName(0, 1, 1)	
	DoWindow/F $winNameStr			// Bring graph to front
	if (V_Flag == 0)					// Verify that graph exists
		Abort "WM_UserSetMarquee: No image in top window."
	endif
	string structStr
	string panelNameStr = UniqueName("PauseforABCursors", 9, 0)
	NewPanel/N=$panelNameStr/K=2/W=(139,341,382,450) as "Set marquee on image"
	AutoPositionWindow/E/M=1/R=$winNameStr			// Put panel near the graph
	
	StructPut /S s, structStr
	DrawText 15,20,"Set cursors A, B and press continue..."
	DrawText 15,35,"Can also use a marquee to zoom-in"
	Button buttonContinue, win=$panelNameStr, pos={80,50},size={92,20}, title="Continue", proc=ATH_Cursors#UserGetCursorsPositions_ContButtonProc 
	Button buttonCancel, win=$panelNameStr, pos={80,80},size={92,20}, title="Cancel", proc=ATH_Cursors#UserGetCursorsPositions_CancelBProc
	SetWindow $winNameStr userdata(sATH_ABCoords)=structStr 
	SetWindow $winNameStr userdata(sATH_ABpanelNameStr)= panelNameStr
	SetWindow $panelNameStr userdata(sATH_ABwinNameStr) = winNameStr 
	SetWindow $panelNameStr userdata(sATH_ABpanelNameStr) = panelNameStr
	PauseForUser $panelNameStr, $winNameStr
	StructGet/S s, GetUserData(winNameStr, "", "sATH_ABCoords")
	
	if(s.canceled)
		Cursor/W=$winNameStr/K A
		Cursor/W=$winNameStr/K B
		Abort
	endif
	xstart = s.xstart
	ystart = s.ystart
	xend = s.xend
	yend = s.yend
	return [xstart, ystart , xend, yend]
End

static Function UserGetCursorsPositions_ContButtonProc(STRUCT WMButtonAction &B_Struct): ButtonControl
	STRUCT sUserCursorPositions s
	string winNameStr = GetUserData(B_Struct.win, "", "sATH_ABwinNameStr")
	StructGet/S s, GetUserData(winNameStr, "", "sATH_ABCoords")
	string structStr
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			GetMarquee/W=$winNameStr/K left, top
			s.xstart = hcsr(A, winNameStr)
			s.ystart = vcsr(A, winNameStr)
			s.xend   = hcsr(B, winNameStr)
			s.yend   = vcsr(B, winNameStr)
			s.canceled = 0
			StructPut/S s, structStr
			SetWindow $winNameStr userdata(sATH_ABCoords) = structStr
			KillWindow/Z $GetUserData(B_Struct.win, "", "sATH_ABpanelNameStr")
			Cursor/W=$winNameStr/K A
			Cursor/W=$winNameStr/K B
			break
	endswitch
	return 0
End

static Function UserGetCursorsPositions_CancelBProc(STRUCT WMButtonAction &B_Struct) : ButtonControl
	STRUCT sUserCursorPositions s
	string winNameStr = GetUserData(B_Struct.win, "", "sATH_ABwinNameStr")
	StructGet/S s, GetUserData(winNameStr, "", "sATH_ABCoords")
	string structStr	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			s.xstart = 0
			s.ystart = 0
			s.xend   = 0
			s.yend   = 0
			s.canceled = 1
			StructPut/S s, structStr
			SetWindow $winNameStr userdata(sATH_ABCoords) = structStr
			KillWindow/Z $GetUserData(B_Struct.win, "", "sATH_ABpanelNameStr")			
			break
	endswitch
	return 0
End
// End of Cursor positions with PauseforUser

static Function CursorsToAngle(string Cursor1, string Cursor2 [, variable deg])
	// Returns the angle in rad or degrees of the line passing through Cursor1, Cursor2
	// Angle range [-π/2, π/2]. NOTE: Y- axis is reversed in images
	// We want compatibility with ImageRotate where positive angle rotate clock-wise
	//
	// Usage example:
	// Use the function do set a line with cursors and get the image rotated such as
	// the direction of the line is paralled to the top axis.
	//
	// ImageRotate/A=(ATH_CursorsToAngle(E, F, deg=1)) waveRef

	deg = ParamIsDefault(deg) ? 0 : 1
	variable XExists = strlen(CsrInfo($Cursor1))
	variable YExists = strlen(CsrInfo($Cursor2))
	if(!XExists)
		print "Cursor ", Cursor1, " not in graph"
		return -1
	endif
	if(!YExists)
		print "Cursor ", Cursor2, " not in graph"
		return -1
	endif
	variable x1 = hcsr($Cursor1)
	variable y1 = vcsr($Cursor1)
	variable x2 = hcsr($Cursor2)
	variable y2 = vcsr($Cursor2)

	variable angle, dx, dy
	if(y1 == y2)
		return 0
	elseif(x1 == x2)
		if(deg)
			return 90
		else
			return pi
		endif
	endif
	dy = y2 - y1
	dx = x2 - x1
	angle = (deg == 0) ? atan(dy/dx) : atan(dy/dx)*180/pi
	return angle
End

/// Generic interaction using a cursor and a CallbackFunction

static Function InteractiveXMLDFitInspection(WAVE wSrc, WAVE wRef)
	/// Interactive operation using a callback function
	/// ATH_Cursors#CursorCallBack(WAVE wSrc, WAVE wRef, variable p0, variable q0)
	//
	// WAVE wSrc - 3D Wave with XMLD images for different angles
	//
	// Check if the wave is displayed
	ATH_Display#NewImg(wRef)
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	// Use cursor C
	variable nrows = DimSize(wRef, 0)
	variable ncols = DimSize(wRef, 1)	
	Cursor/I/C=(65535,0,0)/S=1/P/N=1 B $imgNameTopGraphStr nrows/2, ncols/2
	// Make folder in database
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr) // Root folder here
	// Store globals
	string/G dfr:gATH_wRefPath = GetWavesDataFolder(wRef, 2)
	string/G dfr:gATH_wSrcPath = GetWavesDataFolder(wSrc, 2)
	// Hook and metadata
	SetWindow $winNameStr, hook(MyiCursorActionHook) = ATH_Cursors#iCursorUsingCallbackHookFunction // Set the hook
	SetWindow $winNameStr, userdata(MyiCursorWin) = winNameStr
	SetWindow $winNameStr, userdata(ATH_iCursorDFR) = "root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr
	Display/N=$(winNameStr + "_iFitPlot")/K=1
	DoWindow/F $winNameStr
	SetWindow $winNameStr, userdata(MyiplotWin) = winNameStr + "_iFitPlot"
	return 0
End

static Function iCursorUsingCallbackHookFunction(STRUCT WMWinHookStruct &s)
	variable hookResult = 0
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr)
	string plotNameStr = GetUserData(s.winName, "", "MyiplotWin")
	SVAR/SDFR=dfr gATH_wRefPath, gATH_wSrcPath
	WAVE/Z wRef = $gATH_wRefPath
	WAVE/Z wSrc = $gATH_wSrcPath
	switch(s.eventCode)
		case 2:
			KillWindow/Z $plotNameStr
			KillDataFolder/Z dfr
			break
		case 7: // cursor moved
			if(!cmpstr(s.cursorName, "B")) // It should work only with E, F you might have other cursors on the image
				CursorCallBack(wSrc, wRef, s.pointNumber, s.ypointNumber) // Function using row, column
				//CursorCallBack3(wRef, s.pointNumber, s.ypointNumber) // Function using row, column
			endif
			hookResult = 1
			break
			hookresult = 1
			break
		case 11: // Keyboard event
			if(s.keycode == 27) //  Esc
				SetWindow $s.winName, hook(MyiCursorActionHook) = $""
				Cursor/K/W=$s.winName B
				KillDataFolder/Z dfr
			endif
	endswitch
	return hookResult       // 0 if nothing done, else 1
End

static Function CursorCallBack(WAVE wSrc, WAVE wRef, variable p0, variable q0)
	
	DFREF dfr = $GetUserData("", "", "ATH_iCursorDFR")
	DFREF wdfr = GetWavesDataFolderDFR(wRef)
	string winNameStr = GetUserData("", "", "MyiCursorWin")
	string plotNameStr = GetUserData("", "", "MyiplotWin")	
	MatrixOP/O dfr:cursorBeamProfile = beam(wSrc, p0, q0)
	WAVE wOff = wdfr:$(NameOfWave(wRef)+"_Off")
	WAVE wy0 = wdfr:$(NameOfWave(wRef)+"_y0")
	Make/O dfr:fitPlotW /WAVE=wsin
	SetScale/I x, -pi/2, pi/2, wsin, dfr:cursorBeamProfile // EDIT HERE
	variable xOff = wOff[p0][q0]
	variable xy0 = wy0[p0][q0]
	variable phase = wRef[p0][q0]*pi/180 // sin() needs rad
	wsin = xOff + xy0 * sin(x + phase)^2
	RemoveFromGraph/W=$plotNameStr/ALL
	AppendToGraph/W=$plotNameStr dfr:cursorBeamProfile
	ModifyGraph/W=$plotNameStr mode(cursorBeamProfile)=3,marker(cursorBeamProfile)=19,msize(cursorBeamProfile)=4
	AppendToGraph/W=$plotNameStr wsin 
	ModifyGraph/W=$plotNameStr lsize(fitPlotW)=2,rgb(fitPlotW)=(1,16019,65535)
	return 0
End
