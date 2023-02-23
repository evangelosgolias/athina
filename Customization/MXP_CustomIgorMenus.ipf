#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: evangelos.golias@gmail.com
//	
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//	
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
// ------------------------------------------------------- //


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
		Submenu "XPS"
		"Subtract background ... ", BackgroundSubtractGUI($StringFromList(0,MXP_SelectWavesInModalDataBrowser("Select a wave (1d)")))
		End
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
		"Line profile...", MXP_MainMenuLaunchLineProfile()
		"Z profile...", MXP_MainMenuLaunchSumBeamsProfile()
		"Plane profile...", MXP_MainMenuLaunchImagePlaneProfileZ()
	End
	
	Submenu "Information"
		"Photoionisation CrossSection",/Q, PhotoionisationCrossSection#PhotoionisationCrossSection()
		"List entries in a HDF (.h5) file...", MXP_ListHDF5Groups()
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
	"MXP Z profile", MXP_BrowserMenuLaunchSumBeamsProfile()
	"MXP Line profile", MXP_BrowserMenuLaunchLineProfile()
	"MXP Plane profile", MXP_BrowserMenuLaunchImagePlaneProfileZ()
	"MXP Average stack",  MXP_LaunchAverageStackToImageFromBrowserMenu()
	"MXP Make stack", MXP_LaunchMake3DWaveDataBrowserSelection()
	"MXP Make stack and display", MXP_LaunchMake3DWaveDataBrowserSelection(displayStack = 1)
	Submenu "MXP Normalise"
		"Stack with image", MXP_LaunchNormalisationImageStackWithImage()
		"Stack with profile", MXP_LaunchNormalisationImageStackWithProfile()
		"Stack with stack", MXP_LaunchNormalisationImageStackWithImageStack()
	End
End

Menu "TracePopup"
	//"-"
	//"MXP line profile", MXP_TraceMenuLaunchLineProfiler()
	//"MXP z profile", MXP_TraceMenuLaunchZBeamProfiler()
	//"MXP Normalise stack with profile", MXP_NormaliseImageStackWithProfile()
	//"MXP Average stack",  MXP_LaunchAverageStackToImageFromTraceMenu()
	"MXP Save layer (3D)", MXP_GetLayerFromImageStack()
	"MXP Stack image (3D)", MXP_LaunchStackImageToImageStack()
	"MXP Scale Image stack (3D)", MXP_ScaleImage()
	"MXP Select image and copy scales (2D,3D)", MXP_ImageSelectToCopyScale()
	"MXP Interactive drift correction (3D)", MXP_CreateInteractiveDriftCorrectionPanel()
	"MXP Calculate XMC(L)D (3D[2])", MXP_LaunchCalculateXMCDFromStack()
	//"MXP Remove XPS background", MXP_LaunchRemoveXPSBackground()
	//"MXP BE-Scale XPS spectrum", MXP_LaunchScaleXPSSpectrum()
	Submenu "MXP markups ..."
	"MXP Draw image markups", MXP_AppendMarkupsToTopImage() // NB: Add conditions to work only with images
	"MXP Clear UserFront layer", MXP_ClearROIMarkingsUserFront()
	End
End

Menu "GraphPopup"
	"MXP BE-Scale XPS spectrum", MXP_LaunchScaleXPSSpectrum()
End
