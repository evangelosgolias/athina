#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

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

/// Interactive drift correction of a 3D wave

Function MXP_CreateInteractiveImageRotationPanel()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph"
		return -1
	endif	
	
	WAVE wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
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
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:InteractiveImageRotation:" + winNameStr) // Root folder here
	string backupNameStr = NameOfWave(wRef) + "_undo"
	Duplicate/O wRef, dfr:$backupNameStr
	// Create the global variables for panel
	string/G dfr:gMXP_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gMXP_WindowNameStr = winNameStr
	string/G dfr:gMXP_wPathname = GetWavesDataFolder(wRef, 2)
	string/G dfr:gMXP_wPath = GetWavesDataFolder(wRef, 1)
	string/G dfr:gMXP_wNameStr = NameOfWave(wRef)
	string/G dfr:gMXP_wBackupPathNameStr = GetWavesDataFolder(dfr:$backupNameStr, 2)
	variable/G dfr:gMXP_Angle = 0 // Not set
	
	NewPanel/K=1/EXT=0/N=iImageRotation/W=(0,0,300,130)/HOST=$winNameStr

	SetDrawLayer/W=iImageRotation UserBack
	SetDrawEnv/W=iImageRotation fsize= 13,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=iImageRotation 90, 20,"Image rotation (deg)"
	Slider RotAngleSlider vert=0,limits={-180,180,0},pos={15,25},size={270,50},ticks=50, fSize=12
	Slider RotAngleSlider variable=dfr:gMXP_Angle,proc=MXP_InteractiveImageRotationSliderProc
	SetVariable RotAngle title="Set angle",fSize=14,size={120,20}, pos={90,70}, value = dfr:gMXP_Angle, proc=MXP_InteractiveImageRotationSetAngle
	Button SaveImg title="Save copy",size={80,20},pos={20,100},proc=MXP_InteractiveImageRotationSaveCopyButton
	Button OverwiteImg title="Overwite ",size={70,20}, pos={110,100},proc=MXP_InteractiveImageRotationOverwriteImgButton
	Button RestoreImageRot title="Restore",size={80,20},pos={190,100},fColor=(3,52428,1),proc=MXP_InteractiveImageRotationRestoreImageRotButton

	SetWindow $winNameStr#iImageRotation hook(MyImageRotationPanelHook) = MXP_iImageRotationPanelHookFunction
	SetWindow $winNameStr#iImageRotation userdata(MXP_iRotateFolder) = "root:Packages:MXP_DataFolder:InteractiveImageRotation:" + winNameStr
	SetWindow $winNameStr#iImageRotation userdata(MXP_iImageRotateParentWindow) = winNameStr
	
	SetWindow $winNameStr hook(MyImageRotationParentGraphHook) = MXP_ImageRotationParentGraphHookFunction
	SetWindow $winNameStr userdata(MXP_iRotateFolder) = "root:Packages:MXP_DataFolder:InteractiveImageRotation:" + winNameStr
	return 0
End

Function MXP_ImageRotationParentGraphHookFunction(STRUCT WMWinHookStruct &s)
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(s.winName, "", "MXP_iRotateFolder"))
	SVAR/SDFR=dfr gMXP_WindowNameStr
	SVAR/SDFR=dfr gMXP_wPathname
	SVAR/SDFR=dfr gMXP_wBackupPathNameStr
	WAVE wRef = $gMXP_wPathname
	WAVE wRefbck = $gMXP_wBackupPathNameStr
    switch(s.eventCode)
		case 2: // Kill the window
			Duplicate/O wRefbck, wRef
			SetWindow $s.winName, hook(MyImageRotationParentGraphHook) = $""
			KillDataFolder dfr
			hookresult = 1
			break
	endswitch
	return hookresult
End

Function MXP_iImageRotationPanelHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed
	//Cleanup when window is closed
	variable hookresult = 0
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(s.winName, "", "MXP_iRotateFolder"))
	SVAR/SDFR=dfr gMXP_WindowNameStr
	SVAR/SDFR=dfr gMXP_wPathname
	SVAR/SDFR=dfr gMXP_wBackupPathNameStr
	WAVE wRef = $gMXP_wPathname
	WAVE wRefbck = $gMXP_wBackupPathNameStr
    switch(s.eventCode)
		case 2: // Kill the window
			Duplicate/O wRefbck, wRef
			SetWindow $s.winName, hook(MyImageRotationPanelHook) = $""
			string parentWindow = GetUserData(s.winName, "", "MXP_iImageRotateParentWindow")
			SetWindow $parentWindow, hook(MyImageRotationParentGraphHook) = $"" // Unhook the parent graph
			KillDataFolder dfr
			hookresult = 1
			break
	endswitch
	return hookresult
