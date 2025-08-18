#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Graph
#pragma version = 1.1

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

static Function DuplicateWaveAndDisplayOfTopImage([string grfName])
	/// Duplicate the graph of an image (2d, 3d wave) along with the wave at its
	/// data folder (not cwd). 
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)	
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	DFREF cdfr = GetDataFolderDFR()
    string duplicateWinNameStr = UniqueName(grfName + "_", 6, 1, grfName)
    string waveNameStr = CreateDataObjectName(cdfr, NameOfWave(wRef) + "_", 1, 0, 5)
    Duplicate wRef, cdfr:$waveNameStr // Copy the wave to the working dir
    ControlInfo/W=$grfName ATH_W3DSlider
    if(!V_flag && WaveDims(wRef) == 3) // If there is no 3d axis, there should be a reason.
    	NewImage/G=1/K=1 cdfr:$waveNameStr
    else    	
    	ATH_Display#NewImg(cdfr:$waveNameStr)
    endif
    DoWindow/C $duplicateWinNameStr
    string addTocopyNoteStr = "Duplicate of " + GetWavesDataFolder(wRef, 2)
    Note wRef, addTocopyNoteStr
	return 0
End

//Function DuplicateTopImage([string grfName])
//	//
//	// Duplicate the top graph using the same source
//	// while copying the style of the parent window.
//	// N.B Only style commmands are used for the duplicate
//	// window, no metadata or hooks.
//	//
//	
//	// TODO FIX: When duplicating with and /EXT window on you
//	// get a string of commands for the /EXT window, which is not there
//	// so there are errors. Try to filter out these commands.
//	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
//	WAVE wRef = ATH_Graph#TopImageToWaveRef()
//	string recCmd = WinRecreation(grfName, 0)
//	ATH_Display#NewImg(wRef)
//	string matchStr = ""
//	matchStr += ListMatch(recCmd, "*ModifyImage*", "\r")
//	matchStr += ListMatch(recCmd, "*ModifyGraph*", "\r")	
//	matchStr += ListMatch(recCmd, "*SetAxis*", "\r")	
//	matchStr = ReplaceString("\r\t", matchStr, ";")
//	Execute/P/Q/Z matchStr
//End

static Function TextAnnotationOnTopGraph(string text, [variable fSize, string color])
	/// Add text on the top graph. Optionally you can set fSize and text color.
	/// Defaults are fSize = 12 and color = black.

	fSize = ParamIsDefault(fSize) ? 12: fSize
	string fontSizeStr = "\Z" + num2str(fSize)
	if(!ParamIsDefault(color))
		string colorCode
		strswitch(color)
			case "red":
				colorCode = "\K(65535,16385,16385)"
				break
			case "green":
				colorCode = "\K(2,39321,1)"
				break
			case "blue":
				colorCode = "\K(0,0,65535)"
				break
			default:
				colorCode = "\K(0,0,0)"
		endswitch
	else 
		colorCode = "\k(0,0,0)"
	endif
	// Block using winNameStr
	//string textNameStr = UniqueName("text", 14, 0, winNameStr)
	//string winNameStr = WinName(0, 1, 1) // Top graph
	//string cmdStr = "TextBox/W=" + PossiblyQuoteName(winNameStr)+"/C/N=" + textNameStr +" /F=0/A=MC" +\
	// 				" \"" + colorCode + fontSizeStr + text + "\""
	string textNameStr = UniqueName("text", 14, 0)
	string cmdStr = "TextBox/C/N=" + textNameStr +" /F=0/A=MC" +\
	 				" \"" + colorCode + fontSizeStr + text + "\"" 				
	Execute/P/Z cmdStr
	return 0
End

