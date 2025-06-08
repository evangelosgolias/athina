#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_FuncFit
#pragma version = 1.01
// ------------------------------------------------------- //
// Copyright (c) 2022 Evangelos Golias.
// Contact: egolias@protonmail.com
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

static Function FitFermiEdge(WAVE w, variable x) : FitFunc
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

static Function FitFermiEdgeTimesLine(WAVE w, variable x) : FitFunc
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

static Function FitXASStepBackground(WAVE w, variable E) : FitFunc
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
static Function FitFermiEdgeGaussianConvolution(WAVE pw, WAVE yw, WAVE xw) : FitFunc
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
static Function XMLDCosSqIntensity(WAVE pw, WAVE yw, WAVE xw) : FitFunc
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

static Function XMLDSinSqIntensity(WAVE pw, WAVE yw, WAVE xw) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ I(E) =pw[0] + pw[1] * sin(x + yw[2])^2
	//CurveFitDialog/ 	
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x	
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = baseline
	//CurveFitDialog/ w[1] = amplitute
	//CurveFitDialog/ w[2] = phase
	yw = pw[0] + pw[1] * sin(xw + pw[2])^2
End


static Function XMLDIntensityWtGradient(WAVE pw, WAVE yw, WAVE xw) : FitFunc
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
	yw = pw[0] + pw[1] * xw + pw[2] * cos(xw + pw[3])^2
End

static Function Gaussian2D(WAVE pw, WAVE yw, WAVE wx, WAVE wy) : Fitfunc

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

static Function FocusSTV(WAVE pw, WAVE yw, WAVE xw) : FitFunc
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
