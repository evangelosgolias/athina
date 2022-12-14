#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function MXP_DisplayImage(WAVE waveRef)
	// Display an image or stack
		NewImage/G=1/K=1 waveRef
		ModifyGraph width={Plan,1,top,left}
		WM_AutoSizeImage(0.5)
		if(WaveDims(waveRef)==3)
			WMAppend3DImageSlider()
		endif
End