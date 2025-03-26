#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_iBackground
#pragma version = 1.01

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

static Function CreatelPanel()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	
	if(!strlen(imgNameTopGraphStr))
		print "No image in top graph"
		return -1
	endif
		
	WAVE wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	//Check if you have already created the panel
	if(WinType(winNameStr + "#iBackgroundRemoval") == 7)
		print "#iBackgroundRemoval panel already active"
		return 1
	endif
	// We need a 2d or 3d wave	
	if(WaveDims(wRef) != 3 && WaveDims(wRef) != 2)
		Abort "Operation needs an image or image stack."
	endif

	//Duplicate the wave for backup
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:BackgroundRemoval:" + winNameStr) // Root folder here
	string backupNameStr = NameOfWave(wRef) + "_undo"
	Duplicate/O wRef, dfr:$backupNameStr
	// Create the global variables for panel
	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_wRefPathNameStr = GetWavesDataFolder(wRef, 2)
	string/G dfr:gATH_wRefPath = GetWavesDataFolder(wRef, 1)
	string/G dfr:gATH_wRefNameStr = NameOfWave(wRef)
	string/G dfr:gATH_wRefBackupPathNameStr = GetWavesDataFolder(dfr:$backupNameStr, 2)
	string/G dfr:gATH_wRefBackupNameStr = PossiblyQuoteName(backupNameStr)
	variable/G dfr:gATH_PolyOrder = 1
	variable/G dfr:gATH_left = 0
	variable/G dfr:gATH_right = 0
	variable/G dfr:gATH_top = 0
	variable/G dfr:gATH_bottom = 0
	
	NewPanel/K=1/EXT=0/N=iBackgroundRemoval/W=(0,0,165,250)/HOST=$winNameStr
	//ShowInfo/CP=0/W=$winNameStr
	SetDrawLayer UserBack

	SetDrawEnv/W=iBackgroundRemoval fsize= 13,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=iBackgroundRemoval 15,30,"Interactive background \r          removal"
	SetDrawEnv textrgb= (2,39321,1)
	Button iRBOverwriteAndClose,pos={22.00,40},size={120.00,20.00},title="Ovewrite & close",fSize=12,fColor=(65535,0,0),proc=ATH_iRBOverwriteAndClose

	DrawText 10,120,"You can set a marquee or \r  use the whole image for \r    background removal\r"
	//SetDrawEnv/W=iDriftCorrection dash= 3,fillpat= 0
	Button iRBRemoveBackgroundButton,pos={32.00,120},size={100.00,20.00},fColor=(65535,65533,32768)
	Button iRBRemoveBackgroundButton,title="Remove bckd",fSize=12,proc=ATH_iBackground#RemoveBackgroundButton	
	Button iRBSetMarqueeAreaButton,pos={32.00,155},size={100.00,20.00},title="Set marqueee"
	Button iRBSetMarqueeAreaButton,fSize=12,fColor=(40969,65535,16385)//,proc=ATH_iRBSetMarqueeAreaButtonProc
	Button iRBRestoreImageButton,pos={32.00,190.00},size={100.00,20.00},fColor=(32768,54615,65535)
	Button iRBRestoreImageButton,title="Restore image",fSize=12//,proc=ATH_iRBRestoreImageButtonProc
	SetDrawEnv/W=iBackgroundRemoval fsize= 13,fstyle= 1,textrgb= (1,12815,52428)
//	DrawText 28,243,"Polynomial order\r"
	NVAR PolyOrder = dfr:gATH_PolyOrder
	SetVariable iRBPolynomialOrderSV,pos={10,225.00},size={150.00,20.00},fSize=12,value=PolyOrder,title="Polynomial order",limits={1,10,1}
	//Tranfer info re dfr to controls
	SetWindow $winNameStr#iBackgroundRemoval userdata(ATH_iImageBackgroundRemovalFolder) = "root:Packages:ATH_DataFolder:BackgroundRemoval:" + winNameStr
	SetWindow $winNameStr#iBackgroundRemoval hook(iRBMyHook) = ATH_iBackgroundRemovalPanelHookFunction
	// Set hook to the graph, killing the graph kills the iBackgroundRemoval linked folder
	SetWindow $winNameStr userdata(ATH_iImageBackgroundRemovalFolder) = "root:Packages:ATH_DataFolder:BackgroundRemoval:" + winNameStr
	SetWindow $winNameStr, hook(iRBMyHook) = ATH_iBackground#GraphHookFunction // Set the hook
End

static Function GraphHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iImageBackgroundRemovalFolder"))
	SVAR/Z/SDFR=dfr gATH_imgNameTopWindowStr
	SVAR/Z/SDFR=dfr gATH_WindowNameStr
	
	SVAR/Z/SDFR=dfr gATH_wRefPathNameStr
	SVAR/Z/SDFR=dfr gATH_wRefBackupPathNameStr
	
		
    switch(s.eventCode)
		case 2: // Kill the window
			//Restore wave scaling here as ImageTransform works better with non-scaled waves
			CopyScales/I $gATH_wRefBackupPathNameStr, $gATH_wRefPathNameStr
			KillDataFolder/Z dfr
			SetWindow $s.winName, hook(iRBMyHook) = $""
			Cursor/K I
			hookresult = 1
			break
	endswitch
	return hookresult
End

static Function PanelHookFunction(STRUCT WMWinHookStruct &s) // Cleanup when graph is closed
	//Cleanup when window is closed
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(s.winName, "", "ATH_iImageBackgroundRemovalFolder"))
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/Z/SDFR=dfr gATH_wRefPathNameStr
	SVAR/Z/SDFR=dfr gATH_wRefBackupPathNameStr
    switch(s.eventCode)
		case 2: // Kill the window
			//Restore wave scaling here as ImageTransform works better with non-scaled waves
			//CopyScales/I $gATH_wRefBackupPathNameStr, $gATH_wRefPathNameStr
			SetWindow $s.winName, hook(iRBMyHook) = $""
			GetMarquee/K/Z
			hookresult = 1
			break
	endswitch
	return hookresult
End

static Function OverwriteAndCloseButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImageBackgroundRemovalFolder"))
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/SDFR=dfr gATH_wRefPathNameStr
	SVAR/SDFR=dfr gATH_wRefBackupPathNameStr
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			Duplicate/O $gATH_wRefBackupPathNameStr, $gATH_wRefPathNameStr
			SetWindow $B_Struct.win, hook(iRBMyHook) = $""
			KillWindow $(gATH_WindowNameStr+"#iBackgroundRemoval")
			hookresult =  1
		break
	endswitch
	return hookresult
End

static Function RemoveBackgroundButton(STRUCT WMButtonAction &B_Struct): ButtonControl
	variable hookresult = 0
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(GetUserData(B_Struct.win, "", "ATH_iImageBackgroundRemovalFolder"))
	SVAR/SDFR=dfr gATH_WindowNameStr
	SVAR/SDFR=dfr gATH_wRefPathNameStr
	NVAR PolyOrder = dfr:gATH_PolyOrder
	WAVE wRef = $gATH_wRefPathNameStr
	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			ATH_ImgOp#ImgRemoveBackground(wRef, order = PolyOrder)
			hookresult =  1
		break
	endswitch
	return hookresult
End
