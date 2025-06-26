#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3     // Use modern global access method and strict wave access.
#pragma version=7.01        // will ship with Igor 701
#pragma IgorVersion=7       // color table waves require Igor 7+
 
Menu "Image", dynamic
    WMColorTableFromMenu("Color Table from Graph..."), /Q, WMColorTableFromGraph()
End
 
Menu "GraphMarquee", dynamic
    WMColorTableFromMenu("Color Table from Selection..."), /Q, WMColorTableFromGraph()
End
 
Function/S WMColorTableFromMenu(String enabledItem)
    
    String item=""  // disappears
    String graphName= WinName(0,1)
    String images= ImageNameList(graphName, ";")
    if( ItemsInList(images) == 1 )  // works with graphs having only 1 image plot
        String imageName= StringFromList(0,images)
        WAVE/Z image= ImageNameToWaveRef(graphName, imageName)
        Variable layers= DimSize(image,2)
        if( layers >= 3 )   // must be RGB or RGBA image.
            item= enabledItem   // "Color Table from Selection", etc.
        endif
    endif
    return item
End
 
Proc WMColorTableFromGraph(outputName)
    String outputName=StrVarOrDefault("root:Packages:WMColorTableFromGraph:ctableName", "ColorTable")   // default, missing parameter dialog gives user chance to change it
    
    outputName= CleanupName(outputName,1)
    
    NewDataFolder/O root:Packages
    NewDataFolder/O root:Packages:WMColorTableFromGraph
    String/G root:Packages:WMColorTableFromGraph:ctableName = outputName
    
    Variable created = WMColorTableGraphOrMarquee(outputName)
    if( created )
        WMDemoColorTableWave($outputName)
    endif
End
 
// Samples the first image in the top graph along the image's or marquee's
// longest dimension, in the middle of the shortest dimension.
//
// Note that dimensions may not correlate with marquee lengths if h & v scales differ.
// Scakes will not differ if NewImage is used to initially display the image
// and if the graph is not resized afterwards.
//
// Best is to use ModifyGraph width={perUnit,1,top},height={perUnit,1,left} to avoid confusion.
Function WMColorTableGraphOrMarquee(String outputName)
 
    outputName= CleanupName(outputName,1)
    if( strlen(outputName) == 0 )
        DoAlert 0, "Expected outputName!"
        return 0
    endif
    
    String graphName= WinName(0,1)
    if( strlen(graphName) == 0 )
        DoAlert 0, "Expected graph!"
        return 0
    endif
    String images= ImageNameList(graphName, ";")
    if( strlen(images) == 0 )
        DoAlert 0, "Expected image in "+graphName+"!"
        return 0
    endif
    String imageName= StringFromList(0,images)
    WAVE image= ImageNameToWaveRef(graphName, imageName)
    Variable layers= DimSize(image,2)
    if( layers < 3 )
        DoAlert 0, "Expected "+imageName+" to be an RGB image!"
        return 0
    endif
    
    Variable firstRow, lastRow, firstCol, lastCol
    Variable haveMarquee= WMGetMarqueeImageBounds(graphName, imageName, firstRow, lastRow, firstCol, lastCol)
    
    Variable cRows= lastRow-firstRow+1
    Variable cCols= lastCol-firstCol+1
    if( layers > 4 )
        layers= 4
    endif
    Variable center
    if( cRows > cCols )
        center= floor((firstCol+lastCol)/2)
        Make/O/N=(cRows, layers) $outputName/WAVE=ctable
        ctable= image[p+firstRow][center][q]
    else
        center= floor((lastRow+firstRow)/2)
        Make/O/N=(cCols, layers) $outputName/WAVE=ctable
        ctable= image[center][p+firstCol][q]
    endif
    ctable *= 257   // scale to 0-65535
    Redimension/U/W ctable  // convert to 16-bit int wave
    
    // set dimension labels
    SetDimLabel 1, 0, red, ctable
    SetDimLabel 1, 1, green, ctable
    SetDimLabel 1, 2, blue, ctable
 
    // remove any unnecessary alpha column
    if( layers == 4 )
        ImageStats/M=1/G={0, DimSize(ctable,0)-1, 3, 3} ctable
        if( V_min == V_max )
            Redimension/N=(-1,3) ctable
        else
            SetDimLabel 1, 3, alpha, ctable
        endif
    endif
    
    return WaveExists(ctable)   // in case of error
End
 
Function WMGetMarqueeImageBounds(graphName, imageName, firstRow, lastRow, firstCol, lastCol)
    String graphName, imageName
    Variable &firstRow, &lastRow, &firstCol, &lastCol
 
    WAVE image= ImageNameToWaveRef(graphName, imageName)
    Variable rows= DimSize(image,0)
    Variable cols= DimSize(image,1)
    firstRow= 0
    lastRow= rows-1
    firstCol=0
    lastCol= cols-1
    
    // Use entire image
    String info= ImageInfo(graphName, imageName, 0)
    String hAxis= StringByKey("XAXIS", info)
    String vAxis= StringByKey("YAXIS", info)
    GetMarquee /W=$graphName/Z $hAxis, $vAxis
    Variable haveMarquee= V_Flag
    if( haveMarquee ) // if marquee, use subset of image
        // convert horizontal (X) coordinates to rows
        // convert vertical (Y) coordinates to cols
        Variable swap
        
        // if swapXY, exchange V_left with V_top, and V_right with V_bottom
        String hAxisInfo= AxisInfo(graphName, hAxis)
        String hAxisType= StringByKey("AXTYPE", hAxisInfo)
        Variable axesSwapped= CmpStr(hAxisType, "left") == 0 || CmpStr(hAxisType, "right") == 0
        if( axesSwapped )
            swap= V_left
            V_left= V_top
            V_top= swap
            
            swap= V_right
            V_right= V_bottom
            V_bottom= swap
        endif
        
        firstRow= (V_left-DimOffset(image,0))/DimDelta(image,0)
        lastRow= (V_right-DimOffset(image,0))/DimDelta(image,0)
        if( firstRow > lastRow )
            swap= firstRow
            firstRow= lastRow
            lastRow= swap
        endif
        if( firstRow < 0 )
            firstRow= 0
        endif
        if( lastRow > rows-1 )
            lastRow= rows-1
        endif
        firstRow= floor(firstRow)
        lastRow= ceil(lastRow)
 
        firstCol= (V_top-DimOffset(image,1))/DimDelta(image,1)
        lastCol= (V_bottom-DimOffset(image,1))/DimDelta(image,1)
        if( firstCol > lastCol )
            swap= firstCol
            firstCol= lastCol
            lastCol= swap
        endif
        if( firstCol < 0 )
            firstCol= 0
        endif
        if( lastCol > cols-1 )
            lastCol= cols-1
        endif
        firstCol= floor(firstCol)
        lastCol= ceil(lastCol)
    endif
    return haveMarquee
End
 
Function WMDemoColorTableWave(WAVE ctable)
 
    Variable rows= DimSize(ctable,0)
    String name= NameOfWave(ctable)
    String graphName= CleanupName("CTabDemo"+name,0)[0,30]
    String demoWaveName= CleanupName(name+"Img",0)[0,30]
    Make/O/N=(rows, 30) $demoWaveName= p // simple ramp
    WAVE img= $demoWaveName
    DoWindow/F $graphName
    if( V_Flag == 0 )
        Newimage/N=$graphName img
        ModifyImage/W=$graphName ''#0, ctab={*,*,ctable} // apply color table wave
    endif
    ModifyGraph/W=$graphName nticks=0, width=300, height=40, axThick=1
End