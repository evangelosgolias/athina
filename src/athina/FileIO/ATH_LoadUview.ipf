#pragma rtGlobals    = 3
#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later
#pragma ModuleName  = ATH_Uview
#pragma version = 1.01
// ------------------------------------------------------- //
// Functions to import binary .dat & .dav files created by 
// Elmitec's Uview Software at MAXPEEM beamline of MAX IV.
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

static constant kpixelsTVIPS = 2048 // Change here if needed. Used for corrupted files only.

static Function/WAVE WAVELoadSingleDATFile(string filepathStr, string waveNameStr 
			  [,int skipmetadata, int autoScale, int readMarkups,int binX, int binY, int overwrite])
	///< Function to load a single Elmitec binary .dat file.
	/// @param filepathStr string filename (including) pathname. 
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave. 
	/// If "" the wave name is the filename without the path and extention.
	/// @param skipmetadata int optional and if set to a non-zero value it skips metadata.
	/// @param autoScale int optional scales the imported waves if not 0
	/// @param binX binning for rows
	/// @param binY binning for cols
	/// @return wave reference
	
	skipmetadata = ParamIsDefault(skipmetadata) ? 0: skipmetadata // if set do not read metadata
	autoScale = ParamIsDefault(autoScale) ? 0: autoScale
	readMarkups = ParamIsDefault(readMarkups) ? 0: readMarkups
	binX = ParamIsDefault(binX) ? 1: binX
	binY = ParamIsDefault(binY) ? 1: binY
	overwrite = ParamIsDefault(overwrite) ? 0: overwrite

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
   			return $""
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
   			return $""
   		endif
   		
		message = "Select .dat file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
	else
		Abort "Path for datafile not specified (check ATH_WAVELoadSingleDATFile)!"
	endif
	
	STRUCT UKFileHeader ATHFileHeader
	STRUCT UKImageHeader ATHImageHeader

	FStatus numRef
	// change here if needed

	FSetPos numRef, 0
	FBinRead numRef, ATHFileHeader

	// FileHeader: 104 bytes or 104 + 128 bytes if attachedRecipeSize>0
	if(ATHFileHeader.attachedRecipeSize > 0)
		ATHFileHeader.size += 128
	endif
	
	variable ImageHeaderSize, timestamp
			
	FSetPos numRef, ATHFileHeader.size
	FBinRead numRef, ATHImageHeader

	//Elmitec files can have additional markup blocks hence the offsets of 128 bytes
	if(ATHImageHeader.attachedMarkupSize == 0)
		//no markups
		ImageHeaderSize = 288 // UKImageHeader -> 288 bytes
	else
		//Markup blocks multiple of 128 bytes after image header
		ImageHeaderSize = 288 + 128 * ((trunc(ATHImageHeader.attachedMarkupSize/128))+1)
	endif
	
	variable LEEMdataVersion = ATHImageHeader.LEEMdataVersion <= 2 ? 0: ATHImageHeader.LEEMdataVersion //NB: Added 23.05.2023
	variable ImageDataStart = ATHFileHeader.size + ImageHeaderSize + LEEMdataVersion
	//Now read the image [unsigned int 16-bit, /F=2 2 bytes per pixel]
	if(binX == 1 && binY == 1)
		if(overwrite)
			Make/W/U/O/N=(ATHFileHeader.ImageWidth, ATHFileHeader.ImageHeight) $waveNameStr /WAVE=datWave
		else
			waveNameStr = CreateDataObjectName(GetDataFolderDFR(), waveNameStr, 1,0,1)
			Make/W/U/N=(ATHFileHeader.ImageWidth, ATHFileHeader.ImageHeight) $waveNameStr /WAVE=datWave
		endif
		FSetPos numRef, ImageDataStart
		FBinRead/F=2 numRef, datWave
	else
		Make/W/U/O/N=(ATHFileHeader.ImageWidth, ATHFileHeader.ImageHeight)/FREE datWaveFree
		FSetPos numRef, ImageDataStart
		FBinRead/F=2 numRef, datWaveFree
		Redimension/S datWaveFree
		ImageInterpolate/PXSZ={binX, binY}/DEST=$waveNameStr Pixelate datWaveFree
		if(overwrite)
			WAVE datWave = $waveNameStr
		else
			waveNameStr = CreateDataObjectName(GetDataFolderDFR(), waveNameStr, 1,0,1)
			WAVE datWave = $waveNameStr
		endif		
	endif
	
	Close numRef
	
	string mdatastr = ""
	
	if(!skipmetadata)
		timestamp = ATHImageHeader.imagetime.LONG[0]+2^32 * ATHImageHeader.imagetime.LONG[1]
		timestamp *= 1e-7 // t_i converted from 100ns to s
		timestamp -= 9561628800 // t_i converted from Windows Filetime format (01/01/1601) to Mac Epoch format (01/01/1970)
		// If UView can fill the metadata in ATHFileHeader.size then ATHImageHeader.LEEMdataVersion==0, no need to allocate more space. 
		// NB: Added on 23.05.2023.
		variable metadataStart = ATHImageHeader.LEEMdataVersion <= 2 ? ATHFileHeader.size: (ATHFileHeader.size + ImageHeaderSize)
		mdatastr = filepathStr + "\n"		
		mdatastr += "Timestamp: " + Secs2Date(timestamp, -2) + " " + Secs2Time(timestamp, 3) + "\n"
		if(binX != 1 || binY != 1)
			mdatastr += "Binning: (" + num2str(binX) + ", " + num2str(binY) + ")\n"
		endif			
		mdatastr += StrGetBasicMetadataInfoFromDAT(filepathStr, metadataStart, ImageDataStart, ATHImageHeader.LEEMdataVersion)
		if(readMarkups && ATHImageHeader.attachedMarkupSize)// Add image markups if any
			mdatastr += StrGetImageMarkups(filepathStr)
		endif
		if(autoScale)
			variable imgScaleVar = NumberByKey("FOV(µm)", mdatastr, ":", "\n")
			imgScaleVar = (numtype(imgScaleVar) == 2)? 0: imgScaleVar // NB: Added on 23.05.2023
			SetScale/I x, 0, imgScaleVar, datWave
			SetScale/I y, 0, imgScaleVar, datWave
		endif			
	endif
	
	if(strlen(mdatastr)) // Added to allow ATH_LoadDATFilesFromFolder function to skip Note/K without error
		Note/K datWave, mdatastr
	endif
	
	return datWave
