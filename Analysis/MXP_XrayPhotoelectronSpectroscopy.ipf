#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


// ------------------------------------------------------- //
// Developed by Evangelos Golias.
// Contact: evangelos.golias@gmail.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, IN CONNECTION WITH THE USE OF SOFTWARE.
// ------------------------------------------------------- //


Function MXP_LaunchScaleXPSSpectrum()
	///	Add description here.
	/// Save the
	DFREF dfr = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:XPSSpectrumScale" ) // Root folder here
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
