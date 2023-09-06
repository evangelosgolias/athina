#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

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

static StrConstant WMkSliderDataFolderBase = "root:Packages:WM3DImageSlider:"

Function MXP_DisplayImage(WAVE waveRef)
	// Display an image or stack
	NewImage/G=1/K=1 waveRef
	string igorInfoStr = StringByKey( "SCREEN1", IgorInfo(0)) // INFO: Change here if needed	
	igorInfoStr = RemoveListItem(0, igorInfoStr, ",")
	variable screenLeft, screenTop, screenRight, screenBottom
	sscanf igorInfoStr, "RECT=%d,%d,%d,%d", screenLeft, screenTop, screenRight, screenBottom
	variable screenWidth, screenLength
	screenWidth = abs(screenRight - screenLeft)
	screenLength = abs(screenBottom - screenTop)
	variable scaleFactor
	if(screenWidth > 3835)
		scaleFactor = 0.75
	elseif(screenWidth > 2555)
		scaleFactor = 0.5	
	elseif(screenWidth > 1915)
		scaleFactor = 0.33
	elseif(screenWidth > 1275)	
		scaleFactor = 0.25
	else
		scaleFactor = 0
	endif
	DoAutoSizeImage(scaleFactor, -1)
	// Simple solution when Dims x, y are the same
	if(DimSize(waveRef, 0) == DimSize(waveRef, 1))
		ModifyGraph width={Plan,1,top,left}, height = 0
	else
		ModifyGraph width = 0, height = 0
	endif
	
	if(WaveDims(waveRef)==3)
		MXP_Append3DImageSlider()
	endif
	return 0

	
End

Function MXP_Append3DImageSlider()
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
	
	String/G imageName=possiblyQuoteName(nameOfWave(w)) // EG.
	ControlInfo kwControlBar
	Variable/G gOriginalHeight= V_Height			// we append below original controls (if any)
	ControlBar gOriginalHeight+30

	GetWindow kwTopWin,gsize
	Variable scale = ScreenResolution / 72										// ST: 210601 - properly scale position for windows
	Variable left = V_left*scale
	Variable right = limit(V_right*scale, left+kImageSliderLMargin+50,inf)		// ST: 210601 - make sure the controls get not too small
	
	Slider WM3DAxis,pos={left+10,gOriginalHeight+10},size={right-left-kImageSliderLMargin,16},proc=MXP_3DImageSliderProc		// ST: 210601 - shift slider slightly down
	// uncomment the following line if you want do disable live updates when the slider moves.
	// Slider WM3DAxis live=0	
	Slider WM3DAxis,limits={0,gRightLim,1},value= 0,vert= 0,ticks=0,side=0,variable=gLayer	
	
	SetVariable WM3DVal,pos={right-kImageSliderLMargin+15,gOriginalHeight+6},size={60,18}	// ST: 210601 - control slightly higher to line up with the slider
	SetVariable WM3DVal,limits={0,gRightLim,1},title=" ",proc=WM3DImageSliderSetVarProc		// ST: 210601 - apply same limits as slider
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
	
	SetWindow $grfName hook(WM3Dresize)=MXP_3DImageSliderWinHook
	
	SetDataFolder dfSav
End

Function MXP_3DImageSliderWinHook(STRUCT WMWinHookStruct &s)// ST: 310601 - graph hook to resize the controls dynamically
	if(!DataFolderExists(WMkSliderDataFolderBase + s.winName))
		KillControl/W=$s.winName WM3DAxis
		KillControl/W=$s.winName WM3DVal
		KillControl/W=$s.winName WM3DDoneBtn
		DoWindow/F $s.winName
		//ControlInfo kwControlBar
		ControlBar/W=$s.winName 0		// TODO: We set ControlBar to 30, it might be something else already there, try to generalise  
		MXP_Append3DImageSlider() // Call again to create all folders and 
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
					MXP_3DImageSliderProc("",0,0)
				endif
			endif
		endif
	elseif (s.EventCode == 13)	// renamed
		// Rename the data folder containing this package's globals.
		DFREF oldDF = $(WMkSliderDataFolderBase + s.oldWinName)
		if (DataFolderRefStatus(oldDF) == 1)
			RenameDataFolder oldDF, $(s.winName)
		endif
	endif		
		
	return 0
End

Function MXP_3DImageSliderProc(string name, variable value, variable event)
	//String name			// name of this slider control
	//Variable value		// value of slider
	//Variable event		// bit field: bit 0: value set; 1: mouse down, //   2: mouse up, 3: mouse moved

	String dfSav= GetDataFolder(1)
	String grfName= WinName(0, 1)
	SetDataFolder $(WMkSliderDataFolderBase + grfName)

	NVAR gLayer
	SVAR imageName

	ModifyImage  $imageName plane=(gLayer)
	
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

Function MXP_SetImageRangeTo94Percent()

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

	GetMarquee/K left, top
	if(!V_flag)
		return 0
	endif
	MXP_CoordinatesToROIMask(V_left, V_top, V_right, V_bottom, interior = 0, exterior = 1) // Needed by ImageHistogram
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