End

static Function LoadSingleDATFile(string filepathStr, string waveNameStr
         [,int skipmetadata, int autoScale, int readMarkups, int binX, int binY, int overwrite])
	///< Function to load a single Elmitec binary .dat file.
	/// @param filepathStr string pathname. 
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave. 
	/// If "" the wave name is the filename without the path and extention.
	/// @param skipmetadata is optional and if set to a non-zero value it skips metadata.
	/// @param autoScale int optional scales the imported waves if not 0
	/// @param binX binning for rows
	/// @param binY binning for cols
	
	skipmetadata = ParamIsDefault(skipmetadata) ? 0: skipmetadata // if set do not read metadata
	autoScale = ParamIsDefault(autoScale) ? 0: autoScale
	readMarkups = ParamIsDefault(readMarkups) ? 0: readMarkups	
	binX = ParamIsDefault(binX) ? 1: binX
	binY = ParamIsDefault(binY) ? 1: binY
	overwrite = ParamIsDefault(overwrite) ? 0: overwrite
		
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
   			return NaN
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
   			return NaN
   		endif
   		
		message = "Select .dat file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
	else
		Abort "Path for datafile not specified (check ATH_LoadSingleDATFile)!"
	endif
	
	STRUCT UKFileHeader ATHFileHeader
	STRUCT UKImageHeader ATHImageHeader

	FStatus numRef
	// change here if needed

	FSetPos numRef, 0
	FBinRead numRef, ATHFileHeader

	// FileHeader: 104 bytes or 104 + 128 bytes if attachedRecipeSize>0
	if(ATHFileHeader.attachedRecipeSize > 0)
		ATHFileHeader.size += 128
	endif
	
	variable ImageHeaderSize, timestamp
			
	FSetPos numRef, ATHFileHeader.size
	FBinRead numRef, ATHImageHeader

	//Elmitec files can have additional markup blocks hence the offsets of 128 bytes
	if(ATHImageHeader.attachedMarkupSize == 0)
		//no markups
		ImageHeaderSize = 288 // UKImageHeader -> 288 bytes
	else
		//Markup blocks multiple of 128 bytes after image header
		ImageHeaderSize = 288 + 128 * ((trunc(ATHImageHeader.attachedMarkupSize/128))+1)
	endif
	
	variable LEEMdataVersion = ATHImageHeader.LEEMdataVersion <= 2 ? 0: ATHImageHeader.LEEMdataVersion //NB: Added 23.05.2023
	variable ImageDataStart = ATHFileHeader.size + ImageHeaderSize + LEEMdataVersion
	//Now read the image [unsigned int 16-bit, /F=2 2 bytes per pixel]

	if(binX == 1 && binY == 1)
		if(overwrite)
			Make/W/U/O/N=(ATHFileHeader.ImageWidth, ATHFileHeader.ImageHeight) $waveNameStr /WAVE=datWave
		else
			waveNameStr = CreateDataObjectName(GetDataFolderDFR(), waveNameStr, 1,0,1)
			Make/W/U/N=(ATHFileHeader.ImageWidth, ATHFileHeader.ImageHeight) $waveNameStr /WAVE=datWave
		endif
		FSetPos numRef, ImageDataStart
		FBinRead/F=2 numRef, datWave
	else
		Make/W/U/O/N=(ATHFileHeader.ImageWidth, ATHFileHeader.ImageHeight)/FREE datWaveFree
		FSetPos numRef, ImageDataStart
		FBinRead/F=2 numRef, datWaveFree
		Redimension/S datWaveFree
		ImageInterpolate/PXSZ={binX, binY}/DEST=$waveNameStr Pixelate datWaveFree
		if(overwrite)
			WAVE datWave = $waveNameStr
		else
			waveNameStr = CreateDataObjectName(GetDataFolderDFR(), waveNameStr, 1,0,1)
			WAVE datWave = $waveNameStr
		endif		
	endif

	Close numRef
		
	string mdatastr = ""
	
	if(!skipmetadata)
		timestamp = ATHImageHeader.imagetime.LONG[0]+2^32 * ATHImageHeader.imagetime.LONG[1]
		timestamp *= 1e-7 // t_i converted from 100ns to s
		timestamp -= 9561628800 // t_i converted from Windows Filetime format (01/01/1601) to Mac Epoch format (01/01/1970)
		// If UView can fill the metadata in ATHFileHeader.size then ATHImageHeader.LEEMdataVersion==0, no need to allocate more space. 
		// NB: Added on 23.05.2023.
		variable metadataStart = ATHImageHeader.LEEMdataVersion <= 2 ? ATHFileHeader.size: (ATHFileHeader.size + ImageHeaderSize)
		mdatastr = filepathStr + "\n"		
		mdatastr += "Timestamp: " + Secs2Date(timestamp, -2) + " " + Secs2Time(timestamp, 3) + "\n"
		if(binX != 1 || binY != 1)
			mdatastr += "Binning: (" + num2str(binX) + ", " + num2str(binY) + ")\n"
		endif	
		mdatastr += StrGetBasicMetadataInfoFromDAT(filepathStr, metadataStart, ImageDataStart, ATHImageHeader.LEEMdataVersion)
		if(readMarkups && ATHImageHeader.attachedMarkupSize)// Add image markups if any
			mdatastr += StrGetImageMarkups(filepathStr)
		endif
		if(autoScale)
			variable imgScaleVar = NumberByKey("FOV(µm)", mdatastr, ":", "\n")
			imgScaleVar = (numtype(imgScaleVar) == 2)? 0: imgScaleVar // NB: Added on 23.05.2023
			SetScale/I x, 0, imgScaleVar, datWave
			SetScale/I y, 0, imgScaleVar, datWave
		endif	
	endif

	if(strlen(mdatastr)) // Added to allow ATH_LoadDATFilesFromFolder function to skip Note/K without error
		Note/K datWave, mdatastr
	endif
	
	return 0
