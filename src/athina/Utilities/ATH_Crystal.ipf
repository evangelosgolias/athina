#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_Crystal

static function PlaneDistanceHCP(a,c,h,k,l)
	// here enter hkl from [h k i l] hcp notation (discard the redundant i)
	variable a,c,h,k,l
	variable a_s = 2/(a*sqrt(3)), c_s = 1/c	
	variable h1, k1, l1
	h1 = (2*h-k)/3
	k1 = (2*k-h)/3
	l1 = l
	return sqrt(1/((h1^2+k1^2+h1*k1)*a_s^2+l1^2*c_s^2))
End
static function AngleBetweenPlanesHCP(a,c,h1,k1,l1,h2,k2,l2)
	// return phi, angle between planes [h1 k1 i1 l1] and [h2 k2 i2 l2]
	// here enter hkl from [h k i l] hcp notation (discard the redundant i)
	variable a,c,h1,k1,l1,h2,k2,l2
	variable a_s = 2/(a*sqrt(3)), c_s = 1/c
	//Translate to 3 Miller-Bravais indices
	variable h, k
	h = (2*h1-k1)/3
	k = (2*k1-h1)/3
	h1 = h
	k1 = k	
	h = (2*h2-k2)/3
	k = (2*k2-h2)/3
	h2 = h
	k2 = k		
	variable d1_hkl = sqrt(1/((h1^2+k1^2+h1*k1)*a_s^2+l1^2*c_s^2))
	variable d2_hkl = sqrt(1/((h2^2+k2^2+h2*k2)*a_s^2+l2^2*c_s^2))
	return acos(d1_hkl*d2_hkl*((h1*h2+k1*k2+0.5*(h1*k2+k1*h2))*a_s^2 + l1*l2*a_s^2))*180/pi
End

