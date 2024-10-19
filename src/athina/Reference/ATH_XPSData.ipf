#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_XPSData
#pragma version = 1.01

// Adapted with major modifications from:
// Evangelos Golias (22.02.2023)
// Photoionisation cross-section datasets in the 2d wave were downloaded from
// https://vuo.elettra.eu/services/elements/WebElements.html
// Datasets for the following orbitals Ho3p, Tm3p, Dy3p, Er3p, Gd3p, Lu3p, Tb3p, Yb3p, V1s were empty 
// and are not included in the Photoionisation cross section data table (2d wave)
//
// Tested on Igor Pro 9.01
// Comment out the line with comment "//IP9 only" and the program will work for IP6+
// ---------------------
// Copy of original 
//
// modified from: 
// Periodic Table Menu by
// David Niles and J. J. Weimer
//
// by Richard Knochenmuss Jan. 2017
//
// Graphically select any number of elements, the resulting list is processed separately.
//
// The selection list is: root:Packages:ATH_DataFolder:XPSReferenceData:ElemSelect
// see also waves AtNr and ElementSym in the same data folder.
//
// See the function SelectionActionProc() to perform action after element selection
//
// Create a periodic table panel from the Macros menu, or call ATH_XPSData#XPSReferenceData()
//
// tested on Igor 7.02 and 6.37

// marked and ummarked button colors:
static constant unmarkR=65535  
static constant unmarkG=65535
static constant unmarkB=62500

static constant markR=65535
static constant markG=12500
static constant markB=12500

// panel background color:
static constant PTbgR=21845
static constant PTbgG=21845
static constant PTbgB=21845

static constant dfs=9 // element button default/base font size

static constant defaultscale = 2 // default scale factor for panel. valid values: 1, 1.25, 1.5, 2, 2.5

static constant maxelem=104 // highest desired atomic nr+1
 

//************************************************************
// Periodic Table Initialize Globals Structure
// ptwidth: base width of panel
// ptheight: base height of panel
// left: base start for buttons
// top: base start for buttons
// scfstr: scale factors to change panel size

Static Structure PTPanelInitGlobals
	variable ptwidth
	variable ptheight
	variable left
	variable top
	string scfstr
EndStructure

//************************************************************
// Periodic Table
// this is the starting point for creating the periodic table panel
static Function XPSReferenceData() : Panel

	if (!DataFolderExists("root:Packages:ATH_DataFolder:XPSReferenceData"))
		// new folder and display panel
		if (PTInitPanel())
			PTDisplayPanel()
		endif

	else
		// bring an existing panel forward
		if (strlen(WinList("XPSReferenceDataPanel", ";", "WIN:64"))!=0)
			DoWindow/F XPSReferenceDataPanel
		else
			NVAR gscfpN = root:Packages:ATH_DataFolder:XPSReferenceData:scfpN
			PTDisplayPanel()
			PopupMenu PTresize mode=gscfpN
		endif

	endif
End

//************************************************************
Static Function PTInitGlobals(ptpig)
	STRUCT PTPanelInitGlobals &ptpig
	ptpig.ptwidth=260
	ptpig.ptheight=175
	ptpig.left=10
	ptpig.top=10
	ptpig.scfstr="\"1;1.25;1.5;2;2.5;\""
End

