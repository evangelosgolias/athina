# ATH_ZProfile

**Source file:** `Profilers/ATH_ZProfile.ipf`

Module ATH_ZProfile.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH ZProfile functionality.

```{contents}
:local:
:depth: 2
```

## `GraphMarqueeLaunchOval`

**Signature**

```igorpro
GraphMarqueeLaunchOval()
```

Graph marquee launch oval.

Reads the current graph interaction state and applies the requested operation to that selection.

### Returns

- **Variable**: Zero after completing the operation.


## `GraphMarqueeLaunchRectangle`

**Signature**

```igorpro
GraphMarqueeLaunchRectangle()
```

Graph marquee launch rectangle.

Reads the current graph interaction state and applies the requested operation to that selection.

### Returns

- **Variable**: Zero after completing the operation.


## `TracePopupLaunchSavedROI`

**Signature**

```igorpro
TracePopupLaunchSavedROI()
```

Trace popup launch saved ROI.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `InitialiseFolder`

**Signature**

```igorpro
InitialiseFolder()
```

Create and initialize state for an image-stack z profile.

### Returns

- **DFREF**: Reference to the resulting data folder.


## `DrawOvalImageROI`

**Signature**

```igorpro
DrawOvalImageROI(string winNameStr, variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
```

Draw oval image ROI.

Use ATH_ZProfileDrawImageROI to draw on UserFront and then return the ProgFront (used by the hook
function and ImageGenerateROIMask).

### Parameters

- `winNameStr` *(String)*: Win name str.
- `left` *(Variable)*: Left ROI or marquee bound.
- `top` *(Variable)*: Top ROI or marquee bound.
- `right` *(Variable)*: Right ROI or marquee bound.
- `bottom` *(Variable)*: Bottom ROI or marquee bound.
- `red` *(Variable)*: Red-channel value or wave.
- `green` *(Variable)*: Green-channel value or wave.
- `blue` *(Variable)*: Blue-channel value or wave.

### Returns

- **Variable**: Zero after completing the operation.


## `DrawRectImageROI`

**Signature**

```igorpro
DrawRectImageROI(string winNameStr, variable left, variable top, variable right, variable bottom, variable red, variable green, variable blue)
```

Draw rect image ROI.

Use ATH_ZProfileDrawImageROI to draw on UserFront and then return the ProgFront (used by the hook
function and ImageGenerateROIMask).

### Parameters

- `winNameStr` *(String)*: Win name str.
- `left` *(Variable)*: Left ROI or marquee bound.
- `top` *(Variable)*: Top ROI or marquee bound.
- `right` *(Variable)*: Right ROI or marquee bound.
- `bottom` *(Variable)*: Bottom ROI or marquee bound.
- `red` *(Variable)*: Red-channel value or wave.
- `green` *(Variable)*: Green-channel value or wave.
- `blue` *(Variable)*: Blue-channel value or wave.

### Returns

- **Variable**: Zero after completing the operation.


## `ClearROIMarkingsUserFront`

**Signature**

```igorpro
ClearROIMarkingsUserFront(string winNameStr)
```

Clear ROI markings from the graph's UserFront drawing layer.

### Parameters

- `winNameStr` *(String)*: Win name str.

### Returns

- **Variable**: Zero after completing the operation.


## `InitialiseGraph`

**Signature**

```igorpro
InitialiseGraph(DFREF dfr)
```

Initialize the graph used by the z-profile tool.

Here we will create the profile plot and graph and plot the profile. Note: PopupMenu should follow
SetWindow commands as the function BuildTwinWaveList() needs to get the userdata(ATH_rootdfrZProfileStr)
to initialise the menu.

### Parameters

- `dfr` *(DFREF)*: Reference to the data folder to inspect or modify.

### Returns

- **Variable**: Zero after completing the operation.


## `CursorHookFunction`

**Signature**

```igorpro
CursorHookFunction(STRUCT WMWinHookStruct &s)
```

Handle cursor hook events.

Window hook function. Redraw ROI KillWaves/Z M_ROIMask.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `GraphHookFunction`

**Signature**

```igorpro
GraphHookFunction(STRUCT WMWinHookStruct &s)
```

Handle panel hook events.

ParentGraphWin -- winNameStr. Kill the MyLineProfileHook. We need to reset the link between
parentGraphwin (winNameStr) and ATH_LinkedLineProfilePlotStr.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SaveProfileButton`

**Signature**

```igorpro
SaveProfileButton(STRUCT WMButtonAction &B_Struct)
```

Handle the save profile button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetScaleButton`

**Signature**

```igorpro
SetScaleButton(STRUCT WMButtonAction &B_Struct)
```

Handle the set scale button action.

Twin wave.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `CheckboxPlotProfile`

**Signature**

```igorpro
CheckboxPlotProfile(STRUCT WMCheckboxAction& cb)
```

Handle the plot-profile checkbox action.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `CheckboxMarkAreas`

**Signature**

```igorpro
CheckboxMarkAreas(STRUCT WMCheckboxAction& cb)
```

Handle the mark-areas checkbox action.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `CheckBoxTwinPlot`

**Signature**

```igorpro
CheckBoxTwinPlot(STRUCT WMCheckboxAction& cb)
```

Handle the twin-plot checkbox action.

Create the twinwave plot.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetTwinWavePath`

**Signature**

```igorpro
SetTwinWavePath(STRUCT WMSetVariableAction &sva)
```

Set twin wave path.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sva` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.
