#pragma rtGlobals    = 3
#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later
#pragma ModuleName  = ATH_TVIPS
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


static Function LoadTVIPStiff(string filepathStr, string waveNameStr)
	/// @param filepathStr string pathname. 
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave. 
		
	variable numRef
	string separatorchar = ":"
	string fileFilters = "TVIPS tiff File (*.tif):.tif;"
	fileFilters += "All Files:.*;"
	string message
    if (!strlen(filepathStr) && !strlen(waveNameStr)) 
		message = "Select .dat file. \nFilename will be wave's name. (overwrite)\n "
   		Open/F=fileFilters/M=message/D/R numref
   		filepathStr = S_filename
   		
   		if(!strlen(filepathStr)) // user cancel?
   			Abort
   		endif

   		Open/F=fileFilters/R numRef as filepathStr
		waveNameStr = ParseFilePath(3, filepathStr, separatorchar, 0, 0)
		
	elseif (strlen(filepathStr) && !strlen(waveNameStr))
		message = "Select .dat file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
		waveNameStr = ParseFilePath(3, filepathStr, separatorchar, 0, 0)
		
	elseif (!strlen(filepathStr) && strlen(waveNameStr))
		message = "Select .dat file. \n Destination wave will be overwritten\n "
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
	WAVE wRef = $StringFromList(0, S_waveNames)
	//Guess the dimenions...
	variable Nx = DimSize(wRef, 0)
	variable imgN = DimSize(wRef, 1)/Nx
	Redimension/E=1/N=(Nx,Nx,imgN) wRef
	return 0
End