#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName=ATH_Asylum

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

// Initial idea George Fratian (Brown University). Code edited by in-house developers.

static constant kCBOFFSET = 30 // height slider in 3d waves

/// @function LabelAsylumStack
/// @brief Apply Asylum AFM dimension labels and metadata to an image stack.
/// @param wRef Input wave.
/// @returns Igor status code; zero indicates success and nonzero values report failure or cancellation.
static Function LabelAsylumStack(WAVE wRef)
    
    if(!WaveExists(wRef))
        DoAlert 0, "Error: Please select a 3D PFM wave in the Data Browser first."
        return -1
    endif

    // 1. Pull the labels from the Asylum Wave Note
    string noteStr = note(wRef)
    string labels = StringByKey("Labels", noteStr, ":", "\r")
    
    // Fallback order: PFM-specific (if detected) -> ChannelNDataType -> DART...Label -> Hardcoded
    if(ItemsInList(labels, ";") < 2)
        // Detect PFM Mode and use the confirmed sequence (matched to Gwyddion)
        if(StringMatch(StringByKey("ImagingMode", noteStr, ":", "\r"), "PFM Mode"))
            variable nLayers = DimSize(wRef, 2)
            if(nLayers == 8)
                // Height(R), Amp1(T, R), Amp2(R), Phase1(T, R), Phase2(R), Freq(R)
                labels = "Height_R (m);Amp1_T (m);Amp1_R (m);Amp2_R (m);Phase1_T (deg);Phase1_R (deg);Phase2_R (deg);Freq_R (Hz)"
            elseif(nLayers == 6)
                // Height(R), Amp1(R), Amp2(R), Phase1(R), Phase2(R), Freq(R)
                labels = "Height_R (m);Amp1_R (m);Amp2_R (m);Phase1_R (deg);Phase2_R (deg);Freq_R (Hz)"
            elseif(nLayers == 4)
                // Height(R), Amp1(R), Phase1(R), Freq(R)
                labels = "Height_R (m);Amp1_R (m);Phase1_R (deg);Freq_R (Hz)"
            endif
        endif
    endif
	string indices = ATH_String#ExpandRangeStr("0-"+num2str(nLayers-1))
	// Note that indices use ";" as well as waveNamesList here!
	noteStr = "---* Stacked waves *---\n" + \
	ATH_String#ThreadStr(indices, labels, joinstr=">", listSep0 = ";", listsep1 = ";") + \
	"*--------------------------*\n"
	Note/K wRef, noteStr
    return 0
End

/// @function LoadAsylumIBW
/// @brief Load an Asylum IBW file and display its image channels.
/// @returns Igor status code; zero indicates success and nonzero values report failure or cancellation.
static Function LoadAsylumIBW()
    // Define file filters for Asylum IBW
    string fileFilters = "Asylum IBW Files (*.ibw):.ibw;"
    fileFilters += "All Files:.*;"
    
    variable refNum
    Open/D/R/F=fileFilters/M="Select Asylum IBW file" refNum
    string filepath = S_fileName
    
    if(!strlen(filepath))
        return -1 // User cancelled
    endif
    
    // Load the wave. /W flag is for IBW
    LoadWave/Q/O/W filepath
    
    if(V_flag == 0)
        DoAlert 0, "Error: Failed to load IBW file."
        return -1
    endif
    
    // Get reference to the loaded wave (last one loaded)
    string wname = StringFromList(0, S_waveNames)
    WAVE/Z w = $wname
    
    if(WaveExists(w))
        LabelAsylumStack(w)
        // Asylum files in mathina usually appear upside down relative to Gwyddion.
        // We apply a mandatory Vertical Flip (matching the manual "Rotate from metadata" tool).
        // Use a loop with /P flag to ensure every layer in the stack is flipped.
        variable nL = DimSize(w, 2)
        variable iL
        if(nL > 0)
            for(iL=0; iL < nL; iL+=1)
                ImageTransform/P=(iL) flipCols w
            endfor
        else
            ImageTransform flipCols w
        endif
        
        string grfName = DisplayAsylum(w)
        SetWindow $grfname, hook(AsylumDisplayHook) = ATH_Asylum#AsylumDisplayHook // Set the hook
        ModifyGraph/W=$grfName margin(right)=120
		ColorScale/W=$grfName/C/N=ath_asylum_cbar/E=2/A=RC/X=2/Y=0 width=15

//		variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
//		ControlInfo kwControlBar
//		variable lCBOFFSET = V_Height
//		ControlBar/W=$grfname (lCBOFFSET + kCBOFFSET)*pntConv
//		Button scaleCrsB pos={10,4+lCBOFFSET}, size={60,20}, title="Scale", win=$grfname
//		Button scaleCrsB help = {"Amplitude * cos(phase*π/180)"},proc=ATH_Asylum#AsylumButtons,win=$grfname		
        return 0
    endif
    
    return -1
End

/// @function AsylumDisplayHook
/// @brief Keep an Asylum image graph square when its window is resized.
/// @param s Igor action structure describing the control or window event.
/// @returns Igor callback status; nonzero indicates that the event was handled.
static Function AsylumDisplayHook(STRUCT WMWinHookStruct &s)
	//
	variable hookResult = 0
	Wave/Z w = ATH_Graph#TopImageToWaveRef(grfName=s.winName)
	DFREF dfr = $(skATH_W3DImageSliderParentDFR + s.winName)
	NVAR/Z/SDFR=dfr gLayer	
	if(!WaveExists(w))
		return 0
	endif
	
	switch (s.eventCode)
		case 8:
			string waveListToTitle = StringFromList(gLayer,ATH_String#GetStackNamesFromNote(w),"\n"), unitsStr
			SplitString/E="\(([^)]+)\)" waveListToTitle, unitsStr
			ColorScale/W=$s.winName/C/N=ath_asylum_cbar "\\E\\u#2 " + unitsStr
			if(stringmatch(unitsStr, "deg"))
				ColorScale/W=$s.winName/C/N=ath_asylum_cbar axisRange={-90,90}
			else
				WaveStats/M=1/Q/RMD=[][][gLayer] w
				ColorScale/W=$s.winName/C/N=ath_asylum_cbar axisRange={V_min,V_max}		
			endif
			break
	endswitch
	return 0
End

/// @function DisplayAsylum
/// @brief Display an Asylum image wave with its stored color and scale settings.
/// @param w Asylum image wave to display.
/// @returns The name of the graph displaying the Asylum image.
static Function/S DisplayAsylum(WAVE w)
    string grfName = ATH_Display#NewImg(w)
    SetWindow $grfname, hook(AsylumDisplayHook) = ATH_Asylum#AsylumDisplayHook // Set the hook
	ModifyGraph/W=$grfName margin(right)=120
	return grfName
End

//Static Function AsylumButtons(STRUCT WMButtonAction &s) // Todo: change this behavior
//
//	if (s.eventCode != 2) // If not pressed return, otherwise chaos
//		return 0
//	endif
//
//	strswitch (s.ctrlName)
//		case "scaleCrsB":
//			break
//	endswitch
//	return 0
//End