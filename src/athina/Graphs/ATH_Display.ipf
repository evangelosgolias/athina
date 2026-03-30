#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Display
#pragma version = 1.3

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


/// @module ATH_Display
/// @brief Module ATH_Display.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH Display functionality.

// Visible everywhere, global constant.
strConstant skATH_W3DImageSliderParentDFR = "root:Packages:ATH_DataFolder:W3DImageSlider:" // Ends with semicolon

static Function/S NewImg(WAVE wRef, [string grfname])
	if(!WaveExists(wRef))
		return ""
	endif

	// End of slider structure
	// Display an image or stack
	if(ParamIsDefault(grfname))
		NewImage/G=1/K=1 wRef
		grfname = WinName(0, 1, 1)
		string graphTitle = GetWavesDataFolder(wRef, 2)[5, inf] // Discrard root:	
		DoWindow/T $grfname, graphTitle
	else
		NewImage/G=1/K=1/N=$grfName wRef
	endif

	if(WaveDims(wRef)==3)
		Append3DImageSlider(grfName=grfName)
	endif

	// Error handling
	ATH_exe#HandleSimpleError("NewImg")	
	string matchPattern = "ctab= {%*f,%*f,%[A-Za-z],%d}" //%* -> Read but not store
	string colorScaleStr
	variable cmapSwitch
	sscanf StringByKey("RECREATION",Imageinfo("",NameOfWave(wRef),0)), matchPattern, colorScaleStr, cmapSwitch
	WaveStats/Q wRef //$GetWavesDataFolder(wRef, 2)
	variable ImgAvg = V_avg, ImgStd = V_sdev
	ModifyImage/W=$grfname $PossiblyQuoteName(NameOfWave(wRef)) ctabAutoscale=3, ctab= {ImgAvg - 3 * ImgStd, ImgAvg + 3 * ImgStd,$colorScaleStr,cmapSwitch} // Autoscale per plane / visible area Image
	ModifyGraph/W=$grfname fSize=12
	SetWindow $grfname, hook(AthinaDisplayHook) = ATH_Display#DisplayHookFunction // Set the hook
	if(DimSize(wRef, 0) == DimSize(wRef, 1))
		SetWindow $grfname, userdata(ATH_isPlanQ) = "1"
		ModifyGraph/W=$grfname width={Plan,1,top,left}
	else
		SetWindow $grfname, userdata(ATH_isPlanQ) = "0"
		ModifyGraph/W=$grfname width=0,height=0
	endif
	return grfname
End

/// @function DisplayHookFunction
/// @brief Description of DisplayHookFunction.
/// @details
/// Auto-generated documentation stub for function `DisplayHookFunction`.
/// @param &s Parameter &s.
/// @returns Variable Return value.


