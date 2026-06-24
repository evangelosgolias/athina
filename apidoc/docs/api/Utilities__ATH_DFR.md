# ATH_DFR

**Source file:** `Utilities/ATH_DFR.ipf`

Module ATH_DFR.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH DFR functionality.

```{contents}
:local:
:depth: 2
```

## `CreateDataFolderGetDFREF`

**Signature**

```igorpro
CreateDataFolderGetDFREF(string fullpath, [int setDF])
```

Create a data folder from a full path and return its data folder reference.

Creates the data folder identified by `fullpath` and returns a `DFREF` to it.
If intermediate parent folders do not exist, they are created automatically.
Relative paths beginning with `:` are resolved against the current data folder.
The input path is sanitized before use so that folder names using liberal naming
are handled safely.
If the target folder already exists, no new folder is created and a reference to
the existing folder is returned.

### Parameters

- `fullpath` *(String)*: Full data folder path to create or access.
- `setDF` *(Integer, optional)*: Optional flag. If nonzero, sets the current data folder to the returned folder.

### Returns

- **DFREF**: Data folder reference to the created or existing folder.

```{note}
 - Relative paths starting with `:` are interpreted relative to the current data folder. - The path is sanitized before folder creation to support liberal folder names. - Missing parent folders are created automatically. - If the folder already exists, the function simply returns its reference.
```

### Example

```{code-block} igorpro
    DFREF dfr = CreateDataFolderGetDFREF("root:Packages:MyModule", setDF=1)

```


## `SanitizePath`

**Signature**

```igorpro
SanitizePath(string path)
```

Sanitize path.

Fix liberal relative pathnames in fullpath.

### Parameters

- `path` *(String)*: Path.

### Returns

- **String**: The resulting path string, or an empty string when it cannot be determined.


## `ZapDataInFolderTree`

**Signature**

```igorpro
ZapDataInFolderTree(string path)
```

Remove data in folder tree.

Kills the contents of a data folder and the contents of its children without killing any data folders and
without attempting to kill any waves that may be in use.

### Parameters

- `path` *(String)*: Path.

### Returns

- **Variable**: Zero after completing the operation.


## `ZapAllDataFoldersInPath`

**Signature**

```igorpro
ZapAllDataFoldersInPath(string path)
```

Remove all data folders in path.

Kills all data folders in path.

### Parameters

- `path` *(String)*: Path.

### Returns

- **Variable**: Zero after completing the operation.


## `PrintFoldersAndFiles`

**Signature**

```igorpro
PrintFoldersAndFiles(string pathName, string extension, variable recurse, variable level)
```

Print folders and files.

This is a Wavemetrics function. Striwng pathName Name of symbolic path in which to look for folders and
files. String extensios File name extension (e.g., ".txt") or "????" for all files.

### Parameters

- `pathName` *(String)*: Name of an Igor symbolic path.
- `extension` *(String)*: File-name extension.
- `recurse` *(Variable)*: If nonzero, include nested data folders.
- `level` *(Variable)*: Level.

### Returns

- **Variable**: Zero after completing the operation.


## `CleanGlobalWavesVarAndStrInFolder`

**Signature**

```igorpro
CleanGlobalWavesVarAndStrInFolder(DFREF dfr)
```

Remove global waves, numeric variables, and strings from a data folder.

Move from current working directory to dfr kill all global variables and strings and return to the
working directory.

### Parameters

- `dfr` *(DFREF)*: Reference to the data folder to inspect or modify.

### Returns

- **Variable**: Zero after completing the operation.


## `DeleteEverythingButSomeFolders`

**Signature**

```igorpro
DeleteEverythingButSomeFolders(string baseFolderPattern, string keepFolders)
```

Remove everything but some folders.

Delete waves and child folders in folders that match baseFolderPattern but keep keepFolders
WM_ZapDataInFolderTree(nextPath).

### Parameters

- `baseFolderPattern` *(String)*: Pattern selecting root data folders.
- `keepFolders` *(String)*: If nonzero, remove contents but retain matching folders.

### Returns

- **Variable**: Zero after completing the operation.


## `FindBigWaves`

**Signature**

```igorpro
FindBigWaves(variable minSizeInMB[,DFREF df,variable depth,variable noShow])
```

Find big waves.

See https.

### Parameters

- `minSizeInMB` *(Variable, optional)*: Lower or starting min size in mb.
- `df` *(DFREF, optional)*: Data-folder reference or path.
- `depth` *(Variable, optional)*: Maximum recursion depth.
- `noShow` *(Variable, optional)*: If nonzero, do not open the results window.

### Returns

- **Variable**: Zero after completing the operation.


## `AllWavesSamePathQ`

**Signature**

```igorpro
AllWavesSamePathQ(WAVE/WAVE wWAVEList)
```

Test whether all waves same path.

Function checks whether all have are in the same data folder 0 - no, 1 - yes.

### Parameters

- `wWAVEList` *(Wave/WAVE)*: used by the operation.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `BackupWaveInWaveDF`

**Signature**

```igorpro
BackupWaveInWaveDF(WAVE wref)
```

Create a backup beside a wave in its source data folder.

Backup a wave in the same DF. If a wave with wavename_undo exists, nothing is done. The function returns
a string of backupWavePathStr.

### Parameters

- `wref` *(Wave)*: Input wave.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `BackupWaveInWaveDFQ`

**Signature**

```igorpro
BackupWaveInWaveDFQ(WAVE wref)
```

Test whether a wave has a backup in its source data folder.

Backup a wave in the same DF. If a wave with wavename_undo exists the user is prompted to proceed and
overwrite the destination wave or not. The function returns a string of backupWavePathStr.

### Parameters

- `wref` *(Wave)*: Input wave.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `GetAllWavesStrDF`

**Signature**

```igorpro
GetAllWavesStrDF(DFREF dfr)
```

Return a list of all waves in a data folder tree.

Return a string of all fullpaths of waves in the data folder dfr. Not used, cleanup 14.11.2024.

### Parameters

- `dfr` *(DFREF)*: Reference to the data folder to inspect or modify.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.
