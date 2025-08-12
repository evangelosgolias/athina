#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_Cursors
#pragma version = 1.3
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


/// 06.12.2024: When you plot a trace and you launch MeasureDistanceUsingFreeCursors
/// without any interaction with the window, the buttons do not work. You have to move
/// the window to enable the buttons. 

static constant kCBOFFSET = 30 // height slider in 3d waves

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

// Interactive functionality
static Function MeasureDistanceUsingFreeCursors()	
	/// Use Cursors I, J (Free) to measure distances in a graph
	/// Uses ATH_MeasureDistanceUsingFreeCursorsIJHook.
	string winNameStr = WinName(0, 1, 1) //Top graph
	string topTraceNameStr = StringFromList(0, TraceNameList(winNameStr,";",1))
	if(strlen(topTraceNameStr)) // If you have a trace
		Cursor/A=1/F/H=1/S=1/C=(16385,49025,65535)/N=1/P I $topTraceNameStr 0.25, 0.45
		Cursor/A=1/F/H=1/S=1/C=(65535,43690,0)/N=1/P J $topTraceNameStr 0.75, 0.55
	else
		string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
		Cursor/I/A=1/F/H=1/S=1/C=(16385,49025,65535)/N=1/P I $imgNameTopGraphStr 0.25, 0.45
		Cursor/I/A=1/F/H=1/S=1/C=(65535,43690,0)/N=1/P J $imgNameTopGraphStr 0.5, 0.5 // start at the center, FFT friendly!
	endif
	variable lCBOFFSET 
	ControlInfo/W=winNameStr kwControlBar
	lCBOFFSET = V_height
	
	// if the hook is there you have already launch it!
	GetWindow $winNameStr hook(ATH_MeasureDistanceCsrIJHook)
	// if there is slider and MeasureDistanceUsingFreeCursors is on
	if(strlen(S_Value))
		return 1
	endif	
	
	ControlBar/W=$winNameStr lCBOFFSET + kCBOFFSET		
	
	Button scaleCrsB pos={10,4+lCBOFFSET}, size={60,20}, title="Scale", win=$winNameStr
	Button scaleCrsB help = {"Place cursots C, D and set scale"},fcolor=(65535,0,0),proc=ATH_Cursors#MeasureDistanceButton,win=$winNameStr
	Button modeCrsB pos={75,4+lCBOFFSET}, title="Direct", size={80,20},win=$winNameStr
	Button modeCrsB help = {"Change between direct and reciprocal mode"}, proc=ATH_Cursors#MeasureDistanceButton,win=$winNameStr
	Button markCrsB pos={160,4+lCBOFFSET}, title="Mark", size={55,20},win=$winNameStr
	Button markCrsB help = {"Mark distace (1D: with SHIFT pressed marks dv (1-D) or scale in 2D"},proc=ATH_Cursors#MeasureDistanceButton,win=$winNameStr
	Button dLogCrsB pos={220,4+lCBOFFSET}, title="DLog", fcolor=(65535,0,0),size={55,20},win=$winNameStr
	Button dLogCrsB help = {"Measure distances, press SHIFT+Click to register a point."},proc=ATH_Cursors#MeasureDistanceButton,win=$winNameStr	
	Button angleCrsB pos={280,4+lCBOFFSET}, title="Angle",size={55,20},win=$winNameStr
	Button angleCrsB help = {"Measure angle with apex at cursor F."},proc=ATH_Cursors#MeasureDistanceButton,win=$winNameStr		
	Button closeCrsB pos={340,4+lCBOFFSET}, title="Close", size={50,20},fcolor=(0,0,65535),win=$winNameStr
	Button closeCrsB help = {"Removes control bar"},proc=ATH_Cursors#MeasureDistanceButton, win=$winNameStr
	// Add metadata
	Button scaleCrsB, win=$winNameStr, userdata(ATH_SetScale) = "1", userdata(ATH_SavedDistanceForScale) = "", userdata(ATH_DistanceForScale) = "1"
	Button modeCrsB, win=$winNameStr, userdata(ATH_CursorDistanceMode) = "0"
	Button angleCrsB, win=$winNameStr, userdata(ATH_MeasureAngle) = ""
	if(!str2num(GetUserData(winNameStr, "modeCrsB", "ATH_CursorDistanceMode"))) // 0 - direct, 1 - reciprocal
		Button modeCrsB, title = "Direct", fcolor=(65535,43690,0), win=$winNameStr
	else
		Button modeCrsB, title = "Reciprocal", fcolor=(0,65535,26586), win=$winNameStr
	endif
	// Set the main hook.			
	SetWindow $winNameStr, hook(ATH_MeasureDistanceCsrIJHook) = ATH_Cursors#MeasureDistanceUsingFreeCursorsHook

