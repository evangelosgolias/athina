#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Num

static Function NumSignDigits(variable num, variable sigDigits)
	/// Return the num with sigDigits significant digits
	/// NOTE: Six is the maximum numnbers of sigDigits 
	/// the function can handle.
    string str
    sprintf str, "%.*g", sigDigits, num
    return str2num(str)
End

static Function IntegerQ(variable num)
	/// Check in a number is integer
	if(num == trunc(num))
		return 1
	else
		return 0
	endif
End

static Function IsFloatQ(WAVE wRef)
	// Returns true of wRef is 32 or 64 bit float wave
	return ((WaveType(wRef) & 0x02) || (WaveType(wRef) & 0x04))
End

static Function IsFloat32Q(WAVE wRef)
	// Returns true of wRef is 32 bit float wave
	return WaveType(wRef) & 0x02 
End

static Function IsFloat64Q(WAVE wRef)
	// Returns true of wRef is 64 bit float wave
	return WaveType(wRef) & 0x04 
End

static Function NextPowerOfTwo(variable num)
	 /// Return the first power of two after num.
	 /// @param num double 
	variable bufferVar
	variable result = 1
	do
		result *= 2
	while (result < num)
	return result
End

static Function IsNumberInWaveRangeQ(WAVE w, variable n)
	// Returns 1 if n between min(w) & max(w)
	// or 0 otherwise
	variable minV, maxV
	[minV, maxV] = WaveMinAndMax(w)
	
	if(n < minV || n > maxV)
		return 0
	endif
	return 1
End