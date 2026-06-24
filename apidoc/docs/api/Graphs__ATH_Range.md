# ATH_Range

**Source file:** `Graphs/ATH_Range.ipf`

Module ATH_Range.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Range functionality.

```{contents}
:local:
:depth: 2
```

## `SIDAMRange`

**Signature**

```igorpro
SIDAMRange([String grfName, String imgList, Variable zmin, Variable zmax, int zminmode, int zmaxmode])
```

Open or update the image z-range controls for a graph.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.
- `imgList` *(String, optional)*: Semicolon-separated image names to modify.
- `zmin` *(Variable, optional)*: Lower image color-range endpoint.
- `zmax` *(Variable, optional)*: Upper image color-range endpoint.
- `zminmode` *(Integer, optional)*: Mode used to determine the lower color-range endpoint.
- `zmaxmode` *(Integer, optional)*: Mode used to determine the upper color-range endpoint.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `validate`

**Signature**

```igorpro
validate(STRUCT paramStruct &s)
```

Validate z-range parameters and resolve the target images.

### Parameters

- `s` *(STRUCT paramStruct)*: Z-range parameter structure to validate and normalize.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `applyZRange`

**Signature**

```igorpro
applyZRange(String grfName, String imgName, Variable zmin, Variable zmax)
```

Apply explicit minimum and maximum color limits to an image.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.
- `zmin` *(Variable)*: Lower image color-range endpoint.
- `zmax` *(Variable)*: Upper image color-range endpoint.

### Returns

- **Variable**: Zero after completing the operation.


## `pnl`

**Signature**

```igorpro
pnl(String grfName)
```

Create the image z-range control panel.

### Parameters

- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlInit`

**Signature**

```igorpro
pnlInit(String grfName, String imgName, Variable zmin, Variable zmax)
```

Initialize z-range panel state for the selected image.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.
- `zmin` *(Variable)*: Lower image color-range endpoint.
- `zmax` *(Variable)*: Upper image color-range endpoint.

### Returns

- **String**: The full name of the initialized z-range panel.


## `pnlHookParent`

**Signature**

```igorpro
pnlHookParent(STRUCT WMWinHookStruct &s)
```

Handle changes in the z-range panel's parent graph.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlHookParentIgorDialog`

**Signature**

```igorpro
pnlHookParentIgorDialog(String grfName, String imgName)
```

Handle modal dialogs opened from the z-range panel's parent graph.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.

### Returns

- **Variable**: Zero after restoring the panel state; a nonzero value if the graph or image is unavailable.


## `isZAuto`

**Signature**

```igorpro
isZAuto(String grfName, String imgName, int minormax)
```

Test whether one side of an image color range is automatic.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.
- `minormax` *(Integer)*: Selects the lower or upper color-range endpoint.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `pnlHookParentLayerChanged`

**Signature**

```igorpro
pnlHookParentLayerChanged(String grfName, String imgName)
```

Update the z-range panel after the displayed image layer changes.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `pnlHookParentWaveModified`

**Signature**

```igorpro
pnlHookParentWaveModified(String grfName, String imgName)
```

Update the z-range panel after the image wave changes.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `pnlHookParentUpdatePanel`

**Signature**

```igorpro
pnlHookParentUpdatePanel(String grfName)
```

Synchronize the z-range panel with its parent graph.

### Parameters

- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `pnlHook`

**Signature**

```igorpro
pnlHook(STRUCT WMWinHookStruct &s)
```

Handle events from the image z-range panel.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `pnlHookClose`

**Signature**

```igorpro
pnlHookClose(String pnlName)
```

Clean up z-range state when the panel closes.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlHookCursor`

**Signature**

```igorpro
pnlHookCursor(STRUCT WMWinHookStruct &s)
```

Update z-range values after a graph cursor moves.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlAxHook`

**Signature**

```igorpro
pnlAxHook(STRUCT WMAxisHookStruct &s)
```

Update the z range after an axis-range event.

### Parameters

