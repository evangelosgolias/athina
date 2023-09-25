
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

/// 25032023
/// Added to all Launchers: SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_BeamProfile_" + winNameStr
/// We have to unlink the profile plot window in case the profiler and source wave are killed. That 
/// way another launch that could associate the same Window names is not anymore possible.
/// We will use the metadata to change Window's name after the soruce/profiler are killed
/// 
/// 29032023
/// We changed the save directory to the current working directory
/// DFREF savedfr = GetDataFolderDFR() //MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:LineProfiles:SavedLineProfiles")


Function MXP_MainMenuLaunchSumBeamsProfile()

	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph."
		return -1
	endif
	
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string LinkedPlotStr = GetUserData(winNameStr, "", "MXP_LinkedSumBeamsZPlotStr")
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
		//MXP_DisplayImage(w3dRef)
		MXP_InitialiseZProfileFolder()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		MXP_InitialiseZProfileGraph(dfr)
		SetWindow $winNameStr, hook(MySumBeamsZHook) = MXP_CursorHookFunctionBeamProfile // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedSumBeamsZPlotStr) = "MXP_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(MXP_SumBeamsDFRefEF) = "root:Packages:MXP_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_BeamProfile_" + winNameStr  //  Same as gMXP_WindowNameStr, see MXP_InitialiseLineProfileFolder
	else
		Abort "z-profile needs a 3d wave."
	endif
	return 0
End

Function MXP_TraceMenuLaunchOvalSumBeamsProfile() // Launch directly from trace meny
	
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
		MXP_InitialiseZProfileFolder()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		MXP_InitialiseZProfileGraph(dfr)
		SetWindow $winNameStr, hook(MySumBeamsZHook) = MXP_CursorHookFunctionBeamProfile // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedSumBeamsZPlotStr) = "MXP_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(MXP_SumBeamsDFRefEF) = "root:Packages:MXP_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_BeamProfile_" + winNameStr  //  Same as gMXP_WindowNameStr, see MXP_InitialiseLineProfileFolder
	else
		Abort "z-profile needs a 3d wave"
	endif
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	GetMarquee/K left, top
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom
	gMXP_left = V_left
	gMXP_right = V_right
	gMXP_top = V_top
	gMXP_bottom = V_bottom
	NVAR/SDFR=dfr gMXP_aXlen
	NVAR/SDFR=dfr gMXP_aYlen
	gMXP_aXlen = abs(V_left-V_right)
	gMXP_aYlen = abs(V_top-V_bottom)		
	NVAR/SDFR=dfr gMXP_Rect
	gMXP_Rect = 0
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawOval gMXP_left, gMXP_top, gMXP_right, gMXP_bottom
	ImageGenerateROIMask $wnamestr
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gMXP_left + gMXP_right), 0.5 * (gMXP_top + gMXP_bottom)
	return 0
End

Function MXP_TraceMenuLaunchRectangleSumBeamsProfile() // Launch directly from trace meny
	
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
		MXP_InitialiseZProfileFolder()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		MXP_InitialiseZProfileGraph(dfr)
		SetWindow $winNameStr, hook(MySumBeamsZHook) = MXP_CursorHookFunctionBeamProfile // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedSumBeamsZPlotStr) = "MXP_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(MXP_SumBeamsDFRefEF) = "root:Packages:MXP_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_BeamProfile_" + winNameStr  //  Same as gMXP_WindowNameStr, see MXP_InitialiseLineProfileFolder
	else
		Abort "z-profile needs a 3d wave"
	endif	
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	GetMarquee/K left, top
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom
	gMXP_left = V_left
	gMXP_right = V_right
	gMXP_top = V_top
	gMXP_bottom = V_bottom
	NVAR/SDFR=dfr gMXP_aXlen
	NVAR/SDFR=dfr gMXP_aYlen
	gMXP_aXlen = abs(V_left-V_right)
	gMXP_aYlen = abs(V_top-V_bottom)		
	NVAR/SDFR=dfr gMXP_Rect
	gMXP_Rect = 1
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawRect gMXP_left, gMXP_top, gMXP_right, gMXP_bottom
	ImageGenerateROIMask $wnamestr
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gMXP_left + gMXP_right), 0.5 * (gMXP_top + gMXP_bottom)
	return 0
