#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_TWave

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

static Function DeleteWavesInTextWave(WAVE/T textW)
	// Delete big waves listed in textW
	variable nw = DimSize(textW, 0), i
	for(i = 0; i < nw; i++)			
		KillWaves/Z $textW[i]
	endfor
	return 0
End

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

static Function/WAVE StringListToTextWave(string stringListStr, string sep)

	variable numElem = ItemsInList(stringListStr, sep)
	if(!numElem)
		return $""
	else
		return ListToTextWave(stringListStr, sep)		
	endif
End

// Dev -- need testing
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