#pragma rtGlobals=3
#pragma DefaultTab={3,20,4}
#pragma version=1.50
#pragma ModuleName=ScrollToZoom

/// The code was posted from Tony Withers (tony) at Igor and it is included here as is.
/// For details you can check the following post at the Igor Exchange forum
/// https://www.wavemetrics.com/code-snippet/mousewheel-graph-window-zoom


#define global

// key codes
// 2: shift; 4: option/alt; 8: command/ctrl
// On Windows, alt key is reserved for graph drag.
static constant kZoomKey=8
static constant kFasterKey=2
static constant kZoomSpeed=70
static constant kReverse=0 // reverse the direction of expansion

#ifdef global

static function AfterWindowCreatedHook(string win, variable type)
    if (type == 1)
        SetWindow $win hook(hScrollToZoom)=ScrollToZoom#hookScrollToZoom
    endif
    return 0
end

#else

menu "Graph", dynamic
    ScrollToZoom#zoomMenu(), /Q, ScrollToZoom#toggleZoom()
end

static function /S zoomMenu()
    GetWindow kwTopWin hook(hScrollToZoom)
    return SelectString(strlen(s_value)>0, "", "!" + num2char(18)) + "Scroll-Zoom"
end

#endif

static function toggleZoom()
    GetWindow kwTopWin hook(hScrollToZoom)
    SetWindow kwTopWin hook(hScrollToZoom) = $SelectString(strlen(s_value)>0, "ScrollToZoom#hookScrollToZoom", "")
end

static function hookScrollToZoom(STRUCT WMWinHookStruct &s)
    if (s.eventCode == 22 && s.eventMod&kZoomKey) // mousewheel/touchpad + zoom key

        string strAxes = AxisList(s.WinName), axis = "", type = ""
        int i, numAxes, isHorizontal, isLog
        Make /D/free/N=3 wAx // free wave to hold axis minimum, maximum, axis value for mouse location
        numAxes = ItemsInList(strAxes)
        int rev = 1 - 2*kReverse
        variable expansion = 1 - rev*s.wheelDy * kZoomSpeed/5000
        if (s.eventMod & kFasterKey)
            if (kFasterKey==2 && s.wheelDy==0)
                // this works when shift key also transforms wheel.dY to wheel.dX
                s.wheelDy = s.wheelDx
            endif
            expansion = 1 - rev*s.wheelDy * kZoomSpeed/500
        endif
               
        for (i=0;i<numAxes;i++)
            axis = StringFromList(i, strAxes)
            type = StringByKey("AXTYPE", AxisInfo(s.WinName, axis))
            isHorizontal = (cmpstr(type, "bottom")==0 || cmpstr(type,"top")==0 || cmpstr(type[0,2],"/B=")==0 || cmpstr(type[0,2],"/T=")==0)
            isLog = (NumberByKey("log(x)", AxisInfo(s.WinName, axis),"="))
           
            GetAxis /W=$s.WinName/Q $axis
            wAx = {v_min, v_max, AxisValFromPixel(s.WinName, axis, isHorizontal ? s.mouseLoc.h : s.mouseLoc.v)}
            if (WaveMax(wAx) == wAx[2] || WaveMin(wAx) == wAx[2])
                continue
            endif
                       
            if (isLog)
                wAx = log(wAx)
                wAx = wAx[2] - (wAx[2] - wAx[p]) * expansion
                wAx = alog(wAx)
            else
                wAx = wAx[2] - (wAx[2] - wAx[p]) * expansion
            endif
                   
            WaveStats /Q/M=1 wAx
            if ( (V_numNaNs+V_numInfs) || wAx[1]==wAx[0] )
                continue
            endif
           
            if (wAx[1] > wAx[0])
                SetAxis /W=$s.WinName $axis, wAx[0], wAx[1]
            else
                SetAxis /R/W=$s.WinName $axis, wAx[0], wAx[1]
            endif
        endfor 
    endif
    return 0
end