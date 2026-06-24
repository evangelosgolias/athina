# ATH_PlaneZProfile

**Source file:** `Profilers/ATH_PlaneZProfile.ipf`

Module ATH_PlaneZProfile.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH PlaneZProfile functionality.

```{contents}
:local:
:depth: 2
```

## `MainMenu`

**Signature**

```igorpro
MainMenu()
```

Launch the plane z-profile tool for the active stack.

User selected a wave, check if it's 3d name to the windows hook to kill the plot after completion.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `InitialiseFolder`

**Signature**

```igorpro
InitialiseFolder()
```

Create and initialize state for a plane-averaged z profile.

### Returns

- **DFREF**: Reference to the resulting data folder.


## `InitialiseGraph`

**Signature**

```igorpro
InitialiseGraph(DFREF dfr)
```

Initialize the graph used by the plane z-profile tool.

Here we will create the profile plot and graph and plot the profile.

### Parameters

- `dfr` *(DFREF)*: Reference to the data folder to inspect or modify.

### Returns

- **Variable**: Zero after completing the operation.


## `CreatePanel`

**Signature**

```igorpro
CreatePanel(DFREF dfr)
```

Create panel.

Not good idea to use it now as long as the "i" options interferes with the ControlBar of the profilert.

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

Window hook function. The line profile is drawn from G to H. Set scale.

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

Dispatches the relevant Igor control event and ignores unsupported event codes.

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


## `OverrideNx`

**Signature**

```igorpro
OverrideNx(STRUCT WMCheckboxAction& cb)
```

Toggle manual override of the x sample count.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `OverrideNy`

**Signature**

```igorpro
OverrideNy(STRUCT WMCheckboxAction& cb)
```

Toggle manual override of the y sample count.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `SetVariableNx`

**Signature**

```igorpro
SetVariableNx(STRUCT WMSetVariableAction& sv)
```

Set variable nx.

SetScale/I y, Ystart, Yend, ww.

### Parameters

- `sv` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetVariableNy`

**Signature**

```igorpro
SetVariableNy(STRUCT WMSetVariableAction& sv)
```

Set variable ny.

SetScale/I x, 0, (normGHCursors * Xfactor), ww.

### Parameters

- `sv` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


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
