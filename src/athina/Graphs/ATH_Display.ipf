#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Display
#pragma version = 1.2

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

// File to control the new image display in athina

#include <Imageslider> // Used in many .ipfs
#include <Autosize Images>
#include <WMImageInfo>

static StrConstant WMkSliderDataFolderBase = "root:Packages:WM3DImageSlider:"
static StrConstant ATH_W3DImageSliderParentDFR = "root:Packages:ATH_DataFolder:W3DImageSlider:"
static Function NewImg(WAVE wRef, [string grfname])
	if(!WaveExists(wRef))
		return -1
	endif

	// Display an image or stack
	if(ParamIsDefault(grfname))
		NewImage/G=1/K=1 wRef
		grfname = WinName(0, 1, 1)
		string graphTitle = GetWavesDataFolder(wRef, 2)[5, inf] // Discrard root:	
		DoWindow/T $grfname, graphTitle
	else
		NewImage/G=1/K=1/N=$grfName wRef
	endif
	
	variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
	ModifyGraph/W=$grfname height = 400 * pntConv, width = 400 * pntConv
	Execute/P/Q "ModifyGraph width=0,height=0"
	// Error handling
	ATH_exe#HandleSimpleError("NewImg")	
	string matchPattern = "ctab= {%*f,%*f,%[A-Za-z],%d}" //%* -> Read but not store
	string colorScaleStr
	variable cmapSwitch
	sscanf StringByKey("RECREATION",Imageinfo("",NameOfWave(wRef),0)), matchPattern, colorScaleStr, cmapSwitch
	if(WaveDims(wRef)==3)
		Append3DImageSlider()
	endif
	WaveStats/Q wRef //$GetWavesDataFolder(wRef, 2)
	variable ImgAvg = V_avg
	variable ImgStd = V_sdev
	ModifyImage/W=$grfname $PossiblyQuoteName(NameOfWave(wRef)) ctabAutoscale=3, ctab= {ImgAvg - 3 * ImgStd, ImgAvg + 3 * ImgStd,$colorScaleStr,cmapSwitch} // Autoscale per plane / visible area Image
	ModifyGraph/W=$grfname fSize=12
	SetWindow $grfname, hook(AthinaDisplayHook) = ATH_Display#DisplayHookFunction // Set the hook
	if(DimSize(wRef, 0) == DimSize(wRef, 1))
		SetWindow $grfname, userdata(ATH_isPlanQ) = "1"
	else
		SetWindow $grfname, userdata(ATH_isPlanQ) = "0"
	endif
	return 0
End

