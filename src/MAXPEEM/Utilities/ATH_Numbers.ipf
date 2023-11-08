#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function ATH_IntegerQ(variable num)
/// Check in a number is integer
 if(num == trunc(num))
 	return 1
 else
 	return 0
 else
End