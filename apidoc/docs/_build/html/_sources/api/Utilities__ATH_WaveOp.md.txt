# ATH_WaveOp

**Source file:** `Utilities/ATH_WaveOp.ipf`

Module ATH_WaveOp.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH WaveOp functionality.

```{contents}
:local:
:depth: 2
```

## `Make3DWaveUsingPattern`

**Signature**

```igorpro
Make3DWaveUsingPattern(string wname3dStr, string pattern)
```

Create a 3D wave by stacking waves whose names match a pattern.

Make a 3d wave named wname3d using the RegEx pattern. Give "*" to match all waves.

### Parameters

- `wname3dStr` *(String)*: Wname3d str.
- `pattern` *(String)*: Pattern used to select names or files.

### Returns

- **Variable**: Zero after completing the operation.


## `ConcatenateWavesInDataBrowserSelection`

**Signature**

```igorpro
ConcatenateWavesInDataBrowserSelection(string wname3dStr)
```

Concatenate waves in Data Browser selection.

Concatenate wave from data folder selection. Use it to stack 2D, 3D waves. Returns a string with the name
of the created wave, as wname3dStr.

### Parameters

- `wname3dStr` *(String)*: Wname3d str.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `WaveListStrToWaveRef`

**Signature**

```igorpro
WaveListStrToWaveRef(string wavelistStr, [int isFree])
```

Convert a wave-name list into a wave-reference wave.

Gets a wavelist and retuns a Wave reference Wave. Wave is free is isFree is set.

### Parameters

- `wavelistStr` *(String)*: Wave used by the operation.
- `isFree` *(Integer, optional)*: If nonzero, create a free wave rather than a data-folder wave.

### Returns

- **Wave**: Reference to the result wave; a null reference indicates failure where supported.


## `UnpackLayersToSources`

**Signature**

```igorpro
UnpackLayersToSources(WAVE wRef)
```

Unpack layers to sources.

Unpack layers to destination waves as grabbed from wave note.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `MakeSquare3DWave`

**Signature**

```igorpro
MakeSquare3DWave(WAVE w3d, [variable size])
```

Create square 3D wave.

Creates a 3d waves with the same rows, cols by interpolation of w3d. The wave scaling using the interval
/I.

### Parameters

- `w3d` *(Wave)*: Input 3D wave or image stack.
- `size` *(Variable, optional)*: Size.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `AverageImageStack`

**Signature**

```igorpro
AverageImageStack(WAVE wRef, [string outWaveStr])
```

Average image stack.

Average a 3d wave along z.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `outWaveStr` *(String, optional)*: Wave used by the operation.

### Returns

- **Wave**: Reference to the result wave; a null reference indicates failure where supported.


## `WavePartition`

**Signature**

```igorpro
WavePartition(WAVE wRef, string partitionNameStr, variable aX, variable zX, variable aY, variable zY, [int evenNum, int square, int WaveFREE])
```

Partition a wave into regularly sized subwaves.

Each output wave contains points `aX` through `zX`; successive partitions advance by `partitionIncrement`
points.

### Parameters

- `wRef` *(Wave)*: Source wave to partition.
- `partitionNameStr` *(String)*: Base name for generated partition waves.
- `aX` *(Variable)*: First source index in the x dimension.
- `zX` *(Variable)*: Last source index in the x dimension.
- `aY` *(Variable)*: First source index in the y dimension.
- `zY` *(Variable)*: Last source index in the y dimension.
- `evenNum` *(Integer, optional)*: If nonzero, force an even number of partitions.
- `square` *(Integer, optional)*: If nonzero, use equal x and y partition extents.
- `WaveFREE` *(Integer, optional)*: destination wave used for each partition.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `ZapNaNAndInfWithValue`

**Signature**

```igorpro
ZapNaNAndInfWithValue(WAVE waveRef, variable val)
```

Replace NaN and infinite wave values with a specified value.

### Parameters

- `waveRef` *(Wave)*: used by the operation.
- `val` *(Variable)*: Scalar value to assign or compare.

### Returns

- **Variable**: Zero after completing the operation.


## `NormaliseWaveWithWave`

