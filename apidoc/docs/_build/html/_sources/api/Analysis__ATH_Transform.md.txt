# ATH_Transform

**Source file:** `Analysis/ATH_Transform.ipf`

Fourier and affine-transformation helpers for image processing.

This module contains utility routines for 2D FFT generation, value scaling,
affine mapping estimation from three point pairs, and conversion of affine
coefficients into the parameter-wave format expected by Igor's image-registration tools.

```{contents}
:local:
:depth: 2
```

## `FFT2D`

**Signature**

```igorpro
FFT2D(WAVE wRef, [int mode])
```

Compute the 2D FFT of an input wave.

Duplicates the input wave as a temporary complex wave, performs a 2D FFT, and
stores the result in the source wave's data folder using the suffix `_FFT`.

### Parameters

- `wRef` *(Wave)*: Input 2D wave.
- `mode` *(Variable)*: Optional FFT output mode passed to `FFT/OUT`.

### Returns

- **Wave**: Reference to the generated FFT wave.


## `HighLowScale`

**Signature**

```igorpro
HighLowScale(WAVE wRef, variable low, variable high)
```

Scale wave values into a specified numeric range.

Creates a new wave named `<input>_scaled` using `MatrixOP scale(wRef, low, high)`.

### Parameters

- `wRef` *(Wave)*: Input wave to scale.
- `low` *(Variable)*: Lower bound of the target range.
- `high` *(Variable)*: Upper bound of the target range.

### Returns

- **Variable**: Returns 0 on completion.


## `GetAffine2DMapping`

**Signature**

```igorpro
GetAffine2DMapping(WAVE src, WAVE dest)
```

Compute an affine transform from three source and destination point pairs.

Solves for the six affine coefficients that map the three points in `src` onto
the corresponding three points in `dest`.

### Parameters

- `src` *(Wave)*: Six-element source coordinate wave `{x1,y1,x2,y2,x3,y3}`.
- `dest` *(Wave)*: Six-element destination coordinate wave `{X1,Y1,X2,Y2,X3,Y3}`.

### Returns

- **Wave**: Free wave containing the affine coefficients.


## `MakeImageRegistrationParamsWave`

**Signature**

```igorpro
MakeImageRegistrationParamsWave(WAVE wRef)
```

Convert affine coefficients to an image-registration parameter wave.

Fills `W_ParamsOut` with the 22-element parameter layout used by Igor's
`ImageRegistration` operation, based on the affine coefficients in `wRef`.

### Parameters

- `wRef` *(Wave)*: Input wave containing affine transform coefficients.

### Returns

- **Variable**: Returns 0 on completion.

```{note}
Creates `W_ParamsOut` if it does not already exist and overwrites its contents.
```
