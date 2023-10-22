#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma DefaultTab={3,20,4}
#pragma ModuleName=ClosedPath
#pragma version=1.05

#include <axis utilities>

/// The code was posted from Tony Withers (tony) at Igor and it is included here as is.
/// For details you can check the following post at the Igor Exchange forum
/// https://www.wavemetrics.com/code-snippet/create-smooth-closed-path-drawing-objects

menu "GraphPopup", dynamic
	"Draw Closed-Path Wave", /Q, ClosedPath#ClosedPathDialog()
	"Draw Closed-Path Shape", /Q, ClosedPath#ClosedPathDialog(shape=1)
	ClosedPath#ClosedPathActiveMenu("Stop Closed-Path Drawing"), /Q, ClosedPath#StopClosedPath()
end

//menu "TracePopup", dynamic
//	ClosedPath#ClosedPathTraceMenu("Edit Nodes"), /Q, ClosedPath#StartEditFromPopupMenu()
//	"Convert to Poly", /Q, ClosedPath#Wave2Poly($"", $"", "", "")
//	"Draw Closed-Path Wave", /Q, ClosedPath#ClosedPathDialog()
//	"Draw Closed-Path Shape", /Q, ClosedPath#ClosedPathDialog(shape=1)
//	ClosedPath#ClosedPathActiveMenu("Stop Closed-Path Drawing"), /Q, ClosedPath#StopClosedPath()
//end

static function/T ClosedPathTraceMenu(string strMenu)
	if (WinType("") != 1)
		return "" // Igor is rebuilding the menu
	endif
	GetLastUserMenuInfo
	wave/Z w = TraceNameToWaveRef(S_graphName, S_traceName)
	if (WaveExists(w) && GrepString(note(w), "nodes="))
		return strMenu
	endif
	return ""
end

static function/T ClosedPathActiveMenu(string str)
	GetLastUserMenuInfo
	if (WinType(S_graphName) == 1)
		GetWindow $S_graphName hook(hClosedPath)
		return SelectString(strlen(s_value)>0, "", str)
	endif
	return ""
end

static function StopClosedPath()
	GetLastUserMenuInfo
	SetWindow $S_graphName hook(hClosedPath)=$""
	wave/Z/SDFR=getDFR()/WAVE refs
	if (WaveExists(refs) && WaveExists(refs[0]))
		DoAlert 1, "Remove active nodes?"
		if (V_flag == 1)
			RemoveFromGraph/Z/W=$S_graphName $NameOfWave(refs[0])
		endif
	endif
end

static function/DF getDFR()
	DFREF dfr = root:Packages:ClosedPath
	if (DataFolderRefStatus(dfr) != 1)
		return resetDFR()
	endif
	return dfr
end

static function/DF resetDFR()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:ClosedPath
	DFREF dfr=root:Packages:ClosedPath
	return dfr
end
	
