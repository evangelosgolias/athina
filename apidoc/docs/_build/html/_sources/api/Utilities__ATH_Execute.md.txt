# ATH_Execute

**Source file:** `Utilities/ATH_Execute.ipf`

Module ATH_Execute.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH Execute functionality.

```{contents}
:local:
:depth: 2
```

## `ExecuteShellCommand`

**Signature**

```igorpro
ExecuteShellCommand(uCommand, printCommandInHistory, printResultInHistory [, asAdmin])
```

Execute shell command.

Copy of Wavemetrics procedure.

### Parameters

- `uCommand` *(Variable)*: Igor command to execute.
- `printCommandInHistory` *(Variable)*: If nonzero, echo the command to Igor's history.
- `printResultInHistory` *(Variable, optional)*: If nonzero, print the command result to history.
- `asAdmin` *(Variable, optional)*: If nonzero, request administrator execution where supported.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `CmdExecutionUsingRange`

**Signature**

```igorpro
CmdExecutionUsingRange(string cmdStr, string rangeStr)
```

Cmd execution using range.

Execute cmdStr with parameters the numbers in rangeStr. See ATH_ExpandRangeStr doc string. e.g.:
ATH_CmdExecutionUsingRange("NewDataFolder 'FLDR#%s'", "2,3,11-14").

### Parameters

- `cmdStr` *(String)*: Text containing the cmd str.
- `rangeStr` *(String)*: Range str.

### Returns

- **Variable**: Zero after completing the operation.


## `CmdExecutionInFolderWithPattern`

**Signature**

```igorpro
CmdExecutionInFolderWithPattern(string cmdStr, string pattern)
```

Cmd execution in folder with pattern.

Execute cmdStr for wavelist using pattern e.g.: ATH_CmdExecutionInFolderWithPattern("NewDataFolder",
"waveP*").

### Parameters

- `cmdStr` *(String)*: Text containing the cmd str.
- `pattern` *(String)*: Pattern used to select names or files.

### Returns

- **Variable**: Zero after completing the operation.


## `HandleSimpleError`

**Signature**

```igorpro
HandleSimpleError(string funName)
```

Handle simple error.

Handle execution error, clear and print a message.

### Parameters

- `funName` *(String)*: Fun name.

### Returns

- **Variable**: Igor status code: zero on completion; nonzero reports cancellation, invalid input, or failure.


## `GetAndExecuteNoteEntry`

**Signature**

```igorpro
GetAndExecuteNoteEntry(WAVE wRef, string entry, [string sep, string listsep])
```

Return and execute note entry.

Retrieve string entry from wRef note (use sep).

### Parameters

- `wRef` *(Wave)*: Input wave.
- `entry` *(String)*: Wave-note key or entry to retrieve and execute.
- `sep` *(String, optional)*: Delimiter used between list items.
- `listsep` *(String, optional)*: Delimiter used by the input or output list.

### Returns

- **Variable**: Zero after completing the operation.
