#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion  = 9
#pragma ModuleName = ATH_Geometry
#pragma version = 1.01
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


static Function [variable x0, variable y0] GetSinglePointWithDistanceFromLine(variable x1, variable y1, variable s, variable d)
	/// Return the coordinates of a point with distance d from line passing from A(x1, y1) with slope s.
	/// Use positive or *negative* distance to get a point on either side of A.
	
	x0 = x1 - d * s / sqrt(s^2 + 1)
	y0 = y1 + 1/s * (x1 - x0)
	return [x0, y0]
End

static Function [variable xp0, variable yp0, variable xp1, variable yp1 ] GetBothPointsWithDistanceFromLine(variable x1, variable y1, variable s, variable d)
	/// Return the coordinates of points with distance d from a line passing from A(x1, y1) witl slope s.
	/// Points are on either side of of A.
	
	xp0 = x1 - d * s / sqrt(s^2 + 1)
	xp1 = x1 + d * s / sqrt(s^2 + 1)
	yp0 = y1 + 1/s * (x1 - xp0)
	yp1 = y1 + 1/s * (x1 - xp1)
	return [xp0, yp0, xp1, yp1]
End

static Function SlopePerpendicularToLineSegment(variable x1, variable y1, variable x2, variable y2)
	// Return the slope of a line perpendicular to the line segment defined by (x1, y1) and (x2, y2)
	if (y1 == y2)
		return 0
	elseif (x1 == x2)
		return inf
	else
		return -(x2 - x1)/(y2 - y1)
	endif
End

static Function [variable xshift, variable yshift] GetVerticesPerpendicularToLine(variable radius, variable slope)
	// Return the part of the solution of an intersection between a circle of radius = radius
	// with a line with slope = slope. If the center has coordinates (x0, y0) the two point that
	// the line intersects the cicle have x =  x0 ± sqrt(radius^2 / (1 + slope^2)) and 
	// y = slope * sqrt(radius^2 / (1 + slope^2)). 
	// The funtion returns only the second terms.
	 xshift = sqrt(radius^2 / (1 + slope^2))
	 yshift = slope * sqrt(radius^2 / (1 + slope^2))
	 return [xshift, yshift]
End

static Function [variable xn1, variable yn1, variable xn2, variable yn2] SymmetricLineShrink(variable x1, variable y1, variable x2, variable y2, variable Sfactor)
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
static Function GetAntipodalPoint(variable x1, variable y1, variable x0, variable y0)

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

static Function [variable slope, variable shift] LineEquationFromTwoPoints(variable x0, variable y0, variable x1, variable y1)
	/// Returns A, B for y = A x + B passing through A(x0, y0), B(x1, y1)
	/// Note: Result w.r.t a standard cartesian system.
	slope = (y1 - y0) /(x1 - x0)
		
	if (x1 == x0)
		return [Inf, 0]
	endif
	shift = y0 - slope * x0
	return [slope, shift]
End

static Function [WAVE wx, WAVE wy] XYWavesOfLineFromTwoPoints(variable x0, variable y0, variable x1, variable y1, variable npts)
	// Note: Here to have the correct be
	Make/FREE/N=(npts) wx, wy
	SetScale/I x, x0, x1, wx
	SetScale/I x, y0, y1, wy	
	variable slope, shift
	[slope, shift] = LineEquationFromTwoPoints(x0, y0, x1, y1)
	if(x0 == x1)
		wx = x0
		wy = x
	elseif(y0 == y1) // !!!Note: if y0 == y1 SetScale/I x, y0, y1, wy => SetScale/P x, 0, 1, wy
		wx = x
		wy = y0
	else // simple and works with any axes
		wx = x
		wy = x
	endif
	
	return [wx, wy]
End

static Function [variable p0, variable p1, variable q0, 
		  variable q1] GetCenterNonRotatedImageBoundaries(WAVE wRef, variable value)
	/// Function returns the boundaries of a region that is surrounded/bounded 
	/// by an area with value = value. Works with 2D waves and assumes a centered
	/// rectangular non-rotated image!
	
	variable wDims = WaveDims(wRef)
	if(wDims != 2)
		return 
	endif
		
	variable idxPMax = DimSize(wRef, 0)
	variable idxQMax = DimSize(wRef, 1), i, j, bypass = 1
	
	variable midQ = DimSize(wRef, 1)/2
	for(i = 1; i < idxPMax; i+=2)
		if(wRef[i-1][midQ] == value && wRef[i][midQ] == value)
			continue
		elseif(bypass)
			p0 = i
			bypass = 0
		else
			j = i
			p1 = j - 1
		endif
	endfor
	bypass = 1 // reset bypass switch
	variable midP = DimSize(wRef, 0)/2
	for(i = 1; i < idxQMax; i+=2)
		if(wRef[midP][i-1] == value && wRef[midP][i] == value)
			continue
		elseif(bypass)
			q0 = i
			bypass = 0
		else
			j = i
			q1 = j - 1
		endif
	endfor
	return [p0, p1, q0, q1]
End