//************************************************************
// PTInitPanel()
// initialize the periodic table panel folders and globals
Static Function PTInitPanel()
	
	// create new data folder for Periodic Table information
	//string cdf = GetDataFolder(1)
	DFREF saveDF = GetDataFolderDFR()
	
	variable newpanel = 0
	
	if (!DataFolderExists("root:Packages:ATH_DataFolder:XPSReferenceData"))
		DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:XPSReferenceData", setDF=1)
				
		// create the globals and set them

		string/G gATH_OrbitalOrder = "H1s_E;H1s_CS;He1s_E;He1s_CS;Li1s_E;Li1s_CS;Li2s_E;Li2s_CS;Be1s_E;Be1s_CS;Be2s_E;Be2s_CS;B1s_E;B1s_CS;B2p_E;B2p_CS;B2s_E;B2s_CS;C1s_E;C1s_CS;C2p_E;C2p_CS;C2s_E;C2s_CS;N1s_E;N1s_CS;N2p_E;N2p_CS;N2s_E;N2s_CS;O1s_E;O1s_CS;O2p_E;O2p_CS;O2s_E;O2s_CS;F1s_E;F1s_CS;F2p_E;F2p_CS;F2s_E;F2s_CS;Ne1s_E;Ne1s_CS;"
		gATH_OrbitalOrder+= "Ne2p_E;Ne2p_CS;Ne2s_E;Ne2s_CS;Na1s_E;Na1s_CS;Na2p_E;Na2p_CS;Na2s_E;Na2s_CS;Na3s_E;Na3s_CS;Mg1s_E;Mg1s_CS;Mg2p_E;Mg2p_CS;Mg2s_E;Mg2s_CS;Mg3s_E;Mg3s_CS;Al2p_E;Al2p_CS;Al2s_E;Al2s_CS;Al3p_E;Al3p_CS;Al3s_E;Al3s_CS;Si2p_E;Si2p_CS;Si2s_E;Si2s_CS;Si3p_E;Si3p_CS;Si3s_E;Si3s_CS;P2p_E;P2p_CS;P2s_E;P2s_CS;P3p_E;"
		gATH_OrbitalOrder+= "P3p_CS;P3s_E;P3s_CS;S2p_E;S2p_CS;S2s_E;S2s_CS;S3p_E;S3p_CS;S3s_E;S3s_CS;Cl2p_E;Cl2p_CS;Cl2s_E;Cl2s_CS;Cl3p_E;Cl3p_CS;Cl3s_E;Cl3s_CS;Ar2p_E;Ar2p_CS;Ar2s_E;Ar2s_CS;Ar3p_E;Ar3p_CS;Ar3s_E;Ar3s_CS;K2p_E;K2p_CS;K2s_E;K2s_CS;K3p_E;K3p_CS;K3s_E;K3s_CS;K4s_E;K4s_CS;Ca2p_E;Ca2p_CS;Ca2s_E;Ca2s_CS;Ca3p_E;Ca3p_CS;"
		gATH_OrbitalOrder+= "Ca3s_E;Ca3s_CS;Ca4s_E;Ca4s_CS;Sc2p_E;Sc2p_CS;Sc2s_E;Sc2s_CS;Sc3d_E;Sc3d_CS;Sc3p_E;Sc3p_CS;Sc3s_E;Sc3s_CS;Sc4s_E;Sc4s_CS;Ti2p_E;Ti2p_CS;Ti2s_E;Ti2s_CS;Ti3d_E;Ti3d_CS;Ti3p_E;Ti3p_CS;Ti3s_E;Ti3s_CS;Ti4s_E;Ti4s_CS;V2p_E;V2p_CS;V2s_E;V2s_CS;V3d_E;V3d_CS;V3p_E;V3p_CS;V3s_E;V3s_CS;V4s_E;V4s_CS;Cr2p_E;Cr2p_CS;"
		gATH_OrbitalOrder+= "Cr2s_E;Cr2s_CS;Cr3d_E;Cr3d_CS;Cr3p_E;Cr3p_CS;Cr3s_E;Cr3s_CS;Cr4s_E;Cr4s_CS;Mn2p_E;Mn2p_CS;Mn2s_E;Mn2s_CS;Mn3d_E;Mn3d_CS;Mn3p_E;Mn3p_CS;Mn3s_E;Mn3s_CS;Mn4s_E;Mn4s_CS;Fe2p_E;Fe2p_CS;Fe2s_E;Fe2s_CS;Fe3d_E;Fe3d_CS;Fe3p_E;Fe3p_CS;Fe3s_E;Fe3s_CS;Fe4s_E;Fe4s_CS;Co2p_E;Co2p_CS;Co2s_E;Co2s_CS;Co3d_E;Co3d_CS;"
		gATH_OrbitalOrder+= "Co3p_E;Co3p_CS;Co3s_E;Co3s_CS;Co4s_E;Co4s_CS;Ni2p_E;Ni2p_CS;Ni2s_E;Ni2s_CS;Ni3d_E;Ni3d_CS;Ni3p_E;Ni3p_CS;Ni3s_E;Ni3s_CS;Ni4s_E;Ni4s_CS;Cu2p_E;Cu2p_CS;Cu2s_E;Cu2s_CS;Cu3d_E;Cu3d_CS;Cu3p_E;Cu3p_CS;Cu3s_E;Cu3s_CS;Cu4s_E;Cu4s_CS;Zn2p_E;Zn2p_CS;Zn2s_E;Zn2s_CS;Zn3d_E;Zn3d_CS;Zn3p_E;Zn3p_CS;Zn3s_E;Zn3s_CS;"
		gATH_OrbitalOrder+= "Zn4s_E;Zn4s_CS;Ga2p_E;Ga2p_CS;Ga2s_E;Ga2s_CS;Ga3d_E;Ga3d_CS;Ga3p_E;Ga3p_CS;Ga3s_E;Ga3s_CS;Ga4p_E;Ga4p_CS;Ga4s_E;Ga4s_CS;Ge2p_E;Ge2p_CS;Ge2s_E;Ge2s_CS;Ge3d_E;Ge3d_CS;Ge3p_E;Ge3p_CS;Ge3s_E;Ge3s_CS;Ge4p_E;Ge4p_CS;Ge4s_E;Ge4s_CS;As2p_E;As2p_CS;As2s_E;As2s_CS;As3d_E;As3d_CS;As3p_E;As3p_CS;As3s_E;As3s_CS;"
		gATH_OrbitalOrder+= "As4p_E;As4p_CS;As4s_E;As4s_CS;Se2p_E;Se2p_CS;Se3d_E;Se3d_CS;Se3p_E;Se3p_CS;Se3s_E;Se3s_CS;Se4p_E;Se4p_CS;Se4s_E;Se4s_CS;Br3d_E;Br3d_CS;Br3p_E;Br3p_CS;Br3s_E;Br3s_CS;Br4p_E;Br4p_CS;Br4s_E;Br4s_CS;Kr3d_E;Kr3d_CS;Kr3p_E;Kr3p_CS;Kr3s_E;Kr3s_CS;Kr4p_E;Kr4p_CS;Kr4s_E;Kr4s_CS;Rb3d_E;Rb3d_CS;Rb3p_E;Rb3p_CS;"
		gATH_OrbitalOrder+= "Rb3s_E;Rb3s_CS;Rb4p_E;Rb4p_CS;Rb4s_E;Rb4s_CS;Rb5s_E;Rb5s_CS;Sr3d_E;Sr3d_CS;Sr3p_E;Sr3p_CS;Sr3s_E;Sr3s_CS;Sr4p_E;Sr4p_CS;Sr4s_E;Sr4s_CS;Sr5s_E;Sr5s_CS;Y3d_E;Y3d_CS;Y3p_E;Y3p_CS;Y3s_E;Y3s_CS;Y4d_E;Y4d_CS;Y4p_E;Y4p_CS;Y4s_E;Y4s_CS;Y5s_E;Y5s_CS;Zr3d_E;Zr3d_CS;Zr3p_E;Zr3p_CS;Zr3s_E;Zr3s_CS;Zr4d_E;Zr4d_CS;"
		gATH_OrbitalOrder+= "Zr4p_E;Zr4p_CS;Zr4s_E;Zr4s_CS;Zr5s_E;Zr5s_CS;Nb3d_E;Nb3d_CS;Nb3p_E;Nb3p_CS;Nb3s_E;Nb3s_CS;Nb4d_E;Nb4d_CS;Nb4p_E;Nb4p_CS;Nb4s_E;Nb4s_CS;Nb5s_E;Nb5s_CS;Mo3d_E;Mo3d_CS;Mo3p_E;Mo3p_CS;Mo3s_E;Mo3s_CS;Mo4d_E;Mo4d_CS;Mo4p_E;Mo4p_CS;Mo4s_E;Mo4s_CS;Mo5s_E;Mo5s_CS;Tc3d_E;Tc3d_CS;Tc3p_E;Tc3p_CS;Tc3s_E;Tc3s_CS;"
		gATH_OrbitalOrder+= "Tc4d_E;Tc4d_CS;Tc4p_E;Tc4p_CS;Tc4s_E;Tc4s_CS;Tc5s_E;Tc5s_CS;Ru3d_E;Ru3d_CS;Ru3p_E;Ru3p_CS;Ru3s_E;Ru3s_CS;Ru4d_E;Ru4d_CS;Ru4p_E;Ru4p_CS;Ru4s_E;Ru4s_CS;Ru5s_E;Ru5s_CS;Rh3d_E;Rh3d_CS;Rh3p_E;Rh3p_CS;Rh3s_E;Rh3s_CS;Rh4d_E;Rh4d_CS;Rh4p_E;Rh4p_CS;Rh4s_E;Rh4s_CS;Rh5s_E;Rh5s_CS;Pd3d_E;Pd3d_CS;Pd3p_E;Pd3p_CS;"
		gATH_OrbitalOrder+= "Pd3s_E;Pd3s_CS;Pd4d_E;Pd4d_CS;Pd4p_E;Pd4p_CS;Pd4s_E;Pd4s_CS;Ag3d_E;Ag3d_CS;Ag3p_E;Ag3p_CS;Ag3s_E;Ag3s_CS;Ag4d_E;Ag4d_CS;Ag4p_E;Ag4p_CS;Ag4s_E;Ag4s_CS;Ag5s_E;Ag5s_CS;Cd3d_E;Cd3d_CS;Cd3p_E;Cd3p_CS;Cd3s_E;Cd3s_CS;Cd4d_E;Cd4d_CS;Cd4p_E;Cd4p_CS;Cd4s_E;Cd4s_CS;Cd5s_E;Cd5s_CS;In3d_E;In3d_CS;In3p_E;In3p_CS;"
		gATH_OrbitalOrder+= "In3s_E;In3s_CS;In4d_E;In4d_CS;In4p_E;In4p_CS;In4s_E;In4s_CS;In5p_E;In5p_CS;In5s_E;In5s_CS;Sn3d_E;Sn3d_CS;Sn3p_E;Sn3p_CS;Sn3s_E;Sn3s_CS;Sn4d_E;Sn4d_CS;Sn4p_E;Sn4p_CS;Sn4s_E;Sn4s_CS;Sn5p_E;Sn5p_CS;Sn5s_E;Sn5s_CS;Sb3d_E;Sb3d_CS;Sb3p_E;Sb3p_CS;Sb3s_E;Sb3s_CS;Sb4d_E;Sb4d_CS;Sb4p_E;Sb4p_CS;Sb4s_E;Sb4s_CS;"
		gATH_OrbitalOrder+= "Sb5p_E;Sb5p_CS;Sb5s_E;Sb5s_CS;Te3d_E;Te3d_CS;Te3p_E;Te3p_CS;Te3s_E;Te3s_CS;Te4d_E;Te4d_CS;Te4p_E;Te4p_CS;Te4s_E;Te4s_CS;Te5p_E;Te5p_CS;Te5s_E;Te5s_CS;I3d_E;I3d_CS;I3p_E;I3p_CS;I3s_E;I3s_CS;I4d_E;I4d_CS;I4p_E;I4p_CS;I4s_E;I4s_CS;I5p_E;I5p_CS;I5s_E;I5s_CS;Xe3d_E;Xe3d_CS;Xe3p_E;Xe3p_CS;Xe3s_E;Xe3s_CS;"
		gATH_OrbitalOrder+= "Xe4d_E;Xe4d_CS;Xe4p_E;Xe4p_CS;Xe4s_E;Xe4s_CS;Xe5p_E;Xe5p_CS;Xe5s_E;Xe5s_CS;Cs3d_E;Cs3d_CS;Cs3p_E;Cs3p_CS;Cs3s_E;Cs3s_CS;Cs4d_E;Cs4d_CS;Cs4p_E;Cs4p_CS;Cs4s_E;Cs4s_CS;Cs5p_E;Cs5p_CS;Cs5s_E;Cs5s_CS;Cs6s_E;Cs6s_CS;Ba3d_E;Ba3d_CS;Ba3p_E;Ba3p_CS;Ba3s_E;Ba3s_CS;Ba4d_E;Ba4d_CS;Ba4p_E;Ba4p_CS;Ba4s_E;Ba4s_CS;"
		gATH_OrbitalOrder+= "Ba5p_E;Ba5p_CS;Ba5s_E;Ba5s_CS;Ba6s_E;Ba6s_CS;La3d_E;La3d_CS;La3p_E;La3p_CS;La3s_E;La3s_CS;La4d_E;La4d_CS;La4p_E;La4p_CS;La4s_E;La4s_CS;La5d_E;La5d_CS;La5p_E;La5p_CS;La5s_E;La5s_CS;La6s_E;La6s_CS;Ce3d_E;Ce3d_CS;Ce3p_E;Ce3p_CS;Ce3s_E;Ce3s_CS;Ce4d_E;Ce4d_CS;Ce4f_E;Ce4f_CS;Ce4p_E;Ce4p_CS;Ce4s_E;Ce4s_CS;"
		gATH_OrbitalOrder+= "Ce5p_E;Ce5p_CS;Ce5s_E;Ce5s_CS;Ce6s_E;Ce6s_CS;Pr3d_E;Pr3d_CS;Pr3p_E;Pr3p_CS;Pr3s_E;Pr3s_CS;Pr4d_E;Pr4d_CS;Pr4f_E;Pr4f_CS;Pr4p_E;Pr4p_CS;Pr4s_E;Pr4s_CS;Pr5p_E;Pr5p_CS;Pr5s_E;Pr5s_CS;Pr6s_E;Pr6s_CS;Nd3d_E;Nd3d_CS;Nd3p_E;Nd3p_CS;Nd3s_E;Nd3s_CS;Nd4d_E;Nd4d_CS;Nd4f_E;Nd4f_CS;Nd4p_E;Nd4p_CS;Nd4s_E;Nd4s_CS;"
		gATH_OrbitalOrder+= "Nd5p_E;Nd5p_CS;Nd5s_E;Nd5s_CS;Nd6s_E;Nd6s_CS;Pm3d_E;Pm3d_CS;Pm3p_E;Pm3p_CS;Pm3s_E;Pm3s_CS;Pm4d_E;Pm4d_CS;Pm4f_E;Pm4f_CS;Pm4p_E;Pm4p_CS;Pm4s_E;Pm4s_CS;Pm5p_E;Pm5p_CS;Pm5s_E;Pm5s_CS;Pm6s_E;Pm6s_CS;Sm3d_E;Sm3d_CS;Sm3p_E;Sm3p_CS;Sm4d_E;Sm4d_CS;Sm4f_E;Sm4f_CS;Sm4p_E;Sm4p_CS;Sm4s_E;Sm4s_CS;Sm5p_E;Sm5p_CS;"
		gATH_OrbitalOrder+= "Sm5s_E;Sm5s_CS;Sm6s_E;Sm6s_CS;Eu3d_E;Eu3d_CS;Eu3p_E;Eu3p_CS;Eu4d_E;Eu4d_CS;Eu4f_E;Eu4f_CS;Eu4p_E;Eu4p_CS;Eu4s_E;Eu4s_CS;Eu5p_E;Eu5p_CS;Eu5s_E;Eu5s_CS;Eu6s_E;Eu6s_CS;Gd3d_E;Gd3d_CS;Gd4d_E;Gd4d_CS;Gd4f_E;Gd4f_CS;Gd4p_E;Gd4p_CS;Gd4s_E;Gd4s_CS;Gd5d_E;Gd5d_CS;Gd5p_E;Gd5p_CS;Gd5s_E;Gd5s_CS;Gd6s_E;Gd6s_CS;"
		gATH_OrbitalOrder+= "Tb3d_E;Tb3d_CS;Tb4d_E;Tb4d_CS;Tb4f_E;Tb4f_CS;Tb4p_E;Tb4p_CS;Tb4s_E;Tb4s_CS;Tb5p_E;Tb5p_CS;Tb5s_E;Tb5s_CS;Tb6s_E;Tb6s_CS;Dy3d_E;Dy3d_CS;Dy4d_E;Dy4d_CS;Dy4f_E;Dy4f_CS;Dy4p_E;Dy4p_CS;Dy4s_E;Dy4s_CS;Dy5p_E;Dy5p_CS;Dy5s_E;Dy5s_CS;Dy6s_E;Dy6s_CS;Ho3d_E;Ho3d_CS;Ho4d_E;Ho4d_CS;Ho4f_E;Ho4f_CS;Ho4p_E;Ho4p_CS;"
		gATH_OrbitalOrder+= "Ho4s_E;Ho4s_CS;Ho5p_E;Ho5p_CS;Ho5s_E;Ho5s_CS;Ho6s_E;Ho6s_CS;Er3d_E;Er3d_CS;Er4d_E;Er4d_CS;Er4f_E;Er4f_CS;Er4p_E;Er4p_CS;Er4s_E;Er4s_CS;Er5p_E;Er5p_CS;Er5s_E;Er5s_CS;Er6s_E;Er6s_CS;Tm4d_E;Tm4d_CS;Tm4f_E;Tm4f_CS;Tm4p_E;Tm4p_CS;Tm4s_E;Tm4s_CS;Tm5p_E;Tm5p_CS;Tm5s_E;Tm5s_CS;Tm6s_E;Tm6s_CS;Yb4d_E;Yb4d_CS;"
		gATH_OrbitalOrder+= "Yb4f_E;Yb4f_CS;Yb4p_E;Yb4p_CS;Yb4s_E;Yb4s_CS;Yb5p_E;Yb5p_CS;Yb5s_E;Yb5s_CS;Yb6s_E;Yb6s_CS;Lu4d_E;Lu4d_CS;Lu4f_E;Lu4f_CS;Lu4p_E;Lu4p_CS;Lu4s_E;Lu4s_CS;Lu5d_E;Lu5d_CS;Lu5p_E;Lu5p_CS;Lu5s_E;Lu5s_CS;Lu6s_E;Lu6s_CS;Hf4d_E;Hf4d_CS;Hf4f_E;Hf4f_CS;Hf4p_E;Hf4p_CS;Hf4s_E;Hf4s_CS;Hf5d_E;Hf5d_CS;Hf5p_E;Hf5p_CS;"
		gATH_OrbitalOrder+= "Hf5s_E;Hf5s_CS;Hf6s_E;Hf6s_CS;Ta4d_E;Ta4d_CS;Ta4f_E;Ta4f_CS;Ta4p_E;Ta4p_CS;Ta4s_E;Ta4s_CS;Ta5d_E;Ta5d_CS;Ta5p_E;Ta5p_CS;Ta5s_E;Ta5s_CS;Ta6s_E;Ta6s_CS;W4d_E;W4d_CS;W4f_E;W4f_CS;W4p_E;W4p_CS;W4s_E;W4s_CS;W5d_E;W5d_CS;W5p_E;W5p_CS;W5s_E;W5s_CS;W6s_E;W6s_CS;Re4d_E;Re4d_CS;Re4f_E;Re4f_CS;Re4p_E;Re4p_CS;"
		gATH_OrbitalOrder+= "Re4s_E;Re4s_CS;Re5d_E;Re5d_CS;Re5p_E;Re5p_CS;Re5s_E;Re5s_CS;Re6s_E;Re6s_CS;Os4d_E;Os4d_CS;Os4f_E;Os4f_CS;Os4p_E;Os4p_CS;Os4s_E;Os4s_CS;Os5d_E;Os5d_CS;Os5p_E;Os5p_CS;Os5s_E;Os5s_CS;Os6s_E;Os6s_CS;Ir4d_E;Ir4d_CS;Ir4f_E;Ir4f_CS;Ir4p_E;Ir4p_CS;Ir4s_E;Ir4s_CS;Ir5d_E;Ir5d_CS;Ir5p_E;Ir5p_CS;Ir5s_E;Ir5s_CS;"
		gATH_OrbitalOrder+= "Ir6s_E;Ir6s_CS;Pt4d_E;Pt4d_CS;Pt4f_E;Pt4f_CS;Pt4p_E;Pt4p_CS;Pt4s_E;Pt4s_CS;Pt5d_E;Pt5d_CS;Pt5p_E;Pt5p_CS;Pt5s_E;Pt5s_CS;Pt6s_E;Pt6s_CS;Au4d_E;Au4d_CS;Au4f_E;Au4f_CS;Au4p_E;Au4p_CS;Au4s_E;Au4s_CS;Au5d_E;Au5d_CS;Au5p_E;Au5p_CS;Au5s_E;Au5s_CS;Au6s_E;Au6s_CS;Hg4d_E;Hg4d_CS;Hg4f_E;Hg4f_CS;Hg4p_E;Hg4p_CS;"
		gATH_OrbitalOrder+= "Hg4s_E;Hg4s_CS;Hg5d_E;Hg5d_CS;Hg5p_E;Hg5p_CS;Hg5s_E;Hg5s_CS;Hg6s_E;Hg6s_CS;Tl4d_E;Tl4d_CS;Tl4f_E;Tl4f_CS;Tl4p_E;Tl4p_CS;Tl4s_E;Tl4s_CS;Tl5d_E;Tl5d_CS;Tl5p_E;Tl5p_CS;Tl5s_E;Tl5s_CS;Tl6p_E;Tl6p_CS;Tl6s_E;Tl6s_CS;Pb4d_E;Pb4d_CS;Pb4f_E;Pb4f_CS;Pb4p_E;Pb4p_CS;Pb4s_E;Pb4s_CS;Pb5d_E;Pb5d_CS;Pb5p_E;Pb5p_CS;"
		gATH_OrbitalOrder+= "Pb5s_E;Pb5s_CS;Pb6p_E;Pb6p_CS;Pb6s_E;Pb6s_CS;Bi4d_E;Bi4d_CS;Bi4f_E;Bi4f_CS;Bi4p_E;Bi4p_CS;Bi4s_E;Bi4s_CS;Bi5d_E;Bi5d_CS;Bi5p_E;Bi5p_CS;Bi5s_E;Bi5s_CS;Bi6p_E;Bi6p_CS;Bi6s_E;Bi6s_CS;Po4d_E;Po4d_CS;Po4f_E;Po4f_CS;Po4p_E;Po4p_CS;Po4s_E;Po4s_CS;Po5d_E;Po5d_CS;Po5p_E;Po5p_CS;Po5s_E;Po5s_CS;Po6p_E;Po6p_CS;"
		gATH_OrbitalOrder+= "Po6s_E;Po6s_CS;At4d_E;At4d_CS;At4f_E;At4f_CS;At4p_E;At4p_CS;At4s_E;At4s_CS;At5d_E;At5d_CS;At5p_E;At5p_CS;At5s_E;At5s_CS;At6p_E;At6p_CS;At6s_E;At6s_CS;Rn4d_E;Rn4d_CS;Rn4f_E;Rn4f_CS;Rn4p_E;Rn4p_CS;Rn4s_E;Rn4s_CS;Rn5d_E;Rn5d_CS;Rn5p_E;Rn5p_CS;Rn5s_E;Rn5s_CS;Rn6p_E;Rn6p_CS;Rn6s_E;Rn6s_CS;Fr4d_E;Fr4d_CS;"
		gATH_OrbitalOrder+= "Fr4f_E;Fr4f_CS;Fr4p_E;Fr4p_CS;Fr4s_E;Fr4s_CS;Fr5d_E;Fr5d_CS;Fr5p_E;Fr5p_CS;Fr5s_E;Fr5s_CS;Fr6p_E;Fr6p_CS;Fr6s_E;Fr6s_CS;Fr7s_E;Fr7s_CS;Ra4d_E;Ra4d_CS;Ra4f_E;Ra4f_CS;Ra4p_E;Ra4p_CS;Ra4s_E;Ra4s_CS;Ra5d_E;Ra5d_CS;Ra5p_E;Ra5p_CS;Ra5s_E;Ra5s_CS;Ra6p_E;Ra6p_CS;Ra6s_E;Ra6s_CS;Ra7s_E;Ra7s_CS;Ac4d_E;Ac4d_CS;"
		gATH_OrbitalOrder+= "Ac4f_E;Ac4f_CS;Ac4p_E;Ac4p_CS;Ac4s_E;Ac4s_CS;Ac5d_E;Ac5d_CS;Ac5p_E;Ac5p_CS;Ac5s_E;Ac5s_CS;Ac6d_E;Ac6d_CS;Ac6p_E;Ac6p_CS;Ac6s_E;Ac6s_CS;Th4d_E;Th4d_CS;Th4f_E;Th4f_CS;Th4p_E;Th4p_CS;Th4s_E;Th4s_CS;Th5d_E;Th5d_CS;Th5p_E;Th5p_CS;Th5s_E;Th5s_CS;Th6d_E;Th6d_CS;Th6p_E;Th6p_CS;Th6s_E;Th6s_CS;Pa4d_E;Pa4d_CS;"
		gATH_OrbitalOrder+= "Pa4f_E;Pa4f_CS;Pa4p_E;Pa4p_CS;Pa4s_E;Pa4s_CS;Pa5d_E;Pa5d_CS;Pa5f_E;Pa5f_CS;Pa5p_E;Pa5p_CS;Pa5s_E;Pa5s_CS;Pa6d_E;Pa6d_CS;Pa6p_E;Pa6p_CS;U4d_E;U4d_CS;U4f_E;U4f_CS;U4p_E;U4p_CS;U4s_E;U4s_CS;U5d_E;U5d_CS;U5f_E;U5f_CS;U5p_E;U5p_CS;U5s_E;U5s_CS;U6d_E;U6d_CS;U6p_E;U6p_CS;Np4d_E;Np4d_CS;Np4f_E;Np4f_CS;Np4p_E;"
		gATH_OrbitalOrder+= "Np4p_CS;Np4s_E;Np4s_CS;Np5d_E;Np5d_CS;Np5f_E;Np5f_CS;Np5p_E;Np5p_CS;Np5s_E;Np5s_CS;Np6d_E;Np6d_CS;Np6p_E;Np6p_CS;Pu4d_E;Pu4d_CS;Pu4f_E;Pu4f_CS;Pu4p_E;Pu4p_CS;Pu4s_E;Pu4s_CS;Pu5d_E;Pu5d_CS;Pu5f_E;Pu5f_CS;Pu5p_E;Pu5p_CS;Pu5s_E;Pu5s_CS;Pu6p_E;Pu6p_CS;Pu6s_E;Pu6s_CS;Am4d_E;Am4d_CS;Am4f_E;Am4f_CS;Am4p_E;"
		gATH_OrbitalOrder+= "Am4p_CS;Am4s_E;Am4s_CS;Am5d_E;Am5d_CS;Am5f_E;Am5f_CS;Am5p_E;Am5p_CS;Am5s_E;Am5s_CS;Am6p_E;Am6p_CS;Am6s_E;Am6s_CS;Cm4d_E;Cm4d_CS;Cm4f_E;Cm4f_CS;Cm4p_E;Cm4p_CS;Cm4s_E;Cm4s_CS;Cm5d_E;Cm5d_CS;Cm5f_E;Cm5f_CS;Cm5p_E;Cm5p_CS;Cm5s_E;Cm5s_CS;Cm6d_E;Cm6d_CS;Cm6p_E;Cm6p_CS;Bk4d_E;Bk4d_CS;Bk4f_E;Bk4f_CS;Bk4p_E;"
		gATH_OrbitalOrder+= "Bk4p_CS;Bk4s_E;Bk4s_CS;Bk5d_E;Bk5d_CS;Bk5f_E;Bk5f_CS;Bk5p_E;Bk5p_CS;Bk5s_E;Bk5s_CS;Bk6d_E;Bk6d_CS;Bk6p_E;Bk6p_CS;Cf4d_E;Cf4d_CS;Cf4f_E;Cf4f_CS;Cf4p_E;Cf4p_CS;Cf4s_E;Cf4s_CS;Cf5d_E;Cf5d_CS;Cf5f_E;Cf5f_CS;Cf5p_E;Cf5p_CS;Cf5s_E;Cf5s_CS;Cf6d_E;Cf6d_CS;Cf6p_E;Cf6p_CS;Es4d_E;Es4d_CS;Es4f_E;Es4f_CS;Es4p_E;"
		gATH_OrbitalOrder+= "Es4p_CS;Es4s_E;Es4s_CS;Es5d_E;Es5d_CS;Es5f_E;Es5f_CS;Es5p_E;Es5p_CS;Es5s_E;Es5s_CS;Es6d_E;Es6d_CS;Es6p_E;Es6p_CS;Fm4d_E;Fm4d_CS;Fm4f_E;Fm4f_CS;Fm4p_E;Fm4p_CS;Fm4s_E;Fm4s_CS;Fm5d_E;Fm5d_CS;Fm5f_E;Fm5f_CS;Fm5p_E;Fm5p_CS;Fm5s_E;Fm5s_CS;Fm6d_E;Fm6d_CS;Fm6p_E;Fm6p_CS;Md4d_E;Md4d_CS;Md4f_E;Md4f_CS;Md4p_E;"
		gATH_OrbitalOrder+= "Md4p_CS;Md5d_E;Md5d_CS;Md5f_E;Md5f_CS;Md5p_E;Md5p_CS;Md5s_E;Md5s_CS;Md6d_E;Md6d_CS;Md6p_E;Md6p_CS;Md6s_E;Md6s_CS;No4d_E;No4d_CS;No4f_E;No4f_CS;No4p_E;No4p_CS;No5d_E;No5d_CS;No5f_E;No5f_CS;No5p_E;No5p_CS;No5s_E;No5s_CS;No6d_E;No6d_CS;No6p_E;No6p_CS;No6s_E;No6s_CS;Lr4d_E;Lr4d_CS;Lr4f_E;Lr4f_CS;Lr4p_E;"
		gATH_OrbitalOrder+= "Lr4p_CS;Lr5d_E;Lr5d_CS;Lr5f_E;Lr5f_CS;Lr5p_E;Lr5p_CS;Lr5s_E;Lr5s_CS;Lr6d_E;Lr6d_CS;Lr6p_E;Lr6p_CS;Lr6s_E;Lr6s_CS;"
		
		variable/G scf=defaultscale, kill=1, scfpN = 1, ghv = 150, gwf = 4.5, gKE = 1, gPhCs = 1, gCL = 0, gEhigh = 300, gElow = 20
		variable/G ptleft=0, pttop=0
		
		make/N=(maxelem) AtNr
		AtNr=p
		AtNr[0]=NaN
		
		make/T/N=(maxelem) ElementSym
		ElementSym[0]= {"","H","He","Li","Be","B","C","N","O","F","Ne","Na","Mg","Al","Si","P","S","Cl","Ar","K","Ca","Sc","Ti","V","Cr","Mn","Fe","Co","Ni","Cu","Zn","Ga","Ge","As","Se","Br","Kr","Rb","Sr","Y"}
		ElementSym[40]= {"Zr","Nb","Mo","Tc","Ru","Rh","Pd","Ag","Cd","In","Sn","Sb","Te","I","Xe","Cs","Ba","La","Ce","Pr","Nd","Pm","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm","Yb","Lu","Hf","Ta","W","Re","Os","Ir"}
		ElementSym[78]= {"Pt","Au","Hg","Tl","Pb","Bi","Po","At","Rn","Fr","Ra","Ac","Th","Pa","U","Np","Pu","Am","Cm","Bk","Cf","Es","Fm","Md","No","Lr","Rf","Db","Sg","Bh","Hs"}

		Make/N=(maxelem) ElemSelect, OldElemSelect
		ElemSelect=0
		OldElemSelect=-1
		
		make/N=(maxelem,3) Col
		col[][0]=unmarkR
		col[][1]=unmarkG
		col[][2]=unmarkB
		
		//Load the Ph. Cross-section dataset
		string datasetPathStr = ParseFilePath(1,FunctionPath("ATH_XPSData#XPSReferenceData"),":",1,1) + "Datasets:XPS:"
		NewPath/Q/O ATH_sourceData_TMP, datasetPathStr
		LoadWave/Q/H/P=ATH_sourceData_TMP "ATH_PhCrossSectionTable.ibw"
		LoadWave/Q/H/P=ATH_sourceData_TMP "ATH_ElectronBindingEnergies.ibw"
		LoadWave/Q/H/P=ATH_sourceData_TMP "ATH_Auger_KE.ibw"		
		LoadWave/Q/H/P=ATH_sourceData_TMP "ATH_Auger_Transitions.ibw"
		KillPath/Z ATH_sourceData_TMP
		newpanel = 1
	endif

	SetDataFolder saveDF
	
	return newpanel