End

Function MXP_BrowserMenuLaunchSumBeamsProfile() // Browser menu launcher, active

	// Check if you have selected a single 3D wave
	if(MXP_CountSelectedWavesInDataBrowser(waveDimemsions = 3) == 1\
	 && MXP_CountSelectedWavesInDataBrowser() == 1) // If we selected a single 3D wave		
	 	string selected3DWaveStr = GetBrowserSelection(0)
		WAVE w3dRef = $selected3DWaveStr
		// When plotting waves from calculations we might have NaNs or Infs.
		// Remove them before starting and replace them with zeros
		Wavestats/M=1/Q w3dref
		if(V_numNaNs || V_numInfs)
			printf "Replaced %d NaNs and %d Infs in %s", V_numNaNs, V_numInfs, NameOfWave(w3dref)
			w3dref = (numtype(w3dref)) ? 0 : w3dref // numtype = 1, 2 for NaNs, Infs
		endif
		MXP_DisplayImage(w3dRef)
		string winNameStr = WinName(0, 1, 1)
		MXP_InitialiseZProfileFolder()
		DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + NameOfWave(w3dref)) // Change root folder if you want
		MXP_InitialiseZProfileGraph(dfr)
		SetWindow $winNameStr, hook(MySumBeamsZHook) = MXP_CursorHookFunctionBeamProfile // Set the hook
		SetWindow $winNameStr userdata(MXP_LinkedSumBeamsZPlotStr) = "MXP_ZProfPlot_" + winNameStr // Name of the plot we will make, used to send the kill signal to the plot
		SetWindow $winNameStr userdata(MXP_SumBeamsDFRefEF) = "root:Packages:MXP_DataFolder:ZBeamProfiles:" + PossiblyQuoteName(NameOfWave(w3dref))
		SetWindow $winNameStr userdata(MXP_targetGraphWin) = "MXP_BeamProfile_" + winNameStr  //  Same as gMXP_WindowNameStr, see MXP_InitialiseLineProfileFolder
	else
		Abort "Z profile opearation needs only one 3d wave."
	endif
	return 0
End

Function MXP_InitialiseZProfileFolder()
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
    
    
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + imgNameTopGraphStr) // Root folder here
	string zprofilestr = "wZLineProfileWave"
	Make/O/N=(nlayers) dfr:$zprofilestr /Wave = profile // Store the line profile 
	SetScale/P x, z0, dz, profile
	
	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_LineProfileWaveStr = zprofilestr // image profile wave
	string/G dfr:gMXP_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gMXP_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gMXP_w3dNameStr = NameOfWave(w3dref)
	variable/G dfr:gMXP_dx = DimDelta(w3dref, 0)
	variable/G dfr:gMXP_dy = DimDelta(w3dref, 1)
	variable/G dfr:gMXP_Nx = DimSize(w3dref, 0) - 1 // Last element's index X
	variable/G dfr:gMXP_Ny = DimSize(w3dref, 1)	- 1 // Last element's index Y
	variable/G dfr:gMXP_xOff = DimOffset(w3dref,0)
	variable/G dfr:gMXP_yOff = DimOffset(w3dref,1)
	variable/G dfr:gMXP_xLast = DimOffset(w3dref,0) + DimDelta(w3dref,0) * (DimSize(w3dref,0) - 1)
	variable/G dfr:gMXP_yLast = DimOffset(w3dref,1) + DimDelta(w3dref,1) * (DimSize(w3dref,1) - 1)
	variable/G dfr:gMXP_left = 0
	variable/G dfr:gMXP_right = 0
	variable/G dfr:gMXP_top = 0
	variable/G dfr:gMXP_bottom = 0
	variable/G dfr:gMXP_aXlen
	variable/G dfr:gMXP_aYlen
	variable/G dfr:gMXP_Rect
	variable/G dfr:nLayers = nlayers
	variable/G dfr:gMXP_DoPlotSwitch = 1
	variable/G dfr:gMXP_MarkAreasSwitch = 1
	variable/G dfr:gMXP_colorcnt = 0
	variable/G dfr:gMXP_mouseTrackV
	return 0
