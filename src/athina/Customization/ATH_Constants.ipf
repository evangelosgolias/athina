#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// Constants 

//Wave backup extention
strconstant ksATHBackupWaveExtention = "_undo"

// Drawing
constant kATH_ScaleBarRelFactorRed = 0.51 // relative values of x-axis above which the bar is red


// Wave names
strconstant ksATH_StackPrefix = "ath_stack"
strconstant ksATH_TransientStackPrefix = "ath_tr_stack"

//Special dirs
strConstant skATH_W3DImageSliderParentDFR = "root:Packages:ATH_DataFolder:W3DImageSlider:" // Ends with semicolon
strConstant skATH_DriftCorrectionSettings =  "root:Packages:ATH_DataFolder:DriftCorrectionSettings"
strConstant skATH_SaveImageStackDriftCorrections = "root:Packages:ATH_DataFolder:SavedDriftCorrections"