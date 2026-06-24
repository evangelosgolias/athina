# ATH_Geometry

**Source file:** `Utilities/ATH_Geometry.ipf`

Calculate a point at a signed distance along a line through a reference point.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Geometry functionality.
@function GetSinglePointWithDistanceFromLine

```{contents}
:local:
:depth: 2
```

## `GetSinglePointWithDistanceFromLine`

**Signature**

```igorpro
GetSinglePointWithDistanceFromLine(variable x1, variable y1, variable s, variable d)
```

Calculate a point at a signed distance along a line through a reference point.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Geometry functionality.

### Parameters

- `x1` *(Variable)*: Second x coordinate.
- `y1` *(Variable)*: Second y coordinate.
- `s` *(Variable)*: Slope of the line along which to offset the point.
- `d` *(Variable)*: Signed distance from the reference point.

### Returns

- **Multiple values**: The calculated x and y coordinates.


## `GetBothPointsWithDistanceFromLine`

**Signature**

```igorpro
GetBothPointsWithDistanceFromLine(variable x1, variable y1, variable s, variable d)
```

Calculate the two points separated by a requested distance along a line.

The returned points lie on opposite sides of the reference point and are separated by `d`.

### Parameters

- `x1` *(Variable)*: Second x coordinate.
- `y1` *(Variable)*: Second y coordinate.
- `s` *(Variable)*: Slope of the line on which the returned points lie.
- `d` *(Variable)*: Distance separating the two returned points.

### Returns

- **Multiple values**: The x and y coordinates of both calculated points.


## `SlopePerpendicularToLineSegment`

**Signature**

```igorpro
SlopePerpendicularToLineSegment(variable x1, variable y1, variable x2, variable y2)
```

Calculate slope perpendicular to line segment.

Return the slope of a line perpendicular to the line segment defined by (x1, y1) and (x2, y2).

### Parameters

- `x1` *(Variable)*: Second x coordinate or range bound.
- `y1` *(Variable)*: Second y coordinate or range bound.
- `x2` *(Variable)*: Second point's x coordinate.
- `y2` *(Variable)*: Second point's y coordinate.

### Returns

- **Variable**: The calculated slope perpendicular to line segment.


## `GetVerticesPerpendicularToLine`

**Signature**

```igorpro
GetVerticesPerpendicularToLine(variable radius, variable slope)
```

Calculate the x and y offsets from a circle center to a line intersection.

The offsets are the nonnegative x component and signed y component for a line through the origin
intersecting a circle of the requested radius.

### Parameters

- `radius` *(Variable)*: Radius of the circle.
- `slope` *(Variable)*: Slope of the line through the circle center.

### Returns

- **Multiple values**: The x and y offsets from the circle center.


## `SymmetricLineShrink`

**Signature**

```igorpro
SymmetricLineShrink(variable x1, variable y1, variable x2, variable y2, variable Sfactor)
```

Scale a line segment about its midpoint.

A factor below one shortens the segment and a factor above one lengthens it without moving its midpoint.

### Parameters

- `x1` *(Variable)*: Second x coordinate.
- `y1` *(Variable)*: Second y coordinate.
- `x2` *(Variable)*: Second endpoint's x coordinate.
- `y2` *(Variable)*: Second endpoint's y coordinate.
- `Sfactor` *(Variable)*: Scale factor applied to the segment length about its midpoint.

### Returns

- **Multiple values**: The two endpoints of the scaled line segment.


## `GetAntipodalPoint`

**Signature**

```igorpro
GetAntipodalPoint(variable x1, variable y1, variable x0, variable y0)
```

Return antipodal point.

Returns the antipodal point (xn, yn) of (x1, x2) of a circle with center (x0, y0) return [xn, yn].

### Parameters

- `x1` *(Variable)*: Second x coordinate or range bound.
- `y1` *(Variable)*: Second y coordinate or range bound.
- `x0` *(Variable)*: First x coordinate or range bound.
- `y0` *(Variable)*: First y coordinate or range bound.

### Returns

- **Variable**: Zero after completing the operation.


## `LineEquationFromTwoPoints`

**Signature**

```igorpro
LineEquationFromTwoPoints(variable x0, variable y0, variable x1, variable y1)
```

Calculate slope and intercept for the line through two points.

### Parameters

- `x0` *(Variable)*: First x coordinate.
- `y0` *(Variable)*: First y coordinate.
- `x1` *(Variable)*: Second x coordinate.
- `y1` *(Variable)*: Second y coordinate.

### Returns

- **Multiple values**: The line slope and y intercept; a vertical line returns an infinite slope and zero intercept.


## `LineCoefficientsFromCursors`

**Signature**

```igorpro
LineCoefficientsFromCursors(string csr0, string csr1, [int free, string grfName])
```

Line coefficients from cursors.

Get a WAVE with the coefficients of a line defined by csr0 & csr1. N.B: Wave scaling is taken into
account here! Use poly function to make the polynomial.

### Parameters

- `csr0` *(String)*: Name or index of the first cursor.
- `csr1` *(String)*: Name or index of the second cursor.
- `free` *(Integer, optional)*: If nonzero, create a free wave rather than a data-folder wave.
- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Wave**: Reference to the result wave; a null reference indicates failure where supported.


## `GetLineFromCursors`

**Signature**

```igorpro
GetLineFromCursors(string csr0, string csr1, [int free, string grfName])
```

Return line from cursors.

Get a WAVE with the coefficients of a line defined by csr0 & csr1. N.B: Wave scaling is taken into
account here! Use poly function to make the polynomial.

### Parameters

- `csr0` *(String)*: Name or index of the first cursor.
- `csr1` *(String)*: Name or index of the second cursor.
- `free` *(Integer, optional)*: If nonzero, create a free wave rather than a data-folder wave.
- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **Wave**: Reference to the result wave; a null reference indicates failure where supported.


## `XYWavesOfLineFromTwoPoints`

**Signature**

```igorpro
XYWavesOfLineFromTwoPoints(variable x0, variable y0, variable x1, variable y1, variable npts)
```

Create coordinate waves sampling the segment between two points.

### Parameters

- `x0` *(Variable)*: First x coordinate.
- `y0` *(Variable)*: First y coordinate.
- `x1` *(Variable)*: Second x coordinate.
- `y1` *(Variable)*: Second y coordinate.
- `npts` *(Variable)*: Number of output points or LOESS neighborhood size, as applicable.

### Returns

- **Multiple values**: Free waves containing the sampled x and y coordinates.
