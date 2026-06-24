# ATH_TextWaves

**Source file:** `Utilities/ATH_TextWaves.ipf`

Module ATH_TextWaves.

This module belongs to the ATH Igor Pro toolkit and contains procedures
related to ATH TextWaves functionality.

```{contents}
:local:
:depth: 2
```

## `TWaveRemoveEntriesFromPatters`

**Signature**

```igorpro
TWaveRemoveEntriesFromPatters(WAVE/T textW, string patternStr, [WAVE otherW])
```

Remove text-wave entries whose values match any supplied pattern.

Remove entries from textW that start with pathbase. Optionally we can remove the same entries from
another wave otherW. We use this in ATH_LaunchDeleteBigWaves.

### Parameters

- `textW` *(Wave/T)*: Input text wave.
- `patternStr` *(String)*: Text containing the pattern str.
- `otherW` *(Wave, optional)*: Second text wave used for comparison or concatenation.

### Returns

- **Variable**: Zero after completing the operation.


## `DeleteWavesInTextWave`

**Signature**

```igorpro
DeleteWavesInTextWave(WAVE/T textW)
```

Remove waves in text wave.

Delete big waves listed in textW.

### Parameters

- `textW` *(Wave/T)*: Input text wave.

### Returns

- **Variable**: Zero after completing the operation.


## `TextWaveToString`

**Signature**

```igorpro
TextWaveToString(WAVE/T textW, [string sep])
```

Text wave to string.

Make a string from a textwave.

### Parameters

- `textW` *(Wave/T)*: Input text wave.
- `sep` *(String, optional)*: Delimiter used between list items.

### Returns

- **String**: The resulting string; an empty string indicates that no result was available.


## `StringListToTextWave`

**Signature**

```igorpro
StringListToTextWave(string stringListStr, string sep)
```

String list to text wave.

### Parameters

- `stringListStr` *(String)*: Text containing the string list str.
- `sep` *(String)*: Delimiter used between list items.

### Returns

- **Wave**: Reference to the result wave; a null reference indicates failure where supported.


## `TWaveRemoveEntriesFromStringList`

**Signature**

```igorpro
TWaveRemoveEntriesFromStringList(WAVE/T textW, string stringListStr, [WAVE otherW])
```

Remove text-wave entries listed in a delimited string.

Remove entries from textW in stringListStr. Optionally we can remove the same entries from another wave
otherW. We use this in ATH_LaunchDeleteBigWavesDisplayed.

### Parameters

- `textW` *(Wave/T)*: Input text wave.
- `stringListStr` *(String)*: Text containing the string list str.
- `otherW` *(Wave, optional)*: Second text wave used for comparison or concatenation.

### Returns

- **Variable**: Zero after completing the operation.
