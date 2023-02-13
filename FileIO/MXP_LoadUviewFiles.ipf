#pragma rtGlobals    = 3
#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma rtFunctionErrors=1 // DEGUB. Remove on release
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later

// ------------------------------------------------------- //
// Functions to import binary .dat & .dav files created by Elmitec's Uview Software at
// the MAXPEEM beamline at MAX IV.
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


Structure LONGLONG
	uint32 LONG[2]
EndStructure


Structure UKFileHeader // 104 bytes
	char id[20]  // 1 byte
	int16 size   // 2 bytes
	int16 version
	int16 BitsPerPixel
	int16 CameraBitsPerPixel
	int16 MCPDiameterInPixels
	uchar hBinning, vBinning // 1 byte
	STRUCT LONGLONG starttime			// 8 bytes
	int16 ImageWidth, ImageHeight
	int16 NrImages
	int16 attachedRecipeSize
	char spare[56]
EndStructure

Structure UKImageHeader // 288 bytes
	int16 size
	int16 version
	int16 ColorScaleLow,ColorScaleHigh
	STRUCT LONGLONG imagetime
	int16 MaskXshift, MaskYshift
	uint16 RotateMask
	int16 attachedMarkupSize
	int16 spin
	int16 LEEMdataVersion
	uchar LEEMdata[240]
	uchar applied_processing
	uchar gray_adjust_zone
	uint16 backgroundvalue
	uchar desired_rendering
	uchar desired_rotation_fraction
	int16 rendering_argShort
	float rendering_argFloat
	int16 desired_rotation
	int16 rotation_offset
	int16 spare[2] // to get a size divisible by 8
EndStructure

//Structure UKImageMarkupData
//		uchar MarkupData[128]
//EndStructure


/// What to do if you drag and drop or a .dat file. Problem: Igor thinks .dat files are General text
/// files and tries to read them using Igor routines. TODO: Fix it in the future if possible.

static Function BeforeFileOpenHook(variable refNum, string fileNameStr, string pathNameStr, string fileTypeStr, string fileCreatorStr, variable fileKind)

    PathInfo $pathNameStr
    string fileToOpen = S_path + fileNameStr
    if(StringMatch(fileNameStr, "*.dat") && fileKind == 7) // Igor thinks that the .dat file is a General text (fileKind == 7)
        try	
        	MXP_LoadSingleDATFile(fileToOpen, "", autoscale = 1)
        	AbortOnRTE
        catch
        	print "Are you sure you are not trying to load a text file with .dat extention?"
        	Abort
        endtry
        return 1
    endif
    if(StringMatch(fileNameStr, "*.dav") && fileKind == 0) // fileKind == 0, unknown
    	DoAlert/T="Dropped a .dav file in Igror" 1, "Do you want to load the .dav file in a stack?"
        try
        if(V_flag == 1)
        		MXP_LoadSingleDAVFile(fileToOpen, "", skipmetadata = 1, autoscale = 1, stack3d = 1)
        else
        		MXP_LoadSingleDAVFile(fileToOpen, "", autoscale = 1)
        endif
        	AbortOnRTE
        catch
        	print "Are you sure you are not trying to load a text file with .dav extention?"
        	Abort
        endtry
        return 1
    endif
    return 0
End


Function/WAVE MXP_WAVELoadSingleDATFile(string filepathStr, string waveNameStr, [int skipmetadata, int waveDataType, int autoScale])
	///< Function to load a single Elmitec binary .dat file.
	/// @param filepathStr string filename (including) pathname. 
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave. 
	/// If "" the wave name is the filename without the path and extention.
	/// @param skipmetadata int optional and if set to a non-zero value it skips metadata.
	/// @param waveDataType int optional and sets the Wavetype of the loaded wave to single 
	/// @param autoScale int optional scales the imported waves if not 0
	/// /S of double (= 1) or /D precision (= 2). Default is (=0) uint 16-bit
	/// @return wave reference
	
	skipmetadata = ParamIsDefault(skipmetadata) ? 0: skipmetadata // if set do not read metadata
	waveDataType = ParamIsDefault(waveDataType) ? 0: waveDataType
	autoScale = ParamIsDefault(autoScale) ? 0: autoScale

	variable numRef
	string separatorchar = ":"
	string fileFilters = "dat File (*.dat):.dat;"
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
		
	elseif (strlen(filepathStr) && strlen(waveNameStr))
		message = "Select .dat file. \n Destination wave will be overwritten.\n "
		Open/F=fileFilters/R numRef as filepathStr
		
	elseif (!strlen(filepathStr) && strlen(waveNameStr))
		message = "Select .dat file. \n Destination wave will be overwritten\n "
   		Open/F=fileFilters/M=message/D/R numref
   		filepathStr = S_filename
   		
   		if(!strlen(filepathStr)) // user cancel?
   			Abort
   		endif
   		
		message = "Select .dat file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
	else
		Abort "Path for datafile not specified (check MXP_WAVELoadSingleDATFile)!"
	endif
	
	STRUCT UKFileHeader MXPFileHeader
	STRUCT UKImageHeader MXPImageHeader
	
	FSetPos numRef, 0
	FBinRead numRef, MXPFileHeader

	// FileHeader: 104 bytes or 104 + 128 bytes if attachedRecipeSize>0
	if(MXPFileHeader.attachedRecipeSize > 0)
		MXPFileHeader.size += 128
	endif
	
	variable ImageHeaderSize, timestamp
			
	FSetPos numRef, MXPFileHeader.size
	FBinRead numRef, MXPImageHeader

	//Elmitec files can have additional markup blocks hence the offsets of 128 bytes
	
	if(MXPImageHeader.attachedMarkupSize == 0)
		//no markups
		ImageHeaderSize = 288 // UKImageHeader -> 288 bytes
	else
		//Markup blocks multiple of 128 bytes after image header
		ImageHeaderSize = 288 + 128 * ((trunc(MXPImageHeader.attachedMarkupSize/128))+1)
	endif
	
	//Now read the image [unsigned int 16-bit, /F=2 2 bytes per pixel]
	Make/W/U/O/N=(MXPFileHeader.ImageWidth, MXPFileHeader.ImageHeight) $waveNameStr /WAVE=datWave
	variable ImageDataStart = MXPFileHeader.size + ImageHeaderSize + MXPImageHeader.LEEMdataVersion
	FSetPos numRef, ImageDataStart
	FBinRead/F=2 numRef, datWave
	ImageTransform flipCols datWave // flip the y-axis
	Close numRef
	
	if(!skipmetadata)
		timestamp = MXPImageHeader.imagetime.LONG[0]+2^32 * MXPImageHeader.imagetime.LONG[1]
		timestamp *= 1e-7 // t_i converted from 100ns to s
		timestamp -= 9561628800 // t_i converted from Windows Filetime format (01/01/1601) to Mac Epoch format (01/01/1970)
		variable MetadataStart = MXPFileHeader.size + ImageHeaderSize
		string mdatastr = filepathStr + "\n"
		mdatastr += "Timestamp: " + Secs2Date(timestamp, -2) + " " + Secs2Time(timestamp, 3) + "\n"
		mdatastr += MXP_StrGetBasicMetadataInfoFromDAT(filepathStr, MetadataStart, ImageDataStart)
	endif
	
	// Add image markups if any
	if(MXPImageHeader.attachedMarkupSize)
		mdatastr += MXP_StrGetImageMarkups(filepathStr)
	endif
	if(strlen(mdatastr)) // Added to allow MXP_LoadDATFilesFromFolder function to skip Note/K without error
		Note/K datWave, mdatastr
	endif
	
	// Convert to SP or DP 	
	if(waveDataType == 1)
		Redimension/S datWave
	endif
	
	if(waveDataType == 2)
		Redimension/D datWave
	endif
	
	if(autoScale && !skipmetadata)
		variable imgScaleVar = NumberByKey("FOV(µm)", mdatastr, ":", "\n")
		SetScale/I x, 0, imgScaleVar, datWave
		SetScale/I y, 0, imgScaleVar, datWave
	endif
	return datwave
