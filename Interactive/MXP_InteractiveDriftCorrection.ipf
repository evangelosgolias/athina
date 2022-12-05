#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

/// Interactive drift correction of a 3D wave

// Implementation notes

//AutoPositionWindow/E/M=1/R=$ImGrfName
//
//NewPanel/EXT=0/HOST=iXMCDPanel0/W=(10,120,100,200) as "testPanel1"
//
//Exterior panel can have its own hook function! Use it for image Histogram
//
//Use exterior window to the manual alignment panel.
//
//Make a window popping in a 3D wave where the position will get updates from gLayer (SVAR)



Function MXP_CreateInteractiveDriftCorrectionPanel()
	
	string winNameStr = WinName(0, 1, 1)
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
	WAVE w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave

	NewPanel/K=1/EXT=0/N=iDriftCorrection/W=(0,0,164,240)/HOST=$winNameStr
	SetDrawLayer UserBack
	SetDrawEnv/W=iDriftCorrection fsize= 13,fstyle= 1,textrgb= (1,12815,52428)
	DrawText/W=iDriftCorrection 2,16,"Interactive drift correction"
	SetDrawEnv/W=iDriftCorrection dash= 3,fillpat= 0
	DrawRect/W=iDriftCorrection 19,99,144,195
	SetDrawEnv/W=iDriftCorrection textrgb= (1,12815,52428)
	DrawText/W=iDriftCorrection 27,188,"N = -1 cascades until\r    the end of slide"
	Button SetAnchorCursor,pos={23.00,31.00},size={120.00,20.00}
	Button SetAnchorCursor,title="(Re)Set anchor (A)",fSize=12
	Button SetAnchorCursor,fColor=(65535,32768,32768)
	Button DriftImage,pos={32.00,67.00},size={100.00,20.00},title="DriftImage"
	Button DriftImage,fSize=12
	Button CascadeDrift,pos={32.00,103.00},size={100.00,20.00},title="Cascade Drift"
	Button CascadeDrift,fSize=12
	SetVariable NrImages,pos={33.00,136.00},size={100.00,18.00},title="N =",fSize=12
	Button Restore3dwave,pos={32.00,209.00},size={100.00,20.00}
	Button Restore3dwave,title="Restore stack",fSize=12
EndMacro
