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
//
//Button 1: Set anchor using Cursor A
//Button 2: Drift image
//Button 3: Cascade drift (SetVariable 0: until the last layer, or N for N layers)
//Button 4: Restore (create a wave_undo when launched and delete it after closing the panel)