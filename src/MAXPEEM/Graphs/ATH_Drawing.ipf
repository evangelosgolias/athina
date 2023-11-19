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


Function ATH_DrawLineUsingCursors(string C1, string C2, [string layer])
	// Draw a line using cursor C1 & C2
	// Draws in Overlay layer if layer optional argument is not given
	
	layer = SelectString(ParamIsDefault(layer), layer, "Overlay")
	
	SetDrawLayer $layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawLine hcsr($C1), vcsr($C1), hcsr($C2), vcsr($C2)
	return 0
End

Function ATH_DrawCircleUsingAntinodalCursors(string C1, string C2, [string layer])
	// Draw a circle with antinodal points at C1 & C2
	// Draws in Overlay layer if layer optional argument is not given

	layer = SelectString(ParamIsDefault(layer), layer, "Overlay")
	
	variable left, right, top, bottom, xc, yc, radius
	left = hcsr($C1); right = hcsr($C2)
	top = vcsr($C1); bottom = vcsr($C2)
	
	xc = (left + right)/2
	yc = (top + bottom)/2
	
	radius = ATH_Cursors#GetDistanceFromCursors(C1, C2)/2
	
	//change now left, right, top, bottom
	
	left   = xc - radius
	right  = xc + radius
	top    = yc + radius
	bottom = yc - radius
	
	SetDrawLayer $layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawOval left, top,right, bottom 
	return 0
End

Function ATH_DrawCircleUsingCenterAndPointCursors(string C1, string C2, [string layer])
	// Draw a circle with center at C1 that passed from C2
	// Draws in Overlay layer if layer optional argument is not given

	layer = SelectString(ParamIsDefault(layer), layer, "Overlay")
	
	variable left, right, top, bottom, xc, yc, radius
	left = hcsr($C1); right = hcsr($C2)
	top = vcsr($C1); bottom = vcsr($C2)
	
	xc = left
	yc = top
	
	radius = ATH_Cursors#GetDistanceFromCursors(C1, C2)
		
	left   = xc - radius
	right  = xc + radius
	top    = yc + radius
	bottom = yc - radius
	
	SetDrawLayer $layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawOval left, top,right, bottom 
	return 0
End