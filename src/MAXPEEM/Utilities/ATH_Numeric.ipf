#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Num

static Function NumSignDigits(variable num, variable sigDigits)
	/// Return the num with sigDigits significant digits
	/// NOTE: Six is the maximum numnbers of sigDigits 
	/// the function can handle.
    string str
    sprintf str, "%.*g", sigDigits, num
    return str2num(str)
End

static Function IntegerQ(variable num)
	/// Check in a number is integer
	if(num == trunc(num))
		return 1
	else
		return 0
	endif
End