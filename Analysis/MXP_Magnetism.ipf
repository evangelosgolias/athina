#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function/WAVE MXP_WAVECalculateXMCD(WAVE w1, WAVE w2)
	/// Calculate XMCD/XMLD of two images
	Duplicate/FREE w1, wxmcd
	wxmcd = (w1 - w2)/(w1 + w2)
	return wxmcd
End

Function MXP_CalculateXMCD(WAVE w1, WAVE w2, string wxmcd)
	/// Calculate XMCD/XMLD of two images and save it to 
	/// @param w1 WAVE Wave 1
	/// @param w2 WAVE Wave 2
	/// @param wxmcd string Wavemane of calcualted XMCD/XMLD
	Duplicate w1, $wxmcd
	Wave wref = $wxmcd
	wref = (w1 - w2)/(w1 + w2)
	
End

Function MXP_CalculateXMCD3D(WAVE w1, WAVE w2)
	/// Calculate XMCD/XMLD of two images in a 3d wave
End