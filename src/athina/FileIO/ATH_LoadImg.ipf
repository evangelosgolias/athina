#pragma rtGlobals    = 3
#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later
#pragma ModuleName  = ATH_LoadImg
#pragma version = 1.01
// ------------------------------------------------------- //
// Functions to import data acquired using EMMenu5.
// Functions to import P3B files (ALS)
//
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


static Function Loadtiff(string filepathStr, string waveNameStr, [int displayImg, int overwrite])
	/// @param filepathStr string pathname. 
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave. 

	displayImg = ParamIsDefault(displayImg) ? 0: displayImg	
	overwrite = ParamIsDefault(overwrite) ? 0: overwrite
	variable numRef
	string separatorchar = ":"
	string fileFilters = "TVIPS tiff File (*.tif):.tif;"
	fileFilters += "All Files:.*;"
	string message
    if (!strlen(filepathStr) && !strlen(waveNameStr)) 
		message = "Select .tif file. \nWavename will be filename without file extension.\n "
   		Open/F=fileFilters/M=message/D/R numref
   		filepathStr = S_filename
   		
   		if(!strlen(filepathStr)) // user cancel?
   			Abort
   		endif

   		Open/F=fileFilters/R numRef as filepathStr
		waveNameStr = ParseFilePath(3, filepathStr, separatorchar, 0, 0)
		
	elseif (strlen(filepathStr) && !strlen(waveNameStr))
		message = "Select .tif file. \nWavename will be filename without file extension.\n "
		Open/F=fileFilters/R numRef as filepathStr
		waveNameStr = ParseFilePath(3, filepathStr, separatorchar, 0, 0)
		
	elseif (!strlen(filepathStr) && strlen(waveNameStr))
		message = "Select .tif file. \nWavename will be filename without file extension.\n "
   		Open/F=fileFilters/M=message/D/R numref
   		filepathStr = S_filename
   		
   		if(!strlen(filepathStr)) // user cancel?
   			Abort
   		endif
   		
		message = "Select .tif file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
	else
		Abort "Path for datafile not specified (check ATH_TVIPS#LoadTVIPStiff)!"
	endif
	
	if(overwrite)
		ImageLoad/T=tiff/N=$waveNameStr/O/Q filepathStr	
	else
		ImageLoad/T=tiff/N=$waveNameStr/Q filepathStr
	endif
	Close numref
	WAVE wRef = $StringFromList(0, S_waveNames)
	//Guess the dimenions...
	variable Nx = DimSize(wRef, 0)
	variable imgN = DimSize(wRef, 1)/Nx
	if(imgN==1)
		Redimension/E=1/N=(Nx,Nx) wRef
	else
		Redimension/E=1/N=(Nx,Nx,imgN) wRef
	endif
	Note wRef, filepathStr
	if(displayImg)
		ATH_Display#NewImg(wRef)
	endif
	return 0
End

