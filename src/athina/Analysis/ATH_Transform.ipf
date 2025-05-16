#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Transform
#pragma version = 1.01

static Function/WAVE FFT2D(WAVE wRef)
	///
	/// FFT of a 2D wave
	///
	DFREF dfr = GetWavesDataFolderDFR(wRef)
	Duplicate/FREE wref, wRefFree
	Redimension/C wRefFree 
	string  basenameStr = NameOfWave(wRef) + "_FFT"
	string destWaveNameStr = CreatedataObjectName(dfr, basenameStr, 1, 0, 1)
	//ImageFilter/N=3/P=2 gauss wRefFree
	FFT/OUT=3/DEST=$destWaveNameStr wRefFree // dfr:$destWaveNameStr doesn't work
	return $destWaveNameStr
End

Function HighAndLowScale(WAVE wRef, variable low, variable high)
    // Find min and max values of the wave
    string waveNormStr = NameOfWave(wRef)+"_scaled"
   	MatrixOP $waveNormStr = scale(wRef, low , high)
    return 0
End

Function/WAVE GetAffine2DMapping(WAVE src, WAVE dest)

	// Calculate an affine transformation that maps img0 to img1.
	// The mapping is calculated based on three points (x, y) from 
	// img0 (x) and and three img1 (X).
	// We have (X1;X2;X3;Y1;Y2;Y3) = (B, 0 ; 0, B) * (a11,a12,tx,a21,a22,ty)
	// Where B = (x1,y1,1; x2,y2,1; x3,y3,1).
	//
	// src : (x1,y1,x2,y2,x3,y3)
	// dest: (X1,Y1,X2,Y2,X3,Y3)
	//
	// res: a7 = a8 = 0 & a9 = 1
	//
	//      | a1 a2 a3 |
	//  A = | a4 a5 a6 |
    //  	| a7 a8 a9 |	
	//
	// https://stackoverflow.com/questions/1114257/transform-a-triangle-to-another-triangle
	Make/FREE srcM = {src[0],src[2],src[4],src[1],src[3],src[5]}
	Make/FREE destM = {{dest[0],dest[2],dest[4],0,0,0},{dest[1],dest[3],dest[5],0,0,0},{1,1,1,0,0,0},\
					   {0,0,0,dest[0],dest[2],dest[4]},{0,0,0,dest[1],dest[3],dest[5]},{0,0,0,1,1,1}}
	MatrixOP/FREE res = inv(destM) x srcM
	return res
	
End

// TODO: FIXME
// A quick solution for affineTransform
// It does not work well, fix it


