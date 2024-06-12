#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_VASP


// Here we will develop function to read, process and plot .h5 VASP output.

static Function/S LoadHDF5SpecificGroups(string groupname)
	// -
	variable fileid
	Open /D/R/T="HDF5" fileid
	string filepathname = S_fileName
	if(!strlen(filepathname))
		Abort 
	endif
	DFREF currDF = GetDataFolderDFR()
	string baseNameStr = ParseFilePath(0, S_fileName, ":", 1, 1)
	string loadDFStr = CreateDataObjectName(currDF, baseNameStr, 11, 0, 1)
	NewDataFolder/S $loadDFStr
	HDF5OpenFile/R fileid as filepathname
	HDF5LoadGroup/R/T/Z :, fileid, groupname
	HDF5CloseFile fileid
	// groupname datafolder has been created here.
	SetDataFolder $groupname
	string fullDFPathStr = GetDataFolder(1) // Data folder where groupname is loaded	
	SetDataFolder currDF
	return fullDFPathStr
End

static Function LoadVASPElectronicStructureAndPlot()
	string basepathStr = ATH_VASP#LoadHDF5SpecificGroups("results") // N.B. ends with : 
	variable efermi = ATH_VASP#GetEFermi(basepathStr)
	
	if(DataFolderExists(basepathStr+"electron_eigenvalues_kpoints_opt"))
		DFREF eigenDF = $(basepathStr+"electron_eigenvalues_kpoints_opt")
	elseif(DataFolderExists(basepathStr+"electron_eigenvalues"))
		DFREF eigenDF = $(basepathStr+"electron_eigenvalues")
	else
		print "DataFolder not found"
		return -1
	endif
	
	WAVE/SDFR=eigenDF eigenvalues
	eigenvalues -= efermi
	string waveNoteStr = NameOfWave(eigenvalues) + " -= " + num2str(efermi)
	Note eigenvalues, waveNoteStr
	ATH_VASP#VASP_PlotBandStructure(eigenvalues)
End
static Function GetEFermi(string basePathStr)
	// Where is Efermi
	string pathStr = basePathStr + "electron_dos"
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(pathStr)
	WAVE/SDFR=dfr efermi
	return efermi[0]
End

static function ShiftEigenvaluesWithEfermi(string basePathStr)
	variable efermi = ATH_VASP#GetEFermi(basePathStr)
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(basePathStr + ":" + "electron_eigenvalues_kpoints_opt")
	WAVE/SDFR=dfr eigenvalues
	eigenvalues -= efermi
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(basePathStr + ":" + "electron_eigenvalues_kpoints_opt")
	WAVE/SDFR=dfr eigenvalues
	eigenvalues -= efermi	
End

static Function VASP_PlotBandStructure(WAVE bw, [WAVE kw, string tracename, string graphnameStr]) // Plot Eigenvalues
	// bw - Eigevalues 3d wave, one row as imported from .h5 file
	// kw - kpoints 1d wave
	variable nbands = DimSize(bw, 1), i
	string cmd	
	// Set the kw if set using UserData
	
	string winNameStr = UniqueName("BandStructure", 6, 0)
	if(ParamIsDefault(graphnameStr))
		Display/N=$winNameStr
	else
		DoWindow/F $graphnameStr
		if(!V_flag)
			print "Window ", graphnameStr, " does not exist"
			return -1
		endif
	endif
	if(ParamIsDefault(kw))
		for(i = 0; i < nbands; i++)
			if(ParamIsDefault(tracename))
				AppendToGraph bw[0][][i]
			else
				AppendToGraph bw[0][][i]/TN=$tracename
			endif
		endfor
	else
		for(i = 0; i < nbands; i++)
			if(ParamIsDefault(tracename))
				AppendToGraph bw[0][][i] vs kw
			else
				AppendToGraph bw[0][][i]/TN=$tracename vs kw
				ModifyGraph rgb=(48059,48059,48059) // Use gray for BS plot. That's your girder
			endif
		endfor
	endif
	return 0
End