#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function/S MXP_GetListOfNamedWindowHookFunctions([name,hook])
	// Copy from https://www.wavemetrics.com/code-snippet/get-list-named-window-hook-functions
    string name, hook
    variable all
    
    string wrecStr, lStr=""
    variable sp=0, cp, ep
    
    if (ParamIsDefault(name))
        name = WinName(0,1)
        if (strlen(name)==0)
            return ""
        endif
    endif
    wrecstr = WinRecreation(name,0) 
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
    
    if (ParamIsDefault(hook))
        hook = lStr
    else
        hook = "hook("+hook+")=*"
        hook = ListMatch(lStr,hook)
    endif   
    return hook 
End