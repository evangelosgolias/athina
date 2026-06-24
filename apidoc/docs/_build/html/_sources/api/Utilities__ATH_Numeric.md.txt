# ATH_Numeric

**Source file:** `Utilities/ATH_Numeric.ipf`

Module ATH_Numeric.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Numeric functionality.

```{contents}
:local:
:depth: 2
```

## `NumSignDigits`

**Signature**

```igorpro
NumSignDigits(variable num, variable sigDigits)
```

Round a number to a requested count of significant digits.

Return the num with sigDigits significant digits NOTE: Six is the maximum numnbers of sigDigits the
function can handle.

### Parameters

- `num` *(Variable)*: Numeric input value.
- `sigDigits` *(Variable)*: Number of significant digits to retain.

### Returns

- **Variable**: Num sign digits.


## `IntegerQ`

**Signature**

```igorpro
IntegerQ(variable num)
```

Test whether integer.

Check in a number is integer.

### Parameters

- `num` *(Variable)*: Numeric input value.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `WaveIsFloatQ`

**Signature**

```igorpro
WaveIsFloatQ(WAVE wRef)
```

Test whether wave is float.

Returns true of wRef is 32 or 64 bit float wave.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `WaveIsFloat32Q`

**Signature**

```igorpro
WaveIsFloat32Q(WAVE wRef)
```

Test whether wave is float32.

Returns true of wRef is 32 bit float wave.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `WaveIsFloat64Q`

**Signature**

```igorpro
WaveIsFloat64Q(WAVE wRef)
```

Test whether wave is float64.

Returns true of wRef is 64 bit float wave.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `NextPowerOfTwo`

**Signature**

```igorpro
NextPowerOfTwo(variable num)
```

Return the smallest power of two greater than or equal to a value.

Return the first power of two after num.

### Parameters

- `num` *(Variable)*: Numeric input value.

### Returns

- **Variable**: Next power of two.


## `IsNumberInWaveRangeQ`

**Signature**

```igorpro
IsNumberInWaveRangeQ(WAVE w, variable n)
```

Test whether number in wave range.

Returns 1 if n between min(w) & max(w) or 0 otherwise.

### Parameters

- `w` *(Wave)*: Input wave.
- `n` *(Variable)*: Numeric value to test or transform.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `RunningMeanDifferenceZapNaN`

**Signature**

```igorpro
RunningMeanDifferenceZapNaN(WAVE wRef, [variable dim, variable rowN, variable colN])
```

Calculate the mean adjacent-point difference after removing NaN values.

Finds the mean value of differences for of elements (i+1) - i. dim, int are used when you want to pick up
a specific row, col or beam.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `dim` *(Variable, optional)*: Zero-based wave-dimension index.
- `rowN` *(Variable, optional)*: Zero-based row index.
- `colN` *(Variable, optional)*: Zero-based column index.

### Returns

- **Variable**: The mean adjacent-point difference after removing NaN values.


## `WaveBeamMeanZapNaN`

**Signature**

```igorpro
WaveBeamMeanZapNaN(WAVE wRef, [variable dim, variable rowN, variable colN, int recQ])
```

Calculate a NaN-free mean, or mean reciprocal, along a selected wave beam.

Finds the mean value of a beam along any dimension set recQ to non zero value to find mean of inverse
(reciprocals).

### Parameters

- `wRef` *(Wave)*: Input wave.
- `dim` *(Variable, optional)*: Zero-based wave-dimension index.
- `rowN` *(Variable, optional)*: Zero-based row index.
- `colN` *(Variable, optional)*: Zero-based column index.
- `recQ` *(Integer, optional)*: If nonzero, average reciprocal values instead of the values themselves.

### Returns

- **Variable**: The mean of the selected beam after removing NaNs, or the mean reciprocal when `recQ` is nonzero.
