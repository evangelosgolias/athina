# ATH_ImageOp

**Source file:** `ImageProcessing/ATH_ImageOp.ipf`

Module ATH_ImageOp.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH ImageOp functionality.

```{contents}
:local:
:depth: 2
```

## `RangeMeanSigmaTopImage`

**Signature**

```igorpro
RangeMeanSigmaTopImage()
```

Set the top image's color range to its mean plus or minus three standard deviations.

Autoscale image of the top grap.

### Returns

- **Variable**: Zero after updating the range; -1 when the top graph has no image wave.


## `GetLayerIndex`

**Signature**

```igorpro
GetLayerIndex(string grfName, [Wave/Z w])
```

Return layer index.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `w` *(Wave/Z, optional)*: Input wave.

### Returns

- **Variable**: The zero-based index, or a negative value when no match is found.


## `AutoRangeTopImagePlane`

**Signature**

```igorpro
AutoRangeTopImagePlane()
```

Autoscale the color range of the displayed image plane.

Autoscale image of the top grap.

### Returns

- **Variable**: Zero after completing the operation.


## `SetZScaleOfImageStack`

**Signature**

```igorpro
SetZScaleOfImageStack()
```

Set the layer-axis scale of the image stack in the top graph.

### Returns

- **Variable**: Zero after completing the operation.


## `ImageSelectToCopyScale`

**Signature**

```igorpro
ImageSelectToCopyScale()
```

Copy dimension scales from a selected image to the top image.

Select the first wave from browser selection.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `NormaliseImageStackWithImage`

**Signature**

```igorpro
NormaliseImageStackWithImage(WAVE w3dRef, WAVE w2dRef)
```

Divide every layer of an image stack by a two-dimensional reference image.

### Parameters

- `w3dRef` *(Wave)*: Input image stack.
- `w2dRef` *(Wave)*: Two-dimensional reference image used as the divisor.

### Returns

- **String**: The full path of the normalized output stack.


## `NormaliseImageStackWithImageStack`

**Signature**

```igorpro
NormaliseImageStackWithImageStack(WAVE w3dRef1, WAVE w3dRef2)
```

Divide an image stack pointwise by a second stack.

### Parameters

- `w3dRef1` *(Wave)*: Input image stack.
- `w3dRef2` *(Wave)*: Image stack used as the divisor.

### Returns

- **String**: The full path of the normalized output stack.


## `NormaliseImageStackWithProfile`

**Signature**

```igorpro
NormaliseImageStackWithProfile(WAVE w3dRef, WAVE profWaveRef)
```

Normalize each stack layer by the corresponding value of a one-dimensional profile.

### Parameters

- `w3dRef` *(Wave)*: Input image stack.
- `profWaveRef` *(Wave)*: One-dimensional normalization profile indexed by stack layer.

### Returns

- **String**: The full path of the normalized output stack.


## `GetScaledZoominImageWindow`

**Signature**

```igorpro
GetScaledZoominImageWindow([string grfName, variable w3d, int evenNum])
```

Extract the visible graph region into a correctly scaled image wave.

Get a the current window view as a new image with appropriate scaling. Works for 2D/3D waves. Added om
12.05.2025.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.
- `w3d` *(Variable, optional)*: Input 3D wave or image stack.
- `evenNum` *(Integer, optional)*: If nonzero, force an even number of rows and columns.

### Returns

- **Variable**: The scaled zoomin image window.


## `GetLayerFromImageStack`

**Signature**

```igorpro
GetLayerFromImageStack()
```

Return layer from image stack.

### Returns

- **Variable**: The zero-based index, or a negative value when no match is found.


## `RemoveImagesFromImageStack`

**Signature**

```igorpro
RemoveImagesFromImageStack(WAVE wRef, variable startLayer, variable nrLayers)
```

Remove images from image stack.

