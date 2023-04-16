#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function RecursiveExecution(string cmdStr, string rangeStr)
	
	string numStrList = MXP_ExpandRangeStr(rangeStr)
	string execmdStr
	variable imax = ItemsInList(numStrList), i
	for(i = 0; i < imax; i++)
		sprintf execmdStr, cmdStr, StringFromList(i, numStrList)
		Execute execmdStr
	endfor
	return 0
End