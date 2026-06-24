# ATH_iImageOps

**Source file:** `InteractiveInterfaces/ATH_iImageOps.ipf`

Module ATH_iImageOps.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH iImageOps functionality.

```{contents}
:local:
:depth: 2
```

## `MainMenu`

**Signature**

```igorpro
MainMenu()
```

Launch the interactive two-image operations workflow.

Static Function to interactively drift images and get an updated graph of the XMC(L)D contrast.
S_fileName is a carriage-return-separated list of full paths to one or more files.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `CreateiOpsImgsCalculationPanel`

**Signature**

```igorpro
CreateiOpsImgsCalculationPanel(WAVE wOpResult)
```

Create the interactive two-image calculation panel.

### Parameters

- `wOpResult` *(Wave)*: that receives the operation result.

### Returns

- **Variable**: Zero after completing the operation.


## `WindowHook`

**Signature**

```igorpro
WindowHook(STRUCT WMWinHookStruct &s)
```

Handle window hook events.

Duplicate/O w2_undo, $wName2Str + " dy:" + num2str(gATH_dy) + " of " + wName2Str. Note w2, note2ImgStr.

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


## `SaveOpResultButton`

**Signature**

```igorpro
SaveOpResultButton(STRUCT WMButtonAction &B_Struct)
```

Handle the save op result button action.

Dispatches the relevant Igor control event and ignores unsupported event codes.

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


## `SetOpFormula`

**Signature**

```igorpro
SetOpFormula(STRUCT WMSetVariableAction &sva)
```

Store the primary image-operation formula selected in the panel.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sva` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `SetSecOpFormula`

**Signature**

```igorpro
SetSecOpFormula(STRUCT WMSetVariableAction &sva)
```

Store the optional secondary image-operation formula.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `sva` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `CheckBoxSecOp`

**Signature**

```igorpro
CheckBoxSecOp(STRUCT WMCheckboxAction& cb)
```

Enable or disable the secondary image operation.

Create the twinwave plot.

### Parameters

- `cb` *(STRUCT WMCheckboxAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.