End

//************************************************************
// PTDisplayPanel()
// create the panel and element buttons
Static Function PTDisplayPanel()
	NVAR gscf = root:Packages:ATH_DataFolder:XPSReferenceData:scf
	NVAR gptleft = root:Packages:ATH_DataFolder:XPSReferenceData:ptleft
	NVAR gpttop = root:Packages:ATH_DataFolder:XPSReferenceData:pttop
	NVAR gkill = root:Packages:ATH_DataFolder:XPSReferenceData:kill
	NVAR gElow = root:Packages:ATH_DataFolder:XPSReferenceData:gElow
	NVAR gEhigh = root:Packages:ATH_DataFolder:XPSReferenceData:gEhigh		
	NVAR ghv = root:Packages:ATH_DataFolder:XPSReferenceData:ghv
	NVAR gwf = root:Packages:ATH_DataFolder:XPSReferenceData:gwf
	NVAR gkE = root:Packages:ATH_DataFolder:XPSReferenceData:gKE
	NVAR gCL = root:Packages:ATH_DataFolder:XPSReferenceData:gCL
	NVAR gPhCs = root:Packages:ATH_DataFolder:XPSReferenceData:gPhCs	
	wave Col= root:Packages:ATH_DataFolder:XPSReferenceData:Col
	
	STRUCT PTPanelInitGlobals ptpig	
	PTInitGlobals(ptpig)
	
	if (!gscf)
		gscf = 2
	endif

	variable pntConv = (CmpStr(IgorInfo(2), "Windows") == 0 && ScreenResolution >= 96)? 1 : 72/ScreenResolution
	variable ptwidth, ptheight,left,top
	variable bw=20*gscf*pntConv,bh=15*gscf*pntConv
	variable ptddwidth=gscf*120*pntConv,ptddheight=11*bh*pntConv
	
	string gscfstr=ptpig.scfstr
	ptwidth=gscf*(ptpig.ptwidth+120)*pntConv
	ptheight=gscf*ptpig.ptheight*pntConv
	left=gscf*ptpig.left*pntConv
	top=gscf*ptpig.top*pntConv
	
	string strgscf = num2str(gscf)
	NewPanel/K=(gkill)/W=(gptleft,gpttop,gptleft+ptwidth,gpttop+ptheight)
	ModifyPanel cbRGB=(PTbgR,PTbgG,PTbgB), fixedSize=1//,noEdit=1
	DoWindow/C/T XPSReferenceDataPanel," athina XPS Data"

	DefaultGUIControls/W=XPSReferenceDataPanel native


	string cl2edge  = "\nCore level to absorption edge\n\n"
	cl2edge += "K 1s\n\n"+"L1 2s\n"+"L2 2p1/2\n"+"L3 2P3/2\n\n"+"M1 3s\n"+"M2 3p1/2\n"+"M3 3p3/2\n"
	cl2edge += "M4 3d3/2\n"+"M5 3d5/2\n\n"+"N1 4s\n"+"N2 4p1/2\n"+"N3 4p3/2\n"+"N4 4d3/2\n"
	cl2edge += "N5 4d5/2\n"+"N6 4f5/2\n"+"N7 457/2\n\n"+"01 5s\n"+"02 5p1/2\n"+"03 5p3/2\n\n"+"P1 6s\n" 
	cl2edge += "P2 6p1/2\n"+"P3 6p3/2\n"
	
	SetDrawLayer UserBack
	
	// the element buttons	
	Button H0,pos={left,top},size={bw,bh},fColor=(col[1][0],col[1][1],col[1][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="H"
	
	Button Li0,pos={left,top+bh},size={bw,bh},fColor=(col[3][0],col[3][1],col[3][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Li"
	Button Na0,pos={left,top+2*bh},size={bw,bh},fColor=(col[11][0],col[11][1],col[11][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Na"
	Button K0,pos={left,top+3*bh},size={bw,bh},fColor=(col[19][0],col[19][1],col[19][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="K"
	Button Rb0,pos={left,top+4*bh},size={bw,bh},fColor=(col[37][0],col[37][1],col[37][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Rb"
	Button Cs0,pos={left,top+5*bh},size={bw,bh},fColor=(col[55][0],col[55][1],col[55][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Cs"
	Button Fr0,pos={left,top+6*bh},size={bw,bh},fColor=(col[87][0],col[87][1],col[87][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Fr"

	Button Be0,pos={left+bw,top+bh},size={bw,bh},fColor=(col[4][0],col[4][1],col[4][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Be"
	Button Mg0,pos={left+bw,top+2*bh},size={bw,bh},fColor=(col[12][0],col[12][1],col[12][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Mg"
	Button Ca0,pos={left+bw,top+3*bh},size={bw,bh},fColor=(col[20][0],col[20][1],col[20][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ca"
	Button Sr0,pos={left+bw,top+4*bh},size={bw,bh},fColor=(col[38][0],col[38][1],col[38][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Sr"
	Button Ba0,pos={left+bw,top+5*bh},size={bw,bh},fColor=(col[56][0],col[56][1],col[56][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ba"
	Button Ra0,pos={left+bw,top+6*bh},size={bw,bh},fColor=(col[88][0],col[88][1],col[88][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ra"

	Button Sc0,pos={left+2*bw,top+3*bh},size={bw,bh},fColor=(col[21][0],col[21][1],col[21][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Sc"
	Button Ti0,pos={left+3*bw,top+3*bh},fColor=(col[22][0],col[22][1],col[22][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ti"
	Button V0,pos={left+4*bw,top+3*bh},fColor=(col[23][0],col[23][1],col[23][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="V"
	Button Cr0,pos={left+5*bw,top+3*bh},fColor=(col[24][0],col[24][1],col[24][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Cr"
	Button Mn0,pos={left+6*bw,top+3*bh},fColor=(col[24][0],col[25][1],col[25][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Mn"
	Button Fe0,pos={left+7*bw,top+3*bh},fColor=(col[26][0],col[26][1],col[26][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Fe"
	Button Co0,pos={left+8*bw,top+3*bh},fColor=(col[27][0],col[27][1],col[27][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Co"
	Button Ni0,pos={left+9*bw,top+3*bh},fColor=(col[28][0],col[28][1],col[28][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ni"
	Button Cu0,pos={left+10*bw,top+3*bh},fColor=(col[29][0],col[29][1],col[29][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Cu"
	Button Zn0,pos={left+11*bw,top+3*bh},fColor=(col[30][0],col[30][1],col[30][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Zn"

	Button Y0,pos={left+2*bw,top+4*bh},fColor=(col[39][0],col[39][1],col[39][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Y"
	Button Zr0,pos={left+3*bw,top+4*bh},fColor=(col[40][0],col[40][1],col[40][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Zr"
	Button Nb0,pos={left+4*bw,top+4*bh},fColor=(col[41][0],col[41][1],col[41][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Nb"
	Button Mo0,pos={left+5*bw,top+4*bh},fColor=(col[42][0],col[42][1],col[42][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Mo"
	Button Tc0,pos={left+6*bw,top+4*bh},fColor=(col[43][0],col[43][1],col[43][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Tc"
	Button Ru0,pos={left+7*bw,top+4*bh},fColor=(col[44][0],col[44][1],col[44][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ru"
	Button Rh0,pos={left+8*bw,top+4*bh},fColor=(col[45][0],col[45][1],col[45][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Rh"
	Button Pd0,pos={left+9*bw,top+4*bh},fColor=(col[46][0],col[46][1],col[46][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Pd"
	Button Ag0,pos={left+10*bw,top+4*bh},fColor=(col[47][0],col[47][1],col[47][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ag"
	Button Cd0,pos={left+11*bw,top+4*bh},fColor=(col[48][0],col[48][1],col[48][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Cd"

	Button La0,pos={left+2*bw,top+5*bh},fColor=(col[57][0],col[57][1],col[57][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="La"
	Button Hf0,pos={left+3*bw,top+5*bh},fColor=(col[72][0],col[72][1],col[72][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Hf"
	Button Ta0,pos={left+4*bw,top+5*bh},fColor=(col[73][0],col[73][1],col[73][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ta"
	Button W0,pos={left+5*bw,top+5*bh},fColor=(col[74][0],col[74][1],col[74][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="W"
	Button Re0,pos={left+6*bw,top+5*bh},fColor=(col[75][0],col[75][1],col[75][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Re"
	Button Os0,pos={left+7*bw,top+5*bh},fColor=(col[76][0],col[76][1],col[76][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Os"
	Button Ir0,pos={left+8*bw,top+5*bh},fColor=(col[77][0],col[77][1],col[77][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ir"
	Button Pt0,pos={left+9*bw,top+5*bh},fColor=(col[78][0],col[78][1],col[78][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Pt"
	Button Au0,pos={left+10*bw,top+5*bh},fColor=(col[79][0],col[79][1],col[79][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Au"
	Button Hg0,pos={left+11*bw,top+5*bh},fColor=(col[80][0],col[80][1],col[80][2]),size={bw,bh},fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Hg"

	Button Ac0,pos={left+2*bw,top+6*bh},size={bw,bh},fColor=(col[89][0],col[89][1],col[89][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ac"
//	Button Rf0,pos={left+3*bw,top+6*bh},size={bw,bh},fColor=(col[104][0],col[104][1],col[104][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Rf"
//	Button Ha0,pos={left+4*bw,top+6*bh},size={bw,bh},fColor=(col[105][0],col[105][1],col[105][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ha"

	Button He0,pos={left+17*bw,top},size={bw,bh},fColor=(col[2][0],col[2][1],col[2][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="He"

	Button B0,pos={left+12*bw,top+bh},size={bw,bh},fColor=(col[5][0],col[5][1],col[5][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="B"
	Button C0,pos={left+13*bw,top+bh},size={bw,bh},fColor=(col[6][0],col[6][1],col[6][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="C"
	Button N0,pos={left+14*bw,top+bh},size={bw,bh},fColor=(col[7][0],col[7][1],col[7][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="N"
	Button O0,pos={left+15*bw,top+bh},size={bw,bh},fColor=(col[8][0],col[8][1],col[8][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="O"
	Button F0,pos={left+16*bw,top+bh},size={bw,bh},fColor=(col[9][0],col[9][1],col[9][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="F"
	Button Ne0,pos={left+17*bw,top+bh},size={bw,bh},fColor=(col[10][0],col[10][1],col[10][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ne"

	Button Al0,pos={left+12*bw,top+2*bh},size={bw,bh},fColor=(col[13][0],col[13][1],col[13][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Al"
	Button Si0,pos={left+13*bw,top+2*bh},size={bw,bh},fColor=(col[14][0],col[14][1],col[14][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Si"
	Button P0,pos={left+14*bw,top+2*bh},size={bw,bh},fColor=(col[15][0],col[15][1],col[15][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="P"
	Button S0,pos={left+15*bw,top+2*bh},size={bw,bh},fColor=(col[16][0],col[16][1],col[16][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="S"
	Button Cl0,pos={left+16*bw,top+2*bh},size={bw,bh},fColor=(col[17][0],col[17][1],col[17][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Cl"
	Button Ar0,pos={left+17*bw,top+2*bh},size={bw,bh},fColor=(col[18][0],col[18][1],col[18][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ar"

	Button Ga0,pos={left+12*bw,top+3*bh},size={bw,bh},fColor=(col[31][0],col[31][1],col[31][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ga"
	Button Ge0,pos={left+13*bw,top+3*bh},size={bw,bh},fColor=(col[32][0],col[32][1],col[32][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ge"
	Button As0,pos={left+14*bw,top+3*bh},size={bw,bh},fColor=(col[33][0],col[33][1],col[33][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="As"
	Button Se0,pos={left+15*bw,top+3*bh},size={bw,bh},fColor=(col[34][0],col[34][1],col[34][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Se"
	Button Br0,pos={left+16*bw,top+3*bh},size={bw,bh},fColor=(col[35][0],col[35][1],col[35][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Br"
	Button Kr0,pos={left+17*bw,top+3*bh},size={bw,bh},fColor=(col[36][0],col[36][1],col[36][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Kr"

	Button In0,pos={left+12*bw,top+4*bh},size={bw,bh},fColor=(col[49][0],col[49][1],col[49][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="In"
	Button Sn0,pos={left+13*bw,top+4*bh},size={bw,bh},fColor=(col[50][0],col[50][1],col[50][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Sn"
	Button Sb0,pos={left+14*bw,top+4*bh},size={bw,bh},fColor=(col[51][0],col[51][1],col[51][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Sb"
	Button Te0,pos={left+15*bw,top+4*bh},size={bw,bh},fColor=(col[52][0],col[52][1],col[52][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Te"
	Button I0,pos={left+16*bw,top+4*bh},size={bw,bh},fColor=(col[53][0],col[53][1],col[53][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="I"
	Button Xe0,pos={left+17*bw,top+4*bh},size={bw,bh},fColor=(col[54][0],col[54][1],col[54][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Xe"

	Button Tl0,pos={left+12*bw,top+5*bh},size={bw,bh},fColor=(col[81][0],col[81][1],col[81][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Tl"
	Button Pb0,pos={left+13*bw,top+5*bh},size={bw,bh},fColor=(col[82][0],col[82][1],col[82][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Pb"
	Button Bi0,pos={left+14*bw,top+5*bh},size={bw,bh},fColor=(col[83][0],col[83][1],col[83][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Bi"
	Button Po0,pos={left+15*bw,top+5*bh},size={bw,bh},fColor=(col[84][0],col[84][1],col[84][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Po"
	Button At0,pos={left+16*bw,top+5*bh},size={bw,bh},fColor=(col[85][0],col[85][1],col[85][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="At"
	Button Rn0,pos={left+17*bw,top+5*bh},size={bw,bh},fColor=(col[86][0],col[86][1],col[86][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Rn"

	Button Ce0,pos={left+4*bw,top+7.5*bh},size={bw,bh},fColor=(col[58][0],col[58][1],col[58][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ce"
	Button Pr0,pos={left+5*bw,top+7.5*bh},size={bw,bh},fColor=(col[59][0],col[59][1],col[59][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Pr"
	Button Nd0,pos={left+6*bw,top+7.5*bh},size={bw,bh},fColor=(col[60][0],col[60][1],col[60][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Nd"
	Button Pm0,pos={left+7*bw,top+7.5*bh},size={bw,bh},fColor=(col[61][0],col[61][1],col[61][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Pm"
	Button Sm0,pos={left+8*bw,top+7.5*bh},size={bw,bh},fColor=(col[62][0],col[62][1],col[63][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Sm"
	Button Eu0,pos={left+9*bw,top+7.5*bh},size={bw,bh},fColor=(col[63][0],col[63][1],col[63][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Eu"
	Button Gd0,pos={left+10*bw,top+7.5*bh},size={bw,bh},fColor=(col[64][0],col[64][1],col[64][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Gd"
	Button Tb0,pos={left+11*bw,top+7.5*bh},size={bw,bh},fColor=(col[65][0],col[65][1],col[65][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Tb"
	Button Dy0,pos={left+12*bw,top+7.5*bh},size={bw,bh},fColor=(col[66][0],col[66][1],col[66][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Dy"
	Button Ho0,pos={left+13*bw,top+7.5*bh},size={bw,bh},fColor=(col[67][0],col[67][1],col[67][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Ho"
	Button Er0,pos={left+14*bw,top+7.5*bh},size={bw,bh},fColor=(col[68][0],col[68][1],col[68][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Er"
	Button Tm0,pos={left+15*bw,top+7.5*bh},size={bw,bh},fColor=(col[69][0],col[69][1],col[69][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Tm"
	Button Yb0,pos={left+16*bw,top+7.5*bh},size={bw,bh},fColor=(col[70][0],col[70][1],col[70][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Yb"
	Button Lu0,pos={left+17*bw,top+7.5*bh},size={bw,bh},fColor=(col[71][0],col[71][1],col[71][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Lu"
	
	Button Th0,pos={left+4*bw,top+8.5*bh},size={bw,bh},fColor=(col[90][0],col[90][1],col[90][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Th"
	Button Pa0,pos={left+5*bw,top+8.5*bh},size={bw,bh},fColor=(col[91][0],col[91][1],col[91][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Pa"
	Button U0,pos={left+6*bw,top+8.5*bh},size={bw,bh},fColor=(col[92][0],col[92][1],col[92][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="U"
	Button Np0,pos={left+7*bw,top+8.5*bh},size={bw,bh},fColor=(col[93][0],col[93][1],col[93][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Np"
	Button Pu0,pos={left+8*bw,top+8.5*bh},size={bw,bh},fColor=(col[94][0],col[94][1],col[94][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Pu"
	Button Am0,pos={left+9*bw,top+8.5*bh},size={bw,bh},fColor=(col[95][0],col[95][1],col[95][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Am"
	Button Cm0,pos={left+10*bw,top+8.5*bh},size={bw,bh},fColor=(col[96][0],col[96][1],col[96][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Cm"
	Button Bk0,pos={left+11*bw,top+8.5*bh},size={bw,bh},fColor=(col[97][0],col[97][1],col[97][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Bk"
	Button Cf0,pos={left+12*bw,top+8.5*bh},size={bw,bh},fColor=(col[98][0],col[98][1],col[98][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Cf"
	Button Es0,pos={left+13*bw,top+8.5*bh},size={bw,bh},fColor=(col[99][0],col[99][1],col[99][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Es"
	Button Fm0,pos={left+14*bw,top+8.5*bh},size={bw,bh},fColor=(col[100][0],col[100][1],col[100][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Fm"
	Button Md0,pos={left+15*bw,top+8.5*bh},size={bw,bh},fColor=(col[101][0],col[101][1],col[101][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Md"
	Button No0,pos={left+16*bw,top+8.5*bh},size={bw,bh},fColor=(col[102][0],col[102][1],col[102][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="No"
	Button Lr0,pos={left+17*bw,top+8.5*bh},size={bw,bh},fColor=(col[103][0],col[103][1],col[103][2]),fsize=gscf*dfs,proc=ATH_XPSData#PTGetState,title="Lr"

	// controls
	PopupMenu PTresize,pos={left+12,top+9.8*bh},size={83,20},proc=ATH_XPSData#PTResizePanel,title="Scale  "
	PopupMenu PTresize,help={"Use this to resize the panel."},fSize=12,fStyle=1, fColor=(65535,65535,65535)
	PopupMenu PTresize,mode=1,bodywidth=50,popvalue=strgscf,value=#gscfstr
	SetDrawLayer UserBack
	//DrawRect left+1,top+9.5*bh,left+50,top+9.5*bh+18  // was background for scale popup
	
	Button ShowButton0, pos={left+2.5*bw, top-0.1*bh},size={30.00*gscf,25.00*gscf},proc=ATH_XPSData#ShowButtonProc,title="Show"
	Button ShowButton0, fsize=gscf*dfs, fColor=(57346,65535,49151)
	Button ClearButton0, pos={left+bw, top+7.5*bh},size={32.00*gscf,25.00*gscf},proc=ATH_XPSData#ClearButtonProc,title="Clear"
	Button ClearButton0, fsize=gscf*dfs, fColor=(65535,49151,55704)

	CheckBox CoreLevelsButton0, pos={left+5*bw, top-0.25*bh},size={32.00*gscf,25.00*gscf}, title="Core Levels"
	CheckBox CoreLevelsButton0, fsize=gscf*dfs, fColor=(49151,65535,49151), variable=gCL,value = 1, help={cl2edge}	
	CheckBox PhCrossSectionsButton0, pos={left+12.5*bw, top-0.25*bh},size={32.00*gscf,25.00*gscf}, title="Ph. Cross Sections"
	CheckBox PhCrossSectionsButton0, fsize=gscf*dfs, fColor=(49151,49152,65535), variable=gPhCs,value = 1
	CheckBox KEButton0, pos={left+9*bw, top-0.25*bh},size={32.00*gscf,25.00*gscf}, title="KE"
	CheckBox KEButton0, fsize=gscf*dfs, variable=gKE, value = 0, fColor=(65535,65535,65535)	

	SetVariable hvSetVariable0, pos={left+8.5*bw, top+0.7*bh},size={50*gscf,25.00*gscf}, title="hv"
	SetVariable hvSetVariable0, fsize=gscf*dfs,value=ghv,fColor=(49151,60031,65535), proc=ATH_XPSData#SetVariableFunction

	SetVariable wfSetVariable0, pos={left+8.5*bw, top+1.8*bh},size={50*gscf,25.00*gscf}, title="wf"
	SetVariable wfSetVariable0, fsize=gscf*dfs,value=gwf,fColor=(49151,60031,65535), proc=ATH_XPSData#SetVariableFunction

	SetVariable ElowSetVariable0, pos={left+5*bw, top+0.7*bh},size={50*gscf,25.00*gscf}, title="E\\Bmin"
	SetVariable ElowSetVariable0, fsize=gscf*dfs,value=gElow,fColor=(49151,60031,65535), proc=ATH_XPSData#SetVariableFunction

	SetVariable EhighSetVariable0, pos={left+5*bw, top+1.8*bh},size={50*gscf,25.00*gscf}, title="E\\Bmax"
	SetVariable EhighSetVariable0, fsize=gscf*dfs,value=gEhigh,fColor=(49151,60031,65535), proc=ATH_XPSData#SetVariableFunction
										
	TitleBox title0,pos={left+4*bw, top+9.85*bh},size={132.00,11.00},title="athina: Photoionisation cross-sections & electron binding energies"
	TitleBox title0,frame=0,fColor=(52428,52428,52428),fsize=gscf*dfs
End

//
static Function SetVariableFunction(STRUCT WMSetVariableAction& sv) : SetVariableControl

	NVAR ghv = root:Packages:ATH_DataFolder:XPSReferenceData:ghv
	NVAR gwf = root:Packages:ATH_DataFolder:XPSReferenceData:gwf	
	NVAR gElow = root:Packages:ATH_DataFolder:XPSReferenceData:gElow
	NVAR gEhigh = root:Packages:ATH_DataFolder:XPSReferenceData:gEhigh	
	switch(sv.eventCode)
		case 6:
		strswitch(sv.ctrlName)
			case "hvSetVariable0":
				ghv = sv.dval
				break
			case "wfSetVariable0":
				gwf = sv.dval
				break
			case "EhighSetVariable0":
				gEhigh = sv.dval
				break
			case "ElowSetVariable0":
				gElow = sv.dval
				break								
		endswitch
			break
	endswitch
	return 0
End


//************************************************************
// Resize PT Panel
static Function PTResizePanel(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	NVAR gscf = root:Packages:ATH_DataFolder:XPSReferenceData:scf
	NVAR gscfpN = root:Packages:ATH_DataFolder:XPSReferenceData:scfpN
	
	// wait for mouse up event
	switch(pa.eventCode)
	case 2:

		// if no change in scale factor, no change in panel
		if (pa.popNum==gscfpN)
			return 0
		endif
		
		// store current states
		gscfpN = pa.popNum
		
		// redraw panel at new scale factor
		gscf = str2num(pa.popStr)
			
		KillWindow XPSReferenceDataPanel

		PTDisplayPanel()
		PopupMenu PTresize mode=gscfpN

		return 0
	endswitch
End

//************************************************************
static Function GetAtNr(Estr)
	string Estr
	wave AtNr= root:Packages:ATH_DataFolder:XPSReferenceData:AtNr
	wave/T ElementSym= root:Packages:ATH_DataFolder:XPSReferenceData:ElementSym
	variable ii
	
	for (ii=0; ii<maxelem; ii+=1)
		if (cmpstr(Estr,Elementsym[ii])==0)
			return AtNr[ii]
		endif
	endfor
	
	return -1
end


//************************************************************
static Function ShowButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch( ba.eventCode )
		case 2: // mouse up
			wave Col= root:Packages:ATH_DataFolder:XPSReferenceData:Col
			wave ElemSelect= root:Packages:ATH_DataFolder:XPSReferenceData:ElemSelect
			wave/T ElementSym= root:Packages:ATH_DataFolder:XPSReferenceData:ElementSym
			NVAR gElow = root:Packages:ATH_DataFolder:XPSReferenceData:gElow
			NVAR gEhigh = root:Packages:ATH_DataFolder:XPSReferenceData:gEhigh	
			NVAR ghv = root:Packages:ATH_DataFolder:XPSReferenceData:ghv
			NVAR gwf = root:Packages:ATH_DataFolder:XPSReferenceData:gwf
			NVAR gkE = root:Packages:ATH_DataFolder:XPSReferenceData:gKE
			NVAR gCL = root:Packages:ATH_DataFolder:XPSReferenceData:gCL
			NVAR gPhCs = root:Packages:ATH_DataFolder:XPSReferenceData:gPhCs
			//PhCs
			string str, graphName, elementStr, allSelectedElements
			variable ii, iimax
			string allGraphWindows = ""
			allSelectedElements = GetSelectedElementsStr(ElementSym, ElemSelect)
			if(gPhCs)
				iimax =ItemsInList(allSelectedElements)
				for (ii=0; ii<iimax;ii+=1)
					elementStr = StringFromList(ii, allSelectedElements)
					graphName = "ATH_" + elementStr + "_PhCs"
					allGraphWindows += graphName +";"
					DoWindow/F $graphname
					if(!V_flag) // Window does not exist
						PlotPhCrossSectionOfElement(elementStr)
					endif
				endfor
				// CAUTION: Tiling hard-coded, change /A=(x, y) if you like
				if(strlen(allGraphWindows)) // If "" TileWindows tiles everything
					TileWindows/WINS=allGraphWindows/A=(3,6) //IP9 only (/WINS)
				endif
			endif
			//CL
			if(gCL)
				ShowNotebookCoreLevelsInEnergyRange(gElow, gEhigh, \
				KE = gKE, hv = ghv, wf = gwf,elements = allSelectedElements)
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//************************************************************
static Function ClearButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			wave Col= root:Packages:ATH_DataFolder:XPSReferenceData:Col
			wave ElemSelect= root:Packages:ATH_DataFolder:XPSReferenceData:ElemSelect
			wave OldElemSelect= root:Packages:ATH_DataFolder:XPSReferenceData:OldElemSelect
			wave/T ElementSym= root:Packages:ATH_DataFolder:XPSReferenceData:ElementSym
			string str, graphName, elementStr, allSelectedElements, oldSelectedElements
			variable ii, iimax
			
			// Kill graphs
			allSelectedElements =  GetSelectedElementsStr(ElementSym, ElemSelect) 
			allSelectedElements += GetSelectedElementsStr(ElementSym, OldElemSelect)
			allSelectedElements = ATH_String#UniquifyStringList(allSelectedElements, ";")
			iimax =ItemsInList(allSelectedElements)
			for (ii=0; ii<iimax;ii+=1)
				elementStr = StringFromList(ii, allSelectedElements)
				graphName = "ATH_" + elementStr + "_PhCs"
				KillWindow/Z $graphName
			endfor			
			
			// Clear selected button in the panel and reset ElemSelect wave
			for (ii=1; ii<maxelem;ii+=1)
				ElemSelect[ii]=0
				str=ElementSym[ii] +"0"
				col[ii][0]=unmarkR
				col[ii][1]=unmarkG
				col[ii][2]=unmarkB
				Button $str,fColor=(col[ii][0],col[ii][1],col[ii][2])
			endfor	
			KillWindow/Z ATH_xraydata		
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//************************************************************
// Periodic Table Get State
// this button procedure is called whenever an element button
// is entered, left, or pushed
static Function PTGetState(STRUCT WMButtonAction &bs) : ButtonControl
	
	wave Col= root:Packages:ATH_DataFolder:XPSReferenceData:Col
	wave ElemSelect= root:Packages:ATH_DataFolder:XPSReferenceData:ElemSelect
	wave OldElemSelect= root:Packages:ATH_DataFolder:XPSReferenceData:OldElemSelect
	
	string str
	variable atomnr

	switch(bs.eventCode)
		case 1:
			OldElemSelect = ElemSelect
			break
		case 2: // mouse up
			str=bs.ctrlname
			str=removeending(str)
			atomnr=GetAtNr(str)
			if (ElemSelect[atomnr]==0)
				ElemSelect[atomnr]=1
				str=bs.ctrlname
				col[atomnr][0]=markR
				col[atomnr][1]=markG
				col[atomnr][2]=markB
				Button $str,fColor=(markR,markG,markB)
			else
				ElemSelect[atomnr]=0
				str=bs.ctrlname
				col[atomnr][0]=unmarkR
				col[atomnr][1]=unmarkG
				col[atomnr][2]=unmarkB
				Button $str,fColor=(unmarkR,unmarkG,unmarkB)
			endif
			break
	endswitch

	return 0
end

// DimLabels for the dataset

static Function/S GetSelectedElementsStr(WAVE/T symbolsW, WAVE selw)
	// Return a string list with the elements currently selected, e.g "Si;Co;Ir;"
	string selectedElementsStr = ""

	variable ElemMax = numpnts(selw), i
	
	for(i = 1; i < ElemMax; i++)
		if(selw[i])
			selectedElementsStr += symbolsW[i]
			selectedElementsStr += ";"			
		endif
	endfor
	return selectedElementsStr
End

static Function/S GetColumnOrderFromSelectedElement(string elementStr)
	SVAR ATH_OrbitalOrder = root:Packages:ATH_DataFolder:XPSReferenceData:gATH_OrbitalOrder
	string RegExpBaseStr = "[1-9]{1}[s,p,d,f]{1}" // Use "Symbol" + RegExpBaseStr
	string matchedFilesStr = SortList(GrepList(ATH_OrbitalOrder, elementStr + RegExpBaseStr), ";", 16)
	return matchedFilesStr
End

static Function PlotPhCrossSectionOfElement(string elementStr)
	string allDimLabels = GetColumnOrderFromSelectedElement(elementStr)
	wave PhCSWave= root:Packages:ATH_DataFolder:XPSReferenceData:ATH_PhCrossSectionTable
	string graphName = "ATH_" + elementStr + "_PhCs" // Names for DoWindow/F
	string titleGraph = elementStr + " Photoionisation cross-section"
	variable i
	variable imax = ItemsInList(allDimLabels)
	string tagE, tagCS
	Display/K=1/N=$graphName as titleGraph
	if(mod(imax,2))
		Abort "Error, check PlotPhCrossSectionOfElement"
	endif
	
	for(i = 0; i < imax; i+=2)
		tagCS = StringFromList(i, allDimLabels)
		tagE  = StringFromList(i + 1, allDimLabels)
		AppendToGraph/W=$graphName PhCSWave[][%$tagCS] vs PhCSWave[][%$tagE]			
	endfor	
	
	ModifyGraph/W=$graphName grid(left)=1,log(left)=1,tick=2,mirror=1,fSize=12,lsize=2,gridRGB(left)=(43690,43690,43690)
	SetAxis/W=$graphName bottom *,1500 // CHANGE: Energy range to your taste.
	Label/W=$graphName left "\\Z14 Cross section (Mbarn)"
	Label/W=$graphName bottom "\\Z14 Photon energy (eV)"
	// Change colors for traces
	variable red, green, blue
	string legendStr = ""
	string allTracesinGraph = TraceNameList(graphName,";",1)
	imax = ItemsInList(allTracesinGraph)
	for(i = 0; i < imax; i++)
		[red, green, blue] = SetTraceColor(i)		
		ModifyGraph/W=$graphName rgb($StringFromList(i,allTracesinGraph))=(red,green,blue)
	endfor
	//Add legends
	string bufferStr
	for(i = 0; i < imax; i++)
		sscanf StringFromList(2*i, allDimLabels), "%[A-Za-z0-9]_CS", bufferStr
		legendStr += "\\s(" + StringFromList(i,allTracesinGraph)+") " + bufferStr + "\r"	
	endfor
	legendStr = RemoveEnding(legendStr, "\r") // Drop the last "\r"
	Legend/C/N=text0/J/F=0/S=3/A=RB ("\Z12" +legendStr)
End

static Function [variable red, variable green, variable blue] SetTraceColor(variable colorIndex)
	/// Give a RGB triplet for 16 distinct colors.
	/// https://www.wavemetrics.com/forum/general/different-colors-different-waves
	/// Use as Modifygraph/W=WinName rgb(wavename) = (red, green, blue)

    colorIndex = mod(colorIndex, 16)          // Wrap around if necessary
    switch(colorIndex)
        case 0:
            red = 65535; green = 16385; blue = 16385;           // Red
            break           
        case 1:
            red = 2; green = 39321; blue = 1;                       // Green
            break          
        case 2:
            red = 0; green = 0; blue = 65535;                       // Blue
            break
        case 3:
            red = 39321; green = 1; blue = 31457;                   // Purple
            break
        case 4:
            red = 39321; green = 39321; blue = 39321;           // Gray
            break
        case 5:
            red = 65535; green = 32768; blue = 32768;           // Salmon
            break
        case 6:
            red = 0; green = 65535; blue = 0;                       // Lime
            break
        case 7:
            red = 16385; green = 65535; blue = 65535;           // Turquoise
            break
        case 8:
            red = 65535; green = 32768; blue = 58981;           // Light purple
            break
        case 9:
            red = 39321; green = 26208; blue = 1;                   // Brown
            break
        case 10:
            red = 52428; green = 34958; blue = 1;                   // Light brown
            break
        case 11:
            red = 65535; green = 32764; blue = 16385;           // Orange
            break
        case 12:
            red = 1; green = 52428; blue = 26586;                   // Teal
            break
        case 13:
            red = 1; green = 3; blue = 39321;                   // Dark blue
            break
        case 14:
            red = 65535; green = 49151; blue = 55704;           // Pink
            break
        case 15:
            red = 0; green = 0; blue = 0;                       // Black
            break      
     endswitch

    
     return [red, green, blue]
End



// XPS Part DEV
Function CreateElemSelectCoreLevels([int KE, variable hv, variable wf]) // Works, we create the core levels table.

	if(1) // Here if you tick the core level mode
		WAVE ElemSelect= root:Packages:ATH_DataFolder:XPSReferenceData:ElemSelect
		WAVE CoreLevels= root:Packages:ATH_DataFolder:XPSReferenceData:ATH_ElectronBindingEnergies
		variable nElem = sum(ElemSelect)
		Make/O/N=(nElem, 24) root:Packages:ATH_DataFolder:XPSReferenceData:CoreLevelsSelect
		WAVE wRef = root:Packages:ATH_DataFolder:XPSReferenceData:CoreLevelsSelect
		variable i, ii = 0
		for(i = 1; i < 93;i++)
			if(ElemSelect[i])
				wRef[ii][] = CoreLevels[i][q]
				SetDimLabel 0, ii, $GetDimLabel(CoreLevels, 0, i), wRef
				ii++
			endif
		endfor
		CopyDimLabels/COLS=1 CoreLevels, wRef
	endif
	if(KE && hv > wf)
		wRef = ((hv>(wRef[p][q]+wf)) && wRef[p][q]) ? (hv - (wRef[p][q] + wf)) : 0
		Note/K wRef, "mode:KE"
	else
		Note/K wRef, "mode:BE"
	endif
	
End

// Not the most effective fuction having to call GetCrossSectionAtPhotonEnergy
// several times
Function CreateElemSelectCSAtPhotonEnergy(WAVE wRef, variable hv, [int normalise, int maskExc])
	// wRef here is root:Packages:ATH_DataFolder:XPSReferenceData:CoreLevelsSelect
	//	RSF p3/2 = RSFp * 2/3
	//	RSF p1/2 = RSFp * 1/3
	//	RSF d5/2 = RSFd * 3/5
	//	RSF d3/2 = RSFd * 2/5
	//	RSF f7/2 = RSFf * 4/7
	//	RSF f5/2 = RSFf * 3/7
	
		
	if(1) // Here if you tick the core level mode
		Duplicate/O wRef, root:Packages:ATH_DataFolder:XPSReferenceData:CSSelect
		WAVE wCS = root:Packages:ATH_DataFolder:XPSReferenceData:CSSelect
		variable ii = DimSize(wCS, 0), i
		variable jj = DimSize(wCS, 1), j
		string elem, orbital, subshell
		for(i = 0; i < ii;i++)
			elem = GetDimLabel(wRef,0,i)
			for(j = 0; j < jj;j++)
				orbital = GetDimLabel(wRef,1,j)
				subshell = orbital[0,1] // 2s,3p,4d,5f ...
				variable csV = GetCrossSectionAtPhotonEnergy(elem,subshell, hv)
				if(csV)
					if(strlen(orbital) > 2)
						wCS[i][j] = csV * soRSF(orbital)
					else
						wCS[i][j] = csV
					endif
				else
					wCS[i][j] = csv
				endif
			endfor
		endfor
	endif
	if(normalise)
		variable maxCS = WaveMax(wCS)
		wCS/=maxCS
	endif
	if(maskExc)
		wCS = wCS[p][q] ? 1 : 0
	endif
	return 0
End

// Not the most effective fuction having to call GetCrossSectionAtPhotonEnergy
// several times

Function GetCrossSectionAtPhotonEnergy(string elem, string orb, variable hv)
	// Get the ionisation cross-section, use DimLavels
	
	// Orb might be given as 2p1/2 but PhCS is given for the subshell, 2p
	orb = orb[0,1]
	//
	string energyStr = elem + orb + "_E"
	string csStr = elem + orb + "_CS"
	WAVE crossSection= root:Packages:ATH_DataFolder:XPSReferenceData:ATH_PhCrossSectionTable
	variable idxE = FindDimLabel(crossSection, 1, energyStr)
	variable idxCS = FindDimLabel(crossSection, 1, csStr)
	if(idxE < 0 || idxCS < 0) // DimLabel not found!
		return 0
	endif
	MatrixOP/FREE energy = col(crossSection, idxE)
	MatrixOP/FREE cs = col(crossSection, idxCS)
	if(ATH_Num#IsNumberInWaveRangeQ(energy, hv))
		return interp(hv, energy, cs)
	else 
		return 0
	endif
End

Function soRSF(string orbital)
	// Return relative sensitivity factor
	// orbital is a string of the for 2p, 2p3/2
	// N.B No checks for valid inputs!!!!
	string subshell = orbital[1]
	string so = orbital[2,4]
	
	if(!cmpstr(subshell,"p"))
		if(!cmpstr(so,"1/2"))
			return 1/3
		elseif(!cmpstr(so,"3/2"))
			return 2/3
		else
			return 0
		endif
	elseif(!cmpstr(subshell,"d"))
		if(!cmpstr(so,"5/2"))
			return 3/5
		elseif(!cmpstr(so,"3/2"))
			return 2/5
		else
			return 0
		endif
	elseif(!cmpstr(subshell,"f"))
		if(!cmpstr(so,"7/2"))
			return 4/7
		elseif(!cmpstr(so,"5/2"))
			return 3/7
		else
			return 0
		endif
	else
		return -1
	endif
End

Function/S CoreLevelsInEnergyRange(variable Elow, variable Ehigh,
	[int KE, variable hv, variable wf, string elements])
	//
	WAVE wRef = root:Packages:ATH_DataFolder:XPSReferenceData:ATH_ElectronBindingEnergies
	WAVE wRefA = root:Packages:ATH_DataFolder:XPSReferenceData:ATH_Auger_KE
	WAVE/T wRefT = root:Packages:ATH_DataFolder:XPSReferenceData:ATH_Auger_Transitions

	string report = ""
	variable ii = DimSize(wRef, 0), i
	variable jj = DimSize(wRef, 1), j
	string elem, orbital, strBufferAuger = "", strBuffer = ""
	variable energy, buffer, energyAuger0, energyAuger1

	if(Elow >= Ehigh)
		return ""
	endif

	for(i = 1; i < ii;i++) // Zeroth column is -, dummy elelment
		elem = GetDimLabel(wRef,0,i)
		if(FindListItem(elem, elements) < 0)
			continue
		endif
		// Auger
		if(KE && hv > wf)
			energyAuger0 = wRefA[%$elem][0]
			energyAuger1 = wRefA[%$elem][1]
			if(!(energyAuger0 < Elow || energyAuger0 > Ehigh || (hv <= (wf+energyAuger0))))
				strBufferAuger += "{"+TrimString(wRefT[%$elem][0])+"} " + num2str(energyAuger0) + " eV"
			endif
			if(!(energyAuger1 < Elow || energyAuger1 > Ehigh || (hv < (wf+energyAuger1))))
				if(strlen(strBufferAuger))
					strBufferAuger += ", {"+TrimString(wRefT[%$elem][1])+"} " + num2str(energyAuger1) + " eV"
				else
					strBufferAuger += "{"+TrimString(wRefT[%$elem][1])+"} " + num2str(energyAuger1) + " eV"
				endif
			endif
		endif
		// Core levels
		for(j = 0; j < jj;j++)
			orbital = GetDimLabel(wRef,1,j)
			energy = wRef[%$elem][%$orbital]
			if(!energy) // there is no core level, just 0 to fill the table
				continue
			endif
			if(KE && hv > wf)
				buffer = hv - energy - wf
				energy = buffer
			endif
			if(!(energy < Elow || energy > Ehigh))
				strBuffer += "("+orbital+") "+ num2str(energy)+" eV, "
			endif
		endfor
		if(strlen(strBuffer))
			report += elem + " (Z="+num2str(i)+"): " + RemoveEnding(strBuffer,", ")
		endif
		if(strlen(strBufferAuger))
			if(strlen(strBuffer))
			report += ", "+strBufferAuger +".\n"
			else
			report +=elem + ": "+strBufferAuger +".\n"
			endif
		else
			report += "\n"
		endif
		strBuffer = ""
		strBufferAuger = ""
	endfor
	return report
End

static Function ShowNotebookCoreLevelsInEnergyRange(variable Elow, variable Ehigh,
	[int KE, variable hv, variable wf, string elements])
	string report = CoreLevelsInEnergyRange(Elow, Ehigh, KE = KE, hv = hv, wf = wf,elements=elements)
	if(!strlen(report))
		return -1
	endif
	string infoStr, notebookText
	if(KE && hv > wf)
		infoStr = "Energy Scale -> KE (eV)," +  "Energy Range (eV) = ["+num2str(Elow)+","+num2str(Ehigh)+"], "
		infoStr += "hv = " + num2str(hv) +" eV, Wf = " + num2str(wf) + "e V.\n\n"
	else
		infoStr = "Energy Scale -> BE (eV), Energy Range = ["+num2str(Elow)+","+num2str(Ehigh)+"].\n\n"
	endif	
		
	notebookText = infoStr  + report
	
	KillWindow/Z ATH_xraydata
	NewNotebook/F=0/K=1/N=ATH_xraydata as "athina x-ray data"
	Notebook ATH_xraydata, fSize = 14, text = notebookText

End
