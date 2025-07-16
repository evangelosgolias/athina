#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.2.0		
#pragma igorversion=8		//Require Igro 8 and greater because there might be long names  
#pragma moduleName=IE_IgorThief2
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


// Copied the file from: https://www.wavemetrics.com/node/22225


static constant kProjectID=22225
static strconstant ksShortTitle="IgorThief2"

//IgorThief2 is an update to the IgorThief package for digitizing data. It works on arbitrarily rotated data, and is best for data shown as markers.  
//If you want to digitize data shown as lines, you should use the Tracer package by Igor forums member tony (https://www.wavemetrics.com/project/tracer).  
//IgorThief2 borrows several elements from Tracer, such as using cursors to set the axis min/max points and the ability to load images from the clipboard,
//but it is mostly based on the original IgorThief package.  

//The user can change these constants
STATIC CONSTANT kvDefault_Notebook_Size=12			//Font size for the help notebook.
STATIC CONSTANT kvUse_Lines_as_Default=1			//Sets the default cursor style
STATIC CONSTANT kvShow_Info_Bar=1					//Show the cursor info bar when making the graph
STATIC CONSTANT kvWarn_Before_Closing_Window=0		//Warn the user when closing the graph window
STATIC CONSTANT kvAuto_Reverse_Axes=1				//Will automatically reverse the scale on axes based on the image wave scaling and the user input values for the image axis ranges 

//Default starting window size.  The window will be resized once the image is loaded.
//STATIC CONSTANT kIgorThiefGraphWidthPixels= 800
//STATIC CONSTANT kIgorThiefGraphHeightPixels= 600

STATIC CONSTANT kIgorThiefGraphWidthPixels= 400
STATIC CONSTANT kIgorThiefGraphHeightPixels= 340


//Generally the user shouldn't change these, but they can if they really want to.
STATIC CONSTANT kvKill_Data_Folder=1			//Removes the data folder containing the waves on the image that show the tracing.  I don't think you need these waves after you have digitized the data.
STATIC STRCONSTANT kstrStarting_Cursor="A"		//Cursors are used to set the axis min/max values.  Uses 4 cursors starting with the one listed here.  


//The user should not change any of these constants
STATIC CONSTANT kvControl_Bar_Height=115
STATIC CONSTANT kvSetVar_Body_Width=60		//Width of the setvars that go with the cursors

STATIC CONSTANT kPDFmin = 500 // size in points for smallest dimension of bitmap created from vector graphics

// Makes the graph with the controls
STATIC FUNCTION Graph_Creation()

	String strGraph_Tag=Graph_Get_Unique_Index()
	String strGraph_Name="IgorThiefGraph_"+strGraph_Tag
	
	DFREF dfrCurrent_Data_Folder=GetDataFolderDFR()
	
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S $"root:Packages:ATH_DataFolder:IgorThief_"+strGraph_Tag
	Make/O/D/N=0 Tracing_X_Wave, Tracing_Y_Wave
	
	SetDataFolder dfrCurrent_Data_Folder
	
	Variable vGraph_left= 40
	Variable vGraph_right=vGraph_left+kIgorThiefGraphWidthPixels / ScreenResolution * 72
	Display/K=(!kvWarn_Before_Closing_Window)/W=(vGraph_left,40,vGraph_right,kIgorThiefGraphHeightPixels+kvControl_Bar_Height)/N=$strGraph_Name as strGraph_Name
	IF(kvShow_Info_Bar)
		Variable vStart_Cursor=char2num(UpperStr(kstrStarting_Cursor))-65
		IF(mod(vStart_Cursor,2)==0)
			ShowInfo/W=$strGraph_Name/CP={vStart_Cursor,vStart_Cursor+1}
		ELSE
			ShowInfo/W=$strGraph_Name/CP={vStart_Cursor-1,vStart_Cursor,vStart_Cursor+1}
		ENDIF
	ENDIF
	
	ControlBar kvControl_Bar_Height

	//Build the user interface
	DefaultGuiFont/W=#/Mac popup={"_IgorSmall",0,0},all={"_IgorSmall",0,0}
	DefaultGuiFont/W=#/Win popup={"_IgorSmall",0,0},all={"_IgorSmall",0,0}
	
	//Controls whose names start with V are always enabled, controls with names that start with H are always hidden, and controls whose names start with T
	//are disabled depending on what is going on
	
	Button V0_Button_Help,pos={5.00,3.00},size={50.00,20.00}, proc=IgorThief2#Help_Button,title="Help",fSize=11,fStyle=1,fColor=(49151,65535,49151)
	
	TitleBox V0_Title_ToDo,pos={60.00,3.00},size={165.00,24.00},frame=5,fColor=(65535,0,0), fSize=12, fStyle=1, title="To start, select an image"
	
	PopupMenu T1_Pop_Image_Name,pos={5,27.00},size={87.00,20.00},title="1. Select image",proc=IgorThief2#Image_Pop_Load_Change_Image, mode=1,popvalue="New Image",value=#"\"New Image;\"+sortlist(WaveList(\"*\", \";\", \"TEXT:0,DIMS:2\")+WaveList(\"*\", \";\", \"TEXT:0,DIMS:3\"), \";\", 16)"

	TitleBox T2_Title_Points_Lines,pos={5.00,49.00},size={118.00,16.00},title="Set axis min/max with:",frame=0,disable=2
	CheckBox T2_Check_Use_Lines,pos={4,69.00},size={43.00,16.00},title="Lines",value=kvUse_Lines_as_Default,mode=1,help={"Set the axis min/max locations with lines.  Use if the graph is unrotated."},proc=IgorThief2#Graph_CheckBox_Use_Points_Lines,disable=2
	CheckBox T2_Check_Use_Points,pos={70,69},size={56.00,16.00},title="Points",value=!kvUse_Lines_as_Default,mode=1,help={"Set XY points for the axis min/max locations.  Use if the graph is rotated."},proc=IgorThief2#Graph_CheckBox_Use_Points_Lines,disable=2
	
	PopupMenu T2_Pop_X_Axis_Type,pos={136.00,48.00},size={108.00,20},title="2a. X axis:",mode=1,popvalue="Linear",value=#"\"Linear;Log10;ln;Recip;Sqrt\"",proc=IgorThief2#Graph_Pop_Axis_Type,disable=2
	PopupMenu T2_Pop_Y_Axis_Type,pos={136.00,69.00},size={108.00,20},title="2b. Y axis:",mode=1,popvalue="Linear",value=#"\"Linear;Log10;ln;Recip;Sqrt\"",proc=IgorThief2#Graph_Pop_Axis_Type,disable=2

//	CheckBox T2_Checkbox_Log_X_Axis,pos={141,51},size={50,25},title="2a. Log X",value=0, proc=IgorThief2#Graph_CheckBox_Log_Axes,disable=2
//	CheckBox T2_Checkbox_Log_Y_Axis,pos={141,72},size={50,25},title="2b. Log Y",value=0, proc=IgorThief2#Graph_CheckBox_Log_Axes,disable=2
	
	PopupMenu T3_Pop_X_Wave, mode=1,pos={250,48.00},size={135.00,20.00},title="3a. X Data", proc=IgorThief2#Graph_Pop_Wave_Selection,value=#"\"New Wave;\"+sortlist(WaveList(\"*\", \";\", \"TEXT:0,MAXCOLS:0\"), \";\", 16)",disable=2
	PopupMenu T3_Pop_Y_Wave, mode=1,pos={249,69.00},size={135.00,20.00},title="3b. Y Data", proc=IgorThief2#Graph_Pop_Wave_Selection,value=#"\"New Wave;\"+sortlist(WaveList(\"*\", \";\", \"TEXT:0,MAXCOLS:0\"), \";\", 16)",disable=2

	Button T4_Button_Digitize,pos={5,90},size={110,20},proc=IgorThief2#Digitization_Button_Start_Stop,title="4a. Start Digitizing",disable=2
	
	Button T5_Button_Edit,pos={120,90},size={95,20},proc=IgorThief2#Editing_Button_Start_Stop,title="5a. Start Editing",disable=2
	
	String strCoordinate
	sprintf strCoordinate, "%5g", NaN
	TitleBox T2_Title_Coordinates_X,pos={225,90},size={100,20.00},font="Consolas",fSize=16,fstyle=1,frame=0,title="\\K(0,0,60000)X="+strCoordinate,disable=2
	TitleBox T2_Title_Coordinates_Y,pos={340,90},size={100,20.00},font="Consolas",fSize=16,fstyle=1,frame=0,title="\\K(60000,0,0)Y="+strCoordinate,disable=2
	
	SetVariable H0_SetVar_Graph_Tag,pos={5,5},disable=1,value=_STR:strGraph_Tag
	
	SetVariable H0_SetVar_Are_Moving_Csr_SetVar,pos={5,5},disable=1,value=_NUM:0,userdata=""
	SetVariable H0_SetVar_Are_Digitizing, pos={5.00,3.00},size={50.00,20.00},disable=1, value=_NUM:0
	SetVariable H0_SetVar_Are_Editing, pos={5.00,3.00},size={50.00,20.00},disable=1, value=_NUM:0
	
	//Install window hook for top window, asking for mouse up/down and moved events
	SetWindow kwTopWin, hook(Mouse_Hook)=IgorThief2#Graph_Hook_Mouse

