# ATH_Marquee

**Source file:** `Graphs/ATH_Marquee.ipf`

Module ATH_Marquee.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Marquee functionality.

```{contents}
:local:
:depth: 2
```

## `MarqueeToMask`

**Signature**

```igorpro
MarqueeToMask([string grfName])
```

Convert the active graph marquee into a numeric ROI mask.

Reads the current graph interaction state and applies the requested operation to that selection.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `CoordinatesToROIMask`

**Signature**

```igorpro
CoordinatesToROIMask(variable left, variable top, variable right, variable bottom, [variable interior, variable exterior, variable spW, string grfName])
```

Create an ROI mask from numeric rectangle coordinates.

The rectangle is interpreted in graph-axis coordinates and converted to a mask matching the displayed image
or `spw`.

### Parameters

- `left` *(Variable)*: Left region bound.
- `top` *(Variable)*: Top region bound.
- `right` *(Variable)*: Right region bound.
- `bottom` *(Variable)*: Bottom region bound.
- `interior` *(Variable, optional)*: Mask value assigned inside the ROI.
- `exterior` *(Variable, optional)*: Mask value assigned outside the ROI.
- `spW` *(Variable, optional)*: wave whose dimensions and scaling define the mask.
- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **String**: The full path of the generated ROI mask wave.


## `WAVECoordinatesToROIMask`

**Signature**

```igorpro
WAVECoordinatesToROIMask(variable left, variable top, variable right, variable bottom, [variable interior, variable exterior])
```

Create an ROI mask from coordinate waves.

The coordinate waves describe the ROI boundary in graph-axis coordinates; the mask inherits dimensions and
scaling from the displayed image or `spw`.

### Parameters

- `left` *(Variable)*: Left region bound.
- `top` *(Variable)*: Top region bound.
- `right` *(Variable)*: Right region bound.
- `bottom` *(Variable)*: Bottom region bound.
- `interior` *(Variable, optional)*: Mask value assigned inside the ROI.
- `exterior` *(Variable, optional)*: Mask value assigned outside the ROI.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `PartitionRegion`

**Signature**

```igorpro
PartitionRegion([int evenNum, int square])
```

Partition the active marquee region into a stack of image tiles.

Use NameOfWave(waveRef) instead of imgNameTopGraphStr as the ' ' will be replace by _! CopyScales/P
waveRef, wavePRT.

### Parameters

- `evenNum` *(Integer, optional)*: If nonzero, force an even number of rows and columns.
- `square` *(Integer, optional)*: If nonzero, constrain the partitioned region to a square.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `GetMarqueeToIndex`

**Signature**

```igorpro
GetMarqueeToIndex([string grfName, string axisX, string axisY])
```

Convert the active graph marquee to wave-index bounds.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.
- `axisX` *(String, optional)*: Name of the horizontal graph axis.
- `axisY` *(String, optional)*: Name of the vertical graph axis.

### Returns

- **Multiple values**: A validity flag followed by the left, right, top, and bottom wave-index bounds.


## `GetMarqueeWaveStats`

**Signature**

```igorpro
GetMarqueeWaveStats()
```

Return marquee wave stats.

Wavestats for a marquee region in a 2D wave. In case of a 3D wave the stats are calculated for all
layers.

### Returns

- **Variable**: The marquee wave stats.


## `CheckActiveAxis`

**Signature**

```igorpro
CheckActiveAxis(string graphname, string axis)
```

Check active axis.

### Parameters

- `graphname` *(String)*: Name of the graph window.
- `axis` *(String)*: Name of the graph axis.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `SaveROICoordinatesToDatabase`

**Signature**

```igorpro
SaveROICoordinatesToDatabase([variable rect])
```

Save ROI coordinates selected with the graph marquee.

Save ROI to database and draw it on image's UserFront. The following three function let you select an
area on a 2d/3d wave and return the coordinates.

### Parameters

- `rect` *(Variable, optional)*: Rectangle coordinates receiving or defining the selected region.

### Returns

- **Variable**: Zero after completing the operation.


## `UserGetMarqueePositions`

**Signature**

```igorpro
UserGetMarqueePositions(STRUCT sUserMarqueePositions &s)
```

Pause for the user to define a graph marquee.

### Parameters

- `s` *(STRUCT sUserMarqueePositions)*: Input/output structure containing graph, axis, and marquee settings.

### Returns

- **Multiple values**: The left, right, top, and bottom graph coordinates selected by the user.


## `UserSetMarquee_ContButtonProc`

**Signature**

```igorpro
UserSetMarquee_ContButtonProc(STRUCT WMButtonAction &B_Struct)
```

Handle the continue button for user set marquee.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `UserSetMarquee_CancelBProc`

**Signature**

```igorpro
UserSetMarquee_CancelBProc(STRUCT WMButtonAction &B_Struct)
```

Handle the cancel button for user set marquee.

End of marquee coordinates.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.
