#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma IgorVersion=9.0

//******************************************************************************
//	Start MAXPEEM
//******************************************************************************
Function ATH_AthinaLauncher()
	if(!strlen(FunctionList("ATH_LoadDATFilesFromFolder",";","")))
		Execute/P "INSERTINCLUDE \"ATH_Colors\""
		Execute/P "INSERTINCLUDE \"ATH_Cursors\""
		Execute/P "INSERTINCLUDE \"ATH_CustomIgorMenus\""
		Execute/P "INSERTINCLUDE \"ATH_DialogsAndPrompts\""
		Execute/P "INSERTINCLUDE \"ATH_Display\""
		Execute/P "INSERTINCLUDE \"ATH_Drawing\""
		Execute/P "INSERTINCLUDE \"ATH_Execute\""
		Execute/P "INSERTINCLUDE \"ATH_FolderOperations\""
		Execute/P "INSERTINCLUDE \"ATH_FuncFit\""
		Execute/P "INSERTINCLUDE \"ATH_Geometry\""
		Execute/P "INSERTINCLUDE \"ATH_GraphOps\""
		Execute/P "INSERTINCLUDE \"ATH_ImageAlignment\""
		Execute/P "INSERTINCLUDE \"ATH_ImageLineProfile\""
		Execute/P "INSERTINCLUDE \"ATH_ImageOperations\""
		Execute/P "INSERTINCLUDE \"ATH_ImagePlaneProfileZ\""
		Execute/P "INSERTINCLUDE \"ATH_InteractiveDriftCorrection\""
		Execute/P "INSERTINCLUDE \"ATH_InteractiveImageRotation\""
		Execute/P "INSERTINCLUDE \"ATH_InteractiveImageToXPSSpectrum\""
		Execute/P "INSERTINCLUDE \"ATH_InteractiveXMCDCalculation\""
		Execute/P "INSERTINCLUDE \"ATH_Launchers\""
		Execute/P "INSERTINCLUDE \"ATH_LoadFilesDuringBeamtime\""
		Execute/P "INSERTINCLUDE \"ATH_LoadHDF5Files\""
		Execute/P "INSERTINCLUDE \"ATH_LoadUviewFiles\""
		Execute/P "INSERTINCLUDE \"ATH_Magnetism\""
		Execute/P "INSERTINCLUDE \"ATH_MarqueeOperations\""
		Execute/P "INSERTINCLUDE \"ATH_PhotoionizationCrossSections\""
		Execute/P "INSERTINCLUDE \"ATH_Spaces\""
		Execute/P "INSERTINCLUDE \"ATH_String\""
		Execute/P "INSERTINCLUDE \"ATH_SumBeamsProfile\""
		Execute/P "INSERTINCLUDE \"ATH_Transforms\""
		Execute/P "INSERTINCLUDE \"ATH_WaveFunctions\""
		Execute/P "INSERTINCLUDE \"ATH_WaveOperations\""
		Execute/P "INSERTINCLUDE \"ATH_WinInfo\""
		Execute/P "INSERTINCLUDE \"ATH_XPSSpectraBackgroundRemoval\""
		Execute/P "INSERTINCLUDE \"ATH_XrayPhotoelectronSpectroscopy\""
		Execute/P "COMPILEPROCEDURES "
	else
		Execute/P "DELETEINCLUDE \"ATH_Colors\""
		Execute/P "DELETEINCLUDE \"ATH_Cursors\""
		Execute/P "DELETEINCLUDE \"ATH_CustomIgorMenus\""
		Execute/P "DELETEINCLUDE \"ATH_DialogsAndPrompts\""
		Execute/P "DELETEINCLUDE \"ATH_Display\""
		Execute/P "DELETEINCLUDE \"ATH_Drawing\""
		Execute/P "DELETEINCLUDE \"ATH_Execute\""
		Execute/P "DELETEINCLUDE \"ATH_FolderOperations\""
		Execute/P "DELETEINCLUDE \"ATH_FuncFit\""
		Execute/P "DELETEINCLUDE \"ATH_Geometry\""
		Execute/P "DELETEINCLUDE \"ATH_GraphOps\""
		Execute/P "DELETEINCLUDE \"ATH_ImageAlignment\""
		Execute/P "DELETEINCLUDE \"ATH_ImageLineProfile\""
		Execute/P "DELETEINCLUDE \"ATH_ImageOperations\""
		Execute/P "DELETEINCLUDE \"ATH_ImagePlaneProfileZ\""
		Execute/P "DELETEINCLUDE \"ATH_InteractiveDriftCorrection\""
		Execute/P "DELETEINCLUDE \"ATH_InteractiveImageRotation\""
		Execute/P "DELETEINCLUDE \"ATH_InteractiveImageToXPSSpectrum\""
		Execute/P "DELETEINCLUDE \"ATH_InteractiveXMCDCalculation\""
		Execute/P "DELETEINCLUDE \"ATH_Launchers\""
		Execute/P "DELETEINCLUDE \"ATH_LoadFilesDuringBeamtime\""
		Execute/P "DELETEINCLUDE \"ATH_LoadHDF5Files\""
		Execute/P "DELETEINCLUDE \"ATH_LoadUviewFiles\""
		Execute/P "DELETEINCLUDE \"ATH_Magnetism\""
		Execute/P "DELETEINCLUDE \"ATH_MarqueeOperations\""
		Execute/P "DELETEINCLUDE \"ATH_PhotoionizationCrossSections\""
		Execute/P "DELETEINCLUDE \"ATH_Spaces\""
		Execute/P "DELETEINCLUDE \"ATH_String\""
		Execute/P "DELETEINCLUDE \"ATH_SumBeamsProfile\""
		Execute/P "DELETEINCLUDE \"ATH_Transforms\""
		Execute/P "DELETEINCLUDE \"ATH_WaveFunctions\""
		Execute/P "DELETEINCLUDE \"ATH_WaveOperations\""
		Execute/P "DELETEINCLUDE \"ATH_WinInfo\""
		Execute/P "DELETEINCLUDE \"ATH_XPSSpectraBackgroundRemoval\""
		Execute/P "DELETEINCLUDE \"ATH_XrayPhotoelectronSpectroscopy\""
		Execute/P "COMPILEPROCEDURES "
	endif
	return 0
End

//******************************************************************************
//	Menu item in MACROS
//******************************************************************************
Menu "Macros", dynamic
	//	Nothing is displayed after MAXPEEM is started
	SelectString(strlen(FunctionList("ATH_LoadDATFilesFromFolder",";","")), "Launch Athina", "Unload Athina"), /Q, ATH_AthinaLauncher()
End