static function Wave2Poly(wave/Z wx, wave/Z wy, string hAxis, string vAxis, [string layer, string name])
	
	layer = SelectString(ParamIsDefault(layer), layer, "UserFront")
	name = SelectString(ParamIsDefault(name), name, "")
	
	string newName = "", strNote = ""
	if (WaveExists(wx) == 0 || WaveExists(wy) == 0)
		GetLastUserMenuInfo
		wave/Z wy = TraceNameToWaveRef(S_graphName, S_traceName)
		if (WaveExists(wy) == 0)
			return 0
		endif
		wave/Z wx = XWaveRefFromTrace(S_graphName, S_traceName)
		if (!WaveExists(wy))
			return 0
		endif
		if (!WaveExists(wx))
			newName = NameOfWave(wy) + "_x"
			if (WaveExists($newName))
				DoAlert 1, "overwrite " + newName + "?"
				if (v_flag == 2)
					return 0
				endif
			endif
			Duplicate/O wy $newName/wave=wx
		elseif (WaveRefsEqual(wy, wx))
			DoAlert 0, "Not yet working for parametric traces"
			return 0
		endif
		string strInfo = TraceInfo("", S_traceName, 0)
		hAxis = StringByKey("XAXIS", strInfo)
		vAxis = StringByKey("YAXIS", strInfo)
		
		strNote = note(wy)
		wave/Z nodes = $StringByKey("nodes",strNote,"=")
		variable hasNodes = WaveExists(nodes)
		
		string strHelp
		strHelp = "Select the drawing layer for the shape. "
		if (hasNodes)
			strHelp += " If the trace is removed, further node editing will be disabled. "
			strHelp += " If the trace is not removed it will become transparent and can be right-clicked to edit nodes. "
		endif
		
		variable removeTrace = 1
		Prompt layer, "Layer", Popup, "ProgBack;UserBack;ProgAxes;UserAxes;ProgFront;UserFront;"
		Prompt removeTrace, "Remove trace?", Popup, "No;Yes;"
		DoPrompt/HELP=strHelp "Select drawing layer", layer, removeTrace
		if (v_flag)
			return 0
		endif
		if (removeTrace == 2)
			RemoveFromGraph/Z $S_traceName
		elseif (hasNodes)
			ModifyGraph rgb($S_traceName)=(65535,0,0,0)
		endif
	endif
	
	if (DimSize(wy, 0)<2)
		return 0
	endif
	
	name = SelectString(strlen(name)==0, name, NameOfWave(wy) + "Poly")
	
	DrawAction/L=$layer getgroup=$name, delete
	SetDrawLayer $layer
	SetDrawEnv gstart, gname=$name
	SetDrawEnv xcoord=$hAxis, ycoord=$vAxis
	DrawPoly wx[0], wy[0], 1, 1, wx, wy
	SetDrawEnv gstop, gname=$name
	
	strNote = note(wy)
	if (WaveExists($StringByKey("nodes", strNote, "=")))
		note/K wy, ReplaceStringByKey("layer", strNote, layer, "=")
	endif
	WaveStats/Q/M=1 wy
	return ((V_numNaNs + V_numInfs) == 0)
end

static function ClosedPathDialog([int shape])
	
	shape = ParamIsDefault(shape) ? 0 : shape
	
	string Graph = WinName(0, 1)
	if (strlen(Graph) == 0)
		return 0
	endif
	
	string strBaseName = "spline"
	
	string layer = ""
	string vAxes = HVAxisList("", 0)
	string hAxes = HVAxisList("", 1)
	
	if (ItemsInList(vAxes) == 0 || ItemsInList(hAxes) == 0)
		DoAlert 0, "Graph must have horizontal and vertical axes"
		return 0
	endif
	
	string vAxis = StringFromList(0, vAxes)
	string hAxis = StringFromList(0, hAxes)
		
	Prompt vAxis, "Vertical Axis", Popup, vAxes
	Prompt hAxis, "Horizontal Axis", Popup, hAxes
	if (shape)
		layer = "UserFront"
		Prompt layer, "Layer", Popup, "ProgBack;UserBack;ProgAxes;UserAxes;ProgFront;UserFront;Overlay;"
		DoPrompt/HELP="A polygon drawing object will be created in the selected drawing layer" "Layer", layer, vAxis, hAxis
		if (v_flag)
			return 0
		endif
	elseif (ItemsInList(hAxes)>1 || ItemsInList(vAxes)>1)
		DoPrompt/HELP="The output waves will have units based on the selected axes" "Select Axes", vAxis, hAxis
		if (v_flag)
			return 0
		endif
	endif
	
	GetAxis/Q $vAxis
	if (V_max == V_min)
		return 0
	endif
	GetAxis/Q $hAxis
	if (V_max == V_min)
		return 0
	endif

	int i = 0
	do
		if (exists(strBaseName + num2str(i) + "_nodes") || exists(strBaseName + num2str(i) + "_x") || exists(strBaseName + num2str(i) + "_y"))
			i += 1
		else
			strBaseName = strBaseName + num2str(i)
			break
		endif
	while(1)
	
	StartClosedPath(Graph, layer, vAxis, hAxis, strBaseName, shape)
	return 0
end

static function StartEditFromPopupMenu()
	GetLastUserMenuInfo
	wave/Z wy = TraceNameToWaveRef(S_graphName, S_traceName)
	if (!WaveExists(wy))
		return 0
	endif
	string strInfo = TraceInfo(S_graphName, S_traceName, 0)
	string hAxis = StringByKey("XAXIS", strInfo)
	string vAxis = StringByKey("YAXIS", strInfo)
	
	StartEdit(S_graphName, hAxis, vAxis, wy)
end