End

Function MXP_LoadSingleDATFile(string filepathStr, string waveNameStr, [int skipmetadata, int waveDataType, int autoScale])
	///< Function to load a single Elmitec binary .dat file.
	/// @param filepathStr string filename (including) pathname. 
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave. 
	/// If "" the wave name is the filename without the path and extention.
	/// @param skipmetadata is optional and if set to a non-zero value it skips metadata.
	/// @param waveDataType is optional and sets the Wavetype of the loaded wave to single 
	/// @param autoScale int optional scales the imported waves if not 0
	/// /S of double (= 1) or /D precision (= 2). Default is (=0) uint 16-bit
	
	skipmetadata = ParamIsDefault(skipmetadata) ? 0: skipmetadata // if set do not read metadata
	waveDataType = ParamIsDefault(waveDataType) ? 0: waveDataType
	
	variable numRef
	string separatorchar = ":"
	string fileFilters = "dat File (*.dat):.dat;"
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
   		
		message = "Select .dat file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
	else
		Abort "Path for datafile not specified (check MXP_LoadSingleDATFile)!"
	endif
	
	STRUCT UKFileHeader MXPFileHeader
	STRUCT UKImageHeader MXPImageHeader
	
	FSetPos numRef, 0
	FBinRead numRef, MXPFileHeader

	// FileHeader: 104 bytes or 104 + 128 bytes if attachedRecipeSize>0
	if(MXPFileHeader.attachedRecipeSize > 0)
		MXPFileHeader.size += 128
	endif
	
	variable ImageHeaderSize, timestamp
			
	FSetPos numRef, MXPFileHeader.size
	FBinRead numRef, MXPImageHeader

	//Elmitec files can have additional markup blocks hence the offsets of 128 bytes
	
	if(MXPImageHeader.attachedMarkupSize == 0)
		//no markups
		ImageHeaderSize = 288 // UKImageHeader -> 288 bytes
	else
		//Markup blocks multiple of 128 bytes after image header
		ImageHeaderSize = 288 + 128 * ((trunc(MXPImageHeader.attachedMarkupSize/128))+1)
	endif
	
	//Now read the image [unsigned int 16-bit, /F=2 2 bytes per pixel]
	Make/W/U/O/N=(MXPFileHeader.ImageWidth, MXPFileHeader.ImageHeight) $waveNameStr /WAVE=datWave
	variable ImageDataStart = MXPFileHeader.size + ImageHeaderSize + MXPImageHeader.LEEMdataVersion
	FSetPos numRef, ImageDataStart
	FBinRead/F=2 numRef, datWave
	ImageTransform flipCols datWave // flip the y-axis
	Close numRef // Close the file
	
	if(!skipmetadata)
		timestamp = MXPImageHeader.imagetime.LONG[0]+2^32 * MXPImageHeader.imagetime.LONG[1]
		timestamp *= 1e-7 // t_i converted from 100ns to s
		timestamp -= 9561628800 // t_i converted from Windows Filetime format (01/01/1601) to Mac Epoch format (01/01/1970)
		variable MetadataStart = MXPFileHeader.size + ImageHeaderSize
		string mdatastr = filepathStr + "\n"
		mdatastr += "Timestamp: " + Secs2Date(timestamp, -2) + " " + Secs2Time(timestamp, 3) + "\n"
		mdatastr += MXP_StrGetBasicMetadataInfoFromDAT(filepathStr, MetadataStart, ImageDataStart)
	endif

	// Add image markups if any
	if(MXPImageHeader.attachedMarkupSize)
		mdatastr += MXP_StrGetImageMarkups(filepathStr)
	endif
	if(strlen(mdatastr)) // Added to allow MXP_LoadDATFilesFromFolder function to skip Note/K without error
		Note/K datWave, mdatastr
	endif

	// Convert to SP or DP 
	if(waveDataType == 1)
		Redimension/S datWave
	endif
	
	if(waveDataType == 2)
		Redimension/D datWave
	endif

	if(autoScale && !skipmetadata)
		variable imgScaleVar = NumberByKey("FOV(µm)", mdatastr, ":", "\n")
		SetScale/I x, 0, imgScaleVar, datWave
		SetScale/I y, 0, imgScaleVar, datWave
	endif
	return 0
End

