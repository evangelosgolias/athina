#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma rtFunctionErrors = 1 // Debug mode
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late



/// Documentation

/// end of documentation

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