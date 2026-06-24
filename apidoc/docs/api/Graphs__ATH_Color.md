# ATH_Color

**Source file:** `Graphs/ATH_Color.ipf`

Module ATH_Color.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Color functionality.

```{contents}
:local:
:depth: 2
```

## `applycmap`

**Signature**

```igorpro
applycmap([String grfName, String imgList, String ctable, int rev, int log, Wave minRGB, Wave maxRGB, int history])
```

Apply a color map to one or more target images.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.
- `imgList` *(String, optional)*: Semicolon-separated image names to modify.
- `ctable` *(String, optional)*: Igor color-table name.
- `rev` *(Integer, optional)*: If nonzero, reverse the color table or order.
- `log` *(Integer, optional)*: If nonzero, use logarithmic color mapping.
- `minRGB` *(Wave, optional)*: RGB values for the lower color-range endpoint.
- `maxRGB` *(Wave, optional)*: RGB values for the upper color-range endpoint.
- `history` *(Integer, optional)*: If nonzero, print the generated command to Igor history.

### Returns

- **Variable**: Zero on success; a nonzero value if the target graph or parameters are invalid.


## `defaultValues`

**Signature**

```igorpro
defaultValues(STRUCT paramStruct &s)
```

Populate missing color-panel options with their defaults.

### Parameters

- `s` *(STRUCT paramStruct)*: Color-table parameter structure populated with default values.

### Returns

- **Variable**: Zero after completing the operation.


## `validateInputs`

**Signature**

```igorpro
validateInputs(STRUCT paramStruct &s)
```

Validate color-table parameters and target images.

### Parameters

- `s` *(STRUCT paramStruct)*: Color-table parameter structure to validate and normalize.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `printHistory`

**Signature**

```igorpro
printHistory(STRUCT paramStruct &s, STRUCT paramStruct &base)
```

Print a reproducible color-table command to Igor history.

### Parameters

- `s` *(STRUCT paramStruct)*: Color-table parameters used to construct the command.
- `base` *(STRUCT paramStruct)*: Reference parameter structure used to identify changed settings.

### Returns

- **Variable**: Zero after completing the operation.


## `applyColorTable`

**Signature**

```igorpro
applyColorTable(STRUCT paramStruct &s, int i)
```

Apply the configured color table to one target image.

### Parameters

- `s` *(STRUCT paramStruct)*: Color-table parameters to apply.
- `i` *(Integer)*: Zero-based target-image index.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `pnl`

**Signature**

```igorpro
pnl(String grfName)
```

Create and initialize the module's control panel.

### Parameters

- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `showLoading`

**Signature**

```igorpro
showLoading(String pnlName, int isOpen)
```

Show or hide the color-panel loading indicator.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `isOpen` *(Integer)*: Nonzero while the loading indicator should be visible.

### Returns

- **Variable**: Zero after completing the operation.


## `deleteLoading`

**Signature**

```igorpro
deleteLoading(String pnlName)
```

Remove the color-panel loading indicator.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlGroupComponents`

**Signature**

```igorpro
pnlGroupComponents(String pnlName, int group, [int hide, int rev, int log, String selected])
```

Update visibility and state for one group of color-panel controls.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `group` *(Integer)*: Panel-control group number.
- `hide` *(Integer, optional)*: If nonzero, hide the selected control group.
- `rev` *(Integer, optional)*: If nonzero, reverse the color table or order.
- `log` *(Integer, optional)*: If nonzero, use logarithmic color mapping.
- `selected` *(String, optional)*: Name of the control that should remain selected.

### Returns

- **Variable**: Zero after completing the operation.


## `fetchWavepathList`

**Signature**

```igorpro
fetchWavepathList(DFREF dfr)
```

Return image-wave paths found below a data folder.

### Parameters

- `dfr` *(DFREF)*: Data-folder reference.

### Returns

- **String**: A semicolon-separated list of image-wave paths found below the data folder.


## `findGroup`

**Signature**

```igorpro
findGroup(String grfName, String imgName)
```

Return the color-panel group containing a graph image.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.

### Returns

- **Variable**: The panel group number containing the image, or a negative value if it is not found.


## `findCheckBox`

**Signature**

```igorpro
findCheckBox(String pnlName, String imgName)
```

Return the checkbox associated with an image.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `imgName` *(String)*: Name of the image trace.

### Returns

- **String**: The control name of the checkbox associated with the image, or an empty string if absent.


## `checkBoxNameList`

**Signature**

```igorpro
checkBoxNameList(String pnlName)
```

Return the image-selection checkboxes in a color panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **String**: A semicolon-separated list of image-selection checkbox names.


## `saveInitialColor`

**Signature**

```igorpro
saveInitialColor(String pnlName)
```

Save the initial color settings for every image controlled by a panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlHook`

