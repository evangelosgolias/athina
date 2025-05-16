#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// Routine copied from:
// https://www.wavemetrics.com/forum/general/circular-colorscale
// You can find useful info also here:
//
// https://www.wavemetrics.com/forum/general/viridis-igor-and-other-custom-color-maps
// https://github.com/quantixed/IgorColorTables

Menu "Graph"
	"Make Angle Color Legend"
End
Menu "Panel"
	"Make Angle Color Legend"
End
Menu "Layout"
	"Make Angle Color Legend"
End

Proc MakeAngleColorLegend(colorTableName, repeatColorTable, x0Points, y0Points, radiusPoints, startAngleDegrees, ccw, surroundThicknessPoints, directionsThicknessPoints, arrowOptions)
	String colorTableName= StrVarOrDefault(PackageDFVar("colorTableName"), "SpectrumBlack")
	Variable repeatColorTable = NumVarOrDefault(PackageDFVar("repeatColorTable"), 1) // 0 is no repeat, 1 is repeat once (2 color tables), etc.
	Variable x0Points = NumVarOrDefault(PackageDFVar("x0Points"), NaN) // default is center of window
	Variable y0Points = NumVarOrDefault(PackageDFVar("y0Points"), NaN) // default is center of window
	Variable radiusPoints = NumVarOrDefault(PackageDFVar("radiusPoints"), 36) // default is 0.5 inch
	Variable startAngleDegrees= NumVarOrDefault(PackageDFVar("startAngleDegrees"), 90)
	Variable ccw=NumVarOrDefault(PackageDFVar("ccw"), 1) ? 2 : 1 // 1 = "Clockwise", 2 = "Counter-Clockwise"
	Variable surroundThicknessPoints=NumVarOrDefault(PackageDFVar("surroundThicknessPoints"), 1)
	Variable directionsThicknessPoints= NumVarOrDefault(PackageDFVar("directionsThicknessPoints"), 1)
	Variable arrowOptions= 1+NumVarOrDefault(PackageDFVar("arrowOptions"), 1) // 0 is none, 1 is black arrows, 2 is white arrows, 3 is white arrows with black "outline", 4 is black arrows with white "outline"
	
	Prompt colorTableName, "color table", popup, CTabList()
	Prompt repeatColorTable, "# of color table repeats"
	Prompt x0Points, "x origin (points) or NaN for center"
	Prompt y0Points, "y origin (points) or NaN for center"
	Prompt ccw, "Angle", popup, "Clockwise;Counter-Clockwise;" // 1,2
	Prompt arrowOptions, "arrow options", popup, "None;Black;White;White on Black;Black on White;"

	ccw = ccw == 2						// convert popup item numbers to boolean
	arrowOptions= arrowOptions - 1	// convert popup item numbers to option

	// remember choices for next time
	String/G root:Packages:AngleColorLegend:colorTableName = colorTableName
	Variable/G root:Packages:AngleColorLegend:repeatColorTable = repeatColorTable
	Variable/G root:Packages:AngleColorLegend:x0Points = x0Points
	Variable/G root:Packages:AngleColorLegend:y0Points = y0Points
	Variable/G root:Packages:AngleColorLegend:radiusPoints = radiusPoints
	Variable/G root:Packages:AngleColorLegend:startAngleDegrees = startAngleDegrees
	Variable/G root:Packages:AngleColorLegend:ccw = ccw
	Variable/G root:Packages:AngleColorLegend:surroundThicknessPoints = surroundThicknessPoints
	Variable/G root:Packages:AngleColorLegend:directionsThicknessPoints = directionsThicknessPoints
	Variable/G root:Packages:AngleColorLegend:arrowOptions = arrowOptions

	Variable okay = fMakeAngleColorLegend(colorTableName, repeatColorTable, x0Points, y0Points, radiusPoints, startAngleDegrees, ccw, surroundThicknessPoints, directionsThicknessPoints, arrowOptions)

	if( okay )
		HideTools/A // work around for Igor 8 bug
		ShowTools/A arrow
	endif
End

static Constant kDebugging = 0

