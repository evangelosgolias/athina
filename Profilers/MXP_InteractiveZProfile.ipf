#pragma TextEncoding = "UTF-8"
#pragma rtGlobals    = 3		
#pragma IgorVersion  = 9
#pragma rtFunctionErrors = 1 // Debug mode
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later

#include <Image common>
#include <Imageslider>
#include "::Utilities:MXP_FolderOperations"



Menu "GraphMarquee"
	"Draw ROI", GetMarquee/K left,bottom; DrawROIOnImage(V_left, V_top, V_right, V_bottom)
End

//Menu "DataBrowserObjectsPopup", dynamic
//	"Tag", FunctionCall()
//End

Function MXP_InitialiseZProfilerFolder()
	/// All initialisation happens here. Folders, waves and local/global variables
	/// needed are created here.
	/// Use a a 3D wave in top window
	string imgNameTopWindowStr = RemoveEnding(ImageNameList("", ";"))
	if(!strlen(imgNameTopWindowStr)) // we do not have an image in top graph
		Abort "No image in top graph. Startup profile with an 3d wave at your active window."
	endif

	Wave w3dref = ImageNameToWaveRef("", imgNameTopWindowStr) // full path of wave
	
	if(WaveDims(w3dref) != 3)
		string msg
		sprintf msg, "Z-profiler works with 3d waves only. Wave %s is in top window", imgNameTopWindowStr
		Abort msg
	endif
	WMAppend3DImageSlider()
	string winNameStr = WinName(0, 1, 1)
	/// An instance of the profiler will store its data in
	/// root:Packages:MXP_datafldr:ZProfile0, root:Packages:MXP_datafldr:ZProfile1 ...
//	variable idx = 0
//	string basepath = "root:Packages:MXP_datafldr:ZProfile"
//	if(DataFolderExists(ParseFilePath(2, basepath + num2str(idx), ":", 0, 0)))
//		do
//			idx++
//		while(DataFolderExists(ParseFilePath(2, basepath + num2str(idx), ":", 0, 0)))
//	endif

	// Initialise the Package folder
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_datafldr:ZProfile") // Change root folder if you want
	
	variable nlayers = DimSize(w3dref, 2)	
	variable dx = DimDelta(w3dref, 0)
	variable dy = DimDelta(w3dref, 1)
	variable dz = DimDelta(w3dref, 2)
    variable z0 = DimOffset(w3dref, 2)
	
	string zprofilestr = NameOfWave(w3dref) + "_Zprof"
	Make/O/N=(nlayers) dfr:$zprofilestr /Wave = profile // Store the line profile 
	SetScale/P x, z0, dz, profile
	
	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopWindowStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_LineProfileWaveStr = zprofilestr // image profile wave
	string/G dfr:gMXP_ProfileMetadata = ""
	string/G dfr:gMXP_w3dPathname = GetWavesDataFolder(w3dref, 2)
	string/G dfr:gMXP_w3dPath = GetWavesDataFolder(w3dref, 1)
	string/G dfr:gMXP_3dNameStr = NameOfWave(w3dref)
	variable/G dfr:gMXP_ROI_dx = dx
	variable/G dfr:gMXP_ROI_dy = dy
	//SetDataFolder GetWavesDataFolderDFR(w3dref)
End

Function MXP_InitialiseZProfilerGraph()
	/// Here we will create the profile panel and graph and plot the profile
	if (WinType("wMXP_ZLineProfile") == 0) // line profile window is not displayed
		MXP_CreateProfilePanel()
	else
		DoWindow/F wMXP_ZLineProfile // if it is bring it to the FG
	endif
End

Function MXP_StartZProfiler()
	MXP_InitialiseZProfilerFolder()
	MXP_InitialiseZProfilerGraph()
	string wname = WinName(0, 1, 1)
	SetWindow $wname, hook(MyHook) = MXP_CursorHookFunctionForROIDraw // Set the hook
End


