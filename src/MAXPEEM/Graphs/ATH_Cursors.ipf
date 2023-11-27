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


static Function GetDistanceFromCursors(string C1, string C2)
	/// Returns the distance between C1 and C2 if given.
	return sqrt((hcsr($C1) - hcsr($C2))^2 + (vcsr($C1) - vcsr($C2))^2)
End

static Function GetDistanceFromABCursors()
	/// Returns the distance between cursors A & B.
	return sqrt((hcsr(A) - hcsr(B))^2 + (vcsr(A) - vcsr(B))^2)
End

static Function MeasureDistanceUsingFreeCursorsCD()
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
	SetWindow $winNameStr, hook(ATH_MeasureDistanceCsrDCHook) = ATH_Cursors#MeasureDistanceUsingFreeCursorsCDHook
	TextBox/W=$winNameStr/C/A=LB/G=(65535,0,0)/E=2/N=DistanceCDInfo "\Z10Z-Toggle mode\ns - Scale (img)\nm(M)- Mark d(1/d)\ni - Mark (Inv. Sc)\nEsc - quit"
	string userdataStrQ = GetUserData(winNameStr, "", "ATH_SavedDistanceForScale")
	print userdataStrQ
	if(!strlen(userdataStrQ)) // If data were saved previously used them
		SetWindow $winNameStr userdata(ATH_DistanceForScale) = "1"
		SetWindow $winNameStr userdata(ATH_SetScale) = "1"
		SetWindow $winNameStr userdata(ATH_CursorDistanceMode) = "0"
		SetWindow $winNameStr userdata(ATH_SavedDistanceForScale) = ""
	endif
End

static Function MeasureDistanceUsingFreeCursorsCDHook(STRUCT WMWinHookStruct &s)
	/// Hook function for ATH_MeasureDistanceUsingFreeCursorsCD()
	variable hookResult = 0
	variable x1, x2, y1, y2, z1, z2, distance, vbuffer, inverseD, imgQ
	variable sscale = str2num(GetUserData(s.winName, "", "ATH_SetScale"))
	variable sdist = str2num(GetUserData(s.winName, "", "ATH_DistanceForScale"))
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
	
		case 11: // Esc
			if(s.keycode == 27)
				TextBox/W=$s.WinName/K/N=DistanceCD
				TextBox/W=$s.WinName/K/N=DistanceCDInfo
				SetWindow $s.WinName, hook(ATH_MeasureDistanceCsrDCHook) = $""
				Cursor/W=$s.WinName/K C
				Cursor/W=$s.WinName/K D
			endif
			if(s.keycode == 115) // press s
				if(imgQ) // scaling only for images
					Prompt vbuffer, "Enter value to scale"
					DoPrompt "Scale C, D cursor distance", vbuffer
					if(V_flag) // if you cancel
						hookResult = 1
						break
					endif 
					if(!vbuffer) // if you set scale to 0
						vbuffer = 1
					endif
					SetWindow $s.winName userdata(ATH_SetScale) = num2str(vbuffer)
					SetWindow $s.winName userdata(ATH_DistanceForScale) = num2str(distance)
					scaleDrawCmd = "DrawLine/W=" + s.WinName + "  " + num2str(x1)+"," + num2str(y1) +"," + num2str(x2) +"," + num2str(y2)
					SetWindow $s.winName userdata(ATH_SavedDistanceForScale) = scaleDrawCmd
				endif
			endif
			if(s.keycode == 83) // press S
				scaleDrawCmd = GetUserData(s.winName, "", "ATH_SavedDistanceForScale")
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
				SetWindow $s.winName userdata(ATH_CursorDistanceMode) = num2str(!inverseD)
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

static Function InteractiveCursorAction(WAVE wRef)
	/// Interactive operation using a callback functio
	/// ATH_CursorCallBack()
	
	// Check if the wave is displayed
	CheckDisplayed/A wRef
	if(!V_flag)
		ATH_Display#NewImg(wRef)
	endif
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	// Use cursor C
	variable nrows = DimSize(wRef, 0)
	variable ncols = DimSize(wRef, 1)	
	Cursor/I/C=(65535,0,0)/S=1/P/N=1 C $imgNameTopGraphStr nrows/2, ncols/2
	// Make folder in database
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr) // Root folder here
	// Store globals
	string/G dfr:gATH_wRefDataFolder = GetWavesDataFolder(wRef, 2)
	// Hook and metadata
	SetWindow $winNameStr, hook(MyiCursorActionHook) = ATH_Cursors#iCursorUsingCallbackHookFunction // Set the hook
	SetWindow $winNameStr, userData(ATH_iCursorDFR) = "root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr
	return 0
End

static Function iCursorUsingCallbackHookFunction(STRUCT WMWinHookStruct &s)
    variable hookResult = 0
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iCursorAction:" + imgNameTopGraphStr) // imgNameTopGraphStr will have '' if needed.
	SVAR/SDFR=dfr gATH_wRefDataFolder
	WAVE wRef = $gATH_wRefDataFolder
		switch(s.eventCode)
	    case 7: // cursor moved
			if(!cmpstr(s.cursorName, "C")) // It should work only with E, F you might have other cursors on the image
				CursorCallBack(wRef, s.pointNumber, s.ypointNumber) // Function using row, column
			endif
	   			hookResult = 1
	   			break
			hookresult = 0
			break
		case 11: // Keyboard event
			if(s.keycode == 27) //  Esc
				SetWindow $s.WinName, hook(MyiCursorActionHook) = $""
				Cursor/K/W=$s.WinName C
				KillDataFolder/Z dfr
			endif			
    endswitch
    return hookResult       // 0 if nothing done, else 1
End

static Function CursorCallBack(WAVE wRef, variable p0, variable q0)
	MatrixOP/O root:getBeam = beam(wRef, p0, q0)
	WAVE wOff = root:XMLD:XMLDStack_4x4x1_XMLDMap_offset
	WAVE wfact = root:XMLD:XMLDStack_4x4x1_XMLDMap_factor
	WAVE wphase = root:XMLD:XMLDStack_4x4x1_XMLDMap	
	Make/O root:sinPlotW /WAVE=wsin
	SetScale/I x, (-pi/2 + pi/18), pi/2, wsin, root:getBeam
	variable xOff = wOff[p0][q0]
	variable xFact = wfact[p0][q0]
	variable phase = wphase[p0][q0]
	wsin = xOff + xFact * sin(x + phase)^2
	RemoveFromGraph/W=Graph0/ALL
	AppendToGraph/W=Graph0 root:getBeam;ModifyGraph/W=Graph0 mode(getBeam)=3,marker(getBeam)=19,msize(getBeam)=4
	AppendToGraph/W=Graph0 wsin; ModifyGraph/W=Graph0 lsize(sinPlotW)=2,rgb(sinPlotW)=(1,16019,65535)
//	RemoveFromGraph/W=Graph0/ALL
//	AppendToGraph/W=Graph0 root:getBeam
	return 0
End

/// End of generic interaction using a cursor and a CallbackFunction
