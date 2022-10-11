#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// This code is meant to deal only with the metada files saved in the MAXPEEM beamline. 

Function EG_ListHDF5Groups()
	Variable fileid_
	String filepath = MXP_GetHDF5SingleFilePath()
	HDF5OpenFile/R fileid_ as filepath
	print filepath
	MXP_ListHDF5GroupsFID(fileid_)
End

Function/S EG_GetHDF5Groups()
	Variable fileid_
	String filepathname = MXP_GetHDF5SingleFilePath()
	HDF5OpenFile/R fileid_ as filepathname
	return MXP_GetHDF5GroupsFID(fileid_)
End

Function EG_LoadHDF5File()
	Variable fileid_
	String filepathname = MXP_GetHDF5SingleFilePath()
	HDF5OpenFile/R fileid_ as filepathname
	HDF5LoadGroup/R :, fileid_, "." // load all
	print "HDF5 file ~", filepathname, "~ loaded."
	HDF5CloseFile fileid_
End

Function EG_LoadHDF5SpecificGroups(String groups)
	// String should be in the form "2-5,7,9-12,50"
	groups = MXP_StrExpandRange(groups)
	Variable fileid_
	String filepathname = MXP_GetHDF5SingleFilePath()
	HDF5OpenFile/R fileid_ as filepathname
	
	//PRM: Assure entryXX as group name, change here if needed 
	
	Variable n_entries = ItemsInList(groups)
	Variable ii = 0
	
	for(ii = 0; ii < n_entries; ii += 1)
		String groupname = "entry" + StringFromList(ii, groups)
		HDF5LoadGroup/R/T/Z :, fileid_, groupname
	endfor
	
	HDF5CloseFile fileid_
End

Function MXP_LoadHDF5SpecificGroupsFromPath(String groups, String filename_fullpathstr)
	// String should be in the form "2-5,7,9-12,50"
	
	// Load files faster from a specific file, you need to specify the full path to the datafile.

	groups = MXP_StrExpandRange(groups)
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



//----------------------------------------------------------------
//---------------- Building blocks- ------------------------------
//TODO: Add code when you cancel instaed of selecting a file


Function/S MXP_GetHDF5SingleFilePath()
	// Return a list of the full path of one selected HDF5 file
	Variable dummyid
	Open /D/R/T="HDF5" dummyid
	return S_fileName
End


Function MXP_ListHDF5GroupsFID(Variable fileid)
	//Lists all entries in file
	HDF5ListGroup /TYPE=3 fileid, "."
	print SortList(S_HDF5ListGroup,";",16)
End

Function/S MXP_GetHDF5GroupsFID(Variable fileid)
	//Return a list of all entries in file
	HDF5ListGroup /TYPE=1 fileid, "."
	return SortList(S_HDF5ListGroup,";",16)
End

Function MXP_LoadHDF5GroupFID(Variable fileid, String group)
	HDF5LoadGroup/R :, fileid, group
End


Function MXP_GetHDF5NumGroupsFID(Variable fileid)
	//Returns the number is entries in file
	HDF5ListGroup /TYPE=1 fileid, "."
	return  ItemsInList(S_HDF5ListGroup)
End
//----------------------------------------------------------------
//----------------------------------------------------------------


//----------------------------------------------------------------
//------------------- Future extentions --------------------------

Function/S MXP_GetHDF5MultipleFilePaths()
	// Return a list of the full paths of selected HDF5 files
	Variable dummyid
	Open /D/R/MULT=1/T="HDF5" dummyid
	return ReplaceString("\r", S_fileName,";") // Replace CR with semicolon
End

Function MXP_OpenHDF5FilesWithBrowser([Variable InFolders]) //TODO: Future extention
	// Select and load HDF5 files 
	String filelist = MXP_GetHDF5MultipleFilePaths()
	
	//Here open files recursively and store different fileIDs in different variable 
	//HDF5OpenFile /R fileid as ""
End

//----------------------------------------------------------------
//------------------------ Utilities -----------------------------


Function/S MXP_StrExpandRange(string range)	// expand a string like "2-5,7,9-12,50" to "2,3,4,5,7,9,10,11,12,50"

	variable i1, i2, i 
	string str, out=""
	variable N = ItemsInList(range,",")
	if (N < 1)
		return ""
	endif
	variable j = 0
	do
		str = StringFromList(j, range, ",")
		Variable m = -1				// remove any leading white space
		do
			m += 1
		while (char2num(str[m])<=32)
		str = str[m,strlen(str)-1]

		// now check str to see if it is a range like "20-23"
		i1 = str2num(str)
		i = strsearch(str,"-",strlen(num2str(i1)))		// position of "-" after first number
		if (i>0)
			i2 = str2num(str[i+1,inf])
			i = i1
			do
				out += num2str(i)+";"
				i += 1
			while (i<=i2)
		else
			out += num2str(i1)+";"
		endif
		j += 1
	while (j < N)
	
	return out
End