static Function [variable red, variable green, variable blue] GetColor(variable colorIndex)
	/// Give a RGB triplet for 16 distinct colors.
	/// https://www.wavemetrics.com/forum/general/different-colors-different-waves
	/// Use as Modifygraph/W=WinName rgb(wavename) = (red, green, blue)

    colorIndex = mod(colorIndex, 16)          // Wrap around if necessary
    switch(colorIndex)
        case 0:
            red = 65535; green = 16385; blue = 16385;           // Red
            break           
        case 1:
            red = 2; green = 39321; blue = 1;                       // Green
            break          
        case 2:
            red = 0; green = 0; blue = 65535;                       // Blue
            break
        case 3:
            red = 39321; green = 1; blue = 31457;                   // Purple
            break
        case 4:
            red = 39321; green = 39321; blue = 39321;           // Gray
            break
        case 5:
            red = 65535; green = 32768; blue = 32768;           // Salmon
            break
        case 6:
            red = 0; green = 65535; blue = 0;                       // Lime
            break
        case 7:
            red = 16385; green = 65535; blue = 65535;           // Turquoise
            break
        case 8:
            red = 65535; green = 32768; blue = 58981;           // Light purple
            break
        case 9:
            red = 39321; green = 26208; blue = 1;                   // Brown
            break
        case 10:
            red = 52428; green = 34958; blue = 1;                   // Light brown
            break
        case 11:
            red = 65535; green = 32764; blue = 16385;           // Orange
            break
        case 12:
            red = 1; green = 52428; blue = 26586;                   // Teal
            break
        case 13:
            red = 1; green = 3; blue = 39321;                   // Dark blue
            break
        case 14:
            red = 65535; green = 49151; blue = 55704;           // Pink
            break
        case 15:
            red = 0; green = 0; blue = 0;                       // Black
            break      
     endswitch

    
     return [red, green, blue]
End

static Function GetgLayer(string grfName)
	// Returns the /P=num plane displayed in windowNameStr
	if(!strlen(grfName))
		grfName = WinName(0, 1, 1) // top window
	endif
	ControlInfo/W=$grfName ATH_W3DSlider
	if( V_Flag != 0 )
		DFREF dfr = $(skATH_W3DImageSliderParentDFR + grfName)
		NVAR/SDFR=dfr gLayer
		return gLayer
	else
		return -1 // There is no active slider
	endif
End

static Function [string axisX, string axisY] GetAxes([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	GetAxis/Q/W=$grfName top
	if(V_flag) // V_flag == 1, top is not active
		axisX = "bottom"
	else
		axisX = "top"
	endif
	GetAxis/Q/W=$grfName left
	if(V_flag) // V_flag == 1, left is not active
		axisY = "right"
	else
		axisY = "left"
	endif
	return [axisX, axisY]
End

static Function [string axisX, variable minVX, variable maxVX, string axisY,
				 variable minVY, variable maxVY] GetAxesRange([string grfName])
	//
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	[axisX, axisY] = ATH_Graph#GetAxes(grfName = grfName)
	GetAxis/Q/W=$grfName $axisX
	if(!V_flag) // V_flag == 1, top is not active
		minVX = V_min
		maxVX = V_max
	else
		return ["", 0, 0, "", 0, 0] // Error
	endif
	GetAxis/Q/W=$grfName $axisY
	if(!V_flag) // V_flag == 1, left is not active
		minVY = V_min
		maxVY = V_max
	else
		return ["", 0, 0, "", 0, 0] // Error
	endif
	return [axisX, minVX, maxVX, axisY, minVY, maxVY]
End

static Function/S GetGraphCtabStr([string grfName])
	grfName = SelectString(ParamIsDefault(grfName), grfName, "")
	return StringByKey("RECREATION",ImageInfo(grfName, StringFromList(0, ImageNameList(grfName,";")), 0))
End

static Function SetGraphCtabStr(string ctabStr, [string grfName])
	grfName = SelectString(ParamIsDefault(grfName), grfName, "")	
	string cmdStr = "ModifyImage "
	string waveNameStr = StringFromList(0, ImageNameList(grfName, ";"))
	cmdStr += waveNameStr + " "
	cmdStr += ctabStr
	Execute/P/Q cmdStr
End


static Function [variable relx, variable rely] AxisValToRel2D(WAVE w, variable xv, variable yv)
	// Convert for axis to relative coordinates [0, 1]
	if(!(WaveDims(w)==2 || WaveDims(w)==3))
		return [-1, -1]
	endif
	variable px = ScaleToIndex(w, xv, 0)
	variable py = ScaleToIndex(w, yv, 1)
	variable npx = DimSize(w, 0)
	variable npy = DimSize(w, 1)	
	relx = px/npx ; rely = py/npy
	return [relx, rely]
End

static Function [variable px, variable py] RelToAxisVal2D(WAVE w, variable xr, variable yr)
	// Convert from relative to axis coordinates
	// if xr or yr are outside of [0,1] NaN is returned
	if(!(WaveDims(w)==2 || WaveDims(w)==3))
		return [-1, -1]
	endif
	variable npx = DimSize(w, 0)
	variable npy = DimSize(w, 1)	
	variable nx = xr*npx 
	variable ny = yr*npy
	px = IndexToScale(w, nx, 0)
	py = IndexToScale(w, ny, 1)	
	return [px, py]
End

static Function/WAVE TopImageToWaveRef([string grfName])
	// Return a wave reference from the top graph
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(grfName, ";"),";")
	// if there is no image in the top graph strlen(imgNameTopGraphStr) = 0
	if(strlen(imgNameTopGraphStr))
		WAVE wRef = ImageNameToWaveRef(grfName, imgNameTopGraphStr) // full path of wave
		return wRef
	else 
		return $""
	endif
End

Function/S TopImageName([string grfName])
	// Name of top graph's image. Or grfName's image!
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	string imgNameStr = StringFromList(0,ImageNameList(grfName, ";"),";") 
	if(strlen(imgNameStr))
		return imgNameStr
	else
		return ""
	endif
end

static Function/WAVE TopGraphToWaveRef([string grfName])
	// Return a wave reference from the top graph
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(grfName, ";"),";")
	if(strlen(imgNameTopGraphStr)) // We have an image
		WAVE wRef = ImageNameToWaveRef(grfName, imgNameTopGraphStr) // full path of wave
	else 
		WAVE wRef = ATH_Traces#TopTraceToWaveRef(grfName=grfName) // Trace or nothing, the latter will be handled in ATH_Traces#TopTraceToWaveRef
	endif
	return wRef