**Signature**

```igorpro
pnlHook(STRUCT WMWinHookStruct &s)
```

Handle panel hook events.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `pnlHookClose`

**Signature**

```igorpro
pnlHookClose(String pnlName)
```

Clean up color-panel state when the panel closes.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlHookArrows`

**Signature**

```igorpro
pnlHookArrows(String pnlName, int keycode)
```

Move the color-panel selection in response to arrow keys.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `keycode` *(Integer)*: Igor key code for the keyboard event.

### Returns

- **Variable**: Zero after completing the operation.


## `numOfCheckBoxes`

**Signature**

```igorpro
numOfCheckBoxes(String pnlName, int group)
```

Count image-selection checkboxes in a panel group.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `group` *(Integer)*: Panel-control group number.

### Returns

- **Variable**: The number of image-selection checkboxes in the group.


## `isDoubleColumns`

**Signature**

```igorpro
isDoubleColumns(String pnlName, int group)
```

Test whether a checkbox group is arranged in two columns.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `group` *(Integer)*: Panel-control group number.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `pnlHookWheel`

**Signature**

```igorpro
pnlHookWheel(STRUCT WMWinHookStruct &s)
```

Handle mouse-wheel changes in the color panel.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlHookParent`

**Signature**

```igorpro
pnlHookParent(STRUCT WMWinHookStruct &s)
```

Handle changes in the color panel's parent graph.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlList`

**Signature**

```igorpro
pnlList(STRUCT WMListboxAction &s)
```

Handle color-panel list-box events.

### Parameters