// shape = 1 to create a drawing object.
static function StartClosedPath(string Graph, string layer, string vAxis, string hAxis, string name, int shape)
	
	Make/O/N=(0,2) $(name+"_nodes")/wave=nodes
	Make/O/N=(0) $(name+"_x")/wave=wx
	Make/O/N=(0) $(name+"_y")/wave=wy
	note wy "layer="+layer+";name="+name+";wx="+GetWavesDataFolder(wx, 2)+";nodes="+GetWavesDataFolder(nodes, 2)+";"
			
	RemoveFromGraph/Z $NameOfWave(wy)
	PlotOnNamedAxes("", wy, hAxis, vAxis, xwave=wx)
	ModifyGraph/Z mode($NameOfWave(wy))=0
	
	string strNodes = NameOfWave(nodes)
	RemoveFromGraph/Z $strNodes // keep trace on top
	PlotOnNamedAxes("", nodes, hAxis, vAxis)
	ModifyGraph mode($strNodes)=3, marker($strNodes)=8
	if (shape) // make spline transparent (not hidden, because we want to be able to right-click and edit nodes)
		ModifyGraph rgb($NameOfWave(wy))=(65535,0,0,0)
	endif
	
	DFREF dfr = getDFR()
	Make/O/WAVE/N=3 dfr:refs/wave=refs
	refs[0] = nodes
	refs[1] = wx
	refs[2] = wy
	string/G dfr:layer = layer
	variable/G dfr:status = (shape != 0)
	variable/G dfr:pointNum = NaN
	variable/G dfr:mode = 0
	variable/G dfr:success = 1
	
	SetWindow $Graph hook(hClosedPath)=ClosedPath#ClosedPathHook
end

static function StartEdit(string Graph, string hAxis, string vAxis, wave wy)
	string strNote = note(wy)
	wave/Z nodes = $StringByKey("nodes",strNote,"=")
	wave/Z wx = $StringByKey("wx",strNote,"=")
	string layer = StringByKey("layer",strNote,"=")
	
	if (!(WaveExists(nodes) && WaveExists(wx)))
		return 0
	endif
	
	string strNodes = NameOfWave(nodes)
	RemoveFromGraph/Z/W=$Graph $strNodes // keep trace on top
	PlotOnNamedAxes(Graph, nodes, hAxis, vAxis)
	ModifyGraph/W=$Graph mode($strNodes)=3, marker($strNodes)=8
	
	DFREF dfr = getDFR()
	Make/O/WAVE/N=3 dfr:refs/wave=refs
	refs[0] = nodes
	refs[1] = wx
	refs[2] = wy
	string/G dfr:layer = layer
	variable/G dfr:status = 2
	variable/G dfr:pointNum = NaN
	variable/G dfr:mode = 0
	
	SetWindow $Graph hook(hClosedPath)=ClosedPath#ClosedPathHook
end

