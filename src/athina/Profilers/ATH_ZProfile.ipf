#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late
#pragma ModuleName = ATH_ZProfile
#pragma version = 1.6
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

static Function GraphMarqueeLaunchOval() // Launch directly from trace meny
	
	string winNameStr = WinName(0, 1, 1)
	string wnamestr = ATH_Graph#TopImageName(grfName=winNameStr)	
	WAVE w3dref = ImageNameToWaveRef("", wnamestr) // full path of wave

	if(WaveDims(w3dref) == 3) // if it is a 3d wave
		DFREF dfr = InitialiseFolder()
		InitialiseGraph(dfr)
		SetWindow $winNameStr hook(MyZprofileHook) = ATH_ZProfile#CursorHookFunction // Set the hook
		SetWindow $winNameStr userdata(ATH_LinkedWinImageZPP) = "ATH_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(ATH_ZProfileDFR) = GetDataFolder(1, dfr)//"root:Packages:ATH_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + winNameStr  //  Same as gATH_WindowNameStr, see ATH_InitialiseLineProfileFolder
	else
		Abort "z-profile needs a 3d wave"
	endif
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	variable errCode
	GetMarquee/K left, top; errCode = GetRTError(1);
	if(errCode)
		KillWindow $winNameStr
		ATH_Display#NewImg(w3dref)
	endif
	NVAR/SDFR=dfr gATH_left, gATH_right, gATH_top, gATH_bottom, gATH_aXlen, gATH_aYlen, gATH_Rect
	gATH_left = V_left
	gATH_right = V_right
	gATH_top = V_top
	gATH_bottom = V_bottom
	gATH_aXlen = abs(V_left-V_right)
	gATH_aYlen = abs(V_top-V_bottom)		
	gATH_Rect = 0
	SetDrawLayer/W=$winNameStr ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv/W=$winNameStr linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawOval/W=$winNameStr gATH_left, gATH_top, gATH_right, gATH_bottom
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gATH_left + gATH_right), 0.5 * (gATH_top + gATH_bottom)
	return 0
End

static Function GraphMarqueeLaunchRectangle() // Launch directly from trace meny
	
	string winNameStr = WinName(0, 1, 1)
	string wnamestr = ATH_Graph#TopImageName(grfName=winNameStr)	
	WAVE w3dref = ImageNameToWaveRef("", wnamestr) // full path of wave

	if(WaveDims(w3dref) == 3) // if it is a 3d wave
		DFREF dfr = InitialiseFolder()
		InitialiseGraph(dfr)
		DoWindow/F $winNameStr // You need to have your imange stack as a top window
		SetWindow $winNameStr hook(MyZprofileHook) = ATH_ZProfile#CursorHookFunction // Set the hook
		SetWindow $winNameStr userdata(ATH_LinkedWinImageZPP) = "ATH_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(ATH_ZProfileDFR) = GetDataFolder(1, dfr)
		SetWindow $winNameStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + winNameStr  //  Same as gATH_WindowNameStr, see InitialiseFolder
	else
		Abort "z-profile needs a 3d wave"
	endif	
	variable errCode
	GetMarquee/K left, top; errCode = GetRTError(1);
	if(errCode)
		KillWindow $winNameStr
		ATH_Display#NewImg(w3dref)
	endif
	NVAR/SDFR=dfr gATH_left, gATH_right, gATH_top, gATH_bottom, gATH_aXlen, gATH_aYlen, gATH_Rect
	gATH_left = V_left
	gATH_right = V_right
	gATH_top = V_top
	gATH_bottom = V_bottom
	gATH_aXlen = abs(V_left-V_right)
	gATH_aYlen = abs(V_top-V_bottom)		
	gATH_Rect = 1
	SetDrawLayer/W=$winNameStr ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv/W=$winNameStr linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawRect/W=$winNameStr gATH_left, gATH_top, gATH_right, gATH_bottom
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gATH_left + gATH_right), 0.5 * (gATH_top + gATH_bottom)
	return 0
End

