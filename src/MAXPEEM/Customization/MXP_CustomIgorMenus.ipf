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


Menu "Athina"

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
	
	Submenu "Image Operations"
		"Average layers (range) (TG, 3D)", /Q, MXP_LaunchAverageLayersRange()
		"Average image stack(TG, 3D)", /Q, MXP_LaunchAverageImagePlanes()
		"Append image(s) to stack (TG, 3D)", /Q, MXP_LaunchStackImagesToImageStack()
		"Insert image at slider position  (TG, 3D)", /Q, MXP_LaunchInsertImageToStack()
		"Extract layers to stack (TG, 3D)", /Q, MXP_LaunchExtractLayerRangeToStack()
		"Remove layers from stack (TG, 3D)", /Q, MXP_LaunchRemoveImagesFromImageStack()
		"Sum image stack(TG, 3D)", /Q, MXP_LaunchSumImagePlanes()				
		"New image (stack) from saved ROI (TG, 2D, 3D)", /Q, MXP_LaunchMakeWaveFromSavedROI()
		"FFT (TG, 2D)", /Q, MXP_LaunchImageFFTTransform()
		"Rotate image (TG, 2D, 3D) ", /Q, MXP_LaunchImageRotateAndScale()
		"Rotate image from metadata (TG, 2D, 3D)", /Q, MXP_LaunchImageRotateAndScaleFromMetadata()
		"Remove plane background (TG, 2D)", /Q, MXP_LaunchImageRemoveBackground()	
		"Duplicate image and data (TG, 2D, 3D)/1", /Q, MXP_DuplicateWaveAndDisplayOfTopImage()
		"Backup Image (TG)", /Q, MXP_BackupTopImage()	
		"Restore image from backup (TG)", /Q, MXP_RestoreTopImageFromBackup()
		"Normalize to [0, 1] (TG)", /Q, MXP_LaunchScalePlanesBetweenZeroAndOne()
		"Center image histogram (TG)", /Q, MXP_LaunchHistogramShiftToGaussianCenter()
		"Rotate 3d wave axes (TG, 3D)", /Q, MXP_LaunchRotate3DWaveAxes()
	End
	
	Submenu "Interactive Operations"
		"Rotate image (TG, 2D, 3D) ", /Q,  MXP_CreateInteractiveImageRotationPanel()
		"Drift correction (TG, 2D, 3D) ", /Q, MXP_CreateInteractiveDriftCorrectionPanel()
		"XMC(L)D calculation ...", /Q, MXP_LaunchInteractiveImageDriftCorrectionFromMenu()
	End
	
	Submenu "Drift Correction"
		"Using a feature (TG, 3D)", /Q, MXP_LaunchImageStackAlignmentUsingAFeature()
		"Using the full image (TG, 3D)", /Q, MXP_LaunchImageStackAlignmentByFullImage()
		"Linear drift correction (TG, 3D)",/Q, MXP_LaunchLinearImageStackAlignmentUsingABCursors()

	End
	
	Submenu "Profiles "
		"Line profile (TG, 2D, 3D)", /Q, MXP_MainMenuLaunchLineProfile()
		"Z profile (TG, 3D)", /Q, MXP_MainMenuLaunchSumBeamsProfile()
		"Plane profile (TG, 3D)",/Q, MXP_MainMenuLaunchImagePlaneProfileZ()
	End

	Submenu "XMC(L)D calculation"
		"XMC(L)D (Import two .dat files) ...", /Q, MXP_DialogLoadTwoImagesAndRegisterQ()
		"XMC(L)D (3D[2]) ... ", /Q, MXP_LaunchCalculationXMCD3d()
		"XMC(L)D (2D[2]) ...", /Q, MXP_LaunchRegisterQCalculateXRayDichroism()
	End	
		
	Submenu "XPS"
		"Extract XPS profile from image (TG, 2D)", /Q, MXP_MainMenuLaunchPESExtractor()
		"Subtract background(TG, 1D) ", /Q, BackgroundSubtractGUI()
	End	
	
	Submenu "Utilities"
		"Spaces",/Q, MXP_MainMenuLaunchSpaces()
		"Photoionisation CrossSection",/Q, PhotoionisationCrossSection#PhotoionisationCrossSection()
		"List HDF5 (.h5) entries...", /Q, MXP_ListHDF5Groups()
	End
	Submenu "Beamtime"
		"Set experiment's root folder",/Q, MXP_SetOrResetBeamtimeRootFolder()
		"Load newest file",/Q, MXP_LoadNewestFileInPathTreeAndDisplayPython(".dat")
		"Load newest folder to stack",/Q, MXP_LoadNewestFolderInPathTreeAndDisplay()
		"Load two newest files to stack",/Q, MXP_LoadNewestTwoFilesInPathTreeAndDisplayPython(".dat")

	End