End

static Function/S StrGetBasicMetadataInfoFromDAT(string datafile, variable MetadataStartPos, 
		   variable MetadataEndPos, variable LEEMDataVersion)
	// Read important metadata from a .dat file. Most metadata are stored in the form
	// tag (units): values, so it's easy to parse using the StringByKey function.
	// The function is used by ATH_ImportImageFromSingleDatFile(string datafile, string FileNameStr)
	// to add the most important metadata as note to the imported image.
	variable numRef
   	Open/R numRef as datafile
   	FSetPos numRef, MetadataStartPos
	// String for all metadata
	string ATHMetaDataStr = ""


	variable buffer
	string strbuffer
	
	do
		FBinRead/U/F=1 numRef, buffer 
		/// We read numbers as unsigned. Following the FileFormats 2017.pdf
		/// from Elmitec, the highest bit of a byte in the metadata section
		/// is used to display or not a specific tag on an image. When you choose not 
		/// to diplay a tag the highest bit is set.
		/// For example in MAXPEEM by default we choose to display the start 
		/// voltage, therefore its value is 0x26 (38 decimal). If the value is recorded
		/// but not shown on the image the value would be 0xA6 (166 decimal)
		if (buffer == 255)
			continue
		endif
				
		if (buffer > 127)
			buffer -= 128
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
				ATHMetaDataStr += "STV(V):" + num2str(buffer) + "\n"
			elseif(buffer == 11) // or stringmatch(strbuffer, "*Objective2*")
				FBinRead/F=4 numRef, buffer
				ATHMetaDataStr += "Objective(mA):" + num2str(buffer) + "\n"
			elseif(buffer == 39) // or stringmatch(strbuffer, "*Sample Temp.*")
				FBinRead/F=4 numRef, buffer
				ATHMetaDataStr += "SampleTemp(ºC):" + num2str(buffer) + "\n"
			else
				FBinRead/F=4 numRef, buffer // drop the rest
			endif
		elseif(buffer == 100)
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += "X(mm):" + num2str(buffer) + "\n"
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += "Y(mm):" + num2str(buffer) + "\n"
		elseif(buffer == 101)
			FReadLine /T=(num2char(0)) numRef, strbuffer // old entry, drop
		elseif(buffer == 102)
			FBinRead/F=4 numRef, buffer // old entry, drop
		elseif(buffer == 103)
			FBinRead/F=4 numRef, buffer // old entry, drop
		elseif(buffer == 104)
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += "CamExp(s):" + num2str(buffer) + "\n"
			if(LEEMDataVersion > 1)
				FBinRead/U/F=1 numRef, buffer
				if(buffer == 0)
					ATHMetaDataStr += "CamMode: No averaging\n"
				elseif(buffer < 0)
					ATHMetaDataStr += "CamMode: Sliding average\n"
				elseif(buffer > 0)
					// // last case, ok to read buffer here
					ATHMetaDataStr += "Average images: " + num2str(buffer) + "\n"
					// From FileFormats 2017
					// 2 bytes B1,B2 follow
					// if B1>0 average is on , B2= number of averaged images 2 to 127
					// if B1=0 average is off
					// if B1<0 sliding average (<0 in this case -1: hex: 0xff, decimal :255)
					// The Avg is in the first read, the second is usually 1!
					// We have to read and drop it. Not sure if the manual is wrong.
					FBinRead/U/F=1 numRef, buffer
				else
					print "Error104"
				endif				
			endif
		elseif(buffer == 105)
			FReadLine/T=(num2char(0)) numRef, strbuffer // drop title
		elseif(buffer == 106) // C1G1 - MCH
			FReadLine/T=(num2char(0)) numRef, strbuffer 
			ATHMetaDataStr += "MCH" // MAXPEEM naming conversion
			FReadLine/T=(num2char(0)) numRef, strbuffer
			ATHMetaDataStr += "(" + RemoveEnding(strbuffer) + "):" // Remove trailing 0x00
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 107) // C1G2 - COL
			FReadLine/T=(num2char(0)) numRef, strbuffer
			//ATHMetaDataStr += "COL" // MAXPEEM naming conversion
			FReadLine/T=(num2char(0)) numRef, strbuffer
			//ATHMetaDataStr += "(" + RemoveEnding(strbuffer) + "):"
			FBinRead/F=4 numRef, buffer
			//ATHMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 108) // C2G1 not used at MAXPEEM
			FReadLine/T=(num2char(0)) numRef, strbuffer 
			//ATHMetaDataStr += "MCH" // MAXPEEM naming conversion
			FReadLine/T=(num2char(0)) numRef, strbuffer
			//ATHMetaDataStr += "(" + RemoveEnding(strbuffer) + "):"
			FBinRead/F=4 numRef, buffer
			//ATHMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 109) // C2G1 - PCH
			FReadLine /T=(num2char(0)) numRef, strbuffer
			//ATHMetaDataStr += "PCH" // MAXPEEM naming conversion
			FReadLine /T=(num2char(0)) numRef, strbuffer
			//ATHMetaDataStr += "(" + RemoveEnding(strbuffer) + "):"
			FBinRead/F=4 numRef, buffer
			//ATHMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 110)
			FReadLine /T=(num2char(0))/ENCG={3,3,1} numRef, strbuffer // TODO: Fix the trailing tab and zeros!
			sscanf strbuffer, "%eµm", buffer
			ATHMetaDataStr += "FOV(µm):" + num2str(buffer) + "\n"
			FBinRead/F=4 numRef, buffer //FOV calculation factor
			//ATHMetaDataStr += "FOV calc. fact.:" + num2str(buffer) + "\n"
		elseif(buffer == 111) //drop
			FBinRead/F=4 numRef, buffer // phi
			FBinRead/F=4 numRef, buffer // theta
		elseif(buffer == 112) //drop
			FBinRead/F=4 numRef, buffer // spin
		elseif(buffer == 113)
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += "FOVRot(deg):" + num2str(buffer) + "\n"
		elseif(buffer == 114) //drop
			FBinRead/F=4 numRef, buffer // Mirror state
		elseif(buffer == 115) //drop
			FBinRead/F=4 numRef, buffer // MCP screen voltage in kV
		elseif(buffer == 116) //drop
			FBinRead/F=4 numRef, buffer // MCP channelplate voltage in KV
		elseif(buffer >= 120 && buffer <= 130) //drop other gauges if any 
			FReadLine /T=(num2char(0)) numRef, strbuffer // Name
			FReadLine /T=(num2char(0)) numRef, strbuffer // Units
			FBinRead/F=4 numRef, buffer // value
		endif		
		FGetPos numRef
	while (V_filePos < MetadataEndPos)
	Close numRef
	return ATHMetaDataStr // ConvertTextEncoding(ATHMetaDataStr, 1, 1, 3, 2)
