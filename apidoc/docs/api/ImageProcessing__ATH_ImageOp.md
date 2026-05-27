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

Description of RangeMeanSigmaTopImage.

Auto-generated documentation stub for function `RangeMeanSigmaTopImage`.

### Returns

- **Variable**: Return value.


## `GetLayerIndex`

**Signature**

```igorpro
GetLayerIndex(string grfName, [Wave/Z w])
```

Description of GetLayerIndex.

Auto-generated documentation stub for function `GetLayerIndex`.

### Parameters

- `grfName` *(Parameter)*: grfName.
- `w]` *(Parameter)*: w].

### Returns

- **Variable**: Return value.


## `AutoRangeTopImagePlane`

**Signature**

```igorpro
AutoRangeTopImagePlane()
```

Description of AutoRangeTopImagePlane.

Auto-generated documentation stub for function `AutoRangeTopImagePlane`.

### Returns

- **Variable**: Return value.


## `SetZScaleOfImageStack`

**Signature**

```igorpro
SetZScaleOfImageStack()
```

Description of SetZScaleOfImageStack.

Auto-generated documentation stub for function `SetZScaleOfImageStack`.

### Returns

- **Variable**: Return value.


## `ImageSelectToCopyScale`

**Signature**

```igorpro
ImageSelectToCopyScale()
```

Description of ImageSelectToCopyScale.

Auto-generated documentation stub for function `ImageSelectToCopyScale`.

### Returns

- **Variable**: Return value.


## `GetScaledZoominImageWindow`

**Signature**

```igorpro
GetScaledZoominImageWindow([string grfName, variable w3d, int evenNum])
```

Description of GetScaledZoominImageWindow.

Auto-generated documentation stub for function `GetScaledZoominImageWindow`.

### Parameters

- `grfName` *(Parameter)*: grfName.
- `w3d` *(Parameter)*: w3d.
- `evenNum]` *(Parameter)*: evenNum].

### Returns

- **Variable**: Return value.


## `GetLayerFromImageStack`

**Signature**

```igorpro
GetLayerFromImageStack()
```

Description of GetLayerFromImageStack.

Auto-generated documentation stub for function `GetLayerFromImageStack`.

### Returns

- **Variable**: Return value.


## `RemoveImagesFromImageStack`

**Signature**

```igorpro
RemoveImagesFromImageStack(WAVE wRef, variable startLayer, variable nrLayers)
```

Description of RemoveImagesFromImageStack.

Auto-generated documentation stub for function `RemoveImagesFromImageStack`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `startLayer` *(Parameter)*: startLayer.
- `nrLayers` *(Parameter)*: nrLayers.

### Returns

- **Variable**: Return value.


## `RemoveRangeOfImagesFromImageStack`

**Signature**

```igorpro
RemoveRangeOfImagesFromImageStack(WAVE wRef, string layerRangeList)
```

Description of RemoveRangeOfImagesFromImageStack.

Auto-generated documentation stub for function `RemoveRangeOfImagesFromImageStack`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `layerRangeList` *(Parameter)*: layerRangeList.

### Returns

- **Variable**: Return value.


## `InsertImagesToImageStack`

**Signature**

```igorpro
InsertImagesToImageStack(WAVE wRef, WAVE wIn, variable layerN)
```

Description of InsertImagesToImageStack.

Auto-generated documentation stub for function `InsertImagesToImageStack`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `wIn` *(Parameter)*: wIn.
- `layerN` *(Parameter)*: layerN.

### Returns

- **Variable**: Return value.


## `AppendImagesToImageStack`

**Signature**

```igorpro
AppendImagesToImageStack(WAVE wRef, string waveListStr)
```

Description of AppendImagesToImageStack.

Auto-generated documentation stub for function `AppendImagesToImageStack`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `waveListStr` *(Parameter)*: waveListStr.

### Returns

- **Variable**: Return value.


## `ConcatenateImages`

**Signature**

```igorpro
ConcatenateImages(string destWaveStr, string waveListStr)
```

Description of ConcatenateImages.

Auto-generated documentation stub for function `ConcatenateImages`.

### Parameters

- `destWaveStr` *(Parameter)*: destWaveStr.
- `waveListStr` *(Parameter)*: waveListStr.

### Returns

- **Variable**: Return value.


## `ImageEdgeDetectionToStack`

**Signature**

```igorpro
ImageEdgeDetectionToStack(WAVE w3dref, string method, [variable overwrite])
```

