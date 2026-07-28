#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_BackgroundRemoval
#pragma version = 1.2

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

/// @file ATH_BackgroundRemoval_MarqueeFit.ipf
/// @brief Parallel line polynomial background removal with optional marquee fit area.
///
/// This version keeps the same background model as the pasted code, with one
/// addition: the fitting image can be restricted to the current marquee on the
/// top image. The background is still evaluated over the full image.

/// @brief Generate non-overlapping parallel line segments through the full image.
static Function MakeAngledImageLines(Wave w, variable thetaDeg, variable lineDensity)
	variable xLo = -0.5
	variable xHi = DimSize(w, 0) - 0.5
	variable yLo = -0.5
	variable yHi = DimSize(w, 1) - 0.5

	return MakeAngledImageLinesInArea(w, thetaDeg, lineDensity, xLo, xHi, yLo, yHi)
End

/// @brief Generate non-overlapping parallel line segments through a rectangular fit area.
///
/// The rectangle is given in pixel-boundary coordinates. For image indices
/// `x0...x1` and `y0...y1`, use boundaries `x0 - 0.5`, `x1 + 0.5`,
/// `y0 - 0.5`, and `y1 + 0.5`.
static Function MakeAngledImageLinesInArea(Wave w, variable thetaDeg, variable lineDensity, variable xLo, variable xHi, variable yLo, variable yHi)
	variable nx = DimSize(w, 0), ny = DimSize(w, 1)

	xLo = min(max(xLo, -0.5), nx - 0.5)
	xHi = min(max(xHi, -0.5), nx - 0.5)
	yLo = min(max(yLo, -0.5), ny - 0.5)
	yHi = min(max(yHi, -0.5), ny - 0.5)
	if (xHi <= xLo || yHi <= yLo)
		return -1
	endif

	thetaDeg = mod(thetaDeg, 180)
	thetaDeg = thetaDeg < 0 ? thetaDeg + 180 : thetaDeg

	variable thetaRad = thetaDeg * pi / 180
	variable lineDX = cos(thetaRad), lineDY = sin(thetaRad)
	variable normalX = -lineDY, normalY = lineDX

	Make/FREE/D/N=4 cornerC
	cornerC[0] = normalX * xLo + normalY * yLo
	cornerC[1] = normalX * xHi + normalY * yLo
	cornerC[2] = normalX * xHi + normalY * yHi
	cornerC[3] = normalX * xLo + normalY * yHi

	variable cMin = cornerC[0], cMax = cornerC[0], i
	for (i = 1; i < 4; i += 1)
		cMin = min(cMin, cornerC[i])
		cMax = max(cMax, cornerC[i])
	endfor

	variable projectedWidth = cMax - cMin
	variable minimumLineSpacing = abs(normalX) + abs(normalY)
	variable maxLines = floor(projectedWidth / minimumLineSpacing + 1e-12)
	if (maxLines < 3)
		return -1
	endif

	variable requestedLines
	if (lineDensity == 0 || lineDensity == 1)
		requestedLines = maxLines
	elseif (lineDensity > 0 && lineDensity < 1)
		requestedLines = round(lineDensity * maxLines)
	else
		requestedLines = round(lineDensity)
	endif

	variable targetLines = min(max(requestedLines, 3), maxLines)
	if (targetLines != requestedLines)
		printf "MakeAngledImageLines: requested density rounded/clamped from %g to %d lines.\r", lineDensity, targetLines
	endif

	Make/O/D/N=(targetLines, 2) wx = 0, wy = 0
	Make/FREE/D/N=4 hitX = 0, hitY = 0

	variable lineSpacing = projectedWidth / targetLines
	variable cornerTol = 1e-10 * max(1, projectedWidth)
	variable coordinateTol = 1e-10 * max(1, max(nx, ny))
	variable componentTol = 1e-14
	variable validLines = 0, j, c, xHit, yHit, t0, t1, hitCount, hitsCorner, temp
	variable attempt, phaseIsValid, linePhase = 0.5

	for (attempt = 0; attempt < 9; attempt += 1)
		if (attempt == 0)
			linePhase = 0.5
		elseif (mod(attempt, 2) == 1)
			linePhase = 0.5 - 0.1 * (attempt + 1) / 2
		else
			linePhase = 0.5 + 0.1 * attempt / 2
		endif

		phaseIsValid = 1
		for (i = 0; i < targetLines && phaseIsValid; i += 1)
			c = cMin + (i + linePhase) * lineSpacing
			for (j = 0; j < 4; j += 1)
				if (abs(c - cornerC[j]) <= cornerTol)
					phaseIsValid = 0
					break
				endif
			endfor
		endfor

		if (phaseIsValid)
			break
		endif
	endfor

	for (i = 0; i < targetLines; i += 1)
		c = cMin + (i + linePhase) * lineSpacing

		hitsCorner = 0
		for (j = 0; j < 4; j += 1)
			if (abs(c - cornerC[j]) <= cornerTol)
				hitsCorner = 1
				break
			endif
		endfor
		if (hitsCorner)
			continue
		endif

		hitCount = 0

		if (abs(normalY) > componentTol)
			yHit = (c - normalX * xLo) / normalY
			if (yHit >= yLo - coordinateTol && yHit <= yHi + coordinateTol)
				yHit = min(max(yHit, yLo), yHi)
				hitCount = AddUniqueLineHit(hitX, hitY, hitCount, xLo, yHit, coordinateTol)
			endif

			yHit = (c - normalX * xHi) / normalY
			if (yHit >= yLo - coordinateTol && yHit <= yHi + coordinateTol)
				yHit = min(max(yHit, yLo), yHi)
				hitCount = AddUniqueLineHit(hitX, hitY, hitCount, xHi, yHit, coordinateTol)
			endif
		endif

		if (abs(normalX) > componentTol)
			xHit = (c - normalY * yLo) / normalX
			if (xHit >= xLo - coordinateTol && xHit <= xHi + coordinateTol)
				xHit = min(max(xHit, xLo), xHi)
				hitCount = AddUniqueLineHit(hitX, hitY, hitCount, xHit, yLo, coordinateTol)
			endif

			xHit = (c - normalY * yHi) / normalX
			if (xHit >= xLo - coordinateTol && xHit <= xHi + coordinateTol)
				xHit = min(max(xHit, xLo), xHi)
				hitCount = AddUniqueLineHit(hitX, hitY, hitCount, xHit, yHi, coordinateTol)
			endif
		endif

		if (hitCount != 2)
			continue
		endif

		t0 = lineDX * hitX[0] + lineDY * hitY[0]
		t1 = lineDX * hitX[1] + lineDY * hitY[1]
		if (t1 < t0)
			temp = hitX[0]
			hitX[0] = hitX[1]
			hitX[1] = temp

			temp = hitY[0]
			hitY[0] = hitY[1]
			hitY[1] = temp
		endif

		wx[validLines][0] = hitX[0]
		wx[validLines][1] = hitX[1]
		wy[validLines][0] = hitY[0]
		wy[validLines][1] = hitY[1]
		validLines += 1
	endfor

	Redimension/N=(validLines, 2) wx, wy
	return validLines
