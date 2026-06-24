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

Expand a compact integer-range expression into an Igor string list.

Expand a string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50" now check str to see if it is a range
like "20-23".

### Parameters

- `rangeStr` *(String)*: Range str.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `GetPhotonEnergyFromFilename`

**Signature**

```igorpro
GetPhotonEnergyFromFilename(string nameStr)
```

Return photon energy from filename.

MAXPEEM specific: extract the photon energy from the filename and return it as number regex compiles the
most common ways of writing the energy in a filename.

### Parameters

- `nameStr` *(String)*: Name str.

### Returns

- **Variable**: The returned value is photon energy from filename.


## `UniquifyStringList`

**Signature**

```igorpro
UniquifyStringList(string stringListStr, string sep)
```

Remove duplicate items from a delimited string list.

Remove duplicates from a sting list. Remove duplicates.

### Parameters

- `stringListStr` *(String)*: Text containing the string list str.
- `sep` *(String)*: Delimiter used between list items.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `isLiberalQ`

**Signature**

```igorpro
isLiberalQ(string str)
```

Test whether a string is invalid as an Igor liberal object name.

Checks if a string is liberal. Returns 0 for empty string.

### Parameters

- `str` *(String)*: Text containing the str.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `StringToNonLiberal`

**Signature**

```igorpro
StringToNonLiberal(string str)
```

Convert arbitrary text into a valid Igor liberal object name.

### Parameters

- `str` *(String)*: Text containing the str.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `isEXTWindow`

**Signature**

```igorpro
isEXTWindow(string str)
```

Test whether a window name identifies an external window.

### Parameters

- `str` *(String)*: Text containing the str.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `isPathStringLegalQ`

**Signature**

```igorpro
isPathStringLegalQ(string path)
```

Test whether a string is a syntactically valid Igor data-folder path.

### Parameters

- `path` *(String)*: Path.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `ExtendPathStr`

**Signature**

```igorpro
ExtendPathStr(string str, string ext)
```

Append a child component to an Igor data-folder path.

Add ext to s, which is usually a full path to a wave. Works for liberal and proper paths. Add
ksATHBackupWaveExtention to the root:'2434w' -> root:'2434w_undo' !.

### Parameters

- `str` *(String)*: Text containing the str.
- `ext` *(String)*: File-name extension.

### Returns

- **String**: The resulting path string, or an empty string when it cannot be determined.


## `InsertListAtPosition`

**Signature**

```igorpro
InsertListAtPosition(string listStr, string insertList, variable pos, [string sep])
```

Insert list at position.

We insert list insertList at the position pos of listStr. the element at pos is moved and becomes the
first after the last element of insertList.

### Parameters

- `listStr` *(String)*: Text containing the list str.
- `insertList` *(String)*: List of items to insert.
- `pos` *(Variable)*: Zero-based insertion position.
- `sep` *(String, optional)*: Delimiter used between list items.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `RemoveFileExtention`

**Signature**

```igorpro
RemoveFileExtention(string str)
```

Remove the final extension from a file name.

### Parameters

- `str` *(String)*: Text containing the str.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `StartsWith`

**Signature**

```igorpro
StartsWith(string str, string part)
```

Test whether a string starts with a given substring.

### Parameters

- `str` *(String)*: Text containing the str.
- `part` *(String)*: Prefix or suffix text to test for.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `EndsWith`

**Signature**

```igorpro
EndsWith(string str, string part)
```

Test whether a string ends with a given substring.

### Parameters

- `str` *(String)*: Text containing the str.
- `part` *(String)*: Prefix or suffix text to test for.

### Returns

- **Variable**: Nonzero when the condition is satisfied; otherwise zero.


## `WaveLogging`

**Signature**

```igorpro
WaveLogging(Wave wRef, string msg, [int prepend])
```

Wave logging.

Add str to the note of wRef. Use prepend = 1 to add string at the start.

### Parameters

- `wRef` *(Wave)*: Input wave.
- `msg` *(String)*: Message shown to the user.
- `prepend` *(Integer, optional)*: If nonzero, insert the new text before the existing list.

### Returns

- **Variable**: Zero after completing the operation.


## `WaveToString`

**Signature**

```igorpro
WaveToString(WAVE w, [string sep])
```

Wave to string.

Make a string from a textwave.

### Parameters

- `w` *(Wave)*: to modify in place.
- `sep` *(String, optional)*: Delimiter used between list items.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `GetSelectedImagesinDB`

**Signature**

```igorpro
GetSelectedImagesinDB()
```

Return the names of waves selected in the Data Browser.

### Returns

- **String**: The resulting name, or an empty string when no match is available.


## `GetSelectedWavesinDB`

**Signature**

```igorpro
GetSelectedWavesinDB([variable dim])
```

Return references to waves selected in the Data Browser.

### Parameters

- `dim` *(Variable, optional)*: Zero-based wave-dimension index.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `AppendToStringList`

**Signature**

```igorpro
AppendToStringList(string base, string strlist, [string sep, int rev])
```

Append to string list.

Append on prepand the string base to each item in strList.

### Parameters

- `base` *(String)*: Base string used to build the result.
- `strlist` *(String)*: Input string list.
- `sep` *(String, optional)*: Delimiter used between list items.
- `rev` *(Integer, optional)*: If nonzero, reverse the requested order or color table.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `ThreadStr`

**Signature**

```igorpro
ThreadStr(string strlist0, string strlist1, [string joinstr, string sep, string listsep0, string listsep1])
```

Combine corresponding items from two string lists.

### Parameters