Function MXP_LoadSingleDAVFile(string filepathStr, string waveNameStr, [int skipmetadata, int waveDataType, int autoScale, int stack3d])
	///< Function to load a single Elmitec binary .dav file. dav files comprise of many dat entries in sequence.
	/// @param filepathStr string filename (including) pathname. 
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave. 
	/// If "" the wave name is the filename without the path and extention.
	/// @param skipmetadata is optional and if set to a non-zero value it skips metadata.
	/// @param waveDataType is optional and sets the Wavetype of the loaded wave to single 
	/// @param autoScale int optional scales the imported waves if not 0
	/// @param stack3d int optional Stack images in a 3d wave
	/// /S of double (= 1) or /D precision (= 2). Default is (=0) uint 16-bit
	
	skipmetadata = ParamIsDefault(skipmetadata) ? 0: skipmetadata // if set do not read metadata
	waveDataType = ParamIsDefault(waveDataType) ? 0: waveDataType
	autoScale = ParamIsDefault(autoScale) ? 0: autoScale
	stack3d = ParamIsDefault(stack3d) ? 0: stack3d

	variable numRef
	string separatorchar = ":"
	string fileFilters = "dav File (*.dav):.dav;"
	fileFilters += "All Files:.*;"
	string message
	string mdatastr
    if (!strlen(filepathStr) && !strlen(waveNameStr)) 
		message = "Select .dav file. \nFilename will be wave's name. (overwrite)\n "
   		Open/F=fileFilters/M=message/D/R numref
   		filepathStr = S_filename
   		
   		if(!strlen(filepathStr)) // user cancel?
   			Abort
   		endif

   		Open/F=fileFilters/R numRef as filepathStr
		waveNameStr = ParseFilePath(3, filepathStr, separatorchar, 0, 0)
		
	elseif (strlen(filepathStr) && !strlen(waveNameStr))
		message = "Select .dav file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
		waveNameStr = ParseFilePath(3, filepathStr, separatorchar, 0, 0)
		
	elseif (!strlen(filepathStr) && strlen(waveNameStr))
		message = "Select .dav file. \n Destination wave will be overwritten\n "
   		Open/F=fileFilters/M=message/D/R numref
   		filepathStr = S_filename
   		
   		if(!strlen(filepathStr)) // user cancel?
   			Abort
   		endif
   		
		message = "Select .dav file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
	else
		Abort "Path for datafile not specified (check MXP_ImportImageFromSingleDatFile)!"
	endif
	
	STRUCT UKFileHeader MXPFileHeader
	STRUCT UKImageHeader MXPImageHeader
	
	FSetPos numRef, 0
	FStatus numRef
	variable totalBytesInDAVFile = V_logEOF
	FBinRead numRef, MXPFileHeader //Read fileheader - only once and always 104 bytes for .dav
	
	variable ImageHeaderSize, timestamp
	
	variable cnt = 0 
	variable singlePassSwitch = 1 
	variable MetadataStart
	variable fovScale
	variable readMetadataOnce = 0 // When you skip metadata but you need to scale the 3d wave
	if(stack3d)
		readMetadataOnce = 1
	endif
	// while loop
	do
		mdatastr = "" // Reset metadata string
		FSetPos numRef, MXPFileHeader.size + cnt * (ImageHeaderSize + MXPImageHeader.LEEMdataVersion + 2 * MXPFileHeader.ImageWidth * MXPFileHeader.ImageHeight)
		FBinRead numRef, MXPImageHeader
	
		if(MXPImageHeader.attachedMarkupSize == 0)
			//no markups
			ImageHeaderSize = 288 // UKImageHeader -> 288 bytes
		else
			//Markup blocks multiple of 128 bytes after image header
			ImageHeaderSize = 288 + 128 * ((trunc(MXPImageHeader.attachedMarkupSize/128))+1)
		endif
	
		//Now read the image [unsigned int 16-bit, /F=2 2 bytes per pixel]
		if(stack3d)
			Make/W/U/O/FREE/N=(MXPFileHeader.ImageWidth, MXPFileHeader.ImageHeight) datWave
		else
			Make/W/U/O/N=(MXPFileHeader.ImageWidth, MXPFileHeader.ImageHeight) $(waveNameStr + "_" + num2str(cnt)) /WAVE=datWave
		endif
		variable ImageDataStart = MXPFileHeader.size + ImageHeaderSize + MXPImageHeader.LEEMdataVersion 
		ImageDataStart +=  cnt * (ImageHeaderSize + MXPImageHeader.LEEMdataVersion + 2 * MXPFileHeader.ImageWidth * MXPFileHeader.ImageHeight)
		FSetPos numRef, ImageDataStart
		FBinRead/F=2 numRef, datWave
		ImageTransform flipCols datWave // flip the y-axis
		
		if(!skipmetadata)
			timestamp = MXPImageHeader.imagetime.LONG[0]+2^32 * MXPImageHeader.imagetime.LONG[1]
			timestamp *= 1e-7 // t_i converted from 100ns to s
			timestamp -= 9561628800 // t_i converted from Windows Filetime format (01/01/1601) to Mac Epoch format (01/01/1970)
			MetadataStart = MXPFileHeader.size + ImageHeaderSize + cnt * (ImageHeaderSize + MXPImageHeader.LEEMdataVersion + 2 * MXPFileHeader.ImageWidth * MXPFileHeader.ImageHeight)
			mdatastr += filepathStr + "\n"
			mdatastr += "Timestamp: " + Secs2Date(timestamp, -2) + " " + Secs2Time(timestamp, 3) + "\n"
			mdatastr += MXP_StrGetBasicMetadataInfoFromDAT(filepathStr, MetadataStart, ImageDataStart)
			if(autoscale)
				fovScale = NumberByKey("FOV(µm)", mdatastr,":", "\n")
				SetScale/I x, 0, fovScale, datWave
				SetScale/I y, 0, fovScale, datWave
			endif
		endif
		// when you stack, skip metadata but scale the x, y dimensions of the 3d wave. 
		// if(stack3d) branch at the end.
		// Right before the start of the do...while loop readMetadataOnce = 1
		if(skipmetadata && autoScale && readMetadataOnce) 
			MetadataStart = MXPFileHeader.size + ImageHeaderSize + cnt * (ImageHeaderSize + MXPImageHeader.LEEMdataVersion + 2 * MXPFileHeader.ImageWidth * MXPFileHeader.ImageHeight)
			mdatastr += MXP_StrGetBasicMetadataInfoFromDAT(filepathStr, MetadataStart, ImageDataStart)
			fovScale = NumberByKey("FOV(µm)", mdatastr,":", "\n")
			readMetadataOnce = 0
		endif
		// Add image markups if any
		if(MXPImageHeader.attachedMarkupSize)
			mdatastr += MXP_StrGetImageMarkups(filepathStr)
		endif
		if(strlen(mdatastr)) // Added to allow MXP_LoadDATFilesFromFolder function to skip Note/K without error
			Note/K datWave, mdatastr
		endif

		// Convert to SP or DP 
		if(waveDataType == 1)
			Redimension/S datWave
		endif
	
		if(waveDataType == 2)
			Redimension/D datWave
		endif

		if(stack3d) //TODO: Use ImageTransform here to make import faster
			if(stack3d && singlePassSwitch) // We want stacking and yet the 3d wave is not created
				variable nlayers = (totalBytesInDAVFile - 104)/(ImageHeaderSize + MXPImageHeader.LEEMdataVersion + 2 * MXPFileHeader.ImageWidth * MXPFileHeader.ImageHeight)
				Make/W/U/O/N=(MXPFileHeader.ImageWidth, MXPFileHeader.ImageHeight, nlayers) $(waveNameStr) /WAVE = stack3DWave
				singlePassSwitch = 0
			endif
			stack3DWave[][][cnt] = datWave[p][q]
		endif
		WAVEClear datWave
		cnt += 1
		FGetPos numRef
		if(totalBytesInDAVFile == V_filePos)
			break
		endif
	while(1)
	
	if(autoscale && stack3d) // Scale the 3d wave if you opt to
		SetScale/I x, 0, fovScale, stack3DWave
		SetScale/I y, 0, fovScale, stack3DWave
	endif
	// end of while loop
	Close numRef // Close the file
	return 0
