#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Menu "Data" 
	Submenu "MATRIX (STM)"
		"Single File ...", /Q, STM_LoadMatrixSTMImages()
		"Files from Folder ...", /Q, STM_LoadMatrixSTMImagesFromFolder()
	End
End

/// 
/// Run the following python script. You need to install two packages
/// https://pypi.org/project/access2theMatrix/
/// https://github.com/t-onoz/igorwriter
//
// #!/Users/evangelosgolias/opt/anaconda3/bin/python3
// 
// # Documentation, see:
// # https://pypi.org/project/access2theMatrix/
// # https://github.com/t-onoz/igorwriter
// 
// # Caution: parameter file should be in the folder (big file when the experiment is created)
// # (e.g 20221118-101728_STM-P-Au-Ir111-W46-47_0001.mtrx)
// 
// # debug
// # Igor will provide the filename. Use repr() to cast to raw_string
// # filepath = repr(sys.argv[1]) 
// # debug
// # filepath= r"/Users/evangelosgolias/Dropbox/Work/Data Analysis/Phosphorus allotropes/2022-11-26/20221126-150655_STM-P-Au-Ir111-W46-47--9_1.I_mtrx"
// 
// import access2thematrix
// import numpy as np
// import sys, os, shutil
// from igorwriter import IgorWave
// 
// txtfile = '/Users/evangelosgolias/tmp/Wavemetrics/targetMatrixFile.txt'
// fid = open(txtfile)
// filepaths = fid.readlines()
// 
// # delete folder ... to delete the files
// bufferPath = '/Users/evangelosgolias/tmp/Wavemetrics/buffer'
// if os.path.exists(bufferPath) and os.path.isdir(bufferPath):
//     shutil.rmtree(bufferPath) #Remove folder with files
// # make the buffer folder
// os.mkdir('/Users/evangelosgolias/tmp/Wavemetrics/buffer')
// 
// mtrx_data = access2thematrix.MtrxData()
// 
// for filepath in filepaths:
//     filepath = filepath.strip()
//     filename = os.path.basename(filepath)
//     savename = "w" + filename.split("-")[0] + "_" + filename.split("-")[-1].split(".")[0]
//     # Matrix object
//     try:
//         traces, message = mtrx_data.open(filepath)
//         im_fwd, message = mtrx_data.select_image(traces[0])
//         im_bkd, message = mtrx_data.select_image(traces[1])
// 
//     except:
//         print("Filename %s load error"%filename)
//     else:
//         im_fwd_STM = np.fliplr(np.transpose(im_fwd.data))
//         im_bkd_STM = np.fliplr(np.transpose(im_bkd.data))        
//         waveF = IgorWave(im_fwd_STM, name=savename)
//         waveB = IgorWave(im_bkd_STM, name=savename+'B')
//         height = round(im_fwd.height/1e-09, 3) # length in nm
//         width = round(im_fwd.width/1e-09, 3) # width in nm
//         nrows, ncols = np.shape(im_fwd.data)
//         
//         height_dx = height / (nrows-1)
//         width_dy  = width / (ncols-1)
//         
//         waveF.set_dimscale('x', 0, height_dx, 'nm')  # set x scale information
//         waveF.set_dimscale('y', 0, width_dy, 'nm')  # set y scale information
//         waveF.save('/Users/evangelosgolias/tmp/Wavemetrics/buffer/'+savename+'.ibw')
//         waveB.set_dimscale('x', 0, height_dx, 'nm')  # set x scale information
//         waveB.set_dimscale('y', 0, width_dy, 'nm')  # set y scale information
//         waveB.save('/Users/evangelosgolias/tmp/Wavemetrics/buffer/'+savename+'_B.ibw')


static Function BeforeFileOpenHook(variable refNum, string fileNameStr, string pathNameStr, string fileTypeStr, string fileCreatorStr, variable fileKind)

    PathInfo $pathNameStr
    string fileToOpen = S_path + fileNameStr
    if((StringMatch(fileNameStr, "*.Z_mtrx") && fileKind == 0) || (StringMatch(fileNameStr, "*.I_mtrx") && fileKind == 0)) // Igor thinks that the .dat file is a General text (fileKind == 7)
        try	
        	STM_LoadMatrixSTMImagesFromFile(fileToOpen)
        	AbortOnRTE
        catch
        	print "Are you sure you are not trying to load a text file with .Z_mtrx or I_mtrx extention?"
        	Abort
        endtry
        return 1
    endif
    return 0
