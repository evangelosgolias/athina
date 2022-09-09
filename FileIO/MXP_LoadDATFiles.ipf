﻿#pragma rtGlobals    = 3
#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma rtFunctionErrors=1
#pragma DefaultTab	= {3,20,4}			// Set default tab width in Igor Pro 9 and later

// ------------------------------------------------------- //
// Functions to import binary .dat files written by the Uview Software from Elmitec
// of the MAXPEEM beamline of MAX IV.
//
// Developed by Evangelos Golias.
// Contact: evangelos.golias@maxiv.lu.se
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
//THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// ------------------------------------------------------- //
// v1.0
//
// The function/Wave MPMXP_ImportImageFromSingleDatFile(DataFile, FileNameStr) import a 2D wave from a
// single .dat file created by UKSOFT2001 software in the MAXPEEM beamline.
// MXP_ImportImageFromSingleDatFile calls the MPReadUKMetadataBlock(wv) function to get a string
// of the Frame's metadata.
//

// Add to menu

Menu "MAXPEEM", hideable
	"Load .dat file .../1", MXP_LoadSingleDATFile("","")
	"Load multiply .dat files .../2", MXP_LoadMultiplyDATFiles("")
	"Load files from folder .../3",  MXP_LoadDATFilesFromFolder("", "*")
End


// Constants definitions

// End of constants definitions

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

    
    if(StringMatch(fileNameStr,"*.dat") && fileKind == 7) // Igor thinks that the .dat file is a General text (fileKind == 7)
        PathInfo $pathNameStr
        string fileToOpen = S_path + fileNameStr
        try
        MXP_LoadSingleDATFile(fileToOpen, "")
        AbortOnRTE
        catch
        	print "Are you sure you are not trying to load a text file with .dat extention?"
        	Abort
        endtry
        return 1
    endif
    return 0
End

///< Function to load a single Elmitec binary .dat file.
/// @param datafile string filename (including) pathname. 
/// If "" a dialog opens to select the file.
/// @param FileNameStr name of the imported wave. 
/// If "" the wave name is the filename without the path and extention.
/// @param skipmetadata is optional and if set to a non-zero value it skips metadata.
/// @return wave reference
		

Function/WAVE MXP_LoadSingleDATFile(string datafile, string FileNameStr, [int skipmetadata])
	
	skipmetadata = ParamIsDefault(skipmetadata) ? 0: skipmetadata // if set do not read metadata
	
	variable numRef
	string separatorchar = ":"
	string fileFilters = "dat File (*.dat):.dat;"
	fileFilters += "All Files:.*;"

   if (!strlen(datafile) && !strlen(FileNameStr)) 
		string message = "Select .dat file. \nFilename will be wave's name. (overwrite)\n "
   		Open/F=fileFilters/M=message/D/R numref
   		datafile = S_filename
   		
   		if(!strlen(datafile)) // user cancel?
   			Abort
   		endif

   		Open/F=fileFilters/R numRef as datafile
		FileNameStr = ParseFilePath(3, datafile, separatorchar, 0, 0)
		
	elseif (strlen(datafile) && !strlen(FileNameStr))
		message = "Select .dat file. \nWave names are filenames /O.\n "
		Open/F=fileFilters/R numRef as datafile
		FileNameStr = ParseFilePath(3, datafile, separatorchar, 0, 0)
		
	elseif (strlen(datafile) && strlen(FileNameStr))
		Open/R numRef as datafile
	else
		Abort "Path for datafile not specified (check MXP_ImportImageFromSingleDatFile)!"
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
	Make/W/U/O/N=(MXPFileHeader.ImageWidth, MXPFileHeader.ImageHeight) $FileNameStr /WAVE=datWave
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
		string mdatastr = datafile + "\n"
		mdatastr += "Time stamp: " + Secs2Date(timestamp, -2) + " " + Secs2Time(timestamp, 3) + "\n"
		mdatastr += MXP_StrGetBasicMetadataInfoFromDAT(datafile, MetadataStart, ImageDataStart)
	endif
	
	// Add image markups if any
	if(MXPImageHeader.attachedMarkupSize)
		mdatastr += MXP_StrGetImageMarkups(datafile)
	endif
	
	Note/K datWave, mdatastr
	return datWave
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
		// address-name(str)-unit(ASCII digit)-0-value(float)
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
		elseif(buffer == 106) // C1G1
			FReadLine /T=(num2char(0)) numRef, strbuffer 
			MXPMetaDataStr += "MCH" // MAXPEEM naming conversion
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 107) // C1G2
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "COL" // MAXPEEM naming conversion
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 108) // C2G1 not used at MAXPEEM
			FReadLine /T=(num2char(0)) numRef, strbuffer
			//MXPMetaDataStr += strbuffer
			FReadLine /T=(num2char(0)) numRef, strbuffer
			//MXPMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			//MXPMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 109) // C2G1
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "PCH" // MAXPEEM naming conversion
			FReadLine /T=(num2char(0)) numRef, strbuffer
			MXPMetaDataStr += "(" + strbuffer + "):"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += num2str(buffer) + "\n"
		elseif(buffer == 110)
			FReadLine /T=(num2char(09))/ENCG={3,3,1} numRef, strbuffer // ascii tab = 09
			FBinRead/F=4 numRef, buffer // drop FOV calculation factor
			MXPMetaDataStr += "FOV:" + strbuffer + "\n"
			FReadLine /T=(num2char(0)) numRef, strbuffer // read until you hit num2char(0)
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
	
	return MXPMetaDataStr
