
#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late

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

Function ATH_MainMenuLaunchSumBeamsProfile()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph."
		return -1
	endif
	
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string LinkedPlotStr = GetUserData(winNameStr, "", "ATH_LinkedSumBeamsZPlotStr")
	if(strlen(LinkedPlotStr))
		DoWindow/F LinkedPlotStr
		return 0
	endif

	// When plotting waves from calculations we might have NaNs or Infs.
	// Remove them before starting and replace them with zeros
	Wavestats/M=1/Q w3dref
	if(V_numNaNs || V_numInfs)
		printf "Replaced %d NaNs and %d Infs in %s", V_numNaNs, V_numInfs, NameOfWave(w3dref)
		w3dref = (numtype(w3dref)) ? 0 : w3dref // numtype = 1, 2 for NaNs, Infs
	endif
	if(WaveDims(w3dref) == 3) // if it is a 3d wave
		//ATH_DisplayImage(w3dRef)
		ATH_InitialiseZProfileFolder()
		DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		ATH_InitialiseZProfileGraph(dfr)
		SetWindow $winNameStr, hook(MySumBeamsZHook) = ATH_CursorHookFunctionBeamProfile // Set the hook
		SetWindow $winNameStr userdata(ATH_LinkedSumBeamsZPlotStr) = "ATH_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(ATH_SumBeamsDFRefEF) = "root:Packages:ATH_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + winNameStr  //  Same as gATH_WindowNameStr, see ATH_InitialiseLineProfileFolder
	else
		Abort "z-profile needs a 3d wave."
	endif
	return 0
End

Function ATH_GraphMarqueeLaunchOvalSumBeamsProfile() // Launch directly from trace meny
	
	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine. No problem with name having # here.
	string winNameStr = WinName(0, 1, 1)
	WAVE w3dref = ImageNameToWaveRef("", wnamestr) // full path of wave

	if(WaveDims(w3dref) == 3) // if it is a 3d wave
		// When plotting waves from calculations we might have NaNs or Infs.
		// Remove them before starting and replace them with zeros
		Wavestats/M=1/Q w3dref
		if(V_numNaNs || V_numInfs)
			printf "Replaced %d NaNs and %d Infs in %s", V_numNaNs, V_numInfs, NameOfWave(w3dref)
			w3dref = (numtype(w3dref)) ? 0 : w3dref // numtype = 1, 2 for NaNs, Infs
		endif
		ATH_InitialiseZProfileFolder()
		DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		ATH_InitialiseZProfileGraph(dfr)
		SetWindow $winNameStr, hook(MySumBeamsZHook) = ATH_CursorHookFunctionBeamProfile // Set the hook
		SetWindow $winNameStr userdata(ATH_LinkedSumBeamsZPlotStr) = "ATH_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(ATH_SumBeamsDFRefEF) = "root:Packages:ATH_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + winNameStr  //  Same as gATH_WindowNameStr, see ATH_InitialiseLineProfileFolder
	else
		Abort "z-profile needs a 3d wave"
	endif
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	GetMarquee/K left, top
	NVAR/SDFR=dfr gATH_left
	NVAR/SDFR=dfr gATH_right
	NVAR/SDFR=dfr gATH_top
	NVAR/SDFR=dfr gATH_bottom
	gATH_left = V_left
	gATH_right = V_right
	gATH_top = V_top
	gATH_bottom = V_bottom
	NVAR/SDFR=dfr gATH_aXlen
	NVAR/SDFR=dfr gATH_aYlen
	gATH_aXlen = abs(V_left-V_right)
	gATH_aYlen = abs(V_top-V_bottom)		
	NVAR/SDFR=dfr gATH_Rect
	gATH_Rect = 0
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawOval gATH_left, gATH_top, gATH_right, gATH_bottom
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gATH_left + gATH_right), 0.5 * (gATH_top + gATH_bottom)
	return 0
End

