#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late
#pragma ModuleName = ATH_iXPS
#pragma version = 2.0

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


/// NOTE: the program needs E to be at the lower part of the KE of the dispersion.
/// Line profile is extracted from E -> F cursor. Also set the G - Low KE and H - High KE end.
/// With microscope settings for September 2024 high KE in on the bottomn right part of the image.

static constant kATHEnergyPerPixel =   0.00558659 // energy per pixel - default setting 02.09.2024 [2K image]


static Function MainMenu()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph."
		return -1
	endif
	WAVE imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string LinkedPlotStr = GetUserData(winNameStr, "", "ATH_LinkedWiniXPSPP")
	if(strlen(LinkedPlotStr))
		DoWindow/F LinkedPlotStr
		return 0
	endif
	DFREF dfr = InitialiseFolder(winNameStr)
	variable nrows = DimSize(imgWaveRef,0)
	variable ncols = DimSize(imgWaveRef,1)
	// Cursors to set the scale
	Cursor/I/C=(0,65535,0, 30000)/H=1/S=1/P/N=1 G $imgNameTopGraphStr round(0.4 * nrows/2), round(0.4 * ncols/2)	
	Cursor/I/C=(0,65535,0, 65535)/H=1/S=1/P/N=1 H $imgNameTopGraphStr round(1.6 * nrows/2), round(1.6 * ncols/2)	
	// Cursors to get the profile
	Cursor/I/C=(65535,0,0)/S=1/P/N=1 E $imgNameTopGraphStr round(0.6 * nrows/2), round(0.6 * ncols/2)
	Cursor/I/C=(1,16019,65535)/S=1/P/N=1 F $imgNameTopGraphStr round(1.4 * nrows/2), round(1.4 * ncols/2)	
	InitialiseGraph(dfr)
	SetWindow $winNameStr, hook(MyiXPSHook) = ATH_iXPS#CursorHookFunction // Set the hook
	SetWindow $winNameStr userdata(ATH_LinkedWiniXPSPP) = "ATH_XPSProfPlot_" + winNameStr
	SetWindow $winNameStr userdata(ATH_targetGraphWin) = "ATH_XPSProf_" + winNameStr 
	SetWindow $winNameStr userdata(ATH_iXPSRootDF) = GetDataFolder(1, dfr)	
	return 0
End

static Function/DF InitialiseFolder(string winNameStr)
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here. Use the 3D wave in top window.

	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE imgWaveRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	string msg // Error reporting
	if(!strlen(imgNameTopGraphStr)) // we do not have an image in top graph
		Abort "No image in top graph. Start the XPS extractor with an image or image stack in top window."
	endif
	
	if(WaveDims(imgWaveRef) != 2 && WaveDims(imgWaveRef) != 3)
		sprintf msg, "XPS extractor works with images or image stacks.  Wave %s is in top window", imgNameTopGraphStr
		Abort msg
	endif
	
	if(stringmatch(AxisList(winNameStr),"*bottom*")) // Check if you have a NewImage left;top axes
		sprintf msg, "Reopen as Newimage %s", imgNameTopGraphStr
		KillWindow $winNameStr
		NewImage/K=1/N=$winNameStr imgWaveRef
		ModifyGraph/W=$winNameStr width={Plan,1,top,left}
	endif
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iXPS:" + winNameStr) // Root folder here
	DFREF dfr0 = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iXPS:DefaultSettings:") // Settings here

	variable nrows = DimSize(imgWaveRef,0)
	variable ncols = DimSize(imgWaveRef,1)

	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_ImagePathname = GetWavesDataFolder(imgWaveRef, 2)
	string/G dfr:gATH_ImagePath = GetWavesDataFolder(imgWaveRef, 1)
	string/G dfr:gATH_ImageNameStr = NameOfWave(imgWaveRef)
	variable/G dfr:gATH_dx = DimDelta(imgWaveRef,0)
	variable/G dfr:gATH_dy = DimDelta(imgWaveRef,1)
	variable/G dfr:gATH_C1x = round(1.1 * nrows/2)
	variable/G dfr:gATH_C1y = round(0.9 * ncols/2)
	variable/G dfr:gATH_C2x = round(0.9 * nrows/2)
	variable/G dfr:gATH_C2y = round(1.1 * ncols/2)
	variable/G dfr:gATH_profileWidth = 0
	variable/G dfr:gATH_selectedLayer = 0
	variable/G dfr:gATH_updateSelectedLayer = 0
	variable/G dfr:gATH_updateCursorsPositions = 0
	// XPS scaling values
	variable/G dfr:gATH_hv = ATH_String#GetPhotonEnergyFromFilename(imgNameTopGraphStr)
	variable/G dfr:gATH_Wf = 4.27
	variable/G dfr:gATH_epp = kATHEnergyPerPixel
	variable/G dfr:gATH_Gx = 0
	variable/G dfr:gATH_Gy = 0	
	variable/G dfr:gATH_Hx = 0
	variable/G dfr:gATH_Hy = 0
	variable stv_ = NumberByKey("STV(V)",note(imgWaveRef),":","\n" ) // Start voltage from metadata
	variable/G dfr:gATH_STV = numtype(stv_) ? 0 : stv_
	variable/G dfr:gATH_Eoffset = 0
	variable/G dfr:gATH_linepx
	variable/G dfr:gATH_lowBE // bottom left part is the low BE.
	
	// Switches and indicators
	variable/G dfr:gATH_PlotSwitch = 1
	variable/G dfr:gATH_UseBELineSwitch = 0
	variable/G dfr:gATH_SelectLayer = 0
	variable/G dfr:gATH_colorcnt = 0
	variable/G dfr:gATH_CursorGHSwitch = 0 // Have you set the cursors ?=
	// Default settings
	NVAR/Z/SDFR=dfr0 gATH_profileWidth0
	if(!NVAR_Exists(gATH_profileWidth0)) // init only once and do not overwrite
		variable/G dfr0:gATH_C1x0 = round(1.1 * nrows/2)
		variable/G dfr0:gATH_C1y0 = round(0.9 * ncols/2)
		variable/G dfr0:gATH_C2x0 = round(0.9 * nrows/2)
		variable/G dfr0:gATH_C2y0 = round(1.1 * ncols/2)
		variable/G dfr0:gATH_profileWidth0 = 0
		variable/G dfr0:gATH_linepx0 = 0		
		variable/G dfr0:gATH_Gx0 = 0
		variable/G dfr0:gATH_Gy0 = 0
		variable/G dfr0:gATH_Hx0 = 0
		variable/G dfr0:gATH_Hy0 = 0
		variable/G dfr0:gATH_epp0 = 0
		variable/G dfr0:gATH_Wf0 = 0
	endif
	return dfr