static function PlotOnNamedAxes(string strGraph, wave w, string hAxis, string vAxis, [wave/Z xwave, int xcol, int ycol])
	
	xcol = ParamIsDefault(xcol) ? 0 : xcol
	ycol = ParamIsDefault(ycol) ? 1 : ycol
	
	string axFlags = "" // we can use a standard axis name even if it's not present on graph
	axFlags += SelectString(cmpstr(hAxis, "top")==0, StringByKey("AXFLAG", AxisInfo("", hAxis)), "/T")
	axFlags += SelectString(cmpstr(vAxis, "right")==0, StringByKey("AXFLAG", AxisInfo("", vAxis)), "/R")
	
	variable flagBits = GrepString(axFlags, "/R") + 2*GrepString(axFlags, "/T")
	// set bit 0 for right axis, bit 1 for top axis
		
	switch (flagBits)
		case 0:	// bottom and left axes
			if (DimSize(w, 1) > 1)
				if (WaveExists(xwave))
					if (DimSize(xwave, 1) > 1)
						AppendToGraph/W=$strGraph/B=$hAxis/L=$vAxis w[][ycol] vs xwave[][xcol]
					else
						AppendToGraph/W=$strGraph/B=$hAxis/L=$vAxis w[][ycol] vs xwave
					endif
				else
					AppendToGraph/W=$strGraph/B=$hAxis/L=$vAxis w[][ycol] vs w[][xcol]
				endif
			elseif (WaveExists(xwave))
				AppendToGraph/W=$strGraph/B=$hAxis/L=$vAxis w vs xwave
			else
				AppendToGraph/W=$strGraph/B=$hAxis/L=$vAxis w
			endif
			break
		case 1: // bottom and right axes
			if (DimSize(w, 1) > 1)
				if (WaveExists(xwave))
					if (DimSize(xwave, 1) > 1)
						AppendToGraph/W=$strGraph/B=$hAxis/R=$vAxis w[][ycol] vs xwave[][xcol]
					else
						AppendToGraph/W=$strGraph/B=$hAxis/R=$vAxis w[][ycol] vs xwave
					endif
				else
					AppendToGraph/W=$strGraph/B=$hAxis/R=$vAxis w[][ycol] vs w[][xcol]
				endif
			elseif (WaveExists(xwave))
				AppendToGraph/W=$strGraph/B=$hAxis/R=$vAxis w vs xwave
			else
				AppendToGraph/W=$strGraph/B=$hAxis/R=$vAxis w
			endif
			break
		case 2: // top and left axes
			if (DimSize(w, 1) > 1)
				if (WaveExists(xwave))
					if (DimSize(xwave, 1) > 1)
						AppendToGraph/W=$strGraph/T=$hAxis/L=$vAxis w[][ycol] vs xwave[][xcol]
					else
						AppendToGraph/W=$strGraph/T=$hAxis/L=$vAxis w[][ycol] vs xwave
					endif
				else
					AppendToGraph/W=$strGraph/T=$hAxis/L=$vAxis w[][ycol] vs w[][xcol]
				endif
			elseif (WaveExists(xwave))
				AppendToGraph/W=$strGraph/T=$hAxis/L=$vAxis w vs xwave
			else
				AppendToGraph/W=$strGraph/T=$hAxis/L=$vAxis w
			endif
			break
		case 3: // top and right axes
			if (DimSize(w, 1) > 1)
				if (WaveExists(xwave))
					if (DimSize(xwave, 1) > 1)
						AppendToGraph/W=$strGraph/T=$hAxis/R=$vAxis w[][ycol] vs xwave[][xcol]
					else
						AppendToGraph/W=$strGraph/T=$hAxis/R=$vAxis w[][ycol] vs xwave
					endif
				else
					AppendToGraph/W=$strGraph/T=$hAxis/R=$vAxis w[][ycol] vs w[][xcol]
				endif
			elseif (WaveExists(xwave))
				AppendToGraph/W=$strGraph/T=$hAxis/R=$vAxis w vs xwave
			else
				AppendToGraph/W=$strGraph/T=$hAxis/R=$vAxis w
			endif
			break
	endswitch
end

// corrects for aspect ratio of graph area and relative scale of axes.
static function AspectRatio(string strGraph, string hAxis, string vAxis)
	GetAxis/W=$strGraph/Q $hAxis
	variable horizontalAx = V_max - V_min
	
	string strInfo = AxisInfo(strGraph, hAxis)
	if( NumberByKey("log(x)",strInfo,"="))
		horizontalAx = log(V_max) - log(V_min)
	endif
	
	GetAxis/W=$strGraph/Q $vAxis
	variable verticalAx = V_max - V_min
		
	strInfo = AxisInfo(strGraph, vAxis)
	if( NumberByKey("log(x)",strInfo,"="))
		verticalAx = log(V_max) - log(V_min)
	endif
		
	GetWindow $strGraph psize
	return abs(horizontalAx/verticalAx) / abs((V_left - V_right)/(V_top - V_bottom))
end

