# ATH_IgorHook

**Source file:** `Utilities/ATH_IgorHook.ipf`

Module ATH_IgorHook.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH IgorHook functionality.

```{contents}
:local:
:depth: 2
```

## `BeforeFileOpenHook`

**Signature**

```igorpro
BeforeFileOpenHook(variable refNum, string fileNameStr, string pathNameStr, string fileTypeStr, string fileCreatorStr, variable fileKind)
```

Handle before file open hook events.

ATH_WAVELoadSingleDATFile(fileToOpen, "", autoscale = 1). Added on the 17.03.2023 to deal with a
corrupted file. AfterWindowCreatedHook - Used in Spaces to assign tags to new windows.

### Parameters

- `refNum` *(Variable)*: Igor file reference number.
- `fileNameStr` *(String)*: File name supplied by Igor.
- `pathNameStr` *(String)*: Path name str.
- `fileTypeStr` *(String)*: File-type identifier.
- `fileCreatorStr` *(String)*: File-creator identifier.
- `fileKind` *(Variable)*: Igor file-kind code.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `AfterWindowCreatedHook`

**Signature**

```igorpro
AfterWindowCreatedHook(string windowNameStr, variable winTypevar)
```

Handle after window created hook events.

Every window created is assigned to the active Space if the panel is there. Sanitize names.

### Parameters

- `windowNameStr` *(String)*: Window name str.
- `winTypevar` *(Variable)*: Igor window-type code.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.


## `AfterCompiledHook`

**Signature**

```igorpro
AfterCompiledHook()
```

Handle after compiled hook events.

### Returns

- **Variable**: Igor callback status; nonzero indicates that the event was handled.
