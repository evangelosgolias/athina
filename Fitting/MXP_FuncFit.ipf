#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

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
