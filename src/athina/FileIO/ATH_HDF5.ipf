#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion  = 9
#pragma ModuleName = ATH_HDF5
#pragma version = 1.01

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

/// @module ATH_HDF5
/// @brief Module ATH_HDF5.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH HDF5 functionality.


/// @function ListHDF5Groups
/// @brief Description of ListHDF5Groups.
/// @details
/// Auto-generated documentation stub for function `ListHDF5Groups`.
/// @returns Variable Return value.

static Function ListHDF5Groups()
	variable fileid_
	Open /D/R/T="HDF5" fileid_
	string filepathname = S_fileName
	if(!strlen(filepathname))
		Abort 
	endif
	HDF5OpenFile/R fileid_ as filepathname
	ListHDF5GroupsFID(fileid_)
End

static Function/S GetHDF5Groups()
	Variable fileid_
	String filepathname = GetHDF5SingleFilePath()
	HDF5OpenFile/R fileid_ as filepathname
	return GetHDF5GroupsFID(fileid_)
End

/// @function LoadHDF5File
/// @brief Description of LoadHDF5File.
/// @details
/// Auto-generated documentation stub for function `LoadHDF5File`.
/// @param filename Parameter filename.
/// @returns Variable Return value.

static Function LoadHDF5File(string filename)
	Variable fileid_
	HDF5OpenFile/R fileid_ as filename
	HDF5LoadGroup/R :, fileid_, "." // load all
	HDF5CloseFile fileid_
End

/// @function LoadHDF5SpecificGroups
/// @brief Description of LoadHDF5SpecificGroups.
/// @details
/// Auto-generated documentation stub for function `LoadHDF5SpecificGroups`.
/// @param groups Parameter groups.
/// @returns Variable Return value.

static Function LoadHDF5SpecificGroups(string groups)
	variable fileid_
	Open /D/R/T="HDF5" fileid_
	string filepathname = S_fileName
	if(!strlen(filepathname))
		Abort 
	endif
	HDF5OpenFile/R fileid_ as filepathname
	
	variable n_entries = ItemsInList(groups)
	variable ii = 0
	
	for(ii = 0; ii < n_entries; ii += 1)
		HDF5LoadGroup/R/T/Z :, fileid_, StringFromList(ii, groups)
	endfor
	
	HDF5CloseFile fileid_
End

/// @function LoadHDF5SpecificGroupsNamesIndexed
/// @brief Description of LoadHDF5SpecificGroupsNamesIndexed.
/// @details
/// Auto-generated documentation stub for function `LoadHDF5SpecificGroupsNamesIndexed`.
/// @param idxstr Parameter idxstr.
/// @param strFix] Parameter strFix].
/// @returns Variable Return value.

static Function LoadHDF5SpecificGroupsNamesIndexed(string idxstr, [string strFix])
	// String should be in the form "2-5,7,9-12,50"
	strFix = SelectString(ParamIsDefault(strFix), strFix, "")
	idxstr = ATH_String#ExpandRangeStr(idxstr)
	variable fileid_
	Open /D/R/T="HDF5" fileid_
	string filepathname = S_fileName
	if(!strlen(filepathname))
		Abort 
	endif
	HDF5OpenFile/R fileid_ as filepathname
	//PRM: Assume entryXX as group name, change here if needed 
	
	variable n_entries = ItemsInList(idxstr)
	variable ii = 0
	
	for(ii = 0; ii < n_entries; ii += 1)
		string groupname = strFix + StringFromList(ii, idxstr)
		HDF5LoadGroup/R/T/Z :, fileid_, groupname
	endfor
	
	HDF5CloseFile fileid_
End

/// @function LoadHDF5SpecificGroupsFromPath
/// @brief Description of LoadHDF5SpecificGroupsFromPath.
/// @details
/// Auto-generated documentation stub for function `LoadHDF5SpecificGroupsFromPath`.
/// @param groups Parameter groups.
/// @param filename_fullpathstr Parameter filename_fullpathstr.
/// @returns Variable Return value.