static function ClosedPathHook(STRUCT WMWinHookStruct &s)
	
	// we will use cursor codes to define the mode
	variable Insert = 18 // insert node
	variable Move = 21   // move node
	variable Zap = 19    // delete node
	variable CloseLoop = 33
	variable Idle = 0
	
	// status definitions
	variable wavedraw = 0
	variable polydraw = 1
	variable editnodes = 2
	
	DFREF dfr = getDFR()
	
	wave/wave refs = dfr:refs
	if (WaveExists(refs) == 0)
		SetWindow $s.winName hook(hClosedPath)=$""
		return 0
	endif
	NVAR status = dfr:status
	NVAR mode = dfr:mode
	NVAR pointNum = dfr:pointNum
	NVAR polysuccess = dfr:success
	SVAR layer = dfr:layer // when layer is set there is a drawing object associated with the nodes
	
	wave/Z nodes = refs[0]
	wave/Z wx = refs[1]
	wave/Z wy = refs[2]
	
	if (!(WaveExists(nodes) && WaveExists(wy) && WaveExists(wx)))
		SetWindow $s.winName hook(hClosedPath)=$""
		return 0
	endif
	
	string strNodes = NameOfWave(nodes)
	string strTrace = NameOfWave(wy)
	string strObjName = StringByKey("name", note(wy), "=") // name for drawing object
	
	string strInfo = TraceInfo(s.winName, strNodes, 0)
	string hAxis = StringByKey("XAXIS", strInfo)
	string vAxis = StringByKey("YAXIS", strInfo)
	
	strInfo = AxisInfo(s.winName, hAxis)
	int logx = NumberByKey("log(x)",strInfo,"=")
	strInfo = AxisInfo(s.winName, vAxis)
	int logy = NumberByKey("log(x)",strInfo,"=")
		
	switch(s.eventCode)
		case 4: // mousemoved
			if (s.eventmod & 8) // command key
				mode = Zap // delete node
				s.cursorCode = Zap
			elseif (mode == Move) // move node
				s.cursorCode = Move
			else // zap mode will be decided based on cursor position and status
				mode = Idle
				pointNum = NaN
			endif
			
			if (mode == Move) // move node and update spine
				nodes[pointNum][] = {{AxisValFromPixel(s.winName, hAxis, s.mouseloc.h)},{AxisValFromPixel(s.winName, vAxis, s.mouseloc.v)}}
				CatmullRomSpline(nodes, wx, wy, closed=(status==editnodes), aspect=AspectRatio(s.winName, hAxis, vAxis), logx=logx, logy=logy)
				// redraw poly if we move the anchor point
				if (pointnum==0 && strlen(layer))
					Wave2Poly(wx, wy, hAxis, vAxis, layer=layer, name=strObjName)
				endif
			else
				pointNum = NodeUnderCursor(s, nodes)
				
				if (mode != Zap)
					if (numtype(pointNum) == 0)
						if (status == editnodes || pointnum>0 || DimSize(nodes, 0)<=2)
							s.cursorCode = Move // cursor indicates that node can be moved
							mode = Idle // don't enter move mode until mousedown
						elseif (DimSize(nodes, 0) > 2) // ensure that we enclose a finite volume
							s.cursorCode = CloseLoop // cursor indicates that loop can be closed
							mode = CloseLoop
						endif
					else
						pointNum = SegmentUnderCursor(s, wy)
						if (numtype(pointNum) == 0) // cursor over segment
							mode = Insert
						elseif (status != editnodes && MouseInPlotFrame(s, hAxis, vAxis))
							pointNum = DimSize(nodes, 0)
							mode = Insert
						endif

						if (mode == Insert) // in position to insert a point
							mode = Insert
							s.cursorCode = Insert
						endif
					endif
				endif
			endif
			break
		case 3: // mousedown
			if (numtype(pointnum)==0 && mode==Idle) // grab node beneath cursor for moving
				mode = Move
			endif
			
			if (mode == Insert) // insert a node
				InsertPoints/M=0 pointnum, 1, nodes
				nodes[pointnum][0] = AxisValFromPixel(s.winName, hAxis, s.mouseloc.h)
				nodes[pointnum][1] = AxisValFromPixel(s.winName, vAxis, s.mouseloc.v)
				// allow the inserted node to be dragged while the mouse button remains down
				mode = Move
				s.cursorCode = Move
			endif
						
			break
		case 5: // mouseup
			if (mode == Zap && numtype(pointNum) == 0) // delete a node
				DeletePoints/M=0 pointNum, 1, nodes
				
				if (pointnum==0 && strlen(layer))
					polysuccess = 0 // trigger an update of the drawing object
				endif
				
				pointNum = NaN
			elseif (mode == CloseLoop) // status changes from 'draw' to 'edit' after closing the loop
				status = editnodes
				s.cursorCode = Move
			else
				// stop adjusting points after clicking elsewhere in window
				if (mode != Move && status == editnodes)
					SetWindow $s.winName hook(hClosedPath)=$""
					RemoveFromGraph/Z/W=$s.winName $strNodes
				endif
				// stop moving nodes after mouseup
				mode = Idle
			endif
			
			CatmullRomSpline(nodes, wx, wy, closed=(status==editnodes), aspect=AspectRatio(s.winName, hAxis, vAxis), logx=logx, logy=logy)
			
			if (polysuccess == 0 || (status==polydraw && DimSize(nodes, 0)>1))
				// draw the poly (the drawing object becomes dependent upon wx & wy waves) and revert to wavedraw status on success
				polysuccess = Wave2Poly(wx, wy, hAxis, vAxis, layer=layer, name=strObjName)
				if (polysuccess && (status==polydraw))
					status = wavedraw
				endif
			endif
			break
		case 6: //resize
			// even though we're using axis coordinates, if the window aspect ratio changes, the path shape will change
			CatmullRomSpline(nodes, wx, wy, closed=(status==editnodes), aspect=AspectRatio(s.winName, hAxis, vAxis), logx=logx, logy=logy)
			break
	endswitch
	
	if (s.cursorCode)
		s.doSetCursor = 1
	endif
	
	return 0
