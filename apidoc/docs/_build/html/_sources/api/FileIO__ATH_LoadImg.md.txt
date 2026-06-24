# ATH_LoadImg

**Source file:** `FileIO/ATH_LoadImg.ipf`

Module ATH_LoadImg.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH LoadImg functionality.

```{contents}
:local:
:depth: 2
```

## `Loadtiff`

**Signature**

```igorpro
Loadtiff(string filepathStr, string waveNameStr, [int displayImg, int overwrite])
```

Load TIFF.

Guess the dimenions.

### Parameters

- `filepathStr` *(String)*: Filepath str.
- `waveNameStr` *(String)*: Wave used by the operation.
- `displayImg` *(Integer, optional)*: If nonzero, display the result image.
- `overwrite` *(Integer, optional)*: If nonzero, replace the source or an existing destination.

### Returns

- **Variable**: Zero after completing the operation.


## `Loadtiffs`

**Signature**

```igorpro
Loadtiffs([int numImages, int displayImg, int stack3d])
```

Load tiffs.

### Parameters

- `numImages` *(Integer, optional)*: Maximum number of images to load.
- `displayImg` *(Integer, optional)*: If nonzero, display the result image.
- `stack3d` *(Integer, optional)*: Input 3D image stack.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `PEEM3File`

**Signature**

```igorpro
PEEM3File(string filepathStr, [variable mkdir])
```

Load a PEEM3 image file and its metadata.

### Parameters

- `filepathStr` *(String)*: Full path of the input file.
- `mkdir` *(Variable, optional)*: If nonzero, create a destination data folder for the loaded file.

### Returns

- **String**: The name of the loaded image wave, or an empty string if file selection is cancelled.


## `PEEM3Files`

**Signature**

```igorpro
PEEM3Files([int stack3d])
```

Load PEEM3 image files into Igor waves.

Get the first wave to have the scale.

### Parameters

- `stack3d` *(Integer, optional)*: Input 3D image stack.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.
