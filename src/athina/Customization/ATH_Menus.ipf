#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma version = 1.01
// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: egolias@protonmail.com
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


Menu "athina"

	Submenu "Import"
		".dat files (MAXIV)...", /Q, ATH_Uview#LoadMultiplyDATFiles(autoscale = 1)
		".dat files in folder and stack .../1", /Q, ATH_Uview#LoadDATFilesFromFolder("", "*", stack3d = 1, autoscale = 1, displayImg = 1) 				
		".dat files and stack .../2", /Q, ATH_Uview#LoadMultiplyDATFiles(stack3d = 1, autoscale = 1, displayImg = 1)		
		".dat files in folder...", /Q, ATH_Uview#LoadDATFilesFromFolder("", "*", autoscale = 1)
		".tif (EMMENU5).../3", /Q, ATH_LoadImg#LoadTiff("", "", displayImg = 1)	
		".tifs (EMMENU5) and stack...", /Q, ATH_LoadImg#Loadtiffs(displayImg = 1, stack3d = 1)	
		".h5 file (MAXIV metadata) .../4", /Q, ATH_Launch#LoadHDF5GroupsFromFile()
		Submenu "Other"
		".nxs NeXus files (Diamond) ...",/Q, ATH_HDF5#LoadNXSDataSets()
		".P3B files (ALS)...",/Q, ATH_LoadImg#PEEM3Files()
		".P3B files and stack (ALS)...",/Q, ATH_LoadImg#PEEM3Files(stack3d=1)
		End
	End
	
	Submenu "Image Operations"
		"Average layers (range) (TG, 3D)", /Q, ATH_Launch#AverageLayersRange()
		"Average image stack(TG, 3D)", /Q, ATH_Launch#AverageImageStack()
		"Sum image stack(TG, 3D)", /Q, ATH_Launch#SumImagePlanes()		
		"Append image(s) to stack (TG, 3D)", /Q, ATH_Launch#StackImagesToImageStack()
		"Insert image at slider position  (TG, 3D)", /Q, ATH_Launch#InsertImageToStack()
		"Extract layers to stack (TG, 3D)", /Q, ATH_Launch#ExtractLayerRangeToStack()
		"Remove layers from stack (TG, 3D)", /Q, ATH_Launch#RemoveImagesFromImageStack()
		"Unpack layers to source waves (TG, 3D)",/Q, ATH_Launch#UnpackStackToSources()		
		"Pixelate image (TG, 2D, 3D)", /Q, ATH_Launch#PixelateSingleImageOrStack()
		"Resample image (TG, 2D)", /Q, ATH_Launch#ImageResample()
		"Flip stack planes (TG, 3D)", /Q, ATH_Launch#FlipStackPlanes()			
		"New image (stack) from saved ROI (TG, 2D, 3D)", /Q, ATH_Launch#MakeWaveFromSavedROI()
		"FFT (TG, 2D)", /Q, ATH_Launch#ImageFFTTransform()
		"Histogram Equalisation (TG, 2D, 3D)", /Q, ATH_Launch#HistogramEqualisation()
		"Rotate image from metadata (TG, 2D, 3D)", /Q, ATH_Launch#ImageRotateAndScaleFromMetadata()
		"Remove background (TG, 2D, 3D)", /Q, ATH_Launch#ImgRemoveBackground()
		"Remove background flattening (TG, 2D, 3D)", /Q, ATH_Launch#FlattenImage()		
		"RGB to gray 16-bit (DB, 3D)", /Q, ATH_Launch#ImgRGB2Gray16()
		"Duplicate image and data (TG, 2D, 3D)", /Q, ATH_Graph#DuplicateWaveAndDisplayOfTopImage()
		"Backup Image (TG)", /Q, ATH_ImgOp#BackupTopImage()	
		"Restore image from backup (TG)", /Q, ATH_ImgOp#RestoreTopImageFromBackup()
		"Normalize to [0, 1] (TG)", /Q, ATH_Launch#ScalePlanesBetweenZeroAndOne()
		"Center image histogram (TG)", /Q, ATH_Launch#HistogramShiftToGaussianCenter()
		"Rotate 3d wave axes (TG, 3D)", /Q, ATH_Launch#Rotate3DWaveAxes()
	End
	
	Submenu "Interactive Operations"
		"Drift correction (TG, 3D) ", /Q, ATH_iDriftCorrection#CreatePanel()
		"XMC(L)D calculation .../5", /Q, ATH_iXMCD#MenuLaunch()
		"Image calculation .../6", /Q, ATH_iImgOps#MainMenu()
		"Image rotation (TG, 2D, 3D) ", /Q,  ATH_iImgRotation#CreatePanel()		
	End
	
	Submenu "Drift Correction"
		"Using a feature (TG, 3D)", /Q, ATH_Launch#ImageStackAlignmentPartition()
		"Using the full image (TG, 3D)", /Q, ATH_Launch#ImageStackAlignmentFullImage()
		"Linear drift correction (TG, 3D)",/Q, ATH_Launch#LinearDriftCorrestionStackABCursors()
		"Linear drift correction [Range] (TG, 3D)",/Q, ATH_Launch#LinearDriftCorrestionPlanesABCursors()
	End
	
	Submenu "Profiles "
		"Line profile (TG, 2D, 3D)", /Q, ATH_LineProfile#MainMenu()
		"Plane profile (TG, 3D)",/Q, ATH_PlaneZProfile#MainMenu()	
		"(Z profile -> Use Marquee on TG (3D)"//, /Q, DoAlert 0, "Use Marquee for Z-profile!"
	End

	Submenu "XMC(L)D calculation"
		"XMC(L)D (2D[2]) ... ", /Q, ATH_Launch#CalculationXMCD()
		"XMC(L)D (3Dx2) ... ", /Q, ATH_Launch#CalculationXMCD3D()
		"XMC(L)D combinations (3Dx1) ...", /Q, ATH_Launch#XMCDCombinations()
	End	
		
	Submenu "Analysis"
		Submenu "Fitting"
			"Fast Fitting (1D, 2D, 3D)", /Q, FastFit#Initialise()
			"Remove Baselines (1D)", /Q, Baselines#Initialise()
		End
		Submenu "XPS"
			"Extract XPS profile from image (TG, 2D)", /Q, ATH_iXPS#MainMenu()
			"Extract XPS profile from saved settings (DB, 2D)", /Q, ATH_Launch#XPSProfileFromDefaultSettings()
			"Subtract background(TG, 1D) ", /Q, BackgroundSubtractGUI()
		End
	End	
	
	Submenu "Utilities"
		"Spaces/9",/Q, ATH_Spaces#MenuLaunch()
		"Free space/7",/Q, ATH_Launch#DeleteBigWaves()
		"Photoemission database",/Q, ATH_XPSData#XPSReferenceData()
		"Calculations Pad/8",/Q, ATH_CalcPad#CalcPad()
		"List HDF5 (.h5) entries...", /Q, ATH_HDF5#ListHDF5Groups()		
		"Load additional color maps", /Q, ATH_Color#loadColorTableAll()
		"Unload unused color maps", /Q, ATH_Color#ATH_ColorKillWaves()
	End
