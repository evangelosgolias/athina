#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_exe
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

static Function/S ExecuteShellCommand(uCommand, printCommandInHistory, printResultInHistory [, asAdmin])
	// Copy of WM procedure
	String uCommand					// Unix command to execute
	Variable printCommandInHistory
	Variable printResultInHistory
	Variable asAdmin					// Optional - defaults to 0

	if (ParamIsDefault(asAdmin))
		asAdmin = 0
	endif

	if (printCommandInHistory)
		Printf "Unix command: %s\r", uCommand
	endif

	String cmd
	sprintf cmd, "do shell script \"%s\"", uCommand
	if (asAdmin)
		cmd += " with administrator privileges"
	endif
	ExecuteScriptText/UNQ/Z cmd 	// /UNQ removes quotes surrounding reply

	if (printResultInHistory)
		Print S_value
	endif

	return S_value
End

static Function CmdExecutionUsingRange(string cmdStr, string rangeStr)
	/// Execute cmdStr with parameters the numbers in rangeStr
	/// See ATH_ExpandRangeStr doc string.
	/// e.g.: ATH_CmdExecutionUsingRange("NewDataFolder 'FLDR#%s'", "2,3,11-14")
	string numStrList = ATH_String#ExpandRangeStr(rangeStr)
	string execmdStr
	
	variable imax = ItemsInList(numStrList), i
	for(i = 0; i < imax; i++)
		sprintf execmdStr, cmdStr, StringFromList(i, numStrList)
		Execute execmdStr
	endfor
	return 0
End

static Function CmdExecutionInFolderWithPattern(string cmdStr, string pattern)
	/// Execute cmdStr for wavelist using pattern
	/// e.g.: ATH_CmdExecutionInFolderWithPattern("NewDataFolder", "waveP*")
	
	string wlistStr = Wavelist(pattern, ";", "")
	string execmdStr
	
	variable imax = ItemsInList(wlistStr), i
	for(i = 0; i < imax; i++)
		sprintf execmdStr, cmdStr, StringFromList(i, wlistStr)
		Execute execmdStr
	endfor
	return 0
End
