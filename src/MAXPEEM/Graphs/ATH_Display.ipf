#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Display
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

#include <Imageslider> // Used in many .ipfs
#include <Autosize Images>
#include <WMImageInfo>

static StrConstant WMkSliderDataFolderBase = "root:Packages:WM3DImageSlider:"

static Function NewImg(WAVE wRef)
	// Display an image or stack
	NewImage/G=1/K=1 wRef
	string windowNameStr = GetWavesDataFolder(wRef, 2)[5, inf] // Discrard root:
	DoWindow/T kwTopWin, windowNameStr
	string winNameStr = WinName(0, 1, 1)
	if(DimSize(wRef, 0) == DimSize(wRef, 1))
		ModifyGraph width={Plan,1,top,left}, height = 0
	else
		ModifyGraph width = 0, height = 0
	endif

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
	ModifyImage $PossiblyQuoteName(NameOfWave(wRef)) ctabAutoscale=3, ctab= {ImgAvg - 3 * ImgStd, ImgAvg + 3 * ImgStd,$colorScaleStr,cmapSwitch} // Autoscale per plane / visible area Image		
	SetWindow $winNameStr, hook(AthinaMainDisplayHook) = ATH_Display#DisplayHookFunction // Set the hook	
	return 0
End

Static Function DisplayHookFunction(STRUCT WMWinHookStruct &s)
	// Fast exit if nothing is meant to be done
	//	switch (s.eventCode)
	//		case 22:	//	mouseWheel
	//			break
	//		default:
	//			return 0
	//	endswitch
	// Proceed
	Wave w = ATH_ImgOp#TopImageToWaveRef(graphName=s.winName)
	int is3D = WaveDims(w)==3
	int plane

	switch (s.eventCode)
		case 11:
			if(s.eventMod & 8)
				if(s.keycode==82)
					ATH_Range#pnl(s.winName)
					//return 1 FALLTHROUGHT to not block other hook functions
				endif
			endif
			break //
		case 22:	//	mouseWheel
			if (s.eventMod & 8)		//	if the ctrl key is pressed
				ATH_Display#Mangify(s)
				return 0
			endif

			int direction = (s.wheelDy > 0) ? 1 : -1
			if (is3D)
				STRUCT sMousePosition ms
				ATH_Display#GetMousePosition(ms, s.winName, s.mouseLoc)
				plane = ATH_Display#GetLayerIndex(s.winName, w=ms.w)
				ATH_Display#SetLayerIndex(s.winName, plane+direction, w=ms.w)
			endif
			return 0
	endswitch
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
	
	Wave w= $WMGetImageWave(iName)	// get the wave associated with the top image.	
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
	
	String/G imageName=PossiblyQuoteName(nameOfWave(w)) // EG.
	ControlInfo kwControlBar
	Variable/G gOriginalHeight= V_Height			// we append below original controls (if any)
	ControlBar gOriginalHeight+30
	
	GetWindow kwTopWin,gsize
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
					gLayer = plane
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

	ModifyImage/W=$grfName  $imageName plane=(gLayer)
	
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
		print "Operation needs an image or image stack"
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

// =======================================================================
//
//
// The following code is a modified version of SIDAM functions.
// see https://github.com/yuksk/SIDAM
//
// =======================================================================

Structure sMousePosition
	string	xaxis
	string	yaxis
	float	x
	float	y
	variable/C	z	
	float	p
	float	q
	WAVE	w
EndStructure

Structure sAxisRange
	STRUCT range x
	STRUCT range y
	STRUCT range p
	STRUCT range q
	string	xaxis
	string	yaxis
EndStructure

static Function Mangify(STRUCT WMWinHookStruct &s)
	STRUCT sMousePosition ms
	ATH_Display#GetMousePosition(ms, s.winName, s.mouseLoc)
	if (!WaveExists(ms.w))
		return 1
	endif
	//	upward -> expand
	//	downward -> shrink
	variable coef = 1 - 0.1*sign(s.wheelDy)
	GetAxis/Q/W=$s.winName $ms.xaxis
	SetAxis/W=$s.winName $ms.xaxis  ms.x+(V_min-ms.x)*coef, ms.x+(V_max-ms.x)*coef
	GetAxis/Q/W=$s.winName $ms.yaxis
	SetAxis/R/W=$s.winName $ms.yaxis  ms.y+(V_min-ms.y)*coef, ms.y+(V_max-ms.y)*coef // EG: R needed to set the axis properly when autoscale.