//static Function AffineTransformationThreePoints()
//	// Launch a panel and select two images, src and dest
//	// Use cursors A, B & C to mark three points
//	// Use the affine transform to the dest wrt src image
//	// *_affine2d in created.
//	
//	
//	string msg = "Select two 2d waves (images). Use Ctrl (Windows) or Cmd (Mac)."
//	string selectedWavesInBrowserStr = ATH_Dialog#SelectWavesInModalDataBrowser(msg)
//	// S_fileName is a carriage-return-separated list of full paths to one or more files.
//	variable nrSelectedWaves = ItemsInList(selectedWavesInBrowserStr)
//	string selectedWavesStr = SortList(selectedWavesInBrowserStr, ";", 16)
//	string wave1NameStr = StringFromList(0, selectedWavesStr)
//	string wave2NameStr = StringFromList(1, selectedWavesStr)
//	if(nrSelectedWaves != 2 || WaveDims($wave1NameStr) != 2 || WaveDims($wave2NameStr) != 2)
//		DoAlert/T="athina would like you to know that you have to ..." 1, "Please " +\
//				  "select two images, i.e two 2d waves, non-RGB. \n" + \
//				  "Do you want a another chance with the browser selection?"
//		if(V_flag == 1)
//			AffineTransformationThreePoints()
//			return 0 
//		elseif(V_flag > 1)
//			Abort
//		endif
//	endif
//	
//	Prompt wave1NameStr, "src", popup, selectedWavesStr
//	Prompt wave2NameStr, "dest", popup, selectedWavesStr
//	DoPrompt "dest image will be transformed wrt to src", wave1NameStr, wave2NameStr
//	if(V_flag) // User cancelled
//		return -1
//	endif
//	
//	WAVE wImg1 =  $wave1NameStr // src
//	WAVE wImg2 = $wave2NameStr  // dest
//	string winNameStr1 = UniQueName("Affine_src", 6, 0) // T
//	string winNameStr2 = UniQueName("Affine_dest", 6, 0)	
//	ATH_Display#NewImg(wImg1, grfName = winNameStr1)
//	ATH_Display#NewImg(wImg2, grfName = winNameStr2)
//	// Transfer to the hook the dest wave
//	SetWindow $winNameStr1 userdata(destWavePathStr) = wave2NameStr
//	SetWindow $winNameStr2 userdata(destWavePathStr) = wave2NameStr	
//	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Affine2D_3pnts")
//	variable/G dfr:gATH_pntN = NaN 	
//	Make/O/N=3/D dfr:srcX, dfr:srcY; WAVE srcX = dfr:srcX; WAVE srcY = dfr:srcY
//	variable xOff = DimOffset(wImg1, 0), dx = DimDelta(wImg1, 0), xN = DimSize(wImg1, 0)
//	variable yOff = DimOffset(wImg1, 1), dy = DimDelta(wImg1, 1), yN = DimSize(wImg1, 1)
//	srcX[0] = xOff + 0.25 * xN * dx
//	srcY[0] = yOff + 0.25 * yN * dy
//	srcX[1] = xOff + 0.5 * xN * dx
//	srcY[1] = yOff + 0.5 * yN * dy
//	srcX[2] = xOff + 0.75 * xN * dx
//	srcY[2] = yOff + 0.75 * yN * dy
//	AppendToGraph/W=$winNameStr1 /T srcY vs srcX
//	ModifyGraph/W=$winNameStr1 mode=3,msize=5
//	Make/O/N=3/D dfr:destX, dfr:destY; WAVE destX = dfr:destX; WAVE destY = dfr:destY
//	xOff = DimOffset(wImg2, 0); dx = DimDelta(wImg2, 0); xN = DimSize(wImg2, 0)
//	yOff = DimOffset(wImg2, 1); dy = DimDelta(wImg2, 1); yN = DimSize(wImg2, 1)
//	SetWindow $winNameStr1,hook(DragTheMarkers) = ATH_Launch#Affine2DWindowHook // Set the hook
//	
//	destX[0] = xOff + 0.25 * xN * dx
//	destY[0] = yOff + 0.25 * yN * dy
//	destX[1] = xOff + 0.5 * xN * dx
//	destY[1] = yOff + 0.5 * yN * dy
//	destX[2] = xOff + 0.75 * xN * dx
//	destY[2] = yOff + 0.75 * yN * dy
//	AppendToGraph/W=$winNameStr2 /T destY vs destX
//	ModifyGraph/W=$winNameStr2 mode=3,msize=5,rgb=(0,65535,65535)
//	SetWindow $winNameStr2,hook(DragTheMarkers) = ATH_Launch#Affine2DWindowHook // Set the hook	
//End
//
//static Function Affine2DWindowHook(STRUCT WMWinHookStruct &s)
//	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:Affine2D_3pnts")
//	WAVE/SDFR=dfr srcX, srcY, destX, destY
//	NVAR/SDFR=dfr gATH_pntN
//	variable hookResult
//
//	switch (s.eventCode)
//		case 3:
//			gATH_pntN = str2num(StringByKey("HITPOINT",TraceFromPixel(s.mouseLoc.h,s.mouseLoc.v,""),":"))
//			hookResult = 1 // 1 here supresses long press, INTENTIONAL ... but also right click!
//			break
//		case 4:
//			if(!numtype(gATH_pntN))
//				if(StringMatch(s.winName, "Affine_src*"))
//					srcX[gATH_pntN] = AxisValFromPixel(s.winName, "top", s.mouseLoc.h)
//				 	srcY[gATH_pntN] = AxisValFromPixel(s.winName, "left", s.mouseLoc.v)
//				elseif(StringMatch(s.winName, "Affine_dest*"))
//					destX[gATH_pntN] = AxisValFromPixel(s.winName, "top", s.mouseLoc.h)
//				 	destY[gATH_pntN] = AxisValFromPixel(s.winName, "left", s.mouseLoc.v)
//				endif
//			endif
//			hookResult = 1 // 1 here supresses the marquee. INTENTIONAL
//			break
//		case 5:
//			gATH_pntN = NaN
//			break
//		case 2: // kill
//			// If you are not in a duplicate window
//			break
//	endswitch
//	
//	if(s.specialKeyCode)
//		switch(s.specialKeyCode)
//			case 200: // Enter or Return
//			case 201:
//				if(WaveExists(srcX))
//					Make/N=6/FREE scrF = {srcX[0],srcY[0],srcX[1],srcY[1],srcX[2],srcY[2]}
//					Make/N=6/FREE destF = {destX[0],destY[0],destX[1],destY[1],destX[2],destY[2]}
//					WAVE wC = ATH_Transform#GetAffine2DMapping(scrF,destF)
//					if(numtype(wC[0]))
//						break
//					endif
//				endif
//				string destWaveStr = GetUserData(s.winName, "", "destWavePathStr")
//				ImageInterpolate/APRM={wC[0],wC[1],wC[2],wC[3],wC[4],wC[5],1,0}/DEST=Affine_3pnts Affine2D $destWaveStr
//				WAVE Affine_3pnts
//				Note Affine_3pnts, "Original wave: " + destWaveStr
//				break
//		endswitch
//	endif
//	return hookResult
//End