static Function TracePopupLaunchSavedROI() // Launch directly from trace menu
	
	string winNameStr = WinName(0, 1, 1)
	string wnamestr = ATH_Graph#TopImageName(grfName=winNameStr)	
	WAVE w3dref = ImageNameToWaveRef("", wnamestr) // full path of wave
	
	DFREF dfrROI = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:SavedROI")	
	NVAR/Z/SDFR=dfrROI gATH_Sleft	
	if(!NVAR_Exists(gATH_Sleft))
		print "Cannot find a saved ROI"
		return -1
	endif
	NVAR/SDFR=dfrROI gATH_Sright, gATH_Stop, gATH_Sbottom, gATH_SrectQ
			
	if(WaveDims(w3dref) == 3) // if it is a 3d wave	
		DFREF dfr = InitialiseFolder()
		InitialiseGraph(dfr)
		DoWindow/F $winNameStr // You need to have your imange stack as a top window	
		SetWindow $winNameStr, hook(MyZprofileHook) = ATH_ZProfile#CursorHookFunction // Set the hook
		SetWindow $winNameStr userdata(ATH_LinkedWinImageZPP) = "ATH_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(ATH_ZProfileDFR) = GetDataFolder(1, dfr)
		SetWindow $winNameStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + winNameStr  //  Same as gATH_WindowNameStr, see InitialiseFolder
	else
		Abort "z-profile needs a 3d wave"
	endif	
	NVAR/SDFR=dfr gATH_left, gATH_right, gATH_top, gATH_bottom, gATH_aXlen, gATH_aYlen, gATH_Rect
	gATH_aXlen = abs(gATH_Sleft-gATH_Sright)
	gATH_aYlen = abs(gATH_Stop-gATH_Sbottom)		
	gATH_Rect = gATH_SrectQ
	gATH_left = gATH_Sleft
	gATH_right = gATH_Sright
	gATH_top = gATH_Stop
	gATH_bottom = gATH_Sbottom
	SetDrawLayer/W=$winNameStr ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv/W=$winNameStr linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawRect/W=$winNameStr gATH_left, gATH_top, gATH_right, gATH_bottom
	
	if(gATH_Rect)
		DrawRect/W=$winNameStr gATH_left, gATH_top, gATH_right, gATH_bottom
	else
		DrawOval/W=$winNameStr gATH_left, gATH_top, gATH_right, gATH_bottom
	endif
	
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gATH_left + gATH_right), 0.5 * (gATH_top + gATH_bottom)
	return 0
End

static Function/DF InitialiseFolder()
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here. Use the 3D wave in top window.

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string msg, xAxis, yAxis
	if(!strlen(imgNameTopGraphStr)) // we do not have an image in top graph
		Abort "No image in top graph. Start profile with an image stack in top window."
	endif
		
	// Initialise the Package folder
	variable nlayers = DimSize(w3dref, 2)
	variable dz = DimDelta(w3dref, 2)
    variable z0 = DimOffset(w3dref, 2)
    DFREF rootDF = $("root:Packages:ATH_DataFolder:ZBeamProfiles:")
    //string UniqueFolderNameStr = CreateDataObjectName(rootDF, winNameStr, 11, 0, 1)
    // winNameStr is unique
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ZBeamProfiles:" + winNameStr) // Root folder here
	Make/O/N=(nlayers) dfr:wZLineProfileWave /Wave = profile // Store the line profile 
	SetScale/P x, z0, dz, profile
	[xAxis, yAxis] = ATH_Graph#GetAxes(grfName=winNameStr)
	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_LineProfileWaveStr = "wZLineProfileWave" // image profile wave
	string/G dfr:gATH_LineProfileTwinWaveStr = "wZLineProfileWave" + "_Twin"// image profile wave	
	string/G dfr:gATH_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gATH_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gATH_w3dNameStr = NameOfWave(w3dref)
	string/G dfr:gATH_TwinWavePath = ""
	string/G dfr:gATH_xAxis = xAxis
	string/G dfr:gATH_yAxis = yAxis
	variable/G dfr:gATH_dx = DimDelta(w3dref, 0)
	variable/G dfr:gATH_dy = DimDelta(w3dref, 1)
	variable/G dfr:gATH_Nx = DimSize(w3dref, 0) - 1 // Last element's index X
	variable/G dfr:gATH_Ny = DimSize(w3dref, 1)	- 1 // Last element's index Y
	variable/G dfr:gATH_xOff = DimOffset(w3dref,0)
	variable/G dfr:gATH_yOff = DimOffset(w3dref,1)
	variable/G dfr:gATH_xLast = DimOffset(w3dref,0) + DimDelta(w3dref,0) * (DimSize(w3dref,0) - 1)
	variable/G dfr:gATH_yLast = DimOffset(w3dref,1) + DimDelta(w3dref,1) * (DimSize(w3dref,1) - 1)
	variable/G dfr:gATH_left = 0
	variable/G dfr:gATH_right = 0
	variable/G dfr:gATH_top = 0
	variable/G dfr:gATH_bottom = 0
	variable/G dfr:gATH_aXlen
	variable/G dfr:gATH_aYlen
	variable/G dfr:gATH_Rect
	variable/G dfr:gATH_nLayers = nlayers
	variable/G dfr:gATH_DoPlotSwitch = 1
	variable/G dfr:gATH_MarkAreasSwitch = 1
	variable/G dfr:gATH_TwinPlotSwitch = 0	
	variable/G dfr:gATH_colorcnt = 0
	return dfr