end

static function MouseInPlotFrame(STRUCT WMWinHookStruct &s, string hAxis, string vAxis)
	variable xx = AxisValFromPixel(s.winName, hAxis, s.mouseloc.h)
	variable yy = AxisValFromPixel(s.winName, vAxis, s.mouseloc.v)
	GetAxis/W=$s.winName/Q $hAxis
	variable xmax = max(v_min,v_max)
	variable xmin = min(v_min,v_max)
	GetAxis/W=$s.winName/Q $vAxis
	variable ymax = max(v_min,v_max)
	variable ymin = min(v_min,v_max)
	return (xx == limit(xx, xmin, xmax) && yy == limit(yy, ymin, ymax))
end

static function NodeUnderCursor(STRUCT WMWinHookStruct &s, wave nodes)
	string info = TraceFromPixel(s.mouseloc.h, s.mouseloc.v, "WINDOW:"+s.winName+";DELTAX:4;DELTAY:4;")
	string tname = StringByKey("TRACE", info)
	wave target = TraceNameToWaveRef(s.winName, tname)
	if (WaveRefsEqual(nodes, target))
		return NumberByKey("HITPOINT", info)
	endif
	return NaN
end

static function SegmentUnderCursor(STRUCT WMWinHookStruct &s, wave wy)
	string info = TraceFromPixel(s.mouseloc.h, s.mouseloc.v, "WINDOW:"+s.winName+";DELTAX:4;DELTAY:4;")
	string tname = StringByKey("TRACE", info)
	wave target = TraceNameToWaveRef(s.winName, tname)
	if (WaveRefsEqual(wy, target))
		return ceil(NumberByKey("HITPOINT", info) / 20)
	endif
	return NaN
end

