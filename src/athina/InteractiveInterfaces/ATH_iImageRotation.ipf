#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_iImgRotation
#pragma version = 1.2

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

static Function CreatePanel()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph"
		return -1
	endif	
	
	WAVE wRef = ATH_Graph#TopImageToWaveRef()
	//Check if you have already created the panel
	if(WinType(winNameStr + "#iImageRotation") == 7)
		print "ImageRotation panel is already active"
		return 1
	endif
	
	if(!strlen(imgNameTopGraphStr))
		print "Operation needs an image or image stack."
		return -1
	endif
	

	//Duplicate the wave for backup
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveImageRotation:" + winNameStr) // Root folder here
	string backupNameStr = NameOfWave(wRef) + "_undo"
	Duplicate/O wRef, dfr:$backupNameStr
	// Create the global variables for panel
	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_wPathname = GetWavesDataFolder(wRef, 2)
	string/G dfr:gATH_wPath = GetWavesDataFolder(wRef, 1)
	string/G dfr:gATH_wNameStr = NameOfWave(wRef)
	string/G dfr:gATH_wBackupPathNameStr = GetWavesDataFolder(dfr:$backupNameStr, 2)
	variable/G dfr:gATH_Angle = 0 // Not set
	variable/G dfr:gATH_FlipCols = 0
	NewPanel/K=1/EXT=0/N=iImageRotation/W=(0,0,300,130)/HOST=$winNameStr
	
	string pnlName = winNameStr + "#iImageRotation"
	SetDrawLayer/W=$pnlName UserBack
	SetDrawEnv/W=$pnlName fsize= 13,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=$pnlName 90, 20,"Image rotation (deg)"
	Slider RotAngleSlider, vert=0,limits={-180,180,0},pos={15,25},size={270,50},win=$pnlName
	Slider RotAngleSlider,ticks=50, fSize=12,variable=dfr:gATH_Angle,proc=ATH_iImgRotation#SliderProc,win=$pnlName
	SetVariable RotAngle, title="Set angle",fSize=14,size={120,20},win=$pnlName
	SetVariable RotAngle, pos={40,70}, value = dfr:gATH_Angle, proc=ATH_iImgRotation#SetAngle,win=$pnlName
	CheckBox FlipRowsCB,pos={180,70.00},size={98.00,17.00},win=$pnlName
	CheckBox FlipRowsCB,fcolor=(65535,0,0),title="Flip y-axis",fSize=14,value=0,side=1,win=$pnlName,proc=ATH_iImgRotation#FlipRowsCheckBox
	Button SaveImgB, title="Save copy",size={80,20},pos={20,100},proc=ATH_iImgRotation#iRotButton,win=$pnlName,win=$pnlName
	Button OverwiteImgB, title="Overwite ",size={70,20}, pos={110,100},proc=ATH_iImgRotation#iRotButton,win=$pnlName
	Button RestoreImageRotB, title="Restore",size={80,20},pos={190,100},win=$pnlName
	Button RestoreImageRotB, fColor=(3,52428,1),proc=ATH_iImgRotation#iRotButton,win=$pnlName
		
	SetWindow $pnlName hook(MyImageRotationPanelHook) = ATH_iImgRotation#PanelHookFunction
	SetWindow $pnlName userdata(ATH_iRotateFolder) = "root:Packages:ATH_DataFolder:InteractiveImageRotation:" + winNameStr
	SetWindow $pnlName userdata(ATH_iImageRotateParentWindow) = winNameStr
	
	SetWindow $winNameStr hook(MyImageRotationParentGraphHook) = ATH_iImgRotation#GraphHookFunction
	SetWindow $winNameStr userdata(ATH_iRotateFolder) = "root:Packages:ATH_DataFolder:InteractiveImageRotation:" + winNameStr
	return 0
End

static Function FlipRowsCheckBox(STRUCT WMCheckboxAction& cb) : CheckBoxControl
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(cb.win, "", "ATH_iRotateFolder"))
	NVAR/SDFR=dfr gATH_FlipCols
	SVAR/SDFR=dfr gATH_wPathname, gATH_wBackupPathNameStr
	WAVE wRef = $gATH_wPathname
	WAVE wRefbck = $gATH_wBackupPathNameStr
	switch(cb.checked)
		case 1:
			gATH_FlipCols = 1
			CheckBox FlipRowsCB fColor=(2,39321,1), win=$cb.win
			ImageTransform flipCols wRef
			break
		case 0:
			gATH_FlipCols = 0
			CheckBox FlipRowsCB,fcolor=(65535,0,0), win=$cb.win
			ImageTransform flipCols wRef
			break
	endswitch
	return 0
End

static Function GraphHookFunction(STRUCT WMWinHookStruct &s)

	switch(s.eventCode)
		case 2: // Kill the window
			variable hookresult = 0
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iRotateFolder"))
			SVAR/SDFR=dfr gATH_wPathname, gATH_wBackupPathNameStr
			WAVE wRef = $gATH_wPathname
			WAVE wRefbck = $gATH_wBackupPathNameStr
			Duplicate/O wRefbck, wRef
			SetWindow $s.winName, hook(MyImageRotationParentGraphHook) = $""
			KillDataFolder dfr
			hookresult = 1
			break
	endswitch
	return hookresult
