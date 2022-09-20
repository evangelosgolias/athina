#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma rtFunctionErrors = 1 // Debug mode
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late

#include <Image common>
#include <Imageslider>
#include "::Utilities:MXP_FolderOperations"


//		TODO: 
//		3. Fix the rest of the buttons, save metadata for each saved profile IDEA: bunch the profiles
//		you save per 3D wave. Each 3D wave should have its own folder in Packages: ... where profiles 
//		are saved.
//		4 Clean up and document
//		5. You have to take care of Imageregistration/alignment of the 3d. Make a routine that loads all the files,
//		creates the 3dwave and deletes all the imported images.
		//If you have difficulty follow the following strategy: make a folder 3dwavename_zprofiles at the folder where
		// the 3dwave is.

Menu "GraphMarquee"
	"Draw ROI", GetMarquee/K left,top; DrawROIOnImage(V_left, V_top, V_right, V_bottom)
End

//Menu "DataBrowserObjectsPopup", dynamic
//	"Tag", FunctionCall()
//End

Function MXP_InitialiseZProfilerFolder()
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here.
	/// Use a a 3D wave in top window
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopWindowStr = RemoveEnding(ImageNameList("", ";"))
	Wave w3dref = ImageNameToWaveRef("", imgNameTopWindowStr) // full path of wave

	string msg // Error reporting
	if(!strlen(imgNameTopWindowStr)) // we do not have an image in top graph
		Abort "No image in top graph. Startup profile with an 3d wave in your active window."
	endif
	
	if(WaveDims(w3dref) != 3)
		sprintf msg, "Z-profiler works with 3d waves only. Wave %s is in top window", imgNameTopWindowStr
		Abort msg
	endif
	
	if(stringmatch(AxisList(winNameStr),"*bottom*")) // Check if you have a NewImage left;top axes
		sprintf msg, "Reopen as Newimage %s", imgNameTopWindowStr
		KillWindow $winNameStr
		NewImage/K=1/N=$winNameStr w3dref
		ModifyGraph/W=$winNameStr width={Plan,1,top,left}
	endif
	
	WMAppend3DImageSlider() // Everything ok now, add a slider to the 3d wave
	
	// Initialise the Package folder
	variable nlayers = DimSize(w3dref, 2)
	variable dx = DimDelta(w3dref, 0)
	variable dy = DimDelta(w3dref, 1)
	variable dz = DimDelta(w3dref, 2)
    variable z0 = DimOffset(w3dref, 2)
    
    
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles") // Change root folder if you wan
	string zprofilestr = "wZLineProfilesPlot"//NameOfWave(w3dref) + "_Zprofile"
	Make/O/N=(nlayers) dfr:$zprofilestr /Wave = profile // Store the line profile 
	SetScale/P x, z0, dz, profile
	
	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopWindowStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_LineProfileWaveStr = zprofilestr // image profile wave
	string/G dfr:gMXP_ProfileMetadata = ""
	string/G dfr:gMXP_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gMXP_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gMXP_w3dNameStr = NameOfWave(w3dref)
	variable/G dfr:gMXP_ROI_dx = dx
	variable/G dfr:gMXP_ROI_dy = dy
	variable/G dfr:gMXP_DoPlotSwitch = 0
	variable/G dfr:gMXP_colorcnt = 0

End

Function MXP_InitialiseZProfilerGraph()
	/// Here we will create the profile panel and graph and plot the profile
	if (WinType("MXP_ZBeamLineProfilePanel") == 0) // line profile window is not displayed
		MXP_CreateProfilePanel()
	else
		DoWindow/F ZLineProfilesPlot // if it is bring it to the FG
	endif
End

Function MXP_StartZProfiler()
	MXP_InitialiseZProfilerFolder()
	MXP_InitialiseZProfilerGraph()
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles") // Change root folder if you want
	SVAR winNameStr = dfr:gMXP_WindowNameStr
	SetWindow $winNameStr, hook(MyHook) = MXP_CursorHookFunctionBeamProfiler // Set the hook
End


