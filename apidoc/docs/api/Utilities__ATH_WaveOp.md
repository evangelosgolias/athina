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

Description of Make3DWaveUsingPattern.

Auto-generated documentation stub for function `Make3DWaveUsingPattern`.

### Parameters

- `wname3dStr` *(Parameter)*: wname3dStr.
- `pattern` *(Parameter)*: pattern.

### Returns

- **Variable**: Return value.


## `ConcatenateWavesInDataBrowserSelection`

**Signature**

```igorpro
ConcatenateWavesInDataBrowserSelection(string wname3dStr, [variable makeInSourceDFR, variable autoPath])
```

Description of ConcatenateWavesInDataBrowserSelection.

Auto-generated documentation stub for function `ConcatenateWavesInDataBrowserSelection`.

### Parameters

- `wname3dStr` *(Parameter)*: wname3dStr.
- `makeInSourceDFR` *(Parameter)*: makeInSourceDFR.
- `autoPath]` *(Parameter)*: autoPath].

### Returns

- **String**: Return value.


## `WaveListStrToWaveRef`

**Signature**

```igorpro
WaveListStrToWaveRef(string wavelistStr, [int isFree])
```

Description of WaveListStrToWaveRef.

Auto-generated documentation stub for function `WaveListStrToWaveRef`.

### Parameters

- `wavelistStr` *(Parameter)*: wavelistStr.
- `isFree]` *(Parameter)*: isFree].

### Returns

- **Wave**: Return value.


## `UnpackLayersToSources`

**Signature**

```igorpro
UnpackLayersToSources(WAVE wRef)
```

Description of UnpackLayersToSources.

Auto-generated documentation stub for function `UnpackLayersToSources`.

### Parameters

- `wRef` *(Parameter)*: wRef.

### Returns

- **Variable**: Return value.


## `MakeSquare3DWave`

**Signature**

```igorpro
MakeSquare3DWave(WAVE w3d, [variable size])
```

Description of MakeSquare3DWave.

Auto-generated documentation stub for function `MakeSquare3DWave`.

### Parameters

- `w3d` *(Parameter)*: w3d.
- `size]` *(Parameter)*: size].

### Returns

- **Variable**: Return value.


## `AverageImageStack`

**Signature**

```igorpro
AverageImageStack(WAVE wRef, [string outWaveStr])
```

Description of AverageImageStack.

Auto-generated documentation stub for function `AverageImageStack`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `outWaveStr]` *(Parameter)*: outWaveStr].

### Returns

- **Wave**: Return value.


## `ZapNaNAndInfWithValue`

**Signature**

```igorpro
ZapNaNAndInfWithValue(WAVE waveRef, variable val)
```

Description of ZapNaNAndInfWithValue.

Auto-generated documentation stub for function `ZapNaNAndInfWithValue`.

### Parameters

- `waveRef` *(Parameter)*: waveRef.
- `val` *(Parameter)*: val.

### Returns

- **Variable**: Return value.


## `NormaliseWaveWithWave`

**Signature**

```igorpro
NormaliseWaveWithWave(WAVE wRef1, WAVE wRef2)
```

Description of NormaliseWaveWithWave.

Auto-generated documentation stub for function `NormaliseWaveWithWave`.

### Parameters

- `wRef1` *(Parameter)*: wRef1.
- `wRef2` *(Parameter)*: wRef2.

### Returns

- **Variable**: Return value.


## `SetScalesP`

**Signature**

```igorpro
SetScalesP(WAVE wRef, variable x0, variable y0, variable z0, variable dx, variable dy, variable dz)
```

Description of SetScalesP.

Auto-generated documentation stub for function `SetScalesP`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `x0` *(Parameter)*: x0.
- `y0` *(Parameter)*: y0.
- `z0` *(Parameter)*: z0.
- `dx` *(Parameter)*: dx.
- `dy` *(Parameter)*: dy.
- `dz` *(Parameter)*: dz.

### Returns

- **Variable**: Return value.


## `MakeWaveFromROI`

**Signature**

```igorpro
MakeWaveFromROI(WAVE wRef)
```

Description of MakeWaveFromROI.

Auto-generated documentation stub for function `MakeWaveFromROI`.

### Parameters

- `wRef` *(Parameter)*: wRef.

### Returns

- **Variable**: Return value.


## `SetWaveOffsetZero`

**Signature**

```igorpro
SetWaveOffsetZero(WAVE wRef, [int dim])
```

Description of SetWaveOffsetZero.

Auto-generated documentation stub for function `SetWaveOffsetZero`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `dim]` *(Parameter)*: dim].

### Returns

