# ATH_ImageAlign

**Source file:** `ImageProcessing/ATH_ImageAlign.ipf`

Module ATH_ImageAlign.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH ImageAlign functionality.

```{contents}
:local:
:depth: 2
```

## `LinearDriftStackABCursors`

**Signature**

```igorpro
LinearDriftStackABCursors(WAVE w3d, WAVE wx, WAVE wy, [int intPx])
```

Correct linear drift through a stack using the displacement between cursors A and B.

Linear drift correction w3d using wx and wy displacements. Drifts for ImageInterpolate should be in
pixels. Restore scale here.

### Parameters

- `w3d` *(Wave)*: Input 3D wave or image stack.
- `wx` *(Wave)*: containing x drift or displacement values.
- `wy` *(Wave)*: containing y drift or displacement values.
- `intPx` *(Integer, optional)*: If nonzero, round calculated displacements to integer pixels.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `LinearDriftPlanesABCursors`

**Signature**

```igorpro
LinearDriftPlanesABCursors(WAVE w3d, WAVE wx, WAVE wy, [variable startL, variable endL, int intPx])
```

Correct linear drift over selected stack layers using cursors A and B.

Linear drift correction w3d using wx and wy displacements WAVE wx - x coordinates WAVE wy - y
coordinates.

### Parameters

- `w3d` *(Wave)*: Input 3D wave or image stack.
- `wx` *(Wave)*: containing x drift or displacement values.
- `wy` *(Wave)*: containing y drift or displacement values.
- `startL` *(Variable, optional)*: Lower or starting start l.
- `endL` *(Variable, optional)*: Upper or ending end l.
- `intPx` *(Integer, optional)*: If nonzero, round calculated displacements to integer pixels.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `MultiThreadCorrelationDriftCorrection`

**Signature**

```igorpro
MultiThreadCorrelationDriftCorrection(WAVE w3D, WAVE w3DPart, variable layerN, [variable saveDrift, variable subpixel, variable method])
```

Measure stack drift by multithreaded image correlation.

Uses either normalized real-space correlation or phase correlation against a reference layer, then replaces
the input stack with the aligned layers. Saved drift values are expressed in pixels.

### Parameters

- `w3D` *(Wave)*: Input 3D image stack.
- `w3DPart` *(Wave)*: Preprocessed or cropped stack used to estimate alignment.
- `layerN` *(Variable)*: Zero-based image-stack layer index.
- `saveDrift` *(Variable, optional)*: If nonzero, save the calculated per-layer drift parameters.
- `subpixel` *(Variable, optional)*: If nonzero, refine correlation peaks with a two-dimensional Gaussian fit.
- `method` *(Variable, optional)*: Algorithm or processing method.

### Returns

- **Variable**: Zero after replacing the source stack with the aligned result.


## `DriftCorrelationPartition_Worker`

**Signature**

```igorpro
DriftCorrelationPartition_Worker(WAVE w3D, WAVE w3DPart, WAVE w3DPartRef, variable refP, variable refQ, variable plane, WAVE/Z wDC, [variable subpixel])
```

Register one stack layer by normalized cross-correlation.

### Parameters

- `w3D` *(Wave)*: Input 3D image stack.
- `w3DPart` *(Wave)*: Preprocessed or cropped stack used to estimate alignment.
- `w3DPartRef` *(Wave)*: Reference image used for correlation or registration.
- `refP` *(Variable)*: Reference-row location of the correlation maximum.
- `refQ` *(Variable)*: Reference-column location of the correlation maximum.
- `plane` *(Variable)*: Zero-based image-stack plane index.
- `wDC` *(Wave/Z)*: that receives or supplies per-layer drift parameters.
- `subpixel` *(Variable, optional)*: If nonzero, refine correlation peaks with a two-dimensional Gaussian fit.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `DriftPhaseCorrelationPartition_Worker`

**Signature**

```igorpro
DriftPhaseCorrelationPartition_Worker(WAVE w3D, WAVE w3DPart, WAVE fftRef, variable plane, WAVE/Z wDC, [variable subpixel])
```

Register one stack layer by phase correlation.

### Parameters