End


// -------------------------------------------------------

Menu "GraphMarquee"
	"MXP Image range 96% of ROI (2D, 3D)", /Q, MXP_SetImageRangeTo94Percent()
	"MXP Print ROI stats (2D, 3D)", /Q, MXP_GetMarqueeWaveStats()
	"MXP Save Rect ROI (2D, 3D)", /Q, MXP_SaveROICoordinatesToDatabase(rect = 1)		
	"MXP Save Oval ROI (2D, 3D)", /Q, MXP_SaveROICoordinatesToDatabase()
	"MXP Z-profiler: Set rectangular ROI  (3D)", /Q, MXP_TraceMenuLaunchRectangleSumBeamsProfile()	
	"MXP Z-profiler: Set oval ROI  (3D)", /Q, MXP_TraceMenuLaunchOvalSumBeamsProfile()
	//"MXP Marquee to mask (2D, 3D)", /Q, MXP_MarqueeToMask()
	"MXP Backup traces (1D)", /Q, MXP_BackupTraces()
	"MXP Restore traces (1D)", /Q, MXP_RestoreTraces()
	"MXP Normalise to profile (1D)", /Q, MXP_NormaliseTracesWithProfile()
	"MXP Normalize to one (1D)", /Q, MXP_NormalizeToOne()
	"MXP Pull to zero (1D)", /Q, MXP_PullToZero()
	"MXP Maximum to one (1D)", /Q, MXP_MaximumToOne()
	"MXP Partition 3D region (3D)", /Q, MXP_Partition3DRegion()
End

Menu "DataBrowserObjectsPopup"
	"MXP Newimage", /Q, MXP_LaunchNewImageFromBrowserSelection()
	"MXP Average stack", /Q, MXP_LaunchAverageStackToImageFromBrowserMenu()
	"MXP Make stack", /Q, MXP_LaunchMake3DWaveDataBrowserSelection()
	"MXP Make stack and display", /Q, MXP_LaunchMake3DWaveDataBrowserSelection(displayStack = 1)
	"MXP Restore image from backup", /Q, MXP_LaunchImageBackupFromBrowserSelection()
	Submenu "MXP Profiles"
		"MXP Z profile", /Q, MXP_BrowserMenuLaunchSumBeamsProfile()
		"MXP Line profile", /Q, MXP_BrowserMenuLaunchLineProfile()
		"MXP Plane profile", /Q, MXP_BrowserMenuLaunchImagePlaneProfileZ()
	End	
	Submenu "MXP Normalise"
		"MXP Stack with image", /Q, MXP_LaunchNormalisationImageStackWithImage()
		"MXP Stack with profile", /Q, MXP_LaunchNormalisationImageStackWithProfile()
		"MXP Stack with stack", /Q, MXP_LaunchNormalisationImageStackWithImageStack()
	End
End

Menu "TracePopup"
	"MXP Autoscale Image (2D, 3D)", /Q, MXP_AutoRangeTopImage()
	"MXP Dynamic Autoscale Image Plane (3D)", /Q, MXP_AutoRangeTopImagePerPlaneAndVisibleArea()
	"MXP Z-profiler: Use saved ROI  (3D)", /Q, MXP_UseSavedROIAndWaitHookToAct()		
	"MXP Save layer (TG, 3D)", /Q, MXP_GetLayerFromImageStack()
	"MXP Save current view (TG, 2D, 3D)", /Q, MXP_GetScaledZoominImageWindow()
	"MXP Scale Image stack (TG, 3D)", /Q, MXP_SetZScaleOfImageStack()
	"MXP Select image and copy scales (2D, 3D)", /Q, MXP_ImageSelectToCopyScale()
	"MXP Calculate XMC(L)D (3D[2])", /Q, MXP_LaunchCalculateXMCDFromStack()
	Submenu "MXP markups ..."
	"MXP Draw image markups", /Q, MXP_AppendMarkupsToTopImage() // NB: Add conditions to work only with images
	"MXP Clear UserFront layer" ,/Q, MXP_ClearROIMarkingsUserFront()
	End
End

Menu "GraphPopup" // Right click not on a trace or in the margin of an image
	"MXP Text Annotation (TG)", /Q, MXP_LaunchQuickTextAnnotation()
	"MXP Measure Distance (TG)", /Q, MXP_MeasureDistanceUsingFreeCursorsCD()
End

Menu "AllTracesPopup" // Use SHIFT + right click
	"MXP Measure Distance (TG)", /Q, MXP_MeasureDistanceUsingFreeCursorsCD()
End