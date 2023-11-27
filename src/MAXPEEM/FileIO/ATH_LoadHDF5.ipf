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

// Read metadata of the beamline settings

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

static Function LoadHDF5File()
	Variable fileid_
	String filepathname = GetHDF5SingleFilePath()
	HDF5OpenFile/R fileid_ as filepathname
	HDF5LoadGroup/R :, fileid_, "." // load all
	print "HDF5 file ~", filepathname, "~ loaded."
	HDF5CloseFile fileid_
End

static Function LoadHDF5SpecificGroups(string groups)
	// String should be in the form "2-5,7,9-12,50"
	groups = ATH_String#ExpandRangeStr(groups)
	variable fileid_
	Open /D/R/T="HDF5" fileid_
	string filepathname = S_fileName
	if(!strlen(filepathname))
		Abort 
	endif
	HDF5OpenFile/R fileid_ as filepathname
	//PRM: Assure entryXX as group name, change here if needed 
	
	variable n_entries = ItemsInList(groups)
	variable ii = 0
	
	for(ii = 0; ii < n_entries; ii += 1)
		string groupname = "entry" + StringFromList(ii, groups)
		HDF5LoadGroup/R/T/Z :, fileid_, groupname
	endfor
	
	HDF5CloseFile fileid_
End

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

static Function LoadHDF5GroupFID(Variable fileid, String group)
	HDF5LoadGroup/R :, fileid, group
End


static Function GetHDF5NumGroupsFID(Variable fileid)
	//Returns the number is entries in file
	HDF5ListGroup /TYPE=1 fileid, "."
	return  ItemsInList(S_HDF5ListGroup)
End

///Functions to import datasets acquired at the I06 beamline at Diamond (UK)

static Function LoadDiamondHDFDataSet()
	/// Load data acquired at i06 beamline at Diamond
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	variable fileid_
	string fileFilters = "HDF files (*.hdf):.hdf;"
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
	WAVE wRef = :entry:data:data // here 
	
    variable rows = DimSize(wRef, 0)
    variable layers = DimSize(wRef, 2)
    variable chunks = DimSize(wRef, 3)
    variable type = WaveType(wRef)	
    variable i
    string wnameStr
    ImageTransform/TM4D=4821 transpose4D wRef
    WAVE M_4DTranspose
	for(i = 0; i < rows; i++)
		wnameStr = filename + "_" + num2str(i)
		MatrixOP destDF:$wnameStr = chunk(M_4DTranspose, i)
	endfor
	SetDataFolder saveDF
End

static Function LoadDiamondNXSDataSet()
	/// Load data acquired at i06 beamline at Diamond
	/// along with basic metadada, STV and FoV. Imported 
	/// waves are scaled using FoV
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
static Function LoadMultiplyDiamondNXSDataSets()
	/// Load data acquired at i06 beamline at Diamond
	/// along with basic metadada, STV and FoV. Imported
	/// waves are scaled using FoV
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
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
		rows = DimSize(wRef, 0)
		variable fov, stv
		ImageTransform/TM4D=8421 transpose4D wRef
		WAVE M_4DTranspose
		WAVE wFoV = :entry:instrument:leem:fov_a
		WAVE wSTV = :entry:instrument:leem:stv
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
		// Rename the folder here to avoid overwriting 
		RenameDataFolder :entry, $("dump" + num2str(i))
	endfor
	SetDataFolder saveDF
End