**Signature**

```igorpro
NormaliseWaveWithWave(WAVE wRef1, WAVE wRef2)
```

Normalize wave with wave.

Normalise a wave with another consistency check static Function NormaliseWaveToUnitRange(WAVE waveRef).

### Parameters

- `wRef1` *(Wave)*: First wave to modify in place.
- `wRef2` *(Wave)*: Second input wave.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `GetScalesP`

**Signature**

```igorpro
GetScalesP(WAVE wRef)
```

Return wave dimension offsets and point intervals.

Returns the offset and point interval for the first three dimensions of the input wave.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Multiple values**: The x, y, and z dimension offsets followed by their point intervals.


## `SetScalesP`

**Signature**

```igorpro
SetScalesP(WAVE wRef, variable x0, variable y0, variable z0, variable dx, variable dy, variable dz)
```

Set dimension offsets and intervals for a wave.

Set scale of waves per point variable x0, y0, z0, dx, dy, dz [x0, y0, z0, dx, dy, dz] =
ATH_GetScalesP(wRef).

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `x0` *(Variable)*: First x coordinate or range bound.
- `y0` *(Variable)*: First y coordinate or range bound.
- `z0` *(Variable)*: First layer coordinate or range bound.
- `dx` *(Variable)*: Sampling interval along x.
- `dy` *(Variable)*: Sampling interval along y.
- `dz` *(Variable)*: Sampling interval along z.

### Returns

- **Variable**: Zero after completing the operation.


## `MakeWaveFromROI`

**Signature**

```igorpro
MakeWaveFromROI(WAVE wRef)
```

Create wave from ROI.

Extracts the ROI from wRef using the saved ROI coordinates in the database. Works with 2D and 3D waves.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Zero after completing the operation.


## `SetWaveOffsetZero`

**Signature**

```igorpro
SetWaveOffsetZero(WAVE wRef, [int dim])
```

Set wave offset zero.

Zero the offset for dimension dim.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `dim` *(Integer, optional)*: Zero-based wave-dimension index.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `AllWaves2DQ`

**Signature**

```igorpro
AllWaves2DQ(WAVE/WAVE wRefw)
```

Test whether all waves 2D.

Check whether all images have the same rows, cols.

### Parameters

- `wRefw` *(Wave/WAVE)*: Reference wave supplying values or scaling.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `AllImagesEqualDimensionsQ`

**Signature**

```igorpro
AllImagesEqualDimensionsQ(WAVE/WAVE wRefw)
```

Test whether all images equal dimensions.

Check whether all images have the same rows, cols.

### Parameters

- `wRefw` *(Wave/WAVE)*: Reference wave supplying values or scaling.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `ImagesDimensionsEqualQ`

**Signature**

```igorpro
ImagesDimensionsEqualQ(WAVE w1, WAVE w2)
```

Test whether wave dimensions equal.

Return 1 if waves have the same num of elements in all dims. Works for any wave.

### Parameters

- `w1` *(Wave)*
- `w2` *(Wave)*

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `WaveDimensionsEqualQ`

**Signature**

```igorpro
WaveDimensionsEqualQ(WAVE w1, WAVE w2)
```

Test whether wave dimensions equal.

Return 1 if waves have the same num of elements in all dims. Works for any wave.

### Parameters

- `w1` *(Wave)*: First input wave.
- `w2` *(Wave)*: Second input wave.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `AllWavesEqualDimensionsQ`

**Signature**

```igorpro
AllWavesEqualDimensionsQ(WAVE/WAVE wRefw)
```

Test whether wave dimensions equal.

Return 1 if waves have the same num of elements in all dims. Works for any wave.

### Parameters

- `wRefw` *(Wave/WAVE)*

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `MatchWaveTypes`

**Signature**

```igorpro
MatchWaveTypes(WAVE wRef, WAVE wDest)
```

Match wave types.

Change WaveType of wDest to the one of wRef.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `wDest` *(Wave)*: Destination wave to populate.

### Returns

- **Variable**: Zero after completing the operation.


## `WaveCasting`

**Signature**

```igorpro
WaveCasting(WAVE wRef, int wType)
```