End

static Function LinkGraphSliders([string grfName])
	// Link the sliders of two graphs
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	if(ATH_Graph#GetgLayer(grfName) == -1) // if you have no slider
		return -1
	endif
	// Have you already set a link between graph sliders
	string linkedGraph = GetUserData(grfName, "", "ATH_W3DLinkedSliderGraphStr")
	if(strlen(linkedGraph))
		Slider ATH_W3DSlider, win=$grfName,thumbColor=(0,65535,0), proc=ATH_Display#NewImgSliderHook
		Slider ATH_W3DSlider, win=$linkedGraph,thumbColor=(0,65535,0), proc=ATH_Display#NewImgSliderHook		
		SetWindow $grfName userdata(ATH_W3DLinkedSliderGraphStr) = ""
		SetWindow $linkedGraph userdata(ATH_W3DLinkedSliderGraphStr) = ""
		return 0
	endif
	string wnList = WinList("*",";","WIN:1")
	wnList = RemoveFromList(grfName, wnList,";")
	Prompt linkedGraph, "Select window to link sliders", popup, wnList
	DoPrompt "Graph ", linkedGraph
	if(V_flag)
		return 0
	endif
	variable grfNameLayer = ATH_Graph#GetgLayer(linkedGraph)
	if(grfNameLayer == -1)
		return -1
	endif
	SetWindow $grfName userdata(ATH_W3DLinkedSliderGraphStr) = linkedGraph
	SetWindow $linkedGraph userdata(ATH_W3DLinkedSliderGraphStr) = grfName
	Slider ATH_W3DSlider, win=$linkedGraph,thumbColor=(65535,0,0), proc=ATH_Graph#LinkedImgSliderHook
	Slider ATH_W3DSlider, win=$grfName,thumbColor=(65535,0,0), proc=ATH_Graph#LinkedImgSliderHook
End

static Function LinkedImgSliderHook(STRUCT WMSliderAction &sa) : SliderControl
	//
	if (sa.eventCode & 9) // Mouse moved or arrow key moved the slider & Value Set
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sa.win, "", "ATH_W3DImageSliderDFR"))		
		NVAR/Z/SDFR=dfr gLayer	// added a /Z flag here, risky?
		if(NVAR_Exists(gLayer))
			gLayer = sa.curval
			ModifyImage/W=$sa.win '' plane=gLayer
			ModifyImage/W=$GetUserData(sa.win, "", "ATH_W3DLinkedSliderGraphStr") '' plane=gLayer
		else
			ATH_Display#RestartW3DImageSlider(grfName=sa.win)
		endif
	endif
	
	if(sa.eventCode==-1)
		// Remove metadata from the linked graph
		string grfName = GetUserData(sa.win, "", "ATH_W3DLinkedSliderGraphStr")
		ModifyImage/W=$grfName '' plane=gLayer
		SetWindow $grfName userdata(ATH_W3DLinkedSliderGraphStr) = ""
		Slider ATH_W3DSlider, win=$grfName,thumbColor=(0,65535,0), proc=ATH_Display#NewImgSliderHook
	endif
	return 0
End