End

static Function AddUniqueLineHit(hitX, hitY, numberOfHits, xValue, yValue, tolerance)
	Wave/D hitX, hitY
	Variable numberOfHits, xValue, yValue, tolerance

	Variable i, dx, dy
	for (i = 0; i < numberOfHits; i += 1)
		dx = xValue - hitX[i]
		dy = yValue - hitY[i]
		if (dx * dx + dy * dy <= tolerance * tolerance)
			return numberOfHits
		endif
	endfor

	if (numberOfHits < DimSize(hitX, 0))
		hitX[numberOfHits] = xValue
		hitY[numberOfHits] = yValue
		numberOfHits += 1
	endif

	return numberOfHits
End

ThreadSafe static Function BuildPolynomialLineBackgroundCore(WAVE w, WAVE wx, WAVE wy, WAVE fitMask, variable polynomialOrder)
	if (WaveDims(w) != 2 || WaveType(w, 1) != 1)
		print "BuildPolynomialLineBackground: w must be a numeric 2-D wave."
		return -1
	endif

	variable coordinateWavesInvalid = WaveType(wx, 1) != 1 || WaveType(wy, 1) != 1
	coordinateWavesInvalid = coordinateWavesInvalid || WaveDims(wx) != 2 || WaveDims(wy) != 2
	coordinateWavesInvalid = coordinateWavesInvalid || DimSize(wx, 1) != 2 || DimSize(wy, 1) != 2
	coordinateWavesInvalid = coordinateWavesInvalid || DimSize(wx, 0) != DimSize(wy, 0)
	if (coordinateWavesInvalid)
		print "BuildPolynomialLineBackground: wx and wy must be matching numeric waves with dimensions (numberOfLines, 2)."
		return -1
	endif

	if (numtype(polynomialOrder) != 0 || polynomialOrder < 0 || polynomialOrder != floor(polynomialOrder))
		print "BuildPolynomialLineBackground: polynomialOrder must be a non-negative integer."
		return -1
	endif

	Variable numberOfLines = DimSize(wx, 0)
	if (numberOfLines < 1)
		print "BuildPolynomialLineBackground: wx and wy contain no lines."
		return -1
	endif

	variable nx = DimSize(w, 0), ny = DimSize(w, 1)
	if (WaveDims(fitMask) != 2 || DimSize(fitMask, 0) != nx || DimSize(fitMask, 1) != ny)
		print "BuildPolynomialLineBackground: fitMask must match the first two dimensions of w."
		return -1
	endif
	variable polynomialTerms = polynomialOrder + 1
	variable xScaleDelta = DimDelta(w, 0), yScaleDelta = DimDelta(w, 1)
	if (xScaleDelta == 0 || yScaleDelta == 0)
		print "BuildPolynomialLineBackground: w has invalid dimension scaling."
		return -1
	endif

	Duplicate/O/D w, wBackground
	Redimension/D wBackground
	wBackground = 0

	Make/FREE/D/N=(numberOfLines, polynomialTerms) coefficientTable = 0
	Make/FREE/D/N=(numberOfLines) lineOffsets = 0
	Make/FREE/D/N=2 xTrace, yTrace
	Make/FREE/D/N=1 alongWave

	variable lineIndex, sampleIndex, numberOfSamples, finiteSamples
	variable xIndex, yIndex, fittedLines = 0, skippedLines = 0, imageLineError
	variable xPoint0, xPoint1, yPoint0, yPoint1, segmentDX, segmentDY, segmentLength
	variable unitDX, unitDY, lineDX = 0, lineDY = 0, normalX = 0, normalY = 0, lineOffset
	variable directionIsSet = 0, parallelError, coefficientIndex, coefficientsAreFinite
	variable bracketIndex, lowerLine, upperLine, pointAlong, pointAcross, fractionAcross
	variable lowerValue, upperValue, backgroundValue, offsetSpan

	for (lineIndex = 0; lineIndex < numberOfLines; lineIndex += 1)
		xPoint0 = wx[lineIndex][0]
		xPoint1 = wx[lineIndex][1]
		yPoint0 = wy[lineIndex][0]
		yPoint1 = wy[lineIndex][1]

		xTrace[0] = DimOffset(w, 0) + xScaleDelta * xPoint0
		xTrace[1] = DimOffset(w, 0) + xScaleDelta * xPoint1
		yTrace[0] = DimOffset(w, 1) + yScaleDelta * yPoint0
		yTrace[1] = DimOffset(w, 1) + yScaleDelta * yPoint1

		if (numtype(xPoint0 + xPoint1 + yPoint0 + yPoint1) != 0)
			skippedLines += 1
			continue
		endif

		segmentDX = xPoint1 - xPoint0
		segmentDY = yPoint1 - yPoint0
		segmentLength = sqrt(segmentDX^2 + segmentDY^2)
		if (segmentLength <= 1e-12)
			skippedLines += 1
			continue
		endif

		unitDX = segmentDX / segmentLength
		unitDY = segmentDY / segmentLength
		if (!directionIsSet)
			lineDX = unitDX
			lineDY = unitDY
			normalX = -lineDY
			normalY = lineDX
			directionIsSet = 1
		else
			parallelError = abs(lineDX * unitDY - lineDY * unitDX)
			if (parallelError > 1e-7)
				skippedLines += 1
				continue
			endif
		endif

		lineOffset = normalX * (xPoint0 + xPoint1) / 2 + normalY * (yPoint0 + yPoint1) / 2

		ImageLineProfile/SC srcWave=w, xWave=xTrace, yWave=yTrace
		imageLineError = V_flag

		Wave/Z profile = W_ImageLineProfile
		Wave/Z profileX = W_LineProfileX
		Wave/Z profileY = W_LineProfileY
		if (imageLineError != 0 || !WaveExists(profile) || !WaveExists(profileX) || !WaveExists(profileY))
			skippedLines += 1
			continue
		endif

		numberOfSamples = DimSize(profile, 0)
		if (DimSize(profileX, 0) != numberOfSamples || DimSize(profileY, 0) != numberOfSamples)
			skippedLines += 1
			continue
		endif

		Redimension/N=(numberOfSamples) alongWave
		alongWave = lineDX * ((profileX[p] - DimOffset(w, 0)) / xScaleDelta) + lineDY * ((profileY[p] - DimOffset(w, 1)) / yScaleDelta)

		finiteSamples = 0
		for (sampleIndex = 0; sampleIndex < numberOfSamples; sampleIndex += 1)
			xIndex = round((profileX[sampleIndex] - DimOffset(w, 0)) / xScaleDelta)
			yIndex = round((profileY[sampleIndex] - DimOffset(w, 1)) / yScaleDelta)
			if (xIndex < 0 || xIndex >= nx || yIndex < 0 || yIndex >= ny || !fitMask[xIndex][yIndex])
				profile[sampleIndex] = NaN
			endif
			if (numtype(profile[sampleIndex] + alongWave[sampleIndex]) == 0)
				finiteSamples += 1
			endif
		endfor

		if (finiteSamples < polynomialTerms)
			skippedLines += 1
			continue
		endif

		CurveFit/Q/M=2/W=0 poly (polynomialTerms), profile /X=alongWave
		Wave/Z/D fitCoefficients = W_coef
		if (!WaveExists(fitCoefficients) || DimSize(fitCoefficients, 0) != polynomialTerms)
			skippedLines += 1
			continue
		endif

		coefficientsAreFinite = 1
		for (coefficientIndex = 0; coefficientIndex < polynomialTerms; coefficientIndex += 1)
			if (numtype(fitCoefficients[coefficientIndex]) != 0)
				coefficientsAreFinite = 0
				break
			endif
		endfor
		if (!coefficientsAreFinite)
			skippedLines += 1
			continue
		endif

		profile = poly(fitCoefficients, alongWave[p])

		lineOffsets[fittedLines] = lineOffset
		for (coefficientIndex = 0; coefficientIndex < polynomialTerms; coefficientIndex += 1)
			coefficientTable[fittedLines][coefficientIndex] = fitCoefficients[coefficientIndex]
		endfor

		fittedLines += 1
	endfor

	if (fittedLines > 0)
		Redimension/N=(fittedLines) lineOffsets
		Redimension/N=(fittedLines, polynomialTerms) coefficientTable
		SortColumns keyWaves={lineOffsets}, sortWaves={lineOffsets, coefficientTable}
	endif

	if (fittedLines > 0)
		for (xIndex = 0; xIndex < nx; xIndex += 1)
			for (yIndex = 0; yIndex < ny; yIndex += 1)
				pointAlong = lineDX * xIndex + lineDY * yIndex
				pointAcross = normalX * xIndex + normalY * yIndex

				bracketIndex = BinarySearch(lineOffsets, pointAcross)
				if (bracketIndex == -1)
					lowerLine = 0
					upperLine = 0
				elseif (bracketIndex == -2 || bracketIndex >= fittedLines - 1)
					lowerLine = fittedLines - 1
					upperLine = fittedLines - 1
				else
					lowerLine = bracketIndex
					upperLine = bracketIndex + 1
				endif

				lowerValue = coefficientTable[lowerLine][polynomialTerms - 1]
				for (coefficientIndex = polynomialTerms - 2; coefficientIndex >= 0; coefficientIndex -= 1)
					lowerValue = lowerValue * pointAlong + coefficientTable[lowerLine][coefficientIndex]
				endfor

				if (upperLine == lowerLine)
					backgroundValue = lowerValue
				else
					upperValue = coefficientTable[upperLine][polynomialTerms - 1]
					for (coefficientIndex = polynomialTerms - 2; coefficientIndex >= 0; coefficientIndex -= 1)
						upperValue = upperValue * pointAlong + coefficientTable[upperLine][coefficientIndex]
					endfor

					offsetSpan = lineOffsets[upperLine] - lineOffsets[lowerLine]
					if (abs(offsetSpan) <= 1e-12)
						backgroundValue = (lowerValue + upperValue) / 2
					else
						fractionAcross = (pointAcross - lineOffsets[lowerLine]) / offsetSpan
						fractionAcross = min(max(fractionAcross, 0), 1)
						backgroundValue = lowerValue + fractionAcross * (upperValue - lowerValue)
					endif
				endif

				if (numtype(backgroundValue) != 0)
					backgroundValue = 0
				endif
				wBackground[xIndex][yIndex] = backgroundValue
			endfor
		endfor
	endif

	if (skippedLines > 0)
		printf "BuildPolynomialLineBackground: fitted %d line(s); skipped %d invalid or undersampled line(s).\r", fittedLines, skippedLines
	endif

	return fittedLines