- **Variable**: Return value.


## `Wave2DDimensionsEqualQ`

**Signature**

```igorpro
Wave2DDimensionsEqualQ(WAVE w1, WAVE w2)
```

Description of Wave2DDimensionsEqualQ.

Auto-generated documentation stub for function `Wave2DDimensionsEqualQ`.

### Parameters

- `w1` *(Parameter)*: w1.
- `w2` *(Parameter)*: w2.

### Returns

- **Variable**: Return value.


## `AllImagesEqualDimensionsQ`

**Signature**

```igorpro
AllImagesEqualDimensionsQ(WAVE/WAVE wRefw)
```

Description of AllImagesEqualDimensionsQ.

Auto-generated documentation stub for function `AllImagesEqualDimensionsQ`.

### Parameters

- `wRefw` *(Parameter)*: wRefw.

### Returns

- **Variable**: Return value.


## `WaveDimensionsEqualQ`

**Signature**

```igorpro
WaveDimensionsEqualQ(WAVE w1, WAVE w2)
```

Description of WaveDimensionsEqualQ.

Auto-generated documentation stub for function `WaveDimensionsEqualQ`.

### Parameters

- `w1` *(Parameter)*: w1.
- `w2` *(Parameter)*: w2.

### Returns

- **Variable**: Return value.


## `MatchWaveTypes`

**Signature**

```igorpro
MatchWaveTypes(WAVE wRef, WAVE wDest)
```

Description of MatchWaveTypes.

Auto-generated documentation stub for function `MatchWaveTypes`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `wDest` *(Parameter)*: wDest.

### Returns

- **Variable**: Return value.


## `WaveCasting`

**Signature**

```igorpro
WaveCasting(WAVE wRef, int wType)
```

Description of WaveCasting.

Auto-generated documentation stub for function `WaveCasting`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `wType` *(Parameter)*: wType.

### Returns

- **Variable**: Return value.


## `LastDimVal`

**Signature**

```igorpro
LastDimVal(WAVE w, int dim)
```

Description of LastDimVal.

Auto-generated documentation stub for function `LastDimVal`.

### Parameters

- `w` *(Parameter)*: w.
- `dim` *(Parameter)*: dim.

### Returns

- **Variable**: Return value.


## `SizeOfWave`

**Signature**

```igorpro
SizeOfWave(wv)
```

Description of SizeOfWave.

Auto-generated documentation stub for function `SizeOfWave`.

### Parameters

- `wv` *(Parameter)*: wv.

### Returns

- **Variable**: Return value.


## `SumLateralWaveDims`

**Signature**

```igorpro
SumLateralWaveDims(WAVE w)
```

Description of SumLateralWaveDims.

Auto-generated documentation stub for function `SumLateralWaveDims`.

### Parameters

- `w` *(Parameter)*: w.

### Returns

- **Variable**: Return value.


## `GetWaveType`

**Signature**

```igorpro
GetWaveType(WAVE wRef)
```

Description of GetWaveType.

Auto-generated documentation stub for function `GetWaveType`.

### Parameters

- `wRef` *(Parameter)*: wRef.

### Returns

- **Variable**: Return value.


## `RemoveLineFromWave1D`

**Signature**

```igorpro
RemoveLineFromWave1D(WAVE wRef, [variable x0, variable x1])
```

Description of RemoveLineFromWave1D.

Auto-generated documentation stub for function `RemoveLineFromWave1D`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `x0` *(Parameter)*: x0.
- `x1]` *(Parameter)*: x1].

### Returns

- **Variable**: Return value.


## `RemoveZLineWave3D`

**Signature**

```igorpro
RemoveZLineWave3D(Wave wRef, [variable z0, variable z1])
```

Description of RemoveZLineWave3D.

Auto-generated documentation stub for function `RemoveZLineWave3D`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `z0` *(Parameter)*: z0.
- `z1]` *(Parameter)*: z1].

### Returns

- **Variable**: Return value.


## `GetWaveMinPos`

**Signature**

```igorpro
GetWaveMinPos(WAVE wRef)
```

Description of GetWaveMinPos.

Auto-generated documentation stub for function `GetWaveMinPos`.

### Parameters

- `wRef` *(Parameter)*: wRef.

### Returns

- **Variable**: Return value.


## `GetWaveMaxPos`

**Signature**

```igorpro
GetWaveMaxPos(WAVE wRef)
```

Description of GetWaveMaxPos.

Auto-generated documentation stub for function `GetWaveMaxPos`.

### Parameters

- `wRef` *(Parameter)*: wRef.

### Returns

- **Variable**: Return value.