Remove nrLayers starting at startLayer from w3dRef. Use it to change wave notes.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `startLayer` *(Variable)*: Lower or starting start layer.
- `nrLayers` *(Variable)*: Number of image-stack layers.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `RemoveRangeOfImagesFromImageStack`

**Signature**

```igorpro
RemoveRangeOfImagesFromImageStack(WAVE wRef, string layerRangeList)
```

Remove range of images from image stack.

You need to remove from the end if the list maybe you are trying to remove all the layers?.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `layerRangeList` *(String)*: Layer range list.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `InsertImagesToImageStack`

**Signature**

```igorpro
InsertImagesToImageStack(WAVE wRef, WAVE wIn, variable layerN)
```

Insert images to image stack.

Insert an image at the position layerN of an image stack. Here the z dimension will change, as the
DimDelta for rescaling. Note that the layerN stack will bethe first image after the insering stacks.

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `wIn` *(Wave)*: Input wave or window name, as required by the operation.
- `layerN` *(Variable)*: Zero-based image-stack layer index.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `AppendImagesToImageStack`

**Signature**

```igorpro
AppendImagesToImageStack(WAVE wRef, string waveListStr)
```

Append images to image stack.

Append images in waveListStr to wRef.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `waveListStr` *(String)*: Wave used by the operation.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ConcatenateImages`

**Signature**

```igorpro
ConcatenateImages(string destWaveStr, string waveListStr)
```

Concatenate images.

Concatenate wave to destWaveStr.

### Parameters

- `destWaveStr` *(String)*: Wave used by the operation.
- `waveListStr` *(String)*: Wave used by the operation.

### Returns

- **Variable**: Zero after completing the operation.


## `ImageEdgeDetectionToStack`

**Signature**

```igorpro
ImageEdgeDetectionToStack(WAVE w3dref, string cmd, [variable overwrite])
```

Apply an edge-detection command to every layer of an image stack.

Applied the edge detection operation to w3dref and outputs a wave with name NameofWave(w3dref) + "_ed".
You can optionally ovewrite the input wave.

### Parameters

- `w3dref` *(Wave)*: Input 3D image stack.
- `cmd` *(String)*: Igor command or operation string.
- `overwrite` *(Variable, optional)*: If nonzero, replace the source or an existing destination.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ImageRotateAndScale`

**Signature**

```igorpro
ImageRotateAndScale(WAVE wRef, variable angle, [variable backup, variable flipY])
```

Rotate and rescale an image while preserving its physical coordinates.

Math: If the side of the image is a, then the rotated image will have side a_rot = a * (cos(angle) +
sin(angle)).

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `angle` *(Variable)*: Angle.
- `backup` *(Variable, optional)*: If nonzero, preserve a backup of the source image.
- `flipY` *(Variable, optional)*: If nonzero, flip the result along y.

### Returns

- **Variable**: Zero after completing the operation.


## `BackupTopImage`

**Signature**

```igorpro
BackupTopImage()
```

Backup top image.

Backup wave in the top window, the backup is created in the sourcewave datafolder (to be able to
restore).

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `RestoreTopImageFromBackup`

**Signature**

```igorpro
RestoreTopImageFromBackup([string grfName, variable keepBackup])
```

Restore top image from backup.

