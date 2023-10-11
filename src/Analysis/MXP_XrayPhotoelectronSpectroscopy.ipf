#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
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


Function MXP_LaunchScalePESSpectrum()
	///	Add description here.
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESSpectrumScale" ) // Root folder here
	variable STV, hv, wf, Escale, BE_min, BE_max
	NVAR/Z/SDFR=dfr gMXP_PhotonEnergy
	if(!NVAR_Exists(gMXP_PhotonEnergy))
		variable/G dfr:gMXP_PhotonEnergy
		variable/G dfr:gMXP_StartVoltage
		variable/G dfr:gMXP_WorkFunction
		variable/G dfr:gMXP_EnergyScale
	else
		NVAR/Z/SDFR=dfr gMXP_StartVoltage
		NVAR/Z/SDFR=dfr gMXP_WorkFunction
		NVAR/Z/SDFR=dfr gMXP_EnergyScale
		NVAR/Z/SDFR=dfr gMXP_PhotonEnergy
		hv = gMXP_PhotonEnergy
		STV = gMXP_StartVoltage
		Wf = gMXP_WorkFunction
		Escale = gMXP_EnergyScale
	endif

	
	string waveListStr = TraceNameList("", ";", 1)
	string wavenameStr = StringFromList(0, waveListStr)
	
	Prompt wavenameStr, "Select wave", popup, waveListStr
	Prompt hv, "Photon energy"
	Prompt STV, "Start Voltage"
	Prompt Wf, "Work function"
	Prompt Escale, "Energy scale"
	DoPrompt "Scale to binding energy (all zeros for no scale)", wavenameStr, hv, STV, Wf, Escale
		
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE wRef = TraceNameToWaveRef("", wavenameStr)

	BE_min = hv - STV - Wf - Escale/2
	BE_max = hv - STV - Wf + Escale/2

	SetScale/I x, BE_max, BE_min, wRef
	string noteStr = "hv = " + num2str(hv) + " eV," + "STV = " + num2str(STV) + " V," +\
					 "Wf = " + num2str(Wf) + " eV," + "Escale = " + num2str(Escale) + " eV"
	Note/K wRef, noteStr // Clear the note. 
	noteStr = "SetScale/I x," + num2str(BE_max) + "," + num2str(BE_min) + ","+ NameofWave(wRef)
	Note wRef, noteStr
	
	// plot  
	SetAxis/A/R bottom
	Label bottom "Binding Energy (eV)"
	Label left "\\u#2Intensity (arb. u.)"
	//
	gMXP_PhotonEnergy = hv
	gMXP_StartVoltage = STV
	gMXP_WorkFunction = Wf
	gMXP_EnergyScale  = Escale
End

Function MXP_LaunchScalePartialPESSpectrum()
	/// In some measurements one of the edges of the dispersive plane is clippeda and
	/// MXP_LaunchScalePESSpectrum() cannot scale the PES spectrum. We can recover the
	/// PES spectrum if we can see one of the two edges and we know how many pixels make 
	/// full scale. 
	/// NB. Use one edge and set the A pointer, usually the end at the hight kinetic energy is seen
	
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:PESPartialSpectrumScale" ) // Root folder here
	variable STV, hv, wf, Escale, FullEnergyScale, BE_min, BE_max
	NVAR/Z/SDFR=dfr gMXP_PhotonEnergy
	if(!NVAR_Exists(gMXP_PhotonEnergy))
		variable/G dfr:gMXP_PhotonEnergy
		variable/G dfr:gMXP_StartVoltage
		variable/G dfr:gMXP_WorkFunction
		variable/G dfr:gMXP_EnergyScale
		variable/G dfr:gMXP_FullEnergyScale
	else
		NVAR/Z/SDFR=dfr gMXP_StartVoltage
		NVAR/Z/SDFR=dfr gMXP_WorkFunction
		NVAR/Z/SDFR=dfr gMXP_EnergyScale
		NVAR/Z/SDFR=dfr gMXP_PhotonEnergy
		NVAR/Z/SDFR=dfr gMXP_FullEnergyScale
		hv = gMXP_PhotonEnergy
		STV = gMXP_StartVoltage
		Wf = gMXP_WorkFunction
		Escale = gMXP_EnergyScale
		FullEnergyScale = gMXP_FullEnergyScale
	endif

	
	string waveListStr = TraceNameList("", ";", 1)
	string wavenameStr = StringFromList(0, waveListStr)
	
	Prompt wavenameStr, "Select wave", popup, waveListStr
	Prompt hv, "Photon energy"
	Prompt STV, "Start Voltage"
	Prompt Wf, "Work function"
	Prompt Escale, "Energy scale"
	Prompt FullEnergyScale, "Full Energy scale"
	DoPrompt "Scale to binding energy (all zeros for no scale)", wavenameStr, hv, STV, Wf, Escale
		
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE wRef = TraceNameToWaveRef("", wavenameStr)

	BE_min = hv - STV - Wf - Escale/2
	BE_max = hv - STV - Wf + Escale/2

	SetScale/I x, BE_max, BE_min, wRef
	string noteStr = "hv = " + num2str(hv) + " eV," + "STV = " + num2str(STV) + " V," +\
					 "Wf = " + num2str(Wf) + " eV," + "Escale = " + num2str(Escale) + " eV"
	Note/K wRef, noteStr // Clear the note. 
	noteStr = "SetScale/I x," + num2str(BE_max) + "," + num2str(BE_min) + ","+ NameofWave(wRef)
	Note wRef, noteStr
	
	// plot  
	SetAxis/A/R bottom
	Label bottom "Binding Energy (eV)"
	Label left "\\u#2Intensity (arb. u.)"
	//
	gMXP_PhotonEnergy = hv
	gMXP_StartVoltage = STV
	gMXP_WorkFunction = Wf
	gMXP_EnergyScale  = Escale
End