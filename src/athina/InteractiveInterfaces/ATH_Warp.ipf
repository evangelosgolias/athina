#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9.05
#pragma ModuleName = ATH_Warp
#pragma version = 1.0

// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: egolias@protonmail.com
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

static Function WarpControl()

	string destGraphStr = WinName(0, 1, 1) // Graph with ControlBar	
	string dfrStr = "root:Packages:ATH_DataFolder:Warping:" + destGraphStr
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)

	WAVE destW = ATH_Graph#TopGraphToWaveRef()	

	DoWindow/T $destGraphStr, ("Destination: "+  NameOfWave(destW))

	SetWindow $destGraphStr userdata(destGraphStr) = destGraphStr
	SetWindow $destGraphStr userdata(WarpDFStr) = dfrStr	

	
	// Set global variables
	variable/G dfr:lastIndex = 0
	variable/G dfr:setGrid = 0
		
	variable/G dfr:gATH_gridRows = 2 // minimum allowed
	variable/G dfr:gATH_gridCols = 2
	// Save original scaling
	variable/G dfr:dx0 = Dimoffset(destw,0)
	variable/G dfr:dy0 = Dimoffset(destw,1)
	variable/G dfr:ddx = DimDelta(destw,0)
	variable/G dfr:ddy = DimDelta(destw,1)		
	// Source image
	variable/G dfr:sx0 = 0
	variable/G dfr:sy0 = 0
	variable/G dfr:sdx = 0
	variable/G dfr:sdy = 0

	string/G dfr:gATH_srcStr = ""
	string/G dfr:gATH_destStr = GetWavesDataFolder(destW,2)
	string/G dfr:gATH_srcWinStr = ""
	NVAR/SDFR=dfr gATH_gridRows, gATH_gridCols, dx0, dy0, ddx, ddy
	SetScale/P x, 0, 1, destW; 	SetScale/P y, 0, 1, destW // Change scale

	// Make a copy of the original wave
	Duplicate destW, dfr:backUpWave
		
	if(WaveType(destW) & 0x10) // If WORD (int16)
		Redimension/S destW
	endif
		
	variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
	ControlBar/W=$destGraphStr 55	

	SetVariable svRows,win=$destGraphStr,pos={90*pntConv,5*pntConv},size={90*pntConv,20*pntConv},title="Rows"
	SetVariable svRows,win=$destGraphStr,value=gATH_gridRows,fSize=14,limits={2,5,1},live=1
	SetVariable svCols,win=$destGraphStr,pos={90,28},size={90,20.00},title="Cols"
	SetVariable svCols,win=$destGraphStr,value=gATH_gridCols,fSize=14,limits={2,5,1},live=1
	
	Button SelectSourceImageB,win=$destGraphStr,title="Ref ?",pos={5*pntConv,7*pntConv},size={75*pntConv,40*pntConv},help={"Select source image"}, fColor=(65535,0,0)	
	Button SetGridsB,win=$destGraphStr,title="(Re)Set grid",pos={190*pntConv,5*pntConv},size={90*pntConv,20*pntConv},help={"Set or reset grids on source/destination images"}, valueColor=(1,12815,52428)	
	Button WarpImageB,win=$destGraphStr,title="Warp",pos={190*pntConv,28*pntConv},size={90*pntConv,20*pntConv},help={"Warped destination image"}, valueColor=(1,12815,52428)	
	Button RestoreImgsB,win=$destGraphStr,title="Restore",size={70*pntConv,20*pntConv},pos={295*pntConv,28*pntConv},valueColor=(0,0,0)
	Button DoneB,win=$destGraphStr,title="Done",fColor=(49163,65535,32768),size={44*pntConv,40*pntConv},pos={375*pntConv,8*pntConv},fColor=(32768,54615,65535),valueColor=(0,0,0)

	ModifyControlList ControlNameList(destGraphStr,";","*B"), proc=ATH_Warp#WarpButton, fsize=14*pntConv, win=$destGraphStr

	PopupMenu methodL,win=$destGraphStr,value="smooth;linear;fast", pos={295*pntConv,5*pntConv},size={70*pntConv,20*pntConv},help={"Select interpolation method"}
	PopupMenu methodL,fsize=14*pntConv,valueColor=(1,12815,52428)

	SetWindow $destGraphStr hook(WarpGridHook) = ATH_Warp#WarpGridHook
	
	DoWindow/F $destGraphStr
	return 0
End