END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Gets a unique index for the graphs and datafolders.  Can't conflict with any graphs, graph macros, or data folders
STATIC FUNCTION/S Graph_Get_Unique_Index()

	Variable vCheck_Data_Folder=DataFolderExists("root:Packages")
	
	DFREF dfrCurrent_Data_Folder=GetDataFolderDFR()
	
	IF(vCheck_Data_Folder)
		SetDataFolder root:Packages
	ENDIF
	
	Variable vStart_Index=-1, vFlag=0
	DO
		vStart_Index+=1
		
		String strNew_Image_Graph_Index=ParseFilePath(0, UniqueName("IgorThiefGraph_", 6, vStart_Index), "_", 1, 0)
		String strNew_Digitized_Graph_Index=ParseFilePath(0, UniqueName("DigitizedData_", 6, vStart_Index), "_", 1, 0)
		vFlag=(cmpstr(strNew_Image_Graph_Index, strNew_Digitized_Graph_Index)!=0)
		
		IF(vCheck_Data_Folder)
			String strNew_Folder_Index=ParseFilePath(0, UniqueName("IgorThief_", 11, vStart_Index), "_", 1, 0)
			vFlag=vFlag || cmpstr(strNew_Image_Graph_Index, strNew_Folder_Index)!=0
		ENDIF
	WHILE(vFlag)
	
	SetDataFolder dfrCurrent_Data_Folder
	
	Return strNew_Image_Graph_Index
	
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Handles mouse clicks in window appropriately, depending on current action.  Also handles some menu actions.  
STATIC FUNCTION Graph_Hook_Mouse(STRUCT WMWinHookStruct &s)
	
	String strGraph_Name=s.winName		//I can get the graph name from the STRUCT, but doing this makes it easier to copy code from one function to another
	String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)

	ControlInfo/W=$strGraph_Name T3_Pop_X_wave	//The popup displays the wave name, but the full path is in UserData
	String strX_Wave=S_UserData
	
	ControlInfo/W=$strGraph_Name T3_Pop_Y_wave
	String strY_Wave=S_UserData
	
	ControlInfo/W=$strGraph_Name H0_SetVar_Are_Moving_Csr_SetVar
	Variable vMoving_SetVar=V_Value
	String strCsr_SetVar_Info=S_Userdata
	String strCsr_Name=StringByKey("Csr_Name", strCsr_SetVar_Info,"=")
		
	ControlInfo/W=$strGraph_Name H0_SetVar_Are_Digitizing
	Variable vAre_Digitizing=V_Value
	
	ControlInfo/W=$strGraph_Name H0_SetVar_Are_Editing
	Variable vAre_Editing=V_Value
	
	ControlInfo/W=$strGraph_Name T1_Pop_Image_Name
	String strImage_Wave=S_UserData
	
	WAVE/Z Image_Wave=$strImage_Wave
	Make/O/D/FREE/N=2 DimDelta_Values={DimDelta(Image_Wave, 0), DimDelta(Image_Wave, 1)}		//I don't totally understand why I need these for converting the pixels to x and y coordinates
	
	String strImage_On_Graph=StringFromList(0, ImageNameList(strGraph_Name, ";"))
	WAVE/Z Image_Wave_on_Graph=ImageNameToWaveRef(strGraph_Name, strImage_On_Graph)
	Variable vHave_Image=WaveRefsEqual(Image_Wave, Image_Wave_on_Graph)		//This will return 0 if neither wave exists
	
	variable vX_Val=0,vY_Val=0	// digitized values
		
	Variable vMouse_Moved=cmpstr(s.eventName,"mousemoved")==0
	Variable vMouse_Up=cmpstr(s.eventName,"mouseup")==0
		
	IF(vMouse_Moved || vMouse_Up)		
		Variable vMouse_Pixel_X=s.mouseLoc.h		//Get mouse location
		Variable vMouse_Pixel_Y=s.mouseLoc.v
		
		IF((vMouse_Pixel_X<0) || (vMouse_Pixel_Y<0))		//If mouse location in control bar, ignore.
			return 0
		ENDIF
		
		//Convert pixels to x and y values.
		Variable vMouse_Axis_X=AxisValFromPixel(strGraph_Name, "bottom", vMouse_Pixel_X)
		Variable vMouse_Axis_Y=AxisValFromPixel(strGraph_Name, "left", vMouse_Pixel_Y)
	ENDIF
		
	STRSWITCH(s.eventName)
		CASE "renamed":
			ControlInfo/W=$strGraph_Name H0_SetVar_Graph_Tag
			String strGraph_Tag_Old=S_Value
			
			DoWindow/T $"IgorThiefGraph_"+strGraph_Tag, "IgorThiefGraph_"+strGraph_Tag
		
			IF(DataFolderExists("root:Packages:ATH_DataFolder:IgorThief_"+strGraph_Tag_Old))
				RenameDataFolder $"root:Packages:ATH_DataFolder:IgorThief_"+strGraph_Tag_Old, $"IgorThief_"+strGraph_Tag
			ENDIF
			
			IF(WinType("DigitizedData_"+strGraph_Tag_Old)==1)
				RenameWindow $"DigitizedData_"+strGraph_Tag_Old, $"DigitizedData_"+strGraph_Tag
				DoWindow/T $"DigitizedData_"+strGraph_Tag, "DigitizedData_"+strGraph_Tag
			ENDIF
			
			SetVariable H0_SetVar_Graph_Tag,value=_STR:strGraph_Tag
		BREAK
	
		CASE "kill":
			DoWindow/K $"DigitizedData_"+strGraph_Tag
			
			String strIgor_Thief_Graphs=WinList("IgorThiefGraph_*", ";", "WIN:1")		//Only kill the help window if there won't be any other IgorThief graphs
			IF(ItemsInList(strIgor_Thief_Graphs)<=1)
				DoWindow/K IgorThief2Help
			ENDIF
			
			IF(kvKill_Data_Folder)		//Clean up the data folders
				String strTrace_Names_List=TraceNameList(strGraph_Name, ";", 1)
				
				Int iTraceDex
				FOR(iTraceDex=(ItemsInList(strTrace_Names_List)-1);iTraceDex>=0;iTraceDex-=1)
					RemoveFromGraph/W=$strGraph_Name/Z $StringFromList(iTraceDex, strTrace_Names_List)
				ENDFOR
								
				KillDataFolder/Z $"root:Packages:ATH_DataFolder:IgorThief_"+strGraph_Tag
				
				IF(CountObjectsDFR(root:Packages, 4)==0)				//Kill Packages datafolder if empty
					KillDataFolder/Z root:Packages
				ENDIF
			ENDIF
		BREAK
		
		CASE "mousedown":
			IF(vAre_Digitizing && !(s.eventmod & 8))
				return 1	//Don't accidentally double-click to get a dialog.  Allow the user to access menus like the Zoom options if they hold down the command/control button.
			ENDIF
		BREAK
		
		CASE "mousemoved":
			IF(vHave_Image)				
				String strX_Coordinates, strY_Coordinates
				
				[vX_Val, vY_Val]=Digitization_Axis_XY_to_Data_XY(vMouse_Axis_X, vMouse_Axis_Y, strGraph_Name, DimDelta_Values)
				sprintf strX_Coordinates, "\\K(0,0,60000)X="+SelectString(abs(vX_Val)>1e4 || abs(vX_Val)<1e-2, "%5g", "%0.4e"),vX_Val
				sprintf strY_Coordinates, "\\K(60000,0,0)Y="+SelectString(abs(vY_Val)>1e4 || abs(vY_Val)<1e-2, "%5g", "%0.4e"),vY_Val
				
				TitleBox T2_Title_Coordinates_X, win=$strGraph_Name, title=strX_Coordinates
				TitleBox T2_Title_Coordinates_Y, win=$strGraph_Name, title=strY_Coordinates
			
				//User is holding down command/control and the moving setvar flag is set, so allow the user to move the cursor setvars around
				IF(s.eventmod & 8 && vMoving_SetVar)
					s.doSetCursor = 1
					s.cursorCode = 13
				
					Variable vCursor_Pixel_X=Graph_Get_Csr_Pixel_Position(strGraph_Name, "bottom", strCsr_Name)					
					Variable vCursor_Pixel_Y=Graph_Get_Csr_Pixel_Position(strGraph_Name, "left", strCsr_Name)
				
					Variable vSetVar_Mouse_Offset_X=str2num(StringByKey("X_Offset", strCsr_SetVar_Info,"="))
					Variable vSetVar_Mouse_Offset_Y=str2num(StringByKey("Y_Offset", strCsr_SetVar_Info,"="))
				
					ControlInfo/W=$strGraph_Name $"Csr_Title_1_"+strCsr_Name
					Variable vCsr_Title_1_Height=V_Height
				
					//Some of the math is a little weird, but it's from fine tuning stuff manually and probably should be updated at some point.
					Variable vSetVar_Pos_X=limit(vMouse_Pixel_X+vSetVar_Mouse_Offset_X, vCursor_Pixel_X-70, vCursor_Pixel_X+10)
					Variable vSetVar_Csr_Offset_X=vSetVar_Pos_X-vCursor_Pixel_X
					Variable vTitle_1_X_Offset=(vSetVar_Pos_X+kvSetVar_Body_Width/2)>vCursor_Pixel_X ? vSetVar_Pos_X-20 : vSetVar_Pos_X+kvSetVar_Body_Width+3
					Variable vTitle_2_X_Offset=(vSetVar_Pos_X+kvSetVar_Body_Width/2)>vCursor_Pixel_X ? vSetVar_Pos_X-17 : vSetVar_Pos_X+kvSetVar_Body_Width+6
					
					Variable vSetVar_Pos_Y=limit(vMouse_Pixel_Y+vSetVar_Mouse_Offset_Y, vCursor_Pixel_Y-30, vCursor_Pixel_Y+10)
					Variable vSetVar_Csr_Offset_Y=vSetVar_Pos_Y-vCursor_Pixel_Y
					Variable vTitle_1_Y_Offset=vSetVar_Pos_Y-3
					Variable vTitle_2_Y_Offset=vTitle_1_Y_Offset+vCsr_Title_1_Height-4
					
					SetVariable $"Csr_SetVar_"+strCsr_Name, win=$strGraph_Name, pos={vSetVar_Pos_X, vSetVar_Pos_Y+kvControl_Bar_Height}, userData="X_Offset="+num2str(vSetVar_Csr_Offset_X)+";Y_Offset="+num2str(vSetVar_Csr_Offset_Y)+";"
					
					TitleBox $"Csr_Title_1_"+strCsr_Name, win=$strGraph_Name, pos={vTitle_1_X_Offset, vTitle_1_Y_Offset+kvControl_Bar_Height}
					TitleBox $"Csr_Title_2_"+strCsr_Name, win=$strGraph_Name, pos={vTitle_2_X_Offset, vTitle_2_Y_Offset+kvControl_Bar_Height}
					
				ELSEIF(!(s.eventmod & 8) && vMoving_SetVar)		//If the user stops holding command/control, reactivate the setvars
					ModifyControl/Z $"Csr_SetVar_"+strCsr_Name, win=$strGraph_Name, disable=0
					SetVariable H0_SetVar_Are_Moving_Csr_SetVar, win=$strGraph_Name, value=_NUM:0,userdata=""
					
					TitleBox T2_Title_Points_Lines,win=$strGraph_Name, disable=0
					CheckBox T2_Check_Use_Points,win=$strGraph_Name, disable=0
					CheckBox T2_Check_Use_Lines,win=$strGraph_Name, disable=0
				ENDIF
			ENDIF
		BREAK
		
		CASE "mouseup":
			IF(vAre_Digitizing && !(s.eventmod & 8))

				[vX_Val, vY_Val]=Digitization_Axis_XY_to_Data_XY(vMouse_Axis_X, vMouse_Axis_Y, strGraph_Name, DimDelta_Values)
				//Reference x and y data waves, and append digitized point.
				WAVE Data_X_Wave=$strX_Wave	// strings contain full path to waves
				WAVE Data_Y_Wave=$strY_Wave
				Variable vNum_Data_X_Pnts=DimSize(Data_X_Wave,0)
				Variable vNum_Data_Y_Pnts=DimSize(Data_Y_Wave,0)
				// eliminate duplicates from double-clicking
				IF(Data_X_Wave[vNum_Data_X_Pnts-1] == vX_Val && Data_Y_Wave[vNum_Data_Y_Pnts-1] ==vY_Val)
					break
				ENDIF
				
				Redimension/N=(vNum_Data_X_Pnts+1) Data_X_Wave
				Redimension/N=(vNum_Data_Y_Pnts+1) Data_Y_Wave
				Data_X_Wave[vNum_Data_X_Pnts]=vX_Val
				Data_Y_Wave[vNum_Data_Y_Pnts]=vY_Val
				
				// update trace in digitizing graph
				WAVE/Z Tracing_Y_Wave = TraceNameToWaveRef(strGraph_Name, "Tracing_Y_Wave")
				IF(WaveExists(Tracing_Y_Wave))
					WAVE Tracing_X_Wave= XWaveRefFromTrace(strGraph_Name, "Tracing_Y_Wave")
					Variable vNum_Tracing_X_Pnts=DimSize(Tracing_X_Wave,0)
					Variable vNum_Tracing_Y_Pnts=DimSize(Tracing_Y_Wave,0)
					Redimension/N=(vNum_Tracing_X_Pnts+1) Tracing_X_Wave
					Redimension/N=(vNum_Tracing_Y_Pnts+1) Tracing_Y_Wave
					Tracing_X_Wave[vNum_Tracing_X_Pnts]=vMouse_Axis_X
					Tracing_Y_Wave[vNum_Tracing_Y_Pnts]=vMouse_Axis_Y
				ENDIF		//End making sure the tracing waves exist
			
			ELSEIF(vMoving_SetVar)		//User releases the setvar for the axis min/max
				ModifyControl/Z $"Csr_SetVar_"+strCsr_Name, win=$strGraph_Name, disable=0
				SetVariable H0_SetVar_Are_Moving_Csr_SetVar, win=$strGraph_Name, value=_NUM:0,userdata=""
				
				TitleBox T2_Title_Points_Lines,win=$strGraph_Name, disable=0
				CheckBox T2_Check_Use_Points,win=$strGraph_Name, disable=0
				CheckBox T2_Check_Use_Lines,win=$strGraph_Name, disable=0
			ENDIF
		BREAK
	
		CASE "enablemenu":
			// Provide Undo for digitzing
			IF(vAre_Digitizing)
				WAVE/Z Data_Y_Wave=$strY_Wave
				IF(DimSize(Data_Y_Wave,0) > 0 )
					SetIgorMenuMode "Edit", "Undo", EnableItem
				ENDIF
			ENDIF
		BREAK
		
		CASE "menu":
			//Let's the user duplicate the graph, assuming that you aren't digitizing or editing
			IF(cmpstr(s.menuName,"Edit") == 0 && cmpstr(s.menuItem,"Duplicate")==0 && !vAre_Digitizing && !vMoving_SetVar && !vAre_Editing)	
				Variable vWindow_Offset=10
				
				String strNew_Index=Graph_Get_Unique_Index()
				
				String strNew_Data_Folder="root:Packages:ATH_DataFolder:IgorThief_"+strNew_Index
				DuplicateDataFolder/O=1/Z $"root:Packages:ATH_DataFolder:IgorThief_"+strGraph_Tag, $strNew_Data_Folder
				
				String strNew_Image_Graph_Name="IgorThiefGraph_"+strNew_Index
				
				String strImage_Graph_Recreation_Info = WinRecreation(strGraph_Name, 0)
				Execute/Z strImage_Graph_Recreation_Info
				
				GetWindow/Z $strGraph_Name wsize
					
				String strTemp_Window_Name=StringFromList(0, WinList("IgorThiefGraph_*", ";", "WIN:1"))
				DoWindow/C/W=$strTemp_Window_Name, $strNew_Image_Graph_Name
				DoWindow/T $strNew_Image_Graph_Name, strNew_Image_Graph_Name
				MoveWindow/W=$strNew_Image_Graph_Name V_Left+vWindow_Offset, V_Top+vWindow_Offset, V_Right+vWindow_Offset, V_Bottom+vWindow_Offset		//Offset the duplicated graph
				
				strTrace_Names_List=TraceNameList(strNew_Image_Graph_Name, ";", 1)		//Replace the traces on the image graph with the ones in the matching data folder
				FOR(iTraceDex=0;iTraceDex<ItemsInList(strTrace_Names_List);iTraceDex+=1)
					String strTrace_Name=StringFromList(iTraceDex, strTrace_Names_List)
					
					WAVE/Z Old_Y_Wave=TraceNameToWaveRef(strNew_Image_Graph_Name, strTrace_Name)
					WAVE/Z New_Y_Wave=$strNew_Data_Folder+":"+NameOfWave(Old_Y_Wave)
					
					WAVE/Z Old_X_Wave=XWaveRefFromTrace(strNew_Image_Graph_Name, strTrace_Name)
					WAVE/Z New_X_Wave=$strNew_Data_Folder+":"+NameOfWave(Old_X_Wave)
					
					ReplaceWave/W=$strNew_Image_Graph_Name/X trace=$strTrace_Name, New_X_Wave		//Replace the X wave first so the trace name doesn't change
					ReplaceWave/W=$strNew_Image_Graph_Name trace=$strTrace_Name, New_Y_Wave
				ENDFOR
				
				String strNew_Digitized_Graph_Name="DigitizedData_"+strNew_Index
				
				String strDigitized_Graph_Recreation_Info = WinRecreation("DigitizedData_"+strGraph_Tag, 0)
				Execute/Z strDigitized_Graph_Recreation_Info
				
				GetWindow/Z $"DigitizedData_"+strGraph_Tag wsize
				
				strTemp_Window_Name=StringFromList(0, WinList("DigitizedData_*", ";", "WIN:1"))
				DoWindow/C/W=$strTemp_Window_Name, $strNew_Digitized_Graph_Name
				DoWindow/T $strNew_Digitized_Graph_Name, strNew_Digitized_Graph_Name
				MoveWindow/W=$strNew_Digitized_Graph_Name V_Left+vWindow_Offset, V_Top+vWindow_Offset, V_Right+vWindow_Offset, V_Bottom+vWindow_Offset		//Offset the duplicated graph
								
				Return 1		//If we didn't have this, I think the graph would get duplicated twice
			ENDIF
		
			IF(vAre_Digitizing)		//Undo clicks
				IF(CmpStr(s.menuName,"Edit") == 0 && CmpStr(s.menuItem,"Undo")==0)
					WAVE Data_Y_Wave=$strY_Wave
					Variable vY_Wave_New_Length= DimSize(Data_Y_Wave,0)-1
					if(vY_Wave_New_Length>=0)
						WAVE Data_X_Wave=$strX_Wave	// strings contain full path to waves
						WAVE Data_Y_Wave=$strY_Wave
		
						Redimension/N=(vY_Wave_New_Length) Data_X_Wave,Data_Y_Wave
			
						WAVE/Z Tracing_Y_Wave = TraceNameToWaveRef(strGraph_Name, "Tracing_Y_Wave")
						IF(WaveExists(Tracing_Y_Wave))
							WAVE Tracing_X_Wave= XWaveRefFromTrace(strGraph_Name, "Tracing_Y_Wave")
							Redimension/N=(vY_Wave_New_Length) Tracing_X_Wave,Tracing_Y_Wave
						ENDIF		//End making sure the tracing wave exists
					ENDIF		//End making sure there are a non-zero number of points in the wave
				ENDIF		//End seeing if the user called undo
			ENDIF		//End making sure we are digitizing data
		BREAK
	ENDSWITCH
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Enables/disables controls depending on where you are in the process
STATIC FUNCTION Graph_Update_Controls(STRING strGraph_Name)

	String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)
	
	String strControls_2_Disable=ControlNameList(strGraph_Name, ";", "T*")
	String strControls_2_Enable=""
	
	String strTo_Do_List=""
	
	ControlInfo/W=$strGraph_Name H0_SetVar_Are_Digitizing
	Variable vAre_Digitizing=V_Value
	
	ControlInfo/W=$strGraph_Name H0_SetVar_Are_Editing
	Variable vAre_Editing=V_Value
	
	IF(!vAre_Digitizing && !vAre_Editing)
		strControls_2_Enable+=ControlNameList(strGraph_Name, ";", "V*")
		strControls_2_Enable+=ControlNameList(strGraph_Name, ";", "T1*")
	
		ControlInfo/W=$strGraph_Name T1_Pop_Image_Name
		WAVE/Z Image_Wave=$S_UserData
		IF(WaveExists(Image_Wave) && ItemsInList(ImageNameList(strGraph_Name, ";"))>0)
			strControls_2_Enable+=ControlNameList(strGraph_Name, ";", "T2*")
			strTo_Do_List="2. Set axis limits"
		ENDIF
		
		ControlInfo/W=$strGraph_Name T2_Pop_X_Axis_Type
		String strAxis_Type_X=S_Value
		
		ControlInfo/W=$strGraph_Name T2_Pop_Y_Axis_Type
		String strAxis_Type_Y=S_Value
		
		//Check the axis limits
		Make/O/T/FREE/N=4 Cursor_List=num2char(char2Num(kstrStarting_Cursor)+p)
		Make/O/D/FREE/N=4 XY_Min_Max_Values=NaN
		
		Int iCsrDex
		FOR(iCsrDex=0;iCsrDex<numpnts(Cursor_List);iCsrDex+=1)
			ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+Cursor_List[iCsrDex]
			XY_Min_Max_Values[iCsrDex]=V_Value
		ENDFOR
		
		Variable vX_Limits_Good=1
		IF((XY_Min_Max_Values[0]==0 || XY_Min_Max_Values[1]==0) && (cmpstr(strAxis_Type_X, "Log10")==0 || cmpstr(strAxis_Type_X, "ln")==0))
			vX_Limits_Good=0
		ELSEIF((XY_Min_Max_Values[0]<0 || XY_Min_Max_Values[1]<0) && (cmpstr(strAxis_Type_X, "Log10")==0 || cmpstr(strAxis_Type_X, "ln")==0 || cmpstr(strAxis_Type_X, "Sqrt")==0))
			vX_Limits_Good=0
		ENDIF
		
		Variable vY_Limits_Good=1
		IF((XY_Min_Max_Values[2]==0 || XY_Min_Max_Values[3]==0) && (cmpstr(strAxis_Type_Y, "Log10")==0 || cmpstr(strAxis_Type_Y, "ln")==0))
			vY_Limits_Good=0
		ELSEIF((XY_Min_Max_Values[2]<0 || XY_Min_Max_Values[3]<0) && (cmpstr(strAxis_Type_Y, "Log10")==0 || cmpstr(strAxis_Type_Y, "ln")==0 || cmpstr(strAxis_Type_Y, "Sqrt")==0))
			vY_Limits_Good=0
		ENDIF
		
		WaveStats/Q XY_Min_Max_Values
		IF(v_nPnts==numpnts(XY_Min_Max_Values) && vX_Limits_Good && vY_Limits_Good)
			strControls_2_Enable+=ControlNameList(strGraph_Name, ";", "T3*")
			strTo_Do_List="3. Select X and Y waves"
		ENDIF
		
		//See if we have valid destination waves
		ControlInfo/W=$strGraph_Name T3_Pop_X_wave
		WAVE/Z X_Wave= $S_Userdata
			
		ControlInfo/W=$strGraph_Name T3_Pop_Y_wave
		WAVE/Z Y_Wave= $S_Userdata
		
		IF(WaveExists(X_Wave) && WaveExists(Y_Wave))
			strControls_2_Enable+=ControlNameList(strGraph_Name, ";", "T4*")+ControlNameList(strGraph_Name, ";", "T5*")
			strTo_Do_List="4a. Start digitizing"				
		ENDIF
		
	ELSEIF(vAre_Digitizing)
		strTo_Do_List="4b. Click \"Stop Digitizing\" button when done"
		
		strControls_2_Disable=ControlNameList(strGraph_Name,";", "T*")+ControlNameList(strGraph_Name,";", "V0_*")
		strControls_2_Disable=RemoveFromList("V0_Title_ToDo;",strControls_2_Disable)
		strControls_2_Disable=RemoveFromList("V0_Button_Help",strControls_2_Disable)
		
		strControls_2_Enable="T4_Button_Digitize;"
		
	ELSEIF(vAre_Editing)
		strTo_Do_List="5b. Adjust the trace, click \"Stop Editing\" button when done"
		
		strControls_2_Disable=ControlNameList(strGraph_Name,";", "T*")+ControlNameList(strGraph_Name,";", "V0_*")
		strControls_2_Disable=RemoveFromList("V0_Title_ToDo;",strControls_2_Disable)
		strControls_2_Disable=RemoveFromList("T5_Button_Edit",strControls_2_Disable)
		strControls_2_Disable=RemoveFromList("V0_Button_Help",strControls_2_Disable)
	ENDIF
	
	IF(strlen(strTo_Do_List)>0)
		TitleBox V0_Title_ToDo, title=strTo_Do_List
	ENDIF
	
	ModifyControlList strControls_2_Disable, win=$strGraph_Name, disable=2
	ModifyControlList strControls_2_Enable, win=$strGraph_Name, disable=0
	
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Changes the cursor appearance between lines or points
STATIC FUNCTION Graph_CheckBox_Use_Points_Lines(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	String strGraph_Name=cba.win

	SWITCH( cba.eventCode )
		CASE 2: // mouse up			
			String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)
			String strCtrl_Type=ParseFilePath(0, cba.ctrlName, "_", 1, 0)
			Variable vUse_Points=cmpstr(cba.ctrlName, "T2_Check_Use_Points")==0
			
			String strOther_Control="T2_Check_Use_"+SelectString(vUse_Points, "Points", "Lines")
			
			CheckBox $cba.ctrlName, win=$strGraph_Name, value=cba.checked
			CheckBox $strOther_Control, win=$strGraph_Name, value=!cba.checked
			
			ControlInfo/W=$strGraph_Name T1_Pop_Image_Name
			WAVE/Z Image_Wave=$S_UserData
			IF(WaveExists(Image_Wave) && ItemsInList(ImageNameList(strGraph_Name, ";"))>0)

				String strPoints_Help_Text="Hold down command/control and click the setvar to change where it is relative to the cursor."
				String strLines_Help_Text="Command/control+click doesn't do anything when the cursors are lines."
				
				Make/O/T/FREE/N=4 Cursor_List=num2char(char2Num(kstrStarting_Cursor)+p)
				Int iCsrDex
				FOR(iCsrDex=0;iCsrDex<numpnts(Cursor_List);iCsrDex+=1)
					String strHelp_Text=SelectString(iCsrDex<2, "Y", "X")+num2str(mod(iCsrDex, 2)+1)+", Csr "+Cursor_List[iCsrDex]+"\r"+SelectString(vUse_Points, strLines_Help_Text, strPoints_Help_Text)
					SetVariable $"Csr_SetVar_"+Cursor_List[iCsrDex], win=$strGraph_Name, help={strHelp_Text}
					
					Cursor/H=(vUse_Points ? 0 : (iCsrDex<2 ? 2 : 3))/M/W=$strGraph_Name $Cursor_List[iCsrDex]
				
					STRUCT WMWinHookStruct s
					s.WinName = strGraph_Name
					s.eventcode = 7
					s.eventname="cursormoved"
					s.cursorName=Cursor_List[iCsrDex]
					Graph_Hook_Cursor(s)
				ENDFOR
			ENDIF
		BREAK
		
		CASE -1: // control being killed
		BREAK
	ENDSWITCH

	return 0
		
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//For selecting the image wave
STATIC FUNCTION Image_Pop_Load_Change_Image(STRUCT WMPopupAction &pa) : PopupMenuControl
	
	SWITCH( pa.eventCode )
		CASE 2: // mouse up
		
			IF(cmpstr(pa.popStr,"New Image")==0)
				Image_Load(pa.win)
				
			ELSE
				String strImage_Wave_Name=pa.popStr
				WAVE/Z Image_Wave=$strImage_Wave_Name
				
				IF(WaveExists(Image_Wave))
					Image_Update(pa.win, Image_Wave)
				ENDIF
			ENDIF
		BREAK
		
		CASE -1: // control being killed
		BREAK
	ENDSWITCH

	return 0
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Prompts for an image file, then loads it, displays it, and appends 
//markers for the locations of xmin,xmax,ymin,ymax.
//Called when button pressed.
STATIC FUNCTION Image_Load(STRING strGraph_Name)
			
	Variable vLoad_Mode=-1
	
	//Shamelessly copied from the Tracer package
	LoadPICT/Q/Z "Clipboard"
	IF(V_Flag)
		DoAlert 2, "Do you want to load the image from the clipboard?"
		IF(V_flag == 1)	 	//Load clipboard image
			vLoad_Mode=2
		ELSEIF(V_Flag==2)	//Look for file to load
			vLoad_Mode=1
		ELSE				//Don't load
			vLoad_Mode=-1			
		ENDIF
	ELSE
		vLoad_Mode=1		//No clipboard image
	ENDIF
	
	IF(vLoad_Mode==1)
		String strMessage="Select an image file"
		
		String strFile_Filters="PNG files (*.png):.png;"			//Image file format options, mostly taken from the Load Image dialog
		strFile_Filters+="JPG files (*.jpg, *.jpeg):.jpg,.jpeg;"
		strFile_Filters+="TIFF files (*.tif,*.tiff):.tif,.tiff;"
		strFile_Filters+="BMP files (*.bmp):.bmp;"
		strFile_Filters+="SUN raster files (*.ras):.ras;"
		strFile_Filters+="All files:.*;"
		
		Variable vRefnum
		Open/D/R/F=strFile_Filters/M=strMessage vRefnum
	
		IF(strlen(S_fileName)>0)
			String strImage_File_Path=S_fileName
		ELSE
			vLoad_Mode=-1
		ENDIF
		
	ELSEIF(vLoad_Mode==2)
		strImage_File_Path=Image_Clipboard_Import()
	
	ELSE		//User cancel
		vLoad_Mode=-1
	ENDIF
	
	IF(strlen(strImage_File_Path)>0)
		String strFile_Name_Plus_Extension=ParseFilePath(0, strImage_File_Path, ":", 1, 0)				//Get the name of the file
		String strExtension=ParseFilePath(0, strImage_File_Path, ".", 1, 0)									//Get the extension, without making assumptions about how many periods are in the name					
				
		String strImage_File_Name=RemoveEnding(strFile_Name_Plus_Extension, "."+strExtension)		//Remove the period and the extension
		
		String strImage_Wave_Name=CleanUpName(ReplaceString(" ", strImage_File_Name, "_"), 0)
	
		IF(vLoad_Mode==2)
			Prompt strImage_Wave_Name, "Name for clipboard image" 
			DoPrompt "If you want, change the wave name for the clipboard image", strImage_Wave_Name
		ENDIF
	
		IF(cmpstr(strExtension, "tif")==0)				//TIFF files end in .tif, so need to fix that
			strExtension="TIFF"
		ELSEIF(cmpstr(strExtension, "jpg")==0)
			strExtension="jpeg"
		ENDIF
	
		WAVE/Z Old_Image_Wave=$strImage_Wave_Name
	
		IF(WaveExists(Old_Image_Wave))
			DoAlert 2, "An image with the same name already exists!  Do you want to overwrite the existing image (yes), give the new image a different name (no), or cancel (cancel)?"
		
			IF(V_Flag==1)
				ImageLoad/T=$strExtension/O/Q/N=$strImage_Wave_Name strImage_File_Path										//Load the image
				
			ELSEIF(V_Flag==2)
				String strNew_Wave_Name=strImage_Wave_Name
				Prompt strNew_Wave_Name, "New name"
				DoPrompt "Enter new name", strNew_Wave_Name
			
				IF(cmpstr(strNew_Wave_Name, strImage_Wave_Name)==0)
					DoAlert 0, "You entered the same name as the old name!  Function aborting!"
					Return -1
				ENDIF
			
				strImage_Wave_Name=strNew_Wave_Name
				ImageLoad/T=$strExtension/O/Q/N=$strImage_Wave_Name strImage_File_Path
								
			ELSE
				Return -1
			ENDIF
			
		ELSE	
			ImageLoad/T=$strExtension/O/Q/N=$strImage_Wave_Name strImage_File_Path	//Load the image
		ENDIF
		
		IF(vLoad_Mode==2)		//Clipboard load.  Delete the file so we don't clog the temp folder
			DeleteFile/Z strImage_File_Path
		ENDIF
					
		WAVE/Z Image_Wave=$strImage_Wave_Name
	
		String strImage_List="New Image;"+sortlist(WaveList("*", ";", "TEXT:0,DIMS:2")+WaveList("*", ";", "TEXT:0,DIMS:3"), ";", 16)
		Variable vImage_Index=WhichListItem(strImage_Wave_Name, strImage_List)
		PopupMenu T1_Pop_Image_Name, win=$strGraph_Name, mode=(1+vImage_Index), userdata=GetWavesDataFolder(Image_Wave, 2)
				
		Image_Update(strGraph_Name, Image_Wave)
		
	ELSE		//Reset the image popup to the last value
		ControlInfo/W=$strGraph_Name T1_Pop_Image_Name
		String strOrignal_Image_Wave=S_UserData
		String strOrignal_Image_Wave_Name=ParseFilePath(0, strOrignal_Image_Wave, ":", 1, 0)
			
		strImage_List="New Image;"+sortlist(WaveList("*", ";", "TEXT:0,DIMS:2")+WaveList("*", ";", "TEXT:0,DIMS:3"), ";", 16)
		vImage_Index=limit(WhichListItem(strOrignal_Image_Wave_Name, strImage_List), 0, Inf)
		PopupMenu T1_Pop_Image_Name, win=$strGraph_Name, mode=(1+vImage_Index)
		ControlUpdate/W=$strGraph_Name T1_Pop_Image_Name
	ENDIF
	
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Import image from clipboard
//Copied some of this code from the tracer package
STATIC FUNCTION/S Image_Clipboard_Import()

	LoadPICT/Q/O "Clipboard"
	IF(V_flag == 0)
		return ""
	ENDIF
	
	string strPicture_Name = StringByKey("NAME", S_info)		
	string strType = StringByKey("TYPE", S_info)
	Variable vImage_Width_Pnts = NumberByKey("PHYSWIDTH", S_info)
	Variable vImage_Height_Pnts = NumberByKey("PHYSHEIGHT", S_info)

	String strImage_File_Path=SpecialDirPath("Temporary", 0, 0, 0)+"Clipboard_Image.png"

	String strExtension_List=".jpg;.tif;.png;.bmp;"			//AAAAAA Check this
	IF(WhichListItem(strType, strExtension_List)>=0)
		SavePICT/Z/O/PICT=$strPicture_Name as strImage_File_Path		
		
	ELSE		
		// create a hidden graph as a canvas for pict, match aspect ratio
		Variable vGraph_Height = max(kPDFmin/vImage_Width_Pnts*vImage_Height_Pnts, kPDFmin) // vertical size of graph in points
		Variable vScale_Factor = vGraph_Height / vImage_Height_Pnts
		Variable vGraph_Width = vScale_Factor * vImage_Width_Pnts
		
		KillWindow/Z Clipboard_Temp_Image
		Display/W=(0, 0, vGraph_Width, vGraph_Height)/N=Clipboard_Temp_Image/hide=1
		DrawPICT/W=Clipboard_Temp_Image 0, 0, vScale_Factor, vScale_Factor, $strPicture_Name
		
		// export the graph window as png
		SavePICT/E=-5/B=288/WIN=Clipboard_Temp_Image/O as strImage_File_Path
	ENDIF
	
	KillWindow/Z Clipboard_Temp_Image
	KillPICTs/Z $strPicture_Name
	
	Return strImage_File_Path