End

static Function InitialiseGraph(DFREF dfr)
	/// Here we will create the profile plot and graph and plot the profile
	string plotNameStr = "ATH_XPSProf_" + GetDataFolder(0, dfr)
	if (WinType(plotNameStr) == 0) // XPS profile window is not displayed
		XPSPlot(dfr)
	else
		DoWindow/F $plotNameStr // if it is bring it to the FG
	endif
	return 0
End

static Function XPSPlot(DFREF dfr)
	string rootFolderStr = GetDataFolder(1, dfr)
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/SDFR=dfr gATH_ImagePathname
	NVAR profileWidth = dfr:gATH_profileWidth
	NVAR hv = dfr:gATH_hv
	NVAR Wf = dfr:gATH_Wf
	NVAR epp = dfr:gATH_epp
	NVAR stv = dfr:gATH_STV
	NVAR/Z UseBESwitch = dfr:gATH_UseBELineSwitch	
	NVAR/Z CursorGHSwitch = dfr:gATH_CursorGHSwitch	
	string profilePlotStr = "ATH_XPSProfPlot_" + gATH_WindowNameStr
	Make/O/N=0  dfr:W_ImageLineProfile // Make a dummy wave to display 
	variable pix = 72/ScreenResolution
	Display/W=(0*pix,0*pix,520*pix,300*pix)/K=1/N=$profilePlotStr dfr:W_ImageLineProfile as "XPS spectrum " + gATH_ImagePathname
	AutoPositionWindow/E/M=0/R=$gATH_WindowNameStr
	ModifyGraph rgb=(1,12815,52428), tick(left)=2, tick(bottom)=2, fSize=12, lsize=1.5
	Label left "Intensity (arb. u.)"
	if(UseBESwitch)
		Label/W=$profilePlotStr bottom "\\u#2Binding Energy (eV)[E --> F]"
	else
		Label/W=$profilePlotStr bottom "\\u#2Kinetic Energy (eV)[E --> F]"
	endif
	
	SetWindow $profilePlotStr userdata(ATH_rootdfrStr) = rootFolderStr // pass the dfr to the button controls
	SetWindow $profilePlotStr userdata(ATH_targetGraphWin) = "ATH_XPSProf_" + gATH_WindowNameStr 
	SetWindow $profilePlotStr userdata(ATH_parentGraphWin) = gATH_WindowNameStr 
	SetWindow $profilePlotStr, hook(MyiXPSGraphHook) = ATH_iXPS#GraphHookFunction // Set the hook
	
	ControlBar 100
	
	// Let's set SaveProfileButton to red if nothing is set or green otherwise
	DFREF dfr0 = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iXPS:DefaultSettings:") // Settings here
	NVAR epp0 = dfr0:gATH_epp0
	
	if(epp0)
		Button SaveCursorPositions, fColor=(2,39321,1)
	else
		Button SaveCursorPositions, fColor=(65535,0,0)
	endif
	
	Button SaveProfileButton,pos={18.00,8.00},size={90.00,20.00},title="Save Profile",valueColor=(1,12815,52428),help={"Save current profile"},proc=ATH_iXPS#SaveProfile, win=$profilePlotStr
	Button SaveCursorPositions,pos={118.00,8.00},size={95.00,20.00},title="Save settings",valueColor=(1,12815,52428),help={"Save cursor positions and profile width as defaults"},proc=ATH_iXPS#SaveDefaultSettings, win=$profilePlotStr
	Button RestoreCursorPositions,pos={224.00,8.00},size={111.00,20.00},valueColor=(1,12815,52428),title="Restore settings",help={"Restore default cursor positions and line width"},proc=ATH_iXPS#RestoreDefaultSettings, win=$profilePlotStr
	Button ShowProfileWidth,valueColor=(1,12815,52428), pos={344.00,8.00},size={111.00,20.00},title="Show width",help={"Shows width of integrated area while button is pressed"},proc=ATH_iXPS#ShowProfileWidth, win=$profilePlotStr
	Button SetCursorsGH,valueColor=(1,12815,52428), pos={462,17},size={50,70.00},title="Set\nCsr\nG & H",fcolor=(65535,0,0),win=$profilePlotStr
	Button SetCursorsGH,help={"Set cursors G (top right), H (lower left) and press button to calibrate the energy scale"},proc=ATH_iXPS#SetCursorsGH, win=$profilePlotStr
	CheckBox PlotProfiles,pos={19.00,40.00},size={98.00,17.00},title="Plot profiles ",fSize=14,value=1,side=1,proc=ATH_iXPS#PlotProfile, win=$profilePlotStr
	CheckBox UseBE,pos={127.00,40.00},size={86.00,17.00},title="Show BE ",fSize=14,value=0,side=1,proc=ATH_iXPS#UseBE, win=$profilePlotStr
	CheckBox ProfileLayer3D,pos={227.00,40.00},size={86.00,17.00},title="Stack layer ",fSize=14,side=1,proc=ATH_iXPS#Layer3D, win=$profilePlotStr
	SetVariable setWidth,pos={331.00,40.00},size={123.00,20.00},title="Width", fSize=14,fColor=(1,39321,19939),value=profileWidth,limits={0,inf,1},help={"sampling points: 2*width+1 pixels."},proc=ATH_iXPS#SetProfileWidth, win=$profilePlotStr
	SetVariable setSTV,pos={20,72.00},size={100,20.00},title="STV", fSize=14,fColor=(0,0,65535),value=stv,limits={0,inf,1},proc=ATH_iXPS#SetSTV, win=$profilePlotStr
	SetVariable sethv,pos={135,72.00},size={90,20.00},title="hv", fSize=14,fColor=(65535,0,0),value=hv,limits={0,inf,1},proc=ATH_iXPS#Sethv, win=$profilePlotStr
	SetVariable setWf,pos={235,72.00},size={90,20.00},title="Wf", fSize=14,fColor=(1,39321,19939),value=Wf,limits={0,inf,0.1},proc=ATH_iXPS#SetWf, win=$profilePlotStr
	SetVariable setEPP,pos={335,72.00},size={118,20.00},title="EPP", fSize=14,fColor=(0,0,65535),value=epp,limits={0,10,0.01},proc=ATH_iXPS#SetEPP, win=$profilePlotStr // Energy per pixel
	
	if(!epp0)
		Button RestoreCursorPositions, disable = 2, win=$profilePlotStr
	endif
	
	if(!CursorGHSwitch)
		Button SaveCursorPositions, disable = 2, win=$profilePlotStr
	endif
	
	return 0
