# ATH_Graph

**Source file:** `Graphs/ATH_Graph.ipf`

Module ATH_Graph.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Graph functionality.

```{contents}
:local:
:depth: 2
```

## `DuplicateWaveAndDisplayOfTopImage`

**Signature**

```igorpro
DuplicateWaveAndDisplayOfTopImage([string grfName])
```

Duplicate the top image wave and display the copy in a new graph.

Duplicate the graph of an image (2d, 3d wave) along with the wave at its data folder (not cwd). Function
DuplicateTopImage([string grfName]).

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `TextAnnotationOnTopGraph`

**Signature**

```igorpro
TextAnnotationOnTopGraph(string text, [variable fSize, string color])
```

Add a text annotation to the active graph.

Add text on the top graph. Optionally you can set fSize and text color. Defaults are fSize = 12 and color
= black. Block using winNameStr.

### Parameters

- `text` *(String)*: Text to display or process.
- `fSize` *(Variable, optional)*: F size.
- `color` *(String, optional)*: Color specification.

### Returns

- **Variable**: Zero after completing the operation.


## `GetColor`

**Signature**

```igorpro
GetColor(variable colorIndex)
```

Return the RGB triplet for a standard trace-color index.

### Parameters

- `colorIndex` *(Variable)*: Zero-based index into the standard trace-color palette.

### Returns

- **Multiple values**: The red, green, and blue values for the selected palette index.


## `GetgLayer`

**Signature**

```igorpro
GetgLayer(string grfName)
```

Return the displayed layer index for a 3D image wave.

Returns the /P=num plane displayed in windowNameStr.

### Parameters

- `grfName` *(String)*: Name of the graph window.

### Returns

- **Variable**: The zero-based index, or a negative value when no match is found.


## `GetAxes`

**Signature**

```igorpro
GetAxes([string grfName])
```

Return the x and y axes used by a graph image.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Multiple values**: The horizontal and vertical axis names used by the graph image.


## `GetGraphCtabStr`

**Signature**

```igorpro
GetGraphCtabStr([string grfName])
```

Return the color-table portion of an image recreation string.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **String**: The image's `ctab` recreation-string field, or an empty string if unavailable.


## `SetGraphCtabStr`

**Signature**

```igorpro
SetGraphCtabStr(string ctabStr, [string grfName])
```

Apply an Igor color-table recreation string to a graph image.

### Parameters

- `ctabStr` *(String)*: Text containing the color table str.
- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `AxisValToRel2D`

**Signature**

```igorpro
AxisValToRel2D(WAVE w, variable xv, variable yv)
```

Convert image-axis coordinates to relative graph coordinates.

### Parameters

- `w` *(Wave)*: Displayed image wave used to resolve graph axes and bounds.
- `xv` *(Variable)*: X-axis coordinate.
- `yv` *(Variable)*: Y-axis coordinate.

### Returns

- **Multiple values**: The relative x and y coordinates in the graph image rectangle.


## `RelToAxisVal2D`

**Signature**

```igorpro
RelToAxisVal2D(WAVE w, variable xr, variable yr)
```

Convert relative graph coordinates to image-axis coordinates.

### Parameters

- `w` *(Wave)*: Displayed image wave used to resolve graph axes and bounds.
- `xr` *(Variable)*: Relative x coordinate in the range 0–1.
- `yr` *(Variable)*: Relative y coordinate in the range 0–1.

### Returns

- **Multiple values**: The corresponding x and y graph-axis values.


## `TopImageToWaveRef`

**Signature**

```igorpro
TopImageToWaveRef([string grfName])
```

Return a reference to the top image in a graph.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `TopImageName`

**Signature**

```igorpro
TopImageName([string grfName])
```

Return the name of the top image in a graph.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **String**: The top image name, or an empty string if the graph contains no image.


## `TopGraphToWaveRef`

**Signature**

```igorpro
TopGraphToWaveRef([string grfName])
```

Return the primary wave displayed in the top graph.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `LinkGraphSliders`

**Signature**

```igorpro
LinkGraphSliders([string grfName])
```

Link the image-layer sliders of multiple graphs.

Link the sliders of two graphs. Have you already set a link between graph sliders.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `LinkedImgSliderHook`

**Signature**

```igorpro
LinkedImgSliderHook(STRUCT WMSliderAction &sa)
```

Handle linked image slider hook events.

Remove metadata from the linked graph.

### Parameters

- `sa` *(STRUCT WMSliderAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `LinkGraphRanges`

**Signature**

```igorpro
LinkGraphRanges([string grfName])
```

Link axis ranges across multiple graph windows.

Have you already set a link between graph sliders.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Zero after completing the operation.


## `LinkedGraphAxesRangeHook`

**Signature**

```igorpro
LinkedGraphAxesRangeHook(STRUCT WMWinHookStruct &s)
```

Handle linked graph axes range hook events.

Note: On Windows, you have to mouse-click to enable it. Catch vertical expansion static Function
ShowZScaleInGraph(STRUCT WMWinHookStruct &s).

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.