End

Function/S MXP_StrGetBasicMetadataInfoFromDAT(string datafile, variable MetadataStartPos, variable MetadataEndPos)
	// Read important metadata from a .dat file. Most metadata are stored in the form
	// tag (units): values, so it's easy to parse using the StringByKey function.
	// The function is used by MXP_ImportImageFromSingleDatFile(string datafile, string FileNameStr)
	// to add the most important metadata as note to the imported image.

	variable numRef
   	Open/R numRef as datafile
   	FSetPos numRef, MetadataStartPos
	// String for all metadata
	string MXPMetaDataStr = ""


	variable buffer
	string strbuffer
	
	do
		FBinRead/F=1 numRef, buffer 
		/// We read numbers as signed. Following the FileFormats 2017.pdf
		/// from Elmitec, the highest bit of a byte in the metadata section
		/// is used to display or not a specific tag on an image. All metadata
		/// though are recorded. When you choose not to diplay a tag the highest bit
		/// is set. For example in MAXPEEM by default we choose to display the start 
		/// voltage, therefore its value is 0x26 (38 decimal). This means that the value
		/// read here is -90 decimal, which then changed to 38 but adding 2^8. If we opt
		/// not to display the value then the tag is 38.
		
		if (buffer < 0)
			buffer += 128
		endif
		
		// LEEM modules from 0..99 have a fixed format
		// address-name(str)-unit(ASCIII digit)-0-value(float)
		// unit: ";V;mA;A;ºC;K;mV;pA;nA;µA"
		// In ReadBasicMetadataBlock we will get only
		// Start Voltage, Sample Temp. and Objective
		
		// Use StringByKey to extract the metadata
		if (buffer >= 0 && buffer <= 99)
			FReadLine/T=(num2char(0)) numRef, strbuffer			
			 
			if(buffer == 38) // or stringmatch(strbuffer, "*Start Voltage1*")
				FBinRead/F=4 numRef, buffer
				MXPMetaDataStr += "STV(V):" + num2str(buffer) + "\n"
			elseif(buffer == 11) // or stringmatch(strbuffer, "*Objective2*")
				FBinRead/F=4 numRef, buffer
				MXPMetaDataStr += "Objective(mA):" + num2str(buffer) + "\n"
			elseif(buffer == 39) // or stringmatch(strbuffer, "*Sample Temp.*")
				FBinRead/F=4 numRef, buffer
				MXPMetaDataStr += "SampleTemp(ºC):" + num2str(buffer) + "\n"
			else
				FBinRead/F=4 numRef, buffer // drop the rest
			endif
		elseif(buffer == 100)
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "X(mm):" + num2str(buffer) + "\n"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "Y(mm):" + num2str(buffer) + "\n"
		// added to be in line with Uwe's suggestions. Does not have any effect
		elseif(buffer == 101)
			FReadLine /T=(num2char(0)) numRef, strbuffer // old entry, drop
		elseif(buffer == 102)
			FBinRead/F=4 numRef, buffer // old entry, drop
		elseif(buffer == 103)
			FBinRead/F=4 numRef, buffer // old entry, drop
		//	Remove 101, 102, 103 cases if you see abnormal behaviour		
		elseif(buffer == 104)
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "CamExp(s):" + num2str(buffer) + "\n"
			
			FBinRead/U/F=1 numRef, buffer
			if(buffer == 0)
				MXPMetaDataStr += "CamMode: No averaging\n"
			elseif(buffer == 255)
				MXPMetaDataStr += "CamMode: Sliding average\n"
			else
				MXPMetaDataStr += "Average images: " + num2str(buffer) + "\n"
			endif				
		elseif(buffer == 105)
			FReadLine/T=(num2char(0)) numRef, strbuffer // drop title
		elseif(buffer == 106) // C1G1 - MCH
			FReadLine/T=(num2char(0)) numRef, strbuffer 
			MXPMetaDataStr += "MCH" // MAXPEEM naming conversion
			FReadLine/T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "(" + RemoveEnding(strbuffer) + "):" // Remove trailing 0x00
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 107) // C1G2 - COL
			FReadLine/T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "COL" // MAXPEEM naming conversion
			FReadLine/T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "(" + RemoveEnding(strbuffer) + "):"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 108) // C2G1 not used at MAXPEEM
			FReadLine/T=(num2char(0)) numRef, strbuffer 
			//MXPMetaDataStr += "MCH" // MAXPEEM naming conversion
			FReadLine/T=(num2char(0)) numRef, strbuffer
			//MXPMetaDataStr += "(" + RemoveEnding(strbuffer) + "):"
			FBinRead/F=4 numRef, buffer
			//MXPMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 109) // C2G1 - PCH
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "PCH" // MAXPEEM naming conversion
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "(" + RemoveEnding(strbuffer) + "):"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 110)
			FReadLine /T=(num2char(0))/ENCG={3,3,1} numRef, strbuffer // TODO: Fix the trailing tab and zeros!
			sscanf strbuffer, "%dµm", buffer
			MXPMetaDataStr += "FOV(µm):" + num2str(buffer) + "\n"
			FBinRead/F=4 numRef, buffer // drop FOV calculation factor
		elseif(buffer == 111) //drop
			FBinRead/F=4 numRef, buffer // phi
			FBinRead/F=4 numRef, buffer // theta
		elseif(buffer == 112) //drop
			FBinRead/F=4 numRef, buffer // spin
		elseif(buffer == 113)
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "FOVRot(deg):" + num2str(buffer) + "\n"
		elseif(buffer == 114) //drop
			FBinRead/F=4 numRef, buffer // Mirror state
		elseif(buffer == 115) //drop
			FBinRead/F=4 numRef, buffer // MCP screen voltage in kV
		elseif(buffer == 116) //drop
			FBinRead/F=4 numRef, buffer // MCP channelplate voltage in KV
		endif		
	
		FGetPos numRef
	while (V_filePos < MetadataEndPos)
	Close numRef
	return MXPMetaDataStr // ConvertTextEncoding(MXPMetaDataStr, 1, 1, 3, 2)
End