static Function DisplayHookFunction(STRUCT WMWinHookStruct &s)
	//
	// 31.08.2024: Deal with calls from /EXT windows. We control
	//	using the wave reference. This is patchwork, we need to 
	// find a more stable solution
	//
	// •DisplayHelpTopic "Hook Functions for Exterior Subwindows"
	Wave/Z w = ATH_ImgOp#TopImageToWaveRef(grfName=s.winName)
	if(!WaveExists(w))
		return 0
	endif
	int is3D = WaveDims(w)==3
	variable hookResult = 0
	string buffer
	
	switch (s.eventCode)
		case 2: // kill
			if(s.eventMod & 4) // Kill the wave and its backup when ALT is pressed 
				string wavePathStr = GetWavesDataFolder(w, 2)
				Execute/P/Q/Z "KillWaves/Z " + wavePathStr
				Execute/P/Q/Z "KillWaves/Z " + ATH_String#ExtendPathStr(wavePathStr, "_undo")
			endif
			break
		// mouseWheel has to be before case 11 -> keyboard events as
		// there is a leak in the fallhtrough and case 22 gets triggered!
		// That's a patch until I find something more elegant
		case 22:	//	mouseWheel
			if (s.eventMod & 4)		// Magnify with ALT key pressed.
				ATH_Display#Mangify(s)
				return 0
			endif
			if (is3D)
				int direction = (s.wheelDy > 0) ? 1 : -1
				NVAR/Z gLayer = root:Packages:WM3DImageSlider:$s.winName:gLayer
				NVAR/Z gRightLim = root:Packages:WM3DImageSlider:$s.winName:gRightLim				
				gLayer += direction
				if(gLayer < 0)
					gLayer = 0
				endif
				if(gLayer > gRightLim)
					gLayer = gRightLim 
				endif				
				ModifyImage/W=$s.winName '' plane=gLayer
			endif
			//return hookResult			
		case 11:
			switch(s.keycode)
				case 66: // SHIFT + B
					if(s.eventMod & 2)
						ATH_ImgOp#RestoreTopImageFromBackup(wname=NameOfWave(w))
					endif
					break
				case 70: // F
					if(s.eventMod & 2) // works with SHIFT + F only!
						ATH_Launch#ImageFFTTransform()
					endif
					break
				case 78: // N
					if(s.eventMod & 2) // works with SHIFT + N only!
						ATH_Graph#DuplicateWaveAndDisplayOfTopImage()
					endif
					break
				case 82: // R
					if(s.eventMod & 2) // works with SHIFT + R only!
						ATH_iImgRotation#CreatePanel()
					endif
					break
				case 88: // X
					if(s.eventMod & 2) // works with SHIFT + X only!
						ATH_iXPS#MainMenu()
					endif
					break
				case 97: // a - average if you have a 3d wave
					if(is3d)
						NewImg(ATH_WaveOp#AverageImageStack(w))
					endif
					break
				case 100: //d
					GetMarquee/W=$s.winName // Just check if there is Marquee, no axes.
					if(V_flag)
						ATH_Launch#ImageStackAlignmentPartition() // If marquee present launch partition dc
					else
						ATH_iDriftCorrection#CreatePanel() // otherwise start the interactive panel
					endif
					break
				case 105: // i
					ATH_Cursors#MeasureDistanceUsingFreeCursors()
					break
				case 108: //l
					ATH_LineProfile#MainMenu()
					break
				case 110: // n
					ATH_Launch#QuickTextAnnotation()
					break
				case 112: // p
					ATH_PlaneZProfile#MainMenu()
					break
				case 114: // r
					ATH_Range#pnl(s.winName)
					break
				case 115: // s
					if(str2num(GetUserData(s.winName, "", "ATH_isPlanQ")))
						SetWindow $s.winName, userdata(ATH_isPlanQ) = "0"
						ModifyGraph width = 0, height = 0
					else
						SetWindow $s.winName, userdata(ATH_isPlanQ) = "1"
						ModifyGraph width={Plan,1,top,left}
					endif
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
					break
			endswitch
			hookResult = 1
			//Do not return anything here, you will block any other case 11.
	endswitch
	return hookResult
End

static function Mangify(STRUCT WMWinHookStruct &s)
	//
	// Copied from https://www.wavemetrics.com/code-snippet/mousewheel-graph-window-zoom
	// and edited to our taste.
	//
	// Settings 
	variable ZoomSpeed = 70
	int rev = 1 // SET: -1 to reverse mouseWheel zoom in direction
	// 
	string strAxes = AxisList(s.WinName), axis = "", type = ""
	int i, numAxes, isHorizontal, isLog
	Make /D/free/N=3 wAx // free wave to hold axis minimum, maximum, axis value for mouse location
	numAxes = ItemsInList(strAxes)
	
	variable expansion = 1 - rev*s.wheelDy * ZoomSpeed/5000

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

static Function Append3DImageSlider()
	/// Edited version of WMAppend3DImageSlider() to deal with 
	/// liberal names in 3d waves
	String grfName= WinName(0, 1)
	DoWindow/F $grfName
	if( V_Flag==0 )
		return 0			// no top graph, exit
	endif
	
	String iName= WMTopImageGraph()		// find one top image in the top graph window
	if( strlen(iName) == 0 )
		DoAlert 0,"No image plot found"
		return 0
	endif
	
	Wave w = $WMGetImageWave(iName)	// get the wave associated with the top image.	
	if(DimSize(w,2)<=0)
		DoAlert 0,"Need a 3D image"
		return 0
	endif
	
	ControlInfo WM3DAxis
	if( V_Flag != 0 )
		return 0			// already installed, do nothing
	endif
	
	String dfSav= GetDataFolder(1)
	NewDataFolder/S/O root:Packages
	NewDataFolder/S/O WM3DImageSlider
	NewDataFolder/S/O $grfName
	
	// 09JUN10 Variable/G gLeftLim=0,gRightLim=DimSize(w,2)-1,gLayer=0
	Variable/G gLeftLim=0,gRightLim,gLayer=0
	if((DimSize(w,3)>0 && (dimSize(w,2)==3 || dimSize(w,2)==4)))		// 09JUN10; will also support stacks with alpha channel.
		gRightLim=DimSize(w,3)-1					//image is 4D with RGB as 3rd dim
	else
		gRightLim=DimSize(w,2)-1					//image is 3D grayscale
	endif
	
	String/G imageName = PossiblyQuoteName(NameOfWave(w)) // EG.
	ControlInfo kwControlBar
	Variable/G gOriginalHeight= V_Height			// we append below original controls (if any)
	ControlBar gOriginalHeight+30
	
	// 04.09.2024. Error pops when closing a window with slider and an /EXT window.
	GetWindow/Z kwTopWin,gsize; 
	
	Variable scale = ScreenResolution / 72										// ST: 210601 - properly scale position for windows
	Variable left = V_left*scale
	Variable right = limit(V_right*scale, left+kImageSliderLMargin+50,inf)		// ST: 210601 - make sure the controls get not too small
	
	Slider WM3DAxis,pos={left+10,gOriginalHeight+10},size={right-left-kImageSliderLMargin,16},proc=ATH_Display#W3DImageSliderProc		// ST: 210601 - shift slider slightly down
	// uncomment the following line if you want do disable live updates when the slider moves.
	// Slider WM3DAxis live=0	
	Slider WM3DAxis,limits={0,gRightLim,1},value= 0,vert= 0,ticks=0,side=0,variable=gLayer	
	
	SetVariable WM3DVal,pos={right-kImageSliderLMargin+15,gOriginalHeight+6},size={60,18}	// ST: 210601 - control slightly higher to line up with the slider
	SetVariable WM3DVal,limits={0,gRightLim,1},title=" ",proc=ATH_Display#WM3DImageSliderSetVarProc		// ST: 210601 - apply same limits as slider
	SetVariable WM3DVal,value=gLayer

	Variable zScale = DimOffset(w,2) + gLayer * DimDelta(w,2)
	String helpStr= "Z scale = "+num2str(zScale)
	ModifyControlList "WM3DVal;WM3DAxis;" help={helpStr}

	Button WM3DDoneBtn,pos={right-kImageSliderLMargin+85,gOriginalHeight+6},size={50,18}	// ST: 210601 - button to remove the slider again
	Button WM3DDoneBtn,title="Done",proc=WM3DImageSliderDoneBtnProc

	ModifyImage $imageName plane=0
	// 
	WaveStats/Q w
	ModifyImage $imageName ctab= {V_min,V_max,,0}	// missing ctName to leave it unchanged.
	
	SetWindow $grfName hook(WM3Dresize)=ATH_Display#W3DImageSliderWinHook
	
	SetDataFolder dfSav
End

//*******************************************************************************************************

static Function W3DImageSliderWinHook(STRUCT WMWinHookStruct &s)// ST: 310601 - graph hook to resize the controls dynamically

	// Note on 31.08.2024: In some cases when an /EXT window is active while calling W3DImageSliderWinHook
	// then there is no data folder and we pass the if branch and "DoWindow/F $s.winName" pop an error
	// as subwindiws have names GraphXX#EXTWindowName. Here we add a second condition that there should be only
	// 
	
	if(ATH_String#isEXTWindow(s.WinName))
		return 0
	endif
	
	//
	
	if(!DataFolderExists(WMkSliderDataFolderBase + s.winName))
		KillControl/W=$s.winName WM3DAxis
		KillControl/W=$s.winName WM3DVal
		KillControl/W=$s.winName WM3DDoneBtn
		DoWindow/F $s.winName
		//ControlInfo kwControlBar
		ControlBar/W=$s.winName 0		// TODO: We set ControlBar to 30, it might be something else already there, try to generalise  
		ATH_Display#Append3DImageSlider() // Call again to create all folders and 
	else
		DFREF valDF = $(WMkSliderDataFolderBase + s.winName)
		NVAR gOriginalHeight = valDF:gOriginalHeight
	endif
	
	// Needed to deal with Duplicates as we check in the start of the
	// function for the existance of WMkSliderDataFolderBase + s.winName
	if (s.EventCode == 2) 
		KillDataFolder/Z $(WMkSliderDataFolderBase + s.winName)
	elseif (s.EventCode == 6)	// resize
		variable left = s.winRect.left
		variable right = limit(s.winRect.right, left+kImageSliderLMargin+50,inf)
		
		Slider WM3DAxis		,win=$(s.winName)	,pos={left+10,gOriginalHeight+10}						,size={right-left-kImageSliderLMargin,16}
		SetVariable WM3DVal	,win=$(s.winName)	,pos={right-kImageSliderLMargin+15,gOriginalHeight+6}	,size={60,18}
		Button WM3DDoneBtn	,win=$(s.winName)	,pos={right-kImageSliderLMargin+85,gOriginalHeight+6}	,size={50,18}	
	elseif (s.EventCode == 8)	// modified
		DFREF valDF = $(WMkSliderDataFolderBase + s.winName)
		SVAR/Z/SDFR=valDF imageName
		NVAR/Z/SDFR=valDF gLayer
		if (SVAR_Exists(imageName) && NVAR_Exists(gLayer))
			string info = ImageInfo(s.winName, imageName, 0)
			variable pos = strsearch(info, "RECREATION", 0)
			if (pos >= 0)
				// If the user executes ModifyImage plane=#, make sure that the plane
				// number displayed in the SetVariable control and the slider reflect the change.
				string rec = info[pos + 11, strlen(info) - 1] // strlen("RECREATION:") = 11
				variable plane = NumberByKey("plane", rec, "=", ";", 0)
				if (numtype(plane) == 0 && (gLayer != plane))
					// gLayer = plane 
					// TODO: Removed on the 14.08.2024 
					// When the NewImg windows hook is involved then plane is reduced by
					// one for every key stroke. I have to investigate why.
					// Now the slider doesn't change with mouseWheel, unless the cursor
					// is on the the slider.
					// Best solution: Write another function to deal with Sliders etc.
					DoWindow/F $s.winName
					ATH_Display#W3DImageSliderProc("",0,0)
				endif
			endif
		endif
	elseif (s.EventCode == 13)	// renamed
		// Rename the data folder containing this package's globals.
		DFREF oldDF = $(WMkSliderDataFolderBase + s.oldWinName)
		DFREF newDF = $(WMkSliderDataFolderBase + s.winName)
		if(DataFolderRefStatus(oldDF) == 1 && DataFolderRefStatus(newDF) == 0)
			RenameDataFolder oldDF, $(s.winName)
		endif
	endif		
	return 0
End

static Function W3DImageSliderProc(string name, variable value, variable event)
	//String name			// name of this slider control
	//Variable value		// value of slider
	//Variable event		// bit field: bit 0: value set; 1: mouse down, //   2: mouse up, 3: mouse moved

	String dfSav= GetDataFolder(1)
	String grfName= WinName(0, 1)
	SetDataFolder $(WMkSliderDataFolderBase + grfName)

	NVAR gLayer
	SVAR imageName
	ModifyImage/W=$grfName $imageName plane=(gLayer)
	
	string helpStr=""
	WAVE/Z imageW = ImageNameToWaveRef(grfName, imageName)
	if( WaveExists(imageW) )
		variable zScale = DimOffset(imageW,2) + gLayer * DimDelta(imageW,2)
		helpStr= "Z scale = "+num2str(zScale)
	endif
	ModifyControlList "WM3DVal;WM3DAxis;" win=$grfName, help={helpStr}
	
	SetDataFolder dfSav
	
	// Do we need the following? EG
//	// 08JAN03 Tell us if there is an active LineProfile
	SVAR/Z imageGraphName=root:Packages:WMImProcess:LineProfile:imageGraphName
	if(SVAR_EXISTS(imageGraphName))
		if(cmpstr(imageGraphName,grfName)==0)
			ModifyGraph/W=$imageGraphName offset(lineProfileY)={0,0}			// This will fire the S_TraceOffsetInfo dependency
		endif
	endif	
		
	SVAR/Z imageGraphName=root:Packages:WMImProcess:ImageThreshold:ImGrfName
	if(SVAR_EXISTS(imageGraphName))
		if(cmpstr(imageGraphName,grfName)==0)
			WMImageThreshUpdate()
		endif
	endif
	
	return 0				// other return values reserved
End

static Function WM3DImageSliderSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		// comment the following line if you want to disable live updates.
		case 3: // Live update
			Variable dval = sva.dval
			WM3DImageSliderProc("",0,0)
			break
	endswitch

	return 0
End

static Function WM3DImageSliderDoneBtnProc(bs) : ButtonControl		// ST: 310601 - removes the slider controls
	STRUCT WMButtonAction &bs
	if (bs.eventCode == 2)
		DFREF valDF = $(WMkSliderDataFolderBase + bs.win)
		NVAR originalHeight = valDF:gOriginalHeight
		SetWindow $(bs.win) hook(WM3Dresize)=$""
	
		ControlBar originalHeight
		KillControl/W=$bs.win WM3DAxis
		KillControl/W=$bs.win WM3DVal
		KillControl/W=$bs.win WM3DDoneBtn
		KillDataFolder/Z valDF
	endif
	return 0
End
//*******************************************************************************************************

static Function SetImageRangeTo94Percent()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	
	variable planeN
	
	if(WaveDims(imgWaveRef) == 3)
		string sss = ImageInfo(winNameStr, imgNameTopGraphStr, 0)
		planeN  = numberbykey("plane", sss, "=")
	elseif(WaveDims(imgWaveRef) == 2)
		planeN = - 1
	else
		return -1
	endif
	// Error handling in case axes are different
	GetMarquee/Z/K left, top; variable errorCode = GetRTError(1) // Same line, supressed even when debugger on
	
	if(errorCode)
		print "AthinaError: " + GetErrMessage(errorCode, 3)
		SetDataFolder saveDF
		return -1
	endif
	
	if(!V_flag)
		return 0
	endif
	ATH_Marquee#CoordinatesToROIMask(V_left, V_top, V_right, V_bottom, interior = 0, exterior = 1) // Needed by ImageHistogram
	WAVE M_ROIMask

	if(planeN < 0)
		// adding /I Calculates a histogram with 65536 bins, does not work well for 8-bit images
		ImageHistogram/R=M_ROIMask imgWaveRef
	else
		ImageHistogram/P=(planeN)/R=M_ROIMask imgWaveRef
	endif
	
	variable nzmin, nzmax
	WAVE W_ImageHist
	variable npts= numpnts(W_ImageHist)
	variable tot = sum(W_ImageHist, pnt2x(W_ImageHist,0 ), pnt2x(W_ImageHist,npts-1 ))

	variable s=0,i=0
	do
		s += W_ImageHist[i]
		i+=1
	while( (s/tot) < 0.03 )
	nzmin= LeftX(W_ImageHist)+deltax(W_ImageHist)*i
	
	s=0;i=npts-1
	do
		s += W_ImageHist[i]
		i-=1
	while( (s/tot) < 0.03 )
	nzmax= LeftX(W_ImageHist)+deltax(W_ImageHist)*i
	
	ModifyImage/W=$winNameStr $PossiblyQuoteName(nameOfWave(imgWaveRef)) ctab= {nzmin,nzmax,}
	
	SetDataFolder saveDF
	return 0
End

static Function RestartWM3DImageSlider(string winNameStr)
	// Kill and restart WM3DImageSlider and restart in case 
	// of changed in the source 3d wave.
	DFREF dfr = $(WMkSliderDataFolderBase + winNameStr)
	NVAR originalHeight = dfr:gOriginalHeight
	SetWindow $(winNameStr) hook(WM3Dresize)=$""
	
	ControlBar originalHeight
	KillControl/W=$winNameStr WM3DAxis
	KillControl/W=$winNameStr WM3DVal
	KillControl/W=$winNameStr WM3DDoneBtn
	KillDataFolder/Z dfr
	ATH_Display#Append3DImageSlider()
	return 0
End


// ---------------------------------
// ----------------------------------
	
//static Structure athSliderParam
//	uchar dims
//	uint16 nlayers
//	uint16 layer
//	uint16 LeftLim
//	uint16 RightLim
//	variable cbOriginalHeight
//EndStructure

static Function NewImgS(WAVE wRef, [string grfname])
	if(!WaveExists(wRef))
		return -1
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
//
//	if(WaveDims(wRef)==3)
//		STRUCT athSliderParam sld
//		// Prepare the slider structure
//		sld.dims = 3
//		sld.nlayers = DimSize(wRef, 2)
//		sld.layer = 0
//		sld.LeftLim = 0
//		sld.RightLim = sld.nlayers - 1
//		ControlInfo kwControlBar
//		sld.cbOriginalHeight = V_Height
//		string structStr
//		StructPut/S sld, structStr
//		SetWindow $grfname userdata(sATH_SliderParam) = structStr
//	endif

	if(WaveDims(wRef)==3)
		//
		string dfrStr = ATH_W3DImageSliderParentDFR + grfName
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)
		variable/G dfr:gLayer = 0
		variable/G dfr:gLeftLim = 0
		variable/G dfr:gRightLim = DimSize(wRef, 2) - 1
		ControlInfo kwControlBar
		variable/G dfr:gOriginalHeight = V_Height
		string/G dfr:imageName = NameOfWave(wRef)
		SetWindow $grfname userdata(ATH_W3DImageSliderDFR) = dfrStr
	endif

	variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
	ModifyGraph/W=$grfname height = 400 * pntConv, width = 400 * pntConv
	Execute/P/Q "ModifyGraph width=0,height=0"
	// Error handling
	ATH_exe#HandleSimpleError("NewImg")	
	string matchPattern = "ctab= {%*f,%*f,%[A-Za-z],%d}" //%* -> Read but not store
	string colorScaleStr
	variable cmapSwitch
	sscanf StringByKey("RECREATION",Imageinfo("",NameOfWave(wRef),0)), matchPattern, colorScaleStr, cmapSwitch
	if(WaveDims(wRef)==3)
		athAppendSlider(grfName=grfName)
	endif
	WaveStats/Q wRef //$GetWavesDataFolder(wRef, 2)
	variable ImgAvg = V_avg
	variable ImgStd = V_sdev
	ModifyImage/W=$grfname $PossiblyQuoteName(NameOfWave(wRef)) ctabAutoscale=3, ctab= {ImgAvg - 3 * ImgStd, ImgAvg + 3 * ImgStd,$colorScaleStr,cmapSwitch} // Autoscale per plane / visible area Image
	ModifyGraph/W=$grfname fSize=12
	SetWindow $grfname, hook(AthinaDisplayHook) = ATH_Display#DisplayHookFunction__ // Set the hook
	
	if(DimSize(wRef, 0) == DimSize(wRef, 1))
		SetWindow $grfname, userdata(ATH_isPlanQ) = "1"
	else
		SetWindow $grfname, userdata(ATH_isPlanQ) = "0"
	endif
	return 0
End


Function athAppendSlider([string grfName])
		// Append a slider if you have a stack
		// Wave in top graph
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(grfName, "", "ATH_W3DImageSliderDFR"))
		NVAR/SDFR=dfr gLayer
		NVAR/SDFR=dfr gOriginalHeight	
		grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
		WAVE wRef = ATH_ImgOp#TopImageToWaveRef(grfName=grfName)
		variable nlayers = DimSize(wRef, 2)
		variable tkImageSliderLMargin = 150
		ControlBar gOriginalHeight+30
		variable scale = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
		GetWindow/Z $grfName,gsize
		variable left = V_left*scale
		variable right = limit(V_right*scale, left+tkImageSliderLMargin+50,inf)
		Slider athW3DSlider,ticks=0,vert=0,limits={0, nlayers-1, 1},variable=gLayer,pos={left+10,gOriginalHeight+10},win=$grfName
		Slider athW3DSlider, size={right-left-tkImageSliderLMargin-30,16},proc=ATH_Display#NewImgSliderHook,win=$grfName
		SetVariable athW3DSliderVar,limits={0,nlayers-1, 1},pos={right-165, gOriginalHeight+10},live=1,win=$grfName
		SetVariable athW3DSliderVar,value=gLayer,size={50,20},proc=ATH_Display#ImageSliderSetVarProc,win=$grfName
