# ATH_Launch

**Source file:** `Customization/ATH_Launch.ipf`

Module ATH_Launch.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Launch functionality.

```{contents}
:local:
:depth: 2
```

## `BrowserActionDoXMDC`

**Signature**

```igorpro
BrowserActionDoXMDC()
```

Calculate XMCD from the two waves selected in the Data Browser.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `BrowserActionMakeStack`

**Signature**

```igorpro
BrowserActionMakeStack()
```

Create a stack from the waves selected in the Data Browser.

### Returns

- **Variable**: Zero after completing the operation.


## `Make3DWaveUsingPattern`

**Signature**

```igorpro
Make3DWaveUsingPattern()
```

Create a 3D wave by stacking waves whose names match a pattern.

### Returns

- **Variable**: Zero after completing the operation.


## `Make3DWaveDataBrowserSelection`

**Signature**

```igorpro
Make3DWaveDataBrowserSelection([int displayStack, int transientStack])
```

Create a 3D wave from the waves selected in the Data Browser.

### Parameters

- `displayStack` *(Integer, optional)*: If nonzero, display the newly assembled stack.
- `transientStack` *(Integer, optional)*: If nonzero, mark the stack as temporary in the graph metadata.

### Returns

- **Variable**: Zero when a stack is created and displayed; one when no displayable stack is available.


## `LoadHDF5GroupsFromFile`

**Signature**

```igorpro
LoadHDF5GroupsFromFile()
```

Load selected groups from an HDF5 file.

### Returns

- **Variable**: Zero after completing the operation.


## `AverageStackToImageFromMenu`

**Signature**

```igorpro
AverageStackToImageFromMenu()
```

Average a selected 3D stack into an image from a menu command.

### Returns

- **Variable**: Zero after completing the operation.


## `AverageStackToImageFromTraceMenu`

**Signature**

```igorpro
AverageStackToImageFromTraceMenu()
```

Average the stack associated with the active trace-menu command.

### Returns

- **Variable**: Zero after completing the operation.


## `AverageStackToImageFromBrowserMenu`

**Signature**

```igorpro
AverageStackToImageFromBrowserMenu()
```

Average a stack selected in the Data Browser into an image.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `CalculateXMCDFromStack`

**Signature**

```igorpro
CalculateXMCDFromStack()
```

Calculate XMCD from a selected two-layer stack.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `CalculationXMCD`

**Signature**

```igorpro
CalculationXMCD()
```

Calculate XMCD.

S_fileName is a carriage-return-separated list of full paths to one or more files. as many times as the
dialog will be displayed. Equavalenty, it can. Set defaults.

### Returns

- **Variable**: The calculated calculation XMCD.


## `CalculationXMCD3D`

**Signature**

```igorpro
CalculationXMCD3D()
```

Calculate XMCD 3D.

S_fileName is a carriage-return-separated list of full paths to one or more files. as many times as the
dialog will be displayed. Equavalenty, it can. Set defaults.

### Returns

- **Variable**: The calculated calculation XMCD 3D.


## `ImageRegistrationStack`

**Signature**

```igorpro
ImageRegistrationStack()
```

Register all layers of an image stack to a reference layer.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `ImageStackAlignmentUsingAFeature`

**Signature**

```igorpro
ImageStackAlignmentUsingAFeature()
```

Align an image stack in independently processed spatial partitions.

Save drift correction parameters. Local variables only, not saved. Save settings, use zero/non-zero for
flags.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `LinearDriftCorrestionStackABCursors`

**Signature**

```igorpro
LinearDriftCorrestionStackABCursors()
```

Correct linear stack drift from the displacement between cursors A and B.

Use AB to linearly correct an image stack drift WAVE/Z wx, wy ImageInterpolate needs pixels, multiply by
-1 to have the proper behavior in /ARPM={...}.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `LinearDriftCorrestionPlanesABCursors`

**Signature**

```igorpro
LinearDriftCorrestionPlanesABCursors()
```

Correct linear drift across selected layers using cursors A and B.

Use AB to linearly correct planes in an image stack. Set the slider to the starting layer before
launching the operation. Set cursors and the last layer using the.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `NewImageFromBrowserSelection`

**Signature**

```igorpro
NewImageFromBrowserSelection()
```

New image from browser selection.

Display selected images. Verify that you did not misclicked and prevent opening many images (bummer).

### Returns

- **Variable**: Zero after completing the operation.


## `ImageBackupFromBrowserSelection`

**Signature**

```igorpro
ImageBackupFromBrowserSelection()
```

Image backup from browser selection.

### Returns

- **Variable**: Zero after completing the operation.


## `XPSProfileFromDefaultSettings`

**Signature**

```igorpro
XPSProfileFromDefaultSettings()
```

