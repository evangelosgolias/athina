#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma DefaultTab={3,20,4}
#pragma IgorVersion = 9
#pragma ModuleName = ATH_OperationsPanel
#pragma version = 1.4

// ------------------------------------------------------- //
// Athina Operations Panel prototype
//
// Standalone add-on panel. This file intentionally does not modify Athina
// source files. It buttonizes the operations exposed in ATH_Menus.ipf in a
// compact flow-layout UI.
//
// Usage:
//     ATH_OperationsPanel#MenuLaunch()
// ------------------------------------------------------- //

/// @module ATH_OperationsPanel
/// @brief Compact one-for-all button palette for Athina operations.
/// @details
/// Category buttons act like compact tabs. Each category rebuilds the action
/// area as a compact left-to-right flow of text-sized buttons. Commands are
/// dispatched by string execution so optional Athina modules do not become
/// compile-time dependencies of this standalone prototype.

Static StrConstant ksOperationsPanelName = "ATH_OperationsPanel"
Static StrConstant ksPackageFolder = "root:Packages:ATH_DataFolder:OperationsPanel"
Static StrConstant ksPanelVersion = "1.4"
Static StrConstant ksCategoryNames = "Import/Utilities;Image Ops;Explore;Analysis;"
Static StrConstant ksCategoryButtons = "OP_CatImportUtilities;OP_CatImageOps;OP_CatExplore;OP_CatAnalysis;"

Static Constant kPanelWidth = 410
Static Constant kPanelHeight = 1000
Static Constant kLeft = 8
Static Constant kActionTop = 142
Static Constant kButtonHeight = 24
Static Constant kRowStep = 30
Static Constant kTextButtonPadding = 18
Static Constant kTextButtonCharWidth = 7.2
Static Constant kCategoryButtonGap = 4
Static Constant kActionButtonGap = 8