End

Function STM_LoadMatrixSTMImages()
	// Paths must be POSIX paths (using /).
	// Paths containing spaces or other nonstandard characters
	// must be single-quoted. See Apple Techical Note TN2065 for
	// more on shell scripting via AppleScript.
	
	string fileFilters = "Matrix File (*.mtrx):.Z_mtrx,.I_mtrx;"
	fileFilters += "All Files:.*;"
	string message, unixCmd, igorCmd
	variable numref
	
	message = "Select *.Z_mtrx or *.I_mtrx file."
   	Open/F=fileFilters/M=message/R numref
   	Close numref
   	
   	string filepath = ParseFilePath(5, S_filename, "/", 0, 0)
  //string filename = ParseFilePath(0, S_filename, ":", 1, 0)
   	
   	NewPath/Q/O targetMatrixFile, "Macintosh HD:Users:evangelosgolias:tmp:Wavemetrics:"
	DeleteFile/Z/P=targetMatrixFile "targetMatrixFile.txt"
	
   	Open/P=targetMatrixFile numref as "targetMatrixFile.txt" // Write filepath in Unix form
   	fprintf numref, "%s", filepath
   	Close numref
   	
	sprintf unixCmd, "/Users/evangelosgolias/Dropbox/Programming/python/STM/STM_ReadSTMMatrix.py"
	sprintf igorCmd, "do shell script \"%s\"", unixCmd

	ExecuteScriptText/UNQ igorCmd
	// We have two channels, forward and backward (TraceUp, TraceDown not present in most scans)
	NewPath/Q/O MatrixWavesPath, "Macintosh HD:Users:evangelosgolias:tmp:Wavemetrics:buffer"	
	LoadWave/Q/H/A/P=MatrixWavesPath IndexedFile(MatrixWavesPath,0,".ibw")
	// Here we will do level subtraction as in Gwyddion.
	// There the data are treated as data[i] := data[i] - (pa + pby*i + pbx*j)
	// when are pa, pby and pbx are fitted parameter for an image plane
	WAVE wRefF = $StringFromList(0,S_waveNames)
	variable nrows = DimSize(wRefF,0)
	variable ncols = DimSize(wRefF,1)
	Make/FREE/N=(nrows,ncols)/B/U maskWFree	= 1
	ImageRemoveBackground/O/R=maskWFree wRefF
	// Do not load backwards
	LoadWave/Q/H/A/P=MatrixWavesPath IndexedFile(MatrixWavesPath,1,".ibw")
	WAVE wRefB = $StringFromList(0,S_waveNames)
	ImageRemoveBackground/O/R=maskWFree wRefB
End