End	

//Entry point
Function MXP_DrawOvalROIAndWaitHookToAct() // Function used by the hook
	/// Here we use ProgFront to get a mask from ImageGenerateROIMask
	
	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine. No problem with name having # here.
	string winNameStr = WinName(0, 1, 1)
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	GetMarquee/K left, top
	string dfrStr = GetUserData(winNameStr, "", "MXP_SumBeamsDFRefEF")
	DFREF dfr = MXP_CreateDataFolderGetDFREF(dfrStr)
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom
	gMXP_left = V_left
	gMXP_right = V_right
	gMXP_top = V_top
	gMXP_bottom = V_bottom
	NVAR/SDFR=dfr gMXP_aXlen
	NVAR/SDFR=dfr gMXP_aYlen
	gMXP_aXlen = abs(V_left-V_right)
	gMXP_aYlen = abs(V_top-V_bottom)		
	NVAR/SDFR=dfr gMXP_Rect
	gMXP_Rect = 0
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawOval gMXP_left, gMXP_top, gMXP_right, gMXP_bottom
	ImageGenerateROIMask $wnamestr
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gMXP_left + gMXP_right), 0.5 * (gMXP_top + gMXP_bottom)
	return 0
End

//Entry point
Function MXP_DrawRectROIAndWaitHookToAct() // Function used by the hook
	/// Here we use ProgFront to get a mask from ImageGenerateROIMask
	
	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine. No problem with name having # here.
	string winNameStr = WinName(0, 1, 1)
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	GetMarquee/K left, top
	string dfrStr = GetUserData(winNameStr, "", "MXP_SumBeamsDFRefEF")
	DFREF dfr = MXP_CreateDataFolderGetDFREF(dfrStr)
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom
	gMXP_left = V_left
	gMXP_right = V_right
	gMXP_top = V_top
	gMXP_bottom = V_bottom
	NVAR/SDFR=dfr gMXP_aXlen
	NVAR/SDFR=dfr gMXP_aYlen
	gMXP_aXlen = abs(V_left-V_right)
	gMXP_aYlen = abs(V_top-V_bottom)	
	NVAR/SDFR=dfr gMXP_Rect
	gMXP_Rect = 1
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawRect gMXP_left, gMXP_top, gMXP_right, gMXP_bottom
	ImageGenerateROIMask $wnamestr
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gMXP_left + gMXP_right), 0.5 * (gMXP_top + gMXP_bottom)
	return 0
End

Function MXP_UseSavedROIAndWaitHookToAct()
	
	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine. No problem with name having # here.
	string winNameStr = WinName(0, 1, 1)
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	string dfrStr = GetUserData(winNameStr, "", "MXP_SumBeamsDFRefEF")
	DFREF dfr = MXP_CreateDataFolderGetDFREF(dfrStr)
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom
	// Read the data from the
	DFREF dfrROI = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:SavedROI")
	NVAR/Z/SDFR=dfrROI gMXP_Sleft
	if(!NVAR_Exists(gMXP_Sleft))
		Abort "No Saved ROI found!"
	endif
	NVAR/SDFR=dfrROI gMXP_Sleft
	NVAR/SDFR=dfrROI gMXP_Sright
	NVAR/SDFR=dfrROI gMXP_Stop
	NVAR/SDFR=dfrROI gMXP_Sbottom
	gMXP_left = gMXP_Sleft
	gMXP_right = gMXP_Sright
	gMXP_top = gMXP_Stop
	gMXP_bottom = gMXP_Sbottom
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawRect gMXP_left, gMXP_top, gMXP_right, gMXP_bottom
	ImageGenerateROIMask $wnamestr
	Cursor/I/C=(65535,0,0)/S=2/N=1/A=0 J $wnamestr 0.5 * (gMXP_left + gMXP_right), 0.5 * (gMXP_top + gMXP_bottom)
	return 0
	