Function fMakeAngleColorLegend(colorTableName, repeatColorTable, x0Points, y0Points, radiusPoints, startAngleDegrees, ccw, surroundThicknessPoints, directionsThicknessPoints, arrowOptions)
	String colorTableName
	Variable repeatColorTable		// 0 is no repeats, 1 is one repeat, etc
	Variable x0Points, y0Points, radiusPoints
	Variable startAngleDegrees		// 0, 90, 180, or 270 corresponds to Right, Bottom, Left, or Top. Default is 0 (Right)
	Variable ccw							// 0 for clockwise, else counter-clockwise.
	Variable surroundThicknessPoints
	Variable directionsThicknessPoints		// 0 for no, 1 for yes
	Variable arrowOptions // 0 is none, 1 is black arrows, 2 is white arrows, 3 is white arrows with black "outline", 4 is black arrows with white "outline"


	WAVE ctab = ReplicatedColorTable(colorTableName, repeatColorTable, 360)

if( kDebugging > 1 )
	DemoColorTable(ctab)
	DoWindow/F scratchGraph
	if( V_Flag == 0 )
		Display/N=scratchGraph/K=1
	endif
endif

	String win = ActiveWin() // if "", we don't have a suitable window topmost
	if( strlen(win) == 0 )
		DoAlert 0, "Expected the Active Window to be a graph, panel, or layout."
		return 0
	endif

#if IgorVersion() >= 7
if( kDebugging )
	 // DANGER: Clears Layer currently in use
	GetWindow $win drawLayer
	SetDrawLayer/W=$win/K $S_Value
endif
#endif
	
	GetWindow $win wsize	// screen corners in points
	if( numtype(x0Points) != 0 )
		x0Points = floor((V_Right-V_Left)/2)
	endif
	if( numtype(y0Points) != 0 )
		y0Points = round((V_Bottom-V_Top)/2)
	endif

	SetDrawEnv/W=$win push
	SetDrawEnv/W=$win gstart, gname=AngleColorScale // 	Marks the start of a named group of objects.
	SetDrawEnv/W=$win xcoord=abs, ycoord=abs, linethick= 0, save // absolute coords, no line thickness for wedges

	Variable numWedges = DimSize(ctab,0) // one wedge per color
	Variable deltaRadians = 2 * pi / numWedges 		// radians/wedge, full circle assumed
	Variable angle0 = startAngleDegrees * pi / 180 // radians
	Variable i
	for(i= 0; i<numWedges; i+=1)
		// fill color
		Variable red = ctab[i][0]
		Variable green = ctab[i][1]
		Variable blue = ctab[i][2]
		SetDrawEnv/W=$win fillfgc= (red, green, blue), fillPat=1, save // fillPat=1 = 100% (solid pattern, the default)

		// draw this wedge
		Variable StartAngle = i * deltaRadians
		Variable EndAngle = StartAngle + deltaRadians
		if( ccw )
			StartAngle = -StartAngle
			EndAngle = -EndAngle
		endif
		StartAngle += angle0
		EndAngle += angle0
		// approximate the wedge's arc with n segments
		Variable j, n= ceil(max(1,abs(EndAngle-StartAngle)*(500/pi))) 

		// first point on the outer arc relative to (x0Points, y0Points)
		Variable x0= radiusPoints*cos(StartAngle)
		Variable y0= radiusPoints*sin(StartAngle)

		DrawPoly/W=$win/ABS x0Points,y0Points,1,1,{0,0,x0,y0}		// first and second points
		for(j=1; j<=n; j+=1)
			Variable angle = StartAngle + j * (EndAngle-StartAngle) / n
			x0= radiusPoints*cos(angle)
			y0= radiusPoints*sin(angle)
			DrawPoly/W=$win /A {x0,y0}
		endfor
		DrawPoly/W=$win/A {0,0}
	endfor 

	// draw optional surround
	if( surroundThicknessPoints )
		SetDrawEnv/W=$win linethick= surroundThicknessPoints, linefgc=(0,0,0), fillPat= 0, save // fixed color black, no fill
		Variable left = x0Points - radiusPoints
		Variable right = x0Points + radiusPoints
		Variable top = y0Points - radiusPoints
		Variable bottom = y0Points + radiusPoints
		DrawOval/W=$win left, top, right, bottom
	endif
	
	// draw optional directional arrows
	if( directionsThicknessPoints && arrowOptions )
		Variable arrowRadiusPoints = max(3, radiusPoints * 0.75)

		SetDrawEnv/W=$win push
		SetDrawEnv/W=$win origin = x0Points,y0Points, rotate=mod(startAngleDegrees,90), save

		// horizontal line coordinates
		x0 = - arrowRadiusPoints
		Variable x1 = arrowRadiusPoints
		// vertical line coordinates
		y0 =  - arrowRadiusPoints
		Variable y1 =  arrowRadiusPoints

		SetDrawEnv/W=$win linefgc=(0,0,0), arrow=3, save // arrows at both ends, fixed color black

		// arrowOptions = 0 is none, 1 is black arrows, 2 is white arrows, 3 is white arrows with black "outline", 4 is black arrows with white "outline"
		if( arrowOptions == 3 || arrowOptions == 4 )
			if( arrowOptions == 4 )
				SetDrawEnv/W=$win linefgc=(65535,65535,65535), save // white
			endif
			SetDrawEnv/W=$win linethick= directionsThicknessPoints+1, arrowlen=12, save // black, thicker
			DrawLine/W=$win x0-1, 0, x1+1, 0	// horizontal line
			DrawLine/W=$win 0, y0-1, 0, y1+1	// vertical line
		endif
		SetDrawEnv/W=$win linethick= directionsThicknessPoints, linefgc=(0,0,0), arrowlen=10, save // arrows at both ends, fixed color black
		if( arrowOptions == 2 || arrowOptions == 3 )
			SetDrawEnv/W=$win linefgc=(65535,65535,65535), save // white
		elseif (arrowOptions == 4 )
			SetDrawEnv/W=$win linefgc=(0,0,0), save // black
		endif
		DrawLine/W=$win x0, 0, x1, 0	// horizontal line
		DrawLine/W=$win 0, y0, 0, y1	// vertical line

		SetDrawEnv/W=$win pop
	endif

	SetDrawEnv/W=$win gstop // 	Marks the end of a group of objects.
	SetDrawEnv/W=$win pop

	return 1 // success
