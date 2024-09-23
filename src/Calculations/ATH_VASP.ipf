#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_VASP


// Here we will develop function to read, process and plot .h5 VASP output.

static Function/S LoadVASPHDF([string groupname])
	groupname = SelectString(ParamIsDefault(groupname), groupname, "results")
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

static Function LoadVASPBandStructure([int plotQ, int eFermi])
	plotQ = ParamIsDefault(plotQ) ? 0 : plotQ
	eFermi = ParamIsDefault(eFermi) ? 1 : eFermi
	string basepathStr = ATH_VASP#LoadVASPHDF() // N.B. ends with : 
	eFermi = ATH_VASP#GetEFermi(basepathStr)
	
	if(DataFolderExists(basepathStr+"electron_eigenvalues_kpoints_opt"))
		DFREF eigenDF = $(basepathStr+"electron_eigenvalues_kpoints_opt")
	elseif(DataFolderExists(basepathStr+"electron_eigenvalues"))
		DFREF eigenDF = $(basepathStr+"electron_eigenvalues")
	else
		print "DataFolder not found"
		return -1
	endif
	WAVE/SDFR=eigenDF eigenvalues
	if(eFermi)
		eigenvalues -= eFermi
	endif
	string waveNoteStr = NameOfWave(eigenvalues) + " -= " + num2str(efermi)
	Note eigenvalues, waveNoteStr
	if(plotQ)
		ATH_VASP#PlotBandStructure(eigenvalues)
	endif
End

static Function GetEFermi(string basePathStr)
	// Where is Efermi
	string pathStr = basePathStr + "electron_dos"
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(pathStr)
	WAVE/SDFR=dfr efermi
	return efermi[0]
End

static Function PlotBandStructure(WAVE bw, [WAVE kw, string tracename, string grfName]) // Plot Eigenvalues
	// bw - Eigevalues 3d wave, one row as imported from .h5 file
	// kw - kpoints 1d wave
	// Eigenvalues have bands at cols!
	variable nbands = DimSize(bw, 1), i
	string cmd	
	// Set the kw if set using UserData
	
	
	if(ParamIsDefault(grfName))
		grfName = UniqueName("BandStructure", 6, 0)
		Display/N=$grfName
	else
		DoWindow/F $grfName
		if(!V_flag)
			Display/N=$grfName
		endif
	endif
	if(ParamIsDefault(kw))
		for(i = 0; i < nbands; i++)
			if(ParamIsDefault(tracename))
				AppendToGraph/W=$grfName bw[0][][i]
			else
				AppendToGraph/W=$grfName bw[0][][i]/TN=$tracename
			endif
		endfor
	else
		for(i = 0; i < nbands; i++)
			if(ParamIsDefault(tracename))
				AppendToGraph/W=$grfName bw[0][][i] vs kw
			else
				AppendToGraph/W=$grfName bw[0][][i]/TN=$tracename vs kw
				ModifyGraph/W=$grfName rgb=(65535,0,0) // Use gray for BS plot. That's your girder
			endif
		endfor
	endif
	return 0
End

static Function Direct2Cartesian(WAVE latticeV, WAVE ionPos)
	// https://www.vasp.at/wiki/index.php/POSCAR
	variable atomsN = DimSize(ionPos, 0), i
	Duplicate/O ionPos, $(NameofWave(ionPos) + "_cart")
	WAVE wRef = $(NameofWave(ionPos) + "_cart")
	MatrixOP/FREE a1 = row(latticeV, 0)
	MatrixOP/FREE a2 = row(latticeV, 1)
	MatrixOP/FREE a3 = row(latticeV, 2)
	for(i=0 ; i < atomsN; i++)
		MatrixOP/FREE/O gRow = row(ionPos, i)
		MatrixOP/FREE/O bw = gRow[0] * a1 + gRow[1] * a2 + gRow[2] * a3
		wRef[i][] = bw[q]
	endfor
	return 0
End

