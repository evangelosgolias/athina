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

static Function isEXTWindow(string str)
	// Is s the same of an EXT window, GraphXX#ExtWindowName
	return strsearch(str, "#", 0) != -1
End

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

static Function/S ExtendPathStr(string str, string ext)
	// Add ext to s, which is usually a full path to a wave
	// Works for liberal and proper paths
	// For example:
	// Add "_undo" to the root:'2434w' -> root:'2434w_undo' !

	if(!cmpstr(str[strlen(str) - 1], "'"))
		return RemoveEnding(str, "'") + ext + "'"
	else
		return str+ext
	endif
End

static Function StartsWith(string str, string part)
	
	variable nStr = strlen(str)
	variable nPart = strlen(part)	
	if(nStr < nPart || !nstr || !nPart)
		return -1
	endif
	variable i
	for(i=0;i<nPart;i++)
		if(cmpstr(part[i], str[i]))
			return 0
		endif
	endfor
	return 1
End

static Function WaveLogging(Wave wRef, string msg, [int prepend])
	// Add str to the note of wRef.
	// Use prepend = 1 to add string at the start.
	if(prepend)
		Note wRef, msg + Note(wRef)
	else
		Note wRef, msg
	endif
	return 0
End

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

static Function/S GetSelectedWaveNamesinDB()
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

static Function/S GetStackNamesFromNote(WAVE wref)
	//Get the stings with the pathnames of all layers stacked in wave
	string regex = "([\s\S]*?(?=---\* Stacked waves \*---(?:\r?\n|\r|\n)?))(---\* Stacked waves \*---(?:\r?\n|\r|\n)*)"+\
	"([\s\S]*?(?=\*--------------------------\*(?:\r?\n|\r|\n)?))(\*--------------------------\*(?:\r?\n|\r|\n)*)([\s\S]*$)"
	string strBefore, dump0, waveListStr, dump1, strAfter
	SplitString/E=regex note(wRef), strBefore, dump0, waveListStr, dump1, strAfter
	return waveListStr
End

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

static Function/S StackNamesInNoteStr(string waveNamesList,[string listSep]) // Special listSep="\n" 
	// Add list of stacked waves to wRef
	listsep = SelectString(ParamIsDefault(listsep) ? 0: 1, "\n", listsep)	
	string indices = ATH_String#ExpandRangeStr("0-"+num2str(ItemsInList(waveNamesList,listSep)-1))
	// NB. indices sep is ";", waveNameList is "\n"
	string noteStr = "---* Stacked waves *---\n" + \
	ATH_String#ThreadStr(indices, waveNamesList, joinstr=">", listsep1="\n") + \
	"*--------------------------*\n" // no \n at the end here!
	return noteStr
End

static Function/S GetStackNamesForWaveNote(WAVE wref, string rangeStr, int op, [string listSep, string noteStr])
	// Read stack names from wRef, filter and return a new list of waves
	// to be used as a note to another wave.
	//
	// rangeStr can be "2-5,7,9-12,50"
	//
	// op = 0 // Keep a range (use in extract operation)
	// op = 1 // Remove
	
	listSep = SelectString(ParamIsDefault(listSep) ? 0: 1, "\n", listSep)
	// expand a string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50"
	string layersNum = ExpandRangeStr(rangeStr)
	
	string regex = "([\s\S]*?(?=---\* Stacked waves \*---(?:\r?\n|\r|\n)?))(---\* Stacked waves \*---(?:\r?\n|\r|\n)*)"+\
	"([\s\S]*?(?=\*--------------------------\*(?:\r?\n|\r|\n)?))(\*--------------------------\*(?:\r?\n|\r|\n)*)([\s\S]*$)"
	string strBefore, dump0, waveListStr, dump1, strAfter
	// If you do not give noteStr, use the wave note
	if(ParamIsDefault(noteStr))
		noteStr = note(wRef)
	endif
	SplitString/E=regex noteStr, strBefore, dump0, waveListStr, dump1, strAfter
	waveListStr = ATH_String#RemoveIndexKeysFromList(waveListStr, keySep=">", listSep=listSep)	
	variable nItems = ItemsInList(layersNum), i
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
//		case 2: // Add more cases here
//			
		default:
			break
	endswitch
	// update note
	return waveListStr
End

static Function UpdateStackWaveNote(WAVE wref, string rangeStr, int op, [string listSep, string noteStr])
	// Add/remove layer names in wave note, update the note in wRef
	// rangeStr can be "2-5,7,9-12,50"
	//
	// op = 0 // Keep a range
	// op = 1 // Remove
	
	listSep = SelectString(ParamIsDefault(listSep) ? 0: 1, "\n", listSep)
	// expand a string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50"
	string layersNum = ExpandRangeStr(rangeStr)
	// If you do not give noteStr, use the wave note	
	if(ParamIsDefault(noteStr))
		noteStr = note(wRef)
	endif	
	string regex = "([\s\S]*?(?=---\* Stacked waves \*---(?:\r?\n|\r|\n)?))(---\* Stacked waves \*---(?:\r?\n|\r|\n)*)"+\
	"([\s\S]*?(?=\*--------------------------\*(?:\r?\n|\r|\n)?))(\*--------------------------\*(?:\r?\n|\r|\n)*)([\s\S]*$)"
	string strBefore, dump0, waveListStr, dump1, strAfter
	SplitString/E=regex noteStr, strBefore, dump0, waveListStr, dump1, strAfter
	waveListStr = ATH_String#RemoveIndexKeysFromList(waveListStr, keySep=">", listSep=listSep)	
	variable nItems = ItemsInList(layersNum), i
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
//		case 2: // Add layer
//			
		default:
			break
	endswitch
	// update note
	noteStr = strBefore + StackNamesInNoteStr(waveListStr) + strAfter
	Note/K wRef, noteStr 
	return 0
End