Function ATH_GraphMarqueeLaunchRectangleSumBeamsProfile() // Launch directly from trace meny
	
	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine. No problem with name having # here.
	string winNameStr = WinName(0, 1, 1)
	WAVE w3dref = ImageNameToWaveRef("", wnamestr) // full path of wave

	if(WaveDims(w3dref) == 3) // if it is a 3d wave
		// When plotting waves from calculations we might have NaNs or Infs.
		// Remove them before starting and replace them with zeros
		Wavestats/M=1/Q w3dref
		if(V_numNaNs || V_numInfs)
			printf "Replaced %d NaNs and %d Infs in %s", V_numNaNs, V_numInfs, NameOfWave(w3dref)
			w3dref = (numtype(w3dref)) ? 0 : w3dref // numtype = 1, 2 for NaNs, Infs
		endif
		ATH_InitialiseZProfileFolder()
		DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		ATH_InitialiseZProfileGraph(dfr)
		SetWindow $winNameStr, hook(MySumBeamsZHook) = ATH_CursorHookFunctionBeamProfile // Set the hook
		SetWindow $winNameStr userdata(ATH_LinkedSumBeamsZPlotStr) = "ATH_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(ATH_SumBeamsDFRefEF) = "root:Packages:ATH_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + winNameStr  //  Same as gATH_WindowNameStr, see ATH_InitialiseLineProfileFolder
	else
		Abort "z-profile needs a 3d wave"
	endif	
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	GetMarquee/K left, top
	NVAR/SDFR=dfr gATH_left
	NVAR/SDFR=dfr gATH_right
	NVAR/SDFR=dfr gATH_top
	NVAR/SDFR=dfr gATH_bottom
	gATH_left = V_left
	gATH_right = V_right
	gATH_top = V_top
	gATH_bottom = V_bottom
	NVAR/SDFR=dfr gATH_aXlen
	NVAR/SDFR=dfr gATH_aYlen
	gATH_aXlen = abs(V_left-V_right)
	gATH_aYlen = abs(V_top-V_bottom)		
	NVAR/SDFR=dfr gATH_Rect
	gATH_Rect = 1
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawRect gATH_left, gATH_top, gATH_right, gATH_bottom
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gATH_left + gATH_right), 0.5 * (gATH_top + gATH_bottom)
	return 0
End

Function ATH_BrowserMenuLaunchSumBeamsProfile() // Browser menu launcher, active

	// Check if you have selected a single 3D wave
	if(ATH_CountSelectedWavesInDataBrowser(waveDimemsions = 3) == 1\
	 && ATH_CountSelectedWavesInDataBrowser() == 1) // If we selected a single 3D wave		
	 	string selected3DWaveStr = GetBrowserSelection(0)
		WAVE w3dRef = $selected3DWaveStr
		// When plotting waves from calculations we might have NaNs or Infs.
		// Remove them before starting and replace them with zeros
		Wavestats/M=1/Q w3dref
		if(V_numNaNs || V_numInfs)
			printf "Replaced %d NaNs and %d Infs in %s", V_numNaNs, V_numInfs, NameOfWave(w3dref)
			w3dref = (numtype(w3dref)) ? 0 : w3dref // numtype = 1, 2 for NaNs, Infs
		endif
		ATH_DisplayImage(w3dRef)
		string winNameStr = WinName(0, 1, 1)
		ATH_InitialiseZProfileFolder()
		DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		ATH_InitialiseZProfileGraph(dfr)
		SetWindow $winNameStr, hook(MySumBeamsZHook) = ATH_CursorHookFunctionBeamProfile // Set the hook
		SetWindow $winNameStr userdata(ATH_LinkedSumBeamsZPlotStr) = "ATH_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(ATH_SumBeamsDFRefEF) = "root:Packages:ATH_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + winNameStr  //  Same as gATH_WindowNameStr, see ATH_InitialiseLineProfileFolder
	else
		Abort "Z profile opearation needs only one 3d wave."
	endif
	return 0
End

