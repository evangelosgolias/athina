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
		".dat file...", /Q, ATH_LoadSingleDATFile("", "", autoscale = 1)
		".dat files...", /Q, ATH_LoadMultiplyDATFiles(autoscale = 1)
		".dat files in folder...", /Q, ATH_LoadDATFilesFromFolder("", "*", autoscale = 1)
		".dat files in folder to stack ...", /Q, ATH_LauncherLoadDATFilesFromFolder()
		".dav file in stack...", /Q, ATH_LoadSingleDAVFile("", "", stack3d = 1, skipmetadata = 1, autoscale = 1)
		".dav file...", /Q, ATH_LoadSingleDAVFile("", "", autoscale = 1)
		".dat file (img only)...", /Q, ATH_LoadSingleCorruptedDATFile("", "")
		".h5 file ...", /Q, ATH_LauncherLoadHDF5GroupsFromFile()
	End

	End
	
	Submenu "Image Operations"
		"Average layers (range) (TG, 3D)", /Q, ATH_LaunchAverageLayersRange()
		"Average image stack(TG, 3D)", /Q, ATH_LaunchAverageImagePlanes()
		"Append image(s) to stack (TG, 3D)", /Q, ATH_LaunchStackImagesToImageStack()
		"Insert image at slider position  (TG, 3D)", /Q, ATH_LaunchInsertImageToStack()
		"Extract layers to stack (TG, 3D)", /Q, ATH_LaunchExtractLayerRangeToStack()
		"Remove layers from stack (TG, 3D)", /Q, ATH_LaunchRemoveImagesFromImageStack()
		"Sum image stack(TG, 3D)", /Q, ATH_LaunchSumImagePlanes()				
		"New image (stack) from saved ROI (TG, 2D, 3D)", /Q, ATH_LaunchMakeWaveFromSavedROI()
		"Pixelate image (TG, 2D, 3D)", /Q, ATH_LaunchPixelateSingleImageOrStack()
		"FFT (TG, 2D)", /Q, ATH_LaunchImageFFTTransform()
		"Rotate image (TG, 2D, 3D) ", /Q, ATH_LaunchImageRotateAndScale()
		"Rotate image from metadata (TG, 2D, 3D)", /Q, ATH_LaunchImageRotateAndScaleFromMetadata()
		"Remove background (TG, 2D, 3D)", /Q, ATH_LaunchImageRemoveBackground()	
		"Duplicate image and data (TG, 2D, 3D)", /Q, ATH_DuplicateWaveAndDisplayOfTopImage()
		"Backup Image (TG)", /Q, ATH_BackupTopImage()	
		"Restore image from backup (TG)", /Q, ATH_RestoreTopImageFromBackup()
		"Normalize to [0, 1] (TG)", /Q, ATH_LaunchScalePlanesBetweenZeroAndOne()
		"Center image histogram (TG)", /Q, ATH_LaunchHistogramShiftToGaussianCenter()
		"Rotate 3d wave axes (TG, 3D)", /Q, ATH_LaunchRotate3DWaveAxes()
	End
	
	Submenu "Interactive Operations"
		"Rotate image (TG, 2D, 3D) ", /Q,  ATH_CreateInteractiveImageRotationPanel()
		"Drift correction (TG, 2D, 3D) ", /Q, ATH_CreateInteractiveDriftCorrectionPanel()
		"XMC(L)D calculation ...", /Q, ATH_LaunchInteractiveXMCDCalculationFromMenu()
	End
	
	Submenu "Drift Correction"
		"Using a feature (TG, 3D)", /Q, ATH_LaunchImageStackAlignmentPartition()
		"Using the full image (TG, 3D)", /Q, ATH_LaunchImageStackAlignmentFullImage()
		"Linear drift correction (TG, 3D)",/Q, ATH_LaunchLinearImageStackAlignmentUsingABCursors()

	End
	
	Submenu "Profiles "
		"Line profile (TG, 2D, 3D)", /Q, ATH_MainMenuLaunchLineProfile()
		"Z profile (TG, 3D)", /Q, ATH_MainMenuLaunchSumBeamsProfile()
		"Plane profile (TG, 3D)",/Q, ATH_MainMenuLaunchImagePlaneProfileZ()
	End

	Submenu "XMC(L)D calculation"
		"XMC(L)D (Import two .dat files) ...", /Q, ATH_DialogLoadTwoImagesAndRegisterQ()
		"XMC(L)D (3D[2]) ... ", /Q, ATH_LaunchCalculationXMCD3d()
		"XMC(L)D (2D[2]) ...", /Q, ATH_LaunchRegisterQCalculateXRayDichroism()
		"XMC(L)D combinations (3D[1]) ...", /Q, ATH_LaunchXMCDCombinations()
	End	
		
	Submenu "XPS"
		"Extract XPS profile from image (TG, 2D)", /Q, ATH_MainMenuLaunchPESExtractor()
		"Subtract background(TG, 1D) ", /Q, BackgroundSubtractGUI()
	End	
	
	Submenu "Utilities"
		"Spaces",/Q, ATH_MainMenuLaunchSpaces()
		"Free space",/Q, ATH_LaunchDeleteBigWaves()
		"List HDF5 (.h5) entries...", /Q, ATH_ListHDF5Groups()		
		"Photoionisation CrossSection",/Q, PhotoionisationCrossSection#PhotoionisationCrossSection()
	End
	Submenu "Beamtime"
		"Set experiment's root folder",/Q, ATH_SetOrResetBeamtimeRootFolder()
		"Load newest file",/Q, ATH_LoadNewestFileInPathTreeAndDisplayPython(".dat")
		"Load newest folder to stack",/Q, ATH_LoadNewestFolderInPathTreeAndDisplay()
		"Load two newest files to stack",/Q, ATH_LoadNewestTwoFilesInPathTreeAndDisplayPython(".dat")

	End