//// ELECTRONIC STRUCTURE CALCULATIONS ////
//// PROCAR, LORBIT = 11 ////
//// EXAMPLE HOW TO PLOT PROJECTED BAND STRUCTURE ////
//// ATH_VASP#LoadVASPBandStructure()
//// ATH_VASP#FixOrbitalProjectionsFormat(WAVE par)
//// ATH_VASP#ExtractOrbitalsOfAtoms(par, "0-3", "13-17", "all_P")
//// ATH_VASP#ProjectedBandStructure(eigenvalues, all_P)

//// ---------------------------------------------- ////
static Function FixOrbitalProjectionsFormat(WAVE w4D)
	/// FORMAT:
	/// Change to band, kpoint, orb, atom (rows, cols, layers, chunks)
	///
	DFREF dfr = GetWavesDataFolderDFR(w4D)
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder dfr
	variable norb = DimSize(w4D, 2) // layers - orbitals
	WAVE nionp; variable natoms = nionp[0]
	WAVE nkpoints; variable nkpts = nkpoints[0]
	WAVE nb_tot; variable nbands = nb_tot[0]
	
	Redimension/E=1/N=(natoms, norb, nkpts, nbands) w4D
	ImageTransform/TM4D=8421 transpose4D w4D
	WAVE M_4DTranspose
	Duplicate/O M_4DTranspose, w4D
	Killwaves M_4DTranspose
	string 	noteStr = "Rows - Bands; Columns - K points; Layers - Orbitals (s(0), py, pz, px, dxy, dyz, dz2, dxz, dx2-y2(8)); Chunks - Atoms(1...)"
	Note w4D, noteStr
	SetDataFolder saveDF
	return 0
End

static Function SumAllOrbitalsAndAtoms(WAVE w4D)
	DFREF dfr = GetWavesDataFolderDFR(w4D)
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder dfr
	variable orb = DimSize(w4D, 2)
	MatrixOP $(NameOfWave(w4D) + "_tot") = layer(w4D, 0)
	WAVE wRef = $(NameOfWave(w4D) + "_tot")
	wRef = 0
	variable i
	for(i = 0; i < orb; i++)
		MatrixOP/FREE/O getFREEChuck = Chunk(w4D, i)
		MatrixOP/FREE/O FreeSumBeams = SumBeams(getFREEChuck)
		wRef += FreeSumBeams
	endfor
	SetDataFolder saveDF
	return 0	
End

static Function ExtractOrbitalsOfAtoms(WAVE w4D, string orbitalListStr, string atomsListStr, string outWaveNameStr)
	// Extract orbitats for atoms. Projections are summed over atoms and orbitals if you choose more than one.
	// Use strings like "2-5,7,9-12" for item or range selection
	// Orbitals (s, py, pz, px, dxy, dyz, dz2, dxz, dx2-y2) - zero based
	// 0 - s
	// 1 - py
	// 2 - pz
	// 3 - px
	// 4 - dxy
	// 5 - dyz
	// 6 - dz2
	// 7 - dxz
	// 8 - dx2-y2
	// Atoms numbers are 1, 2, 3 ... check the atom number order in your files (see POSCAR, OUTCAR, vasprun.xml or hdf5 output files)
	// **********
	// N.B: At the moment we do not check wave boundaries so be careful with the atom/orbital selection!
	// **********
	// First you have to run  ATH_VASP#FixOrbitalProjectionsFormat
	DFREF dfr = GetWavesDataFolderDFR(w4D)

	string orbsStr = ATH_String#ExpandRangeStr(orbitalListStr)
	string atomsStr = ATH_String#ExpandRangeStr(atomsListStr)
	variable orbsN = ItemsInList(orbsStr)
	variable atomsN = ItemsInList(atomsStr)
	
	// After ATH_VASP#FixOrbitalProjectionsFormat
	variable nbands = DimSize(w4D, 0)
	variable nkpts = DimSize(w4D, 1)
	//-----
	Make/O/FREE/N=(nbands, nkpts, orbsN) wRefFREE // Get the orbitals for all atoms

	// Calculate the tot sum over all atoms
	variable i, j, atX, orbX

	for(i = 0; i < atomsN; i++)
		atX = str2num(StringFromList(i, atomsStr)) - 1 // First atoms is 1
		for(j = 0; j < orbsN; j++)
			orbX = str2num(StringFromList(j, orbsStr))
			wRefFREE[][][j] += w4D[p][q][orbX][atX]
		endfor
	endfor
	string projWaveStr = "OrbitalProjection_tot"	 // TODO: Fix Normalisation