//	Submenu "Beamtime"
//		"Set experiment's root folder",/Q, ATH_Beamtime#SetOrResetBeamtimeRootFolder()
//		"Load newest file",/Q, ATH_Beamtime#LoadNewestFileInPathTreeAndDisplayPython(".dat")
//		"Load newest folder to stack",/Q, ATH_Beamtime#LoadNewestFolderInPathTreeAndDisplay()
//		"Load two newest files to stack",/Q, ATH_Beamtime#LoadNewestTwoFilesInPathTreeAndDisplayPython(".dat")
//
//	End
End


// -------------------------------------------------------

Menu "GraphMarquee"
	"ATH Z-profiler: Set rectangular ROI  (3D)", /Q, ATH_ZProfile#GraphMarqueeLaunchRectangle()	
	"ATH Z-profiler: Set oval ROI  (3D)", /Q, ATH_ZProfile#GraphMarqueeLaunchOval()	
	"ATH Save Rect ROI (2D, 3D)", /Q, ATH_Marquee#SaveROICoordinatesToDatabase(rect = 1)		
	"ATH Save Oval ROI (2D, 3D)", /Q, ATH_Marquee#SaveROICoordinatesToDatabase()
	"ATH Print ROI stats (2D, 3D)", /Q, ATH_Marquee#GetMarqueeWaveStats()	
	"ATH Partition region (2D, 3D)", /Q, ATH_Marquee#PartitionRegion(evenNum=1)
	"ATH Partition square region (2D, 3D)", /Q, ATH_Marquee#PartitionRegion(square=1)		
			
	SubMenu "ATH Trace Calcs (TG, 1D[2])"
		"ATH Backup traces", /Q, ATH_Traces#MarqueeToTraceOperation(3)
		"ATH Restore traces", /Q, ATH_Traces#MarqueeToTraceOperation(4)
		"ATH Normalise to profile", /Q, ATH_Traces#MarqueeToTraceOperation(5)
		"ATH Normalize to one", /Q, ATH_Traces#MarqueeToTraceOperation(1)
		"ATH Pull to zero", /Q, ATH_Traces#MarqueeToTraceOperation(0)
		"ATH Maximum to one", /Q, ATH_Traces#MarqueeToTraceOperation(2)
		"ATH Custom calculation ...", /Q, ATH_Launch#TwoTraceCalcs()
	End	