static Function LoadHDF5SpecificGroupsFromPath(String groups, String filename_fullpathstr)
	// String should be in the form "2-5,7,9-12,50"
	
	// Load files faster from a specific file, you need to specify the full path to the datafile.

	groups = ATH_String#ExpandRangeStr(groups)
	Variable fileid_
			
	HDF5OpenFile/R fileid_ as filename_fullpathstr
	
	//PRM: Assure entryXX as group name, change here if needed 
	
	Variable n_entries = ItemsInList(groups)
	Variable ii = 0
	
	for(ii = 0; ii < n_entries; ii += 1)
		String groupname = "entry" + StringFromList(ii, groups)
		HDF5LoadGroup/R/T/Z :, fileid_, groupname
	endfor
	
	HDF5CloseFile fileid_
End

/// Building blocks ///
static Function/S GetHDF5SingleFilePath()
	// Return a list of the full path of one selected HDF5 file
	Variable dummyid
	Open /D/R/T="HDF5" dummyid
	return S_fileName
End

/// @function ListHDF5GroupsFID
/// @brief Description of ListHDF5GroupsFID.
/// @details
/// Auto-generated documentation stub for function `ListHDF5GroupsFID`.
/// @param fileid Parameter fileid.
/// @returns Variable Return value.


static Function ListHDF5GroupsFID(Variable fileid)
	//Lists all entries in file
	HDF5ListGroup /TYPE=3 fileid, "."
	print SortList(S_HDF5ListGroup,";",16)
End

static Function/S GetHDF5GroupsFID(Variable fileid)
	//Return a list of all entries in file
	HDF5ListGroup /TYPE=1 fileid, "."
	return SortList(S_HDF5ListGroup,";",16)
End

/// @function LoadHDF5GroupFID
/// @brief Description of LoadHDF5GroupFID.
/// @details
/// Auto-generated documentation stub for function `LoadHDF5GroupFID`.
/// @param fileid Parameter fileid.
/// @param group Parameter group.
/// @returns Variable Return value.

static Function LoadHDF5GroupFID(Variable fileid, String group)
	HDF5LoadGroup/R :, fileid, group
End

/// @function GetHDF5NumGroupsFID
/// @brief Description of GetHDF5NumGroupsFID.
/// @details
/// Auto-generated documentation stub for function `GetHDF5NumGroupsFID`.
/// @param fileid Parameter fileid.
/// @returns Variable Return value.


static Function GetHDF5NumGroupsFID(Variable fileid)
	//Returns the number is entries in file
	HDF5ListGroup /TYPE=1 fileid, "."
	return  ItemsInList(S_HDF5ListGroup)
End

///Functions to import datasets acquired at the I06 beamline at Diamond (UK)

/// @function LoadNXSXMCDDataSet
/// @brief Description of LoadNXSXMCDDataSet.
/// @details
/// Auto-generated documentation stub for function `LoadNXSXMCDDataSet`.
/// @returns Variable Return value.

static Function LoadNXSXMCDDataSet()
	/// Load XMCD data acquired at i06 beamline at Diamond
	/// along with basic metadada, STV and FoV. Imported 
	/// waves are FoV-scaled
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	variable fileid_
	string fileFilters = "NXS files (*.nxs):.nxs;"
	fileFilters += "All Files:.*;"
	Open /D/R/F=fileFilters fileid_
	string filepathname = S_fileName
	if(!strlen(filepathname))
		Abort 
	endif
	HDF5OpenFile/R fileid_ as filepathname
	HDF5LoadGroup/R/T/Z :, fileid_, "entry"	
	HDF5CloseFile fileid_
	// Here S_filename should hold the filename
	string filename = StringFromList(0, S_filename, ".")
	// Make a folder to load all measurements
	NewDataFolder saveDF:$filename
	DFREF destDF = saveDF:$filename
	// We loaded the thingy, now let's extract data to a proper 3D wave
	WAVE wRef = :entry:medipix:data // here 
	
    variable rows = DimSize(wRef, 0)
    variable layers = DimSize(wRef, 2)
    variable chunks = DimSize(wRef, 3)
    variable i
    string wnameStr
    // Get FoV and STV
    variable fov, stv 
    ImageTransform/TM4D=8421 transpose4D wRef
    WAVE M_4DTranspose
	WAVE wFoV = :entry:instrument:leem:fov_a    
	WAVE wSTV = :entry:instrument:leem:stv	
	for(i = 0; i < rows; i++)
		wnameStr = filename + "_" + num2str(i)
		fov = wFoV[0]
		stv = wSTV[0]
		//stv = num2str(:entry:instrument:leem:stv[0])
		MatrixOP destDF:$wnameStr = chunk(M_4DTranspose, i)
		WAVE w = destDF:$wnameStr 
		SetScale/I x, 0, fov, w
		SetScale/I y, 0, fov, w
		Note w, ("STV(V):"+num2str(stv))
	endfor
	SetDataFolder saveDF