End

static Function ClearXPSMarkings()
	SetDrawLayer UserFront
	DrawAction delete
	SetDrawLayer ProgFront
	return 0
End

static Function CursorHookFunction(STRUCT WMWinHookStruct &s)
	/// Window hook function
	/// The XPS profile is plotted from E to F
	variable hookResult = 0
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(s.WinName, ";"),";")
	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iXPSRootDF"))
	DFREF dfr0 = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iXPS:DefaultSettings") // Settings here
	SetdataFolder dfr
	SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr
	SVAR/Z ImagePathname = dfr:gATH_ImagePathname
	SVAR/Z ImagePath = dfr:gATH_ImagePath
	SVAR/Z ImageNameStr = dfr:gATH_ImageNameStr
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z Gx = dfr:gATH_Gx
	NVAR/Z Gy = dfr:gATH_Gy
	NVAR/Z Hx = dfr:gATH_Hx
	NVAR/Z Hy = dfr:gATH_Hy
	NVAR/Z linepx = dfr:gATH_linepx
	NVAR/Z epp = dfr:gATH_epp
	NVAR/Z stv = dfr:gATH_stv
	NVAR/Z Wf = dfr:gATH_Wf
	NVAR/Z hv = dfr:gATH_hv
	NVAR/Z Eoffset = dfr:gATH_Eoffset
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z selectedLayer = dfr:gATH_selectedLayer
	NVAR/Z updateSelectedLayer = dfr:gATH_updateSelectedLayer
	NVAR/Z updateCursorsPositions = dfr:gATH_updateCursorsPositions
	NVAR/Z UseBESwitch = dfr:gATH_UseBELineSwitch
	NVAR/Z C1x0 = dfr0:gATH_C1x0
	NVAR/Z C1y0 = dfr0:gATH_C1y0
	NVAR/Z C2x0 = dfr0:gATH_C2x0
	NVAR/Z C2y0 = dfr0:gATH_C2y0
	NVAR/Z profileWidth0 = dfr0:gATH_profileWidth0
	WAVE/Z imgWaveRef = $ImagePathname
	WAVE/Z/SDFR=dfr W_ImageLineProfile
	variable xc, yc, dGE, BE_Eoffset
	switch(s.eventCode)
		case 0: // Use activation to update the cursors if you request defaults		
			if(updateCursorsPositions)
				SetDrawLayer/W=$s.winName ProgFront
				DrawAction/W=$s.winName delete
				SetDrawEnv/W=$s.winName Linefgc = (65535,0,0,65535), fillpat = 0, Linethick = 1, xcoord = top, ycoord = left
				Cursor/I/C=(65535,0,0)/S=1/N=1 E $imgNameTopGraphStr C1x, C1y
				Cursor/I/C=(1,16019,65535)/S=1/N=1 F $imgNameTopGraphStr C2x, C2y
				SetDrawEnv/W=$s.winName Linefgc = (0,65535,0,65535), fillpat = 0, Linethick = 1, xcoord = top, ycoord = left
				DrawLine/W=$s.winName C1x, C1y, C2x, C2y
				Make/O/FREE/N=2 xTrace={C1x, C2x}, yTrace = {C1y, C2y}
				ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = 2*profileWidth
				// Activate window, e.g after pressing "Restore Settings"
				if(stv)
					linepx = sqrt(((Gx-Hx)/dx)^2+((Gy-Hy)/dy)^2) // Calculate it again.
					dGE    = sqrt(((C1x - Gx)/dx)^2 + ((C1y - Gy)/dy)^2)
					Eoffset = stv - (linepx/2 - dGE) * epp // offset in eV from the bottom right energy (lowest KE)
					if(UseBESwitch)
						BE_Eoffset = hv - Eoffset - Wf
						SetScale/P x, BE_Eoffset, -epp, W_ImageLineProfile
					else
						SetScale/P x, Eoffset, epp, W_ImageLineProfile
					endif
				endif
				updateCursorsPositions = 0
			endif
			break
		case 2: // Kill the window
			KillWindow/Z $(GetUserData(s.winName, "", "ATH_LinkedWiniXPSPP"))
			if(WinType(GetUserData(s.winName, "", "ATH_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "ATH_targetGraphWin")) $UniqueName("XPSProf_unlnk_", 6, 0) // Change name of profile graph
			endif
			KillDataFolder/Z dfr
			hookresult = 1
			break
		case 5: // mouse up
			C1x = hcsr(E)
			C1y = vcsr(E)
			C2x = hcsr(F)
			C2y = vcsr(F)
			/// Note: E is at the low KE part (higher BE)
			/// N.B Line profile is taken from E to F
			if(stv)
				dGE    = sqrt(((C1x - Gx)/dx)^2 + ((C1y - Gy)/dy)^2)
				linepx = sqrt(((Gx - Hx)/dx)^2+((Gy - Hy)/dy)^2)
				// offset in eV from the top right energy (lowest KE)
				Eoffset = stv - (linepx/2 - dGE) * epp // offset in eV from the bottom left energy (lowest KE)
				if(UseBESwitch)
					BE_Eoffset = hv - Eoffset - Wf
					SetScale/P x, BE_Eoffset, -epp, W_ImageLineProfile
				else
					SetScale/P x, Eoffset, epp, W_ImageLineProfile
				endif
			endif
			hookResult = 1
			break
		case 8: // modifications, either move the slides or the cursors
			// NB: s.cursorName gives "" in the switch but "-" outside for no cursor under cursor or CursorName (A,B,...J)
			if(WaveDims(imgWaveRef) == 3 && DataFolderExists("root:Packages:ATH_DataFolder:W3DImageSlider:" + WindowNameStr) && updateSelectedLayer) // deleted  && mouseTrackV < 0
				NVAR/Z glayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(WindowNameStr):gLayer
				selectedLayer = glayer
				Make/O/FREE/N=2 xTrace={C1x, C2x}, yTrace = {C1y, C2y}
				ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = 2*profileWidth
				if(stv)
					linepx = sqrt(((Gx-Hx)/dx)^2+((Gy-Hy)/dy)^2) // Calculate it again.
					dGE    = sqrt(((C1x - Gx)/dx)^2 + ((C1y - Gy)/dy)^2)
					Eoffset = stv - (linepx/2 - dGE) * epp // offset in eV from the bottom right energy (lowest KE)
					if(UseBESwitch)
						BE_Eoffset = hv - Eoffset - Wf
						SetScale/P x, BE_Eoffset, -epp, W_ImageLineProfile
					else
						SetScale/P x, Eoffset, epp, W_ImageLineProfile
					endif
				endif
			endif
			break
		case 7: // cursor moved
			if(!cmpstr(s.cursorName, "E") || !cmpstr(s.cursorName, "F")) // It should work only with E, F you might have other cursors on the image
				SetDrawLayer/W=$s.winName ProgFront
			    DrawAction/W=$s.winName delete
	   			SetDrawEnv/W=$s.winName linefgc = (65535,0,0,65535), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
				C1x = hcsr(E)
				C1y = vcsr(E)
				C2x = hcsr(F)
				C2y = vcsr(F)	   			
				DrawLine/W=$s.winName C1x , C1y, C2x, C2y
	   			Make/O/FREE/N=2 xTrace={C1x, C2x}, yTrace = {C1y, C2y}  // profile from E to F
	   			ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = 2*profileWidth
			endif
				if(stv)
					dGE    = sqrt(((C1x - Gx)/dx)^2 + ((C1y - Gy)/dy)^2)
					linepx = sqrt(((Gx - Hx)/dx)^2+((Gy - Hy)/dy)^2)
					Eoffset = stv - (linepx/2 - dGE) * epp // offset in eV from the bottom right energy (lowest KE)
					if(UseBESwitch)
						BE_Eoffset = hv - Eoffset - Wf
						SetScale/P x, BE_Eoffset, -epp, W_ImageLineProfile
					else
						SetScale/P x, Eoffset, epp, W_ImageLineProfile
					endif
				endif
				hookResult = 1
				break
			hookresult = 0
			break
	endswitch
	SetdataFolder currdfr
	return hookResult       // 0 if nothing done, else 1
End

static Function GraphHookFunction(STRUCT WMWinHookStruct &s)
	string parentGraphWin = GetUserData(s.winName, "", "ATH_parentGraphWin")
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_rootdfrStr"))
	switch(s.eventCode)
		// Window is about to be killed. When using case 2 then I cannot KillWindow and KillDataFolder. 
		// See the discussion with Wavemetrics. If you want to use case 2, then you need to invoke
		// Execute/P cmdStr. I do not see any issue in using here case 17 (14.12.2023).
		case 17:
			SetWindow $parentGraphWin, hook(MyiXPSHook) = $""
			SetWindow $parentGraphWin userdata(ATH_LinkedWiniXPSPP) = ""
			if(WinType(GetUserData(parentGraphWin, "", "ATH_targetGraphWin")) == 1)
				DoWindow/C/W=$(GetUserData(s.winName, "", "ATH_targetGraphWin")) $UniqueName("XPSProf_unlnk_",6,0) // Change name of profile graph
			endif
			Cursor/W=$parentGraphWin/K G
			Cursor/W=$parentGraphWin/K H
			Cursor/W=$parentGraphWin/K E
			Cursor/W=$parentGraphWin/K F
			SetDrawLayer/W=$parentGraphWin ProgFront
			DrawAction/W=$parentGraphWin delete
			SetDrawLayer/W=$parentGraphWin Overlay
			DrawAction/W=$parentGraphWin delete
			SetWindow $s.winName hook(MyiXPSGraphHook) = $""
			KillWindow $s.winName
			KillDataFolder dfr
			break
	endswitch
End


static Function SaveProfile(STRUCT WMButtonAction &B_Struct): ButtonControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_rootdfrStr"))
	string targetGraphWin = GetUserData(B_Struct.win, "", "ATH_targetGraphWin")
	SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gATH_ImageNameStr
	SVAR/Z ImagePathname = dfr:gATH_ImagePathname
	Wave/SDFR=dfr W_ImageLineProfile
	NVAR/Z PlotSwitch = dfr:gATH_PlotSwitch
	NVAR/Z UseBESwitch = dfr:gATH_UseBELineSwitch
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z selectedLayer = dfr:gATH_selectedLayer
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z colorcnt = dfr:gATH_colorcnt
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z Gx = dfr:gATH_Gx
	NVAR/Z Gy = dfr:gATH_Gy
	NVAR/Z Hx = dfr:gATH_Hx
	NVAR/Z Hy = dfr:gATH_Hy
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy
	NVAR/Z Eoffset = dfr:gATH_Eoffset
	NVAR/Z epp = dfr:gATH_epp
	NVAR/Z stv = dfr:gATH_stv
	NVAR/Z linepx = dfr:gATH_linepx
	NVAR/Z hv = dfr:gATH_hv
	NVAR/Z Wf = dfr:gATH_Wf

	string recreateDrawStr
	DFREF savedfr = GetDataFolderDFR()

	variable postfix = 0, dGE
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			string saveWaveBaseStr = w3dNameStr + "_prof"
			string saveWaveNameStr = CreateDataObjectName(savedfr, saveWaveBaseStr, 1, 0, 5)
			// It has to come first, it is used to scale to BE
			if(stv)
				dGE = sqrt(((C1x - Gx)/dx)^2 + ((C1y - Gy)/dy)^2)
				linepx = sqrt(((Gx - Hx)/dx)^2+((Gy - Hy)/dy)^2)
				Eoffset = stv - (linepx/2 - dGE) * epp // offset in eV from the bottom right energy (lowest KE)
				// Duplicate the wave
				WAVE/SDFR=dfr W_ImageLineProfile
				Duplicate dfr:W_ImageLineProfile, savedfr:$saveWaveNameStr
				if(UseBESwitch)
					variable BE_Eoffset = hv - Eoffset - Wf
					SetScale/P x, BE_Eoffset, -epp, savedfr:$saveWaveNameStr
				else
					SetScale/P x, Eoffset, epp, savedfr:$saveWaveNameStr
				endif
			else
				WAVE/SDFR=dfr W_ImageLineProfile
				Duplicate dfr:W_ImageLineProfile, savedfr:$saveWaveNameStr
			endif
			if(PlotSwitch)
				if(WinType(targetGraphWin) == 1)
					AppendToGraph/W=$targetGraphWin savedfr:$saveWaveNameStr
					[red, green, blue] = ATH_Graph#GetColor(colorcnt)
					Modifygraph/W=$targetGraphWin rgb($PossiblyQuoteName(saveWaveNameStr)) = (red, green, blue)
					colorcnt += 1 // i++ does not work with globals?
				else
					Display/N=$targetGraphWin savedfr:$saveWaveNameStr // Do not kill the graph windows, user might want to save the profiles
					[red, green, blue] = ATH_Graph#GetColor(colorcnt)
					Modifygraph/W=$targetGraphWin rgb($PossiblyQuoteName(saveWaveNameStr)) = (red, green, blue)
					AutopositionWindow/R=$B_Struct.win $targetGraphWin
					DoWindow/F $targetGraphWin
					colorcnt += 1
				endif
				if(UseBESwitch)
					Label/W=$targetGraphWin bottom "\\u#2Binding Energy (eV)"
				endif
			endif

			sprintf recreateDrawStr, "pathName:%s\nCursor G:%d,%d\nCursor H:%d,%d\nCursor E:%d,%d\nCursor F:%d,%d\nWidth(px):%d\nSTV(V):%.2f\n" + \
			"hv(eV):%.2f\nWf(eV):%.2f\nEPP(eV/px):%.8f", ImagePathname,  Gx, Gy, Hx, Hy, C1x, C1y, C2x, C2y, profileWidth, stv, hv, Wf, epp
			Note savedfr:$saveWaveNameStr, recreateDrawStr
			// Add metadata
			break
	endswitch
return 0
End

static Function SaveDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_rootdfrStr"))
	DFREF dfr0 = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iXPS:DefaultSettings") // Settings here
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z Gx = dfr:gATH_Gx
	NVAR/Z Gy = dfr:gATH_Gy
	NVAR/Z Hx = dfr:gATH_Hx
	NVAR/Z Hy = dfr:gATH_Hy
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy
	NVAR/Z linepx = dfr:gATH_linepx
	NVAR/Z epp = dfr:gATH_epp
	NVAR/Z Wf = dfr:gATH_Wf
	// --------------------------//
	NVAR/Z C1x0 = dfr0:gATH_C1x0
	NVAR/Z C1y0 = dfr0:gATH_C1y0
	NVAR/Z C2x0 = dfr0:gATH_C2x0
	NVAR/Z C2y0 = dfr0:gATH_C2y0
	NVAR/Z profileWidth0 = dfr0:gATH_profileWidth0
	NVAR/Z linepx0 = dfr0:gATH_linepx0
	NVAR/Z Gx0 = dfr0:gATH_Gx0
	NVAR/Z Gy0 = dfr0:gATH_Gy0
	NVAR/Z Hx0 = dfr0:gATH_Hx0
	NVAR/Z Hy0 = dfr0:gATH_Hy0
	NVAR/Z Wf0 = dfr0:gATH_Wf0
	NVAR/Z epp0 = dfr0:gATH_epp0
	NVAR/Z CursorGHSwitch = dfr:gATH_CursorGHSwitch
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			ControlInfo/W=$B_Struct.win RestoreCursorPositions
			if(CursorGHSwitch)
				string msg = "Save (Overwite) current state as default?"
				DoAlert/T="athina would like to ask you" 1, msg
				if(V_flag == 1)
					C1x0 = C1x
					C1y0 = C1y
					C2x0 = C2x
					C2y0 = C2y
					profileWidth0 = profileWidth
					linepx0 = linepx
					Gx0 = Gx
					Gy0 = Gy
					Hx0 = Hx
					Hy0 = Hy
					epp0 = epp
					Wf0 = Wf
					Button SaveCursorPositions, fColor=(2,39321,1), win=$B_Struct.win
					Button RestoreCursorPositions, disable = 0, win=$B_Struct.win
				endif
			endif
			break
		endswitch
End

static Function RestoreDefaultSettings(STRUCT WMButtonAction &B_Struct): ButtonControl
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_rootdfrStr"))
	DFREF dfr0 = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:iXPS:DefaultSettings") // Settings here
	string parentWindow = GetUserData(B_Struct.win, "", "ATH_parentGraphWin")
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z C1x0 = dfr0:gATH_C1x0
	NVAR/Z C1y0 = dfr0:gATH_C1y0
	NVAR/Z C2x0 = dfr0:gATH_C2x0
	NVAR/Z C2y0 = dfr0:gATH_C2y0
	NVAR/Z profileWidth0 = dfr0:gATH_profileWidth0
	NVAR/Z updateCursorsPositions = dfr:gATH_updateCursorsPositions

	NVAR/Z Gx0 = dfr0:gATH_Gx0
	NVAR/Z Gy0 = dfr0:gATH_Gy0	
	NVAR/Z Hx0 = dfr0:gATH_Hx0
	NVAR/Z Hy0 = dfr0:gATH_Hy0
	NVAR/Z Wf0 = dfr0:gATH_Wf0
	NVAR/Z epp0 = dfr0:gATH_epp0
	
	NVAR/Z Gx = dfr:gATH_Gx
	NVAR/Z Gy = dfr:gATH_Gy	
	NVAR/Z Hx = dfr:gATH_Hx
	NVAR/Z Hy = dfr:gATH_Hy
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy
	NVAR/Z linepx = dfr:gATH_linepx
	NVAR/Z epp = dfr:gATH_epp
	NVAR/Z stv = dfr:gATH_stv
	WAVE/Z/SDFR=dfr W_ImageLineProfile

	NVAR/Z CursorGHSwitch = dfr:gATH_CursorGHSwitch
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			C1x = C1x0
			C1y = C1y0
			C2x = C2x0
			C2y = C2y0
			profileWidth = profileWidth0
			Gx = Gx0
			Gy = Gy0
			Hx = Hx0
			Hy = Hy0
			epp = epp0
			Cursor/K/W=$parentWindow G
			Cursor/K/W=$parentWindow H
			Button SetCursorsGH fcolor=(0,65535,0), win=$B_Struct.win
			ControlUpdate/W=$B_Struct.win SetCursorsGH
			SetDrawLayer/W=$parentWindow Overlay
			DrawAction/W=$parentWindow delete
			SetDrawEnv/W=$parentWindow linefgc = (0, 65535, 0, 32767), fillpat = 0, linethick = 0.5, dash= 3, xcoord= top, ycoord= left
			DrawLine/W=$parentWindow Gx, Gy, Hx, Hy
			SetDrawEnv/W=$parentWindow linefgc = (0, 65535, 0, 32767), fillfgc= (0,65535,0, 32767), fillpat = 1, linethick = 1, dash= 1, xcoord= top, ycoord= left
			DrawOval/W=$parentWindow (Gx + Hx)/2 + 3 * dx, (Gy + Hy)/2 + 3 * dy, (Gx + Hx)/2 - 3 * dx, (Gy + Hy)/2 - 3 * dy
			variable slope = ATH_Geometry#SlopePerpendicularToLineSegment(Gx, Gy, Hx, Hy)
			variable Dx1, Dy1, Dx2, Dy2
			[Dx1, Dy1, Dx2, Dy2] = ATH_Geometry#GetBothPointsWithDistanceFromLine(Gx, Gy, -1/slope, 200*dx)
			SetDrawLayer/W=$parentWindow Overlay
			SetDrawEnv/W=$parentWindow linefgc = (65535,0,0), fillpat = 1, linethick = 3, dash= 8, xcoord= top, ycoord= left
			DrawLine/W=$parentWindow Dx1, Dy1, Dx2, Dy2
			// Use the same local variables for the second line
			[Dx1, Dy1, Dx2, Dy2] = ATH_Geometry#GetBothPointsWithDistanceFromLine(Hx, Hy, -1/slope, 200*dx) // B is the bottom point
			SetDrawLayer/W=$parentWindow Overlay
			SetDrawEnv/W=$parentWindow linefgc = (1,16019,65535),  fillpat = 1, linethick = 3, dash= 8, xcoord= top, ycoord= left
			DrawLine/W=$parentWindow Dx1, Dy1, Dx2, Dy2
			// Draw the midpoint using the same lcoal variable
			[Dx1, Dy1, Dx2, Dy2] = ATH_Geometry#GetBothPointsWithDistanceFromLine(0.5*(Gx+Hx), 0.5*(Gy+Hy), -1/slope, 200*dx) // B is the bottom point
			SetDrawLayer/W=$parentWindow Overlay
			SetDrawEnv/W=$parentWindow linefgc = (16386,65535,16385), fillpat = 1, linethick = 3, dash= 8, xcoord= top, ycoord= left
			DrawLine/W=$parentWindow Dx1, Dy1, Dx2, Dy2
			SetDrawLayer/W=$parentWindow ProgFront
			CursorGHSwitch = 1
			updateCursorsPositions = 1
			DoWindow/F $parentWindow
			break
	endswitch
End

static Function ShowProfileWidth(STRUCT WMButtonAction &B_Struct): ButtonControl
	/// We have to find the vertices of the polygon representing
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_rootdfrStr"))
	SVAR/Z WindowNameStr= dfr:gATH_WindowNameStr
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z width = dfr:gATH_profileWidth
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy // assume here that dx = dy
	variable x1, x2, x3, x4, y1, y2, y3, y4, xs, ys
	variable slope = ATH_Geometry#SlopePerpendicularToLineSegment(C1x, C1y,C2x, C2y)
	if(slope == 0)
		x1 = C1x
		x2 = C1x
		x3 = C2x
		x4 = C2x
		y1 = C1y + 0.5 * width * dy
		y2 = C1y - 0.5 * width * dy
		y3 = C2y - 0.5 * width * dy
		y4 = C2y + 0.5 * width * dy
	elseif(slope == inf)
		y1 = C1y
		y2 = C1y
		y3 = C2y
		y4 = C2y
		x1 = C1x + 0.5 * width * dx
		x2 = C1x - 0.5 * width * dx
		x3 = C2x - 0.5 * width * dx
		x4 = C2x + 0.5 * width * dx
	else
		[xs, ys] = ATH_Geometry#GetVerticesPerpendicularToLine(width * dx/2, slope)
		x1 = C1x + xs
		x2 = C1x - xs
		x3 = C2x - xs
		x4 = C2x + xs
		y1 = C1y + ys
		y2 = C1y - ys
		y3 = C2y - ys
		y4 = C2y + ys
	endif
	switch(B_Struct.eventCode)	// numeric switch
		case 1:	// "mouse down"
			SetDrawLayer/W=$WindowNameStr ProgFront
			SetDrawEnv/W=$WindowNameStr gstart,gname= iXPSWidth
			SetDrawEnv/W=$WindowNameStr linefgc = (65535,16385,16385,32767), fillbgc= (65535,16385,16385,32767), fillpat = -1, linethick = 0, xcoord = top, ycoord = left
			DrawPoly/W=$WindowNameStr x1, y1, 1, 1, {x1, y1, x2, y2, x3, y3, x4, y4}
			SetDrawEnv/W=$WindowNameStr gstop
			break
		case 2: // "mouse up"
		case 3: // "mouse up outside button"
			SetDrawLayer/W=$WindowNameStr ProgFront
			DrawAction/W=$WindowNameStr getgroup = iXPSWidth
			DrawAction/W=$WindowNameStr delete = V_startPos, V_endPos
			break
	endswitch
End

static Function PlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_rootdfrStr"))
	NVAR/Z PlotSwitch = dfr:gATH_PlotSwitch
	switch(cb.checked)
		case 1:		// Mouse up
			PlotSwitch = 1
			break
		case 0:
			PlotSwitch = 0
			break
	endswitch
	return 0
End

static Function Layer3D(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_rootdfrStr"))
	NVAR/Z selectedLayer = dfr:gATH_selectedLayer
	NVAR/Z updateSelectedLayer = dfr:gATH_updateSelectedLayer
	SVAR/Z WindowNameStr = dfr:gATH_WindowNameStr
	if(DataFolderExists(skATH_W3DImageSliderParentDFR + WindowNameStr))
		NVAR/Z glayer = root:Packages:ATH_DataFolder:W3DImageSlider:$(WindowNameStr):gLayer
		if(NVAR_Exists(glayer))
			selectedLayer = glayer
		endif
	else
		return 1
	endif
	switch(cb.checked)
		case 1:
			updateSelectedLayer = 1
			break
		case 0:
			updateSelectedLayer = 0
			break
	endswitch
	return 0
End

static Function SetProfileWidth(STRUCT WMSetVariableAction& sv) : SetVariableControl

	DFREF currdfr = GetDataFolderDFR()
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sv.win, "", "ATH_rootdfrStr"))
	NVAR/Z C1x = dfr:gATH_C1x
	NVAR/Z C1y = dfr:gATH_C1y
	NVAR/Z C2x = dfr:gATH_C2x
	NVAR/Z C2y = dfr:gATH_C2y
	NVAR/Z profileWidth = dfr:gATH_profileWidth
	NVAR/Z selectedLayer = dfr:gATH_selectedLayer
	NVAR/Z Gx = dfr:gATH_Gx
	NVAR/Z Gy = dfr:gATH_Gy
	NVAR/Z Hx = dfr:gATH_Hx
	NVAR/Z Hy = dfr:gATH_Hy	
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy
	NVAR/Z stv = dfr:gATH_stv
	NVAR/Z epp = dfr:gATH_epp
	NVAR/Z hv = dfr:gATH_hv	
	NVAR/Z Wf = dfr:gATH_Wf		
	NVAR/Z linepx = dfr:gATH_linepx
	NVAR/Z UseBESwitch = dfr:gATH_UseBELineSwitch	
	SetDataFolder dfr
	Make/O/FREE/N=2 xTrace={C1x, C2x}, yTrace = {C1y, C2y}
	SVAR/Z ImagePathname = dfr:gATH_ImagePathname
	WAVE/Z imgWaveRef = $ImagePathname
	WAVE/Z/SDFR=dfr W_ImageLineProfile
	variable dGE, Eoffset, BE_Eoffset
	switch(sv.eventCode)
		case 6:
			ImageLineProfile/P=(selectedLayer) srcWave=imgWaveRef, xWave=xTrace, yWave=yTrace, width = 2 * profileWidth
			if(stv)
				dGE    = sqrt(((C1x - Gx)/dx)^2 + ((C1y - Gy)/dy)^2)
				linepx = sqrt(((Gx - Hx)/dx)^2+((Gy - Hy)/dy)^2)
				Eoffset = stv - (linepx/2 - dGE) * epp // offset in eV from the bottom right energy (lowest KE)
				if(UseBESwitch)
					BE_Eoffset = hv - Eoffset - Wf
					SetScale/P x, BE_Eoffset, -epp, W_ImageLineProfile
				else
					SetScale/P x, Eoffset, epp, W_ImageLineProfile
				endif
			endif
			break
	endswitch
	SetDataFolder currdfr
	return 0
End


static Function SetCursorsGH(STRUCT WMButtonAction &B_Struct): ButtonControl)

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_rootdfrStr"))
	string parentWindow = GetUserData(B_Struct.win, "", "ATH_parentGraphWin")
	NVAR/Z Gx = dfr:gATH_Gx
	NVAR/Z Gy = dfr:gATH_Gy	
	NVAR/Z Hx = dfr:gATH_Hx
	NVAR/Z Hy = dfr:gATH_Hy
	NVAR/Z stv = dfr:gATH_STV
	NVAR/Z dx = dfr:gATH_dx
	NVAR/Z dy = dfr:gATH_dy
	NVAR/Z linepx = dfr:gATH_linepx
	NVAR/Z CursorGHSwitch = dfr:gATH_CursorGHSwitch
	
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(parentWindow, ";"),";")
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			if(!CursorGHSwitch) // if not yet set -> CursorGHSwitch = 0
				SetAxis/W=$parentWindow/A/R left // Auto-scale in case of zoomed in!
				Gx = hcsr(G, parentWindow)
				Gy = vcsr(G, parentWindow)
				Hx = hcsr(H, parentWindow)
				Hy = vcsr(H, parentWindow)
				linepx = sqrt(((Gx-Hx)/dx)^2 + ((Gy-Hy)/dy)^2)
				// 
				Cursor/K/W=$parentWindow G
				Cursor/K/W=$parentWindow H
				Button SetCursorsGH fcolor=(0,65535,0)
				ControlUpdate/W=$B_Struct.win SetCursorsGH
				SetDrawLayer/W=$parentWindow Overlay 
				SetDrawEnv/W=$parentWindow linefgc = (65535,65535,0), fillpat = 0, linethick = 3, dash= 3, xcoord= top, ycoord= left
				DrawLine/W=$parentWindow Gx, Gy, Hx, Hy
				SetDrawEnv/W=$parentWindow linefgc = (65535,65535,0), fillfgc= (65535,65535,0), fillpat = 1, linethick = 3, dash= 1, xcoord= top, ycoord= left
				DrawOval/W=$parentWindow (Gx + Hx)/2 + 3 * dx, (Gy + Hy)/2 + 3 * dy, (Gx + Hx)/2 - 3 * dx, (Gy + Hy)/2 - 3 * dy
				SetDrawLayer/W=$parentWindow Overlay 
				SetDrawEnv/W=$parentWindow linefgc = (1,39321,19939, 32767), fillfgc= (0,65535,0, 32767), fillpat = 1, linethick = 1, dash= 1, xcoord= top, ycoord= left	
				variable slope = ATH_Geometry#SlopePerpendicularToLineSegment(Gx, Gy, Hx, Hy)
				variable Dx1, Dy1, Dx2, Dy2
				[Dx1, Dy1, Dx2, Dy2] = ATH_Geometry#GetBothPointsWithDistanceFromLine(Gx, Gy, -1/slope, 200*dx)
				SetDrawLayer/W=$parentWindow Overlay 
				SetDrawEnv/W=$parentWindow linefgc = (65535,0,0), fillpat = 1, linethick = 3, dash= 8, xcoord= top, ycoord= left
				DrawLine/W=$parentWindow Dx1, Dy1, Dx2, Dy2
				// Use the same local variables for the second line
				[Dx1, Dy1, Dx2, Dy2] = ATH_Geometry#GetBothPointsWithDistanceFromLine(Hx, Hy, -1/slope, 200*dx) // B is the bottom point
				SetDrawLayer/W=$parentWindow Overlay 
				SetDrawEnv/W=$parentWindow linefgc = (1,16019,65535),  fillpat = 1, linethick = 3, dash= 8, xcoord= top, ycoord= left
				DrawLine/W=$parentWindow Dx1, Dy1, Dx2, Dy2
				// Draw the midpoint using the same lcoal variable
				[Dx1, Dy1, Dx2, Dy2] = ATH_Geometry#GetBothPointsWithDistanceFromLine(0.5*(Gx+Hx), 0.5*(Gy+Hy), -1/slope, 200*dx) // B is the bottom point
				SetDrawLayer/W=$parentWindow Overlay 
				SetDrawEnv/W=$parentWindow linefgc = (16386,65535,16385), fillpat = 1, linethick = 3, dash= 8, xcoord= top, ycoord= left
				DrawLine/W=$parentWindow Dx1, Dy1, Dx2, Dy2
				SetDrawLayer/W=$parentWindow ProgFront
				Button SaveCursorPositions, disable = 0, win=$B_Struct.win				
				CursorGHSwitch = 1
			else
				Cursor/W=$parentWindow/I/C=(0,65535,0, 30000)/H=1/P/N=1 A $imgNameTopGraphStr Gx, Gy
				Cursor/W=$parentWindow/I/C=(0,65535,0, 65535)/H=1/P/N=1 B $imgNameTopGraphStr Hx, Hy
				SetDrawLayer/W=$parentWindow Overlay
				DrawAction/W=$parentWindow delete
				Button SetCursorsGH fcolor=(65535,0,0)
				ControlUpdate/W=$B_Struct.win SetCursorsGH
				SetDrawLayer/W=$parentWindow ProgFront
				Button SaveCursorPositions, disable = 2, win=$B_Struct.win				
				CursorGHSwitch = 0
			endif
			break
	endswitch
	
