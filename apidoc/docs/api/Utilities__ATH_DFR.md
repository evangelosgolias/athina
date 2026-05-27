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
- `setDF` *(Variable)*: Optional flag. If nonzero, sets the current data folder to the returned folder.

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

Description of SanitizePath.

Auto-generated documentation stub for function `SanitizePath`.

### Parameters

- `path` *(Parameter)*: path.

### Returns

- **String**: Return value.


## `ZapDataInFolderTree`

**Signature**

```igorpro
ZapDataInFolderTree(string path)
```

Description of ZapDataInFolderTree.

Auto-generated documentation stub for function `ZapDataInFolderTree`.

### Parameters

- `path` *(Parameter)*: path.

### Returns

- **Variable**: Return value.


## `ZapAllDataFoldersInPath`

**Signature**

```igorpro
ZapAllDataFoldersInPath(string path)
```

Description of ZapAllDataFoldersInPath.

Auto-generated documentation stub for function `ZapAllDataFoldersInPath`.

### Parameters

- `path` *(Parameter)*: path.

### Returns

- **Variable**: Return value.


## `PrintFoldersAndFiles`

**Signature**

```igorpro
PrintFoldersAndFiles(string pathName, string extension, variable recurse, variable level)
```

Description of PrintFoldersAndFiles.

Auto-generated documentation stub for function `PrintFoldersAndFiles`.

### Parameters

- `pathName` *(Parameter)*: pathName.
- `extension` *(Parameter)*: extension.
- `recurse` *(Parameter)*: recurse.
- `level` *(Parameter)*: level.

### Returns

- **Variable**: Return value.


## `CleanGlobalWavesVarAndStrInFolder`

**Signature**

```igorpro
CleanGlobalWavesVarAndStrInFolder(DFREF dfr)
```

Description of CleanGlobalWavesVarAndStrInFolder.

Auto-generated documentation stub for function `CleanGlobalWavesVarAndStrInFolder`.

### Parameters

- `dfr` *(Parameter)*: dfr.

### Returns

- **Variable**: Return value.


## `DeleteEverythingButSomeFolders`

**Signature**

```igorpro
DeleteEverythingButSomeFolders(string baseFolderPattern, string keepFolders)
```

Description of DeleteEverythingButSomeFolders.

Auto-generated documentation stub for function `DeleteEverythingButSomeFolders`.

### Parameters

- `baseFolderPattern` *(Parameter)*: baseFolderPattern.
- `keepFolders` *(Parameter)*: keepFolders.

### Returns

- **Variable**: Return value.


## `FindBigWaves`

**Signature**

```igorpro
FindBigWaves(variable minSizeInMB[,DFREF df,variable depth,variable noShow])
```

Description of FindBigWaves.

Auto-generated documentation stub for function `FindBigWaves`.

### Parameters

- `minSizeInMB[` *(Parameter)*: minSizeInMB[.
- `df` *(Parameter)*: df.
- `depth` *(Parameter)*: depth.
- `noShow]` *(Parameter)*: noShow].

### Returns

- **Variable**: Return value.


## `AllWavesSamePathQ`

**Signature**

```igorpro
AllWavesSamePathQ(WAVE/WAVE wWAVEList)
```

Description of AllWavesSamePathQ.

Auto-generated documentation stub for function `AllWavesSamePathQ`.

### Parameters

- `wWAVEList` *(Parameter)*: wWAVEList.

### Returns

- **Variable**: Return value.


## `BackupWaveInWaveDF`

**Signature**

```igorpro
BackupWaveInWaveDF(WAVE wref)
```

Description of BackupWaveInWaveDF.

Auto-generated documentation stub for function `BackupWaveInWaveDF`.

### Parameters

- `wref` *(Parameter)*: wref.

### Returns

- **String**: Return value.


## `BackupWaveInWaveDFQ`

**Signature**

```igorpro
BackupWaveInWaveDFQ(WAVE wref)
```

Description of BackupWaveInWaveDFQ.

Auto-generated documentation stub for function `BackupWaveInWaveDFQ`.

### Parameters

- `wref` *(Parameter)*: wref.

### Returns

- **String**: Return value.


## `GetAllWavesStrDF`

**Signature**

```igorpro
GetAllWavesStrDF(DFREF dfr)
```

Description of GetAllWavesStrDF.

Auto-generated documentation stub for function `GetAllWavesStrDF`.

### Parameters

- `dfr` *(Parameter)*: dfr.

### Returns

- **String**: Return value.
