#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma moduleName=ATH_Asylum

Function LabelAsylumStack(w)
    Wave/Z w
    
    if(!WaveExists(w))
        DoAlert 0, "Error: Please select a 3D PFM wave in the Data Browser first."
        return -1
    endif

    // 1. Pull the labels from the Asylum Wave Note
    String noteStr = note(w)
    String labels = StringByKey("Labels", noteStr, ":", "\r")
    
    // Fallback order: PFM-specific (if detected) -> ChannelNDataType -> DART...Label -> Hardcoded
    if(ItemsInList(labels, ";") < 2)
        // Detect PFM Mode and use the confirmed sequence (matched to Gwyddion)
        if(StringMatch(StringByKey("ImagingMode", noteStr, ":", "\r"), "PFM Mode"))
            variable nLayers = DimSize(w, 2)
            if(nLayers == 8)
                // Height(R), Amp1(T, R), Amp2(R), Phase1(T, R), Phase2(R), Freq(R)
                labels = "Height_R;Amp1_T;Amp1_R;Amp2_R;Phase1_T;Phase1_R;Phase2_R;Freq_R"
            elseif(nLayers == 6)
                // Height(R), Amp1(R), Amp2(R), Phase1(R), Phase2(R), Freq(R)
                labels = "Height_R;Amp1_R;Amp2_R;Phase1_R;Phase2_R;Freq_R"
            elseif(nLayers == 4)
                // Height(R), Amp1(R), Phase1(R), Freq(R)
                labels = "Height_R;Amp1_R;Phase1_R;Freq_R"
            endif
        endif
    endif

    if(ItemsInList(labels, ";") < 2)
        // Find the section after "Initial Parms: End" to avoid duplicate keys with generic values like "1"
        string subNote = noteStr
        variable endInit = strsearch(noteStr, "Initial Parms: End", 0)
        if(endInit >= 0)
            subNote = noteStr[endInit, inf]
        endif

        string channelLabels = ""
        variable chIdx = 1
        nLayers = DimSize(w, 2)
        do
            string chKey = "Channel" + num2str(chIdx) + "DataType"
            string chVal = TrimString(StringByKey(chKey, subNote, ":", "\r"))
            // Stop if empty or we reached the wave's actual layer count
            if(strlen(chVal) == 0 || chIdx > nLayers)
                break
            endif
            channelLabels += chVal + ";"
            chIdx += 1
        while(chIdx <= 100)
        
        if(ItemsInList(channelLabels) >= 1)
            labels = channelLabels
        else
            // Fallback to DART specific keys if found
            string dartKeys = "Amplitude1;Phase1;Amplitude2;Phase2;Frequency1;Frequency2;Height"
            string dartLabels = ""
            variable j
            for(j=0; j < ItemsInList(dartKeys); j+=1)
                string k = StringFromList(j, dartKeys)
                if(numtype(NumberByKey("DART" + k + "Label", noteStr, ":", "\r")) == 0)
                    dartLabels += k + ";"
                endif
            endfor
            if(ItemsInList(dartLabels) >= 2)
                labels = dartLabels
            else
                labels = "Height;Amp1;Phase1;Amp2;Phase2;Freq"
            endif
        endif
    endif

    // 2. Apply labels to the 3rd Dimension (Index 2)
    variable i
    for(i=0; i < DimSize(w, 2); i+=1)
        String currentLabel = StringFromList(i, labels, ";")
        if(strlen(currentLabel) == 0)
            currentLabel = "Layer" + num2str(i)
        endif
        SetDimLabel 2, i, $currentLabel, w
    endfor
    
    // 3. Update note with correct summary
    string map = ""
    for(i=0; i < DimSize(w, 2); i+=1)
        map += GetDimLabel(w, 2, i) + SelectString(i < DimSize(w, 2) - 1, "", ", ")
    endfor
    Note/K w, ReplaceStringByKey("LayerMap", note(w), map, ":", "\r")
    
    return 0
End