Function STM_LoadMatrixSTMImagesFromFile(string filepathStr)
	// Paths must be POSIX paths (using /).
	// Paths containing spaces or other nonstandard characters
	// must be single-quoted. See Apple Techical Note TN2065 for
	// more on shell scripting via AppleScript.
	
	string fileFilters = "Matrix File (*.mtrx):.Z_mtrx,.I_mtrx;"
	fileFilters += "All Files:.*;"
	string unixCmd, igorCmd
	variable numref
	
   	Open/F=fileFilters/R numref as filepathStr
   	Close numref
   	
   	string filepath = ParseFilePath(5, S_filename, "/", 0, 0)
  //string filename = ParseFilePath(0, S_filename, ":", 1, 0)
   	
   	NewPath/Q/O targetMatrixFile, "Macintosh HD:Users:evangelosgolias:tmp:Wavemetrics:"
	DeleteFile/Z/P=targetMatrixFile "targetMatrixFile.txt"
	
   	Open/P=targetMatrixFile numref as "targetMatrixFile.txt" // Write filepath in Unix form
   	fprintf numref, "%s", filepath
   	Close numref
   	
	sprintf unixCmd, "/Users/evangelosgolias/Dropbox/Programming/python/STM/STM_ReadSTMMatrix.py"
	sprintf igorCmd, "do shell script \"%s\"", unixCmd

	ExecuteScriptText/B/UNQ igorCmd
	// We have two channels, forward and backward (TraceUp, TraceDown not present in most scans)
   	NewPath/Q/O MatrixWavesPath, "Macintosh HD:Users:evangelosgolias:tmp:Wavemetrics:buffer"
	LoadWave/Q/A/H/P=MatrixWavesPath IndexedFile(MatrixWavesPath,0,".ibw")
	// Here we will do level subtraction as in Gwyddion.
	// There the data are treated as data[i] := data[i] - (pa + pby*i + pbx*j)
	// when are pa, pby and pbx are fitted parameter for an image plane
	WAVE wRefF = $StringFromList(0,S_waveNames)
	variable nrows = DimSize(wRefF,0)
	variable ncols = DimSize(wRefF,1)
	Make/FREE/N=(nrows,ncols)/B/U maskWFree	= 1
	ImageRemoveBackground/O/R=maskWFree wRefF
	// Do not load backwards
	LoadWave/Q/A/H/P=MatrixWavesPath IndexedFile(MatrixWavesPath,1,".ibw")
	WAVE wRefB = $StringFromList(0,S_waveNames)
	ImageRemoveBackground/O/R=maskWFree wRefB
End

Function STM_LoadMatrixSTMImagesFromFolder()

	NewPath/O/Q/M="Select a folder" MXP_MATRIXFilesPathTMP
	if (V_flag) // user cancel?
		Abort
	endif
	PathInfo MXP_MATRIXFilesPathTMP
	string path = S_Path
	string allFiles = IndexedFile(MXP_MATRIXFilesPathTMP, -1, ".Z_mtrx")
	
	string buffer, fname, allFilenames = ""
	variable nrFiles = ItemsInList(allFiles), numref, i
	// If no files are selected (e.g match pattern return "") warn user
	if (!nrFiles)
		//Abort "No files found!"
	endif
	
	// Change filenames 
	for(i = 0; i < nrFiles; i++)
		buffer = StringFromList(i, allFiles)
		fname = ParseFilePath(5, path+buffer, "/", 0, 0)
		allFilenames += fname + "\n"
	endfor	
	
   	NewPath/Q/O targetMatrixFile, "Macintosh HD:Users:evangelosgolias:tmp:Wavemetrics:"
	//DeleteFile/Z/P=targetMatrixFile "targetMatrixFile.txt"
   	Open/P=targetMatrixFile numref as "targetMatrixFile.txt" // Write allFilenames in Unix form
   	fprintf numref, "%s", allFilenames
   	Close numref
   	
   	string unixCmd, igorCmd
	sprintf unixCmd, "/Users/evangelosgolias/Dropbox/Programming/python/STM/STM_ReadSTMMatrix.py"
	sprintf igorCmd, "do shell script \"%s\"", unixCmd

	ExecuteScriptText/UNQ igorCmd
	// We have two channels, forward and backward (TraceUp, TraceDown not present in most scans)
	string ibwsList = IndexedFile(MatrixWavesPath, -1, ".ibw"), wnameStr
	variable nrIBWs = ItemsInList(ibwsList), nrows, ncols
	NewPath/Q/O MatrixWavesPath, "Macintosh HD:Users:evangelosgolias:tmp:Wavemetrics:buffer"
	for(i = 0; i < nrIBWs; i++)
		buffer = StringFromList(i, ibwsList)
		LoadWave/Q/A/H/P=MatrixWavesPath buffer
		wnameStr = RemoveEnding(S_waveNames, ";")
		WAVE wRef = $wnameStr
		nrows = DimSize(wRef,0)
		ncols = DimSize(wRef,1)
		// Here we will do level subtraction as in Gwyddion.
		// There the data are treated as data[i] := data[i] - (pa + pby*i + pbx*j)
		// when are pa, pby and pbx are fitted parameter for an image plane	
		
		//Make/O/FREE/N=(nrows,ncols)/B/U maskWFree = 1
		//ImageRemoveBackground/O/R=maskWFree wRef
	endfor
	return 0
End