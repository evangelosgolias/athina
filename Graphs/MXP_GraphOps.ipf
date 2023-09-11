#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function MXP_DuplicateWaveAndDisplayOfTopImage()
	/// Duplicate the graph of an image (2d, 3d wave) along with the wave at its
	/// data folder (not cwd). 
	string winNameStr = WinName(0, 1)
	WAVE wRef = MXP_TopImageToWaveRef()
	DFREF cdfr = GetDataFolderDFR()
	DFREF wdfr = GetWavesDataFolderDFR(wRef) 
	SetDataFolder wdfr
    string duplicateWinNameStr = UniqueName(winNameStr + "_", 6, 1, winNameStr)
    string waveNameStr = CreateDataObjectName(wdfr, NameOfWave(wRef) + "_dp", 1, 0, 4) 
    Duplicate wRef, $waveNameStr
	MXP_DisplayImage($waveNameStr)
	DoWindow/C $duplicateWinNameStr
	SetDataFolder cdfr
	return 0
End

Function MXP_TextAnnotationOnTopGraph(string text, [variable fSize, string color])
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
