#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma IgorVersion=8
#pragma version=2.10
#pragma ModuleName=MarqueePeaks

/// The code was posted from Tony Withers (tony) at Igor and it is included here as is.
/// For details you can check the following post at the Igor Exchange forum
/// https://www.wavemetrics.com/node/21526


// --------------------- Project Updater header ----------------------
// If you have installed or updated this project using the IgorExchange
// Projects Installer (http: www.igorexchange.com/project/Updater) you
// can be notified when new versions are released.
static constant kProjectID=21526 // the project node on IgorExchange
static strconstant ksShortTitle="Marquee Peaks" // the project short title on IgorExchange

// Most of the Marquee Peak functions use the graph marquee to select a
// subrange of a plotted trace. They're used to determine peak heights,
// areas, centroids (centres of mass), and full-width at half-maximum
// (FWHM). Right click within the graph marquee to select which of these
// you want to calculate. When a trace is selected from the list of
// traces that pass though the marquee, the results of the calculation
// are written to history and shown in a tag on the graph. Select the
// 'clear' submenu to remove tags from the plot.

// Spectra must be baseline-free for these functions to be useful!
// Fit-derived uncertainties are not really meaningful.

// Peak height: fits a third order polynomial through the selected range,
// and then tries to find the peak by looking for the first zero-gradient
// within that selected range. For this to work nicely you should select
// a narrow region around the peak. I used a polynomial so that it should
// work with asymmetric peaks. Also gives peak position.

// Area and Centroid: integrates the data over the selected range and 
// looks for the position of area/2 in the integral wave. Also gives area
// and centre of mass.

// Peak fit: Selects the best fit from Gaussian, Lorentzian and Voigt 
// over the selected x-range. Gives peak height, FWHM, position and peak 
// area for the best fit.

// Doublet Peak: Attempts to fit a pair of peaks to a doublet and derives
// peak position, height, FWHM and area parameters. Works best if the 
// peaks are positioned at 1/4 and 3/4 of the selected x-range. Selects 
// the best fit from attempts to fit a pair of Lorentzian, Gaussian and 
// Voigt peaks.

// Includes options to do all-in-one determinations for all of the traces
// on the plot. The results of all-in-one calculation are presented in a
// table. The waves displayed in the table are located in the package
// folder. It's up to the user to copy data into a more useful location.

// This file also has some functions for normalizing spectra by peak
// height, peak area or total area. To normalize by total area or
// wavemax, use the trace and all traces menus (right click or
// shift-right click on a trace).

// 'Print Waves in Marquee' prints the names of marquee traces in the
// history.

// Settings can be configured thorough the Analysis - Packages - Marquee
// Peaks Settings... menu. The traces and tags that Marquee Peaks adds to
// a graph window are removed either on the next mouseup, or when another
// Marquee Peak operation is selected, depending on the option selected.

// Note: for Voigt fits, the approximate peak FWHM is used as a fit
// coefficient. The fit function uses the accurate VoigtPeak function.
// This method allows some kind of uncertainty for peak FWHM to be
// derived from curve fitting. For Gaussian and Lorentzian peaks where 
// area is not a fit coeffient, no uncertainty is given for peak area.

// https://www.wavemetrics.com/user/tony

// edit here to exclude traces from the marquee menus
static strconstant ksExclude = "fit_*;MQP_*;"

#define normaliseTrace
#define MQnormalise

//#define developer

static strconstant ksPackageName = "MarqueePeaks"
static strconstant ksPrefsFileName = "MarqueePeaks.bin"
static constant kPrefsVersion = 101

static structure PackagePrefs
	uint32 version
	uint32 options
	float normTo
	char reserved[128 - 12]
endstructure

// set prefs structure to default values
// prefs.options bit 0: tags; bit 1: persistent tags; bit 2: history output; bit 3: overwrite
static function PrefsSetDefaults(STRUCT PackagePrefs &prefs)
	prefs.version = kPrefsVersion
	prefs.options = 6 // persistent tags & history output
	prefs.normTo = 1
	int i
	for(i=0;i<(128-12);i+=1)
		prefs.reserved[i] = 0
	endfor
end

static function LoadPrefs(STRUCT PackagePrefs &prefs)
	LoadPackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
	if (V_flag!=0 || V_bytesRead==0 || prefs.version!=kPrefsVersion)
		PrefsSetDefaults(prefs)
	endif
end

#ifdef normaliseTrace

menu "AllTracesPopup"
	submenu "Normalize All Waves"
		"Total Area", MarqueePeaks#NormaliseAllTraces()
		"Maximum Value", MarqueePeaks#NormaliseAllTraces(peak=1)
		"Revert", MarqueePeaks#NormaliseAllTraces(undo=1)
	end
end

menu "TracePopup", dynamic
	submenu "Normalize"
		MarqueePeaks#filterByTraceType("Total Area", 0), MarqueePeaks#NormaliseTraceByArea("")
		MarqueePeaks#filterByTraceType("Wave Maximum", 0), MarqueePeaks#NormaliseTraceByMax("")
		MarqueePeaks#filterByOption("Revert to Original", 8), MarqueePeaks#DenormalizeTrace("")
	end
end

#endif
// -----------------  marquee menu functions for normalise to peak/area ------------------

#ifdef MQnormalise

menu "GraphMarquee", dynamic
	submenu "Normalise By Selected Area"
		MarqueePeaks#TracesInMarquee(),MarqueePeaks#MarqueeNormaliseTraces()
		"-"
		"All Traces", MarqueePeaks#MarqueeNormaliseTraces()
	end
	submenu "Normalise By Marquee Max"
		MarqueePeaks#TracesInMarquee(), MarqueePeaks#MarqueeNormaliseByMax()
		"-"
		"All Traces", MarqueePeaks#MarqueeNormaliseByMax()
	end
end

#endif

// -----------------  marquee menu functions for peak height and area ------------------

menu "Analysis"
	"Marquee Peaks Settings...", /Q, MarqueePeaks#MakeSettingsPanel()
end

menu "GraphMarquee", dynamic
	submenu "Peak Height (poly fit)"
		MarqueePeaks#TracesInMarquee(), MarqueePeaks#MarqueeFit("height")
		"-"
		"All Traces", MarqueePeaks#MarqueeFit("height")
		"Clear", MarqueePeaks#ResetGraph("")
	end
	submenu "Marquee Area and Centroid"
		MarqueePeaks#TracesInMarquee(), MarqueePeaks#MarqueeFit("centroid")
		"-"
		"All Traces", MarqueePeaks#MarqueeFit("centroid")
		"Clear", MarqueePeaks#ResetGraph("")
	end
	submenu "Fit Peak"
		MarqueePeaks#TracesInMarquee(), MarqueePeaks#MarqueeFit("peak")
		"-"
		"All Traces", MarqueePeaks#MarqueeFit("peak")
		"Clear", MarqueePeaks#ResetGraph("")
	end
	submenu "Fit Doublet"
		MarqueePeaks#TracesInMarquee(), MarqueePeaks#MarqueeFit("doublet")
		"-"
		"All Traces", MarqueePeaks#MarqueeFit("doublet")
		"Clear", MarqueePeaks#ResetGraph("")
	end
	"Print Waves In Marquee", Print MarqueePeaks#TracesInMarquee(exclude="")
end

static function /S filterByTraceType(string str, int type)
	if (WinType("")!=1)
		return "" // don't do anything if Igor is just rebuilding the menu
	endif
	GetLastUserMenuInfo
	if (WinType(S_graphName) == 1)
		return SelectString (NumberByKey("TYPE", TraceInfo(S_graphName, S_traceName,0))==type, "", str)
	endif
	return ""
end

static function /S filterByOption(string str, int value)
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	return SelectString(prefs.options & value, "", filterByTraceType(str, 0))
end

STRUCT PackagePrefs prefs
	LoadPrefs(prefs)

