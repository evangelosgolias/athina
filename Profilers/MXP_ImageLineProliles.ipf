#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9

#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late



/// Documentation

/// end of documentation

// Mon CW43 : Develop on Tuesday and Wednesday

Function MXP_GetLineProfile(Wave waveRef)
	// ImageLineProfile srcWave=sampleData, xWave=xTrace, yWave=yTrace
	// We will use Igor's Imagelineprofile here
	
	variable pmin, pmax, qmin, qmax
	
	Variable x1 = hcsr(A), x2 = hcsr(B), y1 = vcsr(A), y2 = vcsr(B)
	
	if (pcsr(A)<pcsr(B))	
		pmin = pcsr(A)
		pmax = pcsr(B)
	else
		pmin = pcsr(B)
		pmax = pcsr(A)
	endif
	
	if (qcsr(A)<qcsr(B))	
		qmin = qcsr(A)
		qmax = qcsr(B)
	else
		qmin = qcsr(B)
		qmax = qcsr(A)
	endif
	
	variable ptot = pmax - pmin, qtot = qmax - qmin
	
	variable xtot = abs(x2 - x1), ytot = abs(y2 - y1)
		
	variable linelen = sqrt(xtot^2+ytot^2) // len in x, y scale
	
	string lineProfileNameStr = NameofWave(waveRef) + "_egprof"
	
	variable ii, xstart, xend, ystart, yend, linegrad = inf	
		 
	linegrad = (y2 - y1)/(x2-x1) // Cartetian system rotated be -90 deg

	Variable pwidth
		if (linegrad < 0)
				xstart = max(x1, x2)
				xend = min(x1, x2)
				ystart =  min(y1, y2)
				yend = max(y1, y2) 
				Make/O/FREE/N=2 xTrace={xstart, xend}, yTrace = {ystart, yend}
		else
				xstart = min(x1, x2)
				xend = max(x1, x2)
				ystart =  min(y1, y2)
				yend = max(y1, y2)
				Make/O/FREE/N=2 xTrace={xstart, xend}, yTrace = {ystart, yend}
		endif
			
		Prompt pwidth, "Line profile widht (pixels)" 
		DoPrompt "Width ", pwidth
		if (V_flag == 1)
			return -1
		endif
		ImageLineProfile/SC srcWave=waveRef, xWave=xTrace, yWave=yTrace, width = pwidth	
	
	// Here add the case when you have a 3d wave and you can get the profile at any plane /P
	
	WAVE/Z W_ImageLineProfile, W_LineProfileDisplacement
	Duplicate/O W_ImageLineProfile, $lineProfileNameStr
	SetScale/I x, W_LineProfileDisplacement[0], W_LineProfileDisplacement[numpnts(W_LineProfileDisplacement) - 1], $lineProfileNameStr
	WAVEClear W_ImageLineProfile, W_LineProfileDisplacement
	// Add details of the line profile
	Note/K $lineProfileNameStr 
	string coordstart = "Start ["+num2str(pmin)+"]"+"["+num2str(qmin)+"] " + "x: " + num2str(xstart) + ", " + "y: " + num2str(ystart) 
	string coordend = "End ["+num2str(pmax)+"]"+"["+num2str(qmax)+"] " + "x: " + num2str(xend) + ", " + "y: " + num2str(yend)
	string gradient = "Gradient: " + num2str(linegrad)+", Line length: " + num2str(linelen) 
	Note $lineProfileNameStr, coordstart
	Note $lineProfileNameStr, coordend
	Note $lineProfileNameStr, gradient
	Note $lineProfileNameStr, "Profile width in pixels: " + num2str(pwidth) +" ("+ num2str(2*(pwidth+0.5)) +" points)"
	Note $lineProfileNameStr, "Profile extracted from " + NameOfWave(waveRef)
End

//Under development
Function dummy()
//	string winNameStr = WinName(0, 1, 1)
//	SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionLineProfiler // Set the hook
//	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
//	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
//	String/G waveStr = NameOfWave(w3dref)
SetWindow $"", hook(MyHook) = MXP_CursorHookFunctionLineProfiler 
End

Function MXP_CursorHookFunctionLineProfiler(STRUCT WMWinHookStruct &s)
	/// Window hook function
//	s.doSetCursor = 1
//	s.cursorCode = 3
    variable hookResult = 0
