# ATH_Draw

**Source file:** `Graphs/ATH_Draw.ipf`

Module ATH_Draw.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Draw functionality.

```{contents}
:local:
:depth: 2
```

## `DrawLineUsingCursors`

**Signature**

```igorpro
DrawLineUsingCursors(string C1, string C2, [string layer])
```

Draw line using cursors.

Draw a line using cursor C1 & C2. Draws in Overlay layer if layer optional argument is not given.

### Parameters

- `C1` *(String)*: Name of the first graph cursor.
- `C2` *(String)*: Name of the second graph cursor.
- `layer` *(String, optional)*: Igor drawing or image layer to use.

### Returns

- **Variable**: Zero after completing the operation.


## `DrawCircleUsingAntinodalCursors`

**Signature**

```igorpro
DrawCircleUsingAntinodalCursors(string C1, string C2, [string layer])
```

Draw circle using antinodal cursors.

Draw a circle with antinodal points at C1 & C2. Draws in Overlay layer if layer optional argument is not
given change now left, right, top, bottom.

### Parameters

- `C1` *(String)*: Name of the first graph cursor.
- `C2` *(String)*: Name of the second graph cursor.
- `layer` *(String, optional)*: Igor drawing or image layer to use.

### Returns

- **Variable**: Zero after completing the operation.


## `DrawCircleUsingCenterAndPointCursors`

**Signature**

```igorpro
DrawCircleUsingCenterAndPointCursors(string C1, string C2, [string layer])
```

Draw circle using center and point cursors.

Draw a circle with center at C1 that passed from C2. Draws in Overlay layer if layer optional argument is
not given. Draw scale bar.

### Parameters

- `C1` *(String)*: Name of the first graph cursor.
- `C2` *(String)*: Name of the second graph cursor.
- `layer` *(String, optional)*: Igor drawing or image layer to use.

### Returns

- **Variable**: Zero after completing the operation.


## `ImageScaleBar`

**Signature**

```igorpro
ImageScaleBar(variable barlen, [string grfName])
```

Draw a scale bar on an image graph and return its relative width.

Here the function returns the factor barlen/xlen which is the number we need to adjust so that the scale
bar corresponds to the size of the visible range.

### Parameters

- `barlen` *(Variable)*: Requested scale-bar length in axis units.
- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Scale-bar width as a fraction of the visible x-axis range.
