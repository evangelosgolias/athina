#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_FuncFit
#pragma version = 1.01
/// @module ATH_FuncFit
/// @brief Fit functions for spectroscopy, XMLD, and image-shape analysis.
/// @details
/// This module collects Igor Pro fit functions used by the ATH analysis package.
/// It includes Fermi-edge models, XAS step backgrounds, angular XMLD models,
/// a 2D Gaussian model, and a simple focus calibration relation.
///

// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: evangelos.golias@gmail.com
//	
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//	
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
// ------------------------------------------------------- //

static constant k_B = 8.617333262e-5 // Boltzmann constant in eV/K

/// @function FitFermiEdge
/// @brief Fermi edge model with constant offset.
/// @details
/// Returns `y0 + 1 / (exp((E - Ef) / kT) + 1)` for scalar fitting in Igor's
/// curve fitting framework.
/// @param w Wave Coefficient wave with `w[0]=y0`, `w[1]=Ef`, and `w[2]=kT`.
/// @param x Variable Energy value at which the model is evaluated.
/// @returns Variable Model value at `x`.
///
ThreadSafe static Function FitFermiEdge(WAVE w, variable x) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(E) = y0 + 1 / (exp((E - Ef)/kT) + 1)
	//CurveFitDialog/ 
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ E
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = Ef
	//CurveFitDialog/ w[2] = kT

	return w[0] + 1 / (exp((x-w[1])/w[2])+1)
End

/// @function FitFermiEdgeTimesLine
/// @brief Fermi edge model multiplied by a linear term and shifted by an offset.
/// @details
/// Returns `y0 + (a*x + b) / (exp((x - Ef) / kT) + 1)` for use with Igor curve fitting.
/// @param w Wave Coefficient wave with `w[0]=y0`, `w[1]=Ef`, `w[2]=kT`, `w[3]=b`, and `w[4]=a`.
/// @param x Variable Energy value at which the model is evaluated.
/// @returns Variable Model value at `x`.
///
ThreadSafe static Function FitFermiEdgeTimesLine(WAVE w, variable x) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(E) = y0 + (a * E + b) / (exp((E - Ef)/kT) + 1)
	//CurveFitDialog/ 
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ E
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = Ef
	//CurveFitDialog/ w[2] = kT
	//CurveFitDialog/ w[3] = b
	//CurveFitDialog/ w[4] = a
	
	return w[0] + (w[4]*x+w[3]) / (exp((x-w[1])/w[2])+1)
End