static Function DisplayHookFunction(STRUCT WMWinHookStruct &s)
	//
	// 31.08.2024: Deal with calls from /EXT windows. We control
	//	using the wave reference. This is patchwork, we need to 
	// find a more stable solution
	//
	// •DisplayHelpTopic "Hook Functions for Exterior Subwindows"
	variable hookResult = 0
	Wave/Z w = ATH_Graph#TopImageToWaveRef(grfName=s.winName)
	if(!WaveExists(w))
		return 0
	endif
	int is3D = WaveDims(w)==3
	if(is3D)
		string dfrSldStr = GetUserData(s.winName, "", "ATH_W3DImageSliderDFR")
		DFREF dfrSld = ATH_DFR#CreateDataFolderGetDFREF(dfrSldStr)
		NVAR/Z/SDFR=dfrSld gLayer, gRightLim, gLeftLim, gOriginalHeight
		SVAR/Z/SDFR=dfrSld imageName
		GetWindow $s.WinName gSizeDC
		variable grfWidth = V_right - V_left
		if(grfWidth < 500)
			variable fct = grfWidth*0.87*sqrt(grfWidth/500)
		else 
			fct = grfWidth*0.87
		endif
	endif
	
	switch (s.eventCode)
		case 6:
			if(is3D)
				Slider ATH_W3DSlider,size={fct,15},win=$s.winName
				SetVariable ATH_W3DSliderVar,pos={fct+15, gOriginalHeight+5},win=$s.winName
			endif
			break
			// mouseWheel has to be before case 11 -> keyboard events as
			// there is a leak in the fallhtrough and case 22 gets triggered!
			// That's a patch until I find something more elegant
		case 22:	//	mouseWheel
			if (s.eventMod & 2)		// Magnify with SHIFT key pressed.
				ATH_Display#Mangify(s)
				return 0
			endif
			if (is3D)
				// s.wheelDy becomes s.wheelDx when SHIFT is pressed.
				// The other value is zero
				int direction = ((s.wheelDx+s.wheelDy) > 0) ? 1 : -1
				gLayer += direction
				if(gLayer < 0)
					if(s.eventMod & 4)
						gLayer = gRightLim
					else
						gLayer = 0
					endif
				endif
				if(gLayer > gRightLim)
					if(s.eventMod & 4)
						gLayer = 0
					else
						gLayer = gRightLim
					endif
				endif
				ModifyImage/W=$s.winName '' plane=gLayer
				hookResult = 1
			endif
			break
		case 8: //ModifyImage/W=$grfName '' plane=XX
			variable plane = ATH_ImgOp#GetLayerIndex(s.winName, w=w)
			if (gLayer != plane)
				gLayer = plane
			else // For example, zoom-in using the marquee
				if(is3D)				
					Slider ATH_W3DSlider,size={fct,15},win=$s.winName
					SetVariable ATH_W3DSliderVar,pos={fct+15, gOriginalHeight+5},win=$s.winName
				endif
			endif
			
			DrawAction/L=UserFront/W=$s.winName getgroup = athScaleBar // Do we gave a scale bar?
			if(V_flag)
				string axisX, axisY, scaleFactorStr
				variable minVX, maxVX, minVY, maxVY
				[axisX, minVX, maxVX, axisY, minVY, maxVY] = ATH_Graph#GetAxesRange(grfName=s.winName)
				variable xlen = abs(maxVX - minVX)
				variable scale = str2num(GetUserData(s.winName, "", "ATH_DrawBarInGraphNominalScale"))
				scaleFactorStr = num2str(scale/xlen)
				if(cmpstr((GetUserData(s.winName, "", "ATH_DrawBarInGraphScaleFactor")), scaleFactorStr))
					variable sf = ATH_Draw#ImageScaleBar(str2num(GetUserData(s.winName, "", "ATH_DrawBarInGraphNominalScale")), grfName=s.winName)
					SetWindow $s.winName userdata(ATH_DrawBarInGraphScaleFactor) = num2str(sf)
				endif
			//hookResult = 1 // it blocks the update of Stack layer in Line profile!	
			endif	
			break
		case 2: // kill
			// If you are not in a duplicate window
			if(is3D && !cmpstr(s.winName, ParseFilePath(0, dfrSldStr, ":", 1, 0)))
				KillDataFolder/Z dfrSld
			endif
			if(is3D && str2num(GetUserData(s.winName, "", "ATH_isTransientStack"))) // Delete the transient stack & backup
				string cmdStr = "KillWaves/Z "+  GetWavesDataFolder(w,2) + ";"
				cmdStr += "KillWaves/Z "+  GetWavesDataFolder(w,2) + ksATHBackupWaveExtention
				Execute/P/Q cmdStr
			endif
			break
		case 13:	// renamed
			// Rename the data folder containing this package's globals.
			DFREF oldDF = $(skATH_W3DImageSliderParentDFR + s.oldWinName)
			DFREF newDF = $(skATH_W3DImageSliderParentDFR + s.winName)
			if(DataFolderRefStatus(oldDF) == 1 && DataFolderRefStatus(newDF) == 0)
				RenameDataFolder oldDF, $(s.winName)
				SetWindow $s.winName userdata(ATH_W3DImageSliderDFR) = skATH_W3DImageSliderParentDFR + s.winName
			endif
			break
		case 11:
			switch(s.keycode)
				case 66: // B
					if(s.eventMod & 2) // works with SHIFT + B only!
						ATH_ImgOp#RestoreTopImageFromBackup() // works with SHIFT + B only!
						hookResult = 1															
					endif
					break			
				case 67: // C
					if(s.eventMod & 2) // works with SHIFT + C only!
						ATH_Color#pnl(s.winName)
						hookResult = 1										
					endif
					break
				case 69: // E
					if(s.eventMod & 2) // works with SHIFT + E only!
						ATH_Launch#ExtractLayerRangeToStack()
						hookResult = 1										
					endif
					break					
				case 70: // F
					if(s.eventMod & 2) // works with SHIFT + F only!
						ATH_Launch#ImageFFTTransform(sourceDF=1)
						hookResult = 1										
					endif
					break
				case 76: // L, link/unlink sliders and ranges
					if(s.eventMod & 2) // works with SHIFT + L only!
						ATH_Graph#LinkGraphSliders(grfName=s.winName)
						ATH_Graph#LinkGraphRanges(grfName=s.winName)
						hookResult = 1										
					endif
					break						
				case 77: // M
					if(s.eventMod & 2) // works with SHIFT + M only!
						ATH_Launch#MirrorPositionToWaveValues()
						hookResult = 1										
					endif
					break					
				case 78: // N
					if(s.eventMod & 2) // works with SHIFT + N only!
						ATH_Launch#QuickTextAnnotation()
						hookResult = 1										
					endif
					break
				case 79: // O
					if(s.eventMod & 2) // works with SHIFT + D only!
						ATH_Graph#DuplicateWaveAndDisplayOfTopImage()
						hookResult = 1										
					endif
					break
				case 80: // P
					if(s.eventMod & 2) // works with SHIFT + D only!
						ATH_Launch#PixelateSingleImageOrStack()
						hookResult = 1										
					endif
					break						
				case 82: // R
					if(s.eventMod & 2) // works with SHIFT + R only!
						ATH_Launch#ImageResample()
						hookResult = 1										
					endif
					break
				case 83: // S
					if(s.eventMod & 2) // works with SHIFT + S only!
						ATH_Launch#SaveAxesRangeAndCtab()
						hookResult = 1											
					endif
					break			
				case 85: // U
					if(s.eventMod & 2 && s.eventMod & 8) // works with SHIFT + Ctrl + U only!
						ATH_Launch#UnpackStackToSources()
						hookResult = 1											
					endif
					break								
				case 88: // X
					if(s.eventMod & 2) // works with SHIFT + X only!
						ATH_iXPS#MainMenu()
						hookResult = 1										
					endif
					break
				case 97: // a - average if you have a 3d wave
					if(is3d)
						NewImg(ATH_WaveOp#AverageImageStack(w))
						hookResult = 1										
					endif
					break
				case 98: // b - remove background
					ATH_Launch#ImgRemoveBackground()
					hookResult = 1										
					break					
				case 100: // d - not capital here
					GetMarquee/W=$s.winName // Just check if there is Marquee, no axes.
					if(V_flag)
						ATH_Launch#ImageStackAlignmentPartition() // If marquee present launch partition dc
					else
						ATH_iDriftCorrection#CreatePanel() // otherwise start the interactive panel
					endif
					hookResult = 1					
					break
				case 102: // f
					ATH_Launch#SetTopGraphDF()
					hookResult = 1					
					break										
				case 105: // i
					ATH_Cursors#MeasureDistanceUsingFreeCursors()
					hookResult = 1										
					break
				case 108: //l
					ATH_LineProfile#MainMenu()
					hookResult = 1										
					break
				case 110: // n
					if(str2num(GetUserData(s.winName, "", "ATH_isPlanQ")))
						SetWindow $s.winName, userdata(ATH_isPlanQ) = "0"
						ModifyGraph width = 0, height = 0
					else
						SetWindow $s.winName, userdata(ATH_isPlanQ) = "1"
						ModifyGraph width={Plan,1,top,left}
					endif
					hookResult = 1								
					break
				case 112: // p
					ATH_PlaneZProfile#MainMenu()
					hookResult = 1										
					break
				case 113: // q
					// Attach the list of waves to the controller
					if(strlen(GetUserData(s.winName, "ATH_W3DSlider", "ATH_StackedWaveList")))
						ModifyControl ATH_W3DSlider win=$s.winName, userdata(ATH_StackedWaveList) = ""
						DoWindow/T $s.winName, GetWavesDataFolder(w,2)						
					else
						string wavelistStr = ATH_string#GetStackNamesFromNote(w)
						ModifyControl ATH_W3DSlider win=$s.winName, userdata(ATH_StackedWaveList) = waveListStr
					endif
					hookResult = 1
					break		
				case 114: // r
					ATH_Range#pnl(s.winName)
					hookResult = 1										
					break
				case 115: // s
					ATH_Launch#SetAxesRangeAndCtabFromSaved()				
					hookResult = 1					
					break			
				case 120: // x, calculate xmcd
					if(is3d && DimSize(w, 2)==2)
						ATH_Launch#CalculateXMCDFromStack()
					endif
					break
				case 122: // z, launch z-profile if marquee present
					if(is3d)
						GetMarquee/W=$s.winName
						if(V_flag)
							Execute/P/Q "ATH_ZProfile#GraphMarqueeLaunchRectangle()"
						endif
					endif
					hookResult = 1										
					break
				default:
					hookResult = 0 // if 1 then arrows for example do not work				
					break
			endswitch
			//Do not return anything here, you will block any other case 11.
	endswitch
	return hookResult
End

/// @function Append3DImageSlider
/// @brief Description of Append3DImageSlider.
/// @details
/// Auto-generated documentation stub for function `Append3DImageSlider`.
/// @param grfName] Parameter grfName].
/// @returns Variable Return value.

Function Append3DImageSlider([string grfName])
		// Append a slider if you have a stack
		// Wave in top graph
			
		grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)		
		WAVE wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
		if(WaveDims(wRef)!=3)
			return 1
		endif

		string dfrStr = skATH_W3DImageSliderParentDFR + grfName
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)
		SetWindow $grfName userdata(ATH_W3DImageSliderDFR) = dfrStr
		ControlInfo kwControlBar
		variable/G dfr:gLayer = 0
		variable/G dfr:gLeftLim = 0
		variable/G dfr:gRightLim = DimSize(wRef, 2) - 1
		variable/G dfr:gOriginalHeight = V_Height
		string/G dfr:imageName = NameOfWave(wRef)
		
		variable nlayers = DimSize(wRef, 2)
		NVAR/Z/SDFR=dfr gLayer
		NVAR/Z/SDFR=dfr gOriginalHeight
		variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
		
		ControlBar/W=$grfName (gOriginalHeight+30)*pntConv
		// Reads graph outer dimensions into V_left,
		// V_right, V_top, and V_bottom in local coordinates. 
		// This includes axes but not the tool palette, control bar, or info panel. 
		// Dimensions are in points.		
		GetWindow $grfName gSizeDC
		// Size values here are overriden by the window hook function, if set.
		Slider ATH_W3DSlider,ticks=0,vert=0,limits={0, nlayers-1, 1},variable=gLayer,pos={(V_left+10),(gOriginalHeight+10)},win=$grfName
		Slider ATH_W3DSlider,thumbColor=(0,65535,0),size={V_right*0.85,15},proc=ATH_Display#NewImgSliderHook,win=$grfName
		SetVariable ATH_W3DSliderVar,limits={0,nlayers-1, 1},fsize= 12,pos={V_right*0.875, (gOriginalHeight+5)},live=1,win=$grfName
		SetVariable ATH_W3DSliderVar,title=" ",value=gLayer,size={50,20},proc=ATH_Display#ImageSliderSetVar,win=$grfName
