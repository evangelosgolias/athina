#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion  = 9

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


Function [variable x0, variable y0] ATH_GetSinglePointWithDistanceFromLine(variable x1, variable y1, variable s, variable d)
	/// Return the coordinates of a point with distance d from line passing from A(x1, y1) with slope s.
	/// Use positive or *negative* distance to get a point on either side of A.
	
	x0 = x1 - d * s / sqrt(s^2 + 1)
	y0 = y1 + 1/s * (x1 - x0)
	return [x0, y0]
End

Function [variable xp0, variable yp0, variable xp1, variable yp1 ] ATH_GetBothPointsWithDistanceFromLine(variable x1, variable y1, variable s, variable d)
	/// Return the coordinates of points with distance d from a line passing from A(x1, y1) witl slope s.
	/// Points are on either side of of A.
	
	xp0 = x1 - d * s / sqrt(s^2 + 1)
	xp1 = x1 + d * s / sqrt(s^2 + 1)
	yp0 = y1 + 1/s * (x1 - xp0)
	yp1 = y1 + 1/s * (x1 - xp1)
	return [xp0, yp0, xp1, yp1]
End

Function ATH_SlopePerpendicularToLineSegment(variable x1, variable y1, variable x2, variable y2)
	// Return the slope of a line perpendicular to the line segment defined by (x1, y1) and (x2, y2)
	if (y1 == y2)
		return 0
	elseif (x1 == x2)
		return inf
	else
		return -(x2 - x1)/(y2 - y1)
	endif
End

Function [variable xshift, variable yshift] ATH_GetVerticesPerpendicularToLine(variable radius, variable slope)
	// Return the part of the solution of an intersection between a circle of radius = radius
	// with a line with slope = slope. If the center has coordinates (x0, y0) the two point that
	// the line intersects the cicle have x =  x0 ± sqrt(radius^2 / (1 + slope^2)) and 
	// y = slope * sqrt(radius^2 / (1 + slope^2)). 
	// The funtion returns only the second terms.
	 xshift = sqrt(radius^2 / (1 + slope^2))
	 yshift = slope * sqrt(radius^2 / (1 + slope^2))
	 return [xshift, yshift]
End

Function [variable xn1, variable yn1, variable xn2, variable yn2] ATH_SymmetricLineShrink(variable x1, variable y1, variable x2, variable y2, variable Sfactor)
	/// Returns the points (xn1, yn1) and (xn2, yn2) that define a line segnemt with
	/// length Sfactor times the length of the line defined by (x1, y1) and (x2, y2).
	/// The center of both line segments is fixed.
	
	variable lineLength = sqrt((x2 - x1)^2 + (y2 - y1)^2) // diameter of the circle
	variable xc = (x1 + x2) / 2,  yc = (y1 + y2) / 2 // center of circle
	variable slope = (y2 - y1) / (x2 - x1) // Slope of line passing from (xc, yc)

	if (slope == inf)
		xn1 = x1
		xn2 = x2
		yn1 = yc - (Sfactor * lineLength) / 2 
		yn2 = yc + (Sfactor * lineLength) / 2
	else
		xn1 = xc - (Sfactor * lineLength) / (2 * sqrt(1 + slope^2))
		xn2 = xc + (Sfactor * lineLength) / (2  * sqrt(1 + slope^2))
		yn1 = yc - slope * (Sfactor * lineLength) / (2  * sqrt(1 + slope^2))
		yn2 = yc + slope * (Sfactor * lineLength) / (2 * sqrt(1 + slope^2))
	endif
	return [xn1, yn1, xn2, yn2]
End

// TODO: Test and uncomment 
//Function [variable xn, variable yn]  ATH_GetAntipodalPoint(variable x1, variable y1, variable x0, variable y0, int solution)
Function ATH_GetAntipodalPoint(variable x1, variable y1, variable x0, variable y0)

	/// Returns the antipodal point (xn, yn) of (x1, x2) of a circle with center (x0, y0)
	
	variable radius = sqrt((x1 - x0)^2 + (y1 - y0)^2) // radius of the circle
	variable slope = (y1 - y0) / (x1 - x0) // slope of line passing through (x0, y0) and (x1, y1)
	variable xn, yn
	if (slope == inf)
		xn = x1
		yn = y0 + radius / 2
		if(yn == y1)
			yn = y0 - radius / 2
		endif
	else
		xn = x0 + radius / sqrt(1 + slope^2)
		yn = y0 + (radius * slope) / sqrt(1 + slope^2)
		if(xn == x1)
			print "Have to change sign for xn"
			xn = x0 - radius / sqrt(1 + slope^2)
		endif
		if(yn == y1)
						print "Have to change sign for yn"
			yn = y0 - (radius * slope) / sqrt(1 + slope^2)
		endif
	endif
	print xn, yn
	//return [xn, yn]
End

Function [variable slope, variable shift] ATH_LineEquationFromTwoPoints(variable x0, variable y0, variable x1, variable y1)
	/// Returns A, B for y = A x + B passing through A(x0, y0), B(x1, y1)
	slope = (y1 - y0) /(x1 - x0)
		
	if (slope == Inf)
		return [Inf, 0]
	endif
	shift = y0 - slope * x0
	return [slope, shift]
End

Function [WAVE wx, WAVE wy] ATH_XYWavesOfLineFromTwoPoints(variable x0, variable y0, variable x1, variable y1, variable npts)
	
	Make/FREE/N=(npts) wx, wy
	SetScale/I x, x0, x1, wx
	SetScale/I x, y0, y1, wy	
	variable slope, shift
	[slope, shift] = ATH_LineEquationFromTwoPoints(x0, y0, x1, y1)
	if(slope == Inf)
		wx = x0
		wy = x
	else // simple and works with any axes
		wx = x
		wy = x
	endif
	
	return [wx, wy]
End