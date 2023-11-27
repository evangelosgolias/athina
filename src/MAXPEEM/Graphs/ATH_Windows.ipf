#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Windows
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

static StrConstant WMkSliderDataFolderBase = "root:Packages:WM3DImageSlider:"

static Function/S GetListOfNamedWindowHookFunctions([string winNameStr, string hookFuncNameStr])
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

static Function SetNamedHookFunctionToWindow(string hookFuncNameStr, string hookFuncStr, [string winNameStr])
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

static Function GetCurrentPlaneWM3DAxis(string windowNameStr)
	// Returns the /P=num plane displayed in windowNameStr
	if(!strlen(windowNameStr))
		windowNameStr = WinName(0, 1, 1) // top window
	endif
	ControlInfo/W=$windowNameStr WM3DAxis
	if( V_Flag != 0 )
		DFREF WMdfr = $(WMkSliderDataFolderBase + windowNameStr)
		NVAR/SDFR=WMdfr gLayer
		return gLayer
	else
		return -1
	endif
End

static Function IsWM3DAxisActiveQ(string windowNameStr)
	/// Check whether WM3DAxis is active
	// 0 - not active
	// 1 - active
		if(!strlen(windowNameStr))
		windowNameStr = WinName(0, 1, 1) // top window
	endif
	ControlInfo/W=$windowNameStr WM3DAxis
	return V_flag
End

// Dev -- need testing

static Function/S WindowNameOfDisplayedImageWaveRef(WAVE wRef)
	// Returns a semicolon separated string of the name 
	// of the graphsnames wRef is displayed. Return "" if
	// wRef is not displayed. Graphs are search by default
	// Check WinList documentation for more details.
	
	string displayedStr = "", windowNameStr, imgNameTopGraphStr
	string windowsListStr = WinList("*", ";","WIN:1")   
	string waveNameStr = NameOfWave(wRef)

	variable numWindows = ItemsInList(windowsListStr), i
	for(i = 0; i < numWindows; i++)
		windowNameStr = StringFromList(i, windowsListStr)
		imgNameTopGraphStr = StringFromList(0, ImageNameList(windowNameStr, ";"),";") // Consider top image
        if (strlen(imgNameTopGraphStr))
	        WAVE/Z wRefLoop = $imgNameTopGraphStr
	        if(WaveRefsEqual(wRef, wRefLoop))
	        	displayedStr += windowNameStr + ";"
	        endif 
        endif	
	endfor
	return displayedStr
End

static Function KillWindowsInListString(string windowsListStr)
	// Kill all windows in winListstr (;)
	variable numWindows = ItemsInList(windowsListStr), i
	for(i = 0; i < numWindows; i++)
		KillWindow/Z $StringFromList(i, windowsListStr)
	endfor
	return 0
End