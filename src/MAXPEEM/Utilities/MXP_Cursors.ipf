#pragma TextEncoding = "UTF-8"
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


Function MXP_GetDistanceFromCursors(string C1, string C2)
	/// Returns the distance between C1 and C2 if given.
	return sqrt((hcsr($C1) - hcsr($C2))^2 + (vcsr($C1) - vcsr($C2))^2)
End

Function MXP_GetDistanceFromABCursors()
	/// Returns the distance between cursors A & B.
	return sqrt((hcsr(A) - hcsr(B))^2 + (vcsr(A) - vcsr(B))^2)
End

Function MXP_MeasureDistanceUsingFreeCursorsCD()
	/// Use Cursors C, D (Free) to measure distances in a graph
	/// Uses MXP_MeasureDistanceUsingFreeCursorsCDHook. 
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
	SetWindow $winNameStr, hook(MXP_MeasureDistanceCsrDCHook) = MXP_MeasureDistanceUsingFreeCursorsCDHook
	TextBox/W=$winNameStr/C/A=LB/G=(65535,0,0)/E=2/N=DistanceCDInfo "\Z10Z-Toggle mode\ns - Scale (img)\nm(M)- Mark d(1/d)\ni - Mark (Inv. Sc)\nEsc - quit"
	SetWindow $winNameStr userdata(MXP_DistanceForScale) = "1"
	SetWindow $winNameStr userdata(MXP_SetScale) = "1"
	SetWindow $winNameStr userdata(MXP_CursorDistanceMode) = "0"
	SetWindow $winNameStr userdata(MXP_SavedDistanceForScale) = ""
End

