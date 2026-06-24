#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Num

/// @module ATH_Numeric
/// @brief Module ATH_Numeric.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH Numeric functionality.

/// @function NumSignDigits
/// @brief Round a number to a requested count of significant digits.
/// @details
/// Return the num with sigDigits significant digits NOTE: Six is the maximum numnbers of sigDigits the
/// function can handle.
/// @param num Numeric input value.
/// @param sigDigits Number of significant digits to retain.
/// @returns Num sign digits.
static Function NumSignDigits(variable num, variable sigDigits)
	/// Return the num with sigDigits significant digits
	/// NOTE: Six is the maximum numnbers of sigDigits 
	/// the function can handle.
    string str
    sprintf str, "%.*g", sigDigits, num
    return str2num(str)
End

/// @function IntegerQ
/// @brief Test whether integer.
/// @details
/// Check in a number is integer.
/// @param num Numeric input value.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function IntegerQ(variable num)
	/// Check in a number is integer
	if(num == trunc(num))
		return 1
	else
		return 0
	endif
End

/// @function WaveIsFloatQ
/// @brief Test whether wave is float.
/// @details
/// Returns true of wRef is 32 or 64 bit float wave.
/// @param wRef Input wave.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function WaveIsFloatQ(WAVE wRef)
	// Returns true of wRef is 32 or 64 bit float wave
	return ((WaveType(wRef) & 0x02) || (WaveType(wRef) & 0x04))
End

/// @function WaveIsFloat32Q
/// @brief Test whether wave is float32.
/// @details
/// Returns true of wRef is 32 bit float wave.
/// @param wRef Input wave.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function WaveIsFloat32Q(WAVE wRef)
	// Returns true of wRef is 32 bit float wave
	return WaveType(wRef) & 0x02 
End

/// @function WaveIsFloat64Q
/// @brief Test whether wave is float64.
/// @details
/// Returns true of wRef is 64 bit float wave.
/// @param wRef Input wave.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
static Function WaveIsFloat64Q(WAVE wRef)
	// Returns true of wRef is 64 bit float wave
	return WaveType(wRef) & 0x04 
End

/// @function NextPowerOfTwo
/// @brief Return the smallest power of two greater than or equal to a value.
/// @details
/// Return the first power of two after num.
/// @param num Numeric input value.
/// @returns Next power of two.
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

/// @function IsNumberInWaveRangeQ
/// @brief Test whether number in wave range.
/// @details
/// Returns 1 if n between min(w) & max(w) or 0 otherwise.
/// @param w Input wave.
/// @param n Numeric value to test or transform.
/// @returns Nonzero when the condition is satisfied; otherwise zero.
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

/// @function RunningMeanDifferenceZapNaN
/// @brief Calculate the mean adjacent-point difference after removing NaN values.
/// @details
/// Finds the mean value of differences for of elements (i+1) - i. dim, int are used when you want to pick up
/// a specific row, col or beam.
/// @param wRef Input wave.
/// @param dim (optional) Zero-based wave-dimension index.
/// @param rowN (optional) Zero-based row index.
/// @param colN (optional) Zero-based column index.
/// @returns The mean adjacent-point difference after removing NaN values.
static Function RunningMeanDifferenceZapNaN(WAVE wRef, [variable dim, variable rowN, variable colN])
	// Finds the mean value of differences for
	// of elements (i+1) - i.
	// dim, int are used when you want to pick up a specific row, col or beam
	switch(dim)
		case 0:
			MatrixOP/FREE w = row(wRef, rowN)
			break
		case 1:
			MatrixOP/FREE w = col(wRef, colN)
			break
		case 2:
			MatrixOP/FREE w = beam(wRef, rowN, colN)		
			break
		default:
			MatrixOP/FREE w = wRef // Do not change anything
			break
	endswitch
	
	MatrixOP/FREE wc= zapNaNs(w)
	variable npts = numpnts(wc)
	
	switch(npts)
		case 0:
			return 0
		case 1:
			return wc[0]
		case 2:
			return wc[1] - wc[0]
		default:
			Duplicate/FREE/R=[1,*] wc, wOffFirst // Remove first element
			Duplicate/FREE/R=[0,DimSize(wc,0)-2] wc, wOffLast // Remove last element
			MatrixOP/FREE diff = mean(wOffFirst-wOffLast)
			return diff[0]
	endswitch
End

/// @function WaveBeamMeanZapNaN
/// @brief Calculate a NaN-free mean, or mean reciprocal, along a selected wave beam.
/// @details
/// Finds the mean value of a beam along any dimension set recQ to non zero value to find mean of inverse
/// (reciprocals).
/// @param wRef Input wave.
/// @param dim (optional) Zero-based wave-dimension index.
/// @param rowN (optional) Zero-based row index.
/// @param colN (optional) Zero-based column index.
/// @param recQ (optional) If nonzero, average reciprocal values instead of the values themselves.
/// @returns The mean of the selected beam after removing NaNs, or the mean reciprocal when `recQ` is nonzero.
static Function WaveBeamMeanZapNaN(WAVE wRef, [variable dim, variable rowN, variable colN, int recQ])
	// Finds the mean value of a beam along any dimension
	// set recQ to non zero value to find mean of inverse (reciprocals)
	switch(dim)
		case 0:
			MatrixOP/FREE w = row(wRef, rowN)
			break
		case 1:
			MatrixOP/FREE w = col(wRef, colN)
			break
		case 2:
			MatrixOP/FREE w = beam(wRef, rowN, colN)		
			break
		default:
			MatrixOP/FREE w = wRef // Do not change anything
			break
	endswitch
	MatrixOP/FREE wc= zapNaNs(w)
	variable npts = numpnts(wc)
	switch(npts)
		case 0:
			return 0
		case 1:
			return wc[0]
		default:
			if(!recQ)
				MatrixOP/FREE meanW = mean(wc)
				return meanW[0]
			else
				MatrixOP/FREE invW = rec(wc)
				MatrixOP/FREE meanW = mean(invW)
				return meanW[0]
			endif
	endswitch
End
