# ATH_Display

**Source file:** `Graphs/ATH_Display.ipf`

Module ATH_Display.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Display functionality.

```{contents}
:local:
:depth: 2
```

## `NewImg`

**Signature**

```igorpro
NewImg(WAVE wRef, [string grfname])
```

Display a wave as a new image graph.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `grfname` *(String, optional)*: Name of the graph window.

### Returns

- **String**: The name of the graph displaying the image.


## `DisplayHookFunction`

**Signature**

```igorpro
DisplayHookFunction(STRUCT WMWinHookStruct &s)
```

Handle display hook events.

31.08.2024: Deal with calls from /EXT windows. We control using the wave reference. This is patchwork, we
need to find a more stable solution.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `Append3DImageSlider`

**Signature**

```igorpro
Append3DImageSlider([string grfName])
```

Append 3D image slider.

Append a slider if you have a stack. Wave in top graph. Reads graph outer dimensions into V_left.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `NewImgSliderHook`

**Signature**

```igorpro
NewImgSliderHook(STRUCT WMSliderAction &sa)
```

Handle new image slider hook events.

Creates a separate result wave, leaving the input wave available to the caller.

### Parameters

- `sa` *(STRUCT WMSliderAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `ImageSliderSetVar`

**Signature**

```igorpro
ImageSliderSetVar(STRUCT WMSetVariableAction &sva)
```

Update the displayed 3D image layer from its slider control.

Added 02.10.2025. End of addition.

### Parameters

- `sva` *(STRUCT WMSetVariableAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `Mangify`

**Signature**

```igorpro
Mangify(STRUCT WMWinHookStruct &s)
```

Magnify the active graph around the cursor position.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Zero after completing the operation.


## `RestartW3DImageSlider`

**Signature**

```igorpro
RestartW3DImageSlider([string grfName])
```

Recreate the layer slider for a displayed 3D wave.

Of changes in the source 3d wave.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.