Restore an image from backup. When ParamIsDefault (wavenameStr = "") the image on the top window is used,
otherwise WAVE $wavenameStr. Backup wave's name is *assummed* to be NameOfWave(wRef) +
ksATHBackupWaveExtention.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.
- `keepBackup` *(Variable, optional)*: If nonzero, retain the backup after restoration.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ExtractLayerRange`

**Signature**

```igorpro
ExtractLayerRange(WAVE w3d, [variable startL, variable endL, variable doStack, variable nameNote])
```

Extract a contiguous layer range as a new stack or as individual image waves.

When `doStack` is nonzero, the result is a scaled 3D stack. Otherwise the layers are written into a new data
folder, optionally using names stored in the source wave note.

### Parameters

- `w3d` *(Wave)*: Input 3D image stack.
- `startL` *(Variable, optional)*: Zero-based first layer to extract.
- `endL` *(Variable, optional)*: Zero-based last layer to extract, inclusive.
- `doStack` *(Variable, optional)*: If nonzero, combine the selected layers into one 3D stack.
- `nameNote` *(Variable, optional)*: If nonzero, name extracted layers from the source wave note when possible.

### Returns

- **String**: The full path of the output stack or data folder; an empty string indicates invalid bounds.


## `AverageImageRangeToStackOffset`

**Signature**

```igorpro
AverageImageRangeToStackOffset(WAVE w3d, variable NP0, variable NPL)
```

Average image range to stack offset.

Average NPL image planes in stack starting from N0.

### Parameters

- `w3d` *(Wave)*: Input 3D wave or image stack.
- `NP0` *(Variable)*: First point index.
- `NPL` *(Variable)*: Number of points or final point index.

### Returns

- **Variable**: Zero after completing the operation.


## `AverageImageRangeToStack`

**Signature**

```igorpro
AverageImageRangeToStack(WAVE w3d, variable NP0, variable NP1)
```

Average image range to stack.

Average image range NP0-NP1, including endpoints.

### Parameters

- `w3d` *(Wave)*: Input 3D wave or image stack.
- `NP0` *(Variable)*: First point index.
- `NP1` *(Variable)*: Second point index.

### Returns

- **Variable**: Zero after completing the operation.


## `HistogramShiftToGaussianCenter`

**Signature**

```igorpro
HistogramShiftToGaussianCenter(WAVE w2d, [variable overwrite])
```

Histogram shift to gaussian center.

Move the histogram center to the center of the fitted gaussian. Useful for symmetrising XMCD/XMLD images.
Add the value to w2d.

### Parameters

- `w2d` *(Wave)*: Input 2D image.
- `overwrite` *(Variable, optional)*: If nonzero, replace the source or an existing destination.

### Returns

- **Variable**: Zero after completing the operation.


## `HistogramShiftToGaussianCenterStack`

**Signature**

```igorpro
HistogramShiftToGaussianCenterStack(WAVE w3d, [variable overwrite])
```

Histogram shift to gaussian center stack.

Move the histogram center to the center of the fitted gaussian. Useful for symmetrising XMCD/XMLD images.
The function returns the applies shift.

### Parameters

- `w3d` *(Wave)*: Input 3D wave or image stack.
- `overwrite` *(Variable, optional)*: If nonzero, replace the source or an existing destination.

### Returns

- **Variable**: The Gaussian-center shift applied to the final processed layer.


## `GrayToRGBImage`

**Signature**

```igorpro
GrayToRGBImage(WAVE wRef)
```

Convert a grayscale image into an RGB image using the Grays color table.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Zero after completing the operation.


## `RGB2Gray8Image`

**Signature**

```igorpro
RGB2Gray8Image(WAVE wRef)
```

Convert an RGB image to 8-bit grayscale.

Convert a 3D RGB image to grayscale (8-bit).

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `RGB2Gray16Image`

**Signature**

```igorpro
RGB2Gray16Image(WAVE wRef)
```

Convert an RGB image to 16-bit grayscale.

Convert a 3D RGB image to grayscale (16-bit) /W/U. The RGB values are converted into the luminance Y of
the YIQ standard using.

### Parameters

- `wRef` *(Wave)*: to modify in place.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `FlattenImage`

**Signature**

```igorpro
FlattenImage(WAVE wRef, string method, string kind, variable kernelN, variable iterN, [int overwrite])
```

Flatten image.

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `method` *(String)*: Algorithm or processing method to apply.
- `kind` *(String)*: Filter or morphology operation to apply.
- `kernelN` *(Variable)*: Kernel width in points.
- `iterN` *(Variable)*: Number of processing iterations.
- `overwrite` *(Integer, optional)*: If nonzero, replace the source or an existing destination.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ImgRemoveBackground`

