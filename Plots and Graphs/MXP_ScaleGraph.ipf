#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3     // Use modern global access method and strict wave access.
#pragma ModuleName=PanelSizes

// ------------------------------------------------------- //
// Developed by Evangelos Golias.
// Contact: evangelos.golias@gmail.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, IN CONNECTION WITH THE USE OF SOFTWARE.
// ------------------------------------------------------- //

// Code copied from: https://www.wavemetrics.com/code-snippet/panel-size-menus

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

// Copy and edited from "Autoscale Images.ipf"

Function WM_AutoSizeImage(variable forceSize)

	String images= ImageNameList("", ";")
	Variable numImages= ItemsInList(images)
	if( numImages < 1 )
		DoAlert 0, "Graph "+WinName(0,1)+" contains no images to autosize!"
		return -1
	endif
	WM_DoAutoSizeImage(forceSize)
End

Function WM_DoAutoSizeImage(variable forceSize)
	
	if( (forceSize != 0) )
		if( (forceSize<0.1) %| (forceSize>20) )
			Abort "Unlikely value for forceSize; usually 0 or between .1 and 20"
			return 0
		endif
	endif
	string imagename= ImageNameList("", ";")
	variable p1= strsearch(imagename, ";", 0)
	if( p1 <= 0 )
		Abort "Graph contains no images"
		return 0
	endif

	// Remember input for next time
	string dfSav= GetDataFolder(1);
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S WMAutoSizeImages
	SetDataFolder dfSav
	
	imagename= imagename[0,p1-1]
	WAVE w= ImageNameToWaveRef("",imagename)
	variable height= DimSize(w,1)
	variable width= DimSize(w,0)
	do
		if(forceSize )
			height *= forceSize;
			width *= forceSize;
			break
		endif
		variable maxdim= max(height,width)
		NewDataFolder/S tmpAutoSizeImage
		Make/O sizes={20,50,100,200,600,1000,2000,10000,50000,100000}		// temp waves used as lookup tables
		Make/O scales={16,8,4,2,1,0.5,0.25,0.125,0.0626,0.03125}
		variable nsizes= numpnts(sizes),scale= 0,i= 0
		do
			if( maxdim < sizes[i] )
				scale= scales[i]
				break;
			endif
			i+=1
		while(i<nsizes)
		KillDataFolder :			// zap our two temp waves that were used as lookup tables
		if( scale == 0 )
			Abort "Image is bigger than planned for"
			return 0
		endif
		width *= scale;
		height *= scale;
	while(0)

	width *= 72/ScreenResolution					// make image pixels match screen pixels
	height *= 72/ScreenResolution					// make image pixels match screen pixels
	ModifyGraph width=width,height=height
	DoUpdate
	if( forceSize==0 )
		ModifyGraph width=0,height=0
	endif
end