Description of ImageEdgeDetectionToStack.

Auto-generated documentation stub for function `ImageEdgeDetectionToStack`.

### Parameters

- `w3dref` *(Parameter)*: w3dref.
- `method` *(Parameter)*: method.
- `overwrite]` *(Parameter)*: overwrite].

### Returns

- **Variable**: Return value.


## `ImageRotateAndScale`

**Signature**

```igorpro
ImageRotateAndScale(WAVE wRef, variable angle, [variable backup, variable flipY])
```

Description of ImageRotateAndScale.

Auto-generated documentation stub for function `ImageRotateAndScale`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `angle` *(Parameter)*: angle.
- `backup` *(Parameter)*: backup.
- `flipY]` *(Parameter)*: flipY].

### Returns

- **Variable**: Return value.


## `BackupTopImage`

**Signature**

```igorpro
BackupTopImage()
```

Description of BackupTopImage.

Auto-generated documentation stub for function `BackupTopImage`.

### Returns

- **Variable**: Return value.


## `RestoreTopImageFromBackup`

**Signature**

```igorpro
RestoreTopImageFromBackup([string grfName, variable keepBackup])
```

Description of RestoreTopImageFromBackup.

Auto-generated documentation stub for function `RestoreTopImageFromBackup`.

### Parameters

- `grfName` *(Parameter)*: grfName.
- `keepBackup]` *(Parameter)*: keepBackup].

### Returns

- **Variable**: Return value.


## `AverageImageRangeToStackOffset`

**Signature**

```igorpro
AverageImageRangeToStackOffset(WAVE w3d, variable NP0, variable NPL)
```

Description of AverageImageRangeToStackOffset.

Auto-generated documentation stub for function `AverageImageRangeToStackOffset`.

### Parameters

- `w3d` *(Parameter)*: w3d.
- `NP0` *(Parameter)*: NP0.
- `NPL` *(Parameter)*: NPL.

### Returns

- **Variable**: Return value.


## `AverageImageRangeToStack`

**Signature**

```igorpro
AverageImageRangeToStack(WAVE w3d, variable NP0, variable NP1)
```

Description of AverageImageRangeToStack.

Auto-generated documentation stub for function `AverageImageRangeToStack`.

### Parameters

- `w3d` *(Parameter)*: w3d.
- `NP0` *(Parameter)*: NP0.
- `NP1` *(Parameter)*: NP1.

### Returns

- **Variable**: Return value.


## `HistogramShiftToGaussianCenter`

**Signature**

```igorpro
HistogramShiftToGaussianCenter(WAVE w2d, [variable overwrite])
```

Description of HistogramShiftToGaussianCenter.

Auto-generated documentation stub for function `HistogramShiftToGaussianCenter`.

### Parameters

- `w2d` *(Parameter)*: w2d.
- `overwrite]` *(Parameter)*: overwrite].

### Returns

- **Variable**: Return value.


## `HistogramShiftToGaussianCenterStack`

**Signature**

```igorpro
HistogramShiftToGaussianCenterStack(WAVE w3d, [variable overwrite])
```

Description of HistogramShiftToGaussianCenterStack.

Auto-generated documentation stub for function `HistogramShiftToGaussianCenterStack`.

### Parameters

- `w3d` *(Parameter)*: w3d.
- `overwrite]` *(Parameter)*: overwrite].

### Returns

- **Variable**: Return value.


## `GrayToRGBImage`

**Signature**

```igorpro
GrayToRGBImage(WAVE wRef)
```

Description of GrayToRGBImage.

Auto-generated documentation stub for function `GrayToRGBImage`.

### Parameters

- `wRef` *(Parameter)*: wRef.

### Returns

- **Variable**: Return value.


## `RGB2Gray8Image`

**Signature**

```igorpro
RGB2Gray8Image(WAVE wRef)
```

Description of RGB2Gray8Image.

Auto-generated documentation stub for function `RGB2Gray8Image`.

### Parameters

- `wRef` *(Parameter)*: wRef.

### Returns

- **Variable**: Return value.


## `RGB2Gray16Image`

**Signature**

```igorpro
RGB2Gray16Image(WAVE wRef)
```

Description of RGB2Gray16Image.

Auto-generated documentation stub for function `RGB2Gray16Image`.

### Parameters

- `wRef` *(Parameter)*: wRef.

### Returns