/// @function FitXASStepBackground
/// @brief Two-step arctangent background model for XAS spectra.
/// @details
/// Models the L3 and L2 edge-step contributions using two broadened arctangent
/// functions plus a constant baseline.
/// @param w Wave Coefficient wave containing baseline, height, edge positions, and widths.
/// @param E Variable Energy value at which the model is evaluated.
/// @returns Variable Model value at `E`.
///
ThreadSafe static Function FitXASStepBackground(WAVE w, variable E) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ I(E) = w[0] + w[1]/3 * (1 + 2/pi * atan((E-w[2])/w[3]) + w[1]/6 * (1 + 2/pi * atan((E-w[4])/w[5])
	//CurveFitDialog/ 	
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ E	
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = baseline
	//CurveFitDialog/ w[1] = h
	//CurveFitDialog/ w[2] = E_L3
	//CurveFitDialog/ w[3] = width_L3
	//CurveFitDialog/ w[4] = E_L2
	//CurveFitDialog/ w[5] = width_L2
		
	return w[0] + w[1]/3 * (1 + 2/pi * atan((E-w[2])/w[3])) + w[1]/6 * (1 + 2/pi * atan((E-w[4])/w[5]))
End

// All-at-once
/// @function FitFermiEdgeGaussianConvolution
/// @brief Fermi-Dirac edge broadened by Gaussian convolution.
/// @details
/// Generates a Fermi-Dirac edge in `yw`, convolves it with a Gaussian kernel
/// defined by the FWHM in `pw[3]`, and then adds a linear background.
/// @param pw Wave Parameter wave with offset, slope, temperature, Gaussian width, amplitude, and edge location.
/// @param yw Wave Output wave that is overwritten with the calculated fit values.
/// @param xw Wave X wave associated with `yw`.
/// @returns Variable FitFunc output as required by Igor; the computed values are written to `yw`.
/// @note `yw` is overwritten. Temporary waves are created during convolution.
///
ThreadSafe static Function FitFermiEdgeGaussianConvolution(WAVE pw, WAVE yw, WAVE xw) : FitFunc
	/// FitFunc shared by Emile Rienks (BESSY-II, 1^3)
	//
	// pw[0] = offset
	// pw[1] = slope
	// pw[2] = T
	// pw[3] = gaussian width (FWHM)
	// pw[4] = amplitude
	// pw[5] = location

	Duplicate /O yw testw
	variable dx = deltax(yw)
	Make/D/O/N=121 gwave
	SetScale/P x -60 * dx, dx, "eV", gwave

	gwave = Gauss(x, 0, pw[3]/(2*sqrt(2*ln(2))))
	
	// Normalize kernel so that convolution doesn't change // the amplitude of the result

	variable sumexp = sum(gwave)
	gwave /= sumexp

   // Put a Fermi-Dirac distribution into the output wave
   yw = pw[4] / (exp((x-pw[5])/(k_B*pw[2]))+1)

	Make /D/N=(numpnts(yw)+60)/O myw
	myw[,59] = yw[0]
	myw[60,] = yw[p-60]

   Convolve/A gwave, myw
	// Add the vertical offset AFTER the convolution to avoid end effects
	yw = myw[p+60]
	yw += pw[0] + pw[1]*x
End

// All-at-once
/// @function XMLDSinSqIntensity
/// @brief XMLD angular intensity model using a squared sine term.
/// @param pw Wave Coefficient wave with baseline, amplitude, and phase.
/// @param yw Wave Output wave that receives the calculated model values.
/// @param xw Wave Angular coordinate wave.
/// @returns Variable FitFunc output as required by Igor; the computed values are written to `yw`.
///
ThreadSafe static Function XMLDSinSqIntensity(WAVE pw, WAVE yw, WAVE xw) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ I(E) =pw[0] + pw[1] * sin(x - yw[2])^2
	//CurveFitDialog/ 	
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x	
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = baseline
	//CurveFitDialog/ w[1] = amplitute
	//CurveFitDialog/ w[2] = phase
	yw = pw[0] + pw[1] * sin(xw + pw[2])^2
End

/// @function XMLDCosSqIntensity
/// @brief XMLD angular intensity model using a squared cosine term.
/// @param pw Wave Coefficient wave with baseline, amplitude, and phase.
/// @param yw Wave Output wave that receives the calculated model values.
/// @param xw Wave Angular coordinate wave.
/// @returns Variable FitFunc output as required by Igor; the computed values are written to `yw`.
///
ThreadSafe static Function XMLDCosSqIntensity(WAVE pw, WAVE yw, WAVE xw) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ I(E) =pw[0] + pw[1] * cos(x - yw[2])^2
	//CurveFitDialog/ 	
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x	
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = baseline
	//CurveFitDialog/ w[1] = amplitute
	//CurveFitDialog/ w[2] = phase
	yw = pw[0] + pw[1] * cos(xw + pw[2])^2
End

/// @function XMLDSin2xIntensity
/// @brief XMLD angular intensity model using `sin(2*(x+phase))`.
/// @param pw Wave Coefficient wave with baseline, amplitude, and phase.
/// @param yw Wave Output wave that receives the calculated model values.
/// @param xw Wave Angular coordinate wave.
/// @returns Variable FitFunc output as required by Igor; the computed values are written to `yw`.
///
ThreadSafe static Function XMLDSin2xIntensity(WAVE pw, WAVE yw, WAVE xw) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ I(E) =pw[0] + pw[1] * sin(2*(x + yw[2]))
	//CurveFitDialog/ 	
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x	
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = baseline
	//CurveFitDialog/ w[1] = amplitute
	//CurveFitDialog/ w[2] = phase
	yw = pw[0] + pw[1] * sin(2*(xw + pw[2]))
End

/// @function XMLDCos2xIntensity
/// @brief XMLD angular intensity model using `cos(2*(x+phase))`.
/// @param pw Wave Coefficient wave with baseline, amplitude, and phase.
/// @param yw Wave Output wave that receives the calculated model values.
/// @param xw Wave Angular coordinate wave.
/// @returns Variable FitFunc output as required by Igor; the computed values are written to `yw`.
///
ThreadSafe static Function XMLDCos2xIntensity(WAVE pw, WAVE yw, WAVE xw) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ I(E) =pw[0] + pw[1] * cos(2*(x + yw[2]))
	//CurveFitDialog/ 	
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x	
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = baseline
	//CurveFitDialog/ w[1] = amplitute
	//CurveFitDialog/ w[2] = phase
	yw = pw[0] + pw[1] * cos(2*(xw + pw[2]))
End

/// @function XMLDIntensityWtGradient
/// @brief XMLD angular intensity model with an added linear gradient term.
/// @param pw Wave Coefficient wave with baseline, gradient, amplitude, and phase.
/// @param yw Wave Output wave that receives the calculated model values.
/// @param xw Wave Angular coordinate wave.
/// @returns Variable FitFunc output as required by Igor; the computed values are written to `yw`.
///
ThreadSafe static Function XMLDIntensityWtGradient(WAVE pw, WAVE yw, WAVE xw) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ I(E) = pw[0] + pw[1] * sin(x + yw[2])^2
	//CurveFitDialog/ 	
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ E	
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = baseline
	//CurveFitDialog/ w[0] = gradient	
	//CurveFitDialog/ w[2] = amplitute
	//CurveFitDialog/ w[3] = phase
	yw = pw[0] + pw[1] * xw + pw[2] * sin(xw + pw[3])^2
End

/// @function Gaussian2D
/// @brief 2D Gaussian model for fitting flattened image data.
/// @details
/// Evaluates a rotated 2D Gaussian plus constant background using separate x and y
/// coordinate waves. This function is intended for use with Igor's all-at-once fitting.
/// @param pw Wave Parameter wave with background, amplitude, angle in radians, center coordinates, and standard deviations.
/// @param yw Wave Output wave that receives the calculated model values.
/// @param wx Wave X coordinate wave.
/// @param wy Wave Y coordinate wave.
/// @returns Variable FitFunc output as required by Igor; the computed values are written to `yw`.
///
ThreadSafe static Function Gaussian2D(WAVE pw, WAVE yw, WAVE wx, WAVE wy) : Fitfunc

	//pw[0]: const bck
	//pw[1]: Amplitude
	//pw[2]: angle (rad)
	//pw[3]: x0
	//pw[4]: y0
	//pw[5]: sigmax
	//pw[6]: sigmay
	
	//You need a 1d version of your laser image as an yw input!
	
	Variable a, b, c
	
	
	a = cos(pw[2])^2/(2*pw[5]^2) + sin(pw[2])^2/(2*pw[6]^2)
	
	b = sin(2*pw[2])/(4*pw[5]^2) - sin(2*pw[2])/(4*pw[6]^2)
	
	c = sin(pw[2])^2/(2*pw[5]^2) + cos(pw[2])^2/(2*pw[6]^2)
	
	yw = pw[0] + pw[1] * exp(-(a*(wx-pw[3])^2+2*b*(wx-pw[3])*(wy-pw[4])+c*(wy-pw[4])^2))
	
End 

/// @function FocusSTV
/// @brief Square-root focus calibration model.
/// @details
/// Returns `f0 + a*sqrt(STV)` for use in curve fitting.
/// @param pw Wave Coefficient wave with `pw[0]=f0` and `pw[1]=a`.
/// @param yw Wave Output wave that receives the calculated model values.
/// @param xw Wave Input STV values.
/// @returns Variable FitFunc output as required by Igor; the computed values are written to `yw`.
///
ThreadSafe static Function FocusSTV(WAVE pw, WAVE yw, WAVE xw) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(STV) = f0 + a * sqrt(STV)
	//CurveFitDialog/ 
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ STV
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ pw[0] = f0
	//CurveFitDialog/ pw[1] = a


	yw = pw[0] + pw[1] * sqrt(xw)
End