Function LoadAsylumIBW()
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
        ImageTransform flipCols w 
        string grfName = ATH_Display#NewImg(w)
        if(WaveDims(w) == 3 && strlen(grfName))
            // Resize window to be wider (600 pts wide, 500 pts tall) to fit the margin!
            MoveWindow/W=$grfName 50, 50, 650, 550
            // Enforce a fixed 120pt whitespace margin on the right
            ModifyGraph/W=$grfName margin(right)=120
            // Add ColorScale in the right window margin
            // /E=2 anchors to the WINDOW boundary (resize-invariant)
            // /A=RC /X=2 pins it to the right edge of the window, staying in the 120pt space
            ColorScale/W=$grfName/C/N=ath_cbar/E=2/A=RC/X=2/Y=0 width=15
            // Dynamic labels are reactive to slider changes!
            AddAsylumLabel(grfName)
        endif
        return 0
    endif
    
    return -1
End

static Function AddAsylumLabel(grfName)
    string grfName
    // Dynamic expression calls GetCurrentLayerLabel on every redraw.
    string dynamicText = "\\Z18\\K(0,0,0)\\{ATH_Asylum#GetCurrentLayerLabel(\"" + grfName + "\")}"
    Textbox/W=$grfName/N=ATH_Asylum_LayerLabel/F=0/A=LT/X=2/Y=2 dynamicText
End

Function/S GetCurrentLayerLabel(grfName)
    string grfName
    WAVE/Z w = ATH_Graph#TopImageToWaveRef(grfName=grfName)
    if(!WaveExists(w) || WaveDims(w) != 3)
        return ""
    endif
    
    variable plane = NumberByKey("plane", ImageInfo(grfName, PossiblyQuoteName(NameOfWave(w)), 0), "=")
    string labelStr = GetDimLabel(w, 2, plane)
    
    // Update the ColorScale units by setting wave data units (SetScale d)
    // This is much more robust than ColorScale title for multi-version compatibility
    string layerUnits = GetLayerUnits(labelStr)
    if(CmpStr(waveunits(w, -1), layerUnits) != 0)
        string setScaleCmd
        sprintf setScaleCmd, "SetScale d, 0, 0, \"%s\", %s", layerUnits, GetWavesDataFolder(w, 2)
        Execute/P/Q setScaleCmd
    endif
    
    // Only apply manual axis label for non-SI units (Phase) and Frequency
    // For 'm' units, we use an empty string to allow automatic SI tick labeling
    string csLabel = layerUnits
    variable tUnit = 0
    variable psExp = 0
    if(StringMatch(layerUnits, "m"))
        csLabel = ""
    elseif(StringMatch(layerUnits, "Hz"))
        csLabel = "kHz"
        tUnit = 1
        psExp = -3 // Show 706.3 instead of 706300 or 706.3 x 10^3
    elseif(StringMatch(layerUnits, "deg"))
        tUnit = 1
    endif
    ColorScale/W=$grfName/C/N=ath_cbar tickUnit=tUnit, prescaleExp=psExp, csLabel
    
    // Dynamic Z-Limits (Auto-scale color bar to current plane's data range)
    string wName = NameOfWave(w)
    string ctabName = "VioletOrangeYellow" // Default color table name
    variable revFlag = 0      // Default reverse flag
    
    if(strsearch(labelStr, "Phase", 0, 2) >= 0)
        // Fixed range for Phase as requested
        ModifyImage/W=$grfName $PossiblyQuoteName(wName) ctab={-90, 90, $ctabName, revFlag}
    else
        // Full range stats for all other layers (Height, Amp, Freq, etc.)
        // Use RMD (Multi-Dimensional) flag for 3D waves as per package standard
        // In rtGlobals=3, we must sometimes declare built-in variables locally
        variable V_flag, V_min, V_max 
        WaveStats/Q/M=1/RMD=[][][plane] w
        if(V_flag == 0) // Stats successful
            ModifyImage/W=$grfName $PossiblyQuoteName(wName) ctab={V_min, V_max, $ctabName, revFlag}
        endif
    endif

    return SelectString(strlen(labelStr) > 0, num2str(plane), labelStr)
End

static Function/S GetLayerUnits(label)
    string label
    if(strsearch(label, "Height", 0, 2) >= 0 || strsearch(label, "ZSensor", 0, 2) >= 0)
        return "m" // Use base units; Igor 10 handles SI prefixes (n, u, p) automatically
    elseif(strsearch(label, "Phase", 0, 2) >= 0)
        return "deg"
    elseif(strsearch(label, "Amp", 0, 2) >= 0 || strsearch(label, "Defl", 0, 2) >= 0)
        return "m"
    elseif(strsearch(label, "Freq", 0, 2) >= 0)
        return "Hz"
    endif
    return ""
End