static function MakeSettingsPanel()
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	KillWindow /Z MarqueePeaksPrefsPanel
	GetMouse
	string strTitle = ""
	sprintf strTitle, "Marquee Peaks [%0.2f]", ProcedureVersion("")
	NewPanel /K=1/N=MarqueePeaksPrefsPanel/W=(V_left,V_top,V_Left+220,V_top+250) as strTitle
	ModifyPanel /W=MarqueePeaksPrefsPanel, fixedSize=1//, noEdit=1
	variable top = 20
	CheckBox checkTags0 win=MarqueePeaksPrefsPanel, pos={10,top}, size={141.00,16.00}, title="No Tags"
	CheckBox checkTags0 win=MarqueePeaksPrefsPanel, fSize=12, value=(prefs.options&3)==0, mode=1
	CheckBox checkTags0 win=MarqueePeaksPrefsPanel, help={"No Tag Output in Graph"}
	CheckBox checkTags0 win=MarqueePeaksPrefsPanel, Proc=MarqueePeaks#CheckFunc
	top += 20
	CheckBox checkTags1 win=MarqueePeaksPrefsPanel, pos={10,top}, size={141.00,16.00}, title="Tags Disappear With Marquee"
	CheckBox checkTags1 win=MarqueePeaksPrefsPanel, fSize=12, value=(prefs.options&3)==1, mode=1
	CheckBox checkTags1 win=MarqueePeaksPrefsPanel, help={"Mouseup Clears all Marquee Peaks Paraphernalia from Graph"}
	CheckBox checkTags1 win=MarqueePeaksPrefsPanel, Proc=MarqueePeaks#CheckFunc
	top += 20
	CheckBox checkTags2 win=MarqueePeaksPrefsPanel, pos={10,top}, size={141.00,16.00}, title="Tags Persist Until Next Action"
	CheckBox checkTags2 win=MarqueePeaksPrefsPanel, fSize=12, value=(prefs.options&3)==2, mode=1
	CheckBox checkTags2 win=MarqueePeaksPrefsPanel, help={"Tags not Cleared Until Next Marquee Peaks Action"}
	CheckBox checkTags2 win=MarqueePeaksPrefsPanel, Proc=MarqueePeaks#CheckFunc
	
	top += 40
	CheckBox checkOverwrite0 win=MarqueePeaksPrefsPanel, pos={10,top}, size={141.00,16.00}, title="Normalize Creates New Wave"
	CheckBox checkOverwrite0 win=MarqueePeaksPrefsPanel, fSize=12, value=(prefs.options&8)==0, mode=1
	CheckBox checkOverwrite0 win=MarqueePeaksPrefsPanel, help={"Output Wave Saved in Same Location as Data Wave"}
	CheckBox checkOverwrite0 win=MarqueePeaksPrefsPanel, Proc=MarqueePeaks#CheckFunc
	top += 20
	CheckBox checkOverwrite1 win=MarqueePeaksPrefsPanel, pos={10,top}, size={141.00,16.00}, title="Normalize Overwrites Original"
	CheckBox checkOverwrite1 win=MarqueePeaksPrefsPanel, fSize=12, value=(prefs.options&8)==8, mode=1
	CheckBox checkOverwrite1 win=MarqueePeaksPrefsPanel, help={"Normalizing Value is Saved in Wavenote"}
	CheckBox checkOverwrite1 win=MarqueePeaksPrefsPanel, Proc=MarqueePeaks#CheckFunc
	top += 20
	SetVariable setvarNormTo win=MarqueePeaksPrefsPanel, pos={10,top}, size={141,16}, title="Normalize to", limits={1e-14,Inf,0}
	SetVariable setvarNormTo win=MarqueePeaksPrefsPanel, value=_NUM:prefs.normTo, focusRing=0, fsize=12
	SetVariable setvarNormTo win=MarqueePeaksPrefsPanel, help={"Set the maximum-value/area for normalized waves"}
	
	top += 40
	CheckBox checkHistory win=MarqueePeaksPrefsPanel, pos={10,top}, size={141.00,16.00}, title="Print Results to History"
	CheckBox checkHistory win=MarqueePeaksPrefsPanel, fSize=12, value=(prefs.options&4)
	CheckBox checkHistory win=MarqueePeaksPrefsPanel, help={"Print Detailed Results of Fitting in History Window"}
	top += 40
	Button ButtonSave win=MarqueePeaksPrefsPanel, pos={15,top}, size={100,22}, title="Save Settings", Proc=MarqueePeaks#PrefsButtonProc
	Button ButtonSave win=MarqueePeaksPrefsPanel, valueColor=(65535,65535,65535),fColor=(0,0,65535)
	Button ButtonCancel win=MarqueePeaksPrefsPanel, pos={134,top}, size={70,22}, title="Cancel", Proc=MarqueePeaks#PrefsButtonProc
	SetWindow MarqueePeaksPrefsPanel, hook(hEnter)=MarqueePeaks#hookPrefsPanel
	PauseForUser MarqueePeaksPrefsPanel
end

// hook makes panel act as if save Button has focus
static function hookPrefsPanel(STRUCT WMWinHookStruct &s)
	if (s.eventCode != 11)
		return 0
	endif
	if (s.keycode==13 || s.keycode==3) // enter or return
		STRUCT WMButtonAction sb
		sb.ctrlName = "ButtonSave"
		sb.eventCode = 2
		PrefsButtonProc(sb)
		return 1
	endif
	return 0
end

static function CheckFunc(STRUCT WMCheckboxAction &s)
	if (s.eventCode != 2)
		return 0
	endif
	// toggle radio checks
	if (GrepString(s.ctrlName, "Tags"))
		CheckBox checkTags0 win=MarqueePeaksPrefsPanel, value=GrepString(s.ctrlName, "0$")
		CheckBox checkTags1 win=MarqueePeaksPrefsPanel, value=GrepString(s.ctrlName, "1$")
		CheckBox checkTags2 win=MarqueePeaksPrefsPanel, value=GrepString(s.ctrlName, "2$")
	elseif (GrepString(s.ctrlName, "Overwrite"))
		CheckBox checkOverwrite0 win=MarqueePeaksPrefsPanel, value=GrepString(s.ctrlName, "0$")
		CheckBox checkOverwrite1 win=MarqueePeaksPrefsPanel, value=GrepString(s.ctrlName, "1$")
	endif
	return 0
end

static function PrefsButtonProc(STRUCT WMButtonAction &s)
	if (s.eventCode != 2)
		return 0
	endif
	if (GrepString(s.ctrlName, "ButtonSave"))
		STRUCT PackagePrefs prefs
		LoadPrefs(prefs)
		prefs.options = 0
		ControlInfo /W=MarqueePeaksPrefsPanel checkTags1
		prefs.options += v_value
		ControlInfo /W=MarqueePeaksPrefsPanel checkTags2
		prefs.options += 2*v_value
		ControlInfo /W=MarqueePeaksPrefsPanel checkHistory
		prefs.options += 4*v_value
		ControlInfo /W=MarqueePeaksPrefsPanel checkOverwrite1
		prefs.options += 8*v_value
		ControlInfo /W=MarqueePeaksPrefsPanel setvarNormTo
		prefs.normTo = v_value
		SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
	endif
	KillWindow /Z MarqueePeaksPrefsPanel
	return 0
end

static function /S TracesInMarquee([string exclude])
	if (ParamIsDefault(exclude))
		exclude = ksExclude
	else
		exclude = ReplaceString(";;", exclude + ";", ";")
	endif
	GetMarquee /Z
	string outlist = "", inlist = TraceNameList(S_marqueeWin,";",1+4) // excludes hidden traces
	string trace, yAxisName, xAxisName, info
	// min and max values for the whole trace
	variable yMax, yMin, xMin, xMax, xOffset, yOffset, xMult, yMult
	int i, j
	int numTraces = ItemsInList(inlist)
	for(i=0;i<numTraces;i+=1)
		trace = StringFromList(i,inlist)
		// check for waves to ignore
		if (ReverseListMatch(trace, exclude))
			continue
		endif
		wave /Z w = TraceNameToWaveRef(S_marqueeWin, trace)
		info = TraceInfo(S_marqueeWin,trace,0)
		if (NumberByKey("TYPE", info) != 0) // not an XY or waveform trace
			continue
		endif
		[xOffset, yOffset, xMult, yMult] = GetAllOffsetsFromInfoString(info)
		xAxisName = StringByKey("XAXIS", info)
		yAxisName = StringByKey("YAXIS", info)
		GetMarquee /Z $xAxisName, $yAxisName
		Make /free MQx = {v_left, v_right}, MQy = {v_bottom, v_top}
		// deal with reversed axes by sorting
		Sort MQx, MQx; Sort MQy, MQy
		MQx -= xOffset; MQy -= yOffset
		MQx /= (xMult!=0) ? xMult : 1; MQy /= (yMult!=0) ? yMult : 1
		
		// deal with x-y data
		wave /Z w_x = XWaveRefFromTrace(S_marqueeWin, trace)
		if (WaveExists(w_x))
			// be careful not to choke on category plot traces etc.
			if ((WaveType(w_x)==0) || (numpnts(w_x)==0))
				continue
			endif
			int errL = 0, errR = 0
			
			MQx = limit(WaveMin(w_x), MQx, WaveMax(w_x))
			if (MQx[0] == MQx[1])
				continue
			endif
			
			FindLevel /P/Q w_x, MQx[0]
			if (V_flag)
				errL = 1
				FindLevel /P/Q w_x, WaveMin(w_x)
			endif
			MQx[0] = pnt2x(w, V_LevelX)
			// MQx[0] is the wave x value for leftmost (lowest x) point of w in marquee x-range
			// takes into account scaling of w
			FindLevel /P/Q w_x, MQx[1]
			if (V_flag)
				errR = 1
				FindLevel /P/Q w_x, WaveMax(w_x)
			endif
			MQx[1] = pnt2x(w, V_LevelX)
			if (errL && errR)
				// wave is plotted to left or right of marquee
				continue
			endif
		else // w is waveform
			// check for waveform waves plotted left or right of marquee
			xMin = min(leftx(w), pnt2x(w,numpnts(w)-1))
			xMax = max(leftx(w), pnt2x(w,numpnts(w)-1))
			if (xMin>MQx[1] || xMax<MQx[0])
				continue
			endif
		endif
				
		// set yMax and yMin to max and min of points plotted
		// within the x-axis range of marquee
		yMax = WaveMax(w, MQx[0], MQx[1])
		yMin = WaveMin(w, MQx[0], MQx[1])
				
		if (yMin>MQy[1] || yMax<MQy[0])
			// wave is plotted above or below marquee
			continue
		endif
		outlist = AddListItem(StringFromList(i,inlist), outlist)
	endfor
	return outlist
end

// matchList is a list of match strings, wildcards ok.
// returns truth that an expression in matchList matches s
static function ReverseListMatch(string s, string matchList)
	int i
	for(i=ItemsInList(matchList)-1;i>=0;i--)
		if (stringmatch(s, StringFromList(i, matchList)))
			return 1
		endif
	endfor
	return 0
end

// cleans package clutter from graph
static function ResetGraph(string strWin)
	string traceList = TraceNameList(strWin, ";", 1), trace=""
	int i
	for (i=ItemsInList(traceList)-1;i>=0;i--)
		trace = StringFromList(i, traceList)
		wave w = TraceNameToWaveRef(strWin, trace)
		if (DataFolderRefsEqual(GetWavesDataFolderDFR(w), packageFolder()))
			RemoveFromGraph /W=$strWin/Z $trace
			KillWaves /Z w
		endif
	endfor
	Tag /W=$strWin/K/N=MarqueePeakTag
	Tag /W=$strWin/K/N=MarqueePeakTag2
end

static function /DF packageFolder()
	NewDataFolder /O root:Packages
	NewDataFolder /O root:Packages:MarqueePeaks
	return root:Packages:MarqueePeaks
end

