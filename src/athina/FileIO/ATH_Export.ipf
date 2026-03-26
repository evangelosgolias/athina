#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3                           // Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}           // Set default tab width in Igor Pro 9 and later
#pragma IgorVersion  = 9
#pragma ModuleName = ATH_Export

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


/// @module ATH_Export_Repeat
/// @brief Module ATH_Export_Repeat.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH Export Repeat functionality.


/// @function WavesToTIFFDB
/// @brief Description of WavesToTIFFDB.
/// @details
/// Auto-generated documentation stub for function `WavesToTIFFDB`.
/// @param byte32] Parameter byte32].
/// @returns Variable Return value.


static Function WavesToTIFFDB([int byte32])
	// Export all traces selected in Data Browser
	byte32 = ParamIsDefault(byte32) ? 1 : byte32 // Use max 32 bits per pixel -- Default TRUE
	if(!strlen(GetBrowserSelection(0)))
		return 1
	endif
	string wname
	variable i = 0
	NewPath/Q/O/M="Select folder to export traces..." ATH_EXPORT_IMAGES_PATH__
	do
		wname = GetBrowserSelection(i)
		WAVE wRef = $wname
		if(!WaveExists(wRef))
			break
		elseif(WaveDims(wRef) == 1 || WaveDims(wRef) == 4)
			i++
			continue
		endif
		int bytesN = ATH_WaveOp#GetWaveType(wRef)
		if(byte32 && bytesN > 32)
			bytesN = 32
		endif
		if(WaveDims(wRef) == 2)
			ImageSave/DS=(bytesN)/P=ATH_EXPORT_IMAGES_PATH__ wRef as NameOfWave(wRef) // /T omitted so .itff
		endif
		if(WaveDims(wRef) == 3)
			ImageSave/S/DS=(bytesN)/P=ATH_EXPORT_IMAGES_PATH__ wRef as NameOfWave(wRef)
		endif		
		i++
	while(strlen(GetBrowserSelection(i)))
	KillPath/Z ATH_EXPORT_IMAGES_PATH__
	return 0
end

/// @function Wave3DToTIFFsDB
/// @brief Description of Wave3DToTIFFsDB.
/// @details
/// Auto-generated documentation stub for function `Wave3DToTIFFsDB`.
/// @param byte32] Parameter byte32].
/// @returns Variable Return value.

static Function Wave3DToTIFFsDB([int byte32])
	// Export all layers of a 3D wave to a folder
	byte32 = ParamIsDefault(byte32) ? 0 : byte32  // Use max 32 bits per pixel -- Default TRUE

	if(!strlen(GetBrowserSelection(0)))
		return 1
	endif
	string wname
	NewPath/Q/O/M="Select folder to export traces..." ATH_EXPORT_IMAGES_PATH__
	wname = GetBrowserSelection(0)
	WAVE wRef = $wname
	variable nLayers = DimSize(wRef, 2), i, bytesN
	if(!WaveExists(wRef) || !nLayers)
		return 1
	endif
	for(i = 0; i < nLayers; i++)		
		bytesN = ATH_WaveOp#GetWaveType(wRef)
		if(byte32 && bytesN > 32)
			bytesN = 32
		endif		
		MatrixOP/FREE layerFree = layer(wRef, i)
		ImageSave/DS=(bytesN)/P=ATH_EXPORT_IMAGES_PATH__ layerFree as (NameOfWave(wRef)+"_"+num2str(i)) // /T omitted so .itff
	endfor
	KillPath/Z ATH_EXPORT_IMAGES_PATH__
	return 0
end

/// @function TracesToGeneralTextDB
/// @brief Description of TracesToGeneralTextDB.
/// @details
/// Auto-generated documentation stub for function `TracesToGeneralTextDB`.
/// @returns Variable Return value.

static Function TracesToGeneralTextDB()
	// Export all traces selected in Data Browser

	if(!strlen(GetBrowserSelection(0)))
		return 1
	endif
	string wname
	variable i = 0
	NewPath/Q/O/M="Select folder to export traces..." ATH_EXPORT_TRACES_PATH__
	do
		wname = GetBrowserSelection(i)
		WAVE wRef = $wname
		if(!WaveExists(wRef))
			break
		elseif(WaveDims(wRef) != 1)
			i++
			continue
		endif
		Duplicate/FREE/O wRef, wavescaleFree
		wavescaleFree = x
		Save/G/M="\n"/P=ATH_EXPORT_TRACES_PATH__ wavescaleFree, wRef as NameOfWave(wRef)
		i++
	while(strlen(GetBrowserSelection(i)))
	KillPath/Z ATH_EXPORT_TRACES_PATH__
	return 0
end
