# ATH_iXPS

**Source file:** `InteractiveInterfaces/ATH_iXPS.ipf`

Module ATH_iXPS.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH iXPS functionality.

```{contents}
:local:
:depth: 2
```

## `MainMenu`

**Signature**

```igorpro
MainMenu()
```

Launch the interactive XPS profiling workflow from the active image.

Cursors to set the scale. Cursors to get the profile.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `InitialiseFolder`

**Signature**

```igorpro
InitialiseFolder(string winNameStr)
```

Create the data folder and state used by an interactive XPS profile window.

### Parameters

- `winNameStr` *(String)*: Name of the target graph or panel window.

### Returns

- **DFREF**: Reference to the resulting data folder.


## `InitialiseGraph`

**Signature**

```igorpro
InitialiseGraph(DFREF dfr)
```

Initialize the graph used by the interactive XPS profiler.

Here we will create the profile plot and graph and plot the profile.

### Parameters

- `dfr` *(DFREF)*: Reference to the data folder to inspect or modify.

### Returns

- **Variable**: Zero after completing the operation.


## `XPSPlot`

**Signature**

```igorpro
XPSPlot(DFREF dfr)
```

Create or update the interactive XPS profile plot.

Let's set SaveProfileButton to red if nothing is set or green otherwise.

### Parameters

- `dfr` *(DFREF)*: Reference to the data folder to inspect or modify.

### Returns

- **Variable**: Zero after completing the operation.


## `ClearXPSMarkings`

**Signature**

```igorpro
ClearXPSMarkings()
```

Clear cursor and width markings used by the XPS profiler.

### Returns

- **Variable**: Zero after completing the operation.


## `CursorHookFunction`

**Signature**

```igorpro
CursorHookFunction(STRUCT WMWinHookStruct &s)
```

Handle cursor hook events.

Window hook function. The XPS profile is plotted from E to F. Activate window, e.g after pressing
"Restore Settings".

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

Window is about to be killed. When using case 2 then I cannot KillWindow and KillDataFolder. See the
discussion with Wavemetrics. If you want to use case 2, then you need to invoke. Execute/P cmdStr. I do
not see any issue in using here case 17 (14.12.2023).

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

String and wave references. Numeric variables from the data folder. It has to come first, it is used to
scale to BE.

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

From main data folder. From default settings folder.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `RestoreDefaultSettings`

**Signature**

```igorpro
RestoreDefaultSettings(STRUCT WMButtonAction &B_Struct)
```

Restore default settings.

Current settings. Default settings. Use the same local variables for the second line.

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


## `PlotProfile`

**Signature**

```igorpro
PlotProfile(STRUCT WMCheckboxAction& cb)
```

Plot profile.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `Layer3D`

**Signature**

```igorpro
Layer3D(STRUCT WMCheckboxAction& cb)
```

Layer 3D.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `SetProfileWidth`

**Signature**

```igorpro
SetProfileWidth(STRUCT WMSetVariableAction& sv)
```

Set profile width.

Numeric variables. String and wave references. Local variables.

### Parameters

- `sv` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `SetCursorsGH`

**Signature**

```igorpro
SetCursorsGH(STRUCT WMButtonAction &B_Struct): ButtonControl)
```

Set the profile cursors from the stored graph coordinates.

Numeric variables. Use the same local variables for the second line. Draw the midpoint using the same
lcoal variable.

### Parameters

- `ButtonControl` *(STRUCT WMButtonAction &B_Struct):)*

### Returns

- **Variable**: Zero after completing the operation.


## `UseBE`

**Signature**

```igorpro
UseBE(STRUCT WMCheckboxAction& cb)
```

Use binding energy.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `Sethv`

**Signature**

```igorpro
Sethv(STRUCT WMSetVariableAction& sv)
```

Set photon energy.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sv` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `SetWf`

**Signature**

```igorpro
SetWf(STRUCT WMSetVariableAction& sv)
```

Set work function.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sv` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `SetEPP`

**Signature**

```igorpro
SetEPP(STRUCT WMSetVariableAction& sv)
```

Set energy per point.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sv` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `SetSTV`

**Signature**

```igorpro
SetSTV(STRUCT WMSetVariableAction& sv)
```

Set stv.

This is used to for waves selected in the DB, not here.

### Parameters

- `sv` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `GetProfileUsingDefaults`

**Signature**

```igorpro
GetProfileUsingDefaults(WAVE wRef, [variable BEscaleQ])
```

Return profile using defaults.

Get a profile from wRef using the default saved settings.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `BEscaleQ` *(Variable, optional)*: B escale q.

### Returns

- **Variable**: The profile using defaults.