static function MarqueeFit(string type)
	GetMarquee /Z
	if (v_flag == 0)
		return 0
	endif
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	int doTag = prefs.options & 3
	
	DFREF dfr = packageFolder()
	string strGraph = S_marqueeWin
	ResetGraph(S_marqueeWin)
	string trace = "", traceList = "", ignored = "", failed = "", strXAxis = ""
	GetLastUserMenuInfo // S_value will be trace name
	traceList = SelectString(cmpstr(S_value, "All Traces")==0, s_value, TraceNameList("",";",1+4))
	int multiTrace = ItemsInList(traceList) > 1, success = 0, numParameters = 0
	string ParameterWaveList=""
	if (multiTrace)
		strswitch (type)
			case "centroid":
				ParameterWaveList = "w_medianX;w_centroid;w_area;"
				break
			case "height":
				ParameterWaveList = "w_height;w_position;"
				break
			case "peak":
				ParameterWaveList = "w_height;w_position;w_FWHM;w_area;"
				break
			case "doublet":
				ParameterWaveList = "w_height1;w_position1;w_FWHM1;w_area1;"
				ParameterWaveList += "w_height2;w_position2;w_FWHM2;w_area2;"
		endswitch
		numParameters = ItemsInList(ParameterWaveList)
		if (createOutputWaves(ParameterWaveList, 0)==0)
			DoAlert 1, "Output waves exist.  Overwrite?"
			if (V_flag == 2)
				if (prefs.options & 4) // output to history
					printf "multi-trace %s determination aborted\r", type
				endif
				return 0
			endif
			createOutputWaves(ParameterWaveList, 1) // overwrite
		endif
	endif
	Make /free/N=2 xRange
	int numTraces = ItemsInList(traceList)
	int i, j
	for(i=0;i<numTraces;i+=1)
		trace = StringFromList(i,traceList)
		if (stringmatch(trace, "fit_*") || stringmatch(trace, "MQP_*")) // ignore fit waves
			ignored += trace + ", "
		else
			wave w = TraceNameToWaveRef("",trace)
			wave /Z w_x = XWaveRefFromTrace("",trace)
			strXAxis = StringByKey("XAXIS", TraceInfo("", trace, 0 ))
			GetMarquee $strXAxis
			xRange = {v_left, v_right}
			if (withinRange(w, w_x, xRange)==0)
				continue
			endif
			strswitch (type)
				case "height" :
					wave wOut = peakHeight(w, w_x, xRange, strGraph, trace, doTag&&(multiTrace==0), prefs.options&4)
					break
				case "centroid" :
					wave wOut = peakCentroid(w, w_x, xRange, strGraph, trace, doTag&&(multiTrace==0), prefs.options&4)
					break
				case "peak" :
					wave wOut = peakFit(w, w_x, xRange, strGraph, trace, doTag&&(multiTrace==0), prefs.options&4)
					break
				case "doublet" :
					wave wOut = peakFitDoublet(w, w_x, xRange, strGraph, trace, doTag&&(multiTrace==0), prefs.options&4)
					break
			endswitch
			if (multiTrace==0) // done
				if(doTag != 1)
					GetMarquee /Z/K
				else
					SetWindow $strGraph hook(MQP) = MarqueePeaks#MarqueeHook
				endif
				return 1
			endif
			
			if(numtype(wOut[0]) != 0)
				failed += trace + ", "
				continue
			endif
			
			wave /T/Z/SDFR=dfr w_name
			w_name[numpnts(w_name)] = {trace}
			for(j=0;j<numParameters;j++)
				wave w1 = dfr:$StringFromList(j, ParameterWaveList)
				w1[numpnts(w1)] = {wOut[j]}
			endfor
						
			if (doTag && GrepString(type, "height|peak|doublet"))
				wave MQP_Fit = dfr:MQP_Fit
				Duplicate /O MQP_Fit dfr:$"MQP_Fit" + NameOfWave(w) /wave=MQP_Fit
				appendToSameAxes(strGraph, trace, MQP_Fit, $"", matchoffset=1, lsize=2)
			endif
		endif
	endfor
	
	if (doTag && GrepString(type, "area|centroid"))
		Make /O/N=2 dfr:MQP_Area /wave=MQP_Area
		SetScale /I x, xRange[0], xRange[1], MQP_Area
		MQP_Area = Inf
		appendToSameAxes(strGraph, trace, MQP_Area, $"", fill=0.1)
		ModifyGraph /Z/W=$strGraph offset(MQP_Area)={0,-1e+25}
	endif
	
	if (prefs.options & 4) // output to history
		if (strlen(ignored))
			printf "Ignoring traces %s\r", RemoveEnding(ignored, ", ")
		endif
		if (strlen(failed))
			printf "Failed fits: %s\r", RemoveEnding(failed, ", ")
		endif
	endif
	
	if (numpnts(w_name))
		int top, left, bottom, right
		string recreation = WinRecreation("MarqueePeakTable", 0)
		if (strlen(recreation))
			sscanf recreation[strsearch(recreation, "/W=(", 0),Inf], "/W=(%g,%g,%g,%g)", left, top, right, bottom
		else
			recreation = WinRecreation(strGraph, 0)
			sscanf recreation[strsearch(recreation, "/W=(", 0),Inf], "/W=(%g,%g,%g,%g)", left, top, right, bottom
			left -= 200; right = left + 400; bottom = top + 250
		endif
		KillWindow /Z MarqueePeakTable
		Edit /N=MarqueePeakTable/K=1/W=(left, top, right, bottom) w_name
		for(i=0;i<numParameters;i++)
			wave w1 = dfr:$StringFromList(i, ParameterWaveList)
			AppendToTable /W=MarqueePeakTable w1
		endfor
	endif
	
	if (doTag != 1)
		GetMarquee /Z/K
	else
		SetWindow $strGraph hook(MQP) = MarqueePeaks#MarqueeHook
	endif
	return 1
end

static function MarqueeHook(STRUCT WMWinHookStruct &s)
	if (s.eventCode == 5)
		ResetGraph(s.WinName)
		SetWindow $s.WinName hook(MQP) = $""
	endif
	return 0
end

// returns 1 on success, 0 when overwrite is required but not set
static function createOutputWaves(string namesList, int overwrite)
	DFREF dfr = packageFolder()
	wave /SDFR=dfr/Z/T w_name
	int i
	string name
	for (i=ItemsInList(namesList)-1;i>=0;i--)
		name = StringFromList(i, namesList)
		if ((overwrite == 0) && (WaveExists(dfr:$name) || WaveExists(w_name)))
			return 0
		endif
		Make /O/N=0 dfr:$name
	endfor
	Make /O/T/N=0 dfr:w_name
	return 1
end

// truth that at least part of w [vs w_x] is within x range specified by 2 point wave 'range'
static function withinRange(wave w, wave /Z w_x, wave range)
	variable wmin, wmax
	wmin = WaveExists(w_x) ? WaveMin(w_x) : min(pnt2x(w, 0), pnt2x(w, numpnts(w)-1))
	wmax = WaveExists(w_x) ? WaveMax(w_x) : max(pnt2x(w, 0), pnt2x(w, numpnts(w)-1))
	return !(wmin>WaveMax(range) || wmax<WaveMin(range))
end

static function /wave peakHeight(wave w, wave /Z w_x, wave xRange, string strGraph, string tracename, int doTag, int doHistory)
	wave pMinMax = getEndPoints(w, w_x, xRange)
	wave xMinMax = getEndX(w, w_x, pMinMax)
	Make /D/free/O/N=4 cw // no need for good initial guesses for poly coefficients
	Make /D/free wOut = {NaN, NaN}
	int sav_debug = DebuggerOff(), n = 4
	try
		CurveFit /Q/NTHR=0/TBOX=0 poly n, kwCWave=cw, w[pMinMax[0],pMinMax[1]] /X=w_x/NWOK; AbortOnRTE
	catch
		variable error = GetRTError(1)
	endtry
	DebuggerOptions debugOnError = sav_debug
	if (error)
		return wOut
	endif
	DFREF dfr = packageFolder()
	Make /O/N=300 dfr:MQP_Fit /Wave=MQP_Fit
	SetScale /I x, xRange[0], xRange[1], MQP_Fit
	MQP_Fit = poly(cw,x)
	if (doTag)
		appendToSameAxes(strGraph, tracename, MQP_Fit, $"", matchoffset=1)
	endif
	// differentiate the poly
	Make /D/free/N=3 wPoly3 = {cw[1],2*cw[2],3*cw[3]}
	FindRoots /P=wPoly3
	wave W_polyRoots = W_polyRoots
	variable x0 = NaN, y0 = -Inf
	int i
	for(i=0;i<numpnts(W_polyRoots);i+=1)
		if (imag(W_polyRoots[i])!=0)
			continue
		endif
		if (real(W_polyRoots[i])>xMinMax[0] && real(W_polyRoots[i])<xMinMax[1])
			// found a root
			if (poly(cw, real(W_polyRoots[i]))>y0)
				x0 = real(W_polyRoots[i])
				y0 = poly(cw, x0)
			endif
		endif
	endfor
	wOut = {y0, x0, cw[0], cw[1], cw[2], cw[3]}
	if (doTag && (numtype(x0)==0))
		string strTag = ""
		sprintf strTag "%s\rheight = %g\rpos = %g", NameOfWave(w), poly(cw, x0), x0
		Tag /A=MB/B=1/C/N=MarqueePeakTag/I=0/L=2/Z=0/X=0/Y=5 MQP_Fit, x0, strTag
	endif
	if (doHistory && (numtype(x0)==0))
		printf "%s: range = (%g,%g), position = %g, height = %g\r", NameOfWave(w), xMinMax[0], xMinMax[1], x0, poly(cw, x0)
	endif
	return wOut
end

