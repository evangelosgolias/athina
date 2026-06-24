# ATH_HDF5

**Source file:** `FileIO/ATH_HDF5.ipf`

Module ATH_HDF5.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH HDF5 functionality.

```{contents}
:local:
:depth: 2
```

## `ListHDF5Groups`

**Signature**

```igorpro
ListHDF5Groups()
```

List HDF5 groups.

Uses Igor's HDF5 operations and reports or propagates file-format errors to the caller.

### Returns

- **Variable**: Zero after completing the operation.


## `GetHDF5Groups`

**Signature**

```igorpro
GetHDF5Groups()
```

Return the groups contained in a user-selected HDF5 file.

### Returns

- **String**: A semicolon-separated list of HDF5 groups, or an empty string after cancellation.


## `LoadHDF5File`

**Signature**

```igorpro
LoadHDF5File(string filename)
```

Load HDF5 file.

Uses Igor's HDF5 operations and reports or propagates file-format errors to the caller.

### Parameters

- `filename` *(String)*: File name.

### Returns

- **Variable**: Zero after completing the operation.


## `LoadHDF5SpecificGroups`

**Signature**

```igorpro
LoadHDF5SpecificGroups(string groups)
```

Load HDF5 specific groups.

Uses Igor's HDF5 operations and reports or propagates file-format errors to the caller.

### Parameters

- `groups` *(String)*: Semicolon-separated list of HDF5 group names or indices to load.

### Returns

- **Variable**: Zero after completing the operation.


## `LoadHDF5SpecificGroupsNamesIndexed`

**Signature**

```igorpro
LoadHDF5SpecificGroupsNamesIndexed(string idxstr, [string strFix])
```

Load HDF5 specific groups names indexed.

String should be in the form "2-5,7,9-12,50" PRM: Assume entryXX as group name, change here if needed.

### Parameters

- `idxstr` *(String)*: Comma-separated group indices and inclusive index ranges.
- `strFix` *(String, optional)*: Prefix prepended to each numeric group index.

### Returns

- **Variable**: Zero after completing the operation.


## `LoadHDF5SpecificGroupsFromPath`

**Signature**

```igorpro
LoadHDF5SpecificGroupsFromPath(String groups, String filename_fullpathstr)
```

Load HDF5 specific groups from path.

String should be in the form "2-5,7,9-12,50". Load files faster from a specific file, you need to specify
the full path to the datafile. PRM: Assure entryXX as group name, change here if needed.

### Parameters

- `groups` *(String)*: Semicolon-separated list of HDF5 group names or indices to load.
- `filename_fullpathstr` *(String)*: Full path of the HDF5 file to open.

### Returns

- **Variable**: Zero after completing the operation.


## `GetHDF5SingleFilePath`

**Signature**

```igorpro
GetHDF5SingleFilePath()
```

Prompt for one HDF5 file and return its full path.

### Returns

- **String**: The selected HDF5 file path, or an empty string after cancellation.


## `ListHDF5GroupsFID`

**Signature**

```igorpro
ListHDF5GroupsFID(Variable fileid)
```

Print a sorted list of groups in an open HDF5 file.

Lists all entries in file.

### Parameters

- `fileid` *(Variable)*: Open HDF5 file identifier.

### Returns

- **Variable**: Zero after completing the operation.


## `GetHDF5GroupsFID`

**Signature**

```igorpro
GetHDF5GroupsFID(Variable fileid)
```

Return a sorted list of groups in an open HDF5 file.

### Parameters

- `fileid` *(Variable)*: Open HDF5 file identifier.

### Returns

- **String**: A sorted semicolon-separated list of groups in the open file.


## `LoadHDF5GroupFID`

**Signature**

```igorpro
LoadHDF5GroupFID(Variable fileid, String group)
```

Load one group from an open HDF5 file.

Uses Igor's HDF5 operations and reports or propagates file-format errors to the caller.

### Parameters

- `fileid` *(Variable)*: Open HDF5 file identifier.
- `group` *(String)*: Name or path of the HDF5 group.

### Returns

- **Variable**: Zero after completing the operation.


## `GetHDF5NumGroupsFID`

**Signature**

```igorpro
GetHDF5NumGroupsFID(Variable fileid)
```

Return the number of groups in an open HDF5 file.

Returns the number is entries in file. Functions to import datasets acquired at the I06 beamline at
Diamond (UK).

### Parameters

- `fileid` *(Variable)*: Open HDF5 file identifier.

### Returns

- **Variable**: The number of groups in the open HDF5 file.


## `LoadNXSXMCDDataSet`

**Signature**

```igorpro
LoadNXSXMCDDataSet()
```

Load XMCD/XAS datasets and metadata from an I06 NeXus file.

Load XMCD data acquired at i06 beamline at Diamond along with basic metadada, STV and FoV. Imported waves
are FoV-scaled.

### Returns

- **Variable**: Zero after completing the operation.


## `LoadNXSDataSets`

**Signature**

```igorpro
LoadNXSDataSets()
```

Load beamline datasets and basic metadata from an I06 NeXus file.

Load data acquired at i06 beamline at Diamond, XMCD or XAS along with basic metadada, STV and FoV. Rename
the folder here to avoid overwriting.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `LoadTVIPSH5Data`

**Signature**

```igorpro
LoadTVIPSH5Data(string filename)
```

Load tvipsh 5data.

Function to load the h5 datasets. Here we check whether the Path MAXPEEM_USER_ROOT_FOLDER is set. load
the file without opening the file browser.

### Parameters

- `filename` *(String)*: File name.

### Returns

- **Variable**: Zero after completing the operation.


## `LoadTVIPSH5Group`

**Signature**

```igorpro
LoadTVIPSH5Group(string filename, [string group])
```

Load tvipsh5 group.

Function to load the h5 datasets. Here we check whether the Path MAXPEEM_USER_ROOT_FOLDER is set. load
the file without opening the file browser.

### Parameters

- `filename` *(String)*: File name.
- `group` *(String, optional)*: Name or path of the HDF5 group.

### Returns

- **Variable**: Zero after completing the operation.


## `LoadTVIPSH5DataNetwork`

**Signature**

```igorpro
LoadTVIPSH5DataNetwork(variable scanID)
```

Load tvipsh 5data network.

Function to load the h5 datasets. Here we check whether the Path MAXPEEM_USER_ROOT_FOLDER is set. load
the file without opening the file browser.

### Parameters

- `scanID` *(Variable)*: Beamline scan identifier.

### Returns

- **Variable**: Zero after completing the operation.
