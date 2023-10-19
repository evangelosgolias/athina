#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function MSC_SanitiseMXP() 
	string allwindows = WinList("*", ";", "") // all windows
	variable imax = ItemsInList(allwindows) , i
	string buffer, winNameStr
	for(i = 0; i < imax; i++)
		winNameStr = StringFromList(i, allwindows)
		buffer = GetUserData(winNameStr, "", "MXP_SpacesTag")
		SetWindow $winNameStr userdata(ATH_SpacesTag) = buffer
	endfor
End