Generate an XPS profile using the saved default settings.

Extract selected PES profiles for selected images in DB.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `NormalisationImageStackWithImage`

**Signature**

```igorpro
NormalisationImageStackWithImage()
```

Normalize every stack layer by a selected 2D reference image.

Consistency check.

### Returns

- **Variable**: Zero after completing the operation.


## `NormalisationImageStackWithProfile`

**Signature**

```igorpro
NormalisationImageStackWithProfile()
```

Normalize stack layers by the corresponding values of a 1D profile.

Consistency check.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `NormalisationImageStackWithImageStack`

**Signature**

```igorpro
NormalisationImageStackWithImageStack()
```

Normalize one image stack by a second stack.

Consistency check. Select how many layers would you like to use for normalisation. Handle here unique
output name.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `RemoveImagesFromImageStack`

**Signature**

```igorpro
RemoveImagesFromImageStack()
```

Remove images from image stack.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `InsertImagesToStack`

**Signature**

```igorpro
InsertImagesToStack([variable extend])
```

Insert images to stack.

We selected at least an image. Let's sort things here a bit. First lets expand the wave note when we
insert a 3D wave.

### Parameters

- `extend` *(Variable, optional)*: If nonzero, extend the destination rather than replacing its current extent.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ImgRGB2Gray16`

**Signature**

```igorpro
ImgRGB2Gray16()
```

Convert the top RGB image to 16-bit grayscale.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `Rotate3DWaveAxes`

**Signature**

```igorpro
Rotate3DWaveAxes()
```

Rotate 3D wave axes.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ImageRotateAndScaleFromMetadata`

**Signature**

```igorpro
ImageRotateAndScaleFromMetadata()
```

Restore microscope orientation and field-of-view scaling from image metadata.

This operation transform the image as seen in the microscope when the angular compensation is on for
different FoVs. The combination of ImageRotation and ImageTransform flipRows wRef restores the image.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ImageFFTTransform`

**Signature**

```igorpro
ImageFFTTransform([int noPlot, int sourceDF, int mode])
```

Calculate the Fourier transform of the active image.

FFT of the top image. If Marquee is present the transform happends at the marked region FFT wave in the
cwd.

### Parameters

- `noPlot` *(Integer, optional)*: If nonzero, suppress creation of a result graph.
- `sourceDF` *(Integer, optional)*: Source data-folder reference or path.
- `mode` *(Integer, optional)*: Mode selector.

### Returns

- **Variable**: Zero after completing the operation.


## `AverageLayersRange`

**Signature**

```igorpro
AverageLayersRange()
```

Average a user-selected range of image-stack layers.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ExtractLayerRangeToStack`

**Signature**

```igorpro
ExtractLayerRangeToStack()
```

Extract a selected layer range into a new image stack.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `FlipStackPlanes`

**Signature**

```igorpro
FlipStackPlanes()
```

Reverse the layer order of the active image stack.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `AverageImageStack`

**Signature**

```igorpro
AverageImageStack()
```

Average image stack.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `HistogramShiftToGaussianCenter`

**Signature**

```igorpro
HistogramShiftToGaussianCenter()
```

Histogram shift to gaussian center.

### Returns

- **Variable**: Zero after completing the operation.


## `TwoTraceCalcs`

**Signature**

```igorpro
TwoTraceCalcs()
```

Perform a selected arithmetic operation on two graph traces.

Creates a separate result wave, leaving the input wave available to the caller.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `QuickTextAnnotation`

**Signature**

```igorpro
QuickTextAnnotation()
```

Prompt for text and add it as an annotation to the active graph.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `MakeWaveFromSavedROI`

**Signature**

```igorpro
MakeWaveFromSavedROI()
```

Create wave from saved ROI.

### Returns

- **Variable**: Zero after completing the operation.


## `XMCDCombinations`

**Signature**

```igorpro
XMCDCombinations()
```

Calculate XMCD for all layer pairs in the active image stack.

S_fileName is a carriage-return-separated list of full paths to one or more files.

### Returns

- **Variable**: Zero after completing the operation.


## `DeleteBigWaves`

**Signature**

```igorpro
DeleteBigWaves()
```

Find and optionally remove waves above a user-selected size threshold.