End

static Function/S StrGetAllMetadataInfoFromDAT(string datafile, variable MetadataStartPos, 
           variable MetadataEndPos, variable LEEMDataVersion)
	// Read all metadata from a .dat file. Most metadata are stored in the form
	// tag (units): values, so it's easy to parse using the StringByKey function.
	// The function is used by ATH_ImportImageFromSingleDatFile(string datafile, string FileNameStr)
	// to add the most important metadata as note to the imported image.

	variable numRef
   	Open/R numRef as datafile
   	FSetPos numRef, MetadataStartPos
	// String for all metadata
	string ATHMetaDataStr = ""


	variable buffer 
	string strBuffer, nametag, units
	
	do
		FBinRead/U/F=1 numRef, buffer 
		/// We read numbers as unsigned. Following the FileFormats 2017.pdf
		/// from Elmitec, the highest bit of a byte in the metadata section
		/// is used to display or not a specific tag on an image. When you choose not 
		/// to diplay a tag the highest bit is set.
		/// For example in MAXPEEM by default we choose to display the start 
		/// voltage, therefore its value is 0x26 (38 decimal). If the value is recorded
		/// but not shown on the image the value would be 0xA6 (166 decimal)
		
		if (buffer == 255)
			continue
		endif
				
		if (buffer > 127)
			buffer -= 128
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
			ATHMetaDataStr += nametag
			strswitch(units)
				case "0":
					ATHMetaDataStr += "None" 
					break
				case "1":
					ATHMetaDataStr += "(V)" 
					break
				case "2":
					ATHMetaDataStr += "(mA)" 
					break
				case "3":
					ATHMetaDataStr += "(A)" 
					break
				case "4":
					ATHMetaDataStr += "(ºC)" 
					break
				case "5":
					ATHMetaDataStr += "(K)" 
					break
				case "6":
					ATHMetaDataStr += "(mV)" 
					break
				case "7":
					ATHMetaDataStr += "(pA)" 
					break
				case "8":
					ATHMetaDataStr += "(nA)" 
					break
				case "9":
					ATHMetaDataStr += "(µA)" 
					break
			endswitch
			FBinRead/F=4 numRef, buffer
			if(strlen(nametag)) // there is a zero nametag! Exclude it
				ATHMetaDataStr += ":" + num2str(buffer) + ";"
			endif
		elseif(buffer == 100)
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += "X(mm):" + num2str(buffer) + ";"
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += "Y(mm):" + num2str(buffer) + ";"
		elseif(buffer == 101)
			FReadLine /T=(num2char(0)) numRef, strbuffer
		elseif(buffer == 102)
			FBinRead/F=4 numRef, buffer
		elseif(buffer == 103)
			FBinRead/F=4 numRef, buffer
		elseif(buffer == 104)
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += "CamExp(s):" + num2str(buffer) + "\n"
			if(LEEMDataVersion > 1)
				FBinRead/U/F=1 numRef, buffer
				if(buffer == 0)
					ATHMetaDataStr += "CamMode: No averaging\n"
				elseif(buffer < 0)
					ATHMetaDataStr += "CamMode: Sliding average\n"
				elseif(buffer > 0)
					// // last case, ok to read buffer here
					ATHMetaDataStr += "Average images: " + num2str(buffer) + "\n"
					// From FileFormats 2017
					// 2 bytes B1,B2 follow
					// if B1>0 average is on , B2= number of averaged images 2 to 127
					// if B1=0 average is off
					// if B1<0 sliding average (<0 in this case -1: hex: 0xff, decimal :255)
					// The Avg is in the first read, the second is usually 1!
					// We have to read and drop it. Not sure if the manual is wrong.
					FBinRead/U/F=1 numRef, buffer
				else
					print "Error104"
				endif				
			endif	
		elseif(buffer == 105)
			FReadLine/T=(num2char(0)) numRef, strbuffer // drop title
		elseif(buffer == 106) // C1G1
			FReadLine /T=(num2char(0)) numRef, strbuffer 
			ATHMetaDataStr += strbuffer
			FReadLine /T=(num2char(0)) numRef, strbuffer
			ATHMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += num2str(buffer) + ";"
		elseif(buffer == 107) // C1G2
			FReadLine /T=(num2char(0)) numRef, strbuffer
			ATHMetaDataStr += strbuffer
			FReadLine /T=(num2char(0)) numRef, strbuffer
			ATHMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += num2str(buffer) + ";"
		elseif(buffer == 108) // C2G1 not used at MAXPEEM
			FReadLine /T=(num2char(0)) numRef, strbuffer
			//ATHMetaDataStr += strbuffer
			FReadLine /T=(num2char(0)) numRef, strbuffer
			//ATHMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			//ATHMetaDataStr += num2str(buffer) + ";"
		elseif(buffer == 109) // C2G1
			FReadLine /T=(num2char(0)) numRef, strbuffer
			ATHMetaDataStr += strbuffer
			FReadLine /T=(num2char(0)) numRef, strbuffer
			ATHMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += num2str(buffer) + ";"
		elseif(buffer == 110)
			FReadLine /T=(num2char(0))/ENCG={3,3,1} numRef, strbuffer // TODO: Fix the trailing tab and zeros!
			sscanf strbuffer, "%dµm", buffer
			ATHMetaDataStr += "FOV(µm):" + num2str(buffer) + "\n"
			FBinRead/F=4 numRef, buffer //FOV calculation factor
			ATHMetaDataStr += "FOV calc. fact.:" + num2str(buffer) + "\n"
		elseif(buffer == 111) //drop
			FBinRead/F=4 numRef, buffer // phi
			FBinRead/F=4 numRef, buffer // theta
		elseif(buffer == 112) //drop
			FBinRead/F=4 numRef, buffer // spin
		elseif(buffer == 113)
			FBinRead/F=4 numRef, buffer
			ATHMetaDataStr += "FOVRot(deg):" + num2str(buffer) + ";"
		elseif(buffer == 114) //drop
			FBinRead/F=4 numRef, buffer // Mirror state
		elseif(buffer == 115) //drop
			FBinRead/F=4 numRef, buffer // MCP screen voltage in kV
		elseif(buffer == 116) //drop
			FBinRead/F=4 numRef, buffer // MCP channelplate voltage in KV
		elseif(buffer >= 120 && buffer <= 130) //drop other gauges if any 
			FReadLine /T=(num2char(0)) numRef, strbuffer // Name
			FReadLine /T=(num2char(0)) numRef, strbuffer // Units
			FBinRead/F=4 numRef, buffer // value
		endif		
		FGetPos numRef
	while (V_filePos < MetadataEndPos)
	Close numRef
	return ATHMetaDataStr
