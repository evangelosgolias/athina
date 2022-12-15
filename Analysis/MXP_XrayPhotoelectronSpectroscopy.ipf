﻿#pragma TextEncoding = "UTF-8"
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
	string waveListStr = TraceNameList("", ";", 1)
	string wavenameStr = StringFromList(0, waveListStr)
	
	variable STV, hv, wf, Escale, BE_min, BE_max
	Prompt wavenameStr, "Select wave", popup, waveListStr
	Prompt hv, "Photon energy"
	Prompt STV, "Start Voltage"
	Prompt Wf, "Work function"
	Prompt Escale, "Energy scale"
	DoPrompt "Scale to binding energy.", wavenameStr, hv, STV, Wf, Escale
	if(V_flag) // User cancelled
		return 1
	endif
	WAVE wRef = TraceNameToWaveRef("", wavenameStr)

	BE_min = hv - STV - Wf - Escale/2
	BE_max = hv - STV - Wf + Escale/2
	
	SetScale/I x, BE_max, BE_min, wRef
End