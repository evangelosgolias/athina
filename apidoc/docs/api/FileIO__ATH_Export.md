# ATH_Export_Repeat

**Source file:** `FileIO/ATH_Export.ipf`

Module ATH_Export_Repeat.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Export Repeat functionality.

```{contents}
:local:
:depth: 2
```

## `WavesToTIFFDB`

**Signature**

```igorpro
WavesToTIFFDB([int byte32])
```

Export waves selected in the Data Browser as TIFF files.

Export all traces selected in Data Browser.

### Parameters

- `byte32` *(Integer, optional)*: If nonzero, export 32-bit rather than 16-bit data.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `Wave3DToTIFFsDB`

**Signature**

```igorpro
Wave3DToTIFFsDB([int byte32])
```

Export each layer of a selected 3D wave as a TIFF file.

Export all layers of a 3D wave to a folder.

### Parameters

- `byte32` *(Integer, optional)*: If nonzero, export 32-bit rather than 16-bit data.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `TracesToGeneralTextDB`

**Signature**

```igorpro
TracesToGeneralTextDB()
```

Export selected graph traces as general-text files.

Export all traces selected in Data Browser.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.