END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Change the image on the graph
STATIC FUNCTION Image_Update(STRING strGraph_Name, WAVE/Z Image_Wave)

	PopupMenu T1_Pop_Image_Name, win=$strGraph_Name, userData=GetWavesDataFolder(Image_Wave, 2)
	
	String strImages_On_Graph_List=ImageNameList(strGraph_Name, ";")
	
	Int iImageDex
	FOR(iImageDex=0;iImageDex<ItemsInList(strImages_On_Graph_List);iImageDex+=1)
		RemoveImage/Z/W=$strGraph_Name $StringFromList(iImageDex, strImages_On_Graph_List)
	ENDFOR
	
	RemoveFromGraph/Z/W=$strGraph_Name Tracing_Data_Y
				
	AppendImage/W=$strGraph_Name Image_Wave
	
	//Make the graph look nice
	IF(DimDelta(Image_Wave, 1)<0)		//AppendImage by default reverses the Y axis, so check the delta
		SetAxis/W=$strGraph_Name/A left		//and see if we need to unreverse the axis
	ELSE
		SetAxis/W=$strGraph_Name/A/R left
	ENDIF
	
	IF(DimDelta(Image_Wave, 0)>0)		//Check the X scaling also.  Never know what a user is going to do...
		SetAxis/W=$strGraph_Name/A bottom
	ELSE
		SetAxis/W=$strGraph_Name/A/R bottom
	ENDIF
	
	ModifyGraph/W=$strGraph_Name margin=-1, margin(right)=14, margin(bottom)=14
	ModifyGraph/W=$strGraph_Name tick=3,mirror=0,noLabel=2,axThick=0,standoff=0
	
	Button T4_Button_Digitize,win=$strGraph_Name,title="4a. Start Digitizing"
	
	//Resizes the graph window to accommodate the image wave 
	GetWindow $strGraph_Name wsizeDC	// current graph dimensions in pixels
	Variable vGraph_Width_Pixels= V_Right-V_Left
	IF(vGraph_Width_Pixels < kIgorThiefGraphWidthPixels)		//Keep graph width as best we can
		vGraph_Width_Pixels= kIgorThiefGraphWidthPixels
	ENDIF
	
	//forceSize is a multiplier of the number of image pixels per screen pixel (1 means 1-to-1 correspondence between pixels in the image and the screen, 2 is 2x magnification).
	ModifyGraph/W=$strGraph_Name width={Plan, abs(DimDelta(Image_Wave, 1 )/ DimDelta(Image_Wave, 0)), bottom, left}
	DoUpdate/W=$strGraph_Name
	ModifyGraph/W=$strGraph_Name width=0
	DoUpdate/W=$strGraph_Name

	PopupMenu T2_Pop_X_Axis_Type, win=$strGraph_Name, mode=1, popvalue="Linear"
	PopupMenu T2_Pop_Y_Axis_Type, win=$strGraph_Name, mode=1, popvalue="Linear"
	
	SetWindow $strGraph_Name hook(Cursor_Hook)=$""
	
	Make/O/T/FREE/N=4 Cursor_List=num2char(char2Num(kstrStarting_Cursor)+p)
	
	Int iCsrDex
	FOR(iCsrDex=0;iCsrDex<numpnts(Cursor_List);iCsrDex+=1)
		KillControl/W=$strGraph_Name $"Csr_SetVar_"+Cursor_List[iCsrDex]
		Cursor/K/W=$strGraph_Name $Cursor_List[iCsrDex]
	ENDFOR
	
	ControlInfo/W=$strGraph_Name T2_Check_Use_Points
	Variable vUse_Points=V_Value
	
	Variable vNum_Images_Rows=DimSize(Image_Wave, 0), vNum_Image_Columns=DimSize(Image_Wave,1)
	
	String strPoints_Help_Text="Hold down command/control and click the setvar to change where it is relative to the cursor."
	String strLines_Help_Text="Command/control+click doesn't do anything when the cursors are lines."
					
	FOR(iCsrDex=0;iCsrDex<numpnts(Cursor_List);iCsrDex+=1)		//Set up the cursors and setvars for setting the axis min/max values
		String strCsr_Name=Cursor_List[iCsrDex]
		
		Variable vCsr_X_pos=SelectNumber(iCsrDex<2, 0.2, SelectNumber(iCsrDex==0, 0.9, 0.1))*vNum_Images_Rows
		Variable vCsr_Y_pos=SelectNumber(iCsrDex>1, 0.8, SelectNumber(iCsrDex==2, 0.1, 0.9))*vNum_Image_Columns
		Cursor/N=1/S=2/I/C=(65535*(iCsrDex>1),0,65535*(iCsrDex<2))/H=(vUse_Points ? 0 : (iCsrDex<2 ? 2 : 3))/P/W=$strGraph_Name $strCsr_Name $NameOfWave(Image_Wave) vCsr_X_pos, vCsr_Y_pos
		
		Variable vCursor_Pixel_X = Graph_Get_Csr_Pixel_Position(strGraph_Name, "bottom", strCsr_Name)
		Variable vCursor_Pixel_Y = Graph_Get_Csr_Pixel_Position(strGraph_Name, "left", strCsr_Name)
		
		String strColor="\K("+num2str(65535*(iCsrDex>1))+","+num2str(0)+","+num2str(65535*(iCsrDex<2))+")"
				
		TitleBox $"Csr_Title_1_"+strCsr_Name, win=$strGraph_Name, title=strColor+SelectString(iCsrDex<2, "Y", "X")+num2str(mod(iCsrDex,2)+1)
		TitleBox $"Csr_Title_1_"+strCsr_Name, win=$strGraph_Name, frame=0,fsize=14, fstyle=1,help={"Cursor name"},font="Consolas"
		ControlUpdate/W=$strGraph_Name $"Csr_Title_1_"+strCsr_Name
		ControlInfo/W=$strGraph_Name $"Csr_Title_1_"+strCsr_Name
		Variable vCsr_Title_1_Height=V_Height
		
		//Two titleboxes is more compact that one titlebox with a carriage return
		TitleBox $"Csr_Title_2_"+strCsr_Name, win=$strGraph_Name, title=strColor+strCsr_Name
		TitleBox $"Csr_Title_2_"+strCsr_Name, win=$strGraph_Name, frame=0,fsize=14, fstyle=1,help={"Cursor name"},font="Consolas"
		ControlUpdate/W=$strGraph_Name $"Csr_Title_2_"+strCsr_Name
		
		String strHelp_Text=SelectString(iCsrDex<2, "Y", "X")+num2str(mod(iCsrDex, 2)+1)+", Csr "+strCsr_Name+"\r"+SelectString(vUse_Points, strLines_Help_Text, strPoints_Help_Text)
		
		SetVariable $"Csr_SetVar_"+strCsr_Name, win=$strGraph_Name, value=_NUM:NaN, limits={-Inf,Inf,0}, size={kvSetVar_Body_Width,23}, bodywidth=kvSetVar_Body_Width,fsize=14,proc=IgorThief2#Graph_SetVar_XY_Min_Max
		SetVariable $"Csr_SetVar_"+strCsr_Name, win=$strGraph_Name, valueColor=(65535*(iCsrDex>1),0, 65535*(iCsrDex<2)),valueBackColor=(SelectNUmber(iCsrDex>1,59110, 65535),59110,SelectNUmber(iCsrDex>1,65535,59110))
		SetVariable $"Csr_SetVar_"+strCsr_Name, win=$strGraph_Name, help={strHelp_Text}, disable=0
		ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+strCsr_Name
		Variable vSetVar_Half_Height=V_Height/-2
		
		Variable vSetVar_X_Offset=vUse_Points ? (iCsrDex!=1 ? 2 : -1*(2+kvSetVar_Body_Width)) : kvSetVar_Body_Width/-2		
		Variable vTitle_1_X_Offset=vUse_Points ? (vSetVar_X_Offset>0 ? vSetVar_X_Offset-20 : vSetVar_X_Offset+kvSetVar_Body_Width+3) : (iCsrDex!=1 ? kvSetVar_Body_Width/2+2 : kvSetVar_Body_Width*-0.8)
		Variable vTitle_2_X_Offset=vUse_Points ? (vSetVar_X_Offset>0 ? vSetVar_X_Offset-17 : vSetVar_X_Offset+kvSetVar_Body_Width+6) : (iCsrDex!=1 ? kvSetVar_Body_Width/2+5 : kvSetVar_Body_Width*-0.8+3)
		
		Variable vSetVar_Y_Offset=vUse_Points ? (iCsrDex!=2 ? 2 : vSetVar_Half_Height*2-2) : vSetVar_Half_Height
		Variable vTitle_1_Y_Offset=vSetVar_Y_Offset-3
		Variable vTitle_2_Y_Offset=vTitle_1_Y_Offset+vCsr_Title_1_Height-4
		
		SetVariable $"Csr_SetVar_"+strCsr_Name, win=$strGraph_Name, pos={vCursor_Pixel_X+vSetVar_X_Offset,vCursor_Pixel_Y+vSetVar_Y_Offset+kvControl_Bar_Height}, userdata="X_Offset="+num2str(iCsrDex!=1 ? 2 : -1*(2+kvSetVar_Body_Width))+";Y_Offset="+num2str(iCsrDex!=2 ? 2 : vSetVar_Half_Height*2-2)+";"
		
		TitleBox $"Csr_Title_1_"+strCsr_Name, win=$strGraph_Name, pos={vCursor_Pixel_X+vTitle_1_X_Offset,vCursor_Pixel_Y+vTitle_1_Y_Offset+kvControl_Bar_Height}, disable=0
		TitleBox $"Csr_Title_2_"+strCsr_Name, win=$strGraph_Name, pos={vCursor_Pixel_X+vTitle_2_X_Offset,vCursor_Pixel_Y+vTitle_2_Y_Offset+kvControl_Bar_Height}, disable=0
	ENDFOR
	
	Graph_Update_Controls(strGraph_Name)
	
	SetWindow $strGraph_Name hook(Cursor_Hook)=IgorThief2#Graph_Hook_Cursor, hookevents=4

	//enter Graph_Hook_Cursor function with resize event to reposition setvars.  
	STRUCT WMWinHookStruct s
	s.WinName = strGraph_Name
	s.eventcode = 6
	s.eventname="resize"
	Graph_Hook_Cursor(s)
	return 1	
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Adapted from the Tracer package, but with a fair amount of changes.
//I made it separate from the mouse hook for reasons (maybe to keep the mouse hook function from getting out of control).
STATIC FUNCTION Graph_Hook_Cursor(STRUCT WMWinHookStruct &s)
	String strGraph_Name=s.winName
	
	STRSWITCH (s.eventName)
		CASE "resize":		
		CASE "modified":
		CASE "cursormoved":
			ControlInfo/W=$strGraph_Name T2_Check_Use_Points
			Variable vUse_Points=V_Value
			
			Make/O/T/FREE/N=4 Cursor_List=num2char(char2Num(kstrStarting_Cursor)+p)
			
			String strCursor_Start_Stop="["+Cursor_List[0]+"-"+Cursor_List[3]+"]"
			String strCursor_X="["+Cursor_List[0]+Cursor_List[1]+"]"
			
			String strCursor_List		//If moving a cursor, only need to check the cursor that moved.  Otherwise check all four cursors.  
			IF(cmpstr(s.eventName, "cursormoved")==0)
				strCursor_List=s.cursorName+";"	
			ELSE
				wfprintf strCursor_List, "%s;", Cursor_List
			ENDIF
			
			Int iCsrDex
			FOR(iCsrDex=0;iCsrDex<ItemsInList(strCursor_List);iCsrDex+=1)
				String strCsr_Name=StringFromList(iCsrDex, strCursor_List)
			
				Int vIs_X = GrepString(strCsr_Name,strCursor_X)
				
				IF(GrepString(strCsr_Name,strCursor_Start_Stop)==0)
					return 0
				ENDIF
				
				FindValue/TEXT=(strCsr_Name)/TXOP=4 Cursor_List
				Variable vCsr_Number=V_Value
				IF(vCsr_Number<0)
					Return 0
				ENDIF
				
				Variable vCursor_Pixel_X=Graph_Get_Csr_Pixel_Position(strGraph_Name, "bottom", strCsr_Name)
				Variable vCursor_Pixel_Y=Graph_Get_Csr_Pixel_Position(strGraph_Name, "left", strCsr_Name)
				
				ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+strCsr_Name
				Variable vSetVar_Half_Height=V_Height/-2
				String strSetVar_UserData=S_UserData
				
				ControlInfo/W=$strGraph_Name $"Csr_Title_1_"+strCsr_Name
				Variable vCsr_Title_1_Height=V_Height
				
				Variable vSetVar_X_Offset=vUse_Points ? str2num(StringByKey("X_Offset", strSetVar_UserData,"=")) : kvSetVar_Body_Width/-2
								
				Variable vTitle_1_X_Offset=vUse_Points ? ((vCursor_Pixel_X+vSetVar_X_Offset+kvSetVar_Body_Width/2)>vCursor_Pixel_X ? vSetVar_X_Offset-20 : vSetVar_X_Offset+kvSetVar_Body_Width+3) : (vCsr_Number!=1 ? kvSetVar_Body_Width/2+2 : kvSetVar_Body_Width*-0.8)
				Variable vTitle_2_X_Offset=vUse_Points ? ((vCursor_Pixel_X+vSetVar_X_Offset+kvSetVar_Body_Width/2)>vCursor_Pixel_X ? vSetVar_X_Offset-17 : vSetVar_X_Offset+kvSetVar_Body_Width+6) : (vCsr_Number!=1 ? kvSetVar_Body_Width/2+5 : kvSetVar_Body_Width*-0.8+3)
					
				Variable vSetVar_Y_Offset=vUse_Points ? str2num(StringByKey("Y_Offset", strSetVar_UserData,"=")) : vSetVar_Half_Height
				Variable vTitle_1_Y_Offset=vSetVar_Y_Offset-3
				Variable vTitle_2_Y_Offset=vTitle_1_Y_Offset+vCsr_Title_1_Height-4
				
				SetVariable $"Csr_SetVar_"+strCsr_Name, win=$strGraph_Name, pos={vCursor_Pixel_X+vSetVar_X_Offset,vCursor_Pixel_Y+vSetVar_Y_Offset+kvControl_Bar_Height}, disable=0
				
				TitleBox $"Csr_Title_1_"+strCsr_Name, win=$strGraph_Name, pos={vCursor_Pixel_X+vTitle_1_X_Offset,vCursor_Pixel_Y+vTitle_1_Y_Offset+kvControl_Bar_Height}
				TitleBox $"Csr_Title_2_"+strCsr_Name, win=$strGraph_Name, pos={vCursor_Pixel_X+vTitle_2_X_Offset,vCursor_Pixel_Y+vTitle_2_Y_Offset+kvControl_Bar_Height}
			
				DoUpdate/W=$strGraph_Name
			ENDFOR
		BREAK			
	ENDSWITCH
	
	return 0
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Gets the cursor position in the graph window's coordinate system
STATIC FUNCTION Graph_Get_Csr_Pixel_Position(STRING strGraph_Name, STRING strAxis_Name, STRING strCsr_Name)

	Variable vScreen_Resolution=ScreenResolution
				
	String strAxis_Type=StringByKey("AXTYPE", AxisInfo(strGraph_Name, strAxis_Name))
	Variable vHorizontal_Axis=cmpstr(strAxis_Type, "bottom")==0 || cmpstr(strAxis_Type, "top")==0
				
	GetAxis/Q/W=$strGraph_Name $strAxis_Name
	Variable vAxis_Min=min(V_Min, V_Max)
	Variable vAxis_Max=max(V_Min, V_Max)
	
	Variable vCsr_Pnt=vHorizontal_Axis ?  hcsr($strCsr_Name, strGraph_Name) : vcsr($strCsr_Name, strGraph_Name)	
	Variable vCsr_Pnt_Limited = limit(vCsr_Pnt, vAxis_Min,vAxis_Max)
				
	Variable vCursor_Pixel = round(PixelFromAxisVal(strGraph_Name, strAxis_Name, vCsr_Pnt_Limited) * (vScreen_Resolution>96 ? 72/vScreen_Resolution : 1))
	
	Return vCursor_Pixel
	
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Handles updates to the setvars setting the axis min/max values
STATIC FUNCTION Graph_SetVar_XY_Min_Max(STRUCT WMSetVariableAction &sva) : SetVariableControl

	String strGraph_Name=sva.win
	String strCsr_Name=ParseFilePath(0, sva.ctrlName, "_", 1, 0)
	
	ControlInfo/W=$strGraph_Name T2_Check_Use_Points
	Variable vUse_Points=V_Value
	
	SWITCH( sva.eventCode )
		CASE 2: 	// Enter key
		CASE 3: 	// Live update
			Variable vActive_Csr_Axis_Limit=sva.dval
			String strActive_Csr_Letter=ParseFilePath(0, sva.ctrlName, "_", 1, 0)
			
			Make/O/T/FREE/N=4 Cursor_List=num2char(char2Num(kstrStarting_Cursor)+p)
			String strCursor_X="["+Cursor_List[0]+Cursor_List[1]+"]"
			Int vIs_X = GrepString(strCsr_Name,strCursor_X)
			
			Variable vCsr_1_Position=vIs_X ? hcsr($Cursor_List[0], strGraph_Name) : vcsr($Cursor_List[2], strGraph_Name)
			ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+SelectString(vIs_X, Cursor_List[2], Cursor_List[0])
			Variable vCsr_1_Value=V_Value
			
			Variable vCsr_2_Position=vIs_X ? hcsr($Cursor_List[1], strGraph_Name) : vcsr($Cursor_List[3], strGraph_Name)
			ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+SelectString(vIs_X, Cursor_List[3], Cursor_List[1])
			Variable vCsr_2_Value=V_Value
			
			Variable vDelta_Position=(vCsr_1_Position-vCsr_2_Position)>0
			Variable vDelta_Value=(vCsr_1_Value-vCsr_2_Value)>0
			
			Variable vSwap_Axes=(vDelta_Position %^ vDelta_Value)
			
			IF(numtype(vCsr_1_Value)==0 && numtype(vCsr_2_Value)==0 && kvAuto_Reverse_Axes)
				IF(vSwap_Axes)
					SetAxis/W=$strGraph_Name/A/R $SelectString(vIs_X, "left", "bottom")
				ELSE
					SetAxis/W=$strGraph_Name/A $SelectString(vIs_X, "left", "bottom")
				ENDIF
				
				STRUCT WMWinHookStruct Csr_s	//If this isn't here then funky things happen when the axes are flipped
				Csr_s.WinName = strGraph_Name
				Csr_s.eventcode = 7
				Csr_s.eventname="modified"
				Graph_Hook_Cursor(Csr_s)
			ENDIF
			
			ControlInfo/W=$strGraph_Name $"T2_Pop_"+SelectString(vIs_X, "Y", "X")+"_Axis_Type"
			String strAxis_Type=S_Value
			
			Variable vAxis_Limit_Error=0
			IF(vActive_Csr_Axis_Limit==0 && (cmpstr(strAxis_Type, "Log10")==0 || cmpstr(strAxis_Type, "ln")==0))				
				vAxis_Limit_Error=1
			ELSEIF(vActive_Csr_Axis_Limit<0 && (cmpstr(strAxis_Type, "Log10")==0 || cmpstr(strAxis_Type, "ln")==0 || cmpstr(strAxis_Type, "Sqrt")==0))
				vAxis_Limit_Error=1
			ENDIF
			
			IF(vAxis_Limit_Error)
				String strCondition=SelectString(cmpstr(strAxis_Type, "Sqrt")==0, "greater than", "greater than or equal to")
				DoAlert/T="ERROR ID-10T" 0, "Axis limits for "+strAxis_Type+" axes must be "+strCondition+" 0!"
			
				SetVariable $sva.ctrlName, win=$strGraph_Name, valueBackColor=(65535,65535,0)
				
			ELSE
				SetVariable $sva.ctrlName, win=$strGraph_Name, valueBackColor=(SelectNumber(!vIs_X,59110, 65535),59110,SelectNumber(!vIs_X,65535,59110))
			ENDIF
			
			Graph_Update_Controls(strGraph_Name)
			
			STRUCT WMWinHookStruct Mouse_s
			Mouse_s.winName=strGraph_Name
			Mouse_s.eventName="mousemoved"
			Mouse_s.eventMod=sva.eventMod
			Mouse_s.mouseLoc.h=sva.mouseLoc.h
			Mouse_s.mouseLoc.v=sva.mouseLoc.v
			Graph_Hook_Mouse(Mouse_s)
		BREAK
		
		CASE 9:		//Mouse down
			IF(sva.eventmod & 8 && vUse_Points)
				
				//Disable these so the user can't do something stupid
				TitleBox T2_Title_Points_Lines,win=$strGraph_Name, disable=2
				CheckBox T2_Check_Use_Points,win=$strGraph_Name, disable=2
				CheckBox T2_Check_Use_Lines,win=$strGraph_Name, disable=2
			
				ModifyControl/Z $sva.ctrlName, win=$strGraph_Name, disable=2,focusRing=0
				
				ControlInfo/W=$strGraph_Name $sva.ctrlName		//Get the offset between the mouse and top left of the setvar
				Variable vSetVar_Mouse_Offset_X=V_Left-sva.mouseloc.h
				Variable vSetVar_Mouse_Offset_Y=V_Top-sva.mouseloc.v
				
				String strCsr_Info="Csr_Name="+ParseFilePath(0, sva.ctrlName, "_", 1, 0)+";"+"X_Offset="+num2str(vSetVar_Mouse_Offset_X)+";Y_Offset="+num2str(vSetVar_Mouse_Offset_Y)+";"	
				
				SetVariable H0_SetVar_Are_Moving_Csr_SetVar, win=$strGraph_Name, value=_NUM:1,userdata=strCsr_Info
			ENDIF
		BREAK
		
		CASE -1: // control being killed
		BREAK
	ENDSWITCH

	return 0
	
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Controls whether the axes are log or not
STATIC FUNCTION Graph_CheckBox_Log_Axes(STRUCT WMCheckboxAction &cba) : CheckBoxControl
	String strGraph_Name=cba.win

	SWITCH( cba.eventCode )
		CASE 2: // mouse up			
			String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)
			
			Variable vIs_X_Axis=StringMatch(cba.ctrlName, "*X_Axis*")
			
			Make/O/T/FREE/N=4 Cursor_List=num2char(char2Num(kstrStarting_Cursor)+p)
			
			Variable vAxis_Limit_1=NaN, vAxis_Limit_2=NaN
			
			ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+Cursor_List[vIs_X_Axis ? 0 : 2]
			IF(V_Flag>0)
				vAxis_Limit_1=V_Value
			ENDIF
			
			ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+Cursor_List[vIs_X_Axis ? 1 : 3]
			IF(V_Flag>0)
				vAxis_Limit_2=V_Value
			ENDIF
			
			Variable vAxis_Limit_1_Error=vAxis_Limit_1<=0 && cba.checked
			Variable vRed=vAxis_Limit_1_Error ? 65535 : (vIs_X_Axis ? 59110 : 65535)
			Variable vGreen=vAxis_Limit_1_Error ? 65535 : 59110
			Variable vBlue=vAxis_Limit_1_Error ? 0 : (vIs_X_Axis ? 65535 : 59110)
			SetVariable $"Csr_SetVar_"+Cursor_List[vIs_X_Axis ? 0 : 2], win=$strGraph_Name, valueBackColor=(vRed,vGreen,vBlue)
			
			Variable vAxis_Limit_2_Error=vAxis_Limit_2<=0 && cba.checked
			vRed=vAxis_Limit_2_Error ? 65535 : (vIs_X_Axis ? 59110 : 65535)
			vGreen=vAxis_Limit_2_Error ? 65535 : 59110
			vBlue=vAxis_Limit_2_Error ? 0 : (vIs_X_Axis ? 65535 : 59110)
			SetVariable $"Csr_SetVar_"+Cursor_List[vIs_X_Axis ? 1 : 3], win=$strGraph_Name, valueBackColor=(vRed,vGreen,vBlue)
			
			IF(vAxis_Limit_1_Error || vAxis_Limit_2_Error)
				DoAlert/T="ERROR ID-10T" 0, "Axis limits for log axes must be greater than 0!"
			ENDIF
			
			IF(WinType("DigitizedData_"+strGraph_Tag)==1)
				ModifyGraph/Z/W=$"DigitizedData_"+strGraph_Tag log($SelectString(vIs_X_Axis, "left", "bottom"))=cba.checked
			ENDIF
			
			Graph_Update_Controls(strGraph_Name)	
		BREAK
		
		CASE -1: // control being killed
		BREAK
	ENDSWITCH

	return 0
		