static Function WarpGridHook(STRUCT WMWinHookStruct &s)

	variable hookResult = 0, curX,curY,flags, px,py
	DFREF dfr = $GetUserData(s.winName, "", "WarpDFStr")
	NVAR/SDFR=dfr setGrid, lastIndex, dx0,dy0,ddx,ddy,sx0,sy0,sdx,sdy
	SVAR/SDFR=dfr gATH_srcWinStr, gATH_srcWStr, gATH_destStr, gATH_srcWStr
	switch(s.eventCode)
		case 17: // not 2,
			if(!cmpstr(s.winName, gATH_srcWinStr)) // Set Info to the window and kill the other window
				string otherWinStr = GetUserData(s.winName, "", "destGraphStr")
				KillWindow/Z $gATH_srcWinStr
				KillControl/W=$otherWinStr svRows
				KillControl/W=$otherWinStr svCols
				KillControl/W=$otherWinStr SelectSourceImageB
				KillControl/W=$otherWinStr SetGridsB
				KillControl/W=$otherWinStr WarpImageB
				KillControl/W=$otherWinStr methodL
				KillControl/W=$otherWinStr RestoreImgsB
				KillControl/W=$otherWinStr DoneB
				ControlBar/W=$otherWinStr 0
				RemoveFromGraph/W=$otherWinStr/Z yd
				SetWindow $otherWinStr hook(WarpGridHook) = ATH_Warp#WarpGridHook				
			else
				KillWindow/Z $gATH_srcWinStr
				KillWindow/Z $s.winName
			endif
			WAVE/Z srcW = $gATH_srcWStr
			WAVE/Z destW = $gATH_destStr	
			SetScale/P x, dx0, ddx, destW; SetScale/P y, dy0, ddy, destW								
			SetScale/P x, sx0, sdx, srcW; SetScale/P y, sy0, sdy, srcW
			KillDataFolder/Z dfr
			break
		case 3:
			hookResult = 1
			lastIndex = -1
			break
		case 4:
			if((s.eventMod & 1) && setGrid )
				px = s.mouseLoc.h
				py = s.mouseLoc.v
				curX=AxisValFromPixel(s.winName, "top", px)
				curY=AxisValFromPixel(s.winName, "left", py)
				if(!cmpstr(s.WinName, gATH_srcWinStr))
					Wave xw = dfr:xs
					Wave yw = dfr:ys
				else
					Wave xw = dfr:xd
					Wave yw = dfr:yd
				endif
				variable rows = DimSize(xw,0)
				variable row,col
				if(lastIndex>-1)
					row = mod(lastIndex,rows)
					col = trunc(lastIndex/rows)
					yw[row][col] = curY
					xw[row][col] = curX
				else
					string info=TraceFromPixel(px,py,"")
					if(strlen(info)>0)
						lastIndex = NumberByKey("HITPOINT", info , ":")
						row = mod(lastIndex,rows)
						col = trunc(lastIndex/rows)
						yw[row][col] = curY
						xw[row][col] = curX
					else
						lastIndex = -1
					endif
				endif
				if(lastIndex>-1)
					hookResult = 1
				endif
			else
				hookResult = 0
			endif
			break
		case 5:
			lastIndex = -1
			break
	endswitch
	return hookResult		// 0 if nothing done, else 1
End

