#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion  = 9
#pragma ModuleName = ATH_Func
#pragma version = 1.00



// Gauss 2d with a angle phi wrt to the horizontal axis and sx, sy std.
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