End

Function NewImgSliderHook(STRUCT WMSliderAction &sa) : SliderControl

	if (sa.eventCode & 1 || sa.eventCode & 8)	// Value set
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sa.win, "", "ATH_W3DImageSliderDFR"))
		NVAR/SDFR=dfr gLayer	
		gLayer = sa.curval
		ModifyImage/W=$sa.win '' plane=gLayer
	endif
	
	return 0

End

static Function ImageSliderSetVarProc(STRUCT WMSetVariableAction &sva) : SetVariableControl
	
	switch( sva.eventCode )
		case 1:
		case 2:
		case 3:
		case 6:
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sva.win, "", "ATH_W3DImageSliderDFR"))
			NVAR/SDFR=dfr gLayer
			gLayer = sva.dval
			ModifyImage/W=$sva.win '' plane=gLayer
			break
	endswitch

	return 0
End

// TODO: Automate the process. Create a function that launches
static Function DisplayHookFunction__(STRUCT WMWinHookStruct &s)
	//
	// 31.08.2024: Deal with calls from /EXT windows. We control
	//	using the wave reference. This is patchwork, we need to 
	// find a more stable solution
	//
	// •DisplayHelpTopic "Hook Functions for Exterior Subwindows"
	Wave/Z w = ATH_ImgOp#TopImageToWaveRef(grfName=s.winName)
	if(!WaveExists(w))
		return 0
	endif
	int is3D = WaveDims(w)==3
	variable hookResult = 0
	string buffer
	
	switch (s.eventCode)
		case 2: // kill
			if(s.eventMod & 4) // Kill the wave and its backup when ALT is pressed 
				string wavePathStr = GetWavesDataFolder(w, 2)
				Execute/P/Q/Z "KillWaves/Z " + wavePathStr
				Execute/P/Q/Z "KillWaves/Z " + ATH_String#ExtendPathStr(wavePathStr, "_undo")
			endif
			break
		// mouseWheel has to be before case 11 -> keyboard events as
		// there is a leak in the fallhtrough and case 22 gets triggered!
		// That's a patch until I find something more elegant
		case 22:	//	mouseWheel
			if (s.eventMod & 4)		// Magnify with ALT key pressed.
				ATH_Display#Mangify(s)
				return 0
			endif
			if (is3D)
				DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_W3DImageSliderDFR"))
				NVAR/SDFR=dfr gLayer, gRightLim, gLeftLim
				int direction = (s.wheelDy > 0) ? 1 : -1
				gLayer += direction
				if(gLayer < 0)
					gLayer = 0
				endif
				if(gLayer > gRightLim)
					gLayer = gRightLim 
				endif	
				ModifyImage/W=$s.winName '' plane=gLayer
			endif
			//return hookResult			
		case 11:
			switch(s.keycode)
				case 66: // SHIFT + B
					if(s.eventMod & 2)
						ATH_ImgOp#RestoreTopImageFromBackup(wname=NameOfWave(w))
					endif
					break
				case 70: // F
					if(s.eventMod & 2) // works with SHIFT + F only!
						ATH_Launch#ImageFFTTransform()
					endif
					break
				case 78: // N
					if(s.eventMod & 2) // works with SHIFT + N only!
						ATH_Graph#DuplicateWaveAndDisplayOfTopImage()
					endif
					break
				case 82: // R
					if(s.eventMod & 2) // works with SHIFT + R only!
						ATH_iImgRotation#CreatePanel()
					endif
					break
				case 88: // X
					if(s.eventMod & 2) // works with SHIFT + X only!
						ATH_iXPS#MainMenu()
					endif
					break
				case 97: // a - average if you have a 3d wave
					if(is3d)
						NewImg(ATH_WaveOp#AverageImageStack(w))
					endif
					break
				case 100: //d
					GetMarquee/W=$s.winName // Just check if there is Marquee, no axes.
					if(V_flag)
						ATH_Launch#ImageStackAlignmentPartition() // If marquee present launch partition dc
					else
						ATH_iDriftCorrection#CreatePanel() // otherwise start the interactive panel
					endif
					break
				case 105: // i
					ATH_Cursors#MeasureDistanceUsingFreeCursors()
					break
				case 108: //l
					ATH_LineProfile#MainMenu()
					break
				case 110: // n
					ATH_Launch#QuickTextAnnotation()
					break
				case 112: // p
					ATH_PlaneZProfile#MainMenu()
					break
				case 114: // r
					ATH_Range#pnl(s.winName)
					break
				case 115: // s
					if(str2num(GetUserData(s.winName, "", "ATH_isPlanQ")))
						SetWindow $s.winName, userdata(ATH_isPlanQ) = "0"
						ModifyGraph width = 0, height = 0
					else
						SetWindow $s.winName, userdata(ATH_isPlanQ) = "1"
						ModifyGraph width={Plan,1,top,left}
					endif
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
					break
			endswitch
			hookResult = 1
			//Do not return anything here, you will block any other case 11.
	endswitch
	return hookResult
End