End

Static Structure range
	STRUCT rangesub min
	STRUCT rangesub max
EndStructure

Static Structure rangesub
	variable value
	uchar auto
EndStructure

static Function GetMousePosition(
	STRUCT sMousePosition &s,
	string grfName,
	STRUCT Point &ps,		//	e.g., WMWinHookStruct.mouseLoc
	[
		int grid
	])

	grid = ParamIsDefault(grid) ? 1 : grid
	s.xaxis = ""	; s.yaxis = ""
	s.x = NaN ;	s.y = NaN ;	s.z = NaN
	s.p = NaN ;	s.q = NaN ;
	WAVE/Z s.w = $""

	GetWaveAndValues(s,grfName,ps)
	if (!WaveExists(s.w))	//	the mouse cursor is not on any image
		return 1
	elseif (WaveExists(ImageNameToWaveRef(grfName,PossiblyQuoteName(NameOfWave(s.w)))))
		//	The following is for when s.w is a 2D/3D wave and is displayed as an image,
		//	but even when s.w is 2D/3D, it can be displayed as a trace.
		//	The above if state is to exclude the latter situation.
		//	(WaveDims(s.w) > 1 fails.)
		variable ox = DimOffset(s.w,0), oy = DimOffset(s.w,1)
		variable dx = DimDelta(s.w,0), dy = DimDelta(s.w,1)
		variable tx = limit(s.x, min(ox,ox+dx*(DimSize(s.w,0)-1)), max(ox,ox+dx*(DimSize(s.w,0)-1)))
		variable ty = limit(s.y, min(oy,oy+dy*(DimSize(s.w,1)-1)), max(oy,oy+dy*(DimSize(s.w,1)-1)))
		variable tp = (tx-ox)/dx, tq = (ty-oy)/dy
		s.p = grid ? round(tp) : tp
		s.q = grid ? round(tq) : tq
		s.x = grid ? (ox + dx * s.p) : tx
		s.y = grid ? (oy + dy * s.q) : ty
		//	the present layer, 0 for 2D images
		int layer = NumberByKey("plane", ImageInfo(grfName, NameOfWave(s.w), 0), "=")
		s.z = s.w(tx)(ty)[limit(layer,0,DimSize(s.w,2)-1)]
	endif
	return 0
End

Static Function GetWaveAndValues(STRUCT sMousePosition &ms, string grfName, STRUCT Point &ps)
	STRUCT sAxisRange as
	string listStr, itemName
	variable mousex, mousey
	variable axis_x_max, axis_x_min, axis_y_max, axis_y_min
	variable wave_x_max, wave_x_min, wave_y_max, wave_y_min
	variable ox, dx, oy, dy
	variable isInRange	//	isInRange has to be variable (not int)
	int swap = strsearch(WinRecreation(grfName,1), "swapXY", 4) != -1
	int i, isImg, nx, ny

	//	Traces are handled only when there is no image.
	listStr = ImageNameList(grfName,";")
	if (!strlen(listStr))
		listStr = TraceNameList(grfName, ";", 1)
	endif

	//	search from the top item
	for (i = ItemsInList(listStr)-1; i >= 0; i--)
		itemName = StringFromList(i,listStr)

		aGetAxis(grfName,itemName,as)

		//	When the axis is reversed, as.xmin > as.xmax and as.ymin > as.ymax
		axis_x_min = min(as.x.min.value, as.x.max.value)
		axis_x_max = max(as.x.min.value, as.x.max.value)
		axis_y_min = min(as.y.min.value, as.y.max.value)
		axis_y_max = max(as.y.min.value, as.y.max.value)

		mousex = AxisValFromPixel(grfName, as.xaxis, (swap ? ps.v : ps.h))
		mousey = AxisValFromPixel(grfName, as.yaxis, (swap ? ps.h : ps.v))

		Wave/Z w = ImageNameToWaveRef(grfName,itemName)
		isImg = WaveExists(w)

		//	When dx (dy) is negative, min and max are reversed
		if (isImg)
			ox = DimOffset(w,0)
			oy = DimOffset(w,1)
			dx = DimDelta(w,0)
			dy = DimDelta(w,1)
			nx = DimSize(w,0)
			ny = DimSize(w,1)
			wave_x_min = dx>0 ? ox-0.5*dx : ox+dx*(nx-0.5)
			wave_x_max = dx>0 ? ox+dx*(nx-0.5) : ox-0.5*dx
			wave_y_min = dy>0 ? oy-0.5*dy : oy+dy*(ny-0.5)
			wave_y_max = dy>0 ? oy+dy*(ny-0.5) : oy-0.5*dy
		endif

		isInRange = !isImg ? 1 : \
			(mousex >= max(axis_x_min, wave_x_min)) \
			& (mousex <= min(axis_x_max, wave_x_max)) \
			& (mousey >= max(axis_y_min, wave_y_min)) \
			& (mousey <= min(axis_y_max, wave_y_max))
		if (isInRange)
			ms.xaxis = as.xaxis
			ms.yaxis = as.yaxis
			ms.x = mousex
			ms.y = mousey
			if (isImg)
				Wave ms.w = w
			else
				Wave ms.w = TraceNameToWaveRef(grfName,itemName)
			endif
			return 1
		endif
	endfor
	return 0