// Create a spline that passes through a series of x-y points,
// optionally looping back to the start point.
// Can be used with ConvexHull to make a loop around a cloud of points.
static function CatmullRomSpline(nodes, wx, wy, [segPoints, alpha, overwrite, closed, name, aspect, logx, logy])
	wave nodes
	wave/Z/D wx, wy
	variable segPoints, alpha
	int overwrite, closed
	string name
	variable aspect, logx, logy
	
	segPoints = ParamIsDefault(segPoints) ? 20 : segPoints
	alpha = ParamIsDefault(alpha) ? 0.5 : alpha
	overwrite = ParamIsDefault(overwrite) ? 0 : overwrite
	closed = ParamIsDefault(closed) ? 0 : closed
	name = SelectString(ParamIsDefault(name), name, NameOfWave(nodes)+"_CR")
	
	logx = ParamIsDefault(logx) ? 0 : logx
	logy = ParamIsDefault(logy) ? 0 : logy
	variable small = 1e-30
		
	variable np = DimSize(nodes, 0)
	
	if (!(WaveExists(wy) && WaveExists(wx)))
		wave/Z/D wx = $name+"_x"
		wave/Z/D wy = $name+"_y"
		if (WaveExists(wx) || WaveExists(wy))
			if (!overwrite)
				DoAlert 1, "overwrite existing wave?"
				if (V_Flag==2)
					return 0
				endif
			endif
			Redimension/N=(0)/D wx, wy
		else
			Make/D/O/N=(0) $name+"_x" /WAVE=wx
			Make/D/O/N=(0) $name+"_y" /WAVE=wy
		endif
	else
		Redimension/N=(0)/D wx, wy
	endif
		
	if (np < 2)
		return 0
	endif
		
	Make/free/N=(np+2,2)/D temp
	
	if (closed)
		// check whether nodes form a closed or open loop
		if (nodes[0][0]!=nodes[np-1][0] || nodes[0][1]!=nodes[np-1][1])
			np += 1
			Redimension/N=(np+2,2) temp
			temp[1,np-1][] = nodes[p-1][q]
			temp[np][] = nodes[0][q]
		else
			temp[1,np][] = nodes[p-1][q]
		endif
		
		// we have made sure the nodes wrap around in points 1 ... np,
		// figure out values for points 0 and np+1.
		temp[0][] = temp[np-1][q]
		temp[np+1][] = temp[2][q]
		
	else // extrapolate beyond first and last node
		temp[1,np][] = nodes[p-1][q]
		temp[0][] = nodes[0][q] - (nodes[1][q] - nodes[0][q])
		temp[np+1][] = nodes[np-1][q] + (nodes[np-1][q] - nodes[np-2][q])
			
		if (logx)
			temp[0][0] = max(small, temp[0][0])
			temp[np+1][0] = max(small, temp[np+1][0])
		endif
		if (logy)
			temp[0][1] = max(small, temp[0][1])
			temp[np+1][1] = max(small, temp[np+1][1])
		endif
		
	endif
		
	if (logx == 1)
		temp[][0] = log(temp[p][0])
	elseif (logx == 2)
		temp[][0] = log(temp[p][0])/log(2)
	endif
	if (logy == 1)
		temp[][1] = log(temp[p][1])
	elseif (logy == 2)
		temp[][1] = log(temp[p][1])/log(2)
	endif
	if (aspect != 1)
		temp[][1] *= aspect
	endif
	
	Make/free/N=(segPoints,2) xy_out
	Make/free/N=(4,2) xy_in
	
	variable i
	for (i=1;i<np;i+=1)
		xy_in[][] = temp[i-1+p][q]
		CatmullRomSegment(xy_in, xy_out, alpha)
		SplitWave/free/OREF=refs xy_out
		Concatenate/NP {refs[0]}, wx
		Concatenate/NP {refs[1]}, wy
	endfor

	wx[numpnts(wx)]={temp[np][0]}
	wy[numpnts(wy)]={temp[np][1]}
	
	if (aspect != 1)
		wy /= aspect
	endif
	if (logx == 1)
		wx = 10^wx
	elseif (logx == 2)
		wx = 2^wx
	endif
	if (logy == 1)
		wy = 10^wy
	elseif (logy == 2)
		wy = 2^wy
	endif
end

static function CatmullRomSegment(wave xy_in, wave xy_out, variable alpha)
	// xy_in has x and y values of four control points
	// alpha=0 for standard (uniform) Catmull-Rom spline
	// alpha=0.5 for centripetal Catmull-Rom spline
	// alpha=1 for chordal Catmull-Rom spline
	
	int nPoints = DimSize(xy_out, 0)
	Make/D/free/N=4 T4 = 0
	T4[1,3] = sqrt((xy_in[p][0]-xy_in[p-1][0])^2 + (xy_in[p][1]-xy_in[p-1][1])^2)^alpha + T4[p-1]
	Make/D/free/N=(nPoints, 3, 2) wA
	Make/D/free/N=(nPoints, 2, 2) wB
	Make/D/free/N=(nPoints) w_t
		
	w_t = T4[1] + p/(nPoints)*(T4[2]-T4[1])
	wA = (T4[q+1]-w_t[p]) / (T4[q+1]-T4[q]) * xy_in[q][r] + (w_t[p]-T4[q]) / (T4[q+1]-T4[q]) * xy_in[q+1][r]
	wB = (T4[q+2]-w_t[p]) / (T4[q+2]-T4[q]) * wA[p][q][r] + (w_t[p]-T4[q]) / (T4[q+2]-T4[q]) * wA[p][q+1][r]
	xy_out = (T4[2]-w_t[p])/(T4[2]-T4[1])*wB[p][0][q] + (w_t[p]-T4[1])/(T4[2]-T4[1])*wB[p][1][q]
end