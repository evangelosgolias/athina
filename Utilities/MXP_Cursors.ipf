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
	/// TODO: Improve is and implement something similar to Gwyddion.
	string winNameStr = WinName(0, 1, 1) //Top graph
	string topTraceNameStr = StringFromList(0, TraceNameList(winNameStr,";",1))
	
	if(strlen(topTraceNameStr)) // If you have a trace
		Cursor/A=1/F/H=1/S=0/C=(65535,0,0,30000)/P C $topTraceNameStr 0.25, 0.5
		Cursor/A=1/F/H=1/S=0/C=(65535,0,0,30000)/P D $topTraceNameStr 0.75, 0.5
	else
		string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
		Cursor/I/A=1/F/H=1/S=0/C=(65535,0,0,30000)/P C $imgNameTopGraphStr 0.25, 0.5
		Cursor/I/A=1/F/H=1/S=0/C=(65535,0,0,30000)/P D $imgNameTopGraphStr 0.75, 0.5
	endif
	SetWindow $winNameStr, hook(MeasureDistanceCsrDCHook) = MXP_MeasureDistanceUsingFreeCursorsCDHook
	TextBox/W=$winNameStr/C/A=LT/G=(65535,0,0)/N=DistanceCDQuit "Z - 1/d\nEsc to quit"
End

Function MXP_MeasureDistanceUsingFreeCursorsCDHook(STRUCT WMWinHookStruct &s)
	/// Hook function for MXP_MeasureDistanceUsingFreeCursorsCD()
	variable hookResult = 0
	variable x1, x2, y1, y2
	x1 = hcsr(C, s.WinName)
	x2 = hcsr(D, s.WinName)
	y1 = vcsr(C, s.WinName)
	y2 = vcsr(D, s.WinName)
	string baseTextStr, cmdStr, notXStr, notYStr
	if(abs(x1-x2) < 1e-4)
		notXStr = "%.5e"
	else
		notXStr = "%.5f"
	endif
	if(abs(y1-y2) < 1e-4)
		notYStr = "%.5e"
	else
		notYStr = "%.5f"
	endif
	
	variable imgSwitch = 0
	string topTraceNameStr = StringFromList(0, TraceNameList(s.WinName,";",1))
	if(strlen(topTraceNameStr)) // If you have a trace
		baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceCD \"\\Z12d\Bh\M\Z12 = " +\
		notXStr + "\nd\Bv\M\Z12 ="+ notYStr +"\""
	else
		baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceCD \"\\Z12d\Bh\M\Z12 = " +\
		notXStr + "\nd\Bv\M\Z12 ="+ notYStr + "\nd\B\M\Z12 =" + notYStr + "\""
		imgSwitch = 1
	endif
	
	switch(s.eventCode)
		case 11:
			if(s.keycode == 27)
				TextBox/W=$s.WinName/K/N=DistanceCD
				TextBox/W=$s.WinName/K/N=DistanceCDQuit
				SetWindow $s.WinName, hook(MeasureDistanceCsrDCHook) = $""
				Cursor/W=$s.WinName/K C
				Cursor/W=$s.WinName/K D
			endif
			if(s.keycode == 122) // pressed z
				x1 = hcsr(C, s.WinName)
				x2 = hcsr(D, s.WinName)
				y1 = vcsr(C, s.WinName)
				y2 = vcsr(D, s.WinName)
				if(imgSwitch)
					baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceCD \"\\Z121/d\Bh\M\Z12 = " +\
					notXStr + "\n1/d\Bv\M\Z12 ="+ notYStr + "\n1/d\B\M\Z12 ="+ notYStr +"\""
					sprintf cmdStr, baseTextStr, 1/abs(x1-x2), 1/abs(y1-y2), 1/sqrt(abs(x1-x2)^2 + abs(y1-y2)^2)
				else
					baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceCD \"\\Z121/d\Bh\M\Z12 = " + notXStr + "\n1/d\Bv\M\Z12 ="+ notYStr +"\""
					sprintf cmdStr, baseTextStr, 1/abs(x1-x2), 1/abs(y1-y2)
				endif

				Execute/P/Q/Z cmdStr
			endif
			hookResult = 1
			break
		case 7:
			x1 = hcsr(C, s.WinName)
			x2 = hcsr(D, s.WinName)
			y1 = vcsr(C, s.WinName)
			y2 = vcsr(D, s.WinName)
			if(imgSwitch)
				sprintf cmdStr, baseTextStr, abs(x1-x2), abs(y1-y2), sqrt(abs(x1-x2)^2 + abs(y1-y2)^2)
			else
				sprintf cmdStr, baseTextStr, abs(x1-x2), abs(y1-y2)
			endif
			Execute/P/Q/Z cmdStr
			hookResult = 1
			break
	endswitch
	return hookResult
End