Function MXP_MeasureDistanceUsingFreeCursorsCDHook(STRUCT WMWinHookStruct &s)
	/// Hook function for MXP_MeasureDistanceUsingFreeCursorsCD()
	variable hookResult = 0
	variable x1, x2, y1, y2, z1, z2, distance, vbuffer, inverseD, imgQ
	variable sscale = str2num(GetUserData(s.winName, "", "MXP_SetScale"))
	variable sdist = str2num(GetUserData(s.winName, "", "MXP_DistanceForScale"))
	variable factor = sscale / sdist
	x1 = hcsr(C, s.WinName)
	x2 = hcsr(D, s.WinName)
	y1 = vcsr(C, s.WinName)
	y2 = vcsr(D, s.WinName)
	z1 = zcsr(C, s.WinName)
	z2 = zcsr(D, s.WinName)
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
	inverseD = str2num(GetUserData(s.winName, "", "MXP_CursorDistanceMode")) // 0 - normal, 1 - inverse
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
	
		case 11: // Esc
			if(s.keycode == 27)
				TextBox/W=$s.WinName/K/N=DistanceCD
				TextBox/W=$s.WinName/K/N=DistanceCDInfo
				SetWindow $s.WinName, hook(MXP_MeasureDistanceCsrDCHook) = $""
				Cursor/W=$s.WinName/K C
				Cursor/W=$s.WinName/K D
				SetWindow $s.winName userdata(MXP_SetScale) = ""
				SetWindow $s.winName userdata(MXP_DistanceForScale) = ""
			endif
			if(s.keycode == 115) // press s
				if(imgQ) // scaling only for images
					vbuffer = MXP_GenericSingleVarPrompt("Scale distances", " \$WMTEX$ d_{CD} $/WMTEX$ scale")
					if(!vbuffer)
						vbuffer = 1
					endif
					SetWindow $s.winName userdata(MXP_SetScale) = num2str(vbuffer)
					SetWindow $s.winName userdata(MXP_DistanceForScale) = num2str(distance)
					scaleDrawCmd = "DrawLine/W=" + s.WinName + "  " + num2str(x1)+"," + num2str(y1) +"," + num2str(x2) +"," + num2str(y2)
					SetWindow $s.winName userdata(MXP_SavedDistanceToScale) = scaleDrawCmd
				endif
			endif
			if(s.keycode == 83) // press S
				scaleDrawCmd = GetUserData(s.winName, "", "MXP_SavedDistanceToScale")
				if(strlen(scaleDrawCmd)) // If a scale is saved
					sscanf scaleDrawCmd, ("DrawLine/W=%s %f,%f,%f,%f"), sdamp, x1, y2, x2, y2 // Restored the saved positions
					SetDrawLayer/W=$s.WinName UserFront
					SetDrawEnv/W=$s.WinName textrgb= (0,0,65535), xcoord =top, ycoord = left, textrot = -(atan((y2-y1)/(x2-x1))*180/pi)
					DrawText/W=$s.WinName (x1+x2)/2, (y1+y2)/2, "Ss: "+num2str(sscale)
					SetDrawEnv/W=$s.WinName arrow = 3, linefgc= (0,0,65535), xcoord =top, ycoord = left
					Execute/Q/Z scaleDrawCmd
				endif
			endif
			if(s.keycode == 122) // pressed z
				SetWindow $s.winName userdata(MXP_CursorDistanceMode) = num2str(!inverseD)
			endif
			if(s.keycode == 109) // Press m to mark
				if(!imgQ)
					SetDrawLayer/W=$s.WinName UserFront
					GetAxis/Q top
					if(V_flag) // V_flag == 1, top is not active
						axisX = "bottom"
					else
						axisX = "top"
					endif
					GetAxis/Q left
					if(V_flag) // V_flag == 1, left is not active
						axisY = "right"
					else
						axisY = "left"
					endif
					SetDrawEnv/W=$s.WinName textrgb=(0,0,65535),xcoord =$axisX, ycoord = $axisY
					DrawText/W=$s.WinName (x1+x2)/2, (y1+y2)/2, num2str(abs(x2-x1))
					SetDrawEnv/W=$s.WinName linefgc=(0,0,65535), arrow = 3, xcoord =$axisX, ycoord = $axisY
					DrawLine/W=$s.WinName x1, (y1+y2)/2, x2, (y1+y2)/2
				else
					SetDrawLayer/W=$s.WinName UserFront
					SetDrawEnv/W=$s.WinName linefgc= (0,0,65535), arrow = 3, xcoord =top, ycoord = left
					DrawLine/W=$s.WinName x1, y1, x2, y2
					SetDrawEnv/W=$s.WinName textrgb= (0,0,65535), xcoord =top, ycoord = left, textrot = -(atan((y2-y1)/(x2-x1))*180/pi)
					DrawText/W=$s.WinName (x1+x2)/2, (y1+y2)/2, "D:"+num2str(distance)
				endif
			endif
			if(s.keycode == 77) // Press M to mark 1/d or dy in graphs
				if(!imgQ)
					SetDrawLayer/W=$s.WinName UserFront
					GetAxis/Q top
					if(V_flag) // V_flag == 1, top is not active
						axisX = "bottom"
					else
						axisX = "top"
					endif
					GetAxis/Q left
					if(V_flag) // V_flag == 1, left is not active
						axisY = "right"
					else
						axisY = "left"
					endif
					SetDrawEnv/W=$s.WinName textrgb=(0,0,65535), xcoord=$axisX, ycoord = $axisY,  textrot= 90
					DrawText/W=$s.WinName (x1+x2)/2, (y1+y2)/2, num2str(abs(y2-y1))
					SetDrawEnv/W=$s.WinName linefgc= (0,0,65535), arrow = 3, xcoord =$axisX, ycoord = $axisY
					DrawLine/W=$s.WinName (x1+x2)/2, y1, (x1+x2)/2, y2
				else
					SetDrawLayer/W=$s.WinName UserFront
					SetDrawEnv/W=$s.WinName linefgc= (0,0,65535),arrow = 3, xcoord =top, ycoord = left
					DrawLine/W=$s.WinName x1, y1, x2, y2
					SetDrawEnv/W=$s.WinName textrgb=(0,0,65535), xcoord =top, ycoord = left, textrot = -(atan((y2-y1)/(x2-x1))*180/pi)
					DrawText/W=$s.WinName (x1+x2)/2, (y1+y2)/2, "I:"+num2str(1/distance)
				endif
			endif
			if(s.keycode == 105) // Press i to mark scaled inverse distance
				if(!imgQ)
					// Nothing is done, it might change in the future
				else
					SetDrawLayer/W=$s.WinName UserFront
					SetDrawEnv/W=$s.WinName linefgc= (0,0,65535), arrow = 3, xcoord =top, ycoord = left
					DrawLine/W=$s.WinName x1, y1, x2, y2
					SetDrawEnv/W=$s.WinName textrgb=(0,0,65535), xcoord =top, ycoord = left, textrot = -(atan((y2-y1)/(x2-x1))*180/pi)
					DrawText/W=$s.WinName (x1+x2)/2, (y1+y2)/2, "IS:" + num2str(sscale * sdist/distance)
				endif
			endif
			hookResult = 1 // Do not focus on Command window!
			break
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