End

static Function aGetAxis(string grfName, string tName, STRUCT sAxisRange &s)
	string info = ImageInfo(grfName, tName, 0)
	variable isImg = strlen(info)
	if (isImg)
		WAVE w = ImageNameToWaveRef(grfName, tName)
	else
		info = TraceInfo(grfName, tName, 0)
		WAVE w = TraceNameToWaveRef(grfName, tName)
	endif

	int i0, i1

	s.xaxis = StringByKey("XAXIS", info)
	GetAxis/W=$grfName/Q $s.xaxis
	s.x.min.value = V_min
	s.x.max.value = V_max
	[i0, i1] = CheckAxisAuto(grfName, s.xaxis)
	s.x.min.auto = i0
	s.x.max.auto = i1

	s.yaxis = StringByKey("YAXIS", info)
	GetAxis/W=$grfName/Q $s.yaxis
	s.y.min.value = V_min
	s.y.max.value = V_max
	[i0, i1] = CheckAxisAuto(grfName, s.yaxis)
	s.y.min.auto = i0
	s.y.max.auto = i1

	s.p.min.value = isImg ? round((s.x.min.value-DimOffset(w,0))/DimDelta(w,0)) \
		: round((s.x.min.value-leftx(w))/deltax(w))
	s.p.max.value = isImg ? round((s.x.max.value-DimOffset(w,0))/DimDelta(w,0)) \
		: round((s.x.max.value-leftx(w))/deltax(w))
	s.q.min.value = isImg ? round((s.y.min.value-DimOffset(w,1))/DimDelta(w,1)) : NaN
	s.q.max.value = isImg ? round((s.y.max.value-DimOffset(w,1))/DimDelta(w,1)) : NaN
End

static Function [int isMinAuto, int isMaxAuto] CheckAxisAuto(string grfName, string axisName)
	string infoStr = AxisInfo(grfName, axisName)
	string type = StringByKey("AXTYPE", infoStr)
	string cmdStr = StringByKey("SETAXISCMD", infoStr)
	int isAuto = strsearch(cmdStr, "/A", 0) != -1
	isMinAuto = (strsearch(cmdStr, "*,", 0) != -1) || isAuto
	isMaxAuto = (strsearch(cmdStr, ",*", 0) != -1) || isAuto
End

static Function GetLayerIndex(string grfName, [Wave/Z w])
	if (ParamIsDefault(w))
		WAVE/Z w = ATH_ImgOp#TopImageToWaveRef(graphName=grfName)
	endif
	if (!WaveExists(w) || WaveDims(w) != 3)
		return NaN
	endif
	
	return NumberByKey("plane", ImageInfo(grfName, NameOfWave(w), 0), "=")
End

Function SetLayerIndex(String grfName, int index, [Wave/Z w])
	if (ParamIsDefault(w))
		WAVE/Z w =  ATH_ImgOp#TopImageToWaveRef(graphName=grfName)
	endif
	if (!WaveExists(w) || WaveDims(w) != 3)
		return 1
	endif
	
	ModifyImage/W=$grfName $NameOfWave(w) plane=limit(round(index), 0, DimSize(w,2)-1)
	// Do not insert DoUpdate/W=$grfName here.
	// If inserted, when this function is called from a hook function, the
	// modification event of a hook function, which are expected to be called
	// by a change made by the above ModifyImage, is not called. This problem
	// occurs in Igor 8.
	return 0
End

// =======================================================================
// 
// =======================================================================