Function/S MXP_StrGetAllMetadataInfoFromDAT(string datafile, variable MetadataStartPos, variable MetadataEndPos)
	// Read all metadata from a .dat file. Most metadata are stored in the form
	// tag (units): values, so it's easy to parse using the StringByKey function.
	// The function is used by MXP_ImportImageFromSingleDatFile(string datafile, string FileNameStr)
	// to add the most important metadata as note to the imported image.

	variable numRef
   	Open/R numRef as datafile
   	FSetPos numRef, MetadataStartPos
	// String for all metadata
	string MXPMetaDataStr = ""


	variable buffer 
	string strBuffer, nametag, units
	
	do
		FBinRead/F=1 numRef, buffer 
		// We read numbers as signed. Following the FileFormats 2017.pdf
		// from Elmitec, the highest bit of a byte in the metadata section
		// is used to display or not a specific tag on the image. All metadata
		// though are recorded.
		
		if (buffer < 0)
			buffer += 128
		endif
		
		// LEEM modules from 0..99 have a fixed format
		// address-name(str)-unit(ASCII digit)-0-value(float)
		// unit: ";V;mA;A;ºC;K;mV;pA;nA;µA"
		// In ReadBasicMetadataBlock we will get only
		// Start Voltage, Sample Temp. and Objective
		// Use StringByKey to extract the metadata
		
		if (buffer >= 0 && buffer <= 99)
			FReadLine/T=(num2char(0)) numRef, strBuffer
			SplitString/E="(.+)(\d)\u0000" strBuffer, nametag, units
			MXPMetaDataStr += nametag
			strswitch(units)
				case "0":
					MXPMetaDataStr += "None" 
					break
				case "1":
					MXPMetaDataStr += "(V)" 
					break
				case "2":
					MXPMetaDataStr += "(mA)" 
					break
				case "3":
					MXPMetaDataStr += "(A)" 
					break
				case "4":
					MXPMetaDataStr += "(ºC)" 
					break
				case "5":
					MXPMetaDataStr += "(K)" 
					break
				case "6":
					MXPMetaDataStr += "(mV)" 
					break
				case "7":
					MXPMetaDataStr += "(pA)" 
					break
				case "8":
					MXPMetaDataStr += "(nA)" 
					break
				case "9":
					MXPMetaDataStr += "(µA)" 
					break
			endswitch
			FBinRead/F=4 numRef, buffer
			if(strlen(nametag)) // there is a zero nametag! Exclude it
				MXPMetaDataStr += ":" + num2str(buffer) + ";"
			endif
		elseif(buffer == 100)
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "X(mm):" + num2str(buffer) + ";"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "Y(mm):" + num2str(buffer) + ";"
		// added to be in line with Uwe's suggestions. Does not have any effect
		elseif(buffer == 101)
			FReadLine /T=(num2char(0)) numRef, strbuffer
		elseif(buffer == 102)
			FBinRead/F=4 numRef, buffer
		elseif(buffer == 103)
			FBinRead/F=4 numRef, buffer
		//	Remove 101, 102, 103 cases if you see abnormal behaviour
		elseif(buffer == 104)
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "CamExp(s):" + num2str(buffer) + ";"
			
			FBinRead/U/F=1 numRef, buffer
			if(buffer == 0)
				MXPMetaDataStr += "CamMode: No averaging\n"
			elseif(buffer == 255)
				MXPMetaDataStr += "CamMode: Sliding average\n"
			else
				MXPMetaDataStr += "Average images: " + num2str(buffer) + ";"
			endif			
		elseif(buffer == 105)
			FReadLine/T=(num2char(0)) numRef, strbuffer // drop title
		elseif(buffer == 106) // C1G1
			FReadLine /T=(num2char(0)) numRef, strbuffer 
			MXPMetaDataStr += strbuffer
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += num2str(buffer) + ";"
		elseif(buffer == 107) // C1G2
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += strbuffer
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += num2str(buffer) + ";"
		elseif(buffer == 108) // C2G1 not used at MAXPEEM
			FReadLine /T=(num2char(0)) numRef, strbuffer
			//MXPMetaDataStr += strbuffer
			FReadLine /T=(num2char(0)) numRef, strbuffer
			//MXPMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			//MXPMetaDataStr += num2str(buffer) + ";"
		elseif(buffer == 109) // C2G1
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += strbuffer
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += num2str(buffer) + ";"
		elseif(buffer == 110)
			FReadLine /T=(num2char(0))/ENCG={3,3,1} numRef, strbuffer // TODO: Fix the trailing tab and zeros!
			sscanf strbuffer, "%dµm", buffer
			MXPMetaDataStr += "FOV(µm):" + num2str(buffer) + "\n"
			FBinRead/F=4 numRef, buffer // drop FOV calculation factor
		elseif(buffer == 111) //drop
			FBinRead/F=4 numRef, buffer // phi
			FBinRead/F=4 numRef, buffer // theta
		elseif(buffer == 112) //drop
			FBinRead/F=4 numRef, buffer // spin
		elseif(buffer == 113)
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "FOVRot(deg):" + num2str(buffer) + ";"
		elseif(buffer == 114) //drop
			FBinRead/F=4 numRef, buffer // Mirror state
		elseif(buffer == 115) //drop
			FBinRead/F=4 numRef, buffer // MCP screen voltage in kV
		elseif(buffer == 116) //drop
			FBinRead/F=4 numRef, buffer // MCP channelplate voltage in KV
		endif		
	
		FGetPos numRef
	while (V_filePos < MetadataEndPos)
	Close numRef
	return MXPMetaDataStr
End

