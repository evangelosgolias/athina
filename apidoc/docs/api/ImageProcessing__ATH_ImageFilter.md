# ATH_ImageFilter

**Source file:** `ImageProcessing/ATH_ImageFilter.ipf`

Module ATH_ImageFilter.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH ImageFilter functionality.

```{contents}
:local:
:depth: 2
```

## `ThresholdImageRangeToMask`

**Signature**

```igorpro
ThresholdImageRangeToMask([string grfName, variable minV, variable maxV, int complexM])
```

Create a mask selecting image values inside a threshold range.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.
- `minV` *(Variable, optional)*: Lower inclusive threshold.
- `maxV` *(Variable, optional)*: Upper inclusive threshold.
- `complexM` *(Integer, optional)*: Complex-wave component selected for thresholding.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `iFFTImgFilter`

**Signature**

```igorpro
iFFTImgFilter(WAVE wRef)
```

Create the interactive FFT image-filtering interface.

Note wRef_fft, "FFT " + GetWavesDataFolder(wRef,2). Set globals. End of globals.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Zero after completing the operation.


## `iImgFilterHookFunction`

**Signature**

```igorpro
iImgFilterHookFunction(STRUCT WMWinHookStruct &s)
```

Handle graph events for the interactive image filter.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `iImgFilterButton`

**Signature**

```igorpro
iImgFilterButton(STRUCT WMButtonAction &ba)
```

Apply or reset the interactive image filter from its button controls.

Creates a separate result wave, leaving the input wave available to the caller.

### Parameters

- `ba` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `iImgFilterSetGValues`

**Signature**

```igorpro
iImgFilterSetGValues(STRUCT WMSetVariableAction &sva)
```

Update the interactive filter's global parameter values.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sva` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.