End

static Function/S StrGetImageMarkups(string filename)
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

static Function LoadDATFilesFromFolder(string folder, string pattern, [int stack3d, string wname3d, int autoscale, int displayImg])
	// We use ImageTransform stackImages X to create the 3d wave. Compared to 3d wave assignement it is faster by nearly 3x.

	/// Import .dat files that match a pattern from a folder. Waves are named after their filename.
	/// @param folder string folder of the .dat files
	/// @param pattern string pattern to filter .dat files, use "*" for all .dat files- empty string gives an error
	/// @param stack3d int optional stack imported .dat files to the 3d wave, kill the imported waves
	/// @param autoScale int optional scales the imported waves if not 0
	/// @param wname3d string optional name of the 3d wave, othewise defaults to ATH_w3d

	stack3d = ParamIsDefault(stack3d) ? 0: stack3d
	wname3d = SelectString(ParamIsDefault(wname3d) ? 0: 1,"", wname3d) // Empty case will be handled below
	autoScale = ParamIsDefault(autoScale) ? 0: autoScale
	stack3d = ParamIsDefault(stack3d) ? 0: stack3d
	displayImg = ParamIsDefault(displayImg) ? 0: displayImg	
	
	string message = "Select a folder."
	string fileFilters = "DAT Files (*.dat):.dat;"
	fileFilters += "All Files:.*;"
	
	NewPath/O/Q/M=message ATH_DATFilesPathTMP
	if (V_flag) // user cancel?
		return NaN
	endif
	PathInfo/S ATH_DATFilesPathTMP
	folder = ParseFilePath(2, S_Path, ":", 0, 0)
	
	DFREF cwDFR = GetDataFolderDFR()
	string basenameStr
	if(!strlen(wname3d))
		basenameStr = ParseFilePath(0, S_Path, ":", 1, 0) // Use it to name the wave if wname3d = "
		wname3d = CreatedataObjectName(cwDFR, basenameStr, 1, 0, 1)
	else
		basenameStr = wname3d
		wname3d = CreatedataObjectName(cwDFR, basenameStr, 1, 0, 1)
	endif
	
	// Get all the .dat files. Use "????" for all files in IndexedFile third argument.
	// Filter the matches with pattern at the second stage.
	string allFiles = ListMatch(SortList(IndexedFile(ATH_DATFilesPathTMP, -1, ".dat"),";", 80), pattern)
		
	variable filesnr = ItemsInList(allFiles)

	// If no files are selected (e.g match pattern return "") warn user
	if (!filesnr)
		Abort "No files match pattern: " + pattern
	endif
	
	string filenameBuffer, datafile2read, filenameStr
	variable i, fovScale
	
	if(stack3d) // Make a folder to import files for the stack
		DFREF saveDF = GetDataFolderDFR()
		SetDataFolder NewFreeDataFolder()
	endif
	// Now get all the files
	for(i = 0; i < filesnr; i += 1)
		filenameBuffer = StringFromList(i, allFiles)
		datafile2read = folder + filenameBuffer
		if(stack3d) // Skip the metadata if you load to a 3dwave
			// Here we assume all the waves have the same x, y scaling 
			if(i == 0) // We get the wave scaling for rows and columnns using the first wave, assumed DimSize(w, 0) == DimSize(w, 1)
					WAVE wname = WAVELoadSingleDATFile(datafile2read, ("ATHWaveToStack_idx_" + num2str(i)), skipmetadata = 0) 
					variable getScaleXY = NumberByKey("FOV(µm)", note(wname), ":", "\n")
					getScaleXY = (numtype(getScaleXY) == 2)? 0: getScaleXY // NB: Added on 23.05.2023
				else
					WAVE wname = WAVELoadSingleDATFile(datafile2read, ("ATHWaveToStack_idx_" + num2str(i)), skipmetadata = 1)
			endif
		else
			filenameStr = ParseFilePath(3, datafile2read, ":", 0, 0)
			WAVE wname = WAVELoadSingleDATFile(datafile2read, filenameStr, skipmetadata = 0)
			fovScale = NumberByKey("FOV(µm)", note(wname), ":", "\n")
			if(autoscale)
				fovScale = (numtype(fovScale) == 2)? 0: fovScale // NB: Added on 23.05.2023
				SetScale/I x, 0, fovScale, $filenameStr
				SetScale/I y, 0, fovScale, $filenameStr 
			endif
		endif		
	endfor

	if(stack3d)
		ImageTransform/NP=(filesnr) stackImages $"ATHWaveToStack_idx_0"
		WAVE M_Stack
		//Add a note to the 3dwave about which files have been loaded
		string note3d
		sprintf note3d, "Timestamp: %s\nFolder: %s\nFiles: %s\n",(date() + " " + time()), folder, allFiles
		Note/K M_Stack, note3d
		MoveWave M_Stack saveDF:$wname3d
		SetDataFolder saveDF
		KillDataFolder/Z ATH_tmpStorageStackFolder
	else
		KillPath/Z ATH_DATFilesPathTMP
	endif
	if(autoscale && stack3d)
		SetScale/I x, 0, getScaleXY, $wname3d
		SetScale/I y, 0, getScaleXY, $wname3d
	endif
	if(displayImg)
		ATH_Display#NewImg(saveDF:$wname3d)
	endif
	return 0