End

/// @function NewImgSliderHook
/// @brief Description of NewImgSliderHook.
/// @details
/// Auto-generated documentation stub for function `NewImgSliderHook`.
/// @param &sa Parameter &sa.
/// @returns Variable Return value.

Function NewImgSliderHook(STRUCT WMSliderAction &sa) : SliderControl

	if (sa.eventCode & 9) // Mouse moved or arrow key moved the slider & Value Set
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sa.win, "", "ATH_W3DImageSliderDFR"))
		NVAR/Z/SDFR=dfr gLayer	// added a /Z flag here, risky?
		if(NVAR_Exists(gLayer))
			gLayer = sa.curval
			ModifyImage/W=$sa.win '' plane=gLayer
		else
			ATH_Display#RestartW3DImageSlider(grfName=sa.win)
		endif
	endif
	
	if(sa.eventCode==-1)
		string dfrSld = GetUserData(sa.win, "", "ATH_W3DImageSliderDFR")
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrSld)
		// If you are not in a duplicate window
		if(!cmpstr(sa.win, ParseFilePath(0, dfrSld, ":", 1, 0)))
			KillDataFolder/Z dfr
		endif
	endif
	return 0
End

/// @function ImageSliderSetVar
/// @brief Description of ImageSliderSetVar.
/// @details
/// Auto-generated documentation stub for function `ImageSliderSetVar`.
/// @param &sva Parameter &sva.
/// @returns Variable Return value.