Function ATH_TracePopupLaunchSavedROISumBeamsProfile() // Launch directly from trace meny
	
	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine. No problem with name having # here.
	string winNameStr = WinName(0, 1, 1)
	WAVE w3dref = ImageNameToWaveRef("", wnamestr) // full path of wave

	if(WaveDims(w3dref) == 3) // if it is a 3d wave
		// When plotting waves from calculations we might have NaNs or Infs.
		// Remove them before starting and replace them with zeros
		Wavestats/M=1/Q w3dref
		if(V_numNaNs || V_numInfs)
			printf "Replaced %d NaNs and %d Infs in %s", V_numNaNs, V_numInfs, NameOfWave(w3dref)
			w3dref = (numtype(w3dref)) ? 0 : w3dref // numtype = 1, 2 for NaNs, Infs
		endif
		ATH_InitialiseZProfileFolder()
		DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		ATH_InitialiseZProfileGraph(dfr)
		SetWindow $winNameStr, hook(MySumBeamsZHook) = ATH_CursorHookFunctionBeamProfile // Set the hook
		SetWindow $winNameStr userdata(ATH_LinkedSumBeamsZPlotStr) = "ATH_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(ATH_SumBeamsDFRefEF) = "root:Packages:ATH_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + winNameStr  //  Same as gATH_WindowNameStr, see ATH_InitialiseLineProfileFolder
	else
		Abort "z-profile needs a 3d wave"
	endif	
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	
	NVAR/SDFR=dfr gATH_left
	NVAR/SDFR=dfr gATH_right
	NVAR/SDFR=dfr gATH_top
	NVAR/SDFR=dfr gATH_bottom
	
	DFREF dfrROI = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:SavedROI")	
	NVAR/SDFR=dfrROI gATH_Sleft
	NVAR/SDFR=dfrROI gATH_Sright
	NVAR/SDFR=dfrROI gATH_Stop
	NVAR/SDFR=dfrROI gATH_Sbottom
	NVAR/SDFR=dfrROI gATH_SrectQ
	
	NVAR/SDFR=dfr gATH_aXlen
	NVAR/SDFR=dfr gATH_aYlen
	gATH_aXlen = abs(gATH_Sleft-gATH_Sright)
	gATH_aYlen = abs(gATH_Stop-gATH_Sbottom)		
	NVAR/SDFR=dfr gATH_Rect
	gATH_Rect = gATH_SrectQ
	
	gATH_left = gATH_Sleft
	gATH_right = gATH_Sright
	gATH_top = gATH_Stop
	gATH_bottom = gATH_Sbottom
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawRect gATH_left, gATH_top, gATH_right, gATH_bottom
	
	if(gATH_Rect)
		DrawRect gATH_left, gATH_top, gATH_right, gATH_bottom
	else
		DrawOval gATH_left, gATH_top, gATH_right, gATH_bottom
	endif
	
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gATH_left + gATH_right), 0.5 * (gATH_top + gATH_bottom)
	return 0
End

Function ATH_InitialiseZProfileFolder()
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here. Use the 3D wave in top window.

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string msg // Error reporting
	if(!strlen(imgNameTopGraphStr)) // we do not have an image in top graph
		Abort "No image in top graph. Start profile with an image stack in top window."
	endif
	
	if(WaveDims(w3dref) != 3)
		sprintf msg, "Z-profile works with 3d waves only.  Wave %s is in top window", imgNameTopGraphStr
		Abort msg
	endif
	
	if(stringmatch(AxisList(winNameStr),"*bottom*")) // Check if you have a NewImage left;top axes
		sprintf msg, "Reopen as Newimage %s", imgNameTopGraphStr
		KillWindow $winNameStr
		NewImage/K=1/N=$winNameStr w3dref
		ModifyGraph/W=$winNameStr width={Plan,1,top,left}
	endif
	
	WMAppend3DImageSlider() // Everything ok now, add a slider to the 3d wave
	
	// Initialise the Package folder
	variable nlayers = DimSize(w3dref, 2)
	variable dz = DimDelta(w3dref, 2)
    variable z0 = DimOffset(w3dref, 2)
    
    
	DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ZBeamProfiles:" + imgNameTopGraphStr) // Root folder here
	string zprofilestr = "wZLineProfileWave"
	Make/O/N=(nlayers) dfr:$zprofilestr /Wave = profile // Store the line profile 
	SetScale/P x, z0, dz, profile
	
	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_LineProfileWaveStr = zprofilestr // image profile wave
	string/G dfr:gATH_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gATH_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gATH_w3dNameStr = NameOfWave(w3dref)
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
	variable/G dfr:nLayers = nlayers
	variable/G dfr:gATH_DoPlotSwitch = 1
	variable/G dfr:gATH_MarkAreasSwitch = 1
	variable/G dfr:gATH_colorcnt = 0
	variable/G dfr:gATH_mouseTrackV
	return 0
End	