End

static Function/WAVE WAVELoadDATFilesFromFolder(string folder, string pattern, [string wname3dStr, int autoscale])
	// We use ImageTransform stackImages X to create the 3d wave. Compared to 3d wave assignement it is faster by nearly 3x.

	/// Import .dat files that match a pattern from a folder. Waves are named after their filename.
	/// @param folder string folder of the .dat files
	/// @param pattern string pattern to filter .dat files, use "*" for all .dat files- empty string gives an error
	/// @param autoScale int optional scales the imported waves if not 0
	/// @param wname3dStr string optional name of the 3d wave, othewise defaults to ATH_w3d

	wname3dStr = SelectString(ParamIsDefault(wname3dStr) ? 0: 1,"", wname3dStr)

	folder = ParseFilePath(2, folder, ":", 0, 0) // We need the last ":"  in path!!!

	NewPath/Q/O ATH_DATFilesPathTMP, folder

	// Get all the .dat files. Use "????" for all files in IndexedFile third argument.
	// Filter the matches with pattern at the second stage.
	string allFiles = ListMatch(SortList(IndexedFile(ATH_DATFilesPathTMP, -1, ".dat"),";", 16), pattern)

	variable filesnr = ItemsInList(allFiles), i

	// If no files are selected (e.g match pattern return "") warn user
	if (!filesnr)
		Abort "No files match pattern: " + pattern
	endif

	string filenameBuffer, datafile2read, filenameStr, basenameStr
	
	if(!strlen(wname3dStr))
		basenameStr = ParseFilePath(0, folder, ":", 1, 0) // Use it to name the wave if wname3d = "
		wname3dStr = CreatedataObjectName(cwDFR, basenameStr, 1, 0, 1)
	else
		basenameStr = wname3dStr
		wname3dStr = CreatedataObjectName(cwDFR, basenameStr, 1, 0, 1)
	endif
		
	DFREF saveDF = GetDataFolderDFR()

	
	if(filesnr == 1)
		filenameBuffer = StringFromList(0, allFiles)
		datafile2read = folder + filenameBuffer
		wname3dStr = CreateDataObjectName(currDF, filenameBuffer, 1, 0, 1)
		WAVE wRef = WAVELoadSingleDATFile(datafile2read, wname3dStr)
		return wRef
	endif
	
	if(filesnr > 1)
		SetDataFolder NewFreeDataFolder()
		filenameBuffer = StringFromList(0, allFiles)
		datafile2read = folder + filenameBuffer
		WAVE wname = WAVELoadSingleDATFile(datafile2read, ("ATHWaveToStack_idx_" + num2str(0)), skipmetadata = 0)
		variable getScaleXY = NumberByKey("FOV(µm)", note(wname), ":", "\n")	
		wname3dStr = CreateDataObjectName(saveDF, wname3dStr, 1, 0, 1)
	endif
	
	// Now get all the files
	for(i = 1; i < filesnr; i += 1)
		filenameBuffer = StringFromList(i, allFiles)
		datafile2read = folder + filenameBuffer
		WAVE wname = WAVELoadSingleDATFile(datafile2read, ("ATHWaveToStack_idx_" + num2str(i)), skipmetadata = 1)
		filenameStr = ParseFilePath(3, datafile2read, ":", 0, 0)
		WAVE wname = WAVELoadSingleDATFile(datafile2read, filenameStr, skipmetadata = 0)
	endfor

	ImageTransform/NP=(filesnr) stackImages $"ATHWaveToStack_idx_0"
	WAVE M_Stack
	//Add a note to the 3dwave about which files have been loaded
	string note3d
	sprintf note3d, "Timestamp: %s\nFolder: %s\nFiles: %s\n",(date() + " " + time()), folder, allFiles
	Note/K M_Stack, note3d
	MoveWave M_Stack saveDF:$wname3dStr

	// It is assumed that all the imported waves have the same dimensions, use it to scale the 3d wave
	if(autoscale)
		SetScale/I x, 0, getScaleXY, saveDF:$wname3dStr
		SetScale/I y, 0, getScaleXY, saveDF:$wname3dStr
	endif
	KillPath/Z ATH_DATFilesPathTMP
	WAVE wRef = saveDF:$wname3dStr
	SetDataFolder saveDF
	return wRef