End

Function MXP_InteractiveImageRotationSliderProc(STRUCT WMSliderAction &sa) : SliderControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sa.win, "", "MXP_iRotateFolder"))
	SVAR/SDFR=dfr gMXP_wPathname
	SVAR/SDFR=dfr gMXP_wBackupPathNameStr
	NVAR/SDFR=dfr gMXP_Angle
	WAVE wRef = $gMXP_wPathname
	WAVE wRefbck = $gMXP_wBackupPathNameStr
	switch( sa.eventCode )
		case -3: // Control received keyboard focus
		case -2: // Control lost keyboard focus
		case -1: // Control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				gMXP_Angle = sa.curval
				sImageRestoreAndRotate(wRefbck, wRef, gMXP_Angle)
			endif
			break
	endswitch

	return 0
End

Function MXP_InteractiveImageRotationSetAngle(STRUCT WMSetVariableAction &sva) : SetVariableControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(sva.win, "", "MXP_iRotateFolder"))
	SVAR/SDFR=dfr gMXP_wPathname
	SVAR/SDFR=dfr gMXP_wBackupPathNameStr
	NVAR/SDFR=dfr gMXP_Angle
	WAVE wRef = $gMXP_wPathname
	WAVE wRefbck = $gMXP_wBackupPathNameStr
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			gMXP_Angle = sva.dval
			sImageRestoreAndRotate(wRefbck, wRef, gMXP_Angle)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function MXP_InteractiveImageRotationSaveCopyButton(STRUCT WMButtonAction &ba) : ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(ba.win, "", "MXP_iRotateFolder"))
	SVAR/SDFR=dfr gMXP_wPathname
	SVAR/SDFR=dfr gMXP_wBackupPathNameStr
	SVAR/SDFR=dfr gMXP_wNameStr
	NVAR/SDFR=dfr gMXP_Angle
	WAVE wRef = $gMXP_wPathname
	WAVE wRefbck = $gMXP_wBackupPathNameStr
	string backupwNameStr = gMXP_wNameStr + "_rot"
	switch( ba.eventCode )
		case 2: // mouse up
			string noteStr = gMXP_wPathname + " rotated by " + num2str(gMXP_Angle) + " deg"
			Duplicate/O wRef, $backupwNameStr /WAVE =wCopyRef
			Note wCopyRef, noteStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function MXP_InteractiveImageRotationOverwriteImgButton(STRUCT WMButtonAction &ba) : ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(ba.win, "", "MXP_iRotateFolder"))
	SVAR/SDFR=dfr gMXP_wPathname
	SVAR/SDFR=dfr gMXP_wBackupPathNameStr
	NVAR/SDFR=dfr gMXP_Angle
	WAVE wRef = $gMXP_wPathname
	WAVE wRefbck = $gMXP_wBackupPathNameStr
	switch( ba.eventCode )
		case 2: // mouse up
			DoAlert 1, "Do want to ovewrite the source image? The operation cannot be restored"
			if(V_Flag == 1)
				string noteStr = gMXP_wPathname + " rotated by " + num2str(gMXP_Angle) + " deg"
				Duplicate/O wRef, wRefbck
				Note wRefbck, noteStr
				Note wRef, noteStr
				Button RestoreImageRot, win=$ba.win, fColor=(65535,0,0)
				ControlUpdate/W=$ba.win RestoreImageRot
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function MXP_InteractiveImageRotationRestoreImageRotButton(STRUCT WMButtonAction &ba) : ButtonControl
	DFREF dfr = MXP_CreateDataFolderGetDFREF(GetUserData(ba.win, "", "MXP_iRotateFolder"))
	SVAR/SDFR=dfr gMXP_wPathname
	SVAR/SDFR=dfr gMXP_wBackupPathNameStr
	NVAR/SDFR=dfr gMXP_Angle
	WAVE wRef = $gMXP_wPathname
	WAVE wRefbck = $gMXP_wBackupPathNameStr
	switch( ba.eventCode )
		case 2: // mouse up
			Duplicate/O wRefbck, wRef
			gMXP_Angle = 0 // Set angle to zero
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


static Function sImageRestoreAndRotate(WAVE source, WAVE dest, variable angle)
	/// Rotate dest, restore source
	Duplicate/O source, dest
	ImageRotate/Q/O/A=(angle) dest
	return 0
End

