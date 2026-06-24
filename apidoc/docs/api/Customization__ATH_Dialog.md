# ATH_Dialog

**Source file:** `Customization/ATH_Dialog.ipf`

Module ATH_Dialog.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Dialog functionality.

```{contents}
:local:
:depth: 2
```

## `GenericSinglePopupStrPrompt`

**Signature**

```igorpro
GenericSinglePopupStrPrompt(string strPrompt, string popupStrSelection, string msgDialog)
```

Prompt for one value chosen from a pop-up list.

### Parameters

- `strPrompt` *(String)*: Prompt text shown beside the input control.
- `popupStrSelection` *(String)*: Semicolon-separated choices for the pop-up control.
- `msgDialog` *(String)*: Title or explanatory text for the prompt dialog.

### Returns

- **String**: The selected pop-up item, or an empty string if the dialog is cancelled.


## `GenericSingleStrPrompt`

**Signature**

```igorpro
GenericSingleStrPrompt(string strPrompt, string msgDialog)
```

Prompt for one text value.

### Parameters

- `strPrompt` *(String)*: Prompt text shown beside the input control.
- `msgDialog` *(String)*: Title or explanatory text for the prompt dialog.

### Returns

- **String**: The entered text, or an empty string if the dialog is cancelled.


## `GenericSingleStrPromptAndPopup`

**Signature**

```igorpro
GenericSingleStrPromptAndPopup(string strPrompt1,string strPrompt2, string popupStrSelection1, string msgDialog)
```

Prompt for one pop-up selection and one text value.

### Parameters

- `strPrompt1` *(String)*: Prompt text for the first value.
- `strPrompt2` *(String)*: Prompt text for the second value.
- `popupStrSelection1` *(String)*: Choices for the first pop-up control.
- `msgDialog` *(String)*: Title or explanatory text for the prompt dialog.

### Returns

- **Multiple values**: The entered text and the selected pop-up item.


## `GenericDoubleStrPromptPopup`

**Signature**

```igorpro
GenericDoubleStrPromptPopup(string strPrompt1, string strPrompt2, string popupStrSelection1, string popupStrSelection2, string msgDialog)
```

Prompt for two values chosen from pop-up lists.

### Parameters

- `strPrompt1` *(String)*: Prompt text for the first value.
- `strPrompt2` *(String)*: Prompt text for the second value.
- `popupStrSelection1` *(String)*: Choices for the first pop-up control.
- `popupStrSelection2` *(String)*: Choices for the second pop-up control.
- `msgDialog` *(String)*: Title or explanatory text for the prompt dialog.

### Returns

- **Multiple values**: The two selected pop-up items.


## `GenericDoubleStrPrompt`

**Signature**

```igorpro
GenericDoubleStrPrompt(string strPrompt1, string strPrompt2, string msgDialog)
```

Prompt for two text values.

### Parameters

- `strPrompt1` *(String)*: Prompt text for the first value.
- `strPrompt2` *(String)*: Prompt text for the second value.
- `msgDialog` *(String)*: Title or explanatory text for the prompt dialog.

### Returns

- **Multiple values**: The two entered text values.


## `SelectWavesInModalDataBrowser`

**Signature**

```igorpro
SelectWavesInModalDataBrowser(string msg)
```

Open a modal Data Browser and return the selected waves.

### Parameters

- `msg` *(String)*: Message displayed to the user.

### Returns

- **String**: A semicolon-separated list of selected wave paths, or an empty string if none are selected.


## `CountSelectedObjectsInDataBrowser`

**Signature**

```igorpro
CountSelectedObjectsInDataBrowser()
```

Count all objects selected in the Data Browser.

Return how many objects of any kind you have selected in the data browser.

### Returns

- **Variable**: The number of matching items.


## `CountSelectedWavesInDataBrowser`

**Signature**

```igorpro
CountSelectedWavesInDataBrowser([variable wDim])
```

Count waves selected in the Data Browser, optionally by dimensionality.

Return how many waves are selected in the data browser. Function returns selected waves of dimensionality
wDims.

### Parameters

- `wDim` *(Variable, optional)*: Wave dimensionality to require; zero counts waves of any dimensionality.

### Returns

- **Variable**: The number of matching items.


## `GetSelectedWavesInDataBrowser`

**Signature**

```igorpro
GetSelectedWavesInDataBrowser([variable wDim])
```

Return waves selected in the Data Browser, optionally filtered by dimensionality.

### Parameters

- `wDim` *(Variable, optional)*: Required wave dimensionality; zero accepts any dimensionality.

### Returns

- **String**: A semicolon-separated list of selected wave paths matching the dimensionality filter.


## `WaitForUserActions`

**Signature**

```igorpro
WaitForUserActions(STRUCT sUserMarqueePositions &s, [variable vWinType])
```

Open a modal panel and wait for the user to continue or cancel.

### Parameters

- `s` *(STRUCT sUserMarqueePositions)*: Input/output structure carrying the operation's settings and results.
- `vWinType` *(Variable, optional)*: Igor window-type code used to choose the parent window; defaults to a graph.

### Returns

- **Variable**: One if the user cancels; zero if the user continues.


## `WaitForUserActions_ContButtonProc`

**Signature**

```igorpro
WaitForUserActions_ContButtonProc(STRUCT WMButtonAction &B_Struct)
```

Handle the continue button in the modal user-action panel.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `WaitForUserActions_CancelBProc`

**Signature**

```igorpro
WaitForUserActions_CancelBProc(STRUCT WMButtonAction &B_Struct)
```

Handle the cancel button in the modal user-action panel.

End of wait to complete operations.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.