Function/S MXP_StrGetImageMarkups(string filename)
	/// Read markups from a dat file. Then generate a list containing the markups parameters (positions, \
	///  \size, color,line thickness, text), based partially on https://github.com/euaruksakul/SLRILEEMPEEMAnalysis
	
	variable refNum
	string fileFilters = "Data Files (*.dat):.dat;"
	Open /R /F=fileFilters refNum as filename
	
	// Read attachedRecipeSize
	variable attachedRecipeSize = 0
	FSetPos refNum, 46
	FBinRead /F=2 refNum, attachedRecipeSize
	
	// Follow Elmitec's instructions
	if (attachedRecipeSize != 0)
		attachedRecipeSize = 128
	endif
	
	// Read aAttachedMarkupSize
	variable attachedMarkupSize
	FSetpos refNum, (126 + attachedRecipeSize)
	FBinRead /F=2 refNum, attachedMarkupSize
	attachedMarkupSize = (floor(attachedMarkupSize/128)+1)*128 // Follow Elmitec's instructions
	
	if(attachedMarkupSize)
		variable markupStartPos = 104 + attachedRecipeSize + 288
	
		variable filePos = markupStartPos
		variable readValue = 0	
		
		variable marker
		variable markup_x
		variable markup_y
		variable markup_radius
		variable markup_color_R
		variable markup_color_G
		variable markup_color_B
		variable markup_type
		variable markup_lsize
		string markup_text
		string markupsList = "Markups:"
		string markupsString = ""
		
		FSetPos refNum, FilePos
		FBinRead /F=2 refNum, readValue // Block size
		FBinRead /F=2 refNum, readValue // Reserved
		
		do
			FBinRead /F=2 refNum, marker
			if (marker == 6)
				FBinRead /F=2 refNum, markup_x
				FBinRead /F=2 refNum, markup_y
				FBinRead /F=2 refNum, markup_radius
				FBinRead /F=2 refNum, readValue // always 0050
				FBinRead /F=1/U refNum, markup_color_R; markup_color_R *= 257 // Make 65535 max
				FBinRead /F=1/U refNum, markup_color_G; markup_color_G *= 257
				FBinRead /F=1/U refNum, markup_color_B; markup_color_B *= 257
				FBinRead /F=2 refNum, readValue // always 0000
				FBinRead /F=2 refNum, readValue // always 0000
				FBinRead /F=2 refNum, markup_type
				FBinRead /F=1/U refNum, markup_lsize
				FBinRead /F=2 refNum, readValue // always 0800
				FReadLine /T=(num2char(0)) refNum, markup_text
				
				sprintf markupsString,"%u,%u,%u,%u,%u,%u,%u,%u,%s~",markup_x, markup_y, markup_radius, markup_color_R, markup_color_G, markup_color_B, markup_type, markup_lSize, markup_text
				markupsList += markupsString
			endif
		while (marker != 0)
	endif
	Close refNum
	
	markupsList = RemoveEnding(markupsList) + ";" // Replace the last tidle with a semicolon
	return markupsList
End

Function/S MXP_StrGetImageMarkupsDEV(string filename) // TODO: Work on the function.
	/// Read markups from a dat file. Then generate a list containing the markups parameters (positions, \
	///  \size, color,line thickness, text), based partially on https://github.com/euaruksakul/SLRILEEMPEEMAnalysis
	
	variable refNum
	string fileFilters = "Data Files (*.dat):.dat;"
	Open /R /F=fileFilters refNum as filename
	
	// Read attachedRecipeSize
	variable attachedRecipeSize = 0
	FSetPos refNum, 46
	FBinRead /F=2 refNum, attachedRecipeSize
	
	// Follow Elmitec's instructions
	if (attachedRecipeSize != 0)
		attachedRecipeSize = 128
	endif
	
	// Read aAttachedMarkupSize
	variable attachedMarkupSize
	FSetpos refNum, (126 + attachedRecipeSize)
	FBinRead /F=2 refNum, attachedMarkupSize
	attachedMarkupSize = (floor(attachedMarkupSize/128)+1)*128 // Follow Elmitec's instructions
	
	if(attachedMarkupSize)
		variable markupStartPos = 104 + attachedRecipeSize + 288
	
		variable filePos = markupStartPos
		variable readValue = 0	
		
		// Cross Section
		variable indexX1, indexY1, indexX2, indexY2, indexCx, indexCy
		// Markers
		variable marker, markup_x, markup_y, markup_radius, markup_color_R, markup_color_G, markup_color_B
		variable markup_type, markup_lsize
		// Inclusion
		variable indexRect, RectLeft, RectRight, RectTop, RectBottom
		
		string markup_text
		string markupsList = "Markups:"
		string markupsString = ""
		
		FSetPos refNum, FilePos
		FBinRead /F=2 refNum, readValue // Block size
		FBinRead /F=2 refNum, readValue // Reserved
		
		do
			FBinRead /F=2 refNum, marker
			if (marker == 1 || marker == 2 || marker == 3) // cross section
				FBinRead /F=2 refNum, indexX1
				FBinRead /F=2 refNum, indexY1
				FBinRead /F=2 refNum, indexX2
				FBinRead /F=2 refNum, indexY2
				FBinRead /F=2 refNum, indexCx
				FBinRead /F=2 refNum, indexCy

				sprintf markupsString,"%s,%u,%u,%u,%u,%u,%u", "CrossSection", indexX1, indexY1, indexX2, indexY2, indexCx, indexCy
				markupsList += markupsString
			endif
			if (marker == 6) // marker
				FBinRead /F=2 refNum, markup_x
				FBinRead /F=2 refNum, markup_y
				FBinRead /F=2 refNum, markup_radius
				FBinRead /F=2 refNum, readValue // always 0050
				FBinRead /F=1/U refNum, markup_color_R; markup_color_R *= 257 // Make 65535 max
				FBinRead /F=1/U refNum, markup_color_G; markup_color_G *= 257
				FBinRead /F=1/U refNum, markup_color_B; markup_color_B *= 257
				FBinRead /F=2 refNum, readValue // always 0000
				FBinRead /F=2 refNum, readValue // always 0000
				FBinRead /F=2 refNum, markup_type
				FBinRead /F=1/U refNum, markup_lsize
				FBinRead /F=2 refNum, readValue // always 0800
				FReadLine /T=(num2char(0)) refNum, markup_text
				
				sprintf markupsString,"%s,%u,%u,%u,%u,%u,%u,%u,%u~",markup_text, markup_x, markup_y, markup_radius, markup_color_R, markup_color_G, markup_color_B, markup_type, markup_lSize
				markupsList += markupsString
			endif
			if (marker == 7) // inclusion
				FBinRead /F=2 refNum, indexRect // type: index of rectangle (0,1,2,3)
				FBinRead /F=2 refNum, RectLeft
				FBinRead /F=2 refNum, RectTop
				FBinRead /F=2 refNum, RectRight
				FBinRead /F=2 refNum, RectBottom

				sprintf markupsString,"%s,%u,%u,%u,%u,%u~", "InclExlAreas", indexRect, RectLeft, RectTop, RectRight, RectBottom
				markupsList += markupsString
			endif
		while (marker != 0)
	endif
	Close refNum
	
	markupsList = RemoveEnding(markupsList) + ";" // Replace the last tidle with a semicolon
	return markupsList
End

