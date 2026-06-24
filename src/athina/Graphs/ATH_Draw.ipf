#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Draw
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


/// @module ATH_Draw
/// @brief Module ATH_Draw.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH Draw functionality.


/// @function DrawLineUsingCursors
/// @brief Draw line using cursors.
/// @details
/// Draw a line using cursor C1 & C2. Draws in Overlay layer if layer optional argument is not given.
/// @param C1 Name of the first graph cursor.
/// @param C2 Name of the second graph cursor.
/// @param layer (optional) Igor drawing or image layer to use.
/// @returns Zero after completing the operation.
static Function DrawLineUsingCursors(string C1, string C2, [string layer])
	// Draw a line using cursor C1 & C2
	// Draws in Overlay layer if layer optional argument is not given
	
	layer = SelectString(ParamIsDefault(layer), layer, "Overlay")
	
	SetDrawLayer $layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, xcoord = top, ycoord = left
	DrawLine hcsr($C1), vcsr($C1), hcsr($C2), vcsr($C2)
	return 0
End

/// @function DrawCircleUsingAntinodalCursors
/// @brief Draw circle using antinodal cursors.
/// @details
/// Draw a circle with antinodal points at C1 & C2. Draws in Overlay layer if layer optional argument is not
/// given change now left, right, top, bottom.
/// @param C1 Name of the first graph cursor.
/// @param C2 Name of the second graph cursor.
/// @param layer (optional) Igor drawing or image layer to use.
/// @returns Zero after completing the operation.
static Function DrawCircleUsingAntinodalCursors(string C1, string C2, [string layer])
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

/// @function DrawCircleUsingCenterAndPointCursors
/// @brief Draw circle using center and point cursors.
/// @details
/// Draw a circle with center at C1 that passed from C2. Draws in Overlay layer if layer optional argument is
/// not given. Draw scale bar.
/// @param C1 Name of the first graph cursor.
/// @param C2 Name of the second graph cursor.
/// @param layer (optional) Igor drawing or image layer to use.
/// @returns Zero after completing the operation.
static Function DrawCircleUsingCenterAndPointCursors(string C1, string C2, [string layer])
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

// Draw scale bar

/// @function ImageScaleBar
/// @brief Draw a scale bar on an image graph and return its relative width.
/// @details
/// Here the function returns the factor barlen/xlen which is the number we need to adjust so that the scale
/// bar corresponds to the size of the visible range.
/// @param barlen Requested scale-bar length in axis units.
/// @param grfName (optional) Name of the graph window.
/// @returns Scale-bar width as a fraction of the visible x-axis range.
static Function ImageScaleBar(variable barlen, [string grfName]) 
	// Here the function returns the factor barlen/xlen which is the 
	// number we need to adjust so that the scale bar corresponds to the
	// size of the visible range.
	// Return 0 if you have already a scale bar on image. Function used
	// in case 8 of ATH_Display#NewImg()
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	string axisX, axisY
	variable minVX, maxVX, minVY, maxVY, sf
	[axisX, minVX, maxVX, axisY, minVY, maxVY] = ATH_Graph#GetAxesRange(grfName=grfName)
	variable xlen = abs(maxVX - minVX)
	
	sf = barlen/xlen
	
	if(kATH_ScaleBarRelFactorRed * xlen < barlen) // it looks bad
		SetDrawLayer/W=$grfName UserFront	
		DrawAction/W=$grfName getgroup = athScaleBar
		DrawAction/W=$grfName delete = V_startPos, V_endPos
		SetDrawEnv/W=$grfName gstart,gname= athScaleBar
		SetDrawEnv/W=$grfName xcoord= axrel,ycoord= axrel, fillfgc = (65535,0,0)
		DrawRect/W=$grfName 0.95-sf, 0.925, 0.95, 0.95
		SetDrawEnv/W=$grfName gstop	
		SetDrawLayer/W=$grfName UserFront
	else 
		SetDrawLayer/W=$grfName UserFront	
		DrawAction/W=$grfName getgroup = athScaleBar
		DrawAction/W=$grfName delete = V_startPos, V_endPos
		SetDrawEnv/W=$grfName gstart,gname= athScaleBar
		SetDrawEnv/W=$grfName xcoord= axrel,ycoord= axrel
		DrawRect/W=$grfName 0.95-sf, 0.925, 0.95, 0.95
		SetDrawEnv/W=$grfName gstop	
		SetDrawLayer/W=$grfName UserFront
	endif
	
	return sf
End

//Function DrawArrowsUsingCDIntensity()
//	string grfName = WinName(0, 1, 1), axisX, axisY
//	[axisX, axisY] = ATH_Graph#GetAxes(grfName=grfName)
//	variable flag, left, right, top, bottom
//	[flag, left, right, top, bottom] = ATH_Marquee#GetMarqueeToIndex(axisX=axisX, axisY=axisY)
//	if (!flag)
//		return 1
//	endif
//	WAVE wRef = ATH_Graph#TopImageToWaveRef(grfName = grfName)
//	variable layerN = ATH_Graph#GetgLayer(grfName)
//	if(layerN > -1)
//		Duplicate/FREE/RMD=[left,right][top,bottom][layerN] wRef, regionFREE
//	else
//		Duplicate/FREE/RMD=[left,right][top,bottom] wRef, regionFREE
//	endif
//
//	variable avgSize = 5
//	variable arrowLength = 10
//	variable zeroaAngle = 0
//	Prompt avgSize, "Average nxn - use n odd"
//	Prompt arrowLength, "Arrow length"
//	Prompt zeroaAngle, "x-axis rotation (FoV Rotation)"		
//	DoPrompt "Process selected aread", avgSize, arrowLength, zeroaAngle
//	
//		
//	ImageInterpolate/PXSZ={avgSize,avgSize} Pixelate regionFREE
//	WAVE/Z M_PixelatedImage
//	// Normalize the region
//	//MatrixOP/FREE rF = scale(regionFREE, 0 , pi)
//	//Set up user input
//
//	//ImageFilter/N=(avgSize) avg regionFREE
////	WaveStats/Q M_PixelatedImage
////	M_PixelatedImage -= V_avg // I0
////	WaveStats/Q M_PixelatedImage	
////	M_PixelatedImage /= (V_max-V_min) // A
//	MatrixOP/O M_PixelatedImageFREE = scale(M_PixelatedImage, -1, 1)
//	MatrixOP/O angles = acos(M_PixelatedImageFREE)
//	KillWaves/Z M_PixelatedImage
//End