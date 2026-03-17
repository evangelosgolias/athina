# ATH_Func

**Source file:** `Analysis/ATH_Func.ipf`

Utility mathematical functions used by other ATH modules.

This module provides low-level helper functions for generating 2D Gaussian
intensity distributions. The routines are primarily used for image modeling
and fitting workflows in the ATH package.

```{contents}
:local:
:depth: 2
```

## `GenericGaussian2D`

**Signature**

```igorpro
GenericGaussian2D(WAVE wRef, variable ampl, variable phi, variable x0, variable y0, variable sx, variable sy)
```

Fill a 2D wave with a rotated Gaussian distribution.

Computes a 2D Gaussian centered at (`x0`, `y0`) with amplitude `ampl`,
standard deviations `sx` and `sy`, and in-plane rotation angle `phi` in degrees.
The result is written directly into `wRef`.

### Parameters

- `wRef` *(Wave)*: Destination 2D wave that receives the calculated Gaussian.
- `ampl` *(Variable)*: Peak amplitude of the Gaussian.
- `phi` *(Variable)*: Rotation angle in degrees with respect to the horizontal axis.
- `x0` *(Variable)*: X coordinate of the Gaussian center.
- `y0` *(Variable)*: Y coordinate of the Gaussian center.
- `sx` *(Variable)*: Standard deviation along the first principal axis.
- `sy` *(Variable)*: Standard deviation along the second principal axis.

### Returns

- **Variable**: Returns 0 on completion.

```{note}
The input wave is modified in place.
```


## `GenericGaussian2Dpw`

**Signature**

```igorpro
GenericGaussian2Dpw(WAVE wRef, WAVE pw)
```

Fill a 2D wave with a rotated Gaussian using a parameter wave.

Computes a 2D Gaussian plus constant background using values stored in `pw`.
The parameters are interpreted as:
`pw[0]` background, `pw[1]` amplitude, `pw[2]` angle in degrees,
`pw[3]` x center, `pw[4]` y center, `pw[5]` x standard deviation,
and `pw[6]` y standard deviation.

### Parameters

- `wRef` *(Wave)*: Destination 2D wave that receives the calculated Gaussian.
- `pw` *(Wave)*: Parameter wave containing background and Gaussian parameters.

### Returns

- **Variable**: Returns 0 on completion.

```{note}
The input wave is modified in place.
```
