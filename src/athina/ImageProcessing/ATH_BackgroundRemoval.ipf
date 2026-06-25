#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_BackgroundRemoval
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

/// @file AngledImageLines.ipf
/// @brief Parallel image-line generation and polynomial background construction.

/// @brief Generate non-overlapping parallel line segments through a 2-D image.
///
/// The angle is measured counterclockwise from positive x in pixel coordinates.
/// For a line direction theta, the minimum perpendicular separation is
/// `abs(sin(theta)) + abs(cos(theta))` pixels. This is the projection width of
/// one square pixel onto the line normal and prevents neighboring rasterized
/// line regions from occupying the same pixel cell.
///
/// `lineDensity` is interpreted as follows:
///
/// - `0` or `1`: use the maximum non-overlapping line count.
/// - `0 < lineDensity < 1`: use that fraction of the maximum count.
/// - `lineDensity > 1`: request that absolute number of lines.
///
/// Fractional and absolute requests are rounded to the nearest integer and
/// clamped to the supported range of three lines through the angle-dependent
/// maximum. The image boundary is `[-0.5, nx-0.5] x [-0.5, ny-0.5]`. Lines
/// through corners are avoided by shifting the phase of the complete lattice.
///
/// The function overwrites `wx` and `wy` in the current data folder. They have
/// dimensions `(numberOfLines, 2)`. Endpoint zero precedes endpoint one in the
/// direction specified by `thetaDeg`.
///
/// @param[in] w Numeric 2-D image wave.
/// @param[in] thetaDeg Line angle in degrees.
/// @param[in] lineDensity Requested absolute or fractional line density.
/// @return Number of generated lines, or a negative value on error.

static Function MakeAngledImageLines(Wave w, variable thetaDeg, variable lineDensity)
   
    variable nx = DimSize(w, 0), ny = DimSize(w, 1)

    // A line angle is periodic over 180 degrees.
    thetaDeg = mod(thetaDeg, 180)
    thetaDeg = thetaDeg < 0 ? thetaDeg + 180 : thetaDeg

    variable thetaRad = thetaDeg * pi / 180, lineDX = cos(thetaRad), lineDY = sin(thetaRad)

    // Unit normal to the family of parallel lines.
    variable normalX = -lineDY, normalY = lineDX
    variable xLo = -0.5, xHi = nx - 0.5, yLo = -0.5, yHi = ny - 0.5

    // Project all corners onto the unit normal. A line is normal.r = c.
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

    variable projectedWidth = cMax - cMin, minimumLineSpacing = abs(normalX) + abs(normalY)
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

    Make/O/D/N=(targetLines, 2) wx = NaN, wy = NaN
    Make/FREE/D/N=4 hitX = NaN, hitY = NaN

    // Center the lattice. At maxLines, adjacent lines remain separated by at
    // least the angle-dependent projection width of one square pixel.
    variable lineSpacing = projectedWidth / targetLines
    variable cornerTol = 1e-10 * max(1, projectedWidth)
    variable coordinateTol = 1e-10 * max(1, max(nx, ny)), componentTol = 1e-14
    variable validLines = 0, j, c, xHit, yHit, t0, t1, hitCount, hitsCorner, temp
    // A line family has a free phase within one spacing interval. Try the
    // centered phase first, then symmetric alternatives. There are only four
    // corner projections, so one of these nine phases must avoid all corners.
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

        // This tests both the extreme and the two possible intermediate corner
        // projections. Extreme corners are normally excluded by the half-step.
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

        hitX = NaN
        hitY = NaN
        hitCount = 0

        // Intersections with x = xLo and x = xHi.
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

        // Intersections with y = yLo and y = yHi.
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
            // A non-corner line crossing a rectangle should always have two
            // unique intersections. Skip it defensively if roundoff says not.
            continue
        endif

        // Keep endpoint ordering consistent with the requested line direction.
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


// Adds a rectangle-boundary hit unless it duplicates a hit already present.
// Returns the updated number of unique hits.
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

