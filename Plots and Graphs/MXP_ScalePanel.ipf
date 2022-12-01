#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3     // Use modern global access method and strict wave access.
#pragma ModuleName=PanelSizes
#pragma version=7   // circa Igor 7
// Code copied from: https://www.wavemetrics.com/code-snippet/panel-size-menus

#if IgorVersion() >= 7
Menu "Panel", dynamic
    "-"
    Submenu "Size"
        "Make Panel Bigger",/Q, PanelSizes#MakeTopPanelBigger()
        "Make Panel Smaller",/Q, PanelSizes#MakeTopPanelSmaller()
        "Make Panel Normal Size",/Q, PanelSizes#MakeTopPanelNormal()
        "\\M1:(:Panel Resolution = "+num2str(PanelResolution(WinName(0,64)))
        "\\M1:(:Screen Resolution = "+num2str(ScreenResolution)
    End
    "-"
End
#endif

static Function MakeTopPanelBigger()

    String panel= WinName(0,64)
    if( strlen(panel) )
        Variable currentRes= PanelResolution(panel)
        Variable newRes= BiggerResolution(currentRes)
        String newCode= RewritePanelCodeResolution(panel, newRes)
        KillWindow/Z $panel
        Execute/Q/Z newCode
        DoIgorMenu "Control", "Retrieve Window"
    endif   
End

static Function MakeTopPanelSmaller()

    String panel= WinName(0,64)
    if( strlen(panel) )
        Variable currentRes= PanelResolution(panel)
        Variable newRes= SmallerResolution(currentRes)
        String newCode= RewritePanelCodeResolution(panel, newRes)
        KillWindow/Z $panel
        Execute/Q/Z newCode
    endif   
End

static Function MakeTopPanelNormal()

    String panel= WinName(0,64)
    if( strlen(panel) )
        Variable newRes= 1 // This is the default setting in effect when Igor starts.
        String newCode= RewritePanelCodeResolution(panel, newRes)
        KillWindow/Z $panel
        Execute/Q/Z newCode
        DoIgorMenu "Control", "Retrieve Window"
    endif   
End


static StrConstant ksResolutions= "72;96;120;144;192;240;288;384;480;"

static Function BiggerResolution(currentRes)
    Variable currentRes
    
    Variable nextRes= ActualResolution(currentRes)
    String strRes= num2istr(nextRes)
    Variable whichOne = WhichListItem(strRes, ksResolutions)
    Variable numItems= ItemsInList(ksResolutions)
    if( whichOne >= 0 && whichOne < numItems-1)
        nextRes = str2num(StringFromList(whichOne+1, ksResolutions))
    else
        nextRes = str2num(StringFromList(numItems-1, ksResolutions))
    endif
    return nextRes
End

static Function SmallerResolution(currentRes)
    Variable currentRes
    
    Variable nextRes= ActualResolution(currentRes)
    String strRes= num2istr(nextRes)
    Variable whichOne = WhichListItem(strRes, ksResolutions)
    if( whichOne > 0 )
        nextRes = str2num(StringFromList(whichOne-1, ksResolutions))
    else
        nextRes = 72
    endif
    return nextRes
End

static Function ActualResolution(currentRes)
    Variable currentRes

    Variable actualRes= currentRes
    Variable screenRes= ScreenResolution // On Macintosh this was always 72 before Retina displays. On Windows it is usually 96 (small fonts) or 120 (large fonts).
    if( actualRes == 0 ) // points
        actualRes = screenRes
    elseif( actualRes == 1 )
        if( screenRes == 96 )
            actualRes = 72
        else
            actualRes = screenRes
        endif
    endif
    return actualRes
End


static Function/S RewritePanelCodeResolution(panel, newRes)
    String panel
    Variable newRes
    
    String code= WinRecreation(panel, 4)
    Wave/T tw = ListToTextWave(code, "\r")

    // insert three lines of code before line 2 (line 0 is Macro... and line 1 is PauseUpdate...)
    InsertPoints 2,3, tw
    tw[2]= "    SetIgorOption PanelResolution=?"
    tw[3]= "    Variable oldResolution = V_Flag"
    tw[4]= "    SetIgorOption PanelResolution="+num2istr(newRes)


    Variable lines= numpnts(tw)
    
    // insert SetIgorOption PanelResolution=oldResolution
    // before EndMacro (line lines-1)
    InsertPoints lines-1, 1, tw
    tw[lines-1]= "  SetIgorOption PanelResolution=oldResolution"
    
    // convert back to code
    String list
    wfprintf list, "%s\r", tw
    
    return list
End