//static function /wave peakArea(wave w, wave /Z w_x, wave xRange, string strGraph, string tracename, int doTag, int doHistory)
//	DFREF dfr = packageFolder()
//	wave /Z MQP_AreaX = $""
//	
//	wave pMinMax = getEndPoints(w, w_x, xRange)
//	wave xMinMax = getEndX(w, w_x, pMinMax)
//	
//	if (WaveExists(w_x))
//		Duplicate /O/R=[pMinMax[0],pMinMax[1]] w dfr:MQP_Area /wave=MQP_Area
//		Duplicate /O/R=[pMinMax[0],pMinMax[1]] w_x dfr:MQP_AreaX /wave=MQP_AreaX
//	else
//		Duplicate /O/R=(xMinMax[0],xMinMax[1]) w dfr:MQP_Area /wave=MQP_Area
//	endif
//	Make /D/free wOut = {NaN}
//	wOut = AreaXoptional(MQP_Area,MQP_AreaX,-Inf,Inf)
//	if (doTag)
//		appendToSameAxes(strGraph, tracename, MQP_Area, MQP_AreaX, matchoffset=1, lsize=0, fill=0.1)
//		string strTag
//		sprintf strTag "%s\rArea = %g", NameOfWave(w), wOut[0]
//		WaveStats /M=1/Q MQP_Area
//		Tag /A=MB/B=1/C/N=MarqueePeakTag/I=0/L=2/Z=0/X=0/Y=5 $tracename, V_maxloc, strTag
//	endif
//	if (doHistory && (numtype(wOut[0])==0))
//		printf "%s: range = (%g,%g), area = %g\r", NameOfWave(w), xMinMax[0], xMinMax[1], wOut[0]
//	endif
//	return wOut
//end

static function /wave peakCentroid(wave w, wave /Z w_x, wave xRange, string strGraph, string tracename, int doTag, int doHistory)
	DFREF dfr = packageFolder()
	Make /free/D wOut = {NaN}

	wave pMinMax = getEndPoints(w, w_x, xRange)
	wave xMinMax = getEndX(w, w_x, pMinMax)
	
	if (WaveExists(w_x))
		// figure out marquee horizontal dimensions in terms of x scaling for w
		if (DimDelta(w_x,0)!=DimDelta(w,0) || DimOffset(w_x,0)!=DimOffset(w,0))
			if (doHistory)
				printf "%s: centroid calculation requires same scaling for X and Y waves\r", NameOfWave(w)
			endif
			return wOut
		endif
	endif
	wave /Z MQP_AreaX = $""
	Duplicate /O/R=[pMinMax[0], pMinMax[1]] w dfr:MQP_Area /wave=MQP_Area
	Make /free PeakIntWave
	if (WaveExists(w_x))
		Duplicate /O/R=[pMinMax[0],pMinMax[1]] w_x dfr:MQP_AreaX /wave=MQP_AreaX
		Integrate /METH=1 MQP_Area /D=PeakIntWave/X=MQP_AreaX
	else
		Integrate /METH=1 MQP_Area /D=PeakIntWave
	endif
	PeakIntWave *= sign(PeakIntWave[Inf])
	variable vArea = PeakIntWave[Inf]
	FindLevel /Q PeakIntWave, vArea/2
	if (V_flag)
		return wOut
	endif

	variable medianX = WaveExists(MQP_AreaX) ? MQP_AreaX(V_LevelX) : V_LevelX
	variable centroid
	
	if (WaveExists(w_x))
		Duplicate /free/R=[pMinMax[0], pMinMax[1]] w CoMy
		Duplicate /free/R=[pMinMax[0], pMinMax[1]] w_x CoMx
		centroid = centerOfMassXY(CoMx, CoMy)
	else
		centroid = centerOfMass(w, xMinMax[0], xMinMax[1])
	endif
	
	wOut={medianX, centroid, vArea}
	
	if (doTag)
		string strTag
		appendToSameAxes(strGraph, tracename, MQP_Area, MQP_AreaX, matchoffset=1, lsize=0, fill=0.1)
		sprintf strTag "%s\rmedian X = %g\rcentre of mass = %g\rarea = %g", NameOfWave(w), medianX, centroid, vArea
		Tag /A=MB/B=1/C/N=MarqueePeakTag/I=0/L=2/Z=0/X=0/Y=5 $tracename, V_LevelX, strTag
	endif
	
	if (doHistory && (numtype(wOut[0])==0))
		printf "%s: range = (%g,%g), median X = %g, centre of mass = %g, area = %g\r", NameOfWave(w), xMinMax[0], xMinMax[1], medianX, centroid, vArea
	endif
	
	return wOut
end

#if IgorVersion() < 9
static function centerOfMass(wave w, variable x1, variable x2)
	Duplicate /free/R=(x1,x2) w w_CoM
	w_CoM *= x
	return sum(w_CoM) / sum(w, x1, x2)
end

static function centerOfMassXY(wave w_x, wave w_y)
	Duplicate /free w_y w_CoM
	w_CoM *= w_x
	return sum(w_CoM) / sum(w_y)
end
#endif

static function /wave PeakFit(wave w, wave/Z w_x, wave xRange, string strGraph, string tracename, int doTag, int doHistory)
	DFREF dfr = packageFolder()
	wave pMinMax = getEndPoints(w, w_x, xRange)
	wave xMinMax = getEndX(w, w_x, pMinMax)
	int sav_debug = DebuggerOff()
	string strTag
	variable gChiSq, lChiSq, vChiSq, gError, lError, vError, wg, wl, yMax
		
	Make /D/O/free wOut = {NaN,NaN,NaN}
	WaveStats /Q/R=[pMinMax[0],pMinMax[1]] w
	Make /O/D/free cwg = {v_max, xMinMax[0]+(xMinMax[1]-xMinMax[0])/2, (xMinMax[1]-xMinMax[0])/2}
	// set constraints for Gaussian and Lorentzian fit
	Make /O/free/T T_Constraints = {"K0>0","K0<"+num2str(1.3*V_max),"K1>"+num2str(xMinMax[0]),"K1<"+num2str(xMinMax[1]),"K2>0"}
	
	// first fit a Gaussian
	try
		FuncFit /Q/NTHR=0/TBOX=0 MarqueePeaks#gPeak, kwCWave=cwg, w[pMinMax[0], pMinMax[1]] /X=w_x/NWOK/C=T_Constraints; AbortOnRTE
		wave w_sigma
		Duplicate /O/free w_sigma swg
		gChiSq = v_chiSq
	catch
		gError = GetRTError(1)
	endtry
	
	// now try Lorentzian
	Make /O/D/free cwl = {v_max, xMinMax[0]+(xMinMax[1]-xMinMax[0])/2, (xMinMax[1]-xMinMax[0])/2}
	try
		FuncFit /Q/NTHR=0/TBOX=0 MarqueePeaks#lPeak, kwCWave=cwl, w[pMinMax[0], pMinMax[1]] /X=w_x/NWOK/C=T_Constraints; AbortOnRTE
		wave w_sigma
		Duplicate /O/free w_sigma swl
		lChiSq = v_chiSq
	catch
		lError = GetRTError(1)
	endtry
	
	// and now Voigt
	try
		Make /D/free/O/N=4 cwv
		if (gError == 0)
			cwv = {cwg[0]*cwg[2]*sqrt(Pi/(4*ln(2))), cwg[1], cwg[2], 1}
		else
			cwv = {AreaXoptional(w, w_x, xMinMax[0], xMinMax[1]), xMinMax[0]+(xMinMax[1]-xMinMax[0])/2, (xMinMax[1]-xMinMax[0])/2, 1}
		endif
		Make /free/T/O T_Constraints = {"K0>0","K1>"+num2str(xMinMax[0]),"K1<"+num2str(xMinMax[1]),"K2>0","K3>0"}
		FuncFit /Q/NTHR=0/TBOX=0/M=2 MarqueePeaks#vPeakFWHM, kwCWave=cwv, w[pMinMax[0], pMinMax[1]] /X=w_x/NWOK/C=T_Constraints; AbortOnRTE
		wave w_sigma
		Duplicate /free w_sigma swv
		vChiSq = v_chiSq
	catch
		vError = GetRTError(1)
	endtry
	DebuggerOptions debugOnError = sav_debug // end of fitting
	
	if (vError && lError && gError)
		return wOut
	endif
	
	Make /O/N=300 dfr:MQP_Fit /Wave=MQP_Fit
	SetScale /I x, xRange[0], xRange[1], MQP_Fit
	if (doTag)
		appendToSameAxes(strGraph, tracename, MQP_Fit, $"", matchoffset=1, fill=0.1)
		appendToSameAxes(strGraph, tracename, MQP_Fit, $"", matchoffset=1) // plot a second trace, in front of datawave trace
	endif
	
	variable vArea
	
	if (gError==0 && (lError || gChiSq<lChisq) && (vError || gChiSq<vChisq) )
		MQP_Fit = gPeak(cwg,x)
		
		// area = Amplitude * FWHM / (2 * sqrt(ln(2))) * sqrt(pi)
		vArea = cwg[0] * cwg[2] / (2 * sqrt(ln(2))) * sqrt(pi)
		
		if (doTag)
			sprintf strTag "%s\rpos = %g±%g\rheight = %g±%g\rarea = %g\rFWHM (Gaussian) = %g±%g", NameOfWave(w), cwg[1], swg[1], cwg[0], swg[0], vArea, cwg[2], swg[2]
			Tag /A=MB/B=1/C/N=MarqueePeakTag/I=0/L=2/Z=0/X=0/Y=5 MQP_Fit, cwg[1], strTag
		endif
		if (doHistory)
			printf "%s Gaussian fit: range = (%g,%g), ", NameOfWave(w), xMinMax[0], xMinMax[1]
			printf "position = %g±%g, height = %g±%g, FWHM = %g±%g, area = %g\r", cwg[1], swg[1], cwg[0], swg[0], cwg[2], swg[2], vArea
		endif
		#ifdef developer
		printf "%s MarqueePeaks#gPeak", NameOfWave(w)
		Print cwg
		#endif
		Duplicate/O/free cwg wOut
		wOut[numpnts(wOut)] = {vArea}
	elseif (lError==0 && (gError || lChiSq<gChisq) && (vError || lChiSq<vChisq) )
		MQP_Fit = lPeak(cwl,x)
		
		// area of a Lorentzian in pi * amplitude * FWHM/2
		// using integrate1D with a Lorentzian function matches this
		// a quick area estimate over limited x-range doesn't.
		vArea = pi * cwl[0]*cwl[2]/2
		
		if (doTag)
			sprintf strTag "%s\rpos = %g±%g\rheight = %g±%g\rarea = %g\rFWHM (Lorentzian) = %g±%g", NameOfWave(w), cwl[1], swl[1], cwl[0], swl[0], vArea, cwl[2], swl[2]
			Tag /A=MB/B=1/C/N=MarqueePeakTag/I=0/L=2/Z=0/X=0/Y=5 MQP_Fit, cwl[1], strTag
		endif
		if (doHistory)
			printf "%s Lorentzian fit: range = (%g,%g), ", NameOfWave(w), xMinMax[0], xMinMax[1]
			printf "position = %g±%g, height = %g±%g, FWHM = %g±%g, area = %g\r", cwl[1], swl[1], cwl[0], swl[0], cwl[2], swl[2], vArea
		endif
		#ifdef developer
		printf "%s MarqueePeaks#lPeak", NameOfWave(w)
		Print cwl
		#endif
		Duplicate /O/free cwl wOut
		wOut[numpnts(wOut)] = {vArea}
	elseif (vError==0) // vError should be zero if we arrived here!
		wg = cwv[2] / (0.5346*cwv[3] + sqrt(0.2166*cwv[3]^2 + 1))
		wl = wg * cwv[3]
		yMax = vPeakFWHM(cwv,cwv[1])
		MQP_Fit = vPeakFWHM(cwv,x)
		if (doTag)
			sprintf strTag "%s\rpos = %g±%g\rheight = %g, area = %g±%g\rFWHM (Voigt) = %g±%g", NameOfWave(w), cwv[1], swv[1], yMax, cwv[0], swv[0], cwv[2], swv[2]
			Tag /A=MB/B=1/C/N=MarqueePeakTag/I=0/L=2/Z=0/X=0/Y=5 MQP_Fit, cwv[1], strTag
		endif
		if (doHistory)
			printf "%s Voigt fit: range = (%g,%g), ", NameOfWave(w), xMinMax[0], xMinMax[1]
			printf "position = %g±%g, height = %g, FWHM (Voigt) = %g±%g, Gauss FWHM = %g, Lorentzian FWHM = %g, area = %g±%g\r", cwv[1], swv[1], yMax, cwv[2], swv[2], wg, wl, cwv[0], swv[0]
		endif
		#ifdef developer
		printf "%s MarqueePeaks#vPeakFWHM", NameOfWave(w)
		Print cwv
		#endif
		wOut = {yMax, cwv[1], cwv[2], cwv[0]}
	endif
	return wOut
