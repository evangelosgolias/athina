# ATH_iDriftCorrection

**Source file:** `InteractiveInterfaces/ATH_iDriftCorrection.ipf`

Module ATH_iDriftCorrection.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH iDriftCorrection functionality.

```{contents}
:local:
:depth: 2
```

## `CreatePanel`

**Signature**

```igorpro
CreatePanel()
```

Create panel.

Check if you have already created the panel. When autoscaled then SETAXISCMD is SetAxis/A. Duplicate the
wave for backup.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `GraphHookFunction`

**Signature**

```igorpro
GraphHookFunction(STRUCT WMWinHookStruct &s)
```

Handle panel hook events.

Cleanup when window is closed. Same behavior with /F or not.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `PanelHookFunction`

**Signature**

```igorpro
PanelHookFunction(STRUCT WMWinHookStruct &s)
```

Handle panel hook events.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetAnchorCursorButton`

**Signature**

```igorpro
SetAnchorCursorButton(STRUCT WMButtonAction &B_Struct)
```

Handle the set anchor cursor button action.

String variables. Wave and numeric variables. Image dimensions.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `DriftImageButton`

**Signature**

```igorpro
DriftImageButton(STRUCT WMButtonAction &B_Struct)
```

Handle the drift image button action.

String variables. Wave references. Numeric variables.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `ToggleSubPixelModeButton`

**Signature**

```igorpro
ToggleSubPixelModeButton(STRUCT WMButtonAction &B_Struct)
```

Handle the toggle sub pixel mode button action.

String variables. Wave reference. Numeric variables.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetStartLayerButton`

**Signature**

```igorpro
SetStartLayerButton(STRUCT WMButtonAction &B_Struct)
```

Handle the set start layer button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetEndLayerButton`

**Signature**

```igorpro
SetEndLayerButton(STRUCT WMButtonAction &B_Struct)
```

Handle the set end layer button action.

String variable. External numeric variable. Numeric variables from dfr.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `LinearDCButton`

**Signature**

```igorpro
LinearDCButton(STRUCT WMButtonAction &B_Struct)
```

Handle the linear dc button action.

Relative s, y shifts for Drift Correction ImageInterpolate needs pixels, multiply by -1 to have the
proper behavior in /ARPM={...}.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `CheckpointButton`

**Signature**

```igorpro
CheckpointButton(STRUCT WMButtonAction &B_Struct)
```

Handle the checkpoint button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `RestoreWaveButton`

**Signature**

```igorpro
RestoreWaveButton(STRUCT WMButtonAction &B_Struct)
```

Handle the restore wave button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `DriftSelectedLayers3DWaveButton`

**Signature**

```igorpro
DriftSelectedLayers3DWaveButton(STRUCT WMButtonAction &B_Struct)
```

Handle the drift selected layers 3D wave button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `CascadeDrift3DWaveButton`

**Signature**

```igorpro
CascadeDrift3DWaveButton(STRUCT WMButtonAction &B_Struct)
```

Handle the cascade drift 3D wave button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `FastModeCheckbox`

**Signature**

```igorpro
FastModeCheckbox(STRUCT WMCheckboxAction& cb)
```

Handle the fast mode checkbox action.

DrawTheRefCross(w3dRef,gATH_AnchorPositionX, gATH_AnchorPositionY,grfName=gATH_WindowNameStr). Copy code
here. When autoscaled then SETAXISCMD is SetAxis/A.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `InterStackAlignmentButton`

**Signature**

```igorpro
InterStackAlignmentButton(STRUCT WMButtonAction &B_Struct)
```

Handle the inter stack alignment button action.

Fast exit if not eventCode is not 2 NB: Save coordinates in pixels! We shouldn't depend on wave scaling.
Reference should be relative, between 0 and 1 as the number of pixels and scale might be different.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `DrawTheRefCross`

**Signature**

```igorpro
DrawTheRefCross(WAVE wRef, variable xv, variable yv, [string grfName, int axisRel])
```

Draw the ref cross.

Draw the ref line.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `xv` *(Variable)*: X-coordinate value or wave.
- `yv` *(Variable)*: Y-coordinate value or wave.
- `grfName` *(String, optional)*: Name of the graph window.
- `axisRel` *(Integer, optional)*: If nonzero, interpret coordinates relative to the graph axes.

### Returns

- **Variable**: Zero after completing the operation.