- **Variable**: Return value.


## `FlattenImage`

**Signature**

```igorpro
FlattenImage(WAVE wRef, string method, variable kernelN, variable iterN, [int overwrite])
```

Description of FlattenImage.

Auto-generated documentation stub for function `FlattenImage`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `method` *(Parameter)*: method.
- `kernelN` *(Parameter)*: kernelN.
- `iterN` *(Parameter)*: iterN.
- `overwrite]` *(Parameter)*: overwrite].

### Returns

- **Variable**: Return value.


## `ImgRemoveBackground`

**Signature**

```igorpro
ImgRemoveBackground(WAVE wRef, [variable order, int useMask, int w3d, variable layerN])
```

Description of ImgRemoveBackground.

Auto-generated documentation stub for function `ImgRemoveBackground`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `order` *(Parameter)*: order.
- `useMask` *(Parameter)*: useMask.
- `w3d` *(Parameter)*: w3d.
- `layerN]` *(Parameter)*: layerN].

### Returns

- **Variable**: Return value.


## `ImgRemoveBackgroundCols`

**Signature**

```igorpro
ImgRemoveBackgroundCols(WAVE wRef, variable orderN)
```

Description of ImgRemoveBackgroundCols.

Auto-generated documentation stub for function `ImgRemoveBackgroundCols`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `orderN` *(Parameter)*: orderN.

### Returns

- **Variable**: Return value.


## `PixelateImage`

**Signature**

```igorpro
PixelateImage(WAVE wRef, variable nx, variable ny, [variable i16])
```

Description of PixelateImage.

Auto-generated documentation stub for function `PixelateImage`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `nx` *(Parameter)*: nx.
- `ny` *(Parameter)*: ny.
- `i16]` *(Parameter)*: i16].

### Returns

- **Variable**: Return value.


## `PixelateImageStack`

**Signature**

```igorpro
PixelateImageStack(WAVE wRef, variable nx, variable ny, variable nz, [variable i16])
```

Description of PixelateImageStack.

Auto-generated documentation stub for function `PixelateImageStack`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `nx` *(Parameter)*: nx.
- `ny` *(Parameter)*: ny.
- `nz` *(Parameter)*: nz.
- `i16]` *(Parameter)*: i16].

### Returns

- **Variable**: Return value.


## `MatrixFilter3D`

**Signature**

```igorpro
MatrixFilter3D(WAVE wRef, string method, variable size, variable passes, [int overwite])
```

Description of MatrixFilter3D.

Auto-generated documentation stub for function `MatrixFilter3D`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `method` *(Parameter)*: method.
- `size` *(Parameter)*: size.
- `passes` *(Parameter)*: passes.
- `overwite]` *(Parameter)*: overwite].

### Returns

- **Variable**: Return value.


## `FlattenImage3D`

**Signature**

```igorpro
FlattenImage3D(WAVE wRef, string method, variable size, variable passes, [int overwrite])
```

Description of FlattenImage3D.

Auto-generated documentation stub for function `FlattenImage3D`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `method` *(Parameter)*: method.
- `size` *(Parameter)*: size.
- `passes` *(Parameter)*: passes.
- `overwrite]` *(Parameter)*: overwrite].

### Returns

- **Variable**: Return value.


## `ImageWindow3D`

**Signature**

```igorpro
ImageWindow3D(WAVE wRef, string method)
```

Description of ImageWindow3D.

Auto-generated documentation stub for function `ImageWindow3D`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `method` *(Parameter)*: method.

### Returns

- **Variable**: Return value.


## `ScaleImagePreserveDims`

**Signature**

```igorpro
ScaleImagePreserveDims(WAVE wRef, variable factor, [variable factorY])
```

Description of ScaleImagePreserveDims.

Auto-generated documentation stub for function `ScaleImagePreserveDims`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `factor` *(Parameter)*: factor.
- `factorY]` *(Parameter)*: factorY].

### Returns

- **Variable**: Return value.


## `ScaleFoVWithObjectiveCurrent`

**Signature**

```igorpro
ScaleFoVWithObjectiveCurrent(WAVE wRef, variable mobj,[int interval])
```

Description of ScaleFoVWithObjectiveCurrent.

Auto-generated documentation stub for function `ScaleFoVWithObjectiveCurrent`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `mobj` *(Parameter)*: mobj.
- `interval]` *(Parameter)*: interval].

### Returns

- **Variable**: Return value.
