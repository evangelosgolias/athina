#pragma rtGlobals    = 3
#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later
#pragma ModuleName  = ATH_LoadImg
#pragma version = 1.01
// ------------------------------------------------------- //
// Functions to import data acquired using EMMenu5.
// 
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


static Function Loadtiff(string filepathStr, string waveNameStr, [int displayImg])
	/// @param filepathStr string pathname. 
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave. 

	displayImg = ParamIsDefault(displayImg) ? 0: displayImg	
	
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
	
	
	ImageLoad/T=tiff/N=$waveNameStr/Q filepathStr
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

// Here you can find functions that could be place in ImgOp module

static Function/WAVE AverageStackedStacks(WAVE wRef, [int overwrite])
	// Read wave notes
	overwrite = ParamIsDefault(overwrite) ? 0 : overwrite
	string noteStr = note(wRef)
	string stackNames = StringByKey("STCK", noteStr, ":", "\n")
	string wavenameStr, newWaveNameStr, buffer
	string wlist = ""
	variable itemsN = ItemsInList(stackNames), nL, i
	int startL = 0
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	for(i = 0; i < itemsN; i++)
		sscanf StringFromList(i, stackNames), "%[^(](%d%[)]", wavenameStr, nL, buffer
		Duplicate/O/FREE/RMD=[][][startL, startL+nL-1] wRef, freeW
		buffer = "img_" + num2str(i)
		wlist += buffer+";"
		ATH_WaveOp#AverageImageStack(freeW, outWaveStr = buffer)
		startL += nL
	endfor
	if(overwrite)
		Concatenate/O/NP=2 wlist, wRef
		Note/K wRef, stackNames
		SetDataFolder saveDF
		return wRef
	else
		newWaveNameStr = CreateDataObjectName(saveDF, NameOfWave(wRef) + "_stck_avg", 1, 0, 1)
		Concatenate/O/NP=2 wlist, saveDF:$newWaveNameStr
		Note/K saveDF:$newWaveNameStr, stackNames
		SetDataFolder saveDF
		return saveDF:$newWaveNameStr
	endif
End