end

static function /wave PeakFitDoublet(wave w, wave /Z w_x, wave xRange, string strGraph, string tracename, int doTag, int doHistory)
	DFREF dfr = packageFolder()
	wave pMinMax = getEndPoints(w, w_x, xRange)
	wave xMinMax = getEndX(w, w_x, pMinMax)
	int sav_debug = DebuggerOff() // switch this off in case the fit fails
	variable gChiSq, lChiSq, vChiSq, gError, lError, vError, wg1, wl1, y01, wg2, wl2, y02
	WaveStats /Q/R=[pMinMax[0],pMinMax[1]] w
	variable height = v_max/2, FWHM = (xMinMax[1]-xMinMax[0])/4
	Make /D/free cwguess = {height, xMinMax[0]+(xMinMax[1]-xMinMax[0])/4, FWHM, height, xMinMax[0]+(xMinMax[1]-xMinMax[0])*3/4, FWHM}
	Duplicate /free cwguess cwg, cwl, cwv
	Make /N=1/free/D wOut = NaN
	// set constraints for 2 Gaussian and 2 Lorentzian fits
	Make /free/T T_Constraints = {"K0>0","K0<"+num2str(1.3*V_max),"K1>"+num2str(xMinMax[0]),"K1<"+num2str(xMinMax[1]),"K2>0"}
	T_Constraints[numpnts(T_Constraints)] = {"K3>0","K3<"+num2str(1.1*V_max),"K4>"+num2str(xMinMax[0]),"K4<"+num2str(xMinMax[1]),"K5>0"}
	// first fit two Gaussians
	try
		FuncFit /Q/NTHR=0/TBOX=0 MarqueePeaks#TwoGaussiansNoBase, kwCWave=cwg, w[pMinMax[0], pMinMax[1]] /X=w_x/NWOK/C=T_Constraints; AbortOnRTE
	catch
		gError = GetRTError(1)
	endtry
	if (gError==0)
		wave w_sigma = w_sigma
		Duplicate /free w_sigma swg
		gChiSq = V_chisq
	endif
	// now fit two Lorentzians
	try
		FuncFit /Q/NTHR=0/TBOX=0 MarqueePeaks#TwoLorentziansNoBase, kwCWave=cwl, w[pMinMax[0], pMinMax[1]] /X=w_x/NWOK/C=T_Constraints; AbortOnRTE
	catch
		lError = GetRTError(1)
	endtry
	if (lError==0)
		wave w_sigma = w_sigma
		lChiSq = V_chisq
		Duplicate /free w_sigma swl
	endif
	// use Gaussian fit as starting guesses for Voigt fit
	// for the fit function TwoVoigtNoBase we use parameters area, position, gw, lw for each peak
	// for the fit function TwoVoigtNoBaseFWHM we use parameters area, position, FWHM, l/v for each peak
	// uncertainties for these parameters then come directly from w_sigma
	if (gError == 0)
//		cwv = {cwg[0]*cwg[2]*sqrt(Pi/(4*ln(2))), cwg[1], cwg[2]/2, cwg[2]/2, cwg[3]*cwg[5]*sqrt(Pi/(4*ln(2))), cwg[4], cwg[5]/2, cwg[2]/2}
		cwv = {cwg[0]*cwg[2]*sqrt(Pi/(4*ln(2))), cwg[1], cwg[2], 1, cwg[3]*cwg[5]*sqrt(Pi/(4*ln(2))), cwg[4], cwg[5], 1}
	else // if Gaussian fit wasn't successful, derive guesses from initial guess wave