- `s` *(STRUCT WMAxisHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `pnlSetVar`

**Signature**

```igorpro
pnlSetVar(STRUCT WMSetVariableAction &s)
```

Handle numeric edits in the z-range panel.

### Parameters

- `s` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `pnlPopup`

**Signature**

```igorpro
pnlPopup(STRUCT WMPopupAction &s)
```

Handle pop-up selections in the z-range panel.

### Parameters

- `s` *(STRUCT WMPopupAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `pnlButton`

**Signature**

```igorpro
pnlButton(STRUCT WMButtonAction &s)
```

Handle button actions in the z-range panel.

### Parameters

- `s` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `pnlCheck`

**Signature**

```igorpro
pnlCheck(STRUCT WMCheckboxAction &s)
```

Handle checkbox actions in the z-range panel.

### Parameters

- `s` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `revertZmode`

**Signature**

```igorpro
revertZmode(String pnlName)
```

Restore the z-range mode saved when the panel opened.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `updatePnlPresentValues`

**Signature**

```igorpro
updatePnlPresentValues(String pnlName)
```

Refresh panel controls from the image's current z-range state.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `resetPnlCtrls`

**Signature**

```igorpro
resetPnlCtrls(String pnlName)
```

Reset z-range panel controls to their default state.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `updatePnlRadioBox`

**Signature**

```igorpro
updatePnlRadioBox(String pnlName, String ctrlName)
```

Update the z-range mode radio-button group.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `ctrlName` *(String)*: Name of the Igor control.

### Returns

- **Variable**: Zero after completing the operation.


## `updatePnlCursorsPos`

**Signature**

```igorpro
updatePnlCursorsPos(String pnlName)
```

Synchronize z-range cursors with the panel values.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `updatePnlColor`

**Signature**

```igorpro
updatePnlColor(String pnlName)
```

Refresh the panel color-scale preview.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `updatePnlHistogram`

**Signature**

```igorpro
updatePnlHistogram(String pnlName, int mode)
```

Recalculate and display the image histogram in the panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `mode` *(Integer)*: Operation mode selector.

### Returns

- **Variable**: Zero after completing the operation.


## `updatePnlAxis`

**Signature**

```igorpro
updatePnlAxis(String pnlName)
```

Refresh the histogram axes in the z-range panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `updateZmode`

**Signature**

```igorpro
updateZmode(String pnlName)
```

Apply the z-range mode selected in the panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `findSelectedMode`

**Signature**

```igorpro
findSelectedMode(String pnlName)
```

Return the selected lower- and upper-range modes.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Multiple values**: The selected lower- and upper-range mode codes.


## `updateZRange`

**Signature**

```igorpro
updateZRange(String grfName, [int pause])
```

Recalculate color limits for images in a graph.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `pause` *(Integer, optional)*: If nonzero, defer graph updates while applying the range.

### Returns

- **Variable**: Zero after completing the operation.


## `updateZRange_getValues`

**Signature**

```igorpro
updateZRange_getValues(String grfName, String imgName, int m0, Variable v0, int m1, Variable v1)
```

Calculate z-range limits for one image and mode combination.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.
- `m0` *(Integer)*: Lower-range mode.
- `v0` *(Variable)*: Explicit lower-range value.
- `m1` *(Integer)*: Upper-range mode.
- `v1` *(Variable)*: Explicit upper-range value.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `initializeZmodeValue`

**Signature**

```igorpro
initializeZmodeValue(String grfName)
```

Store initial z-range metadata for graph images.

### Parameters

- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `setZmodeValue`

**Signature**

```igorpro
setZmodeValue(String grfName, String imgList, String key, Variable var)
```

Write a z-range metadata value for a list of images.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgList` *(String)*: Semicolon-separated image names to modify.
- `key` *(String)*: Metadata or settings key.
- `var` *(Variable)*: Numeric value to apply.

### Returns

- **Variable**: Zero after completing the operation.


## `getZmodeValue`

**Signature**

```igorpro
getZmodeValue(String grfName, String imgName, String key)
```

Read a z-range metadata value for an image.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.
- `key` *(String)*: Metadata or settings key.

### Returns

- **Variable**: The requested zmode value.


## `cleanZmodeValue`

**Signature**

```igorpro
cleanZmodeValue(String grfName)
```

Remove obsolete z-range metadata from a graph.

### Parameters

- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Nonzero if obsolete z-range metadata was removed; otherwise zero.


## `deleteZmodeValues`

**Signature**

```igorpro
deleteZmodeValues(String grfName)
```

Delete stored z-range metadata for a graph.

### Parameters

- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `canZmodeBeDeleted`

**Signature**

```igorpro
canZmodeBeDeleted(String grfName)
```

Test whether stored z-range metadata is no longer required.

### Parameters

- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `SIDAMWindowExists`

**Signature**

```igorpro
SIDAMWindowExists(String pnlName)
```

Test whether a named host window or child window exists.

ListStr is empty if "hostName" does not exist or "hostName" does not have a child window. Extension of
WMImageInfo.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `SIDAM_ColorTableForImage`

**Signature**

```igorpro
SIDAM_ColorTableForImage(String grfName, String imgName)
```

Return the active color table and range for an image.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.

### Returns

- **String**: The image color-table specification from the graph recreation string.


## `SIDAM_GetColorTableMinMax`

**Signature**

```igorpro
SIDAM_GetColorTableMinMax(String grfName, String imgName, Variable &zmin, Variable &zmax, [int allowNaN])
```

Return numeric endpoints from an image color-table specification.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.
- `zmin` *(Variable)*: Lower image color-range endpoint.
- `zmax` *(Variable)*: Upper image color-range endpoint.
- `allowNaN` *(Integer, optional)*: If nonzero, accept NaN color-range endpoints.

### Returns

- **Variable**: Zero after writing the resolved minimum and maximum through the reference parameters.


## `SIDAMNewDF`

**Signature**

```igorpro
SIDAMNewDF(String grfName, String procName)
```

Create and return a uniquely named data folder.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `procName` *(String)*: Procedure name used as part of the generated data-folder name.

### Returns

- **String**: The full path of the newly created data folder.


## `SIDAMImageNameToWaveRef`

**Signature**

```igorpro
SIDAMImageNameToWaveRef(String grfName, [String imgName, int displayed])
```

Resolve an image name to its source wave reference.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String, optional)*: Name of the image trace.
- `displayed` *(Integer, optional)*: If nonzero, resolve the displayed layer wave rather than the source image wave.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `SIDAM_ColorTableLog`

**Signature**

```igorpro
SIDAM_ColorTableLog(String grfName, String imgName)
```

Test whether an image uses logarithmic color mapping.

EG: Modified Hist Functions as param Structures are the same across different files in SIDAM.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.

### Returns

- **Variable**: Nonzero when logarithmic color mapping is enabled; otherwise zero.


## `SIDAMHistogram`

**Signature**

```igorpro
SIDAMHistogram(Wave/Z w, [variable startz, variable endz, variable deltaz, int bins, int cumulative, int normalize, int cmplxmode, string grfName])
```

Calculate a histogram for an image wave or displayed layer.

### Parameters

- `w` *(Wave/Z)*: Input wave.
- `startz` *(Variable, optional)*: Lower histogram bound.
- `endz` *(Variable, optional)*: Upper histogram bound.
- `deltaz` *(Variable, optional)*: Histogram bin width.
- `bins` *(Integer, optional)*: Number of histogram bins.
- `cumulative` *(Integer, optional)*: If nonzero, return a cumulative histogram.
- `normalize` *(Integer, optional)*: If nonzero, normalize the histogram.
- `cmplxmode` *(Integer, optional)*: Complex-wave component selected for analysis.
- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `validateHist`

**Signature**

```igorpro
validateHist(STRUCT paramStructHist &s)
```

Validate histogram parameters and establish output defaults.

### Parameters

- `s` *(STRUCT paramStructHist)*: Histogram parameter structure to validate and normalize.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `SIDAMGetLayerIndex`

**Signature**

```igorpro
SIDAMGetLayerIndex(String grfName, [Wave/Z w])
```

Get layer index.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `w` *(Wave/Z, optional)*: Input wave.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `SIDAMKillDataFolder`

**Signature**

```igorpro
SIDAMKillDataFolder(DFREF dfr)
```

Kill data folder.

### Parameters

- `dfr` *(DFREF)*: Reference to the data folder to inspect or modify.

### Returns

- **Variable**: Recursive status: zero on completion, one for the protected package folder, two for remaining child objects, or three for waves that could not be removed.


## `SIDAMPopupTo`

**Signature**

```igorpro
SIDAMPopupTo(STRUCT WMPopupAction &s, String paramStr)
```

Send a panel value to the command line or clipboard.

### Parameters

- `s` *(STRUCT WMPopupAction)*: Igor action structure describing the control or window event.
- `paramStr` *(String)*: Text containing the param str.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SIDAMGetCtrlValues`

**Signature**

```igorpro
SIDAMGetCtrlValues(String win, String ctrlList)
```

Return numeric values from a list of panel controls.

### Parameters

- `win` *(String)*: Name of the panel or graph containing the controls.
- `ctrlList` *(String)*: Semicolon-separated list of control names.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `histogramFrom2D`

**Signature**

```igorpro
histogramFrom2D(STRUCT paramStructHist &s)
```

Calculate a histogram from a two-dimensional wave region.

### Parameters

- `s` *(STRUCT paramStructHist)*: Validated histogram parameters for a two-dimensional image.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `histogramFrom3D`

**Signature**

```igorpro
histogramFrom3D(STRUCT paramStructHist &s)
```

Calculate a histogram from a three-dimensional wave region.

### Parameters

- `s` *(STRUCT paramStructHist)*: Validated histogram parameters for a three-dimensional image or layer range.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `getMinMax`

**Signature**

```igorpro
getMinMax(Wave w, String grfName, [int cmplxmode])
```

Return minimum and maximum values for a wave or displayed region.

### Parameters

- `w` *(Wave)*: Input wave.
- `grfName` *(String)*: Name of the graph window.
- `cmplxmode` *(Integer, optional)*: Complex-wave component selected for analysis.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `killDependence`

**Signature**

```igorpro
killDependence(DFREF dfr)
```

Remove graph dependencies that prevent temporary waves from being deleted.

### Parameters

- `dfr` *(DFREF)*: Data-folder reference.

### Returns

- **Variable**: Zero after completing the operation.


## `killWaveDataFolder`

**Signature**

```igorpro
killWaveDataFolder(DFREF dfr)
```

Remove deletable waves from a data folder.

### Parameters

- `dfr` *(DFREF)*: Data-folder reference.

### Returns

- **Variable**: The number of waves that could not be removed from the data folder.


## `valueType`

**Signature**

```igorpro
valueType(String recreationStr)
```

Classify a serialized Igor value by type.

### Parameters

- `recreationStr` *(String)*: Igor window or control recreation string.

### Returns

- **Variable**: A code identifying the serialized value as numeric, text, wave, or unsupported.


## `eval`

**Signature**

```igorpro
eval(String str)
```

Evaluate a serialized numeric Igor expression.

### Parameters

- `str` *(String)*: Serialized Igor numeric expression.

### Returns

- **Variable**: The numeric value represented by the serialized Igor expression.


## `removeImageTrace`

**Signature**

```igorpro
removeImageTrace(DFREF dfr)
```

Remove graph image traces that reference waves in a data folder.

### Parameters

- `dfr` *(DFREF)*: Data-folder reference.

### Returns

- **Variable**: Zero after completing the operation.


## `removeImageTraceHelper`

**Signature**

```igorpro
removeImageTraceHelper(DFREF dfr, String grfName)
```

Remove matching image traces from one graph.

### Parameters

- `dfr` *(DFREF)*: Data-folder reference.
- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `GetMarqueeToIndex`

**Signature**

```igorpro
GetMarqueeToIndex([string grfName])
```

Convert the active graph marquee to wave-index bounds.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Multiple values**: A validity flag followed by the left, right, top, and bottom wave-index bounds.


## `TopImageToWaveRef`

**Signature**

```igorpro
TopImageToWaveRef([string grfName])
```

Return a reference to the top image in a graph.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.
