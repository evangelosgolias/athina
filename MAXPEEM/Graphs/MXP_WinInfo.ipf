#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function/S MXP_GetListOfNamedWindowHookFunctions([string winNameStr, string hookFuncNameStr])
	// Copy from https://www.wavemetrics.com/code-snippet/get-list-named-window-hook-functions
    variable all
    
    string wrecStr, lStr=""
    variable sp=0, cp, ep
    
    if (ParamIsDefault(winNameStr))
        winNameStr = WinName(0,1)
        if (strlen(winNameStr)==0)
            return ""
        endif
    endif
    wrecstr = WinRecreation(winNameStr,0) 
//  notebook winrec, text = wrecStr     // uncomment and have notebook winrec fo winrecreation string
    do
        cp = strsearch(wrecStr,"hook(",sp)
        if (cp == -1)
            break
        endif
        ep = strsearch(wrecStr,"\r",cp)
        lStr += wrecStr[cp,ep-1] + ";"
        sp = ep+1
    while(1)
    
    if (ParamIsDefault(hookFuncNameStr))
        hookFuncNameStr = lStr
    else
        hookFuncNameStr = "hook(" + hookFuncNameStr + ")=*"
        hookFuncNameStr = ListMatch(lStr, hookFuncNameStr)
    endif   
    return hookFuncNameStr 
End

Function MXP_SetNamedHookFunctionToWindow(string hookFuncNameStr, string hookFuncStr, [string winNameStr])
	// Set the the named hook function hookFuncStr as hook(hookFuncNameStr) 
	// at winNameStr (TG if default)
	if (ParamIsDefault(winNameStr))
        winNameStr = WinName(0,1)
        if (strlen(winNameStr)==0)
            return 1
        endif
    endif

    SetWindow $winNameStr, hook($hookFuncNameStr) = $hookFuncStr
	return 0
End