//		cwv = {cwguess[0]*cwguess[2]*sqrt(Pi/(4*ln(2))), cwguess[1], cwguess[2]/2, cwguess[2]/2, cwguess[3]*cwguess[5]*sqrt(Pi/(4*ln(2))), cwguess[4], cwguess[5]/2, cwguess[2]/2}
		cwv = {cwguess[0]*cwguess[2]*sqrt(Pi/(4*ln(2))), cwguess[1], cwguess[2], 1, cwguess[3]*cwguess[5]*sqrt(Pi/(4*ln(2))), cwguess[4], cwguess[5], 1}
	endif
	T_Constraints = {"K0>0","K1>"+num2str(xMinMax[0]),"K1<"+num2str(xMinMax[1]),"K2>0","K3>0"}
	T_Constraints[numpnts(T_Constraints)] = {"K4>0","K5>"+num2str(xMinMax[0]),"K5<"+num2str(xMinMax[1]),"K6>0","K7>0"}
	try
		FuncFit /Q/NTHR=0/TBOX=0/M=2 MarqueePeaks#TwoVoigtNoBaseFWHM, kwCWave=cwv, w[pMinMax[0], pMinMax[1]] /X=w_x/NWOK/C=T_Constraints; AbortOnRTE
	catch
		vError = GetRTError(1)
	endtry
	if (vError == 0)
		wave w_sigma = w_sigma
		Duplicate /free w_sigma swv
		vChiSq = V_chisq
	endif
	DebuggerOptions debugOnError = sav_debug // end of fitting
	
	if (gError && lError && vError)
		return wOut
	endif
	
	Make /O/N=300 dfr:MQP_Fit /Wave=MQP_Fit
	Make /O/N=300 dfr:MQP_Fit1 /Wave=MQP_Fit1, dfr:MQP_Fit2 /Wave=MQP_Fit2
	SetScale /I x, xRange[0], xRange[1], MQP_Fit, MQP_Fit1, MQP_Fit2
	if (doTag)
		appendToSameAxes(strGraph, tracename, MQP_Fit, $"", matchoffset=1, lsize=2)
		appendToSameAxes(strGraph, tracename, MQP_Fit1, $"", matchoffset=1, fill=0.1)
		appendToSameAxes(strGraph, tracename, MQP_Fit2, $"", matchoffset=1, fill=0.1)
	endif
	
	variable vArea1, vArea2
	
	Make /D/free cw1, cw2, sw1, sw2
	string fitType = ""
	// Uncertainties are really just guesses. No way that these errors are normally distributed.
	// choose the best fit
	if (gError==0 && (gChiSq<lChisq || lError) && (gChiSq<vChisq || vError))
		fitType = "Gaussian"
		MQP_Fit = TwoGaussiansNoBase(cwg,x)
		cw1 = {cwg[0],cwg[1],cwg[2]}
		sw1 = {swg[0],swg[1],swg[2]}
		vArea1 = cw1[0] * cw1[2] / (2 * sqrt(ln(2))) * sqrt(pi)
		MQP_Fit1 = gpeak(cw1,x)
		cw2 = {cwg[3],cwg[4],cwg[5]}
		sw2 = {swg[3],swg[4],swg[5]}
		vArea2 = cw2[0] * cw2[2] / (2 * sqrt(ln(2))) * sqrt(pi)
		MQP_Fit2 = gpeak(cw2,x)
		if (doHistory) // output to history
			printf "%s: Fitting Gaussian peaks between %g and %g\r", NameOfWave(w), xMinMax[0], xMinMax[1]
			printf "Peak 1: position = %g±%g, height = %g±%g, FWHM = %g±%g, area = %g\r", cwg[1], swg[1], cwg[0], swg[0], cwg[2], swg[2], vArea1
			printf "Peak 2: position = %g±%g, height = %g±%g, FWHM = %g±%g, area = %g\r", cwg[4], swg[4], cwg[3], swg[3], cwg[5], swg[5], vArea2
		endif
		#ifdef developer
			printf "%s MarqueePeaks#TwoGaussiansNoBase", NameOfWave(w)
			Print cwg
		#endif
	elseif (lError==0 && (lChiSq<gChisq || gError) && (lChiSq<vChisq || vError) )
		fitType = "Lorentzian"
		MQP_Fit = TwoLorentziansNoBase(cwl,x)
		cw1 = {cwl[0],cwl[1],cwl[2]}
		sw1 = {swl[0],swl[1],swl[2]}
		vArea1 =  pi * cw1[0] * cw1[2] / 2
		MQP_Fit1 = lpeak(cw1,x)
		cw2 = {cwl[3],cwl[4],cwl[5]}
		sw2 = {swl[3],swl[4],swl[5]}
		vArea2 =  pi * cw2[0] * cw2[2] / 2
		MQP_Fit2 = lpeak(cw2,x)
		if (doHistory) // output to history
			printf "%s: Fitting Lorentzian peaks between %g and %g\r", NameOfWave(w), xMinMax[0], xMinMax[1]
			printf "Peak 1: position = %g±%g, height = %g±%g, FWHM = %g±%g, area = %g\r", cwl[1], swl[1], cwl[0], swl[0], cwl[2], swl[2], vArea1
			printf "Peak 2: position = %g±%g, height = %g±%g, FWHM = %g±%g, area = %g\r", cwl[4], swl[4], cwl[3], swl[3], cwl[5], swl[5], vArea2
		endif
		#ifdef developer
			printf "%s MarqueePeaks#TwoLorentziansNoBase", NameOfWave(w)
			Print cwl
		#endif
	elseif (vError == 0) // vError ought to be zero if we arrived here!
		fitType = "Voigt"
		MQP_Fit = TwoVoigtNoBaseFWHM(cwv, x)
		cw1 = {cwv[0], cwv[1], cwv[2], cwv[3]}
		sw1 = {swv[0], swv[1], swv[2], swv[3]}
		vArea1 = cw1[0]
		MQP_Fit1 = vpeakFWHM(cw1, x)
		cw2 = {cwv[4], cwv[5], cwv[6], cwv[7]}
		sw2 = {swv[3], swv[4], swv[5], swv[7]}
		vArea2 = cw2[0]
		MQP_Fit2 = vpeakFWHM(cw2, x)
		// convert total width to Gaussian width
		// this comes from multipeak fitting package
		// voigt width: An approximation with an accuracy of 0.02%
		// from Olivero and Longbothum, 1977, JQSRT 17, 233
		wg1 = cw1[2] / (0.5346*cw1[3] + sqrt(0.2166*cw1[3]^2 + 1))
		wl1 = wg1 * cw1[3]
		y01 = vPeakFWHM(cw1, cw1[1])
		wg2 = cw2[2] / (0.5346*cw2[3] + sqrt(0.2166*cw2[3]^2 + 1))
		wl2 = wg2 * cw2[3]
		y02 = vPeakFWHM(cw2, cw2[1])
		
		// sigma wl and sigma wg probably have strong negative covariance.
		// error propagation (assuming the constants in the formula are uncertainty-free) would be interesting...
		if (doHistory) // output to history
			printf "%s: Fitting Voigt peaks between %g and %g\r", NameOfWave(w), xMinMax[0], xMinMax[1]
			printf "Peak 1: position = %g±%g, height = %g, FWHM = %g±%g, Gaussian FWHM = %g, Lorentzian FWHM = %g, area = %g±%g\r", cw1[1], sw1[1], y01, cw1[2], swv[2], wg1, wl1, cw1[0], swv[0]
			printf "Peak 2: position = %g±%g, height = %g, FWHM = %g±%g, Gaussian FWHM = %g, Lorentzian FWHM = %g, area = %g±%g\r", cw2[1], sw2[1], y02, cw2[2], sw2[2], wg2, wl2, cw2[0], sw2[0]
		endif
		#ifdef developer
			printf "%s MarqueePeaks#TwoVoigtNoBaseFWHM", NameOfWave(w)
			Print cwv
		#endif
		// when a shape parameter is used, end up with smaller uncertainty for wg, and (usually) larger propagated uncertainty for wl:
		// cwv[6]*cwv[7]*(sqrt( (swv[6]/cwv[6])^2 + (swv[7]/cwv[7])^2) - 2*mcv[6][7]/(cwv[6]*cwv[7]) )
		// set 1st coefficient to height for consistency with Gaussian and Lorentzian fits
		cw1[0] = y01; sw1[0] = NaN
		cw2[0] = y02; sw2[0] = NaN
	endif
	if (doTag)
		string strTag = ""
		sprintf strTag "%s %s1\rpos = %g±%g\rheight = %g±%g\rFWHM = %g±%g\rarea = %g", NameOfWave(w), fitType, cw1[1], sw1[1], cw1[0], sw1[0], cw1[2], sw1[2], vArea1
		Tag /A=MB/B=1/C/N=MarqueePeakTag/I=0/L=2/Z=0/X=-5/Y=5 MQP_Fit1, cw1[1], strTag
		sprintf strTag "%s %s2\rpos = %g±%g\rheight = %g±%g\rFWHM = %g±%g\rarea = %g", NameOfWave(w), fitType, cw2[1], sw2[1], cw2[0], sw2[0], cw2[2], sw2[2], vArea2
		Tag /A=MB/B=1/C/N=MarqueePeakTag2/I=0/L=2/Z=0/X=5/Y=5 MQP_Fit2, cw2[1], strTag
	endif
	wOut = {cw1[0], cw1[1], cw1[2], vArea1, cw2[0], cw2[1], cw2[2], vArea2}
	return wOut
end

static function DebuggerOff()
	DebuggerOptions
	int sav_debug = V_debugOnError
	DebuggerOptions debugOnError = 0
	return sav_debug
end

static function AreaXoptional(wave  w, wave /Z w_x, variable x1, variable x2)
	variable xmin = min(x1,x2), xmax = max(x1,x2)
	return (WaveExists(w_x)) ? areaXY(w_x, w, xmin, xmax) : area(w, xmin, xmax)
end

static function /WAVE getEndPoints(wave w, wave /Z w_x, wave wXrange)
	Make /free/N=2 pMinMax = {0, numpnts(w)-1}
	if (WaveExists(w_x))
		if (w_x[1] < w_x[0])
			Sort /R wXrange, wXrange
		else
			Sort wXrange, wXrange
		endif
		FindLevel /Q/P w_x, wXrange[0]
		pMinMax[0] = (v_flag==0) ? V_LevelX : pMinMax[0]
		FindLevel /Q/P w_x, wXrange[1]
		pMinMax[1] = (v_flag==0) ? V_LevelX : pMinMax[1]
	else
		pMinMax = x2pnt(w, wXrange)
	endif
	Sort pMinMax, pMinMax
	pMinMax = limit(0, pMinMax, numpnts(w)-1)
	return pMinMax
end

static function /WAVE getEndX(wave w, wave /Z w_x, wave pMinMax)
	Make /free/D/N=2 xRange = WaveExists(w_x) ? w_x[pMinMax] : pnt2x(w, pMinMax)
	Sort xRange, xRange
	return xRange
end

// -------------------  Normalize by area ---------------------

static function MarqueeNormaliseTraces([variable height])
	height = ParamIsDefault(height) ? 0 : height
	string tracenames, strXAxis, strTrace
	GetLastUserMenuInfo // S_value will be trace name
	tracenames = S_value
	if (cmpstr(tracenames, "All Traces")==0)
		tracenames = TraceNameList("",";",1+4)
	endif
	int i = 0, numTraces = ItemsInList(tracenames)
	for(i=0;i<numTraces;i++)
		strTrace = StringFromList(i,tracenames)
		strXAxis = StringByKey("XAXIS", TraceInfo("", strTrace, 0 ))
		GetMarquee /Z $strXAxis
		if (height)
			normaliseTraceByMax(strTrace, x1=v_left, x2=v_right)
		else
			normaliseTraceByArea(strTrace, x1=v_left, x2=v_right)
		endif
	endfor
end

static function normaliseTraceByArea(string trace, [variable x1, variable x2])
	if (strlen(trace)==0)
		GetLastUserMenuInfo
		trace = S_traceName
	endif
	wave /Z w = TraceNameToWaveRef("", trace)
	wave /Z w_x = XWaveRefFromTrace("", trace)
	if (WaveExists(w) == 0)
		return 0
	endif
	if (ParamIsDefault(x1))
		wave w_norm = NormaliseByArea(w, w_x=w_x)
	else
		wave w_norm = NormaliseByArea(w, w_x=w_x, x1=x1, x2=x2)
	endif
	ReplaceWave trace=$trace, w_norm
end

static function /wave NormaliseByArea(wave w, [wave/Z w_x, variable x1, variable x2])
	variable var_area
	if (WaveExists(w_x))
		x1 = ParamIsDefault(x1) ? w_x[0] : x1
		x2 = ParamIsDefault(x2) ? w_x[numpnts(w_x)-1] : x2
		var_area = abs(areaXY(w_x, w, x1, x2))
	else
		x1 = ParamIsDefault(x1) ? leftx(w) : x1
		x2 = ParamIsDefault(x2) ? pnt2x(w, numpnts(w)-1) : x2
		var_area = abs(area(w, x1, x2))
	endif
	
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	if (prefs.options & 8)
		wave w_norm = w
	else
		DFREF dfr = GetWavesDataFolderDFR(w)
		Duplicate /O w dfr:$NameOfWave(w)+"_n" /wave=w_norm
		printf "duplicate /O %s %s\r" GetWavesDataFolder(w, 4), GetWavesDataFolder(w_norm, 4)
	endif
	
	w_norm = w / (var_area/prefs.normTo)
	printf "%s = %s/%g\r" GetWavesDataFolder(w_norm, 4), GetWavesDataFolder(w, 4), var_area
	
	string strNote = note(w_norm)
	variable divisor = prefs.options & 8 ? NumberByKey("Divisor", strNote, ":", "\r") : 1
	divisor = numtype(divisor) != 0 ? 1 : divisor
	divisor *= var_area/prefs.normTo
