#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Menu "MAXPEEM"
	Submenu "Import"
		".dat file .../1", MXP_LoadSingleDATFile("", "")
		"multiply .dat files .../2", MXP_LoadMultiplyDATFiles("")
		"files from folder ...",  MXP_LoadDATFilesFromFolder("", "*") // Add promptin future release
		"files from folder in stack .../4",  MXP_LoadDATFilesFromFolder("", "*", switch3d = 1) // Add promptin future release
		"two images for XMC(L)D calculation.../5", MXP_MenuLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()

	End
End

Menu "MAXPEEM"
	Submenu "Analyse"
	"***** ...", MXP_RegisterQCalculateXRayDichroism()
	End
	Submenu "Align"
	"image stack (no mask) ...", MXP_RegisterQCalculateXRayDichroism()
	"stack using mask ...", MXP_RegisterQCalculateXRayDichroism()
	End
	Submenu "Make"
	"a stack from pattern", MXP_RegisterQCalculateXRayDichroism()
	"a stack from browser selection", MXP_RegisterQCalculateXRayDichroism()
	"a mask in top window"
	End
	
	Submenu "Calculation"
	"Calculate XMC(L)D ...", MXP_RegisterQCalculateXRayDichroism()
	End
	Submenu "Plot"
		"z-profile", MXP_MainMenuLaunchZBeamProfiler()
	End
End



Menu "GraphMarquee"
	"Oval ROI z profile", GetMarquee/K left, top; MXP_DrawImageROICursor(V_left, V_top, V_right, V_bottom)
	"Clear ROI markings", MXP_CleanROIMarkings()
End