Function DrawROIOnImage(Variable l, Variable t, Variable r, Variable b)
	
	NVAR/Z V_left, V_top, V_right, V_bottom

	String wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine

	// Drawing env stuff
	SetDrawLayer ProgFront // ImageGenerateROIMask needs this layer
	SetDrawEnv linefgc= (65535,0,0),fillpat= 0, linethick = 0.5, xcoord= top,ycoord= left, save
	// Set the cursor J, A=0 -> Do not move Cursor with keyboard
	Cursor/I/L=0/C=(65535,0,0,30000)/S=2 J $wnamestr 0.5 * (l + r), 0.5 * (t + b)
	DrawOval l, t, r, b
End


Function MXP_CursorHookFunctionBeamProfiler(STRUCT WMWinHookStruct &s)
	/// Window hook function
	    
    Variable hookResult = 0
	DFREF dfr = root:Packages:MXP_datafldr:ZBeamProfiles
	NVAR/Z V_left, V_top, V_right, V_bottom
	NVAR/Z dx = dfr:gMXP_ROI_dx
	NVAR/Z dy = dfr:gMXP_ROI_dy
	variable axisxlen = V_right - V_left 
	variable axisylen = V_bottom - V_top

	SVAR/Z profilemetadata = dfr:gMXP_ProfileMetadata
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
	SVAR/Z w3dPath = dfr:gMXP_w3dPath
	DFREF wrk3dwave = $w3dPath
	Wave/SDFR=wrk3dwave w3d = $w3dNameStr
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	Wave/Z M_ROIMask
	
    switch(s.eventCode)
		case 2: // Kill the window
			KillWaves/Z M_ROIMask
			KillWindow/Z ZLineProfilesPlot
			KillWindow/Z MXP_ZBeamLineProfilePanel
			MXP_CleanGlobalWavesVarAndStrInFolder(dfr)
			hookresult = 1
			break
        case 7: // cursor moved
        	DrawAction delete
			DrawROIOnImage(-axisxlen * 0.5 + s.pointNumber * dx, axisylen * 0.5 + s.yPointNumber * dy, \
							 axisxlen * 0.5 + s.pointNumber * dx, -(axisylen * 0.5) + s.yPointNumber * dy)
			ImageGenerateROIMask $w3dNameStr // Here we need name of a wave, not a wave reference!
			if(WaveExists(M_ROIMask))
				MatrixOP/FREE/O/NTHR=0 buffer = sum(w3d*M_ROIMask) // Use two threads
		   	 	MatrixOP/FREE/O profile_free = beam(buffer,0,0)
		    		profile = profile_free
		    endif
		    hookresult = 1
	 		break
        case 5: // mouse up
			KillWaves/Z M_ROIMask // Cleanup
			hookresult = 1
			break
    endswitch
    
    return hookResult       // 0 if nothing done, else 1
End


