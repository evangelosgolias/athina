# ATH_iBackground

**Source file:** `InteractiveInterfaces/ATH_iBackground.ipf`

Module ATH_iBackground.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH iBackground functionality.

```{contents}
:local:
:depth: 2
```

## `CreatelPanel`

**Signature**

```igorpro
CreatelPanel()
```

Create the interactive background-removal panel.

Check if you have already created the panel. We need a 2d or 3d wave. Duplicate the wave for backup.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `GraphHookFunction`

**Signature**

```igorpro
GraphHookFunction(STRUCT WMWinHookStruct &s)
```

Handle panel hook events.

Restore wave scaling here as ImageTransform works better with non-scaled waves.

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

Cleanup when window is closed. Restore wave scaling here as ImageTransform works better with non-scaled
waves CopyScales/I $gATH_wRefBackupPathNameStr, $gATH_wRefPathNameStr.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `OverwriteAndCloseButton`

**Signature**

```igorpro
OverwriteAndCloseButton(STRUCT WMButtonAction &B_Struct)
```

Handle the overwrite and close button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `RemoveBackgroundButton`

**Signature**

```igorpro
RemoveBackgroundButton(STRUCT WMButtonAction &B_Struct)
```

Handle the remove background button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.