End

static Function PanelHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed

	switch(s.eventCode)
		case 2: // Kill the window
			variable hookresult = 0
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iRotateFolder"))
			SVAR/SDFR=dfr gATH_wPathname, gATH_wBackupPathNameStr
			WAVE wRef = $gATH_wPathname
			WAVE wRefbck = $gATH_wBackupPathNameStr
			Duplicate/O wRefbck, wRef
			SetWindow $s.winName, hook(MyImageRotationPanelHook) = $""
			string parentWindow = GetUserData(s.winName, "", "ATH_iImageRotateParentWindow")
			SetWindow $parentWindow, hook(MyImageRotationParentGraphHook) = $"" // Unhook the parent graph
			KillDataFolder dfr
			hookresult = 1
			break
	endswitch
	return hookresult
End

static Function SliderProc(STRUCT WMSliderAction &sa) : SliderControl

	switch( sa.eventCode )
		case -3: // Control received keyboard focus
		case -2: // Control lost keyboard focus
		case -1: // Control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sa.win, "", "ATH_iRotateFolder"))
				SVAR/SDFR=dfr gATH_wPathname, gATH_wBackupPathNameStr
				NVAR/SDFR=dfr gATH_Angle, gATH_FlipCols
				WAVE wRef = $gATH_wPathname
				WAVE wRefbck = $gATH_wBackupPathNameStr
				gATH_Angle = sa.curval
				ImageRestoreAndRotate(wRefbck, wRef, gATH_Angle, flipY=gATH_FlipCols)
			endif
			break
	endswitch

	return 0
End

static Function SetAngle(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(sva.win, "", "ATH_iRotateFolder"))
			SVAR/SDFR=dfr gATH_wPathname, gATH_wBackupPathNameStr
			NVAR/SDFR=dfr gATH_Angle
			WAVE wRef = $gATH_wPathname
			WAVE wRefbck = $gATH_wBackupPathNameStr
			gATH_Angle = sva.dval
			ImageRestoreAndRotate(wRefbck, wRef, gATH_Angle)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

static Function iRotButton(STRUCT WMButtonAction &ba) : ButtonControl

	if (ba.eventCode != 2)
		return 0
	endif

	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(ba.win, "", "ATH_iRotateFolder"))
	SVAR/SDFR=dfr gATH_wPathname
	SVAR/SDFR=dfr gATH_wBackupPathNameStr
	SVAR/SDFR=dfr gATH_wNameStr
	NVAR/SDFR=dfr gATH_Angle
	WAVE wRef = $gATH_wPathname
	WAVE wRefbck = $gATH_wBackupPathNameStr
	NVAR/SDFR=dfr gATH_FlipCols	
	string noteStr
	strswitch (ba.ctrlName)
		case "SaveImgB":
			DFREF dfr = GetWavesDataFolderDFR(wRef)
			noteStr = gATH_wPathname + " rotated by " + num2str(gATH_Angle) + " deg "
			if(gATH_FlipCols)
				noteStr += "[Flipped y-axis (ImageTransform flipCols w)]."
			endif			
			string backupwNameStr = CreatedataObjectName(dfr, gATH_wNameStr + "_rot", 1, 0, 1)
			Duplicate/O wRef, dfr:$backupwNameStr /WAVE =wCopyRef
			Note wCopyRef, noteStr
			ATH_Display#NewImg(wCopyRef)
			break
		case "OverwiteImgB":
			DoAlert 1, "Do want to ovewrite the source image? You cannot undo the operation"
			if(V_Flag == 1)
				noteStr = gATH_wPathname + " rotated by " + num2str(gATH_Angle) + " deg "
				if(gATH_FlipCols)
					noteStr += "[Flipped y-axis (ImageTransform flipCols w)]."
				endif
				Note wRef, noteStr
				Duplicate/O wRef, wRefbck
				Button RestoreImageRotB, win=$ba.win, fColor=(65535,0,0), disable=2, title = "Restore", fstyle=16
				ControlUpdate/W=$ba.win RestoreImageRotB
			endif
			break
		case "RestoreImageRotB":
			Duplicate/O wRefbck, wRef
			gATH_FlipCols = 0
			CheckBox FlipRowsCB,fcolor=(65535,0,0),value=0,win=$ba.win
			gATH_Angle = 0 // Set angle to zero
			break
	endswitch
	return 0
End


static Function ImageRestoreAndRotate(WAVE source, WAVE dest, variable angle, [int flipY])
	/// Rotate dest, restore source
	Duplicate/O source, dest
	if(flipY)
		ImageTransform flipCols dest
	endif
	ImageRotate/Q/O/A=(-angle)/E=0 dest
	return 0
End

