# ATH_LoadUview

**Source file:** `FileIO/ATH_LoadUview.ipf`

Module ATH_LoadUview.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH LoadUview functionality.

```{contents}
:local:
:depth: 2
```

## `WAVELoadSingleDATFile`

**Signature**

```igorpro
WAVELoadSingleDATFile(string filepathStr, string waveNameStr [,int skipmetadata, int autoScale,int binX, int binY, int overwrite])
```

Load one UView DAT file and return the image wave.

### Parameters

- `filepathStr` *(String)*: Full path of the input file.
- `waveNameStr` *(String, optional)*: destination wave name.
- `skipmetadata` *(Integer, optional)*: If nonzero, skip reading image metadata.
- `autoScale` *(Integer, optional)*: If nonzero, derive physical scaling from the file metadata.
- `binX` *(Integer, optional)*: Horizontal binning factor.
- `binY` *(Integer, optional)*: Vertical binning factor.
- `overwrite` *(Integer, optional)*: If nonzero, replace the source or existing destination.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `LoadSingleDATFile`

**Signature**

```igorpro
LoadSingleDATFile(string filepathStr, string waveNameStr [,int skipmetadata, int autoScale, int binX, int binY, int overwrite])
```

Load one UView DAT file into the current data folder.

### Parameters

- `filepathStr` *(String)*: Full path of the input file.
- `waveNameStr` *(String, optional)*: destination wave name.
- `skipmetadata` *(Integer, optional)*: If nonzero, skip reading image metadata.
- `autoScale` *(Integer, optional)*: If nonzero, derive physical scaling from the file metadata.
- `binX` *(Integer, optional)*: Horizontal binning factor.
- `binY` *(Integer, optional)*: Vertical binning factor.
- `overwrite` *(Integer, optional)*: If nonzero, replace the source or existing destination.

### Returns

- **Variable**: Zero on success; a nonzero status if the file cannot be loaded.


## `StrGetBasicMetadataInfoFromDAT`

**Signature**

```igorpro
StrGetBasicMetadataInfoFromDAT(string datafile, variable MetadataStartPos, variable MetadataEndPos, variable LEEMDataVersion)
```

Read basic acquisition metadata from a UView DAT file.

### Parameters

- `datafile` *(String)*: Full path of the UView DAT file.
- `MetadataStartPos` *(Variable)*: Byte offset where metadata begins.
- `MetadataEndPos` *(Variable)*: Byte offset where metadata ends.
- `LEEMDataVersion` *(Variable)*: UView/LEEM file-format version read from the header.

### Returns

- **String**: An Igor key-value string containing basic acquisition metadata.


## `StrGetAllMetadataInfoFromDAT`

**Signature**

```igorpro
StrGetAllMetadataInfoFromDAT(string datafile, variable MetadataStartPos, variable MetadataEndPos, variable LEEMDataVersion)
```

Read all supported metadata records from a UView DAT file.

### Parameters

- `datafile` *(String)*: Full path of the UView DAT file.
- `MetadataStartPos` *(Variable)*: Byte offset where metadata begins.
- `MetadataEndPos` *(Variable)*: Byte offset where metadata ends.
- `LEEMDataVersion` *(Variable)*: UView/LEEM file-format version read from the header.

### Returns

- **String**: An Igor key-value string containing all recognized metadata records.


## `LoadDATFilesFromFolder`

**Signature**

```igorpro
LoadDATFilesFromFolder(string folder, string pattern, [int stack3d, string wname3d, int autoscale, int displayImg])
```

Load UView DAT files from a selected folder.

We use ImageTransform stackImages X to create the 3d wave. Compared to 3d wave assignement it is faster
by nearly 3x. Import .dat files that match a pattern from a folder. Waves are named after their filename.
Get all the .dat files. Use "????" for all files in IndexedFile third argument.

### Parameters

- `folder` *(String)*: Source folder path.
- `pattern` *(String)*: Pattern used to select names or files.
- `stack3d` *(Integer, optional)*: Input 3D image stack.
- `wname3d` *(String, optional)*: Wname3d.
- `autoscale` *(Integer, optional)*: Autoscale.
- `displayImg` *(Integer, optional)*: If nonzero, display the result image.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `WAVELoadDATFilesFromFolder`

**Signature**

```igorpro
WAVELoadDATFilesFromFolder(string folder, string pattern, [string wname3dStr, int autoscale])
```

Load matching UView DAT files from a folder into an image stack.

### Parameters

- `folder` *(String)*: Source folder path.
- `pattern` *(String)*: Pattern used to select names or files.
- `wname3dStr` *(String, optional)*: destination name for the assembled image stack.
- `autoscale` *(Integer, optional)*: If nonzero, derive physical scaling from the file metadata.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `LoadMultiplyDATFiles`

**Signature**

```igorpro
LoadMultiplyDATFiles([int skipmetadata, int autoscale, int stack3d, int displayImg])
```

Load multiple UView DAT files selected by the user.

Load multiply selected .dat files. Note: the selected wave are sort alphanumerically so the first on the
list takes the first name in filenames etc.

### Parameters

- `skipmetadata` *(Integer, optional)*: If nonzero, skip reading image metadata.
- `autoscale` *(Integer, optional)*: Autoscale.
- `stack3d` *(Integer, optional)*: Input 3D image stack.
- `displayImg` *(Integer, optional)*: If nonzero, display the result image.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `UviewLoad_Worker`

**Signature**

```igorpro
UviewLoad_Worker(string filepathStr)
```

Load one UView DAT file in a worker thread.

### Parameters

- `filepathStr` *(String)*: Full path of the input file.

### Returns

- **Wave**: Reference to the result wave; a null wave reference indicates failure where supported.


## `LoadDATFilesFromFolderMT`

**Signature**

```igorpro
LoadDATFilesFromFolderMT([int displayImg])
```

Load a folder of UView DAT files using multithreaded conversion.

Get all the .dat files. Use "????" for all files in IndexedFile third argument.

### Parameters

- `displayImg` *(Integer, optional)*: If nonzero, display the result image.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `LoadMultiplyDATFilesMT`

**Signature**

```igorpro
LoadMultiplyDATFilesMT([int displayImg])
```

Load multiple UView DAT files using multithreaded conversion.

### Parameters

- `displayImg` *(Integer, optional)*: If nonzero, display the result image.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `LoadDATFilesMatchingPattternToStackMT`

**Signature**

```igorpro
LoadDATFilesMatchingPattternToStackMT([int displayImg, int pattern])
```

Load matching UView DAT files into a stack using multithreaded conversion.

### Parameters

- `displayImg` *(Integer, optional)*: If nonzero, display the result image.
- `pattern` *(Integer, optional)*: Pattern used to select names or files.

### Returns

- **Variable**: NaN if input validation fails; otherwise zero after completing the operation.


## `ReadFovFromDATFile`

**Signature**

```igorpro
ReadFovFromDATFile(string filepathStr)
```

Read the field of view from a UView DAT file header.

Elmitec files can have additional markup blocks hence the offsets of 128 bytes no markups. Markup blocks
multiple of 128 bytes after image header.

### Parameters

- `filepathStr` *(String)*: Filepath str.

### Returns

- **Variable**: The field of view in micrometres, or zero when the metadata value is unavailable.
