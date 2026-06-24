# ATH_iXMCD

**Source file:** `InteractiveInterfaces/ATH_iXMCD.ipf`

Module ATH_iXMCD.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH iXMCD functionality.

```{contents}
:local:
:depth: 2
```

## `MenuLaunch`

**Signature**

```igorpro
MenuLaunch()
```

Launch the interactive XMCD workflow from the active image stack.

Function to interactively drift images and get an updated graph of the XMC(L)D contrast. S_fileName is a
carriage-return-separated list of full paths to one or more files.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `CreateiXMCDPanel`

**Signature**

```igorpro
CreateiXMCDPanel(WAVE wXMCD)
```

Create the interactive XMCD calculation panel.

Set the path to all windows.

### Parameters

- `wXMCD` *(Wave)*: Destination wave for the XMCD result.

### Returns

- **Variable**: Zero after completing the operation.


## `iXMCDWindowHook`

**Signature**

```igorpro
iXMCDWindowHook(STRUCT WMWinHookStruct &s)
```

Handle events from the interactive XMCD graph window.

Window is about to be killed case 17. Needed if you want more than one hook functions to be able to
cleanup/close windows linked a parent window.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `RestoreImagesButton`

**Signature**

```igorpro
RestoreImagesButton(STRUCT WMButtonAction &B_Struct)
```

Handle the restore images button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SaveXMCDImageButton`

**Signature**

```igorpro
SaveXMCDImageButton(STRUCT WMButtonAction &B_Struct)
```

Save the current XMCD result when the panel button is pressed.

Gather metadata.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `SetDriftStepVar`

**Signature**

```igorpro
SetDriftStepVar(STRUCT WMSetVariableAction &sva)
```

Set drift step var.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sva` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `SetIntensityScale`

**Signature**

```igorpro
SetIntensityScale(STRUCT WMSetVariableAction &sva)
```

Set intensity scale.

Here get the old factor and calculate the next to avoid duplications. Give info about the ratio of
signals in marquee if present. Grab normalisation region.

### Parameters

- `sva` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.