Delete filter larger than minFileSizeMB. The textWave that pops to check the waves can be edited to
remove the waves you want to keep (an invalid path.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `DeleteBigWavesDisplayed`

**Signature**

```igorpro
DeleteBigWavesDisplayed()
```

Close displays of oversized waves before removing those waves.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `PixelateSingleImageOrStack`

**Signature**

```igorpro
PixelateSingleImageOrStack()
```

Pixelate either a single image or every layer of an image stack.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `SetTopGraphDF`

**Signature**

```igorpro
SetTopGraphDF()
```

Switch the current data folder to the top graph's source folder.

Sets the DF of the top image or top trace. Remove background.

### Returns

- **Variable**: Zero after completing the operation.


## `ImgRemoveBackground`

**Signature**

```igorpro
ImgRemoveBackground([variable w3d])
```

Launch background removal for the active image or stack.

Return 1 for successful Mask creation, 0 otherwise. Flatten Image.

### Parameters

- `w3d` *(Variable, optional)*: Input 3D wave or image stack.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `FlattenImage`

**Signature**

```igorpro
FlattenImage()
```

Flatten image.

Create backup here. Resolve the. Get and set image range and ctab.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `SaveAxesRangeAndCtab`

**Signature**

```igorpro
SaveAxesRangeAndCtab([string grfName])
```

Save axes range and color table.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `SetAxesRangeAndCtabFromSaved`

**Signature**

```igorpro
SetAxesRangeAndCtabFromSaved([string grfName, variable setCtab, variable printCmd])
```

Set axes range and color table from saved.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.
- `setCtab` *(Variable, optional)*: If nonzero, restore the saved image color table.
- `printCmd` *(Variable, optional)*: If nonzero, print the generated Igor command to history.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `HistogramEqualisation`

**Signature**

```igorpro
HistogramEqualisation()
```

Apply histogram equalization to the active image.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `CloseTopWindowAndDeleteSource`

**Signature**

```igorpro
CloseTopWindowAndDeleteSource([int deleteBackUp, string grfName])
```

Close the active graph and delete its displayed source wave.

Close topwindow and delete the top image or trace.

### Parameters

- `deleteBackUp` *(Integer, optional)*: If nonzero, delete the image's backup wave as well.
- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `DeleteBackupWave`

**Signature**

```igorpro
DeleteBackupWave([string grfName])
```

Remove backup wave.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `MirrorPositionToWaveValues`

**Signature**

```igorpro
MirrorPositionToWaveValues()
```

Mirror the current graph position into stored wave values.

S_fileName is a carriage-return-separated list of full paths to one or more files.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `DrawSavedROIOnGraph`

**Signature**

```igorpro
DrawSavedROIOnGraph(string grfName, WAVE wRef, [variable bypass])
```

Draw a saved ROI on the active graph.

Draw the ROI saved in wRef on grfName set bypass to draw ROI on any graph.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `wRef` *(Wave)*: Input wave.
- `bypass` *(Variable, optional)*: If nonzero, skip the normal validation or selection step.

### Returns

- **Variable**: Zero after completing the operation.


## `iImgFFTFilter`

**Signature**

```igorpro
iImgFFTFilter([string grfName])
```

Launch the interactive FFT filter for the active image.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `UnpackStackToSources`

**Signature**

```igorpro
UnpackStackToSources([string grfName])
```

Restore image-stack layers to their source waves using stack metadata.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `ImageResample`

**Signature**

```igorpro
ImageResample()
```

Resample the active image using a selected interpolation method and scale.

Resample and offset image. Copyscales/I wRef, $resampledWaveName.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `DrawScaleBar`

**Signature**

```igorpro
DrawScaleBar([string grfName])
```

Prompt for a physical length and draw a scale bar on the active image graph.

String axisX, axisY variable minVX, maxVX, minVY, maxVY, sf.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: The scale-bar width as a fraction of the visible x-axis range, or -1 if the prompt is cancelled or invalid.


## `ImageZScore`

**Signature**

```igorpro
ImageZScore([string grfName])
```

Create a z-score-normalized copy of the active image.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `SetRangeAndCTabForAllGraphsInSpace`

**Signature**

```igorpro
SetRangeAndCTabForAllGraphsInSpace([string spaceTagStr, variable setCtab])
```

Apply saved axis ranges and color tables to every graph in an ATH space.

### Parameters

- `spaceTagStr` *(String, optional)*: ATH space tag selecting graph windows.
- `setCtab` *(Variable, optional)*: If nonzero, also apply the saved color table.

### Returns

- **Variable**: Zero after completing the operation.


## `ApplyEdgeDetectionCommandToStack`

**Signature**

```igorpro
ApplyEdgeDetectionCommandToStack([string grfName])
```

Apply an edge-detection command to the active image stack.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `ImageFilter3D`

**Signature**

```igorpro
ImageFilter3D([string grfName])
```

Apply a selected matrix filter to every layer of an image stack.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `ImageSmooth3D`

**Signature**

```igorpro
ImageSmooth3D([string grfName])
```

Smooth every layer of an image stack.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `SmoothWave`

**Signature**

```igorpro
SmoothWave([string grfName])
```

Smooth the selected wave using user-provided settings.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.