static Function BuildPolynomialLineBackgroundCore(WAVE w, WAVE wx, WAVE wy, variable polynomialOrder)

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
    variable polynomialTerms = polynomialOrder + 1
    variable xScaleDelta = DimDelta(w, 0), yScaleDelta = DimDelta(w, 1)
    if (xScaleDelta == 0 || yScaleDelta == 0)
        print "BuildPolynomialLineBackground: w has invalid dimension scaling."
        return -1
    endif

    // Duplicate first to preserve w's dimension scaling, units, and note.
    // Redimension is necessary because Duplicate's /D flag describes the wave
    // reference type but does not convert the destination's numeric type.
    Duplicate/O/D w, wBackground
    Redimension/D wBackground
    wBackground = 0

    // One row of coefficients is stored per successfully fitted support line.
    Make/FREE/D/N=(numberOfLines, polynomialTerms) coefficientTable = 0
    Make/FREE/D/N=(numberOfLines) lineOffsets = 0

    // ImageLineProfile's named destination flags were added in Igor Pro 10.
    // For Igor Pro 9 compatibility, run it in a free data folder
    // and use its standard W_ImageLineProfile/W_LineProfileX/Y outputs.
    //  Launcher will deal with these
	//  DFREF savedDFR = GetDataFolderDFR()
	//	SetDataFolder NewFreeDataFolder()
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

        // Give every support line the same global independent coordinate:
        // distance projected along the common line direction in pixel units.
        // This makes coefficients from neighboring lines directly comparable.
        Redimension/N=(numberOfSamples) alongWave
        alongWave = lineDX * ((profileX[p] - DimOffset(w, 0)) / xScaleDelta) + lineDY * ((profileY[p] - DimOffset(w, 1)) / yScaleDelta)

        finiteSamples = 0
        for (sampleIndex = 0; sampleIndex < numberOfSamples; sampleIndex += 1)
            if (numtype(profile[sampleIndex] + alongWave[sampleIndex]) == 0)
                finiteSamples += 1
            endif
        endfor

        if (finiteSamples < polynomialTerms)
            skippedLines += 1
            continue
        endif

        // CurveFit's poly parameter is the number of terms, not the degree.
        // alongWave is supplied as X so the same coordinate system is used by
        // all lines. The fitted background then replaces the sampled profile.
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

        // W_LineProfileX/Y contain the actual intermediate sampling locations,
        // not merely the two vertices in xTrace/yTrace. /SC expresses them in
        // w's scaled coordinates. This count wave marks direct support pixels;
        // wBackground itself will be evaluated everywhere below.
        for (sampleIndex = 0; sampleIndex < numberOfSamples; sampleIndex += 1)
            if (numtype(profile[sampleIndex] + profileX[sampleIndex] + profileY[sampleIndex]) != 0)
                continue
            endif
            xIndex = ScaleToIndex(w, profileX[sampleIndex], 0)
            yIndex = ScaleToIndex(w, profileY[sampleIndex], 1)
            xIndex = min(max(xIndex, 0), nx - 1)
            yIndex = min(max(yIndex, 0), ny - 1)
        endfor

        fittedLines += 1
    endfor

    // Sort the successfully fitted lines by their perpendicular coordinate.
    // SortColumns moves the complete coefficient rows with the offset keys.
    if (fittedLines > 0)
        Redimension/N=(fittedLines) lineOffsets
        Redimension/N=(fittedLines, polynomialTerms) coefficientTable
        SortColumns keyWaves={lineOffsets}, sortWaves={lineOffsets, coefficientTable}
    endif

    // Fill the complete image. Polynomial values are evaluated along the line
    // direction and linearly interpolated across adjacent support lines. For
    // pixels outside the support-line range, use the nearest fitted line.
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

                // Horner evaluation of one row of coefficientTable.
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

                // Absolute guarantee: no NaN or Inf is written to the result.
                if (numtype(backgroundValue) != 0)
                    backgroundValue = 0
                endif
                wBackground[xIndex][yIndex] = backgroundValue
            endfor
        endfor
    endif

    // SetDataFolder savedDFR

//    if (skippedLines > 0)
//        printf "BuildPolynomialLineBackground: fitted %d line(s); skipped %d invalid or undersampled line(s).\r", fittedLines, skippedLines
//    endif

    return fittedLines
End

// ----- Launcher ------ //

/// @function RemovePolynomialLineFitBackground
/// @brief Remove fitted polynimial background along user selected angles.
/// @param grfName (optional) Name of the graph window.
/// @returns Zero after completing the operation.
static Function RemovePolynomialLineFitBackground([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopGraphToWaveRef(grfName=grfName)

	variable order = 1, density = 1
	if(WaveDims(wRef) == 2)
		Prompt order, "Background polynomial order (constant = 0, line = 1, ...)"
		Prompt density, "Line density percentage [e.g. 0.25 (25%). Set 0 or 1 for 100%]"
		DoPrompt "Use E, F cursors to define the line for background subtraction ", order, density
	else
		print "You need a 2D wave (single image) for this operation"
		return -1
	endif
	density = (density > 0 && density < 1) ? density : 0
	order = trunc(order)
	if(V_flag || order < 0 || order > 12)
		return -1
	endif
	ATH_DFR#BackupWaveInWaveDFQ(wRef)
	string noteStr = note(wRef)
	// No need to kill anything
	variable eExists= strlen(CsrInfo(E)) > 0
	variable fExists= strlen(CsrInfo(F)) > 0
	if(eExists || fExists)
		print "The operation user cursors E & F, disable them to proceeed"
		return -1
	endif
	// Drop two cursors and wait
	variable nrows = DimSize(wRef,0), ncols = DimSize(wRef,1)
	Cursor/I/C=(65535,65535,0)/S=1/N=1/P E $NameOfWave(wRef) round(1.3 * nrows/2), round(0.7 * ncols/2)
	Cursor/I/C=(65535,65535,0)/S=1/N=1/P F $NameOfWave(wRef) round(0.7 * nrows/2), round(1.3 * ncols/2)	
	variable c1x, c1y, c2x, c2y
	STRUCT sUserCursorPositions sc
	[c1x, c1y, c2x, c2y] = ATH_Cursors#UserGetCursorPositions(sc, "E", "F", usePoints = 1)
	variable angleDeg = atan((c2y-c1y)/(c2x-c1x))* 180/pi
	
	DFREF savedDFR = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	MakeAngledImageLines(wRef, angleDeg, density)
	WAVE wx ,wy
	BuildPolynomialLineBackgroundCore(wRef, wx, wy, order)
	WAVE wBackground
	// Duplicate/O wBackground, root:wBackground // Debug
	SetDataFolder savedDFR
	wRef -= wBackground
	return 0
End