Function ATH_SumBeamsDrawOvalImageROI(variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	// Use ATH_SumBeamsDrawImageROI to draw on UserFront and then return the ProgFront (used by the hook function and ImageGenerateROIMask)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 1, xcoord= top, ycoord= left
	DrawOval left, top, right, bottom
	SetDrawLayer ProgFront 
	return 0
End

Function ATH_SumBeamsDrawRectImageROI(variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	// Use ATH_SumBeamsDrawImageROI to draw on UserFront and then return the ProgFront (used by the hook function and ImageGenerateROIMask)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 1, xcoord= top, ycoord= left
	DrawRect left, top, right, bottom
	SetDrawLayer ProgFront 
	return 0
End

Function ATH_ClearROIMarkingsUserFront()
	SetDrawLayer UserFront
	DrawAction delete
	SetDrawLayer ProgFront
	return 0
End

Function ATH_InitialiseZProfileGraph(DFREF dfr)
	/// Here we will create the profile plot and graph and plot the profile
	string rootFolderStr = GetDataFolder(1, dfr)
	DFREF dfr = ATH_CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/SDFR=dfr gATH_LineProfileWaveStr
	SVAR/SDFR=dfr gATH_WindowNameStr
	WAVE profile = dfr:$gATH_LineProfileWaveStr

	string profilePlotStr = "ATH_ZProfPlot_" +gATH_WindowNameStr//+ GetDataFolder(0, dfr)

	if (WinType(profilePlotStr) == 0) // line profile window is not displayed
		variable pix = 72/ScreenResolution
		Display/W=(0*pix,0*pix,500*pix,300*pix)/K=1/N=$profilePlotStr profile as "Z profile " + gATH_WindowNameStr
		AutoPositionWindow/E/M=0/R=$gATH_WindowNameStr
		ModifyGraph rgb=(1,12815,52428), tick(left)=2, fSize=12, lsize=1.5
		Label left "\\u#2 Intensity (arb. u.)";DelayUpdate
		Label bottom "\\u#2 Energy (eV)"
		ControlBar 40
		Button SaveProfileButton, pos={20.00,10.00}, size={90.00,20.00}, proc=ATH_SaveSumBeamsProfileButton, title="Save Profile", help={"Save current profile"}, valueColor=(1,12815,52428)
		Button SetScaleZaxis, pos={125.00,10.00}, size={90.00,20.00}, proc=ATH_SetScaleSumBeamsProfileButton, title="Set scale", help={"Set abscissas range"}, valueColor=(1,12815,52428)
		CheckBox ShowProfile, pos={230.00,12.00}, side=1, size={70.00,16.00}, proc=ATH_SumBeamsProfilePlotCheckboxPlotProfile,title="Plot profiles ", fSize=14, value= 1
		CheckBox ShowSelectedAread, pos={340,12.00}, side=1, size={70.00,16.00}, proc=ATH_SumBeamsProfilePlotCheckboxMarkAreas,title="Mark areas ", fSize=14, value= 1

		SetWindow $profilePlotStr userdata(ATH_rootdfrSumBeamsStr) = rootFolderStr // pass the dfr to the button controls
		SetWindow $profilePlotStr userdata(ATH_targetGraphWin) = "ATH_BeamProfile_" + gATH_WindowNameStr
		SetWindow $profilePlotStr userdata(ATH_parentGraphWin) = gATH_WindowNameStr
		SetWindow $profilePlotStr, hook(MySumBeamsProfileHook) = ATH_SumBeamsGraphHookFunction // Set the hook
	else
		DoWindow/F $profilePlotStr // if it is bring it to the FG
	endif
	return 0
End

Function ATH_CursorHookFunctionBeamProfile(STRUCT WMWinHookStruct &s)
	/// Window hook function
	variable hookResult = 0, i
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF dfr = ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ZBeamProfiles:" + imgNameTopGraphStr) // imgNameTopGraphStr will have '' if needed.
	NVAR/SDFR=dfr gATH_left
	NVAR/SDFR=dfr gATH_right
	NVAR/SDFR=dfr gATH_top
	NVAR/SDFR=dfr gATH_bottom
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy
	NVAR/Z xOff = dfr:gATH_xOff
	NVAR/Z yOff = dfr:gATH_yOff
	NVAR/Z xLast = dfr:gATH_xLast
	NVAR/Z yLast = dfr:gATH_yLast
	NVAR/SDFR=dfr gATH_Nx
	NVAR/SDFR=dfr gATH_Ny
	NVAR/Z nLayers = dfr:nLayers
	NVAR/Z mouseTrackV = dfr:gATH_mouseTrackV
	NVAR/SDFR=dfr gATH_Rect
	NVAR/SDFR=dfr gATH_aXlen
	NVAR/SDFR=dfr gATH_aYlen
	SVAR/Z LineProfileWaveStr = dfr:gATH_LineProfileWaveStr
	SVAR/Z w3dNameStr = dfr:gATH_w3dNameStr
	SVAR/Z w3dPath = dfr:gATH_w3dPath
	SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr
	DFREF wrk3dwave = $w3dPath
	Wave/SDFR=wrk3dwave w3d = $w3dNameStr
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	string w3dNameStrQ = PossiblyQuoteName(w3dNameStr) // Dealing with name1#name2 waves names
	SetDrawLayer/W=$WindowNameStr ProgFront // We need it for ImageGenerateROIMask
	variable rs, re, cs, ce // MatrixOP
	switch(s.eventCode)
		case 2: // Kill the window
			KillWindow/Z $(GetUserData(s.winName, "", "ATH_LinkedSumBeamsZPlotStr"))
			if(WinType(GetUserData(s.winName, "", "ATH_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "ATH_targetGraphWin")) $UniqueName("BeamProfile_unlnk_",6,0) // Change name of profile graph
			endif
			KillDataFolder/Z dfr
			KillWaves/Z M_ROIMask // Cleanup
			hookresult = 1
			break
		case 4:
			mouseTrackV = s.mouseLoc.v
			hookresult = 0 // Here hookresult = 1, supresses Marquee
			break
		case 5: // mouse up
			ImageGenerateROIMask/W=$WindowNameStr $w3dNameStrQ
			WAVE/Z M_ROIMask
			if(!gATH_Rect && WaveExists(M_ROIMask))
				rs = (gATH_left  < xOff)   ? 0  :  ScaleToIndex(w3d, gATH_left, 0)
				re = (gATH_right > xLast) ? gATH_Nx :  ScaleToIndex(w3d, gATH_right, 0)
				cs = (gATH_bottom < yOff)  ? 0  :  ScaleToIndex(w3d, gATH_bottom, 1)
				ce = (gATH_top > yLast)   ? gATH_Ny :  ScaleToIndex(w3d, gATH_top, 1)
				MatrixOP/O/FREE partitionMask = subrange(M_ROIMask, rs, re, cs, ce)
				MatrixOP/O/NTHR=0 profile = sum(subrange(w3d, rs, re, cs, ce) * partitionMask)
				Redimension/E=1/N=(nLayers) profile
				hookresult = 1
			endif
			KillWaves/Z M_ROIMask
			break
		case 7: // cursor moved
			if(!cmpstr(s.CursorName,"J")) // acts only on the J cursor
				DrawAction/W=$WindowNameStr delete // TODO: Here add the env commands of ATH_SumBeamsDrawImageROICursor before switch and here only the draw command
				SetDrawEnv/W=$WindowNameStr linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
				if(gATH_Rect)
					DrawRect/W=$WindowNameStr xOff - gATH_aXlen * 0.5 + s.pointNumber * dx, yOff + gATH_aYlen * 0.5 + s.yPointNumber * dy, \
					xOff + gATH_aXlen * 0.5 + s.pointNumber * dx,  yOff - (gATH_aYlen * 0.5) + s.yPointNumber * dy

				else
					DrawOval/W=$WindowNameStr xOff - gATH_aXlen * 0.5 + s.pointNumber * dx, yOff + gATH_aYlen * 0.5 + s.yPointNumber * dy, \
					xOff + gATH_aXlen * 0.5 + s.pointNumber * dx,  yOff - (gATH_aYlen * 0.5) + s.yPointNumber * dy
				endif
				Cursor/W=$WindowNameStr/I/C=(65535,0,0)/S=2/N=1/A=0 J $w3dNameStrQ, xOff + s.pointNumber * dx, yOff + s.yPointNumber * dy
				gATH_left   = xOff - gATH_aXlen * 0.5 + s.pointNumber * dx
				gATH_right  = xOff + gATH_aXlen * 0.5 + s.pointNumber * dx
				gATH_top    = yOff + gATH_aYlen * 0.5 + s.yPointNumber * dy
				gATH_bottom = yOff - gATH_aYlen * 0.5 + s.yPointNumber * dy
				// What if the box goes out of the image?
				rs = (gATH_left  < xOff)   ? 0  :  ScaleToIndex(w3d, gATH_left, 0)
				re = (gATH_right > xLast) ? gATH_Nx :  ScaleToIndex(w3d, gATH_right, 0)
				cs = (gATH_bottom < yOff)  ? 0  :  ScaleToIndex(w3d, gATH_bottom, 1)
				ce = (gATH_top > yLast)   ? gATH_Ny :  ScaleToIndex(w3d, gATH_top, 1)
				MatrixOP/S/O/NTHR=0 profile = sum(subrange(w3d, rs, re, cs, ce))
				Redimension/E=1/N=(nLayers) profile
				//	Debug:
				//		    		print "Left:", gATH_left, ",Right:",gATH_right, ",Top:", gATH_top, ",Bottom:", gATH_bottom
				//		    		print "HookPointX:",(s.pointNumber * dx),",HookPointY:",(s.ypointNumber * dy), ",CursorX:", hcsr(J), ",CursorY:",vcsr(J)
				//		    		print "l+r/2:", (gATH_left + gATH_right)/2, ",t+b/2:", (gATH_top + gATH_bottom)/2
				//    			print "leftP:",(gATH_left/dx),",rightP:",(gATH_right/dx),"topQ:",(gATH_top/dy),",bottomQ:",(gATH_bottom/dy)
				//		    		print "------"
				//		    		print rs,re,cs,ce
				hookresult = 1
				break
			endif
			hookresult = 0
			break
		case 8: // We have a Window modification event
			string plotNameStr = GetUserData(s.winName, "", "ATH_LinkedSumBeamsZPlotStr")
			if(mouseTrackV < 0 && strlen(WinList(plotNameStr,";",""))) // mouse outside image stack area and profile plot exists
				NVAR/Z glayer = root:Packages:WM3DImageSlider:$(WindowNameStr):gLayer
				variable linePos = DimOffset(profile, 0) + glayer * DimDelta(profile, 0)
				DrawAction/W=$plotNameStr delete
				SetDrawEnv/W=$plotNameStr xcoord= bottom, ycoord= prel,linefgc = (65535,0,0) //It should be after the draw action
				DrawLine/W=$plotNameStr linePos, 0, linePos, 1
				hookresult = 1
				break
			endif
			hookresult = 0
			break
	endswitch
	//KillWaves/Z M_ROIMask
	return hookResult       // If non-zero, we handled event and Igor will ignore it.
End

Function ATH_SumBeamsGraphHookFunction(STRUCT WMWinHookStruct &s)
	string parentGraphWin = GetUserData(s.winName, "", "ATH_parentGraphWin")
	switch(s.eventCode)
		case 2: // Kill the window
			// parentGraphWin -- winNameStr
			// Kill the MyLineProfileHook
			SetWindow $parentGraphWin, hook(MySumBeamsZHook) = $""
			// We need to reset the link between parentGraphwin (winNameStr) and ATH_LinkedLineProfilePlotStr
			// see ATH_MainMenuLaunchLineProfile() when we test if with strlen(LinkedPlotStr)
			SetWindow $parentGraphWin userdata(ATH_LinkedSumBeamsZPlotStr) = ""
			if(WinType(GetUserData(parentGraphWin, "", "ATH_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "ATH_targetGraphWin")) $UniqueName("BeamProfile_unlnk_",6,0) // Change name of profile graph
			endif
			Cursor/W=$parentGraphWin/K J
			SetDrawLayer/W=$parentGraphWin ProgFront
			DrawAction/W=$parentGraphWin delete
			break
	endswitch
End

Function ATH_SaveSumBeamsProfileButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = ATH_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_rootdfrSumBeamsStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "ATH_targetGraphWin")
	SVAR/Z LineProfileWaveStr = dfr:gATH_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gATH_w3dNameStr
	SVAR/Z w3dPathName = dfr:gATH_w3dPathName
	Wave/SDFR=dfr profile = $LineProfileWaveStr // full path to wave
	NVAR/Z DoPlotSwitch = dfr:gATH_DoPlotSwitch
	NVAR/Z MarkAreasSwitch = dfr:gATH_MarkAreasSwitch
	NVAR/Z colorcnt = dfr:gATH_colorcnt

	NVAR/SDFR=dfr gATH_left
	NVAR/SDFR=dfr gATH_right
	NVAR/SDFR=dfr gATH_top
	NVAR/SDFR=dfr gATH_bottom
	NVAR/SDFR=dfr gATH_Rect
	string recreateDrawStr
	DFREF savedfr = GetDataFolderDFR() // ATH_CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:ZBeamProfiles:SavedZProfiles")
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down" // FIX THIS
			string saveWaveBaseNameStr = w3dNameStr + "_Zprof"
			string saveWaveNameStr = CreatedataObjectName(savedfr, saveWaveBaseNameStr, 1, 0, 1)
			Duplicate dfr:$LineProfileWaveStr, savedfr:$saveWaveNameStr // here waveRef is needed instead of $saveWaveNameStr
			if(DoPlotSwitch)
				if(WinType(targetGraphWin) == 1)
					AppendToGraph/W=$targetGraphWin savedfr:$saveWaveNameStr
					[red, green, blue] = ATH_GetColor(colorcnt)
					Modifygraph/W=$targetGraphWin rgb($PossiblyQuoteName(saveWaveNameStr)) = (red, green, blue)
					colorcnt += 1 // i++ does not work with globals?
				else
					Display/N=$targetGraphWin savedfr:$saveWaveNameStr // Do not kill the graph windows, user might want to save the profiles
					[red, green, blue] = ATH_GetColor(colorcnt)
					Modifygraph/W=$targetGraphWin rgb($PossiblyQuoteName(saveWaveNameStr)) = (red, green, blue)
					AutopositionWindow/M=1/R=$B_Struct.win $targetGraphWin
					DoWindow/F $targetGraphWin
					colorcnt += 1
				endif
			endif

			if(MarkAreasSwitch)
				if(!DoPlotSwitch)
					[red, green, blue] = ATH_GetColor(colorcnt)
					colorcnt += 1
				endif
				DoWindow/F $WindowNameStr
				if(gATH_Rect)
					ATH_SumBeamsDrawRectImageROI(gATH_left, gATH_top, gATH_right, gATH_bottom, red, green, blue) // Draw on UserFront and return to ProgFront
				else
					ATH_SumBeamsDrawOvalImageROI(gATH_left, gATH_top, gATH_right, gATH_bottom, red, green, blue) // Draw on UserFront and return to ProgFront
				endif
			endif
			if(gATH_Rect)
				sprintf recreateDrawStr, "pathName:%s;DrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= top, ycoord= left;" + \
				"DrawCmd:DrawRect %f, %f, %f, %f", w3dPathName, red, green, blue, gATH_left, gATH_top, gATH_right, gATH_bottom
			else
				sprintf recreateDrawStr, "pathName:%s;DrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= top, ycoord= left;" + \
				"DrawCmd:DrawOval %f, %f, %f, %f", w3dPathName, red, green, blue, gATH_left, gATH_top, gATH_right, gATH_bottom
			endif

			Note savedfr:$saveWaveNameStr, recreateDrawStr
			break
	endswitch
	return 0
End

Function ATH_SetScaleSumBeamsProfileButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = ATH_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_rootdfrSumBeamsStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "ATH_targetGraphWin")
	SVAR/Z LineProfileWaveStr = dfr:gATH_LineProfileWaveStr
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			string rangeZStr, sval1, separator, sval2
			Prompt rangeZStr, "Set scale are \"x0-xn\" or \"x0,dx\""
			DoPrompt "Set x-axis range (z scale of wave does not change)", rangeZStr
			if(!V_flag && strlen(rangeZStr))
				SplitString/E="\s*([-]?[0-9]*[.]?[0-9]+)\s*(-|,)\s*([-]?[0-9]*[.]?[0-9]+)\s*" rangeZStr, sval1, separator, sval2
				if(!cmpstr(separator, "-"))
					SetScale/I x, str2num(sval1), str2num(sval2), profile
				elseif(!cmpstr(separator, ","))
					print sval1, separator, sval2
					SetScale/P x, str2num(sval1), str2num(sval2), profile
				else
					print "Invalid range input"
				endif
			endif
			break
	endswitch
	return 0
End

Function ATH_SumBeamsProfilePlotCheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = ATH_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_rootdfrSumBeamsStr"))
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