- `s` *(STRUCT WMListboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `pnlCheck`

**Signature**

```igorpro
pnlCheck(STRUCT  WMCheckboxAction &s)
```

Handle the panel checkbox action.

### Parameters

- `s` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `pnlCheckRadio`

**Signature**

```igorpro
pnlCheckRadio(STRUCT WMCheckboxAction &s)
```

Handle color-panel radio-button changes.

### Parameters

- `s` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlCheckCtab`

**Signature**

```igorpro
pnlCheckCtab(STRUCT WMCheckboxAction &s)
```

Handle color-table checkbox changes.

### Parameters

- `s` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `pnlPopup`

**Signature**

```igorpro
pnlPopup(STRUCT WMPopupAction &s)
```

Handle the panel pop-up action.

### Parameters

- `s` *(STRUCT WMPopupAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `pnlButton`

**Signature**

```igorpro
pnlButton(STRUCT WMButtonAction &s)
```

Handle the panel button action.

### Parameters

- `s` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `targetImageList`

**Signature**

```igorpro
targetImageList(String pnlName)
```

Return the graph images currently targeted by the color panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **String**: A semicolon-separated list of target image names.


## `selectGroup`

**Signature**

```igorpro
selectGroup(String pnlName, int group)
```

Select one image group in the color panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `group` *(Integer)*: Panel-control group number.

### Returns

- **Variable**: Zero after completing the operation.


## `updateAllImaeges`

**Signature**

```igorpro
updateAllImaeges(STRUCT  WMCheckboxAction &s)
```

Apply a color-setting change to every selected image.

### Parameters

- `s` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `updateOptionCheckboxes`

**Signature**

```igorpro
updateOptionCheckboxes(String pnlName, String imgName)
```

Update reverse and logarithmic option checkboxes from an image.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `imgName` *(String)*: Name of the image trace.

### Returns

- **Variable**: Zero after completing the operation.


## `updateColorscalesInPnl`

**Signature**

```igorpro
updateColorscalesInPnl(String pnlName)
```

Refresh all color-scale controls in a panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `updateColorscalesInSubpnl`

**Signature**

```igorpro
updateColorscalesInSubpnl(String subPnlNameFull, int rev, int log)
```

Refresh the color scales inside one image subpanel.

### Parameters

- `subPnlNameFull` *(String)*: Full name of the image subpanel.
- `rev` *(Integer)*: If nonzero, reverse the color table or order.
- `log` *(Integer)*: If nonzero, use logarithmic color mapping.

### Returns

- **Variable**: Zero after completing the operation.


## `selectCheckBox`

**Signature**

```igorpro
selectCheckBox(String pnlName, String ctrlName)
```

Select one image checkbox and clear incompatible selections.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `ctrlName` *(String)*: Name of the Igor control.

### Returns

- **Variable**: Zero after completing the operation.


## `selectCtabCheckBox`

**Signature**

```igorpro
selectCtabCheckBox(String pnlName, String ctrlName)
```

Select one color-table checkbox.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `ctrlName` *(String)*: Name of the Igor control.

### Returns

- **Variable**: Zero after completing the operation.


## `findSelectedColortable`

**Signature**

```igorpro
findSelectedColortable(String pnlName)
```

Return the color table selected in the panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **String**: The selected Igor color-table name, or an empty string if none is selected.


## `revertImageColor`

**Signature**

```igorpro
revertImageColor(String pnlName)
```

Restore the images' color settings saved when the panel opened.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Zero after completing the operation.


## `makeRGBWave`

**Signature**

```igorpro
makeRGBWave(STRUCT paramStructLite &s)
```

Create an RGB color wave from lightweight color parameters.

### Parameters

- `s` *(STRUCT paramStructLite)*: Lightweight color parameters containing the RGB endpoints.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `getRGBFromPanel`

**Signature**

```igorpro
getRGBFromPanel(String pnlName, STRUCT paramStruct &s)
```

Read the current minimum and maximum RGB values from a color panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `s` *(STRUCT paramStruct)*: Color-table parameter structure that receives both RGB endpoints.

### Returns

- **Variable**: Zero after reading both RGB endpoints.


## `getRGBFromPanelHelper`

**Signature**

```igorpro
getRGBFromPanelHelper(String pnlName, STRUCT paramStruct &s, int mode)
```

Read one RGB endpoint from a color panel.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `s` *(STRUCT paramStruct)*: Color-table parameter structure that receives one RGB endpoint.
- `mode` *(Integer)*: Operation mode selector.

### Returns

- **Variable**: Zero after reading the requested RGB endpoint.


## `printHistoryAfterPressingButton`

**Signature**

```igorpro
printHistoryAfterPressingButton(String pnlName)
```

Print the color command after an apply-button action.

### Parameters

- `pnlName` *(String)*: Name of the panel window.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `findChangedParameters`

**Signature**

```igorpro
findChangedParameters(String pnlName, STRUCT paramStruct &s, STRUCT paramStruct &base)
```

Determine which color parameters differ from their initial values.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `s` *(STRUCT paramStruct)*: Current color-table parameters to compare.
- `base` *(STRUCT paramStruct)*: Reference parameter structure used to identify changed settings.

### Returns

- **Variable**: The matching changed parameters, or a negative value if no match is found.


## `fetchPresentParameters`

**Signature**

```igorpro
fetchPresentParameters(STRUCT paramStruct &s)
```

Read the current color parameters from the target image.

### Parameters

- `s` *(STRUCT paramStruct)*: Color-table parameter structure populated from the displayed image.

### Returns

- **Variable**: Zero after completing the operation.


## `fetchInitParameters`

**Signature**

```igorpro
fetchInitParameters(String infoStr, STRUCT paramStruct &s)
```

Read initial color parameters from a saved recreation string.

### Parameters

- `infoStr` *(String)*: Igor recreation or metadata string.
- `s` *(STRUCT paramStruct)*: Color-table parameter structure populated from the saved recreation string.

### Returns

- **Variable**: Zero after completing the operation.


## `loadColorTableAll`

**Signature**

```igorpro
loadColorTableAll()
```

Load all supported user color-table wave files.

### Returns

- **Variable**: Zero after completing the operation.


## `loadColorTableIbwFiles`

**Signature**

```igorpro
loadColorTableIbwFiles(String dfStr, String pathStr)
```

Load color-table IBW files from one symbolic path.

### Parameters

- `dfStr` *(String)*: Destination data-folder path.
- `pathStr` *(String)*: Symbolic or file-system path.

### Returns

- **Variable**: Zero after completing the operation.


## `divide3Dto1D`

**Signature**

```igorpro
divide3Dto1D(Wave w, int makesubdir)
```

Split 3D color-table waves into individual 1D color tables.

### Parameters

- `w` *(Wave)*: Three-dimensional wave containing one or more color tables.
- `makesubdir` *(Integer)*: If nonzero, create a subfolder for each converted table.

### Returns

- **Variable**: Zero after completing the operation.


## `isCtabWave`

**Signature**

```igorpro
isCtabWave(String pathName, String wName)
```

Test whether a wave has the dimensions required for a color table.

### Parameters

- `pathName` *(String)*: Name of an Igor symbolic path.
- `wName` *(String)*: Wave name.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `ATH_ColorKillWaves`

**Signature**

```igorpro
ATH_ColorKillWaves()
```

Remove temporary color-table waves created by the color panel.

Waves when the panel is opened next time.

### Returns

- **Variable**: Zero after completing the operation.


## `cindexWave2ctabWave`

**Signature**

```igorpro
cindexWave2ctabWave()
```

Convert indexed color waves into Igor color-table waves.

### Returns

- **Variable**: Zero after completing the operation.


## `SIDAM_ColorTableLog`

**Signature**

```igorpro
SIDAM_ColorTableLog(String grfName, String imgName)
```

Test whether an image uses logarithmic color mapping.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.

### Returns

- **Variable**: Nonzero when logarithmic color mapping is enabled; otherwise zero.


## `SIDAM_ImageColorRGBMode`

**Signature**

```igorpro
SIDAM_ImageColorRGBMode(String grfName, String imgName, String key)
```

Return the RGB color-mode code stored in an image's recreation settings.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.
- `key` *(String)*: Metadata or window-note key.

### Returns

- **Variable**: Igor's numeric RGB color-mode code.


## `SIDAM_ImageColorRGBValues`

**Signature**

```igorpro
SIDAM_ImageColorRGBValues(String grfName, String imgName, String key, STRUCT RGBColor &s)
```

Read or write RGB endpoint values in an image recreation string.

### Parameters

- `grfName` *(String)*: Name of the graph window.
- `imgName` *(String)*: Name of the image trace.
- `key` *(String)*: Metadata or settings key.
- `s` *(STRUCT RGBColor)*: RGB color settings structure.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `SIDAMWaveToString`

**Signature**

```igorpro
SIDAMWaveToString(Wave/Z w, [int noquote])
```

Serialize a numeric or text wave as an Igor expression.

### Parameters

- `w` *(Wave/Z)*: Numeric or text wave to serialize.
- `noquote` *(Integer, optional)*: If nonzero, omit quotes around text elements.

### Returns

- **String**: An Igor expression that reconstructs the wave's values.


## `SIDAMClickCheckBox`

**Signature**

```igorpro
SIDAMClickCheckBox(String pnlName, String ctrlName)
```

Handle the click checkbox action.

S.mouseLoc.v = s.mouseLoc.h =.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `ctrlName` *(String)*: Name of the Igor control.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SIDAMClickCheckBoxPrototype`

**Signature**

```igorpro
SIDAMClickCheckBoxPrototype(STRUCT WMCheckboxAction &s)
```

Programmatically invoke a panel checkbox's action procedure.

Join elements of a text wave and return as a string.

### Parameters

- `s` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `join`

**Signature**

```igorpro
join(Wave/T tw, int noquote)
```

Join text-wave elements into an Igor list expression.

### Parameters

- `tw` *(Wave/T)*: Text wave whose elements are joined.
- `noquote` *(Integer)*: If nonzero, omit quotes around text elements.

### Returns

- **String**: The joined Igor list expression.


## `num2text`

**Signature**

```igorpro
num2text(Wave w)
```

Convert a numeric wave to a text wave.

### Parameters

- `w` *(Wave)*: Numeric wave to convert.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `col`

**Signature**

```igorpro
col(Wave w, Variable index)
```

Return one column of a two-dimensional wave.

### Parameters

- `w` *(Wave)*: Two-dimensional source wave.
- `index` *(Variable)*: Zero-based item index.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `getActionFunctionName`

**Signature**

```igorpro
getActionFunctionName(String recreationStr)
```

Extract an action-procedure name from a control recreation string.

### Parameters

- `recreationStr` *(String)*: Igor window or control recreation string.

### Returns

- **String**: The action-procedure name, or an empty string if the recreation string has none.


## `getWinRect`

**Signature**

```igorpro
getWinRect(String pnlName, STRUCT Rect &winRect)
```

Return a panel window's screen rectangle.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `winRect` *(STRUCT Rect)*: Structure receiving the window rectangle.

### Returns

- **Variable**: Zero after populating `winRect`.


## `getCtrlRect`

**Signature**

```igorpro
getCtrlRect(String pnlName, String ctrlName, STRUCT Rect &ctrlRect)
```

Return a panel control's rectangle.

### Parameters

- `pnlName` *(String)*: Name of the panel window.
- `ctrlName` *(String)*: Name of the Igor control.
- `ctrlRect` *(STRUCT Rect)*: Structure receiving the control rectangle.

### Returns

- **Variable**: Zero after populating `ctrlRect`.


## `getEventMod`

**Signature**

```igorpro
getEventMod()
```

Return the current keyboard-modifier bit mask.

### Returns

- **Variable**: The current keyboard-modifier bit mask.
