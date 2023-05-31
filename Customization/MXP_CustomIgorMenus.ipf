﻿#pragma TextEncoding = "UTF-8"
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
	
	Submenu "Image Operations"
		"FFT (TG, 2D)", /Q, MXP_LaunchImageFFTTransform()
		"Rotate image (TG, 2D, 3D) ", /Q, MXP_LaunchImageRotateAndScale()
		"Rotate image from metadata (TG, 2D, 3D)", /Q, MXP_LaunchImageRotateAndScaleFromMetadata()
		"Restore image from backup (TG)", /Q, MXP_RestoreTopImageFromBackup()
	End
	
	Submenu "Interactive Operations"
		"Rotate image (TG, 2D, 3D) ", /Q,  MXP_CreateInteractiveImageRotationPanel()
		"Drift correction (TG, 2D, 3D) ", /Q, MXP_CreateInteractiveDriftCorrectionPanel() // TODO: Needs some tuning.
		"XMC(L)D calculation ...", /Q, print "Not yet implemented"
	End
	
	Submenu "Drift Correction"
		"Using a feature, fixed ref (TG)...", /Q, MXP_LaunchImageStackAlignmentUsingAFeature()
		"Using a feature, cascade ref (TG)...", /Q, MXP_LaunchCascadeImageStackAlignmentUsingAFeature()		
		"Using the full image, fixed ref (TG)...", /Q, MXP_LaunchImageStackAlignmentByFullImage()
		"Using the full image, cascade ref (TG)...", /Q, MXP_LaunchCascadeImageStackAlignmentByFullImage()	// TODO	
	End
	
	Submenu "Profiles "
		"Line profile (TG)", /Q, MXP_MainMenuLaunchLineProfile()
		"Z profile (TG)", /Q, MXP_MainMenuLaunchSumBeamsProfile()
		"Plane profile (TG)",/Q, MXP_MainMenuLaunchImagePlaneProfileZ()
	End
	
	Submenu "Calculations"
		"Average stack (3D)...", /Q, MXP_LaunchAverageStackToImageFromMenu()
		"XMC(L)D (TG, 3D[2])...", /Q, MXP_LaunchRegisterQCalculateXRayDichroism()
		"XMC(L)D (import)...", /Q, MXP_DialogLoadTwoImagesInFolderRegisterQCalculateXRayDichroism()
	End
	
	Submenu "XPS"
		"Extract XPS profile from image (TG)", /Q, MXP_MainMenuLaunchPESExtractor()
		"Subtract background(TG) ", /Q, BackgroundSubtractGUI()
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
	"MXP Set image range using ROI (2D, 3D)", /Q, MXP_SetImageRangeTo94Percent()
	"MXP ROI stats (2D, 3D)", /Q, MXP_GetMarqueeWaveStats()
	"MXP Z-profiler: Set oval ROI  (3D)", /Q, MXP_DrawOvalROIAndWaitHookToAct()
	"MXP Z-profiler: Set rectangular ROI  (3D)", /Q, MXP_DrawRectROIAndWaitHookToAct()	
	"MXP Marquee to mask (2D, 3D)", /Q, MXP_MarqueeToMask()
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
	"MXP Z profile", /Q, MXP_BrowserMenuLaunchSumBeamsProfile()
	"MXP Line profile", /Q, MXP_BrowserMenuLaunchLineProfile()
	"MXP Plane profile", /Q, MXP_BrowserMenuLaunchImagePlaneProfileZ()
	"MXP Average stack", /Q, MXP_LaunchAverageStackToImageFromBrowserMenu()
	"MXP Make stack", /Q, MXP_LaunchMake3DWaveDataBrowserSelection()
	"MXP Make stack and display", /Q, MXP_LaunchMake3DWaveDataBrowserSelection(displayStack = 1)
	Submenu "MXP Normalise"
		"MXP Stack with image", /Q, MXP_LaunchNormalisationImageStackWithImage()
		"MXP Stack with profile", /Q, MXP_LaunchNormalisationImageStackWithProfile()
		"MXP Stack with stack", /Q, MXP_LaunchNormalisationImageStackWithImageStack()
	End
End

Menu "TracePopup"
	"MXP Autoscale Image (2D, 3D)", /Q, MXP_AutoRangeTopImage()
	"MXP Dynamic Autoscale Image Plane (3D)", /Q, MXP_AutoRangeTopImagePerPlaneAndVisibleArea()	
	"MXP Save layer (3D)", /Q, MXP_GetLayerFromImageStack()
	"MXP Save current view (2D,3D)", /Q, MXP_GetScaledZoominImageWindow()
	"MXP Add images to Stack (3D)", /Q, MXP_LaunchStackImagesToImageStack()
	"MXP Scale Image stack (3D)", /Q, MXP_SetScaleOfImageStack()
	"MXP Select image and copy scales (2D,3D)", /Q, MXP_ImageSelectToCopyScale()
	"MXP Calculate XMC(L)D (3D[2])", /Q, MXP_LaunchCalculateXMCDFromStack()
	Submenu "MXP markups ..."
	"MXP Draw image markups", /Q, MXP_AppendMarkupsToTopImage() // NB: Add conditions to work only with images
	"MXP Clear UserFront layer" ,/Q, MXP_ClearROIMarkingsUserFront()
	End
End

// Hidden operations
//	Submenu "Misc"
//		"Make a stack from pattern", /Q, MXP_LaunchMake3DWaveUsingPattern()
//		"Make a stack from browser selection", /Q, MXP_LaunchMake3DWaveDataBrowserSelection()
//	End