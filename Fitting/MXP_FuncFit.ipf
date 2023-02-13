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

Function FermiEdge_Line(WAVE w, variable E) : FitFunc
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
