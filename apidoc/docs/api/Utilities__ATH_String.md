# ATH_String

**Source file:** `Utilities/ATH_String.ipf`

Module ATH_String.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH String functionality.

```{contents}
:local:
:depth: 2
```

## `ExpandRangeStr`

**Signature**

```igorpro
ExpandRangeStr(string rangeStr)
```

Description of ExpandRangeStr.

Auto-generated documentation stub for function `ExpandRangeStr`.

### Parameters

- `rangeStr` *(Parameter)*: rangeStr.

### Returns

- **String**: Return value.


## `GetPhotonEnergyFromFilename`

**Signature**

```igorpro
GetPhotonEnergyFromFilename(string nameStr)
```

Description of GetPhotonEnergyFromFilename.

Auto-generated documentation stub for function `GetPhotonEnergyFromFilename`.

### Parameters

- `nameStr` *(Parameter)*: nameStr.

### Returns

- **Variable**: Return value.


## `UniquifyStringList`

**Signature**

```igorpro
UniquifyStringList(string stringListStr, string sep)
```

Description of UniquifyStringList.

Auto-generated documentation stub for function `UniquifyStringList`.

### Parameters

- `stringListStr` *(Parameter)*: stringListStr.
- `sep` *(Parameter)*: sep.

### Returns

- **String**: Return value.


## `isLiberalQ`

**Signature**

```igorpro
isLiberalQ(string str)
```

Description of isLiberalQ.

Auto-generated documentation stub for function `isLiberalQ`.

### Parameters

- `str` *(Parameter)*: str.

### Returns

- **Variable**: Return value.


## `StringToNonLiberal`

**Signature**

```igorpro
StringToNonLiberal(string str)
```

Description of StringToNonLiberal.

Auto-generated documentation stub for function `StringToNonLiberal`.

### Parameters

- `str` *(Parameter)*: str.

### Returns

- **String**: Return value.


## `isEXTWindow`

**Signature**

```igorpro
isEXTWindow(string str)
```

Description of isEXTWindow.

Auto-generated documentation stub for function `isEXTWindow`.

### Parameters

- `str` *(Parameter)*: str.

### Returns

- **Variable**: Return value.


## `isPathStringLegalQ`

**Signature**

```igorpro
isPathStringLegalQ(string path)
```

Description of isPathStringLegalQ.

Auto-generated documentation stub for function `isPathStringLegalQ`.

### Parameters

- `path` *(Parameter)*: path.

### Returns

- **Variable**: Return value.


## `ExtendPathStr`

**Signature**

```igorpro
ExtendPathStr(string str, string ext)
```

Description of ExtendPathStr.

Auto-generated documentation stub for function `ExtendPathStr`.

### Parameters

- `str` *(Parameter)*: str.
- `ext` *(Parameter)*: ext.

### Returns

- **String**: Return value.


## `InsertListAtPosition`

**Signature**

```igorpro
InsertListAtPosition(string listStr, string insertList, variable pos, [string sep])
```

Description of InsertListAtPosition.

Auto-generated documentation stub for function `InsertListAtPosition`.

### Parameters

- `listStr` *(Parameter)*: listStr.
- `insertList` *(Parameter)*: insertList.
- `pos` *(Parameter)*: pos.
- `sep]` *(Parameter)*: sep].

### Returns

- **String**: Return value.


## `RemoveFileExtention`

**Signature**

```igorpro
RemoveFileExtention(string str)
```

Description of RemoveFileExtention.

Auto-generated documentation stub for function `RemoveFileExtention`.

### Parameters

- `str` *(Parameter)*: str.

### Returns

- **String**: Return value.


## `StartsWith`

**Signature**

```igorpro
StartsWith(string str, string part)
```

Description of StartsWith.

Auto-generated documentation stub for function `StartsWith`.

### Parameters

- `str` *(Parameter)*: str.
- `part` *(Parameter)*: part.

### Returns

- **Variable**: Return value.


## `EndsWith`

**Signature**

```igorpro
EndsWith(string str, string part)
```

Description of EndsWith.

Auto-generated documentation stub for function `EndsWith`.

### Parameters

- `str` *(Parameter)*: str.
- `part` *(Parameter)*: part.

### Returns

- **Variable**: Return value.


## `WaveLogging`

**Signature**

```igorpro
WaveLogging(Wave wRef, string msg, [int prepend])
```

Description of WaveLogging.

Auto-generated documentation stub for function `WaveLogging`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `msg` *(Parameter)*: msg.
- `prepend]` *(Parameter)*: prepend].

### Returns

- **Variable**: Return value.


## `WaveToString`

**Signature**

```igorpro
WaveToString(WAVE w, [string sep])
```

Description of WaveToString.

Auto-generated documentation stub for function `WaveToString`.

### Parameters