End

static Function LoadMultiplyDATFiles([int skipmetadata, int autoscale, int stack3d, int displayImg])
	/// Load multiply selected .dat files
	/// @param skipmetadata is optional and if set to a non-zero value it skips metadata.
	/// @param autoScale int optional scales the imported waves if not 0
	/// @param stack3d int optional stack imported images
	/// @param displayImg int optional display image only if stacked		
	/// Note: the selected wave are sort alphanumerically so the first on the list takes the 
	/// first name in filenames etc.
	
	skipmetadata = ParamIsDefault(skipmetadata) ? 0: skipmetadata // if set do not read metadata	
	autoScale = ParamIsDefault(autoScale) ? 0: autoScale
	stack3d = ParamIsDefault(stack3d) ? 0: stack3d
	displayImg = ParamIsDefault(displayImg) ? 0: displayImg

	variable numRef, i
    string loadFiles, filepathStr, basenameStr, fileStr0

	string message = "Select .dat files. \n"
	message += "Import overwrites waves with the same name."
	string fileFilters = "DAT File (*.dat):.dat;"
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
		WAVE wRef0 = WAVELoadSingleDATFile(fileStr0, "", skipmetadata = skipmetadata, autoscale = autoscale)
		basenameStr = ParseFilePath(0, fileStr0, ":", 1, 1) + "_S" // "_S" for selected files insted of the whole folder
		Rename wRef0, $"ImageToStack_0"
		for(i = 1; i < nrloadFiles; i++)
			WAVE wRef = WAVELoadSingleDATFile(StringFromList(i,loadFiles, "\r"), "", skipmetadata = skipmetadata, autoscale = 0)
			Rename wRef, $("ImageToStack_"+num2str(i))
		endfor
		ImageTransform/NP=(nrloadFiles) stackImages $"ImageToStack_0"
		WAVE M_Stack
		CopyScales wRef0, M_Stack
		string newWaveNameStr = CreateDataObjectName(saveDF, basenameStr, 1, 0, 1)
		Note M_Stack, ("Files loaded to " + newWaveNameStr + ":\n" + loadFiles)
		MoveWave M_Stack, saveDF:$newWaveNameStr
		SetDataFolder saveDF
		if(displayImg)
			ATH_Display#NewImg(saveDF:$newWaveNameStr)
		endif
	else
		for(i = 0; i < nrloadFiles; i++)
			LoadSingleDATFile(StringFromList(i,loadFiles, "\r"), "", skipmetadata = skipmetadata, autoscale = autoscale)
		endfor
	endif
	return 0