End
Function MXP_SumBeamsDrawOvalImageROI(variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	// Use MXP_SumBeamsDrawImageROI to draw on UserFront and then return the ProgFront (used by the hook function and ImageGenerateROIMask)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 1, xcoord= top, ycoord= left
	DrawOval left, top, right, bottom
	SetDrawLayer ProgFront 
	return 0
End

Function MXP_SumBeamsDrawRectImageROI(variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	// Use MXP_SumBeamsDrawImageROI to draw on UserFront and then return the ProgFront (used by the hook function and ImageGenerateROIMask)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 1, xcoord= top, ycoord= left
	DrawRect left, top, right, bottom
	SetDrawLayer ProgFront 
	return 0
End

Function MXP_ClearROIMarkingsUserFront()
	SetDrawLayer UserFront
	DrawAction delete
	SetDrawLayer ProgFront
	return 0
End

Function MXP_InitialiseZProfileGraph(DFREF dfr)
	/// Here we will create the profile plot and graph and plot the profile
	string rootFolderStr = GetDataFolder(1, dfr)
	DFREF dfr = MXP_CreateDataFolderGetDFREF(rootFolderStr)
	SVAR/SDFR=dfr gMXP_LineProfileWaveStr
	SVAR/SDFR=dfr gMXP_WindowNameStr
	WAVE profile = dfr:$gMXP_LineProfileWaveStr

	string profilePlotStr = "MXP_ZProfPlot_" +gMXP_WindowNameStr//+ GetDataFolder(0, dfr)

	if (WinType(profilePlotStr) == 0) // line profile window is not displayed
		variable pix = 72/ScreenResolution
		Display/W=(0*pix,0*pix,500*pix,300*pix)/K=1/N=$profilePlotStr profile as "Z profile " + gMXP_WindowNameStr
		AutoPositionWindow/E/M=0/R=$gMXP_WindowNameStr
		ModifyGraph rgb=(1,12815,52428), tick(left)=2, fSize=12, lsize=1.5
		Label left "\\u#2 Intensity (arb. u.)";DelayUpdate
		Label bottom "\\u#2 Energy (eV)"
		ControlBar 40
		Button SaveProfileButton, pos={20.00,10.00}, size={90.00,20.00}, proc=MXP_SaveSumBeamsProfileButton, title="Save Profile", help={"Save current profile"}, valueColor=(1,12815,52428)
		CheckBox ShowProfile, pos={130.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_SumBeamsProfilePlotCheckboxPlotProfile,title="Plot profiles ", fSize=14, value= 1
		CheckBox ShowSelectedAread, pos={250.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_SumBeamsProfilePlotCheckboxMarkAreas,title="Mark areas ", fSize=14, value= 1

		SetWindow $profilePlotStr userdata(MXP_rootdfrSumBeamsStr) = rootFolderStr // pass the dfr to the button controls
		SetWindow $profilePlotStr userdata(MXP_targetGraphWin) = "MXP_BeamProfile_" + gMXP_WindowNameStr
		SetWindow $profilePlotStr userdata(MXP_parentGraphWin) = gMXP_WindowNameStr
		SetWindow $profilePlotStr, hook(MySumBeamsProfileHook) = MXP_SumBeamsGraphHookFunction // Set the hook
	else
		DoWindow/F $profilePlotStr // if it is bring it to the FG
	endif
	return 0
End

Function MXP_CursorHookFunctionBeamProfile(STRUCT WMWinHookStruct &s)
	/// Window hook function
	variable hookResult = 0, i
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:" + imgNameTopGraphStr) // imgNameTopGraphStr will have '' if needed.
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom
	NVAR/Z dx = dfr:gMXP_dx
	NVAR/Z dy = dfr:gMXP_dy
	NVAR/Z xOff = dfr:gMXP_xOff
	NVAR/Z yOff = dfr:gMXP_yOff
	NVAR/Z xLast = dfr:gMXP_xLast
	NVAR/Z yLast = dfr:gMXP_yLast
	NVAR/SDFR=dfr gMXP_Nx
	NVAR/SDFR=dfr gMXP_Ny
	NVAR/Z nLayers = dfr:nLayers
	NVAR/Z mouseTrackV = dfr:gMXP_mouseTrackV
	NVAR/SDFR=dfr gMXP_Rect
	NVAR/SDFR=dfr gMXP_aXlen
	NVAR/SDFR=dfr gMXP_aYlen
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
	SVAR/Z w3dPath = dfr:gMXP_w3dPath
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	DFREF wrk3dwave = $w3dPath
	Wave/SDFR=wrk3dwave w3d = $w3dNameStr
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	string w3dNameStrQ = PossiblyQuoteName(w3dNameStr) // Dealing with name1#name2 waves names
	SetDrawLayer/W=$WindowNameStr ProgFront // We need it for ImageGenerateROIMask
	variable rs, re, cs, ce // MatrixOP
	switch(s.eventCode)
		case 0: //activate window rescales the profile to the layer scale of the 3d wave
			SetScale/P x, DimOffset(w3d,2), DimDelta(w3d,2), profile // TODO: Change this, I do not like it.
			hookresult = 1
			break
		case 2: // Kill the window
			KillWindow/Z $(GetUserData(s.winName, "", "MXP_LinkedSumBeamsZPlotStr"))
			if(WinType(GetUserData(s.winName, "", "MXP_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "MXP_targetGraphWin")) $UniqueName("BeamProfile_unlnk_",6,0) // Change name of profile graph
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
			if(!gMXP_Rect && WaveExists(M_ROIMask))
				rs = (gMXP_left  < xOff)   ? 0  :  ScaleToIndex(w3d, gMXP_left, 0)
				re = (gMXP_right > xLast) ? gMXP_Nx :  ScaleToIndex(w3d, gMXP_right, 0)
				cs = (gMXP_bottom < yOff)  ? 0  :  ScaleToIndex(w3d, gMXP_bottom, 1)
				ce = (gMXP_top > yLast)   ? gMXP_Ny :  ScaleToIndex(w3d, gMXP_top, 1)
				MatrixOP/O/FREE partitionMask = subrange(M_ROIMask, rs, re, cs, ce)
				MatrixOP/O/NTHR=0 profile = sum(subrange(w3d, rs, re, cs, ce) * partitionMask)
				Redimension/E=1/N=(nLayers) profile
				hookresult = 1
			endif
			KillWaves/Z M_ROIMask
			break
		case 7: // cursor moved
			if(!cmpstr(s.CursorName,"J")) // acts only on the J cursor
				DrawAction/W=$WindowNameStr delete // TODO: Here add the env commands of MXP_SumBeamsDrawImageROICursor before switch and here only the draw command
				SetDrawEnv/W=$WindowNameStr linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
				if(gMXP_Rect)
					DrawRect/W=$WindowNameStr xOff - gMXP_aXlen * 0.5 + s.pointNumber * dx, yOff + gMXP_aYlen * 0.5 + s.yPointNumber * dy, \
					xOff + gMXP_aXlen * 0.5 + s.pointNumber * dx,  yOff - (gMXP_aYlen * 0.5) + s.yPointNumber * dy

				else
					DrawOval/W=$WindowNameStr xOff - gMXP_aXlen * 0.5 + s.pointNumber * dx, yOff + gMXP_aYlen * 0.5 + s.yPointNumber * dy, \
					xOff + gMXP_aXlen * 0.5 + s.pointNumber * dx,  yOff - (gMXP_aYlen * 0.5) + s.yPointNumber * dy
				endif
				Cursor/W=$WindowNameStr/I/C=(65535,0,0)/S=2/N=1/A=0 J $w3dNameStrQ, xOff + s.pointNumber * dx, yOff + s.yPointNumber * dy
				gMXP_left   = xOff - gMXP_aXlen * 0.5 + s.pointNumber * dx
				gMXP_right  = xOff + gMXP_aXlen * 0.5 + s.pointNumber * dx
				gMXP_top    = yOff + gMXP_aYlen * 0.5 + s.yPointNumber * dy
				gMXP_bottom = yOff - gMXP_aYlen * 0.5 + s.yPointNumber * dy
				// What if the box goes out of the image?
				rs = (gMXP_left  < xOff)   ? 0  :  ScaleToIndex(w3d, gMXP_left, 0)
				re = (gMXP_right > xLast) ? gMXP_Nx :  ScaleToIndex(w3d, gMXP_right, 0)
				cs = (gMXP_bottom < yOff)  ? 0  :  ScaleToIndex(w3d, gMXP_bottom, 1)
				ce = (gMXP_top > yLast)   ? gMXP_Ny :  ScaleToIndex(w3d, gMXP_top, 1)
				MatrixOP/O/NTHR=0 profile = sum(subrange(w3d, rs, re, cs, ce))
				Redimension/E=1/N=(nLayers) profile
				//	Debug:
				//		    		print "Left:", gMXP_left, ",Right:",gMXP_right, ",Top:", gMXP_top, ",Bottom:", gMXP_bottom
				//		    		print "HookPointX:",(s.pointNumber * dx),",HookPointY:",(s.ypointNumber * dy), ",CursorX:", hcsr(J), ",CursorY:",vcsr(J)
				//		    		print "l+r/2:", (gMXP_left + gMXP_right)/2, ",t+b/2:", (gMXP_top + gMXP_bottom)/2
				//    			print "leftP:",(gMXP_left/dx),",rightP:",(gMXP_right/dx),"topQ:",(gMXP_top/dy),",bottomQ:",(gMXP_bottom/dy)
				//		    		print "------"
				//		    		print rs,re,cs,ce
				hookresult = 1
				break
			endif
			hookresult = 0
			break
		case 8: // We have a Window modification event
			string plotNameStr = GetUserData(s.winName, "", "MXP_LinkedSumBeamsZPlotStr")
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

Function MXP_SumBeamsGraphHookFunction(STRUCT WMWinHookStruct &s)
	string parentGraphWin = GetUserData(s.winName, "", "MXP_parentGraphWin")
	switch(s.eventCode)
		case 2: // Kill the window
			// parentGraphWin -- winNameStr
			// Kill the MyLineProfileHook
			SetWindow $parentGraphWin, hook(MySumBeamsZHook) = $""
			// We need to reset the link between parentGraphwin (winNameStr) and MXP_LinkedLineProfilePlotStr
			// see MXP_MainMenuLaunchLineProfile() when we test if with strlen(LinkedPlotStr)
			SetWindow $parentGraphWin userdata(MXP_LinkedSumBeamsZPlotStr) = ""
			if(WinType(GetUserData(parentGraphWin, "", "MXP_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "MXP_targetGraphWin")) $UniqueName("BeamProfile_unlnk_",6,0) // Change name of profile graph
			endif
			Cursor/W=$parentGraphWin/K J
			SetDrawLayer/W=$parentGraphWin ProgFront
			DrawAction/W=$parentGraphWin delete
			break
	endswitch
End

Function MXP_SaveSumBeamsProfileButton(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "MXP_rootdfrSumBeamsStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "MXP_targetGraphWin")
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
	SVAR/Z w3dPathName = dfr:gMXP_w3dPathName
	Wave/SDFR=dfr profile = $LineProfileWaveStr // full path to wave
	NVAR/Z DoPlotSwitch = dfr:gMXP_DoPlotSwitch
	NVAR/Z MarkAreasSwitch = dfr:gMXP_MarkAreasSwitch
	NVAR/Z colorcnt = dfr:gMXP_colorcnt
	
	NVAR/SDFR=dfr gMXP_left
	NVAR/SDFR=dfr gMXP_right
	NVAR/SDFR=dfr gMXP_top
	NVAR/SDFR=dfr gMXP_bottom
	NVAR/SDFR=dfr gMXP_Rect
	string recreateDrawStr
	DFREF savedfr = GetDataFolderDFR() // MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:ZBeamProfiles:SavedZProfiles")
	
	variable postfix = 0
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			do
				string saveWaveNameStr = w3dNameStr + "_prof" + num2str(postfix) // deal here with liberal name
				//WAVE/Z waveRefToSave = $saveWaveNameStr // Some operation like Duplicate need a wref insted of a $("literalNameStr")
				if(WaveExists(savedfr:$saveWaveNameStr) == 1)
					postfix++
				else
					Duplicate dfr:$LineProfileWaveStr, savedfr:$saveWaveNameStr // here waveRef is needed instead of $saveWaveNameStr
					if(DoPlotSwitch)
						if(WinType(targetGraphWin) == 1)
							AppendToGraph/W=$targetGraphWin savedfr:$saveWaveNameStr
							[red, green, blue] = MXP_GetColor(colorcnt)
							Modifygraph/W=$targetGraphWin rgb($PossiblyQuoteName(saveWaveNameStr)) = (red, green, blue)
							colorcnt += 1 // i++ does not work with globals?
						else
							Display/N=$targetGraphWin savedfr:$saveWaveNameStr // Do not kill the graph windows, user might want to save the profiles
							[red, green, blue] = MXP_GetColor(colorcnt)
							Modifygraph/W=$targetGraphWin rgb($PossiblyQuoteName(saveWaveNameStr)) = (red, green, blue)
							AutopositionWindow/M=1/R=$B_Struct.win $targetGraphWin
							DoWindow/F $targetGraphWin
							colorcnt += 1
						endif
					endif
					
					if(MarkAreasSwitch)
						if(!DoPlotSwitch)
							[red, green, blue] = MXP_GetColor(colorcnt)
							colorcnt += 1
						endif
						DoWindow/F $WindowNameStr
						if(gMXP_Rect)
							MXP_SumBeamsDrawRectImageROI(gMXP_left, gMXP_top, gMXP_right, gMXP_bottom, red, green, blue) // Draw on UserFront and return to ProgFront
						else
							MXP_SumBeamsDrawOvalImageROI(gMXP_left, gMXP_top, gMXP_right, gMXP_bottom, red, green, blue) // Draw on UserFront and return to ProgFront
						endif
					endif
				break // Stop if you go through the else branch
				endif
			while(1)
			if(gMXP_Rect)
				sprintf recreateDrawStr, "pathName:%s;DrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= top, ycoord= left;" + \
								 "DrawCmd:DrawRect %f, %f, %f, %f", w3dPathName, red, green, blue, gMXP_left, gMXP_top, gMXP_right, gMXP_bottom
			else
				sprintf recreateDrawStr, "pathName:%s;DrawEnv:SetDrawEnv linefgc = (%d, %d, %d), fillpat = 0, linethick = 1, xcoord= top, ycoord= left;" + \
								 "DrawCmd:DrawOval %f, %f, %f, %f", w3dPathName, red, green, blue, gMXP_left, gMXP_top, gMXP_right, gMXP_bottom
			endif

		Note savedfr:$saveWaveNameStr, recreateDrawStr
		return 1
		break
	endswitch
	return 0
End


Function MXP_SumBeamsProfilePlotCheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(cb.win, "", "MXP_rootdfrSumBeamsStr"))
	NVAR/Z DoPlotSwitch = dfr:gMXP_DoPlotSwitch
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
