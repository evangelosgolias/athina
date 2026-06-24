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

Compute the 2D FFT.

Performs a 2D FFT, and stores the result in the source wave's data
folder using the suffix `_FFT`.

### Parameters

- `wRef` *(Wave)*: Input 2D wave.
- `mode` *(Integer, optional)*: FFT output mode:<br>mode = 1:	Default for complex output (default)<br>mode = 2:	Real output<br>mode = 3:	Magnitude<br>mode = 4:	Magnitude square<br>mode = 5:	Phase<br>mode = 6:	Scaled magnitude<br>mode = 7:	Scaled magnitude squared

### Returns

- **Wave**: WAVE Reference to the generated FFT wave


## `PhaseCorrelation`

**Signature**

```igorpro
PhaseCorrelation(WAVE wRef, WAVE wTest, [variable subpixel, variable filter, variable smth])
```

Compute the phase correlation between two images.

Forms a normalized cross-power spectrum, transforms it back to obtain the correlation peak, and measures the row and column displacement from the image center. Optional edge or sharpening filters can be applied before correlation; optional smoothing and a 2D Gaussian fit provide subpixel peak localization.

### Parameters

- `wRef` *(Wave)*: Reference image.
- `wTest` *(Wave)*: Image to register against `wRef`.
- `subpixel` *(Variable, optional)*: If nonzero, fit the correlation peak with a 2D Gaussian for subpixel displacement.
- `filter` *(Variable, optional)*: Preprocessing mode: 1 applies edge detection, 2 applies sharpening, and other values apply no filter.
- `smth` *(Variable, optional)*: Smoothing width applied to both dimensions of the correlation image.

### Returns

- **Complex**: displacement with row drift in the real component and column drift in the imaginary component.


## `HighLowScale`

**Signature**

```igorpro
HighLowScale(WAVE wRef, variable low, variable high)
```

Scale wave values into a specified numeric range.

Creates a new wave named `NameOfWave_scaled` using `MatrixOP scale(wRef, low, high)`.

### Parameters

- `wRef` *(Wave)*: Input wave to scale.
- `low` *(Variable)*: Lower bound of the target range
- `high` *(Variable)*: Upper bound of the target range

### Returns

- **Variable**: 0


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

- **Wave**: Wave containing the affine transformation coefficients.


## `MakeImageRegistrationParamsWave`

**Signature**

```igorpro
MakeImageRegistrationParamsWave(string wPathName, [variable nlayers])
```

Create an empty, dimension-labelled parameter wave for Igor image registration.

Allocates either one 22-element parameter vector or a 22-by-layer matrix and labels every parameter row from `dx` through `SNR`.

### Parameters

- `wPathName` *(String)*: Full data-folder path and name for the parameter wave.
- `nlayers` *(Variable, optional)*: Number of image layers; omit or pass zero to create a 1D parameter vector.

### Returns

- **Variable**: Zero after creating and labelling the wave.


## `MakeImageRegistrationParamsWaveForImageRegistration`

**Signature**

```igorpro
MakeImageRegistrationParamsWaveForImageRegistration(WAVE wRef)
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