End	

static Function DrawOvalImageROI(string winNameStr, variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	// Use ATH_ZProfileDrawImageROI to draw on UserFront and then return the ProgFront (used by the hook function and ImageGenerateROIMask)
	SetDrawLayer/W=$winNameStr UserFront 
	SetDrawEnv/W=$winNameStr linefgc = (red, green, blue), fillpat = 0, linethick = 1, xcoord= top, ycoord= left
	DrawOval/W=$winNameStr left, top, right, bottom
	SetDrawLayer/W=$winNameStr ProgFront 
	return 0
End

static Function DrawRectImageROI(string winNameStr, variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	// Use ATH_ZProfileDrawImageROI to draw on UserFront and then return the ProgFront (used by the hook function and ImageGenerateROIMask)
	SetDrawLayer/W=$winNameStr UserFront 
	SetDrawEnv/W=$winNameStr linefgc = (red, green, blue), fillpat = 0, linethick = 1, xcoord= top, ycoord= left
	DrawRect/W=$winNameStr left, top, right, bottom
	SetDrawLayer/W=$winNameStr ProgFront 
	return 0
End

static Function ClearROIMarkingsUserFront(string winNameStr)
	SetDrawLayer/W=$winNameStr UserFront
	DrawAction/W=$winNameStr delete
	SetDrawLayer/W=$winNameStr ProgFront
	return 0
End

static Function InitialiseGraph(DFREF dfr)
	/// Here we will create the profile plot and graph and plot the profile
	string rootFolderStr = GetDataFolder(1, dfr)
	DFREF dfr = $(rootFolderStr)
	SVAR/SDFR=dfr gATH_LineProfileWaveStr
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/SDFR=dfr gATH_imgNameTopWindowStr
	SVAR/Z/SDFR=dfr gATH_TwinWavePath
	WAVE profile = dfr:$gATH_LineProfileWaveStr
	string profilePlotStr = "ATH_ZProfPlot_" + gATH_WindowNameStr
	if (WinType(profilePlotStr) == 0) // line profile window is not displayed
		variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
		Display/W=(0*pntConv,0*pntConv,500*pntConv,300*pntConv)/K=1/N=$profilePlotStr profile as "Z profile " + gATH_imgNameTopWindowStr
		AutoPositionWindow/E/M=0/R=$gATH_WindowNameStr
		ModifyGraph rgb=(1,12815,52428), tick(left)=2, tick(bottom)=2, fSize=12, lsize=2
		Label left "\\u#2 Intensity (arb. u.)";DelayUpdate
		Label bottom "\\u#2 Energy (eV)"
		ControlBar 40
		ModifyGraph/Z cbRGB=(65535,54611,49151)
		Button SaveProfileButton, pos={15.00,10.00},size={80.00,20.00}, proc=ATH_ZProfile#SaveProfileButton, title="Save prof.", help={"Save current profile"}, valueColor=(1,12815,52428)
		Button SetScaleZaxis, pos={105.00,10.00}, size={80.00,20.00}, proc=ATH_ZProfile#SetScaleButton, title="Set scale", help={"Set abscissas range"}, valueColor=(1,12815,52428)
		CheckBox PlotProfile, pos={195.00,12.00}, side=1, size={70.00,16.00}, proc=ATH_ZProfile#CheckboxPlotProfile,title="Plot prof.", fSize=14, value= 1
		CheckBox MarkAreas, pos={280,12.00}, side=1, size={70.00,16.00}, proc=ATH_ZProfile#CheckboxMarkAreas,title="Mark areas", fSize=14, value= 1
		CheckBox TwinWavePlot, pos={400,2.00}, side=1, size={70.00,16.00}, proc=ATH_ZProfile#CheckBoxTwinPlot,title="Twin plot", fSize=12, value= 0
		
		SetWindow $profilePlotStr userdata(ATH_rootdfrZProfileStr) = rootFolderStr // pass the dfr to the button controls
		SetWindow $profilePlotStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + gATH_WindowNameStr
		SetWindow $profilePlotStr userdata(ATH_LinkedWinImageSource) = gATH_WindowNameStr
		SetWindow $profilePlotStr, hook(MyZProfileProfileHook) = ATH_ZProfile#GraphHookFunction // Set the hook
		// Note: PopupMenu should follow SetWindow commands as the function BuildTwinWaveList() needs to get the
		// userdata(ATH_rootdfrZProfileStr) to initialise the menu 
		SetVariable SetTwinWavePath,win=$profilePlotStr,fSize=12,pos={370,20},size={120,20.00},title="TW"
		SetVariable SetTwinWavePath,value=gATH_TwinWavePath,proc=ATH_ZProfile#SetTwinWavePath
	else
		DoWindow/F $profilePlotStr // if it is bring it to the FG
		string cmdStr = GetUserData(profilePlotStr, "","ScaleZProfileCmdStr") // plot
		if(strlen(cmdStr))
			Execute/Q/Z/P  cmdStr
		endif
		cmdStr = GetUserData(profilePlotStr, "","ScaleZProfileTwinCmdStr") // Twin plot!
		if(strlen(cmdStr))
			Execute/Q/Z/P  cmdStr
		endif		
	endif
	return 0
End

static Function CursorHookFunction(STRUCT WMWinHookStruct &s)
	/// Window hook function
	variable hookResult = 0, i
	DFREF dfr = $(GetUserData(s.winName, "", "ATH_ZProfileDFR"))
	NVAR/SDFR=dfr gATH_left, gATH_right, gATH_top, gATH_bottom, gATH_dx, gATH_dy, gATH_xOff, gATH_yOff, gATH_TwinPlotSwitch
	NVAR/SDFR=dfr gATH_Nx, gATH_Ny, gATH_xLast, gATH_yLast, gATH_nLayers, gATH_Rect, gATH_aXlen, gATH_aYlen
	SVAR/Z/SDFR=dfr gATH_TwinWavePath, gATH_LineProfileWaveStr, gATH_LineProfileTwinWaveStr, gATH_xAxis, gATH_yAxis
	SVAR/Z/SDFR=dfr	gATH_WindowNameStr, gATH_w3dPath, gATH_w3dNameStr
	WAVE/Z twinWRef = $gATH_TwinWavePath // twin wave
	WAVE/SDFR=$gATH_w3dPath w3d = $gATH_w3dNameStr
	WAVE/SDFR=dfr profile = $gATH_LineProfileWaveStr // full path to wave
	WAVE/Z/SDFR=dfr profileTwin = $gATH_LineProfileTwinWaveStr	
	string w3dNameStrQ = PossiblyQuoteName(gATH_w3dNameStr) // Dealing with name1#name2 waves names
	switch(s.eventCode)
		case 2: // Kill the window
			KillWindow/Z $(GetUserData(s.winName, "", "ATH_LinkedWinImageZPP"))
			if(WinType(GetUserData(s.winName, "", "ATH_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "ATH_targetGraphWin")) $UniqueName("BeamProfile_unlnk_",6,0) // Change name of profile graph
			endif
			KillDataFolder/Z dfr
			KillWaves/Z M_ROIMask // Cleanup
			hookresult = 1
			break
		case 5: // mouse up
			if(!gATH_Rect)
				variable rs, re, cs, ce 
				SetDrawLayer/W=$gATH_WindowNameStr ProgFront // We need it for ImageGenerateROIMask			
				ImageGenerateROIMask/W=$gATH_WindowNameStr $w3dNameStrQ
				WAVE/Z M_ROIMask
				rs = (gATH_left  < gATH_xOff)   ? 0  :  ScaleToIndex(w3d, gATH_left, 0)
				re = (gATH_right > gATH_xLast) ? gATH_Nx :  ScaleToIndex(w3d, gATH_right, 0)
				cs = (gATH_bottom < gATH_yOff)  ? 0  :  ScaleToIndex(w3d, gATH_bottom, 1)
				ce = (gATH_top > gATH_yLast)   ? gATH_Ny :  ScaleToIndex(w3d, gATH_top, 1)
				MatrixOP/O/FREE partitionMask = subrange(M_ROIMask, rs, re, cs, ce)
				MatrixOP/O/NTHR=0 profile = sum(subrange(w3d, rs, re, cs, ce) * partitionMask)
				Redimension/E=1/N=(gATH_nLayers) profile
				if(gATH_TwinPlotSwitch && WaveExists(twinWRef))
					variable nlayersTW = DimSize(twinWRef, 2)
					MatrixOP/O/FREE partitionMask = subrange(M_ROIMask, rs, re, cs, ce)
					MatrixOP/O profile = sum(subrange(twinWRef, rs, re, cs, ce) * partitionMask) // Removed /NTHR=0
					Redimension/E=1/N=(nlayersTW) profileTwin
				endif				
				KillWaves/Z M_ROIMask				
				hookresult = 1
			endif
			break
		case 7: // cursor moved
			if(!cmpstr(s.CursorName,"J")) // acts only on the J cursor
				gATH_left   = gATH_xOff - gATH_aXlen * 0.5 + s.pointNumber * gATH_dx
				gATH_right  = gATH_xOff + gATH_aXlen * 0.5 + s.pointNumber * gATH_dx
				gATH_top    = gATH_yOff + gATH_aYlen * 0.5 + s.yPointNumber * gATH_dy
				gATH_bottom = gATH_yOff - gATH_aYlen * 0.5 + s.yPointNumber * gATH_dy
				rs = (gATH_left  < gATH_xOff)   ? 0  :  ScaleToIndex(w3d, gATH_left, 0)
				re = (gATH_right > gATH_xLast) ? gATH_Nx :  ScaleToIndex(w3d, gATH_right, 0)
				cs = (gATH_bottom < gATH_yOff)  ? 0  :  ScaleToIndex(w3d, gATH_bottom, 1)
				ce = (gATH_top > gATH_yLast)   ? gATH_Ny :  ScaleToIndex(w3d, gATH_top, 1)
				MatrixOP/S/O profile =sum(subrange(w3d, rs, re, cs, ce)) // Removed /NTHR=0
				Redimension/E=1/N=(gATH_nLayers) profile
				if(gATH_TwinPlotSwitch && WaveExists(twinWRef))
					nlayersTW = DimSize(twinWRef, 2)
					MatrixOP/S/O profileTwin =sum(subrange(twinWRef, rs, re, cs, ce)) // Removed /NTHR=0
					Redimension/E=1/N=(nlayersTW) profileTwin
				endif
				// Redraw ROI
				DrawAction/W=$s.winName delete
				SetDrawLayer/W=$s.winName ProgFront		
				SetDrawEnv/W=$s.winName linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = $gATH_xAxis, ycoord = $gATH_yAxis			
				if(gATH_Rect)
					DrawRect/W=$s.winName gATH_left, gATH_top, gATH_right, gATH_bottom
				else
					DrawOval/W=$s.winName gATH_left, gATH_top, gATH_right, gATH_bottom
				endif				
				hookresult = 1
				break
			endif
			hookresult = 0
			break
		case 8: // We have a Window modification event
			string plotNameStr = GetUserData(s.winName, "", "ATH_LinkedWinImageZPP")
			if(strlen(WinList(plotNameStr,";",""))) // if profile plot exists (deleted mouseTrackV < 0 condition)
				NVAR/Z glayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(gATH_WindowNameStr):gLayer
				variable linePos = DimOffset(profile, 0) + glayer * DimDelta(profile, 0)
				DrawAction/W=$plotNameStr delete
				SetDrawEnv/W=$plotNameStr xcoord= bottom, ycoord= prel,linefgc = (65535,0,0) //It should be after the draw action
				DrawLine/W=$plotNameStr linePos, 0, linePos, 1
				TextBox/W=$plotNameStr/F=0/A=LT/C/N=zScaleProfileTag "\\Z12z\Bsc\M\Z12 = " + num2str(linepos)
				hookresult = 1
				break
			endif
			hookresult = 0
			break
	endswitch
	//KillWaves/Z M_ROIMask
	return hookResult       // If non-zero, we handled event and Igor will ignore it.
End

static Function GraphHookFunction(STRUCT WMWinHookStruct &s)
	string parentGraphWin = GetUserData(s.winName, "", "ATH_LinkedWinImageSource")
	switch(s.eventCode)
		case 2: // Kill the window
			// parentGraphWin -- winNameStr
			// Kill the MyLineProfileHook
			SetWindow $parentGraphWin, hook(MyZprofileHook) = $""
			// We need to reset the link between parentGraphwin (winNameStr) and ATH_LinkedLineProfilePlotStr
			// see ATH_MainMenuLaunchLineProfile() when we test if with strlen(LinkedPlotStr)
			SetWindow $parentGraphWin userdata(ATH_LinkedWinImageZPP) = ""
			if(WinType(GetUserData(parentGraphWin, "", "ATH_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "ATH_targetGraphWin")) $UniqueName("BeamProfile_unlnk_",6,0) // Change name of profile graph
			endif
			Cursor/W=$parentGraphWin/K J
			SetDrawLayer/W=$parentGraphWin ProgFront
			DrawAction/W=$parentGraphWin delete
			Execute/P/Q/Z ("KillDataFolder/Z " + GetUserData(s.winName, "","ATH_rootdfrZProfileStr"))			
			break
	endswitch
End

static Function SaveProfileButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down" // FIX THIS
			DFREF dfr = $(GetUserData(B_Struct.win, "", "ATH_rootdfrZProfileStr"))
			string targetGraphWin = GetUserData(B_Struct.win, "", "ATH_targetGraphWin"), recreateDrawStr, recreateDrawTwinStr
			NVAR/SDFR=dfr gATH_left, gATH_right, gATH_top, gATH_bottom, gATH_Rect, gATH_TwinPlotSwitch, gATH_colorcnt, gATH_MarkAreasSwitch, gATH_DoPlotSwitch
			SVAR/SDFR=dfr gATH_w3dNameStr, gATH_w3dPathName, gATH_LineProfileWaveStr, gATH_WindowNameStr, gATH_LineProfileTwinWaveStr, gATH_TwinWavePath, gATH_xAxis, gATH_yAxis
			WAVE/Z twinWRef = $gATH_TwinWavePath // twin wave
			WAVE/SDFR=dfr profile = $gATH_LineProfileWaveStr // full path to wave
			Wave/Z/SDFR=dfr profileTwin = $gATH_LineProfileTwinWaveStr
			DFREF savedfr = GetDataFolderDFR()
			variable red, green, blue
			string saveWaveBaseNameStr = gATH_w3dNameStr + "_Zprof"
			string saveWaveNameStr = CreatedataObjectName(savedfr, saveWaveBaseNameStr, 1, 0, 5)
			Duplicate dfr:$gATH_LineProfileWaveStr, savedfr:$saveWaveNameStr // here waveRef is needed instead of $saveWaveNameStr
			if(gATH_TwinPlotSwitch && WaveExists(twinWRef))
				DFREF twdfr= GetWavesDataFolderDFR($gATH_TwinWavePath)
				string saveTwinWaveBaseNameStr = NameOfWave(twinWRef) + "_Zprof"
				string saveTwinWaveNameStr = CreatedataObjectName(twdfr, saveTwinWaveBaseNameStr, 1, 0, 5)
				Duplicate dfr:$gATH_LineProfileTwinWaveStr, twdfr:$saveTwinWaveNameStr // here waveRef is needed instead of $saveWaveNameStr
			endif
			if(gATH_DoPlotSwitch)
				if(WinType(targetGraphWin) == 1)
					AppendToGraph/W=$targetGraphWin savedfr:$saveWaveNameStr
					[red, green, blue] = ATH_Graph#GetColor(gATH_colorcnt)
					Modifygraph/W=$targetGraphWin rgb($PossiblyQuoteName(saveWaveNameStr)) = (red, green, blue)
					gATH_colorcnt += 1
				else
					Display/N=$targetGraphWin savedfr:$saveWaveNameStr // Do not kill the graph windows, user might want to save the profiles
					[red, green, blue] = ATH_Graph#GetColor(gATH_colorcnt)
					Modifygraph/W=$targetGraphWin rgb($PossiblyQuoteName(saveWaveNameStr)) = (red, green, blue)
					AutopositionWindow/M=1/R=$B_Struct.win $targetGraphWin
					DoWindow/F $targetGraphWin
					gATH_colorcnt += 1
				endif
			endif
			if(gATH_MarkAreasSwitch)
				if(!gATH_DoPlotSwitch)
					[red, green, blue] = ATH_Graph#GetColor(gATH_colorcnt)
					gATH_colorcnt += 1
				endif
				if(gATH_Rect)
					DrawRectImageROI(gATH_WindowNameStr, gATH_left, gATH_top, gATH_right, gATH_bottom, red, green, blue) // Draw on UserFront and return to ProgFront
				else
					DrawOvalImageROI(gATH_WindowNameStr, gATH_left, gATH_top, gATH_right, gATH_bottom, red, green, blue) // Draw on UserFront and return to ProgFront
				endif
			endif
			if(gATH_Rect)
				sprintf recreateDrawStr, "WaveName:%s\nWavePath:%s\nDrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= " + gATH_xAxis +", ycoord= "+gATH_yAxis+"\n" + \
				"DrawCmd:DrawRect %f, %f, %f, %f", gATH_w3dNameStr, gATH_w3dPathName, red, green, blue, gATH_left, gATH_top, gATH_right, gATH_bottom
				if(gATH_TwinPlotSwitch && WaveExists(twinWRef))
					sprintf recreateDrawTwinStr, "WaveName:%s\nWavePath:%s\nDrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= " + gATH_xAxis +", ycoord= "+gATH_yAxis+"\n" + \
					"DrawCmd:DrawRect %f, %f, %f, %f", ParseFilePath(0, gATH_TwinWavePath, ":", 1, 0) , gATH_TwinWavePath, red, green, blue, gATH_left, gATH_top, gATH_right, gATH_bottom
					Note twdfr:$saveTwinWaveNameStr, recreateDrawTwinStr
				endif
			else
				sprintf recreateDrawStr, "WaveName:%s\nWavePath:%s\nDrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= " + gATH_xAxis +", ycoord= "+gATH_yAxis+"\n" + \
				"DrawCmd:DrawOval %f, %f, %f, %f", gATH_w3dNameStr, gATH_w3dPathName, red, green, blue, gATH_left, gATH_top, gATH_right, gATH_bottom
				if(gATH_TwinPlotSwitch && WaveExists(twinWRef))
					sprintf recreateDrawTwinStr, "WaveName:%s\nWavePath:%s\nDrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= " + gATH_xAxis +", ycoord= "+gATH_yAxis+"\n" + \
					"DrawCmd:DrawOval %f, %f, %f, %f", PossiblyQuoteName(NameOfWave(twinWRef)), gATH_TwinWavePath, red, green, blue, gATH_left, gATH_top, gATH_right, gATH_bottom
					Note twdfr:$saveTwinWaveNameStr, recreateDrawTwinStr
				endif
			endif
			Note savedfr:$saveWaveNameStr, recreateDrawStr
			break
	endswitch
	return 0
End

static Function SetScaleButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			DFREF dfr = $(GetUserData(B_Struct.win, "", "ATH_rootdfrZProfileStr"))
			SVAR/Z LineProfileWaveStr = dfr:gATH_LineProfileWaveStr
			Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
			// Twin wave
			NVAR/Z TwinPlotSwitch = dfr:gATH_TwinPlotSwitch
			SVAR/Z/SDFR=dfr gATH_LineProfileTwinWaveStr
			WAVE/Z/SDFR=dfr twinprofile = $gATH_LineProfileTwinWaveStr // twin wave
			string scaleCmd, scaleTwinCmd
			string rangeZStr, sval1, separator, sval2, inputStr
			Prompt inputStr, "Set scale as \"x0 xn\" or \"x0,dx\". \nOptionally,  add a semicolon and a second pair to scale TW."
			DoPrompt "Set x-axis range (override wave's z-scale)", inputStr
			if(!V_flag && strlen(inputStr))
				rangeZstr = TrimString(StringFromList(0, inputStr), 1) // remove double+ spaces if any
				SplitString/E="\s*([-]?[0-9]*[.]?[0-9]+)\s*(\s+|\s*,)\s*([-]?[0-9]*[.]?[0-9]+)\s*" rangeZStr, sval1, separator, sval2
				if(!cmpstr(TrimString(separator), "")) // If there is one or more spaces
					SetScale/I x, str2num(sval1), str2num(sval2), profile
					scaleCmd  = "SetScale/I x,"+sval1+","+sval2 +", "
					scaleCmd += GetUserData(B_Struct.win, "", "ATH_rootdfrZProfileStr")+LineProfileWaveStr
					SetWindow $B_Struct.win userdata(ScaleZProfileCmdStr) = scaleCmd
				elseif(!cmpstr(separator, ","))
					SetScale/P x, str2num(sval1), str2num(sval2), profile
					scaleCmd  = "SetScale/P x,"+sval1+","+sval2 +", "
					scaleCmd += GetUserData(B_Struct.win, "", "ATH_rootdfrZProfileStr")+LineProfileWaveStr
					SetWindow $B_Struct.win userdata(ScaleZProfileCmdStr) = scaleCmd
				else
					print "Invalid range input"
				endif
				rangeZstr = TrimString(StringFromList(1, inputStr), 1) // remove double+ spaces if any
				if(strlen(TrimString(rangeZstr)))
					SplitString/E="\s*([-]?[0-9]*[.]?[0-9]+)\s*(\s+|\s*,)\s*([-]?[0-9]*[.]?[0-9]+)\s*" rangeZStr, sval1, separator, sval2
					if(!cmpstr(TrimString(separator), "")) // If there is one or more spaces
						SetScale/I x, str2num(sval1), str2num(sval2), twinprofile
						scaleTwinCmd  = "SetScale/I x,"+sval1+","+sval2 +", "
						scaleTwinCmd += GetUserData(B_Struct.win, "", "ATH_rootdfrZProfileStr")+gATH_LineProfileTwinWaveStr
						SetWindow $B_Struct.win userdata(ScaleZProfileTwinCmdStr) = scaleTwinCmd
					elseif(!cmpstr(separator, ","))
						SetScale/P x, str2num(sval1), str2num(sval2), twinprofile
						scaleTwinCmd  = "SetScale/P x,"+sval1+","+sval2 +", "
						scaleTwinCmd += GetUserData(B_Struct.win, "", "ATH_rootdfrZProfileStr")+gATH_LineProfileTwinWaveStr
						SetWindow $B_Struct.win userdata(ScaleZProfileTwinCmdStr) = scaleTwinCmd
					else
						print "Invalid range input"
					endif
				endif
			endif
			break
	endswitch
	return 0
End

static Function CheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = $(GetUserData(cb.win, "", "ATH_rootdfrZProfileStr"))
	NVAR/Z DoPlotSwitch = dfr:gATH_DoPlotSwitch
	switch(cb.checked)
		case 1:		// Mouse up
			DoPlotSwitch = 1
			break
		case 0:
			DoPlotSwitch = 0
			break
	endswitch
	return 0
End

static Function CheckboxMarkAreas(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = $(GetUserData(cb.win, "", "ATH_rootdfrZProfileStr"))
	NVAR/Z MarkAreasSwitch = dfr:gATH_MarkAreasSwitch
	switch(cb.checked)
		case 1:		// Mouse up
			MarkAreasSwitch = 1
			break
		case 0:
			MarkAreasSwitch = 0
			break
	endswitch
	return 0
End

static Function CheckBoxTwinPlot(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = $(GetUserData(cb.win, "", "ATH_rootdfrZProfileStr"))
	NVAR/Z TwinPlotSwitch = dfr:gATH_TwinPlotSwitch
	SVAR/Z/SDFR=dfr gATH_TwinWavePath
	WAVE/Z twinWRef = $gATH_TwinWavePath // twin wave
	SVAR/Z/SDFR=dfr gATH_LineProfileTwinWaveStr
	switch(cb.checked)
		case 1:		// Mouse up
			// Create the twinwave plot
			if(!cmpstr(gATH_TwinWavePath,"Wave Error!"))
				break
			endif
			WAVE/Z profileTwin = dfr:$gATH_LineProfileTwinWaveStr
			if(WaveExists(twinWRef))
				if(WaveExists(profileTwin))
					CheckDisplayed/W=$cb.win $gATH_LineProfileTwinWaveStr	
					if(!V_flag)
						AppendToGraph/W=$cb.win/T/R profileTwin
						ModifyGraph/W=$cb.win tick(right)=2, tick(top)=2, fSize=12, lsize=2
						Label/W=$cb.win right "\\u#2"		
					endif
				else
					Make/O/N=(DimSize(twinWRef,2)) dfr:$gATH_LineProfileTwinWaveStr	 /Wave = profileTwin // Store the line profile
					AppendToGraph/W=$cb.win/T/R profileTwin
					ModifyGraph/W=$cb.win tick(right)=2, tick(top)=2, fSize=12, lsize=2
					Label/W=$cb.win right "\\u#2"				
				endif
			else
				gATH_TwinWavePath = "Wave Error!"
				ControlUpdate/W=$cb.win SetTwinWavePath
			endif
			TwinPlotSwitch = 1
			break
		case 0:
			RemoveFromGraph/Z/W=$cb.win $gATH_LineProfileTwinWaveStr
			WAVE/Z profileTwin = dfr:$gATH_LineProfileTwinWaveStr
			KillWaves/Z profileTwin
			TwinPlotSwitch = 0
			break
	endswitch
	return 0
End


static Function SetTwinWavePath(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch (sva.eventCode)
		case 1:
		case 2:
		case 3: 							// Live update
			DFREF dfr = $(GetUserData(sva.win, "", "ATH_rootdfrZProfileStr"))
			NVAR/Z TwinPlotSwitch = dfr:gATH_TwinPlotSwitch
			NVAR/Z/SDFR=dfr gATH_Nx, gATH_Ny
			variable nx = gATH_Nx + 1
			variable ny = gATH_Ny + 1
			SVAR/Z/SDFR=dfr gATH_TwinWavePath, gATH_LineProfileTwinWaveStr
			WAVE/Z profileTwin = dfr:$gATH_LineProfileTwinWaveStr
			CheckDisplayed/W=$sva.win dfr:$gATH_LineProfileTwinWaveStr
			if(!V_flag && WaveExists(profileTwin))
				AppendToGraph/W=$sva.win/T/R profileTwin
			endif
			WAVE wRef = $sva.sval
			if(WaveExists(wRef) && (DimSize(wRef,0)==nx && DimSize(wRef,1)==ny) && WaveDims(wRef)==3)
				gATH_TwinWavePath = sva.sval
			else
				gATH_TwinWavePath = "Wave Error!"
				ControlUpdate/W=$sva.win SetTwinWavePath
			endif
			break
		case -1: 							// Control being killed
			break
	endswitch
	return 0
End