End
	
static Function UseBE(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_rootdfrStr"))
	NVAR/Z UseBESwitch = dfr:gATH_UseBELineSwitch
	NVAR/Z updateCursorsPositions = dfr:gATH_updateCursorsPositions	
	switch(cb.checked)
		case 1:
			UseBESwitch = 1
			Label/W=$cb.win bottom "\\u#2Binding Energy (eV)[E --> F]"
			break
		case 0:
			UseBESwitch = 0
			Label/W=$cb.win bottom "\\u#2Kinetic Energy (eV)[E --> F]"
			break
	endswitch
	updateCursorsPositions = 1 // do update by making GetUserData(cb.win, "", "ATH_parentGraphWin") TG
	DoWindow/F $GetUserData(cb.win, "", "ATH_parentGraphWin")
	return 0
End

static Function Sethv(STRUCT WMSetVariableAction& sv) : SetVariableControl	

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sv.win, "", "ATH_rootdfrStr"))
	NVAR/Z hv = dfr:gATH_hv
	switch(sv.eventCode)
		case 6:
			hv = sv.dval
			break
	endswitch
	return 0
End

static Function SetWf(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sv.win, "", "ATH_rootdfrStr"))
	NVAR/Z wf = dfr:gATH_Wf
	switch(sv.eventCode)
		case 6:
			wf = sv.dval
			break
	endswitch
	return 0