Function DrawROIOnImage(Variable l, Variable t, Variable r, Variable b)
	
	NVAR/Z V_left, V_top, V_right, V_bottom
	DFREF dfr = root:Packages:MXP_datafldr:ZProfile
	// Variable/G instead of NVAR to reset the values

//	// TODO: Get info about the profile area
//	String/G root:Packages:MXP3DImageProfiles:ProfileMetadata /N=pmdata
//	sprintf pmdata, "left=%d;top=%d;right=%d;bottom=%d;shape=%d;w3d=%s\n",V_left, V_top,V_right, V_bottom, shape, w3dname
//	pmdata += "Recreation command (top window)\n"
//	pmdata += "SetDrawEnv linefgc= (65535,0,0),fillpat= 0, linethick = 0.5, xcoord= top,ycoord= left\n"
//	String recrtncmd
//	sprintf recrtncmd, "DrawOval %d, %d, %d, %d", V_left, V_top,V_right, V_bottom
//	pmdata += recrtncmd
	
	String wnamestr = WMTopImageName() // Where is your cursor? // Use WM routine
	
	// Drawing env stuff
	SetDrawLayer ProgFront // ImageGenerateROIMask needs this layer
	SetDrawEnv linefgc= (65535,0,0),fillpat= 0, linethick = 0.5, xcoord= bottom,ycoord= left, save
	// Set the cursor J, A=0 -> Do not move Cursor with keyboard
	Cursor/I/A=0/L=0/C=(65535,0,0,30000)/S=2 J $wnamestr 0.5 * (l + r), 0.5 * (t + b)
	DrawOval l, t, r, b

End


Function MXP_CursorHookFunctionForROIDraw(STRUCT WMWinHookStruct &s)
	// Windows hook function to handle events. You can to link the hook function with
	// a window, for example using with
	//
	// SetWindow #, hook(MyHook) = MXPCursorHookFunctionForROIDraw
    
    Variable hookResult = 0
	DFREF dfr = root:Packages:MXP_datafldr:ZProfile
	NVAR/Z V_left, V_top, V_right, V_bottom
	NVAR/Z dx = dfr:gMXP_ROI_dx
	NVAR/Z dy = dfr:gMXP_ROI_dy
	variable axisxlen = V_right - V_left 
	variable axisylen = V_bottom - V_top

	SVAR/Z profilemetadata = dfr:gMXP_ProfileMetadata
	SVAR/Z LineProfileWaveStr = dfr:gMXP_LineProfileWaveStr
	SVAR/Z WindowNameStr = dfr:gMXP_WindowNameStr
	SVAR/Z imgNameTopWindowStr = dfr:gMXP_imgNameTopWindowStr
	SVAR/Z w3dPathname = dfr:gMXP_w3dPathname
	SVAR/Z w3dNameStr = dfr:gMXP_3dNameStr
	SVAR/Z w3dPath = dfr:gMXP_w3dPath
	DFREF w3d_dfr = $w3dPath
	Wave/SDFR=w3d_dfr w3d = $w3dNameStr
	Wave profile = dfr:$LineProfileWaveStr// full path to wave
	Wave/Z M_ROIMask


	// 24.05.22 test if without MatrixOP we can be faster 
	Variable i, j
    switch(s.eventCode)
//        case 6:
//        case 12: //Window moved or resized
//        		if(WinType("MXPProfilePanel")==7) // We have a panel here
//        			AutopositionWindow/M=0/R=MXPWave3DStackViewer MXPProfilePanel // Linked to MXPProfilePanel 
//        			DoWindow/F MXPProfilePanel
//        		endif
//        		
//        		if(WinType("MXPProfilesPlot")==1)
//        			AutopositionWindow/M=1/R=MXPProfilePanel MXPProfilesPlot
//        			DoWindow/F MXPProfilesPlot
//        		endif
//        		break
//        		
//	 	case 3:
//	 				        DrawAction delete
//
//	 		print "Mouse down"
        case 7: // Cursor moved
		        DrawAction delete
				DrawROIOnImage(-axisxlen * 0.5 + s.pointNumber * dx, axisylen * 0.5 + s.yPointNumber * dy, \
							 axisxlen * 0.5 + s.pointNumber * dx, -(axisylen * 0.5) + s.yPointNumber * dy)
				ImageGenerateROIMask w3d // Cannot launch it from another folder.
