#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Menu "MAXPEEM"

	Submenu "Import"
		".dat file...", MXP_LoadSingleDATFile("", "", autoscale = 1)
		".dat files...", MXP_LoadMultiplyDATFiles(autoscale = 1)
		".dat files in folder...",  MXP_LoadDATFilesFromFolder("", "*", autoscale = 1)
		".dat files in folder to stack ...", MXP_LauncherLoadDATFilesFromFolder()
		".dav file in stack...", MXP_LoadSingleDAVFile("", "", stack3d = 1, skipmetadata = 1, autoscale = 1)
		".dav file...", MXP_LoadSingleDAVFile("", "", autoscale = 1)
		".h5 file ...", MXP_LauncherLoadHDF5GroupsFromFile()
	End
	
	Submenu "Analyse"
		"***** ", print "Not yet implemented, however, Igor Pro has plently of tools to analyse your data."
	End
	
	Submenu "Align"
		"using a feature (recommended)...", MXP_LaunchImageStackAlignmentUsingAFeature()
		"using the full image...", MXP_LaunchImageStackAlignmentByFullImage()
	End
	
	Submenu "Make"
		"a stack from pattern", MXP_LaunchMake3DWaveUsingPattern()
		"a stack from browser selection", MXP_LaunchMake3DWaveDataBrowserSelection()
	End
	
	Submenu "Calculation"
		"Stack average...", MXP_LaunchAverageStackToImageFromMenu()
		"Calculate XMC(L)D...", MXP_LaunchRegisterQCalculateXRayDichroism()
		"Calculate XMC(L)D interactively...", MXP_LaunchInteractiveCalculateXRayDichroism()
		"Import .dat files and calculate XMC(L)D...", MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()
	End
	
	Submenu "Profiles"
		"Line profile...", MXP_MainMenuLaunchLineProfiler()
		"z-profile...", MXP_MainMenuLaunchZBeamProfiler()
	End
	
	Submenu "Report"
		"List entries in a .h5 file...", MXP_ListHDF5Groups()
		//"List big waves", print "Now yet implemented"
	End
End

Menu "GraphMarquee"
	"Oval ROI z profile", MXP_DrawROIAndWaitHookToAct()
	"Marquee to mask", MXP_MarqueeToMask()
	"Backup traces", MXP_BackupTraces()
	"Restore traces", MXP_RestoreTraces()
	"Normalise to profile", MXP_NormaliseTracesWithProfile()
	"Normalize to one", MXP_NormalizeToOne()
	"Pull to zero", MXP_PullToZero()
	"Maximum to one", MXP_MaximumToOne()
	"Partition 3D region", MXP_Partition3DRegion()
End


Menu "DataBrowserObjectsPopup"
	"MXP Newimage", MXP_LaunchNewImageFromBrowserSelection()
	"MXP Z profile", MXP_BrowserMenuLaunchZBeamProfiler()
	"MXP Line profile", MXP_BrowserMenuLaunchLineProfiler()
	"MXP Average stack",  MXP_LaunchAverageStackToImageFromBrowserMenu()
	"MXP Make stack", MXP_LaunchMake3DWaveDataBrowserSelection()
End

Menu "TracePopup"
	"-"
	//"MXP line profile", MXP_TraceMenuLaunchLineProfiler()
	//"MXP z profile", MXP_TraceMenuLaunchZBeamProfiler()
	"MXP Scale Image", MXP_ScaleImage()
	"MXP Normalise stack with profile", MXP_NormaliseImageStackWithProfile()
	"MXP Select image to copy scales", MXP_ImageSelectToCopyScale()
	//"MXP Average stack",  MXP_LaunchAverageStackToImageFromTraceMenu()
	"MXP Calculate XMC(L)D", MXP_LaunchCalculateXMCDFromStack()
	"MXP Draw Image Markups", MXP_AppendMarkupsToTopImage() // NB: Add conditions to work only with images
	"MXP Clear UserFront layer", MXP_ClearROIMarkings()
End
