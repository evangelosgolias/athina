# ATH_Windows

**Source file:** `Graphs/ATH_Windows.ipf`

Module ATH_Windows.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Windows functionality.

```{contents}
:local:
:depth: 2
```

## `GetListOfNamedWindowHookFunctions`

**Signature**

```igorpro
GetListOfNamedWindowHookFunctions([string winNameStr, string hookFuncNameStr])
```

List named hook functions installed on a window.

### Parameters

- `winNameStr` *(String, optional)*: Name of the target graph or panel window.
- `hookFuncNameStr` *(String, optional)*: hook-function name used to filter the result.

### Returns

- **String**: A semicolon-separated list of matching named hook functions.


## `SetNamedHookFunctionToWindow`

**Signature**

```igorpro
SetNamedHookFunctionToWindow(string hookFuncNameStr, string hookFuncStr, [string grfName])
```

Set named hook function to window.

Set the the named hook function hookFuncStr as hook(hookFuncNameStr) at grfName (TG if default).

### Parameters

- `hookFuncNameStr` *(String)*: Hook func name str.
- `hookFuncStr` *(String)*: Text containing the hook func str.
- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `WindowNameOfDisplayedImageWaveRef`

**Signature**

```igorpro
WindowNameOfDisplayedImageWaveRef(WAVE wRef)
```

Find the image window displaying a specified wave.

### Parameters

- `wRef` *(Wave)*: Image wave to locate in open graph windows.

### Returns

- **String**: The matching image-window name, or an empty string if the wave is not displayed.


## `KillWindowsInListString`

**Signature**

```igorpro
KillWindowsInListString(string windowsListStr)
```

Remove windows in list string.

Kill all windows in winListstr (;).

### Parameters

- `windowsListStr` *(String)*: Text containing the windows list str.

### Returns

- **Variable**: Zero after completing the operation.