End

static Function MeasureDistanceUsingFreeCursorsHook(STRUCT WMWinHookStruct &s)
	/// Hook function for ATH_MeasureDistanceUsingFreeCursorsIJ()
	variable hookResult = 0
	string axisX, axisY, baseTextStr, cmdStr
	[axisX, axisY] = ATH_Graph#GetAxes(grfName=s.winName)
	variable xVal, yVal, dimWStr, dmode, dist
	DFREF dLogDF = $("root:Packages:ATH_DataFolder:iDistanceLogger:" + s.winName)
	NVAR/SDFR=dLogDF/Z ath_ClickRegisterSwitch; NVAR/SDFR=dLogDF/Z ath_gposX; NVAR/SDFR=dLogDF/Z ath_gposY
	WAVE/Z dLogW = dLogDF:DistanceLogger
	variable imax = DimSize(dLogW,0), i
	switch(s.eventCode)
		case 4:
			// currently button is disabled for wavedims != 1
			if(strlen(GetUserData(s.winName, "dLogCrsB", "CursorDistanceLogMode")))
				dimWStr = str2num(GetUserData(s.winName, "dLogCrsB", "CursorDistanceLogMode"))
				if(dimWStr==1)
					SetDrawLayer/W=$s.winName ProgFront
					DrawAction/W=$s.winName delete
					SetDrawEnv/W=$s.winName linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = $axisX, ycoord = axrel
					SetDrawEnv/W=$s.winName xcoord= $axisX,ycoord= axrel
					xVal = AxisValFromPixel(s.winName, axisX, s.mouseLoc.h)
					DrawLine xVal, 0, xVal, 1
					//SetDrawEnv/W=$s.winName xcoord= axrel,ycoord= $axisY
					//yVal = AxisValFromPixel(s.winName, axisY, s.mouseLoc.v)
					//DrawLine 0, yVal, 1, yVal
					SetDrawLayer/W=$s.winName UserFront
				else
					SetDrawLayer/W=$s.winName ProgFront
					DrawAction/W=$s.winName delete
					if(ath_ClickRegisterSwitch && (s.eventMod & 2))
						SetDrawLayer/W=$s.winName ProgFront
						SetDrawEnv/W=$s.winName linefgc = (0,0,0,65535), fillpat = 0, linethick = 1, xcoord = $axisX, ycoord = $axisY
						DrawLine/W=$s.winName ath_gposX, ath_gposY, AxisValFromPixel(s.winName, axisX, s.mouseLoc.h), AxisValFromPixel(s.winName, axisY, s.mouseLoc.v)
					elseif(ath_ClickRegisterSwitch)
						for(i = 0;i < imax; i++)
							if(!numtype(dLogW[i][0]) && numtype(dLogW[i][3])) // if only the first point is registered
								dLogW[i][] = NaN
								ath_ClickRegisterSwitch = 0
								break
							endif
						endfor
					endif
				endif
			endif
			break
		case 5:
			if(strlen(GetUserData(s.winName, "dLogCrsB", "CursorDistanceLogMode")) && (s.eventMod & 2))
				dimWStr = str2num(GetUserData(s.winName, "dLogCrsB", "CursorDistanceLogMode"))
				if(dimWStr==1)					
					xVal = AxisValFromPixel(s.winName, axisX, s.mouseLoc.h)
					for(i = 0;i < imax; i++)
						if(numtype(dLogW[i][0]))  // NaN here
							dLogW[i][0] = xVal
							if(i > 0)
								dLogW[i][1] = xVal - dLogW[i-1][0]
							endif
							SetDrawLayer/W=$s.winName UserFront
							SetDrawEnv/W=$s.winName xcoord= $axisX,ycoord= axrel
							DrawLine xVal, 0, xVal, 1
							baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=distMeanLog/X=80/Y=-2.5 \"\\Z12d\Bavg\M\Z12 = " + "%.4f\""
							sprintf cmdStr, baseTextStr, ATH_Num#RunningMeanDifferenceZapNaN(dLogW, dim = 1, colN = 0)
							Execute/Q/Z cmdStr
							break
						endif
					endfor
				else
					xVal = AxisValFromPixel(s.winName, axisX, s.mouseLoc.h)
					yVal = AxisValFromPixel(s.winName, axisY, s.mouseLoc.v)
					for(i = 0;i < imax; i++)
						if(numtype(dLogW[i][3]))  // 3 is important here, we need a pair to be registed to proceed with the calculation
							if(!ath_ClickRegisterSwitch)
								dLogW[i][0] = xVal
								dLogW[i][1] = yVal
								ath_gposX = xVal
								ath_gposY = yVal
								ath_ClickRegisterSwitch = 1
							else
								dLogW[i][2] = xVal
								dLogW[i][3] = yVal
								ath_ClickRegisterSwitch = 0
							endif
							dmode = str2num(GetUserData(s.winName, "modeCrsB", "ATH_CursorDistanceMode")) // 0 - direct, 1 - reciprocal
							dist = sqrt( (dLogW[i][0] - dLogW[i][2])^2 + (dLogW[i][1] - dLogW[i][3])^2 )
							dLogW[i][4] = dmode ? 1/dist : dist
							if(i > 0)
								dLogW[i][5] = abs(dLogW[i][4]-dLogW[i-1][4])
							endif
							SetDrawLayer/W=$s.winName UserFront
							SetDrawEnv/W=$s.winName linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord= $axisX, ycoord= $axisY
							DrawLine dLogW[i][0], dLogW[i][1], dLogW[i][2], dLogW[i][3]
							SetDrawEnv/W=$s.winName linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord= $axisX, ycoord= $axisY
							DrawText/W=$s.winName (dLogW[i][0]+dLogW[i][2])/2, (dLogW[i][1]+dLogW[i][3])/2, num2str(i)
							baseTextStr = "TextBox/W="+PossiblyQuoteName(s.winName)+"/C/N=distMeanLog/X=80/Y=2.5 \"\\Z12d\Bavg\M\Z12 = " + "%.4f\""
							sprintf cmdStr, baseTextStr, ATH_Num#WaveBeamMeanZapNaN(dLogW, dim = 1, colN = 4)
							Execute/Q/Z cmdStr
							break
						endif
					endfor						
				endif
			endif
			break
		case 7:
			if(strlen(GetUserData(s.winName, "dLogCrsB", "CursorDistanceLogMode")))
				hookResult = 1
				break
			endif
			variable x1, x2, y1, y2, z1, z2, distance, vbuffer, inverseD, imgQ
			variable sscale = str2num(GetUserData(s.winName, "scaleCrsB", "ATH_SetScale"))
			variable sdist = str2num(GetUserData(s.winName, "scaleCrsB", "ATH_DistanceForScale"))
			variable factor = sscale / sdist
			inverseD = str2num(GetUserData(s.winName, "modeCrsB", "ATH_CursorDistanceMode")) // 0 - normal, 1 - inverse
			imgQ = !strlen(StringFromList(0, TraceNameList(s.WinName,";",1))) // 0 - trace, 1 - image
			x1 = hcsr(I, s.WinName);x2 = hcsr(J, s.WinName);y1 = vcsr(I, s.WinName);y2 = vcsr(J, s.WinName);z1 = zcsr(I, s.WinName);z2 = zcsr(J, s.WinName)
			distance = sqrt((x1-x2)^2 + (y1-y2)^2)
			string notXStr, notYStr, notDStr, notscDStr, notZStr, scaleDrawCmd, sdamp
			
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

			if(!imgQ) // If you have a trace
				if(inverseD)
					baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceIJ \"\\Z121/d\Bh\M\Z12 = " + notXStr + "\n1/d\Bv\M\Z12  = "+ notYStr +"\""
					sprintf cmdStr, baseTextStr, 1/abs(x1-x2), 1/abs(y1-y2)
				else
					baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceIJ \"\\Z12d\Bh\M\Z12 = " +\
					notXStr + "\nd\Bv\M\Z12 = "+ notYStr +"\""
				endif
			else // if you have an image
				if(inverseD)
					baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceIJ \"\\Z121/d\Bh\M\Z12 = " +\
					notXStr + "\n1/d\Bv\M\Z12 = "+ notYStr + "\n1/d\B\M\Z12 = "+ notDStr + "\n1/d\Bsc\M\Z12 = " +\
					notscDStr +"\nΔz\BIJ\M\Z12 = "+ notZStr// +"\"", check below
				else
					baseTextStr = "TextBox/W="+PossiblyQuoteName(s.WinName)+"/C/N=DistanceIJ \"\\Z12d\Bh\M\Z12 = " +\
					notXStr + "\nd\Bv\M\Z12 = "+ notYStr + "\nd\B\M\Z12 = " + notDStr + "\nd\Bsc\M\Z12 = " + notscDStr +\
					"\nΔz\BIJ\M\Z12 = " + notZStr// + "\"", check below
				endif
			
			// Do we have angleCrsB, here we add the missing "\""
			if(strlen(GetUserData(s.winName, "angleCrsB", "ATH_MeasureAngle")))
				baseTextStr += "\ntheta = %.2f" + "\""
			else
				baseTextStr += "\""
			endif
							
			endif
			if(imgQ)
				if(inverseD)
					if(strlen(GetUserData(s.winName, "angleCrsB", "ATH_MeasureAngle")))
						sprintf cmdStr, baseTextStr, 1/abs(x1-x2), 1/abs(y1-y2), 1/distance, sscale * sdist/distance, (zcsr(J) - zcsr(I)), ATH_Cursors#ThreeCursorsToAngle("I", "F", "J", deg = 1)
					else
						sprintf cmdStr, baseTextStr, 1/abs(x1-x2), 1/abs(y1-y2), 1/distance, sscale * sdist/distance, (zcsr(J) - zcsr(I))
					endif
				else
					if(strlen(GetUserData(s.winName, "angleCrsB", "ATH_MeasureAngle")))
						sprintf cmdStr, baseTextStr, abs(x1-x2), abs(y1-y2), distance, factor * distance, (zcsr(J) - zcsr(I)), ATH_Cursors#ThreeCursorsToAngle("I", "F", "J", deg = 1)
					else
						sprintf cmdStr, baseTextStr, abs(x1-x2), abs(y1-y2), distance, factor * distance, (zcsr(J) - zcsr(I))
					endif
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

	if (s.eventCode != 2) // If not pressed return, otherwise chaos
		return 0
	endif

	variable x1, x2, y1, y2, z1, z2, distance, vbuffer, inverseD, imgQ, x1s, x2s, y1s, y2s
	variable sscale = str2num(GetUserData(s.win, "scaleCrsB", "ATH_SetScale"))
	variable sdist = str2num(GetUserData(s.win, "scaleCrsB", "ATH_DistanceForScale"))
	variable factor = sscale / sdist
	string baseTextStr, cmdStr, notXStr, notYStr, notDStr, notscDStr, notZStr, axisX, axisY, scaleDrawCmd, sdamp

	inverseD = str2num(GetUserData(s.win, "modeCrsB", "ATH_CursorDistanceMode")) // 0 - normal, 1 - inverse
	imgQ = !strlen(StringFromList(0, TraceNameList(s.win,";",1))) // 0 - trace, 1 - image
	[axisX, axisY] = ATH_Graph#GetAxes(grfName=s.win)
	strswitch (s.ctrlName)
		case "scaleCrsB":
			if(imgQ) // scaling only for images
				Prompt vbuffer, "Enter value to scale"
				DoPrompt "Scale I, J cursor distance", vbuffer
				if(V_flag) // if you cancel
					return 1
				endif
				if(!vbuffer) // if you set scale to 0
					vbuffer = 1
					Button scaleCrsB, win=$s.win, fcolor=(0,0,0), userdata(ATH_SavedDistanceForScale) = ""
					return 1
				endif
				x1 = hcsr(I, s.win);x2 = hcsr(J, s.win);y1 = vcsr(I, s.win);y2 = vcsr(J, s.win);z1 = zcsr(I, s.win);z2 = zcsr(J, s.win)
				distance = sqrt((x1-x2)^2 + (y1-y2)^2)
				Button scaleCrsB, win=$s.win, userdata(ATH_SetScale) = num2str(vbuffer)
				Button scaleCrsB, win=$s.win, userdata(ATH_DistanceForScale) = num2str(distance)
				scaleDrawCmd = "DrawLine/W=" + s.win + "  " + num2str(x1)+"," + num2str(y1) +"," + num2str(x2) +"," + num2str(y2)
				Button scaleCrsB, win=$s.win, userdata(ATH_SavedDistanceForScale) = scaleDrawCmd
				if(str2num(GetUserData(s.win, "scaleCrsB", "ATH_SetScale")))
					Button scaleCrsB, fcolor=(0,65535,26586), win=$s.win
				endif
			endif
			break
		case "angleCrsB":
			if(!strlen(GetUserData(s.win, "angleCrsB", "ATH_MeasureAngle")) && imgQ)
				Button angleCrsB, win=$s.win, fcolor=(0,65535,26586), userdata(ATH_MeasureAngle) = "A"
				Cursor/I/A=1/F/H=1/S=1/C=(0,65535,26586)/N=1/P F $ATH_Graph#TopImageName(grfName=s.win) 0.45, 0.55
			else
				Button angleCrsB, win=$s.win, fcolor=(0,0,0), userdata(ATH_MeasureAngle) = ""
				Cursor/K/W=$s.win F
			endif
			
			break
		case "modeCrsB": // direct/reciprocal
			Button modeCrsB, win=$s.win, userdata(ATH_CursorDistanceMode) = num2str(!inverseD)
			if(!str2num(GetUserData(s.win, "modeCrsB", "ATH_CursorDistanceMode"))) // 0 - direct, 1 - reciprocal
				Button modeCrsB, title = "Direct", fcolor=(65535,43690,0), win=$s.win
			else
				Button modeCrsB, title = "Reciprocal", fcolor=(65535,65535,0), win=$s.win
			endif
			break
		case "markCrsB":
			x1 = hcsr(I, s.win);x2 = hcsr(J, s.win);y1 = vcsr(I, s.win);y2 = vcsr(J, s.win);z1 = zcsr(I, s.win);z2 = zcsr(J, s.win)
			distance = sqrt((x1-x2)^2 + (y1-y2)^2)
			if(!imgQ)  // Traces
				SetDrawLayer/W=$s.win UserFront
				if(!str2num(GetUserData(s.win, "modeCrsB", "ATH_CursorDistanceMode"))) // 0 - direct, 1 - reciprocal
					if(s.eventMod & 2)
						SetDrawEnv/W=$s.win textrgb=(65535,0,0),xcoord =$axisX, ycoord = $axisY, textrot= 90
						DrawText/W=$s.win x2, (y1+y2)/2, ("D:"+num2str(abs(y2-y1)))
						SetDrawEnv/W=$s.win linefgc=(65535,0,0), arrow = 3, xcoord =$axisX, ycoord = $axisY
						DrawLine/W=$s.win x2, y1, x2, y2
					else
						SetDrawEnv/W=$s.win textrgb=(65535,0,0),xcoord =$axisX, ycoord = $axisY
						DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, ("D:"+num2str(abs(x2-x1)))
						SetDrawEnv/W=$s.win linefgc=(65535,0,0), arrow = 3, xcoord =$axisX, ycoord = $axisY
						DrawLine/W=$s.win x1, (y1+y2)/2, x2, (y1+y2)/2
					endif
				else
					if(s.eventMod & 2)
						SetDrawEnv/W=$s.win textrgb=(65535,0,0),xcoord =$axisX, ycoord = $axisY, textrot= 90
						DrawText/W=$s.win x2, (y1+y2)/2, ("R:"+num2str(1/abs(y2-y1)))
						SetDrawEnv/W=$s.win linefgc=(65535,0,0), arrow = 3, xcoord =$axisX, ycoord = $axisY
						DrawLine/W=$s.win x2, y1, x2, y2
					else
						SetDrawEnv/W=$s.win textrgb=(65535,0,0),xcoord =$axisX, ycoord = $axisY
						DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, ("R:"+num2str(1/abs(x2-x1)))
						SetDrawEnv/W=$s.win linefgc=(65535,0,0), arrow = 3, xcoord =$axisX, ycoord = $axisY
						DrawLine/W=$s.win x1, (y1+y2)/2, x2, (y1+y2)/2
					endif
				endif
			else  // Images
				if(s.eventMod & 2)
					scaleDrawCmd = GetUserData(s.win, "scaleCrsB", "ATH_SavedDistanceForScale")
					if(strlen(scaleDrawCmd)) // If a scale is saved
						sscanf scaleDrawCmd, ("DrawLine/W=%s %f,%f,%f,%f"), sdamp, x1s, y1s, x2s, y2s // Restored the saved positions
						SetDrawLayer/W=$s.win UserFront
						SetDrawEnv/W=$s.win textrgb= (65535,0,0), xcoord =$axisX, ycoord = $axisY, textrot = -(atan((y2s-y1s)/(x2s-x1s))*180/pi)
						DrawText/W=$s.win (x1s+x2s)/2, (y1s+y2s)/2, "Ss: "+ num2str(sscale)
						SetDrawEnv/W=$s.win arrow = 3, linefgc= (65535,0,0), xcoord =$axisX, ycoord = $axisY
						Execute/Q/Z scaleDrawCmd
					endif
				// angelB = 1 and F, I, J cursors area active (dLog assumed false)
				elseif(strlen(GetUserData(s.win, "angleCrsB", "ATH_MeasureAngle")) \
				&& !cmpstr("FIJ", ATH_Cursors#GetActiveCursors(grfName=s.win)))
					SetDrawLayer/W=$s.win UserFront
					SetDrawEnv/W=$s.win linefgc= (0,65535,26586), xcoord =$axisX, ycoord = $axisY
					DrawLine/W=$s.win x1, y1, hcsr(F, s.win), vcsr(F, s.win)
					SetDrawEnv/W=$s.win linefgc= (0,65535,26586), xcoord =$axisX, ycoord = $axisY
					DrawLine/W=$s.win hcsr(F, s.win), vcsr(F, s.win), x2, y2
					SetDrawEnv/W=$s.win textrgb= (0,65535,26586), xcoord =$axisX, ycoord = $axisY, textrgb = (0,65535,26586)
					DrawText/W=$s.win hcsr(F, s.win), vcsr(F, s.win), "θ: "+ num2str(ATH_Cursors#ThreeCursorsToAngle("I", "F", "J", deg = 1))
				else
					if(!str2num(GetUserData(s.win, "modeCrsB", "ATH_CursorDistanceMode"))) // 0 - direct, 1 - reciprocal
						SetDrawLayer/W=$s.win UserFront
						SetDrawEnv/W=$s.win linefgc= (65535,16385,55749), arrow = 3, xcoord =$axisX, ycoord = $axisY
						DrawLine/W=$s.win x1, y1, x2, y2
						SetDrawEnv/W=$s.win textrgb= (65535,16385,55749), xcoord =$axisX, ycoord = $axisY, textrot = -(atan((y2-y1)/(x2-x1))*180/pi)
						if(strlen(GetUserData(s.win, "scaleCrsB", "ATH_SavedDistanceForScale")))
							DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, "sD:"+num2str(factor * distance)
						else
							DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, "D:"+num2str(distance)
						endif
					else
						SetDrawLayer/W=$s.win UserFront
						SetDrawEnv/W=$s.win linefgc= (65535,16385,55749),arrow = 3,xcoord =$axisX, ycoord = $axisY
						DrawLine/W=$s.win x1, y1, x2, y2
						SetDrawEnv/W=$s.win textrgb=(65535,16385,55749), xcoord =$axisX, ycoord = $axisY, textrot = -(atan((y2-y1)/(x2-x1))*180/pi)
						if(strlen(GetUserData(s.win, "scaleCrsB", "ATH_SavedDistanceForScale")))
							DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, "sR:"+num2str(sscale * sdist/distance)
						else
							DrawText/W=$s.win (x1+x2)/2, (y1+y2)/2, "R:"+num2str(1/distance)
						endif
					endif
				endif
			endif
			break
		case "dLogCrsB":
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iDistanceLogger:" + s.win)
			string dLoggerWinNameStr = s.win + "_DistanceLogger"
			if(strlen(GetUserData(s.win, "dLogCrsB", "CursorDistanceLogMode")))
				string imgNameTopGraphStr = ATH_Graph#TopImageName(grfName = s.win)
				if(strlen(imgNameTopGraphStr))
					Cursor/I/A=1/F/H=1/S=1/C=(16385,49025,65535)/N=1/P I $imgNameTopGraphStr 0.25, 0.45
					Cursor/I/A=1/F/H=1/S=1/C=(65535,43690,0)/N=1/P J $imgNameTopGraphStr 0.5, 0.5 // start at the center, FFT friendly!
				else
					string traceNameTopGraphStr = NameOfWave(ATH_Traces#TopTraceToWaveRef(grfName = s.win))
					Cursor/A=1/F/H=1/S=1/C=(16385,49025,65535)/N=1/P I $imgNameTopGraphStr 0.25, 0.45
					Cursor/A=1/F/H=1/S=1/C=(65535,43690,0)/N=1/P J $imgNameTopGraphStr 0.5, 0.5
				endif
				Button dLogCrsB, fcolor=(65535,0,0), userData(CursorDistanceLogMode) = ""
				Button markCrsB, disable = 0, win=$s.win
				SetDrawLayer/W=$s.win UserFront
				DrawAction/W=$s.win delete
				TextBox/K/N=distMeanLog
				KillWindow/Z $dLoggerWinNameStr
				KillDataFolder/Z dfr
			else
				variable dimW = WaveDims(ATH_Graph#TopGraphToWaveRef(grfName=s.win))
				Button dLogCrsB, fcolor=(0,65535,26586), userData(CursorDistanceLogMode) = num2str(dimW)
				Cursor/K/W=$s.win I
				Cursor/K/W=$s.win J
				TextBox/W=$s.win/K/N=DistanceIJ
				variable/G dfr:ath_ClickRegisterSwitch
				variable/G dfr:ath_gposX
				variable/G dfr:ath_gposY
				// Disable button
				Button markCrsB, disable = 2, win=$s.win
				if(!WaveExists(dfr:DistanceLogger))
					if(dimW == 1)
						Make/O/N=(64,2) dfr:DistanceLogger
						WAVE dLogW = dfr:DistanceLogger; dLogW = NaN
						SetDimLabel 1, 0, Position, dLogW
						SetDimLabel 1, 1, Difference, dLogW
					else
						Make/O/N=(64,6) dfr:DistanceLogger
						WAVE dLogW = dfr:DistanceLogger; dLogW = NaN
						SetDimLabel 1, 0, PosX1, dLogW
						SetDimLabel 1, 1, PosY1, dLogW
						SetDimLabel 1, 2, PosX2, dLogW
						SetDimLabel 1, 3, PosY2, dLogW
						SetDimLabel 1, 4, Distance, dLogW
						SetDimLabel 1, 5, Difference, dLogW
					endif
				endif
				if(!WinType(dLoggerWinNameStr))
					Edit/K=1/N=$dLoggerWinNameStr dfr:DistanceLogger.ld
				endif
			endif
			break
		case "closeCrsB":
			TextBox/W=$s.win/K/N=DistanceIJ
			SetWindow $s.win, hook(ATH_MeasureDistanceCsrIJHook) = $""
			Cursor/W=$s.win/K I
			Cursor/W=$s.win/K J
			if(strlen(GetUserData(s.win, "angleCrsB", "ATH_MeasureAngle")))
				Cursor/W=$s.win/K F
			endif
			SetDrawLayer/W=$s.win ProgFront // Clear the interactive line
			DrawAction/W=$s.win delete
			SetDrawLayer/W=$s.win UserFront
			KillControl/W=$s.win scaleCrsB
			KillControl/W=$s.win modeCrsB
			KillControl/W=$s.win markCrsB
			KillControl/W=$s.win closeCrsB
			KillControl/W=$s.win dLogCrsB
			KillControl/W=$s.win angleCrsB
			ControlInfo/W=$s.win kwControlBar
			ControlBar/W=$s.win V_Height - kCBOFFSET
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

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			STRUCT sUserCursorPositions s
			string winNameStr = GetUserData(B_Struct.win, "", "sATH_ABwinNameStr")
			StructGet/S s, GetUserData(winNameStr, "", "sATH_ABCoords")
			string structStr
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

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			STRUCT sUserCursorPositions s
			string winNameStr = GetUserData(B_Struct.win, "", "sATH_ABwinNameStr")
			StructGet/S s, GetUserData(winNameStr, "", "sATH_ABCoords")
			string structStr
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

static Function ThreeCursorsToAngle(string Cursor1, string Cursor2, string Cursor3, [, variable deg]) 
	//
	// Returns  the angle formed by the cursors 
	// Cursor1, Cursor2 & Cursor3 (*corner of angle at Cursor2*)
	// in rad or degrees.
	deg = ParamIsDefault(deg) ? 0 : 1
	variable angle
	variable C1Exists = strlen(CsrInfo($Cursor1))
	variable C2Exists = strlen(CsrInfo($Cursor2))
	variable C3Exists = strlen(CsrInfo($Cursor3))
	
	if(!C1Exists)
		print "Cursor ", Cursor1, " not in graph"
		return -1
	endif
	
	if(!C2Exists)
		print "Cursor ", Cursor2, " not in graph"
		return -1
	endif
	
	if(!C3Exists)
		print "Cursor ", Cursor3, " not in graph"
		return -1
	endif	
	
	variable x1 = hcsr($Cursor1); variable y1 = vcsr($Cursor1)
	variable x2 = hcsr($Cursor2); variable y2 = vcsr($Cursor2)
	variable x3 = hcsr($Cursor3); variable y3 = vcsr($Cursor3)

	variable l1 = cabs(cmplx(x3-x2, y3-y2))
	variable l2 = cabs(cmplx(x3-x1, y3-y1))
	variable l3 = cabs(cmplx(x2-x1, y2-y1))
	
	angle = acos((-l2^2+l1^2+l3^2)/(2*l1*l3))	
		
	return (deg == 0) ? angle : angle*180/pi
End


static Function MirrorCursorPositionToWaveValues(WAVE wRef)
	// Add a textbox with values from two graphs in the same cursor position
	string grfName = WinName(0,1,1)
	string textbuffer =  "TextBox/W="+grfName+"/C/N=ATH_CursorMirroGraphValues \"\\Z12Local: %g\\nMirror: %g\""
	string athTopImg = ATH_Graph#TopImageName()

	string axisX, axisY
	[axisX, axisY] = ATH_Graph#GetAxes(grfName=grfName)
	string dumpStr, val1Str, val2Str
	string axisXRangeStr = StringByKey("SETAXISCMD", AxisInfo("", axisX))
	SplitString/E="\s*([-]?[0-9]*[.]?[0-9]+)\s*(,)\s*([-]?[0-9]*[.]?[0-9]+)\s*" axisXRangeStr, val1Str, dumpStr, val2Str
	variable midOfImageX = 0.5 * (str2num(val1Str) + str2num(val2Str))
	string axisYRangeStr = StringByKey("SETAXISCMD", AxisInfo("", axisY))
	SplitString/E="\s*([-]?[0-9]*[.]?[0-9]+)\s*(,)\s*([-]?[0-9]*[.]?[0-9]+)\s*" axisYRangeStr,val1Str, dumpStr, val2Str
	variable midOfImageY = 0.5 * (str2num(val1Str) + str2num(val2Str))
		
	Cursor/I/C=(65535,0,0)/N=1/S=0/A=0/H=1 J $athTopImg midOfImageX,midOfImageY
	SetWindow $grfName hook(ATH_MirrorCursorHook) = ATH_Cursors#SyncCursorsInGraphsHook
	SetWindow $grfName userdata(ATH_textbuffer) = textbuffer
	SetWindow $grfName userdata(ATH_LinkedWaveToMirrorValues) = GetWavesDataFolder(wRef,2)
	return 0
End

static Function SyncCursorsInGraphsHook(STRUCT WMWinHookStruct &s)

	variable hookResult, layerN
	string mirrorWaveStr = GetUserData(s.winName, "", "ATH_LinkedWaveToMirrorValues")
	string textbuffer = GetUserData(s.winName, "", "ATH_textbuffer"), cmdStr
	switch(s.eventCode)
		case 7:
			if(!cmpstr(s.CursorName,"J")) // acts only on the J cursor
				WAVE mirrorW = $mirrorWaveStr
				WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName = s.winName)
				layerN = ATH_Graph#GetgLayer(s.winName)
				if(layerN==-1)
					sprintf cmdStr, textbuffer, wRef[s.pointnumber][s.ypointnumber], mirrorW[s.pointnumber][s.ypointnumber]
				else
					sprintf cmdStr, textbuffer, wRef[s.pointnumber][s.ypointnumber], mirrorW[s.pointnumber][s.ypointnumber][layerN]
				endif
				Execute/Q/Z cmdStr
			endif
			break
		case 11:
			if(s.specialKeyCode == 204) // if you press ESC
				SetWindow $s.winName hook(ATH_MirrorCursorHook) = $""
				Cursor/K/W=$s.winName J
				TextBox/K/N=ATH_CursorMirroGraphValues
				SetWindow $s.winName userdata(ATH_textbuffer) = ""
				SetWindow $s.winName userdata(ATH_LinkedWaveToMirrorValues) = ""
			endif
			break
	endswitch
	return hookResult
End