End

Function/S MXP_StrGetImageMarkups(string filename)
	/// Read markups from a dat file. Then generate a list containing the markups parameters (positions, \
	///  \size, color,line thickness, text), copied from https://github.com/euaruksakul/SLRILEEMPEEMAnalysis
	
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
	fsetpos refNum, (126 + attachedRecipeSize)
	fbinread /F=2 refNum, attachedMarkupSize
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
		string markupsList = ""
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
				
				sprintf markupsString,"Markups: %u,%u,%u,%u,%u,%u,%u,%u,%s;",markup_x, markup_y, markup_radius, markup_color_R, markup_color_G, markup_color_B, markup_type, markup_lSize, markup_text
				markupsList += markupsString
			endif
		while (marker != 0)
	endif
	
	Close refNum
	return markupsList
End

Function MXP_LoadDATFilesFromFolder(string folder, string pattern, [int stack3d, string wname3d])

	/// Import .dat files that match a pattern from a folder. Waves are named after their filename.
	/// @param folder string folder of the .dat files
	/// @param pattern string pattern to filter .dat files, use "*" for all .dat files- empty string gives an error
	/// @param stack3d int optional stack imported .dat files to the 3d wave, kill the imported waves
	/// @param wname3d string optional name of the 3d wave, othewise defaults to MXP_w3d

	stack3d = ParamIsDefault(stack3d) ? 0: stack3d
	wname3d = SelectString(ParamIsDefault(wname3d) ? 0: 1,"MXP_w3d", wname3d)
	
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

	// Handle the case where the 3d wave exists and find an appropriate name
	if(stack3d && exists(wname3d) == 1)
		do
		printf "Wave %s exists in %s renaming to %s\n", wname3d, GetDataFolder(1), (wname3d + "_n")
		wname3d += "_new"
		while(exists(wname3d) == 1)
	endif
	
	string fnameBuffer
	variable ii	
	for(ii = 0; ii < filesnr; ii += 1)
		fnameBuffer = StringFromList(ii, allFiles)
		string datafile2read = folder + fnameBuffer
		if(stack3d) // Skip the metadata if you load to a 3dwave
			Wave wname = MXP_LoadSingleDATFile(datafile2read, "", skipmetadata = 1)
		else
			Wave wname = MXP_LoadSingleDATFile(datafile2read, "", skipmetadata = 0)
		endif
	endfor

	// It is assumed that all the imported waves have the same dimensions
	variable nx = DimSize(wname, 0)
	variable ny = DimSize(wname, 1)
	if (stack3d)
		Make/N=(nx, ny, filesnr) $wname3d /Wave=w3dref
		string bufferWaveName
		for(ii = 0; ii < filesnr; ii++)
			bufferWaveName = RemoveEnding(StringFromList(ii, allFiles), ".dat") // allfiles: filename.dat
			Wave w2dref = $(bufferWaveName)
			w3dref[][][ii] = w2dref[p][q]
			KillWaves/Z $(bufferWaveName)
		endfor
		//Add a note to the 3dwave about which files have been loaded
		string note3d
		sprintf note3d, "Timestamp: %s\nFolder: %s\nFiles: %s\n",(date() + " " + time()), folder, allFiles
		Note/K w3dref, note3d
	endif
	KillPath/Z MXP_DATFilesPathTMP
End