END



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Selects waves for x and y data, allowing the creation of a new wave.
STATIC FUNCTION Graph_Pop_Axis_Type(STRUCT WMPopupAction &pa) : PopupMenuControl
	String strGraph_Name=pa.win
	
	SWITCH( pa.eventCode )
		CASE 2: // mouse up
			String strAxis_Type=pa.popStr
			String strCtrl_Name=pa.ctrlName
			Variable vPop_Num=pa.popNum
			
			String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)
			
			Variable vIs_X_Axis=StringMatch(pa.ctrlName, "*X_Axis*")
			
			Make/O/T/FREE/N=4 Cursor_List=num2char(char2Num(kstrStarting_Cursor)+p)
			
			Variable vAxis_Limit_1=NaN, vAxis_Limit_2=NaN
			
			ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+Cursor_List[vIs_X_Axis ? 0 : 2]
			IF(V_Flag>0)
				vAxis_Limit_1=V_Value
			ENDIF
			
			ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+Cursor_List[vIs_X_Axis ? 1 : 3]
			IF(V_Flag>0)
				vAxis_Limit_2=V_Value
			ENDIF
			
			Variable vAxis_Limit_1_Error=0
			IF(vAxis_Limit_1==0 && (cmpstr(strAxis_Type, "Log10")==0 || cmpstr(strAxis_Type, "ln")==0))
				vAxis_Limit_1_Error=1
			ELSEIF(vAxis_Limit_1<0 && (cmpstr(strAxis_Type, "Log10")==0 || cmpstr(strAxis_Type, "ln")==0 || cmpstr(strAxis_Type, "Sqrt")==0))
				vAxis_Limit_1_Error=1
			ENDIF
						
			Variable vRed=vAxis_Limit_1_Error ? 65535 : (vIs_X_Axis ? 59110 : 65535)
			Variable vGreen=vAxis_Limit_1_Error ? 65535 : 59110
			Variable vBlue=vAxis_Limit_1_Error ? 0 : (vIs_X_Axis ? 65535 : 59110)
			SetVariable $"Csr_SetVar_"+Cursor_List[vIs_X_Axis ? 0 : 2], win=$strGraph_Name, valueBackColor=(vRed,vGreen,vBlue)
			
			Variable vAxis_Limit_2_Error=0
			IF(vAxis_Limit_2==0 && (cmpstr(strAxis_Type, "Log10")==0 || cmpstr(strAxis_Type, "ln")==0))
				vAxis_Limit_2_Error=1
			ELSEIF(vAxis_Limit_2<0 && (cmpstr(strAxis_Type, "Log10")==0 || cmpstr(strAxis_Type, "ln")==0 || cmpstr(strAxis_Type, "Sqrt")==0))
				vAxis_Limit_2_Error=1
			ENDIF
			
			vRed=vAxis_Limit_2_Error ? 65535 : (vIs_X_Axis ? 59110 : 65535)
			vGreen=vAxis_Limit_2_Error ? 65535 : 59110
			vBlue=vAxis_Limit_2_Error ? 0 : (vIs_X_Axis ? 65535 : 59110)
			SetVariable $"Csr_SetVar_"+Cursor_List[vIs_X_Axis ? 1 : 3], win=$strGraph_Name, valueBackColor=(vRed,vGreen,vBlue)
			
			IF(vAxis_Limit_1_Error || vAxis_Limit_2_Error)
				String strCondition=SelectString(cmpstr(strAxis_Type, "Sqrt")==0, "greater than", "greater than or equal to")
				DoAlert/T="ERROR ID-10T" 0, "Axis limits for "+strAxis_Type+" axes must be "+strCondition+" 0!"				
			ENDIF
			
			Graph_Update_Controls(strGraph_Name)
		BREAK
	ENDSWITCH
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Selects waves for x and y data, allowing the creation of a new wave.
STATIC FUNCTION Graph_Pop_Wave_Selection(STRUCT WMPopupAction &pa) : PopupMenuControl
	String strGraph_Name=pa.win
	
	SWITCH( pa.eventCode )
		CASE 2: // mouse up
			String strPopStr=pa.popStr
			String strCtrl_Name=pa.ctrlName
			Variable vPop_Num=pa.popNum
			
			String strWave_Type=StringFromList(2, strCtrl_Name, "_")
			
			String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)
	
			// If "New Wave" is selected from popup menu, create new wave and set Data_Wave to the newly created wave.
			// Otherwise, set Data_Wave to one selected in popup menu.
			IF(cmpstr(strPopStr,"New Wave")==0)
				String strNew_Wave_Name
				String strTitle="Name of new "+upperstr(strWave_Type)+" wave"
				
				Prompt strNew_Wave_Name, strTitle
				DoPrompt strTitle, strNew_Wave_Name
				IF(V_Flag==1)	// cancel
					PopupMenu $strCtrl_Name, win=$strGraph_Name, mode=1
					
					Graph_Update_Controls(strGraph_Name)
					
					return 0
				ENDIF
				
				Make/D/N=0 $strNew_Wave_Name/WAVE=Data_Wave
				
				//Set popNum to item number corresponding to new wave
				String strWave_List="New Wave;"+sortlist(WaveList("*", ";", "TEXT:0,MAXCOLS:0"), ";", 16)
				vPop_Num=WhichListItem(NameOfWave(Data_Wave),strWave_List)+1
			
			ELSE
				WAVE/D/Z Data_Wave=$strPopStr		//This doesn't need to be the userdata because the only options in the popup menu are waves in the current data folder
				
				IF(!WaveExists(Data_Wave))
					PopupMenu $strCtrl_Name, win=$strGraph_Name, mode=1
					
					Graph_Update_Controls(strGraph_Name)
					
					return 0
				ENDIF
			ENDIF
		
			//Set item selected in popup menu to popNum, and update control
			PopupMenu $strCtrl_Name, win=$strGraph_Name,mode=vPop_Num, userdata=GetWavesDataFolder(Data_Wave, 2)
			ControlUpdate/W=$strGraph_Name $strCtrl_Name
			
			Graph_Update_Controls(strGraph_Name)
					
			return(vPop_Num)
		BREAK
		
		CASE -1: // control being killed
		BREAK
	ENDSWITCH

	return 0

