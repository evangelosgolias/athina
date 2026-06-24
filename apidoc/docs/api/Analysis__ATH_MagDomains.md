# ATH_MagDom

**Source file:** `Analysis/ATH_MagDomains.ipf`

Tools for XMLD magnetic-domain analysis and interactive inspection.

This module provides routines for fitting angular XMLD image stacks pixel by
pixel and for interactively inspecting the fitted phase, offset, and amplitude
at selected image positions.

```{contents}
:local:
:depth: 2
```

## `FitXMLDMap`

**Signature**

```igorpro
FitXMLDMap(WAVE wRef, [string fitFunc, variable firstAngle, variable angleStep, int fastFit])
```

Fit an angular XMLD model to every pixel in a 3D image stack.

For each `(row, column)` beam in the 3D input wave, this routine fits an XMLD
angular model along the layer axis and generates three 2D output maps:
phase, offset, and amplitude. By default it uses
`ATH_FuncFit#XMLDCos2xIntensity`.

### Parameters

- `wRef` *(Wave)*: Input 3D wave whose third dimension contains images acquired at different angles.
- `fitFunc` *(String, optional)*: Optional fully qualified fit-function name. Defaults to `ATH_FuncFit#XMLDCos2xIntensity`.
- `firstAngle` *(Variable, optional)*: Optional angle in degrees assigned to the first layer. Defaults to -90.
- `angleStep` *(Variable, optional)*: Optional angular increment in degrees between successive layers. Defaults to 10.
- `fastFit` *(Integer, optional)*: Optional flag controlling the fitting strategy. Non-zero uses one initial phase guess; zero tests multiple initial phases.

### Returns

- **Variable**: Returns 0 on completion. Returns 1 if the input has no layers.

```{note}
Creates output waves named `<input>_map`, `<input>_map_offset`, and `<input>_map_amplitude`.
```


## `InteractiveXMLDFitInspection`

**Signature**

```igorpro
InteractiveXMLDFitInspection(WAVE wSrc, WAVE wRef,[variable firstAngle, variable angleStep])
```

Launch interactive inspection of an XMLD fit map.

Displays the fitted map and opens a companion plot window. Moving cursor `J`
over the image updates the beam profile and overlayed fit curve for the selected pixel.

### Parameters

- `wSrc` *(Wave)*: Source 3D XMLD image stack used to extract beam profiles.
- `wRef` *(Wave)*: 2D phase map produced by `FitXMLDMap`.
- `firstAngle` *(Variable, optional)*: Optional first angle in degrees for the source stack. Defaults to -90.
- `angleStep` *(Variable, optional)*: Optional angle increment in degrees. Defaults to 10.

### Returns

- **Variable**: Returns 0 on completion.


## `iCursorUsingCallbackHookFunction`

**Signature**

```igorpro
iCursorUsingCallbackHookFunction(STRUCT WMWinHookStruct &s)
```

Window hook for interactive XMLD fit inspection.

Handles window close, cursor movement, and keyboard events for the interactive
XMLD inspection workflow.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Struct Igor window hook structure supplied by the event system.

### Returns

- **Variable**: Hook return code. Returns 1 when the event is handled, otherwise 0.


## `CursorCallBack`

**Signature**

```igorpro
CursorCallBack(WAVE wSrc, WAVE wRef, variable p0, variable q0)
```

Update the fit-inspection plot for the selected pixel.

Extracts the beam profile at `(p0, q0)`, reconstructs the fitted angular dependence
from the stored fit maps, and redraws the inspection plot.

### Parameters

- `wSrc` *(Wave)*: Source 3D XMLD image stack.
- `wRef` *(Wave)*: Phase map returned by `FitXMLDMap`.
- `p0` *(Variable)*: Row index of the selected pixel.
- `q0` *(Variable)*: Column index of the selected pixel.

### Returns

- **Variable**: Returns 0 on completion.


## `SortMapPerPolarAngle`

**Signature**

```igorpro
SortMapPerPolarAngle(WAVE wRef, [variable angleRange])
```

Reorder an angular map by increasing polar angle.

### Parameters

- `wRef` *(Wave)*: Angular map whose rows are reordered in place.
- `angleRange` *(Variable, optional)*: Angular interval represented by the map.

### Returns

- **Variable**: Zero after completing the operation.
