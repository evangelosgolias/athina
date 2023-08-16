#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

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

Function FermiEdge(WAVE w, variable E) : FitFunc
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(E) = y0 + 1 / (exp((E - Ef)/kT) + 1)
	//CurveFitDialog/ 
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ E
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = Ef
	//CurveFitDialog/ w[2] = kT

	return w[0] + 1 / (exp((E-w[1])/w[2])+1)
End

Function FermiEdgeTimesLine(WAVE w, variable E) : FitFunc
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
	
	return w[0] + (w[4]*E+w[3]) / (exp((E-w[1])/w[2])+1)
End

Function FermiEdgeGaussianConvolution(WAVE pw, WAVE yw, WAVE xw) : FitFunc
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

Function XASStepBackground(WAVE w, variable E) : FitFunc
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

// Does not function well, fix it
//Function FermiEdgeTimesLinearDOSGaussianConvolution(WAVE pw, WAVE yw, WAVE xw) : FitFunc	
//	// Linear DOS x Fermi convolved with Gaussian (energy resolution).
//	// M. G. Helander, M. T. Greiner, Z. B. Wang, and Z. H. Lu, Review of Scientific Instruments 82, 096107 (2011)
//	// https://aip.scitation.org/doi/pdf/10.1063/1.3642659
//	//
//	// pw[0] = offset
//	// pw[1] = Fermi level
//	// pw[2] = T
//	// pw[3] = DOS offset
//	// pw[4] = DOS slope
//	// pw[5] = energy resolution FWHM (eV)
//	
//	// Make the resolution function wave W_res.
//	variable x0 = xw[0]
//	variable dx = (xw[inf] - xw[0])/(numpnts(xw) - 1)	// assumes even data spacing, which is necessary for the convolution anyway
//	Make/FREE/D/N=(min(max(abs(3 * pw[5] / dx), 5), numpnts(yw))) W_res	// make the Gaussian resolution wave
//	Redimension/N=(numpnts(W_res) + !mod(numpnts(W_res), 2)) W_res	// force W_res to have odd length
//	SetScale/P x, -dx * (numpnts(W_res) - 1) / 2, dx, W_res
//	W_res = gauss(x, 0, pw[5]/(2*sqrt(2*ln(2))) ) // In this form FWHM = pw[5]
//	variable a = sum(W_res)
//	W_res /= a
//	
//	// To eliminate edge effects due to the convolution, add points to yw
//	// convolve and then delete the extra points.
//	Redimension/N=(numpnts(yw) + 2 * numpnts(W_res)) xw, yw
//	xw = (x0 - numpnts(W_res) * dx) + p * dx
//	//pw[0] * (1 / (1 + exp((xw[p] - pw[1])/(kB * pw[2]))) + Heaviside(xw[p], pw[1]) * (pw[3] + pw[4] * xw[p]))
//	yw = pw[0] + (1 / (1 + exp((xw[p] - pw[1])/(k_B * pw[2]))))
//	Convolve/A W_res, yw
//	yw += ((xw[p] > pw[1] ? 0 : 1) * (pw[3] + pw[4] * xw[p]))
//	DeletePoints 0, numpnts(W_res), xw, yw
//	DeletePoints numpnts(yw)-numpnts(W_res), numpnts(W_res), xw, yw
//End

