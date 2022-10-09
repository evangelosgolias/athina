﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Menu "Athina"

	Submenu "Import!*"
		".dat file...", MXP_LoadSingleDATFile("", "")
		"multiply .dat files...", MXP_LoadMultiplyDATFiles("")
		".dat files in folder...",  MXP_LoadDATFilesFromFolder("", "*") 
		".dat files in folder to stack ...", MXP_LauncherLoadDATFilesFromFolder()
	End
	
	Submenu "Analyse"
	"***** ", print "Not yet implemented"
	End
	
	Submenu "Align!*"
	"stack (correlation, fast)!* ...", MXP_LaunchMXP_ImageStackAlignmentByCorrelation()
	End
	
	Submenu "Make!*"
	"a stack from pattern", MXP_Launchake3DWaveUsingPattern()
	"a stack from browser selection", MXP_LaunchMake3DWaveDataBrowserSelection()
	End
	
	Submenu "Calculation!*"
	"Stack average...!*", MXP_LaunchAverageStackToImage()
	"Import .dat files and calculate XMC(L)D...!*", MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()
	"Calculate XMC(L)D...!*", MXP_LaunchRegisterQCalculateXRayDichroism()
	End
	
	Submenu "Profiles!*"
		"z-profile...!*", MXP_MainMenuLaunchZBeamProfiler()
		"z-profile (many areas)..."
	End
End



Menu "GraphMarquee"
	"Oval ROI z profile", GetMarquee/K left, top; MXP_DrawImageROICursor(V_left, V_top, V_right, V_bottom)
	"Clear ROI markings", MXP_CleanROIMarkings()
End