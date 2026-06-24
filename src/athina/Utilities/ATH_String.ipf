#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_String
#pragma version = 1.1

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

/// @module ATH_String
/// @brief Module ATH_String.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH String functionality.

/// @function ExpandRangeStr
/// @brief Expand a compact integer-range expression into an Igor string list.
/// @details
/// Expand a string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50" now check str to see if it is a range
/// like "20-23".
/// @param rangeStr Range str.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S ExpandRangeStr(string rangeStr)	
	// expand a string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50"

	variable i1, i2, i 
	string str, outStr = ""
	variable N = ItemsInList(rangeStr,",")
	if (N < 1)
		return ""
	endif
	variable j = 0
	do
		str = TrimString(StringFromList(j, rangeStr, ","))

		// now check str to see if it is a range like "20-23"
		i1 = str2num(str)
		i = strsearch(str,"-",strlen(num2str(i1)))		// position of "-" after first number
		if (i > 0)
			i2 = str2num(str[i+1,inf])
			i = i1
			do
				outStr += num2str(i)+";"
				i += 1
			while (i <= i2)
		else
			outStr += num2str(i1)+";"
		endif
		j += 1
	while (j < N)
	
	return SortList(outStr,";", 34) // remove duplicates and sorts
End

/// @function GetPhotonEnergyFromFilename
/// @brief Return photon energy from filename.
/// @details
/// MAXPEEM specific: extract the photon energy from the filename and return it as number regex compiles the
/// most common ways of writing the energy in a filename.
/// @param nameStr Name str.
/// @returns The returned value is photon energy from filename.
static Function GetPhotonEnergyFromFilename(string nameStr)
	// MAXPEEM specific: extract the photon energy from the filename and return it as number
	// regex compiles the most  common ways of writing the energy in a filename.
	string regex = "\s*(hv\s*=|hn\s*=|hn|hv)\s*([0-9]*[.]?[0-9]+)(\s*eV|\s*)"
	string prefix, energy, suffix
	SplitString/E=regex nameStr, prefix, energy, suffix
	if(V_flag)
		return str2num(energy)
	endif
	return 0
End

// Dev -- needs testing

/// @function UniquifyStringList
/// @brief Remove duplicate items from a delimited string list.
/// @details
/// Remove duplicates from a sting list. Remove duplicates.
/// @param stringListStr Text containing the string list str.
/// @param sep Delimiter used between list items.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S UniquifyStringList(string stringListStr, string sep)	
	// Remove duplicates from a sting list
	WAVE/T textW = ATH_TWave#StringListToTextWave(stringListStr, sep)
	//Remove duplicates
	if(DimSize(textW, 0) > 1)
		FindDuplicates/FREE/RT=textWSet textW // Error if only one element
		return ATH_TWave#TextWaveTostring(textWSet, sep = sep)
	else
		return stringListStr
	endif
	
End

/// @function isLiberalQ
/// @brief Test whether a string is invalid as an Igor liberal object name.
/// @details
/// Checks if a string is liberal. Returns 0 for empty string.
/// @param str Text containing the str.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function isLiberalQ(string str)
	// Checks if a string is liberal.
	// Returns 0 for empty string
	string regex = "^[a-zA-Z]{1}[a-zA-Z0-9_]+$"
	if(GrepString(str, regex) || !strlen(str))
		return 0
	else
		return 1
	endif
End