static Function WarpButton(STRUCT WMButtonAction &B_Struct)

	if (B_Struct.eventCode != 2)
		return 0
	endif
	DFREF dfr = $GetUserData(B_Struct.win, "", "WarpDFStr")
	NVAR/SDFR=dfr gATH_gridRows, gATH_gridCols, setGrid,  dx0,dy0,ddx,ddy,sx0,sy0,sdx,sdy
	SVAR/SDFR=dfr gATH_srcStr, gATH_destStr, gATH_srcWinStr
	WAVE/Z srcW = $gATH_srcStr
	WAVE/Z destW = $gATH_destStr
	WAVE/SDFR=dfr backupWave
	strswitch (B_Struct.ctrlName)
		case "SelectSourceImageB":
			string buffer0, buffer1
			[buffer0, buffer1] = ATH_Warp#SelectSourceWave(destW,B_Struct.win)
			gATH_srcStr = buffer0
			gATH_srcWinStr = buffer1
			SetWindow $gATH_srcWinStr hook(WarpGridHook) = ATH_Warp#WarpGridHook
			SetWindow $gATH_srcWinStr userdata(WarpDFStr) = GetUserData(B_Struct.win, "", "WarpDFStr")
			break
		case "SetGridsB":
			if(!strlen(gATH_srcStr))
				print "You need to set the reference (source) image"
				return 0
			endif
			DFREF currDFR = GetDataFolderDFR()
			SetDataFolder dfr
			Make/O/D/N=(gATH_gridRows,gATH_gridCols) xs,ys, xd, yd
			variable imagerows = DimSize(destW, 0)
			variable imagecols = DimSize(destW, 1)
			xs=p*imagerows/(gATH_gridRows-1)
			ys=q*imageCols/(gATH_gridCols-1)
			xd=p*imagerows/(gATH_gridRows-1)
			yd=q*imageCols/(gATH_gridCols-1)
			CheckDisplayed/W=$B_Struct.win yd
			variable dx = DimDelta(destW,0)
			variable dy = DimDelta(destW,1)
			if(V_Flag==0)
				AppendToGraph/W=$B_Struct.win /T yd vs xd
			endif
			ModifyGraph/W=$B_Struct.win mode=3,marker=0,msize=5

			CheckDisplayed/W=$gATH_srcWinStr ys
			if(V_Flag==0)
				AppendToGraph/W=$gATH_srcWinStr  /T ys vs xs
			endif
			ModifyGraph/W=$gATH_srcWinStr mode=3,marker=0,msize=5
			SetDataFolder currDFR
			setGrid = 1
			break
		case "WarpImageB":
			if(setGrid)
			WAVE/SDFR=dfr xs, ys, xd, yd, backUpWave
			ControlInfo/W=$B_Struct.win methodL
			ImageInterpolate/wm=(4-V_Value)/sgrx=xs/sgry=ys/dgrx=xd/dgry=yd warp destW
			WAVE M_InterpolatedImage
			Duplicate/O M_InterpolatedImage, destW
			KillWaves M_InterpolatedImage
			endif
			break
		case "RestoreImgsB":
			Duplicate/O dfr:backUpWave, destW
			break
		case "DoneB":
			SetWindow $B_Struct.win hook(WarpGridHook) = $""
			SetWindow $gATH_srcWinStr hook(WarpGridHook) = $""
			RemoveFromGraph/W=$B_Struct.win/Z yd
			RemoveFromGraph/W=$gATH_srcWinStr/Z ys
			KillWindow/Z $gATH_srcWinStr
			KillControl/W=$B_Struct.win svRows
			KillControl/W=$B_Struct.win svCols
			KillControl/W=$B_Struct.win SelectSourceImageB
			KillControl/W=$B_Struct.win SetGridsB
			KillControl/W=$B_Struct.win WarpImageB
			KillControl/W=$B_Struct.win methodL
			KillControl/W=$B_Struct.win RestoreImgsB
			KillControl/W=$B_Struct.win DoneB
			ControlBar/W=$B_Struct.win 0
			SetScale/P x, sx0, sdx, srcW; SetScale/P y, sy0, sdy, srcW	
			SetScale/P x, dx0, ddx, destW; SetScale/P y, dy0, ddy, destW					
			KillDataFolder/Z dfr				
			break
	endswitch
	return 0
End

static Function [string srcWStr, string srcGraphStr] SelectSourceWave(WAVE destW, string grfName)

	string msg = "Select the source wave for warping..."
	string selectedWavesInBrowserStr = ATH_Dialog#SelectWavesInModalDataBrowser(msg)
	// S_fileName is a carriage-return-separated list of full paths to one or more files.
	srcWStr = StringFromList(0, selectedWavesInBrowserStr)
	if(!strlen(srcWStr)) // User cancelled
		return ["",""]
	endif
	WAVE srcW = $srcWStr
	if(!ATH_WaveOp#WaveDimensionsEqualQ(srcW, destW))
		return ["",""]
	endif
	//Save image scaling
	DFREF dfr = $GetUserData(grfName, "", "WarpDFStr")
	variable/G dfr:sx0 = DimOffset(srcW, 0)
	variable/G dfr:sy0 = DimOffset(srcW, 1)
	variable/G dfr:sdx = DimDelta(srcW,0)
	variable/G dfr:sdy = DimDelta(srcW,1)
	string/G dfr:gATH_srcWStr = srcWStr
	SetScale/P x, 0, 1, srcW; 	SetScale/P y, 0, 1, srcW // Change scale
	Button SelectSourceImageB, fColor=(49163,65535,32768), title="Ref Set", help={srcWStr},win=$grfName
	ATH_Display#NewImg(srcW)
	srcGraphStr = WinName(0, 1, 1)
	DoWindow/T $srcGraphStr, ("Source: "+ NameOfWave(srcW))
	return [srcWStr, srcGraphStr]
End
