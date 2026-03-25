# ATH_FuncFit

**Source file:** `Analysis/ATH_FuncFit.ipf`

Fit functions for spectroscopy, XMLD, and image-shape analysis.

This module collects Igor Pro fit functions used by the ATH analysis package.
It includes Fermi-edge models, XAS step backgrounds, angular XMLD models,
a 2D Gaussian model, and a simple focus calibration relation.

```{contents}
:local:
:depth: 2
```

## `FitFermiEdge`

**Signature**

```igorpro
FitFermiEdge(WAVE w, variable x)
```

Fermi edge model with constant offset.

Returns `y0 + 1 / (exp((E - Ef) / kT) + 1)` for scalar fitting in Igor's
curve fitting framework.

### Parameters

- `w` *(Wave)*: Coefficient wave with `w[0]=y0`, `w[1]=Ef`, and `w[2]=kT`.
- `x` *(Variable)*: Energy value at which the model is evaluated.

### Returns

- **Variable**: Model value at `x`.


## `FitFermiEdgeTimesLine`

**Signature**

```igorpro
FitFermiEdgeTimesLine(WAVE w, variable x)
```

Fermi edge model multiplied by a linear term and shifted by an offset.

Returns `y0 + (a*x + b) / (exp((x - Ef) / kT) + 1)` for use with Igor curve fitting.

### Parameters

- `w` *(Wave)*: Coefficient wave with `w[0]=y0`, `w[1]=Ef`, `w[2]=kT`, `w[3]=b`, and `w[4]=a`.
- `x` *(Variable)*: Energy value at which the model is evaluated.

### Returns

- **Variable**: Model value at `x`.


## `FitXASStepBackground`

**Signature**

```igorpro
FitXASStepBackground(WAVE w, variable E)
```

Two-step arctangent background model for XAS spectra.

Models the L3 and L2 edge-step contributions using two broadened arctangent
functions plus a constant baseline.

### Parameters

- `w` *(Wave)*: Coefficient wave containing baseline, height, edge positions, and widths.
- `E` *(Variable)*: Energy value at which the model is evaluated.

### Returns

- **Variable**: Model value at `E`.


## `FitFermiEdgeGaussianConvolution`

**Signature**

```igorpro
FitFermiEdgeGaussianConvolution(WAVE pw, WAVE yw, WAVE xw)
```

Fermi-Dirac edge broadened by Gaussian convolution.

Generates a Fermi-Dirac edge in `yw`, convolves it with a Gaussian kernel
defined by the FWHM in `pw[3]`, and then adds a linear background.

### Parameters

- `pw` *(Wave)*: Parameter wave with offset, slope, temperature, Gaussian width, amplitude, and edge location.
- `yw` *(Wave)*: Output wave that is overwritten with the calculated fit values.
- `xw` *(Wave)*: X wave associated with `yw`.

### Returns

- **Variable**: FitFunc output as required by Igor; the computed values are written to `yw`.

```{note}
`yw` is overwritten. Temporary waves are created during convolution.
```


## `XMLDSinSqIntensity`

**Signature**

```igorpro
XMLDSinSqIntensity(WAVE pw, WAVE yw, WAVE xw)
```

XMLD angular intensity model using a squared sine term.

### Parameters

- `pw` *(Wave)*: Coefficient wave with baseline, amplitude, and phase.
- `yw` *(Wave)*: Output wave that receives the calculated model values.
- `xw` *(Wave)*: Angular coordinate wave.

### Returns

- **Variable**: FitFunc output as required by Igor; the computed values are written to `yw`.


## `XMLDCosSqIntensity`

**Signature**

```igorpro
XMLDCosSqIntensity(WAVE pw, WAVE yw, WAVE xw)
```

XMLD angular intensity model using a squared cosine term.

### Parameters

- `pw` *(Wave)*: Coefficient wave with baseline, amplitude, and phase.
- `yw` *(Wave)*: Output wave that receives the calculated model values.
- `xw` *(Wave)*: Angular coordinate wave.

### Returns

- **Variable**: FitFunc output as required by Igor; the computed values are written to `yw`.


## `XMLDSin2xIntensity`

**Signature**

```igorpro
XMLDSin2xIntensity(WAVE pw, WAVE yw, WAVE xw)
```

XMLD angular intensity model using `sin(2*(x+phase))`.

### Parameters

- `pw` *(Wave)*: Coefficient wave with baseline, amplitude, and phase.
- `yw` *(Wave)*: Output wave that receives the calculated model values.
- `xw` *(Wave)*: Angular coordinate wave.

### Returns

- **Variable**: FitFunc output as required by Igor; the computed values are written to `yw`.


## `XMLDCos2xIntensity`

**Signature**

```igorpro
XMLDCos2xIntensity(WAVE pw, WAVE yw, WAVE xw)
```

XMLD angular intensity model using `cos(2*(x+phase))`.

### Parameters

- `pw` *(Wave)*: Coefficient wave with baseline, amplitude, and phase.
- `yw` *(Wave)*: Output wave that receives the calculated model values.
- `xw` *(Wave)*: Angular coordinate wave.

### Returns

- **Variable**: FitFunc output as required by Igor; the computed values are written to `yw`.


## `XMLDIntensityWtGradient`

**Signature**

```igorpro
XMLDIntensityWtGradient(WAVE pw, WAVE yw, WAVE xw)
```

XMLD angular intensity model with an added linear gradient term.

### Parameters

- `pw` *(Wave)*: Coefficient wave with baseline, gradient, amplitude, and phase.
- `yw` *(Wave)*: Output wave that receives the calculated model values.
- `xw` *(Wave)*: Angular coordinate wave.

### Returns

- **Variable**: FitFunc output as required by Igor; the computed values are written to `yw`.


## `Gaussian2D`

**Signature**

```igorpro
Gaussian2D(WAVE pw, WAVE yw, WAVE wx, WAVE wy)
```

2D Gaussian model for fitting flattened image data.

Evaluates a rotated 2D Gaussian plus constant background using separate x and y
coordinate waves. This function is intended for use with Igor's all-at-once fitting.

### Parameters

- `pw` *(Wave)*: Parameter wave with background, amplitude, angle in radians, center coordinates, and standard deviations.
- `yw` *(Wave)*: Output wave that receives the calculated model values.
- `wx` *(Wave)*: X coordinate wave.
- `wy` *(Wave)*: Y coordinate wave.

### Returns

- **Variable**: FitFunc output as required by Igor; the computed values are written to `yw`.


## `FocusSTV`

**Signature**

```igorpro
FocusSTV(WAVE pw, WAVE yw, WAVE xw)
```

Square-root focus calibration model.

Returns `f0 + a*sqrt(STV)` for use in curve fitting.

### Parameters

- `pw` *(Wave)*: Coefficient wave with `pw[0]=f0` and `pw[1]=a`.
- `yw` *(Wave)*: Output wave that receives the calculated model values.
- `xw` *(Wave)*: Input STV values.

### Returns

- **Variable**: FitFunc output as required by Igor; the computed values are written to `yw`.
