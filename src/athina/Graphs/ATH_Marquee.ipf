#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Marquee
#pragma version = 1.1

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

/// @module ATH_Marquee
/// @brief Module ATH_Marquee.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH Marquee functionality.

Structure sUserMarqueePositions
	// Used in ATH_UserGetMarqueePositions
	variable left
	variable right
	variable top
	variable bottom
	variable canceled
EndStructure

/// @brief State used while collecting vertices for an enhanced marquee.
Structure sEnhancedMarqueeState
	string graphName
	string panelName
	variable finished
	variable canceled
EndStructure

/// @function UserCreateEnhancedMarqueeMask
/// @brief Let the user make a polygonal marquee by clicking image vertices.
/// @details Click vertices in order, then choose "Use selection". The returned
/// mask is retained beside the image as `M_EnhancedROIMask` so it can also be
/// inspected or reused by other ATH operations.
/// @param grfName Graph containing the target image.
/// @returns One when a polygon mask was created, two when the saved mask should
/// be reused, zero when canceled, or a negative value on error.
static Function UserCreateEnhancedMarqueeMask([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0 : 1, WinName(0, 1, 1), grfName)
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	if (!WaveExists(wRef))
		return -1
	endif

	DFREF stateDFR = ATH_DFR#CreateDataFolderGetDFREF("root:Packages:ATH_DataFolder:EnhancedMarquee")
	Make/O/D/N=0 stateDFR:xVertices, stateDFR:yVertices
	variable/G stateDFR:finished = 0
	variable/G stateDFR:canceled = 0
	variable/G stateDFR:useLastSelection = 0
	string/G stateDFR:graphName = grfName
	string panelName = UniqueName("ATHEnhancedMarquee", 9, 0)
	string/G stateDFR:panelName = panelName

	DoWindow/F $grfName
	ClearEnhancedMarqueePreview(grfName)
	SetWindow $grfName hook(ATH_EnhancedMarqueeHook)=ATH_Marquee#EnhancedMarqueeHook

	NewPanel/N=$panelName/K=2/W=(139,341,430,540) as "Enhanced Marquee"
	AutoPositionWindow/E/M=1/R=$grfName
	DrawText 12,20,"Click image vertices in order to outline the region."
	DrawText 12,38,"Use Undo or Clear to correct the outline."
	DrawText 12,54,"Use last selection reuses this image's saved polygon."
	TitleBox status, pos={12,71}, size={260,18}, title="0 vertices (need at least 3)"
	Button undo, pos={12,98}, size={70,22}, title="Undo", proc=ATH_Marquee#EnhancedMarqueeButtonProc
	Button clear, pos={92,98}, size={70,22}, title="Clear", proc=ATH_Marquee#EnhancedMarqueeButtonProc
	Button use, pos={172,98}, size={105,22}, title="Use selection", proc=ATH_Marquee#EnhancedMarqueeButtonProc
	Button useLast, pos={12,128}, size={115,22}, title="Use last selection", proc=ATH_Marquee#EnhancedMarqueeButtonProc
	Button showLast, pos={137,128}, size={120,22}, title="Show last selection", proc=ATH_Marquee#EnhancedMarqueeButtonProc
	Button cancel, pos={12,158}, size={100,22}, title="Cancel", proc=ATH_Marquee#EnhancedMarqueeButtonProc
	SetWindow $panelName userdata(ATH_EnhancedMarqueeState)="root:Packages:ATH_DataFolder:EnhancedMarquee"
	PauseForUser $panelName, $grfName

	SetWindow $grfName hook(ATH_EnhancedMarqueeHook)=$""
	NVAR/SDFR=stateDFR wasCanceled = canceled, reuseLast = useLastSelection
	WAVE/SDFR=stateDFR xVertices, yVertices
	ClearEnhancedMarqueePreview(grfName)
	if (reuseLast)
		return 2
	endif
	if (wasCanceled || numpnts(xVertices) < 3)
		return 0
	endif

	WAVE polygonMask = PolygonCoordinatesToROIMask(xVertices, yVertices, grfName=grfName)
	return WaveExists(polygonMask)
End

/// @brief Receive mouse clicks while the enhanced-marquee panel is open.
static Function EnhancedMarqueeHook(STRUCT WMWinHookStruct &s)
	if (s.eventCode != 5)
		return 0
	endif
	DFREF stateDFR = $("root:Packages:ATH_DataFolder:EnhancedMarquee")
	if (!DataFolderRefStatus(stateDFR))
		return 0
	endif
	SVAR/SDFR=stateDFR graphName
	if (cmpstr(s.winName, graphName))
		return 0
	endif
	string axisX, axisY
	[axisX, axisY] = ATH_Graph#GetAxes(grfName=s.winName)
	WAVE/SDFR=stateDFR xVertices, yVertices
	xVertices[numpnts(xVertices)] = {AxisValFromPixel(s.winName, axisX, s.mouseLoc.h)}
	yVertices[numpnts(yVertices)] = {AxisValFromPixel(s.winName, axisY, s.mouseLoc.v)}
	DrawEnhancedMarqueePreview(s.winName, xVertices, yVertices)
	UpdateEnhancedMarqueeStatus()
	return 1
End

/// @brief Handle enhanced-marquee panel buttons.
static Function EnhancedMarqueeButtonProc(STRUCT WMButtonAction &b) : ButtonControl
	if (b.eventCode != 2)
		return 0
	endif
	DFREF stateDFR = $(GetUserData(b.win, "", "ATH_EnhancedMarqueeState"))
	if (!DataFolderRefStatus(stateDFR))
		return 0
	endif
	WAVE/SDFR=stateDFR xVertices, yVertices
	NVAR/SDFR=stateDFR finished, canceled, useLastSelection
	SVAR/SDFR=stateDFR graphName
	strswitch (b.ctrlName)
		case "undo":
			if (numpnts(xVertices) > 0)
				Redimension/N=(numpnts(xVertices)-1) xVertices, yVertices
			endif
			DrawEnhancedMarqueePreview(graphName, xVertices, yVertices)
			UpdateEnhancedMarqueeStatus()
			break
		case "clear":
			Redimension/N=0 xVertices, yVertices
			ClearEnhancedMarqueePreview(graphName)
			UpdateEnhancedMarqueeStatus()
			break
		case "use":
			if (numpnts(xVertices) < 3)
				DoAlert 0, "Click at least three vertices before using the enhanced marquee."
				return 0
			endif
			finished = 1
			KillWindow/Z $b.win
			break
		case "useLast":
			useLastSelection = 1
			KillWindow/Z $b.win
			break
		case "showLast":
			if (!LoadLastEnhancedMarqueeVertices(graphName, xVertices, yVertices))
				DoAlert 0, "No saved enhanced marquee vertices are available for this image. Create and use an enhanced marquee once first."
				return 0
			endif
			DrawEnhancedMarqueePreview(graphName, xVertices, yVertices)
			UpdateEnhancedMarqueeStatus()
			break
		case "cancel":
			canceled = 1
			KillWindow/Z $b.win
			break
	endswitch
	return 0
End

/// @brief Redraw the in-progress polygon in a dedicated persistent draw group.
/// `ProgFront` is owned by Igor's marquee interaction and can be cleared while
/// clicking, so the preview is intentionally kept on `UserFront` instead.
static Function DrawEnhancedMarqueePreview(string grfName, WAVE xVertices, WAVE yVertices)
	ClearEnhancedMarqueePreview(grfName)
	variable i, nVertices = numpnts(xVertices)
	if (!nVertices)
		return 0
	endif
	string axisX, axisY
	[axisX, axisY] = ATH_Graph#GetAxes(grfName=grfName)
	SetDrawLayer/W=$grfName UserFront
	SetDrawEnv/W=$grfName gstart, gname=ATHEnhancedMarqueePreview
	SetDrawEnv/W=$grfName linefgc=(65535,0,0), fillpat=0, linethick=1.5, xcoord=$axisX, ycoord=$axisY
	if (nVertices == 2)
		DrawLine/W=$grfName xVertices[0], yVertices[0], xVertices[1], yVertices[1]
	elseif (nVertices >= 3)
		string pointList = "{"
		for (i = 0; i < nVertices; i += 1)
			if (i > 0)
				pointList += ","
			endif
			pointList += num2str(xVertices[i]) + "," + num2str(yVertices[i])
		endfor
		// Repeat the first vertex so the prospective closing edge stays visible.
		pointList += "," + num2str(xVertices[0]) + "," + num2str(yVertices[0])
		pointList += "}"
		string drawCommand = "DrawPoly/W=" + PossiblyQuoteName(grfName) + " " + num2str(xVertices[0]) + "," + num2str(yVertices[0]) + ",1,1," + pointList
		Execute/Q/Z drawCommand
	endif
	SetDrawEnv/W=$grfName gstop
	return 0
End

/// @brief Remove the temporary enhanced-marquee outline.
static Function ClearEnhancedMarqueePreview(string grfName)
	SetDrawLayer/W=$grfName UserFront
	DrawAction/W=$grfName getgroup=ATHEnhancedMarqueePreview
	if (V_flag)
		DrawAction/W=$grfName delete=V_startPos,V_endPos
	endif
	return 0
End

/// @brief Refresh the vertex count in the enhanced-marquee panel.
static Function UpdateEnhancedMarqueeStatus()
	DFREF stateDFR = $("root:Packages:ATH_DataFolder:EnhancedMarquee")
	WAVE/SDFR=stateDFR xVertices
	SVAR/SDFR=stateDFR panelName
	if (WinType(panelName) == 7)
		TitleBox status, win=$panelName, title=num2str(numpnts(xVertices)) + " vertices" + SelectString(numpnts(xVertices) < 3, " (ready)", " (need at least 3)")
	endif
	return 0
End

/// @brief Convert polygon vertex coordinates to an image-sized binary ROI mask.
static Function/WAVE PolygonCoordinatesToROIMask(WAVE xVertices, WAVE yVertices, [string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0 : 1, WinName(0, 1, 1), grfName)
	WAVE wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	DFREF imageDFR = GetWavesDataFolderDFR(wRef)
	Make/O/B/U/N=(DimSize(wRef, 0), DimSize(wRef, 1)) imageDFR:M_EnhancedROIMask = 0
	WAVE mask = imageDFR:M_EnhancedROIMask
	Make/O/D/N=(numpnts(xVertices)) imageDFR:M_EnhancedMarqueeVerticesX
	Make/O/D/N=(numpnts(yVertices)) imageDFR:M_EnhancedMarqueeVerticesY
	WAVE savedX = imageDFR:M_EnhancedMarqueeVerticesX
	WAVE savedY = imageDFR:M_EnhancedMarqueeVerticesY
	savedX = xVertices[p]
	savedY = yVertices[p]
	variable xIndex, yIndex
	for (xIndex = 0; xIndex < DimSize(mask, 0); xIndex += 1)
		for (yIndex = 0; yIndex < DimSize(mask, 1); yIndex += 1)
			mask[xIndex][yIndex] = PointIsInsidePolygon(IndexToScale(wRef, xIndex, 0), IndexToScale(wRef, yIndex, 1), xVertices, yVertices)
		endfor
	endfor
	Note/K mask
	Note mask, "Enhanced marquee: " + num2str(numpnts(xVertices)) + " vertices"
	return mask
End

/// @brief Restore the saved enhanced-marquee mask for the specified image.
/// @details New selections are restored from their vertex waves so the mask is
/// regenerated if it was removed. Older sessions that contain only the mask
/// remain usable.
static Function RestoreLastEnhancedMarqueeMask([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0 : 1, WinName(0, 1, 1), grfName)
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	if (!WaveExists(wRef))
		return 0
	endif
	DFREF imageDFR = GetWavesDataFolderDFR(wRef)
	WAVE/Z savedX = imageDFR:M_EnhancedMarqueeVerticesX
	WAVE/Z savedY = imageDFR:M_EnhancedMarqueeVerticesY
	if (WaveExists(savedX) && WaveExists(savedY) && numpnts(savedX) >= 3 && numpnts(savedX) == numpnts(savedY))
		WAVE restoredMask = PolygonCoordinatesToROIMask(savedX, savedY, grfName=grfName)
		return WaveExists(restoredMask)
	endif
	WAVE/Z savedMask = imageDFR:M_EnhancedROIMask
	return WaveExists(savedMask) && DimSize(savedMask, 0) == DimSize(wRef, 0) && DimSize(savedMask, 1) == DimSize(wRef, 1) && sum(savedMask) >= 3
End

/// @brief Load saved enhanced-marquee vertices into the interactive preview.
static Function LoadLastEnhancedMarqueeVertices(string grfName, WAVE xVertices, WAVE yVertices)
	WAVE/Z wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	if (!WaveExists(wRef))
		return 0
	endif
	DFREF imageDFR = GetWavesDataFolderDFR(wRef)
	WAVE/Z savedX = imageDFR:M_EnhancedMarqueeVerticesX
	WAVE/Z savedY = imageDFR:M_EnhancedMarqueeVerticesY
	if (!WaveExists(savedX) || !WaveExists(savedY) || numpnts(savedX) < 3 || numpnts(savedX) != numpnts(savedY))
		return 0
	endif
	Redimension/N=(numpnts(savedX)) xVertices, yVertices
	xVertices = savedX[p]
	yVertices = savedY[p]
	return 1
End

/// @brief Return one when a graph-coordinate point lies inside a polygon.
static Function PointIsInsidePolygon(variable x, variable y, WAVE xVertices, WAVE yVertices)
	variable i, j = numpnts(xVertices) - 1, inside = 0, crosses
	for (i = 0; i < numpnts(xVertices); i += 1)
		crosses = ((yVertices[i] > y) != (yVertices[j] > y))
		if (crosses && x < (xVertices[j] - xVertices[i]) * (y - yVertices[i]) / (yVertices[j] - yVertices[i]) + xVertices[i])
			inside = !inside
		endif
		j = i
	endfor
	return inside
End

/// @function MarqueeToMask
/// @brief Convert the active graph marquee into a numeric ROI mask.
/// @details
/// Reads the current graph interaction state and applies the requested operation to that selection.
/// @param grfName (optional) Name of the graph window.
/// @returns The resulting string; an empty string indicates that no result was available.
static Function/S MarqueeToMask([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	string axisX, axisY
	[axisX, axisY] = ATH_Graph#GetAxes()
	GetMarquee/K $axisX, $axisY
	if(!V_flag)
		return ""
	endif
	string maskPathStr = CoordinatesToROIMask(V_left, V_top, V_right, V_bottom, grfName = grfName)
	return maskPathStr // return the path of M_ROIMask
End

/// @function CoordinatesToROIMask
/// @brief Create an ROI mask from numeric rectangle coordinates.
/// @details
/// The rectangle is interpreted in graph-axis coordinates and converted to a mask matching the displayed image
/// or `spw`.
/// @param left Left region bound.
/// @param top Top region bound.
/// @param right Right region bound.
/// @param bottom Bottom region bound.
/// @param interior (optional) Mask value assigned inside the ROI.
/// @param exterior (optional) Mask value assigned outside the ROI.
/// @param spW (optional) Optional wave whose dimensions and scaling define the mask.
/// @param grfName (optional) Name of the graph window.
/// @returns The full path of the generated ROI mask wave.
static Function/S CoordinatesToROIMask(variable left, variable top, variable right, variable bottom, 
				[variable interior, variable exterior, variable spW, string grfName])
	/// Generate a Mask from Marquee
	/// The graph should have left, top axes
	/// By default the mask generated by ImageGenerateROIMask has 1 interior and 0 exterio values
	/// you can change the mask values with the optional parameters.
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	/// Creates the wave M_ROIMask
	interior = ParamIsDefault(interior) ? 1: interior
	exterior = ParamIsDefault(exterior) ? 0: exterior
	string maskPathStr
	WAVE wRef = ATH_Graph#TopImageToWaveRef(grfName = grfName)
	DoWindow/F $grfName // You need to have your imange stack as a top window
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	DrawAction  delete
	SetDrawEnv linefgc = (65535,16385,16385), fillpat = 0, linethick = 0.5, xcoord = top, ycoord = left
	DrawRect/W=$grfName left, top, right, bottom
	// Create the mask in the source wave data folder. Made the change on the 27.03.2026
	// so that the remove background operation using a marquee works for iXMCD operation
	DFREF saveDF = GetDataFolderDFR()
	SetDataFolder GetWavesDataFolderDFR(wRef)
	ImageGenerateROIMask/W=$grfName/i=(interior)/e=(exterior) $NameOfWave(wRef)
	WAVE/Z M_ROIMask
	if(V_flag)
		maskPathStr = GetWavesDataFolder(M_ROIMask, 2)
	else
		maskPathStr = ""
	endif

	if(spW) // converts to single-specision float
		Redimension/S M_ROIMask
	endif
		
	// Add a note to the mask
	string maskNotePattern = "Background area [left, top, right, bottom]=[%d,%d,%d,%d]", maskNote
	sprintf maskNote, maskNotePattern, left, top, right, bottom
	Note M_ROIMask, maskNote
	SetDataFolder saveDF
	
	variable domask = V_flag
	DrawAction  delete
	SetDrawLayer UserFront
	

	return maskPathStr // "" if mask fails, otherwise the pathname of M_ROIMask
End

/// @function WAVECoordinatesToROIMask
/// @brief Create an ROI mask from coordinate waves.
/// @details
/// The coordinate waves describe the ROI boundary in graph-axis coordinates; the mask inherits dimensions and
/// scaling from the displayed image or `spw`.
/// @param left Left region bound.
/// @param top Top region bound.
/// @param right Right region bound.
/// @param bottom Bottom region bound.
/// @param interior (optional) Mask value assigned inside the ROI.
/// @param exterior (optional) Mask value assigned outside the ROI.
/// @returns Reference to the result wave; a null wave reference indicates failure where supported.
static Function/WAVE WAVECoordinatesToROIMask(variable left, variable top, variable right, 
											  variable bottom, [variable interior, variable exterior])
	/// Creates the wave M_ROIMask
	interior = ParamIsDefault(interior) ? 1: interior // if set do not read metadata
	exterior = ParamIsDefault(exterior) ? 0: exterior // if set do not read metadata
	string winNameStr = WinName(0, 1, 1)
	string wnamestr = ATH_Graph#TopImageName(grfName=winNameStr)
	DoWindow/F $winNameStr // You need to have your imange stack as a top window
	SetDrawLayer ProgFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,16385,16385), fillpat = 0, linethick = 0.5, xcoord = top, ycoord = left
	DrawRect/W=$winNameStr left, top, right, bottom
	ImageGenerateROIMask/i=(interior)/e=(exterior) $wnamestr
	DrawAction  delete
	SetDrawLayer UserFront
	WAVE M_ROIMask
	Duplicate/O/FREE M_ROIMask, ATH_ROIMask
	Redimension/S ATH_ROIMask
	KillWaves/Z M_ROIMask
	return ATH_ROIMask
End

/// @function PartitionRegion
/// @brief Partition the active marquee region into a stack of image tiles.
/// @details
/// Use NameOfWave(waveRef) instead of imgNameTopGraphStr as the ' ' will be replace by _! CopyScales/P
/// waveRef, wavePRT.
/// @param evenNum (optional) If nonzero, force an even number of rows and columns.
/// @param square (optional) If nonzero, constrain the partitioned region to a square.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function PartitionRegion([int evenNum, int square])
	evenNum = ParamIsDefault(evenNum) ? 1 : evenNum
	square = ParamIsDefault(square) ? 0 : square
	string grfName = WinName(0, 1, 1)
	string xaxis, yaxis
	[xaxis, yaxis] = ATH_Graph#GetAxes(grfName=grfName) // Use top graph
	GetMarquee/W=$grfName/K $xaxis, $yaxis
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(grfName, ";"),";")
	WAVE waveRef = ImageNameToWaveRef(grfName, imgNameTopGraphStr) // full path of wave
	DFREF currDF = GetDataFolderDFR()
	string stacknameStr = CreateDataObjectName(currDF, NameOfWave(waveRef) + "_PART", 1, 0, 1)
	// Use NameOfWave(waveRef) instead of imgNameTopGraphStr as the ' ' will be replace by _!
	ATH_WaveOp#WavePartition(waveRef, stacknameStr, V_left, V_right, V_top, V_bottom, \
	evenNum = evenNum, square = square)
	WAVE/Z wavePRT = $stacknameStr
	if(!WaveExists(wavePRT)) // Wave does not exists, operation failed.
		return 1
	endif
	//CopyScales/P waveRef, wavePRT // Change, keep the original x, y offsets
	return 0
End

/// @function GetMarqueeToIndex
/// @brief Convert the active graph marquee to wave-index bounds.
/// @param grfName (optional) Name of the graph window.
/// @param axisX (optional) Name of the horizontal graph axis.
/// @param axisY (optional) Name of the vertical graph axis.
/// @returns A validity flag followed by the left, right, top, and bottom wave-index bounds.
static Function [variable flag, variable leftR, variable rightR, variable topR, variable bottomR] GetMarqueeToIndex([string grfName, string axisX, string axisY])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	axisX = SelectString(ParamIsDefault(axisX) ? 0: 1,"left", axisX)
	axisY = SelectString(ParamIsDefault(axisY) ? 0: 1,"top", axisY)
	variable errCode
	
	WAVE wRef = ATH_Graph#TopImageToWaveRef(grfName=grfName)
	GetMarquee/W=$grfName $axisX, $axisY; errCode = GetRTError(1);
	flag = V_flag
	if(errCode)
		print GetErrMessage(errCode)
		return [flag, -1, -1, -1, -1]
	endif
	leftR = ScaleToIndex(wRef, V_left, 0)
	rightR = ScaleToIndex(wRef, V_right, 0)
	topR = ScaleToIndex(wRef, V_top, 1)
	bottomR = ScaleToIndex(wRef, V_bottom, 1)
	return [flag, leftR, rightR, topR, bottomR]
End

/// @function GetMarqueeWaveStats
/// @brief Return marquee wave stats.
/// @details
/// Wavestats for a marquee region in a 2D wave. In case of a 3D wave the stats are calculated for all
/// layers.
/// @returns The marquee wave stats.
static Function GetMarqueeWaveStats()
	/// Wavestats for a marquee region in a 2D wave. In case of a 3D wave the stats
	/// are calculated for all layers.
	GetMarquee/Z
	variable plane, flag, left, right, top, bottom
	string imgNameTopGraphStr = StringFromList(0, ImageNameList("", ";"),";"), msg, cmd
	WAVE wRef = ImageNameToWaveRef("", imgNameTopGraphStr) // full path of wave
	string infoStr = ImageInfo(WinName(0, 1, 1), imgNameTopGraphStr, 0)
	plane = NumberByKey("plane", infoStr, "=")	
	[flag, left, right, top, bottom] = GetMarqueeToIndex()
	msg = "\n##--------------------------------------------------##\n"
	msg += "Statistics of " + GetWavesDataFolder(wRef, 2) + "\n"
	msg += "Marquee: left = "+num2str(IndexToScale(wRef, left, 0)) + "; "
	msg += "right = "+num2str(IndexToScale(wRef, right, 0)) + "; "
	msg += "top = "+num2str(IndexToScale(wRef, top, 1)) + "; "
	msg += "botttom = "+num2str(IndexToScale(wRef, bottom, 1)) + "; "
	if(WaveDims(wRef)==3)
		msg += "plane = " + num2str(plane) + "\n"
	endif	
	if(WaveDims(wRef) == 2 || WaveDims(wRef)==3)
		print msg
		WaveStats/RMD=[left, right][top, bottom][plane] wRef
		print "%%--------------------------------------------------%%"
	else
		return -1
		//TODO: Make it work with traces. You need TraceNameToWaveRef
	endif
	return 0
End

/// @function CheckActiveAxis
/// @brief Check active axis.
/// @param graphname Name of the graph window.
/// @param axis Name of the graph axis.
/// @returns One when the requested condition or operation succeeds; otherwise zero.
static Function CheckActiveAxis(string graphname, string axis)
	/// If axis is present, return 1 otherwise 0
	/// graphnname = "" we refer to the top window
	if (strlen(AxisInfo(graphname, axis)))
		return 1
	else 
		return 0
	endif
End

/// @function SaveROICoordinatesToDatabase
/// @brief Save ROI coordinates selected with the graph marquee.
/// @details
/// Save ROI to database and draw it on image's UserFront. The following three function let you select an
/// area on a 2d/3d wave and return the coordinates.
/// @param rect (optional) Rectangle coordinates receiving or defining the selected region.
/// @returns Zero after completing the operation.
static Function SaveROICoordinatesToDatabase([variable rect])
	// Save ROI to database and draw it on image's UserFront
	rect = ParamIsDefault(rect) ? 0: rect
	string dfrStr = "root:Packages:ATH_DataFolder:SavedROI"
	DFREF dfr = ATH_DFR#CreateDataFolderGetDFREF(dfrStr)
	GetMarquee/K left, top
	variable/G dfr:gATH_Sleft = V_left
	variable/G dfr:gATH_Sright = V_right
	variable/G dfr:gATH_Stop = V_top
	variable/G dfr:gATH_Sbottom = V_bottom
	variable/G dfr:gATH_SrectQ = rect
	SetDrawLayer UserFront // ImageGenerateROIMask needs ProgFront layer
	SetDrawEnv linefgc = (65535,0,0), fillpat = 0, linethick = 1, dash= 2, xcoord = top, ycoord = left
	if(rect)
		DrawRect V_left, V_top, V_right, V_bottom
	else
		DrawOval V_left, V_top, V_right, V_bottom	
	endif
	return 0
End

// The following three function let you select an area on a 2d/3d wave and return the coordinates.
/// @function UserGetMarqueePositions
/// @brief Pause for the user to define a graph marquee.
/// @param s Input/output structure containing graph, axis, and marquee settings.
/// @returns The left, right, top, and bottom graph coordinates selected by the user.
static Function [variable leftR, variable rightR, variable topR, variable bottomR] UserGetMarqueePositions(STRUCT sUserMarqueePositions &s)
	//
	string winNameStr = WinName(0, 1, 1)	
	DoWindow/F $winNameStr			// Bring graph to front
	if (V_Flag == 0)					// Verify that graph exists
		Abort "WM_UserSetMarquee: No image in top window."
	endif
	string structStr
	string panelNameStr = UniqueName("PauseforCursor", 9, 0)
	NewPanel/N=$panelNameStr/K=2/W=(139,341,382,450) as "Set marquee on image"
	AutoPositionWindow/E/M=1/R=$winNameStr			// Put panel near the graph
	
	StructPut /S s, structStr
	DrawText 15,20,"Draw marquee and press continue..."
	DrawText 15,35,"Can also use a marquee to zoom-in"
	Button buttonContinue, win=$panelNameStr, pos={80,50},size={92,20}, title="Continue", proc=ATH_Marquee#UserSetMarquee_ContButtonProc 
	Button buttonCancel, win=$panelNameStr, pos={80,80},size={92,20}, title="Cancel", proc=ATH_Marquee#UserSetMarquee_CancelBProc
	SetWindow $winNameStr userdata(sATH_Coords)=structStr 
	SetWindow $winNameStr userdata(sATH_panelNameStr)= panelNameStr
	SetWindow $panelNameStr userdata(sATH_winNameStr) = winNameStr 
	SetWindow $panelNameStr userdata(sATH_panelNameStr) = panelNameStr
	PauseForUser $panelNameStr, $winNameStr
	StructGet/S s, GetUserData(winNameStr, "", "sATH_Coords")
	
	if(s.canceled)
		GetMarquee/W=$winNameStr/K // Kill Marquee
		Abort
	endif
	leftR = s.left
	rightR = s.right
	topR = s.top
	bottomR = s.bottom
	return [leftR, rightR , topR, bottomR]
End

/// @function UserSetMarquee_ContButtonProc
/// @brief Handle the continue button for user set marquee.
/// @details
/// Dispatches the relevant Igor control event and ignores unsupported event codes.
/// @param B_Struct Igor action structure describing the control or window event.
/// @returns Igor callback status; nonzero indicates that the event was handled.
static Function UserSetMarquee_ContButtonProc(STRUCT WMButtonAction &B_Struct): ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			STRUCT sUserMarqueePositions s
			string winNameStr = GetUserData(B_Struct.win, "", "sATH_winNameStr")
			StructGet/S s, GetUserData(winNameStr, "", "sATH_Coords")
			string structStr, xaxis, yaxis
			[xaxis, yaxis] = ATH_Graph#GetAxes(grfName = winNameStr)
			GetMarquee/W=$winNameStr/K $xaxis, $yaxis
			s.left = V_left
			s.right = V_right
			s.top = V_top
			s.bottom = V_bottom
			s.canceled = 0
			StructPut/S s, structStr
			SetWindow $winNameStr userdata(sATH_Coords) = structStr
			KillWindow/Z $GetUserData(B_Struct.win, "", "sATH_panelNameStr")
			break
	endswitch
	return 0
End

/// @function UserSetMarquee_CancelBProc
/// @brief Handle the cancel button for user set marquee.
/// @details
/// End of marquee coordinates.
/// @param B_Struct Igor action structure describing the control or window event.
/// @returns Igor callback status; nonzero indicates that the event was handled.
static Function UserSetMarquee_CancelBProc(STRUCT WMButtonAction &B_Struct) : ButtonControl

	switch(B_Struct.eventCode)	// numeric switch
		case 2:	// "mouse up after mouse down"
			STRUCT sUserMarqueePositions s
			string winNameStr = GetUserData(B_Struct.win, "", "sATH_winNameStr")
			StructGet/S s, GetUserData(winNameStr, "", "sATH_Coords")
			string structStr
			s.left = 0
			s.right = 0
			s.top = 0
			s.bottom = 0
			s.canceled = 1
			StructPut/S s, structStr
			SetWindow $winNameStr userdata(sATH_Coords) = structStr
			KillWindow/Z $GetUserData(B_Struct.win, "", "sATH_panelNameStr")
			break
	endswitch
	return 0
End
// End of marquee coordinates
