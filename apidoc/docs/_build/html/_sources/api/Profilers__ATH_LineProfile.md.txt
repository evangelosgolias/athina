# ATH_LineProfile

**Source file:** `Profilers/ATH_LineProfile.ipf`

Module ATH_LineProfile.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH LineProfile functionality.

```{contents}
:local:
:depth: 2
```

## `MainMenu`

**Signature**

```igorpro
MainMenu()
```

Launch the line-profile tool for the active image.

When autoscaled then SETAXISCMD is SetAxis/A.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `InitialiseFolder`

**Signature**

```igorpro
InitialiseFolder(string winNameStr)
```

Create and initialize state for a graph's line-profile tool.

### Parameters

- `winNameStr` *(String)*: Name of the target graph or panel window.

### Returns

- **DFREF**: Reference to the resulting data folder.


## `InitialiseGraph`

**Signature**

```igorpro
InitialiseGraph(DFREF dfr)
```

Initialize the graph used by the line-profile tool.

Here we will create the profile plot and graph and plot the profile.

### Parameters

- `dfr` *(DFREF)*: Reference to the data folder to inspect or modify.

### Returns

- **Variable**: Zero after completing the operation.


## `CreatePlot`

**Signature**

```igorpro
CreatePlot(DFREF dfr)
```

Create plot.

ModifyGraph
mode=7,useNegRGB=1,usePlusRGB=1,hbFill=5,negRGB=(65535,32768,32768),plusRGB=(32768,40777,65535).

### Parameters

- `dfr` *(DFREF)*: Reference to the data folder to inspect or modify.

### Returns

- **Variable**: Zero after completing the operation.


## `ClearLineMarkings`

**Signature**

```igorpro
ClearLineMarkings(string winNameStr)
```

Clear line markings.

### Parameters

- `winNameStr` *(String)*: Win name str.

### Returns

- **Variable**: Zero after completing the operation.


## `DrawLineUserFront`

**Signature**

```igorpro
DrawLineUserFront(string winNameStr, variable x0, variable y0, variable x1, variable y1, variable red, variable green, variable blue)
```

Draw line user front.

### Parameters

- `winNameStr` *(String)*: Win name str.
- `x0` *(Variable)*: First x coordinate or range bound.
- `y0` *(Variable)*: First y coordinate or range bound.
- `x1` *(Variable)*: Second x coordinate or range bound.
- `y1` *(Variable)*: Second y coordinate or range bound.
- `red` *(Variable)*: Red-channel value or wave.
- `green` *(Variable)*: Green-channel value or wave.
- `blue` *(Variable)*: Blue-channel value or wave.

### Returns

- **Variable**: Zero after completing the operation.


## `CursorsHookFunction`

**Signature**

```igorpro
CursorsHookFunction(STRUCT WMWinHookStruct &s)
```

Handle cursors hook events.

Window hook function. The line profile is drawn from E to F. To revise. Case 17 is not recommended to use
for killing windows. See JW's email.

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

ParentImageWinStr -- winNameStr. Kill the MyLineProfileHook. We need to reset the link between
parentImageWinStr (winNameStr) and ATH_LinkedWinImageLPP.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SaveProfile`

**Signature**

```igorpro
SaveProfile(STRUCT WMButtonAction &B_Struct)
```

Save profile.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `SaveDefaultSettings`

**Signature**

```igorpro
SaveDefaultSettings(STRUCT WMButtonAction &B_Struct)
```

Save default settings.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `SetLineProfileScale`

**Signature**

```igorpro
SetLineProfileScale(STRUCT WMButtonAction &B_Struct)
```

Set the line-profile scale from a user-entered cursor distance.

Converts the entered physical distance to a per-point scaling factor. A value of zero restores nominal image scaling; anisotropic image pixels disable custom scaling.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor button-action structure describing the event and panel window.

### Returns

- **Variable**: Zero after updating the scale, one if the prompt is cancelled, or -1 for anisotropic image pixels.


## `RestoreDefaultSettings`

**Signature**

```igorpro
RestoreDefaultSettings(STRUCT WMButtonAction &B_Struct)
```

Restore default settings.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `ShowProfileWidth`

**Signature**

```igorpro
ShowProfileWidth(STRUCT WMButtonAction &B_Struct)
```

Show profile width.

We have to find the vertices of the polygon representing.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


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


## `ProfileLayer3D`

**Signature**

```igorpro
ProfileLayer3D(STRUCT WMCheckboxAction& cb)
```

Profile layer 3D.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `CheckboxMarkLines`

**Signature**

```igorpro
CheckboxMarkLines(STRUCT WMCheckboxAction& cb)
```

Handle the mark-lines checkbox action.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetVariableWidth`

**Signature**

```igorpro
SetVariableWidth(STRUCT WMSetVariableAction& sv)
```

Set variable width.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sv` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `DrawLineProfileRectangle`

**Signature**

```igorpro
DrawLineProfileRectangle(variable C1x,variable C1y,variable C2x, variable C2y, variable dx, variable dy, variable width, string grfName)
```

Draw the polygon representing a line profile's sampling width.

### Parameters

- `C1x` *(Variable)*: X coordinate of the profile's first endpoint.
- `C1y` *(Variable)*: Y coordinate of the profile's first endpoint.
- `C2x` *(Variable)*: X coordinate of the profile's second endpoint.
- `C2y` *(Variable)*: Y coordinate of the profile's second endpoint.
- `dx` *(Variable)*: Horizontal pixel size.
- `dy` *(Variable)*: Vertical pixel size.
- `width` *(Variable)*: Half-width of the sampled line profile in pixels.
- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Zero after drawing the sampling-width polygon.


## `DeleleLineProfileRectangle`

**Signature**

```igorpro
DeleleLineProfileRectangle(string grfName)
```

Delete the rectangle marking the line-profile width.

### Parameters

- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.
