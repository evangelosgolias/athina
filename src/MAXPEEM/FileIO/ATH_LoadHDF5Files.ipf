﻿#pragma TextEncoding = "UTF-8"
#pragma IgorVersion  = 9
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

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

Function ATH_ListHDF5Groups()
	variable fileid_
	Open /D/R/T="HDF5" fileid_
	string filepathname = S_fileName
	if(!strlen(filepathname))
		Abort 
	endif
	HDF5OpenFile/R fileid_ as filepathname
	print filepathname
	ATH_ListHDF5GroupsFID(fileid_)
End

Function/S ATH_GetHDF5Groups()
	Variable fileid_
	String filepathname = ATH_GetHDF5SingleFilePath()
	HDF5OpenFile/R fileid_ as filepathname
	return ATH_GetHDF5GroupsFID(fileid_)
End

Function ATH_LoadHDF5File()
	Variable fileid_
	String filepathname = ATH_GetHDF5SingleFilePath()
	HDF5OpenFile/R fileid_ as filepathname
	HDF5LoadGroup/R :, fileid_, "." // load all
	print "HDF5 file ~", filepathname, "~ loaded."
	HDF5CloseFile fileid_
End

Function ATH_LoadHDF5SpecificGroups(string groups)
	// String should be in the form "2-5,7,9-12,50"
	groups = ATH_ExpandRangeStr(groups)
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

Function ATH_LoadHDF5SpecificGroupsFromPath(String groups, String filename_fullpathstr)
	// String should be in the form "2-5,7,9-12,50"
	
	// Load files faster from a specific file, you need to specify the full path to the datafile.

	groups = ATH_ExpandRangeStr(groups)
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
Function/S ATH_GetHDF5SingleFilePath()
	// Return a list of the full path of one selected HDF5 file
	Variable dummyid
	Open /D/R/T="HDF5" dummyid
	return S_fileName
End


Function ATH_ListHDF5GroupsFID(Variable fileid)
	//Lists all entries in file
	HDF5ListGroup /TYPE=3 fileid, "."
	print SortList(S_HDF5ListGroup,";",16)
End

Function/S ATH_GetHDF5GroupsFID(Variable fileid)
	//Return a list of all entries in file
	HDF5ListGroup /TYPE=1 fileid, "."
	return SortList(S_HDF5ListGroup,";",16)
End

Function ATH_LoadHDF5GroupFID(Variable fileid, String group)
	HDF5LoadGroup/R :, fileid, group
End


Function ATH_GetHDF5NumGroupsFID(Variable fileid)
	//Returns the number is entries in file
	HDF5ListGroup /TYPE=1 fileid, "."
	return  ItemsInList(S_HDF5ListGroup)
End