static Function ImageSliderSetVar(STRUCT WMSetVariableAction &sva) : SetVariableControl
	variable hookresult =  0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sva.win, "", "ATH_W3DImageSliderDFR"))
	NVAR/Z/SDFR=dfr gLayer, gRightLim
	switch(sva.eventCode)
		case 1:
		case 2:
		case 3:
		case 6:
			gLayer = sva.dval
			ModifyImage/W=$sva.win '' plane=gLayer
			// Added 02.10.2025
			string stackedWaveList = GetUserData(sva.win, "ATH_W3DSlider", "ATH_StackedWaveList")
			if(strlen(stackedWaveList))
				DoWindow/T $sva.win, StringByKey(num2str(gLayer),stackedWaveList,">","\n")
			endif
			// End of addition			
			break
	endswitch
	return 0
End

static Function Mangify(STRUCT WMWinHookStruct &s)
	//
	// Copied from https://www.wavemetrics.com/code-snippet/mousewheel-graph-window-zoom
	// and edited to our taste.
	//
	// Settings 
	variable ZoomSpeed = 70, expansion
	int rev = 1 // SET: -1 to reverse mouseWheel zoom in direction
	// 
	string strAxes = AxisList(s.WinName), axis = "", type = ""
	int i, numAxes, isHorizontal, isLog
	Make /D/free/N=3 wAx // free wave to hold axis minimum, maximum, axis value for mouse location
	numAxes = ItemsInList(strAxes)
	
	if(s.wheelDx)
		expansion = 1 - rev*s.wheelDx * ZoomSpeed/5000
	elseif(s.wheelDy)
		expansion = 1 - rev*s.wheelDy * ZoomSpeed/5000
	else
		// pass
	endif
	
	for (i = 0; i < numAxes; i++)
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
		if ((V_numNaNs + V_numInfs) || wAx[1] == wAx[0])
			continue
		endif

		if (wAx[1] > wAx[0])
			SetAxis /W=$s.WinName $axis, wAx[0], wAx[1]
		else
			SetAxis /R/W=$s.WinName $axis, wAx[0], wAx[1]
		endif
	endfor
	return 0
End

/// @function RestartW3DImageSlider
/// @brief Description of RestartW3DImageSlider.
/// @details
/// Auto-generated documentation stub for function `RestartW3DImageSlider`.
/// @param grfName] Parameter grfName].
/// @returns Variable Return value.

static Function RestartW3DImageSlider([string grfName])
	// Kill and restart ATH_Display#Append3DImageSlider and restart in case 
	// of changes in the source 3d wave.
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	DFREF dfr = $(skATH_W3DImageSliderParentDFR + grfName)
	NVAR/Z originalHeight = dfr:gOriginalHeight
	if(NVAR_Exists(originalHeight))
		ControlBar/W=$grfName originalHeight
	endif
	KillControl/W=$grfName ATH_W3DSlider
	KillControl/W=$grfName ATH_W3DSliderVar
	KillDataFolder/Z dfr
	ATH_Display#Append3DImageSlider()
	return 0
End