//				MatrixOP/O buffer = sum(w3dname*M_ROIMask)
//		     	MatrixOP/O profile = beam(buffer,0,0)
//		     	
//		     	for(i=0;i<1024;i+=1)
//		     		for(j=0;j<1024;j+=1)
//		     			if(M_ROIMask[i][j])
//		     			profile += w3d[i][j][p]
//		     			endif
//		     		endfor
//		     	endfor
		     	
	 			break
//        case 5: // mouseup
//        	print "Mouse up"
//		  			//ImageGenerateROIMask/W=MXP_ZProfilePanel $profilestr
//		      		//MatrixOP/O buffer = sum(w3d*M_ROIMask)
//		     	 	//MatrixOP/O profile = beam(buffer,0,0)
//		     	    //Note/K profile, pmdata
//				break
    endswitch
    
    return hookResult       // 0 if nothing done, else 1
End


Function MXP_CreateProfilePanel()
	 
	NewPanel/N=wMXP_ZLineProfile /W=(580,53,995,316) // Linked to MXPInitializeAreaIntegrationProfiler()
	ModifyPanel cbRGB=(61166,61166,61166), frameStyle=3
	SetDrawLayer UserBack
	Button SaveProfileButton,pos={220.00,10.00},size={80.00,20.00},proc=MXPPanelSaveProfile,title="Save Profile"
	Button SaveProfileButton,help={"Save current profile"}
	Button SaveProfileButton,valueColor=(1,12815,52428)
	Button ShowCursorALayer,pos={28.00,10.00},size={80.00,20.00},proc=MXPPanelShowCursorALayerAction,title="Layer <- A"
	Button ShowCursorALayer,help={"Set cursor from layer n"},valueColor=(0,26214,13293)
	CheckBox ShowProfile,pos={310.00,12.00},side=1,size={70.00,16.00},proc=MXPProfilePanelCheckbox,title="Plot profiles"
	CheckBox ShowProfile,fSize=12,value= 0
	Button ShowLayerCursorA,pos={122.00,10.00},size={80.00,20.00},proc=MXPPanelShowLayerCursorAAction,title="Layer -> A"
	Button ShowLayerCursorA,help={"Set layer from cursor A"},valueColor=(65535,0,0)

	DFREF dfr = root:Packages:MXP_datafldr:ZProfile
	SVAR/SDFR=dfr gMXP_LineProfileWaveStr
	Wave profile = dfr:$gMXP_LineProfileWaveStr
	
	if (WaveExists(profile))
		Display/N=wMXP_ZLineProfile/W=(15,38,391,236)/HOST=#  profile
		ModifyGraph rgb=(1,12815,52428), tick(left)=2, fSize=12, lsize=1.5
		Label left "\\u#2 Intensity (arb. u.)";DelayUpdate
		Label bottom "\\u#2 Energy (eV)"
	else
		Abort "Cannot find the line profile wave, check MXP_CreateProfilePanel()"
	endif

	SetDrawLayer UserFront
End