End

// Select many files to load at once

/// @function LoadNXSDataSets
/// @brief Description of LoadNXSDataSets.
/// @details
/// Auto-generated documentation stub for function `LoadNXSDataSets`.
/// @returns Variable Return value.
static Function LoadNXSDataSets()
	/// Load data acquired at i06 beamline at Diamond, XMCD or XAS
	/// along with basic metadada, STV and FoV.
	variable fileid_
	string fileFilters = "NXS files (*.nxs):.nxs;"
	fileFilters += "All Files:.*;"
	Open/D/R/MULT=1/F=fileFilters fileid_
	string filepaths = S_fileName
	if(!strlen(filepaths))
		Abort
	endif
	string filename, foldername, selFilePath, wnameStr
	variable numFiles = ItemsInList(filepaths, "\r"), i, j, rows
	
	DFREF saveDF = GetDataFolderDFR()	
	SetDataFolder NewFreeDataFolder()
	
	for(i = 0; i < numFiles; i++) 
		selFilePath = StringFromList(i, filepaths, "\r")
		HDF5OpenFile/R fileid_ as selFilePath
		HDF5LoadGroup/R/T/Z :, fileid_, "entry"
		HDF5CloseFile fileid_
		foldername = ParseFilePath(3, selFilePath,":", 0, 0) //StringFromList(i, selFilePath, ".")
		foldername = CreateDataObjectName(saveDF, foldername, 11, 0, 1)
		NewDataFolder saveDF:$foldername
		DFREF destDF = saveDF:$foldername
		WAVE wRef = :entry:medipix:data
		WAVE wFoV = :entry:instrument:leem:fov_a
		WAVE wSTV = :entry:instrument:leem:stv
		
		if(WaveDims(wRef) == 4) // Assume XMCD spectrum or similar?
			rows = DimSize(wRef, 0)
			variable fov, stv
			ImageTransform/TM4D=8421 transpose4D wRef
			WAVE M_4DTranspose
			for(j = 0; j < rows; j++)
				wnameStr = foldername + "_" + num2str(j)
				fov = wFoV[0]
				stv = wSTV[0]
				MatrixOP destDF:$wnameStr = chunk(M_4DTranspose, j)
				WAVE w = destDF:$wnameStr
				SetScale/I x, 0, fov, w
				SetScale/I y, 0, fov, w
				Note w, ("STV(V):"+num2str(stv))
			endfor
		elseif(WaveDims(wRef) == 3) // Assume XAS spectrum
			wnameStr = foldername + "_" + num2str(j)
			ImageTransform/G=4 transposeVol wRef
			WAVE M_VolumeTranspose
			MoveWave M_VolumeTranspose, destDF:$wnameStr 
			WAVE w = destDF:$wnameStr 
			WAVE wE = :entry:medipix:fastEnergy
			fov = wFoV[0]
			stv = wSTV[0]
			SetScale/I x, 0, fov, w
			SetScale/I y, 0, fov, w	
			SetScale/I z, wE[0], wE[numpnts(wE)-1], w
		else
			print "Unkown dataset in " + selFilePath
			return -1
		endif
		// Rename the folder here to avoid overwriting 
		RenameDataFolder :entry, $("dump" + num2str(i))
	endfor
	SetDataFolder saveDF
End

//// ------ MAXPEEM HDF5 files using TVIPS pipeline ------ /////
//// ------ Functions will be used in ATH_MAXPEEM  ------ /////