Function MXP_CreateProfilePanel()
	 
	NewPanel/N=MXP_ZBeamLineProfilePanel /W=(580,53,995,316) // Linked to MXPInitializeAreaIntegrationProfiler()
	ModifyPanel cbRGB=(61166,61166,61166), frameStyle=3
	SetDrawLayer UserBack
	Button SaveProfileButton, pos={20.00,10.00}, size={90.00,20.00}, proc=MXP_SaveProfilePanel, title="Save Profile", help={"Save current profile"}, valueColor=(1,12815,52428)
	CheckBox ShowProfile, pos={150.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ProfilePanelCheckbox,title="Plot profiles ", fSize=14, value= 0
	CheckBox ShowSelectedAread, pos={270.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ProfilePanelCheckbox,title="Mark areas ", fSize=14, value= 0

	//Button ShowCursorALayer,pos={28.00,10.00},size={80.00,20.00},proc=MXP_PanelShowCursorALayerAction,title="Layer <- A"
	//Button ShowCursorALayer,help={"Set cursor from layer n"},valueColor=(0,26214,13293)
	//Button ShowLayerCursorA,pos={122.00,10.00},size={80.00,20.00},proc=MXP_PanelShowLayerCursorAAction,title="Layer -> A"
	//Button ShowLayerCursorA,help={"Set layer from cursor A"},valueColor=(65535,0,0)

	DFREF dfr = root:Packages:MXP_datafldr:ZBeamProfiles
	SVAR/SDFR=dfr gMXP_LineProfileWaveStr
	Wave profile = dfr:$gMXP_LineProfileWaveStr
	
	if (WaveExists(profile))
		Display/N=MXP_ZLineProfilesPlot/W=(15,38,391,236)/HOST=#  profile
		ModifyGraph rgb=(1,12815,52428), tick(left)=2, fSize=12, lsize=1.5
		Label left "\\u#2 Intensity (arb. u.)";DelayUpdate
		Label bottom "\\u#2 Energy (eV)"
	else
		Abort "Cannot find the line profile wave, check MXP_CreateProfilePanel()"
	endif

	SetDrawLayer UserFront
End

Function MXP_SaveProfilePanel(STRUCT WMButtonAction &B_Struct): ButtonControl
	/// Save profile wave
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles")
	SVAR/Z profilemetadata = dfr:gMXP_ProfileMetadata
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
	SVAR/Z w3dPath = dfr:gMXP_w3dPath
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	NVAR/Z DoPlotSwitch = dfr:gMXP_DoPlotSwitch
	NVAR/Z colorcnt = dfr:gMXP_colorcnt
	DFREF savedfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles:SavedProfiles")
	
	variable postfix = 0
	variable red, green, blue
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			do
				string saveWaveNameStr = w3dNameStr + "_prof" + num2str(postfix)
				if(WaveExists(savedfr:$saveWaveNameStr) == 1)
					postfix++
				else
					Duplicate dfr:$LineProfileWaveStr, savedfr:$saveWaveNameStr
							
					postfix = 0
					if(DoPlotSwitch)
						if(WinType("MXP_LineProfileGraph") == 1)
							AppendToGraph/W=MXP_LineProfileGraph savedfr:$saveWaveNameStr
							[red, green, blue] = MXP_GetColor(colorcnt)
							Modifygraph/W=MXP_LineProfileGraph rgb($saveWaveNameStr) = (red, green, blue)
							colorcnt += 1 // i++ does not work with globals?
						else
							Display/N=MXP_LineProfileGraph savedfr:$saveWaveNameStr
							[red, green, blue] = MXP_GetColor(colorcnt)
							Modifygraph/W=MXP_LineProfileGraph rgb($saveWaveNameStr) = (red, green, blue)
							AutopositionWindow/R=MXP_ZBeamLineProfilePanel MXP_LineProfileGraph
							DoWindow/F MXP_LineProfileGraph
							colorcnt += 1
						endif
					endif
				break
				endif
			while(1)		
			
		break
	endswitch
End

// 20.09.2022 Remove the two buttons below. Not very useful.
//Function MXP_PanelShowCursorALayerAction(STRUCT WMButtonAction &B_Struct): ButtonControl
//	/// 
//	DFREF dfr =root:Packages:MXP_datafldr:ZBeamProfiles
//	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
//	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
//	
//	switch(B_Struct.eventCode)	// numeric switch
//		case 2:
//			variable num = pcsr(A, "MXP_ZBeamLineProfilePanel#MXP_ZLineProfilesPlot")
//			if(numtype(num)!=2) // if pcsr returns NaN
//				DoWindow/F $WindowNameStr // Make the window the top graph
//				ModifyImage/W=$WindowNameStr $w3dNameStr plane = num
//				variable/G dfr:gMXP_selectedZLayer = num
//			else
//				print "Cursor A not in graph"
//			endif
//		break
//	endswitch
//End
//
//
//Function MXP_PanelShowLayerCursorAAction(STRUCT WMButtonAction &B_Struct): ButtonControl
//	///
//	DFREF dfr =root:Packages:MXP_datafldr:ZBeamProfiles
//	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
//	NVAR/Z selectedZLayer = dfr:gMXP_selectedZLayer
//
//	switch(B_Struct.eventCode)	// numeric switch
//		case 2:
//			DoWindow/W=MXP_ZBeamLineProfilePanel/F MXP_ZLineProfilesPlot
//			Cursor/W=MXP_ZBeamLineProfilePanel#MXP_ZLineProfilesPlot /P A $LineProfileWaveStr selectedZLayer
//		break
//	endswitch
//End
//End


Function MXP_ProfilePanelCheckbox(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles")
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

Function [variable red, variable green, variable blue] MXP_GetColor(variable colorIndex)
	/// Give a RGB triplet for 16 distinct colors.
	/// https://www.wavemetrics.com/forum/general/different-colors-different-waves
    colorIndex = mod(colorIndex, 16)          // Wrap around if necessary
    switch(colorIndex)
        case 0:     // Time wave
            red = 0; green = 0; blue = 0;                               // Black
            break           
        case 1:
            red = 65535; green = 16385; blue = 16385;           // Red
            break           
        case 2:
            red = 2; green = 39321; blue = 1;                       // Green
            break          
        case 3:
            red = 0; green = 0; blue = 65535;                       // Blue
            break
        case 4:
            red = 39321; green = 1; blue = 31457;                   // Purple
            break
        case 5:
            red = 39321; green = 39321; blue = 39321;           // Gray
            break
        case 6:
            red = 65535; green = 32768; blue = 32768;           // Salmon
            break
        case 7:
            red = 0; green = 65535; blue = 0;                       // Lime
            break
        case 8:
            red = 16385; green = 65535; blue = 65535;           // Turquoise
            break
        case 9:
            red = 65535; green = 32768; blue = 58981;           // Light purple
            break
        case 10:
            red = 39321; green = 26208; blue = 1;                   // Brown
            break
        case 11:
            red = 52428; green = 34958; blue = 1;                   // Light brown
            break
        case 12:
            red = 65535; green = 32764; blue = 16385;           // Orange
            break
        case 13:
            red = 1; green = 52428; blue = 26586;                   // Teal
            break
        case 14:
            red = 1; green = 3; blue = 39321;                       // Dark blue
            break
        case 15:
            red = 65535; green = 49151; blue = 55704;           // Pink
            break
    endswitch
End

Function MXP_CleanGlobalWavesVarAndStrInFolder(DFREF dfr)
	/// Move from current working directory to dfr
	/// kill all global variables and strings and 
	/// return to the working directory
	
	DFREF cwd = GetDataFolderDFR()
	SetDataFolder dfr
	KillWaves/A
	KillVariables/A
	KillStrings/A
	SetDataFolder cwd
End



Function testit()
	variable red, green, blue	
	[red, green, blue] = IE_GetColor(12)
	print red, green, blue
	[red, green, blue] = IE_GetColor(7)
	print red, green, blue
End


///// 19.09.2022 N.B: I haven't checkt the code below
//===============================================================
//
// Functions to get multiple ROI using the drawing tools.
// Operation acts on the top window. We use the same
// window to plot the resulting profile (MXPCreateProfilePanel).
//
//===============================================================

//Function MXPAreaProfileFromManyROI()
//
//	DoWindow MXPWave3DStackViewer
//	// If Window has not been yet created
//	if (V_flag == 0)
//		//MXPInitializeAreaIntegrationProfiler()
//	endif
//	DoWindow/F MXPWave3DStackViewer // Bring the windows to the foreground, important for the commands that follow!
//	SetDrawLayer ProgFront // ImageGenerateROIMask needs this layer
//	SetDrawEnv linefgc= (65535,0,0),fillpat= 0, linethick = 0.5, xcoord= top,ycoord= left, save
//	String graphName = WinName(0,1) // Name of the top graph window
//	MXPUserDrawElements(graphName)
//End


Function MXPUserDrawElements(string graphName)

	DoWindow/F $graphName			// Bring graph to front
	
	if (V_Flag == 0)					// Verify that graph exists
		Abort "MXPUserDrawElements: No such graph."
		return -1
	endif
	Cursor/K J	//Removes cursor J from top graph
	
	ShowTools/A 	// Added for MXPAreaProfileFromManyROI()
	
	NewDataFolder/O root:tmp_PauseforDrawingDF
	Variable/G root:tmp_PauseforDrawingDF:canceled= 0

	NewPanel/K=2 /W=(139,341,382,450) as "Pause to draw elements"
	DoWindow/C tmp_PauseforDrawing			// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=$graphName			// Put panel near the graph
	
	String wname = WaveName(graphName, 0, 1)
	Struct WMButtonAction B_Struct

	//Name of the image in graphName
	String imgName = StringFromList(0,ImageNameList(graphName,";"))
	
	DrawText 5,20,"=== Draw ROI and then press Continue ==="
	Button button0,pos={80,30},size={92,20},title="Continue"
	Button button0,proc=MXPUserDrawElements_ContButtonProc,userdata=imgName
	Button button1,pos={80,55},size={92,20}
	Button button1,proc=MXPUserDrawElements_ClearButtonProc,userdata=graphName,title="Clear"
	Button button2,pos={80,80},size={92,20}
	Button button2,proc=MXPUserDrawElements_CancelButtonProc,title="Cancel"
	
	PauseForUser tmp_PauseforDrawing,$graphName

	NVAR gCanceled= root:tmp_PauseforDrawingDF:canceled
	Variable canceled= gCanceled			// Copy from global to local before global is killed
	KillDataFolder root:tmp_PauseforDrawingDF
	
	HideTools/A  // Added for MXPAreaProfileFromManyROI()
	
	return canceled 
End

Function MXPUserDrawElements_ContButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	SVAR profilestr = root:Packages:MXP3DImageProfiles:MXPAreaLineProfile // Name of the line profile

	switch(B_Struct.eventCode)	// numeric switch
		case 2:
				Wave M_ROIMask, W_PolyX, W_PolyY
				Wave w3d = $("root:Packages:MXP3DImageProfiles:" + B_Struct.userdata)
	 			Wave profile = $("root:Packages:MXP3DImageProfiles:" + profilestr)
	 			Wave buffer = root:Packages:MXP3DImageProfiles:TempMXPMatrixOPBuffer_del
		  		ImageGenerateROIMask/W=MXPWave3DStackViewer $B_Struct.userdata
		     	MatrixOP/O buffer = sum(w3d * M_ROIMask)
		     	MatrixOP/O profile = beam(buffer, 0 ,0)
		      // Save the regions used to get the profile
		      // See: DrawROIOnImage() for an important connection 
		      // with this function. There, both waves have to get
		      // killed (W_PolyX & W_PolyY) as the save routine will
		      // associate a profile to multiply regions when it is called
		      // and W_PolyX & W_PolyY are in the folder.
		      
		      // TODO: Change here to allow for literal wave names
				String name_suffix
				Prompt name_suffix, "Give suffix for W_PolyX(Y)_SUFFIX"	
				DoPrompt "Enter SUFFIX ([a-z0-9_]):", name_suffix
				String w_polyXstr = "W_PolyX_" + name_suffix
				String w_polyYstr = "W_PolyY_" + name_suffix
				String ROIMask_str = "ROIMask_" + name_suffix

		      DrawAction/W=MXPWave3DStackViewer ExtractOutline
		      if (WaveExists(W_PolyX) && WaveExists(W_PolyY))
					if (!WaveExists(root:Packages:MXP3DImageProfiles:SavedAreaProfiles:$ROIMask_str))
			      	Duplicate W_PolyX, root:Packages:MXP3DImageProfiles:SavedAreaProfiles:$w_polyXstr
			      	Duplicate W_PolyY, root:Packages:MXP3DImageProfiles:SavedAreaProfiles:$w_polyYstr
			      	Duplicate M_ROIMask, root:Packages:MXP3DImageProfiles:SavedAreaProfiles:$ROIMask_str
			      else
			      	print "Wave names exists, enter another suffix"
			      endif
		      endif
		      
			DoWindow/K tmp_PauseforDrawing			// Kill self
		break
	endswitch
End

Function MXPUserDrawElements_ClearButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2: 
		DoWindow/F $B_Struct.userdata
		DrawAction/W=$B_Struct.userdata delete // Clear the window
		// Set again the drawing env parameters.
		SetDrawLayer ProgFront // ImageGenerateROIMask needs this layer
		SetDrawEnv linefgc= (65535,0,0),fillpat= 0, linethick = 0.5, xcoord= top,ycoord= left, save
		break
	endswitch
End

Function MXPUserDrawElements_CancelButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:
			Variable/G root:tmp_PauseforDrawingDF:canceled= 1
			DoWindow/K tmp_PauseforDrawing			// Kill self
		break
	endswitch
	
End

//========================================================