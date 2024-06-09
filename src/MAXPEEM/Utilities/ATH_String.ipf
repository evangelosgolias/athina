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
	string regex = "\s+(hv\s*=|hn\s*=|hn|hv)\s*([0-9]*[.]?[0-9]+)(\s*eV|\s*)"
	string prefix, energy, suffix
	SplitString/E=regex nameStr, prefix, energy, suffix
	if(V_flag)
		return str2num(energy)
	endif
	return 0
End

// Dev -- need testing
static Function/S UniquifyStringList(string stringListStr, [string sep])	
	// Remove duplicates from a sting list
	if(ParamIsDefault(sep))
		sep = ";"
	else
		sep = sep
	endif
	WAVE/T textW = WAVEStringListToTextWave(stringListStr, sep = sep)
	//FindDuplicates
End

static Function/WAVE WAVEStringListToTextWave(string stringListStr, [string sep])

	if(ParamIsDefault(sep))
		sep = ";"
	else
		sep = sep
	endif
	variable numElem = ItemsInList(stringListStr, sep)
	if(!numElem)
		return $""
	else
		return ListToTextWave(stringListStr, sep)		
	endif
End