static Function Loadtiffs([int numImages, int displayImg, int stack3d])
	/// @param filepathStr string pathname.
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave.

	displayImg = ParamIsDefault(displayImg) ? 0: displayImg
	stack3d = ParamIsDefault(stack3d) ? 0: stack3d
	
	variable numRef, Nx, imgN
	string separatorchar = ":"
	string fileFilters = "TVIPS tiff File (*.tif):.tif;"
	fileFilters += "All Files:.*;"
	string loadFiles, filepath, filename, newWaveNameStr, basenameStr, noteStr
	string waveNameStr = ""
	string message = "Select .tif file. \nWavename will be filename without file extension.\n "
	Open/F=fileFilters/M=message/D/R/MULT=1 numref
	if(!strlen(S_fileName))
		return 1
	endif
	if(stack3d)
		DFREF saveDF = GetDataFolderDFR()
		SetDataFolder NewFreeDataFolder()
	endif
	loadFiles = SortList(S_fileName, "\r", 80)
	variable filesN = ItemsInList(loadFiles, "\r"), i
	numImages = (ParamIsDefault(numImages) || numImages> filesN) ? filesN : numImages
	noteStr = "Path: "+ ParseFilePath(1, StringFromList(0, loadFiles, "\r"), separatorchar, 1, 0) + "\n"
	noteStr += "STCK:"
	for(i = 0; i < numImages; i++)
		filepath = StringFromList(i, loadFiles, "\r")
		filename = ParseFilePath(3, filepath, separatorchar, 0, 0)
		if(stack3d)
			waveNameStr += filename + ";"
		else
			waveNameStr = filename
		endif
		ImageLoad/T=tiff/N=$filename/Q filepath
		WAVE wRef = $filename
		Nx = DimSize(wRef, 0)
		imgN = DimSize(wRef, 1)/Nx
		if(imgN==1)
			Redimension/E=1/N=(Nx,Nx) wRef
		else
			Redimension/E=1/N=(Nx,Nx,imgN) wRef
		endif
		noteStr += filename + "(" + num2str(imgN) +");"
	endfor
	
	if(stack3d)		
		basenameStr = ParseFilePath(0, filepath, separatorchar, 1, 1)
		newWaveNameStr = CreateDataObjectName(saveDF, basenameStr, 1, 0, 1)
		Concatenate/NP=2 waveNameStr, saveDF:$newWaveNameStr
		SetDataFolder saveDF
		WAVE w3d = saveDF:$newWaveNameStr
		CopyScales/P wRef, w3d
		Note w3d, noteStr
	endif	

	if(displayImg && stack3d)
		ATH_Display#NewImg(w3d)
	endif
	return 0
End


/// ---------------- Load PEEM3 P3B files ----------------///

static Structure long
	int32 length
EndStructure

static Structure dentry
	int32 dtype
	int32 dlen
EndStructure

static Function/S PEEM3File(string filepathStr, [variable mkdir])
	variable numRef
	string separatorchar = ":", waveNameStr, message
	string fileFilters = "P3B File (*.P3B):.P3B;"
	fileFilters += "All Files:.*;"
	string parentDirName = ParseFilePath(3, filepathStr, separatorchar, 0, 0)
	if (!strlen(filepathStr))
		message = "Select .dat file. \nFilename will be wave's name. (overwrite)\n "
		Open/F=fileFilters/M=message/D/R numref
		filepathStr = S_filename

		if(!strlen(filepathStr)) // user cancel?
			return ""
		endif

		Open/F=fileFilters/R numRef as filepathStr
		waveNameStr = ParseFilePath(3, filepathStr, separatorchar, 0, 0)
	elseif (strlen(filepathStr))
		message = "Select .dat file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
		waveNameStr = ParseFilePath(3, filepathStr, separatorchar, 0, 0)
	else
		print "Check ATH_LoadImage#PEEM3!"
	endif
	
	DFREF saveDF = GetDataFolderDFR()
	if(mkdir)
		NewDataFolder/S $waveNameStr
	else
		DFREF dfrF = NewFreeDataFolder()
		SetDataFolder dfrF
	endif

	FStatus numRef
	FSetPos numRef, 0

	string tagname, tagnameVal, tagsStrData = ""
	variable i, tagnum
	STRUCT long mylong
	STRUCT dentry myentry
	FBinRead numRef, mylong
	tagnum = mylong.length
	for(i=0;i<tagnum;i++)
		FBinRead numRef, mylong
		FReadLine/N=(mylong.length) numRef, tagname
		if(exists(tagname))
			tagname += "_"
		endif
		FBinRead numRef, myentry
		switch(myentry.dtype)
			case 1:
				Make/B/U/N=(myentry.dlen) $tagname
				FBinRead/F=1/U numRef,$tagname
				break
			case 2:
				Make/W/N=(myentry.dlen) $tagname
				FBinRead/F=2 numRef,$tagname
				break
			case 3:
				Make/I/N=(myentry.dlen) $tagname
				FBinRead/F=3 numRef,$tagname
				break
			case 4:
				Make/R/N=(myentry.dlen) $tagname
				FBinRead/F=4 numRef,$tagname
				break
			case 5:
				Make/D/N=(myentry.dlen) $tagname
				FBinRead/F=5 numRef,$tagname
				break
			case 7:
				FReadLine/N=(myentry.dlen) numRef, tagnameVal
				//tagsStrData += tagname +"="+tagnameVal+"\n"
				break
			case 12:
				Make/W/U/N=(myentry.dlen) $tagname
				FBinRead/F=2/U numRef,$tagname
				break
			case 13:
				Make/I/U/N=(myentry.dlen) $tagname
				FBinRead/F=3/U numRef,$tagname
				break
			case 14:
				Make/L/N=(myentry.dlen) $tagname
				FBinRead/F=6 numRef,$tagname
				break
			case 15:
				Make/L/U/N=(myentry.dlen) $tagname
				FBinRead/F=6/U numRef,$tagname
				break
			default:
				Make/B/N=(myentry.dlen) $tagname
				FBinRead/F=1 numRef,$tagname
				break
		endswitch

		if(myentry.dlen==1)
			WAVE/Z wRef = $tagname
			if(WaveExists(wRef))
				tagsStrData += RemoveEnding(tagname,"_") +"="+num2str(wRef[0])+"\n"
			else
				tagsStrData += RemoveEnding(tagname,"_") +"="+tagnameVal+"\n"
			endif
		endif
	endfor

	WAVE/Z DATA, DIMX, DIMY
	Redimension/N=(DIMX[0],DIMY[0]) DATA
	Note DATA, tagsStrData
	if(mkdir)
		// Here waveNameStr is the dir name, avoid conflict in h5px
		waveNameStr = "w_"+waveNameStr
		Duplicate/O DATA, saveDF:$("w_"+waveNameStr)
	else
		Duplicate/O DATA, saveDF:$waveNameStr
	endif
	SetDataFolder saveDF
	return waveNameStr