END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Start or stop digitizing
STATIC FUNCTION Digitization_Button_Start_Stop(STRUCT WMButtonAction &ba) : ButtonControl
	
	SWITCH(ba.eventcode)
		CASE 2:
			String strGraph_Name=ba.win
			String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)
		
			ControlInfo/W=$strGraph_Name H0_SetVar_Are_Digitizing
			Variable vAre_Digitizing=V_Value
			
			IF(!vAre_Digitizing)		//Start digitizing
				Variable vDigitization_Flag=Digitization_Start(strGraph_Name)
				
			ELSE		//stop digitizing
				vDigitization_Flag=Digitization_Stop(strGraph_Name)
			ENDIF
			
			IF(vDigitization_Flag)
				SetVariable H0_SetVar_Are_Digitizing, win=$strGraph_Name, value=_NUM:!vAre_Digitizing
				Graph_Update_Controls(strGraph_Name)
			ENDIF
		BREAK
		
		CASE -1: // control being killed
		BREAK
	ENDSWITCH

	return 0
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// Checks to see if you are ready to start digitizing.  Also displays the output in a new graph off to the side.
STATIC FUNCTION Digitization_Start(STRING strGraph_Name)

	String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)
	
	ControlInfo/W=$strGraph_Name T3_Pop_X_wave
	WAVE/Z Data_X_Wave= $S_UserData
	IF(!WaveExists(Data_X_Wave) )
		DoAlert 0, "Select an X Data Wave!"
		return 0
	ENDIF

	ControlInfo/W=$strGraph_Name T3_Pop_Y_wave
	WAVE/Z Data_Y_Wave= $S_UserData
	IF(!WaveExists(Data_Y_Wave) )
		DoAlert 0, "Select an Y Data Wave!"
		return 0
	ENDIF
	
	IF(numpnts(Data_Y_Wave)>0)
		DoWindow/F $"DigitizedData_"+strGraph_Tag // NO: keep DigitizedData behind IgorThiefGraph
		DoWindow/B=$strGraph_Name $"DigitizedData_"+strGraph_Tag
		
		DoAlert 1, "Overwrite existing data in "+NameOfWave(Data_X_Wave)+" and "+NameOfWave(Data_Y_Wave)+"?"
		IF(V_flag!=1)			
			return 0
		ENDIF
	ENDIF
	
	Button T4_Button_Digitize, win=$strGraph_Name, title="4b. Stop Digitizing"
	
	Redimension/N=0 Data_X_Wave, Data_Y_Wave
	
	WAVE/D/Z Tracing_Y_Wave = TraceNameToWaveRef(strGraph_Name, "Tracing_Y_Wave")
	IF(WaveExists(Tracing_Y_Wave))
		WAVE/D/Z Tracing_X_Wave= XWaveRefFromTrace(strGraph_Name, "Tracing_Y_Wave")
		Redimension/N=0 Tracing_X_Wave, Tracing_Y_Wave
	ELSE
		WAVE/Z Tracing_Y_Wave=$"root:Packages:ATH_DataFolder:IgorThief_"+strGraph_Tag+":Tracing_Y_Wave"
		WAVE/Z Tracing_X_Wave=$"root:Packages:ATH_DataFolder:IgorThief_"+strGraph_Tag+":Tracing_X_Wave"
		
		Redimension/N=0 Tracing_X_Wave, Tracing_Y_Wave
		
		AppendToGraph/W=$strGraph_Name Tracing_Y_Wave vs Tracing_X_Wave
		ModifyGraph/W=$strGraph_Name lsize(Tracing_Y_Wave)=2,lstyle(Tracing_Y_Wave)=0, mode(Tracing_Y_Wave)=4, msize(Tracing_Y_Wave)=6
	ENDIF
	
	ModifyGraph/W=$strGraph_Name/Z UIControl=2		//Disables the cursors while digitizing so the user doesn't do something stupid
	
	// display digitized in seperate window
	Digitization_Show_Data_Seperately(Data_X_Wave,Data_Y_Wave, strGraph_Name)
	
	// eventually here we'll also append Data_Y_Wave vs Data_X_Wave on an axis aligned to the x & y min/max points and values.
	WAVE/D/Z Tracing_Y_Wave = TraceNameToWaveRef(strGraph_Name, "Tracing_Y_Wave")
	IF(WaveExists(Tracing_Y_Wave))
		WAVE/D/Z Tracing_X_Wave= XWaveRefFromTrace(strGraph_Name, "Tracing_Y_Wave")
		Redimension/N=0 Tracing_X_Wave, Tracing_Y_Wave
	
	ELSE
		NewDataFolder/O/S root:Packages
		NewDataFolder/O/S $"root:Packages:ATH_DataFolder:IgorThief_"+strGraph_Tag
		Make/O/D/N=0 Tracing_X_Wave, Tracing_Y_Wave		
		SetDataFolder dfrCurrent_Data_Folder

		AppendToGraph/W=$strGraph_Name Tracing_Y_Wave vs Tracing_X_Wave
		ModifyGraph/W=$strGraph_Name lsize(Tracing_Y_Wave)=2,lstyle(Tracing_Y_Wave)=0, mode(Tracing_Y_Wave)=4, msize(Tracing_Y_Wave)=6
	ENDIF

	return 1
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Stops digitization and resets various controls
STATIC FUNCTION Digitization_Stop(STRING strGraph_Name)

	String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)

	ControlInfo/W=$strGraph_Name T3_Pop_X_wave
	WAVE/Z Data_X_Wave= $S_UserData
	IF(!WaveExists(Data_X_Wave))
		return 0
	ENDIF
	
	ControlInfo/W=$strGraph_Name T3_Pop_Y_wave
	WAVE/Z Data_Y_Wave= $S_USerData
	IF(!WaveExists(Data_Y_Wave))
		return 0
	ENDIF
	
	Button T4_Button_Digitize, win=$strGraph_Name, title="4a. Start Digitizing"
	ModifyGraph/W=$strGraph_Name/Z UIControl=0			//Reenables moving the cursors
	
	WAVE/Z Tracing_Y_Wave = TraceNameToWaveRef(strGraph_Name, "Tracing_Y_Wave")
	WAVE/Z Tracing_X_Wave= XWaveRefFromTrace(strGraph_Name, "Tracing_Y_Wave")

	// see if the derived x values need sorting (don't check Tracing_X_Wave, because ccw tilt can cause Tracing_X_Wave to be non-increasing while Data_X_Wave is strictly increasing)
	IF((numpnts(Data_X_Wave) > 0) && !Digitization_Is_Monotonic(Data_X_Wave))
		// ask if the user wants to sort by x data
		DoWindow/F $"DigitizedData_"+strGraph_Tag
		DoAlert 1, "X values aren't sorted. Sort them?"
		IF(V_flag==1)		// yes clicked
			IF(WaveExists(Tracing_Y_Wave))
				Sort Data_X_Wave, Data_X_Wave, Data_Y_Wave, Tracing_X_Wave, Tracing_Y_Wave
			ELSE
				Sort Data_X_Wave, Data_X_Wave, Data_Y_Wave
			ENDIF
		ENDIF
	ENDIF
	
	DoWindow/B=$strGraph_Name $"DigitizedData_"+strGraph_Tag
	
	Return 1
	
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Converts values in the graph windows coordinate system into values from the image
STATIC FUNCTION [VARIABLE vX_Val, VARIABLE vY_Val] Digitization_Axis_XY_to_Data_XY(VARIABLE vMouse_Axis_X, VARIABLE vMouse_Axis_Y, STRING strGraph_Name, WAVE/Z DimDelta_Values)
	
	ControlInfo/W=$strGraph_Name T2_Pop_X_Axis_Type
	String strAxis_Type_X=S_Value
	
	ControlInfo/W=$strGraph_Name T2_Pop_Y_Axis_Type
	String strAxis_Type_Y=S_Value
	
	ControlInfo/W=$strGraph_Name T2_Check_Use_Points
	Variable vUse_Points=V_Value
	
	Make/O/T/FREE/N=4 Cursor_List=num2char(char2Num(kstrStarting_Cursor)+p)
	Make/O/D/FREE/N=4 Csr_X_Values=NaN, Csr_Y_Values=NaN, XY_Min_Max_Values=NaN
	
	vMouse_Axis_X/=DimDelta_Values[0]		//I don't totally understand why I need to divide by the dimdelta, but it doesn't work otherwise
	vMouse_Axis_Y/=DimDelta_Values[1]
	
	Int iCsrDex
	FOR(iCsrDex=0;iCsrDex<numpnts(Cursor_List);iCsrDex+=1)
		ControlInfo/W=$strGraph_Name $"Csr_SetVar_"+Cursor_List[iCsrDex]
		XY_Min_Max_Values[iCsrDex]=V_Value
		
		Csr_X_Values[iCsrDex]=hcsr($Cursor_List[iCsrDex], strGraph_Name)/DimDelta_Values[0]
		Csr_Y_Values[iCsrDex]=vcsr($Cursor_List[iCsrDex], strGraph_Name)/DimDelta_Values[1]
	ENDFOR
	
	Variable vXmin, vXmax, vYmin, vYmax
	
	STRSWITCH(strAxis_Type_X)
		CASE "Linear":
			vXmin=XY_Min_Max_Values[0]
			vXmax=XY_Min_Max_Values[1]
		BREAK
		
		CASE "Log10":
			vXmin=log(XY_Min_Max_Values[0])
			vXmax=log(XY_Min_Max_Values[1])
		BREAK
		
		CASE "ln":
			vXmin=ln(XY_Min_Max_Values[0])
			vXmax=ln(XY_Min_Max_Values[1])
		BREAK
		
		CASE "Recip":
			vXmin=1/(XY_Min_Max_Values[0])
			vXmax=1/(XY_Min_Max_Values[1])
		BREAK
		
		CASE "Sqrt":
			vXmin=sqrt(XY_Min_Max_Values[0])
			vXmax=sqrt(XY_Min_Max_Values[1])
		BREAK
	ENDSWITCH
	
	STRSWITCH(strAxis_Type_Y)
		CASE "Linear":
			vYmin=XY_Min_Max_Values[2]
			vYmax=XY_Min_Max_Values[3]
		BREAK
		
		CASE "Log10":
			vYmin=log(XY_Min_Max_Values[2])
			vYmax=log(XY_Min_Max_Values[3])
		BREAK
		
		CASE "ln":
			vYmin=ln(XY_Min_Max_Values[2])
			vYmax=ln(XY_Min_Max_Values[3])
		BREAK
		
		CASE "Recip":
			vYmin=1/(XY_Min_Max_Values[2])
			vYmax=1/(XY_Min_Max_Values[3])
		BREAK
		
		CASE "Sqrt":
			vYmin=sqrt(XY_Min_Max_Values[2])
			vYmax=sqrt(XY_Min_Max_Values[3])
		BREAK
	ENDSWITCH
	
	
	IF(vUse_Points)
		//Project axisx and axisy values onto x and y axes, and scale appropriately This handles rotation!
		vX_Val = ((vMouse_Axis_X-Csr_X_Values[0])*(Csr_X_Values[1]-Csr_X_Values[0])+(vMouse_Axis_Y-Csr_Y_Values[0])*(Csr_Y_Values[1]-Csr_Y_Values[0]))/((Csr_X_Values[1]-Csr_X_Values[0])^2+(Csr_Y_Values[1]-Csr_Y_Values[0])^2)*(vXmax-vXmin) + vXmin
		vY_Val = ((vMouse_Axis_X-Csr_X_Values[2])*(Csr_X_Values[3]-Csr_X_Values[2])+(vMouse_Axis_Y-Csr_Y_Values[2])*(Csr_Y_Values[3]-Csr_Y_Values[2]))/((Csr_X_Values[3]-Csr_X_Values[2])^2+(Csr_Y_Values[3]-Csr_Y_Values[2])^2)*(vYmax-vYmin) + vYmin
	
	ELSE
		vX_Val=((vXmax-vXmin)/(Csr_X_Values[1]-Csr_X_Values[0]))*(vMouse_Axis_X-Csr_X_Values[0])+vXmin
		vY_Val=((vYmax-vYmin)/(Csr_Y_Values[3]-Csr_Y_Values[2]))*(vMouse_Axis_Y-Csr_Y_Values[2])+vYmin
	ENDIF
	
	
	STRSWITCH(strAxis_Type_X)
		CASE "Linear":
			//don't need to do anything
		BREAK
		
		CASE "Log10":
			vX_Val=10^vX_Val
		BREAK
		
		CASE "ln":
			vX_Val=exp(vX_Val)
		BREAK
		
		CASE "Recip":
			vX_Val=1/vX_Val
		BREAK
		
		CASE "Sqrt":
			vX_Val=vX_Val^2
		BREAK
	ENDSWITCH
	
	STRSWITCH(strAxis_Type_Y)
		CASE "Linear":
			//don't need to do anything
		BREAK
		
		CASE "Log10":
			vY_Val=10^vY_Val
		BREAK
		
		CASE "ln":
			vY_Val=exp(vY_Val)
		BREAK
		
		CASE "Recip":
			vY_Val=1/vY_Val
		BREAK
		
		CASE "Sqrt":
			vY_Val=vY_Val^2
		BREAK
	ENDSWITCH
	
	
	Return [vX_Val, vY_Val]