Function MXP_AppendMarkupsToTopImageDEV()
	/// Draw the markups on an image display (drawn on the UserFront layer)
	/// function based on https://github.com/euaruksakul/SLRILEEMPEEMAnalysis
	/// markups are drawn on the top graph
	string imgNamestr = StringFromList(0,ImageNameList("",";"))
	wave w = ImageNameToWaveRef("", imgNamestr)
	string graphName = WinName(0, 1)
	// Newlines and line feeds create problems with StringByKey, replace with ;
	string markupsList = StringByKey("Markups", note(w), ":", "\n")//ReplaceString("\n",note(w), ";"))

	// Cross Section
	variable indexX1, indexY1, indexX2, indexY2, indexCx, indexCy
	// Markers
	variable marker, markup_x, markup_y, markup_radius, markup_color_R, markup_color_G, markup_color_B
	variable markup_type, markup_lsize
	// Inclusion
	variable indexRect, RectLeft, RectRight, RectTop, RectBottom
	
	string markup, markup_text

	SetDrawLayer /W=$graphName userFront
	variable factorX = DimDelta(w, 0) // Take into account wave scaling, edited EG 02.11.22
	variable factorY = DimDelta(w, 1)
	variable i = 0
	for(i = 0; i < ItemsInList(markupsList, "~"); i++)
		markup = StringFromList(i, markupsList, "~")
		if(!cmpstr(markup, "CrossSection", 0))
			indexX1 = str2num(StringFromList(1, markupsList, "~"))
			indexY1 = str2num(StringFromList(2, markupsList, "~"))
			indexX2 = str2num(StringFromList(3, markupsList, "~"))
			indexY2 = str2num(StringFromList(4, markupsList, "~"))
			indexCx = str2num(StringFromList(5, markupsList, "~"))
			indexCy = str2num(StringFromList(6, markupsList, "~"))
			SetDrawEnv/W=$graphName fillpat = 0,linefgc = (65535,0,0), ycoord = left, xcoord = top //$xaxis
			DrawLine/W=$graphName indexX1, indexY1, indexX2, indexY2
		elseif(!cmpstr(markup, "InclExlAreas", 0))
			indexRect = str2num(StringFromList(1, markupsList, "~"))
			RectLeft = str2num(StringFromList(2, markupsList, "~"))
			RectRight = str2num(StringFromList(3, markupsList, "~"))
			RectTop = str2num(StringFromList(4, markupsList, "~"))
			RectBottom = str2num(StringFromList(5, markupsList, "~"))
			SetDrawEnv/W=$graphName fillpat = 0,linefgc = (65535,0,0), ycoord = left, xcoord = top //$xaxis
			DrawLine/W=$graphName indexX1, indexY1, indexX2, indexY2
		else
			markup_x = str2num(StringFromList(0, markup, ","))
			markup_y = str2num(StringFromList(1, markup, ","))
			markup_radius = str2num(StringFromList(2, markup, ","))
			markup_color_R = str2num(StringFromList(3, markup, ","))
			markup_color_G = str2num(StringFromList(4, markup, ","))
			markup_color_B = str2num(StringFromList(5, markup, ","))
			markup_lsize = str2num(StringFromList(7, markup, ","))
			markup_text = StringFromList(8, markup, ",")
			markup_x *= factorX
			markup_y *= factorY
			markup_radius *= factorX // assumed stuff here
			SetDrawEnv/W=$graphName fillpat = 0,linefgc = (markup_color_R, markup_color_G, markup_color_B), linethick = markup_lsize, ycoord = left, xcoord = top //$xaxis
			DrawOval/W=$graphName markup_x - markup_radius, markup_y - markup_radius, markup_x + markup_radius, markup_y + markup_radius
			SetDrawEnv/W=$graphName fsize = 16, textRGB = (markup_color_R, markup_color_G, markup_color_B), textxjust = 1, textyjust = 1, ycoord = left, xcoord = top
			DrawText/W=$graphName markup_x, markup_y, markup_text
		endif
	endfor
	return 0
End

// ** TODO **: Do we need to flip the image ?
Function MXP_AppendMarkupsToTopImage()
	/// Draw the markups on an image display (drawn on the UserFront layer)
	/// function based on https://github.com/euaruksakul/SLRILEEMPEEMAnalysis
	/// markups are drawn on the top graph
	string imgNamestr = StringFromList(0,ImageNameList("",";"))
	wave w = ImageNameToWaveRef("", imgNamestr)
	string graphName = WinName(0, 1)
	// Newlines and line feeds create problems with StringByKey, replace with ;
	string markupsList = StringByKey("Markups", note(w), ":", "\n")//ReplaceString("\n",note(w), ";"))
	print markupsList
	variable markup_x
	variable markup_y
	variable markup_radius
	variable markup_color_R
	variable markup_color_G
	variable markup_color_B
	variable markup_type
	variable markup_lsize
	string markup_text
	string markup
		

//	string xAxis = ""	
//	// Check whether the image is created from 'NewImage' or 'Display' commands (i.e. whether the top or bottom axis is used)
//	if (WhichListItem("bottom",AxisList(GraphName),";") != -1)
//		xAxis = "bottom"
//	else		
//		xAxis = "top"
//	endif

	SetDrawLayer /W=$graphName userFront
	variable factorX = DimDelta(w, 0) // Take into account wave scaling, edited EG 02.11.22
	variable factorY = DimDelta(w, 1)
	variable i = 0
	for(i = 0; i < ItemsInList(markupsList, "~"); i++)
		markup = StringFromList(i, markupsList, "~")
		markup_x = str2num(StringFromList(0, markup, ","))
		markup_y = str2num(StringFromList(1, markup, ","))
		markup_radius = str2num(StringFromList(2, markup, ","))
		markup_color_R = str2num(StringFromList(3, markup, ","))
		markup_color_G = str2num(StringFromList(4, markup, ","))
		markup_color_B = str2num(StringFromList(5, markup, ","))
		markup_lsize = str2num(StringFromList(7, markup, ","))
		markup_text = StringFromList(8, markup, ",")
		markup_x *= factorX
		markup_y *= factorY
		markup_radius *= factorX // assumed stuff here
		SetDrawEnv/W=$graphName fillpat = 0,linefgc = (markup_color_R, markup_color_G, markup_color_B), linethick = markup_lsize, ycoord = left, xcoord = top //$xaxis
		DrawOval/W=$graphName markup_x - markup_radius, markup_y - markup_radius, markup_x + markup_radius, markup_y + markup_radius
		SetDrawEnv/W=$graphName fsize = 16, textRGB = (markup_color_R, markup_color_G, markup_color_B), textxjust = 1, textyjust = 1, ycoord = left, xcoord = top
		DrawText/W=$graphName markup_x, markup_y, markup_text
	endfor
	return 0
End