/// @function StringToNonLiberal
/// @brief Convert arbitrary text into a valid Igor liberal object name.
/// @param str Text containing the str.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S StringToNonLiberal(string str)
	if(ATH_String#IsLiberalQ(str))
		variable imax = strlen(str), i
		string regex = "[^a-zA-Z0-9_]", regex0 = "[^a-zA-Z]", nlstr=""
		if(GrepString(str[0], regex0))
			nlstr+="w"
		endif
		for(i=0; i<imax; i++)
			if(GrepString(str[i], regex))
				nlstr+="_"
			else
				nlstr+=str[i]
			endif
		endfor
		return nlstr
	endif
	return str
End

/// @function isEXTWindow
/// @brief Test whether a window name identifies an external window.
/// @param str Text containing the str.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function isEXTWindow(string str)
	// Is s the same of an EXT window, GraphXX#ExtWindowName
	return strsearch(str, "#", 0) != -1
End

/// @function isPathStringLegalQ
/// @brief Test whether a string is a syntactically valid Igor data-folder path.
/// @param path Path.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function isPathStringLegalQ(string path)
	variable steps = ItemsInlist(path, ":"), i
	string str
	for(i = 0; i < steps ; i++)
		str = StringFromList(i, path, ":")
		
		if(ATH_String#isLiberalQ(str) && (cmpstr(str[0],"'") || cmpstr(str[strlen(str)-1],"'")) )
			return 0
		endif
	endfor
	return 1
End

/// @function ExtendPathStr
/// @brief Append a child component to an Igor data-folder path.
/// @details
/// Add ext to s, which is usually a full path to a wave. Works for liberal and proper paths. Add
/// ksATHBackupWaveExtention to the root:'2434w' -> root:'2434w_undo' !.
/// @param str Text containing the str.
/// @param ext File-name extension.
/// @returns The resulting path string, or an empty string when it cannot be determined.
static Function/S ExtendPathStr(string str, string ext)
	// Add ext to s, which is usually a full path to a wave
	// Works for liberal and proper paths
	// For example:
	// Add ksATHBackupWaveExtention to the root:'2434w' -> root:'2434w_undo' !

	if(!cmpstr(str[strlen(str) - 1], "'"))
		return RemoveEnding(str, "'") + ext + "'"
	else
		return str+ext
	endif
End

/// @function InsertListAtPosition
/// @brief Insert list at position.
/// @details
/// We insert list insertList at the position pos of listStr. the element at pos is moved and becomes the
/// first after the last element of insertList.
/// @param listStr Text containing the list str.
/// @param insertList List of items to insert.
/// @param pos Zero-based insertion position.
/// @param sep (optional) Delimiter used between list items.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S InsertListAtPosition(string listStr, string insertList, variable pos, [string sep])
	// We insert list insertList at the position pos of listStr.
	// the element at pos is moved and becomes the first after the 
	// last element of insertList
	sep = SelectString(ParamIsDefault(sep) ? 0: 1, ";", sep)
	WAVE/T twList = ATH_TWave#StringListToTextWave(listStr, sep) 
	WAVE/T twInsList = ATH_TWave#StringListToTextWave(insertList, sep)
	variable nptsL = numpnts(twList), nptsI = numpnts(twInsList)
	if(pos > nptsL)
		Concatenate/FREE {twList, twInsList}, freeList
	elseif(!pos)
		Concatenate/FREE {twInsList, twList}, freeList
	else
		Make/T/FREE/N=(pos) freeL1 
		Make/T/FREE/N=(nptsL-pos) freeL2 		
		freeL1 = twList[p]
		freeL2 = twList[pos+p]
		Concatenate/FREE {freeL1, twInsList ,freeL2}, freeList
	endif
	return ATH_TWave#TextWaveToString(freeList)
End

/// @function RemoveFileExtention
/// @brief Remove the final extension from a file name.
/// @param str Text containing the str.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S RemoveFileExtention(string str)
	string name, ext
	SplitString/E="(.*(?=\.))(.*)" str, name, ext
	return name
End

/// @function StartsWith
/// @brief Test whether a string starts with a given substring.
/// @param str Text containing the str.
/// @param part Prefix or suffix text to test for.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function StartsWith(string str, string part)
	
	variable nStr = strlen(str)
	variable nPart = strlen(part)	
	if(nStr < nPart || !nstr || !nPart)
		return -1
	endif
	
	return !cmpstr(str[0,nPart-1], part)
End

/// @function EndsWith
/// @brief Test whether a string ends with a given substring.
/// @param str Text containing the str.
/// @param part Prefix or suffix text to test for.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function EndsWith(string str, string part)
	
	variable nStr = strlen(str)
	variable nPart = strlen(part)	
	if(nStr < nPart || !nstr || !nPart)
		return -1
	endif

	return !cmpstr(str[nStr-nPart,nStr-1], part)
End

/// @function WaveLogging
/// @brief Wave logging.
/// @details
/// Add str to the note of wRef. Use prepend = 1 to add string at the start.
/// @param wRef Input wave.
/// @param msg Message shown to the user.
/// @param prepend (optional) If nonzero, insert the new text before the existing list.
/// @returns Zero after completing the operation.
static Function WaveLogging(Wave wRef, string msg, [int prepend])
	// Add str to the note of wRef.
	// Use prepend = 1 to add string at the start.
	if(prepend)
		string noteStr = note(wRef)
		Note/K wRef, msg + "\n" + noteStr
	else
		Note wRef, msg
	endif
	return 0
End

/// @function WaveToString
/// @brief Wave to string.
/// @details
/// Make a string from a textwave.
/// @param w Wave to modify in place.
/// @param sep (optional) Delimiter used between list items.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S WaveToString(WAVE w, [string sep])
	// Make a string from a textwave
	// If you want to return a list, just set strsep=;
	sep = SelectString(ParamIsDefault(sep) ? 0: 1, ";", sep)
	
	string concStr = ""
	variable nitems = DimSize(w, 0), i
	
	for(i = 0; i < nitems; i++)
		concStr += num2str(w[i]) + sep
	endfor
	return concStr
End

/// @function GetSelectedWaveNamesinDB
/// @brief Return the names of waves selected in the Data Browser.
/// @returns The resulting name, or an empty string when no match is available.
static Function/S GetSelectedImagesinDB()
	string buffer, listOfSelectedWaves = ""
	variable i = 0
	do
		buffer = GetBrowserSelection(i)
		if(WaveExists($buffer) && (WaveDims($buffer)==2 || WaveDims($buffer)==3))
			listOfSelectedWaves += buffer + ";" // Match stored at S_value
		endif
		i++
	while (strlen(GetBrowserSelection(i)))
	return listOfSelectedWaves
End

/// @function GetSelectedWavesinDB
/// @brief Return references to waves selected in the Data Browser.
/// @param dim (optional) Zero-based wave-dimension index.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S GetSelectedWavesinDB([variable dim])
	dim = ParamIsDefault(dim) ? 2 : dim
	string buffer, listOfSelectedWaves = ""
	variable i = 0
	do
		buffer = GetBrowserSelection(i)
		if(WaveExists($buffer) && WaveDims($buffer)==dim)
			listOfSelectedWaves += buffer + ";" // Match stored at S_value
		endif
		i++
	while (strlen(GetBrowserSelection(i)))
	return listOfSelectedWaves
End

/// @function AppendToStringList
/// @brief Append to string list.
/// @details
/// Append on prepand the string base to each item in strList.
/// @param base Base string used to build the result.
/// @param strlist Input string list.
/// @param sep (optional) Delimiter used between list items.
/// @param rev (optional) If nonzero, reverse the requested order or color table.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S AppendToStringList(string base, string strlist, [string sep, int rev])
	// Append on prepand the string base to each item in strList
	sep = SelectString(ParamIsDefault(sep) ? 0: 1, ";", sep)
	rev = ParamIsDefault(rev) ? 0: !!rev
	variable imax = ItemsInList(strlist, sep), i
	string retStr = ""
	for(i=0;i<imax;i++)
		if(rev)
			retStr += StringFromList(i,strlist) + base + ";"
		else
			retStr += base + StringFromList(i,strlist) +";"
		endif
	endfor
	return retStr
End

/// @function ThreadStr
/// @brief Combine corresponding items from two string lists.
/// @param strlist0 First input string list.
/// @param strlist1 Second input string list.
/// @param joinstr (optional) Text inserted between the paired list items.
/// @param sep (optional) String-list delimiter.
/// @param listsep0 (optional) Delimiter for the first input list.
/// @param listsep1 (optional) Delimiter for the second input list.
/// @returns A string list containing the paired and joined items.
static Function/S ThreadStr(string strlist0, string strlist1, 
							[string joinstr, string sep, string listsep0, string listsep1])						
	// Thead strings as in Mathematica. strlist0 and strlist1 should
	
	// Note that listsep0, and listsep1 have been added for special cases as wave note
	// for Stacked Waves where we use "\n" as list separator.
	joinstr = SelectString(ParamIsDefault(joinstr) ? 0: 1, "", joinstr)							
	sep = SelectString(ParamIsDefault(sep) ? 0: 1, "\n", sep)
	listsep0 = SelectString(ParamIsDefault(listsep0) ? 0: 1, ";", listsep0)
	listsep1 = SelectString(ParamIsDefault(listsep1) ? 0: 1, ";", listsep1)	
	
	variable imax0 = ItemsInList(strlist0, listsep0)
	variable imax1 = ItemsInList(strlist1, listsep1) , i
	if(imax0 != imax1)
		return ""
	endif
	string retStr = ""
	for(i=0;i<imax0;i++)
		retStr += StringFromList(i, strlist0, listsep0) + joinstr + StringFromList(i, strlist1,listsep1) + sep
	endfor
	return retStr	
End

/// @function RemoveIndexKeysFromList
/// @brief Remove numeric index prefixes from a keyed string list.
/// @param listStr List str.
/// @param keySep (optional) Delimiter between an index key and its value.
/// @param listSep (optional) String-list delimiter.
/// @param startIndex (optional) Smallest numeric key to remove.
/// @returns The input list with matching numeric key prefixes removed.
static Function/S RemoveIndexKeysFromList(string listStr, 
				  [string keySep, string listSep, int startIndex])
	keySep = SelectString(ParamIsDefault(keySep) ? 0: 1, ":", keySep)			  
	listsep = SelectString(ParamIsDefault(listsep) ? 0: 1, ";", listsep)
	startIndex = ParamIsDefault(startIndex) ? 0 : startIndex
	variable nitems = ItemsInList(listStr, listSep), i
	string retStr = ""
	for(i = 0; i < nitems; i++)
		retStr += StringByKey(num2str(i+startIndex), listStr, keySep, listsep) + listsep
	endfor
	return retStr
End

/// @function GetRangeItemsFromList
/// @brief Return range items from list.
/// @details
/// Get the items from startIndex to endIndex from a list with listSep.
/// @param listStr Text containing the list str.
/// @param listSep Delimiter used by the input or output list.
/// @param startIndex Lower or starting start index.
/// @param endIndex Upper or ending end index.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S GetRangeItemsFromList(string listStr, string listSep, int startIndex, int endIndex)
	// Get the items from startIndex to endIndex from a list with listSep
	variable i
	if(endIndex < startIndex || endIndex > ItemsInList(listStr,listSep) || startIndex < 0)
		return ""
	endif
	string retStr = ""
	for(i = startIndex; i < endIndex+1; i++)
		retStr += StringFromList(i,listStr, listSep) + listSep
	endfor
	return retStr
End

/// @function RemoveCharFromString
/// @brief Remove char from string.
/// @details
/// Remove the character cc from string str.
/// @param str Text containing the str.
/// @param cc Character or character code to test.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S RemoveCharFromString(string str, string cc)
	// remove the character cc from string str
	
	variable imax = strlen(str), i
	string outStr = ""
	for(i = 0; i < imax; i++)
		if(cmpstr(str[i],cc))
			outStr += str[i]
		endif
	endfor
	return outStr
End

/// @function ComposeWaveListsFromWaveNotes
/// @brief Compose wave lists from wave notes.
/// @details
/// Given a list of 2D/3D waves in wavelist compose a wave list with all waves: names and add them to the
/// list. At the end you will end up with a list of all 2D waves in the list of wavelistStr.
/// @param wavelistStr Wave used by the operation.
/// @param sep (optional) Delimiter used between list items.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S ComposeWaveListsFromWaveNotes(string wavelistStr, [string sep])
	// Given a list of 2D/3D waves in wavelist compose a wave list with all waves:
	// If a wave is 2D just add it, if the wave is 3D check its note, expand wave 
	// names and add them to the list. At the end you will end up with a list of all
	// 2D waves in the list of wavelistStr
	sep = SelectString(ParamIsDefault(sep) ? 0: 1, ";", sep) // sep of wavelistStr
	
	//If waveListStr is empty abort
	if(!strlen(wavelistStr))
		return ""
	endif
	variable imax = ItemsInList(wavelistStr, sep), i
	string wnameStr, bufferStr, expandedWaveListStr = ""
	for (i = 0; i < imax; i++)
		try
			wnameStr = StringFromList(i, wavelistStr)
			WAVE wRef = $wnameStr // Wave exists?
			AbortOnRTE				// Abort if an error occurred
			// This code executes if no error occurred
			if(WaveDims(wRef) == 2)
				expandedWaveListStr += wnameStr+";"
			elseif(WaveDims(wRef) == 3)
				bufferStr = ATH_String#GetStackNamesForWaveNote(wRef,-1) // sep = "\n" here
				if(DimSize(wRef,2) == ItemsInList(bufferStr, "\n"))
					expandedWaveListStr += ReplaceString("\n", bufferStr, ";")
				else
					return  "" // Something is wrong, just return ""
					//Abort "ComposeWaveListsFromWaveNotes error in "+wnameStr+" waves in notes != number of layers"
				endif
			else
				print "ComposeWaveListsFromWaveNotes " + "assumes 2D/3D waves"
				return  ""
			endif
		catch
			// This code executes if an error occurred in the try block
			variable err = GetRTError(1)		// Gets error code and clears error
			string errMessage = GetErrMessage(err, 3)
			printf "While executing ComposeWaveListsFromWaveNotes, the following error occurred: %s\r", errMessage
		endtry
	endfor
	return expandedWaveListStr
End

/// @function GetStackNamesFromNote
/// @brief Return stack names from note.
/// @details
/// Get the stings with the pathnames of all layers stacked in wave.
/// @param wref Input wave.
/// @returns The resulting name, or an empty string when no match is available.
static Function/S GetStackNamesFromNote(WAVE wref)
	//Get the stings with the pathnames of all layers stacked in wave
	string regex = "([\s\S]*?(?=---\* Stacked waves \*---(?:\r?\n|\r|\n)?))(---\* Stacked waves \*---(?:\r?\n|\r|\n)*)"+\
	"([\s\S]*?(?=\*--------------------------\*(?:\r?\n|\r|\n)?))(\*--------------------------\*(?:\r?\n|\r|\n)*)([\s\S]*$)"
	string strBefore, dump0, waveListStr, dump1, strAfter
	SplitString/E=regex note(wRef), strBefore, dump0, waveListStr, dump1, strAfter
	return waveListStr
End

/// @function SetStackNamesInNote
/// @brief Set stack names in note.
/// @details
/// Add list of stacked waves to wRef. Special listSep=";" as by default most functions send lists with ";"
/// sep. listSepI: sep the indices (usually ";").
/// @param wref Input wave.
/// @param waveNamesList Wave used by the operation.
/// @param listSepI (optional) Delimiter used by the input list.
/// @param listSepW (optional) Delimiter used by the wave-name list.
/// @returns Zero after completing the operation.
static Function SetStackNamesInNote(WAVE wref, string waveNamesList,[string listSepI,string listSepW])
	// Add list of stacked waves to wRef
	// Special listSep=";" as by default most functions send lists with ";" sep.
	// ATH_String#ThreadStr will by default separate items with "\n"
	// listSepI: sep the indices (usually ";")
	// listSepW: sep for waveNamesList
	listsepI = SelectString(ParamIsDefault(listsepI) ? 0: 1, ";", listsepI)
	listsepW = SelectString(ParamIsDefault(listsepW) ? 0: 1, ";", listsepW)	
	// Here ATH_String#ExpandRangeStr uses as list seperator ";", so default BUT waveNamesList
	// uses "\n"
	string indices = ATH_String#ExpandRangeStr("0-"+num2str(ItemsInList(waveNamesList,listSepW)-1))
	// Note that indices use ";" as well as waveNamesList here!
	string noteStr = "---* Stacked waves *---\n" + \
	ATH_String#ThreadStr(indices, waveNamesList, joinstr=">", listSep0 = listSepI, listsep1 = listSepW) + \
	"*--------------------------*\n"
	Note/K wRef, noteStr
End

/// @function StackNamesInNoteStr
/// @brief Format a stack's source-wave names for storage in a wave note.
/// @details
/// Add list of stacked waves to wRef NB. indices sep is ";", waveNameList is "\n".
/// @param waveNamesList Wave used by the operation.
/// @param listSep (optional) Delimiter used by the input or output list.
/// @returns The resulting name, or an empty string when no match is available.
static Function/S StackNamesInNoteStr(string waveNamesList,[string listSep]) // Special listSep="\n" 
	// Add list of stacked waves to wRef
	listsep = SelectString(ParamIsDefault(listsep) ? 0: 1, "\n", listsep)
	
	if(!strlen(waveNamesList)) // If list is empty return ""
		return ""
	endif
	
	string indices = ATH_String#ExpandRangeStr("0-"+num2str(ItemsInList(waveNamesList,listSep)-1))
	// NB. indices sep is ";", waveNameList is "\n"
	string noteStr = "---* Stacked waves *---\n" + \
	ATH_String#ThreadStr(indices, waveNamesList, joinstr=">", listsep1="\n") + \
	"*--------------------------*\n" // no \n at the end here!
	return noteStr
End

/// @function GetStackNamesForWaveNote
/// @brief Return stack names for wave note.
/// @details
/// Add/remove layer names in wave note, update the note in wRef rangeStr can be "2-5,7,9-12,50" expand a
/// string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50".
/// @param wRef Input wave.
/// @param op Operation selector.
/// @param rangeStr (optional) Range str.
/// @param wlist (optional) List of wave names.
/// @param noteStr (optional) Text containing the note str.
/// @returns The resulting name, or an empty string when no match is available.
static Function/S GetStackNamesForWaveNote(WAVE wRef, int op, [string rangeStr, string wlist, string noteStr])
	//
	// Add/remove layer names in wave note, update the note in wRef
	// rangeStr can be "2-5,7,9-12,50"
	// expand a string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50"
	//
	// op = 0 // Keep a range
	// op = 1 // Remove layers
	// op = 2 // Flip Stack
	// op = 3 // Append layers
	// op = 4 // Insert layers // Here rangeStr is the layerN we apply the ATH_ImgOp#InsertImagesToImageStack
	//

	if(!ParamIsDefault(rangeStr))
		string layersNum = ExpandRangeStr(rangeStr)
		variable nItems = ItemsInList(layersNum)
	endif
	
	
	string regex = "([\s\S]*?(?=---\* Stacked waves \*---(?:\r?\n|\r|\n)?))(---\* Stacked waves \*---(?:\r?\n|\r|\n)*)"+\
	"([\s\S]*?(?=\*--------------------------\*(?:\r?\n|\r|\n)?))(\*--------------------------\*(?:\r?\n|\r|\n)*)([\s\S]*$)"
	string strBefore, dump0, waveListStr, dump1, strAfter, buffer = ""
	// If you do not give noteStr, use the wave note
	if(ParamIsDefault(noteStr))
		noteStr = note(wRef)
	endif
	SplitString/E=regex noteStr, strBefore, dump0, waveListStr, dump1, strAfter
	waveListStr = ATH_String#RemoveIndexKeysFromList(waveListStr, keySep=">", listSep="\n")
	// What if we created a wave, and there is no stacked wave string?
	if(!strlen(waveListStr)) // Critical!
		return "" 
	endif
	variable i
	switch(op)
		case 0: // Extract a range
			waveListStr = GetRangeItemsFromList(waveListStr, "\n",\
			str2num(StringFromList(0,layersNum)), str2num(StringFromList(nItems-1,layersNum)))
			break
		case 1: // Remove layers
			for(i = nItems - 1; i > - 1; i--)
				waveListStr = RemoveListItem(str2num(StringFromList(i,layersNum)),waveListStr,"\n")
			endfor
			break
		case 2: // Flip stack
			variable totalItems = ItemsInList(waveListStr,"\n")
			for(i = 0 ; i < totalItems; i++)
				buffer+=StringFromList(totalItems-i-1, waveListStr, "\n")+"\n"
			endfor
				waveListStr = buffer
			break
		case 3: // Append layer(s)
			waveListStr += wlist
			break
		case 4: // Insert layer(s)
			break						
		default: // Do nothing and proceed
			break
	endswitch
	// update note
	return waveListStr
End

/// @function UpdateStackWaveNote
/// @brief Update stack wave note.
/// @details
/// Add/remove layer names in wave note, update the note in wRef rangeStr can be "2-5,7,9-12,50" expand a
/// string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50".
/// @param wRef Input wave.
/// @param op Operation selector.
/// @param rangeStr (optional) Range str.
/// @param wlist (optional) List of wave names.
/// @param noteStr (optional) Text containing the note str.
/// @param explicitWaveList (optional) Wave used by the operation.
/// @returns Zero after completing the operation.
static Function UpdateStackWaveNote(WAVE wRef, int op, [string rangeStr, string wlist, string noteStr, string explicitWaveList])
	//
	// Add/remove layer names in wave note, update the note in wRef
	// rangeStr can be "2-5,7,9-12,50"
	// expand a string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50"
	//
	// op = 0 // Keep a range
	// op = 1 // Remove layers
	// op = 2 // Flip Stack
	// op = 3 // Append layers
	// op = 4 // Insert layers // Here rangeStr is the layerN we apply the ATH_ImgOp#InsertImagesToImageStack
	//
	// default: use the explicitWaveList optional parameter
	
	if(!ParamIsDefault(rangeStr))
		string layersNum = ExpandRangeStr(rangeStr)
		variable nItems = ItemsInList(layersNum)
	endif
	// If you do not give noteStr, use the wave note	
	if(ParamIsDefault(noteStr))
		noteStr = note(wRef)
	endif	
	string regex = "([\s\S]*?(?=---\* Stacked waves \*---(?:\r?\n|\r|\n)?))(---\* Stacked waves \*---(?:\r?\n|\r|\n)*)"+\
	"([\s\S]*?(?=\*--------------------------\*(?:\r?\n|\r|\n)?))(\*--------------------------\*(?:\r?\n|\r|\n)*)([\s\S]*$)"
	string strBefore, dump0, waveListStr, dump1, strAfter, buffer = ""
	SplitString/E=regex noteStr, strBefore, dump0, waveListStr, dump1, strAfter
	waveListStr = ATH_String#RemoveIndexKeysFromList(waveListStr, keySep=">", listSep="\n")	
	variable i
	switch(op)
		case 0: // Extract a range
			waveListStr = GetRangeItemsFromList(waveListStr, "\n",\
			str2num(StringFromList(0,layersNum)), str2num(StringFromList(nItems-1,layersNum)))
			break
		case 1: // Remove layers
			for(i = nItems - 1; i > - 1; i--)
				waveListStr = RemoveListItem(str2num(StringFromList(i,layersNum)),waveListStr,"\n")
			endfor
			break
		case 2: // Flip stack
			variable totalItems = ItemsInList(waveListStr,"\n")
			for(i = 0 ; i < totalItems; i++)
				buffer+=StringFromList(totalItems-i-1, waveListStr, "\n")+"\n"
			endfor
				waveListStr = buffer
			break
		case 3: // Append layer(s)
			waveListStr += wlist
			break
		case 4: // Insert layer(s)
			//Insert here the code in ATH_Launch#InsertImagesToStack()
			break
		default:
			if(!ParamIsDefault(explicitWaveList))
				waveListStr = explicitWaveList
			endif
			break
	endswitch
	// update note. Careful waveListStr needs "\n" list separator
	noteStr = strBefore + StackNamesInNoteStr(waveListStr) + strAfter
	Note/K wRef, noteStr 
	return 0
End

/// @function RandomSampleStringList
/// @brief Select a random sample from a string list without replacement.
/// @details
/// Removes each selected item from the candidate list so an item cannot be chosen twice.
/// @param list Input string list.
/// @param sampleN Number of items to select.
/// @returns A semicolon-separated sample, or an empty string if `sampleN` exceeds the list length.

static Function/S RandomSampleStringList(string list, variable sampleN)
	// A stack has layer indices 0...N-1 so listN = N. Therefore the first pick
	// in the for look is floor(abs(enoise(listN))). So, we incude the layer N-1
	// in the selection (floor!),  When we call it to sample a stack,
	// we have to use ATH_String#ExpandRangeStr("0-"+num2str(nlayers-1)) as list
	variable listN = ItemsInList(list)
	if(sampleN > listN)
		return ""
	endif
	variable i, item
	string rList = ""
	for(i = 0 ; i < sampleN; i++)
		item = floor(abs(enoise(listN-i))) // reduce enoise range as you pop an item from the list
		rlist += StringFromList(item, list) + ";"		
		list = RemoveListItem(item,list)
	endfor
	return rlist
End