End

/// @function RemovePolynomialLineFitBackground
/// @brief Remove fitted polynomial background along a user-selected angle.
///
/// The fit can use the current rectangular marquee or an enhanced polygonal
/// marquee. Subtraction can then be applied to the full image or only inside
/// the selected region.
///
/// @param grfName Optional graph window name.
/// @returns Zero after completing the operation, negative on error.
static Function RemovePolynomialLineFitBackground([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0 : 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName=grfName)

	variable order = 1, density = 1, selectionMode = 1, applicationMode = 1
	
	if (WaveDims(wRef) == 2 || WaveDims(wRef) == 3)
		Prompt order, "Background polynomial order (constant = 0, line = 1, ... 5th order poly max)"
		Prompt density, "Line density percentage [e.g. 0.25 (25%). Set 0 or 1 for 100%]"
		Prompt selectionMode, "Fit selection", popup, "Full image;Current rectangular marquee;Enhanced marquee (click vertices);Use last enhanced selection"
		Prompt applicationMode, "Apply subtraction", popup, "Entire image;Selected region only"
		DoPrompt "Set E, F cursors to define the line for background subtraction", order, density, selectionMode, applicationMode
	else
		print "This operations needs a image or a stack of images."
		return -1
	endif

	density = (density > 0 && density < 1) ? density : 1 // Use only percentages
	order = trunc(order)

	if (V_flag || order < 0 || order > 5)
		return -1
	endif

	variable eExists = strlen(CsrInfo(E)) > 0
	variable fExists = strlen(CsrInfo(F)) > 0
	if (eExists || fExists)
		print "The operation uses cursors E and F; disable them to proceed."
		return -1
	endif
	
	variable nrows = DimSize(wRef, 0), ncols = DimSize(wRef, 1)
	if (nrows < 2 || ncols < 2)
		print "The image is too small for line background removal."
		return -1
	endif
	Cursor/I/C=(65535,65535,0)/S=1/N=1/P E $NameOfWave(wRef) round(1.3 * nrows / 2), round(0.7 * ncols / 2)
	Cursor/I/C=(65535,65535,0)/S=1/N=1/P F $NameOfWave(wRef) round(0.7 * nrows / 2), round(1.3 * ncols / 2)

	variable c1x, c1y, c2x, c2y
	STRUCT sUserCursorPositions sc
	[c1x, c1y, c2x, c2y] = ATH_Cursors#UserGetCursorPositions(sc, "E", "F", usePoints = 1)
	variable angleDeg = atan2(c2y - c1y,c2x - c1x) * 180 / pi

	DFREF savedDFR = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	Make/O/B/U/N=(nrows, ncols) fitMask = 1
	variable hasSelection = selectionMode != 1
	variable left = 0, right = 0, top = 0, bottom = 0
	variable fitX0 = 0, fitX1 = nrows - 1, fitY0 = 0, fitY1 = ncols - 1
	if (selectionMode == 2)
		variable hasMarquee = 0
		[hasMarquee, left, right, top, bottom] = ATH_Marquee#GetMarqueeToIndex(grfName=grfName)
		if (!hasMarquee)
			SetDataFolder savedDFR
			print "Draw a rectangular marquee first, or choose Enhanced marquee."
			return -1
		endif
		fitX0 = min(max(round(min(left, right)), 0), nrows - 1)
		fitX1 = min(max(round(max(left, right)), 0), nrows - 1)
		fitY0 = min(max(round(min(top, bottom)), 0), ncols - 1)
		fitY1 = min(max(round(max(top, bottom)), 0), ncols - 1)
		fitMask = p >= fitX0 && p <= fitX1 && q >= fitY0 && q <= fitY1
	elseif (selectionMode == 3 || selectionMode == 4)
		SetDataFolder savedDFR
		variable enhancedMarqueeResult = 1
		if (selectionMode == 3)
			enhancedMarqueeResult = ATH_Marquee#UserCreateEnhancedMarqueeMask(grfName=grfName)
			if (enhancedMarqueeResult == 2)
				enhancedMarqueeResult = ATH_Marquee#RestoreLastEnhancedMarqueeMask(grfName=grfName)
			endif
		else
			enhancedMarqueeResult = ATH_Marquee#RestoreLastEnhancedMarqueeMask(grfName=grfName)
		endif
		DFREF imageDFR = GetWavesDataFolderDFR(wRef)
		WAVE/Z enhancedMask = imageDFR:M_EnhancedROIMask
		if (enhancedMarqueeResult != 1 || !WaveExists(enhancedMask) || DimSize(enhancedMask, 0) != nrows || DimSize(enhancedMask, 1) != ncols || sum(enhancedMask) < 3)
			print "The enhanced marquee was canceled, has too few pixels, or no saved enhanced selection is available for this image."
			return -1
		endif
		SetDataFolder NewFreeDataFolder()
		Make/O/B/U/N=(nrows, ncols) fitMask = enhancedMask
	endif

	variable xIndex, yIndex, selectedPixels = 0
	fitX0 = nrows - 1; fitX1 = 0; fitY0 = ncols - 1; fitY1 = 0
	for (xIndex = 0; xIndex < nrows; xIndex += 1)
		for (yIndex = 0; yIndex < ncols; yIndex += 1)
			if (fitMask[xIndex][yIndex])
				fitX0 = min(fitX0, xIndex); fitX1 = max(fitX1, xIndex)
				fitY0 = min(fitY0, yIndex); fitY1 = max(fitY1, yIndex)
				selectedPixels += 1
			endif
		endfor
	endfor
	if (selectedPixels < 3 || fitX1 <= fitX0 || fitY1 <= fitY0)
		SetDataFolder savedDFR
		print "The selected fitting area is too small."
		return -1
	endif

	variable generatedLines = MakeAngledImageLinesInArea(wRef, angleDeg, density, fitX0 - 0.5, fitX1 + 0.5, fitY0 - 0.5, fitY1 + 0.5)
	if (generatedLines < 1)
		SetDataFolder savedDFR
		print "Could not create enough fitting lines in the selected area."
		return -1
	endif

	WAVE wx, wy
	
	if(WaveDims(wRef) == 2)
	
		variable fittedLines = BuildPolynomialLineBackgroundCore(wRef, wx, wy, fitMask, order)
		if (fittedLines < 1)
			SetDataFolder savedDFR
			print "Could not fit a background in the selected area."
			return -1
		endif
		WAVE wBackground
		
		ATH_DFR#BackupWaveInWaveDFQ(wRef)
		if (applicationMode == 2 && hasSelection)
			wRef -= wBackground * fitMask
		else
			wRef -= wBackground
		endif
	else // stack
		Make/O/WAVE/N=(DimSize(wRef,2)) ww
		ATH_DFR#BackupWaveInWaveDFQ(wRef)
		MultiThreadingControl setMode=0	
		MultiThread ww = RemovePolynomialLineFitBackgroundMT_Worker(wRef, p, order, wx, wy, fitMask, applicationMode == 2 && hasSelection)
		MultiThreadingControl setMode=1	
		// At this point, ww holds wave references to numplanes free waves
		// created by DriftCorrelation_Worker.
		// So, now repack all layers.
		Concatenate/O {ww}, $GetWavesDataFolder(wRef,2)
		KillWaves ww
	endif
	SetDataFolder savedDFR
	string note2Wwave = "Applied RemovePolynomialLineFitBackground(order = " + num2str(order) + ", density = "+num2str(density) + ")\n"
	note2Wwave += "Fit selection: " + StringFromList(selectionMode - 1, "full image;rectangle marquee;enhanced marquee;last enhanced marquee") + "; subtraction: " + SelectString(applicationMode == 2 && hasSelection, "entire image", "selected region only") + ".\n"
	if (hasSelection)
		note2Wwave += "Selection bounds [" + num2str(fitX0)+","+ num2str(fitY0)+","+ num2str(fitX1)+","+num2str(fitY1)+"]"
	endif
	Note wRef, note2Wwave
	return 0
End


/// @function RemovePolynomialLineFitBackground
/// @brief Remove fitted polynomial background along a user-selected angle.
///
/// Fits with the supplied selection mask, then applies the requested scope.
///
/// @param grfName Optional graph window name.
/// @returns Zero after completing the operation, negative on error.
ThreadSafe static Function/WAVE RemovePolynomialLineFitBackgroundMT_Worker(WAVE wRef, variable plane,
							variable order, WAVE wx, WAVE wy, WAVE fitMask, variable selectedRegionOnly)

	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	ImageTransform/P=(plane) getPlane wRef
	WAVE M_ImagePlane	
	BuildPolynomialLineBackgroundCore(M_ImagePlane, wx, wy, fitMask, order)
	WAVE wBackground
	
	if (selectedRegionOnly)
		M_ImagePlane -= wBackground * fitMask
	else
		M_ImagePlane -= wBackground
	endif

	SetDataFolder dfSav	
	return M_ImagePlane
End