End

Function/WAVE ReplicatedColorTable(colorTableName, repeatColorTable, maxRows)
	String colorTableName
	Variable repeatColorTable		// 0 is no repeats, 1 is one repeat, etc
	Variable maxRows

	String savedDataFolder = SetPackageDF()
	ColorTab2Wave $colorTableName
	WAVE ctab=M_Colors
	Variable colorTableRows= DimSize(ctab,0)
	Duplicate/O ctab, replicated
	SetDataFolder savedDataFolder
	
	if( repeatColorTable || (colorTableRows > maxRows) )
		Variable replicatedRows = colorTableRows * (1+repeatColorTable)
		replicatedRows = min(replicatedRows, maxRows)	// avoid creating needlessly complex drawing
		Variable rowsPerRepeat = floor(replicatedRows / (1+repeatColorTable))
		Variable totalRows = rowsPerRepeat*(1+repeatColorTable)
		Redimension/N=(totalRows,-1) replicated
		// Extract rowsPerRepeat from ctab
		Variable i
		for(i=0;i<=repeatColorTable;i+=1)
			Variable firstRow= i*rowsPerRepeat
			replicated[firstRow, firstRow+rowsPerRepeat-1][] = ctab[(p-firstRow) * (colorTableRows-1) / (rowsPerRepeat-1)][q]
		endfor
	endif
	return replicated
End

// This is where the packages's globals are stored.
Function/S PackageDF()
	return "root:Packages:AngleColorLegend"
End

Function/S SetPackageDF()
	String oldDF = GetDataFolder(1)
	SetDataFolder PackageDF()
	return oldDF
End

Function/S PackageDFVar(varName)
	String varName
	
	String df= PackageDF()
	if( !DataFolderExists(df) )
		NewDataFolder/O root:Packages
		NewDataFolder/O $df
	endif
	return df+":"+PossiblyQuoteName(varName)
End

static Function/S ActiveWinInWin(win)
	String win 

	String active=""
	if( strlen(win) )
		Variable type= WinType(win)
		if( type != 0 )
			GetWindow $win activeSW		// Stores the window "path" of currently active subwindow in S_Value. See Subwindow Syntax for details on the window hierarchy.
			Variable activeType= WinType(S_Value)
			if( activeType == 1 || activeType == 3 || activeType == 7 ) 	// window or subwindow, graph, layout, or panel
				active= S_Value
			endif
		endif
	endif
	return active
End	

static Function/S ActiveWin()

	String win= WinName(0,1+4+64,1)	// topmost graph, layout, or panel
	win = ActiveWinInWin(win)		// a graph can be a subwindow in a panel or in another graph
	return win
End

// ----- DEBUGGING

Function DemoColorTable(ctab)
	WAVE ctab

	Variable rows = DimSize(ctab,0)
	Make/O/N=(rows,10) ramp = p
	DoWindow/K DemoColorTableGraph
	NewImage/K=1/N=DemoColorTableGraph ramp
	ModifyImage/W=$S_Name ramp ctab={*,*,ctab,0}
End