End

static Function PEEM3Files([int stack3d])
	stack3d = ParamIsDefault(stack3d) ? 0 : !!stack3d
	variable numRef, i
	string loadFiles, filepathStr, basenameStr, fileStr0

	string message = "Select .P3B files. \n"
	message += "Import overwrites waves with the same name."
	string fileFilters = "P3B File (*.P3B):.P3B;"
	fileFilters += "All Files:.*;"
	Open/F=fileFilters/MULT=1/M=message/D/R numref
	filepathStr = S_filename

	if(!strlen(filepathStr)) // user cancel?
		return NaN
	endif
	loadFiles = SortList(S_fileName, "\r", 80)
	variable nrloadFiles = ItemsInList(loadFiles, "\r")
	if(!nrloadFiles)
		return 1
	endif
	if(stack3d)
		DFREF saveDF = GetDataFolderDFR()
		SetDataFolder NewFreeDataFolder()
		//Get the first wave to have the scale
		fileStr0 = StringFromList(0,loadFiles, "\r")
		string wname0 = PEEM3File(fileStr0)
		basenameStr = ParseFilePath(0, fileStr0, ":", 1, 1)
		Rename $wname0, $"ImageToStack_0"
		for(i = 1; i < nrloadFiles; i++)
			wname0 = PEEM3File(StringFromList(i,loadFiles, "\r"))
			Rename $wname0, $("ImageToStack_"+num2str(i))
		endfor
		ImageTransform/NP=(nrloadFiles) stackImages $"ImageToStack_0"
		WAVE M_Stack
		string newWaveNameStr = CreateDataObjectName(saveDF, basenameStr, 1, 0, 1)
		Note M_Stack, ("Files loaded to " + newWaveNameStr + ":\n" + loadFiles)
		MoveWave M_Stack, saveDF:$newWaveNameStr
		SetDataFolder saveDF
	else
		for(i = 0; i < nrloadFiles; i++)
			PEEM3File(StringFromList(i,loadFiles, "\r"))
		endfor
	endif
End