Convert a numeric wave to a requested Igor wave type.

Change to WaveType.

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `wType` *(Integer)*: Igor numeric wave-type code.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `LastDimVal`

**Signature**

```igorpro
LastDimVal(WAVE w, int dim)
```

Return the scaled coordinate of a dimension's final point.

Return the last value of dimension dim.

### Parameters

- `w` *(Wave)*: Input wave.
- `dim` *(Integer)*: Zero-based wave-dimension index.

### Returns

- **Variable**: The scaled coordinate of the final point along the selected dimension.


## `SizeOfWave`

**Signature**

```igorpro
SizeOfWave(wv)
```

Size of wave.

### Parameters

- `wv` *(Variable)*: Wave whose memory footprint is calculated.

### Returns

- **Variable**: Size of wave.


## `SumLateralWaveDims`

**Signature**

```igorpro
SumLateralWaveDims(WAVE w)
```

Sum lateral dimensions to reduce a 2D or 3D wave to a 1D profile.

Sum cols (assumed energy axis) in 2D or sum rows and cols in 3D waves to make a 1D wave.

### Parameters

- `w` *(Wave)*: Input wave.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `GetWaveType`

**Signature**

```igorpro
GetWaveType(WAVE wRef)
```

Return the number of bytes per wave element.

Return the number of bytes per element of wave wRef.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: The wave type.


## `RemoveLineFromWave1D`

**Signature**

```igorpro
RemoveLineFromWave1D(WAVE wRef, [variable x0, variable x1])
```

Remove line from wave 1d.

Remove a line from a 1D wave. Line is defined from points x0 and x1. Here scaling is taken into account.
The function is structured to give.

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `x0` *(Variable, optional)*: First x coordinate or range bound.
- `x1` *(Variable, optional)*: Second x coordinate or range bound.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `RemoveZLineWave3D`

**Signature**

```igorpro
RemoveZLineWave3D(Wave wRef, [variable z0, variable z1])
```

Remove z line wave 3D.

Remove a line defined by z0, z1 for every wRef beam we use the wave scaling along z, but it's not needed.
Unscaled wave will give the same results.

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `z0` *(Variable, optional)*: First layer coordinate or range bound.
- `z1` *(Variable, optional)*: Second layer coordinate or range bound.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `GetWaveMinPos`

**Signature**

```igorpro
GetWaveMinPos(WAVE wRef)
```

Return the scaled position of a wave's minimum value.

Return the position of the maximun value of wave.

### Parameters

- `wRef` *(Wave)*: to modify in place.

### Returns

- **Variable**: The wave min pos.


## `GetWaveMaxPos`

**Signature**

```igorpro
GetWaveMaxPos(WAVE wRef)
```

Return the scaled position of a wave's maximum value.

Return the position of the maximun value of wave.

### Parameters

- `wRef` *(Wave)*: to modify in place.

### Returns

- **Variable**: The wave max pos.


## `AverageEvenOddLayers`

**Signature**

```igorpro
AverageEvenOddLayers(WAVE wRef, [variable offset])
```

Average even odd layers.

Not absolute even/odd referenence when offset!=0.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `offset` *(Variable, optional)*: Offset.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `AverageSplitStack`

**Signature**

```igorpro
AverageSplitStack(WAVE wRef)
```

Split an image stack into two halves and average each half.

Creates sibling waves with suffixes `_half1` and `_half2`; an unmatched first layer is skipped for odd-sized stacks.

### Parameters

- `wRef` *(Wave)*: Input 3D image stack.

### Returns

- **Variable**: Zero on success; one if the input is not a multi-layer 3D wave.


## `AverageRandomStackSample`

**Signature**

```igorpro
AverageRandomStackSample(WAVE wRef, variable sampleN)
```

Average a random subset of layers from an image stack.

Selects layers without replacement, records their indices in the result note, and preserves the input scaling.

### Parameters

- `wRef` *(Wave)*: Input 3D image stack.
- `sampleN` *(Variable)*: Number of layers to sample; must not exceed 75 percent of the stack.

### Returns

- **Variable**: Zero on success; one if the input has no layers or the requested sample is too large.