// ----- Link Axes range
static Function LinkGraphRanges([string grfName])
	// 
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below

	// Have you already set a link between graph sliders
	string linkedGraph = GetUserData(grfName, "", "ATH_LinkedGraphAxesRangesStr")
	if(strlen(linkedGraph))
		SetWindow $grfName userdata(ATH_LinkedGraphAxesRangesStr) = ""		
		SetWindow $grfName hook(ATH_LinkedGraphAxesRangeHook) = $""
		SetWindow $linkedGraph userdata(ATH_LinkedGraphAxesRangesStr) = ""		
		SetWindow $linkedGraph hook(ATH_LinkedGraphAxesRangeHook) = $""
		string axisX, axisY
		[axisX, axisY] = ATH_Graph#GetAxes(grfName=grfName)
		ModifyGraph/W=$grfName axRGB($axisX)=(0,0,0),tlblRGB($axisX)=(0,0,0)
		ModifyGraph/W=$grfName axRGB($axisY)=(0,0,0),tlblRGB($axisY)=(0,0,0)				
		[axisX, axisY] = ATH_Graph#GetAxes(grfName=linkedGraph)		
		ModifyGraph/W=$linkedGraph axRGB($axisX)=(0,0,0),tlblRGB($axisX)=(0,0,0)
		ModifyGraph/W=$linkedGraph axRGB($axisY)=(0,0,0),tlblRGB($axisY)=(0,0,0)		
		return 0
	endif
	string wnList = WinList("*",";","WIN:1")
	wnList = RemoveFromList(grfName, wnList,";")
	Prompt linkedGraph, "Select window to link sliders", popup, wnList
	DoPrompt "Graph ", linkedGraph
	if(V_flag)
		return 0
	endif	
	SetWindow $grfName userdata(ATH_LinkedGraphAxesRangesStr) = linkedGraph		
	SetWindow $grfName hook(ATH_LinkedGraphAxesRangeHook) = ATH_Graph#LinkedGraphAxesRangeHook
	SetWindow $linkedGraph userdata(ATH_LinkedGraphAxesRangesStr) = grfName	
	SetWindow $linkedGraph hook(ATH_LinkedGraphAxesRangeHook) = ATH_Graph#LinkedGraphAxesRangeHook
	[axisX, axisY] = ATH_Graph#GetAxes(grfName=grfName)	
	ModifyGraph/W=$grfName axRGB($axisX)=(65535,0,0),tlblRGB($axisX)=(65535,0,0)
	ModifyGraph/W=$grfName axRGB($axisY)=(65535,0,0),tlblRGB($axisY)=(65535,0,0)	
	[axisX, axisY] = ATH_Graph#GetAxes(grfName=linkedGraph)	
	ModifyGraph/W=$linkedGraph axRGB($axisX)=(65535,0,0),tlblRGB($axisX)=(65535,0,0)
	ModifyGraph/W=$linkedGraph axRGB($axisY)=(65535,0,0),tlblRGB($axisY)=(65535,0,0)	
End

static Function LinkedGraphAxesRangeHook(STRUCT WMWinHookStruct &s)
	variable hookResult
	switch (s.eventCode)
		case 2:
			string linkedGraph = GetUserData(s.winName, "", "ATH_LinkedGraphAxesRangesStr"), axisX, axisY
			SetWindow $linkedGraph userdata(ATH_LinkedGraphAxesRangesStr) = ""
			SetWindow $linkedGraph hook(ATH_LinkedGraphAxesRangeHook) = $""
			[axisX, axisY] = ATH_Graph#GetAxes(grfName=linkedGraph)		
			ModifyGraph/W=$linkedGraph axRGB($axisX)=(0,0,0),tlblRGB($axisX)=(0,0,0)
			ModifyGraph/W=$linkedGraph axRGB($axisY)=(0,0,0),tlblRGB($axisY)=(0,0,0)			
			break
		case 8:
			linkedGraph = GetUserData(s.winName, "", "ATH_LinkedGraphAxesRangesStr")
			variable minX, maxX, minY, maxY
			[axisX,minX,maxX, axisY,minY,maxY] = ATH_Graph#GetAxesRange(grfName=s.winName)
			GetAxis/Q/W=$linkedGraph $axisY
			variable axisLength = abs(V_max - V_min)
			if(abs(minY - V_min) > 1e-3 * axisLength)
				SetAxis/W=$linkedGraph $axisX, minX, maxX
				SetAxis/R/W=$linkedGraph $axisY, minY, maxY
				hookResult = 0
				break
			endif
			//Catch vertical expansion
			GetAxis/Q/W=$linkedGraph $axisX
			axisLength = abs(V_max - V_min)
			if(abs(minX - V_min) > 1e-3 * axisLength)
				SetAxis/W=$linkedGraph $axisX, minX, maxX
				SetAxis/R/W=$linkedGraph $axisY, minY, maxY
				hookResult = 0
				break
			endif			
		break
	endswitch
	return hookResult
End