//	WAVE wtot = dfr:par_tot
	MatrixOP/O dfr:$outWaveNameStr = SumBeams(wRefFREE)///wtot
End

static Function RemoveTracesFromGraph(string grfName, variable nbands, string tracename)

	variable i
	string tnameStr
	
	for (i = nbands - 1; i > 0; i--) // Careful here, error suppression
		tnameStr = tracename + "#" + num2str(i)
		RemoveFromGraph/Z/W=$grfName $tnameStr
	endfor
	RemoveFromGraph/Z/W=$grfName $tracename
	return 0
End

static Function ProjectedBandStructure(WAVE wRef, WAVE wProj, [string tracename, 
		 variable red, variable green, variable blue])
	// wRef in the wave band structure (eigenvalues)
	// wProj is the wave created with ExtractOrbitalsOfAtoms
	///
	// wProj have a fixed structure bands x kpoints
	variable nbands = DimSize(wProj, 0), i
	
	string projWaveNameStr = NameOfWave(wProj), bsPlotNameStr, cmd
	string grfName = UniqueName("OrbitalProjection", 6, 0)
	
	if(ParamIsDefault(tracename))
		bsPlotNameStr = "eigenvalues"
	else
		bsPlotNameStr = tracename
	endif

	if(ParamIsDefault(tracename))
		ATH_VASP#PlotBandStructure(wRef, grfName = grfName)
	else
		ATH_VASP#PlotBandStructure(wRef, grfName = grfName, tracename = tracename)
	endif
	ModifyGraph/W=$grfName mode=3,marker=8
	
	bsPlotNameStr = PossiblyQuoteName(bsPlotNameStr)
	string dfrStr = GetWavesDataFolder(wProj, 1)
	// Run the zeroth wave - ill defined
	sprintf cmd, "ModifyGraph/W="+grfName+" mode("+bsPlotNameStr+")=3,marker("+bsPlotNameStr+")=8, rgb("+bsPlotNameStr+")=(%d,%d,%d)", red, green, blue
	Execute cmd	
	sprintf cmd, "ModifyGraph/W="+grfName+" zmrkSize("+bsPlotNameStr+")={"+(dfrStr+projWaveNameStr)+"[0][*],*,*,0,5}"
	Execute cmd	
	
	// Modify the rest
	for (i = 1; i< nbands;i+=1)
		// Uncomment to use false-color map
		//	sprintf cmd, "ModifyGraph/W="+winNameStr+" zColor(Eigenvals"+spincmpStr+"#%d)={"+projWaveNameStr+"[%d][*],0," + num2str(cmapMax)+",Rainbow,0}", i, i
		//	Execute cmd
		// Use markers, edit here to change appearence
		sprintf cmd, "ModifyGraph/W="+grfName+" mode("+bsPlotNameStr+"#%d)=3,marker("+bsPlotNameStr+"#%d)=8, rgb("+bsPlotNameStr+"#%d)=(%d,%d,%d)", i, i, i, red, green, blue
		Execute cmd
		sprintf cmd, "ModifyGraph/W="+grfName+" zmrkSize("+bsPlotNameStr+"#%d)={"+(dfrStr+projWaveNameStr)+"[%d][*],*,*,0,5}", i, i
		Execute cmd
	endfor
End