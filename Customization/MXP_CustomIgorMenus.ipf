#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Menu "MAXPEEM"

	Submenu "Import!*"
		".dat file...", MXP_LoadSingleDATFile("", "", autoscale = 1)
		".dat files...", MXP_LoadMultiplyDATFiles(autoscale = 1)
		".dat files in folder...",  MXP_LoadDATFilesFromFolder("", "*") // scale
		".dat files in folder to stack ...", MXP_LauncherLoadDATFilesFromFolder()
	End
	
	Submenu "Analyse"
	"***** ", print "Not yet implemented"
	End
	
	Submenu "Align!*"
	"stack (correlation, fast)!* ...", MXP_LaunchMXP_ImageStackAlignmentByCorrelation()
	End
	
	Submenu "Make!*"
	"a stack from pattern!*", MXP_Launchake3DWaveUsingPattern()
	"a stack from browser selection!*", MXP_LaunchMake3DWaveDataBrowserSelection()
	End
	
	Submenu "Calculation!*"
	"Stack average...!*", MXP_LaunchAverageStackToImage()
	"Import .dat files and calculate XMC(L)D...!*", MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()
	"Calculate XMC(L)D...!*", MXP_LaunchRegisterQCalculateXRayDichroism()
	End
	
	Submenu "Profiles!*"
		"z-profile...!*", MXP_MainMenuLaunchZBeamProfiler()
		"Line profile...", print "Now yet implemented"
	End
	
	Submenu "Housekeeping"
		"List big waves", print "Now yet implemented"
		"Export and remove big waves", print "Now yet implemented"
	End
End



Menu "GraphMarquee"
	"Oval ROI z profile", GetMarquee/K left, top; MXP_DrawImageROICursor(V_left, V_top, V_right, V_bottom)
	"Clear ROI markings", MXP_CleanROIMarkings()
End