- `w` *(Parameter)*: w.
- `sep]` *(Parameter)*: sep].

### Returns

- **String**: Return value.


## `GetSelectedWaveNamesinDB`

**Signature**

```igorpro
GetSelectedWaveNamesinDB()
```

Description of GetSelectedWaveNamesinDB.

Auto-generated documentation stub for function `GetSelectedWaveNamesinDB`.

### Returns

- **String**: Return value.


## `AppendToStringList`

**Signature**

```igorpro
AppendToStringList(string base, string strlist, [string sep, int rev])
```

Description of AppendToStringList.

Auto-generated documentation stub for function `AppendToStringList`.

### Parameters

- `base` *(Parameter)*: base.
- `strlist` *(Parameter)*: strlist.
- `sep` *(Parameter)*: sep.
- `rev]` *(Parameter)*: rev].

### Returns

- **String**: Return value.


## `GetRangeItemsFromList`

**Signature**

```igorpro
GetRangeItemsFromList(string listStr, string listSep, int startIndex, int endIndex)
```

Description of GetRangeItemsFromList.

Auto-generated documentation stub for function `GetRangeItemsFromList`.

### Parameters

- `listStr` *(Parameter)*: listStr.
- `listSep` *(Parameter)*: listSep.
- `startIndex` *(Parameter)*: startIndex.
- `endIndex` *(Parameter)*: endIndex.

### Returns

- **String**: Return value.


## `RemoveCharFromString`

**Signature**

```igorpro
RemoveCharFromString(string str, string cc)
```

Description of RemoveCharFromString.

Auto-generated documentation stub for function `RemoveCharFromString`.

### Parameters

- `str` *(Parameter)*: str.
- `cc` *(Parameter)*: cc.

### Returns

- **String**: Return value.


## `ComposeWaveListsFromWaveNotes`

**Signature**

```igorpro
ComposeWaveListsFromWaveNotes(string wavelistStr, [string sep])
```

Description of ComposeWaveListsFromWaveNotes.

Auto-generated documentation stub for function `ComposeWaveListsFromWaveNotes`.

### Parameters

- `wavelistStr` *(Parameter)*: wavelistStr.
- `sep]` *(Parameter)*: sep].

### Returns

- **String**: Return value.


## `GetStackNamesFromNote`

**Signature**

```igorpro
GetStackNamesFromNote(WAVE wref)
```

Description of GetStackNamesFromNote.

Auto-generated documentation stub for function `GetStackNamesFromNote`.

### Parameters

- `wref` *(Parameter)*: wref.

### Returns

- **String**: Return value.


## `SetStackNamesInNote`

**Signature**

```igorpro
SetStackNamesInNote(WAVE wref, string waveNamesList,[string listSepI,string listSepW])
```

Description of SetStackNamesInNote.

Auto-generated documentation stub for function `SetStackNamesInNote`.

### Parameters

- `wref` *(Parameter)*: wref.
- `waveNamesList` *(Parameter)*: waveNamesList.
- `listSepI` *(Parameter)*: listSepI.
- `listSepW]` *(Parameter)*: listSepW].

### Returns

- **Variable**: Return value.


## `StackNamesInNoteStr`

**Signature**

```igorpro
StackNamesInNoteStr(string waveNamesList,[string listSep])
```

Description of StackNamesInNoteStr.

Auto-generated documentation stub for function `StackNamesInNoteStr`.

### Parameters

- `waveNamesList` *(Parameter)*: waveNamesList.
- `listSep]` *(Parameter)*: listSep].

### Returns

- **String**: Return value.


## `GetStackNamesForWaveNote`

**Signature**

```igorpro
GetStackNamesForWaveNote(WAVE wRef, int op, [string rangeStr, string wlist, string noteStr])
```

Description of GetStackNamesForWaveNote.

Auto-generated documentation stub for function `GetStackNamesForWaveNote`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `op` *(Parameter)*: op.
- `rangeStr` *(Parameter)*: rangeStr.
- `wlist` *(Parameter)*: wlist.
- `noteStr]` *(Parameter)*: noteStr].

### Returns

- **String**: Return value.


## `UpdateStackWaveNote`

**Signature**

```igorpro
UpdateStackWaveNote(WAVE wRef, int op, [string rangeStr, string wlist, string noteStr, string explicitWaveList])
```

Description of UpdateStackWaveNote.

Auto-generated documentation stub for function `UpdateStackWaveNote`.

### Parameters

- `wRef` *(Parameter)*: wRef.
- `op` *(Parameter)*: op.
- `rangeStr` *(Parameter)*: rangeStr.
- `wlist` *(Parameter)*: wlist.
- `noteStr` *(Parameter)*: noteStr.
- `explicitWaveList]` *(Parameter)*: explicitWaveList].

### Returns

- **Variable**: Return value.
