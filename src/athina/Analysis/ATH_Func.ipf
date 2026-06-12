#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion  = 9
#pragma ModuleName = ATH_Func
#pragma version = 1.00



/// @module ATH_Func
/// @brief Utility mathematical functions used by other ATH modules.
/// @details
/// This module provides low-level helper functions for generating 2D Gaussian
/// intensity distributions. The routines are primarily used for image modeling
/// and fitting workflows in the ATH package.
///

// Gauss 2d with a angle phi wrt to the horizontal axis and sx, sy std.
/// @function GenericGaussian2D
/// @brief Fill a 2D wave with a rotated Gaussian distribution.
/// @details
/// Computes a 2D Gaussian centered at (`x0`, `y0`) with amplitude `ampl`,
/// standard deviations `sx` and `sy`, and in-plane rotation angle `phi` in degrees.
/// The result is written directly into `wRef`.
/// @param wRef Wave Destination 2D wave that receives the calculated Gaussian.
/// @param ampl Variable Peak amplitude of the Gaussian.
/// @param phi Variable Rotation angle in degrees with respect to the horizontal axis.
/// @param x0 Variable X coordinate of the Gaussian center.
/// @param y0 Variable Y coordinate of the Gaussian center.
/// @param sx Variable Standard deviation along the first principal axis.
/// @param sy Variable Standard deviation along the second principal axis.
/// @returns Variable Returns 0 on completion.
/// @note The input wave is modified in place.
///
static Function GenericGaussian2D(WAVE wRef, variable ampl, variable phi,
						   variable x0, variable y0, variable sx, variable sy)		
	// x0,y0 center of the gaussian
	// sx, sy is the standard deviation
	variable a, b, c
	phi *= pi/180
	
	a = cos(phi)^2/(2*sx^2) + sin(phi)^2/(2*sy^2)
	b = sin(2*phi)/(4*sx^2) - sin(2*phi)/(4*sy^2)
	c = sin(phi)^2/(2*sx^2) + cos(phi)^2/(2*sy^2)
	
	wRef = ampl * exp(-(a*(x-x0)^2+2*b*(x-x0)*(y-y0)+c*(y-y0)^2))
	
	return 0
End

// Gauss 2d with a angle phi wrt to the horizontal axis and sx, sy std.
/// @function GenericGaussian2Dpw
/// @brief Fill a 2D wave with a rotated Gaussian using a parameter wave.
/// @details
/// Computes a 2D Gaussian plus constant background using values stored in `pw`.
/// The parameters are interpreted as:
/// `pw[0]` background, `pw[1]` amplitude, `pw[2]` angle in degrees,
/// `pw[3]` x center, `pw[4]` y center, `pw[5]` x standard deviation,
/// and `pw[6]` y standard deviation.
/// @param wRef Wave Destination 2D wave that receives the calculated Gaussian.
/// @param pw Wave Parameter wave containing background and Gaussian parameters.
/// @returns Variable Returns 0 on completion.
/// @note The input wave is modified in place.
///
static Function GenericGaussian2Dpw(WAVE wRef, WAVE pw)		
	//pw[0]: const bck
	//pw[1]: Amplitude
	//pw[2]: angle (rad)
	//pw[3]: x0
	//pw[4]: y0
	//pw[5]: sx
	//pw[6]: sy
	variable const, ampl, phi, x0, y0, sx, sy, a, b, c
	const = pw[0]; ampl = pw[1]; phi = pw[2] * pi/180; x0 = pw[3]; 
	y0 = pw[4]; sx = pw[5]; sy = pw[6]

	a = cos(phi)^2/(2*sx^2) + sin(phi)^2/(2*sy^2)
	b = sin(2*phi)/(4*sx^2) - sin(2*phi)/(4*sy^2)
	c = sin(phi)^2/(2*sx^2) + cos(phi)^2/(2*sy^2)
	
	wRef = const + ampl * exp(-(a*(x-x0)^2+2*b*(x-x0)*(y-y0)+c*(y-y0)^2))
	
	return 0
End