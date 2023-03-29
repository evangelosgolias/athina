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
		".dat file...", /Q, MXP_LoadSingleDATFile("", "", autoscale = 1)
		".dat files...", /Q, MXP_LoadMultiplyDATFiles(autoscale = 1)
		".dat files in folder...", /Q, MXP_LoadDATFilesFromFolder("", "*", autoscale = 1)
		".dat files in folder to stack ...", /Q, MXP_LauncherLoadDATFilesFromFolder()
		".dav file in stack...", /Q, MXP_LoadSingleDAVFile("", "", stack3d = 1, skipmetadata = 1, autoscale = 1)
		".dav file...", /Q, MXP_LoadSingleDAVFile("", "", autoscale = 1)
		".dat file (img only)...", /Q, MXP_LoadSingleCorruptedDATFile("", "")
		".h5 file ...", /Q, MXP_LauncherLoadHDF5GroupsFromFile()
	End
	
	Submenu "Analyse"
		Submenu "XPS"
		//"Subtract background ... ", BackgroundSubtractGUI($StringFromList(0,MXP_SelectWavesInModalDataBrowser("Select a wave (1d)")))
		"Subtract background (TG) ", /Q, BackgroundSubtractGUI()
		End
	End
	
	Submenu "Align"
		"using a feature (recommended) (TG)...", /Q, MXP_LaunchImageStackAlignmentUsingAFeature()
		"using the full image (TG)...", /Q, MXP_LaunchImageStackAlignmentByFullImage()
	End
	
	Submenu "Make"
		"a stack from pattern", /Q, MXP_LaunchMake3DWaveUsingPattern()
		"a stack from browser selection", /Q, MXP_LaunchMake3DWaveDataBrowserSelection()
	End
	
	Submenu "Calculation"
		"Stack average...", /Q, MXP_LaunchAverageStackToImageFromMenu()
		"Calculate XMC(L)D (TG)...", /Q, MXP_LaunchRegisterQCalculateXRayDichroism()
		"Calculate XMC(L)D interactively...", /Q, MXP_LaunchInteractiveCalculateXRayDichroism()
		"Import .dat files and calculate XMC(L)D...", /Q, MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()
	End
	
	Submenu "Profiles "
		"Line profile (TG)", /Q, MXP_MainMenuLaunchLineProfile()
		"Z profile (TG)", /Q, MXP_MainMenuLaunchSumBeamsProfile()
		"Plane profile (TG)",/Q, MXP_MainMenuLaunchImagePlaneProfileZ()
	End
	
	Submenu "Utilities"
		"Spaces",/Q, MXP_MainMenuLaunchSpaces()
		"Photoionisation CrossSection",/Q, PhotoionisationCrossSection#PhotoionisationCrossSection()
		"List HDF5 (.h5) entries...", /Q, MXP_ListHDF5Groups()
	End
End

Menu "GraphMarquee"
	"Oval ROI z profile (3D)", /Q, MXP_DrawROIAndWaitHookToAct()
	"ROI stats (2D, 3D)", /Q, MXP_GetMarqueeWaveStats()
	"Marquee to mask (2D, 3D)", /Q, MXP_MarqueeToMask()
	"Backup traces (1D)", /Q, MXP_BackupTraces()
	"Restore traces (1D)", /Q, MXP_RestoreTraces()
	"Normalise to profile (1D)", /Q, MXP_NormaliseTracesWithProfile()
	"Normalize to one (1D)", /Q, MXP_NormalizeToOne()
	"Pull to zero (1D)", /Q, MXP_PullToZero()
	"Maximum to one (1D)", /Q, MXP_MaximumToOne()
	"Partition 3D region (3D)", /Q, MXP_Partition3DRegion()
End


Menu "DataBrowserObjectsPopup"
	"MXP Newimage", /Q, MXP_LaunchNewImageFromBrowserSelection()
	"MXP Z profile", /Q, MXP_BrowserMenuLaunchSumBeamsProfile()
	"MXP Line profile", /Q, MXP_BrowserMenuLaunchLineProfile()
	"MXP Plane profile", /Q, MXP_BrowserMenuLaunchImagePlaneProfileZ()
	"MXP Average stack", /Q, MXP_LaunchAverageStackToImageFromBrowserMenu()
	"MXP Make stack", /Q, MXP_LaunchMake3DWaveDataBrowserSelection()
	"MXP Make stack and display", /Q, MXP_LaunchMake3DWaveDataBrowserSelection(displayStack = 1)
	Submenu "MXP Normalise"
		"Stack with image", /Q, MXP_LaunchNormalisationImageStackWithImage()
		"Stack with profile", /Q, MXP_LaunchNormalisationImageStackWithProfile()
		"Stack with stack", /Q, MXP_LaunchNormalisationImageStackWithImageStack()
	End
End

Menu "TracePopup"
	//"-"
	//"MXP line profile", MXP_TraceMenuLaunchLineProfiler()
	//"MXP z profile", MXP_TraceMenuLaunchZBeamProfiler()
	//"MXP Normalise stack with profile", MXP_NormaliseImageStackWithProfile()
	//"MXP Average stack",  MXP_LaunchAverageStackToImageFromTraceMenu()
	"MXP Save layer (3D)", /Q, MXP_GetLayerFromImageStack()
	"MXP Save current view (2D,3D)", /Q, MXP_GetScaledZoominImageWindow()
	"MXP Add images to Stack (3D)", /Q, MXP_LaunchStackImagesToImageStack()
	"MXP Scale Image stack (3D)", /Q, MXP_ScaleImage()
	"MXP Select image and copy scales (2D,3D)", /Q, MXP_ImageSelectToCopyScale()
	"MXP Interactive drift correction (3D)", /Q, MXP_CreateInteractiveDriftCorrectionPanel()
	"MXP Calculate XMC(L)D (3D[2])", /Q, MXP_LaunchCalculateXMCDFromStack()
	//"MXP Remove XPS background", MXP_LaunchRemoveXPSBackground()
	//"MXP BE-Scale XPS spectrum", /Q, MXP_LaunchScaleXPSSpectrum()
	Submenu "MXP markups ..."
	"MXP Draw image markups", /Q, MXP_AppendMarkupsToTopImage() // NB: Add conditions to work only with images
	"MXP Clear UserFront layer" ,/Q, MXP_ClearROIMarkingsUserFront()
	End
End

Menu "GraphPopup"
	"MXP BE-Scale XPS spectrum", /Q, MXP_LaunchScaleXPSSpectrum()
End