/// @function LoadTVIPSH5Data
/// @brief Description of LoadTVIPSH5Data.
/// @details
/// Auto-generated documentation stub for function `LoadTVIPSH5Data`.
/// @param filename Parameter filename.
/// @returns Variable Return value.

static Function LoadTVIPSH5Data(string filename)
	// Function to load the h5 datasets
	// Here we check whether the Path MAXPEEM_USER_ROOT_FOLDER is set.
	// If not, then the filename should be the filepath if you want to
	// load the file without opening the file browser.
	// Take care of UNC file paths on Windows (\\\\Server\\folder\\file) 
	
	variable fileid

	HDF5OpenFile/R fileid as filename
	// Use S_filename as you might not get filename correctly
	// and load the h5 with the file browser.
	HDF5LoadData/Q fileid, "/entry/instrument/tvips/data"
	HDF5CloseFile fileid
	WAVE data	
	string wname = CreateDataObjectName(GetDataFolderDFR(), \
				   ParseFilePath(3, S_fileName, "*", 0, 0), 1, 0, 1)
	if(DimSize(data,0) == 1) // You have a single image
		Redimension/E=1/N=(DimSize(data,1), DimSize(data,2)) data
		Rename data, $wname
	else
		ImageTransform/G=3 transposeVol data
		WAVE M_VolumeTranspose
		Rename M_VolumeTranspose, $wname
	endif
	KillWaves/Z data
	// Metadata
	string waveNoteStr = S_Path + S_filename
	Note $wname, waveNoteStr
	return 0
End

/// @function LoadTVIPSH5Group
/// @brief Description of LoadTVIPSH5Group.
/// @details
/// Auto-generated documentation stub for function `LoadTVIPSH5Group`.
/// @param filename Parameter filename.
/// @param group] Parameter group].
/// @returns Variable Return value.

static Function LoadTVIPSH5Group(string filename, [string group])
	// Function to load the h5 datasets
	// Here we check whether the Path MAXPEEM_USER_ROOT_FOLDER is set.
	// If not, then the filename should be the filepath if you want to
	// load the file without opening the file browser.
	// Take care of UNC file paths on Windows (\\\\Server\\folder\\file) 
	
	variable fileid
	group = SelectString(ParamIsDefault(group), group, "entry")
	HDF5OpenFile/R fileid as filename
	// Use S_filename as you might not get filename correctly
	// and load the h5 with the file browser.
	HDF5LoadGroup/T/Q :, fileid, group
	HDF5CloseFile fileid
	return 0
End

/// @function LoadTVIPSH5DataNetwork
/// @brief Description of LoadTVIPSH5DataNetwork.
/// @details
/// Auto-generated documentation stub for function `LoadTVIPSH5DataNetwork`.
/// @param scanID Parameter scanID.
/// @returns Variable Return value.

static Function LoadTVIPSH5DataNetwork(variable scanID)
	// Function to load the h5 datasets
	// Here we check whether the Path MAXPEEM_USER_ROOT_FOLDER is set.
	// If not, then the filename should be the filepath if you want to
	// load the file without opening the file browser.
	// Take care of UNC file paths on Windows (\\\\Server\\folder\\file) 
	
	variable fileid
	PathInfo MAXPEEM_USER_ROOT_FOLDER 
	if(V_flag)
		string filename = "scan-"+num2str(scanID)+".h5"
	endif
	HDF5OpenFile/R/P=MAXPEEM_USER_ROOT_FOLDER fileid as filename
	HDF5LoadData/Q fileid, "/entry/instrument/tvips/data"
	HDF5CloseFile fileid
	WAVE data	
	HDF5CloseFile fileid
	string wname = CreateDataObjectName(GetDataFolderDFR(),"w"+num2str(scanID), 1, 0, 1)	
	if(DimSize(data,0) == 1) // You have a single image
		Redimension/E=1/N=(DimSize(data,1), DimSize(data,2)) data
		Rename data, $wname
	else
		ImageTransform/G=3 transposeVol data
		WAVE M_VolumeTranspose
		Rename M_VolumeTranspose, $wname
	endif
	KillWaves/Z data
	// Metadata
	string waveNoteStr = S_Path+filename
	Note $wname, waveNoteStr
	return 0
End