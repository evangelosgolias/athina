# ATH_Cursors

**Source file:** `Graphs/ATH_Cursors.ipf`

Module ATH_Cursors.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Cursors functionality.

```{contents}
:local:
:depth: 2
```

## `GetActiveCursors`

**Signature**

```igorpro
GetActiveCursors([string grfName])
```

Return a list of cursors currently attached to graph traces.

### Parameters

- `grfName` *(String, optional)*: Name of the graph window.

### Returns

- **String**: A semicolon-separated list of active cursor names.


## `GetDistanceFromCursors`

**Signature**

```igorpro
GetDistanceFromCursors(string C1, string C2)
```

Return distance from cursors.

Returns the distance between C1 and C2 if given. Interactive functionality.

### Parameters

- `C1` *(String)*: Name of the first graph cursor.
- `C2` *(String)*: Name of the second graph cursor.

### Returns

- **Variable**: The returned value is distance from cursors.


## `MeasureDistanceUsingFreeCursors`

**Signature**

```igorpro
MeasureDistanceUsingFreeCursors()
```

Measure distance using free cursors.

Use Cursors I, J (Free) to measure distances in a graph. Uses ATH_MeasureDistanceUsingFreeCursorsIJHook.
Add metadata.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `MeasureDistanceUsingFreeCursorsHook`

**Signature**

```igorpro
MeasureDistanceUsingFreeCursorsHook(STRUCT WMWinHookStruct &s)
```

Handle measure distance using free cursors hook events.

Hook function for ATH_MeasureDistanceUsingFreeCursorsIJ() currently button is disabled for wavedims != 1
SetDrawEnv/W=$s.winName xcoord= axrel,ycoord= $axisY.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `MeasureDistanceButton`

**Signature**

```igorpro
MeasureDistanceButton(STRUCT WMButtonAction &s)
```

Handle actions from the cursor-distance measurement panel.

### Parameters

- `s` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `UserGetABCursorPositions`

**Signature**

```igorpro
UserGetABCursorPositions(STRUCT sUserCursorPositions &s)
```

Pause for the user to position cursors A and B.

### Parameters

- `s` *(STRUCT sUserCursorPositions)*: Input/output structure containing graph, axis, and cursor settings.

### Returns

- **Multiple values**: The start and end coordinates selected with cursors A and B.


## `UserGetCursorsPositions_ContButtonProc`

**Signature**

```igorpro
UserGetCursorsPositions_ContButtonProc(STRUCT WMButtonAction &B_Struct)
```

Handle the continue button for user get cursors positions.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `UserGetCursorsPositions_CancelBProc`

**Signature**

```igorpro
UserGetCursorsPositions_CancelBProc(STRUCT WMButtonAction &B_Struct)
```

Handle the cancel button for user get cursors positions.

End of Cursor positions with PauseforUser.

### Parameters

- `B_Struct` *(STRUCT WMButtonAction)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `ThreeCursorsToAngle`

**Signature**

```igorpro
ThreeCursorsToAngle(string Cursor1, string Cursor2, string Cursor3, [, variable deg])
```

Calculate the angle formed by three graph cursors.

Returns the angle formed by the cursors Cursor1, Cursor2 & Cursor3 (*corner of angle at Cursor2*) in rad
or degrees.

### Parameters

- `Cursor1` *(String)*: Name of the first graph cursor.
- `Cursor2` *(String)*: Name of the second graph cursor.
- `Cursor3` *(String)*: Name of the third graph cursor.
- `deg` *(Variable, optional)*: If nonzero, return the angle in degrees instead of radians.

### Returns

- **Variable**: The angle in radians, or in degrees when `deg` is nonzero.


## `MirrorCursorPositionToWaveValues`

**Signature**

```igorpro
MirrorCursorPositionToWaveValues(WAVE wRef)
```

Mirror cursor position to wave values.

Add a textbox with values from two graphs in the same cursor position.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Zero after completing the operation.


## `SyncCursorsInGraphsHook`

**Signature**

```igorpro
SyncCursorsInGraphsHook(STRUCT WMWinHookStruct &s)
```

Handle sync cursors in graphs hook events.

Dispatches the relevant Igor control event and ignores unsupported event codes.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.
