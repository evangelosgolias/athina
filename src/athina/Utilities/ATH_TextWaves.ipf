#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_TWave

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

/// @module ATH_TextWaves
/// @brief Module ATH_TextWaves.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH TextWaves functionality.


/// @function TWaveRemoveEntriesFromPatters
/// @brief Remove text-wave entries whose values match any supplied pattern.
/// @details
/// Remove entries from textW that start with pathbase. Optionally we can remove the same entries from
/// another wave otherW. We use this in ATH_LaunchDeleteBigWaves.
/// @param textW Input text wave.
/// @param patternStr Text containing the pattern str.
/// @param otherW (optional) Second text wave used for comparison or concatenation.
/// @returns Zero after completing the operation.
static Function TWaveRemoveEntriesFromPatters(WAVE/T textW, string patternStr, [WAVE otherW])
	// Remove entries from textW that start with pathbase
	// Optionally we can remove the same entries from another wave otherW
	// We use this in ATH_LaunchDeleteBigWaves
	variable otherWQ = ParamIsDefault(otherW) ? 0 : 1
	variable numpts = DimSize(textW, 0), i
	for(i = numpts - 1; i > 0; i--)
		if(Stringmatch(textW[i], patternStr))
			DeletePoints i, 1, textW
			if(otherWQ)
				DeletePoints i, 1, otherW
			endif
		endif
	endfor
	return 0
End

/// @function DeleteWavesInTextWave
/// @brief Remove waves in text wave.
/// @details
/// Delete big waves listed in textW.
/// @param textW Input text wave.
/// @returns Zero after completing the operation.
static Function DeleteWavesInTextWave(WAVE/T textW)
	// Delete big waves listed in textW
	variable nw = DimSize(textW, 0), i
	for(i = 0; i < nw; i++)			
		KillWaves/Z $textW[i]
	endfor
	return 0
End

/// @function TextWaveToString
/// @brief Text wave to string.
/// @details
/// Make a string from a textwave.
/// @param textW Input text wave.
/// @param sep (optional) Delimiter used between list items.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S TextWaveToString(WAVE/T textW, [string sep])
	// Make a string from a textwave
	// If you want to return a list, just set strsep=;
	sep = SelectString(ParamIsDefault(sep) ? 0: 1, ";", sep)
	
	string concStr = ""
	variable nitems = DimSize(textW, 0), i
	
	for(i = 0; i < nitems; i++)
		concStr += textW[i] + sep
	endfor
	return concStr
End

/// @function StringListToTextWave
/// @brief String list to text wave.
/// @param stringListStr Text containing the string list str.
/// @param sep Delimiter used between list items.
/// @returns Reference to the result wave; a null reference indicates failure where supported.
static Function/WAVE StringListToTextWave(string stringListStr, string sep)

	variable numElem = ItemsInList(stringListStr, sep)
	if(!numElem)
		return $""
	else
		return ListToTextWave(stringListStr, sep)		
	endif
End

// Dev -- need testing

/// @function TWaveRemoveEntriesFromStringList
/// @brief Remove text-wave entries listed in a delimited string.
/// @details
/// Remove entries from textW in stringListStr. Optionally we can remove the same entries from another wave
/// otherW. We use this in ATH_LaunchDeleteBigWavesDisplayed.
/// @param textW Input text wave.
/// @param stringListStr Text containing the string list str.
/// @param otherW (optional) Second text wave used for comparison or concatenation.
/// @returns Zero after completing the operation.
static Function TWaveRemoveEntriesFromStringList(WAVE/T textW, string stringListStr, [WAVE otherW])
	// Remove entries from textW in stringListStr
	// Optionally we can remove the same entries from another wave otherW
	// We use this in ATH_LaunchDeleteBigWavesDisplayed
	
	variable otherWQ = ParamIsDefault(otherW) ? 0 : 1
	variable numpts = DimSize(textW, 0), i
	for(i = numpts - 1; i > 0; i--)
		if(1)
			DeletePoints i, 1, textW
			if(otherWQ)
				DeletePoints i, 1, otherW
			endif
		endif
	endfor
	return 0
End