Function MXP_LoadDATFilesFromFolder(string folder, string pattern, [int stack3d, string wname3d, int autoscale])
	// We use ImageTransform stackImages X to create the 3d wave. Compared to 3d wave assignement it is faster by nearly 3x.

	/// Import .dat files that match a pattern from a folder. Waves are named after their filename.
	/// @param folder string folder of the .dat files
	/// @param pattern string pattern to filter .dat files, use "*" for all .dat files- empty string gives an error
	/// @param stack3d int optional stack imported .dat files to the 3d wave, kill the imported waves
	/// @param autoScale int optional scales the imported waves if not 0
	/// @param wname3d string optional name of the 3d wave, othewise defaults to MXP_w3d

	stack3d = ParamIsDefault(stack3d) ? 0: stack3d
	wname3d = SelectString(ParamIsDefault(wname3d) ? 0: 1,"stack3d", wname3d)
	
	string message = "Select a folder."
	string fileFilters = "DAT Files (*.dat):.dat;"
	fileFilters += "All Files:.*;"
	
	NewPath/O/Q/M=message MXP_DATFilesPathTMP
	if (V_flag) // user cancel?
		Abort
	endif
	PathInfo/S MXP_DATFilesPathTMP
	folder = ParseFilePath(2, S_Path, ":", 0, 0)
	
	// Get all the .dat files. Use "????" for all files in IndexedFile third argument.
	// Filter the matches with pattern at the second stage.
	string allFiles = ListMatch(SortList(IndexedFile(MXP_DATFilesPathTMP, -1, ".dat"),";", 16), pattern)
		
	variable filesnr = ItemsInList(allFiles)

	// If no files are selected (e.g match pattern return "") warn user
	if (!filesnr)
		Abort "No files match pattern: " + pattern
	endif
	variable cnt = 0
	string odlwname = wname3d
	// IDEA: Use CreateDataObjectName(dfr, nameInStr, objectType, suffixNum, options)
	// Handle the case where the 3d wave exists and find an appropriate name
	if(stack3d && exists(wname3d) == 1)
		do
			printf "Wave %s exists in %s renaming to %s\n", wname3d, GetDataFolder(1), (wname3d + num2str(cnt))
			wname3d = odlwname + "_" + num2str(cnt)
			cnt++
		while(exists(wname3d) == 1)
		// if name in use by a global wave/variable 
		if(!exists(wname3d) == 0) // 0 - Name not in use, or does not conflict with a wave, numeric variable or string variable in the specified data folder.
			print "MXP: Renamed your wave to \"" + (wname3d + "_rn") + "\" to avoid conflicts"
			wname3d += "_rn"
		endif
	endif
	
	string filenameBuffer, datafile2read, filenameStr
	variable i, fovScale
	
	if(stack3d) // Make a folder to import files for the stack
		NewDataFolder MPX_tmpStorageStackFolder
		SetDataFolder MPX_tmpStorageStackFolder
	endif
	// Now get all the files
	for(i = 0; i < filesnr; i += 1)
		filenameBuffer = StringFromList(i, allFiles)
		datafile2read = folder + filenameBuffer
		if(stack3d) // Skip the metadata if you load to a 3dwave
			// Here we assume all the waves have the same x, y scaling 
			if(i == 0) // We get the wave scaling for rows and columnns using the first wave, assumed DimSize(w, 0) == DimSize(w, 1)
					WAVE wname = MXP_WAVELoadSingleDATFile(datafile2read, ("MXPWaveToStack_idx_" + num2str(i)), skipmetadata = 0) 
					variable getScaleXY = NumberByKey("FOV(µm)", note(wname), ":", "\n")
				else
					WAVE wname = MXP_WAVELoadSingleDATFile(datafile2read, ("MXPWaveToStack_idx_" + num2str(i)), skipmetadata = 1)
			endif
		else
			filenameStr = ParseFilePath(3, datafile2read, ":", 0, 0)
			WAVE wname = MXP_WAVELoadSingleDATFile(datafile2read, filenameStr, skipmetadata = 0)
			fovScale = NumberByKey("FOV(µm)", note(wname), ":", "\n")
			if(autoscale)
				SetScale/I x, 0, fovScale, $filenameStr
				SetScale/I y, 0, fovScale, $filenameStr 
			endif
		endif		
	endfor
	
	// It is assumed that all the imported waves have the same dimensions, use it to scale the 3d wave
	if(stack3d)
		WAVE wname = MXP_WAVELoadSingleDATFile(datafile2read, ("MXPWaveToStack_idx_"+num2str(i)), skipmetadata = 0)
	endif

	if(stack3d)
		ImageTransform/NP=(filesnr) stackImages $"MXPWaveToStack_idx_0"
		WAVE M_Stack
		//Add a note to the 3dwave about which files have been loaded
		string note3d
		sprintf note3d, "Timestamp: %s\nFolder: %s\nFiles: %s\n",(date() + " " + time()), folder, allFiles
		Note/K M_Stack, note3d
		MoveWave M_Stack ::$wname3d
		SetDataFolder ::
		KillDataFolder/Z MPX_tmpStorageStackFolder
	endif
	if(autoscale && stack3d)
		SetScale/I x, 0, getScaleXY, $wname3d
		SetScale/I y, 0, getScaleXY, $wname3d
	endif
	KillPath/Z MXP_DATFilesPathTMP
	return 0
End

Function MXP_LoadMultiplyDATFiles([string filenames, int skipmetadata, int autoscale])
	/// Load multiply selected .dat files
	/// @param filenames string optional string separated by ";". If you provide filenames and the
	/// number of selected files  match the number of names in string then use them to name waves.
	/// @param skipmetadata is optional and if set to a non-zero value it skips metadata.
	/// @param autoScale int optional scales the imported waves if not 0
	/// Note: the selected wave are sort alphanumerically so the first on the list takes the 
	/// first name in filenames etc.
	
	filenames = SelectString(ParamIsDefault(filenames) ? 0: 1,"", filenames)
	skipmetadata = ParamIsDefault(skipmetadata) ? 0: skipmetadata // if set do not read metadata	
	autoScale = ParamIsDefault(autoScale) ? 0: autoScale

	variable numRef
    string loadFiles, filepathStr

	string message = "Select .dat files. \n"
	message += "Import overwrites waves with the same name."
	string fileFilters = "DAT File (*.dat):.dat;"
	fileFilters += "All Files:.*;"
   	Open/F=fileFilters/MULT=1/M=message/D/R numref
   	filepathStr = S_filename
   	
   	if(!strlen(filepathStr)) // user cancel?
   		Abort
   	endif
   				
	loadFiles = SortList(S_fileName, "\r", 16) 
	variable nrloadFiles = ItemsInList(loadFiles, "\r")
	variable nrFilenames = ItemsInList(filenames)
	
	variable i = 0
	for(i = 0; i < nrloadFiles; i += 1)
		if (nrloadFiles == nrFilenames)
			MXP_LoadSingleDATFile(StringFromList(i,loadFiles, "\r"), StringFromList(i, filenames), skipmetadata = skipmetadata, autoscale = autoscale)
		else
			MXP_LoadSingleDATFile(StringFromList(i,loadFiles, "\r"), "", skipmetadata = skipmetadata, autoscale = autoscale)
		endif
	endfor
	return 0
End