End

static Function/WAVE WAVELoadSingleCorruptedDATFile(string filepathStr, string waveNameStr, [int overwrite])
	///< Function to load a single Elmitec binary .dat file by skipping reading the metadata.
	/// We assume here that the image starts at sizeOfFile - kpixelsTVIPS^2 * 16
	/// @param filepathStr string filename (including) pathname.
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave.
	/// If "" the wave name is the filename without the path and extention.
	/// @param skipmetadata int optional and if set to a non-zero value it skips metadata.
	/// @return wave reference
	overwrite = ParamIsDefault(overwrite) ? 0: overwrite
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
			return $""
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
			return $""
		endif

		message = "Select .dat file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
	else
		Abort "Path for datafile not specified (check ATH_Uview#WAVELoadSingleDATFile)!"
	endif

	FStatus numRef
	// change here if needed
	variable imgSizeinBytes = kpixelsTVIPS^2 * 2
	variable ImageDataStart = V_logEOF - imgSizeinBytes
	FSetPos numRef, ImageDataStart

	//Now read the image [unsigned int 16-bit, /F=2 2 bytes per pixel]
	if(overwrite)
		Make/W/U/O/N=(kpixelsTVIPS, kpixelsTVIPS) $waveNameStr
		WAVE datWave = $waveNameStr
	else
		waveNameStr = CreateDataObjectName(GetDataFolderDFR(), waveNameStr, 1,0,1)
		Make/W/U/N=(kpixelsTVIPS, kpixelsTVIPS) $waveNameStr
		WAVE datWave = $waveNameStr
	endif
	FBinRead/F=2 numRef, datWave
	Close numRef

	return datwave
End

static Function LoadSingleCorruptedDATFile(string filepathStr, string waveNameStr, [int waveDataType, int overwrite])
	///< Function to load a single Elmitec binary .dat file by skipping reading the metadata.
	/// We assume here that the image starts at sizeOfFile - kpixelsTVIPS^2 * 2
	/// @param filepathStr string filename (including) pathname. 
	/// If "" a dialog opens to select the file.
	/// @param waveNameStr name of the imported wave. 
	/// If "" the wave name is the filename without the path and extention.
	/// @param skipmetadata int optional and if set to a non-zero value it skips metadata.
	/// @param waveDataType int optional and sets the Wavetype of the loaded wave to single 
	/// /S of double (= 1) or /D precision (= 2). Default is (=0) uint 16-bit
	/// @return wave reference
	
	waveDataType = ParamIsDefault(waveDataType) ? 0: waveDataType
	overwrite = ParamIsDefault(overwrite) ? 0: overwrite

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
   			return NaN
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
   			return NaN
   		endif
   		
		message = "Select .dat file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as filepathStr
	else
		Abort "Path for datafile not specified (check ATH_Uview#WAVELoadSingleDATFile)!"
	endif
		
	FStatus numRef
	// change here if needed
	variable imgSizeinBytes = kpixelsTVIPS^2 * 2 
	variable ImageDataStart = V_logEOF - imgSizeinBytes
	FSetPos numRef, ImageDataStart
		
	//Now read the image [unsigned int 16-bit, /F=2 2 bytes per pixel]
	if(overwrite)
		Make/W/U/O/N=(kpixelsTVIPS, kpixelsTVIPS) $waveNameStr
		WAVE datWave = $waveNameStr
	else
		waveNameStr = CreateDataObjectName(GetDataFolderDFR(), waveNameStr, 1,0,1)
		Make/W/U/N=(kpixelsTVIPS, kpixelsTVIPS) $waveNameStr
		WAVE datWave = $waveNameStr
	endif
		
	FBinRead/F=2 numRef, datWave
	Close numRef
	
	// Convert to SP or DP 	
	if(waveDataType == 1)
		Redimension/S datWave
	endif
	
	if(waveDataType == 2)
		Redimension/D datWave
	endif
	
	return 0
End
