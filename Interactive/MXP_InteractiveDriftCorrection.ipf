#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion= 9
#pragma ModuleName = InteractiveDriftCorrection
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


//Structure InteractiveWaveDriftStruct
//	variable mode			// [mandatory] 0: drift a 2D wave or 1: layer of a 3D wave
//	WAVE driftWave			// [mandatory] wave to drift - will NOT be modified in any way
//	WAVE refWave			// [mandatory] wave to compare - will NOT be modified in any way
//	WAVE cmpWave			// [optional] result of comparison between orgWave and refWave will be written here
//	WAVE modWave			// [optional] modified wave - saves the scaled and drifted version of driftWave
//	WAVE dichroismWave		// [optional] calculates the XMCD/XMLD from driftWave and refWave
//	variable xdrift 		// x drift	(default 0)
//	variable ydrift     	// y drift	(default 0)
//	variable driftStep  	// x position of the baseline		(default DimDelta(driftWave))
//EndStructure
//
//Function InitializeDriftCorrection(STRUCT InteractiveWaveDriftStruct &s)
//	// Initialise
//	string winNameStr = WinName(0, 1, 1)
//	string imgNameTopGraphStr = StringFromList(0, ImageNameList(winNameStr, ";"),";")
//	Wave w3dref = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
//	s.xdrift = 1
//	s.ydrift = 1
//	s.driftStep = 1
//End

// TODO: Copy the code from InteractiveZProfile and edit it.
// Use Emile's PED