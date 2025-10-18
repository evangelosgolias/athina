#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_String
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

static Function/S AppendToStringList(string base, string strlist, [string sep, int rev])
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
							[string joinstr, string sep, string listsep])
	// Thead strings as in Mathematica. strlist0 and strlist1 should
	joinstr = SelectString(ParamIsDefault(joinstr) ? 0: 1, "", joinstr)							
	sep = SelectString(ParamIsDefault(sep) ? 0: 1, "\n", sep)
	listsep = SelectString(ParamIsDefault(listsep) ? 0: 1, ";", listsep)
	
	variable imax = ItemsInList(strlist0, listsep), i
	if(ItemsInList(strlist0, listsep) != imax)
		return ""
	endif
	string retStr = ""
	for(i=0;i<imax;i++)
		retStr += StringFromList(i, strlist0) + joinstr + StringFromList(i, strlist1) + sep
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