Function MXPPanelSaveProfile(B_Struct): ButtonControl

	STRUCT WMButtonAction &B_Struct
	DFREF dfr = root:Packages:MXP_datafldr:ZProfile
	SVAR basename = root:Packages:MXP3DImageProfiles:MXPCopyOf3DWave
	SVAR profile = root:Packages:MXP3DImageProfiles:MXPAreaLineProfile
	NVAR plot_switch = root:Packages:MXP3DImageProfiles:MXP_PlotSavedProfilesSwitch
	
	Variable postfix = 0
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
		
			do
				String wnamestr = "root:Packages:MXP3DImageProfiles:SavedAreaProfiles:" + basename + num2str(postfix)
				if(Exists(wnamestr) == 1)
					postfix+=1
				else
					String duplwv = "root:Packages:MXP3DImageProfiles:" + profile
					Duplicate $duplwv, $wnamestr
					
					
					// Here take care and use the current working directory. Fix the dings everywhere to be consistent. 
					// Otherwise it will not work of waves are not in the folder they are supposed to be
					
					if(WaveExists(root:Packages:MXP3DImageProfiles:W_PolyX) && WaveExists(root:Packages:MXP3DImageProfiles:W_PolyY))
						MoveWave root:Packages:MXP3DImageProfiles:W_PolyX, root:Packages:MXP3DImageProfiles:SavedAreaProfiles:$("W_PolyX_"+num2str(postfix))
						MoveWave root:Packages:MXP3DImageProfiles:W_PolyY, root:Packages:MXP3DImageProfiles:SavedAreaProfiles:$("W_PolyY_"+num2str(postfix))
					endif
					postfix = 0
					if(plot_switch)
						if(WinType("MXPProfilesPlot") ==1)
							AppendToGraph/W=MXPProfilesPlot $wnamestr
						else
							Display/N=MXPProfilesPlot  $wnamestr
							AutopositionWindow/M=1/R=MXPProfilePanel MXPProfilesPlot
						endif
					endif
				break
				endif
			while(1)		
			
			break
	endswitch
End


Function MXPPanelShowCursorALayerAction(B_Struct): ButtonControl

	STRUCT WMButtonAction &B_Struct
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:
			Variable num = pcsr(A, "MXPProfilePanel#MXPProfileGraph")
			if(numtype(num)!=2) // if pcsr returns NaN
				ModifyImage/W=MXPWave3DStackViewer newPED_cp plane = num
				Variable/G root:Packages:WM3DImageSlider:MXPWave3DStackViewer:gLayer = num
			else
				print "Cursor A not in graph"
			endif
		break
	endswitch
End


Function MXPPanelShowLayerCursorAAction(B_Struct): ButtonControl

	STRUCT WMButtonAction &B_Struct
	SVAR profile = root:Packages:MXP3DImageProfiles:MXPAreaLineProfile
	
	switch(B_Struct.eventCode)	// numeric switch
		case 2:
			NVAR gLayer = root:Packages:WM3DImageSlider:MXPWave3DStackViewer:gLayer
			Cursor/W=MXPProfilePanel#MXPProfileGraph/P A $profile gLayer
		break
	endswitch
End
End


Function MXPProfilePanelCheckbox(cb) : CheckBoxControl
	STRUCT WMCheckboxAction& cb
	
	switch(cb.checked)
		case 1:		// Mouse up
			Variable/G root:Packages:MXP3DImageProfiles:MXP_PlotSavedProfilesSwitch = 1
			break
		case 0:
			Variable/G root:Packages:MXP3DImageProfiles:MXP_PlotSavedProfilesSwitch = 0
			break
	endswitch

	return 0
End


//===============================================================
//
// Functions to get multiple ROI using the drawing tools.
// Operation acts on the top window. We use the same
// window to plot the resulting profile (MXPCreateProfilePanel).
//
//===============================================================

Function MXPAreaProfileFromManyROI()

	DoWindow MXPWave3DStackViewer
	// If Window has not been yet created
	if (V_flag == 0)
		//MXPInitializeAreaIntegrationProfiler()
	endif
	DoWindow/F MXPWave3DStackViewer // Bring the windows to the foreground, important for the commands that follow!
	SetDrawLayer ProgFront // ImageGenerateROIMask needs this layer
	SetDrawEnv linefgc= (65535,0,0),fillpat= 0, linethick = 0.5, xcoord= top,ycoord= left, save
	String graphName = WinName(0,1) // Name of the top graph window
	MXPUserDrawElements(graphName)
End


Function MXPUserDrawElements(String graphName)

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