**Signature**

```igorpro
ImgRemoveBackground(WAVE wRef, [variable order, int useMask, variable layerN])
```

Image remove background.

Remove background of an image (default 1st order). Use order = n, n > 1 for higher order polynomial. Use
overwite = 1 to overwite the original wave.

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `order` *(Variable, optional)*: Interpolation or polynomial order.
- `useMask` *(Integer, optional)*: If nonzero, restrict the calculation to the supplied mask.
- `layerN` *(Variable, optional)*: Zero-based image-stack layer index.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `ImgRemoveBackgroundCols`

**Signature**

```igorpro
ImgRemoveBackgroundCols(WAVE wRef, variable orderN)
```

Remove a fitted background independently from each image column.

Image Remove 1-d background from each column. Make/O/N=(DimSize(wRef,1), orderN) fitCoeff fitCoeff[i][] =
W_coef[q].

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `orderN` *(Variable)*: Interpolation or polynomial order.

### Returns

- **Variable**: Zero after completing the operation.


## `PixelateImage`

**Signature**

```igorpro
PixelateImage(WAVE wRef, variable nx, variable ny, [variable i16])
```

Pixelate image.

Pixalate a 2D image using a (nx, ny) binning. Set i16 to preserve a 16-bit integer wave.

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `nx` *(Variable)*: Number of points along the x dimension.
- `ny` *(Variable)*: Number of points along the y dimension.
- `i16` *(Variable, optional)*: If nonzero, produce a 16-bit integer image.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `PixelateImageStack`

**Signature**

```igorpro
PixelateImageStack(WAVE wRef, variable nx, variable ny, variable nz, [variable i16])
```

Pixelate image stack.

Pixalate a 3D image stack using a (nx, ny, nz) binning. Set i16 to preserve a 16-bit integer wave.

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `nx` *(Variable)*: Number of points along the x dimension.
- `ny` *(Variable)*: Number of points along the y dimension.
- `nz` *(Variable)*: Number of points or layers along the z dimension.
- `i16` *(Variable, optional)*: If nonzero, produce a 16-bit integer image.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ImageFilter3D`

**Signature**

```igorpro
ImageFilter3D(WAVE wRef, string method, variable size, variable passes, [int overwrite])
```

Apply an Igor matrix filter independently to every layer of a 3D image stack.

Reassembles the filtered planes with the original scaling and wave note. By default the source is overwritten; otherwise a new wave with a `_filter` suffix is created.

### Parameters

- `wRef` *(Wave)*: Input 3D image stack.
- `method` *(String)*: Matrix-filter method: `gauss`, `avg`, `median`, `max`, or `min`.
- `size` *(Variable)*: Filter-kernel size in points.
- `passes` *(Variable)*: Number of filter passes.
- `overwrite` *(Integer, optional)*: If nonzero, replace `wRef`; defaults to one.

### Returns

- **Variable**: Zero on success; -1 for an unsupported method or a non-3D input wave.


## `FlattenImage3D`

**Signature**

```igorpro
FlattenImage3D(WAVE wRef, string method, string kind, variable size, variable passes, [int overwrite])
```

Flatten image 3D.

Applies the MatrixFilter/N=size/P=passes method wRef to each layer of wRef. Restore scale here.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `method` *(String)*: Algorithm or processing method to apply.
- `kind` *(String)*: Filter or morphology operation to apply.
- `size` *(Variable)*: Size.
- `passes` *(Variable)*: Number of filter passes to apply.
- `overwrite` *(Integer, optional)*: If nonzero, replace the source or an existing destination.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ImageWindow3D`

**Signature**

```igorpro
ImageWindow3D(WAVE wRef, string method)
```

Image window 3D.