//	strNote = ReplaceNumberByKey("Normalized", strNote, 1, ":", "\r")
	strNote = ReplaceStringByKey("Normalized, Data Source", strNote, NameOfWave(w), ":", "\r")
	strNote = ReplaceNumberByKey("Divisor", strNote, divisor, ":", "\r")
	note /K w_norm, RemoveEnding(strNote, "\r")

	return w_norm
end

// -------------------  Normalize by peak ---------------------

static function MarqueeNormaliseByMax()
	string tracenames, strXAxis, strTrace
	GetLastUserMenuInfo // S_value will be trace name
	tracenames = S_value
	if (cmpstr(tracenames, "All Traces")==0)
		tracenames = TraceNameList("",";",1+4)
	endif
	int i = 0, numTraces = ItemsInList(tracenames)
	for(i=0;i<numTraces;i++)
		strTrace = StringFromList(i, tracenames)
		strXAxis = StringByKey("XAXIS", TraceInfo("", strTrace, 0 ))
		GetMarquee /Z $strXAxis
		normaliseTraceByMax(strTrace, x1=v_left, x2=v_right)
	endfor
end

static function NormaliseAllTraces([int peak, int undo])
	peak = ParamIsDefault(peak) ? 0 : peak
	undo = ParamIsDefault(undo) ? 0 : undo
	string traceList = TraceNameList("",";",1+4), trace = ""
	int i = 0, numTraces = ItemsInList(traceList)
	for(i=0;i<numTraces;i+=1)
		trace = StringFromList(i, traceList)
		if (undo)
			DenormalizeTrace(trace)
		elseif (peak)
			NormaliseTraceByMax(trace)
		else
			NormaliseTraceByArea(trace)
		endif
	endfor
end

static function NormaliseTraceByMax(string strTrace, [variable x1, variable x2])
	if (strlen(strTrace) == 0)
		GetLastUserMenuInfo
		strTrace = S_traceName
	endif
	wave /Z w = TraceNameToWaveRef("", strTrace)
	wave /Z w_x = XWaveRefFromTrace("", strTrace)
	if (WaveExists(w) == 0)
		return 0
	endif
	if (WaveExists(w_x) && (ParamIsDefault(x1) + ParamIsDefault(x2))==0)
		wave pMinMax = getEndPoints(w, w_x, {x1, x2})
		x1 = pnt2x(w, pMinMax[0])
		x2 = pnt2x(w, pMinMax[1])
	endif
	
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	
	variable maxVal = NaN
	maxVal = (ParamIsDefault(x1)||ParamIsDefault(x2)) ? WaveMax(w) : WaveMax(w, x1, x2)
	
	if (prefs.options & 8)
		wave w_norm = w
	else
		DFREF dfr=GetWavesDataFolderDFR(w)
		Duplicate /O w dfr:$NameOfWave(w)+"_n" /wave=w_norm
		printf "duplicate /O %s %s\r" GetWavesDataFolder(w, 4), GetWavesDataFolder(w_norm, 4)
	endif
	
	w_norm = w / (maxVal/prefs.normTo)
	printf "%s = %s/%g\r" GetWavesDataFolder(w_norm, 4), GetWavesDataFolder(w, 4), maxVal
	
	string strNote = note(w_norm)
	variable divisor = prefs.options & 8 ? NumberByKey("Divisor", strNote, ":", "\r") : 1
	divisor = numtype(divisor) != 0 ? 1 : divisor
	divisor *= maxVal / prefs.normTo
//	strNote = ReplaceNumberByKey("Normalized", strNote, 1, ":", "\r")
	strNote = ReplaceStringByKey("Normalized, Data Source", strNote, NameOfWave(w), ":", "\r")
	strNote = ReplaceNumberByKey("Divisor", strNote, divisor, ":", "\r")
	note /K w_norm, RemoveEnding(strNote, "\r")
	
	// this doesn't complain if replaced with self
	ReplaceWave trace=$strTrace, w_norm
end

static function DenormalizeTrace(string strTrace)
	if (strlen(strTrace) == 0)
		GetLastUserMenuInfo
		strTrace = S_traceName
	endif
	wave /Z w = TraceNameToWaveRef("", strTrace)
	if (WaveExists(w) == 0)
		return 0
	endif
	string strNote = note(w)
	variable divisor = NumberByKey("Divisor", strNote, ":", "\r")
	if (numtype(divisor) != 0)
		DoAlert 0, "No normalization data found in wavenote"
		return 0
	endif
	
	w *= divisor
	strNote = RemoveByKey("Normalized, Data Source", strNote, ":", "\r")
	strNote = RemoveByKey("Divisor", strNote, ":", "\r")
	note /K w, RemoveEnding(strNote, "\r")
	printf "%s *= %g\r" GetWavesDataFolder(w, 4), divisor
	return 1
end


// ----------------------------------------------------------------

// Plots w, optionally vs w_x, on the same axes as the already plotted
// trace 'traceStr'
// AppendToSameAxes(graphStr, traceStr, w, w_x, w_rgb={r,g,b}, matchOffset=1)
// appends w (vs w_x if w_x exists), sets color to (r,g,b) and matches y
// offset of traceStr
// offset = val sets offset. matchOffset takes precedence over offset.
// Default is to choose a color that contrasts with that of traceStr;
// matchRGB = 1 forces color to match, takes precedence over supplied rgb values
// fill = val adds fill to zero with opacity=val and sends trace to back
// unique = 1 removes any other instances of wave w from the graph
// replace = 1 removes tracestr after plotting w
static function AppendToSameAxes(graphStr, traceStr, w, w_x, [w_rgb, matchOffset, offset, matchRGB, fill, lsize, unique, replace])
	string graphStr, traceStr
	wave /Z w, w_x, w_rgb
	variable matchOffset, offset // match y offset, set Y offset
	int matchRGB // match color of already plotted trace
	variable fill // opacity for fill to zero
	variable lsize
	int unique, replace
	
	matchOffset = ParamIsDefault(matchOffset) ? 0 : matchOffset
	offset      = ParamIsDefault(offset)      ? 0 : offset
	matchRGB    = ParamIsDefault(matchRGB)    ? 0 : matchRGB
	fill        = ParamIsDefault(fill)        ? 0 : min(fill, 1)
	lsize       = ParamIsDefault(lsize)       ? 1 : lsize
	unique      = ParamIsDefault(unique)      ? 0 : unique
	replace     = ParamIsDefault(replace)     ? 0 : replace
	
	string s_info = TraceInfo(graphStr, traceStr, 0)
	string s_Xax = StringByKey("XAXIS",s_info)
	string s_Yax = StringByKey("YAXIS",s_info)
	string s_flags = StringByKey("AXISFLAGS",s_info)
	variable flagBits = GrepString(s_flags, "/R") + 2*GrepString(s_flags, "/T")
	
	offset = matchOffset ? GetOffsetFromInfoString(s_info, 1) : offset
	
	// get color of already plotted trace
	variable c0, c1, c2
	sscanf ListMatch(s_info, "rgb(x)=*"), "rgb(x)=(%d,%d,%d", c0, c1, c2
	
	if (matchRGB==0 && ParamIsDefault(w_rgb)) // no color specified
		wave w_rgb = ContrastingColor({c0,c1,c2})
	elseif (matchRGB) // this overides any specified color
		Make /free/O w_rgb = {c0,c1,c2}
	endif
	
	int i, numTraces
	string traces, trace
	if (unique)
		traces = TraceNameList(graphStr,";",1)
		for (i=ItemsInList(traces)-1;i>=0;i-=1)
			trace = StringFromList(i,traces)
			wave /Z ithTraceWave = TraceNameToWaveRef(graphStr, trace)
			if (WaveRefsEqual(ithTraceWave, w))
				RemoveFromGraph /W=$graphStr/Z $trace
			endif
		endfor
	endif
	
	switch (flagBits)
		case 0:
			if (WaveExists(w_x))
				AppendToGraph /W=$graphStr/B=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w vs w_x
			elseif (DimSize(w,1) == 2)
				AppendToGraph /W=$graphStr/B=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w[][1] vs w[][0]
			else
				AppendToGraph /W=$graphStr/B=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w
			endif
			break
		case 1:
			if (WaveExists(w_x))
				AppendToGraph /W=$graphStr/B=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w vs w_x
			elseif (DimSize(w, 1) == 2)
				AppendToGraph /W=$graphStr/B=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w[][1] vs w[][0]
			else
				AppendToGraph /W=$graphStr/B=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w
			endif
			break
		case 2:
			if (WaveExists(w_x))
				AppendToGraph /W=$graphStr/T=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w vs w_x
			elseif (DimSize(w,1) == 2)
				AppendToGraph /W=$graphStr/T=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w[][1] vs w[][0]
			else
				AppendToGraph /W=$graphStr/T=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w
			endif
			break
		case 3:
			if (WaveExists(w_x))
				AppendToGraph /W=$graphStr/T=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w vs w_x
			elseif (DimSize(w, 1) == 2)
				AppendToGraph /W=$graphStr/T=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w[][1] vs w[][0]
			else
				AppendToGraph /W=$graphStr/T=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w
			endif
			break
	endswitch
	
	// figure out trace name, may not be unique.
	string strNewTrace = TraceNameList(graphStr, ";", 1)
	strNewTrace = StringFromList(ItemsInList(strNewTrace)-1, strNewTrace)
	
	ModifyGraph /W=$graphStr offset($strNewTrace)={0,offset}, lsize($strNewTrace)=lsize
	
	if (fill > 0)
		ModifyGraph /W=$graphStr mode($strNewTrace)=7, hbFill($strNewTrace)=2
		ModifyGraph /W=$graphStr usePlusRGB($strNewTrace)=1, plusRGB($strNewTrace)=(w_rgb[0],w_rgb[1],w_rgb[2],fill*65535)
		ModifyGraph /W=$graphStr useNegRGB($strNewTrace)=1, negRGB($strNewTrace)=(w_rgb[0],w_rgb[1],w_rgb[2],fill*65535)
		ReorderTraces /W=$graphStr _back_, {$strNewTrace}
	endif
	
	if (replace)
		RemoveFromGraph /W=$graphStr traceStr
	endif