END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Shows data in a separate window.  From IgorThief
STATIC FUNCTION Digitization_Show_Data_Seperately(WAVE Data_X_Wave, WAVE Data_Y_Wave, STRING strGraph_Name)

	String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)
	
	DoWindow $"DigitizedData_"+strGraph_Tag
	IF(V_Flag)
		CheckDisplayed/W=$"DigitizedData_"+strGraph_Tag Data_Y_Wave
		IF(V_Flag == 0)
			AppendToGraph/W=$"DigitizedData_"+strGraph_Tag Data_Y_Wave vs Data_X_Wave
			Variable vTop_Trace_Index= ItemsInList(TraceNameList("DigitizedData_"+strGraph_Tag, ";", 1))-1
			AssignColorForTraceIndex("DigitizedData_"+strGraph_Tag, vTop_Trace_Index)
		ENDIF
	
	ELSE
		Display/N=$"DigitizedData_"+strGraph_Tag/K=1 Data_Y_Wave vs Data_X_Wave as "DigitizedData_"+strGraph_Tag
		DoWindow/C $"DigitizedData_"+strGraph_Tag	// in case of a saved macro
		AssignColorForTraceIndex("DigitizedData_"+strGraph_Tag, 0)
		Legend/C/N=digitized
		AutoPositionWindow/E/R=$strGraph_Name/M=1 $"DigitizedData_"+strGraph_Tag
		DoWindow/B=$strGraph_Name $"DigitizedData_"+strGraph_Tag
		ModifyGraph/W=$"DigitizedData_"+strGraph_Tag grid=1
	ENDIF
	
	ControlInfo/W=$strGraph_Name T2_Checkbox_Log_X_Axis
	ModifyGraph/W=$"DigitizedData_"+strGraph_Tag log(bottom)=V_Value 
	
	ControlInfo/W=$strGraph_Name T2_Checkbox_Log_Y_Axis
	ModifyGraph/W=$"DigitizedData_"+strGraph_Tag log(left)=V_Value 
	
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Mostly from IgorThief
STATIC FUNCTION Editing_Button_Start_Stop(STRUCT WMButtonAction &ba) : ButtonControl
	
	SWITCH(ba.eventcode)
		CASE 2:
			String strGraph_Name=ba.win
			String strGraph_Tag=ParseFilePath(0, strGraph_Name, "_", 1, 0)
		
			ControlInfo/W=$strGraph_Name H0_SetVar_Are_Editing
			Variable vAre_Editing=V_Value
		
			IF(!vAre_Editing)		//Start editing
				ControlInfo/W=$strGraph_Name T3_Pop_X_wave
				WAVE/Z Data_X_Wave= $S_UserData
				IF(!WaveExists(Data_X_Wave))
					return 0
				ENDIF
				
				ControlInfo/W=$strGraph_Name T3_Pop_Y_wave
				WAVE/Z Data_Y_Wave= $S_UserData
				IF(!WaveExists(Data_Y_Wave))
					return 0
				endif
				
				WAVE/Z Tracing_Y_Wave = TraceNameToWaveRef(strGraph_Name, "Tracing_Y_Wave")
				IF(!WaveExists(Tracing_Y_Wave))
					return 0
				ENDIF
			
				WAVE/Z Tracing_X_Wave= XWaveRefFromTrace(strGraph_Name, "Tracing_Y_Wave")
				IF(!WaveExists(Tracing_X_Wave))
					return 0
				ENDIF
				
				Button T5_Button_Edit, win=$strGraph_Name, title="5b. Stop Editing"
			
				GraphWaveEdit/W=$strGraph_Name Tracing_Y_Wave		//Switch to edit mode
				ModifyGraph/W=$strGraph_Name/Z UIControl=2		//Disables the cursors while editing so the user doesn't accidentally move a cursor
				
			ELSE
				Button T5_Button_Edit, win=$strGraph_Name, title="5a. Start Editing"
								
				GraphNormal/W=$strGraph_Name
				ModifyGraph/W=$strGraph_Name/Z UIControl=0		//Reenables the cursors
			ENDIF
			
			SetVariable H0_SetVar_Are_Editing, win=$strGraph_Name, value=_NUM:!vAre_Editing
			Graph_Update_Controls(strGraph_Name)
		BREAK
		
		CASE -1: // control being killed
		BREAK
	ENDSWITCH

	return 0
	
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Returns true if the wave has ∂wave(x)/∂x >= 0 for all x.  Taken from Igor Thief with some clean up (e.g. replaced DO-WHILE with FOR)
STATIC FUNCTION Digitization_Is_Monotonic(Wave Data_Wave)
	
	Variable vDelta,iPntDex
	Variable vNum_Pnts=numpnts(Data_Wave)-1
	Variable vIncreasing=(Data_Wave[1]-Data_Wave[0])>0
	
	FOR(iPntDex=0;iPntDex<vNum_Pnts;iPntDex+=1)
		vDelta=vIncreasing ? Data_Wave[iPntDex+1]-Data_Wave[iPntDex] : Data_Wave[iPntDex]-Data_Wave[iPntDex+1]
		
		IF(vDelta<0)	//Original code had a check for the numtype of vDelta, but we only care about the true case here, and if vDelta is a NaN we won't hit the true case
			return 0	// not monotonically increasing. (we allow Data_Wave[iPntDex+1] == Data_Wave[iPntDex]).
		ENDIF
	ENDFOR
	
	return 1			// success
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//From Igor Thief, probably not going to change
STATIC FUNCTION AssignColorForTraceIndex(STRING strGraph_Name, INT iTraceDex)

	Variable vRed, vGreen, vBlue

	SWITCH(mod(iTraceDex, 10))// Wrap after 10 traces.
		CASE 0:
			vRed = 0; vGreen = 0; vBlue = 0;
		BREAK

		CASE 1:
			vRed = 65535; vGreen = 16385; vBlue = 16385;
		BREAK
			
		CASE 2:
			vRed = 2; vGreen = 39321; vBlue = 1;
		BREAK
			
		CASE 3:
			vRed = 0; vGreen = 0; vBlue = 65535;
		BREAK
			
		CASE 4:
			vRed = 39321; vGreen = 1; vBlue = 31457;
		BREAK
			
		CASE 5:
			vRed = 48059; vGreen = 48059; vBlue = 48059;
		BREAK
			
		CASE 6:
			vRed = 65535; vGreen = 32768; vBlue = 32768;
		BREAK
			
		CASE 7:
			vRed = 0; vGreen = 65535; vBlue = 0;
		BREAK
			
		CASE 8:
			vRed = 16385; vGreen = 65535; vBlue = 65535;
		BREAK
			
		CASE 9:
			vRed = 65535; vGreen = 32768; vBlue = 58981;
		BREAK
	ENDSWITCH
	
	IF(strlen(strGraph_Name)==0)
		strGraph_Name= WinName(0,1,1)
	ENDIF
	
	DoWindow $strGraph_Name
	IF(V_Flag)
		ModifyGraph/Z/W=$strGraph_Name rgb[iTraceDex]=(vRed, vGreen, vBlue)
	ENDIF
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Makes the help notebook
STATIC FUNCTION Help_Button(STRUCT WMButtonAction &ba) : ButtonControl
	
	SWITCH(ba.eventcode)
		CASE 2:
			String nb = "IgorThief2Help"		//Igor uses nb when you make the notebook commands, so just use that here

			DoWindow/F/B=$ba.win $nb
			IF(V_Flag==0)
				String strUpdate_Date="Glorious 25th of May, Year of the Dancing Dog"
				String strIpf_path=FunctionPath(GetRTStackInfo(1))
				GetFileFolderInfo/Q/Z strIpf_path
				IF(V_Flag==0 && V_IsFile)
					strUpdate_Date=Secs2Date(V_modificationDate, -2)
				ENDIF
				
				NewNotebook/N=$nb/F=1/V=1/K=1/ENCG={3,1}/OPTS=4
				Notebook $nb showRuler=0
				Notebook $nb newRuler=Normal, justification=0, margins={0,0,670}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",kvDefault_Notebook_Size,0,(0,0,0)}
				Notebook $nb ruler=Normal, fSize=kvDefault_Notebook_Size+3, fStyle=1, text="IgorThief2 documentation\r"
				
				Notebook $nb text=""
				Notebook $nb fSize=(kvDefault_Notebook_Size-3), fStyle=-1, text="Last updated "+strUpdate_Date+"\r"
				Notebook $nb fSize=-1, text="\r"
		
				Notebook $nb text="IgorThief2 is a basic graph trace digitizer. It is an updated version of the IgorThief utility which is based on a user contribution by Daniel Murphy dated 9 Aug 2002.\r"
				Notebook $nb text="\r"
				Notebook $nb text="The tool is used to digitize discrete data (i.e. markers) from an image or a graph.  If you have continuous data (i.e. lines), you should use the "
				NotebookAction commands=("BrowseUrl/Z \"https://www.wavemetrics.com/project/tracer\""), linkStyle=1, quiet=1, title="Tracer package", helpText="https://www.wavemetrics.com/project/tracer"
				Notebook $nb text=" by Igor Forums user "
				NotebookAction commands=("BrowseUrl/Z \"https://www.wavemetrics.com/user/tony\""), linkStyle=1, quiet=1, title="tony", helpText="https://www.wavemetrics.com/user/tony"
				Notebook $nb text=".  Some features of Tracer (e.g. loading clipboard images) have been incorporated into IgorThief2.  \r"
				Notebook $nb text="\r"
				Notebook $nb text="Like IgorThief, IgorThief2 works on arbitrarily rotated graphs because you teach it the x and y values at two points along each axis.\r"
				Notebook $nb text="\r"
				Notebook $nb text="Major changes from IgorThief include the ability to have multiple digitization graphs, a hopefully more user-friendly interface for setting the axis min/max values, and the elimination of globals. "
				Notebook $nb text="There are also two cursor styles to choose from: points, which are useful if the image is rotated; and lines, which are a little more user-friendly but won't work if the image is rotated.  \r"
				Notebook $nb text="\r"
				Notebook $nb text="There are some checks to prevent the user from getting themselves into trouble (e.g. the cursors are locked when digitizing or editing), but I have not tested everything to failure.  "
				Notebook $nb text="This should not be interpreted as a challenge.  \r"
				Notebook $nb text="\r"
				Notebook $nb text="To start, go to Data->IgorThief2, which will create a blank graph.  \r"
				Notebook $nb text="\r"
				Notebook $nb text="The default graph name is \"IgorThiefGraph_[Graph Tag]\", where the Graph Tag is an integer starting from 0.  "
				Notebook $nb text="The names of the data folder and any other graphs associated with that instance of IgorThief2 will all end with the tag.  The tag is defined internally as the last item in an underscore separated list.  "
				Notebook $nb text="If you change the name (not the title) of the graph, the code will get a new graph tag and update the names of any associated objects.  \r"
				Notebook $nb text="\r"
				Notebook $nb text="Once you have made the graph, either select an already loaded image wave from the Image popup or select \"New Image\" to load a new image.  "
				Notebook $nb text="If you have an image in the Clipboard (e.g. from a Windows screen snip) you can load that without having to first save the image.  "
				Notebook $nb text="Note that the image wave will not be altered in any way (e.g. the x and y scaling will not be changed).\r"
				Notebook $nb text="\r"
				Notebook $nb text="Move the cursors to the min and max positions of the X and Y axes, and then enter values for those points in the setvars associated with the cursors.  "
				Notebook $nb text="If you are using point cursors and a setvar is in the way, you can move it by clicking while holding down the control (Windows) or command (macOS) key and then moving to a better location.  "
				Notebook $nb text="Click the control again (or release the control/commadn key) when it is in a good place.  \r"
				Notebook $nb text="\r"
				Notebook $nb text="If an axis uses a log scale, select the approriate checkbox. \r"
				Notebook $nb text="\r"
				Notebook $nb text="Select x and y waves to receive the digitized data.  The data will be appended to the end of the waves. "
				Notebook $nb text=" You must select (or create) an x and y wave in order to Start Digitizing.\r"
				Notebook $nb text="\r"
				Notebook $nb text="Then click \"Start Digitizing\", and click on the image to add x/y values to the digitized waves. The digitized waves are displayed in a seperate DigitizedData graph. "
				Notebook $nb text="The cursors will be locked in place while you digitize to prevent you from accidentally moving them.  "
				Notebook $nb text="Select \"Edit\"->\"Undo\" to remove the last digitized value. "
				Notebook $nb text="If you want to zoom in while digitizing, hold down the command/control button while selecting the area to zoom in to, and then keep holding the key while you select the zoom option.  \r"
				Notebook $nb text="\r"
				Notebook $nb text="Click \"Stop Digitizing\" to display the graph containing the digitized values.\r"
				Notebook $nb text="\r"
				Notebook $nb text="Click \"Start Editing\" to alter the digitized values.\r"
				Notebook $nb text="\r"
				Notebook $nb text="The controls in the editing mode because it is too easy to accidently edit the controls.\r"
				Notebook $nb text="\r"
				Notebook $nb text="As you edit the trace, the changes are reflected in the digitized waves displayed in the DigitizedData graph.  "
				Notebook $nb text="See "
				NotebookAction/W=$nb name=waveEditingHelp, title="Editing a Polygon", commands="DisplayHelpTopic \"Editing a Polygon\""
				Notebook $nb text=" for details on editing the (polygonal) wave.\r"
				Notebook $nb text="\r"
				Notebook $nb text="To end the editing, click \"Stop Editing.\"\r"
				Notebook $nb text="\r"
				Notebook $nb text="To digitize another trace, select \"New Wave\" in the \"X Data\" and \"Y Data\" popups and then click \"Start "
				Notebook $nb text="Digitizing\".\r"
				Notebook $nb text="\r"
				Notebook $nb text="The same X/Y point and values will be used to digitize the new trace, and the digitized result is added "
				Notebook $nb text="to the DigitizedData graph.\r"
		
				// scroll back to the top
				Notebook $nb selection={startOfFile, startOfFile },findText={"", 1}
		
				AutopositionWindow/R=$ba.win $nb
				Notebook $nb visible=1
			ENDIF
			
			DoWindow/F IgorThief2Help
			AutopositionWindow/R=$ba.win/M=0 IgorThief2Help
		BREAK
		
		CASE -1: // control being killed
		BREAK
	ENDSWITCH

	return 0
END


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