Restore scale here.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `method` *(String)*: Algorithm or processing method to apply.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ImageResampling`

**Signature**

```igorpro
ImageResampling(WAVE wRef,  string func, variable xOffset, variable yOffset, [int overwrite, variable xscale, variable yscale])
```

Resample and translate an image with a selected interpolation method.

Supported interpolation functions are `bilinear`, `nn`, `cubic`, `spline`, and `sinc`. Offsets and scale
factors are passed to Igor's `ImageInterpolate` operation.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `func` *(String)*: Interpolation function: `bilinear`, `nn`, `cubic`, `spline`, or `sinc`.
- `xOffset` *(Variable)*: Horizontal translation in source pixels.
- `yOffset` *(Variable)*: Vertical translation in source pixels.
- `overwrite` *(Integer, optional)*: If nonzero, replace the source or existing destination.
- `xscale` *(Variable, optional)*: Horizontal resampling factor.
- `yscale` *(Variable, optional)*: Vertical resampling factor.

### Returns

- **String**: The full path of the resampled image, or an empty string for invalid input.


## `ScaleImagePreserveDims`

**Signature**

```igorpro
ScaleImagePreserveDims(WAVE wRef, variable factor, [variable factorY])
```

Scale image preserve dims.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `factor` *(Variable)*: Factor.
- `factorY` *(Variable, optional)*: Factor y.

### Returns

- **Variable**: Zero after completing the operation.


## `ScaleFoVWithFactor`

**Signature**

```igorpro
ScaleFoVWithFactor(WAVE wRef, variable factor,[int interval])
```

Scale an image's field of view by a multiplicative factor.

Scale image with factor.

### Parameters

- `wRef` *(Wave)*: to modify in place.
- `factor` *(Variable)*: Factor.
- `interval` *(Integer, optional)*: Sampling interval for the generated or rescaled data.

### Returns

- **Variable**: Zero after completing the operation.


## `ComputeImageZScore`

**Signature**

```igorpro
ComputeImageZScore(Wave wRef, [string grfName])
```

Create a z-score-normalized copy of an image wave.

Uses statistics from the graph ROI when one exists, or from the complete wave otherwise, and saves the result beside the source with a `_zscr` suffix.

### Parameters

- `wRef` *(Wave)*: Input image wave.
- `grfName` *(String, optional)*: Graph containing the ROI; defaults to the active graph.

### Returns

- **Variable**: Zero after completing the operation.


## `MultiThreadLoess3D`

**Signature**

```igorpro
MultiThreadLoess3D(WAVE wRef, variable npts,variable order, variable passes, variable extrapolate, variable robust, [variable overwrite])
```

Apply LOESS smoothing to every image-stack layer using Igor's worker threads.

Collects the free waves returned by `Loess3D_Worker`, concatenates them into a 3D result, and preserves the source note.

### Parameters

- `wRef` *(Wave)*: Input 3D image stack.
- `npts` *(Variable)*: LOESS neighborhood size.
- `order` *(Variable)*: Polynomial order used by LOESS.
- `passes` *(Variable)*: Number of robust-fitting passes.
- `extrapolate` *(Variable)*: Extrapolation mode passed to Igor's `Loess` operation.
- `robust` *(Variable)*: Robust-fitting mode passed to Igor's `Loess` operation.
- `overwrite` *(Variable, optional)*: If nonzero, replace the input stack; otherwise create a wave with a `_loess` suffix.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `Loess3D_Worker`

**Signature**

```igorpro
Loess3D_Worker(WAVE wRef, variable npts,variable order, variable passes, variable extrapolate, variable robust, variable plane)
```

Apply LOESS smoothing to one image-stack layer.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `npts` *(Variable)*: Number of output points or LOESS neighborhood size, as applicable.
- `order` *(Variable)*: Polynomial order used by LOESS.
- `passes` *(Variable)*: Number of robust-fitting passes.
- `extrapolate` *(Variable)*: Extrapolation mode passed to Igor's `Loess` operation.
- `robust` *(Variable)*: Robust-fitting mode passed to Igor's `Loess` operation.
- `plane` *(Variable)*: Zero-based image-stack plane index.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.
