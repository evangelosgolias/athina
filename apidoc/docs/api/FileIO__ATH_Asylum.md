# ATH_Asylum

**Source file:** `FileIO/ATH_Asylum.ipf`

```{contents}
:local:
:depth: 2
```

## `LabelAsylumStack`

**Signature**

```igorpro
LabelAsylumStack(WAVE wRef)
```

Apply Asylum AFM dimension labels and metadata to an image stack.

### Parameters

- `wRef` *(Wave)*: Input wave.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `LoadAsylumIBW`

**Signature**

```igorpro
LoadAsylumIBW()
```

Load an Asylum IBW file and display its image channels.

### Returns

- **Variable**: Igor status code; zero indicates success and nonzero values report failure or cancellation.


## `AsylumDisplayHook`

**Signature**

```igorpro
AsylumDisplayHook(STRUCT WMWinHookStruct &s)
```

Keep an Asylum image graph square when its window is resized.

### Parameters

- `s` *(STRUCT WMWinHookStruct)*: Igor action structure describing the control or window event.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `DisplayAsylum`

**Signature**

```igorpro
DisplayAsylum(WAVE w)
```

Display an Asylum image wave with its stored color and scale settings.

### Parameters

- `w` *(Wave)*: Asylum image wave to display.

### Returns

- **String**: The name of the graph displaying the Asylum image.