End

Menu "DataBrowserObjectsPopup"
	"ATH Newimage", /Q, ATH_Launch#NewImageFromBrowserSelection()
	"ATH Transient Stack", /Q, ATH_Launch#Make3DWaveDataBrowserSelection(displayStack = 1, transientStack=1)		
	"ATH Average stack", /Q, ATH_Launch#AverageStackToImageFromBrowserMenu()
	"ATH Make Stack", /Q, ATH_Launch#Make3DWaveDataBrowserSelection()
	"ATH Make Stack and display", /Q, ATH_Launch#Make3DWaveDataBrowserSelection(displayStack = 1)
	"ATH Restore from backup", /Q, ATH_Launch#ImageBackupFromBrowserSelection()
	Submenu "ATH Normalise"
		"ATH Stack with image", /Q, ATH_Launch#NormalisationImageStackWithImage()
		"ATH Stack with profile", /Q, ATH_Launch#NormalisationImageStackWithProfile()
		"ATH Stack with stack", /Q, ATH_Launch#NormalisationImageStackWithImageStack()
	End
End

Menu "TracePopup"
	"ATH Save Axes\Color Range (TG, 2D, 3D)",/Q, ATH_Launch#SaveAxesRangeAndCtab()
	"ATH Set Saved Axes Range and Ctab (TG, 2D, 3D)",/Q, ATH_Launch#SetAxesRangeAndCtabFromSaved(setCtab=1)
	"ATH Set Saved Axes Range (TG, 2D, 3D)",/Q, ATH_Launch#SetAxesRangeAndCtabFromSaved()		
	"ATH Save layer (TG, 3D)", /Q, ATH_ImgOp#GetLayerFromImageStack()
	"ATH Save current view (layer) (TG, 2D, 3D)", /Q, ATH_ImgOp#GetScaledZoominImageWindow(evenNum=1)
	"ATH Partition current view (3D)", /Q, ATH_ImgOp#GetScaledZoominImageWindow(w3d=1, evenNum=1)	
	"ATH Z-profiler: Use saved ROI  (3D)", /Q, ATH_ZProfile#TracePopupLaunchSavedROI()	
	"ATH Scale Image stack (TG, 3D)", /Q, ATH_ImgOp#SetZScaleOfImageStack()
	"ATH Select image and copy scales (2D, 3D)", /Q, ATH_ImgOp#ImageSelectToCopyScale()
	"ATH Backup Image (2D, 3D)", /Q, ATH_ImgOp#BackupTopImage()	
	"ATH Restore image (2D, 3D)", /Q, ATH_ImgOp#RestoreTopImageFromBackup()
	"ATH Clear UserFront layer" ,/Q, ATH_ZProfile#ClearROIMarkingsUserFront("")	
End

Menu "GraphPopup" // Right click not on a trace or in the margin of an image
	"ATH Text Annotation (TG)", /Q, ATH_Launch#QuickTextAnnotation()
	"ATH SetDataFolder (TG)", /Q, ATH_Launch#SetTopGraphDF()
	"ATH Measure Distance (TG)", /Q, ATH_Cursors#MeasureDistanceUsingFreeCursors()
	"ATH Clear UserFront layer" ,/Q, ATH_ZProfile#ClearROIMarkingsUserFront("")	

End

Menu "AllTracesPopup" // Use SHIFT + right click
	"ATH Close and delete (TG)", /Q, ATH_Launch#CloseTopWindowAndDeleteSource(deleteBackUp=1)
End