//    if(!cmpstr(s.cursorName,"Α"))
//    	print s.cursorName
//		s.doSetCursor = 1
//		s.cursorCode = 9
//	endif
	//SVAR wrStr = waveStr
	WAVE/Z w3dref
	variable x1 = hcsr(A)
	//variable x2 = hcsr(B)
	variable y1 = vcsr(A)
	//variable y2 = xcsr(B)
	Wave s3d = $"LEEM at 10p3eV FoV 1p25um Mirror off"
	variable dx = DimDelta(w3dref,0)
	variable dy = DimDelta(w3dref,1)
    switch(s.eventCode)
		case 2: // Kill the window
			hookresult = 1
			break
	    case 7: // cursor moved
	    	DrawAction delete
	    	SetDrawLayer ProgFront
	    	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	    	DrawLine x1, y1, s.pointNumber * dx, s.ypointNumber*dy
	    	Make/O/FREE/N=2 xTrace={x1, s.pointNumber * dx}, yTrace = {y1, s.ypointNumber * dy}
	    	ImageLineProfile/SC srcWave=w3dref, xWave=xTrace, yWave=yTrace, width = 0	

	    		//break
//	    	switch(s.eventMod)
//	    		case 1: // Drag it like this. Set A a cursor to start, drag and draw line
//	    		//print s.pointNumber, s.ypointNumber
//
//	    	endswitch
	    	hookResult = 1
	 		break
	 	//case 3:
//	 	case 4:
//	 		//print s.pointNumber, s.ypointNumber
//	 		print s.mouseLoc.h, s.mouseLoc.v
//	 		hookResult = 1
//	 		break
        case 5: // mouse up
        	print "mouseup"
       		hookResult = 1
			break
    endswitch
    return hookResult       // 0 if nothing done, else 1
End

Function PrintCooord(STRUCT WMWinHookStruct &s)
	print s.pointNumber, s.yPointNumber
End





------------
#include <Readback ModifyStr>
#include <Axis Utilities>

Menu "Graph", hideable
    "Draw Axis Line...",/Q, JP_DrawAxisLine("")
End

Function JP_DrawAxisLine(graphName)
    String graphName
 
    if( strlen(graphName) == 0 )
        graphName= WinName(0,1)
    endif
    if( strlen(graphName) == 0 )
        DoAlert 0, "No graph window"
        return 0
    endif

    String str_AxisList= AxisList(graphName)
    if( ItemsInList(str_AxisList) < 2 )
        doalert 0, "no axes!"
        return 0
    endif
    String str_Axis= StringFromList(0,str_AxisList)
    Prompt str_Axis, "Line Intersecting: ", popup, str_AxisList
 
    String str_rangeList="entire plot area;over extent of other axis;"
    String str_range="entire plot area"
    Prompt str_range, "Extent of line: ", popup, str_rangeList 
 
    Variable pos
    Prompt pos, "At this value: "
 
    String str_layers="ProgBack;UserBack;ProgAxes;UserAxes;ProgFront;UserFront;"
    String str_layer="ProgAxes"
    Prompt str_layer, "On this drawing layer: ", popup, str_layers 
 
    DoPrompt "Draw Line Across Plot Area", str_Axis, str_range, pos, str_layer  
    if( V_Flag )
        return 0            // user cancelled
    endif
 
    String info=AxisInfo(graphName,str_Axis)
    String axisType= StringByKey("AXTYPE",info)
    Variable isHorizontal= (CmpStr(axisType,"bottom") == 0) || (CmpStr(axisType,"top") == 0)
 
    Variable pRelStart=0, pRelEnd=1
    String otherAxesList, otherAxis, otherInfo
    strswitch(str_range)
        case "over extent of other axis":
            // get a list of perpendicular axes. If there are more than 1, ask the user which one to use.
            otherAxesList= HVAxisList(graphName,!isHorizontal)
            if( ItemsInList(otherAxesList) == 1 )
                otherAxis= StringFromList(0,otherAxesList)
            else
                // ask the user which one he wants
                Prompt otherAxis, "Same extent as this axis:", popup, otherAxesList 
                DoPrompt "Choose Perpendicular Axis for Extent", otherAxis  
                if( V_Flag )
                    return 0            // user cancelled
                endif
            endif
            otherInfo=AxisInfo(graphName,otherAxis)
            // parse axisEnab(x)={0.25,0.75}
            pRelStart= GetNumFromModifyStr(otherInfo,"axisEnab","{",0)
            pRelEnd= GetNumFromModifyStr(otherInfo,"axisEnab","{",1)
        break
    endswitch
 
    SetDrawLayer $str_layer
    if( isHorizontal )
        SetDrawEnv/W=$graphName xcoord=$str_Axis, ycoord=prel
        DrawLine/W=$graphName pos,pRelStart,pos,pRelEnd
    else
        SetDrawEnv/W=$graphName xcoord=prel, ycoord=$str_Axis
        DrawLine/W=$graphName pRelStart,pos,pRelEnd, pos
    endif
    return 1    // success
End
