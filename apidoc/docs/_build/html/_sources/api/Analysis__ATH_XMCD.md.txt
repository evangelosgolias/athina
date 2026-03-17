# ATH_XMCD

**Source file:** `Analysis/ATH_XMCD.ipf`

XMCD/XMLD calculations for 2D images and 3D stacks.

This module provides helper routines for computing normalized contrast maps of the form
`(w1 - w2) / (w1 + w2)` for individual images, two-layer stacks, all pairwise layer
combinations, and specific four-layer acquisition schemes. It also includes a multithreaded
worker-based implementation for stack combinations.

```{contents}
:local:
:depth: 2
```

## `CalculateXMCDWAVE`

**Signature**

```igorpro
CalculateXMCDWAVE(WAVE w1, WAVE w2, [string outWave, WAVE wRef])
```

Compute a normalized XMCD/XMLD image from two input waves.

Calculates `(w1 - w2) / (w1 + w2)` after converting integer inputs to single
precision if needed. The result is written either to a named output wave or to
a provided destination wave reference.

### Parameters

- `w1` *(Wave)*: First input image.
- `w2` *(Wave)*: Second input image.
- `outWave` *(String)*: Optional output-wave name. Exactly one of `outWave` or `wRef` must be provided.
- `wRef` *(Wave)*: Optional destination wave reference. Exactly one of `outWave` or `wRef` must be provided.

### Returns

- **Wave**: Reference to the output wave. Returns a null wave reference on invalid argument usage.


## `CalculateXMCD`

**Signature**

```igorpro
CalculateXMCD(WAVE w1, WAVE w2)
```

Compute a normalized XMCD/XMLD image and save it in the current data folder.

Validates that the two waves have equal dimensions, computes
`(w1 - w2) / (w1 + w2)`, copies scales from `w1`, and attaches provenance notes.

### Parameters

- `w1` *(Wave)*: First input image.
- `w2` *(Wave)*: Second input image.

### Returns

- **Variable**: Returns 0 on success and -1 if the dimensions do not match.


## `StackToXMCD`

**Signature**

```igorpro
StackToXMCD(WAVE w3d, [string wnameStr])
```

Compute XMCD/XMLD from a two-layer stack.

Extracts the first two layers of `w3d` and computes `(w0 - w1) / (w0 + w1)`.
The output is written to `wXMCD` or to a user-specified wave name.

### Parameters

- `w3d` *(Wave)*: Input 3D wave with exactly two layers.
- `wnameStr` *(String)*: Optional output-wave name.

### Returns

- **Variable**: Returns 0 on success and 1 if the stack does not have exactly two layers.


## `CalculateXMCD3D`

**Signature**

```igorpro
CalculateXMCD3D(WAVE w3d1, WAVE w3d2)
```

Compute XMCD/XMLD layer by layer for two 3D stacks.

Computes `(w3d1 - w3d2) / (w3d1 + w3d2)` for all corresponding layers in two
equally sized 3D waves. Multithreaded `MatrixOP` is used for large stacks.

### Parameters

- `w3d1` *(Wave)*: First input 3D stack.
- `w3d2` *(Wave)*: Second input 3D stack.

### Returns

- **Variable**: Returns 0 on success and -1 if the input dimensions are incompatible.


## `CalculateXMCDComb`

**Signature**

```igorpro
CalculateXMCDComb(WAVE w3d)
```

Compute XMCD/XMLD for all pairwise layer combinations in a 3D stack.

Iterates over all unique layer pairs in `w3d`, computes a normalized contrast map
for each pair, and stacks the results into a new output wave.

### Parameters

- `w3d` *(Wave)*: Input 3D stack.

### Returns

- **Variable**: Returns 0 on success and -1 if `w3d` is not three-dimensional.

```{note}
The output stack is saved in the current data folder under a generated name based on `XMCD_Comb`.
```


## `XMCDStack4L`

**Signature**

```igorpro
XMCDStack4L(WAVE wRef, [string order, int overwrite, string outWave])
```

Compute a difference of two XMCD images from a four-layer stack.

Forms XMCD for layer pairs `(l0,l1)` and `(l2,l3)` according to `order`, then
subtracts the second XMCD image from the first. The result is written to `outWave`.

### Parameters

- `wRef` *(Wave)*: Input 3D stack with four layers.
- `order` *(String)*: Optional permutation string specifying layer order, default `0123`.
- `overwrite` *(Variable)*: Optional flag controlling whether an existing output wave may be overwritten.
- `outWave` *(String)*: Optional output-wave name.

### Returns

- **Variable**: Returns 0 on success and -1 on invalid input or output creation failure.


## `MultiThreadXMLDComb`

**Signature**

```igorpro
MultiThreadXMLDComb(WAVE w3D)
```

Multithreaded computation of XMCD/XMLD for all layer combinations.

Builds all unique layer-pair combinations, dispatches the work to
`XMCDCalculation_Worker`, then concatenates the returned free waves into a
combined output stack.

### Parameters

- `w3D` *(Wave)*: Input 3D stack.

### Returns

- **Variable**: Returns 0 on completion.

```{note}
The combined output is stored in the source wave's data folder using a generated `XMCD_Comb` name.
```


## `XMCDCalculation_Worker`

**Signature**

```igorpro
XMCDCalculation_Worker(WAVE w3D, string idxStr)
```

Thread-safe worker for a single pairwise XMCD/XMLD calculation.

Parses a layer-index pair from `idxStr`, extracts the corresponding layers from
`w3D`, computes `(w0 - w1) / (w0 + w1)`, and returns the result as a free wave.

### Parameters

- `w3D` *(Wave)*: Input 3D stack.
- `idxStr` *(String)*: Comma-separated layer indices specifying the pair to process.

### Returns

- **Wave**: Free wave containing the computed XMCD/XMLD image.