- `strlist0` *(String)*: First input string list.
- `strlist1` *(String)*: Second input string list.
- `joinstr` *(String, optional)*: Text inserted between the paired list items.
- `sep` *(String, optional)*: String-list delimiter.
- `listsep0` *(String, optional)*: Delimiter for the first input list.
- `listsep1` *(String, optional)*: Delimiter for the second input list.

### Returns

- **String**: A string list containing the paired and joined items.


## `RemoveIndexKeysFromList`

**Signature**

```igorpro
RemoveIndexKeysFromList(string listStr, [string keySep, string listSep, int startIndex])
```

Remove numeric index prefixes from a keyed string list.

### Parameters

- `listStr` *(String)*: List str.
- `keySep` *(String, optional)*: Delimiter between an index key and its value.
- `listSep` *(String, optional)*: String-list delimiter.
- `startIndex` *(Integer, optional)*: Smallest numeric key to remove.

### Returns

- **String**: The input list with matching numeric key prefixes removed.


## `GetRangeItemsFromList`

**Signature**

```igorpro
GetRangeItemsFromList(string listStr, string listSep, int startIndex, int endIndex)
```

Return range items from list.

Get the items from startIndex to endIndex from a list with listSep.

### Parameters

- `listStr` *(String)*: Text containing the list str.
- `listSep` *(String)*: Delimiter used by the input or output list.
- `startIndex` *(Integer)*: Lower or starting start index.
- `endIndex` *(Integer)*: Upper or ending end index.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `RemoveCharFromString`

**Signature**

```igorpro
RemoveCharFromString(string str, string cc)
```

Remove char from string.

Remove the character cc from string str.

### Parameters

- `str` *(String)*: Text containing the str.
- `cc` *(String)*: Character or character code to test.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `ComposeWaveListsFromWaveNotes`

**Signature**

```igorpro
ComposeWaveListsFromWaveNotes(string wavelistStr, [string sep])
```

Compose wave lists from wave notes.

Given a list of 2D/3D waves in wavelist compose a wave list with all waves: names and add them to the
list. At the end you will end up with a list of all 2D waves in the list of wavelistStr.

### Parameters

- `wavelistStr` *(String)*: Wave used by the operation.
- `sep` *(String, optional)*: Delimiter used between list items.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `GetStackNamesFromNote`

**Signature**

```igorpro
GetStackNamesFromNote(WAVE wref)
```

Return stack names from note.

Get the stings with the pathnames of all layers stacked in wave.

### Parameters

- `wref` *(Wave)*: Input wave.

### Returns

- **String**: The resulting name, or an empty string when no match is available.


## `SetStackNamesInNote`

**Signature**

```igorpro
SetStackNamesInNote(WAVE wref, string waveNamesList,[string listSepI,string listSepW])
```

Set stack names in note.

Add list of stacked waves to wRef. Special listSep=";" as by default most functions send lists with ";"
sep. listSepI: sep the indices (usually ";").

### Parameters

- `wref` *(Wave)*: Input wave.
- `waveNamesList` *(String)*: Wave used by the operation.
- `listSepI` *(String, optional)*: Delimiter used by the input list.
- `listSepW` *(String, optional)*: Delimiter used by the wave-name list.

### Returns

- **Variable**: Zero after completing the operation.


## `StackNamesInNoteStr`

**Signature**

```igorpro
StackNamesInNoteStr(string waveNamesList,[string listSep])
```

Format a stack's source-wave names for storage in a wave note.

Add list of stacked waves to wRef NB. indices sep is ";", waveNameList is "\n".

### Parameters

- `waveNamesList` *(String)*: Wave used by the operation.
- `listSep` *(String, optional)*: Delimiter used by the input or output list.

### Returns

- **String**: The resulting name, or an empty string when no match is available.


## `GetStackNamesForWaveNote`

**Signature**

```igorpro
GetStackNamesForWaveNote(WAVE wRef, int op, [string rangeStr, string wlist, string noteStr])
```

Return stack names for wave note.

Add/remove layer names in wave note, update the note in wRef rangeStr can be "2-5,7,9-12,50" expand a
string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50".

### Parameters

- `wRef` *(Wave)*: Input wave.
- `op` *(Integer)*: Operation selector.
- `rangeStr` *(String, optional)*: Range str.
- `wlist` *(String, optional)*: List of wave names.
- `noteStr` *(String, optional)*: Text containing the note str.

### Returns

- **String**: The resulting name, or an empty string when no match is available.


## `UpdateStackWaveNote`

**Signature**

```igorpro
UpdateStackWaveNote(WAVE wRef, int op, [string rangeStr, string wlist, string noteStr, string explicitWaveList])
```

Update stack wave note.

Add/remove layer names in wave note, update the note in wRef rangeStr can be "2-5,7,9-12,50" expand a
string like "2-5,7,9-12,50" to "2;3;4;5;7;9;10;11;12;50".

### Parameters

- `wRef` *(Wave)*: Input wave.
- `op` *(Integer)*: Operation selector.
- `rangeStr` *(String, optional)*: Range str.
- `wlist` *(String, optional)*: List of wave names.
- `noteStr` *(String, optional)*: Text containing the note str.
- `explicitWaveList` *(String, optional)*: Wave used by the operation.

### Returns

- **Variable**: Zero after completing the operation.


## `RandomSampleStringList`

**Signature**

```igorpro
RandomSampleStringList(string list, variable sampleN)
```

Select a random sample from a string list without replacement.

Removes each selected item from the candidate list so an item cannot be chosen twice.

### Parameters

- `list` *(String)*: Input string list.
- `sampleN` *(Variable)*: Number of items to select.

### Returns

- **String**: A semicolon-separated sample, or an empty string if `sampleN` exceeds the list length.
