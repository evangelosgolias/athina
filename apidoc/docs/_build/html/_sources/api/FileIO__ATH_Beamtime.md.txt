# ATH_Beamtime

**Source file:** `FileIO/ATH_Beamtime.ipf`

Module ATH_Beamtime.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Beamtime functionality.

```{contents}
:local:
:depth: 2
```

## `SetOrResetBeamtimeRootFolder`

**Signature**

```igorpro
SetOrResetBeamtimeRootFolder()
```

Select or clear the beamtime root folder used by file-loading helpers.

### Returns

- **String**: The selected beamtime root path, or an empty string after reset or cancellation.


## `LoadNewestFileInRaw`

**Signature**

```igorpro
LoadNewestFileInRaw(string extension)
```

Load newest file in raw.

Load the last file found in the directory tree with root at pathName. Return UNC.

### Parameters

- `extension` *(String)*: File-name extension.

### Returns

- **Variable**: Zero after completing the operation.


## `LoadFileFromRaw`

**Signature**

```igorpro
LoadFileFromRaw(variable scanID)
```

Load file from raw.

### Parameters

- `scanID` *(Variable)*: Beamline scan identifier.

### Returns

- **Variable**: Zero after completing the operation.


## `GetNewestCreatedFileInPathTree`

**Signature**

```igorpro
GetNewestCreatedFileInPathTree(string pathName, string extension, string &latestfile, variable &latestctime, variable recurse, variable level)
```

Find the newest matching file in a folder tree.

### Parameters

- `pathName` *(String)*: Name of an Igor symbolic path.
- `extension` *(String)*: File-name extension filter.
- `latestfile` *(String)*: Input/output path of the newest file found so far.
- `latestctime` *(Variable)*: Input/output creation-time value for the newest item.
- `recurse` *(Variable)*: If nonzero, recurse into subfolders.
- `level` *(Variable)*: Current recursion depth.

### Returns

- **String**: The full path of the newest matching file.


## `LoadNewestFolderInPathTreeAndDisplay`

**Signature**

```igorpro
LoadNewestFolderInPathTreeAndDisplay()
```

Load newest folder in path tree and display.

Load the last file found in the directory tree with root at pathName will pop to set pathName. The path
name is saved as pATH_LoadLastFileIgorPath.

### Returns

- **Variable**: Zero after completing the operation.


## `GetNewestCreatedFolderInPathTree`

**Signature**

```igorpro
GetNewestCreatedFolderInPathTree(string pathName, string &latestfolder, variable &latestctime)
```

Find the newest folder in a folder tree.

### Parameters

- `pathName` *(String)*: Name of an Igor symbolic path.
- `latestfolder` *(String)*: Input/output path of the newest folder found so far.
- `latestctime` *(Variable)*: Input/output creation-time value for the newest item.

### Returns

- **String**: The full path of the newest folder.


## `LoadNewestFileInPathTreeAndDisplayPython`

**Signature**

```igorpro
LoadNewestFileInPathTreeAndDisplayPython(string ext)
```

Load newest file in path tree and display python.

Load the last file found in the directory tree with root set at pathName will pop to set pathName. The
path name is saved as pATH_LoadLastFileIgorPath.

### Parameters

- `ext` *(String)*: File-name extension.

### Returns

- **Variable**: One when the requested condition or operation succeeds; otherwise zero.


## `GetLastSavedFileInFolderTreePython`

**Signature**

```igorpro
GetLastSavedFileInFolderTreePython(string pathName, string ext)
```

Find the most recently saved matching file using the Python helper.

### Parameters

- `pathName` *(String)*: Name of an Igor symbolic path.
- `ext` *(String)*: File-name extension filter.

### Returns

- **String**: The full path of the most recently saved matching file.