Structure sUserCursorPositions
	// Used in MXP_UserGetMarqueePositions
	variable xstart
	variable ystart
	variable xend
	variable yend
	variable canceled
EndStructure

// The following three function let you set two cursors (AB) on an image stack
Function [variable xstart, variable ystart , variable xend, variable yend] MXP_UserGetABCursorPositions(STRUCT sUserCursorPositions &s)
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
	Button buttonContinue, win=$panelNameStr, pos={80,50},size={92,20}, title="Continue", proc=MXP_UserGetCursorsPositions_ContButtonProc 
	Button buttonCancel, win=$panelNameStr, pos={80,80},size={92,20}, title="Cancel", proc=MXP_UserGetCursorsPositions_CancelBProc
	SetWindow $winNameStr userdata(sMXP_ABCoords)=structStr 
	SetWindow $winNameStr userdata(sMXP_ABpanelNameStr)= panelNameStr
	SetWindow $panelNameStr userdata(sMXP_ABwinNameStr) = winNameStr 
	SetWindow $panelNameStr userdata(sMXP_ABpanelNameStr) = panelNameStr
	PauseForUser $panelNameStr, $winNameStr
	StructGet/S s, GetUserData(winNameStr, "", "sMXP_ABCoords")
	
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

Function MXP_UserGetCursorsPositions_ContButtonProc(STRUCT WMButtonAction &B_Struct): ButtonControl
	STRUCT sUserCursorPositions s
	string winNameStr = GetUserData(B_Struct.win, "", "sMXP_ABwinNameStr")
	StructGet/S s, GetUserData(winNameStr, "", "sMXP_ABCoords")
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
			SetWindow $winNameStr userdata(sMXP_ABCoords) = structStr
			KillWindow/Z $GetUserData(B_Struct.win, "", "sMXP_ABpanelNameStr")
			Cursor/W=$winNameStr/K A
			Cursor/W=$winNameStr/K B
			break
	endswitch
	return 0
End

Function MXP_UserGetCursorsPositions_CancelBProc(STRUCT WMButtonAction &B_Struct) : ButtonControl
	STRUCT sUserCursorPositions s
	string winNameStr = GetUserData(B_Struct.win, "", "sMXP_ABwinNameStr")
	StructGet/S s, GetUserData(winNameStr, "", "sMXP_ABCoords")
	string structStr	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			s.xstart = 0
			s.ystart = 0
			s.xend   = 0
			s.yend   = 0
			s.canceled = 1
			StructPut/S s, structStr
			SetWindow $winNameStr userdata(sMXP_ABCoords) = structStr
			KillWindow/Z $GetUserData(B_Struct.win, "", "sMXP_ABpanelNameStr")			
			break
	endswitch
	return 0
End
// End of marquee coordinates
