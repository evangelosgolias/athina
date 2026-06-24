# ATH_XPSBackgroundRemoval

**Source file:** `Analysis/ATH_XPSBackgroundRemoval.ipf`

```{contents}
:local:
:depth: 2
```

## `BackRemoveInitialize`

**Signature**

```igorpro
BackRemoveInitialize(bs)
```

Initialize background removal for a selected spectrum.

### Parameters

- `bs` *(Variable)*: Background-model settings structure.

### Returns

- **Variable**: Zero after completing the operation.


## `GenerateBackground`

**Signature**

```igorpro
GenerateBackground(s, inwave, backwave, [from, to])
```

Generate a background wave from the current removal settings.

### Parameters

- `s` *(Variable)*: Background-calculation settings structure.
- `inwave` *(Variable)*: Input spectrum wave.
- `backwave` *(Variable)*: Wave that receives the calculated background.
- `from` *(Variable, optional)*: Lower x coordinate of the background range.
- `to` *(Variable, optional)*: Upper x coordinate of the background range.

### Returns

- **String**: An empty string on success; otherwise a message describing invalid input or calculation failure.


## `BackgroundSubtractGUI`

**Signature**

```igorpro
BackgroundSubtractGUI() //BackgroundSubtractGUI(inwave)
```

Launch the interactive XPS background-subtraction panel.

### Parameters

- `inwave` *() //BackgroundSubtractGUI()*

### Returns

- **Variable**: Zero after opening the panel; a negative value if the input wave is invalid.


## `getWorkFolder`

**Signature**

```igorpro
getWorkFolder(gName)
```

Return the package data folder used by background removal.

### Parameters

- `gName` *(Variable)*: Name of the background-removal graph window.

### Returns

- **DFREF**: Reference to the resulting data folder.


## `BackRem_WindowHook`

**Signature**

```igorpro
BackRem_WindowHook(s)
```

Handle window events for the XPS background-removal graph.

### Parameters

- `s` *(Variable)*: Igor window-hook event structure.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `BackRem_InitLoadSettings`

**Signature**

```igorpro
BackRem_InitLoadSettings(bs, inwave, gName)
```

Initialize the background-removal panel from defaults or saved wave settings.

### Parameters

- `bs` *(Variable)*: Background-model settings structure.
- `inwave` *(Variable)*: Input spectrum wave.
- `gName` *(Variable)*: Name of the background-removal graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `BackRem_SwitchModeControls`

**Signature**

```igorpro
BackRem_SwitchModeControls(mode, gName)
```

Show the controls required by the selected background model.

### Parameters

- `mode` *(Variable)*: Operation mode selector.
- `gName` *(Variable)*: Name of the background-removal graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `BackRem_ModeSelect`

**Signature**

```igorpro
BackRem_ModeSelect(s)
```

Handle selection of a background model.

### Parameters

- `s` *(Variable)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `BackRem_CheckAction`

**Signature**

```igorpro
BackRem_CheckAction(s)
```

Recalculate the background after a checkbox change.

### Parameters

- `s` *(Variable)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `BackRem_CSWaveSelect`

**Signature**

```igorpro
BackRem_CSWaveSelect(s)
```

Recalculate the background after selecting a cross-section wave.

### Parameters

- `s` *(Variable)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `BackRem_CSWaveList`

**Signature**

```igorpro
BackRem_CSWaveList()
```

Return the one-dimensional waves available as scattering cross sections.

### Returns

- **String**: A semicolon-separated list of one-dimensional waves.


## `BackRem_ButtonAction`

**Signature**

```igorpro
BackRem_ButtonAction(STRUCT WMButtonAction &s)
```

Handle subtract, undo, save, and close actions in the background-removal panel.

### Parameters

- `s` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `BackRem_VarChange`

**Signature**

```igorpro
BackRem_VarChange(s)
```

Update cursors or recalculate the background after a control value changes.

### Parameters

- `s` *(Variable)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `BackRem_UpdateCursorControls`

**Signature**

```igorpro
BackRem_UpdateCursorControls(mainCur, subCur, gName)
```

Write the current cursor positions into the panel controls.

### Parameters

- `mainCur` *(Variable)*: Primary cursor x coordinate.
- `subCur` *(Variable)*: Secondary cursor x coordinate.
- `gName` *(Variable)*: Name of the background-removal graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `BackRem_ReadAllPanelSettings`

**Signature**

```igorpro
BackRem_ReadAllPanelSettings(info, gName)
```

Read all panel controls into a background-model settings structure.

### Parameters

- `info` *(Variable)*: Structure receiving all settings read from the background-removal panel.
- `gName` *(Variable)*: Name of the background-removal graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `BackRem_BackCalc`

**Signature**

```igorpro
BackRem_BackCalc(gName)
```

Recalculate the background and net spectrum for the current panel state.

### Parameters

- `gName` *(Variable)*: Name of the background-removal graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `GetCursorLoc`

**Signature**

```igorpro
GetCursorLoc(mainCur,subCur, gName)
```

Return a cursor's x coordinate in the background-removal graph.

### Parameters

- `mainCur` *(Variable)*: Primary cursor x coordinate.
- `subCur` *(Variable)*: Secondary cursor x coordinate.
- `gName` *(Variable)*: Name of the background-removal graph window.

### Returns

- **Variable**: The requested cursor x coordinate.
