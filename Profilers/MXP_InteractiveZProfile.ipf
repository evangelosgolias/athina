#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma rtFunctionErrors = 1 // Debug mode
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and late

#include <Image common>
#include <Imageslider>
#include "::Utilities:MXP_FolderOperations"
#include "::Plots and Graphs:MXP_Colors"

Menu "GraphMarquee"
	"Draw ROI", GetMarquee/K left,top; MXP_DrawImageROICursor(V_left, V_top, V_right, V_bottom)
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
	string/G dfr:gMXP_ProfileMetadata
	string/G dfr:gMXP_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gMXP_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gMXP_w3dNameStr = NameOfWave(w3dref)
	string/G dfr:gMXP_ProfileAreaOvalCoord
	variable/G dfr:gMXP_ROI_dx = dx
	variable/G dfr:gMXP_ROI_dy = dy
	variable/G dfr:gMXP_DoPlotSwitch = 0
	variable/G dfr:gMXP_colorcnt = 0
	variable/G dfr:gMXP_MarkAreasSwitch = 0
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


Function MXP_DrawImageROICursor(variable left, variable top, variable right, variable bottom) // Function used by the hook
	/// Here we use ProgFront to get a mask from ImageGenerateROIMask

	string wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 0.5, xcoord = top, ycoord = left
	DrawOval left, top, right, bottom
	Cursor/I/L=0/C=(65535, 0, 0, 30000)/S=2 J $wnamestr 0.5 * (left + right), 0.5 * (top + bottom)
End

Function MXP_DrawImageROI(variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
	SetDrawLayer UserFront 
	SetDrawEnv linefgc = (red, green, blue), fillpat = 0, linethick = 0.5, xcoord= top, ycoord= left
	DrawOval left, top, right, bottom
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
			MXP_DrawImageROICursor(-axisxlen * 0.5 + s.pointNumber * dx, axisylen * 0.5 + s.yPointNumber * dy, \
							 axisxlen * 0.5 + s.pointNumber * dx, -(axisylen * 0.5) + s.yPointNumber * dy)
			// We need to update the values here if we want to redraw
			V_left = -axisxlen * 0.5 + s.pointNumber * dx
        	V_top = axisylen * 0.5 + s.yPointNumber * dy
        	V_right = axisxlen * 0.5 + s.pointNumber * dx
        	V_bottom = -(axisylen * 0.5) + s.yPointNumber * dy
			ImageGenerateROIMask $w3dNameStr // Here we need name of a wave, not a wave reference!
			if(WaveExists(M_ROIMask))
				MatrixOP/FREE/O/NTHR=4 buffer = sum(w3d*M_ROIMask) // Use two threads
		   	 	MatrixOP/FREE/O profile_free = beam(buffer,0,0) 
		    		profile = profile_free
		    endif
		    hookresult = 1
	 		break
        case 5: // mouse up
        	// Updathe the V_ values to redraw the oval if needed
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
	CheckBox ShowProfile, pos={150.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ProfilePanelCheckboxPlotProfile,title="Plot profiles ", fSize=14, value= 0
	CheckBox ShowSelectedAread, pos={270.00,12.00}, side=1, size={70.00,16.00}, proc=MXP_ProfilePanelCheckboxMarkAreas,title="Mark areas ", fSize=14, value= 0

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
	NVAR/Z V_left, V_right, V_top, V_bottom
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles")
	SVAR/Z profilemetadata = dfr:gMXP_ProfileMetadata
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z w3dNameStr = dfr:gMXP_w3dNameStr
	SVAR/Z w3dPath = dfr:gMXP_w3dPath
	SVAR/Z ProfileAreaOvalCoord = dfr:gMXP_ProfileAreaOvalCoord
	Wave/SDFR=dfr profile = $LineProfileWaveStr// full path to wave
	NVAR/Z DoPlotSwitch = dfr:gMXP_DoPlotSwitch
	NVAR/Z MarkAreasSwitch = dfr:gMXP_MarkAreasSwitch
	NVAR/Z colorcnt = dfr:gMXP_colorcnt

	variable axisxlen = V_right - V_left 
	variable axisylen = V_bottom - V_top
	string recreateDrawStr
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
					
					if(MarkAreasSwitch)
						if(!DoPlotSwitch) // Have beed not set above?
							[red, green, blue] = MXP_GetColor(colorcnt)
						endif
						DoWindow/F $WindowNameStr
						MXP_DrawImageROI(V_left, V_top, V_right, V_bottom, red, green, blue)
						SetDrawLayer/W= $WindowNameStr ProgFront // Return to ProgFront
					endif
					
				break
				endif
			while(1)
		sprintf recreateDrawStr, "DrawCmd:DrawOval %f, %f, %f, %f;DrawEnv:SetDrawEnv xcoord= top, ycoord= left;", V_left, V_top, V_right, V_bottom
		Note savedfr:$saveWaveNameStr, recreateDrawStr
		break
	endswitch
End


Function MXP_ProfilePanelCheckboxPlotProfile(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
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


Function MXP_ProfilePanelCheckboxMarkAreas(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZBeamProfiles")
	NVAR/Z MarkAreasSwitch = dfr:gMXP_MarkAreasSwitch
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


Function MXP_UserDrawElements(string graphName)

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

Function MXP_UserDrawElements_ContButtonProc(B_Struct) : ButtonControl
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
		      // See: MXP_DrawImageROICursor() for an important connection 
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

Function MXP_UserDrawElements_ClearButtonProc(B_Struct) : ButtonControl
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

Function MXP_UserDrawElements_CancelButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:
			Variable/G root:tmp_PauseforDrawingDF:canceled= 1
			DoWindow/K tmp_PauseforDrawing			// Kill self
		break
	endswitch
	
End

//========================================================