End


// -------------------------------------------------------

Menu "GraphMarquee"
	"ATH Image range 96% of ROI (2D, 3D)", /Q, ATH_SetImageRangeTo94Percent()
	"ATH Print ROI stats (2D, 3D)", /Q, ATH_GetMarqueeWaveStats()
	"ATH Save Rect ROI (2D, 3D)", /Q, ATH_SaveROICoordinatesToDatabase(rect = 1)		
	"ATH Save Oval ROI (2D, 3D)", /Q, ATH_SaveROICoordinatesToDatabase()
	"ATH Z-profiler: Set rectangular ROI  (3D)", /Q, ATH_GraphMarqueeLaunchRectangleSumBeamsProfile()	
	"ATH Z-profiler: Set oval ROI  (3D)", /Q, ATH_GraphMarqueeLaunchOvalSumBeamsProfile()
	//"ATH Marquee to mask (2D, 3D)", /Q, ATH_MarqueeToMask()
	"ATH Backup traces (1D)", /Q, ATH_BackupTraces()
	"ATH Restore traces (1D)", /Q, ATH_RestoreTraces()
	"ATH Normalise to profile (1D)", /Q, ATH_NormaliseTracesWithProfile()
	"ATH Normalize to one (1D)", /Q, ATH_NormalizeToOne()
	"ATH Pull to zero (1D)", /Q, ATH_PullToZero()
	"ATH Maximum to one (1D)", /Q, ATH_MaximumToOne()
	"ATH Partition region (2D, 3D)", /Q, ATH_Partition3DRegion()
End

Menu "DataBrowserObjectsPopup"
	"ATH Newimage", /Q, ATH_LaunchNewImageFromBrowserSelection()
	"ATH Average stack", /Q, ATH_LaunchAverageStackToImageFromBrowserMenu()
	"ATH Make stack", /Q, ATH_LaunchMake3DWaveDataBrowserSelection()
	"ATH Make stack and display", /Q, ATH_LaunchMake3DWaveDataBrowserSelection(displayStack = 1)
	"ATH Restore image from backup", /Q, ATH_LaunchImageBackupFromBrowserSelection()
	Submenu "ATH Profiles"
		"ATH Z profile", /Q, ATH_BrowserMenuLaunchSumBeamsProfile()
		"ATH Line profile", /Q, ATH_BrowserMenuLaunchLineProfile()
		"ATH Plane profile", /Q, ATH_BrowserMenuLaunchImagePlaneProfileZ()
	End	
	Submenu "ATH Normalise"
		"ATH Stack with image", /Q, ATH_LaunchNormalisationImageStackWithImage()
		"ATH Stack with profile", /Q, ATH_LaunchNormalisationImageStackWithProfile()
		"ATH Stack with stack", /Q, ATH_LaunchNormalisationImageStackWithImageStack()
	End
End

Menu "TracePopup"
	"ATH Autoscale Image (2D, 3D)", /Q, ATH_AutoRangeTopImage()
	"ATH Dynamic Autoscale Image Plane (3D)", /Q, ATH_AutoRangeTopImagePerPlaneAndVisibleArea()
	"ATH Z-profiler: Use saved ROI  (3D)", /Q, ATH_TracePopupLaunchSavedROISumBeamsProfile()		
	"ATH Save layer (TG, 3D)", /Q, ATH_GetLayerFromImageStack()
	"ATH Save current view (TG, 2D, 3D)", /Q, ATH_GetScaledZoominImageWindow()
	"ATH Scale Image stack (TG, 3D)", /Q, ATH_SetZScaleOfImageStack()
	"ATH Select image and copy scales (2D, 3D)", /Q, ATH_ImageSelectToCopyScale()
	"ATH Backup Image (2D, 3D)", /Q, ATH_BackupTopImage()	
	"ATH Restore image (2D, 3D)", /Q, ATH_RestoreTopImageFromBackup()
	"ATH Calculate XMC(L)D (3D[2])", /Q, ATH_LaunchCalculateXMCDFromStack()
	"ATH Measure Distance (TG)", /Q, ATH_MeasureDistanceUsingFreeCursorsCD()
	Submenu "ATH markups ..."
	"ATH Clear UserFront layer" ,/Q, ATH_ClearROIMarkingsUserFront()
	"ATH Draw .dat markups", /Q, ATH_AppendMarkupsToTopImage() // NB: Add conditions to work only with images
	End
End

Menu "GraphPopup" // Right click not on a trace or in the margin of an image
	"ATH Text Annotation (TG)", /Q, ATH_LaunchQuickTextAnnotation()
	"ATH Measure Distance (TG)", /Q, ATH_MeasureDistanceUsingFreeCursorsCD()
End

//Menu "AllTracesPopup" // Use SHIFT + right click
//	//
//End