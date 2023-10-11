#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function MXP_RightDimVal(WAVE w, int dim)
	// Return the last value of dimension dim
	return DimOffSet(w, dim) + DimDelta(w, dim) * (DimSize(w, dim) - 1 ) 
End