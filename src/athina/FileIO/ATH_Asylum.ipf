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
        string grfName = ATH_Display#NewImg(w)
        if(WaveDims(w) == 3 && strlen(grfName))
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
    return SelectString(strlen(labelStr) > 0, num2str(plane), labelStr)
End
