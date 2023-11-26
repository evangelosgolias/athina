#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Graph

static StrConstant WMkSliderDataFolderBase = "root:Packages:WM3DImageSlider:"


static Function DuplicateWaveAndDisplayOfTopImage()
	/// Duplicate the graph of an image (2d, 3d wave) along with the wave at its
	/// data folder (not cwd). 
	string winNameStr = WinName(0, 1)
	WAVE wRef = ATH_ImageOP#TopImageToWaveRef()
	DFREF cdfr = GetDataFolderDFR()
    string duplicateWinNameStr = UniqueName(winNameStr + "_", 6, 1, winNameStr)
    string waveNameStr = CreateDataObjectName(cdfr, NameOfWave(wRef) + "_d", 1, 0, 5)
    Duplicate wRef, cdfr:$waveNameStr // Copy the wave to the working dir
    ControlInfo/W=$winNameStr WM3DAxis
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