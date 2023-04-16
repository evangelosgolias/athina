﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function/S MXP_ExpandRangeStr(string rangeStr)	
	// expand a string like "2-5,7,9-12,50" to "2,3,4,5,7,9,10,11,12,50"

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