/// @function MenuLaunch
/// @brief Open or rebuild the compact Athina Operations Panel.
Static Function MenuLaunch()
	DFREF dfr = ATH_OperationsPanel#InitPackage()

	if(WinType(ksOperationsPanelName) == 7 && ATH_OperationsPanel#PanelIsCurrent())
		DoWindow/F $ksOperationsPanelName
		ATH_OperationsPanel#UpdateTargetTitle()
		return 0
	endif
	KillWindow/Z $ksOperationsPanelName

	PauseUpdate
	NewPanel/K=1/N=ATH_OperationsPanel/W=(80,70,80 + kPanelWidth,70 + kPanelHeight) as "Athina Operations Panel"
	ModifyPanel frameStyle=0
	SetWindow $ksOperationsPanelName, userdata(ATHPanelVersion)=ksPanelVersion

	TitleBox OP_Title, pos={kLeft,7}, size={250,22}, title="Athina Operations", frame=0, fSize=16, fStyle=1
	TitleBox OP_Target, pos={kLeft,32}, size={kPanelWidth - 16,19}, title="Target: no active image window", frame=0, fSize=12

	variable catX = kLeft
	variable catY = 58
	variable catW = ATH_OperationsPanel#TextButtonWidth("Import/Utilities", 0)
	ATH_OperationsPanel#AddCategoryButton("OP_CatImportUtilities", "Import/Utilities", 0, catX, catY, catW)
	catX += catW + kCategoryButtonGap
	catW = ATH_OperationsPanel#TextButtonWidth("Image Ops", 0)
	ATH_OperationsPanel#AddCategoryButton("OP_CatImageOps", "Image Ops", 1, catX, catY, catW)
	catX += catW + kCategoryButtonGap
	catW = ATH_OperationsPanel#TextButtonWidth("Explore", 0)
	ATH_OperationsPanel#AddCategoryButton("OP_CatExplore", "Explore", 2, catX, catY, catW)

	catX = kLeft
	catY = 84
	catW = ATH_OperationsPanel#TextButtonWidth("Analysis", 0)
	ATH_OperationsPanel#AddCategoryButton("OP_CatAnalysis", "Analysis", 3, catX, catY, catW)

	TitleBox OP_CategoryTitle, pos={kLeft,116}, size={kPanelWidth - 16,20}, title="Import/Utilities", frame=0, fSize=14, fStyle=1
	TitleBox OP_CommandPreview, pos={kLeft,kPanelHeight - 38}, size={kPanelWidth - 16,18}, title="", frame=0, fSize=10

	ATH_OperationsPanel#ShowCategory(0)
	ATH_OperationsPanel#UpdateTargetTitle()
	return 0
End

Static Function/DF InitPackage()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:ATH_DataFolder
	NewDataFolder/O root:Packages:ATH_DataFolder:OperationsPanel

	DFREF dfr = $ksPackageFolder
	NVAR/Z/SDFR=dfr gActiveCategory
	NVAR/Z/SDFR=dfr gBuildRow
	NVAR/Z/SDFR=dfr gBuildCol
	NVAR/Z/SDFR=dfr gActionIndex
	NVAR/Z/SDFR=dfr gSectionIndex
	if(!NVAR_Exists(gActiveCategory))
		variable/G dfr:gActiveCategory = 0
	endif
	if(!NVAR_Exists(gBuildRow))
		variable/G dfr:gBuildRow = 0
	endif
	if(!NVAR_Exists(gBuildCol))
		variable/G dfr:gBuildCol = 0
	endif
	if(!NVAR_Exists(gActionIndex))
		variable/G dfr:gActionIndex = 0
	endif
	if(!NVAR_Exists(gSectionIndex))
		variable/G dfr:gSectionIndex = 0
	endif

	return dfr
End

Static Function PanelIsCurrent()
	if(WinType(ksOperationsPanelName) != 7)
		return 0
	endif

	if(CmpStr(GetUserData(ksOperationsPanelName, "", "ATHPanelVersion"), ksPanelVersion) != 0)
		return 0
	endif

	return ATH_OperationsPanel#ControlExists(ksOperationsPanelName, "OP_CatImportUtilities") && ATH_OperationsPanel#ControlExists(ksOperationsPanelName, "OP_CatAnalysis")
End

Static Function TextButtonWidth(string label, variable maxWidth)
	variable width = strlen(label) * kTextButtonCharWidth + kTextButtonPadding
	width = round(width + 0.5)

	if(width < 42)
		width = 42
	endif

	if(maxWidth > 0 && width > maxWidth)
		width = maxWidth
	endif

	return width
End

Static Function AddCategoryButton(string ctrlName, string title, variable category,
								  variable xPos, variable yPos, variable width)
	Button $ctrlName, pos={xPos,yPos}, size={width,24}, title=title
	Button $ctrlName, proc=ATH_OperationsPanel#CategoryButtonProc, fSize=12
	Button $ctrlName, userdata(ATHCategory)=num2istr(category), help={"Show " + title + " operations."}
	return 0
End

Static Function CategoryButtonProc(STRUCT WMButtonAction &s) : ButtonControl
	if(s.eventCode != 2)
		return 0
	endif

	variable category = str2num(GetUserData(s.win, s.ctrlName, "ATHCategory"))
	ATH_OperationsPanel#ShowCategory(category)
	ATH_OperationsPanel#UpdateTargetTitle()
	return 0
End

Static Function ShowCategory(variable category)
	DFREF dfr = ATH_OperationsPanel#InitPackage()
	NVAR/SDFR=dfr gActiveCategory
	gActiveCategory = category

	ATH_OperationsPanel#ClearActionControls()
	ATH_OperationsPanel#StartActionGrid()
	ATH_OperationsPanel#SetCategoryButtonState(category)
	TitleBox OP_CategoryTitle, win=$ksOperationsPanelName, title=StringFromList(category, ksCategoryNames, ";")

	switch(category)
		case 0:
			ATH_OperationsPanel#BuildImportUtilitiesCategory()
			break
		case 1:
			ATH_OperationsPanel#BuildImageOpsCategory()
			break
		case 2:
			ATH_OperationsPanel#BuildExploreCategory()
			break
		case 3:
			ATH_OperationsPanel#BuildAnalysisCategory()
			break
	endswitch

	TitleBox OP_CommandPreview, win=$ksOperationsPanelName, title=""
	return 0
End

Static Function StartActionGrid()
	DFREF dfr = ATH_OperationsPanel#InitPackage()
	NVAR/SDFR=dfr gBuildRow, gBuildCol, gActionIndex, gSectionIndex
	gBuildRow = 0
	gBuildCol = kLeft
	gActionIndex = 0
	gSectionIndex = 0
	return 0
End

Static Function ClearActionControls()
	string controls = ControlNameList(ksOperationsPanelName, ";")
	variable i

	for(i = ItemsInList(controls, ";") - 1; i >= 0; i -= 1)
		string ctrlName = StringFromList(i, controls, ";")
		if(StringMatch(ctrlName, "OP_Action*") || StringMatch(ctrlName, "OP_Section*"))
			KillControl/W=$ksOperationsPanelName $ctrlName
		endif
	endfor

	return 0
End

Static Function AddSection(string label)
	DFREF dfr = ATH_OperationsPanel#InitPackage()
	NVAR/SDFR=dfr gBuildRow, gBuildCol, gSectionIndex

	if(gBuildCol != kLeft)
		gBuildRow += 1
	endif
	gBuildCol = kLeft

	string ctrlName = "OP_Section" + num2istr(gSectionIndex)
	variable yPos = kActionTop + gBuildRow * kRowStep
	TitleBox $ctrlName, win=$ksOperationsPanelName, pos={kLeft,yPos + 2}, size={kPanelWidth - 16,17}
	TitleBox $ctrlName, win=$ksOperationsPanelName, title=label, frame=0, fSize=12, fStyle=1, fcolor=(0, 0, 65535)
	gSectionIndex += 1
	gBuildRow += 1
	return 0
End

Static Function AddSubsection(string label)
	DFREF dfr = ATH_OperationsPanel#InitPackage()
	NVAR/SDFR=dfr gBuildRow, gBuildCol, gSectionIndex

	if(gBuildCol != kLeft)
		gBuildRow += 1
	endif
	gBuildCol = kLeft

	string ctrlName = "OP_Section" + num2istr(gSectionIndex)
	variable yPos = kActionTop + gBuildRow * kRowStep
	TitleBox $ctrlName, win=$ksOperationsPanelName, pos={kLeft + 8,yPos + 3}, size={kPanelWidth - 24,17}
	TitleBox $ctrlName, win=$ksOperationsPanelName, title="> " + label, frame=0, fSize=11, fStyle=1, fcolor=(26411,1,52428)
	gSectionIndex += 1
	gBuildRow += 1
	return 0
End

Static Function AddAction(string label, string commandStr, [variable style])
	DFREF dfr = ATH_OperationsPanel#InitPackage()
	NVAR/SDFR=dfr gBuildRow, gBuildCol, gActionIndex

	if(ParamIsDefault(style))
		style = 0
	endif

	variable buttonWidth = ATH_OperationsPanel#TextButtonWidth(label, kPanelWidth - 2 * kLeft)
	if(gBuildCol + buttonWidth > kPanelWidth - kLeft && gBuildCol != kLeft)
		gBuildRow += 1
		gBuildCol = kLeft
	endif

	string ctrlName = "OP_Action" + num2istr(gActionIndex)
	variable xPos = gBuildCol
	variable yPos = kActionTop + gBuildRow * kRowStep
	Button $ctrlName, win=$ksOperationsPanelName, pos={xPos,yPos}, size={buttonWidth,kButtonHeight}
	Button $ctrlName, win=$ksOperationsPanelName, title=label, proc=ATH_OperationsPanel#CommandButtonProc
	Button $ctrlName, win=$ksOperationsPanelName, fSize=12, userdata(ATHCommand)=commandStr, help={commandStr}
	ATH_OperationsPanel#ApplyActionStyle(ctrlName, style)

	gBuildCol += buttonWidth + kActionButtonGap
	gActionIndex += 1
	return 0
End

Static Function AddWideAction(string label, string commandStr, [variable style])
	if(ParamIsDefault(style))
		style = 0
	endif

	return ATH_OperationsPanel#AddAction(label, commandStr, style=style)
End

Static Function ApplyActionStyle(string ctrlName, variable style)
	switch(style)
		case 1:
			Button $ctrlName, win=$ksOperationsPanelName, fColor=(49151,65535,49151)
			break
		case 2:
			Button $ctrlName, win=$ksOperationsPanelName, fColor=(65535,32768,32768)
			break
		case 3:
			Button $ctrlName, win=$ksOperationsPanelName, fColor=(49151,58982,65535)
			break
		case 4:
			Button $ctrlName, win=$ksOperationsPanelName, fColor=(65535,0,0), fStyle=1
			break
		default:
			Button $ctrlName, win=$ksOperationsPanelName, fStyle=0
			break
	endswitch

	return 0
End

Static Function BuildImportUtilitiesCategory()
	ATH_OperationsPanel#AddSection("Load data")
	ATH_OperationsPanel#AddSubsection(".dat (Elmitec)")
	ATH_OperationsPanel#AddAction(".dat files", "ATH_Uview#LoadMultiplyDATFiles(autoscale=1)")
	ATH_OperationsPanel#AddWideAction(".dat folder to stack", "ATH_Uview#LoadDATFilesFromFolderMT(displayImg=1)")
	ATH_OperationsPanel#AddWideAction(".dat files to stack", "ATH_Uview#LoadMultiplyDATFilesMT(displayImg=1)")
	ATH_OperationsPanel#AddAction("Scan ID", "ATH_Uview#LoadDATFilesMatchingPattternToStackMT(displayImg=1)")
	ATH_OperationsPanel#AddSubsection("HDF5")
	ATH_OperationsPanel#AddAction("MaxIV meta", "ATH_Launch#LoadHDF5GroupsFromFile()")
	ATH_OperationsPanel#AddSection("Process data")
	ATH_OperationsPanel#AddSubsection("Stacks")
	ATH_OperationsPanel#AddAction("Make stack", "ATH_Launch#Make3DWaveDataBrowserSelection()")
	ATH_OperationsPanel#AddWideAction("Make stack and display", "ATH_Launch#Make3DWaveDataBrowserSelection(displayStack=1)")
	ATH_OperationsPanel#AddWideAction("Make transient stack and display", "ATH_Launch#Make3DWaveDataBrowserSelection(displayStack=1, transientStack=1)")
	ATH_OperationsPanel#AddAction("Avg range", "ATH_Launch#AverageLayersRange()")
	ATH_OperationsPanel#AddAction("Avg stack", "ATH_Launch#AverageImageStack()")
	ATH_OperationsPanel#AddSubsection("Add/remove")
	ATH_OperationsPanel#AddWideAction("Insert images at slider position", "ATH_Launch#InsertImagesToStack()")
	ATH_OperationsPanel#AddWideAction("Append images to stack", "ATH_Launch#InsertImagesToStack(extend=1)")
	ATH_OperationsPanel#AddWideAction("Remove layers from stack", "ATH_Launch#RemoveImagesFromImageStack()", style=2)
	ATH_OperationsPanel#AddAction("Flip stack", "ATH_Launch#FlipStackPlanes()")
	ATH_OperationsPanel#AddSubsection("Extract")
	ATH_OperationsPanel#AddWideAction("Extract layers to stack", "ATH_Launch#ExtractLayerRangeToStack()")
	ATH_OperationsPanel#AddAction("Save layer", "ATH_ImgOp#GetLayerFromImageStack()")
	ATH_OperationsPanel#AddWideAction("Save current view", "ATH_ImgOp#GetScaledZoominImageWindow(evenNum=1)")
	ATH_OperationsPanel#AddWideAction("Unpack stack to source waves", "ATH_Launch#UnpackStackToSources()", style=4)
	ATH_OperationsPanel#AddSubsection("Partition")
	ATH_OperationsPanel#AddWideAction("Partition region", "ATH_Marquee#PartitionRegion(evenNum=1)")
	ATH_OperationsPanel#AddWideAction("Partition square region", "ATH_Marquee#PartitionRegion(square=1)")
	ATH_OperationsPanel#AddSection("Utilities")
	ATH_OperationsPanel#AddAction("Free", "ATH_Launch#DeleteBigWaves()", style=2)
	ATH_OperationsPanel#AddAction("CalcPad", "ATH_CalcPad#CalcPad()")
	ATH_OperationsPanel#AddAction("HDF5 list", "ATH_HDF5#ListHDF5Groups()")
	ATH_OperationsPanel#AddAction("Load CT", "ATH_Color#loadColorTableAll()")
	ATH_OperationsPanel#AddAction("Kill CT", "ATH_Color#ATH_ColorKillWaves()")
	ATH_OperationsPanel#AddAction("Scale bar", "ATH_Launch#DrawScaleBar()")
	ATH_OperationsPanel#AddSubsection("Backup")
	ATH_OperationsPanel#AddAction("Backup", "ATH_ImgOp#BackupTopImage()", style=1)
	ATH_OperationsPanel#AddAction("Restore", "ATH_ImgOp#RestoreTopImageFromBackup()", style=2)
	ATH_OperationsPanel#AddAction("Browser", "ATH_Launch#ImageBackupFromBrowserSelection()")
	ATH_OperationsPanel#AddSubsection("Window")
	ATH_OperationsPanel#AddAction("Close+del", "ATH_Launch#CloseTopWindowAndDeleteSource(deleteBackUp=1)", style=2)
	ATH_OperationsPanel#AddAction("Del backup", "ATH_Launch#DeleteBackupWave()", style=2)
	ATH_OperationsPanel#AddSection("Ph. Em. DB")
	ATH_OperationsPanel#AddAction("XPS DB", "ATH_XPSData#XPSReferenceData()")
	return 0
End

Static Function BuildImageOpsCategory()
	ATH_OperationsPanel#AddSection("Stack")
	ATH_OperationsPanel#AddAction("Axes 3D", "ATH_Launch#Rotate3DWaveAxes()")
	ATH_OperationsPanel#AddSection("Process")
	ATH_OperationsPanel#AddAction("Pixelate", "ATH_Launch#PixelateSingleImageOrStack()")
	ATH_OperationsPanel#AddAction("Resample", "ATH_Launch#ImageResample()")
	ATH_OperationsPanel#AddAction("Rot meta", "ATH_Launch#ImageRotateAndScaleFromMetadata()")
	ATH_OperationsPanel#AddAction("FFT", "ATH_Launch#ImageFFTTransform()")
	ATH_OperationsPanel#AddAction("Hist eq", "ATH_Launch#HistogramEqualisation()")
	ATH_OperationsPanel#AddAction("Center H", "ATH_Launch#HistogramShiftToGaussianCenter()")
	ATH_OperationsPanel#AddAction("Filter", "ATH_Launch#ImageFilter3D()")
	ATH_OperationsPanel#AddAction("Loess", "ATH_Launch#ImageSmooth3D()")
	ATH_OperationsPanel#AddAction("Edges", "ATH_Launch#ApplyEdgeDetectionCommandToStack()")
	ATH_OperationsPanel#AddAction("Smooth", "ATH_Launch#SmoothWave()")
	ATH_OperationsPanel#AddAction("Full reg", "ATH_Launch#ImageRegistrationStack()")
	ATH_OperationsPanel#AddAction("RGB gray", "ATH_Launch#ImgRGB2Gray16()")
	ATH_OperationsPanel#AddSection("Background")
	ATH_OperationsPanel#AddAction("Bkg", "ATH_Launch#ImgRemoveBackground()", style=1)
	ATH_OperationsPanel#AddAction("Flatten", "ATH_Launch#FlattenImage()", style=1)
	ATH_OperationsPanel#AddAction("Line fit", "ATH_BackgroundRemoval#RemovePolynomialLineFitBackground()", style=1)
	ATH_OperationsPanel#AddAction("XPS bkg", "ATH_BackgroundRemover#BackgroundSubtractGUI()", style=1)
	ATH_OperationsPanel#AddSection("Drift correction")
	ATH_OperationsPanel#AddAction("Drift reg", "ATH_OperationsPanel#DriftRegistrationUsingAFeautre()", style=3)
	ATH_OperationsPanel#AddAction("Linear", "ATH_Launch#LinearDriftCorrestionStackABCursors()")
	ATH_OperationsPanel#AddAction("Linear N", "ATH_Launch#LinearDriftCorrestionPlanesABCursors()")
	ATH_OperationsPanel#AddSection("Interactive")
	ATH_OperationsPanel#AddAction("iDrift", "ATH_iDriftCorrection#CreatePanel()", style=3)
	ATH_OperationsPanel#AddAction("iXMCD", "ATH_iXMCD#MenuLaunch()", style=3)
	ATH_OperationsPanel#AddAction("iImgOps", "ATH_iImgOps#MainMenu()", style=3)
	ATH_OperationsPanel#AddAction("iFFT", "ATH_Launch#iImgFFTFilter()")
	ATH_OperationsPanel#AddAction("iRotate", "ATH_iImgRotation#CreatePanel()")
	ATH_OperationsPanel#AddAction("iXPS", "ATH_iXPS#MainMenu()")
	ATH_OperationsPanel#AddSection("Profiles")
	ATH_OperationsPanel#AddAction("Line", "ATH_LineProfile#MainMenu()", style=3)
	ATH_OperationsPanel#AddAction("Plane", "ATH_PlaneZProfile#MainMenu()", style=3)
	ATH_OperationsPanel#AddAction("Z saved", "ATH_ZProfile#TracePopupLaunchSavedROI()")
	ATH_OperationsPanel#AddAction("XPS", "ATH_iXPS#MainMenu()")
	ATH_OperationsPanel#AddAction("XPS set", "ATH_Launch#XPSProfileFromDefaultSettings()")
	ATH_OperationsPanel#AddSection("ROI")
	ATH_OperationsPanel#AddAction("Z rect", "ATH_ZProfile#GraphMarqueeLaunchRectangle()")
	ATH_OperationsPanel#AddAction("Z oval", "ATH_ZProfile#GraphMarqueeLaunchOval()")
	ATH_OperationsPanel#AddAction("Rect ROI", "ATH_Marquee#SaveROICoordinatesToDatabase(rect=1)")
	ATH_OperationsPanel#AddAction("Oval ROI", "ATH_Marquee#SaveROICoordinatesToDatabase()")
	ATH_OperationsPanel#AddAction("ROI stats", "ATH_Marquee#GetMarqueeWaveStats()")
	ATH_OperationsPanel#AddAction("Clear UF", "ATH_ZProfile#ClearROIMarkingsUserFront(\"\")")
	return 0
End

Static Function BuildExploreCategory()
	ATH_OperationsPanel#AddSection("Data Browser")
	ATH_OperationsPanel#AddAction("New image", "ATH_Launch#NewImageFromBrowserSelection()")
	ATH_OperationsPanel#AddAction("Avg stack", "ATH_Launch#AverageStackToImageFromBrowserMenu()")
	ATH_OperationsPanel#AddAction("Restore", "ATH_Launch#ImageBackupFromBrowserSelection()")
	ATH_OperationsPanel#AddAction("Norm img", "ATH_Launch#NormalisationImageStackWithImage()")
	ATH_OperationsPanel#AddAction("Norm prof", "ATH_Launch#NormalisationImageStackWithProfile()")
	ATH_OperationsPanel#AddAction("Norm stack", "ATH_Launch#NormalisationImageStackWithImageStack()")
	ATH_OperationsPanel#AddSection("Graph tools")
	ATH_OperationsPanel#AddAction("Text", "ATH_Launch#QuickTextAnnotation()")
	ATH_OperationsPanel#AddAction("Set DF", "ATH_Launch#SetTopGraphDF()")
	ATH_OperationsPanel#AddAction("Measure", "ATH_Cursors#MeasureDistanceUsingFreeCursors()")
	ATH_OperationsPanel#AddSection("Copy / Extract")
	ATH_OperationsPanel#AddAction("Duplicate", "ATH_Graph#DuplicateWaveAndDisplayOfTopImage()")
	ATH_OperationsPanel#AddAction("Saved ROI", "ATH_Launch#MakeWaveFromSavedROI()")
	ATH_OperationsPanel#AddAction("Copy scale", "ATH_ImgOp#ImageSelectToCopyScale()")
	ATH_OperationsPanel#AddAction("Z scale", "ATH_ImgOp#SetZScaleOfImageStack()")
	ATH_OperationsPanel#AddSection("View state")
	ATH_OperationsPanel#AddAction("Save axes", "ATH_Launch#SaveAxesRangeAndCtab()")
	ATH_OperationsPanel#AddAction("Set axes+ct", "ATH_Launch#SetAxesRangeAndCtabFromSaved(setCtab=1)")
	ATH_OperationsPanel#AddAction("Set axes", "ATH_Launch#SetAxesRangeAndCtabFromSaved()")
	return 0
End

Static Function BuildAnalysisCategory()
	ATH_OperationsPanel#AddSection("XMC(L)D")
	ATH_OperationsPanel#AddAction("XMCD 2D", "ATH_Launch#CalculationXMCD()", style=1)
	ATH_OperationsPanel#AddAction("XMCD 3D", "ATH_Launch#CalculationXMCD3D()", style=1)
	ATH_OperationsPanel#AddAction("Combos", "ATH_Launch#XMCDCombinations()")
	ATH_OperationsPanel#AddSection("Baseline/FastFit")
	ATH_OperationsPanel#AddAction("Baselines", "ATH_Baselines#Initialise()")
	ATH_OperationsPanel#AddAction("FastFit", "FastFit#Initialise()")
	return 0
End

Static Function SetCategoryButtonState(variable activeCategory)
	variable i
	variable nButtons = ItemsInList(ksCategoryButtons, ";")

	for(i = 0; i < nButtons; i += 1)
		string buttonName = StringFromList(i, ksCategoryButtons, ";")
		if(ATH_OperationsPanel#ControlExists(ksOperationsPanelName, buttonName))
			ATH_OperationsPanel#SetCategoryControlLook(buttonName, i, activeCategory)
		endif
	endfor

	return 0
End

Static Function SetCategoryControlLook(string buttonName, variable category, variable activeCategory)
	variable red
	variable green
	variable blue

	switch(category)
		case 0:
			red = 65535
			green = 55704
			blue = 32768
			break
		case 1:
			red = 32768
			green = 52428
			blue = 65535
			break
		case 2:
			red = 52428
			green = 45875
			blue = 65535
			break
		case 3:
			red = 32768
			green = 58982
			blue = 65535
			break
		default:
			red = 52428
			green = 52428
			blue = 58982
			break
	endswitch

	if(category != activeCategory)
		red = round((red + 2 * 61166) / 3)
		green = round((green + 2 * 61166) / 3)
		blue = round((blue + 2 * 61166) / 3)
		Button $buttonName, win=$ksOperationsPanelName, fColor=(red,green,blue), fStyle=0
	else
		Button $buttonName, win=$ksOperationsPanelName, fColor=(red,green,blue), fStyle=1
	endif

	return 0
End

Static Function CommandButtonProc(STRUCT WMButtonAction &s) : ButtonControl
	if(s.eventCode != 2)
		return 0
	endif

	string commandStr = GetUserData(s.win, s.ctrlName, "ATHCommand")
	TitleBox OP_CommandPreview, win=$ksOperationsPanelName, title=commandStr
	ATH_OperationsPanel#RunCommand(commandStr)
	ATH_OperationsPanel#UpdateTargetTitle()
	return 0
End

Static Function RunCommand(string commandStr)
	if(!strlen(commandStr))
		return -1
	endif

	if(!StringMatch(commandStr, "ATH_OperationsPanel#*"))
		string graphName = WinName(0, 1, 1)
		if(strlen(graphName))
			DoWindow/F $graphName
		endif
	endif

	Execute/P/Q/Z commandStr
	variable err = GetRTError(1)
	if(err)
		string errMsg = GetErrMessage(err, 3)
		Print "ATH Operations Panel command failed: " + commandStr
		Print errMsg
		DoAlert 0, "Command failed:\r" + commandStr + "\r\r" + errMsg
		return err
	endif

	return 0
End

/// @function DriftRegistrationUsingAFeautre
/// @brief Launch drift registration using the current Athina function name when available.
Static Function DriftRegistrationUsingAFeautre()
	string graphName = WinName(0, 1, 1)
	if(strlen(graphName))
		DoWindow/F $graphName
	endif

	Execute/P/Q/Z "ATH_Launch#DriftRegistrationUsingAFeautre()"
	variable err = GetRTError(1)
	if(!err)
		return 0
	endif

	Execute/P/Q/Z "ATH_ImgAlign#DriftRegistrationUsingAFeautre()"
	err = GetRTError(1)
	if(!err)
		return 0
	endif

	Execute/P/Q/Z "ATH_Launch#ImageStackAlignmentUsingAFeature()"
	err = GetRTError(1)
	if(err)
		string errMsg = GetErrMessage(err, 3)
		Print "ATH Operations Panel drift registration failed."
		Print errMsg
		DoAlert 0, "Drift registration failed:\r" + errMsg
		return err
	endif

	return 0
End

Static Function UpdateTargetTitle()
	if(WinType(ksOperationsPanelName) != 7)
		return -1
	endif

	TitleBox OP_Target, win=$ksOperationsPanelName, title=ATH_OperationsPanel#TopImageSummary()
	return 0
End

Static Function/S TopImageSummary()
	string graphName = WinName(0, 1, 1)
	if(!strlen(graphName))
		return "Target: no active image window"
	endif

	string imageList = ImageNameList(graphName, ";")
	if(ItemsInList(imageList, ";") <= 0)
		return "Target: " + graphName + " (no image)"
	endif

	string imageName = StringFromList(0, imageList, ";")
	WAVE/Z img = ImageNameToWaveRef(graphName, imageName)
	if(!WaveExists(img))
		return "Target: " + graphName + " / " + imageName
	endif

	variable nx = DimSize(img, 0)
	variable ny = DimSize(img, 1)
	variable nz = DimSize(img, 2)

	if(nz > 0)
		return "Target: " + graphName + " / " + imageName + " (" + num2istr(nx) + "x" + num2istr(ny) + "x" + num2istr(nz) + ")"
	endif

	return "Target: " + graphName + " / " + imageName + " (" + num2istr(nx) + "x" + num2istr(ny) + ")"
End

Static Function ControlExists(string panelName, string ctrlName)
	if(WinType(panelName) != 7)
		return 0
	endif

	return WhichListItem(ctrlName, ControlNameList(panelName, ";"), ";") >= 0
End
