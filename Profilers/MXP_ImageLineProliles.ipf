#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma rtFunctionErrors = 1 // Debug mode
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late



/// Documentation

/// end of documentation

Function MXP_GetIgorLineProfile(Wave waveRef)
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
SetWindow Graph0, hook(MyHook) = MXP_CursorHookFunctionLineProfiler // Set the hook
End

Function MXP_CursorHookFunctionLineProfiler(STRUCT WMWinHookStruct &s)
	/// Window hook function
	    
    variable hookResult = 0

	
    switch(s.eventCode)
		case 2: // Kill the window
			hookresult = 1
			break
	    case 7: // cursor moved
	    	switch(s.eventMod)
	    		case 1: // Drag it like this. Set A a cursor to start, drag and draw line
	    		print "D"
	    		break
	    	endswitch
	 		break
        case 5: // mouse up
			break
    endswitch
    return hookResult       // 0 if nothing done, else 1
End

Function PrintCooord(STRUCT WMWinHookStruct &s)
	print s.pointNumber, s.yPointNumber
End