Function MXP_LoadMultiplyDATFiles(string datafile, [string filenames, int skipmetadata])
	/// Load multiply selected .dat files
	/// @param datafile string Location of the files you want to load, if "" a dialog will pop	
	/// @param filenames string optional string separated by ";". If you provide filenames and the
	/// number of selected files  match the number of names in string then use then as wave names.
	/// @param skipmetadata is optional and if set to a non-zero value it skips metadata.
	/// Note: the selected wave are sort alphanumerically so the first on the list takes the 
	/// first name in filenames etc.
	
	filenames = SelectString(ParamIsDefault(filenames) ? 0: 1,"", filenames)
	skipmetadata = ParamIsDefault(skipmetadata) ? 0: skipmetadata // if set do not read metadata	
	
	variable numRef
    string loadFiles

	string message = "Select .dat files. \nFilenames define the wave names.\n"
	message += "Import overwrites waves with the same name."
	string fileFilters = "DAT File (*.dat):.dat;"
	fileFilters += "All Files:.*;"

	// Open multi-selection File dialog
	// S_fileName contains all the selected files seperates with CR
	Open/D/R/MULT=1/F=fileFilters/M=message numRef 
	loadFiles = SortList(S_fileName, "\r", 16) 
	variable nrloadFiles = ItemsInList(loadFiles, "\r")
	variable nrFilenames = ItemsInList(filenames)
	
	variable ii = 0
	for(ii = 0; ii < nrloadFiles; ii += 1)
		if (nrloadFiles == nrFilenames)
			MXP_LoadSingleDATFile(StringFromList(ii,loadFiles, "\r"), StringFromList(ii,filenames), skipmetadata = skipmetadata)
		else
			MXP_LoadSingleDATFile(StringFromList(ii,loadFiles, "\r"), StringFromList(ii,filenames), skipmetadata = skipmetadata)
		endif
	endfor

End

Function MXP_AppendMarkupsToTopImage()
	/// Draw the markups on an image display (drawn on the UserFront layer)
	/// function based on https://github.com/euaruksakul/SLRILEEMPEEMAnalysis
	/// markups are drawn on the top graph
	string imgNamestr = StringFromList(0,ImageNameList("",";"))
	wave w = ImageNameToWaveRef("", imgNamestr)
	string graphName = WinName(0, 1)
	// Newlines and line feeds create problems with StringByKey, replace with ;
	string markupsList = StringByKey("Markups", ReplaceString("\n",note(w), ";"))
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
	
	variable ii = 0
	string xAxis = ""
	
	SetDrawLayer /W=$graphName userFront
	
	// Check whether the image is created from 'NewImage' or 'Display' commands (i.e. whether the top or bottom axis is used)
	if (WhichListItem("bottom",AxisList(GraphName),";") != -1)
		xAxis = "bottom"
	else
		xAxis = "top"
	endif
	
	for(ii = 0; ii < ItemsInList(markupsList, ";"); ii++)
		markup = StringFromList(ii, markupsList, ";")
		markup_x = str2num(StringFromList(0, markup, ","))
		markup_y = str2num(StringFromList(1, markup, ","))
		markup_radius = str2num(StringFromList(2, markup, ","))
		markup_color_R = str2num(StringFromList(3, markup, ","))
		markup_color_G = str2num(StringFromList(4, markup, ","))
		markup_color_B = str2num(StringFromList(5, markup, ","))
		markup_lsize = str2num(StringFromList(7, markup, ","))
		markup_text = StringFromList(8, markup, ",")		
		SetDrawEnv/W=$GraphName fillpat = 0,linefgc = (markup_color_R, markup_color_G, markup_color_B), linethick = markup_lsize, ycoord = left, xcoord = $xAxis
		DrawOval/W=$GraphName markup_x - markup_radius, markup_y - markup_radius, markup_x + markup_radius, markup_y + markup_radius
		SetDrawEnv/W=$GraphName fsize = 16, textRGB = (markup_color_R, markup_color_G, markup_color_B), textxjust = 1, textyjust = 1, ycoord = left, xcoord = $xAxis
		DrawText/W=$GraphName markup_x, markup_y, markup_text
	endfor
	
End

// TODO: Fix this fuction
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
			MXPMetaDataStr += ":" + num2str(buffer) + ";"
			
		elseif(buffer == 100)
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "X(mm):" + num2str(buffer) + ";"
			FBinRead/F=4 numRef, buffer
			MXPMetaDataStr += "Y(mm):" + num2str(buffer) + ";"
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
		elseif(buffer == 106) // C1G1				// TODO: Fix the name of gauges for MAXPEEM
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
			FReadLine /T=(num2char(09))/ENCG={3,3,1} numRef, strbuffer // ascii tab = 09
			FBinRead/F=4 numRef, buffer // drop FOV calculation factor
			MXPMetaDataStr += "FOV:" + strbuffer + ";"
			FReadLine /T=(num2char(0)) numRef, strbuffer // read until you hit num2char(0)
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
	
	return MXPMetaDataStr
End