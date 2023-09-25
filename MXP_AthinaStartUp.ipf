#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma IgorVersion=9.0

//******************************************************************************
//	Start MAXPEEM
//******************************************************************************
Function MXP_AthinaStartUp()
	Execute/P "INSERTINCLUDE \"MXP_Colors\""
	Execute/P "INSERTINCLUDE \"MXP_Cursors\""
	Execute/P "INSERTINCLUDE \"MXP_CustomIgorMenus\""
	Execute/P "INSERTINCLUDE \"MXP_DialogsAndPrompts\""
	Execute/P "INSERTINCLUDE \"MXP_Display\""
	Execute/P "INSERTINCLUDE \"MXP_Drawing\""
	Execute/P "INSERTINCLUDE \"MXP_Execute\""
	Execute/P "INSERTINCLUDE \"MXP_FolderOperations\""			
	Execute/P "INSERTINCLUDE \"MXP_FuncFit\""
	Execute/P "INSERTINCLUDE \"MXP_Geometry\""
	Execute/P "INSERTINCLUDE \"MXP_GraphOps\""
	Execute/P "INSERTINCLUDE \"MXP_ImageAlignment\""			
	Execute/P "INSERTINCLUDE \"MXP_ImageLineProfile\""
	Execute/P "INSERTINCLUDE \"MXP_ImageOperations\""
	Execute/P "INSERTINCLUDE \"MXP_ImagePlaneProfileZ\""
	Execute/P "INSERTINCLUDE \"MXP_InteractiveDriftCorrection\""
	Execute/P "INSERTINCLUDE \"MXP_InteractiveImageRotation\""
	Execute/P "INSERTINCLUDE \"MXP_InteractiveImageToXPSSpectrum\""
	Execute/P "INSERTINCLUDE \"MXP_InteractiveXMCDCalculation\""
	Execute/P "INSERTINCLUDE \"MXP_Launchers\""			
	Execute/P "INSERTINCLUDE \"MXP_LoadFilesDuringBeamtime\""
	Execute/P "INSERTINCLUDE \"MXP_LoadHDF5Files\""
	Execute/P "INSERTINCLUDE \"MXP_LoadUviewFiles\""	
	Execute/P "INSERTINCLUDE \"MXP_Magnetism\""
	Execute/P "INSERTINCLUDE \"MXP_MarqueeOperations\""			
	Execute/P "INSERTINCLUDE \"MXP_PhotoionizationCrossSections\""
	Execute/P "INSERTINCLUDE \"MXP_Spaces\""
	Execute/P "INSERTINCLUDE \"MXP_String\""
	Execute/P "INSERTINCLUDE \"MXP_SumBeamsProfile\""	
	Execute/P "INSERTINCLUDE \"MXP_Transforms\""
	Execute/P "INSERTINCLUDE \"MXP_WaveFunctions\""			
	Execute/P "INSERTINCLUDE \"MXP_WaveOperations\""
	Execute/P "INSERTINCLUDE \"MXP_WinInfo\""
	Execute/P "INSERTINCLUDE \"MXP_XPSSpectraBackgroundRemoval\""
	Execute/P "INSERTINCLUDE \"MXP_XrayPhotoelectronSpectroscopy\""								
	Execute/P "COMPILEPROCEDURES "
	return 0
End

//******************************************************************************
//	Menu item in MACROS
//******************************************************************************
Menu "Macros", dynamic
	//	Nothing is displayed after MAXPEEM is started
	SelectString(strlen(FunctionList("MXP_LoadDATFilesFromFolder",";","")), "Athina", ""), /Q, MXP_AthinaStartUp()
End