End

static Function SetEPP(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sv.win, "", "ATH_rootdfrStr"))
	NVAR/Z epp = dfr:gATH_epp
	switch(sv.eventCode)
		case 6:
			epp = sv.dval
			break
	endswitch
	return 0
End

static Function SetSTV(STRUCT WMSetVariableAction& sv) : SetVariableControl
	
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sv.win, "", "ATH_rootdfrStr"))
	NVAR/Z stv = dfr:gATH_STV
	switch(sv.eventCode)
		case 6:
			stv = sv.dval
			break
	endswitch
	return 0
End

// This is used to for waves selected in the DB, not here
static Function GetProfileUsingDefaults(WAVE wRef, [variable BEscaleQ])
	/// Get a profile from wRef using the default saved settings
	/// BEscaleQ = 1 is default. If BEscaleQ = 0 scale with KE
	BEscaleQ = ParamIsDefault(BEscaleQ) ? 1 : BEscaleQ

	if(WaveDims(wRef) != 2)
		return -1
	endif

	DFREF dfr0 =  $"root:Packages:ATH_DataFolder:iXPS:DefaultSettings"
	if(!DataFolderRefStatus(dfr0))
		print "Default settings DFREF is invalid"
		return -1
	endif

	NVAR/Z C1x0 = dfr0:gATH_C1x0
	NVAR/Z C1y0 = dfr0:gATH_C1y0
	NVAR/Z C2x0 = dfr0:gATH_C2x0
	NVAR/Z C2y0 = dfr0:gATH_C2y0
	NVAR/Z profileWidth0 = dfr0:gATH_profileWidth0
	NVAR/Z Gx0 = dfr0:gATH_Gx0
	NVAR/Z Gy0 = dfr0:gATH_Gy0
	NVAR/Z Hx0 = dfr0:gATH_Hx0
	NVAR/Z Hy0 = dfr0:gATH_Hy0
	NVAR/Z Wf0 = dfr0:gATH_Wf0
	NVAR/Z epp0 = dfr0:gATH_epp0
	NVAR/Z linepx0 = dfr0:gATH_linepx0
	if(!NVAR_Exists(Gx0))
		return 1
	endif
	variable dx = DimDelta(wRef,0)
	variable dy = DimDelta(wRef,1)

	DFREF dfr = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	Make/O/N=2 xTrace={C1x0, C2x0}, yTrace = {C1y0, C2y0}
	ImageLineProfile srcWave=wRef, xWave=xTrace, yWave=yTrace, width = 2 * profileWidth0
	WAVE W_ImageLineProfile
	string saveWaveBaseStr = NameOfWave(wRef) + "_prof"
	string saveWaveNameStr = CreateDataObjectName(dfr, saveWaveBaseStr, 1, 0, 5)
	Duplicate W_ImageLineProfile, dfr:$saveWaveNameStr
	SetDataFolder dfr
	variable hv = ATH_String#GetPhotonEnergyFromFilename(NameOfWave(wRef))
	variable stv_ = NumberByKey("STV(V)",note(wRef),":","\n" )
	variable stv = numtype(stv_) ? 0 : stv_
	if(stv)
		variable dGE = sqrt(((C1x0 - Gx0)/dx)^2 + ((C1y0 - Gy0)/dy)^2)
		variable Eoffset = stv - (linepx0/2 - dGE) * epp0
		if(hv > Wf0 && BEscaleQ)
			variable BE_Eoffset = hv - Eoffset - Wf0
			SetScale/P x, BE_Eoffset, -epp0, dfr:$saveWaveNameStr
		else
			SetScale/P x, Eoffset, epp0, dfr:$saveWaveNameStr
		endif
	endif
	string recreateDrawStr
	sprintf recreateDrawStr, "XPS profile using saved settings.\npathName:%s\nCursor G:%d,%d\nCursor H:%d,%d\nCursor E:%d,%d\nCursor F:%d,%d\nWidth(px):%d\nSTV(V):%.2f\n" + \
	"hv(eV):%.2f\nWf(eV):%.2f\nEPP(eV/px):%.8f", GetWavesDataFolder(wRef, 2), C1x0, C1y0, C2x0, C2y0, Gx0, Gy0, Hx0, Hy0, profileWidth0, stv, hv, Wf0, epp0
	Note dfr:$saveWaveNameStr, recreateDrawStr
	return 0
End