- `w3D` *(Wave)*: Input 3D image stack.
- `w3DPart` *(Wave)*: Preprocessed or cropped stack used to estimate alignment.
- `fftRef` *(Wave)*: Phase spectrum of the reference image.
- `plane` *(Variable)*: Zero-based image-stack plane index.
- `wDC` *(Wave/Z)*: that receives or supplies per-layer drift parameters.
- `subpixel` *(Variable, optional)*: If nonzero, refine correlation peaks with a two-dimensional Gaussian fit.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `MultiThreadRegistrationDriftCorrection`

**Signature**

```igorpro
MultiThreadRegistrationDriftCorrection(WAVE w3D, WAVE w3DPart, variable layerN, [variable RotZ, variable saveDrift])
```

Measure stack drift using multithreaded image registration.

Registers each normalized layer to the selected reference layer and replaces the input stack with the
aligned result.

### Parameters

- `w3D` *(Wave)*: Input 3D image stack.
- `w3DPart` *(Wave)*: Preprocessed or cropped stack used to estimate alignment.
- `layerN` *(Variable)*: Zero-based image-stack layer index.
- `RotZ` *(Variable, optional)*: If nonzero, allow rotation about the z axis.
- `saveDrift` *(Variable, optional)*: If nonzero, save the calculated per-layer drift parameters.

### Returns

- **Variable**: Zero after replacing the source stack with the registered result.


## `DriftRegistrationPartition_Worker`

**Signature**

```igorpro
DriftRegistrationPartition_Worker(WAVE w3D, WAVE w3DPart, WAVE w3DPartRef, WAVE wROIMask, variable plane, [variable RotZ, WAVE/Z wDC])
```

Register one stack layer and optionally record its transformation parameters.

### Parameters

- `w3D` *(Wave)*: Input 3D image stack.
- `w3DPart` *(Wave)*: Preprocessed or cropped stack used to estimate alignment.
- `w3DPartRef` *(Wave)*: Reference image used for correlation or registration.
- `wROIMask` *(Wave)*: Mask defining pixels used by ImageRegistration.
- `plane` *(Variable)*: Zero-based image-stack plane index.
- `RotZ` *(Variable, optional)*: If nonzero, allow rotation about the z axis.
- `wDC` *(Wave/Z, optional)*: that receives or supplies per-layer drift parameters.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `MultiThreadApplySavedDriftCorrections`

**Signature**

```igorpro
MultiThreadApplySavedDriftCorrections(WAVE w3D, [WAVE/Z cDriftW])
```

Apply stored drift corrections to an image stack in parallel.

Accepts either the two-row translation format produced by correlation or the 22-row transformation format
produced by ImageRegistration.

### Parameters

- `w3D` *(Wave)*: Input 3D image stack.
- `cDriftW` *(Wave/Z, optional)*: containing saved translation or ImageRegistration parameters.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `ApplySavedDriftCorrections_Worker`

**Signature**

```igorpro
ApplySavedDriftCorrections_Worker(WAVE w3D, WAVE wROIMask, WAVE wDC, variable plane)
```

Apply saved correlation or registration parameters to one stack layer.

### Parameters

- `w3D` *(Wave)*: Input 3D image stack.
- `wROIMask` *(Wave)*: Mask defining pixels used by ImageRegistration.
- `wDC` *(Wave)*: that receives or supplies per-layer drift parameters.
- `plane` *(Variable)*: Zero-based image-stack plane index.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `MultiThreadImageRegistration`

**Signature**

```igorpro
MultiThreadImageRegistration(WAVE w3D, variable ref)
```

Register image-stack layers in parallel.

### Parameters

- `w3D` *(Wave)*: Input 3D image stack.
- `ref` *(Variable)*: Zero-based index of the reference layer.

### Returns

- **Variable**: Zero after replacing the source stack with the registered result.


## `ImageRegistration_Worker`

**Signature**

```igorpro
ImageRegistration_Worker(WAVE w3D, WAVE wRef, variable plane)
```

Register one stack layer to a reference image.

### Parameters

- `w3D` *(Wave)*: Input 3D image stack.
- `wRef` *(Wave)*: Reference image used to register the selected layer.
- `plane` *(Variable)*: Zero-based image-stack plane index.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.