end

// area, x0, FWHM, L/G
// assumes FWHM = wl * 0.5346 + sqrt( 0.2166 * wl^2 + wg^2)
// this comes from multipeak fitting package
// Voigt width: An approximation with an accuracy of 0.02% from Olivero 
// and Longbothum, 1977, JQSRT 17, 233
function vpeakFWHM(wave w, variable x)
	Make/free w1 = {0, w[0], w[1], w[2]/(0.5346*w[3]+sqrt(0.2166*w[3]^2+1)), w[3]}
	return VoigtPeak(w1, x)
end

// area, x0, gFWHM, lFWHM
function vpeak(wave w, variable x)
	Make/free w1 = {0, w[0], w[1], w[2], w[3]/w[2]}
	return VoigtPeak(w1, x)
end

// amplitude, x0, FWHM
function lpeak(wave w, variable x)
	variable height = w[0], centre = w[1], FWHM = w[2]
	return height * ((FWHM/2)^2) / ( (x-centre)^2 + (FWHM/2)^2 )
end

// gaussian distribution
// f(x) = 1/(sigma * sqrt(2*pi)) * exp(-(x=x0)^2/(2*sigma^2))

// gaussian function
// FWHM = 2*sqrt(2*ln(2)) * sigma
// y = A * exp(-((x-x0)*2*sqrt(ln(2))/FWHM)^2)

// y = A * exp( - (x-x0)^2/(2C^2))
// y = A * exp( - ((x-x0)/(sqrt(2)*C))^2)

// FWHM = 2*sqrt(2*ln(2)) * C
// area = sqrt(2) * A * C * sqrt(pi)

// sqrt(2)*C = FWHM / (2 * sqrt(ln(2)))
// C = FWHM / (2 * sqrt(2) * sqrt(ln(2)))
// area = A * FWHM / (2 * sqrt(ln(2))) * sqrt(pi)

// amplitude, x0, FWHM
function gpeak(wave w, variable x)
	variable height = w[0], centre = w[1], FWHM = w[2]
	return height*exp(-((x-centre)*2*sqrt(ln(2))/FWHM)^2)
end

// amplitude, x0, FWHM, amplitude, x0, FWHM
static function TwoGaussiansNoBase(Wave w, variable x)
	return w[0]*exp(-((x-w[1])*2*sqrt(ln(2))/w[2])^2) + w[3]*exp(-((x-w[4])*2*sqrt(ln(2))/w[5])^2)
end

// amplitude, x0, FWHM, amplitude, x0, FWHM
static function TwoLorentziansNoBase(Wave w, variable x)
	return w[0]*((w[2]/2)^2)/( (x-w[1])^2 + (w[2]/2)^2 ) + w[3]*((w[5]/2)^2)/( (x-w[4])^2 + (w[5]/2)^2 )
end

// area, centre, gFWHM, lFWHM, area, centre, gFWHM, lFWHM
static function TwoVoigtNoBase(Wave w, variable x)
	Make/free w1 = {0, w[0], w[1], w[2], w[3]/w[2]}, w2 = {0, w[4], w[5], w[6], w[7]/w[6]}
	return VoigtPeak(w1, x) + VoigtPeak(w2, x)
end

// area, centre, FWHM, L/V, area, centre, FWHM, L/V
static function TwoVoigtNoBaseFWHM(Wave w, variable x)
	Make/free w1 = {0, w[0], w[1], w[2]/(0.5346*w[3]+sqrt(0.2166*w[3]^2+1)), w[3]}, w2 = {0, w[4], w[5], w[6]/(0.5346*w[7]+sqrt(0.2166*w[7]^2+1)), w[7]}
	return VoigtPeak(w1, x) + VoigtPeak(w2, x)
end

// area, centre, gFWHM, L/G, area, centre, gFWHM, L/G
//static function TwoVoigtNoBase(Wave w, Variable xx)
//	make/free w1={0, w[0], w[1], w[2], w[3]}, w2={0, w[4], w[5], w[6], w[7]}
//	return VoigtPeak(w1, xx) + VoigtPeak(w2, xx)
//end

static function /wave ContrastingColor(wave RGB)
	wave hsl = RGB2HSL(rgb)
	if (hsl[1] < 0.3)
		return ColorWave("red")
	endif
	variable hue = round(6*hsl[0])
	hue -= 6 * (hue > 5)
	switch (hue)
		case 0: // red
			return ColorWave("cyan")
		case 1: // yellow
			return ColorWave("blue")
		case 2: // green
			return ColorWave("magenta")
		case 3: // cyan
			return ColorWave("red")
		case 4: // blue
			return ColorWave("orange") // orange, yellow is hard to see
		case 5: // magenta
			return ColorWave("lime")
	endswitch
	return rgb
end

static function /WAVE RGB2HSL(wave rgbInt)
	Make /free/N=3 hsl, rgb, rgbDelta
	rgb = rgbInt / 0xFFFF
	variable rgbMin = WaveMin(rgb)
	variable rgbMax = WaveMax(rgb)
	variable del_Max = rgbMax - rgbMin
	
	hsl[2] = (rgbMax + rgbMin) / 2
	if (del_Max == 0) // grey
		hsl[0] = 0
		hsl[1] = 0
	else
		hsl[1] = (hsl[2] < 0.5) ? del_Max/(rgbMax + rgbMin) : del_Max/(2 - rgbMax - rgbMin)
		rgbDelta = ( (rgbMax - rgb[p])/6 + del_Max/2 ) / del_Max
		if (rgb[0] == rgbMax )
			hsl[0] = rgbDelta[2] - rgbDelta[1]
		elseif (rgb[1] == rgbMax )
			hsl[0] = (1/3) + rgbDelta[0] - rgbDelta[2]
		elseif (rgb[2] == rgbMax )
			hsl[0] = (2/3) + rgbDelta[1] - rgbDelta[0]
		endif
		hsl[0] += (hsl[0] < 0)
		hsl[0] -= (hsl[0] > 1)
	endif
	return hsl
end

static function /WAVE ColorWave(string color)
	Make /I/U/free w = {0x0000,0x0000,0x0000}
	strswitch (color)
		case "red" :
			w = {0xFFFF,0x0000,0x0000}
			break
		case "lime" :
			w = {0x0000,0xFFFF,0x0000}
			break
		case "blue" :
			w = {0x0000,0x0000,0xFFFF}
			break
		case "magenta" :
			w = {0xFFFF,0x0000,0xFFFF}
			break
		case "orange" :
			w = {0xFFFF,0xA5A5,0x0000}
			break
		case "cyan" :
			w = {0x0000,0xFFFF,0xFFFF}
			break
		case "plum" :
			w = {0x8080,0x0000,0x8080}
			break
		case "teal" :
			w = {0x0000,0x8080,0x8080}
			break
		case "maroon" :
			w = {0x8080,0x0000,0x0000}
			break
		case "green" :
			w = {0x0000,0x8080,0x0000}
			break
		case "purple" :
			w = {0x8080,0x0000,0x8080}
			break
		// the rest are non-chromatic or hard to see
		case "yellow" :
			w = {0xFFFF,0xFFFF,0x0000}
			break
		case "black" :
			w = {0x0000,0x0000,0x0000}
			break
		case "grey" : // this is my preferred grey
			w = {0xDDDD,0xDDDD,0xDDDD}
			break
		case "mercury" :
			w = {0xE6E6,0xE6E6,0xE6E6}
			break
	endswitch
	return w
end

static function [variable xoffset, variable yoffset] getOffset(string Graph, string trace)
	string s = TraceInfo(Graph, trace, 0)
	s = ListMatch(s, "offset(x)=*")
	sscanf s, "offset(x)={%g,%g}", xoffset, yoffset
	return [xoffset, yoffset]
end

static function [variable x, variable y, variable xmult, variable ymult] GetAllOffsetsFromInfoString(string s)
	sscanf ListMatch(s, "offset(x)=*"), "offset(x)={%g,%g}", x, y
	sscanf ListMatch(s, "muloffset(x)=*"), "muloffset(x)={%g,%g}", xmult, ymult
	return [x, y, xmult, ymult]
end

// axis: 0 = x, 1 = y
static function GetOffsetFromInfoString(string s, int axis)
	variable xOffset, yOffset
	sscanf ListMatch(s, "offset(x)=*"), "offset(x)={%g,%g}", xOffset, yOffset
	return axis ? yOffset : xOffset
end

static function traceType(string Graph, string trace)
	return NumberByKey("TYPE", TraceInfo(Graph, trace, 0))
end

#if (exists("ProcedureVersion") != 3)
// replicates ProcedureVersion function for older versions of Igor
static function ProcedureVersion(string win)
	variable noversion = 0 // default value when no version is found
	if (strlen(win) == 0)
		string strStack = GetRTStackInfo(3)
		win = StringFromList(ItemsInList(strStack, ",") - 2, strStack, ",")
		string IM = " [" + GetIndependentModuleName() + "]"
	endif
	
	wave /T ProcText = ListToTextWave(ProcedureText("", 0, win + IM), "\r")	
	
	variable version
	Grep /Q/E="(?i)^#pragma[\s]*version[\s]*=" /LIST/Z ProcText
	s_value = LowerStr(TrimString(s_value, 1))
	sscanf s_value, "#pragma version = %f", version

	if (V_flag!=1 || version<=0)
		return noversion
	endif
	return version	
end
#endif
