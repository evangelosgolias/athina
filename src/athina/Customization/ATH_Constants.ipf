#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// Constants 

// Number of layers above which the MT drift correction is called
constant kATH_DriftCorrectionMT = 9

// Wave names
strconstant ksATH_StackPrefix = "ath_stack"
strconstant ksATH_TransientStackPrefix = "ath_tr_stack"
