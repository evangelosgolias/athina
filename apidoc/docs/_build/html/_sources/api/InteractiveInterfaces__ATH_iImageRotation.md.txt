# ATH_iImageRotation

**Source file:** `InteractiveInterfaces/ATH_iImageRotation.ipf`

Module ATH_iImageRotation.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH iImageRotation functionality.

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

Check if you have already created the panel. Duplicate the wave for backup. Create the global variables
for panel.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `FlipRowsCheckBox`

**Signature**

```igorpro
FlipRowsCheckBox(STRUCT WMCheckboxAction& cb)
```

Handle the flip rows checkbox action.

Added 17.06.2026. That's ugly.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `GraphHookFunction`

**Signature**

```igorpro
GraphHookFunction(STRUCT WMWinHookStruct &s)
```

Handle panel hook events.

Dispatches the relevant Igor control event and ignores unsupported event codes.

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


## `SliderProc`

**Signature**

```igorpro
SliderProc(STRUCT WMSliderAction &sa)
```

Handle changes to the panel slider.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sa` *(STRUCT WMSliderAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetAngle`

**Signature**

```igorpro
SetAngle(STRUCT WMSetVariableAction &sva)
```

Set angle.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sva` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `iRotButton`

**Signature**

```igorpro
iRotButton(STRUCT WMButtonAction &ba)
```

Handle the i rot button action.

Creates a separate result wave, leaving the input wave available to the caller.

### Parameters

- `ba` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `ImageRestoreAndRotate`

**Signature**

```igorpro
ImageRestoreAndRotate(WAVE source, WAVE dest, variable angle, [int flipY])
```

Image restore and rotate.

Rotate dest, restore source.

### Parameters

- `source` *(Wave)*: Source wave, path, or coordinate array.
- `dest` *(Wave)*: Destination wave, path, or coordinate array.
- `angle` *(Variable)*: Angle.
- `flipY` *(Integer, optional)*: If nonzero, flip the result along y.

### Returns

- **Variable**: Zero after completing the operation.
