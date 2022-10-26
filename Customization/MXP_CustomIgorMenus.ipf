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
		".dav file in stack...", MXP_LoadSingleDAVFile("", "", stack3d = 1, skipmetadata = 1)
		".dav file...", MXP_LoadSingleDAVFile("", "")
	End
	
	Submenu "Analyse"
		"***** ", print "Not yet implemented"
	End
	
	Submenu "Align!*"
		"using a feature (recommended)...", MXP_LaunchImageStackAlignmentByPartition()
		"using the full image...", MXP_LaunchImageStackAlignmentByFullImage()
	End
	
	Submenu "Make!*"
		"a stack from pattern!*", MXP_LaunchMake3DWaveUsingPattern()
		"a stack from browser selection!*", MXP_LaunchMake3DWaveDataBrowserSelection()
	End
	
	Submenu "Calculation!*"
		"Stack average...!*", MXP_LaunchAverageStackToImageFromMenu()
		"Calculate XMC(L)D...!*", MXP_LaunchRegisterQCalculateXRayDichroism()
		"Calculate XMC(L)D interactively...!*", MXP_LaunchInteractiveCalculateXRayDichroism()
		"Import .dat files and calculate XMC(L)D...!*", MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()
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
	"Clear ROI markings", MXP_ClearROIMarkings()
	"Marquee to mask", MXP_MarqueeToMask()
	"Backup traces", MXP_BackupTraces()
	"Restore traces", MXP_RestoreTraces()
	"Normalize to one", MXP_NormalizeToOne()
	"Pull to zero", MXP_PullToZero()
	"Maximum to one", MXP_MaximumToOne()
	"Partition 3D region", MXP_Partition3DRegion()
End


Menu "DataBrowserObjectsPopup"
	"MXP Newimage", MXP_LaunchNewImageFromBrowserSelection()
	"MXP Make stack", MXP_LaunchMake3DWaveDataBrowserSelection()
End

Menu "TracePopup"
	"-"
	"MXP z profile", MXP_TraceMenuLaunchZBeamProfiler()
	"MXP Scale Image", MXP_ScaleImage()
	"MXP Average wave",  MXP_LaunchAverageStackToImageFromTraceMenu()
	"MXP Calculate XMC(L)D", MXP_LaunchCalculateXMCDFromStack()
End
