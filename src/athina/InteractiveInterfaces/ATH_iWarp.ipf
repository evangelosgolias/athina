#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_iWarp
#pragma version = 2.4

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

	WAVE wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	//Check if you have already created the panel
	string pnlNameStr = winNameStr + "#iWarp"
	if(WinType(pnlNameStr) == 7)
		return 1
	endif

	//Duplicate the wave for backup
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveImgWarping:" + winNameStr) // Root folder here
	string backupNameStr = NameOfWave(wRef) + "_undo"
	Duplicate/O wRef, dfr:$backupNameStr
	ModifyImage/W=$winNameStr $imgNameTopGraphStr ctabAutoscale=3
	// Create the global variables for panel
	string/G dfr:gATH_imgNameTopWindowStr = imgNameTopGraphStr
	string/G dfr:gATH_WindowNameStr = winNameStr
	string/G dfr:gATH_wPathname = GetWavesDataFolder(wRef, 2)
	string/G dfr:gATH_wPath = GetWavesDataFolder(wRef, 1)
	string/G dfr:gATH_wNameStr = NameOfWave(wRef)
	string/G dfr:gATH_wBackupPathNameStr = GetWavesDataFolder(dfr:$backupNameStr, 2)
	string/G dfr:gATH_wBackupNameStr = PossiblyQuoteName(backupNameStr)
	variable/G dfr:gATH_wnlayers = DimSize(wRef, 2) // 0 for 2D wave
	variable/G dfr:gATH_WarpInterpolation = 0	
	Make/O/N=3 dfr:imgW, dfr:imgW	
	DFREF dfrS = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveImgWarping:ReferencePoints")	
	Make/O/N=3 dfrS:refWx, dfrS:refWy
	variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
	NewPanel/K=1/EXT=0/N=iWarp/W=(0,0,165*pntConv,490*pntConv)/HOST=$winNameStr
	SetDrawLayer UserBack
	SetDrawEnv/W=iWarp fsize= 15*pntConv,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=iWarp 33*pntConv,18*pntConv,"Image Warping"
	//
	SetDrawEnv/W=iWarp fsize= 14*pntConv,fstyle= 1,textrgb= (1,39321,19939)
	DrawText/W=iWarp 30*pntConv,50*pntConv,"Reference Image"	
	PopupMenu RefGraph title="",pos={50,60},value=#"WinList(\"*\",\";\",\"WIN:1\")",fSize=12,proc=ATH_iWarp#PopupMenuAction,win=$pnlNameStr

	// Save Reference
	DFREF dfrS = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:InteractiveImgWarping:ReferencePoints")	
	NVAR/SDFR=dfrS/Z gATH_SavedRefGrig
	if(NVAR_Exists(gATH_SavedRefGrig))
//		Button gATH_SavedRefGrig,disable = 0,fColor=(2,39321,1),win=$pnlNameStr
	else
//		Button gATH_SavedRefGrig,disable = 2,fColor=(65535,16385,16385),win=$pnlNameStr
//		Button gATH_SavedRefGrig,disable = 2,win=$pnlNameStr		
	endif

End

Function PopupMenuAction(STRUCT WMPopupAction &PU_Struct) : PopupMenuControl

	if(PU_Struct.eventCode != 2)
		return 0
	endif
	print PU_Struct.popNum
	
End