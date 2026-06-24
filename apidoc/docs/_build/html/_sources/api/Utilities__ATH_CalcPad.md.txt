# ATH_CalcPad

**Source file:** `Utilities/ATH_CalcPad.ipf`

Module ATH_CalcPad.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH CalcPad functionality.

```{contents}
:local:
:depth: 2
```

## `PrefsSetDefaults`

**Signature**

```igorpro
PrefsSetDefaults(STRUCT PackagePrefs &prefs)
```

Initialize calculator preferences with their default values.

### Parameters

- `prefs` *(STRUCT PackagePrefs)*: Input/output structure carrying the operation's settings and results.

### Returns

- **Variable**: Zero after completing the operation.


## `LoadPrefs`

**Signature**

```igorpro
LoadPrefs(STRUCT PackagePrefs &prefs)
```

Load prefs.

### Parameters

- `prefs` *(STRUCT PackagePrefs)*: Input/output structure carrying the operation's settings and results.

### Returns

- **Variable**: Zero after completing the operation.


## `CalcPad`

**Signature**

```igorpro
CalcPad()
```

Create or bring forward the calculator pad.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `CalcPadHook`

**Signature**

```igorpro
CalcPadHook(STRUCT WMWinHookStruct &H_Struct)
```

Handle calc pad hook events.

Make sure that we're typing on the last line store position find last paragraph.

### Parameters

- `H_Struct` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `PreventPaste`

**Signature**

```igorpro
PreventPaste()
```

Prevent paste.

Store position find last paragraph restore current position.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `SaveWindow`

**Signature**

```igorpro
SaveWindow(string strWin)
```

Save window.

Save window position save window magnification.

### Parameters

- `strWin` *(String)*: Name of the target window.

### Returns

- **Variable**: Zero after completing the operation.


## `makePrefsPanel`

**Signature**

```igorpro
makePrefsPanel()
```

Create the calculator preferences panel.

### Returns

- **Variable**: Zero after completing the operation.


## `ButtonProc`

**Signature**

```igorpro
ButtonProc(STRUCT WMButtonAction &s)
```

Handle the continue button for the panel.

Reset controls.

### Parameters

- `s` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `CheckProc`

**Signature**

```igorpro
CheckProc(STRUCT WMCheckboxAction &cba)
```

Handle the panel checkbox action.

### Parameters

- `cba` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetVarProc`

**Signature**

```igorpro
SetVarProc(STRUCT WMSetVariableAction &sva)
```

Handle changes to the panel set-variable control.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sva` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `PopMenuProc`

**Signature**

```igorpro
PopMenuProc(STRUCT WMPopupAction &pa)
```

Handle the panel pop-up menu action.

### Parameters

- `pa` *(STRUCT WMPopupAction)*: Igor control-action structure.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.
