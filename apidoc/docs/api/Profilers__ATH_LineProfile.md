# ATH_LineProfile

**Source file:** `Profilers/ATH_LineProfile.ipf`

Module ATH_LineProfile.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH LineProfile functionality.

```{contents}
:local:
:depth: 2
```

## `MainMenu`

**Signature**

```igorpro
MainMenu()
```

Description of MainMenu.

Auto-generated documentation stub for function `MainMenu`.

### Returns

- **Variable**: Return value.


## `InitialiseGraph`

**Signature**

```igorpro
InitialiseGraph(DFREF dfr)
```

Description of InitialiseGraph.

Auto-generated documentation stub for function `InitialiseGraph`.

### Parameters

- `dfr` *(Parameter)*: dfr.

### Returns

- **Variable**: Return value.


## `CreatePlot`

**Signature**

```igorpro
CreatePlot(DFREF dfr)
```

Description of CreatePlot.

Auto-generated documentation stub for function `CreatePlot`.

### Parameters

- `dfr` *(Parameter)*: dfr.

### Returns

- **Variable**: Return value.


## `ClearLineMarkings`

**Signature**

```igorpro
ClearLineMarkings(string winNameStr)
```

Description of ClearLineMarkings.

Auto-generated documentation stub for function `ClearLineMarkings`.

### Parameters

- `winNameStr` *(Parameter)*: winNameStr.

### Returns

- **Variable**: Return value.


## `DrawLineUserFront`

**Signature**

```igorpro
DrawLineUserFront(string winNameStr, variable x0, variable y0, variable x1, variable y1, variable red, variable green, variable blue)
```

Description of DrawLineUserFront.

Auto-generated documentation stub for function `DrawLineUserFront`.

### Parameters

- `winNameStr` *(Parameter)*: winNameStr.
- `x0` *(Parameter)*: x0.
- `y0` *(Parameter)*: y0.
- `x1` *(Parameter)*: x1.
- `y1` *(Parameter)*: y1.
- `red` *(Parameter)*: red.
- `green` *(Parameter)*: green.
- `blue` *(Parameter)*: blue.

### Returns

- **Variable**: Return value.


## `CursorsHookFunction`

**Signature**

```igorpro
CursorsHookFunction(STRUCT WMWinHookStruct &s)
```

Description of CursorsHookFunction.

Auto-generated documentation stub for function `CursorsHookFunction`.

### Parameters

- `&s` *(Parameter)*: &s.

### Returns

- **Variable**: Return value.


## `GraphHookFunction`

**Signature**

```igorpro
GraphHookFunction(STRUCT WMWinHookStruct &s)
```

Description of GraphHookFunction.

Auto-generated documentation stub for function `GraphHookFunction`.

### Parameters

- `&s` *(Parameter)*: &s.

### Returns

- **Variable**: Return value.


## `SaveProfile`

**Signature**

```igorpro
SaveProfile(STRUCT WMButtonAction &B_Struct)
```

Description of SaveProfile.

Auto-generated documentation stub for function `SaveProfile`.

### Parameters

- `&B_Struct` *(Parameter)*: &B_Struct.

### Returns

- **Variable**: Return value.


## `SaveDefaultSettings`

**Signature**

```igorpro
SaveDefaultSettings(STRUCT WMButtonAction &B_Struct)
```

Description of SaveDefaultSettings.

Auto-generated documentation stub for function `SaveDefaultSettings`.

### Parameters

- `&B_Struct` *(Parameter)*: &B_Struct.

### Returns

- **Variable**: Return value.


## `RestoreDefaultSettings`

**Signature**

```igorpro
RestoreDefaultSettings(STRUCT WMButtonAction &B_Struct)
```

Description of RestoreDefaultSettings.

Auto-generated documentation stub for function `RestoreDefaultSettings`.

### Parameters

- `&B_Struct` *(Parameter)*: &B_Struct.

### Returns

- **Variable**: Return value.


## `ShowProfileWidth`

**Signature**

```igorpro
ShowProfileWidth(STRUCT WMButtonAction &B_Struct)
```

Description of ShowProfileWidth.

Auto-generated documentation stub for function `ShowProfileWidth`.

### Parameters

- `&B_Struct` *(Parameter)*: &B_Struct.

### Returns

- **Variable**: Return value.


## `CheckboxPlotProfile`

**Signature**

```igorpro
CheckboxPlotProfile(STRUCT WMCheckboxAction& cb)
```

Description of CheckboxPlotProfile.

Auto-generated documentation stub for function `CheckboxPlotProfile`.

### Parameters

- `cb` *(Parameter)*: cb.

### Returns

- **Variable**: Return value.


## `ProfileLayer3D`

**Signature**

```igorpro
ProfileLayer3D(STRUCT WMCheckboxAction& cb)
```

Description of ProfileLayer3D.

Auto-generated documentation stub for function `ProfileLayer3D`.

### Parameters

- `cb` *(Parameter)*: cb.

### Returns

- **Variable**: Return value.


## `CheckboxMarkLines`

**Signature**

```igorpro
CheckboxMarkLines(STRUCT WMCheckboxAction& cb)
```

Description of CheckboxMarkLines.

Auto-generated documentation stub for function `CheckboxMarkLines`.

### Parameters

- `cb` *(Parameter)*: cb.

### Returns

- **Variable**: Return value.


## `SetVariableWidth`

**Signature**

```igorpro
SetVariableWidth(STRUCT WMSetVariableAction& sv)
```

Description of SetVariableWidth.

Auto-generated documentation stub for function `SetVariableWidth`.

### Parameters

- `sv` *(Parameter)*: sv.

### Returns

- **Variable**: Return value.


## `DeleleLineProfileRectangle`

**Signature**

```igorpro
DeleleLineProfileRectangle(string grfName)
```

Description of DeleleLineProfileRectangle.

Auto-generated documentation stub for function `DeleleLineProfileRectangle`.

### Parameters

- `grfName` *(Parameter)*: grfName.

### Returns

- **Variable**: Return value.
