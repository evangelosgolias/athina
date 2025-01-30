#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma version=5.13
#pragma IgorVersion=7
#pragma ModuleName=baselines
#pragma DefaultTab={3,20,4}
#pragma hide=1

// Project Updater header
static constant kProjectID=348 // the project node on IgorExchange
static strconstant ksShortTitle="Baselines" // the project short title on IgorExchange

// If you have installed or updated this project using the IgorExchange
// Projects Installer (http: www.igorexchange.com/project/Updater) you
// can be notified when new versions are released.

#define MarqueeMenus
//#define dev
//#define debug
//#define testing

// Written by Tony Withers, https: www.wavemetrics.com/user/tony
// I would be very happy to hear from you if you find this package
// useful, or if you have any suggestions for improvement. See the help
// file for contact information.

// Baselines now includes all of the baseline types from the ArcHull and
// BaselineSpline projects.

// Hold down the shift key when clicking the reset nodes button for the
// old snap-to-trace behaviour.

// Hold down the option/alt key when clicking the data wave popup menu to 
// allow selection of output waves as data waves

// Wave assignments for large waves are multithreaded.

// Subrange fitting provides an easy way to adjust the output of the
// automatic baseline algorithms, and can used to treat different regions
// of interest separately. See usage notes for more details.

// Note: subrange fitting is not optimized. For masked and spline fits
// the entire baseline is assigned and then the points outside of the
// subrange are reassigned.

// See help file BaselinesHelp.ihf for usage notes

// Version history
// 5.12  Option to allow selection of subtracted and baseline waves as input waves
// 5.04  Improves checking for incompatible traces
// 5.03  Bug Fix: panel was redrawn incorrectly when clicking show info on a left-hand panel
//       Reverses the order of the traces popup menu
// 5.02  Fixes strconstant syntax errors
// 5.01  Updated help file
// 5.00  Setting mask regions now sets precisely the points within the selected range.
//       Previously the points closest to the edges of the range were set in the mask wave.
//       Now possible to fit a constant baseline when only one point is selected.
//       Bug fix: selecting fit regions for x-y traces where x values are < 1 in some
//       edge cases selected incorrect points in the mask wave.
//       Information display is more reliably cleared when fit fails.
//       Removed ARS baseline. No obvious advantage over an iterative smoothing spline fit.
// 4.93  Improved clarity of cleanup code that executes when package window is closed
// 4.92  Takes into account fix for MoveSubwindow in build > 56466
// 4.87  New info ListBox
//       Breaking change: the order of baseline types has changed
// 4.83  New functions:
//       ImportSettings(), ExportSettings(), ImportNodes(), ExportNodes()
// 4.81  Adds Chebyshev series option to auto tab. New convergence test for auto
//       baselines. Lengthy baseline calculations are interrupted with a dialog that
//       has an option to halt calculation. Hover previews (Igor 9) for the Baseline
//       type popup in the auto tab are shown only when calculation is fast enough
//       for the control to feel responsive.
// 4.80  Adds Chebyshev series option for masked and node fitting
//       Changed the title of tab3 to 'Nodes' to describe all interpolated baselines
// 4.79  Igor 8 fix for auto smoothing spline fit to subrange
// 4.78  Adds iterative smoothing spline and ARS baselines.
//       Restores Igor 7 compatibility.
// 4.76  Method for writing custom baseline definitions has changed.
//       Updated help file with instructions for writing user-defined functions.
// 4.75  Adds subfolder output option.
// 4.73  Fixes preferences bug.
// 4.72  Fixes bug that prevented overwrite dialog from appearing when output waves
//       are saved in a data folder other than that currently selected.
// 4.70  Adds Planck function for masked and auto fitting, could perhaps be used
//       with the 'negative peaks' option to fit a continuum with downward-facing
//       peaks.
// 4.65  Fix for manual sigmoid when cursor G is at higher x value than cursor H
// 4.62  Adds option to choose tab and fit type from commandline:
//       baselines#initialise(tab=2,type=15,trace="foo") restarts with an
//       'arc hull' baseline.
// 4.60  Bug fix for Igor 8, interpolate2 error when initialising spline nodes.
//       Check for category traces when compiling list of eligible traces.
//       Shortcut keys for adding and removing mask regions.
// 4.50  Tangent baseline looks for a common tangent when 2 regions are masked,
//       and a horizontal tangent when only one region is masked.
//       Bug Fix: using the (undocumented) browser menu for Igor 9 to initialise
//       a baseline fit sometimes resulted in improperly scaled axes because the
//       graph was not redrawn before initialisation. Fixed with a judiciously
//       placed DoUpdate.
// 4.40  Bug fix: On some computers the window hook was not being set correctly.
//       This happened because the hook function checked the window name against
//       a setting that had not yet been updated, and turned itself off. Now the
//       graph name is recorded in the settings before the hook is set.
// 4.30  Replaced manual 'step' function with sigmoid for consistency with
//       masked and auto fit functions.
//       Some speed improvements achieved by using FastOp.
//       Added manual poly 5 function.
//       Fixed a minor bug that found common tangents outside of the selected
//       fitting range.
//       Added a SetVariable to change polynomial order.
//       Added a checkbox for fixing value of first fit coefficient in some
//       fit functions.
//       Fixed a cosmetic bug that affected the display of masked regions.
//       Added checks for procedure file version changes after init. This
//       enables a less ungraceful quit if an outdated baselines control panel
//       is open in a saved experiment.
// 3.40  Fit regions are now recorded in a 2D wave and the maskwave is set
//       to match the fit regions. Previously fit regions were recorded
//       directly in the maskwave, which has the same dimensionality as the
//       selected trace. The advantage of the new method is that the mask
//       regions are guaranteed to have the same x coordinates (clipped to the
//       length of the trace) as different traces are selected. Now it's
//       possible to do an all-in-one fit for a bunch of mis-matched traces,
//       mixing waveform and X-Y, and different numbers of points. One
//       consequence of the new method is that it's now possible to select a
//       fit region beyond the bounds of the selected trace.
//       Baseline fit parameters are recorded in the wavenote in a nested
//       key-pair format that is consistent with the Bruker Opus file loader
//       for FTIR spectra.
//       Several new options for manual baselines.
// 3.30  Introduces step between cursors, inspired by Stephan Thuermer's
//       Spectra Background Remover project
//       Some additional options for (re)coloring traces
// 3.20  Fixed bug introduced when rtGlobals pragma setting was changed in
//       a previous release
// 3.15  adds compatibility with version 3 of the Updater project
// 3.14  adds missing include statement for ReadbackModifyStr
// 3.13  respects the axes on which data wave is plotted
// 3.10  adds lor3
// 3.09  choose which waves to ignore during all-at-once fitting by
//       editing ksIGNORE
// 3.08  restores printing to history of commands for setting mask regions
// 3.07  Record fit coefficients in wave note of output waves, so that
//       user has access to these for further processing
// 3.06  Added headers for Project Updater.
// 3.05  Jan 5 2018 Adds an easy-to-edit user defined fit function - see
//       the last three functions in this file.
// 3.04  11/11/17 Should be backward compatible for Igor 6.
// 3.03  Panel size decreased for compatibility with smaller or lower
//       resolution screens. Some bugs fixed.
// 3.02  bug fix: spline fit was damaged by 'cosmetic' changes in version 3.01.
// 3.01  cosmetic changes
// 3.00  Sep 11 2017. Switch to panel interface. Closing panel should
//       clear baseline waves from graph. Baseline updates as user interacts
//       with controls on panel or changes mask wave. This was a major rewrite,
//       so let me know when you find the bugs.
// 2.20  code cleanup to use waverefs instead of global string variables
// 2.10  Aug 22 2017 cleaned up the 'tangent' baseline for a beta release
// 2.00  1/2/15 made it work for X-Y data; added wave notes to output waves
// 1.50  finally fixed offsets
// 1.22  fixed offset calculation
// 1.21  12/10/09
// 1.20  6/24/08 added line between cursors
// 1.12  6/9/08
// 1.11  9/12/07
// 1.10  7/23/07 added smoothed spline baseline
// 1.00  7/3/07


// *** constant definitions ***

static constant kMultithreadCutoff = 1e4 // wave assignments will be multithreaded for waves longer than this cutoff
static constant kAllowMuloffset  = 1 // apply matching y-multiplication offset to baseline waves for display.

static strconstant ksManTypes    = "constant;line;poly;gauss;lor;sin;sigmoid;"
static strconstant ksSplineTypes = "cubic spline;Akima spline;PCHIP;linear;smoothing;Chebyshev;Chebyshev2;"

#if IgorVersion() >= 9 // allow fit functions added in later versions
static strconstant ksMaskedTypes = "constant;line;poly;gauss;lor;voigt;sin;sigmoid;exp;dblexp;dblexp_peak;hillequation;power;log;lognormal;spline;Chebyshev;Chebyshev2;Planck;tangent;"
static strconstant ksAutoTypes   = "constant;line;poly;gauss;lor;voigt;sin;sigmoid;exp;dblexp;dblexp_peak;hillequation;power;log;lognormal;spline;Chebyshev;Chebyshev2;Planck;arc hull;hull spline;"
#else // use built-in fit functions available in Igor 7 and 8
static strconstant ksMaskedTypes = "constant;line;poly;gauss;lor;sin;sigmoid;exp;dblexp;hillequation;power;lognormal;spline;Chebyshev;Chebyshev2;Planck;tangent;"
static strconstant ksAutoTypes   = "constant;line;poly;gauss;lor;sin;sigmoid;exp;dblexp;hillequation;power;lognormal;spline;Chebyshev;Chebyshev2;Planck;arc hull;hull spline;"
#endif

static strconstant ksPackageName   = "Baselines"
static strconstant ksPrefsFileName = "acwBaselines.bin"
static constant    kPrefsVersion   = 120

// *** menus ***

//menu "Analysis"
//	"Baselines", /Q, baselines#Initialise()
//end

#if IgorVersion() >= 9
menu "DataBrowserObjectsPopup"
	"Start Baseline Correction", /Q, Baselines#BrowserInit()
end

static function BrowserInit()
	int i
	string strItem = "", strList = ""
	for (i=0;1;i++)
		strItem = GetBrowserSelection(i)
		if (!strlen(strItem))
			break
		endif
		strList = AddListItem(strItem, strList)
	endfor
			
	wave/wave wwObjects = ListToWaveRefWave(strList, 1)

	if (!numpnts(wwObjects))
		return 0
	endif
	int displayed = 0

	for (wave/Z w : wwObjects)
		if (WaveType(w, 1) == 1)
			if (displayed == 0)
				GetMouse
				v_left *= 72 / ScreenResolution
				v_top *= 72 / ScreenResolution
				Display/W=(V_left-100, V_top-100, V_left+300, V_top+200)
				displayed = 1
			endif
			AppendToGraph w
		endif
	endfor
	if (displayed)
		DoUpdate
		Initialise()
	endif
	return 0
end
#endif

#ifdef MarqueeMenus
menu "GraphMarquee", dynamic
	baselines#MarqueeMenuString("-")
	baselines#MarqueeMenuString("Add Region to Fit"), /Q, baselines#MaskAddOrRemoveSelection(1)
	baselines#MarqueeMenuString("Remove Region From Fit"), /Q, baselines#MaskAddOrRemoveSelection(0)
	baselines#MarqueeMenuString("Clear All Fit Regions"), /Q, baselines#SetBaselineRegion(-Inf, Inf, 0); SetMarquee 0, 0, 0, 0
	"-"
end
#endif

static structure PackagePrefs
	uint32 version
	char blsuff[20]  // suffix for saved baselines
	char subsuff[20] // suffix for saved baseline-subtracted waves
	char tab         // last used tab
	char type[4]     // selection number for type popup
	char history     // bitwise settings for history options
	char nodes       // default number of nodes to set
	int16 options
	// 1: add subtracted wave to plot, 2: add BL to plot, 4: remove original,
	// 8: negative peaks, 16: nodes on trace, 32: don't recolor, 64: LHS panel,
	// 128: overwrite without warning, 256: output to current DF, 512: save mask
	// 1024: use subfolders, 2048: allow selection of output waves
	float base // option for non-zero baseline reference level
	char keyplus
	char keyminus
	char masksuff[20] // suffix for saved mask waves
	char reserved[128 - 4 - 47 - 2 - 4 - 2 - 20] // 79 bytes used
endstructure

// set prefs structure to default values
// default values for bls in prefs button function should match these
static function PrefsSetDefaults(STRUCT PackagePrefs &prefs)
	prefs.version  = kPrefsVersion
	prefs.blsuff   = "_BL"
	prefs.subsuff  = "_sub"
	prefs.masksuff = "_mask"
	prefs.tab      = 0
	prefs.type[0]  = 0
	prefs.type[1]  = 0
	prefs.type[2]  = WhichListItem("arc hull", ksAutoTypes)
	prefs.type[3]  = 0
	prefs.history  = 1
	prefs.nodes    = 5
	prefs.options  = 1
	prefs.base     = 0
	prefs.keyplus  = 43
	prefs.keyminus = 45
	int i
	for(i=0;i<(128-79);i+=1)
		prefs.reserved[i] = 0
	endfor
end

static function PrefsLoad(STRUCT PackagePrefs &prefs)
	LoadPackagePreferences/MIS=1 ksPackageName, ksPrefsFileName, 0, prefs
	if (V_flag!=0 || V_bytesRead==0)
		PrefsSetDefaults(prefs)
	elseif (prefs.version != kPrefsVersion)
		// prefs definition may be changed
		PrefsUpdate(prefs)
	endif
end

static function PrefsUpdate(STRUCT PackagePrefs &prefs)
	if (prefs.version < 100)
		PrefsSetDefaults(prefs)
	elseif (prefs.version < 120)
		prefs.keyplus  = 43
		prefs.keyminus = 45
		prefs.masksuff = "_mask"
		prefs.version  = 120
	endif
end

static function PrefsSave(STRUCT BLstruct &bls)
	int version = GetThisVersion()
	if (bls.version != version)
		// if the definition of bls has changed, avoid writing to prefs
		return 0
	endif
	
	STRUCT PackagePrefs prefs
	PrefsLoad(prefs)
	
	prefs.tab      = bls.tab
	prefs.type[0]  = bls.type[0]
	prefs.type[1]  = bls.type[1]
	prefs.type[2]  = bls.type[2]
	prefs.type[3]  = bls.type[3]
	prefs.history  = bls.history
	prefs.nodes    = bls.nodes
	prefs.blSuff   = bls.blsuff
	prefs.subSuff  = bls.subsuff
	prefs.masksuff = bls.masksuff
	prefs.options  = bls.options
	prefs.base     = bls.base
	prefs.keyplus  = bls.keyplus
	prefs.keyminus = bls.keyminus
	SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
end

static structure coordinates
	float x
	float y
endstructure

static structure cursors
	STRUCT coordinates A
	STRUCT coordinates B
	STRUCT coordinates C
	STRUCT coordinates D
	STRUCT coordinates E
	STRUCT coordinates F
	STRUCT coordinates G
	STRUCT coordinates H
	STRUCT coordinates I
	STRUCT coordinates J
endstructure

// *** bls structure ***

// When this structure definition is altered it should be copied to 
// FastFitting.ipf 

// structure definition should not be altered except by extension.
// not static so that determined users can access internal parameters.
structure blstruct
	
	char trace[255] // trace name
	char graph[255] // graph name
	char tab
	char type[4]   // selection number for type popup
	char multi     // set this for all-in-one fitting - a temporary flag not a setting, see fitall below
		
	// information about trace
	int32 datalength
	STRUCT coordinates offset
	char XY
	
	// for subrange fitting
	char subrange
	int32 endp[2]
	
	// storage for cursor positions
	STRUCT cursors csr
	
	// masked fit specific
	STRUCT RectF roi // range for mask selection
	float sd         // for smoothing spline
	
	// man specific
	int16 cycles
	
	// auto specific
	float depth     // for arc hull
	int16 smoothing // binomial pre-smoothing iterations
	char hull
	
	// spline specific
	int16 flagF
	char editmode
	char nodes

	// preferences
	char blsuff[20]
	char subsuff[20]
	char masksuff[20]
	int16 options // see PackagePrefs stucture definition for details
	char history // bit 0: print baseline parameters, 1: print SetBaselineRegion commands
	float base   // for non-zero baseline
	
	// bls definition extended for baselines version 4.30
	int16 version // this will be set to procedure file version at time of initialisation
	char peak     // use 'peak' functions with no y0 offset
	char polyorder
	char FitFunc[32] // the name of the selected fitting function defined by type[tab]
	
	// for baselines version 4.60
	char keyplus
	char keyminus
	
	// for Planck function
	char wavelength
	
	// for ARS, version 4.78
	int16 arsits
	float arssd
	
	// maximum order of Chebshev polynomial in Chebyshev series
	int16 cheborder
	
	// used to limit time for fitting during live popup menu updates
	char quickpop
	
	// fit all traces checkbox state
	char fitall
	
	// set when rebuilding panel to avoid cleanup of package folder
	char rebuild  // flag for internal use
	char info
	
	STRUCT coordinates muloffset // used for calculating baselines and cursor positions for manual fitting
	
endstructure


static function InitialiseStructure(STRUCT BLstruct &bls)
	
	bls.version = GetThisVersion()
	
	STRUCT PackagePrefs prefs
	PrefsLoad(prefs)
	bls.trace       = ""
	bls.graph       = ""
	bls.offset.x    = 0
	bls.offset.y    = 0
	bls.muloffset.x = 0
	bls.muloffset.y = 0
	bls.subrange    = 0
	bls.roi.left    = NaN
	bls.roi.right   = NaN
	bls.roi.top	    = NaN
	bls.roi.bottom  = NaN
	
	bls.csr.C.x     = NaN
	bls.csr.C.y     = NaN
	bls.csr.D.x     = NaN
	bls.csr.D.y     = NaN
	bls.csr.E.x     = NaN
	bls.csr.E.y     = NaN
	bls.csr.F.x     = NaN
	bls.csr.F.y     = NaN
	bls.csr.G.x     = NaN
	bls.csr.G.y     = NaN
	bls.csr.H.x     = NaN
	bls.csr.H.y     = NaN
	bls.csr.I.x     = NaN
	bls.csr.I.y     = NaN
	bls.csr.J.x     = NaN
	bls.csr.J.y     = NaN
	bls.sd          = 1
	bls.smoothing   = 20
	bls.flagF       = 1
	bls.editmode    = 1
	bls.multi       = 0
	bls.hull        = 0
	bls.cycles      = 0
	bls.polyorder   = 3
	bls.peak        = 0
	bls.wavelength  = 1
	bls.arsits      = 25
	bls.arssd       = 10
	bls.cheborder   = 5
	bls.fitall      = 0
	bls.rebuild     = 0
	bls.info        = 0
	
	// load last-used settings from prefs, with some just-in-case sanity checks
	bls.tab      = limit(prefs.tab, 0, 3)
	bls.type[0]  = limit(prefs.type[0], 0, ItemsInList(ksMaskedTypes)-1)
	bls.type[1]  = limit(prefs.type[1], 0, ItemsInList(ksManTypes)-1)
	bls.type[2]  = limit(prefs.type[2], 0, ItemsInList(ksAutoTypes)-1)
	bls.type[3]  = limit(prefs.type[3], 0, ItemsInList(ksSplineTypes)-1)
	bls.nodes    = limit(prefs.nodes, 4, 255)
	bls.history  = prefs.history
	bls.blsuff   = SelectString(strlen(prefs.blSuff)>0, "_BL", prefs.blSuff)
	bls.subsuff  = SelectString(strlen(prefs.subSuff)>0, "_sub", prefs.subSuff)
	bls.maskSuff = SelectString(strlen(prefs.maskSuff)>0, "_mask", prefs.maskSuff)
	bls.options  = prefs.options // see PackagePrefs stucture definition for details
	bls.base     = prefs.base
	bls.keyplus  = prefs.keyplus == 0 ? 43 : prefs.keyplus
	bls.keyminus = prefs.keyminus == 0 ? 45 : prefs.keyminus
	
	SetFitFunc(bls) // sets bls.fitfunc
end

static function InfoMenu()
	string cmd = "(Version: " + num2str(GetThisVersion()/100) + ";"
	cmd += "Visit web page;Email the developer;"
	PopupContextualMenu cmd
	if (V_flag == 2)
		BrowseURL /Z "https://www.wavemetrics.com/node/" + num2str(kProjectID)
	elseif (V_flag == 3)
		Make/T/free/N=5 wt = "mail"
		string newline = "\r\n"
//		#ifdef WINDOWS
//		newline = "\n"
//		#endif
		wt[3] = "subject=" + URLEncode(ksShortTitle + " Package for Igor Pro")
		wt[4] = "Type your message here" + newline + newline
		wt[4] += "PROJECT VERSION:" + num2str(GetThisVersion()) + newline
		wt[4] += ReplaceString(";", IgorInfo(3), newline) + newline
		wt[4] = "body=" + URLEncode(wt[4])
		wt[1] = "tony withers"
		wt[2] = "uni-bayreuth de"
		sprintf cmd, "%sto:%s%%%d%s?%s&%s" wt[0], wt[1], 40, wt[2], wt[3], wt[4]
		BrowseURL/Z ReplaceString(" ", cmd, ".")
	endif
end

// ProcedureVersion("") doesn't work for independent modules!
// extract procedure version from this file
static function GetThisVersion()

	variable procVersion
	// try the quick way
	#if exists("ProcedureVersion") == 3
	procVersion = ProcedureVersion("")
	if (procVersion)
		return round(100 * procVersion)
	endif
	#endif
	
	int maxLines = 20 // number of lines to search for version pragma
	int refNum, i
	string strHeader = ""
	string strLine = ""
	
	Open/R/Z refnum as FunctionPath("")
	if (refnum == 0)
		return 0
	endif
	for (i=0;i<maxLines;i+=1)
		FReadLine refNum, strLine
		strHeader += strLine
	endfor
	Close refnum
	wave/T ProcText = ListToTextWave(strHeader, "\r")
	Grep/Q/E="(?i)^#pragma[\s]*version[\s]*=" /LIST/Z ProcText
	if (v_flag != 0)
		return 0
	endif
	s_value = LowerStr(TrimString(s_value, 1))
	sscanf s_value, "#pragma version = %f", procVersion
	ProcVersion = (V_flag!=1 || ProcVersion<=0) ? 0 : ProcVersion

	return round(100 * ProcVersion)
end

static function ResetPrefs()
	STRUCT PackagePrefs prefs
	LoadPackagePreferences/MIS=1 ksPackageName, ksPrefsFileName, 0, prefs
	PrefsSetDefaults(prefs)
	SavePackagePreferences/KILL ksPackageName, ksPrefsFileName, 0, prefs
end

static function MakePrefsPanel(STRUCT WMButtonAction &s)
	
	if (s.eventcode != 2)
		return 0
	endif
		
	DFREF dfr = GetPackageDFREF()
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct

	if (CheckUpdated(bls, 1))
		return 0
	endif
	
	STRUCT PackagePrefs prefs
	PrefsLoad(prefs)
	
	KillWindow/Z BaselinesPrefsPanel
	
	variable WL = 150, WT = 100, height = 305, width = 422 // window coordinates
	GetWindow/Z $s.win wsizeRM
	if (v_flag == 0)
		WL = V_left + 50; WT = V_top
	endif
	
	NewPanel/K=1/N=BaselinesPrefsPanel/W=(WL,WT,WL+width,WT+height) as "Baseline Settings [version " + num2str(GetThisVersion()/100) +"]"
	ModifyPanel/W=BaselinesPrefsPanel, fixedSize=1, noEdit=1
	
	variable top = 5, vL = 25, vL2 = 230, font = 12, groupw = 200
	
	GroupBox groupGen, pos={vL-15,top}, size={groupw,110}, title="General Settings",fSize=font
	TitleBox txt1, title="Panel on", pos={vL, top+20}, fSize=font, frame=0
	CheckBox chkLHS, pos={vL+60, top+20}, title="Left", mode=1, fSize=font, Proc=baselines#BaselineCheckboxes
	CheckBox chkRHS, pos={vL+110, top+20}, title="Right", mode=1, fSize=font, Proc=baselines#BaselineCheckboxes
	CheckBox chkColor, pos={vL, top+40}, fSize=font, title="Recolor Traces"
	CheckBox chkColor, help={"Highlight working traces by making others grey"}

	CheckBox chkNeg, pos={vL, top+60}, fSize=font, title="Negative Peaks"
	CheckBox chkNeg, help={"Affects auto baselines and node positioning for spline baselines"}
	SetVariable svBase, pos={vL,top+80}, size={150,16}, title="Baseline Zero Value", limits={-Inf,Inf,0}
	SetVariable svBase, help={"Set to desired baseline reference value"}, fSize=font
	
	//top=155
	GroupBox groupSub, pos={vL2-15,top}, size={groupw,265}, title="Baseline Subtraction", fSize=font
	CheckBox chkAppendSub, pos={vL2, top+20}, fSize=font, title="Append Subtracted"
	CheckBox chkAppendSub, help={"Add baseline-subtracted wave to plot after subtraction"}
	CheckBox chkAppendBL, pos={vL2, top+40}, fSize=font, title="Append Baseline"
	CheckBox chkAppendBL, help={"Add baseline to plot after subtraction"}
	CheckBox chkRemOrig, pos={vL2, top+60}, fSize=font, title="Remove Original"
	CheckBox chkRemOrig, help={"Remove trace from graph after subtracting baseline"}
	CheckBox chkOverwrite, pos={vL2, top+80}, fSize=font, title="Overwrite Without Warning"
	CheckBox chkOverwrite, help={"Overwrite baseline, baseline-subtracted, mask, and nodes waves without warning"}
	CheckBox chkParams, pos={vL2, top+100}, fSize=font, title="Record Settings in History"
	CheckBox chkParams, help={"Print baseline parameters after subtracting"}
	
	TitleBox txt2, title="Output Data Folder:", pos={vL2, top+120}, fSize=font, frame=0
	CheckBox chkCurrentDF, pos={vL2, top+140}, title="Current", mode=1, fSize=font, Proc=baselines#BaselineCheckboxes
	CheckBox chkSourceDF, pos={vL2+65, top+140}, title="Same as Source", mode=1, fSize=font, Proc=baselines#BaselineCheckboxes
	CheckBox chkSubfolders, pos={vL2, top+160}, title="Save Waves in Subfolders", mode=0, fSize=font
	CheckBox chkSubfolders, help={"Save output waves in separate subfolder for each baseline type"}
	
	SetVariable svBLsuff, pos={vL2,top+180}, size={165,16}, title="Baseline Suffix", Proc=baselines#BaselineSetvars
	SetVariable svBLsuff, help={"Baseline suffix is appended to output baseline wave names"}, fSize=font, bodyWidth=60
	SetVariable svSubSuff, pos={vL2,top+200}, size={165,16}, title="Subtracted Suffix", Proc=baselines#BaselineSetvars
	SetVariable svSubSuff, help={"Subtracted suffix is appended to output baseline-subtracted wave names"}, fSize=font, bodyWidth=60
	
	CheckBox chkMask, pos={vL2, top+220}, title="Save Mask:", fSize=font
	CheckBox chkMask, help={"Save a copy of mask wave"}
	SetVariable svMaskSuff, pos={vL2,top+220}, size={165,16}, title="", Proc=baselines#BaselineSetvars
	SetVariable svMaskSuff, help={"Mask suffix is appended to output mask wave names"}, fSize=font, bodyWidth=60
	
	CheckBox chkAllowSubSel, pos={vL2, top+240}, title="Allow Selection of Outputs", mode=0, fSize=font
	CheckBox chkAllowSubSel, help={"Output waves can be selected as inputs for baseline fitting"}
		
	top = 115
	GroupBox groupMask, pos={vL-15,top}, size={groupw,70}, title="Mask Settings", fSize=font
	CheckBox chkRegions, pos={vL, top+20}, fSize=font, title="Print SetRegion Commands"
	CheckBox chkRegions, help={"Provides hint for using commandline to set masked regions"}
	SetVariable svKeyplus, pos={vL,top+40}, size={85,16}, title="Keys:  Add", Proc=baselines#BaselineSetvars
	SetVariable svKeyplus, help={"Shortcut for adding selection to masked regions"}, fSize=font
	SetVariable svKeyminus, pos={vL+95,top+40}, size={72,16}, title="Remove", Proc=baselines#BaselineSetvars
	SetVariable svKeyminus, help={"Shortcut for removing selection from masked regions"}, fSize=font
	
	top = 185
	GroupBox groupSpline, pos={vL-15,top}, size={groupw,70}, title="Spline Settings", fSize=font
	CheckBox chkNodesOnTrace, pos={vL, top+20}, fSize=font, title="Set Nodes on Trace"
	CheckBox chkNodesOnTrace, help={"Place nodes on trace Y values rather than guessing baseline node positions"}
	SetVariable svNodes, pos={vL,top+40}, size={150,16}, title="Number of Nodes", fSize=font, limits={4,255,0}
	SetVariable svNodes, help={"Default number of nodes to create when nodes are reset"}
	
	top=275
	Button btnDefaults, pos={vL-10,top}, size={110,22}, title="Revert Settings", Proc=baselines#PrefsButtonProc
	Button btnDefaults, help={"Set all controls to default values"}
	
	Button btnImport, pos={vL+110,top}, size={50,22}, title="Import", Proc=baselines#PrefsButtonProc
	Button btnImport, help={"Load settings from a file"}
	Button btnExport, pos={vL+170,top}, size={50,22}, title="Export", Proc=baselines#PrefsButtonProc
	Button btnExport, help={"Save currently displayed settings to a file"}
	
	Button btnCancel, pos={vL2+60,top}, size={60,22}, title="Cancel", Proc=baselines#PrefsButtonProc
	Button btnSave, pos={vL2+130,top}, size={50,22}, title="Save", Proc=baselines#PrefsButtonProc
	
	SetControlValuesFromPrefs(bls)
	
	PauseForUser BaselinesPrefsPanel
	return 0
end

static function PrefsButtonProc(STRUCT WMButtonAction &s)

	if (s.eventCode != 2) // mouseup
		return 0
	endif
	
	STRUCT BLstruct bls
	
	DFREF dfr = GetPackageDFREF()
	StructGet bls dfr:w_struct
	
	if (CheckUpdated(bls, 1))
		return 0
	endif
	
	strswitch(s.ctrlName)
		case "btnCancel" :
			DoWindow/K $s.win
			break
		case "btnSave" :
			STRUCT BLstruct oldbls
			oldbls = bls
			GetPrefsControlValues(bls)
			
			if ((bls.options&0x20) %^ (oldbls.options&0x20)) // color option has changed
				if (bls.options & 0x20)
					ResetColors(oldbls, 0) // restore colors
				else
					ResetColors(bls, 3) // save current colors
				endif
				ResetGraphForTrace(bls) // set selected trace and baseline colors
			endif
						
			// rebuild the panel to sync controls
			MakeBaselinesPanel(bls)
			StructPut bls dfr:w_struct
			PrefsSave(bls)
			DoFit(bls)
			DoWindow/K $s.win
			break
		case "btnDefaults" :
			bls.base     = 0
			bls.history  = 1
			bls.options  = 1
			bls.blsuff   = "_BL"
			bls.subsuff  = "_sub"
			bls.nodes    = 5
			bls.keyplus  = 43
			bls.keyminus = 45
			
			SetControlValuesFromPrefs(bls)
			break
		case "btnImport" :
			ImportSettings("", 1, 0)
			break
		case "btnExport" :
			ExportSettings("", 1)
			break
	endswitch
	return 0
end

static function ExportSettings(string strPath, int gui)
	
	STRUCT BLstruct bls
	DFREF dfr = GetPackageDFREF()
	StructGet bls dfr:w_struct
	
	if (gui)
		GetPrefsControlValues(bls)
	endif
	bls.trace = "Exported Settings"
	Make/O/N=0 dfr:w_struct_temp /wave=w_export
	StructPut bls w_export // saving bls ensures that all options are saved
	if (strlen(strPath))
		Save/C w_export as strPath
	else
		Save/C/I w_export as "Baselines Settings"
	endif
	KillWaves/Z w_export
end

// extended=0: import preferences as displayed in settings dialog
// extended=1: also import values for controls in the baselines control panel
// in this way all settings other than the trace selection can be transferred

static function ImportSettings(string strPath, int gui, int extended)
	int i
	
	STRUCT BLstruct importbls
	STRUCT BLstruct bls
	DFREF dfr = GetPackageDFREF()
	
	DFREF saveDF = GetDataFolderDFR()
	DFREF DFfree = NewFreeDataFolder()
	SetDataFolder DFfree
	
	try
		if (strlen(strPath))
			LoadWave/Q strPath; AbortOnRTE
		else
			LoadWave/Q/I; AbortOnRTE
		endif
		if (v_flag)
			StructGet importbls, $StringFromList(0, S_waveNames); AbortOnRTE
		endif	
	catch
		variable err = GetRTError(1)		// Gets error code and clears error
		SetDataFolder saveDF
		return 0
	endtry
	
	SetDataFolder saveDF
	if (cmpstr(importbls.trace, "Exported Settings"))
		return 0
	endif


	if (gui)
		SetControlValuesFromPrefs(importbls)
	else
	
		wave wstruct = dfr:w_struct
		StructGet bls wstruct
			
		if ((importbls.options&0x20) %^ (bls.options&0x20)) // color option has changed
			if (importbls.options & 0x20)
				ResetColors(bls, 0) // restore colors
			else
				ResetColors(importbls, 3) // save current colors
			endif
		endif
		
		bls.history  = importbls.history
		bls.nodes    = importbls.nodes
		bls.blsuff   = importbls.blsuff
		bls.subsuff  = importbls.subsuff
		bls.masksuff = importbls.masksuff
		bls.options  = importbls.options // changing bit 3 (negative peaks) may require a panel and graph update
		bls.base     = importbls.base // changing base requires a graph update
		bls.keyplus  = importbls.keyplus
		bls.keyminus = importbls.keyminus
		StructPut bls wstruct
		PrefsSave(bls)
		
		if (extended)
			bls.tab        = importbls.tab
			bls.type       = importbls.type
			bls.sd         = importbls.sd // this setting may not be retained
			bls.smoothing  = importbls.smoothing
			bls.flagF      = importbls.flagF
			bls.editmode   = importbls.editmode
			bls.hull       = importbls.hull
			bls.cycles     = importbls.cycles
			bls.polyorder  = importbls.polyorder
			bls.peak       = importbls.peak
			bls.wavelength = importbls.wavelength
			bls.arsits     = importbls.arsits
			bls.arssd      = importbls.arssd
			bls.cheborder  = importbls.cheborder
			bls.fitall     = importbls.fitall
			bls.info       = importbls.info
			
			bls.subrange   = importbls.subrange
			bls.endp[0]    = importbls.endp[0]
			bls.endp[1]    = importbls.endp[1]
		endif
		
		ResetPanelAndGraph(bls)
	endif
	return 1
end

static function GetPrefsControlValues(STRUCT BLstruct &bls)
		
	int options, history
	int oldOptions = bls.options
	ControlInfo/W=BaselinesPrefsPanel chkAppendSub
	options += 1 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkAppendBL
	options += 2 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkRemOrig
	options += 4 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkNeg
	options += 8 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkNodesOnTrace
	options += 16 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkColor
	options += 32 * (!v_value)
	ControlInfo/W=BaselinesPrefsPanel chkLHS
	options += 64 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkOverwrite
	options += 128 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkCurrentDF
	options += 256 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkMask
	options += 512 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkSubfolders
	options += 1024 * v_value
	ControlInfo/W=BaselinesPrefsPanel chkAllowSubSel
	options += 2048 * v_value
	bls.options = options
			
	ControlInfo/W=BaselinesPrefsPanel svBase
	bls.base = v_value
	ControlInfo/W=BaselinesPrefsPanel svBLsuff
	bls.blsuff = s_value
	ControlInfo/W=BaselinesPrefsPanel svSubSuff
	bls.subsuff = s_value
	ControlInfo/W=BaselinesPrefsPanel svMaskSuff
	bls.masksuff = s_value
	ControlInfo/W=BaselinesPrefsPanel svNodes
	bls.nodes = v_value
	ControlInfo/W=BaselinesPrefsPanel svKeyplus
	bls.keyplus = char2num(s_value)
	ControlInfo/W=BaselinesPrefsPanel svKeyminus
	bls.keyminus = char2num(s_value)
	
	ControlInfo/W=BaselinesPrefsPanel chkParams
	history = v_value
	ControlInfo/W=BaselinesPrefsPanel chkRegions
	history += 2*v_value
	bls.history = history
	
	if ((bls.options&8) != (oldOptions&8)) // reversed peak direction
		bls.depth = -bls.depth
	endif
end

static function SetControlValuesFromPrefs(STRUCT BLstruct &bls)
	
	CheckBox chkAppendSub, win=BaselinesPrefsPanel, value = bls.options&1
	CheckBox chkAppendBL, win=BaselinesPrefsPanel, value = bls.options&2
	CheckBox chkRemOrig, win=BaselinesPrefsPanel, value = bls.options&4
	CheckBox chkNeg, win=BaselinesPrefsPanel, value = bls.options&8
	CheckBox chkNodesOnTrace, win=BaselinesPrefsPanel, value = bls.options&0x10
	CheckBox chkColor, win=BaselinesPrefsPanel, value = !(bls.options&0x20)
	CheckBox chkLHS, win=BaselinesPrefsPanel, value = bls.options&0x40
	CheckBox chkRHS, win=BaselinesPrefsPanel, value = !(bls.options&0x40)
	CheckBox chkOverwrite, win=BaselinesPrefsPanel, value = (bls.options&0x80)
	CheckBox chkCurrentDF, win=BaselinesPrefsPanel, value = bls.options&0x100
	CheckBox chkSourceDF, win=BaselinesPrefsPanel, value = !(bls.options&0x100)
	CheckBox chkMask, win=BaselinesPrefsPanel, value = bls.options&0x200
	CheckBox chkSubfolders, win=BaselinesPrefsPanel, value = bls.options&0x400
	CheckBox chkAllowSubSel, win=BaselinesPrefsPanel, value = bls.options&2048

	SetVariable svBLsuff, win=BaselinesPrefsPanel, value=_STR:bls.blsuff
	SetVariable svSubSuff, win=BaselinesPrefsPanel, value=_STR:bls.subsuff
	SetVariable svMaskSuff, win=BaselinesPrefsPanel, value=_STR:bls.masksuff
	SetVariable svBase, win=BaselinesPrefsPanel, value=_NUM:bls.base
	SetVariable svNodes, win=BaselinesPrefsPanel, value=_NUM:bls.nodes
	
	SetVariable svKeyplus, win=BaselinesPrefsPanel, value=_STR:num2char(bls.keyplus)
	SetVariable svKeyminus, win=BaselinesPrefsPanel, value=_STR:num2char(bls.keyminus)
	
	CheckBox chkParams, win=BaselinesPrefsPanel, value = bls.history&1
	CheckBox chkRegions, win=BaselinesPrefsPanel, value = bls.history&2
end

static function SetTraceProperties(STRUCT BLstruct &bls)
	// be careful because bls.trace = "" will be interpreted as top trace!
	wave/Z w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	if (strlen(bls.trace)==0 || WaveExists(w_data) == 0)
		bls.datalength = 0
		return 0
	endif
	bls.datalength = DimSize(w_data, 0)
	
	if (bls.datalength < 5)
		bls.datalength = 0
		return 0
	endif
	
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	bls.XY = WaveExists(w_x)
	if (bls.XY)
		// check for monotonic X wave
		Make/free w_diff
		Differentiate w_x /D=w_diff
		WaveStats/Q/M=0 w_diff
		if (V_max>0 && V_min<0)
			bls.datalength = 0
			#ifdef debug
			Print "Baselines: cannot use non-monotonic X-wave"
			#endif
		endif
	endif
	variable offsetX = 0, offsetY = 0
	string infostr = TraceInfo(bls.graph, bls.trace, 0)
	
	sscanf ListMatch(infostr, "offset(x)=*"), "offset(x)={%g,%g}", offsetX, offsetY
	bls.offset.x = offsetX
	bls.offset.y = offsetY
	
	sscanf ListMatch(infostr, "muloffset(x)=*"), "muloffset(x)={%g,%g}", offsetX, offsetY
	bls.muloffset.x = offsetX
	bls.muloffset.y = offsetY
	
end

static function SetFitFunc(STRUCT BLstruct &bls)
	switch (bls.tab)
		case 0:
			bls.fitfunc = StringFromList(bls.type[bls.tab], ksMaskedTypes + GetListOfUserFuncs())
			break
		case 1:
			bls.fitfunc = StringFromList(bls.type[bls.tab], ksManTypes)
			break
		case 2:
			bls.fitfunc = StringFromList(bls.type[bls.tab], ksAutoTypes + GetListOfUserFuncs())
			break
		case 3:
			bls.fitfunc = StringFromList(bls.type[bls.tab], ksSplineTypes)
			break
	endswitch
	return 1
end

static function QuitBaselines(STRUCT BLstruct &bls)
	KillWindow/Z $bls.graph + "#BL_panel"
	KillWindow/Z BaselinesPrefsPanel
	PrefsSave(bls)
	ClearGraph(bls, 0)
	KillDataFolder/Z GetPackageDFREF()
	return 0
end

static function/DF GetPackageDFREF()
	DFREF dfr = root:Packages:Baselines
	if (DataFolderRefStatus(dfr) != 1 || WaveExists(dfr:w_struct)==0)
		DFREF dfr = CreatePackageFolder()
	endif	
	return dfr
end

static function/DF CreatePackageFolder()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:Baselines
	DFREF dfr = root:Packages:Baselines
	STRUCT BLstruct bls
	InitialiseStructure(bls)
	Make/O/N=0 dfr:w_struct /wave=w_struct
	StructPut bls w_struct
	
	Make/O/N=(0,2) dfr:w_regions
	Make/O/N=0 dfr:w_display
	Make/O/N=0/D dfr:w_nodesX, dfr:w_nodesY
	Make/O/N=1 dfr:w_spline_dependency /wave=w_spline_dependency
	// set a dependency to trigger interpolation and update graph when we
	// adjust a node position
	w_spline_dependency := baselines#DoSplineFit(root:Packages:Baselines:w_nodesY)
	Make/O/N=0/T dfr:w_traces
	Make/O/I/U/N=(0,3) dfr:w_colors
	Make/O/N=2 dfr:dummy /wave=dummy = {1, 100}
	SetScale/I x, 1, 100, dummy
	Make/O/N=0 dfr:w_mask
	Make/T/O/N=(0,2) dfr:listwave
	Make/O/N=0 dfr:w_base
	return dfr
end
 
static function/S MarqueeMenuString(string str)
	wave/Z w_struct = root:Packages:Baselines:w_struct
	if (WaveExists(w_struct) == 0) // not initialised
		return ""
	endif
	STRUCT BLstruct bls
	StructGet bls w_struct
	if (bls.tab != 0 || cmpstr(WinName(0,1), bls.graph))
		return ""
	endif
			
	DFREF dfr = GetPackageDFREF()
	wave/Z/SDFR=dfr w_regions
		
	if (DimSize(w_regions, 0)==0 && cmpstr(str[0,2], "Add"))
		return ""
	endif

 	return str
end

// optional parameters:
// graph = name of graph window
// tab = tab to display, numbered from 0
// type = zero-based numeric index for baseline type
// trace = name of trace to select at startup;
// EditMode = set edit mode when starting with tab=3 (defaults to 0)
// Example: Baselines#Initialise(graph="MySpectra", tab=3, type=5, trace="Spectrum3", EditMode=0)
// See also ImportSettings() and ImportNodes() functions.
static function Initialise([string Graph, int tab, int type, string trace, int EditMode])
	DFREF dfr = GetPackageDFREF()
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct
	
	// clear any package detritus from the last used baseline graph
	ClearGraph(bls, 1) // may delete package folder
	
	if (ParamIsDefault(Graph) == 0)
		DoWindow/F $Graph
	endif
	
	if (WinType("") != 1) // not a graph
		DoAlert 1, "The top window is not a graph.\rDo you want to create a demo graph?"
		if (v_flag == 1)
			MakeSpectrum(N=5)
			DoUpdate
		else
			KillDataFolder/Z dfr
			return 0
		endif
	endif
	
	// make a fresh start
	dfr = CreatePackageFolder()
	StructGet bls dfr:w_struct
	
	// make sure the top graph is visible
	string graphStr = WinName(0,1)
	DoWindow/F $graphStr
	bls.graph = graphStr
		
	if (ParamIsDefault(tab) == 0)
		bls.tab = limit(tab, 0, 3)
	endif
	
	if (ParamIsDefault(type) == 0)
		bls.type[bls.tab] = type
	endif
	
	SetFitFunc(bls)
	if (strlen(bls.fitfunc) == 0) // invalid type
		bls.type[bls.tab] = 0
		SetFitFunc(bls)
	endif
		
	if (ParamIsDefault(trace) == 0)
		bls.trace = trace
	endif
	
	// when panel is made a hook function is set for graph window;
	// hook checks struct for matching window name!
	StructPut bls dfr:w_struct
		
	// make the panel
	if (MakeBaselinesPanel(bls) == 0) // bls structure now contains information about trace
		return 0
	endif
	
	ResetColors(bls, 3) // save current trace colors and set all to grey
	ResetGraphForTrace(bls) // create fit waves and add to plot
	ResetGraphForType(bls) // sets cursors
	DoFit(bls)
	
	if (ParamIsDefault(editmode)==0 && bls.tab==3)
		bls.editmode = EditMode
		SetEditMode(bls)
	endif
	
	StructPut bls dfr:w_struct
end

static function action(string str)
	DFREF dfr = GetPackageDFREF()
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct
	
	str = ReplaceString(" ", LowerStr(str), "")
	STRUCT WMButtonAction s
	s.eventCode = 2
	strswitch (str)
		case "subtract":
			s.ctrlName = "btnSub"
			break
		case "done":
			s.ctrlName = "btnDone"
			break
	endswitch
	s.win = bls.graph + "#BL_panel"
	BaselineButtons(s)
end

// *** panel ***
// We call this to set up the graph for baseline fitting
static function MakeBaselinesPanel(STRUCT BLstruct &bls)
	
	if (strlen(bls.graph) == 0)
		return 0
	endif
	
	// make sure there's space for the panel
	// this could be smarter - deal with multiple screens, use igorinfo(0)
	GetWindow/Z $bls.graph wsize
	
	variable panelW = 205, panelH = 370 + 60 * bls.info
	if ((bls.options&0x40) && V_left < panelW)
		MoveWindow/W=$bls.graph panelW, V_top, -1, -1
	endif
	
	string panelStr = bls.graph+"#BL_panel"
		
	// this will usually kill the package folder
	KillWindow/Z $panelStr
	
	// make panel
	if (bls.options & 0x40)	// panel on left
		NewPanel/K=1/N=BL_panel/W=(panelW,0,0,panelH)/HOST=$bls.graph/EXT=1 as "Baseline Controls"
	else // panel on right
		NewPanel/K=1/N=BL_panel/W=(0,0,panelW,panelH)/HOST=$bls.graph/EXT=0 as "Baseline Controls"
	endif
	ModifyPanel/W=$panelStr, noEdit=1
	
	string traces = GetTraceList(bls)
	if (strlen(traces) == 0)
		DoAlert 0, "No eligible traces for baseline fitting plotted in top graph - check wave names"
	endif
	
	variable top=5, vL=25, font=12, groupw=188, vC = panelW/2
	variable isWin = 0
	#ifdef WINDOWS
	isWin = 1
	#endif
	
	Button btnSettings, win=$panelStr, pos={180,top}, size={15,15}, title="", Picture=Baselines#pCog, labelBack=0
	Button btnSettings, win=$panelStr, Proc=Baselines#MakePrefsPanel, help={"Change Settings"}, focusRing=0
	Button btnHelp, win=$panelStr, pos={160,top}, size={15,15}, title="", Picture=Baselines#pHelp, labelBack=0
	Button btnHelp, win=$panelStr, Proc=Baselines#baselineButtons, help={"Click for help"}, focusRing=0//, disable=2
	Button btnInfo, pos={140,top}, size={15,15}, Proc=Baselines#baselineButtons, title=""
	Button btnInfo, help={"Show Info"}, Picture=Baselines#pInfo
	
	top = 10
	GroupBox groupTrace, win=$panelStr, pos={vL-15,top}, size={groupw,50}, title="Data wave", fSize=font
	PopupMenu popTrace, win=$panelStr, pos={vL,top+25}, size={155,20}, title="", mode=1, Value=baselines#GetTracesForPopup()
	PopupMenu popTrace, win=$panelStr, help={"Select data wave" }, Proc=baselines#BaselinePopups, bodywidth=155
	
	if (WhichListItem(bls.trace, traces) == -1) // if we are rebuilding the panel we keep current selection
		bls.trace = StringFromList(0, traces)
	else
		PopupMenu popTrace, win=$panelStr, popmatch=bls.trace
	endif
	SetTraceProperties(bls)
	
	top = 65
	TabControl tabs, win=$panelStr, pos={0,top}, size={205,200}, labelBack=(0xEEEE,0xEEEE,0xEEEE)
	TabControl tabs, win=$panelStr, tabLabel(0)="Mask", tabLabel(1)="Man", tabLabel(2)="Auto", tabLabel(3)="Nodes"
	TabControl tabs, win=$panelStr, value=bls.tab, Proc=baselines#BaselineTabs
	
	// all tabs, controls within the 'baseline type' groupbox
	top = 95
	GroupBox groupType, win=$panelStr, pos={vL-15,top}, size={groupw,50}, title="Baseline type", fSize=font
	PopupMenu popType, win=$panelStr, pos={vL,top+25}, size={100,20}, title="", fSize=font
	PopupMenu popType, win=$panelStr, help={"Select baseline type" }, Proc=baselines#BaselinePopups
	SetVariable svSD, win=$panelStr, pos={vL+40,top+25}, size={120,16}, title="SD", fSize=font, focusring=0
	SetVariable svSD, win=$panelStr, limits={0,Inf,1}, value=_NUM:bls.sd, bodyWidth=60
	string strModifiers
	#ifdef WINDOWS
	strModifiers = "\rHold shift/alt to increase/decrease increment"
	#else
	strModifiers = "\rHold shift/option to increase/decrease increment"
	#endif
	SetVariable svSD, win=$panelStr, help={"Estimate of noise for smoothing spline" + strModifiers}, Proc=baselines#BaselineSetvars
	SetVariable svCycles_tab1, win=$panelStr, pos={vL+65,top+25}, size={90,16}, title="Cycles", fSize=font, focusring=0
	SetVariable svCycles_tab1, win=$panelStr, limits={0,1000,1}, value=_NUM:bls.cycles
	SetVariable svCycles_tab1, win=$panelStr, help={"Select desired number of complete cycles between cursors"}, Proc=baselines#BaselineSetvars
	SetVariable svDepth_tab2, win=$panelStr, pos={vL+95,top+25}, size={65,16}, title="", fSize=font, focusring=0
	SetVariable svDepth_tab2, win=$panelStr, limits={-Inf,Inf,abs(bls.depth/10)+(bls.depth==0)}, value=_NUM:bls.depth
	SetVariable svDepth_tab2, win=$panelStr, help={"Depth of arc" + strModifiers}, Proc=baselines#BaselineSetvars
		
	SetVariable svARSits_tab2, win=$panelStr, pos={vL+63,top+25}, size={50,16}, title="its", fSize=font, focusring=0
	SetVariable svARSits_tab2, win=$panelStr, value=_NUM:bls.arsits, limits={1,100,0}
	SetVariable svARSits_tab2, win=$panelStr, help={"Iterations"}, Proc=baselines#BaselineSetvars
	SetVariable svARSsd_tab2, win=$panelStr, pos={vL+115,top+25}, size={50,16}, title="sd", fSize=font, focusring=0
	SetVariable svARSsd_tab2, win=$panelStr, value=_NUM:bls.arssd, limits={1,100,0}
	SetVariable svARSsd_tab2, win=$panelStr, help={"SD for smoothing"}, Proc=baselines#BaselineSetvars
	
	SetVariable svF_tab3, win=$panelStr, pos={vL+105,top+25}, size={50,16}, title="", fSize=font, bodyWidth=50, focusring=0
	SetVariable svF_tab3, win=$panelStr, value=_NUM:bls.flagF, limits={0,Inf,1}
	SetVariable svF_tab3, win=$panelStr, help={"Smoothing factor"}, Proc=Baselines#BaselineSetvars
	
	// appears in tabs 0, 1, 2
	SetVariable svPoly, win=$panelStr, pos={vL+80,top+25}, size={80,16}, title="Order", fSize=font, focusring=0
	SetVariable svPoly, win=$panelStr, value=_NUM:bls.polyorder // , limits={3,20,1}
	SetVariable svPoly, win=$panelStr, help={"Polynomial order"}, Proc=baselines#BaselineSetvars
	
	// appears in tabs 0, 2, 3
	SetVariable svChebOrder, win=$panelStr, pos={vL+60,top+25}, size={100,16}, title="", fSize=font, focusring=0
	SetVariable svChebOrder, win=$panelStr, limits={0,30,1}, value=_NUM:bls.cheborder, bodyWidth=40
	SetVariable svChebOrder, win=$panelStr, help={"Maximum polynomial order in Chebyshev series"}, Proc=baselines#BaselineSetvars
	
	// appears in tabs 0 and 2
	CheckBox chkPeak, win=$panelStr, pos={vL+110,top+25+2*isWin}, title="Peak", fSize=font, Proc=Baselines#BaselineCheckboxes
	CheckBox chkPeak, win=$panelStr, help={"Peak function with vertical offset y0 fixed at baseline zero value"}, value=bls.peak
	
	// appears in tabs 0 and 2
	PopupMenu popPlanck, win=$panelStr, pos={vL+90,top+25}, title="", fSize=font, Proc=baselines#BaselinePopups
	PopupMenu popPlanck, win=$panelStr, help={"select wavelength units"}, mode=bls.wavelength, value="nm;μm;cm^-1;Å;"
		
	// tab 0, mask region group
	top = 150
	GroupBox groupMaskRegions_tab0, win=$panelStr, pos={vL-15,top}, size={groupw,85}, title="Fit regions"
	GroupBox groupMaskRegions_tab0, win=$panelStr, fSize=font
	SetVariable svL_tab0, win=$panelStr, pos={vL,top+25}, size={70,16}, title="", fsize=font, value=_STR:"", focusring=0
	SetVariable svL_tab0, win=$panelStr, limits={-Inf,Inf,0}, Proc=baselines#BaselineSetvars
	SetVariable svL_tab0, win=$panelStr, help={"Click and drag in graph window or type a pair\rof values here to select a region for fitting"}
	SetVariable svR_tab0, win=$panelStr, pos={vC+10,top+25}, size={70,16}, title="-", fsize=font, value=_STR:"", focusring=0
	SetVariable svR_tab0, win=$panelStr, limits={-Inf,Inf,0}, bodyWidth=70, Proc=baselines#BaselineSetvars
	SetVariable svR_tab0, win=$panelStr, help={"Click and drag in graph window or type a pair\rof values here to select a region for fitting"}
	Button btnAdd_tab0, win=$panelStr, pos={vL+125,top+50}, size={30,26}, title="\sa-04+", Proc=baselines#BaselineButtons
	Button btnAdd_tab0, win=$panelStr, help={"Add marquee range to fit region"}, fSize=20, fColor=(49151,65535,49151)
	Button btnRemove_tab0, win=$panelStr, pos={vL+85,top+50}, size={30,26}, title="\sa-04-", Proc=baselines#BaselineButtons
	Button btnRemove_tab0, win=$panelStr, help={"Remove marquee range from fit region"}, fSize=20, fColor=(65535,49151,49151)
	Button btnClear_tab0, win=$panelStr, pos={vL,top+53}, size={60,20}, title="Clear All", Proc=baselines#BaselineButtons
	Button btnClear_tab0, win=$panelStr, help={"Clear all fit regions"}, fSize=font
	
	// tab 1, manual
	top = 150
	Button btnResetCsrs_tab1, win=$panelStr, pos={vC-25,top+85}, size={50,20}, title="Reset", fSize=font
	Button btnResetCsrs_tab1, win=$panelStr, help={"Reset cursor positions"}, Proc=baselines#BaselineButtons
		
	// tab 2, auto
	top = 155
	SetVariable svSmooth_tab2, win=$panelStr, pos={vL,top}, size={130,16}, title="Pre-smooth", fSize=font, focusring=0
	SetVariable svSmooth_tab2, win=$panelStr, limits={0,32767,1},value=_NUM:bls.smoothing
	SetVariable svSmooth_tab2, win=$panelStr, help={"Binomial pre-smoothing factor for baseline calculation"}, Proc=baselines#BaselineSetvars
	CheckBox chkNeg_tab2, win=$panelStr, pos={vL,top+25+2*isWin}, title="Negative peaks", fSize=font, Proc=Baselines#BaselineCheckboxes
	CheckBox chkNeg_tab2, win=$panelStr, help={"Fit baseline to top of spectrum, also\raffects node positions for splines"}, value=bls.options&8
	CheckBox chkHull_tab2, win=$panelStr, pos={vL,top+45+2*isWin}, title="Use convex hull at start", fSize=font, Proc=Baselines#BaselineCheckboxes
	CheckBox chkHull_tab2, win=$panelStr, help={"Use convex hull for first iteration"}, value=bls.hull
	// define guides for ARS graph subwindow
	DefineGuide/W=$panelStr gLeft={FL,5}
	DefineGuide/W=$panelStr gRight={FR,-5}
	DefineGuide/W=$panelStr gTop={FT,150}
	DefineGuide/W=$panelStr gBottom={FB,-90}
		
	// tab 3, spline, nodes group
	top = 150
	GroupBox groupNodes_tab3, win=$panelStr, pos={vL-15,top}, size={groupw,100}, title="Node control", fSize=font
	CheckBox chkEdit_tab3, win=$panelStr, pos={vL+35,top+20}, title="Edit mode ", fSize=font, value=bls.editmode, side=1
	CheckBox chkEdit_tab3, win=$panelStr, mode=0,help={"Toggle to edit nodes"}, Proc=Baselines#BaselineCheckboxes
	TitleBox text_tab3 win=$panelStr, pos={vL, top+35}, frame=0, fSize=font
	#ifdef WINDOWS
	TitleBox text_tab3 win=$panelStr, title="Control- or alt-click in\rgraph to add or zap nodes"
	#else
	TitleBox text_tab3 win=$panelStr, title="Control- or option-click in\rgraph to add or zap nodes"
	#endif
	Button btnResetNodes_tab3, win=$panelStr, pos={vL-5,top+70}, size={45,20}, title="Reset", Proc=Baselines#BaselineButtons
	Button btnResetNodes_tab3, win=$panelStr, help={"Distribute nodes over x-range of graph\rShift-click to snap to trace"}, fSize=font
	Button btnLoadNodes_tab3, win=$panelStr, pos={vL+45,top+70}, size={50,20}, title="Load...", Proc=Baselines#BaselineButtons
	Button btnLoadNodes_tab3, win=$panelStr, help={"Load nodes used in a previous fit"} , fSize=font
	Button btnExportNodes_tab3, win=$panelStr, pos={vL+100,top+70}, size={60,20}, title="Export...", Proc=Baselines#BaselineButtons
	Button btnExportNodes_tab3, win=$panelStr, help={"Save node positions in external file"}, fSize=font
	
	// subrange group, all tabs
	top = 265
	GroupBox groupSubrange, win=$panelStr, pos={vL-15,top}, size={groupw,50}, title="Subrange", fSize=font
	CheckBox chkRange, win=$panelStr, pos={vL,top+25+2*isWin}, title="", fSize=font, Proc=Baselines#BaselineCheckboxes
	CheckBox chkRange, win=$panelStr, help={"Calculate baseline between cursors"}, value=bls.subrange
	SetVariable svL, win=$panelStr, pos={vL+25,top+25}, size={55,16}, title="", fsize=font, value=_STR:"", focusring=0
	SetVariable svL, win=$panelStr, limits={-Inf,Inf,0}, Proc=baselines#BaselineSetvars, disable=2
	SetVariable svL, win=$panelStr, help={"Type a value or drag vertical cursor to set subrange for baseline subtraction"}
	SetVariable svR, win=$panelStr, pos={vC+5,top+25}, size={67,16}, title="-", fsize=font, value=_STR:"", focusring=0
	SetVariable svR, win=$panelStr, limits={-Inf,Inf,0}, Proc=baselines#BaselineSetvars, bodyWidth=55, disable=2
	SetVariable svR, win=$panelStr, help={"Type a value or drag vertical cursor to set subrange for baseline subtraction"}
	if (bls.subrange)
		SetVariable svL, win=$panelStr, value=_NUM:bls.csr.C.x, disable=0
		SetVariable svR, win=$panelStr, value=_NUM:bls.csr.D.x, disable=0
	endif

	// info readout area, all tabs
	top = 320
	CheckBox chkInfo, win=$panelStr, pos={vL-15,top+2*isWin}, size={37,16}, value=bls.info, mode=2, title="", fsize=font
	CheckBox chkInfo, win=$panelStr, Proc=Baselines#BaselineCheckboxes, help={"Show/Hide Baseline Info"}
	string strTitle = selectstring(bls.info, "show baseline info", "hide baseline info")
	Button btnBLInfo, win=$panelStr, pos={vL+5,top+1}, size={85,15}, title=strTitle, labelBack=0, Picture=Baselines#transparent
	Button btnBLInfo, win=$panelStr, help={"Show/Hide Baseline Info"}, focusRing=0, Proc=Baselines#BaselineButtons, fsize=9 // , disable=bls.info
	top += 20
	wave/SDFR=GetPackageDFREF() listwave
	ListBox listInfo, win=$panelStr, pos={vL-15,top}, size={188.00,50.00}, focusRing=0
	ListBox listInfo, win=$panelStr, listWave=listwave, widths={10,17}, disable=!bls.info, fsize=font-3, Proc=baselines#BaselineListbox
	#if IgorVersion() >= 8
	ListBox listInfo, win=$panelStr, helpWave=listwave
	#endif
	// subtract button, all tabs
	top += 60 * bls.info
	CheckBox chkFitAll, win=$panelStr, pos={vL,top+2}, size={65,20}, title="All Traces", fSize=font, Proc=baselines#BaselineCheckboxes
	CheckBox chkFitAll, win=$panelStr, help={"Subtract baseline from all traces"}
	Button btnSub, win=$panelStr, pos={Vc+20,top}, size={65,20}, title="Subtract", Proc=baselines#BaselineButtons
	Button btnSub, win=$panelStr, help={"Subtract baseline"}, fSize=font
		
	// Button for graph window
	Button btnEdit_graph, win=$bls.Graph, pos={70,20}, size={140,30}, title="\\K(0,65535,0)Edit mode", fSize=20, fColor=(0,0,0), focusRing=0
	Button btnEdit_graph, win=$bls.Graph, Proc=Baselines#BaselineButtons, help={"Click to toggle edit mode"}, Picture=baselines#transparent
	#if (IgorVersion() >= 9)
	Button btnEdit_graph, win=$bls.Graph, labelBack=(0xFFFF,0xFFFF,0xFFFF,0)
	#endif
	ModifyGraph/W=$bls.graph axisOnTop=1
	ClearMarquee(bls)
	
	SetWindow $bls.graph hook(hBaselines)=baselines#hookBaselines
	SetWindow $bls.graph hook(hCleanup)=baselines#hookCleanup
	SetWindow $panelStr hook(hCleanup)=baselines#hookCleanup
	
	ShowTab(bls)

	// changes to bls structure will be saved in Initialise() or PrefsButtonProc() function
	return 1
end

// create fit waves and add to plot
static function ResetGraphForTrace(STRUCT BLstruct &bls)
		
	RemoveFromGraph/W=$bls.graph/Z w_display, w_base, w_sub, tangent0, tangent1, w_nodesY
	if (bls.datalength == 0)
		return 0
	endif
		
	wave/Z w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
				
	ResetColors(bls, 1) // set all to grey
	RestoreTraceColor(bls)
	
	DFREF dfr=GetPackageDFREF()
		
	// plot the baseline...
	Duplicate/O w_data dfr:w_base /WAVE=w_base
	FastOp w_base = (NaN)
	AppendToSameAxes(bls.graph, bls.trace, w_base, w_x, matchOffset=1+2*kAllowMuloffset, unique=1)
	
	// ... and the baseline-subtracted result
	Duplicate/O w_data dfr:w_sub /WAVE=w_sub
	FastOp w_sub = (NaN)
	AppendToSameAxes(bls.graph, bls.trace, w_sub, w_x, unique=1, matchOffset=2*kAllowMuloffset)
	
	// make sure cursors report correct axis, clip point range to wave length
	ResetCursorsForSubrange(bls)
		
	switch (bls.tab)
		case 0 : // masked fit: plot masked regions
			ResetDisplayAndMaskWaves(bls)
			wave/SDFR=dfr w_display
			AppendToSameAxes(bls.graph, bls.trace, w_display, $"", w_RGB={0xD5A5,0xDE87,0xFFFF}, unique=1, fill=0.5, offset=-1e9)
			ResetTangentWaves(bls)
			
			if (!bls.multi && cmpstr(bls.fitfunc, "spline")==0 && bls.datalength) // smoothing spline - make a guess for SD
				ResetSD(bls)
			endif
					
			break
		case 1 :
			// set cursors on correct axes
			SetCursorsForManFit(bls)
			break
		case 2 : // auto
			if (!bls.multi)
				ResetDepth(bls) // estimate depth parameter for arc hull baseline
			endif
			
			if (!bls.multi && cmpstr(bls.fitfunc, "spline")==0 && bls.datalength) // smoothing spline - make a guess for SD
				ResetSD(bls)
			endif
			break
		case 3 : // spline, plot nodes
			if (bls.XY  && !isMonotonic(w_x))
				DoAlert 0, "X wave is not monatonic!"
				bls.datalength = 0
			endif
			SetNodes(bls)
			break
	endswitch
	
	ModifyGraph/W=$bls.graph live(w_base)=2
	ModifyGraph/W=$bls.graph live(w_sub)=2
end

// check for monotonic X wave
static function isMonotonic(wave w_x)
	Make/free w_diff
	Differentiate w_x /D=w_diff
	WaveStats/Q/M=0 w_diff
	return !(V_max>0 && V_min<0)
end

 // estimate depth parameter for arc hull baseline
static function ResetDepth(STRUCT BLstruct &bls)
	if (bls.datalength == 0)
		return 0
	endif
	wave/Z w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	int p1 = 0, p2 = numpnts(w_data) - 1
	if (bls.subrange)
		p1 = bls.endp[0]
		p2 = bls.endp[1]
	endif
	WaveStats/Q/M=1/R=[p1,p2] w_data
	bls.depth = (v_max - v_min) * (bls.options & 8 ? -0.15 : 0.15)
	SetVariable svDepth_tab2, win=$bls.graph+"#BL_panel", limits={-Inf,Inf,abs(bls.depth/10)}, value=_NUM:bls.depth
end

// *** control procedures ***

static function BaselineListbox(STRUCT WMListboxAction &s)
	
	if (!(s.eventcode == 1 && s.eventMod & 16)) // mousedown; right click
		return 0
	elseif (s.row>=DimSize(s.listwave, 0) || s.row<0)
		return 0
	endif
	string strMenu = "Copy baseline info to clipboard;"
	strMenu += SelectString(s.col, "", "Copy this value to clipboard;")
		
	PopupContextualMenu strMenu
	if (v_flag == 1)
		wave/Z/SDFR=GetPackageDFREF() w_base
		PutScrapText note(w_base)
	elseif (v_flag == 2)
		PutScrapText s.listWave[s.row][s.col]
	endif
	return 0
end

static function BaselineCheckboxes(STRUCT WMCheckboxAction &s)
	
	if (s.eventCode != 2)
		return 0
	endif
	
	DFREF dfr = GetPackageDFREF()
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct
	
	if (CheckUpdated(bls, 1))
		return 0
	endif
	
	strswitch (s.ctrlName)
		case "chkPeak":
			bls.peak = s.checked
			DoFit(bls)
			break
		case "chkNeg_tab2" :
			bls.options = (bls.options&~8) | 8*s.checked
			bls.depth = -bls.depth
			SetVariable svDepth_tab2, win=$s.win, value=_NUM:bls.depth
			DoFit(bls)
			break
		case "chkHull_tab2" :
			bls.hull = s.checked
			DoFit(bls)
			break
		case "chkRange" :
			if (bls.datalength == 0)
				CheckBox $s.ctrlName win=$s.win, value=0
				bls.subrange = 0
				ResetCursorsForSubrange(bls)
			else
				bls.subrange = s.checked
				if (bls.subrange)
					SetVariable svL win=$s.win, disable=0, value=_NUM:bls.endp[0]
					SetVariable svR win=$s.win, disable=0, value=_NUM:bls.endp[0]
				else
					SetVariable svL win=$s.win, disable=2, value=_STR:""
					SetVariable svR win=$s.win, disable=2, value=_STR:""
				endif
				StructPut bls dfr:w_struct
				ResetCursorsForSubrange(bls)
				DoFit(bls)
			endif
			break
		case "chkEdit_tab3" :
			if (bls.datalength == 0)
				CheckBox $s.ctrlName win=$s.win, value=0
				bls.editMode = 0
			else
				bls.editMode = s.checked
			endif
			SetEditMode(bls)
			break
		case "chkLHS" :
			CheckBox chkRHS win=$s.win, value=!s.checked
			break
		case "chkRHS" :
			CheckBox chkLHS win=$s.win, value=!s.checked
			break
		case "chkCurrentDF" :
			CheckBox chkSourceDF win=$s.win, value=!s.checked
			break
		case "chkSourceDF" :
			CheckBox chkCurrentDF win=$s.win, value=!s.checked
			break
		case "chkFitAll":
			bls.fitall = s.checked
			break
		case "chkInfo" :
			bls.info = s.checked
			ShowBaselineInfo(bls)
			break
	endswitch
	StructPut bls dfr:w_struct
end


static function BaselineButtons(STRUCT WMButtonAction &s)

	// make this button moveable
	if (s.eventcode==1 && cmpstr(s.ctrlname, "btnEdit_graph")==0) // mouse down
		if (IgorVersion() < 8)
			return 0 // code runs too too slowly in Igor 7
		endif
		int buttondown = 0, moved = 0
		variable dx, dy
		Button $s.ctrlName win=$s.win, userdata=""
		do
			GetMouse/W=$s.win
			buttondown = V_flag & 1
			dx = (v_left - s.mouseLoc.h)
			dy = (v_top - s.mouseLoc.v)
			if (buttondown && (dx || dy))
				if (moved == 1)
					moved = 2 // more than one move, assume movement is intentional
					Button $s.ctrlName win=$s.win, userdata="moved"
				endif
				if (!moved)
					moved = 1 // first move - may not be intentional
				endif
				s.mouseLoc.h = v_left
				s.mouseLoc.v = v_top
				Button btnEdit_graph, win=$s.win, pos+={dx,dy}
				DoUpdate/W=$s.win
			endif
		while (buttondown)
		return 0
	endif
	
	if (s.eventCode != 2)
		return 0
	endif
	
	DFREF dfr = GetPackageDFREF()
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct
	
	if (cmpstr(s.ctrlName, "btnDone") && CheckUpdated(bls, 1))
		return 0
	endif
			
	strswitch(s.ctrlName)
		case "btnEdit_graph" :
			// check whether button has been moved
			if (strlen(s.userdata))
				Button $s.ctrlName win=$s.win, userdata=""
				return 0
			endif
			bls.editmode = !bls.editmode
			SetEditMode(bls)
			break
		case "btnSub" :
			if (bls.datalength == 0)
				DoAlert 0, "Nothing to subtract"
				return 0
			endif
			if (bls.fitall && bls.tab!=1)
				FitAll(bls)
			else
				SubtractBaseline(bls)
			endif
			break
		case "btnClear_tab0" :
			SetBaselineRegion(-Inf, Inf, 0)
			break
		case "btnAdd_graph" :
		case "btnRemove_graph" :
		case "btnAdd_tab0" :
		case "btnRemove_tab0" :
			// add or remove fit region
			int add = stringmatch(s.ctrlName, "btnAdd*")
			if (MaskAddOrRemoveSelection(add) == 0)
				DoAlert 0, "first use marquee to select region on graph"
			endif
			break
		case "btnResetCsrs_tab1" :
			ResetCursorsForManFit(bls)
			DoFit(bls)
			break
		case "btnLoadNodes_tab3" :
			LoadNodes(bls)
			break
		case "btnResetNodes_tab3" :
			if (s.eventmod & 2) // shift-click places nodes on trace
				SetNodes(bls, onTrace = 1)
			else
				ResetNodes(bls)
			endif
			break
		case "btnDone" :
			KillWindow/Z $s.win
			// just to make sure
			PrefsSave(bls)
			ClearGraph(bls, 0)
			KillDataFolder/Z GetPackageDFREF()
			return 0
			break
		case "btnHelp" :
//			help()
			OpenHelp/INT=0/Z ParseFilePath(1, FunctionPath(""), ":", 1, 0) + "Baselines Help.ihf"
			DisplayHelpTopic/K=1/Z "How to use Baselines for Igor Pro"
			DoIgorMenu "Control", "Retrieve Window"
			break
		case "btnExportNodes_tab3" :
			ExportNodes("")
			break
		case "btnBLInfo" :
			bls.info = !bls.info
			ShowBaselineInfo(bls)
			break
		case "btnInfo" :
			InfoMenu()
			break
	endswitch
	
	StructPut bls dfr:w_struct
	return 0
end

static function BaselineSetvars(STRUCT WMSetVariableAction &s)
	
	STRUCT BLstruct bls
	
	variable DefaultIncrement = 10 // % of value
	variable FastIncrement = 30
	variable SlowIncrement = 1
	
	switch (s.eventCode)
		#if IgorVersion() >= 9
		case 9 : // mousedown, Igor 9+
			if (s.mousepart == 1 || s.mousepart == 2)
				variable increment = DefaultIncrement / 100 * abs(s.dval) // default: set increment to 10% of value
				if (s.eventmod & 2) // shift -> 30%
					increment = FastIncrement / 100 * abs(s.dval)
				elseif (s.eventmod & 4) // option/alt -> 1%
					increment = SlowIncrement / 100 * abs(s.dval)
				endif
				increment = increment == 0 ? 1 : increment
				
				if (cmpstr(s.ctrlName, "svSD") == 0)
					SetVariable $s.ctrlName win=$s.win, limits={0, Inf, increment}
				elseif (cmpstr(s.ctrlName, "svDepth_tab2") == 0)
					SetVariable $s.ctrlName win=$s.win, limits={-Inf, Inf, increment}
				endif
			endif
			break
		#endif
		case 7: // begin edit
			if (cmpstr((s.ctrlName)[0,4], "svARS")==0) // svARSits_tab2 or svARSsd_tab2
				wave/SDFR=GetPackageDFREF() w_struct
				StructGet bls w_struct
				if (CheckUpdated(bls, 1))
					return 0
				endif
				ShowARSgraph(bls, 1)
			endif
			break
		case 8 : // update
		case 1 : // mouseup
			wave/SDFR=GetPackageDFREF() w_struct
			StructGet bls w_struct
			if (CheckUpdated(bls, 1))
				return 0
			endif
			
			strswitch (s.ctrlName)
				case "svCycles_tab1" :
					bls.cycles = s.dval // ensure that displayed value is an integer
					SetVariable svCycles_tab1 win=$s.win, value=_NUM:bls.cycles
					DoFit(bls)
					break
				case "svPoly" :
					bls.polyorder = s.dval // ensure that displayed value is an integer
					SetVariable svPoly win=$s.win, value=_NUM:bls.polyorder
					if (bls.tab == 1)
						SetCursorsForManFit(bls)
					endif
					DoFit(bls)
					break
				case "svSD" :
					#if IgorVersion() < 9
					SetvarPercentageIncrement(s, DefaultIncrement, SlowIncrement, FastIncrement) // resets control value and s.dval
					SetVariable $s.ctrlName win=$s.win, userdata=num2str(s.dval) // keep track of value, however it is changed
					#endif
					bls.sd = s.dval
					DoFit(bls)
					break
				case "svChebOrder" :
					bls.cheborder = s.dval
					SetVariable $s.ctrlName win=$s.win, value=_NUM:bls.cheborder
					DoFit(bls)
					break
				case "svL_tab0" :
				case "svR_tab0" :
					if (bls.datalength == 0)
						SetVariable $s.ctrlName win=$s.win,value=_STR:""
						return 0
					endif
					if (cmpstr(s.ctrlName, "svR_tab0")==0)
						bls.roi.right = s.dval
					else
						bls.roi.left = s.dval
					endif
					SetVariable $s.ctrlName win=$s.win,value=_STR:SelectString(numtype(s.dval)==0, "", num2str(s.dval))
					MarqueeSetAtSetvarValues(bls) // set marquee in host window
					break
				case "svDepth_tab2" :
					#if IgorVersion() < 9
					SetvarPercentageIncrement(s, DefaultIncrement, SlowIncrement, FastIncrement) // resets control value and s.dval
					SetVariable $s.ctrlName win=$s.win, userdata=num2str(s.dval)
					#endif
					bls.depth = s.dval
					DoFit(bls)
					break
				case "svSmooth_tab2" :
					bls.smoothing = s.dval
					SetVariable $s.ctrlName win=$s.win,value=_NUM:bls.smoothing // set to integer value
					DoFit(bls)
					break
				case "svARSits_tab2" :
				case "svARSsd_tab2" :
					if (cmpstr(s.ctrlName, "svARSits_tab2") == 0)
						bls.arsits = s.dval
					else
						bls.arssd = s.dval
					endif
					if (WinType(s.win+"#g0") == 1) // just in case
						Cursor/N=1/F/H=1/W=$s.win+"#g0" A dummy bls.arsits, bls.arssd
					endif
					DoFit(bls)
					break
				case "svL" :
					bls.csr.C.x = s.dval
					Cursor/F/W=$bls.graph/N=1 C $bls.trace bls.csr.C.x, 0
					GetPointsFromCursors(bls)
					DoFit(bls)
					break
				case "svR" :
					bls.csr.D.x = s.dval
					Cursor/F/W=$bls.graph/N=1 D $bls.trace bls.csr.D.x, 0
					GetPointsFromCursors(bls)
					DoFit(bls)
					break
				case "svF_tab3" :
					bls.flagF = s.dval
					DoFit(bls)
					break
				case "svBLsuff" :
					if (strlen(s.sval)==0) // don't allow an empty string value
						SetVariable $s.ctrlName, win=$s.win, value=_STR:bls.blsuff
					endif
					break
				case "svsubsuff" :
					if (strlen(s.sval)==0) // don't allow an empty string value
						SetVariable $s.ctrlName, win=$s.win, value=_STR:bls.subsuff
					endif
					break
				case "svKeyplus" :
					if (strlen(s.sval)!=1) // don't allow an empty string value
						SetVariable $s.ctrlName, win=$s.win, value=_STR:"+"
					endif
					break
				case "svKeyminus" :
					if (strlen(s.sval)!=1) // don't allow an empty string value
						SetVariable $s.ctrlName, win=$s.win, value=_STR:"-"
					endif
					break
			endswitch
			StructPut bls w_struct
			// end of events 1 and 8
	endswitch
	
	return 0
end

// for Igor versions older than 9
static function SetvarPercentageIncrement(STRUCT WMSetVariableAction &s, variable normal, variable option, variable shift)
	if (s.eventCode != 1)
		return 0
	endif
	
	variable pc = normal
	if (s.eventmod & 4)
		pc = option
	elseif (s.eventmod & 2)
		pc = shift
	endif

	variable oldValue = str2num(s.userdata)
	oldValue = numtype(oldValue) == 0 ? oldValue : 1
	
	variable direction = 1 - 2 * (s.dval < oldValue)
	variable newValue = oldValue + direction * pc / 100 * abs(oldValue != 0 ? oldValue : s.dval - oldValue)
	
	SetVariable $s.ctrlName, win=$s.win, value=_NUM:newValue
	s.dval = newValue
	return 0
end

// *** mask functions ***

// 'clear all' button fires SetBaselineRegion()
// '+' & '-' buttons fire MaskAddOrRemoveSelection() -> SetBaselineRegion()
// selecting a trace fires ResetGraphForTrace() -> ResetDisplayAndMaskWaves()

// resets display and mask waves based on w_regions and selected trace
static function ResetDisplayAndMaskWaves(STRUCT BLstruct &bls)
	DFREF dfr = GetPackageDFREF()
	wave/Z/SDFR=dfr w_display, w_regions
	
	wave/Z w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	if (bls.datalength==0 || WaveExists(w_data)==0)
		return 0
	endif
	
	Duplicate/O w_data dfr:w_mask /WAVE=w_mask
	FastOp w_mask = 0
	Redimension/N=(0,2) w_display
	
	int numRegions = DimSize(w_regions, 0)
	if (numRegions)
		Make/free/N=(numRegions) dummy
		dummy = SetRangeInMaskWave(1, w_regions[p][0], w_regions[p][1], w_mask, w_data, w_x)
		dummy = SetRangeInDisplayWave(w_display, w_regions[p][0], w_regions[p][1])
	endif
	return 1
end

// reset baseline region selected by marquee
static function MaskAddOrRemoveSelection(int add)
	DFREF dfr = GetPackageDFREF()
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct
			
	if ((numtype(bls.roi.left) + numtype(bls.roi.right)) == 0)
		variable success = SetBaselineRegion(bls.roi.left, bls.roi.right, add)
		if ((bls.history&2) && success)
			printf "SetBaselineRegion(%g, %g, %d)\r", bls.roi.left, bls.roi.right, add
		endif
		ClearMarquee(bls) // clears marquee, buttons, roi
		StructPut bls dfr:w_struct
		return 1
	endif
	return 0
end

// set region between x1 and x2 to value; value = 1 to include, 0 to exclude.
// can be used from commandline.
function SetBaselineRegion(variable x1, variable x2, int value)
	DFREF dfr = GetPackageDFREF()
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct
	
	wave/Z/SDFR=dfr w_regions, w_mask, w_display
	wave/Z w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	
	if (bls.datalength==0 || WaveExists(w_data)==0)
		return 0
	elseif (numpnts(w_mask) != numpnts(w_data))
		return 0
	endif
	
	SetRangeInRegionWave(value, x1, x2, w_regions)
	ResetDisplayWave(w_regions, w_display)
	SetRangeInMaskWave(value, x1, x2, w_mask, w_data, w_x)
	
	DoFit(bls)
	return 1
end

static function SetRangeInRegionWave(int add, variable x1, variable x2, wave regions)
	int i, numP
	variable xHigh = max(x1, x2)
	variable xLow = min(x1, x2)
	if (add)
		regions[DimSize(regions, 0)][] = {{xLow},{xHigh}}
		SortColumns/KNDX={0,1} sortwaves={regions}
		for (i=DimSize(regions,0)-1;i>0;i-=numP)
			numP = 1
			WaveStats/Q/RMD=[0,i-1][1,1]/M=1 regions
			if (V_max >= regions[i][0]) // join overlapping regions
				regions[V_maxRowLoc][1] = max(regions[V_maxRowLoc][1], regions[i][1])
				numP = i - V_maxRowLoc
				DeletePoints/M=0 V_maxRowLoc+1, numP, regions
			endif
		endfor
	else // remove range from regions wave
		for (i=DimSize(regions,0)-1;i>=0;i--)
			if (xHigh < regions[i][0] || xLow > regions[i][1])
				continue
			elseif (xLow <= regions[i][0] && xHigh >= regions[i][1])
				DeletePoints/M=0 i, 1, regions
			elseif (xLow > regions[i][0] && xHigh < regions[i][1])
				InsertPoints/M=0 i+1, 1, regions
				regions[i+1][1] = regions[i][1]
				regions[i+1][0] = xHigh
				regions[i][1] = xLow
			elseif (xLow > regions[i][0])
				regions[i][1] = xLow
			elseif (xHigh < regions[i][1])
				regions[i][0] = xHigh
			endif
		endfor
	endif
	return 1
end

// clears and resets w_display to match selection stored in w_regions
static function ResetDisplayWave(wave w_regions, wave w_display)
	Redimension/N=(0,2) w_display
	int numRegions = DimSize(w_regions, 0)
	if (numRegions)
		Make/free/N=(numRegions) dummy
		dummy = SetRangeInDisplayWave(w_display, w_regions[p][0], w_regions[p][1])
	endif
end

static function SetRangeInDisplayWave(wave w_display, variable x1, variable x2)
	w_display[DimSize(w_display, 0)][] = {{x1, x2, NaN},{Inf, Inf, NaN}}
	return 1
end

static function SetRangeInMaskWave(variable value, variable x1, variable x2, wave w_mask, wave w_data, wave/Z w_x)
	variable xlow = min(x1, x2), xhigh = max(x1, x2)
	
	// figure out the maximum point range
	// helps speed things up for large waves with many fit regions
	variable p1, p2, pLow, pHigh, lastpnt
	lastpnt = numpnts(w_data) - 1
	p1 = WaveExists(w_x) ? GetPointFromXwave(w_x, x1) : x2pnt(w_data, x1)
	p2 = WaveExists(w_x) ? GetPointFromXwave(w_x, x2) : x2pnt(w_data, x2)
	// x2pnt() gives the nearest point to x, GetPointFromXwave() gives crossing point
	// in either case end points in range could be one of the adjacent points
	pLow = limit(min(p1, p2) - 1, 0, lastpnt)
	pHigh = limit(max(p1, p2) + 1, 0, lastpnt)
		
	if (value)
		if ((pHigh-pLow) < 10)
			if (WaveExists(w_x))
				w_mask[pLow,pHigh] = w_mask || (w_x[p] == limit(w_x[p], xLow, xHigh))
			else
				w_mask[pLow,pHigh] = w_mask || (pnt2x(w_data, p) == limit(pnt2x(w_data, p), xLow, xHigh))
			endif
		else
			w_mask[pLow+3,pHigh-3] = 1
			if (WaveExists(w_x))
				w_mask[pLow,pLow+2]   = w_mask || (w_x[p] == limit(w_x[p], xLow, xHigh))
				w_mask[pHigh-2,pHigh] = w_mask || (w_x[p] == limit(w_x[p], xLow, xHigh))
			else
				w_mask[pLow,pLow+2]   = w_mask || (pnt2x(w_data, p) == limit(pnt2x(w_data, p), xLow, xHigh))
				w_mask[pHigh-2,pHigh] = w_mask || (pnt2x(w_data, p) == limit(pnt2x(w_data, p), xLow, xHigh))
			endif
		endif
	else // set points to zero
		if ((pHigh-pLow) < 10)
			if (WaveExists(w_x))
				w_mask[pLow,pHigh] = w_mask && (w_x[p] != limit(w_x[p], xLow, xHigh))
			else
				w_mask[pLow,pHigh] = w_mask && (pnt2x(w_data, p) != limit(pnt2x(w_data, p), xLow, xHigh))
			endif
		else
			w_mask[pLow+3,pHigh-3] = 0
			if (WaveExists(w_x))
				w_mask[pLow,pLow+2]   = w_mask && (w_x[p] != limit(w_x[p], xLow, xHigh))
				w_mask[pHigh-2,pHigh] = w_mask && (w_x[p] != limit(w_x[p], xLow, xHigh))
			else
				w_mask[pLow,pLow+2]   = w_mask && (pnt2x(w_data, p) != limit(pnt2x(w_data, p), xLow, xHigh))
				w_mask[pHigh-2,pHigh] = w_mask && (pnt2x(w_data, p) != limit(pnt2x(w_data, p), xLow, xHigh))
			endif
		endif
	endif
	return 1
end

static function MakeARSgraph(STRUCT BLstruct &bls)
	
	wave/SDFR=GetPackageDFREF() dummy
	
	string panelStr = bls.graph + "#BL_panel"
	string graphStr = panelStr + "#g0"
	
	KillWindow/Z $graphStr
	Display/HOST=$panelStr/FG=(gLeft, gTop, gRight, gBottom)/N=g0 dummy
	ModifyGraph/W=$graphStr margin(left)=1,margin(top)=1,margin(right)=1,margin(bottom)=1
	ModifyGraph/W=$graphStr hideTrace=2, grid=1, log=1, mirror=1, standoff=0, axThick=0.1
	SetAxis/W=$graphStr left 1,100
	SetAxis/W=$graphStr bottom 1,100
	Cursor/N=1/F/H=1/W=$graphStr A dummy bls.arsits, bls.arssd

	SetVariable svSmooth_tab2, win=$panelStr, disable=1
	CheckBox chkNeg_tab2, win=$panelStr, disable=1
	CheckBox chkHull_tab2, win=$panelStr, disable=1
end

// shows or hides the info display based on the value of bls.info
static function ShowBaselineInfo(STRUCT BLstruct &bls)

	string panelStr = bls.graph + "#BL_panel"
	variable panelW = 205, panelH = 370 + 60 * bls.info // control panel units
	

	if (NumberByKey("BUILD", IgorInfo(0))<56466 && ScreenResolution > 96)
		// panelW and panelH units should be points or cpu - they are equivalent at this screenresolution
		variable F = ScreenResolution / 72
		panelW *= F
		panelH *= F // unexpanded pixels. not points, not cpu, and not necessarily pixels!
	endif
	if (bls.options & 0x40)	// panel on left
		MoveSubwindow/W=$panelStr fnum=(panelW,0,0,panelH)
	else
		MoveSubwindow/W=$panelStr fnum=(0,0,panelW,panelH)
	endif
	// units for control positions are control panel units
	CheckBox chkFitAll, win=$panelStr, pos={25,342+60*bls.info}
	Button btnSub, win=$panelStr, pos={122.5,340+60*bls.info}
	CheckBox chkInfo, win=$panelStr, value=bls.info
	ListBox listInfo, win=$panelStr, disable=!bls.info
	
	string strTitle = selectstring(bls.info, "show baseline info", "hide baseline info")
	Button btnBLInfo, win=$panelStr, title=strTitle //disable=bls.info
	
	if (bls.info)
		DFREF dfr = GetPackageDFREF()
		wave/SDFR=GetPackageDFREF() listwave, w_base
		UpdateListwave(note(w_base), listwave)
	endif
end

static function ShowARSgraph(STRUCT BLstruct &bls, int show)
	string panelStr = bls.graph + "#BL_panel"
	string graphStr = panelStr + "#g0"
	
	
	if (show && WinType(graphStr)!=1)
		MakeARSgraph(bls)
		SetWindow $panelStr hook(hARS)=baselines#HookARS
	elseif (show == 0)
		KillWindow/Z $graphStr
		SetWindow $panelStr hook(hARS)=$""
	endif
end

static function HookARS(STRUCT WMWinHookStruct &s)
		
	if (s.eventCode!=7 && s.eventCode!=5)
		return 0
	endif
		
	STRUCT BLstruct bls
	wave/SDFR=GetPackageDFREF() w_struct
	StructGet bls w_struct
	
	if (s.eventCode == 5) // mouseup
		GetWindow/Z $s.winName+"#g0" wsizeDC
		if (V_flag == 0)
			if (s.mouseloc.h<v_left || s.mouseloc.h>v_right || s.mouseloc.v<v_top || s.mouseloc.v>v_bottom)
				KillWindow /Z $s.winName+"#g0"
				SetWindow $s.winName hook(hARS)=$""
				CheckBox chkNeg_tab2, win=$s.winName, disable=(bls.tab != 2)
				CheckBox chkHull_tab2, win=$s.winName, disable=(bls.tab != 2)
				SetVariable svSmooth_tab2, win=$s.winName, disable=(bls.tab != 2)
			endif
		endif
		return 0
	endif
	
	int newiterations = limit(round(hcsr(a, s.winName)), 1, 100)
	variable newsd = limit(round(vcsr(a, s.winName)), 1, 100)
	
	if (newiterations==bls.arsits && newsd==bls.arssd)
		return 0
	endif
	bls.arsits = newiterations
	bls.arssd = newsd
	
	string panelStr = bls.graph + "#BL_panel"
	SetVariable svARSsd_tab2, win=$panelStr, value=_NUM:bls.arssd
	SetVariable svARSits_tab2, win=$panelStr, value=_NUM:bls.arsits
	
	DoFit(bls)
	
	StructPut bls w_struct
	return 0
end

// this hook is set for both graph and panel windows
static function hookCleanup(STRUCT WMWinHookStruct &s)
	if (s.eventCode == 2) // kill
		wave/SDFR=GetPackageDFREF() w_struct
		STRUCT BLstruct bls
		StructGet bls w_struct
		
		if (WinType("BaselinesPrefsPanel") == 7 || bls.rebuild)
			return 0
		endif
		
		if (!stringmatch(s.winName, "*#BL_panel"))
			KillWindow/Z $s.winName + "#BL_panel"
		endif

		PrefsSave(bls)
		ClearGraph(bls, 0)
		KillDataFolder/Z GetPackageDFREF()

	endif
	return 0
end

static function BaselinePopups(STRUCT WMPopupAction &s)
	
	if (s.eventCode == -1)
		return 0
	endif
		
	wave/SDFR=GetPackageDFREF() w_struct
	STRUCT BLstruct bls
	StructGet bls w_struct
	
	if (s.eventcode==2 && CheckUpdated(bls, 0))
		return 0
	endif
	
	int hover = 0
	
	switch (s.eventCode)
		case 3 : // hover
			if (IgorVersion() < 9)
				return 0
			endif
			if (cmpstr(s.ctrlName, "popTrace") == 0)
				bls.trace = s.popstr
				if (strlen(bls.trace))
					SelectTrace(bls)
				endif
				// don't try to update fit here
				// resetting mask regions will look up wrong trace name
				break
			endif
			hover = 1
		case 4: // dismissed without selection (Igor 9)
		case 2: // mouseup
			
			strswitch (s.ctrlName)
				case "popTrace" :
					bls.trace = s.popstr
					SetTraceProperties(bls)
					ResetGraphForTrace(bls)
					if (bls.tab != 3) // resetting nodes triggers fit
						DoFit(bls)
					endif
					break
				case "popType" :
					bls.type[bls.tab] = s.popNum - 1
//					SetFitFunc(bls) // store the name of the selected fit function in bls
					bls.fitfunc = s.popstr // much faster!
					ResetGraphForType(bls)
					ResetPanelForType(bls)
					bls.quickpop = hover
					DoFit(bls)
					bls.quickpop = 0
					StructPut bls w_struct // even if no trace is selected we want to save the current selection
					break
				case "popPlanck" :
					bls.wavelength = s.popNum
					DoFit(bls)
					StructPut bls w_struct
					break
			endswitch
						
			break
	endswitch
	
	StructPut bls w_struct
	return 0
end

static function BaselineTabs(STRUCT WMTabControlAction &s)
	
	wave/SDFR=GetPackageDFREF() w_struct
	STRUCT BLstruct bls
	StructGet bls w_struct
		
	if (s.eventCode == 2) // tab selection
	
		if (CheckUpdated(bls, 1))
			return 0
		endif
		
		bls.tab = s.tab
		SetFitFunc(bls)
		StructPut bls w_struct
		ResetGraphForTrace(bls)
		ResetGraphForType(bls)
		ShowTab(bls)
		DoFit(bls)
		ClearMarquee(bls)
		StructPut bls w_struct
	endif
		
	return 0
end

//// resets values of controls based on bls
//// after executing this function must call ShowTab()
//// the fit function popup selection and controls' visibility
//// are set by calling ShowTab()
//static function SetMainPanelControlValues(STRUCT BLstruct &bls)
//	string panelStr = bls.graph + "#BL_panel"
//
//	PopupMenu popTrace, win=$panelStr, popmatch=bls.trace
//	TabControl tabs, win=$panelStr, value=bls.tab
//
////  popType will be reset in ResetPanelForType
////	PopupMenu popType, win=$panelStr, ...
//
//	SetVariable svSD, win=$panelStr, value=_NUM:bls.sd
//	SetVariable svCycles_tab1, win=$panelStr, value=_NUM:bls.cycles
//	SetVariable svDepth_tab2, win=$panelStr, value=_NUM:bls.depth
//	SetVariable svARSits_tab2, win=$panelStr, value=_NUM:bls.arsits
//	SetVariable svARSsd_tab2, win=$panelStr, value=_NUM:bls.arssd
//	SetVariable svF_tab3, win=$panelStr, value=_NUM:bls.flagF
//	SetVariable svPoly, win=$panelStr, value=_NUM:bls.polyorder
//	SetVariable svChebOrder, win=$panelStr, value=_NUM:bls.cheborder
//	CheckBox chkPeak, win=$panelStr, value=bls.peak
//	PopupMenu popPlanck, win=$panelStr, mode=bls.wavelength
//	SetVariable svSmooth_tab2, win=$panelStr, value=_NUM:bls.smoothing
//	CheckBox chkNeg_tab2, win=$panelStr, value=bls.options&8
//	CheckBox chkHull_tab2, win=$panelStr, value=bls.hull
//	CheckBox chkEdit_tab3, win=$panelStr, value=bls.editmode
//	CheckBox chkRange, win=$panelStr, value=bls.subrange
//	if (bls.subrange)
//		SetVariable svL, win=$panelStr, value=_NUM:bls.csr.C.x, disable=0
//		SetVariable svR, win=$panelStr, value=_NUM:bls.csr.D.x, disable=0
//	else
//		SetVariable svL win=$panelStr, disable=2, value=_STR:""
//		SetVariable svR win=$panelStr, disable=2, value=_STR:""
//	endif
//	CheckBox chkFitAll, win=$panelStr, value=bls.fitall
//
//end

// synchronize panel with values passed in bls structure
static function ResetPanelAndGraph(STRUCT BLstruct &bls)
	
//	SetMainPanelControlValues(bls)
		
	wave/SDFR=GetPackageDFREF() w_struct
	SetFitFunc(bls)
	bls.rebuild = 1 // prevent cleanup of package folder when panel is killed
	StructPut bls w_struct
	
	// rebuild the panel to sync controls
	MakeBaselinesPanel(bls)
//	ShowBaselineInfo(bls)
	bls.rebuild = 0
	bls.multi = 1 // prevent depth and sd from being reset
	ResetGraphForTrace(bls)
	ResetGraphForType(bls)
	bls.multi = 0
	DoFit(bls)

	StructPut bls w_struct
end
 
// reset popType list and selection, enable and disable controls based on tab
static function ShowTab(STRUCT BLstruct &bls)
	
	string panelStr = bls.graph + "#BL_panel"
	SetActiveSubwindow $panelStr
	ModifyControlList/Z ControlNameList(panelStr,";","*_tab0"), win=$panelStr, disable=(bls.tab!=0)
	ModifyControlList/Z ControlNameList(panelStr,";","*_tab1"), win=$panelStr, disable=(bls.tab!=1)
	ModifyControlList/Z ControlNameList(panelStr,";","*_tab2"), win=$panelStr, disable=(bls.tab!=2)
	ModifyControlList/Z ControlNameList(panelStr,";","*_tab3"), win=$panelStr, disable=(bls.tab!=3)
	RedrawPicture(bls)
	ShowARSgraph(bls, 0)
		
	CheckBox chkFitAll, win=$panelStr, disable = 1*(bls.tab == 1)
	
	ControlInfo/W=$bls.Graph btnEdit_graph
	if (v_flag)
		Button btnEdit_graph, win=$bls.Graph, disable=bls.tab!=3
	endif
		
	string types = ""
	switch (bls.tab)
		case 0:
			types = ksMaskedTypes + GetListOfUserFuncs()
			break
		case 1:
			types = ksManTypes
			break
		case 2:
			types = ksAutoTypes + GetListOfUserFuncs()
			break
		case 3:
			types = ksSplineTypes
			break
	endswitch
	
	PopupMenu popType, win=$panelStr, value=#("\"" + types + "\"")
	PopupMenu popType, win=$panelStr, popmatch=StringFromList(bls.type[bls.tab], types)
	
	ResetPanelForType(bls)
end

// returns truth that this procedure file has been updated since initialisation
static function CheckUpdated(STRUCT BLstruct &bls, int restart)
	int version = GetThisVersion()
	if (bls.version != version)
		if (restart)
			DoAlert 0, "You have updated the baseline fitting package since this panel was created.\r\rThe package will restart to update the control panel."
			QuitBaselines(bls)
			Initialise()
		else
			DoAlert 0, "You have updated the baseline fitting package since this panel was created.\r\rPlease close any open baselines control panels and reopen to continue."
		endif
		return 1
	endif
	return 0
end

// for testing
static function blsVersion()
	DFREF dfr = GetPackageDFREF()
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct
	return bls.version
end

static function RepositionMarquee(STRUCT BLstruct &bls)
	GetMarquee/W=$bls.graph
	if (v_flag)
		MarqueeSetAtSetvarValues(bls)
	else
		ClearMarquee(bls)
	endif
end

// set the marquee to the range entered in panel setvars
static function MarqueeSetAtSetvarValues(STRUCT BLstruct &bls)
	if (bls.tab != 0)
		return 0
	endif
	if ((numtype(bls.roi.left + bls.roi.right)) == 0)
		string s_info = TraceInfo(bls.graph, bls.trace, 0)
		string s_Xax = StringByKey("XAXIS", s_info)
		string s_Yax = StringByKey("YAXIS", s_info)

		GetMarquee/W=$bls.graph/Z
		if (v_flag == 0)
			GetAxis/W=$bls.graph/Q $s_Yax
			bls.roi.top    = v_max
			bls.roi.bottom = v_min
		endif
		variable vL = bls.roi.left, vR = bls.roi.right
		variable vT = bls.roi.top, vB = bls.roi.bottom
		
		#if (IgorVersion() >= 9)
		SetMarquee/W=$bls.graph/HAX=$s_Xax/VAX=$s_Yax vL, vT, vR, vB
		#else
		vL = PosFromAxisVal(bls.graph, s_Xax, vL)
		vR = PosFromAxisVal(bls.graph, s_Xax, vR)
		vT = PosFromAxisVal(bls.graph, s_Yax, vT)
		vB = PosFromAxisVal(bls.graph, s_Yax, vB)
		SetMarquee/W=$bls.graph vL, vT, vR, vB
		#endif
		
		// position buttons
		GetMarquee/W=$bls.graph // units are points
		SetMarqueeButtons(bls, V_left, V_top, V_right, V_bottom)
	else
		SetMarquee/W=$bls.graph 0, 0, 0, 0
		KillControl/W=$bls.Graph btnAdd_graph
		KillControl/W=$bls.Graph btnRemove_graph
	endif
end

static function PosFromAxisVal(string Graph, string axis, variable value)
	variable pixel = PixelFromAxisVal(Graph, axis, value)
	variable resolution = ScreenResolution
	return resolution > 96 ? pixel * 72/resolution : pixel
end

// vL, vB, vR, vT in points
static function SetMarqueeButtons(STRUCT BLstruct &bls, variable vL, variable vT, variable vR, variable vB)
	
	variable res = ScreenResolution
	
	if (res <= 96) // points -> pixels
		variable PixPerPnt = res/72
		vL *= PixPerPnt
		vT *= PixPerPnt
		vR *= PixPerPnt
		vB *= PixPerPnt
	endif
	
	variable height = abs(vB - vT)
	variable buttonsize = 30
	variable font = 30
	Button btnAdd_graph, win=$bls.Graph, pos={vR+4,vT+(height-buttonsize)/2}, size={buttonsize,buttonsize}, fSize=font, title="\sa-10+", fColor=(0xBFFF,0xFFFF,0xBFFF), focusRing=0
	Button btnAdd_graph, win=$bls.Graph, Proc=Baselines#BaselineButtons
	Button btnRemove_graph, win=$bls.Graph, pos={vL-buttonsize-4,vT+(height-buttonsize)/2}, size={buttonsize,buttonsize}, fSize=font, title="\sa-10-", fColor=(0xFFFF,0xBFFF,0xBFFF), focusRing=0
	Button btnRemove_graph, win=$bls.Graph, Proc=Baselines#BaselineButtons
	#if (IgorVersion() >= 9)
	Button btnAdd_graph, win=$bls.Graph, Picture=baselines#transparent, labelBack=(0xFFFF,0xFFFF,0xFFFF,0), title="+"
	Button btnRemove_graph, win=$bls.Graph, Picture=baselines#transparent, labelBack=(0xFFFF,0xFFFF,0xFFFF,0), title="-"
	#endif
	return 1
end

static function FitAll(STRUCT BLstruct &bls)
	string listStr = GetTraceList(bls)
	if (!ItemsInList(listStr))
		DoAlert 0, "No traces to fit"
		return 0
	elseif (ItemsInList(listStr) == 1)
		SubtractBaseline(bls)
		return 0
	endif
	
	if ((bls.options&0x80) == 0)
		string msg = "Subtract baseline from all traces using current settings?\r"
		msg += "Existing baselines will be overwritten!"
		DoAlert 1, msg
		if (v_flag == 2)
			return 0
		endif
	endif

	string savTrace = bls.trace
	bls.multi = 1 // used to prevent any parameters being reset as we cycle through traces
	
	int i
	for(i=0;i<ItemsInList(listStr);i+=1)
		bls.trace = StringFromList(i, listStr)
		SetTraceProperties(bls)
		if (bls.tab == 3)
			SetNodes(bls)
		endif
		ResetGraphForTrace(bls)
		if (DoFit(bls))
			SubtractBaseline(bls)
		else
			Print "Baselines all in one failed to fit " + bls.trace
		endif
	endfor
	bls.trace = savTrace
	SetTraceProperties(bls)
	ResetGraphForTrace(bls)
	PopupMenu/Z popTrace, win=$bls.graph+"#BL_panel", popmatch=savTrace
	DoFit(bls)
	bls.multi = 0
end

// type specific settings - disable controls depending on type selesction
static function ResetPanelForType(STRUCT BLstruct &bls)
	string panelStr = bls.graph + "#BL_panel"
	
	// deal with controls that appear in one tab
	switch (bls.tab)
		case 0:
			break
		case 1:
			RedrawPicture(bls)
			SetVariable svCycles_tab1, win=$panelStr, disable=(cmpstr(bls.fitfunc, "sin")!=0)
			break
		case 2:
			int isArcHull = (cmpstr(bls.fitfunc, "arc hull")==0 || cmpstr(bls.fitfunc, "hull spline")==0)
			SetVariable svDepth_tab2, win=$panelStr, disable=!isArcHull
			CheckBox chkHull_tab2, win=$panelStr, disable=2*isArcHull
			CheckBox chkNeg_tab2, win=$panelStr, disable=0
			SetVariable svARSits_tab2, win=$panelStr, disable=(cmpstr(bls.fitfunc, "ARS")!=0)
			SetVariable svARSsd_tab2, win=$panelStr, disable=(cmpstr(bls.fitfunc, "ARS")!=0)
			SetVariable svSmooth_tab2, win=$panelStr, disable=0
			ShowARSgraph(bls, 0)
			break
		case 3:
			SetVariable svF_tab3, win=$panelStr, disable=(cmpstr(bls.fitfunc, "smoothing")!=0)
			SetEditMode(bls)
			break
	endswitch
	
	// deal with controls that appear in multiple tabs
	if (cmpstr(bls.fitfunc, "poly") != 0)
		SetVariable svPoly, win=$panelStr, disable=1
	elseif (bls.tab == 1) // limit poly order to 5
		bls.polyorder = min(5, bls.polyorder)
		SetVariable svPoly, win=$panelStr, disable=0, limits={3, 5, 1}, value=_NUM:bls.polyorder
	else
		SetVariable svPoly, win=$panelStr, disable=0, limits={3, 20, 1}
	endif
	
	SetVariable svChebOrder, win=$panelStr, disable=(cmpstr((bls.fitfunc)[0,4], "Cheby")!=0)//, value=_NUM:bls.cheborder
		
	if (bls.tab == 0 || bls.tab == 2)
		strswitch (bls.fitfunc)
			case "gauss":
			case "lor":
			case "voigt":
			case "sin":
			case "sigmoid":
			case "exp":
			case "dblexp":
			case "dblexp_peak":
			case "hillequation":
			case "power":
			case "log":
			case "lognormal":
				CheckBox chkPeak, win=$panelStr, disable=0
				break
			default:
				CheckBox chkPeak, win=$panelStr, disable=1
		endswitch
		PopupMenu popPlanck, win=$panelStr, disable=(cmpstr(bls.fitfunc, "Planck") != 0)
		SetVariable svSD, win=$panelStr, disable=(cmpstr(bls.fitfunc, "spline") != 0)
	else
		CheckBox chkPeak, win=$panelStr, disable=1
		PopupMenu popPlanck, win=$panelStr, disable=1
		SetVariable svSD, win=$panelStr, disable=1
	endif
	
end

static function RedrawPicture(STRUCT BLstruct &bls)
	
	string panelStr = bls.graph + "#BL_panel"
	DrawAction/L=ProgBack/W=$panelStr getgroup=ManPic, delete
	
	if (bls.tab != 1)
		return 0
	endif
	
	SetDrawLayer/W=$panelStr ProgBack
	SetDrawEnv/W=$panelStr gstart, gname=ManPic
	string picName = "baselines#p" + ReplaceString(" ", bls.fitfunc, "_")
	variable scale = ScreenResolution > 72 ? 0.3 * ScreenResolution / 72 : 0.3
	DrawPICT/W=$panelStr 45, 150, scale, scale, $picName
	SetDrawEnv/W=$panelStr gstop, gname=ManPic
end

// sets the graph up for given type of baseline
static function ResetGraphForType(STRUCT BLstruct &bls)
	
	if (bls.tab != 1)
		Cursor/K/W=$bls.graph F
		Cursor/K/W=$bls.graph G
		Cursor/K/W=$bls.graph H
		Cursor/K/W=$bls.graph I
		Cursor/K/W=$bls.graph J
	endif
		
	switch (bls.tab)
		case 0 : // masked fit
			ResetTangentWaves(bls)
			if (cmpstr(bls.fitfunc, "spline")==0 && bls.datalength) // smoothing spline - make a guess for SD
				ResetSD(bls)
			endif
			break
		case 1 : // manual fit - arrange cursors
			ResetCursorsForManFit(bls)
		case 2: // auto
		
			break
		case 3: // spline

			break
	endswitch
end

// I don't know a good way to guess noise level without knowing something about the signal
static function ResetSD(STRUCT BLstruct &bls)
	DFREF dfr = GetPackageDFREF()
	wave/SDFR=dfr/Z w_mask
	wave/Z w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	if (WaveExists(w_data) == 0)
		return 1
	endif
	
	if (bls.tab == 0)
		Extract/free w_data, temp, w_mask
	else
		Duplicate/free w_data temp //should try to eliminate peaks?
	endif
	
	if (numpnts(temp) == 0)
		Duplicate/free w_data temp
	endif
	temp = temp - temp[max(0,p-1)]
	WaveStats/Q temp
	bls.sd = v_sdev/15
	SetVariable svSD, win=$bls.graph+"#BL_panel", limits={0,Inf,bls.sd/10}, value=_NUM:bls.sd
end

static function ResetTangentWaves(STRUCT BLstruct &bls)
	if (bls.tab==0 && cmpstr(bls.fitfunc, "tangent")==0)
		DFREF dfr = GetPackageDFREF()
		Make/O/N=0 dfr:tangent0 /WAVE=tangent0, dfr:tangent1 /WAVE=tangent1
		
		// make sure the zero-point waves won't plot outside x-axis
		// range before appending to graph
		GetAxis/W=$bls.graph/Q $(StringByKey("XAXIS", TraceInfo(bls.graph,bls.trace,0)))
		SetScale/P x, V_max, 1, tangent0, tangent1
				
		AppendToSameAxes(bls.graph, bls.trace, tangent0, $"", matchOffset=1+2*kAllowMuloffset, unique=1)
		AppendToSameAxes(bls.graph, bls.trace, tangent1, $"", matchOffset=1+2*kAllowMuloffset, unique=1)
		// preserve Y offsets; X offsets will lead only to trouble
	else
		RemoveFromGraph/Z/W=$bls.graph tangent0, tangent1
	endif
end

static function ResetCursorsForManFit(STRUCT BLstruct &bls)
		
	// do an auto fit to choose cursor positions
	string xAxisName = StringByKey("XAXIS", TraceInfo(bls.graph, bls.trace, 0))
	string yAxisName = StringByKey("YAXIS", TraceInfo(bls.graph, bls.trace, 0))
	GetAxis/W=$bls.graph/Q $xAxisName
	variable xleft = v_min, xright = v_max, xrange = xright - xleft
	GetAxis/W=$bls.graph/Q $yAxisName
	variable ybottom = v_min, ytop = v_max, yrange = ytop - ybottom
	SetAxis $yAxisName, V_min, V_max
	
	int sav = bls.peak
	bls.peak = 0
	int success = DoAutoFit(bls) // fits function named in bls.fitfunc
	bls.peak = sav
	
	bls.csr.G.x = xleft + 1/7 * xrange
	bls.csr.I.x = xleft + 2/7 * xrange
	bls.csr.F.x = xleft + 0.5 * xrange
	bls.csr.J.x = xleft + 5/7 * xrange
	bls.csr.H.x = xleft + 6/7 * xrange
	
	variable mult = kAllowMuloffset && (bls.muloffset.y != 0) ? bls.muloffset.y : 1
	
	if (success)
		strswitch (bls.fitfunc)
			// two- and one-cursor types
			case "line":
			case "sin":
			case "sigmoid":
				bls.csr.H.y = GetFitValue(bls, bls.csr.H.x)*mult + bls.offset.y
			case "constant": // constant
				bls.csr.G.y = GetFitValue(bls, bls.csr.G.x)*mult + bls.offset.y
				break
			
			// poly types
			case "poly":
				switch (bls.polyorder)
					case 5: // poly 5
						bls.csr.F.y = GetFitValue(bls, bls.csr.F.x)*mult + bls.offset.y
					case 4: // poly 4
						bls.csr.J.y = GetFitValue(bls, bls.csr.J.x)*mult + bls.offset.y
					case 3: // poly 3
						bls.csr.I.y = GetFitValue(bls, bls.csr.I.x)*mult + bls.offset.y
						bls.csr.H.y = GetFitValue(bls, bls.csr.H.x)*mult + bls.offset.y
						bls.csr.G.y = GetFitValue(bls, bls.csr.G.x)*mult + bls.offset.y
						break
				endswitch
				break
				
			// peak-types
			case "gauss": // Gaussian
			case "lor": // Lorentzian
				bls.csr.G.y = GetFitValue(bls, bls.csr.G.x)*mult + bls.offset.y
				bls.csr.H.y = GetFitValue(bls, bls.csr.H.x)*mult + bls.offset.y
				if (bls.csr.H.y < bls.csr.G.y)
					variable swapx = bls.csr.H.x, swapy = bls.csr.H.y
					bls.csr.H.x = bls.csr.G.x
					bls.csr.H.y = bls.csr.G.y
					bls.csr.G.x = swapx
					bls.csr.G.y = swapy
				endif
				break
		endswitch
	endif
	
	// if autofit failed default to these values
	bls.csr.G.y = numtype(bls.csr.G.y) == 0 ? bls.csr.G.y : ybottom + 1/5 * yrange
	bls.csr.I.y = numtype(bls.csr.I.y) == 0 ? bls.csr.I.y : ybottom + 1/5 * yrange
	bls.csr.J.y = numtype(bls.csr.J.y) == 0 ? bls.csr.J.y : ybottom + 2/5 * yrange
	bls.csr.H.y = numtype(bls.csr.H.y) == 0 ? bls.csr.H.y : ybottom + 3/5 * yrange
	bls.csr.F.y = numtype(bls.csr.F.y) == 0 ? bls.csr.F.y : ybottom + 1/2 * yrange
			
	// keep cursors within plot
	variable ymin = min(ytop, ybottom) + abs(yrange)/50
	variable ymax = max(ytop, ybottom) - abs(yrange)/50
			
	bls.csr.G.y = max(ymin, min(bls.csr.G.y, ymax))
	bls.csr.H.y = max(ymin, min(bls.csr.H.y, ymax))
	bls.csr.I.y = max(ymin, min(bls.csr.I.y, ymax))
	bls.csr.J.y = max(ymin, min(bls.csr.J.y, ymax))
	bls.csr.F.y = max(ymin, min(bls.csr.F.y, ymax))
	
	if (numtype(yrange) || numtype(xrange))
		// avoid recursion
		return 0 // make sure we've found real values for all cursor coordinates
	endif
	
	SetCursorsForManFit(bls)
end

// set cursors at positions set in bls structure
static function SetCursorsForManFit(STRUCT BLstruct &bls)
	
	if (bls.datalength == 0)
		return 0
	endif
		
	// check that we have all the needed cursors on the graph
	int reset = 0
	
	int numCursors
	strswitch (bls.fitfunc)
		case "poly":
			numCursors = min(5, bls.polyorder)
			break
		case "constant":
			numCursors = 1
			break
		default:
			numCursors = 2
	endswitch
		
	switch (numCursors)
		case 5:
			reset += (numtype(bls.csr.F.x) || numtype(bls.csr.F.y))
		case 4:
			reset += (numtype(bls.csr.J.x) || numtype(bls.csr.J.y))
		case 3:
			reset += (numtype(bls.csr.I.x) || numtype(bls.csr.I.y))
		case 2:
			reset += (numtype(bls.csr.H.x) || numtype(bls.csr.H.y))
		default:
			reset += (numtype(bls.csr.G.x) || numtype(bls.csr.G.y))
	endswitch
			
	if (reset) // do an auto fit to choose cursor positions
		ResetCursorsForManFit(bls) // recursive
		return 0
	endif
	
	// remove unneeded cursors
	if (numCursors < 5)
		Cursor/K/W=$bls.graph F
		if (numCursors < 4)
			Cursor/K/W=$bls.graph J
			if (numCursors < 3)
				Cursor/K/W=$bls.graph I
				if (numCursors < 2)
					Cursor/K/W=$bls.graph H
				endif
			endif
		endif
	endif
	
	wave rgb = ChooseCursorColor(bls)
	
	// turn off hook function before setting cursors
	SetWindow $bls.graph hook(hBaselines)=$""
	switch (numCursors)
		case 5: // poly 5
			Cursor/F/W=$bls.graph/N=1/H=0/S=1/C=(rgb[0],rgb[1],rgb[2]) F $bls.trace bls.csr.F.x, bls.csr.F.y
		case 4: // or poly 4
			Cursor/F/W=$bls.graph/N=1/H=0/S=1/C=(rgb[0],rgb[1],rgb[2]) J $bls.trace bls.csr.J.x, bls.csr.J.y
		case 3: // or poly 3
			Cursor/F/W=$bls.graph/N=1/H=0/S=1/C=(rgb[0],rgb[1],rgb[2]) I $bls.trace bls.csr.I.x, bls.csr.I.y
		case 2 : // or sin, lor, gauss, sigmoid, line
			Cursor/F/W=$bls.graph/N=1/H=0/S=1/C=(rgb[0],rgb[1],rgb[2]) H $bls.trace bls.csr.H.x, bls.csr.H.y
		default: // or constant
			Cursor/F/W=$bls.graph/N=1/H=0/S=1/C=(rgb[0],rgb[1],rgb[2]) G $bls.trace bls.csr.G.x, bls.csr.G.y
	endswitch
	SetWindow $bls.graph hook(hBaselines)=baselines#hookBaselines
end

static function ResetCursorsForSubrange(STRUCT BLstruct &bls)
	if (bls.subrange == 0)
		Cursor/K/W=$bls.graph C
		Cursor/K/W=$bls.graph D
		return 0
	endif
	
	wave/Z w = TraceNameToWaveRef(bls.graph, bls.trace)
	if (WaveExists(w) == 0)
		return 0
	endif
	
	Make/free/N=(2) range = {bls.csr.C.x,bls.csr.D.x}

	// put cursors on graph
	string xAxisName = StringByKey("XAXIS", TraceInfo(bls.graph, bls.trace, 0))
	GetAxis/W=$bls.graph/Q $xAxisName
	variable xmin = v_min, xmax = v_max
	
	range = numtype(range) == 0 ? range : ( p ? xmax - (xmax-xmin)/50 : xmin + (xmax-xmin)/50 )

	bls.csr.C.x = range[0]
	bls.csr.D.x = range[1]
	SetVariable svL win=$bls.graph+"#BL_panel", value=_NUM:bls.csr.C.x
	SetVariable svR win=$bls.graph+"#BL_panel", value=_NUM:bls.csr.D.x
	GetPointsFromCursors(bls)
	
	wave/SDFR=GetPackageDFREF() w_struct
	StructPut bls w_struct
	
	wave rgb = ChooseCursorColor(bls)
	
	SetWindow $bls.graph hook(hBaselines)=$""
	Cursor/F/W=$bls.graph/N=1/H=2/S=2/C=(rgb[0],rgb[1],rgb[2]) C $bls.trace range[0], 0
	Cursor/F/W=$bls.graph/N=1/H=2/S=2/C=(rgb[0],rgb[1],rgb[2]) D $bls.trace range[1], 0
	SetWindow $bls.graph hook(hBaselines)=baselines#hookBaselines
end

static function GetPointsFromCursors(STRUCT BLstruct &bls)
	
	DFREF dfr = GetPackageDFREF()
	wave/Z w = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)

	Make/free/N=2 w_pRange={0, 0}, w_Xrange={bls.csr.C.x,bls.csr.D.x}
	if (bls.XY)
		w_pRange = GetPointFromXwave(w_x, w_Xrange)
	else
		w_pRange = x2pnt(w, w_Xrange)
	endif
	Sort w_pRange, w_pRange
	bls.endp[0] = max(0, min(w_pRange[0], bls.datalength - 1))
	bls.endp[1] = max(0, min(w_pRange[1], bls.datalength - 1))
end

// wrapper for findlevel, returns point values clipped to 0, wavelength-1 for out of range x
static function GetPointFromXwave(wave xwave, variable xval)
	variable lastpoint = numpnts(xwave)-1
	variable xlast = xwave[lastpoint], xfirst = xwave[0]
	variable xmax = max(xfirst, xlast), xmin = min(xfirst, xlast)
	variable ascending = (xlast > xfirst) // rhs must not be compiled as integer!
	if (xval > xmax)
		return ascending ? lastpoint : 0
	elseif (xval < xmin)
		return ascending ? 0 : lastpoint
	else
		FindLevel/Q/P xwave, xval
		if (v_flag == 0)
			return V_LevelX
		endif
	endif
	return NaN
end

static function SelectTrace(STRUCT BLstruct &bls)
	ResetColors(bls, 1) // set all to grey
	if (strlen(bls.trace) && bls.datalength)
		RestoreTraceColor(bls)
	endif
	return 1
end

// make sure structure wave is up to date before calling
static function/S GetTracesForPopup()
	DFREF dfr = GetPackageDFREF()
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct
	return GetTraceList(bls)
end

static function/S GetTraceList(STRUCT BLstruct &bls)
	string listStr = ReverseList(TraceNameList(bls.graph, ";", 1+4))
	string removeStr = "w_display;w_base;w_sub;tangent0;tangent1;w_nodesY;"
	if (!(bls.options&2048 || GetKeyState(0)&6)) // option or shift to overrride hiding of baselines and baseline-subtracted output waves
		removeStr += ListMatch(listStr, "*" + bls.blSuff)
		removeStr += ListMatch(listStr, "*" + bls.subsuff)
	endif
	listStr = RemoveFromList(removeStr, listStr, ";", 0)
	
	// remove 2D traces from list
	string strTrace
	int i
	for (i=ItemsInList(listStr)-1;i>=0;i--)
		strTrace = StringFromList(i, listStr)
		wave w = TraceNameToWaveRef(bls.graph, strTrace)
		if (WaveDims(w) > 1)
			listStr = RemoveListItem(i, listStr)
		endif
		
//		strInfo = StringByKey("YRANGE", TraceInfo(bls.graph, strTrace, 0))
//		if (cmpstr(strInfo, "[*]"))
//			listStr = RemoveListItem(i, listStr)
//			continue
//		endif
		wave/Z w_x = XWaveRefFromTrace(bls.graph, strTrace)
		if (WaveType(w_x, 1) > 1) // may be category plot
			listStr = RemoveListItem(i, listStr)
		endif
	endfor
		
	return listStr
end

static function/S ReverseList(string list)
	string reverselist = ""
	int i
	for (i=ItemsInList(list)-1;i>=0;i--)
		reverselist += StringFromList(i, list) + ";"
	endfor
	return reverselist
end

// clear baseline paraphernalia from graph
static function ClearGraph(STRUCT BLstruct &bls, int killPanel)

	// we must hope that bls contains the correct graph window name
	if (strlen(bls.graph) == 0 || WinType(bls.graph) != 1)
		return 0
	endif
	
	GraphNormal/W=$bls.graph
	SetWindow $bls.graph hook(hBaselines)=$""
	SetWindow $bls.graph hook(hCleanup)=$""
	Cursor/K/W=$bls.graph C
	Cursor/K/W=$bls.graph D
	Cursor/K/W=$bls.graph E
	Cursor/K/W=$bls.graph F
	Cursor/K/W=$bls.graph G
	Cursor/K/W=$bls.graph H
	Cursor/K/W=$bls.graph I
	Cursor/K/W=$bls.graph J
	
	KillControl/W=$bls.Graph btnEdit_graph
	KillControl/W=$bls.Graph btnAdd_graph
	KillControl/W=$bls.Graph btnRemove_graph

	DFREF dfr = GetPackageDFREF()
	wave/Z/SDFR=dfr w_display, w_base, w_sub, tangent0, tangent1, w_nodesY
	
	wave/Z w = dfr:w_spline_dependency
	if (WaveExists(w))
		SetFormula w, "" // remove dependency
	endif
	
	do // remove all instances of w_display
		RemoveFromGraph/W=$bls.graph/Z w_display
		CheckDisplayed/W=$bls.graph w_display
	while (V_flag) // should be okay.
	// if somehow our package waves were displayed with different tracenames
	// that would be a problem.
	do // remove all instances of w_base
		RemoveFromGraph/W=$bls.graph/Z w_base
		CheckDisplayed/W=$bls.graph w_base
	while (V_flag)
	do // remove all instances of w_sub
		RemoveFromGraph/W=$bls.graph/Z w_sub
		CheckDisplayed/W=$bls.graph w_sub
	while (V_flag)
	do // remove all instances of tangent waves
		RemoveFromGraph/W=$bls.graph/Z tangent0, tangent1
		CheckDisplayed/W=$bls.graph tangent0, tangent1
	while (V_flag)
	do // remove all instances of nodes wave
		RemoveFromGraph/W=$bls.graph/Z w_nodesY
		CheckDisplayed/W=$bls.graph w_nodesY
	while (V_flag)
	
	ResetColors(bls, 0)
	
	if (killPanel)
		KillWindow/Z $bls.graph+"#BL_panel"
	endif
	bls.datalength = 0
end

// subtract current baseline from w_data
static function SubtractBaseline(STRUCT BLstruct &bls)
	
	if (bls.datalength == 0)
		return 0
	endif
		
	DFREF dfr = GetPackageDFREF()
	wave w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	
	wave/Z/SDFR=dfr w_base, w_sub, w_nodesX, w_nodesY, w_mask
	if (numpnts(w_base) != numpnts(w_data)) // should never happen
		if (!bls.multi)
			Print NameOfWave(w_data) + " and baseline have different length"
		else
			DoAlert 0, NameOfWave(w_data) + " and baseline have different length"
		endif
		return 0
	endif
	
	WaveStats/Q/M=1 w_base
	if (V_npnts == 0)
		return 0
	endif
	
	DFREF outputDFR = GetOutputDataFolder(bls)

	string strNote = "", msg = "", strOutput = ""
	
	// save a copy of the baseline
	string strNewName = CleanupName(NameOfWave(w_data) + bls.blSuff, 0)
	if ((bls.options&0x80)==0 && bls.multi==0 && WaveExists(outputDFR:$strNewName))
		if (bls.subrange)
			WaveStats/Q/M=1/R=[bls.endp[0], bls.endp[1]] outputDFR:$strNewName
			if (V_npnts)
				sprintf msg, "Overwrite %s[%g,%g]?", strNewName, bls.endp[0], bls.endp[1]
			endif
		else
			msg = strNewName + " exists. Overwrite?"
		endif
		
		if (strlen(msg))
			DoAlert 1, msg
			if (V_flag == 2)
				return 0
			endif
		endif
	endif

	if (bls.subrange)
		wave/Z newbase = outputDFR:$strNewName
		if (WaveExists(newbase) == 0)
			Duplicate w_data outputDFR:$strNewName /wave=newbase
			FastOp newbase = (NaN)
			note/K newbase
		endif
		if (bls.endp[1] == bls.endp[0])
			return 0
		endif
		newbase[bls.endp[0], bls.endp[1]] = w_base
		strNote = RemoveEnding(note(w_base), "\r")
		if (strlen(strNote))
			note newbase strNote // append note
		endif
	else
		Duplicate/O w_base outputDFR:$strNewName /wave=newbase
		strNote = note(w_base)
	endif
	
	// subtract baseline
	strNewName = CleanupName(NameOfWave(w_data) + bls.subsuff, 0)
	if ((bls.options&0x80)==0 && bls.multi==0 && WaveExists(outputDFR:$strNewName))
		if (bls.subrange)
			WaveStats/Q/M=1/R=[bls.endp[0], bls.endp[1]] outputDFR:$strNewName
			if (V_npnts)
				sprintf msg, "Overwrite %s[%g,%g]?", strNewName, bls.endp[0], bls.endp[1]
			endif
		else
			msg = strNewName + " exists. Overwrite?"
		endif
		
		if (strlen(msg))
			DoAlert 1, msg
			if (V_flag == 2)
				return 0
			endif
		endif
	endif
	
	if (bls.subrange)
		wave/Z subtracted = outputDFR:$strNewName
		if (WaveExists(subtracted) == 0)
			Duplicate w_data outputDFR:$strNewName /wave=subtracted
			FastOp subtracted = (NaN)
		endif
		subtracted[bls.endp[0], bls.endp[1]] = w_data - w_base + bls.base
	else
		Duplicate/O w_data outputDFR:$strNewName /wave=subtracted
		FastOp subtracted = w_data - w_base + (bls.base)
	endif
			
	if (bls.tab==0 && bls.options&0x200) // save mask
		strNewName = CleanupName(NameOfWave(w_data) + bls.maskSuff, 0)
		wave/Z mask = outputDFR:$strNewName
		if ((bls.options&0x80)==0 && bls.multi==0 && WaveExists(mask))
			msg = strNewName + " exists. Overwrite?"
			DoAlert 1, msg
			if (V_flag == 2)
				return 0
			endif
		endif
		Duplicate/O w_mask outputDFR:$strNewName /wave=mask
	endif
	
	if (bls.tab==3 && bls.subrange==0)
		strNewName = CleanupName(NameOfWave(w_data) + "_SpNodes", 0)
		if ((bls.options&0x80)==0 && bls.multi==0 && WaveExists(outputDFR:$strNewName))
			DoAlert 1, strNewName + " exists. Overwrite?"
			if (V_flag == 2)
				return 0
			endif
		endif
		Duplicate/O w_nodesX outputDFR:$strNewName /WAVE=nd
		Redimension/N=(-1, 2) nd
		nd[][0] = w_nodesX[p]
		nd[][1] = w_nodesY[p]
		note nd, "nodes:" + NameOfWave(w_data)
	endif
	
	// append note from baseline wave to output wave note
	strNote = ReplaceStringByKey("data", strNote, NameOfWave(w_data), "=", ";")
	sprintf strOutput, "%s,%s", NameOfWave(subtracted), NameOfWave(newbase)
	if (bls.tab==3 && bls.subrange==0)
		sprintf strOutput, "%s,%s", strOutput, NameOfWave(nd)
	endif
	strNote = ReplaceStringByKey("output", strNote, strOutput, "=", ";")
	if (WaveExists(w_x))
		strNote = ReplaceStringByKey("xwave", strNote, NameOfWave(w_x), "=", ";")
	endif

	note subtracted, strNote // append note
	if (bls.history & 1)
		Print strNote[strsearch(strNote, "Baseline Parameters", 0), strlen(strNote)-1]
	endif
		
	if (WaveExists(w_x)) // make sure the output wave has an xwave tag for XYbrowser
		strNote = note(subtracted)
		strNote = ReplaceStringByKey("Xwave", strNote, NameOfWave(w_x), ":", "\r")
		note/K subtracted, strNote
		strNote = note(newbase)
		strNote = ReplaceStringByKey("Xwave", strNote, NameOfWave(w_x), ":", "\r")
		note/K newbase, strNote
	endif
	
	RestoreTraceColor(bls) // for all-at-once fitting
	// prevent y-axis from autoscaling
	HoldYaxis(bls)
	if (bls.options & 1)
		AppendToSameAxes(bls.graph, bls.trace, subtracted, w_x, matchRGB=((bls.options&0x20)==0), w_rgb={0,0,0}, unique=1, matchOffset=2*kAllowMuloffset)
	endif
	if (bls.options & 2)
		AppendToSameAxes(bls.graph, bls.trace, newbase, w_x, matchRGB=((bls.options&0x20)==0), w_rgb={0,0,0}, matchOffset=1+2*kAllowMuloffset, unique=1)
	endif
	
	CheckDisplayed/W=$bls.graph w_sub, w_base, w_nodesY
	if (v_flag & 1)
		ReorderTraces/W=$bls.graph _front_, {w_sub}
	endif
	if (v_flag & 2)
		ReorderTraces/W=$bls.graph _front_, {w_base}
	endif
	if (v_flag & 4)
		ReorderTraces/W=$bls.graph _front_, {w_nodesY}
	endif
	
	if (bls.options & 4) // remove trace after fitting
		RemoveFromGraph/W=$bls.graph/Z $bls.trace, w_base
		PopupMenu popTrace, win=$bls.graph+"#BL_panel", mode=1
		ControlInfo/W=$bls.graph+"#BL_panel" popTrace
		bls.trace = S_value
		SetTraceProperties(bls)
		StructPut bls, dfr:w_struct
		if (bls.tab == 3)
			SetNodes(bls)
		endif
		ResetGraphForTrace(bls)
		DoFit(bls)
	endif
	
	if (bls.tab == 3) // disable edit mode after baseline subtraction
		bls.editmode = 0
		SetEditMode(bls)
	endif
	
	return 1
end

// if a baseline has been subtracted from the currently active trace, this
// returns its wave reference
static function/wave GetBLWave(STRUCT BLstruct &bls)
	if (bls.datalength == 0)
		return $""
	endif
	
	wave w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	DFREF dfr = GetOutputDataFolder(bls)
		
	wave/Z sub = dfr:$CleanupName(NameOfWave(w_data) + bls.blsuff, 0)
	if (WaveExists(sub) && numpnts(sub) != numpnts(w_data))
		wave/Z sub = $""
	endif
	return sub
end

static function/DF GetOutputDataFolder(STRUCT BLstruct &bls)
	if (bls.datalength == 0)
		return $""
	endif
	wave w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	DFREF sourceDFR = GetWavesDataFolderDFR(w_data)
	if (bls.options & 0x100) // use current DF
		DFREF OutputDFR = GetDataFolderDFR()
	else // use source DF
		DFREF OutputDFR = sourceDFR
	endif
	
	if (bls.options & 0x400) // use subfolders
		string subfolder = ""
		if (bls.options&0x100 && !DataFolderRefsEqual(sourceDFR, OutputDFR))
			subfolder = GetWavesDataFolder(w_data, 0) + "_"
		endif
		subfolder += "baselines_"
		subfolder += StringFromList(bls.tab, "mask_;man_;auto_;nodes_")
		subfolder += bls.fitfunc
		subfolder = CleanupName(subfolder, 0)
		NewDataFolder/O $GetDataFolder(1, OutputDFR) + subfolder
		DFREF OutputDFR = $GetDataFolder(1, OutputDFR) + subfolder
	endif
	return OutputDFR
end

// this function is slow because of the string list handling functions
static function/S CreateNote(STRUCT BLstruct &bls)
	
	string keyList = "", strItem = ""
	int i
	switch (bls.tab)
		
		case 0 :
			keyList = ReplaceStringByKey("type", keyList, "masked", "=", ";")
			keyList = ReplaceStringByKey("function", keyList, bls.fitfunc, "=", ";")
			if (cmpstr(bls.fitfunc, "spline") == 0)
				keyList = ReplaceNumberByKey("smoothingSD", keyList, bls.sd, "=", ";")
			endif
			break
		case 1 :
			keyList = ReplaceStringByKey("type", keyList, "manual", "=", ";")
			keyList = ReplaceStringByKey("function", keyList, bls.fitfunc, "=", ";")
			break
		case 2 :
			strswitch (bls.fitfunc)
				case "hull spline":
					strItem = "hull-spline"
					break
				case "arc hull":
					strItem = "arc-hull"
					break
				default:
					strItem = "iterative"
			endswitch
			keyList = ReplaceStringByKey("type", keyList, strItem, "=", ";")
			if (cmpstr(strItem, "iterative") == 0)
				keyList = ReplaceStringByKey("function", keyList, bls.fitfunc, "=", ";")
			endif
			// no way to get number of iterations...
			break
		case 3 : // node interpolation
			keyList = ReplaceStringByKey("type", keyList, "interpolated", "=", ";")
			keyList = ReplaceStringByKey("function", keyList, bls.fitfunc, "=", ";")
			if (cmpstr(bls.fitfunc, "smoothing") == 0) // smoothing
				keyList = ReplaceNumberByKey("F", keyList, bls.flagF, "=", ";")
			endif
			wave/SDFR=GetPackageDFREF() w_nodesX
			keyList = ReplaceNumberByKey("numNodes", keyList, numpnts(w_nodesX), "=", ";")
			break
	endswitch
	
	// deal with coefficient wave
	if (bls.tab < 3)
		wave/Z w_coef = w_coef
		if (WaveExists(w_coef))
			strItem = "{" + num2str(w_coef[0])
			for (i=1;i<numpnts(w_coef);i++)
				strItem += "," + num2str(w_coef[i])
			endfor
			strItem += "}"
			keyList = ReplaceStringByKey("w_coef", keyList, strItem, "=", ";")
		endif
	endif
	
	if (bls.subrange)
		variable x1, x2
		if (bls.XY)
			wave w_x = XWaveRefFromTrace(bls.graph, bls.trace)
			x1 = w_x[bls.endp[0]]
			x2 = w_x[bls.endp[1]]
		else
			wave w_data = TraceNameToWaveRef(bls.graph, bls.trace)
			x1 = pnt2x(w_data, bls.endp[0])
			x2 = pnt2x(w_data, bls.endp[1])
		endif
		sprintf strItem, "(%g,%g)", min(x1, x2), max(x1, x2)
		keyList = ReplaceStringByKey("output range", keyList, strItem, "=", ";")
	endif
	
	return "Baseline Parameters:" + keyList
end

// The bls structure is not stored after fitting in any function
// below this level. Fit parameters are saved in wavenote of w_base -
// that's quicker.
static function DoFit(STRUCT BLstruct &bls)
	
	if (bls.datalength == 0)
		return 0
	endif
	
	int success = 0
	
	#ifdef testing
	tic()
	#endif
	
	switch (bls.tab)
		case 0:
			success = DoMaskedFit(bls)
			break
		case 1:
			success = DoManFit(bls)
			break
		case 2:
			success = DoAutoFit(bls)
			break
		case 3:
			DFREF dfr = GetPackageDFREF()
			StructPut bls dfr:w_struct
			DoSplineFit({NaN})
			success = 1
			break
	endswitch
	
	#ifdef testing
	Print bls.fitfunc, toc()/1e6, "s"
	#endif

//	if (!success)
//		if (bls.info)
//			wave listwave = dfr:listwave
//			UpdateListwave("", listwave)
//		endif
//	endif
	return success
end

// cursor positions must be correctly stored in bls structure
static function DoManFit(STRUCT BLstruct &bls)
	
	if (bls.datalength == 0)
		return 0
	endif
	
	wave w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	
	DFREF dfr = GetPackageDFREF()
	wave/SDFR=dfr w_base, w_sub
	
	string strNote = "", strRange=""
	
	variable p1 = 0, p2 = bls.datalength - 1
	if (bls.subrange)
		PadSubrange(bls, w_data, w_base)
		p1 = bls.endp[0]
		p2 = bls.endp[1]
		variable x_1, x_2
		x_1 = bls.XY ? w_x[bls.endp[0]] : pnt2x(w_data, bls.endp[0])
		x_2 = bls.XY ? w_x[bls.endp[1]] : pnt2x(w_data, bls.endp[1])
		sprintf strRange, "output range=(%g,%g);", min(x_1, x_2), max(x_1, x_2)
	endif
	variable numPoints = p2 - p1
	
	if (!numPoints)
		return 0
	endif
	
	variable mult = kAllowMuloffset && (bls.muloffset.y != 0) ? bls.muloffset.y : 1
	
	variable x1, y1, x2, y2, x3, y3, x4, y4, x5, y5
	x1 = bls.csr.G.x
	y1 = (bls.csr.G.y - bls.offset.y)/mult
	x2 = bls.csr.H.x
	y2 = (bls.csr.H.y - bls.offset.y)/mult
	x3 = bls.csr.I.x
	y3 = (bls.csr.I.y - bls.offset.y)/mult
	x4 = bls.csr.J.x
	y4 = (bls.csr.J.y - bls.offset.y)/mult
	x5 = bls.csr.F.x
	y5 = (bls.csr.F.y - bls.offset.y)/mult
	
	Make/D/O/N=1 w_coef
	strswitch (bls.fitfunc)
		case "constant":
			w_coef = {y1}
			if (numPoints > kMultithreadCutoff)
				multithread w_base[p1,p2] = y1
			else
				w_base[p1,p2] = y1
			endif
			break
		case "line":
			w_coef = {y1-x1*(y2-y1)/(x2-x1), (y2-y1)/(x2-x1)}
			if (numPoints > kMultithreadCutoff)
				if (WaveExists(w_x))
					multithread w_base[p1,p2] =	 w_coef[0] + w_coef[1] * w_x[p]
				else
					multithread w_base[p1,p2] =	 w_coef[0] + w_coef[1] * x
				endif
			elseif (WaveExists(w_x))
				w_base[p1,p2] =	 w_coef[0] + w_coef[1] * w_x[p]
			else
				w_base[p1,p2] =	 w_coef[0] + w_coef[1] * x
			endif
			break
		case "poly":
			Make/free/D coordinates={{x1,x2,x3,x4,x5},{y1,y2,y3,y4,y5}}
			Redimension/N=(bls.polyorder,-1) coordinates, w_coef
			wave polyCoef = PolyCoefficients(coordinates)
			w_coef = polyCoef
			if (numPoints > kMultithreadCutoff)
				if (WaveExists(w_x))
					multithread w_base[p1,p2] = poly(w_coef, w_x)
				else
					multithread w_base[p1,p2] = poly(w_coef, x)
				endif
			elseif (WaveExists(w_x))
				w_base[p1,p2] = poly(w_coef, w_x)
			else
				w_base[p1,p2] = poly(w_coef, x)
			endif
			break
		case "gauss":
			w_coef = {y1, y2-y1, x2, abs(x2-x1)/2}
			if (numPoints > kMultithreadCutoff)
				if (WaveExists(w_x))
					multithread w_base[p1,p2] = w_coef[0] + w_coef[1] * exp(-((w_x - w_coef[2])/w_coef[3])^2)
				else
					multithread w_base[p1,p2] = w_coef[0] + w_coef[1] * exp(-((x - w_coef[2])/w_coef[3])^2)
				endif
			elseif (WaveExists(w_x))
				w_base[p1,p2] =	 w_coef[0] + w_coef[1] * exp(-((w_x - w_coef[2])/w_coef[3])^2)
			else
				w_base[p1,p2] =	 w_coef[0] + w_coef[1] * exp(-((x - w_coef[2])/w_coef[3])^2)
			endif
			break
		case "lor":
			w_coef = {y1, (y2-y1)*(x2-x1)^2/16, x2, (x2-x1)^2/16}
			if (numPoints > kMultithreadCutoff)
				if (WaveExists(w_x))
					multithread w_base[p1,p2] = w_coef[0]+w_coef[1]/(((w_x-w_coef[2])^2)+w_coef[3])
				else
					multithread w_base[p1,p2] = w_coef[0]+w_coef[1]/(((x-w_coef[2])^2)+w_coef[3])
				endif
			elseif (WaveExists(w_x))
				w_base[p1,p2] =	w_coef[0]+w_coef[1]/(((w_x-w_coef[2])^2)+w_coef[3])
			else
				w_base[p1,p2] =	w_coef[0]+w_coef[1]/(((x-w_coef[2])^2)+w_coef[3])
			endif
			break
		case "sin":
			x2 = x1 + (x2-x1)/(2*(bls.cycles+1)-1)
			w_coef = {(y1+y2)/2, (y2-y1)/2, Pi/(x2-x1), -Pi/2*(x1+x2)/(x2-x1)}
			if (numPoints > kMultithreadCutoff)
				if (WaveExists(w_x))
					multithread w_base[p1,p2] = w_coef[0] + w_coef[1]*sin(w_coef[2]*w_x + w_coef[3])
				else
					multithread w_base[p1,p2] = w_coef[0] + w_coef[1]*sin(w_coef[2]*x + w_coef[3])
				endif
			elseif (WaveExists(w_x))
				w_base[p1,p2] =	w_coef[0] + w_coef[1]*sin(w_coef[2]*w_x + w_coef[3])
			else
				w_base[p1,p2] =	w_coef[0] + w_coef[1]*sin(w_coef[2]*x + w_coef[3])
			endif
			break
		case "sigmoid":
			if (x2 >= x1)
				w_coef = {y1, y2-y1, (x1+x2)/2, abs(x1-x2)/10}
			else
				w_coef = {y2, y1-y2, (x1+x2)/2, abs(x2-x1)/10}
			endif
			if (numPoints > kMultithreadCutoff)
				if (WaveExists(w_x))
					multithread w_base[p1,p2] = W_coef[0] + W_coef[1]/(1+exp(-(w_x[p]-W_coef[2])/W_coef[3]))
				else
					multithread w_base[p1,p2] = W_coef[0] + W_coef[1]/(1+exp(-(x-W_coef[2])/W_coef[3]))
				endif
			elseif (WaveExists(w_x))
				w_base[p1,p2] = W_coef[0] + W_coef[1]/(1+exp(-(w_x[p]-W_coef[2])/W_coef[3]))
			else
				w_base[p1,p2] = W_coef[0] + W_coef[1]/(1+exp(-(x-W_coef[2])/W_coef[3]))
			endif
			break
		default:
			return 0
	endswitch
	
	
	sprintf strNote, "Baseline Parameters:type=manual;function=%s;w_coef={%g", bls.fitfunc, w_coef[0]
	int i
	for (i=1;i<numpnts(w_coef);i++)
		sprintf strNote, "%s,%g", strNote, w_coef[i]
	endfor
	strNote += "};" + strRange
	
	// update note in w_base so that it's copied to output wave by SubtractBaseline()
	note/K w_base strNote
	if (bls.info)
		wave listwave = dfr:listwave
		UpdateListwave(strNote, listwave)
	endif

	FastOp w_sub = w_data - w_base + (bls.base)
	
	return 1
end



static function DoMaskedFit(STRUCT BLstruct &bls)
	
	if (bls.datalength == 0)
		return 0
	endif
		
	DFREF dfr = GetPackageDFREF()
	wave/Z/SDFR=dfr w_base, w_display, w_mask, w_sub
	wave/Z w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	
	if (WaveMin(w_mask)==0 && WaveMax(w_mask)==0) // no region to fit
		if (bls.subrange)
			PadSubrange(bls, w_data, w_base)
			w_base[bls.endp[0],bls.endp[1]] = NaN
			FastOp w_sub = w_data - w_base + (bls.base)
		else
			FastOp w_base = (NaN)
			FastOp w_sub  = (NaN)
		endif
		
		if (cmpstr(bls.fitfunc, "tangent") == 0)
			ClearTangentWaves()
		endif
		note/K w_base

		if (bls.info)
			wave listwave = dfr:listwave
			UpdateListwave("", listwave)
		endif
		
		return 0
	endif
	
	HoldYaxis(bls)
	
	string strNote = "Baseline Parameters:"
	strNote += "type=masked;function=" + bls.fitfunc + ";"
	string rangeStr = ""
	
	int success = 1
	
	// treat spline and tangent as special cases,
	// otherwise use CurveFit to fit selected function
	if (cmpstr(bls.fitfunc, "spline") == 0) // spline
		
		success = FitMaskedSpline(bls, w_data, w_x, w_mask, w_base)
		sprintf strNote, "%ssmoothingSD=%g;", strNote, bls.sd
		
	elseif (cmpstr(bls.fitfunc, "tangent") == 0) // tangent
		
		success = FitTangent(bls, w_data, w_x, w_mask, w_base)
		strNote += note(w_base)
		
	else // not one of the 'special case' baselines
		
		DebuggerOptions
		variable sav_debug = V_debugOnError
		DebuggerOptions debugOnError=0 // switch this off in case the fit fails
		
		success = FitFuncs(bls, w_data, w_x, w_mask, w_base)

		DebuggerOptions debugOnError=sav_debug
	
		if (success) // record fit coefficients in baseline wavenote
			strNote += CoefficientString()
		endif
		
	endif
	
	if (!success)
						
		FastOp w_base = (NaN)
		FastOp w_sub = (NaN)
		
		if (bls.subrange)
			PadSubrange(bls, w_data, w_base)
			FastOp w_sub = w_data - w_base + (bls.base)
		endif
		
		if (bls.info)
			wave listwave = dfr:listwave
			UpdateListwave("", listwave)
		endif
					
		return success
	endif
	
	wave w_mask = dfr:w_mask
	strNote += MaskString(w_mask, w_x)
	
	if (bls.subrange)
		PadSubrange(bls, w_data, w_base)
		variable x1, x2
		x1 = bls.XY ? w_x[bls.endp[0]] : pnt2x(w_data, bls.endp[0])
		x2 = bls.XY ? w_x[bls.endp[1]] : pnt2x(w_data, bls.endp[1])
		sprintf strNote, "%soutput range=(%g,%g);", strNote, min(x1, x2), max(x1, x2)
	endif
	
	// update note in w_base so that it's copied to output wave by SubtractBaseline()
	note/K w_base strNote
	if (bls.info)
		wave listwave = dfr:listwave
		UpdateListwave(strNote, listwave)
	endif
	
	FastOp w_sub = w_data - w_base + (bls.base)
	return success
end

// figure out ranges used for fitting from mask wave
static function/S MaskString(wave w_mask, wave/Z w_x)
	int i
	int imax = numpnts(w_mask), used = 0
	variable xVal
	string rangeStr = ""
	for(i=0;i<imax;i+=1)
		if (w_mask[i] != used) // edge of a masked region
			used = !used
			if (used) // started to include
				xVal = (WaveExists(w_x)) ? w_x[i] : pnt2x(w_mask, i)
				sprintf rangeStr, "%s(%g", rangeStr, xVal
			else // stopped including
				xVal = (WaveExists(w_x)) ? w_x[i] : pnt2x(w_mask, i-1)
				sprintf rangeStr, "%s,%g),", rangeStr, xVal
			endif
		endif
		if ( (i==numpnts(w_mask)-1) && used )
			xVal = (WaveExists(w_x)) ? w_x[i] : pnt2x(w_mask, i)
			sprintf rangeStr, "%s,%g)", rangeStr, xVal
		endif
	endfor

	return "fit regions=" + RemoveEnding(rangeStr, ",") + ";"
end

static function FitMaskedSpline(STRUCT BLstruct &bls, wave w_data, wave/Z w_x, wave w_mask, wave w_base)
		
	Duplicate/free w_data w_masked
	FastOp w_masked = w_data / w_mask
	WaveStats/Q/M=1 w_masked
	if (V_npnts < 4)
		FastOp w_base = (NaN)
		return 0
	endif
	
	if (WaveExists(w_x))
		#if (IgorVersion() < 9)
		Duplicate/free w_x w_x2 // source and destination must be different
		Interpolate2/T=3/I=3/F=1/S=(bls.sd)/X=w_x2/Y=w_base w_x, w_masked
		#else
		Interpolate2/T=3/I=3/F=1/S=(bls.sd)/X=w_x/Y=w_base w_x, w_masked
		#endif
	else
		Interpolate2/T=3/I=3/F=1/S=(bls.sd)/Y=w_base w_masked
	endif
	return 1
end

static function ClearTangentWaves()
	wave/Z/SDFR=GetPackageDFREF() tangent0, tangent1
	if (WaveExists(tangent0))
		FastOp tangent0 = (NaN)
	endif
	if (WaveExists(tangent1))
		FastOp tangent1 = (NaN)
	endif
end

static function FitTangent(STRUCT BLstruct &bls, wave w_data, wave/Z w_x, wave w_mask, wave w_base)
	
	note/K w_base
	ClearTangentWaves()
	
	// make sure we have one or two regions to fit
	FindLevels/Q/EDGE=1/P w_mask, 1
	int numRegions = V_LevelsFound + (w_mask[0]==1)
	if (numRegions<1 || numRegions>2)
		return 0
	endif
	
	// find the points at edges of fit regions
	Make/free/N=(2*numRegions) wEdgesP, wEdgesX
	
	int pnt = 0, j = 0
	do
		if (pnt==0 && w_mask[pnt]==1)
			wEdgesP[j] = pnt
			j += 1
		elseif (pnt==numpnts(w_mask)-1 && w_mask[pnt]==1)
			wEdgesP[j] = pnt
			j += 1
		elseif (pnt>0 && w_mask[pnt]!=w_mask[pnt-1])
			wEdgesP[j] = pnt - w_mask[pnt-1]
			j += 1
		endif
		pnt += 1
	while (j<(2*numRegions) && pnt<numpnts(w_mask))
	if (!(j==2 || j==4))
		return 0
	endif
	
	Make/free/N=2 wTangentCoef = NaN
	
	Sort wEdgesP, wEdgesP
	wEdgesX = (WaveExists(w_x)) ? w_x[wEdgesP] : pnt2x(w_data, wEdgesP)
	// first poly is the one fit to the lower point range
	
	int success = 0
	
	if (numRegions == 2)
		success = fitCommonTangent(wTangentCoef, wEdgesP, wEdgesX, w_data, w_x, w_base)
	else //if (abs(wEdgesP[1]-wEdgesP[0]) >= 4) // fit horizontal tangent
		DFREF dfr = GetPackageDFREF()
		Make/O/N=200 dfr:tangent0 /WAVE=tangent0
		Make/O/N=200 dfr:tangent1 /WAVE=tangent1
		FastOp tangent0 = (NaN)
		FastOp tangent1 = (NaN)
		
		SetScale/I x, wEdgesX[0], wEdgesX[1], tangent0, tangent1
		
		variable V_FitError = 0
		CurveFit/Q poly 4, w_data[wEdgesP[0],wEdgesP[1]] /X=w_x/NWOK
		
		if (!V_FitError)
			wave/D w_coef = w_coef
			tangent0 = poly(w_coef,x)
			// differentiate and look for roots in range
			Make/free/D w = {w_coef[1], 2*w_coef[2], 3*w_coef[3]}
			FindRoots/Q/P=w
			if (!v_flag)
				wave w_polyroots
				variable xmin = min(wEdgesX[0], wEdgesX[1])
				variable xmax = max(wEdgesX[0], wEdgesX[1])
				Make/free/N=(numpnts(w_polyroots)) wRootsX, wRootsY
				wRootsX = real(w_polyroots)
				wRootsY = imag(w_polyroots[p]) || wRootsX[p]!=limit(wRootsX[p], xmin, xmax) ? NaN : poly(w_coef, wRootsX)
				WaveStats/M=1/P/Q wRootsY
				int index = bls.options&8 ? V_maxloc : V_minloc
				if (index >- 1)
					wTangentCoef[1] = 0
					wTangentCoef[0] = wRootsY[index]
					string strNote = ""
					sprintf strNote, "w_coef={%g,0};contact point=(%g,%g);", wTangentCoef[0], wRootsX[index], wTangentCoef[0]
					note/K w_base, strNote
					success = 1
				endif
			endif
		endif
	endif
		
	if (WaveExists(w_x))
		FastOp w_base = (wTangentCoef[0]) + (wTangentCoef[1]) * w_x
	elseif (bls.datalength > kMultithreadCutoff)
		multithread w_base = wTangentCoef[0] + wTangentCoef[1] * x
	else
		w_base = wTangentCoef[0] + wTangentCoef[1] * x
	endif
	
	// create a coefficent wave for this fit in case user wants access for further processing
	wave/D w_coef
	w_coef = {wTangentCoef[0], wTangentCoef[1]}
	return success
end

// returns 1 for success, puts coefficients for tangent in wTangentCoef, adds note to w_base
static function FitCommonTangent(wave wTangentCoef, wave wEdgesP, wave wEdgesX, wave w_data, wave/Z w_x, wave w_base)
	
	DFREF dfr = GetPackageDFREF()
	Make/D/free/N=9 w_9coef = 0
	// w_9coef[0,3],[4,7] are coefficients for first and second poly, respectively
	Make/O/N=200 dfr:tangent0 /WAVE=tangent0
	Make/O/N=200 dfr:tangent1 /WAVE=tangent1
	SetScale/I x, wEdgesX[0], wEdgesX[1], tangent0
	SetScale/I x, wEdgesX[2], wEdgesX[3], tangent1
	
	variable V_FitError = 0
	CurveFit/Q poly 4, w_data[wEdgesP[0],wEdgesP[1]] /X=w_x/NWOK
	wave/D w_coef = w_coef
	tangent0 = poly(w_coef,x)
	w_9coef[0,3] = w_coef
	
	V_FitError = 0
	CurveFit/Q poly 4, w_data[wEdgesP[2],wEdgesP[3]] /X=w_x/NWOK
	w_9coef[4,7] = w_coef[p-4]
	tangent1 = poly(w_coef,x)
	
	// pass the mid position of second poly function
	// to help choose the correct root
	w_9coef[8] = (wEdgesX[2] + wEdgesX[3]) / 2
	
	int pnts = 300
	Make/free/N=(pnts) w_deltaY
	SetScale/I x, wEdgesX[0], wEdgesX[1], w_deltaY
	w_deltaY = TangentDistance(w_9coef, x)
	
	variable xmin = min(wEdgesX[0], wEdgesX[1])
	variable xmax = max(wEdgesX[0], wEdgesX[1])
	variable xmid = (wEdgesX[0] + wEdgesX[1])/2
	variable crossing1 = NaN, crossing2 = NaN
	variable crossingX
		
	FindLevel/Q/R=(xmid, xmax), w_deltaY, 0
	if (V_flag == 0)
		crossing1 = V_LevelX
	endif
	FindLevel/Q/R=(xmid, xmin), w_deltaY, 0
	if (V_flag == 0)
		crossing2 = V_LevelX
	endif
	
	if (numtype(crossing1))
		if (numtype(crossing2))
			return 0 // no crossings
		else // one crossing
			crossingX = crossing2
		endif
	elseif (numtype(crossing2))
		crossingX = crossing1
	else // two crossings, choose the one closest to midpoint
		crossingX = (abs(crossing1 - xmid) < abs(crossing2 - xmid)) ? crossing1 : crossing2
	endif
				
	variable delta = 2 * abs(deltax(w_deltaY))
	FindRoots/H=(crossingX+delta)/L=(crossingX-delta)/Q baselines#TangentDistance, w_9coef
	if (V_flag)
		wTangentCoef = {NaN, NaN}
		return 0
	endif
	
	if (V_root != limit(V_root, xmin, xmax))
		wTangentCoef = {NaN, NaN}
		return 0 // found a tangent beyond the x-range of first region
	endif
			
	variable grad = w_9coef[1] + 2 * w_9coef[2] * V_Root + 3 * w_9coef[3] * V_Root^2
	variable intercept = w_9coef[0] + w_9coef[1] * V_Root + w_9coef[2] * V_Root^2 + w_9coef[3] * V_Root^3 - grad * V_Root
	
	variable x1, y1, x2, y2
	x1 = V_root
	y1 = intercept + grad * x1
		
	// figure out second tangent point
	variable a, b, c, root1, root2
	a = 3 * w_9coef[7]
	b = 2 * w_9coef[6]
	c = w_9coef[5] - grad
	
	root1 = (-b + sqrt(b^2 -4 * a * c)) / (2 * a)
	root2 = (-b - sqrt(b^2 -4 * a * c)) / (2 * a)

	// choose root closest to midpoint of x range
	x2 = (abs(root1-w_9coef[8]) < abs(root2-w_9coef[8])) ? root1 : root2
	y2 = intercept + grad * x2
	
	xmin = min(wEdgesX[2], wEdgesX[3])
	xmax = max(wEdgesX[2], wEdgesX[3])
	if (x2 != limit(x2, xmin, xmax))
		return 0
	endif
	
	string strNote = ""
	sprintf strNote, "w_coef={%g,%g};contact points=(%g,%g),(%g,%g);", intercept, grad, x1, y1, x2, y2
	note/K w_base, strNote
	
	wTangentCoef = {intercept, grad}
	return 1
end

// for finding common tangent to two 3rd degree polynomials
threadsafe static function TangentDistance(wave w, variable x)
	// first poly 4 is y=w[0]+w[1]*x+w[2]*x^2+w[3]*x^3
	// second poly 4 is y=w[4]+w[5]*x+w[6]*x^2+w[7]*x^3
	// w[8] is midpoint of x range for second poly
	
	// find gradient of tangent at position x on first poly
	variable grad = w[1] + 2*w[2]*x + 3*w[3]*x^2
	variable intercept = w[0] + w[1]*x + w[2]*x^2 + w[3]*x^3 - grad*x
	
	// find distance from tangent to second poly
	// start by finding tangent to second poly with gradient == grad
	variable a, b, c, root1, root2
	
	// gradient of second poly is w[5]+2*w[6]*x+3*w[7]*x^2
	// so 3*w[7]*x^2 + 2*w[6]*x + w[5]-grad = 0
	a = 3 * w[7]
	b = 2 * w[6]
	c = w[5] - grad
	
	root1 = (-b + sqrt(b^2-4*a*c)) / (2*a)
	root2 = (-b - sqrt(b^2-4*a*c)) / (2*a)
	// FindRoots/P (Jenkins-Traub) would be more robust, but this works tolerably.
	// With a factor of 5 speed gain
	
	variable x0, y0
	
	// choose root closest to midpoint of x range
	x0 = (abs(root1-w[8]) < abs(root2-w[8])) ? root1 : root2
	y0 = w[4] + w[5] * x0 + w[6] * x0^2 + w[7] * x0^3
	
	// distance to tangent is (intercept + grad*x0 - y0) / sqrt(1 + grad^2)
	return (intercept + grad*x0 - y0) // vertical offset, this will do
end

static function ClearMarquee(STRUCT BLstruct &bls)
	SetMarquee/W=$bls.graph 0, 0, 0, 0
	MarqueeEvent(bls) // clear buttons, setvars, roi
end

//// GraphWaveEdit swallows the mousemoved events
//static function HookSpline(STRUCT WMWinHookStruct &s)
//	if (s.eventCode == 4) // mousemoved
//		int v_key = GetKeyState(0)
//		if (v_key == 0)
//			return 0
//		endif
//		int controlkey = 16
//		#ifdef WINDOWS
//		controlkey = 1
//		#endif
//		if (v_key & controlkey)
//			s.doSetCursor = 1
//			s.cursorCode = 7
//		endif
//	endif
//
//	return 0
//end

// hook for GRAPH window
static function HookBaselines(STRUCT WMWinHookStruct &s)
		
	if (s.eventCode < 5)
		return 0
	endif
	
	if (s.eventCode==17 && WinType("BaselinesPrefsPanel")==7) // KillVote
		return 2 // No Kill when preferences panel is displayed
	endif
	
	STRUCT BLstruct bls
	DFREF dfr = GetPackageDFREF()
	StructGet bls dfr:w_struct
	
	if (cmpstr(bls.graph, s.winName)) // the wrong graph window
		SetWindow $s.winName hook(hBaselines)=$""
		return 0
	endif
		
	switch (s.eventCode)
		case 5: // mouseup
			ClickEvent(bls, s) // for spline
			MarqueeEvent(bls) // updates roi after drawing marquee, removes buttons after dismissing marquee
			break
		case 6: // resized
		case 8: // modify
			SetTraceProperties(bls) // if the modify event removes our target trace this will fix things
			RepositionMarquee(bls) // reposition marquee if there is one
			RepositionCursors(bls)
			StructPut bls dfr:w_struct
			break
		case 7: // Cursor moved
			if (numtype(s.pointnumber) == 0) // cursor hasn't been killed
				CursorEvent(bls, s.cursorName)
				StructPut bls dfr:w_struct
			endif
			break
		case 11: // keyboard
			if (s.keycode == bls.keyplus || s.keycode == bls.keyminus)
				if (MaskAddOrRemoveSelection(s.keycode == bls.keyplus))
					return 1
				endif
			endif
			// maybe one day we will be able to use this
//			if (bls.tab == 3 && s.keycode == 32)
//				bls.editmode = !bls.editmode
//				SetEditMode(bls) // also sets mode for nodes trace
//				StructPut bls dfr:w_struct
//				return 1
//			endif
			break
		case 13: // renamed (!)
			bls.graph = s.WinName
			StructPut bls dfr:w_struct
			break
	endswitch
	return 0
end

// called from hook function for a click event
// or from ClearMarquee for cleanup
static function MarqueeEvent(STRUCT BLstruct &bls)
	
	if (bls.datalength==0 || bls.tab!=0)
		KillControl/W=$bls.Graph btnAdd_graph
		KillControl/W=$bls.Graph btnRemove_graph
		return 0
	endif
				
	string panelStr = bls.graph + "#BL_panel"
	string s_Xax = StringByKey("XAXIS", TraceInfo(bls.graph, bls.trace, 0))
	string s_Yax = StringByKey("YAXIS", TraceInfo(bls.graph, bls.trace, 0))
	GetMarquee/W=$bls.graph/Z $s_Xax, $s_Yax
	if (V_flag == 0) // no marquee
		SetVariable svL_tab0, win=$panelStr, value=_STR:""
		SetVariable svR_tab0, win=$panelStr, value=_STR:""
		bls.roi.left   = NaN
		bls.roi.right  = NaN
		bls.roi.top    = NaN
		bls.roi.bottom = NaN
		KillControl/W=$bls.Graph btnAdd_graph
		KillControl/W=$bls.Graph btnRemove_graph
	else
		SetVariable svL_tab0, win=$panelStr, value=_STR:num2str(v_left)
		SetVariable svR_tab0, win=$panelStr, value=_STR:num2str(v_right)
		bls.roi.left   = v_left
		bls.roi.right  = v_right
		bls.roi.top    = v_top
		bls.roi.bottom = v_bottom
		
		// create buttons
		GetMarquee/W=$bls.graph/Z // units are points
		SetMarqueeButtons(bls, V_left, V_top, V_right, V_bottom)
	endif
	DFREF dfr = GetPackageDFREF()
	StructPut bls dfr:w_struct

	return 0
end

// updates baseline and sub waves whenever a cursor is repositioned
// called for cursor moved event, but only when cursor is still on graph
static function CursorEvent(STRUCT BLstruct &bls, string csr)//, STRUCT WMWinHookStruct &s)
	
	if (bls.datalength==0)
		return 0
	endif

	if (bls.tab == 1)
		strswitch (csr)
			case "F" :
				bls.csr.F.x = hcsr(F); bls.csr.F.y = vcsr(F)
				return DoFit(bls)
			case "G" :
				bls.csr.G.x = hcsr(G); bls.csr.G.y = vcsr(G)
				return DoFit(bls)
			case "H" :
				bls.csr.H.x = hcsr(H); bls.csr.H.y = vcsr(H)
				return DoFit(bls)
			case "I" :
				bls.csr.I.x = hcsr(I); bls.csr.I.y = vcsr(I)
				return DoFit(bls)
			case "J" :
				bls.csr.J.x = hcsr(J); bls.csr.J.y = vcsr(J)
				return DoFit(bls)
		endswitch
	endif
	
	if (bls.subrange)
		strswitch (csr)
			case "C" :
				bls.csr.C.x = hcsr(C)
				break
			case "D" :
				bls.csr.D.x = hcsr(D)
				break
			default:
				return 0
		endswitch
		SetVariable svL win=$bls.graph+"#BL_panel", value=_NUM:bls.csr.C.x
		SetVariable svR win=$bls.graph+"#BL_panel", value=_NUM:bls.csr.D.x
		GetPointsFromCursors(bls)
		if (numtype(bls.csr.C.x + bls.csr.D.x)==0)
			DoFit(bls)
		endif
	endif

	return 0
end

// repositions cursors after graph modification
static function RepositionCursors(STRUCT BLstruct &bls)
	
	if (bls.datalength==0)
		return 0
	endif
	
	int numCursors = 1
	strswitch (bls.fitfunc)
		
		case "poly":
			numCursors = bls.polyorder
			break
		case "constant":
			numCursors = 1
			break
		default:
			numCursors = 2
	endswitch
		
	if (bls.tab == 1)
		// poly >=3 coefficients
		if (numCursors>2 && numtype(bls.csr.I.x)==0 && numtype(bls.csr.I.y)==0)
			Cursor/F/W=$bls.graph/N=1 I $bls.trace bls.csr.I.x, bls.csr.I.y
		endif
		// poly >=4 coefficients
		if (numCursors>3 && numtype(bls.csr.J.x)==0 && numtype(bls.csr.J.y)==0)
			Cursor/F/W=$bls.graph/N=1 J $bls.trace bls.csr.J.x, bls.csr.J.y
		endif
		// poly 5
		if (numCursors>4 && numtype(bls.csr.F.x)==0 && numtype(bls.csr.F.y)==0)
			Cursor/F/W=$bls.graph/N=1 F $bls.trace bls.csr.F.x, bls.csr.F.y
		endif
		// all types > 0 require >= 2 cursors
		if (numCursors>1 && numtype(bls.csr.H.x)==0 && numtype(bls.csr.H.y)==0)
			Cursor/F/W=$bls.graph/N=1 H $bls.trace bls.csr.H.x, bls.csr.H.y
		endif
		if (numtype(bls.csr.G.x)==0 && numtype(bls.csr.G.y)==0)
			Cursor/F/W=$bls.graph/N=1 G $bls.trace bls.csr.G.x, bls.csr.G.y
		endif
	endif
	
	if (bls.subrange)
		if (numtype(bls.csr.C.x) == 0)
			Cursor/F/W=$bls.graph/N=1 C $bls.trace bls.csr.C.x, 0
		endif
		if (numtype(bls.csr.D.x) == 0)
			Cursor/F/W=$bls.graph/N=1 D $bls.trace bls.csr.D.x, 0
		endif
	endif
end

// uses the mac ctrl key, not command, for node insertion.
// we call this only for mouseup event
static function ClickEvent(STRUCT BLstruct &bls, STRUCT WMWinHookStruct &s)
	
	if (bls.datalength==0 || bls.tab!=3)
		return 0
	endif
	
	variable v_key = GetKeyState(0)
	
	// remove this if we have a way to hook graphwaveedit events
	if (v_key == 0)
		return 0
	endif
	
	DFREF dfr = GetPackageDFREF()
	
	int controlkey = 16, shiftkey = 4
	#ifdef WINDOWS
	controlkey = 1
	#endif
	
	if (v_key & shiftkey) // shift click
		bls.editmode = ! bls.editmode // toggle mode
		SetEditMode(bls)
		StructPut bls dfr:w_struct
		return 0
	elseif (bls.editmode && (v_key & controlkey)) // add a node
		wave/SDFR=dfr w_nodesY, w_nodesX
		string infoStr = TraceInfo(bls.graph, bls.trace, 0)
		string xAxisName = StringByKey("XAXIS", infoStr)
		string yAxisName = StringByKey("YAXIS", infoStr)
		variable v_X = AxisValFromPixel(bls.graph, xAxisName, s.mouseLoc.h)
		variable v_Y = AxisValFromPixel(bls.graph, yAxisName, s.mouseLoc.v)
		// deal with offset
		v_Y -= bls.offset.y
		w_nodesX[numpnts(w_nodesX)] = {v_X}
		w_nodesY[numpnts(w_nodesY)] = {v_Y}
		Sort w_nodesX, w_nodesX, w_nodesY
		DoSplineFit({NaN})
	endif

	return 0
end

// fill points outside of subrange
static function PadSubrange(STRUCT BLstruct &bls, wave w_data, wave w_base)
	
	if (!bls.subrange)
		return 0
	endif
	wave/Z bl = GetBLWave(bls)
	if (WaveExists(bl)) // an output wave exists
		if (bls.endp[0] == bls.endp[1])
			w_base = bl
			return 0
		endif
		// pre-fill points outside of subrange with values from existing baseline
		if (bls.endp[0] > 0)
			w_base[0,bls.endp[0]-1] = bl[p]
		endif
		if (bls.endp[1] < (bls.datalength - 1))
			w_base[bls.endp[1]+1,bls.datalength-1] = bl[p]
		endif
		return 1
	endif
	
	if (bls.endp[0] == bls.endp[1])
		FastOp w_base = (NaN)
		return 0
	endif
	if (bls.endp[0] > 0)
		w_base[0,bls.endp[0]-1] = NaN
	endif
	if (bls.endp[1] < (bls.datalength - 1))
		w_base[bls.endp[1]+1,bls.datalength-1] = NaN
	endif
	return 1
end

// used for masked & auto fits
// making the explicit wave assignment is faster than setting a destination wave for curvefit.
// avoiding poly and Gauss1D functions improves speed
// set dofit=0 to make the wave assignment using values from global coefficient wave w_coef
static function FitFuncs(STRUCT BLstruct &bls,
	wave/Z w_data, wave/Z w_x, wave/Z w_mask, wave w_base,
	[int dofit, wave/Z/D w_coef])
	
	variable V_FitError = 0, V_fitOptions = 4
	dofit = ParamIsDefault(dofit) ? 1 : dofit
	if (!dofit && WaveExists(w_coef)==0)
		wave/D w_coef
	endif
	variable success = 1
	int ChebyshevType = 1 // set default
	try
		strswitch (bls.fitfunc)
			case "constant":
				if (dofit)
					Make/O/D w_coef = {0,0}
					CurveFit/Q/N/H="01" line, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
				endif
				// the wave assignment
				FastOp w_base = (w_coef[0])
				w_coef = {w_coef[0]}
				break
			case "line":
				if (dofit)
					CurveFit/Q/N line, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
				endif
				
				if (WaveExists(w_x))
					FastOp w_base = (w_coef[0]) + (w_coef[1]) * w_x
				elseif (bls.datalength > kMultithreadCutoff)
					multithread w_base = w_coef[0] + w_coef[1] * x
				else
					w_base = w_coef[0] + w_coef[1] * x
				endif
				break
			case "poly":
				if (dofit)
					CurveFit/Q/N poly bls.polyorder, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = poly(w_coef, w_x)
					else
						multithread w_base = poly(w_coef, x)
					endif
				elseif (WaveExists(w_x))
					w_base = poly(w_coef, w_x)
				else
					w_base = poly(w_coef, x)
				endif
				break
			case "gauss":
				if (dofit)
					CurveFit/Q/N Gauss, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="1000" Gauss, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						// a bit faster than Gauss1D function
						multithread w_base = w_coef[0] + w_coef[1] * exp(-((w_x - w_coef[2])/w_coef[3])^2)
					else
						multithread w_base = w_coef[0] + w_coef[1] * exp(-((x - w_coef[2])/w_coef[3])^2)
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0] + w_coef[1] * exp(-((w_x - w_coef[2])/w_coef[3])^2)
				else
					w_base = w_coef[0] + w_coef[1] * exp(-((x - w_coef[2])/w_coef[3])^2)
				endif
				break
			case "lor":
				if (dofit)
					CurveFit/Q/N lor, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="1000" lor, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = w_coef[0] + w_coef[1]/((w_x - w_coef[2])^2 + w_coef[3])
					else
						multithread w_base = w_coef[0] + w_coef[1]/((x - w_coef[2])^2 + w_coef[3])
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0] + w_coef[1]/((w_x - w_coef[2])^2 + w_coef[3])
				else
					w_base = w_coef[0] + w_coef[1]/((x - w_coef[2])^2 + w_coef[3])
				endif
				break
			#if IgorVersion() >= 9
			case "voigt":
				if (dofit)
					CurveFit/Q/N voigt, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="10000" voigt, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = VoigtPeak(w_coef, w_x)
					else
						multithread w_base = VoigtPeak(w_coef, x)
					endif
				elseif (WaveExists(w_x))
					w_base = VoigtPeak(w_coef, w_x)
				else
					w_base = VoigtPeak(w_coef, x)
				endif
				break
			case "dblexp_peak":
				if (dofit)
					CurveFit/Q/N dblexp_peak, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="10000" dblexp_peak, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = W_coef[0]+W_coef[1]*(-exp(-(w_x-W_coef[4])/W_coef[2])+exp(-(w_x-W_coef[4])/W_coef[3]))
					else
						multithread w_base = W_coef[0]+W_coef[1]*(-exp(-(x-W_coef[4])/W_coef[2])+exp(-(x-W_coef[4])/W_coef[3]))
					endif
				elseif (WaveExists(w_x))
					w_base = W_coef[0]+W_coef[1]*(-exp(-(w_x-W_coef[4])/W_coef[2])+exp(-(w_x-W_coef[4])/W_coef[3]))
				else
					w_base = W_coef[0]+W_coef[1]*(-exp(-(x-W_coef[4])/W_coef[2])+exp(-(x-W_coef[4])/W_coef[3]))
				endif
				break
			#endif
			case "exp":
				if (dofit)
					CurveFit/Q/N exp, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="100" exp, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = w_coef[0] + w_coef[1]*exp(-w_coef[2]*w_x)
					else
						multithread w_base = w_coef[0] + w_coef[1]*exp(-w_coef[2]*x)
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0] + w_coef[1]*exp(-w_coef[2]*w_x)
				else
					w_base = w_coef[0] + w_coef[1]*exp(-w_coef[2]*x)
				endif
				break
			case "dblexp":
				if (dofit)
					CurveFit/Q/N dblexp, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="10000" exp, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = w_coef[0]+w_coef[1]*exp(-w_coef[2]*w_x)+w_coef[3]*exp(-w_coef[4]*w_x)
					else
						multithread w_base = w_coef[0]+w_coef[1]*exp(-w_coef[2]*x)+w_coef[3]*exp(-w_coef[4]*x)
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0]+w_coef[1]*exp(-w_coef[2]*w_x)+w_coef[3]*exp(-w_coef[4]*w_x)
				else
					w_base = w_coef[0]+w_coef[1]*exp(-w_coef[2]*x)+w_coef[3]*exp(-w_coef[4]*x)
				endif
				break
			case "sin":
				if (dofit)
					CurveFit/Q/N sin, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="1000" sin, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = w_coef[0] + w_coef[1]*sin(w_coef[2]*w_x + w_coef[3])
					else
						multithread w_base = w_coef[0] + w_coef[1]*sin(w_coef[2]*x + w_coef[3])
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0] + w_coef[1]*sin(w_coef[2]*w_x + w_coef[3])
				else
					w_base = w_coef[0] + w_coef[1]*sin(w_coef[2]*x + w_coef[3])
				endif
				break
			case "hillequation":
				if (dofit)
					CurveFit/Q/N hillequation, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="1000" hillequation, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = w_coef[0]+(w_coef[1]-w_coef[0])*(w_x^w_coef[2]/(1+(w_x^w_coef[2]+w_coef[3]^w_coef[2])))
					else
						multithread w_base = w_coef[0]+(w_coef[1]-w_coef[0])*(x^w_coef[2]/(1+(x^w_coef[2]+w_coef[3]^w_coef[2])))
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0]+(w_coef[1]-w_coef[0])*(w_x^w_coef[2]/(1+(w_x^w_coef[2]+w_coef[3]^w_coef[2])))
				else
					w_base = w_coef[0]+(w_coef[1]-w_coef[0])*(x^w_coef[2]/(1+(x^w_coef[2]+w_coef[3]^w_coef[2])))
				endif
				break
			case "sigmoid":
				if (dofit)
					CurveFit/Q/N sigmoid, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="1000" sigmoid, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = w_coef[0] + w_coef[1]/(1+exp(-(w_x - w_coef[2])/w_coef[3]))
					else
						multithread w_base = w_coef[0] + w_coef[1]/(1+exp(-(x - w_coef[2])/w_coef[3]))
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0] + w_coef[1]/(1+exp(-(w_x - w_coef[2])/w_coef[3]))
				else
					w_base = w_coef[0] + w_coef[1]/(1+exp(-(x - w_coef[2])/w_coef[3]))
				endif
				break
			case "power":
				if (dofit)
					CurveFit/Q/N power, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="100" power, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = w_coef[0] + w_coef[1]*w_x^w_coef[2]
					else
						multithread w_base = w_coef[0] + w_coef[1]*x^w_coef[2]
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0] + w_coef[1]*w_x^w_coef[2]
				else
					w_base = w_coef[0] + w_coef[1]*x^w_coef[2]
				endif
				break
			#if IgorVersion() >= 9
			case "log":
				if (dofit)
					CurveFit/Q/N log, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="10" log, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = w_coef[0] + w_coef[1]*log(w_x)
					else
						multithread w_base = w_coef[0] + w_coef[1]*log(x)
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0] + w_coef[1]*log(w_x)
				else
					w_base = w_coef[0] + w_coef[1]*log(x)
				endif
				break
			#endif
			case "lognormal":
				if (dofit)
					CurveFit/Q/N lognormal, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					if (bls.peak)
						w_coef[0] = bls.base
						CurveFit/Q/N/H="1000" lognormal, kwCWave=w_coef, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = w_coef[0] + w_coef[1]*exp(-(ln(w_x/w_coef[2])/w_coef[3])^2)
					else
						multithread w_base = w_coef[0] + w_coef[1]*exp(-(ln(x/w_coef[2])/w_coef[3])^2)
					endif
				elseif (WaveExists(w_x))
					w_base = w_coef[0] + w_coef[1]*exp(-(ln(w_x/w_coef[2])/w_coef[3])^2)
				else
					w_base = w_coef[0] + w_coef[1]*exp(-(ln(x/w_coef[2])/w_coef[3])^2)
				endif
				break
				
			case "Planck":
				if (dofit)
					CurveFit/Q/N Gauss, w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					wave/D w_coef
					W_coef = {5000,(w_coef[0]+w_coef[1])/3e13}
					
					// FuncFit won't work with the funcref
					switch (bls.wavelength)
						case 2:
							FuncFit/Q/N baselines#PlanckmuM w_coef w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
							break
						case 3:
							FuncFit/Q/N baselines#PlanckWN w_coef w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
							break
						case 4:
							FuncFit/Q/N baselines#PlanckAngstrom w_coef w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
							break
						default:
							FuncFit/Q/N baselines#Planck w_coef w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endswitch
				endif
				if (bls.datalength > kMultithreadCutoff)
					if (WaveExists(w_x))
						multithread w_base = planck(w_coef, wl2nm(bls, w_x))
					else
						multithread w_base = planck(w_coef, wl2nm(bls, x))
					endif
				elseif (WaveExists(w_x))
					w_base = planck(w_coef, wl2nm(bls, w_x))
				else
					w_base = planck(w_coef, wl2nm(bls, x))
				endif
				break
			case "spline":
				
				if (bls.datalength < 4)
					FastOp w_base = (NaN)
					return 0
				endif
				
				#if (IgorVersion() < 9)
				if (WaveExists(w_x))
					Duplicate/free w_x w_x2 // source and destination must be different
					if (WaveType(w_base, 2)==2) // free wave, fitting a subrange
						Duplicate/free w_base w_2
						Interpolate2/T=3/I=3/F=1/S=(bls.sd)/X=w_x2/Y=w_2 w_x, w_data; AbortOnRTE
						FastOp w_base = w_2
					else
						Interpolate2/T=3/I=3/F=1/S=(bls.sd)/X=w_x2/Y=w_base w_x, w_data; AbortOnRTE
					endif
				elseif (WaveType(w_base, 2)==2) // free wave, fitting a subrange
					Duplicate/free w_base w_2
					Interpolate2/T=3/I=3/F=1/S=(bls.sd)/Y=w_2 w_data; AbortOnRTE
					FastOp w_base = w_2
				else
					Interpolate2/T=3/I=3/F=1/S=(bls.sd)/Y=w_base w_data; AbortOnRTE
				endif
				#else
				if (WaveExists(w_x))
					Interpolate2/T=3/I=3/F=1/S=(bls.sd)/X=w_x/Y=w_base w_x, w_data; AbortOnRTE
				else
					Interpolate2/T=3/I=3/F=1/S=(bls.sd)/Y=w_base w_data; AbortOnRTE
				endif
				#endif

				break
			case "Chebyshev2":
				ChebyshevType = 2
			case "Chebyshev":
				Duplicate/free w_data w_relx
				variable xmin = WaveExists(w_x) ? w_x[0] : leftx(w_data)
				variable xmax = WaveExists(w_x) ? w_x[numpnts(w_x)-1] : pnt2x(w_data,numpnts(w_data)-1)
				w_relx = 2*((WaveExists(w_x) ? w_x : x) - xmin)/(xmax-xmin) - 1
				
				int numCoef = bls.cheborder + 1
				numCoef = min(WaveExists(w_mask)? sum(w_mask) : numpnts(w_data), numCoef)

				Make/O/D/N=(numCoef) w_coef = 1 / (x+1)
				if (ChebyshevType == 2)
					FuncFit/Q/N baselines#ChebyshevSeries2 w_coef w_data /M=w_mask/X=w_relx/NWOK; AbortOnRTE
					ChebyshevSeries2(w_coef, w_base, w_relx)
				else
					FuncFit/Q/N baselines#ChebyshevSeries w_coef w_data /M=w_mask/X=w_relx/NWOK; AbortOnRTE
					ChebyshevSeries(w_coef, w_base, w_relx)
				endif
				
				break
			default:
				
				int AllAtOnce = 0
				
				FUNCREF BaselineGuessPrototype GuessFunc = $bls.fitfunc+"Guess"
				if (NumberByKey("ISPROTO", FuncRefInfo(GuessFunc)))
					return 0
				endif
				
				FUNCREF BaselineFitPrototype FitFunc = $bls.FitFunc
				if (NumberByKey("ISPROTO", FuncRefInfo(FitFunc)))
					
					// check for All At Once fit function
					FUNCREF BaselineFitAAWPrototype FitFuncAAW = $bls.fitfunc
					if (NumberByKey("ISPROTO", FuncRefInfo(FitFuncAAW)))
						return 0
					else
						AllAtOnce = 1
					endif
				endif
				
				if (dofit)
					GuessFunc(w_data, w_x, w_mask)
					wave/D w_coef
					if (AllAtOnce)
						FuncFit/Q/N FitFuncAAW w_coef w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					else
						FuncFit/Q/N FitFunc w_coef w_data /M=w_mask/X=w_x/NWOK; AbortOnRTE
					endif
				endif
				
				if (AllAtOnce)
					FitFuncAAW(W_coef, w_base, w_x)
				elseif (WaveExists(w_x))
					w_base = FitFunc(W_coef, w_x)
				else
					w_base = FitFunc(W_coef, x)
				endif
				break
		endswitch
	catch
		if (V_AbortCode == -4)
			// Clear the error silently.
			variable CFerror = GetRTError(1)	// 1 to clear the error
			#ifdef debug
			Print "Error during curve fit:", GetErrMessage(CFerror)
			#endif
			FastOp w_base = (NaN)
		endif
		success = 0
	endtry
	
	success = V_FitError ? 0 : success
	return success
end

threadsafe static function ChebyshevSeries(wave cw, wave w_poly, wave w_xrel)
	variable i
	int order = numpnts(cw)
	FastOp w_poly = 0
	for (i=0;i<(order);i++)
		w_poly += cw[i] * chebyshev(i, w_xrel)
	endfor
end

threadsafe static function ChebyshevSeries2(wave cw, wave w_poly, wave w_xrel)
	variable i
	int order = numpnts(cw)
	FastOp w_poly = 0
	for (i=0;i<(order);i++)
		w_poly += cw[i] * chebyshevU(i, w_xrel)
	endfor
end

// Find best fit Chebyshev polynomial though nodes
static function FitChebyshevSeries(int order, int type, wave w_nodesX, wave w_nodesY, wave w_base, [wave/Z xwave])
	// because we want to be able to output values over the entire baseline range,
	// we transform x values using the baseline max/min
	Duplicate/free w_nodesX w_relx
	variable xmin =  WaveExists(xwave) ? WaveMin(xwave) : leftx(w_base)
	variable xmax = WaveExists(xwave) ? WaveMax(xwave) : pnt2x(w_base,numpnts(w_base)-1)
	w_relx = 2*(w_nodesX - xmin)/(xmax-xmin) - 1
	Make/O/D/N=(min(order + 1, numpnts(w_nodesX))) w_coef = 1 / (x+1)
	try
		if (type == 2)
			FuncFit/Q/N baselines#ChebyshevSeries2 w_coef w_nodesY /X=w_relx/NWOK; AbortOnRTE
		else
			FuncFit/Q/N baselines#ChebyshevSeries w_coef w_nodesY /X=w_relx/NWOK; AbortOnRTE
		endif
	catch
		if (V_AbortCode == -4)
			// Clear the error silently.
			variable CFerror = GetRTError(1)	// 1 to clear the error
			#ifdef debug
			Print "Error during Chebyshev fit:", GetErrMessage(CFerror)
			#endif
			FastOp w_base = (NaN)
		endif
		return 0
	endtry
	Duplicate/free/O w_base w_relx
	w_relx = 2*((WaveExists(xwave) ? xwave : x) - xmin)/(xmax-xmin) - 1
	if (type == 2)
		ChebyshevSeries2(w_coef, w_base, w_relx)
	else
		ChebyshevSeries(w_coef, w_base, w_relx)
	endif

end

// this is inefficient for a wave assignment, but useful if you need just a few values
// no check for inappropriate funtion!
// used only for manual baseline types.
static function GetFitValue(STRUCT BLstruct &bls, variable x)

	wave/Z w_coef
	if (!WaveExists(w_coef))
		return NaN
	endif
	strswitch (bls.fitfunc)
		case "constant":
			return w_coef[0]
		case "line":
		case "tangent":
			return w_coef[0] + w_coef[1]*x
		case "poly":
			return poly(w_coef, x)
		case "gauss":
			return w_coef[0] + w_coef[1]*exp(-((x - w_coef[2])/w_coef[3])^2)
		case "lor":
			return w_coef[0] + w_coef[1]/((x-w_coef[2])^2 + w_coef[3])
		#if IgorVersion() >= 8
		case "voigt":
			return VoigtPeak(w_coef, x)
		#endif
		case "exp":
			return w_coef[0] + w_coef[1]*exp(-w_coef[2]*x)
		case "dblexp":
			return w_coef[0] + w_coef[1]*exp(-w_coef[2]*x) + w_coef[3]*exp(-w_coef[4]*x)
		case "dblexp_peak":
			return W_coef[0] + w_coef[1]*(-exp(-(x-w_coef[4])/w_coef[2]) + exp(-(x-w_coef[4])/w_coef[3]))
		case "sin":
			return w_coef[0] + w_coef[1]*sin(w_coef[2]*x + w_coef[3])
		case "hillequation":
			return w_coef[0] + (w_coef[1]-w_coef[0])*(x^w_coef[2]/(1+(x^w_coef[2]+w_coef[3]^w_coef[2])))
		case "sigmoid":
			return w_coef[0] + w_coef[1]/(1+exp(-(x-w_coef[2])/w_coef[3]))
		case "power":
			return w_coef[0] + w_coef[1]*x^w_coef[2]
		case "log":
			return w_coef[0] + w_coef[1]*log(x)
		case "lognormal":
			return w_coef[0] + w_coef[1]*exp(-(ln(x/w_coef[2])/w_coef[3])^2)
		case "Chebyshev":
			Abort // no can do unless we know the bounding x values for the fit
			break
		case "Chebyshev2":
			Abort
			break
		default:

			FUNCREF BaselineFitPrototype FitFunc = $bls.FitFunc
			if (NumberByKey("ISPROTO", FuncRefInfo(FitFunc)) == 0)
				return FitFunc(W_coef, x)
			endif
			
			// if w_base has been assigned, maybe we can grab a value from there
			wave/SDFR=GetPackageDFREF() w_base
			wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
			return GetYfromWavePair(x, w_base, w_x) // defaults to w_base(x)
	endswitch
end

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
	wave/Z w, w_x, w_rgb
	variable matchOffset, offset // match y offset, set Y offset
	int matchRGB // match color of already plotted trace
	variable fill // opacity for fill to zero
	variable lsize
	int unique, replace
	
	matchOffset = ParamIsDefault(matchOffset) ? 0 : matchOffset
	offset = ParamIsDefault(offset) ? 0 : offset
	matchRGB = ParamIsDefault(matchRGB) ? 0 : matchRGB
	fill = ParamIsDefault(fill) ? 0 : min(fill, 1)
	lsize = ParamIsDefault(lsize) ? 1 : lsize
	unique = ParamIsDefault(unique) ? 0 : unique
	replace = ParamIsDefault(replace) ? 0 : replace
	
	string s_info = TraceInfo(graphStr, traceStr, 0)
	string s_Xax = StringByKey("XAXIS",s_info)
	string s_Yax = StringByKey("YAXIS",s_info)
	string s_flags = StringByKey("AXISFLAGS",s_info)
	variable flagBits = GrepString(s_flags, "/R") + 2*GrepString(s_flags, "/T")
	
	offset = matchOffset & 1 ? GetOffsetFromInfoString(s_info, 1) : offset
	variable muloffset = matchOffset & 2 ? GetMulOffsetFromInfoString(s_info, 1) : 0
	
	// get color of already plotted trace
	variable c0, c1, c2
	sscanf ListMatch(s_info, "rgb(x)=*"), "rgb(x)=(%d,%d,%d", c0, c1, c2
	
	if (matchRGB==0 && ParamIsDefault(w_rgb)) // no color specified
		wave w_rgb = ContrastingColor({c0,c1,c2})
	elseif (matchRGB) // this overides any specified color
		Make/free/O w_rgb = {c0,c1,c2}
	endif
	
	int i, numTraces
	string traces, trace
	if (unique)
		traces = TraceNameList(graphStr,";",1)
		for (i=ItemsInList(traces)-1;i>=0;i-=1)
			trace = StringFromList(i,traces)
			wave/Z ithTraceWave = TraceNameToWaveRef(graphStr, trace)
			if (WaveRefsEqual(ithTraceWave, w))
				RemoveFromGraph/W=$graphStr/Z $trace
			endif
		endfor
	endif
	
	switch (flagBits)
		case 0:
			if (WaveExists(w_x))
				AppendToGraph/W=$graphStr/B=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w vs w_x
			elseif (DimSize(w,1)==2)
				AppendToGraph/W=$graphStr/B=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w[][1] vs w[][0]
			else
				AppendToGraph/W=$graphStr/B=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w
			endif
			break
		case 1:
			if (WaveExists(w_x))
				AppendToGraph/W=$graphStr/B=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w vs w_x
			elseif (DimSize(w,1)==2)
				AppendToGraph/W=$graphStr/B=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w[][1] vs w[][0]
			else
				AppendToGraph/W=$graphStr/B=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w
			endif
			break
		case 2:
			if (WaveExists(w_x))
				AppendToGraph/W=$graphStr/T=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w vs w_x
			elseif (DimSize(w,1)==2)
				AppendToGraph/W=$graphStr/T=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w[][1] vs w[][0]
			else
				AppendToGraph/W=$graphStr/T=$s_Xax/L=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w
			endif
			break
		case 3:
			if (WaveExists(w_x))
				AppendToGraph/W=$graphStr/T=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w vs w_x
			elseif (DimSize(w,1)==2)
				AppendToGraph/W=$graphStr/T=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w[][1] vs w[][0]
			else
				AppendToGraph/W=$graphStr/T=$s_Xax/R=$s_Yax/C=(w_rgb[0],w_rgb[1],w_rgb[2]) w
			endif
			break
	endswitch
		
	// figure out trace name, may not be unique.
	string strNewTrace = TraceNameList(graphStr, ";", 1)
	strNewTrace = StringFromList(ItemsInList(strNewTrace)-1, strNewTrace)
	
	ModifyGraph/W=$graphStr offset($strNewTrace)={0,offset}, lsize($strNewTrace)=lsize, muloffset($strNewTrace)={0,muloffset}
	
	if (fill > 0)
		ModifyGraph/W=$graphStr mode($strNewTrace)=7, hbFill($strNewTrace)=2
		ModifyGraph/W=$graphStr usePlusRGB($strNewTrace)=1, plusRGB($strNewTrace)=(w_rgb[0],w_rgb[1],w_rgb[2],fill*65535)
		ModifyGraph/W=$graphStr useNegRGB($strNewTrace)=1, negRGB($strNewTrace)=(w_rgb[0],w_rgb[1],w_rgb[2],fill*65535)
		ReorderTraces/W=$graphStr _back_, {$strNewTrace}
	endif
	
	if (replace)
		RemoveFromGraph/W=$graphStr traceStr
	endif
end

static function GetOffsetFromInfoString(string s, int axis)
	variable xOffset, yOffset
	sscanf ListMatch(s, "offset(x)=*"), "offset(x)={%g,%g}", xOffset, yOffset
	return axis ? yOffset : xOffset
end

static function GetMulOffsetFromInfoString(string s, int axis)
	variable xOffset, yOffset
	sscanf ListMatch(s, "muloffset(x)=*"), "muloffset(x)={%g,%g}", xOffset, yOffset
	return axis ? yOffset : xOffset
end

// execute Baselines#makeSpectrum() to create a fake spectrum for demo
static function MakeSpectrum([int n, int points])

	n = ParamIsDefault(n) ? 1 : n
	points = ParamIsDefault(points) ? 200 : points

	variable numPeaks = 5 // number of Gaussian peaks in the spectrum
	string strName
	variable a, b, c, d, i, j, height, position, width
	Make/free/T colornames = {"red", "green", "blue", "maroon", "teal"}
	
	STRUCT point screenOrigin
	GetScreenOrigin(screenOrigin)
	
	
	Display/K=1/W=(screenOrigin.h+100, screenOrigin.v+100, screenOrigin.h+600, screenOrigin.v+450)
	for(i=0;i<n;i+=1)
		strName = UniqueName("foo", 1, 0)
		Make/N=(points) $(UniqueName("foo", 1, 0)) /WAVE=foo
		SetScale/I x, 0, 1000, foo
		a = enoise(5); b = enoise(1e-3); c = enoise(1e-5); d = enoise(400)
		foo = gnoise(0.1) + a + b * x + c * (x - d)^2
		for(j=0;j<numPeaks;j+=1)
			height = 150 + enoise(50)
			position = 500 + enoise(400)
			width = 20 + enoise(10)
			foo += height * Gauss(x, position, width/sqrt(2))
		endfor
		wave color = ColorWave(colornames[mod(i,5)])
		AppendToGraph/C=(color[0],color[1],color[2]) foo
	endfor
end

// status 0: reset to saved colors
// status 1: set all to grey
// status 2: save current
// status 3: save current and set all to grey
static function ResetColors(STRUCT BLstruct &bls, int status)
	
	if (bls.options & 0x20)
		return 0
	endif
		
	DFREF dfr = GetPackageDFREF()
	string traceStr = bls.trace
	int i, numTraces
		
	if (status == 0) // reset to saved
		wave/Z/T w_traces = dfr:w_traces
		wave/Z w_colors = dfr:w_colors
		if (WaveExists(w_colors)==0)
			return 0
		endif
		numTraces = numpnts(w_traces)
		for(i=0;i<numTraces;i+=1)
			ModifyGraph/W=$bls.graph/Z rgb($w_traces[i])=(w_colors[i][0],w_colors[i][1],w_colors[i][2])
		endfor
		return 1
	endif
	
	if (status & 1) // define grey color
		wave wGrey = ColorWave("grey")
	endif
		
	if (status & 2) // save current
		Make/O/N=0/T dfr:w_traces /wave=w_traces
		Make/O/N=(0,3) dfr:w_colors /wave=w_colors
	else
		wave/Z/T w_traces = dfr:w_traces
		wave/Z w_colors = dfr:w_colors
	endif
	
	string traceListStr = TraceNameList(bls.graph, ";", 1+4)
	numTraces = ItemsInList(traceListStr)
		
	for(i=0;i<numTraces;i+=1)
		traceStr = StringFromList(i,traceListStr)
		if (status & 2) // save current
			w_traces[i] = {traceStr}
			wave w_rgb = GetTraceColor(bls.graph, traceStr)
			w_colors[i][]={{w_rgb[0]},{w_rgb[1]},{w_rgb[2]}}
		elseif (WaveExists(w_traces))
			// check to see if a trace has been added since the list was created
			FindValue/TEXT=traceStr/TXOP=4/Z w_traces
			if (V_Value == -1)
				w_traces[numpnts(w_traces)]={traceStr}
				wave w_rgb = GetTraceColor(bls.graph, traceStr)
				w_colors[DimSize(w_colors, 0)][] = {{w_rgb[0]},{w_rgb[1]},{w_rgb[2]}}
			endif
		endif
		if (status & 1) // set to grey
			ModifyGraph/W=$bls.graph/Z rgb($traceStr)=(wGrey[0],wGrey[1],wGrey[2])
		endif
	endfor
end

// use this to restore the saved color of a single trace
static function RestoreTraceColor(STRUCT BLstruct &bls)
	
	if (bls.options & 0x20)
		return 0
	endif
	
	DFREF dfr = GetPackageDFREF()
	wave/T/Z w_traces = dfr:w_traces
	wave/Z w_colors = dfr:w_colors
	wave rgb = ColorWave("plum")
	
	FindValue/TEXT=bls.trace/Z w_traces
	if (V_value > -1)
		wave w = ColorWave("grey")
		w = abs(w - w_colors[V_Value][p])
		if (sum(w) > 30000) // not too close to grey
			rgb = w_colors[V_value][p]
		endif
	endif
	ModifyGraph/W=$bls.graph/Z rgb($bls.trace)=(rgb[0],rgb[1],rgb[2])
end

static function/WAVE GetTraceColor(string graphStr, string traceStr)
	variable c0, c1, c2
	string infoStr = TraceInfo(graphStr, traceStr, 0)
	variable startIndex = strsearch(infoStr, ";rgb(x)=", 0)
	if (startIndex == -1)
		return $"{}"
	endif
	sscanf infoStr[startIndex,strlen(infoStr)-1], ";rgb(x)=(%d,%d,%d*", c0, c1, c2
	Make/I/U/free w_rgb={c0,c1,c2}
	return w_rgb
end

// default colors are defined here
static function/WAVE ColorWave(string color)
	Make/I/U/free w = {0x0000,0x0000,0x0000}
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

static function/wave ContrastingColor(wave RGB)
	wave hsl = RGB2HSL(rgb)
	if (hsl[1] < 0.3) // low saturation, make it red
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

// select a color midway between the hues of trace and baseline
static function/wave ChooseCursorColor(STRUCT BLstruct &bls)
	wave hsl = RGB2HSL(GetTraceColor(bls.graph, bls.trace))
	if (HSL[2] > 0.5) // high luminosity, make it black
		return ColorWave("black")
	endif
	if (HSL[1] < 0.3) // low saturation, make it green
		return ColorWave("green")
	endif
	variable hue = round(6*HSL[0])
	hue -= 6 * (hue > 5)
	switch (hue) // select a contrasting hue
		case 0: // red & cyan
			return ColorWave("magenta")
		case 1: // yellow & blue
			return ColorWave("red")
		case 2: // lime & magenta
			return ColorWave("blue")
		case 3: // cyan & red
		case 4: // blue & orange
			return ColorWave("lime")
		case 5: // magenta & lime
			return ColorWave("orange")
	endswitch
	return ColorWave("none")
end

// converts 16 bit sRGB to HSL
static function/WAVE RGB2HSL(wave rgbInt)
	Make/free/N=3 hsl, rgb, rgbDelta
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

// *** spline specific functions ***

static function SetEditMode(STRUCT BLstruct &bls)
	if (bls.editmode)
		// manually scale y axis
		string strYax = StringByKey("YAXIS", TraceInfo(bls.graph, "w_nodesY", 0))
		if (strlen(strYax) == 0)
			bls.editmode = 0
			SetEditMode(bls)
			DFREF dfr = GetPackageDFREF()
			StructPut bls dfr:w_struct
			return 0
		endif
		
		GetAxis/W=$bls.graph/Q $strYax
		SetAxis/W=$bls.graph $strYax, V_min, V_max
		ModifyGraph/Z/W=$bls.graph mode(w_nodesY)=3, marker(w_nodesY)=11
		GraphWaveEdit/W=$bls.graph/NI/T=1/M $"w_nodesY"
	else
		GraphNormal/W=$bls.graph
		ModifyGraph/Z/W=$bls.graph mode(w_nodesY)=2
	endif
	CheckBox chkEdit_tab3 win=$bls.graph+"#BL_panel", value=bls.editmode
	
	ControlInfo/W=$bls.Graph btnEdit_graph
	if (v_flag)
		string strTitle = ""
		sprintf strTitle, "\\K(%d,%d,0)Edit mode %s", 0xFFFF*bls.editmode, 0xFFFF*(!bls.editmode), SelectString(bls.editmode, "off", "on")
		Button btnEdit_graph, win=$bls.Graph, title=strTitle
	endif
end

// stop Y axis from rescaling during fit
static function HoldYaxis(STRUCT BLstruct &bls)
	string strYax = StringByKey("YAXIS", TraceInfo(bls.graph, bls.trace, 0))
	if (strlen(strYax) == 0)
		return 0
	endif
	GetAxis/W=$bls.graph/Q $strYax
	SetAxis/W=$bls.graph $strYax, V_min, V_max
	return 1
end

// dependency function to define the spline curve
static function DoSplineFit(wave w)
		
	DFREF dfr = GetPackageDFREF()
	wave/Z/SDFR=dfr w_nodesX, w_nodesY, w_base, w_sub
	
	STRUCT BLstruct bls
	StructGet bls dfr:w_struct
	
	if (strlen(bls.graph)==0 || bls.tab!=3 || bls.datalength==0)
		return NaN
	endif
	
	wave/Z w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	
	if (WaveExists(w_data) == 0)
		return NaN
	elseif (numpnts(w_nodesX) < 2)
		return NaN
	elseif (numpnts(w_data) != numpnts(w_base))
		// could arrive here if we trigger an update before popup runs updateGraph
		return NaN
	endif
	
	int typeAkima = 0, typePCHIP = 0, typeSmoothing = 0, typeLinear = 0, typeChebyshev = 0
	
	if (cmpstr(bls.fitfunc, "cubic spline") == 0)
		// this is default option
	elseif (cmpstr(bls.fitfunc, "Akima spline") == 0)
		typeAkima = 1
	elseif (cmpstr(bls.fitfunc, "PCHIP") == 0)
		typePCHIP = 1
	elseif (cmpstr(bls.fitfunc, "linear") == 0)
		typeLinear = 1
	elseif (cmpstr(bls.fitfunc, "smoothing") == 0)
		typeSmoothing = 1
	elseif (cmpstr(bls.fitfunc, "Chebyshev") == 0)
		typeChebyshev = 1
	elseif (cmpstr(bls.fitfunc, "Chebyshev2") == 0)
		typeChebyshev = 2
	else
		return NaN
	endif
	
	if (typeAkima && numpnts(w_nodesX)<5)
		DoAlert 0, "Akima spline requires at least 5 nodes - resetting node positions."
		ResetNodes(bls)
	endif

	// do the spline calculation
	if (typeAkima) // Akima type spline
		Akima(w_nodesX, w_nodesY, w_base, xwave=w_x)
	elseif (typePCHIP) // PCHIP
		PCHIP(w_nodesX, w_nodesY, w_base, xwave=w_x)
	elseif (typeChebyshev)
		FitChebyshevSeries(bls.cheborder, typeChebyshev, w_nodesX, w_nodesY, w_base, xwave=w_x)
	else
		int flagT = 2, flagE = 2 // cubic spline with 'natural' ends
		// since we can manually position the nodes, it doesn't matter
		// which constraint we use to define the ends.

		// check for small number of points
		if (typeLinear || numpnts(w_nodesX)<4) // linear
			flagT = 1 // don't change bls.type, so will revert to desired type as nodes are added
		elseif (typeSmoothing) // smoothing
			flagT = 3
		endif
		
		DebuggerOptions
		variable sav_debug = V_debugOnError
		DebuggerOptions debugOnError = 0 // switch this off in case interpolate fails
		try
			if (bls.XY)
				Interpolate2/E=(flagE)/F=(bls.flagF)/T=(flagT)/I=3/X=w_x/Y=w_base w_nodesX, w_nodesY; AbortOnRTE
			else
				Interpolate2/E=(flagE)/F=(bls.flagF)/T=(flagT)/I=3/Y=w_base w_nodesX, w_nodesY; AbortOnRTE
			endif
		catch
			variable CFerror = GetRTError(1)
			Print "Error during interpolate:", GetErrMessage(CFerror)
		endtry
		DebuggerOptions debugOnError=sav_debug
	endif
	
	if (bls.subrange)
		PadSubrange(bls, w_data, w_base)
	endif
		
	FastOp w_sub = w_data - w_base + (bls.base)
	UpdateSplineWaveNote(bls)
	
	return 1
end

static function UpdateSplineWaveNote(STRUCT BLstruct &bls)
	
	DFREF dfr = GetPackageDFREF()
	wave/SDFR=dfr w_nodesX, w_base
	string strNote = "Baseline Parameters:type=interpolated;"
	
	strNote += "function=" + bls.fitfunc + ";"
	
	if (cmpstr((bls.fitfunc)[0,8], "Chebyshev") == 0)
		strNote += CoefficientString()
	endif
			
	strNote += "numNodes=" + num2str(numpnts(w_nodesX)) + ";"
	
	if (cmpstr(bls.fitfunc, "smoothing") == 0)
		strNote += "F=" + num2str(bls.flagF) + ";"
	endif
		
	if (bls.subrange)
		wave w_data = TraceNameToWaveRef(bls.graph, bls.trace)
		wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
		variable x1 = bls.XY ? w_x[0] : pnt2x(w_data, bls.endp[0])
		variable x2 = bls.XY ? w_x[numpnts(w_x) - 1] : pnt2x(w_data, bls.endp[1])
		sprintf strNote, "%soutput range=(%g,%g);", strNote, min(x1, x2), max(x1, x2)
	endif
	
	note/K w_base strNote
	if (bls.info)
		wave listwave = dfr:listwave
		UpdateListwave(strNote, listwave)
	endif
end

static function UpdateListWave(string strNote, wave/T listwave)
	int p1, p2, p3
	p1 = 20
	Redimension/N=(0,2) listwave
	do
		p2 = strsearch (strNote, "=", p1)
		if (p2 == -1)
			break
		endif
		p3 = strsearch(strNote, ";", p2)
		p3 = p3 == -1 ? strlen(strNote) - 1 : p3
		listwave[DimSize(listwave, 0)][] = {{strNote[p1,p2-1]},{strNote[p2+1,p3-1]}}
		p1 = p3 + 1
	while(1)
	return 1
end

static function ResetNodes(STRUCT BLstruct &bls, [int OnTrace])
	
	if (bls.datalength == 0)
		RemoveFromGraph/W=$bls.graph/Z w_nodesY
		return 0
	endif
	
	DFREF dfr = GetPackageDFREF()
	wave/SDFR=dfr w_nodesX, w_nodesY, w_base

	// define some local variables
	variable i, p_low, p_high, delP, delX
	variable trace_offset = 0
	
	wave w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	Redimension/N=(bls.nodes) w_nodesX, w_nodesY
	
	// determine axis names
	string strInfo = TraceInfo(bls.graph,bls.trace,0)
	string xAxisName = StringByKey("XAXIS", strInfo)
	string yAxisName = StringByKey("YAXIS", strInfo)
	
	// determine where to place nodes on the bottom axis
	
	// keep nodes within window
	GetAxis/Q $xAxisName
	Make/N=2/free xrange={v_min, v_max}
	Sort xrange, xrange
	
	GetAxis/Q $yAxisName
	Make/N=2/free yrange={v_min, v_max}
	Sort yrange, yrange
	
	// keep nodes within extent of w_data
	if (bls.XY)
		xrange[0] = max(xrange[0], WaveMin(w_x))
		xrange[1] = min(xrange[1], WaveMax(w_x))
	else
		xrange[0] = max(xrange[0], min(pnt2x(w_data, 0), pnt2x(w_data, numpnts(w_data)-1)) )
		xrange[1] = min(xrange[1], max(pnt2x(w_data, 0), pnt2x(w_data, numpnts(w_data)-1)) )
	endif
	
	// inset nodes a little
	delX = (xrange[1] - xrange[0]) / 50
	xrange[0] += delX
	xrange[1] -= delX
	delX = (xrange[1] - xrange[0]) / (bls.nodes - 1)
	// initialize node positions
	w_nodesX = xrange[0] + p * delX
	
	onTrace = ParamIsDefault(OnTrace) ? bls.options & 0x10 : OnTrace
	
	if (onTrace == 0)
		FastOp w_base = w_data
		onTrace = !GuessNodePositions(bls, w_data, w_x, w_base, w_nodesX, w_nodesY)
	endif
	
	if (onTrace)
		if (bls.XY)
			w_nodesY = GetYfromWavePair(w_nodesX, w_data, w_x)
		else
			w_nodesY = w_data(w_nodesX)
		endif
	endif
	
	// Akima calculation won't work if nodes are reverse sorted
	Sort w_nodesX, w_nodesX, w_nodesY
	
	// if data are offset, then apply offsets to nodes
	sscanf ListMatch(strInfo, "offset(x)=*"), "offset(x)={%*g,%g}", trace_offset
	
	// keep nodes within window
	w_nodesY = limit(w_nodesY, yrange[0]-trace_offset, yrange[1]-trace_offset)
	
	if (bls.tab == 3)
		// make sure nodes are plotted on correct axes
		AppendToSameAxes(bls.graph, bls.trace, w_nodesY, w_nodesX, matchOffset=1+2*kAllowMuloffset, unique=1)
		bls.editmode = 1
		SetEditMode(bls) // also sets mode for nodes trace
	endif
	
	string strNote = bls.trace
	note/K w_nodesY, strNote
		
	return 1
end

// populate w_nodesY with guesses for a baseline
// all points of w_nodesX must lie within x-range of data
static function GuessNodePositions(STRUCT BLstruct &bls, wave w_data, wave/Z w_x, wave w_base, wave w_nodesX, wave w_nodesY)
	
	DFREF dfr = GetPackageDFREF()
	StructPut bls dfr:w_struct // save current settings
	
	// adjust settings for an ArcHull type fit
	bls.smoothing = 30
	bls.depth = (WaveMax(w_data) - WaveMin(w_data)) * ((bls.options&8) ? -0.15 : 0.15)
	bls.fitfunc = "arc hull"
	
	DoArcHull(bls, w_data, w_x, w_base)
		
	StructGet bls dfr:w_struct // reload saved settings
	
	if (WaveExists(w_x))
		Interpolate2/T=1/Y=w_nodesY/X=w_nodesX/I=3 w_x, w_base
	else
		w_nodesY = w_base(w_nodesX)
	endif
	return 1
end

// place nodes on w_data.
// doesn't reset x positions unless they're out of range.
static function SetNodes(STRUCT BLstruct &bls, [int OnTrace])
	
	if (bls.datalength == 0)
		RemoveFromGraph/W=$bls.graph/Z w_nodesY
		return 0
	endif
	
	wave/Z w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	
	DFREF dfr = GetPackageDFREF()
	wave/SDFR=dfr w_nodesX, w_nodesY, w_base
	variable numNodes = numpnts(w_nodesY)
	
	if (numNodes < 2)
		return ParamIsDefault(OnTrace) ? ResetNodes(bls) : ResetNodes(bls, OnTrace=OnTrace)
	endif
	
	if (cmpstr(bls.trace, note(w_nodesY)) || ParamIsDefault(OnTrace)==0)
		// keep nodes within x-range of data
		variable xmax = bls.XY ? WaveMax(w_x) : max(pnt2x(w_data, 0), pnt2x(w_data, bls.datalength-1))
		variable xmin = bls.XY ? WaveMin(w_x) : min(pnt2x(w_data, 0), pnt2x(w_data, bls.datalength-1))
		w_nodesX = min(xmax, max(xmin, w_nodesX))
		
		if (bls.XY)
			w_nodesY = GetYfromWavePair(w_nodesX, w_data, w_x)
		else
			w_nodesY = w_data(w_nodesX)
		endif
				
		// remove duplicate nodes,
		// in case some were outside of the range of w_data
		Duplicate/free w_nodesX w_duplicates
		FindDuplicates/SN=(NaN)/SNDS=w_duplicates w_nodesX
		Extract/O w_nodesX, w_nodesX, numtype(w_duplicates)==0
		Extract/O w_nodesY, w_nodesY, numtype(w_duplicates)==0
	endif
	
	onTrace = ParamIsDefault(OnTrace) ? bls.options & 0x10 : OnTrace
	
	if (numpnts(w_nodesX) < 2)
		ResetNodes(bls)
		if (bls.tab==3)
			DoAlert 0, "Nodes couldn't be placed on " + NameOfWave(w_data) + " at the same x positions. Nodes have been reset."
		endif
	else
		if (OnTrace == 0)
			GuessNodePositions(bls, w_data, w_x, w_base, w_nodesX, w_nodesY)
		endif
			
		if (bls.tab == 3)
			// make sure nodes are plotted on correct axes
			AppendToSameAxes(bls.graph, bls.trace, w_nodesY, w_nodesX, matchOffset=1+2*kAllowMuloffset, unique=1)
			SetEditMode(bls) // also sets mode for nodes trace
		endif
	endif
	
	string strNote = bls.trace
	note/K w_nodesY, strNote
	return 1
end

static function LoadNodes(STRUCT BLstruct &bls)
	
	if (bls.datalength == 0)
		return 0
	endif
	
	DFREF dfr = GetPackageDFREF()
	DFREF listDFR = GetOutputDataFolder(bls)
	string str_NodeWave
	variable selection
	
	Prompt str_NodeWave, "Select saved nodes", Popup, WaveListDFR("*",";","DIMS:2",listDFR) + "From file;"
	
	Prompt selection, " ", Popup, "Load X positions only;Load X and Y positions;"
	DoPrompt "", str_NodeWave, selection
	if (V_Flag)
		return 0
	endif
	int loadY = selection == 2
	
	if (cmpstr(str_NodeWave, "From file") == 0)
		return ImportNodes("", loadY=loadY)
	endif
	
	wave/Z w_nodes = listDFR:$str_NodeWave
	if (WaveExists(w_nodes) == 0)
		return 0
	endif
		
	wave/SDFR=dfr w_nodesX, w_nodesY
	Redimension/N=(DimSize(w_nodes, 0)), w_nodesX, w_nodesY
	w_nodesX = w_nodes[p][0]
	
	if (LoadY)
		w_nodesY = w_nodes[p][1]
		return 1
	endif
	
	// set the y values to follow data wave
	SetNodes(bls, OnTrace=1)

	return 1
end

// export the current baseline nodes
static function ExportNodes(string strPath)
	wave/SDFR=GetPackageDFREF() w_nodesX, w_nodesY
	if (numpnts(w_nodesX) == 0)
		return 0
	endif
	if (strlen(strPath))
		Save/C/T w_nodesX, w_nodesY as strPath
	else
		Save/C/T/I w_nodesX, w_nodesY as "Baseline Nodes.itx"
	endif
	return 1
end

// loadY default value is 1. Set loadY=0 to load only X values
static function ImportNodes(string strPath, [int loadY])
	DFREF dfr = GetPackageDFREF()
	DFREF saveDF = GetDataFolderDFR()
	int success = 0
	loadY = ParamIsDefault(loadY) ? 1 : loadY
	NewDataFolder/S/O dfr:tempDF
	DFREF tempDF = dfr:tempDF
	if (strlen(strPath))
		LoadWave/Q/C/T strPath
	else
		LoadWave/Q/C/T/I
	endif
	wave/Z w_nodesX, w_nodesY
	if (WaveExists(w_nodesX) && WaveExists(w_nodesY))
		Duplicate/O w_nodesX dfr:w_nodesX
		Duplicate/O w_nodesY dfr:w_nodesY
		success = 1
	endif
		
	if (success && !loadY)
		STRUCT BLstruct bls
		StructGet bls dfr:w_struct
		SetNodes(bls, OnTrace=1)
	endif
	
	SetDataFolder saveDF
	KillDataFolder tempDF
	return success
end

static function/S WaveListDFR(string matchStr, string separatorStr, string optionsStr, DFREF dfr)
	DFREF DFsav = GetDataFolderDFR()
	SetDataFolder dfr
	string strList = WaveList(matchStr, separatorStr, optionsStr)
	SetDataFolder DFsav
	return strList
end

// ---------------------- Akima spline code --------------------------
// *** Akima spline ***

// this part based on code posted to IgorExchange by Michael Bongard
// edited to allow extrapolation beyond end nodes
 
// Routines to implement Akima-spline fitting, based on
// H. Akima, JACM, Vol 17, No 4, 1970 p 589-602
// after M. Bongard, 11/17/09

static function Akima(wave w_nodesX, wave w_nodesY, wave w_interp, [wave/Z xwave])
	wave/Z w_iota = AkimaIota(w_nodesX, w_nodesY)
	if (WaveExists(w_iota))
		if (WaveExists(xwave))
			multithread w_interp = AkimaThread(xwave[p], w_nodesX, w_nodesY, w_iota)
		else
			multithread w_interp = AkimaThread(x, w_nodesX, w_nodesY, w_iota)
		endif
		return 1
	endif
	return 0
end

static function/wave AkimaIota(wave knotX, wave knotY)
	
 	// removed some sanity checks, converted to wave function
	variable numKnots = numpnts(knotX)
 
	if (numKnots < 5)
		Print "calcIota: ERROR -- Akima spline algorithm requires at least 5 knots. Aborting..."
		return $""
	endif
 	 
	Make/D/N=(numKnots)/free kX, kY
	kX = knotX
	kY = knotY
 
	// Handle end-point extrapolation
	Make/D/N=5/free endX, endY
	
	// RHS: end points are last three in dataset
	endX[0,2] = kX[p+numKnots-3]
	endY[0,2] = kY[p+numKnots-3]
 
	AkimaEndPoints(endX, endY)
 	
 	kX[numpnts(kX)] = {endX[3],endX[4]}
 	kY[numpnts(kY)] = {endY[3],endY[4]}

	// LHS: end points are first three in dataset, but reversed in ordering
	// (i.e. point 3 in Akima's notation == index 0)
	endX = 0
	endY = 0
	
	endX[0,2] = knotX[2-p]
	endY[0,2] = knotY[2-p]
 
	AkimaEndPoints(endX, endY)
	
	InsertPoints 0, 2, kX, kY
	kX[0,1] = endX[4-p]
	kY[0,1] = endY[4-p]
 
	// kX, kY are now properly populated, including extrapolated endpoints
 
	Make/D/FREE/N=(numKnots + 4 - 1) mK
	mK = (kY[p+1]-kY)/(kX[p+1]-kX)
 
	Make/free/N=(numKnots) w_Iota
	w_Iota = ( abs(mK[p+3]-mK[p+2])*mK[p+1] + abs(mK[p+1]-mK[p])*mK[p+2] ) / (abs(mK[p+3]-mK[p+2])+abs(mK[p+1]-mK))
	w_Iota = numtype(w_Iota) == 0 ? w_Iota : 0.5*(mK[p+1]+mK[p+2])
	return w_Iota
end

// Given: 5-point knot wave knotX, knotY, with i=[0,2] representing the last three
// knot locations from data, compute end knots i=[3,4] appropriately.
// kX and kY hold node X, Y coordinates, respectively
threadsafe static function AkimaEndPoints(wave kX, wave kY)
 
	// compute X locations of knots, eq. 8 of Akima 1970:
	kX[3] = kX[1] + kX[2] - kX[0]
	kX[4] = 2*kX[2] - kX[0]
 
	// eq. (12)-(14), determine gradient on [0,1]
	Make/N=4/free mi
	mi = (kY[p+1]-kY)/(kX[p+1]-kX)
 
	// Determine remainder of quantities by applying solutions of eq (9)
	kY[3] = (2*mi[1] - mi[0])*(kX[3] - kX[2]) + kY[2]
	mi[2] = (kY[3] - kY[2]) / (kX[3] - kX[2])
 
	kY[4] = (2*mi[2] - mi[1])*(kX[4] - kX[3]) + kY[3]
	// not sure why the next line was included
	//mi[3] = (kY[4] - kY[3]) / (kX[4] - kX[3])
end

threadsafe static function AkimaThread(variable x, wave w_nodesX, wave w_nodesY, wave w_Iota)
	variable p0, p1
	if (x < WaveMin(w_nodesX))
		p0 = 0
	elseif (x >= WaveMax(w_nodesX))
		p0 = numpnts(w_nodesX) - 2
	else
		FindLevel/P/EDGE=1/Q w_nodesX, x
		if (v_flag == 1) // not found
			return NaN
		endif
		p0 = floor(v_levelX)
	endif
	p1 = p0 + 1

	variable x1, x2, y1, y2, iota1, iota2
    x1    = w_nodesX[p0]
    y1    = w_nodesY[p0]
    iota1 = w_Iota[p0]
 
    x2    = w_nodesX[p1]
    y2    = w_nodesY[p1]
    iota2 = w_Iota[p1]
 
	variable coeff2, coeff3, delx
    coeff2 = ( 3 * (y2 - y1)/(x2 - x1) - 2*iota1 - iota2 ) / (x2 - x1)
    coeff3 = (iota1 + iota2 - 2 * (y2 - y1)/(x2 - x1)) / (x2 - x1)^2
    delx   = x - x1
 	
	return y1 + iota1 * delx + coeff2 * delx^2 + coeff3 * delx^3
end

// ----------------------------------------------------------------------
// *** PCHIP ***
// this code replicates exactly the output from matlab pchip function.

// populate w_interp with interpolated values from piecewise cubic
// Hermite spline
static function PCHIP(wave w_nodesX, wave w_nodesY, wave w_interp, [wave/Z xwave])
	if (numpnts(w_nodesX) == 2) // linear interpolation
		if (WaveExists(xwave))
			w_interp = w_nodesY[0] + (xwave[p] - w_nodesX[0]) / (w_nodesX[1]-w_nodesX[0])*(w_nodesY[1]-w_nodesY[0])
		else
			w_interp = w_nodesY[0] + (x - w_nodesX[0]) / (w_nodesX[1]-w_nodesX[0])*(w_nodesY[1]-w_nodesY[0])
		endif
		return 1
	endif
	wave w_d = PCHIP_SetDerivatives(w_nodesX, w_nodesY)
	
	if (WaveExists(xwave))
		multithread w_interp = PCHIP_Interpolate(w_nodesX, w_nodesY, w_d, xwave[p])
	else
		multithread w_interp = PCHIP_Interpolate(w_nodesX, w_nodesY, w_d, x)
	endif
end

// The trick is to choose good values for the slope at each node. See:
// FN Fritsch and RE Carlson (1980) Monotone piecewise cubic
// interpolation. SIAM J. Numer. Anal. 17: 238. DOI:10.1137/0717021
// KW Brodlie (1980) A review of methods for curve and function drawing.
// In Mathematical Methods in Computer Graphics and Design, KW Brodlie,
// ed., Academic Press, London, pp. 1-37.
// FN Fritsch and J Butland (1984) A method for constructing local
// monotone piecewise cubic interpolants, SIAM Journal on Scientific and
// Statistical Computing 5: 300-304.
static function/WAVE PCHIP_SetDerivatives(wave w_nodesX, wave w_nodesY)
	Duplicate/free w_nodesX, w_d, w_a
	// w_d will be set to desired derivatives at node positions
	// w_a will be used as weighting for harmonic means
	w_d = 0
	
	Make/free/N=(numpnts(w_nodesX)-1), w_m, w_delx
	// w_m[i] is gradient between node i and i+1
	// w_delx[i] and w_delx[i-1] are x offsets of nodes i+1 and i-1
	
	w_m = (w_nodesY[p+1]-w_nodesY) / (w_nodesX[p+1]-w_nodesX)
	w_delx = w_nodesX[p+1] - w_nodesX
	variable pmax = numpnts(w_d) - 2 // pmax is numpnts(w_m)-1 = numpnts(w_d)-2
	
	w_a[1,pmax] = ( 1 + w_delx[p-1] / (w_delx[p-1] + w_delx) ) / 3
	
	// Brodlie modification of Butland formula (for same sign slopes)
	w_d [1,pmax] = ( w_m!=0 && w_m[p-1]!=0 && (sign(w_m)==sign(w_m[p-1])) ) ? w_m[p-1]*w_m/(w_a*w_m[p-1]+(1-w_a)*w_m) : 0
		
	// deal with ends
	w_d[0] = PCHIP_EndDerivative(w_delx[0], w_delx[1], w_m[0], w_m[1])
	w_d[pmax+1] = PCHIP_EndDerivative(w_delx[pmax], w_delx[pmax-1], w_m[pmax], w_m[pmax-1])
	
	// clean up any division by zero errors
	w_d = numtype(w_d) == 0 ? w_d : 0
			
	return w_d
end

// one-sided three-point estimate for the derivative adjusted to be shape
// preserving
static function PCHIP_EndDerivative(variable delX0, variable delX1, variable m0, variable m1)
	variable derivative = ( m0*(2*delX0+delX1) - delX0*m1 ) / (delX0+delX1)
	if (sign(derivative) != sign(m0))
		derivative = 0
	elseif ( (sign(m0)!=sign(m1)) && (abs(derivative)>3*abs(m0)) )
		derivative = 3 * m0
	endif
	return derivative
end

threadsafe static function PCHIP_Interpolate(wave w_nodesX, wave w_nodesY, wave w_nodesM, variable x)
	variable p0, p1
	if (x < WaveMin(w_nodesX))
		p0 = 0
	elseif (x >= WaveMax(w_nodesX))
		p0 = numpnts(w_nodesX) - 2
	else
		FindLevel/P/EDGE=1/Q w_nodesX, x
		if (v_flag == 1) // not found
			return NaN
		endif
		p0 = floor(v_levelX)
	endif
	p1 = p0 + 1
	return InterpolateHermite(x, w_nodesX[p0], w_nodesY[p0], w_nodesX[p1], w_nodesY[p1], w_nodesM[p0], w_nodesM[p1])
end

// https: en.wikipedia.org/wiki/Cubic_Hermite_spline
// calculate cubic function f(x) such that f(x1)=y1, f(x2)=y2, f'(x1)=m1 and f'(x2)=m2
threadsafe static function InterpolateHermite(variable x, variable x0, variable y0, variable x1, variable y1, variable m0, variable m1)
	variable t = (x-x0) / (x1-x0)
	m0 *= (x1-x0)
	m1 *= (x1-x0)
	return y0*(2*t^3-3*t^2+1) + m0*(t^3-2*t^2+t) + y1*(-2*t^3+3*t^2) + m1*(t^3-t^2)
end

// ------------ Auto baseline functions --------------

static function DoAutoFit(STRUCT BLstruct &bls)
	
	if (bls.datalength<3 || numtype(bls.depth)!=0)
		return 0
	endif
	
	DFREF dfr = GetPackageDFREF()
	wave w_data = TraceNameToWaveRef(bls.graph, bls.trace)
	wave/Z w_x = XWaveRefFromTrace(bls.graph, bls.trace)
	wave/Z/SDFR=dfr w_sub, w_base
	
	int success = 1
	string strNote = ""
	int p1 = 0, p2 = bls.datalength - 1
	int points = p2 - p1
	if (bls.subrange) // make some temporary waves
		p1 = bls.endp[0]
		p2 = bls.endp[1]
		points = p2 - p1
		if (points < 3)
			return 0
		endif
		
		wave w_fullbase = dfr:w_base
		wave w_fulldata = w_data
		wave/Z w_fullx = w_x
		waveclear w_base, w_x, w_data
		Duplicate/free/R=[p1,p2] w_fulldata w_data, w_base
		if (bls.XY)
			Duplicate/free/R=[p1,p2] w_fullx w_x
		endif
	endif
			
	if (cmpstr(bls.fitfunc, "arc hull") && cmpstr(bls.fitfunc, "hull spline") && cmpstr(bls.fitfunc, "ARS"))
		success = DoIterativeFit(bls, w_data, w_x, w_base)
		strNote = note(w_base)
	elseif (cmpstr(bls.fitfunc, "ARS") == 0)
		success = ARS(bls, w_data, w_base, w_x)
		sprintf strNote, "type=iterative;function=ARS;iterations=%g;SD=%g;hull=%g;smoothing=%g;negative=%g;", bls.arsits, bls.arssd, bls.hull, bls.smoothing, (bls.options&8)!=0
	else // do arc hull calculation
		success = DoArcHull(bls, w_data, w_x, w_base)
		sprintf strNote, "type=%s;depth=%g;smoothing=%g;negative=%g;", ReplaceString(" ", bls.fitfunc, "-"), bls.depth, bls.smoothing, (bls.options&8)!=0
	endif
	
	// update baseline and sub waves
	if (bls.subrange)
		if (points > kMultithreadCutoff)
			multithread w_fullbase[p1,p2] = w_base[p-p1]
		else
			w_fullbase[p1,p2] = w_base[p-p1]
		endif
		
		// reset wave refs back to 'normal'
		wave/SDFR=dfr w_base
		wave w_data = w_fulldata
		wave/Z w_x = w_fullx
		
		PadSubrange(bls, w_data, w_base)
	endif
	
	FastOp w_sub = w_data - w_base + (bls.base)
		
	if (bls.subrange)
		variable x1 = bls.XY ? w_x[0] : pnt2x(w_data, P1)
		variable x2 = bls.XY ? w_x[numpnts(w_x) - 1] : pnt2x(w_data, P2)
		sprintf strNote, "%soutput range=(%g,%g);", strNote, min(x1, x2), max(x1, x2)
	endif
	
	if (success)
		strNote = "Baseline Parameters:" + strNote
	else
		strNote = ""
	endif
	note/K w_base strNote
	if (bls.info)
		wave listwave = dfr:listwave
		UpdateListwave(strNote, listwave)
	endif
	
	return success
end

// The supplied waves may be free waves representing a subrange of the data.
// Algorithm is similar to that described by Lieber and Mahadevan-Jansen
// (2003) Applied Spectroscopy 57: 1363-1367
static function DoIterativeFit(STRUCT BLstruct &bls, wave w_data, wave/Z w_x, wave w_base)
	
	int numPoints = numpnts(w_data)
	Duplicate/free w_data w1, w2, w_test
	if (bls.smoothing)
		Smooth bls.smoothing, w1
	endif
	variable conv = Inf
	int success = 0
	int i, done
	
	DebuggerOptions
	variable sav_debug = V_debugOnError
	DebuggerOptions debugOnError=0 // switch this off in case the fit fails
	
	variable offset, factor
	variable startTime = datetime
	variable alertTime = 3
	
	for (i=0;i<100;i+=1)
		
		if (mod(i,2))
            wave wIn  = w2
            wave wOut = w1
        else
            wave wIn  = w1
            wave wOut = w2
		endif
		
		if (i==0 && bls.hull)
			DoHalfHull(bls, wIn, w_x)
			wave w_XHull, w_YHull
			success = FitFuncs(bls, w_YHull, w_XHull, $"", w_YHull)
			FitFuncs(bls, $"", w_x, $"", w_base, dofit=0)
		else
			success = FitFuncs(bls, wIn, w_x, $"", w_base)
		endif
		
		if (success == 0)
			FastOp w_base = (NaN)
			break
		endif
		
		offset = 0
		// don't remove points too aggressively for the first few iterations
		if (i<8)
			factor = 0.5
			if (i==0 && bls.hull)
				factor = 0.1
			endif

			FastOp w_test = wIn - w_base
					
			if (bls.options & 8)
				offset = max(0, -factor * WaveMin(w_test))
			else
				offset = max(0, factor * WaveMax(w_test))
			endif
		endif
		
		if (bls.options & 8)
			if (numPoints > kMultithreadCutoff)
				multithread wOut = (wIn+offset < w_base) ? w_base : wIn
			else
				wOut = (wIn+offset < w_base) ? w_base : wIn
			endif
		elseif (numPoints > kMultithreadCutoff)
			multithread wOut = (wIn-offset > w_base) ? w_base : wIn
		else
			wOut = (wIn-offset > w_base) ? w_base : wIn
		endif
		
//		if (success && i<10) // make at least 10 iterations
//			continue
//		endif
		
		// convergence test - get a count of the number of fit points changed in this iteration
		FastOp w_test = wOut - wIn
		FastOp w_test = 1 / w_test
		WaveStats/Q/M=1 w_test
		
		if (i>20 && v_npnts<=conv) // converged
			break
		elseif (i>20 && (abs(v_npnts-conv)/conv) < 0.005) // less than 0.5% difference in number of changed points
			break
		else
			conv = v_npnts
		endif
		
		if (bls.quickpop && (datetime-startTime) > 0.2)
			success = 0
			FastOp w_base = (NaN)
			break
		endif
		
		if ((datetime-startTime) > alertTime)
			done = 0
			DoUpdate
			DoAlert 2, "Calculation is slow.\r" + num2str(i+1) + " iterations completed.\r\rContinue?"
			switch (V_Flag)
				case 3 :
					success = 0
					FastOp w_base = (NaN)
				case 2 :
					done = 1
			endswitch
			if (done)
				break
			endif
			startTime = datetime // reset timer
			alertTime += 3 // run for longer this time
		endif
		
	endfor
	
	DebuggerOptions debugOnError=sav_debug
	
	string strNote = ""
	
	if (cmpstr(bls.fitfunc, "spline") == 0)
		sprintf strNote, "type=iterative;function=%s;iterations=%d;errors=%d;sd=%g;hull=%d;smoothing=%g;negative=%g;", bls.fitfunc, i+1, !success, bls.sd, bls.hull, bls.smoothing, (bls.options&8)!=0
	else
		sprintf strNote, "type=iterative;function=%s;%siterations=%d;errors=%d;hull=%d;smoothing=%g;negative=%g;", bls.fitfunc, CoefficientString(), i+1, !success, bls.hull, bls.smoothing, (bls.options&8)!=0
	endif
	note/K w_base, strNote
	
	return success
end

static function/S CoefficientString()
	wave/Z w_coef = w_coef
	if (WaveExists(w_coef) == 0)
		return ""
	endif
	string coefStr = "w_coef={"
	int j
	for(j=0;j<numpnts(w_coef);j+=1)
		sprintf coefstr, "%s%g,", coefstr, w_coef[j]
	endfor
	coefstr = RemoveEnding(coefstr, ",") + "};"
	return coefstr
end

// populates w_base with archull/hullspline baseline calculated from w_data
// the supplied waves may be free waves representing a subrange of the data
threadsafe static function DoArcHull(STRUCT BLstruct &bls, wave w_data, wave/Z w_x, wave w_base)
	
	int success = 1
	int datalength = numpnts(w_data)
	
	// make a copy of the (possibly smoothed) data wave
	Duplicate/free w_data w_smoothed, w_arc
	if (bls.smoothing > 0)
		Smooth bls.smoothing, w_smoothed
	endif
	FastOp w_base = w_smoothed

	// calculate arc hull based on (possibly smoothed) data
	
	if (bls.XY == 0)
		Duplicate/free w_base w_x
		// redimension to make sure we don't get hull vertices
		// outside the range of w_x owing to difference in precision
		// of output from ConvexHull
		Redimension/D w_x
		if (datalength > kMultithreadCutoff)
			multithread w_x = x
		else
			w_x = x
		endif
	endif

	// add concave function
	variable radius
	if (bls.XY)
		radius = (WaveMax(w_x) - WaveMin(w_x)) / 2
		if (datalength > kMultithreadCutoff)
			multithread w_arc = bls.depth * (w_x[p] - w_x[0])^2 / radius^2
		else
			w_arc = bls.depth * (w_x[p] - w_x[0])^2 / radius^2
		endif
	else
		variable x1 = leftx(w_base), x2 = pnt2x(w_base, numpnts(w_base) - 1)
		radius = abs(x2 - x1) / 2
		if (datalength > kMultithreadCutoff)
			multithread w_arc = bls.depth * (x-x1)^2 / radius^2
		else
			w_arc = bls.depth * (x-x1)^2 / radius^2
		endif
	endif
	
	FastOp w_base = w_base + w_arc
		
	if (datalength < 4)
		return 0
	endif
	
	ConvexHull/Z w_x, w_base
	wave/Z w_XHull, w_YHull
	
	if (bls.XY == 0)
		wave/Z w_x = $""
	endif

	if ((bls.options & 8) == 0)
		Reverse/P w_XHull, w_YHull
	endif
	// negative depth will subtract top part of convex hull
	// an offset will likely need to be applied
	
	WaveStats/Q/M=1 w_XHull
	Rotate -v_minloc, w_XHull, w_YHull
	SetScale/P x, 0, 1, w_XHull, w_YHull
	WaveStats/Q/M=1 w_XHull
	DeletePoints v_maxloc+1, numpnts(w_XHull)-v_maxloc-1, w_XHull, w_YHull
		
	if (cmpstr(bls.fitfunc, "hull spline") == 0) // hull spline - prepare nodes
		if (bls.XY)
			w_YHull = GetYfromWavePair(w_XHull, w_smoothed, w_x)
		else
			w_YHull = w_smoothed(w_XHull)
		endif
		
		if (numpnts(w_XHull) > 3)
			DoInterpolation(2, w_base, w_x, w_YHull, w_XHull)
		else
			FastOp w_base = (NaN)
			success = 0
		endif
	else // normal archull calculation
		DoInterpolation(1, w_base, w_x, w_YHull, w_XHull)
		FastOp w_base = w_base - w_arc
	endif
	
	return success
end



threadsafe static function DoHalfHull(STRUCT BLstruct &bls, wave w_data, wave/Z w_x)
	
	if (bls.XY == 0)
		Duplicate/free w_data w_x
		// redimension to make sure we don't get hull vertices
		// outside the range of w_x owing to difference in precision
		// of output from ConvexHull
		Redimension/D w_x
		if (numpnts(w_data) > kMultithreadCutoff)
			multithread w_x = x
		else
			w_x = x
		endif
	endif

	ConvexHull/Z w_x, w_data
	wave w_XHull, w_YHull
	if ((bls.options&8) == 0)
		Reverse/P w_XHull, w_YHull
	endif
	WaveStats/Q w_XHull
	Rotate -v_minloc, w_XHull, w_YHull
	SetScale/P x, 0, 1, w_XHull, w_YHull
	WaveStats/Q w_XHull
	DeletePoints v_maxloc+1, numpnts(w_XHull)-v_maxloc-1, w_XHull, w_YHull
end

// Algorithm loosely based on Xu et al (2021) Applied Spectroscopy 75:
// 34–45. A scale factor is used because the Xu algorithm is sensitive
// to the absolute values of input data and will fail to fit data that
// have values close to 1.
static function ARS(STRUCT BLstruct &bls, wave data, wave base, wave/Z w_x)
	
	int success = 1
	Duplicate/free data W_tofit, freebase
	
	if (bls.smoothing)
		Smooth bls.smoothing, W_tofit
	endif
	
	// scale the input data
	variable f = 1000 / (WaveMax(data)-WaveMin(data))
	f = numtype(f) ? 1 : f
	
	FastOp W_tofit = (f) * W_tofit
	
	DebuggerOptions
	variable sav_debug = V_debugOnError
	DebuggerOptions debugOnError = 0 // switch this off in case interpolate fails
	
	try

		if (bls.hull)
			DoHalfHull(bls, W_tofit, w_x)
			wave w_XHull, w_YHull
			
			if (numpnts(w_XHull) < 4)
				FastOp freebase = (NaN)
				FastOp base = (NaN)
				DebuggerOptions debugOnError=sav_debug
				return 0
			endif
					
			if (bls.XY)
				Interpolate2/E=(2)/F=(1)/S=(bls.arssd)/T=(3)/I=3/X=w_x/Y=freebase w_XHull, w_YHull
			else
				Interpolate2/E=(2)/F=(1)/S=(bls.arssd)/T=(3)/I=3/Y=freebase w_XHull, w_YHull
			endif
			if (bls.options & 8) // negative peaks
				W_tofit = (freebase - (f*data)) > 1 ? freebase - (freebase - (f*data))^0.25 : W_toFit
			else
				W_tofit = ((f*data) - freebase) > 1 ? freebase + ((f*data) - freebase)^0.25 : W_toFit  // w_data
			endif
		endif

		int i
		for(i=0;i<bls.arsits;i++)
			if (bls.XY)
				Interpolate2/E=(2)/F=(1)/S=(bls.arssd)/T=(3)/I=3/X=w_x/Y=freebase w_x, W_tofit; AbortOnRTE
			else
				Interpolate2/E=(2)/F=(1)/S=(bls.arssd)/T=(3)/I=3/Y=freebase W_tofit; AbortOnRTE
			endif

			if (bls.options & 8) // negative peaks
				W_tofit = (freebase - (f*data)) > 1 ? freebase - (freebase - (f*data))^0.25 : W_toFit
			else
				W_tofit = ((f*data) - freebase) > 1 ? freebase + ((f*data) - freebase)^0.25 : W_toFit  // w_data
			endif
		endfor

	catch
		variable CFerror = GetRTError(1)
		Print "Error during interpolate:", GetErrMessage(CFerror)
		success = 0
	endtry
	DebuggerOptions debugOnError=sav_debug
	
	if (success)
		FastOp freebase = (1/f) * freebase
		base = freebase
	else
		FastOp base = (NaN)
	endif
	
	return success
end

// wrapper for interpolate2, handles case of free output wave for older Igor versions
threadsafe static function DoInterpolation(int Tflag, wave w_yout, wave/Z w_xout, wave w_y, wave/Z w_x)
	
	if (WaveExists(w_x) == 0)
		Duplicate/free w_y w_x
		w_x = x
	endif
	
	#if (IgorVersion() >= 9)
	if (WaveExists(w_xout))
		Interpolate2/T=(Tflag)/E=2/Y=w_yout/X=w_xout/I=3 w_x, w_y
	else
		Interpolate2/T=(Tflag)/E=2/Y=w_yout/I=3 w_x, w_y
	endif
	#else
	int isFree = 0
	if (WaveType	(w_yout, 2) == 2) // free
		Duplicate/free w_yout w_yout8
		isFree = 1
	else
		wave w_yout8 = w_yout
	endif

	if (WaveExists(w_xout) && WaveRefsEqual(w_x, w_xout))
		Duplicate/free w_xout w_xout8
	else
		wave/Z w_xout8 = w_xout
	endif

	if (WaveExists(w_xout8))
		Interpolate2/T=(Tflag)/E=2/Y=w_yout8/X=w_xout8/I=3 w_x, w_y
	else
		Interpolate2/T=(Tflag)/E=2/Y=w_yout8/I=3 w_x, w_y
	endif

	if (isFree) // w_yout8 doesn't reference w_yout after interpolate2
		w_yout = w_yout8
	endif
	#endif
end

// when w_x is null this defaults to w(v_x)
// returns NaN for out-of-range x without error
threadsafe static function GetYfromWavePair(variable v_x, wave w, wave/Z w_x)
	variable pnt
	if (WaveExists(w_x))
		pnt = BinarySearchInterp(w_x, v_x)
		return numtype(pnt)? NaN : w[pnt]
	else
		pnt = x2pnt(w, v_x)
		return pnt == limit(pnt, 0, numpnts(w)-1) ? w(v_x) : NaN
	endif
end

// returns, as a free wave, the coefficients for the polynomial that
// passes through the unique points in the 2D coordinates wave
threadsafe static function/wave PolyCoefficients(wave coordinates)
	int numP = DimSize(coordinates, 0)

	if (numP > 5)
		Make/free/N=(numP,numP)/D MA
		MA = coordinates[p][0]^q
		Make/free/N=(numP)/D w = coordinates[p][1]
		MatrixLinearSolve/O MA, w
		return w
	endif
	
	// some hard-coded fast solutions for poly 3, poly 4 and poly 5
	variable A, B, C, D, E
	variable x1, x2, x3, x4, x5
	variable y1, y2, y3, y4, y5
	switch (numP)
		case 5:
			x5 = coordinates[4][0]
			y5 = coordinates[4][1]
		case 4:
			x4 = coordinates[3][0]
			y4 = coordinates[3][1]
		case 3:
			x3 = coordinates[2][0]
			y3 = coordinates[2][1]
		case 2:
			x2 = coordinates[1][0]
			y2 = coordinates[1][1]
		default:
			x1 = coordinates[0][0]
			y1 = coordinates[0][1]
	endswitch
	
	switch (numP)
		case 5 :
			variable A3 = y3-y5 - (y5-y4)*(x3-x5)/(x5-x4)
			variable B3 = (x3^2-x5^2) + (x4^2-x5^2)*(x3-x5)/(x5-x4)
			variable C3 = (x3^3-x5^3) + (x4^3-x5^3)*(x3-x5)/(x5-x4)
			variable D3 = (x3^4-x5^4) + (x4^4-x5^4)*(x3-x5)/(x5-x4)
			
			variable A2 = (y2-y5) - (y5-y4)*(x2-x5)/(x5-x4)
			variable B2 = (x2^2-x5^2) + (x4^2-x5^2)*(x2-x5)/(x5-x4)
			variable C2 = (x2^3-x5^3) + (x4^3-x5^3)*(x2-x5)/(x5-x4)
			variable D2 = (x2^4-x5^4) + (x4^4-x5^4)*(x2-x5)/(x5-x4)
		
			variable A1 = (y1-y5) - (y5-y4)*(x1-x5)/(x5-x4)
			variable B1 = (x1^2-x5^2) + (x4^2-x5^2)*(x1-x5)/(x5-x4)
			variable C1 = (x1^3-x5^3) + (x4^3-x5^3)*(x1-x5)/(x5-x4)
			variable D1 = (x1^4-x5^4) + (x4^4-x5^4)*(x1-x5)/(x5-x4)
	
			E = (A1 -  A3/B3*B1 - (C1-C3*B1/B3)*(A2/(C2-C3*B2/B3) - A3/B3*B2/(C2-C3*B2/B3)))/(( (D1-D3*B1/B3) - (C1-C3*B1/B3)*(D2-D3*B2/B3)/(C2-C3*B2/B3)) )
			D = A2/(C2-C3*B2/B3) - A3/B3*B2/(C2-C3*B2/B3) - E*(D2-D3*B2/B3)/(C2-C3*B2/B3)
			C = A3/B3 - D*C3/B3 - E*D3/B3
			B = (y5-y4)/(x5-x4) + C*(x4^2-x5^2)/(x5-x4) + D*(x4^3-x5^3)/(x5-x4) + E*(x4^4-x5^4)/(x5-x4)
			A = y1 - B * x1 - C * x1^2 - D * x1^3 - E * x1^4
			Make/free w_coef = {A, B, C, D, E}
			break
		case 4 :
			variable E1, E2, E3, E4, E5, E6
			E1 = (x4^2-x2^2)*(x4-x3) + (x2-x4)*(x4^2-x3^2)
			E2 = (x1^2-x4^2)*(x4-x3) + (x1-x4)*(x3^2-x4^2)
			E3 = (x2^3-x4^3)*(x4-x3) + (x2-x4)*(x3^3-x4^3)
			E4 = (x1^3-x4^3)*(x4-x3) + (x1-x4)*(x3^3-x4^3)
			E5 = (x4-x3)*(y4-y2) + (x2-x4)*(y4-y3)
			E6 = (y1-y4)*(x4-x3) + (x4-x1)*(y4-y3)
	
			D = (E1 * E6 - E2 * E5) / ( E2 * E3 + E1 * E4)
			C = (E5 + D * E3) / E1
			B = (y3 - y4 + D*(x4^3 - x3^3) + C*(x4^2 - x3^2))/(x3-x4)
			A = y4 - D * x4^3 - C * x4^2 - B * x4
			Make/free w_coef = {A, B, C, D}
			break
		case 3 :
			C = (x1*(y3-y2) + x2*(y1-y3) + x3*(y2-y1)) / ((x1-x2)*(x1-x3)*(x2-x3))
			B = (y2-y1)/(x2-x1) - C*(x1+x2)
			A = y1 - C*x1^2 - B*x1
			Make/free w_coef = {A, B, C}
			break
		case 2 :
			Make/free w_coef = {y1-x1*(y2-y1)/(x2-x1), (y2-y1)/(x2-x1)}
			break
		case 1 :
			Make/free w_coef = {y1}
			break
	endswitch

	return w_coef
end

// Planck fitting functions
threadsafe static function planckmuM(wave w, variable wavelength)
	return planck(w, wavelength*1000)
end

threadsafe static function planckAngstrom(wave w, variable wavelength)
	return planck(w, wavelength/10)
end

threadsafe static function planckWN(wave w, variable wavenumber)
	return planck(w, 1e7/wavenumber)
end

// convert wavelength units to nm for planck function
threadsafe static function wl2nm(STRUCT BLstruct &bls, variable wl)
	switch (bls.wavelength)
		case 2: // micron
			return wl * 1000
		case 3: // wavenumber
			return 1e7 / wl
		case 4: // angstrom
			return wl / 10
	endswitch
	return wl
end

// wavelength in nm
threadsafe static function planck(w, wavelength) : FitFunc
	Wave w
	variable wavelength

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ variable wl = wavelength/1e9
	//CurveFitDialog/ variable c = 299792458 // m/s
	//CurveFitDialog/ variable h = 6.62607015e-34 // J/Hz
	//CurveFitDialog/ variable kB = 1.380649e-23 // J/K
	//CurveFitDialog/ f(wavelength) = w_1*2*h*c^2/wl^5/(exp(h*c/(wl*kB*w_0))-1)
	//CurveFitDialog/ //	return w[1]*2*h*f^3/c^2/(exp(h*f/kB/w[0])-1)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ wavelength
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = w_0
	//CurveFitDialog/ w[1] = w_1

	variable wl = wavelength/1e9
	variable c = 299792458 // m/s
	variable h = 6.62607015e-34 // J/Hz
	variable kB = 1.380649e-23 // J/K
	// hc/kB = 0.0143877687750393
	// 2hc^2 * 1e9^5 = 1.19104297239719e+29
	return w[1]*1.19104297239719e+29/wavelength^5/(exp(14387768.7750393/(wavelength*w[0]))-1)
	// return w[1]*2*h*c^2/wl^5/(exp(h*c/(wl*kB*w[0]))-1)
end

// *** user-defined fit function prototypes ***

static function/S GetListOfUserFuncs()
	string funcList = FunctionList("*", ";", "KIND:10,SUBTYPE:FitFunc")
	int i
	string strFunc = ""
	for (i=ItemsInList(funcList)-1;i>=0;i--)
		strFunc = StringFromList(i, funcList)
		if (strlen(strFunc)>32 || exists(strFunc + "Guess")!=6)
			funcList = RemoveListItem(i, funcList)
		endif
	endfor
	return funcList
end

function BaselineGuessPrototype(wave yw, wave xw, wave mask)
end

function BaselineFitPrototype(wave cw, variable x)
end

function BaselineFitAAWPrototype(wave cw, wave yw, wave xw)
end

static function tic()
	variable/G tictoc = StartMSTimer
end

static function toc()
	NVAR/Z tictoc
	variable ttTime = StopMSTimer(tictoc)
//	printf "%g seconds\r", (ttTime/1e6)
	KillVariables/Z tictoc
	return ttTime
end

static function GetScreenOrigin(STRUCT point &pnt)
	
	// set default value
	pnt.h = 0
	pnt.v = 0
	
	GetMouse
	
	#ifdef debug
	Print v_left, v_top
	#endif

	STRUCT point mousePoint
	mousePoint.h = v_left
	mousePoint.v = v_top
	
	STRUCT rect screenRect
	
	string strInfo = IgorInfo(0)
	string str = ""
	int numScreens = NumberByKey("NSCREENS", strInfo)
	int i, left, top, right, bottom
	
	for (i=1;i<=numScreens;i++)
		str = StringByKey("SCREEN"+num2str(i), strInfo)
		sscanf str, "DEPTH=%*d,RECT=%d,%d,%d,%d", left, top, right, bottom
		if (V_flag != 4)
			continue
		endif
		screenRect.left   = left
		screenRect.top    = top
		screenRect.right  = right
		screenRect.bottom = bottom
		if ( pointInRect(mousePoint, screenRect) )
			pnt.h = screenRect.left
			pnt.v = screenRect.top
			return 1
		endif
	endfor
	return 0
end

// point and rect structures must have same units
static function pointInRect(STRUCT point &pnt, STRUCT rect &r)
	return ( pnt.h>r.left && pnt.h<r.right && pnt.v>r.top && pnt.v<r.bottom )
end

// *** proc pictures ***

// for transparent button
static Picture transparent
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!!'!!!!##R18/!./"R?2ss*&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U!#8'n5u\,XA,QB,56EgZKN47fJH5b4"p4lqaq1fX!!!!j78?7R6=>B
	ASCII85End
end

// PNG: width= 90, height= 30
static Picture pCog
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"&!!!!?#R18/!3BT8GQ7^D&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U%adj95u_NKeXCo&'5*oW5;QerS2ddE(FP;'6Ql#oBiuS1dW/'TBu9uWoJd,<?@,Ku[OT_*C6>N&V
	5fgKO-Z!0m]BHZFE$kSY/b+).^UIV80KE-KEW"FQ9_,eF^bT7+UPEE3;1R;IlL+VJZGMtc/)57aYSB
	X^5kLMq7Sp9q0YBG@U214ph]9b)&eA4@(!#Ip%g0/F0_UH>\E'7M.=ui]mI6`m'G"T)B'OA[IVmQDm
	=?Eat`-Qd[5bR1c#F]`cT(Se*XgJen[DI=<Y8YF7N!d-X+iY2pq;SVDt;siWS_bs$!E]WT^pRhs]aH
	M%csq\akmJ4tMo<HGU1WqT,5cib%XrHM`>*]/&U:](RQ7QDj\u&#cMNi8>`?8;-?rCcXX>+1^gW10F
	n!h-2G-M;R\a+TD2op'?`R]"%W!DpJmO],i(@-(/F?,;L7Vkt%YOa,f\8+CV@lHVOEMgMZPnh$6>!V
	MTYBm^8f[O,?Z$2MnH6.T'JWSM4HtSissRo-):4d:ecoe5Tn^(gUEQm+o94@;L(/[91%aXk:!pP;mm
	\kh$s.7qbe%=-p1eBtDs*CHp:+$CUY\0A,jM0:4J2&pY-HWBG?nb`"BE/M-#*)+E?I*C/(r;J]APNh
	3!Ea<(u)`o?0R`ma=QV<n?GV/s3:I0Wf2_M0p@:__T%OEl+sL@10K8&ViQgR(0Q3qMLYA':/iba:,;
	]Y$@ACMV&9b[fD4A`Vq5+A!37VD0na`;0#fWNWKq#f5N>Mt)$S['[2:?=(p2$Q$$NX_cXoJ`iVOcHm
	Rb+"_b#*b4@tp)Xq9r*1_<^IVlpMJ=kE>MhiHa2]]q9<d*4(lA_8$4ej2NM5Z!#`oc=+Ttk-]%D5"O
	Yiu,o$V/I<=@2fN3Ds,PNfIEnqn6C?^[OYDs4q2k*s6TFu+@1>SKUmdko@B5>Pp)-]8`l_Ig,/1c.T
	K'Z+asa)qDc*mqZAKmijlOd;;&H$MEMWY1:\q<G#aaNVlho?TWCGL35!G658MH$RpQ,/[:S#==eP-@
	T+s%'h-7&.0)\eW6j@1gNW'FYlgRIid1g1dP0.MtL)"o@*4A+B&XU\9bRSJWg?B!keI%b6T7FS'?W(
	@7j-a-n[,Adkh%U((6"oN9G"iRV$rmb0"2lqXk08!N&V_b13Oo*tc)h=[L]E@W<ihr:]%Dbs-*cCbc
	T^`<b81D1(d_gue7JX)rMl-Q!ag!0.a4mbCL5'MQH2X<p3`1nA#69QNiWDnN[J^:kIm`JPCXo#W8lo
	?KFN_dOMp#7s\i!;q:1Vb`q^Za5j'0Sg8ALVn\tm:OM*.G/IF;=K4S+O/0U]^`u\O,i'69Y*0'f,SH
	:Kp)mH3.EQ3hDf%?f;W[LbJbR7R5Lb$8U4I7,[8ZM7fU7H5(>6BlSlr1cG6"263q!"YH.\`>aLYN(!
	e3hZYm666$Mq_c(_GHO?%CE(rnI-UV=I6M\e$%CXt$`9q"IB8d`/4e)0&Dcf`43oobf6MqdV?d>\73
	X/dI(2jZ+#[Nt'sQg5KRFl_^rEVX>cZ5h3g1gR#*IhTZf+KqmsVrW[`UcE6>MM*N0fMcT[S!:h'=ju
	EaL@5>OfU]WXd+d/JISLYCQZ_BPkB$IiAYUBq1l^ecC4a8EYJ'WJ,pak5V59k6$F23m\(d</D&W$.c
	&:n64N(\`j0%h;m7iB=j)(R^kh8BUCfn<.JP[26K1F7\>0JOc56jWCOX(6k=i$m^+A%<G5QZ.i$e8]
	01cU/k$R?&@c[1P\L>tK[OkSMmQ7lT_puI&4&#-'R99q+p;3\Sn`Ic2G%kDj/"N6oB<E0?Z6Kl"@,Y
	?4P5G,Nu\q^LTs(Vj(g3YCoZEl;W9!T)>ePG,S!10n_Y\rP(FBr90.J3;jVP^MYp<-ML6>(=)*bFsB
	&uWX-VWg'<P8G@$+\A?J1@G'F,/Z.<q/;.,=8I?;gFp>>;IjEQPE_:7`.R+3bElA@DB6<k@ksJ9lg(
	=CVM=g<G(^E#SiiFHZ8.qF-^ppkE&\[U*_);<'Lfk*Fq]^#W339=Q'IWpj"KgUWU]1,ETW<&G^OtOH
	MkGSX1r0@A!=Gd&>m2;$s(nF8b!K?8R`eZjO8V38_I$<1AcnP!)B*`T#3.X=hE[s8PMoFf*/H2@32u
	N'Len`GUk?n:K*@=9gMMi1ES9gF7flQcCD`2n^,h:`S5=GNQ^G#@^/a:?]W`PV50n4Xue>QVk8E1=]
	lWKB?uV(SiXjL_hVC,G-+W-bHd)[C`^u(BPM:VV58ltJcZ8d$CEhp-Ek)Qb.'^'f)4eT`-]7*:O[1>
	WO?>HRRZ3%&Aum4gNS.jU=.^S*B#H\'0H3Z)tG>O;)WW1_IO09[>@PI4Y3R7J0]^!UgQhj+u1-,O_#
	4q7aj2?Y5.V]ph=D*J`g8?n%JH:8P)K%MLrfVTs(X1]A:d+mFtdNBG"";'8siHNZC4&bKJq`%mNb7r
	SW;=`2-+n=L)HDOsFHoS$CX_6m<3W758iRSt7"9?7u`s%5^"&NsfV]&fKiR),nod"F>!-ZZj257RH'
	BCpkU2>pgE:BYW?=m,Fa:(R[)N0g+8U_d1?h6?87.J?1.S8QM+N.?c/5H^[K9Qq/KSe*09PFi*)kOs
	Cpa8151hB![K\`b9:/2t#`0h)TQGGW^_mOCaj@jCA@uU*q95,uIW@7!X&<O\"P/_=YGg"!\PP(fcMs
	XX8]B01I/5GVm/oHal.qLkA^e?r`*cq5<6cMYpEN]i/%/Vl(p'^fIMd8C\oHLnT1!)7oQm]mKeID*1
	Nn<=:2#ZkEe#YpHHH,[1j)T%7I4;@/)4cu_Q1)PbZM:[@i"UEI%;r>p03XoVZ_RkU=+$'7#=USG/bL
	8-+m<=>h,iqN=A8kNQ3E0-ce+TlUO7L$\:&5CW07\^Y5(=Lpj3bn5fXf]+hD?H]7Wq?&[-c"7hNK0#
	/)B'Mj<HT8ma3CurC,*bh\'aHR7Z[QbX-ZmAk800m):lpO:?P+(!;TY'R\j"AmjWGZ^'4n^bf?W3J@
	>&NBK1HqWkVhSJ@2:%U$9,hq:d,G1cCmI-TcrP\J*Ut[2@6?BcK3XN6]^DH?sm>]m;PWk0+t]M3*pb
	_i5ToaNr1&dko4ib1O7G-^#a3R58IWd+6c;6ULrU<E06&]A7B"H::^+p=jM"Cht@E-\k9W-F%RN7[f
	g9`s&hll-^kfa*7KZfMd!Yc("^(?tb@(G_h8BF>IEA!<RhTlND,!db&r!Y3m>2$M&6dHhJmnR;"(TN
	7k9deNFM:rt_%M:_\bI5MO2h<A0N#R:ZSrC"&ps\iY*%&:=-;@IrX+"G9!l_&sOI?=_'7)$hsk)[Og
	CfZ9V$@mNB]AS#G_>V6^Z_/)$iF?19\*_+U8'Lh!@O$@74\ogtP<K2K,l#,B;0e6NJ*#oS35C1Gqa?
	[/#EMYbdp\'g083t^Hm.OC']=?TCh[+\@'/CD^$lb9k>s0TnKIaqh4fI!&lDq*\4*U*,*??/2AnId;
	.P@%q^Y_gV7L#<Y@CP!Nm,EKn=&i8<r@!PTa5]H_PQ](fBqn;iMUE,Pl5E-<#!*W9G0Gifi6\]*<o4
	FnfrX,WF^_\F$1nF]^fU-bLO!=bm%5lG.k3$IWMqUu'c@l,R*B4I#7$5RGsBAo;S"q!W&r%8C2/"PK
	bsa<4<J73edT0;DW#W4)GM@uFDONL"9R+_N^([T!(k&'aJc*VLHV&^R;!(_#4Z$g7@#[rnEd4b][m6
	"s2Cf6FX#Yth+![-Bc9;DCc35!#ZOe]>R5l%A3s9r*"E3cZ^HAq!@!X3ZLR*.A7oQ8om.\p[kV)RYJ
	YS_VJ,ke(!91A):`eg`H3<A0s%C//=2RBq,pC2:S]*\P@U_Oa*3.T[g!Hf.uI$^Z574:Ig+a&Rh&b)
	g:i!IBPVCY]Y$?Mc-nM/==coe'#A=jP*M;$C2,4.LP+[KAA[:ZiG]VW6ipmf;5gRtUogbYmG#,M=Y+
	23\;kLm>:;.qMlKqn)uClJ![.i',6Vo?VRu"<5C39QHia.rIUXNcq/492/E<t4:q=5j]#0#BT^2C8R
	r=7NOaA&EGCimE'I"(o(b72sE7cRPmWBnj]tHh/;(=(Hs(iTH$*GN/REC6P4"-OQ)1Z*S9OlNXqYG,
	/qFo"%Xt5WcH)DMDo_@'gn2mp\l)\(b!Y0Pa!2n,Nj%-R@Yjn?WT$E#t(FUbj=.R08ON,:0qYL%:/M
	0]<Q1)2)G':0@s*h8ZZ<4MLPu4'A3d&SI6l9j+cCI%0ltDh?G(&13<0N\Q=?t??;p9Q8$59_n3Rli=
	5b`N"1`$#>;[JNr+$!*^fli%qGlHBaGd#r_gndbH0<a<pR0sE5L0:j)I_t)\EH/7Wqt8QJMd<r<&WK
	8J3cuoH9hij#22_bS-?/1q+bUC@(DjDc_1Dg*LCYK([C$_m"OB=44C54XF6CiRHM)#JSik-Qi#lgdX
	C:AAV;n0(-%L_0m!T,"d5MVG@HhTKZ87K.p%WH^Xh3kCpXcTY<@p]%p!H!PcGm8Ma`dWI-i:%O`.@A
	\EMhGlp>Rk7O<G2m`*r,h[u\8;4r,bUaQp%EDN*J]D4B1hFXuppq^tpModARV5%<QlNN?L%hAEkIlW
	/#`^]Bs#-d.f-97RH2#l<o@ZXZ&T?iRH-<%N9SU+'so7AAgW2mil0fWaM)A,6@)4Rp@WFC0@Y,uIN:
	5uCJkMPAJFd6VVd/UR6[rI=?0fVgq/kI,s^(YARDN54WD\PD#"bV<C5XKS<`]Fql#m@)ul]O#Nn]-2
	[lB);<HM,sPARkJs:;d4_S!/nh?qGe7@I:AsnMi7DjM_D$2XW>fsY^ZQI8$;`nm!f"mg^^mq'BNs/!
	!!!j78?7R6=>B
	ASCII85End
end

// PNG: width= 90, height= 30
static Picture pHelp
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"&!!!!?#R18/!3BT8GQ7^D&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U%&ule5u_NK]pa@g']g@U^Upt%GFQ2iG6aJpJmdFX78;,cVIC:7E<8Td:b6cN,?9UjVf\f%WZ;[/V
	%KP#JO*M&WN?THKK9cU)`=`H0[O9,)L8;-_'G*Bak\80]?@nUmHm(8j1N'qpQ@[GqTSkLm[iV;4l?5
	9p34hHca--pCc9?`a1`N@?0>MW\`C_cK87>p!!)X0(AW7k(<k1!Z6U5Zb%=PW#*`9'?8(R.l9\9B%n
	9#Xi,CY"\p?O1oCK4p_#dS:<['Ueqmu'!DdI1i5jrP3+p\-^L%B)Rl&&6R@eFq>=L[qbCBEtmmNr/L
	*e`#,Pc(S2@J/p9W2QZ)-J]W[Rki??laDuDX[@&P,(^^j"-[%#SONo\V1=G'!!%70KV'(>nd;T\r9s
	nW!!']u`J45Y;-RJO#^h#IS8@)s?-6E37K\jr"J&9mNoQd1W?So9&&7!4QcfPj`<*6p)q!4%Z!kNSb
	ab*S0C)+!-4P&qo6Jd<2$QkkZlF^m=^($s8m)tsn,tIZn\F/q!JI,[b(u%<c'JV4aX<^Bf%*k%J6&^
	>;,IqtHG)FHLBE0]KCF+J!.aqBH9Cu\K<fV!+1qo2IdrI^jN)fkTP5;J-4NXp%T0D`+g<s/YW;Xf"@
	\,T!Yqbd?E6KnN%F4r'*)'g*uD%cKYq4thknG`:Fo$Eh;$dZNZ:%ld4Hbsa^bHA79m^g0PiWdCc346
	JH/)8KM&)(k36QF'1-*7>&j)l`JADS2'.,2Z*_)fH$KMmMP'\-](',%?j1@)>F]S9TO0p.T!W[#6cg
	fTP-7;t(+Zf_JqtSn,aMH!n\';3U2ZD&S;P.=h1rnGXk<CB$fKN,kd+9PO4u%TJ&Hu4&4Crs9Y@_nH
	"MR&l)1>b[1u<1&g\hMaNi(kl1-rkL5)pKfeO6U'VM\7&0/`!A7PfqQOE]am/tCKELH9=]@#NnO'jY
	tqYGLh>IH)^mct,(P9&uXOhUj'bDC#sD;2^*qE?dh;P68RpF'`l^&V357%l%naPeh(A($.glRQtugt
	ZGl%$*W+%Ia6#,81..8g^]id,Kck$t@][$aBOjq/OasMhNuG2M,LC'G_J("Z[P4_r5QBmFntXjd',6
	lZt\G^OJI;7Rj%OX5iIM#6uCX!]FoLK`(amh5S'MpXVq/O#EQ=C>KI[/s=orf,T\.V5"J]r\=n:<P^
	dbK.Jkf0au0o*Zjc5<u!+J$%sur)3hjN3<hR:W<>kX3+#G"^cXsdL/hY`gSKQ2hQ^Pq(l!UpCdqH+(
	.;#abis6/fk6q:$aRh5_>*eM9NS:6RPelrZ>?$aa)Nf&c!V@m]6<R6e=FIgEcWdq5MWd4Wd(EGH-(t
	7'6n3kpg)VSEUsmM3$iUNPR)sTB+NfY$cV71VX=4n!'f7b&o2]5j7tq;=*jFX8d1ff/P>NYa\kIC.H
	0D<]`$GJ&fmmVZ]hoTDId<i+X\WBThm/_*d[#n'GhQY]#TjRa0oj>Y^?+^*&qn&>%qpqLF8^A1;Q1&
	-O1QL#&^mh-Vg1nFHc5Yg_^Fm5Mj%+,Mn_\Yol9dGTnRi%0.uNj'\-e(in+;$'enZ/=ITkLsojIs'f
	5J4*Sf)rJ-0)p,hFVP)c6^;1hlKdF&nZ-FC.eJ7Vk#%#29.N7pubh'DZ93h9r&DjT2'SNDUuSfXk:T
	hm!T6a,*oAQcCI[)@&bnCG;H\^W#'+J+VfO[ZNjXF'@+Pe?YI;kq8O!7WJ6/>GbW`_[MnT91E/eol'
	bTm^=u,IJJ5lD.poMum`/$SP;Lj,6doEk."\m=nfH#0X:Yfbb'MOIr-edqrknBHJ'.M!5h;8]P4A(2
	C5q?EY.TLP&:@>Ph$?Yg`,3D[$dC9?0\Lot/&E.W?j`_I5L)S`l("cMF\gETWuSY0H>CU9[07$'*X?
	.ECCH8hd=RSR5*cX/cU:_gpc,KYucE`q+RG\$$<TcCB`,F1^8,XK7BFNf9bRLZ:?J%"ljN:<;Dmlr<
	<hnCr)p-KUd:j9K#ZR[0<)\a0F9.RDN?6IID#?^a.u`5-q,0f8$Rlf7RA:d.C+<VOe$lIo%e;iX5o1
	`08MhTJ)r/NmJY-DDFd-.d!K_Rt0c0JkU#f>m(GTtJ#XKnY4Yh:U@^b&M*`#/`.YmHm=QB$'%\qX#r
	@k9m_?!'^:&'rj398\D*jgar,Hmr+Pss6/[R]X5WiKS!V5MLl\*=I@$r(oGZ,`<UmS89I+G&ERttG\
	?uGTYJ4QI94'p5&O$_NuCGa:bXG:/cc`G"U[\/_&o4D^R9qQ.&+2[(Oj,+Wf%(,h7@a%l,]TuYHJJ]
	c-7[nR\D2Y'FNK/2Is\:pn`I55s*LoL%75rm!\:SWNQ!$7lE$\oEiU0_1I2l(qmg9mW>fI686_Rj.5
	jeJn6.1(2"3)s(MJI+9@R=1DURoE!UFZS]K(#"X+#C.&IfNW]P,?eu`-]QAr!;/J\^(*&mqjc^33aT
	ho-+@KOjAb]rUUj[oC9NQ;ek29;O&*`'Q"/";k+Tg7'`6o+_GJCHppi2q`P`s):,hk.sAA13FNUdVO
	CqH6RTVp:'Y5Q5n4OSA+pK<_\dBuc<WYCcMO?Q@,LgL<7c;$W^J0;HuM+9W5^S^q4aWOpsd@r>fnk2
	So.FRL?T3's"<s%-?!6l<9^F=LQcfaIk'F`fAVN=fHg&+@:55-A/$,0Q;a!e\;h*Lf(XaXKL[!4-!c
	aqqcW-G6]?LB/PBBUY6(jb9r[dt)"0%,6E?I7ZC,@h&U9d0N'0B"I*cP&=W6+,5Q+jm*N\UX=lkGu&
	=k,OT/8_;BQ/7_Ej-C_!.H&/7RV2C0;(69I-DBB1!=ngL'RTsV0@Thl"/7EIHaEf0:a;]5Cc66VSZQ
	6I"!Xu@+C"F9t&6)h$QNJ4Z`l)J2%pja/;XcRC:V`\qo7%>:kj303LOY7gGU9[=BWi@Q<4J,J?\$`W
	[j`9>Hfs<YZk"J7Y4O9e.Z4_2'41CGG!H$J1+c^co`cG$^kE[l+]TgZQ_ZQAl-Ye&1(foL%GJNZubA
	I=\jNa+r25c`$-\_d!-SF>`c$*"bnA5Pd&@G[NL1-s#NT^QJE4K3ch;$eqe%2otU'SNkO0)Wq;?3TU
	rR^1M8Y>J.e=2WqS,EtAVsr+7Ye3:5n)T/gm&69l`j'CTj4Lg;;));SI-5M&;0PNH(V+qhEd59(q77
	:UfXZ&NG4+.BMM_c:\fMCIl=*8Wl$0*1n"*V,VrbVTeamc>-QOiL!'a[j8ho<N"<e&.<_R:uIoHWYJ
	V2XkU$7DS=[%EK"=$\$kMQ0&ZlWD`GVR/k$j8kX2:&F1\IrM\).p2mX&c?cjWb$4(kt>!Fg\$7MYDA
	UHms%/2@dgf]sf_>hK$8KIS*p\IF@UM*pf19J:qKEM*`+C1)HeU%mj[5%,n0(A&?QmTqML1]D_'#VU
	*PTY.VJl],a[1oi.[R2gCCs)EWsbZM?gV]Lt.iOP5c/>+CgY](/@X'N)9IE>TW8![nBi9rGA-g7>Hp
	7+aXH[X[R9gD:QXZ-eK.]oBqplJdKII8NiR<EiZXD*$*VkL$%p@CP!"\(botnDUa&J]RXWD/Cjs8kK
	_<Vt(nb'K\+MDAp)9hWgu3=Kl-_8`3<f3W%U'e"ljrNP(a<ThrgW8>ReE0a-h(!L0!@m!e[%Zs0JWq
	t?0?mV_+Ij[j)-=03DO_eQTRXK2hGf<1D3EY\ZChfAPHFN"fO]NbF:l!M_*b:=[),oo-29QT>^V:Jn
	:-m.rqHKcs0/5Y;,CW^2$p-3Z_&F&EBJB;>bhJ?i+bO_rAXf/4u_28sXAEi7<jcOgQrqM6=VYgP@_8
	H64h2ZJOlBs?ebm(55\!.MW!DM.KJ-<m>:brccmn<T3VCVWDrT)dYhZZGG0Gk5H\]2"fJq/]7#nTGM
	d*Rkr\k#n?2".f$$2_u>^Ei3E4V/;GBQFSYB4Z]qWhhRd8-hNf"q^:7iL-29.seIBTbbt(s41u^CK<
	qq#AJ*pLEHlLC:2KZR-9u#'FI,;"9\c,GW[%O/;p>tQ_L@Sk*gC1'^rD[Ng<&QqT8!\!;\90X=aNKD
	r`TCVbt6obG&O5$4H$sZ/XWa124<T4?Q;4T0A86rdItO<p@AD3h6a-P6iN]-!7Zr+m.(@HX1ct2t-b
	HR`A77"JcKsz8OZBBY!QNJ
	ASCII85End
end

// PNG: width= 381, height= 271
static Picture pConstant
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%J!!!$1#R18/!3VM"RfEEg&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U#r,">5u`*!mG2,cQ1Z$1n`TNT81`>K"^,Ga>V4?k)3lo.=:be_A.^aj[UE"MSJoDbP2V@.(Do_K@
	f-n]9Sa@qE[FO#p!*\+,p^&qW"Bf"=K2jFThnOmare5'ZBMh.KgSXsn9dE$ml>gRpH8*-gL#EmjA:Y
	giJ<<hrr)oUlr>O#U9<'7!&/ji+!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&U
	f0t6m!N`d0E31oDoR:I=O^R+!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&Uf0t
	6m!N`d0E31oDoR:I=O^R+!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&Uf0t6m!
	N`d0E31oDoR:I=O^R+!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&Uf0t6m!N`d
	0E31oDoR:I=O^R+!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&Uf0t6m!N`d0E3
	1oDoR:I=O^R+!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&Uf0t6m!N`d0E31oD
	oR:I=O^R+!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&Uf0t6m!N`d0E31oDoR:
	I=O^R+!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&Uf0t6m!N`d0E31oDoR:I=O
	^R+!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&Uf0t6m!N`d0E31oDoR:I=O^R+
	!;0C#=q8T!>5umJ4)dI+;*!+84<(N&eTPB6pr+>&^^hS7.^Km&Uf0t6m!N`d0E31oDoR:rJ5]Dp$-d
	H_1L=MBiD-(!N7KqO,*noh=8>4Xmu5&5cmNWW%-1"84<(N&eTPB6lKf'^tE8eNZGB9rVH<`]C/4=:J
	VDeh]J&NS)_/>/rK,DR1iXS?6&?RkLOrQ+>M7c"/"r7(Os-aY5%17%3p=&lKsR/Df:$QeJ59k>8OV`
	^,_KApg?d_1oU\C!nl8`3DFk0Di[C(/fYK$M+p^ldbZ#YS!q(^r*.K0'9=bL'RfG`2kFL\7"gj)C&.
	,R_0GmTRprV*0-VV*lK_s2d\S[J`JU$@@n-:,rgo^+IGMKeZ@73A*Z@*=LLSZ*puAf"ER*Xe[2L,Xa
	@cIhFP_@_3V`7\-H'as4rM+`m'3_s59f*=f%0W8rV+>QSXnl`%im\F>Fp:igh-h3'E&8deC>:`J+hR
	dj'Ot=5[:jEnYk%RB?c=1CY+jo^\7H_EU:c/Wm(h=s$XUg><=pia5=MoWgIk^D'sJ^%r\s$VI+dt6p
	qIMh&BWQ]i:9m!)CJ(IYG5DpgX'o-d.iHU$h"@IMN9E\>-Ad5!+!C+sNJR:Tqog!%/ue(&5F@MZ(/2
	8&XqRs5<b>:[._t/M/]fV55**!K>1p:'F8'^#e:O$SRJ1VG4,M1]SoL9"tG"m+YT*DAm**roMP&0mM
	WlW:ub5e.`SB4a5+^!uR$]=5`9Y?^-W;)SZ2P\DriUi\/K@NI%cg\)&%<H1]K=Rgia^[Wa2TV6-kIg
	u$TP[H@u0&!+aj!%6#`^B,4Y[RP[T@iRRN,_cdLMP5TPR+0nRik262*AR$.4%DF5;--i3[s@RiN!f%
	hU0iJ_L5*42[C,r23PE%J7GH%S,L2e4d1O,uZY%/I0ALVE3VqXDpu:QK$h-Asmo67IdS%d(S"FrbPc
	ij8`Z+%"mp:"QR*>d'9gl`_f.:'&55rTDcUI<*>pjdN?sd8g]OOJ-nT<.``f]IdkisHeio7#BNeiKE
	Nua.nX]u`N$kA;Dc-X6k4F,+%jYqEgg=pK5!96]D.o[o2il:l`.mO$bVG6U%_M)@/iZIOQMa-*D@s#
	KYf(&(ll=0#3[8A=d`arJ,#]JdqQM.k1j2]?0a-NWpMMR(:4*S\3f3TE8fs@IHRVUp"9.l(7gUB]IR
	r?<%n%9=S%Nd<147Dmtj-&*%CG\&5Q0=j;?U+0Z[*>*Ycej.p*$-#U_a?erF5t9m\T-X9c`_8'N9aN
	GLnCeS3PL+IK^G<bnY9[=ichT?)DgO%+7\55r`<BRI<<]&(VbIe[J9Qt<REL?i]'^?@&6)"VTkJ?G<
	GnQ$kElhrnY3H_en/fPE.qga]#+W7@.9q;`d$n*iM*H+(L!k+^3USUSYZ;etW5(@!`,$&^^hS7.^Km
	&Uf0t6m!P66:;5P7.g6Jf6EP63RHS&6N[EFV-#k=pYl:F%8*I[O).9R9IU`m4T`F/Ye:.#M!+pd11G
	UnNJ<2?gt5_o(E6Ve.LpCL:mHC"MP`7H@`!9>IH,Tcg:Y4hD=3N2n^F7'X83_ZU;+7D1&c:?3E:@0q
	)pl<I/E<2h"t'`nEHjuI1lS"1MpIVbk?gJW^hQWVg#/OdQdI)q_:2e:mHC"MY^d:$Kn&]NTZjHo)`R
	5C9R8&V36mU!b>.XQ+W4eOGW0',U3'snabtqnaM,6Z#eBk>)r_]<MCSU^P:^"X]siWDo%pO!7`@k!/
	ZLq5U)p5OGN*&,U3'bM24>\,,,U0M!+pd,5M:rLd"'JU(<?AkQ<(Sq>cA.5!U<d&!2V2"!f)e!/ZLq
	5U)p5OGN*&,U3'bM24>\,,,U0M!+pd,5M:rLd"'JU(<?AkQ<(Sq>cA.5!U<d&!2V2"!gd#LuF/Grr2
	m8O&A%E]";Hc?m)<\M_V3A\^od@<(3ccMM>:FnSKtV=KM0$!9:ri%R;54&!2V2"!f)e!/ZLq5U)p5O
	GN*&,U3'bM24>\,,,U0M!+pd,5M:rLd"'JU(<?AkQ<(Sq>cA.5!U<d&!2V2"!f)e!/ZLq5U)p5OGN*
	&,U3'bM24>\,,,U0M!+pd;V8<gcZ!)m>HR&gTZZupfjgihO@_gXnbN?,pA5AjXfI%PX%#SZ!!!!j78
	?7R6=>B
	ASCII85End
end

// PNG: width= 381, height= 271
static Picture pLine
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%J!!!$1#R18/!3VM"RfEEg&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U%X1K45u`*!mG32Lgi]1'n^$R1]3X,g==>c@D2Y5"Sj=s(=,n2GgnF_@^^2&K!Q-"*C4Q)@n=YUN3
	)&8)=@8@LE/-<;EcPJ4T_Ate;M=Zdbs>!=(##N\;#7Qd16pZZmetQ"g3.[QBBSM<1Z-gMT?]&Fh/E)
	Kc&^2"ju9i,k`:P`md:PbRTD\FO-ZjX!C6%.5!VG&+!;`$&!.@M#=s[7"!g;,!>6UQ!!s6cJ:r_B5X
	Ij\+<dHiO:]eE8;QI3,Xh8*&gI/P#n_T9KSVfW6:;n<+efL/&CC_RM!+pd7.^Km,5M9G&Uf1_Ld"'j
	6m!NpU(<=sd0E3ukQ<(uoDoRKq>^g6I=R!,5!VG&+!;`$&!.@M#=s[7"!g;,!>6UQ!!s6cJ:r_B5XI
	j\+<dHiO:]eE8;QI3,Xh8*&gI/P#n_T9KSVfW6:;ndb)ZE^iZ%pnNHk6oLU00:-:AqHb2.btA,5EOn
	a"eVSb5i8+o20F&Uf1_Ld"'j`asPuJ4B%LD]ag'7h<SKQ>uHf^]/W-Y?Uhfb1O@NF$rFO]\qq>Icg9
	;*O.#e%o@oarqh7+EpQ=b7""Cj^)"7aY,KtNm!jL#0>@6k6pt;ZJ]fj1^@;[u6:;n<+efL/&CC_RM!
	+pd7.^Km,5M9GZ)8*d7OqhO=nJ<bgHBIVq(uS+q>b$tV18MCejh-VnI@fN>j2?Ld3CS4;Y54sLX5uS
	2XT0sjV&A)oDusFnbg?p8,oPG:XrJ;NHY@8,5M9G&Uf1_Ld"'EGd#3G&X5r\!A_$VXY%9Ad1Ph3l`>
	?0USI*=ch7i6#$/+=`BtXdZ+]6PfA=i4+!5_!ou.gIrDia*U(:'Fq-5P$4CLQ-CMuE`p0G_"a$1S*'
	T3JBWbV#J6m&'MXY$YpjOfT.D.t$^lNZ-(jfF9%7Q=\oO2p(i]s7A%iJO1I1nkLWKXW$Aqi0'*['dl
	m]:P's3VD"%\+fR77E:G=2"h#>+/"4sF1HP$]tN>0kNj[ZE!d2*J-oE+eeWaOD2kA*-CjZ*/4MUQLd
	"'AL>0S%aEE58M!+r";8&$0$5%]:,'E'hnT]D-4F#SLW9S5Q;i'W>N+/T.ID(Y[$5%\/.:&KMZ/ka-
	d<S4EW6ZJu?N7.ahY:P#O)PHJ77;Vn7!Ej!`^^'N?6de^8!D9^?0MGZ1sX6T\O7N1>,/3)QHOLXW/;
	VmGJk#`s$>5VLp"(rigX"uo9A\Q42T[[/LEXX5[8Et=Bp+KGdM*?_AVdSQ"%B.<6a9PHXlm:j]NZMk
	&nofN+eoMb8YYDMgnn&=KI@82&Vp*^rbcA#13[U@UMhUCRo*[(:A1nDt<OF?_*^rRZ)H@VU^VUQfTp
	X!Lh;k[^OiFg3Vc)-<n$^"ORIC_FRc$c*hXq0$snB<hVHM/O"PA\qX@u*7ua@k*A\('7HP4P]PlkJZ
	YY]DopKZd0CRZ1YqgW/#!R(4^0n2,PjZ2C??J-AP)NF\rt3qca"bk5[?qJ`b/EdI3:=8341.15g;1(
	B?`=ad0FF+b%:97+/h4NQh<`<JZ:E-Y>:l'<0WZkqBl&(79I*:%&+8sbQt-:Ld!M)7Q?B#oRW_SiA<
	aG#7<6'BeH+j%*Q7pS!3%<VspkBjsKpi7!R=".RY?kAmV)Nd>%j-\P/@R6UIkZ,5T[IN,UbEkX1Q>E
	li8g+.A.R9*u8ZBG+>u.>I%R"'a1((>E%t:]+p5:D#u:)UM#Vp#bq+7eEB?'\^E,I/%Z&RFb@?d>'b
	q$\q=eIAg'h`SM@?jUcj=1F'#,g;9Nr6m(]IQ-7nFlKjBSf.W!+1HMj+8g\Qjd2rtJh;+Xl;'8#&/u
	b[p54;)cZ=)dWXGB'iLm:WuJ`oId=h1?"Ld"dp)kTug6m!o&((U"2oUu>6:^N+JoUu[WCR.F7qG76c
	2+s\WI416j%a@92@2)`pBdTPb,Hu2[1D5*qNKm/*RHR#*f96]l-YZU68WDqt,V,4W9(Y]0&IsU\#r'
	5I^CYg^Q4XT8-2KG5,9/+*oP"Zh2%.A8I2\Puc,/+h4q5WGAt_&U:W"liL[p9cFjJ2V<0$0@\#`h$j
	bZ0D`<Z^K9D#1k7Q=3`U/.YFE1jX-T1fY0HQsN/51-9?<j]9Rp=@e.J"@F&,93Wkd>s)jh035=\S>,
	lqVHR/m\3-Q+/e@^1r9iOW'/OhLj`L9`:hehMnYdSXH1dd$>n`Q5(#?$bj-DcU/+4gnJTh8dAJ2Dp^
	A'nkYi6U5(gj!qA$AY_hM:l`"V\7+8ui-gU>);]mHMab*4l,qXjQuAXCAkYIZ2q03jn;0e:,`,r?sr
	YCLh@m>CqRmC)fMDgjM'TB1:cNr8>$n^b9on[iAU@fD?G`c^2=I^GY(o54\3/tqflI[PA^?QY>Wrpt
	-fXg_($If#p4ETXWBna<PcETl>s_=,/0jHHiYmFo'mq=9n6HZlNP>7rHQcoa_2%.ET@+-1mEZZ0s1S
	qr29Bl/k*2r"soHcI-]D=62qkB1^t(;F(^/65"*6lbX^NLfCea-'5G,/1C,D+p<Z3NM0VAE=GmPN\@
	ll#2&u0_hbeD/ma/O2ZmX\n]=X3bQZmCE@^C5'"n*Z0ZP(MnXR&H4M!Oe]X<"'t<(,lXL`AjV""dbN
	M`13,bp'(MeL!o>.W6IIP']K7C10oB4.'9:$-;rSjT5`j$aYWclCe=OG\8hsKW`$dUm"Pi1HUf,%*[
	r9%2:dj+Y7"C12Xkd@=\*dmnbO+&o<qna/,HJQQ4q+R=Y_%4Q2%3)$SkK[3(m'AG8g2!a3bY_NRKX?
	PaM:Ol^bi%O)DnS#K/]IZa;_FDpY<;c*]XNB?6ps^/s88meYE2(T3*%Z*\VYbAqXXI7]6SHcS;?rII
	Hja@HMup(;e,CJWRWt36+1_4d4[e7p[5l<PKl<McC?dE_paQ^Uc23)_L_?8IL4le[;5:%U]OWaa,_:
	$KDY?Wr4CZ19oAY$'.\77!JOQ,?.D<R7)&jp%ilR9gbNd.It\i5HS5<jVOIql?'jAf93hLl+'%ZD5&
	1o^7.a,kcHM]/O1Vl<)tA4P2>h$ac^G#p+o3MKS1u6la,c9k7ug"+JHO<Sdh<a#V@7b,H#r,da1qK$
	+l@cbh7D82o#kU:UX0:e((N#<d4[f/\8fnV@n,h<Zmd1CG&Q.Q1G?F`aRd]H1FN1\Hf#e5rEnE&cX?
	Ckmck_^cSr]A8gX<[RX3qHK@,2En]-EEr^\r]o[;[XpO26m7DI+R#:Pqn0U1dal`M1Sr-uKV7I8m@Z
	)H7pgp8Bbfs"oSlgp$jree.mprJ[KEVm\2K>I";IQ[V?[l62c3"Yhr\d+*<qB_SSh0%+&DdGh"*'\T
	trp.ik:Uu2ME-ckWinnXfH12W_;eODtEP0bkbJfMi9Gf\]"8B[CXfp'p*Z,R<02X?gMlZ<]J+2b_=0
	7?+='doH(&u*5Hf?DS?QE?WH0*!1>?^$@V+W&"bFS4:PAbjBSWcN'-cb(D4]!UarA)T'\1mpEeluYW
	:Oa8p&\HnE,9C0u-tY&5&2PrL,gO*]K%RV_I;J`XmpjE(YK*o3@f>gMIlT,`Y[Hs9o6R&F7))Fqq!c
	0Uo?p9Aj^!)LiSNENgtNcd]^S8#n\P[O5/27<ppf=D45uHJhJ)'aW&`8/JA8h_VO0AnIf/c.HXc<02
	8d`5>?Y6@p;2N'm6_E's'0qkgi)9eaFNJUaL&L!j!uW]7Xoo;m+o<7G-"sgn%SBg9KqpXR"!FOESd3
	Gn^QXAnOXrF+@Dl1@C]VqVTtc]b(lRLFI,WF*2(kN^Iei]:l,boO;60H0HX6qe2,LUJ3mI"5,\U_-_
	at&mT_@cDf:[A4$$.4^8lRQ?AX+;7_6d>/KCG?jW^E`,,2]]46*)HBA]",dG*+`kKKAPm!\C/N&7a<
	<c;o(d2!3gkOSG]/,b9[F(WZ8nXk*Y/C7'YIfqs6"DC9!Ii:70".E@eBDTBSn%O$feZ,YLSC)`\hKr
	c#U.']AO#4_aipOEgmW6]CB7GE.s)gI&]E"e,q+Q:qQ7]B?[F]0h,DXh$dh<=gY?W.Ee":+:X09Og/
	.QrgJb&r-X/8tp"'[N`qsE1LnRcFsW%45-Eo,3PM?&Nrcf`b\fsGc+Ub%@fbsF?QZZ6AJVJ2go`b,9
	=2-oiE\p&Rr)kRRU("n`NRU&i[^X0T)Mn,i0fIF0Q"#RWENkW,1!fTi@7c.K(!D:g;dC4-&:nG7Z^6
	M?Ab,O.Z>Iam8]Xj#M.4^_b'W3RX?gc&_!6*&:qECh\TXHV4^(2[oa@=FKn$?U,Z<-__)rUeHO/bY+
	#R@%%<&FG@2urWR,11Vp1P!JA<qP5C%%ski'R_o(")(@s8)Ls#T^e![I4LWac""]U>IalM5!u(Ed^X
	::gVeq<2ulZd8G$715CP<]7Q:CmAOuG0*]XjW8%<b+5SG%KrJqs^)BV%e1lJ[?:h;5R56ZRL+o20F&
	Uf1_Ld"'j6m!NpU(<=sd0E3ukQ<(uoDoSfMhq@gM!j^!N/s-mI9X-JDbj0!1M^$59UV(:E<*!_T?gU
	4K@(Xg3O<=/I0>(h0\uh$M!+pd7.^Km,5M9G&Uf1_Ld"'j6m!NpU(<=sd0E3ukQ<(uoDoRKq>^g6I=
	R!,5!VG&+!;`$&!.@M#=s[7"!g;,!>6UQ!!s6cJ:r_B5XIj\+<dHiO:]eE8;QI3,Xh8*&sD"\F_h$$
	R5;05#67c4FmE(0q>_r^(NH2K!&VIj#Fh#518Z!`m/R+d!(fUS7'8jaJc
	ASCII85End
end

// PNG: width= 381, height= 271
static Picture pSigmoid
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%J!!!$1#R18/!3VM"RfEEg&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U%lHpH5u`*!mG38.g\%,Xn^f]pmA<TK8P*-0k;Fk*esgQdJpQO7[#It$R^=cWC921gl6"bg)JD>\I
	VcLjK*`eYD5F2E6`MnDVc25$8i52bU`i3YW2EK5D:'csg+N=)D3NHqq1^q%A,H6rC)k8cD9$"5mI0r
	JpntA9],rNmlrS+T^7RBJ;N_`P`<6/H0%Y5Gj7a_t!9HT?!Pf8@%fh=qI/ksSkQ?>Y6luC;+o21H#g
	ikW6\mo+(ddiq^_!4N!/;&5!&0)i"+VO_*rl]mq>an/d0BY=LcteU6M(;o&>B[8L(Jb50SJWlJ0@<&
	!":%I!+6)[#67,I4ocEdoDu`=U(76Y&:FO4K]iMg+[dCP$mGHI?jP-b!(2Q+!#S&p!Pf8@%fh=qI/k
	sSkQ?>Y6luC;+o21H#gikW6\mo+(ddiq^_!4N!/;&5!&0)i"+VO_*rl]mq>an/d0BY=LcteU6M(;o&
	>B]NPZ-a@l$L2DT!lA?eaK@0K'3:jARKaJ]Ct[@+5ZjHhb3JCd0BY=LcteU6M(;oOBTC8!!(PWqk(<
	4FF7&q27<;KXl%D#Fh?PdX^_IR,Y<3^]h?PO=Q\-Ho0W'M+:jP4pS5<e\0srFcFWJcELa[JpWNU8V-
	a,dX-09J5C0[)d:^)o!/;&5!&0)i"+VO_*rl]mq>an/d0BY=LcteU_ENAJ.+%B@GNZY8s1Q8C4C1`j
	LcteQkSsQp%DS6+1r_TW?jKj1!)T?U)n4unhKe+W-Zl`qW5gF2+41=D!c;,I.IZL#B&@MV.f,*J!5K
	/?%fh=qI/ksSkQ?>Y6luC;+o21H#gikW6\mo+j<7J9Rdt6fYEPd9OT2dZq7ct2VulF1'R+NMF8%dui
	g%^s=8Do)#gikW6\mo+(ddiq^_!4N!/;&5!&0'XRfH-=2FY%@c>@<"d,aq!I,RUg8Q%)To6Dbb!&(m
	cbBO6l/0Xii?jJQ:!1l/mrfhm*da.htL8%a=p&4R@TD!Y6338=;&'r34MOi8Rs61rpd\^099PR;^hr
	S*]W=XIX-'94q1]>5F[<Isu/"3\Yq$jpfrbk`,lO&DiZ6jA60fC;jp@C&B/@W@WC8)63r*k\]B-Rut
	43hEP2ePNCZ;TD^e"bITmnE[[lBje#kO1j'8So@bP9e*dQKdo$s!['YVJ/aM[!)Em:]CiHmf8*e'_W
	%_m?f&]ZcS/>V2HZ5<O:7SEF"n]IDCa,nOpT)^MdXN$hJUmM\3'\6lu]5bfJre^LYD#pA.`\RmonjA
	Lcg#.T((O*sd\H;9_dscQ9i'%/Zl,75O>r#s+dk<3])i5O19h7l?]sBDaMn@!FrKp?p@DO*A]F.\[G
	QTrr?:mt="f6[rfL6fa@;d0H[B=#d:A]"2UNS,5ZE[++$4#)+;u5S_?Tqe.aaDiThjH5)%r!u5XLfK
	U(21V,kLLd"XdLcrC;oRR>^Eu_SH2!@cU9iT%PV*ss,$IK`JkeRE1dZ95J]Kl)iTB3Yqs2fs&qYKES
	O/kTD&UhGbfiRpK&dc88]'RFfB8Ab0PP0_8p!eHc^E?VP-jQIWp`MBf>hu0FLd"X)g%5*LnSu8#\j!
	;)QLKOSJMQI;po"0\+"2bja3bnF_>hW2$NqQc@(ZSd/2R(%&d`]mY*td9_^A^R"!/Z]W&-man471;U
	?`UI,5A)b6m(n`k"Sn[+-hMI5#>_eNfstPZ=K+]po#TGklW4GS"/G1'3Frl6ULtu'ntiR-'YqN^RHa
	$<$7nGPXp/P5($u;W'j#q."TUKFP=aT3B.H_Ms(7aPT>/>Zpc8cqS4(m7NqsW<JBW=7>bYmc!6N)&:
	@F\U(7s;I<',#,eZb<;'h#^:k[+bABIXf[Uu7;&:L3:fgdTt;[:j+kQ;"0%R+AC<#_PBj=/*:3X>_[
	&*,22K3QXN6+,^:9cssoE#TeEVPprZ\P5d+Rf$KL0-!P48W(Jr4td)<9JOT8[>PelqXEQ>TGkADbBO
	9%*;8D;8;KG`MsQW`)=*sL&Ue$k?/[IbB-M;N4tqVL\iND\1n!E0*<ZSo#BK$e7!,_Hid[#Eic1Sl"
	-a;C#I7m4T"/QObi]]AV*jm+/F:qRO:cm`"#jX3kdWV\R+1Ra\t5Cq&7F:`"\ae6Np`8SlYq.sJrJm
	qRQB$ak4D=M(t"+a0uq]%PC)kM&<El[i$6$n50V4*Xi"GR#We[je(Cc)CY6<&ZT']Xf!'K+VK!7b/0
	apEM6RPl@_;ea)!ese`]Gl2Ymr<0qCmW.%]j0Q"#Ce[^cKIs0SQbA^j$)R0\-7O0]#+REF^gYJaj3O
	O!Bj>WJE_>N?aX<WJE_>M^+F:l%hM)M^+F:l%hM)M;:3XDX?4Gi,B>FO;kfU-GB2q,C3hT3Z[(`a7#
	jt"LnaGQl4;<FKW)S-hm)]aP``K9>MUU2`*5>!G4Xi&K%($LjEfO,tVt6j*Z(Zj?W>L#lTdY#8\qQ1
	bm%#J[#]H'@B>#j/uT/J$j_Y+@o6L3i'I84JVZMne]8?SC$c@JEe$lFiCXtqWLX4knEIOC2IbXH^TG
	K3QL<c>@;VB^BB;:T%1$YrGB7>o#oL2cgC%^gXi?I%j'594*PGa=21aE5Q.RuPBVmnDR0#sF4Vut42
	s@'FSbC6[;Gm=Bu,k[f;lHi<K[.S.F5d!m'D$/[bK;]oOp7O)+`G%Hp5%D/rqO]3Oj&-]UnuZ(H("*
	01i/MKsYIP7XaFuqmH(-ldFZ,4)mTjmG+\ScTIu-G^SKmMVE$t^E5G.q&+P%OhZA-pcq]dd[u0[+9!
	r7r(oAS]:XOU?eN/A9(4.+C&)dtiR(/<Dg-Cdo'uJ3fA9fFb.d!\\FdW)Thn:\&dd^q5QQ[iOkr6G;
	#>_?lh'3j4oVrTdG@(QCKf;jdDd1gdZ7a`l7"#3?M&&n6'_Db/TZ:^Imh%Bqn'Jh?iU'P5H1.?^,rO
	MrT!'*YH(a,OsCL.5-9Gj]\pp.Jh$YX>CmA"L7*LQ%fH>#l*#$^Z:.M_IfFjXNh^s5]63*1GtCooeQ
	7+'^*)Eq>@?lTIM#%S<s-L'8XbJ15CE12"hhXD\QKBdc!DqQYW=!@m^NEmJERfcmH[Dp?%:C)\mjo%
	+'0,'m0sNh.suO*!-:O"M_K8HD#3Jo=g$D@j5V%AGAc"+MU^6.Z>a6oeeU*1,FqKDB;Z594JH29nVg
	Uk:$p/SKno[&8,[i,k#pU-VQYDBG<Yh5ajq4Qff*:._bbloA+r_1(9^i&r]55^`/NT?iek*VgjB9MK
	.HmE1bE(;d(FWr>eI$1qsQ%!32jF.`bF>>AE?F3l<E/7pADN-&*dh(:H=_EQ*NW]jlS(dFGPAXC2.P
	7[![/qr1(JG8$q9q)lJ,AP*IP?a((0)HiEhr+&5?+b%T;Z`E&Dn%rJlQ$7ILG4%3nup=f/j4e8,I^%
	TP5YG]/7aN$MOZ8GXo>e>(`5#>EN^IU;"fT?+/s*j](oc6&UfB\1gqfV&JU%IBGM8#db_/C87=3o5)
	,9=Q%7))9n2f)<4okI&r16Kq)%m6N4iSdpH'-A4Dds'W5rd_Jg[FP2"V^ib<5;b>o#sL:S!T#!r7<0
	A<\,Z6Dl,S;0ZU`d$YFk?BJ%37#s*=M/l@%]PM:^A/B]G*nEZCu.l`ESB%1TmeiBj**4Ml^."5`'jg
	c9%bCX^%7fqQ0ppk:!Xm,>k9qWUeVAaNYQ^YoB&Fj2d)rV#"2rUZY(lE.O[(`Q,_p/C_@UMJG`okEO
	eME/tHK@?R:U`PE6[41/)#CnahrZ$?3lW1-tnODnpn3N&Qiu3irFnh5'FSM,&EdiLOhE9V7s8DfG#9
	G;^67YIdG"danH_B/MIL5rDk07)7ArWC3pgG3#[kHo\^EsXmCKm:BeBstdf3e!a.fIm4%]cA-/j7@>
	-B:RXUeIGoLjk13^$[r;]6h"bWK[UI*Rgti#;gPbN#J!5dB\g]9M8Eh<,Eo?pG0oEH^#apL(<,hU0h
	Aij/BMr<R%YJIP8ZA0um.(,bi?FlI+!5]*J7(oMJMs@P9IY!@e9#7nIfV_g3[EdZ4.pV`b!3G[+St*
	G(H;<!]4ZU321-3Z/9!r0m<=,)JHZR>=$610`t;aeZX23iYom*iN1/+.%,\cu0gA;`'Wp"'V?)30I1
	&'T9qX?Aa6Xp%Bk!32jeJ/NM.r\)^HFV`Z<u5TmS>bE]de/T,:mHO48M*V]2I27\cX,4n,S&H..%(%
	j#j2acAs%g/GQ9^%&C+Slg$ju@ZF'%(Z\-ZEBElBc&%>pAc'cqTGtla=.cR5`HU5A^*b5LS3-0739H
	KrBLf0njPVjg*e,a*Nr4qQb^dYG4I_DnWR:pW=6Do^<B9^nb\ln!Q+1*Eb>RPfdW6S5@CuDgM!2Km<
	TL&(I)hJ"pB:?(CT_.t)i'N/SJC*^h#60%5"4G^6-XptO\j)BAD1]aGEeBp#`8d:L)=YP$JC;Yo2$Q
	l7=G]!JFC5Uj4GbEbj&YekNgIU"&s=@2W\^_!4nl,?.6d1bisl0t9-IP1j)4@Sm"E=Bb,rVJHM!?X'
	!J<u'U!#S&p!Pf8@%fh=qI/ksSkQ?>Y6luC;+o21H#gikW6\mo+(ddiq^_!4N!/;&5!&0)i"+VO_*r
	l]mq>an/d0BY=LcteU6M(;o&>B[8L(Jb50SJWlJ0@<&!":%I!+6)[#67,I4ocEdoDu`=U(76Y&:FO4
	K]iMg+[dCP$mGHI?jP-b!(._t.7oE9@QlHa5Nd?>'d"FFig(A12)b<E*!#J]laj+hHP)NNED)5I9)s
	LJ@(ZRAL(Jb50SJWlJ0@<&!":%I!+6)[#67,I4ocEdoDu`=U(76Y&:FO4K]iMg+[dCP$mGHI?jP-b!
	(2Q+!#S&p!Pf8@%fh=qI/ksSkQ?>Y6luC;+o21H#gikW6\mo+(ddiq^_!4N!/;&5!&0)i"+VQ?n`.Y
	g.orb@HQ<(dNu^H6S1B!fYbY<gW':8)q#2@q%rDR]Tht+V!!!!j78?7R6=>B
	ASCII85End
end

// PNG: width= 381, height= 271
static Picture pGauss
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%J!!!$1#R18/!3VM"RfEEg&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U'=17u5u`*!mG382eFfBQn^f_3AD'4s&<5Vm"gIpO>j&KZG^/@?/a@KHNd,fmGm`-oO'$8,e'^6AX
	.>7k4+bp*%SWF5E`tL_nbPVAC[h>&ULML3W-8;<M5!fh-ph<5ndTDY_e/@um-a7YIdQUmIeWG]r'M+
	fj!2M*IX1DFqhZUJ.S51V5QH>WA_XYnS6c<uTQGuR!#UCQ"+W[n4ocFQkQ??$LcteUK]iMg6&7])(k
	h)TJ3euT!#UCQ"+W[n4ocFQkQ??$LcteUK]iMg6&7])(kh)TJ3euT!#UCQ"+W[n4ocFQkQ??$LcteU
	K]iMg6&7])(kh)TJ3euT!#UCQ"+W[n4ocFQkQ??$LcteUK]iMg6&7])(kh)TJ3euT!#UCQ"+W[n4oc
	FQkQ??$LcteUK]iM@3e$e4f)L'0[_B?'l(nA_,PjZk:(NuJcF8#_Pn.5AH7;,1LcteUK]iMg6&7])(
	rYb4!WZ/8Isnpq(II[nH1fut^74Z5mJ:4W%\Gp98\/QR4^([kTNFj?!Jip9,#A44P8]F>8s6opniO-
	./#/1&`B1i]S"I>B8\3kR2\:DuL%,WQ(kh)TJ3euT!#UCQ"+W[n4ocFQkQ??$LcteUKRN]I"*T*s/)
	u'ST+?BWjOM$k6m$B`rVplPdn>4b)".HT6+G>J*3fCEm2:t/SpBuH*U5jgj;#KF6m$B`g?[=%*;s6X
	s!sh)Jml:o!!XVC!+6A4%fceWq>an7U(75.+o21H&>B[8"sNh.M0Q$_.DKKlEK]DUE,,pR_flYg,+i
	eqmGP@<+*b?3.tPgPdK]c)&:FO4#gikWK+NG20F6&2!.ti2!&+[_2M!D:2`>I+S_MXre*-F%J?2n:U
	662r"<:_T!2,]qgLe)#!%&lc!+6@MqC#RgcQ:\6?i?tQb>@fCAps.!mj2</XKGTrkPrlGBoYTg2B4@
	(o`E6k50DI@iR?NVp.hNPT`kh-d:h9EP%)82ReRES/UkH8p4$$Wlb0n*C8-b<nO,"PesUSloZDrmPl
	0j=PP":E=o*d&X+4bQF"`i^]d)WeR`EFT2B5J?&/[S_rQfBqn+5)W;(WV(du$\lKWCFXCDsVGb#Kbd
	RW&Md[Y[0Z(U,H5pjCf^pSYYe*r*\>Z#NNDo!mkQU`HdS:\a]Z_-kF+!)=[55YQsZVi<Pk.;sQXA40
	Lp"[3T4/PDWuT:YfQ;FWsj+&4'W0ODQ#e5feShP;N2*t8G)*XZUf1n+1%n#W\C(;E'[r[j7g\ntZ2"
	o/!\2V=o<UNQ?Z>2%>b#_#DlU-f"bg+Y9;D=EUY4g+Im?E^K7DOp<5X:9rmDfAN7cCIo*fU*q`fAk9
	,L'DeqI"hA,!O=u_@@VjZWO8l]AXrAaq=Ekh)Tq:/5/+'GRjXWanULE5q8D#Gf$pY#[Pkb:"*l*e0M
	6iK3%'/th]<,ijQj:1696qWTU+5jSfY)%n=ue85)dnJoBGhAEDADnpOtFW)HG,1OBO;BO>J$Xf"/H_
	m@ce-&UbLiXgU,Bc=r,'oPk2@m\eKMgPPFoH9>rCX]7UE8!+C3<4oZn>4m-\Da&)r7't^WePmkWB=_
	qA1$A#uGdNq/UWA6T.U$l^>;'6#A=PH>p/":%a6*;Q+2p_A;6eQ%heh*XY@qZFdAXWmS+*3:Ld!;OR
	t;_Ppe_Ad*u1]kkAsquis7l,NTd.3,bLbD5OQ=(-4BiV_N+aAqPY7q_;FXsi5`gS09,Gc=iChT-kN,
	6MU69EM;U$()q/]Z0"YCMfkQC6;mpafk:R*mkem&pQDN-:+LXZ^A[sBK=7)\Xb+6-adY<,]ICNVS=Z
	Th'E.spe4#Yu_`Xcc.r5],jLT>RmHmr^mPfoW+Kgti7-q#/[Q2\_(dq@nZ;e%Yah6sEhYqu27f$pq!
	#<<t(E2?1\WKX<,dAYn?)G7ZfNZR85kehNE't@0i;iU/-6(Wlr>UMORQ*aI;;s`^65);C--2i[)dt/
	[.rkpEZ2'>gc+0L_geuA9hDDRCpIZA/.VMIE@,C-A#_@sC7C#l2sjFHI3'p<LN13osb0)_^Qk51MPd
	7;k_5:Y@YYthn(:afnhc^4sd+o3U&l#V52*gKt;aaYq%Gq^85O0ZbF5;VR$pDNR1.RY@iMsZqc8K[Q
	.N>%L!qC#!QcccjQ3&))@O0Z]+-T>l%`(YtNaq!/^o><I]9S_i,XKXjo0\FC%W=XKB%CTmb(>Cf')5
	<1t_&U4ofZ&ciGb&.@+Lu97AohIg[b\JgNAZ\j04dW?To`T>rRl(iWR7/R\?,^H;1+\*W$DNJ!Jd!C
	;["^F9,ecpNK84.P(#G+o#I@Uib[@]]E@=OegW5k4@hs6i@)-IQ3OsH&4cBO(q+(C(;"i7&UcWlm?s
	fkQj48OLI75W_]6F5)"W:AUZ;KBV9OJ(,jE]aO?%cH1$120d7;;)n((p-?[CsHSi4H('V^YOEmm`bQ
	)m+_;X9#EP,'/&=.Rml%^-/7_Tc43R=<?-jkM+\<j&I+='nsmR`EFTDfF(fje0])3=@,HYUlo:N=f>
	<&Y?We':XS>8Q&nq't\`"_3I2VU:%-V1"Q/F?pIGFFim2Ehp%jG!CgrAN%9=@6t^XbarI&3QPXi:R"
	ab!kdJF<B/Yg1Z!4+7ERU4VLd$]r_rjs*ebHUVI"%%FPCCt]5<!FZ/>A3"8O$ruD)gnOMD1T=gJ3EO
	F_r^SlW,F.O.tUSA9VaH7b&7NHg:9KR."*)U5u&,aCKL0@_Q4>Lcu0+,EprC6eNq.d76KBA9)6Prd3
	[?^TnE!'GPWdb0UublB0_:X/GlEY4a@Od7;#lQs+&m*m=)LDWN#;.#@N#%Wd$lis=ei7.a=fN--UKq
	@UrqpYCno,B%DEXDH!;D6]SNrJ3Z._Y-YZE%"rP+Ss.sgG@*jTkp!HkTa`an]epF>Esd',:@<R1_X@
	?pETOU)V['m`AUKc,PoJ"@i_n\NRQ^>5-i'!9Ls![F>KYPN3PMZadDP/'@B<>fUdqAbkKqMkT_=rnM
	(pDqsHiD0dF,>@QNcFI=A,@GpE0Q<^5=pOTBp0\pG!:9W?pTZoU+rBo,4plX3?_:j)LTqNt5)(AqL"
	7kKjZ\nmk@%]5Nj6e-Hk[lb7N9Ib<PI[=oPM;TT\4L&,iLd!.V^B'8N,9,FJ<SiNq;K)^R$@s/*aqr
	Gq6MaFtDSSTA\8eQs&Ud6_T6N]KXB_`WHhKG4'Z[FV#DJI-h^A?`J`o`fF6&/Rp?pJPi1SOlE<J@G:
	b:G2:&)m?d0DaU:fQ]<B1J#hLq_j#WIn+,W.sk/oF9AP>K]b^PYCpN%><UV?DeT98P\pOlKoBpeE;>
	ZUB8JrC&%=7q<R?H[pXd$FT(mDZE6ho>$IP(VPK'bB;Z5s/UgYdr;!,<[C(r,*C06)@-HZCrT?NYl(
	cj:S+(duWDg)uS^M0JpZi@95HjD@^0>B%ne5%#r=5oN*5RD/RO/@@DDhuh']Y`HSN(RRgMX]I6L]DE
	kGi7<')C\89mQV_0>4/oDnAaBLCTSiR0a!<:2Aj.2FeAX4IeW_<mTTALB]s>9TiB:nS#nQFkZK54*p
	2E0g5BiH[=u00g36pYAX3f[h;d:-Oq-C[bG]K8;VtgI^^oFLJp1&brJ0V%pe)m^4uO^,tX]nC>Jd($
	i64WgGOKVns&la>e!W1puIWbYcCF'A)H(XJH<HtF(`VGb2'KS2sE8>[FWkW^luB!8+^lpg&Cqrs-LJ
	o]`(]r2s\Vp[V7s<nTEIJXrTS:YJ9ngF,Gp:(2]%N*Bp)JDeP6Nh6n^baa<gC=8X&b<a8$W7shkZ&h
	j:\=2(Epn%CZTO8I+#X)r&KM^3$+`!Pi"mOlZYinA-_;m,W#gD8nJgU:$M4j<\ZMqpHTg@r5:-!n=E
	^ADG@AbPn5=dC,qlI,L7B-g.BQX3j[ogu,Yg;^>c#sQL/r#Uu[2)U4@IR]F<_3KHZ7Vl;,%j.)o*q@
	#?g=NY,ptDSlc!S1io9V++bkMPtI@!^Tck+#`=_#HY)FQdpp8LuIQfh\&Z0LJtGAoDQYq6W,Ps458g
	<dW<4U&iM-O3!d:F9D>gXJ(Aqi+mkT]%\>VYsc6\T?l%1T)A]$<U?O=ZQ[-DU`OXlL=T^cUD]PWR62
	q=7a+1+@JF!(R!(BWU`g_8(d_9hs91OXdf$*?2sT$lcs.8c$N1`8]N&K"<['_*XZUU336,bn*0VPb^
	<4LO7>sT/m>V1nT*R?YpnQ`>+um\HLROjJ"H[#i-P!h;=t>,E?9U\EM]:[`e=f^R5IX"d8:&P"r&$s
	PeXq]_Y[WECmf2=ju4[#rNlJ"Ff;49+DXRJB5i5k-3mYHP'#H%id%OFY?+fUf5";=W3tTgdn=a.U7[
	&fY?-\k(FIGR3VDX7>'0/>'Ai2@A]qIWa$60bp>8()80[p%R[\A%6i-_Pi1lG]LVL$m8e979UR-?lr
	^E:Y`]H1q>.QQ\E_f1q<Zh5'>Akforj+8-3U<m)iU^bt6UOK8G8#@'\8L'PNcXC54>nOCEDN`nIZCR
	6ZR555s8M.>3q_a8)1C:ZJ%r_]m7k6BBpR.B^;EtiTAQs[+/W-Z%Vst[+T)!+5kK,>opRaQ^A;S9dT
	@chQT&_WBR"dUNsQ:+l@jTQ8NaiDZt)bJj.4K\C0ahHT5o_STn*5ng(fQ'fm`puB?qq()'Jc9Z7JYX
	s6)t0f0@rp8)%ppFil66iVn<)m.T1VjLt<-5JF-iGO=$+CPHcUJ7Y^fY"fMRRA7LK;%MGj$`'BI,>"
	C'IW";j!)M\<@7b78rqaA+o_-U\/kJ*Ln=[5HFH[KD=J:H#>bd31]1aR^*70glhpq6-5?&nB\&"%74
	J9kuXI/_Q-h#9AUunp:FtE\ciqrO5Hp0\.qfrnqCMNKNlq-&'/rV,"qK_r#X]r3sg2"*3j$n`T6%sq
	W*IQlV*IQn,8`/D]CR2^2m;M</2f+lPF*:ScCQ%)B\?_I@BD7@*J;NDWUY7CWU@qD3EAL[DjRYnrW:
	j&Dpa9L_;ZM<TDOo@nrjnEQI.N"5Nu1s[nS$U82sT;WHrGOppuCp?nk[X-gcg"J_sAGc9`/KT7R#;]
	9#!XR041jeGO89b)V+)iLNS"%4q2r1Kk`9O6jp0-6C06-2JMBOM0nY:7QE`:VAf8HT06E9#_dB0iE-
	"H^VDDD;U^dTC0IoR`qSl%Y1?)aO*8a=STl*Y#P'h,aJZ5A8jDhBo`MtdkckZGGJI`FH\o9r:h]B]:
	\k7GB"q]BrI-ml1869C&YgtaLjk2&<`c?Jiu.kS.JD"rA,8YCUpZm->;1UPM+<!ma@OJ+-iP6m`U>`
	toL&8/BWBEPN,\hF,`d@7I6Kg_o;Spn.V88DnApFJ8#$gr!'p/aCo5R_%>WJMfKUa7E\f?eeO(Q+H>
	$i"_WWBHCSa2p&H+`1,G04Kci^G64Sn=7q/k&jVL/B2,AF=(*s=,d;+V)t!Y-m&3G4?l;/gJN(G/rU
	l+-S/!R&na5+dR>7jgtGH&9lMDKj[;-9M:(Ma%J<Em=XM[VZ]VW?bie9@>h7b.mk!j<aQujTERtquL
	3XZ81i5ib`8X"(S*uI`7mrW[mj(2a5(\.#d3l!GU\&9_MkUpq7=7_tDEL.Gg8VmZBP9qHqh/BU#Wa!
	%(7/$ma[fc%A;eEbAQG8+egG,GU0*dceI-or;ZUXJ1*YiQ!$AppJ]\o!uacS]]k$F>E<'fqK.hglc]
	sSut'd;;G`Cl'"8WEaE7Lr50%pW9#tojRb2-A8/=SK9Y7dCY5MH&T%jZMma\][O:M"l'XD%>;Ei(cI
	U7\NbS"g*u+)5?'OBirThRh\pn*q`[gbR7ujNdn(o&!9&Y^;%Q_9+!'-EaFL*D5SFE2u3]^I:23mf+
	5Ot^:.9aN;q4ggc>r\q>/B9=umF$iLn*4mrVX"D9l*u2>%fj\@D;1SY%fdq"q>an7U+^6T'2Rh[Pq.
	!]%!Ln95VWk!NB^k+[s'L;A,oRkU(75.+o21H&>B[8"sNgC?kB%C!!XVC!+6A4%fceWq>an7U(75.+
	o21H&>B[8"sNgC?kB%C!!XVC!+6A4%fceWq>an7U(75.+o21H&>B[8"sNgC?kB%C!!XVC!+6A4%fce
	Wq>an7U(75.+o21H&>B[8"sNgC?kB%C!!XVC!+6A4%fceWq>an792\`P!eGm>96&7F,=`Ff*7RE8(X
	$/mn+:W#TI=X2QIk@iP_4l006VXJ!)O;eG6#E$6luC;6M(;o+@I:O$psRe^`Z#e!";3d!PfgG*rl^9
	oDu`M6luC;6M(;o+@I:O$psRe^`Z#e!";3d!PfgG*rl^9oDu`M6luC;6M(;o+@I:O$psRe^`Z#e!";
	3d!PfgG*rl^9oDu`M6luC;6M(;o+P+r88#(tX/TQ.X!.Z7THLrUeq>an9Y;BR8!'oZC5A!b?FV41bI
	K0?J!(fUS7'8jaJc
	ASCII85End
end

// PNG: width= 381, height= 271
static Picture pLor
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%J!!!$1#R18/!3VM"RfEEg&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U'Br(V5u`*!mG320*;+a#n^$L]4%ZmY+HR&'au8bl315p0j-l];BSgI&W7<kI8jOegG*G7D1PqO9L
	.p&)PRQ3.(c->j.AK5"0QNb(eC_-XKLmo;KaCF-p;A-ZHi/])AY19PXj]j*?2r:-H*t5I:8ck$^&,K
	Ms)=.ij<&@8g$aCa]0BG]P*-N=7Kidj>deLMb3qb!!(r$n#69Afq>an766?196KeN%5mVl=0F4?_!!
	XV=!Pfh24ocFQcj'Q'&GcB7&4.H=$ps.[J3aHh!&+\P%fceWoDu`MKK]AQK[9r(K+RkZ?k>XH!";3X
	"+WZCI/kr,Taq,-+nPfN+G;oY(kg6@!.tjZ!+6@)*rl^9kQ??$#^l\,#b_b/"sNU>^`\:o!#UC9#69
	Afq>an766?196KeN%5mVl=0F4?_9[JXf-a`R`CUNEW9n"`!QnUiKR%Uc%cYD4(g[rYf=8ZA30O]Vu!
	#UC9#69Afq>aobC;1PbQt"6gDc-FQ>h)j)qY'*dSbMGn]XpOdcQ8Ath7N#[>r2EtYEfFr&GeYK4SbU
	FC+q@j8c%!Yhi_PRH+iXdDuEeAJ+1#pl*aCC7d+>[B^YqO5mVl=0F4?_!!XV=!Pfh24ocFQcj'Q'&G
	cB7&E`Tc+7+5r8)A=`+8(*DnS2GE66G^5='tg(hb/KnB^YqO6)aDV+)JK79A]',B3p!ULUn"A]HW_p
	cj+sF]!O?`d/Wo'5:?)#1phH,^`\:o!#UC9#69Afq>an766?196KeN%5mVl=0F4?_PXq`&1ub,@I@V
	W`LUa_rPJ]Hf.$9QK'Xi#8b7D6jjH[Mk<;HT&&4.H=$ps.[J3aHh!&+\P%fceWoDu`MN,/P/eC;j@c
	$+#*6X>?%9*$B`P*D3,BJf#G;?-]'Z>H*)%KMlLcj'Q'd*kKmSN)*c5CE-ZIP4&_Z^UOUnqT#.7kIB
	g,8"4g/2\^dC)n.Q'\r?_:4te4lg2Tsg@jYe^R(X`RVpQkb9'd7ZIBqPkipgT&V%Ng[T;^(0mtfblN
	OTQ67r?*gnf(<AcF9001-1k%Jk>6.]obP)tEm-P"D4NXN]:SHV`trs7`F[>3Z:&1t4Br`JlBq?3Pr%
	[V\>Q(f*eQ^%PE43@TD.(/nF"Y$&lB3l5<BW3+V?Wo;-29+hPRg9qo`8\^Q!j@&26j)>5%P!hXKCg4
	6O"F>D?OuX0up^pJaC]\*[O$kaShgG7*p0>+h2=Mok/KWLcH?uqDO\f+-Um:WG3q$b\!'rp7"'J#DC
	II9ue$_&^G2iE+Xo64BD0g?RLt=I1PNkh)Y:C=8MYd1t/JuPBTat\]iX"mVNkh!a9GM-NaP<.VC1CV
	CUuC6MO$pWd-nmr?52aj1M5Vp]r-N-:p@[N`l/^8.O)%<2+\>j==%A_bJO8Q&%dpc#><H6=cZ-CGB_
	*?;#^sM)foC']FXEi62@fkHcj*I[/LtnOm:3ERK\JP*[!<3NKKc'f[a*#p)eLjB*B.W#LM@ns5j/:g
	H1A=!`sl.)BLjKCBIkK%HE+E>C*1/7oO5D2X0#=e4)(6u%935o)kdf&3J4hDD&k"(I09kM&#6\9r*m
	'Vgo0oY'SJZ/[b]sn5E0D"5sa_PB[<SCInbF-B2sC!eNSS8d"eke_Vr^&pc##2l+KKmO!#S;@BB3%,
	FV=o6^chQlSY\jpl3XUOh*,;>AIt!8RM(nQg[DO&&/_Q0TQ%ugX[!l^-o@>IhDN2c?>9:^<IJE55[h
	4_`5qu*P[&aXg?aMT\;mB&c+1RW@)k0Bh0SYVS?K$FIGfD,t-t7."4kVj>&**QEdipL)(:lL<t]1U-
	;<<jDkbIFQ!<g+3&7(CT/\)ZJgBfr'9J`#c66WD5%m)7&^dp0LD`s<gtM;I?YYD%jRktA4j,3g-eg*
	UQc%4<'9?0$Zc@bp_)+@8rM%d7ItlLKm[mH(.s;-7n*#rbCt=(Dq96+d"dA^I8i%90Airb(\3j*6hk
	n+PrccjT3$Y;7HgLU70DDiGAA39:t*dQUapX!"3!anULFDoAupBUmhBAL#'bjK7n!dMbuj"7CBf$Cc
	ppM3lHNGk@=/_p,P4iqS9sB7]?5&,B[Z%T2J_^Cee[rAVK&pX]OXT+8l@Jaom%uOEHHlO=u1<$,\cS
	@9>5><>_n@s24=0fTq7j]Bhoo)Ctki88*('*T)")7g4r`8I8lH(m?q<0HMd1=ToY)ZP1jqB.\AH?>h
	GJG?6Jl;0fm21ba&VUqteIL&'i`7n,f;EMW*p`Qd_>a=P0&C`CB'd,#h/fhi4`U:i(eK.RH.5\WAJQ
	AjA'_qC$^P]&c8mfU;i[7-LE4[?p-D$i+7Z'?*B'UT@IAQ(R2$R&t=dV#h<!kbG4ZHBk,ROA'D!?_8
	UC.hlHU#6c@E;79/to$c=Pn]W9)L=Ess0N!Keb*MYegIeX>S^s]bqonH&:kV$T;Pi2tRkNs[51Mh(6
	0P'pV$!oam_6p^eNP=4cpudR#`!Q8CA=p#%R?4Sm:.mWI?YabQ!^]kj\HZB4pjaBUTBhhjekuCUJQV
	-apM/J(!^Qdm2;!=66Bck.Y"8FJH7>oD8!TbY)_leO;C5*AV2I^[%4XrH-Gsja9SE"ZHuKV:R.OUgG
	<63#^lh^7l[S5e^]hYk0'*jnm0n>!>@c_,Oh4?*G7G9=)_"Qq',GCB^LofD4Ne.;&B$PoFY2&bL3u5
	3_@b_7"Vkm31OVI<;XajcpqJ(K529?ST22i_cA_H5-c='&P/edQ!Z(ZnT^qUZa.<:2@i8#oFXV@mZh
	,f%EYD,;eJO)Tb+R-(kp=,i3_"c)nB%!Yr'%(pZ_.aM9nbcZpu;bB(Dql$fc'p0[0\I66Cd;T%7<sI
	ra29!SJ%\#Rk>fT4sk<F)TGkRg0S"O+:o)7-NZX^tn-]N"^k.I+Rb#ld3[*Y+<#G(ah'EIJBhsZEuC
	;ele/,d+7^eA"7K^o\l9Q.e(&:+Y?82e7m[EFZeY)j(on6NCE'K2pQ^H:>8eoJa]SHG[/L[02%K%<*
	+-Lf2.,aI,Vd?MngtTB7HQLI5;K3-ol1\ns=EH^NoZt71"F<&Gde(pS89X@$R=)IfJH..^ddX1WjDC
	66@N&*f9+WR56-DWT1IrG^RG`>t-j!60Ltqp%[Qnk)MNFE;+7bQVt(llK^r>pe9uJY:UgI+*r5Y1!4
	2C6=80O,=cj'mp>\]pA2IeMWF-_V^m-Ig]dkUSE;!ei@/s]J'WfV<;6LS*p)JBDIk'bi>M'l/K[&k3
	tqPVMP#g=Q&3kC-difJ\_FQ?m'Q.W(O$2bb#@^%!\2<kXtIE`if!ZspV0f%fJ-YoHWIO1An_#ufB<m
	WhPqN!>-ss5g$`KuY,/j]6k>p%D9GFR4K^=G$tQfe\:3R6D=$TK?A](VkSM'he#2lfLE=n@^]!Pu5I
	8\+OaZAN:@?l7s*=Th/\U<gXnojE'MeVTmn2UMr*<:sAZ%8j6!HDFf@AF95JgjsWMgB8G:)S(JHOW=
	I/0_VO%c%?`WZ_aR5Sp#pYXiA?-hAQVn*BZ.ciEK(UYeO:S0i1:0T@)QES;=;S*oQ2K45VEY/)2d!,
	K%T)7L`eT:;W,cN7-d^%E([Jm;;o[L-UHL1%.p!g6VqPV#RFo+,3Of@bE*B9_:GM]=u$E9QL,7uM$p
	$\a9^o&Y5J$Y;0mC@1e$bR4/d%?!:msIVA]=T@\Tl=-.^$pXQDT`g?=hK!to,?c:eJFg);@dqoW[9U
	J''nf0S(kB:I*KWpY3sa`RF:TeB`rlrEF7Y;Ica=IkU^4sIXt8^gS]7Ep9Vup?[DQ_h:U.2k%j*4?)
	kNGDU!S-qK't30f\CM)SP47m[#133n2Wr"htD0^3eJB6RV8mnjM[XBQ%Nrk4'OCjtjUA^AIJIh4LcN
	TkfuGOX0Uk3i.6dGC$PYYN2_Ol/,Q+GFuW#'[f=Jrj'H6:4_:!org04DnH$u=]P8<5:t(,K:SRu4+C
	S"1um;*4^"Bng*;^l@F'%UH.%+ikBgWC?(G;\7'tFOe\HMTn>Psecu7Z"Hhah@i=Q%Mk<D2)f@Mr>C
	<khXR^76YVT0ch*T=4d4_"]H4YkaNE?0),HdYpo`gRfL4on1;(Vi4U-M)K9eQ6P_S2id9`]NFh?Sci
	)Ni105khRI8?1k*Knk.?Z[C*Ah!fltL!A9m+SU!?"YqbG5L+Zia`H14^r)o.rdhJ32[:j>+L8\[Cpi
	V=Se20"Xos'lf#6oQ\)1ne=*nREC!OYEAH7Ce<]WSD4>A@ntcNFfQ?\$=[.^uE=pOC&_hu#tD^3]I>
	5O6n(Hpr6BqeX[22AmOoYhfnE['cbXo0'r3q3[F@lB2'p[Dh00OX_3.=&itZe>_.u>K_@A5\TU#i2V
	(o1683NNobXpZ:t,Nc8L\=n2L(6l+Pq[5-2h0]&g9kdNpa[%7sGEr'*>SL-!1[T2u:Jr;nh"SZC,%.
	7t!Y.b<(D=DtBXB?V4c]\/2Yl*FasqP`kTgp^(7p?X6I;KI_!QF9:-H9Mt`o]r@4b5Q2H\6@p40%-J
	%XTJZ?*>hUC333Rs[5qVo259Y[*>hUO,!eNR"%'a&<RoW7Qod75J'OGm5Ld>MDAi,[fo$V[jnHMSlM
	J>Bo[-@rcY@4cG-N[Q=u[.3*-`]0phr^:s(M@q*hcr6`e=dVTtdM=4_s9Eo&1O+A01cuV`n,Q[CPD!
	l6U.=J%oloie#4@iI<s()ZD,7^G"g8([1!]X"ob9n!Cf=R1DO+lZF#U]Cg/F=6Aga4Uh:LE*3.1)PR
	%GWlgKZX87=&`H8&V7o)rmTnHSS#.-Q0dsJdAU\as/C2,N;rscBDo`%'@V-fmb<isg<kFU/mGMgqI,
	,(>FGsq]-PFmff9%bZEgT).Y]f1"`[rK69U:,9o(&^SEb#D86<:pN[Z)W:dqhHtXiZe"&A6G5tk(tJ
	XYGk7I51mPQS!Pe[5J6WOAhRCKlM27.]Cg)Lrj#;eh`q&8W[ci<FfVT8hS#<U^g*$lp$!bTbTci1@D
	4o@bNf-NM1`Sh&GhTpTXe3TG5qMeo1)$.,b7,D:n)@;?1XC7e(gF2f%&AXVc*g1kfE4AV\At%/)b`:
	IeJ<tFPX66'E1)B+,\;&/:7Atl0m5'n\IKdanGcXE>DA!6@Y0tG1.e_]B'gq=LV$-Z'Y`)0cbZ/2'%
	)3[B.[b9pq`jr8os2=-#J,f?_bjjI:mYe2f:VBuqV84Xrq0"+[1ecN9siPI`+_BCiSP#lPtBe((KVD
	s:0ulHr+EoUU1?^NabJF/hPM/SK%QQSr[,SEmB)qK&0Fm*+'kKY0]1%l63&j8#2KI(-OBF2f_M+E/O
	sMe(,m`HlLD%OI<1SNV@&-f02G(I%h#os8;sRN$.klpZh3mF[(Ahgh%!H,)#`=b-+tQMVSeq`l9lq0
	=1VMp/IX2(i"(`WZ`>9[bu_)t9#YDb=C]gn0Y8rVc##I.#!8&4e$M6YVh`\Kg_oa^)0LjdN&d,2e%3
	S!?\4U&P$'hfBkFV!Q\;S?a.DV"/F=&c-"Y<N2mU<O"Wr:FRRk*[mk$#6K*b-uHVLJX!iJj:p\$[um
	BQrZBscHJBAJlb??pJ`ft2Vn">O1o=u;@*A8Sc#k_%`buSPjZ6=Zo&HgFlpH98C>:CFFoE2NOQK4$S
	2*N'ZM]b7f-<>,_Mn/UcIOIcb3)I7aa)Ia4?09(^O3T=A`q%ad%=uZ]1o(>GB6gJ]nqF=-*8.,<5`b
	`8>Qg3/R,9sBrj)oVefuTlQskEhia4gUhDTRoa-fkk$05Hf\)3`NOua%o5dE^.+[.RX6.aS\h?5IGi
	?;HNAt_C]$e')HZ\Jd;-g:e;l3)8IPBq?Ohc.8)@(fjfX<rS]sD@oPcT;3aTQZ;"?$7Eeu6r6*ZW[U
	a4CGM!*"tuHht^glg`$g_=$-Ns#oE<lgK6tMf6@YgujsWH3%D)=kc#E3d9Y@Npke.b.f^4rncMESl]
	gq"b?--[*h`GanRIF.@kK`0*$qWlgtYeTJG3/bqDNk!0[uj!+6@)?c,f'ceNMq%L-<=#6;D)kj-BU%
	T>+_.NP2n!!XV=!Pfh24ocFQcj'Q'&GcB7&4.H=$ps.[J3aHh!&+\P%fceWoDu`MKK]AQK[9r(K+Rk
	Z?k>XH!";3X"+WZCI/kr,Taq,-+nPfN+G;oY(kg6@!.tjZ!+6@)*rl^9kQ??$#^l\,#b_b/"sNU>^`
	\:o!#UC9#69Afq>an766?196KeN%5mVl=0Sh#(.7qp#eE<\'kM21EMY6].Wql6d4(F$&b5hT=fX@ns
	^D@Ib=3[B+pC[J!,\ZWHJ3aHh!&+\P%fceWoDu`MKK]AQK[9r(K+RkZ?k>XH!";3X"+WZCI/kr,Taq
	,-+nPfN+G;oY(kg6@!.tjZ!+6@)*rl^9kQ??$#^l\,#b_b/"sNU>^`\:o!#UC9#69Afq>an766?196
	KeN%5mVl=0F4?_!!]]g*^,s^2fG;FlMpp0m-)il<;HT&P%n\jr;cn`n,EF&J]3pkn35e2!!!!j78?7
	R6=>B
	ASCII85End
end

// PNG: width= 381, height= 271
static Picture pSin
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%J!!!$1#R18/!3VM"RfEEg&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U'OjX%5u`*!mG3,*>ihBon_`l(RFm?L0pmVoSV6,p[TY(%#`Dbh;V8-q0pdm<6:)9LdR"=A9=6&$/
	lG,2eHWE-.+'4^09Bof[b[+83c+gE.Lh:>$Y>e12<L2]2[I@D`:i_<CsU?)@F&KHGjNY5BBEIUmmf_
	7D._WYnSc]8mrP(18P2TQ1`@)/+Ll7B<gDEt!!#t.Taq,-+nPfN+G;oY(kg6@!.tjZ!+6@)*rl^9kQ
	??$#^l\,#b_b/"sNU>^`\:o!#UC9#69Afq>an766?196KeN%5mVl=0F4?_!!XV=!Pfh24ocFQcj'Q'
	&GcB7&4.H=$ps.[J3aHh!&+\P%fceWoDu`MKK]AQK[9r(K+RkZ?k>XH!";3X"+WZCI/kr,Taq,-+nP
	fN+G;oY(kg6@!.tjZ!+6@)+"5L@e&V+=Im'a&]^ulHQN@k[cj'o"Eo<b%^U@E$^AXe\9*#AhkQ??$#
	^l\,#b_b/#,ucm!IuW-^:[INnX->WWqD@tI3\48mJQ!>*B\UDP'#=@]<nek@C_[0!tb;oKfo4hO(p4
	0-;"(1R]jo?XLrHFe(9)L=5JEqP'$ApY9rlr/!P5X^`\:o!#UC9#69Afq>an766?196KeN%5mVl=0F
	3+'J.$Q"EG+-VqB,BY<9D`H,_SA>JhR)CQeYmK$q5FH!"?`,52_$pGAPO9]^tnkO6]'WJMOD7VBGL3
	(Tb5X?/D:TMa.,kcpu2Sh>mV/&GcB7&4.H=$ps.[J3aHh!&+\P%fceWoDu`MKK`3UTrLr?T7u,sP,^
	m>>(bMe?P$$W+)NWJE8'pX5%!<7^gnGL"+WZCI/kr,Taq,-+nPfN+G;oY(kg6@!/&Y(#o'>7WC:$/h
	kI"%-F]<C'[2`)Pb_tLlLIgQ!9IbG2WYqZ0F=E`!!]-o&'m:[qNua0dZ<3jL0E`KkaOMY;j+L4*7iM
	6p?\<8G[0Q(7m4Ch^kpEnB:U#%WU6m+GC(32\EG]-[JfDZi)f#hF1f&\7Vd>,n\f`,D7PnXa0aL?Kk
	Hqp4J`kOI^*@CpV3D`:01H[NTt7I/aLV>k+*l*ITuZtQ:+(*7RnaRqh8G9V"E6AZL5%JRFIM^j,-C=
	EbnEjbPdche5Y1uRkDFS!fmK!Z#,uWLY8DfV<9$74V`fI3Ju,kp[m&a90&D\Q$fHU=7F#HLb?hi+$_
	+`qCpK\E*2R^6J=>1:=e#q6(][_Mg:8VTo]JTS<(!jGaRtj71oAM:=QT!<`c2:a,tYXO2+OqQ?M>67
	mZpFOpHIQV*,I=`nK/=k:MOD^)W&F>qDlKa^j9&PNpRF[S(4&33:@^22"1DNg$eWKH9$U/no"?$N.r
	!L:"Fn:\Tp/'GU>jRBE8n2jr9WNbWK>T=,1=W[3dh,TX"edK=RRWjTQ)HP78F0gZt5't#U#f%95=\T
	?4ieZ7\L*U)n@L02[]e`@;@mSHHt)B73JM7C2Z";RVk5\c?J[&gMe?+Y#H,d_E-:gO%u"WuEa>:TOm
	)]D=uD.@Fb/no"GNc<XiPp(qhI0<1-kWW&sa6WEh%C)91o_*$"4>,klaeu8DcK1<78-jVH7ZX<#a%N
	8!I*GG6e^`QL<V#CSXsWp@15%gmTfj%9b)CAd@m`VT/EPqC<UsiE+."err+tqu'F9-^?<^]@\t$)V*
	nS"f41_%UVer>aT1rXV!hg.^9%ECBW[Hp5Y):9-bI5sfe"cg)FP?GQ9jYt*-l/Ke?ZO`d>K=d4?-YG
	Lk9_j)IM@^eL[Xk;Q>XqQr5XPHe7mYiYH%LuS%P/3IY&Yq,4shER=QHeqL-(5lhglM$:X0r2k5HV&]
	"6k^'K0%MpR54A@?$;*r%/e5Dhbj_t,X]@hSRi#_!JFd"eOl=B7KP(FBcGCrr2!Jff[ho\irP)SS%J
	KHK9@bh438OY9$CSs4$>QGB+1_2isTqX>K9FG`TXj(o!LGRB!dHNZQF6Kl<CU',qe&H%n*Tb#JjS>A
	U2c^lrfREc+qd"b,u3G.LepncAPgZ]ku)f'3qILu?p?X$fAH9?66ppb=MFNTU$7j^PEY&X`\$.CX[X
	XT[f0&+soaic>TXKC#eY/"U"66E@EO$j9O$CRM[lIGn5o]J0<Z"kmW+0N[)YHTJt-h&XZ.@Ek:JZCj
	HU8,b*KK^k<l56_/MnlN`%C$bPS;&9\;/sn49ZAS^(-VS-,P4i1Zt=Ud4oFFdoMI?MApTBAQ'74L1D
	'D]#Wd+@.J%hXUW3dr50>KMViGE;d:44a+(^cV,]r<rO0bU:qL5YK]=e1IRrdUJ#b=".9eG(>q\D'>
	2S$McP3K>j[FWs13u$,_g03;f3m&dr5Zs85Oq`mF?![ki-M)iOeFC4*C0Bd;l.#MB6$SO3)7FAqqC%
	CGbL4PQ7S.6qD[Z$oGmcOb[]/MdoJkm^^REj.%6Qs!--$n4rl2rqYS$^[WV/l91N!;F'=WROcpu2;-
	YIJ>XhSl8<\P-^-jf26_8D+6_*mL^,cK`.'D;=^+nRL)9[4&)lMJCak[RY`K@Hj[#8?e/i#qYh1^9q
	IKDL%9&GddnK@J+3I6SPSI2'ZRO3bhJ)4^Bu*pWX:6g1:QcE[q&I'[>fs/gEdD!_!,ToXe&ehLB-19
	$;UkIiqk@Un#&#^mC4M"C.639O[-lMLRsBP$8LH!td*Fca3(MBj5+mH#J+iu"nW]Q%A$j?im\rt,#d
	/,Jcj*G>C9AKL:boPmoJggVTL@PQRrI>#tfN9J;P5%s!K%lSG_/ZtFt6LaH_qq0!/[$Zo86IEg;%ij
	gYVp&2SGC+ZSQ]/T)`p$bKkp%RYF,S_ENRQVfI:Qch%VCVRbhbhQ,7En,-jAcNAqJo%#^rL'<sPSOC
	"pkhpE2dEP.9j%b(K$GH4Q\[`[mdaf\#j466F_I;-(p(nWo]=5K$b[@k_KqQ/J1Y6^btX;aPtT9oX%
	$G(pTTB[9'M;<ID'XO&&p/8^t7LJ+9XTSG60W%e)B]ceouCT4ub+Z3?!3u$,CG[)8t9j%]9iU#GL@k
	'.pllG5k"<5Z?gr=^_G>()FLY:=r`EXF.!VLm8j:)!aA5XG3:C?dni*`\t]Rp!oH`$2ZGL"4j8b#%A
	n_keDpY@Raa]U_T_*L:L]Z<+1Ja;Wfhc\:HATih.[7;F*Fl6Eh+]_WM@i3j?nLnP5;q?NOY_Q=`H%e
	GO0)h*GEP!oecn>1biDJqb<_hKRf7I8bht>&8H@3sU]si?tgIiupb[6mCrdFnjSegCGnWJL$C^,%2j
	j]tk3kAsb7f)u:?:r>DE=5!?&$c$>*j*Y`Mt\qs%=Z;<@X/\.qJ<`f)hZYuGO-K==&Bc2EGi?aHh.F
	GW?E\"Y^6+E(OO%/Z'_,NX;e'0$)X%$Nd#^5[:c)Y7t:B!U.:5Wi8dJ[1c2.[iBhthWiL5]>FUqe[[
	-=N1G<S$@GB#VJZj4M[bC$3e5]eFhUj\K@nNHYd$N$?.Ad?"s!OH&5OZ?on,2Tt;ncn:3$J1;$%9=%
	TDn#QVf]nKGA?N+I\^pW9hEru)>FV<6VqmYG'Y@q`nFUu*?F7tlR^<G)S&SaUitG"(+'ZWbhR&"^43
	o+gi1/q^lQ^/VrjgK'q%!6lg&IQpRIhbnOE0k3)Hn<Zpu>*Wh+J6DB0fXnq@mr`Pue0c2,<@o92bZg
	>AP%gnZ</kk&RPH/!3$rU<0G;H5-@ea(h&e*F4'#=jg<?f$0/5<*[O&+A2HCVT_ro[3X-rVO"a`Z$d
	5Jk]9YVbSTY[g3g/G"ZW%TeDi2Ui_"]gD];?OX,Xt@GUnSe,#uE>I@kXMQEFc>-pi04Sl#Elfc]cao
	=<;]tJ`/qt=/U5+O_g"WP(M;j,Lob^35Ogp^(/q"`7bTE!p^J#J:[g1J"BOt3]^*S\$!5C_e:-P[^B
	/*cZhe:D<pD;2"J.@63O^1>fYZDXHBrUHdLqcR3IpYC,Nm]UN>8JeI3,t[A`IU)b24,\E43d"gSB?&
	:N?FX-\n)WJEZYHPA$Y5fRn#q53rqPc*mZCM7hs71O=h:f36URbI99L2G\=hd#VGd^HF*@321-3SH5
	QOK'Un8:l=5snIf#`OL,u''f?[i"G"l6nq\QK;@XO)P6/(-<SI&1.G,s$0V0'>3]TZdG;KX-9F'\qY
	`dR<PPb.R>k;uM:O'mX%si!8cm'TeC*31*_9\@P$NK"h:30CNGo4F-8D]"5]$F79.iPOuoeR[^5R\]
	"9Q##:_Xn\-4=js`'0mTCWq^^%/&:Bpj$)&^?kf%H<GoM_s5.iTGX*=AdR^0\#:pT)F!:WdoO8YrG5
	qYu9*^\t;6IJs![n*?u,HpP5+n\gAN6f8'WjU2![**ee&fucB*RD[]AY,YB(!8`I$]6J>lj62UMe,E
	UX"TRrsHsgR29`?V7=c`2R;O`XbCMO%B2QUW?,)+<&8+Ei=%JTR2\?A[c%1Q6bmel1iFj4"%1?IgDm
	b=WA?!V)k*9VPM![#K8F`<bkR%SU3Q9n#,?^_9">=M*bnM[JK\lqgd(8^3WSG;"E/\_/R.6i%Uo&[I
	Uqqn%:oj<.5>NsM,hpR\Z0c7(o'P9]`VAI,.FLud5ID%[Yg\9gj;Cd*>-W?,`L,CVgQN"Cp]tL)nId
	lX'l&Yl(1S:*+rUrcM.iTER0jXl/6tX&UlA4?djlB=?B]r)f0>Q">?a$C=T9ROMY"aEDJ%toX:42Os
	?FLm;l-[Q-h<E6=E.i[E?!Z"n53!B._K=LT<lT)]f5)04I49M<O'c7R03u1j/XKcn8P6q]HN'Un'H7
	mVnM\:5I<tam]@%Y2btFC8Q$4uBD,Wt"Ibj_ugpA4?e%<<,P5K`I=UqTf^6JNFfMB>%=dEt)mW[-P^
	V>-)[bPi>Zq(#r4[&YNRr?lO2rC.8I8uR#fX=N*jPSYDV:3uPcOi>p$UO,!/;8sujQ>IWgg/UcW5jX
	IHo"r6BksdKqOW'+g9]*tP!40[4oOHqCUI^GC+[$`17`XJKfZqt^CIsIL5rtG[c4'Wl.]Ncn%H;Ook
	I(*AHLuQll>Y%`fu*%.4Ij9B[jFYoONmeQ7<u(gV<MPm=!psh=L!>](kEW$blQY5PpjlDVV2<iSh-B
	D!7C1FT'h*VS@QC+na0LP;PI^^^&$"m>UQBgU>ogmpp1)]^0*B<fc.X11.S@]cMRsAZ`K1\g`t99W8
	AQ[/?A.oZs_RU;)3Q@@\b7JVruE`fuXejdf*:P=]oipLfIsp/@UNJe]eXhp.cb-BgK9n=Yg/h5gO95
	??V9kA0$F([:kZb>g\cD6uG=8U'Ah1B-Yf:^OZf`l+(N4;7Q?RIg2PSNVE_He5PS2(r78k+t^lIc&h
	Pj/9X2&-U9oIU(=JTM<>A>*lMW(1a!bml3<hHWE$_qL0c@e?[S-?Va<AhuT5nE?20]dK=RR)H6(oAE
	Z[!qJ7s#o)#iH[QP8NZH5\5&hTN%(NeB>[LE_H-'=:bF@k/H),ggeL;#Keo;+M_dP;mbor!i<Sb7?Y
	C5@CAXW&;2hS-_*P=>G70u`X(kY#PH?W,u,C#Z)kP(j2.#_u\jg!#sVpT*:n*U)m%_\Va7b`]9mO,P
	NRk<hIF6S,):)<IGh*R8Frb`6XEQS^Nm3P),Y"*iRB)&'B?O!d]J.b'Jt=IX)@FL:>WCK>3JE&$aNV
	[a`qE*o6_?*Ya=>l<9Vafja"!L)XAI=>R76l3i&^@(QsD;1\VTAkPP-J'/>&db=:^jr(uSl6m0qtJk
	>Tq=*r'D(<f9R"Kc,sSqU7l[TFU!U`MKKTl[V_(P'+qZsQM+m_n?T1$G(*=Rq#:B)>l(8f,ioklpUj
	:'m;(i!MOACAm\:;@:0LN!ep<o?FJD"O.le%U(B!RW!*%E$+],l5cn*f+=p;`"nQ:<-jW62eLrMf76
	:\E=HJ(FK7Gkb]qr;5A%=-SId2'ikKJ!RWWrt"#_N`KD3D-7q_5lRX-\"AgEd*2C$-LYHnaG;b90t=
	Jj[V])h%)]&3LNIXaSr,\f\^Ps)2hQ`D1hY*:Dh$T*,?jZh>LS%ND">?WU/mVqOhSOb56?@%Uu'X?)
	BMYg!";KR2OQ)Mo#MWFQ:+'A@q2??Akj((dSG#-\Abm-r?`N8k_0hqR_/jl9]CR$Z]]`b=qHb\mjdg
	;9P67h70"eb<G!:#Yf3qHqZ;>KklUotk*^Mk!.`37oDu`MKYAeEMB6-27dj?MZNpQd7-Nr1<tS^n!.
	p6X#69Afq>an766?196KeN%5mVl=0F4?_!!XV=!Pfh24ocFQcj'Q'&GcB7&4.H=$ps.[J3aHh!&+\P
	%fceWoDu`MKK]AQK[9r(K+RkZ?k>XH!";3X"+WZCI/kr,Taq,-+nPfN+G;oY(kg6@!.tjZ!+6@)*rl
	^9kQ??$#^l\,#b_b/"sNU>^`\:o!#WY;Pa%tW2!XX0giMc-+V"2=l.dRX<7B4Pp2U/+/8X'A[G-W/J
	od80EI.ul:_Aq9!5K_14ocFQcj'Q'&GcB7&4.H=$ps.[J3aHh!&+\P%fceWoDu`MKK]AQK[9r(K+Rk
	Z?k>XH!";3X"+WZCI/kr,Taq,-+nPfN+G;oY(kg6@!.tjZ!+6@)*rl^9kQ??$#^l\,#b_b/"sNU>^`
	\:o!#UC9#69BYLCYJ%/mc3Cm<&C/b3\WV_]7nCJ4Zc;M=_#Q"Q04]Ap]@U1timHz8OZBBY!QNJ
	ASCII85End
end

// PNG: width= 381, height= 271
static Picture pPoly
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!%J!!!$1#R18/!3VM"RfEEg&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U(2?E/5u`*!mG382eFfBQn^f^N/GVR\M#m5SKHLQLp.iaR"KV;"S\&ZOm5V4"=R"$9=q;Wa'X^lcl
	I_,A'rZ0)/!i=0HZ8)HV(LQ[9XP/.(MgD^ltIbt@,_\&/Aak7$1.*YOko]"c2Plbq#5Y)AshqfS)(P
	0nCl4&^[LXSCIj=S;D8q%!5Q35To^bj/cl"qIC#e?%ol]sP[TgLI7BIoeH#Y1]i@q'IgH6'8_<Y.l!
	pu#g"qXP4oj5OCET:+Um[@$VF71jI4mo/!,N?+%"3'D-qVj0rV^;W5=-FlCpZ(VerccII=5[V5=-Fl
	CigqOi-%P-YJum5Q_-P,"+X*tL7o(Hf$8LJ!ad/D!PgTo[rs#`*rp+eF_aJkoDu`CG-lE<66?2D@7P
	*',4koO(-OR_FsKBr!,V16r+E.Nmn;jHJAob2r&P3eq%BA3!1'slT.^fQ!+7fK7PthbI/pL5?)*hpK
	K]B<W6N?5N^W(5J7X=eTnfYK,t[ia_j7cT,XNRQ/7UkoH_V%NI#62T!6a#?!&oJU#65.aI/l3Wcj'O
	YfK#F>7d'r)"e<rnOU-@8-p+?6FsKBr!6WS9XW<8F#Cs+$8o$p@oDtVdSCH8T#^l\$.jq`J,XNRQb0
	!;X*Jr,JJ?j/uCI]T@!MF8qhGH'L66?3M^^3);VF0PL5T)Oi8'Q,]I/kYtV]EQI+S5]-`12&P2hB<\
	J.cqWCq^d\%fdp<eCKXJkQ=(A3OuOB&c)K(;GM,s8;'/,Pa%A93te4t!%$[terE/^"$jsfESH1HKK]
	C#J5`p_84D_E5RFeXFPDLKKK]AMaXsQ@M9lKXU,d@;[<)\&!%=#Za#)$HI/k[I)oa_Z#^l\$JfD]db
	m8^t^=%.u9=Oram99DRg7hrt9a>VN#^l]eEieGkSnNU?cb0*JdBDZ/"1SYj4oc;<9a>VN#^l\$JD1R
	l-4p"R:]RD3Tq'41]*eT=2gB0%A*Q/1V\'Xg[.;A)g)(A!>cjQps7!B**]kcA\pj)?RddQgQIMB1Ta
	q-KGjrHhe="Aq8Q+q_Y?#;T5bhjZ,a.ip2SZb)]/t1/P306t[ls@tmf:-Wh,RAu8X^NRBQ8O:c.*45
	Taq,,g(=\F?,EfXq>a=l2iVO?&c)K(J6]d8V]ta6@$mCW;:kL3'*s!daFh$cZckjZq5FXJ!6@OWFPB
	M;A#3X0*rp<e)TJGshtd/IAAn5ualV?Bn!9lM!YP8/OFqi%"\DnkULc>`;EWYp!0G*\4BM2n^e,[KZ
	KO46VO?r+=!#Ps]sI.[FZRltTH'dCK[9sS%"a5-CIXAN,T6GlJnOVD`Hd7<[[4H`.eIHD!'g`m!s-)
	A=XcqB[(2K#+nPdX"7u6.?Kp_gq>cVsQE$st[nh/\66?3Upf"i-j5qp0dNS5`+GKXf\'&')p2)jD4o
	hBlF6W@9o0MRBJ4\*AoMB\<,jCn>fTggGB1(kbJ;JQ:J"p_C?Wg5dk\%WRcQ?"us/Alh<r`41d@Fj6
	s6c>m2GSVaVPd$a>H+jT#652sqfZQs12)sA-%nG^B^j]agI!.1p$rb%I14keXtFkah5_'I+1JirTOc
	8Zh_od;n0LCC"aG4X>-5L9Ep_Vd_sUEQP47bi\*4J#!.8]Zr8=^/cG!#.cj/KED1OrmQ%)jpCi_Jqa
	2fS-?YQNYdeYW#=+*fVJqfuL2)UO$-?d&9b*NB^!'\k.gRoMJh&o;#3'O&c8NT6^]1T@CTasd9IcV=
	3hml[KFT*SQBZf,@2HL$rgJV%:*790/oP)X3BVm!G@>U"M]Cb"<rN7F1lIDpAIFuhmnCFWf@\lHU""
	9)1'4#qFfgkB]6VV'[ZteR"6'%F(1_U+4SQp(^&c)LMi`OM]4jj7^h.:8#e#X]9RVkOBan:r4Tb!eI
	&lUQ/X08KEF?e61VGle42*rBM=dZ*tS0H^DVA&8I#>WPGi#Cglo)1><R>T>ri!\63b4cQ9++WOBpW>
	`#kZ`B!8%31!ZYOE\arZ4"!7,F:m?R_@Oi.$Vs4sJ`?@BiUWpE%8"7W\I$_;e&Veqt-66C`U/Mc^sj
	/4\O1ElAkGh/OrNfWncabJ.Ii(9n(q5j,l&GcAhBorq8:!O!;&%FmFd11#BEO4@0[bG)F/'ukhN6hf
	7T`&91<c2-@D6Ic^]+i;\Xcjd!&&;+WlXWNL"7Q`Q3k5k!!'Gh@:4<Is!1lG[-U6sq%nfl\punnb7J
	uI1m'isBPE,;UP9etii"jjBe_",(@2=hD9j8u@KK^r,`GN*KMVE$T]*tK[oN.+=d.'JdV!J$N3`h(8
	U=#b/6@;XMn_(7UF`O.g"2M=u!eEXgrsROA3>))f>Uf?]/V0N966C_.ET"8ZKK]CfiP9<h#^l]UP1m
	t>_!UV&qA?ZG'.9gE_@'AucsV&Hn<p^MJ3JFE(tlj3/R5\U$WjI9]+"I.C>dR]0+9@Z!05ZJRad`:N
	G:s36m'0/KK]B+$Q=c&M,3E\N(!<TWD`qK&SUVmfSQa`I<b\"h.:9d`/.XopKOYte6,qR88"i0H.4o
	>'%('W3E+'5#K]t!gr2CTZ^hh[d0P.*HZnd[[;Xc0G8^8*\oi=7feR]Ife[86<L#Tq#/2e"54XL^pu
	)a)^><j$YEc[iP:s%BVq.\;bP2RO6I7E@N+Os\pdHG"*@rok@u$^cW'>b.hFWq'qqBc*cYn\12>b&X
	e2M/Dp=HFF8A8t"<KcXBdD>SKr!1Othu1.H/Y,;f1R_H-KYE(A4XH;*e!O5*Akg[O(AA?!m&!<ai:1
	#i*Vbi]qdfVCC#1rErKH[VcUeTDLJONhn4SSapUP*+?`oL8p,[DO_a?U%'")j_<+sOT;9?l1<*/Z7:
	o'Jrg*PmsT,EK!HRM9TVo/jh*srp@[KZfe(^OX\H94JNomKb'#]b>!eAYnnC0t?)m3"(I3mjetKC+h
	tQ?-4dHh-MHc\]VM3YFIt8ZFHo<*rRBBoT(tHts;i5%?dm-"4;LT9q+6E_=>V=$@]-pJt@27;oAEjj
	.iGJ*?f_DYj*s,Y=UjmuuIRa6k+skr@CjhD;j.U_shXW&Bb9\4nu[Sp3]^QOfeY".<3`.scP"UOYU'
	9GQ5@-'RR\i'U'Tik`AQc*m\fHiVB+R?tSba*7Q^TC)TF^@2qG83V2TH</q[na5E9FPd5&@_N*TJR<
	kZ^;m'SfdBO'pX6^\3QQ.-mF@Lf5Wsjap03%h4ocMe)RWuL!q"^V99Q[Ka^t>!)o'gka`A0]$YeA=g
	U+G*Dt<^*cb.tt3`?.<CO\".LsYmp/QGeS;dE[lQ+bq2NQ(O6]`W*Zo="_7I/lBQh.-<*5C>quH;Ed
	AoW4X3nOYn>ifca$pV<L.o\!#gf(/Z806>4sC"=F!4XTiT(5Wc*,0^#Z!AJN[6p5bkF1UD24-D+CZZ
	2b\BuOX6[,UWkQI_>4+L*usS*HKMrlaVE5B(HU6Jk..><,F*W9t"J4V;(u17Sl*jaDQ[T)tJ83)r2V
	q58Q!a;]HcrAXAo#OeUbY!Ej]?_lh=B$9KpYO3]`<qm-3%D$!)%@4`+P7[R3Ont,q'3]G"o`9#MFgY
	kZJ1_[gJM%dhJSjkJq@/YmM1#YXQV7:tjS)\MTi+)Tr`!$gE=0bphZ0_j1^pbq!d^fV3r'WkH[?A$/
	sb5:i?)!4,X)2`9`^Zs!K?20Y`.")Nq!S.IY>F.dEX2UFAkHh^&`JT"]Qu9-HGN\LNR*6+5]=(JC&K
	`At/1Mq@2A=@F,'28Jh*urH')IhaLH?pU##.@K$Im:CF*8hZ0O5S#3$a9/XIqIYn%W8gdosF.h*p#^
	r&4J+$),[Xb152M>j_BiSqACMA\[6DgkJ#^b_ZoNd"H]mJg$#jh6oiDMni&dWjY+S6\7rk1C)g'T%U
	L2`:q[5E&87;r1p1@r]?*aV1s4'5]0^tp=PlT!U\gkWVncAhl%Nhi"2N`;XHQUZp1cnNruBoVAfpRX
	H6.jiN'H*cOQhZuh[mr'^,FWqmnI?Jc6*'*(?os'l:3I=dCSN3HK8S9?WO.5:1p(K2+oGssd0F$nt:
	>f?OrF!6<DHgh!):E*>[:/nX6QS.8,ES_7SM0;Y/?Uo[l"BNN#tnKh')F4HkW;W+"XS='pm+KFak3T
	=0QaaKSu0N^6W3'IKk\u5Us#&7qYe!-9]qlt.\CZLdf3mg2K>VO*tc7.aO+aCi`$N<,P3!'h%bV,iE
	O?";_m<Nnn,IK#>:4,bo-;OO$4D,,ji_DdYWUtWSDSl)207+*Q6a]R1P?uck_8p$KI'e$mp,%QkjaT
	XKN64%M=Y,'O"s<#DHZQNa+&S56Y(AT4pqk#H9bEG%gK*S'*]m"TKV:*P`Zi&"c&17A2G(@]F+r/)0
	DC"YN=/gFW"YTq#g)TUZ:9)f];"!*1?:D8Ou7!:2u7gE=Sj[K(,1khBKBHo+b7BA3Kl'VTHMe4CZM1
	BCU7d'jRM3WSM9kZ`]B[fDqKd'iu[D?2^#Tl0rAg]DF%6GLau!W`ed!cSQ7^Pl(F3aOgc4*KUO2-kI
	#C)\)X/d9$EZ*eTi[06WRgKnX\/6oST$WjI9]*nZC@&5Mja8PaJh%a")s/oWRHd-HGcpQ@6P,*HA@G
	3aB*.cJ'FSsK/FmdqXhNK<[np78O7.ElR#Cu[`qIRGG;#iQjTjM9.dlL_F"b;dJqBb4QBcR31_=UJ/
	rUYRBReQU;)S9p[VB%dte]3]LHH[4SCr-=_baYLp?aN@&0>?*,1'..eTjIl!NZ?H1.otldF3ePiij&
	:)d*\Tq*BgEHp?g>42f@-8YC9L'Id_W`MGNpGJ<ag:'^<<_?ISb)$[(C<k6='jW2ikWe>Wf)eI?j&G
	?_QAqc@("mK3]q//&"/Z-k;Jkn>H:K.h[N4l+qWUf_3)`\(DgRr5c*j/5[K4tl^)g\UT_NG<t@EV5+
	)"!84Y?);oBmaW`7^,uBlDQNJgYl1'K9EosQW_.2Ih5\4s^OB#;92b_a8c$;V&*i<EgQNd&rnmmd5O
	jEg2$<>,6GGeSm+\G)J,J?frSKg8W&A"*<S$&AShilDfruWFJ+jJ&TZENWAZHCC;A&a/g9Z3So(MV,
	Zh:e#QK30$eu(_+3Lr6QVBkEeHgb\+07Hd,)?Crq4oGHLrV=d'\%@t[f8Y'YfF>aFc.f_noSF6EUbV
	&(>F,*c+<<e`!55(fNZC5AE5sYSh3D%Olh<n.2JR>D@i6`uJF$t<'HhMiB_$?H\8b\U?Z0F3!0BEGq
	?>Li$monR3Tlokc\nAXX.J@lZbBJ5Y"jQ%g60tj!8.q[_\=p9D3T-br-j'AF1$*rs5bp,Y=k0lID'o
	5qjP7srU6)U5QJlWp<G?D)Eh7e/M5*A_7/=IptQ]JC]\Pm<r0_<V5d.k=&u>q\QQqnOc#\iU[SL1."
	(T]WlL&9o)*LVVWlNIHt17Xn*Jf,"#%;p7EGN`#baHkCZ:hZrE2RCcC$L<\UVoP2rE-Gfs?GrJ)%DF
	]&l*3)=mPun%Lk$qI?"`b#gC2@bS>+>2$Peo3:A3>mahsd*L1,W[`-l%!9DT$AWd#r:?,Gs$Bpog<e
	1,c/8FGH2G6MI%n!%_NS/->1M?TC3LQb!.+KeqG[<BD,W9k`Voc3oX39ts4d!lne3$lo?FpSVl..2n
	%\jJo)?1Q4obs&qKW>bL,Ou/,tV8]^Db\)CTgaeXBC^^BI'=Mm^uJH4ZuqT-[bK\rpBRJP6Z=OVbX)
	%"2IffINI2EJ`Q4;n^'3'6_AkdJ`Pi3]67oe_M&k/r&rllqPVYh?AF"(]7JkCW6eU(Cli'BAZQjO#,
	A)g6dROZ;#C=]4lPn':"?+II'HkircPVeg*B6NZ@BX?/m+e/\T9Xme">2O;l8clf3Zq"QX3SAX04#$
	hk0i&95hC5;s)B5o`#'p#lPaeX8I&U3rdX^[@04)[[pg=>5dEaqSQb/J,X`\J,]8NY?*`)Ub9FT<aC
	.:S`M==!&C:^P=9\]<PI-T9:"f8SNA_-ZHIu-*\j@_Z;T.(]i94BhQ=Qgf!dKQoO.e$<ahhs6-q<-:
	&HJB1F&$hX*h8De#2NoVk7!@(=TO@#M$5+Y>2e2^.+/&V[5.kB\]t/"?cb>&c*A]%0Z<LHq\U..$W<
	e;P\jG]T#jfWc@=REg?q1"eiVn_8c8MHpqtW)VII_J4C1IBpd5\SIp_2>R^[t%\]LalIiWHi"^ooMK
	ELg!e=>`qC0j`I1$$]@7Z8I;UBLl5ef=.k`EY/:T@mH'Rb#mA4ZlEq02Q+g0>KqPYNV@@UrE#)Od-A
	8cKWGlU^9d^'+MGUV1/H*n/>W/ft)KK[>cq$Nq<q"Q4Qk[WcoMJ%n$fmBZ:7e,&EZpM'JU"j-X-_pI
	\;)G($8/gSFnSQ[ZH'["kN5CVgX3qr!Gnh&>U4aD(pIIkD&N_h-LgSsiI5bTa"hFUD_fWCjX=k.$%8
	/bUlTE"GB9,]jrj2?6ETMUqMmj+c@S7HE$rUQL]0)u^(pBP`"`%P35`!uc3n9*ra[p0bGhuiHL?\a*
	i!:K3cn(-b!o<mHVP<&\?:;.0co**J'FEH`[4aWQZ!T87;%=RgKgm2X'`_$6H3kc&Oo)[X/o^`+YKJ
	,]b"1S@/b*SgJT(rBab'0Ot5(IuU36Z2&!+58%kdP+`!uCsMc<$^c.Na2uq'u$CmBZlpIc.9RB:g1E
	Icm3IB1rs=HkcE]):J]gs+ES<*<>S#kgS5dJ-!@iIEoV3J,u5PI:i'Oi$4g(IEoV3J<+q9oNC8X^gN
	`DIEoV3JAF>gqM]+i^gN`CIE")E?ms?U5%idT^egU3I9J]40U*qPT@OJPV!#kHVmQU,l$5&VC$bmcH
	CbLm=uu_GRHHo/ed_[jk./j:[0$DsGq/H#m/TCpSdKo>bm/dc4;7SXW!NI7Gp`1:;%iqM)e!pkV,GM
	<gs=f#T<;G0;@UmqAZ-";SAQ#6?gIeu_B+57GbVmhCd%j[`tP/mCd%j[a7Z.PCd%j[ch3u-CBjk1kP
	EQ'[0$F)F*6]qg&Z`_EHUKog&Z`_EHUKog&Z`_EGapgg&Z`_F)C-ig&Z`_F)C-ig&Z`_F(ORag&Z`@
	\2*\jm/TC[>T*CFFo\0hXp]Y]3ri):f7cDj*<7LXlU%5p%KI3g<M<3(#69YAWmIZO!s$;[<Ts2(g&Z
	_u\17,8N;oue[0cnQ0@tlk\Y!6L.N\WtigS5lT+:q@F%tjSWX/[EF%,;bAlKED9#;=:?PA@^Y23L0N
	'q@H!'h,)8MNdD#(nh#P1s]g:^nq'!%:Ad'U!J2nDW$\acl+p"TVA2LCYJM7sbI@:`:RSJb00IGi/N
	'&<G%(0tl`Jz8OZBBY!QNJ
	ASCII85End
end

// PNG: width= 90, height= 30
static Picture pInfo
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"&!!!!?#R18/!3BT8GQ7^D&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U#t@KS5u_NKc'hjQ<7_k>^N6#'iu's#@iL6?EN#,SR%ORqWY?g_DQ6ZakX-9m6UF`Y7B5's^*$E%B
	u3<(a:i;5<Ct\*^a)hT'K%0QC]d[0jPV;N@+9cG@fjB`p38^oR<*NngmMP4QXaLkr6j/Tp8k\$ZiA^
	F[J/@;&;!fa/0Y"8EKlO!*92tV8I!509L_n[prdb[0DD]b^77\4Qh+<X22WSL=^Tpl!>%R?bOV1l`F
	.H/kj.Q0YHO!p0Z_o!(t!"2!0>1<o&\&oX/k93#9I:/\ol*"]HFk2"&^kI,Op^Po$LJ:qE[=Zdn*%1
	/%c)$r:,4%r)#UgVCL9-4fb:)2uc00,SCF2g"FKhP:)ciSp&'<om1=hD5F)*"ddDT8%a$Z"blrKB1V
	t"bqBnEcNrlWWRU];Q?b;\6c%+`!0V&SGg^%NRV$e":,J(6+Q,'.qs8WXZ?]HQd?\@;-q_mAJ,]9,i
	ondb3ItHg(Zjc?GW[$h>t<@#!7L*gWDnag1eK/1,*>Cr1P3*D[BX`3`d.+2D9NUG(..rXX^7$1"@82
	!1KE^Ub4(b^NWMsF;Ht6&&;b$b#dun1L:o\#UFM.3gNK`n[l7Cp+c[X/cDaa?O<b.!b=-Pr2.^?1Nd
	)e2#U:Q=,SCE:&8^%*L$dX(UQj\B/Bea\(..rm00Qspp'-Bu;ci@[g2Ab(7h`\ZA=S45.(4!_jMmH)
	qUNK^MN[#3[D>08n\uMdd,!N;U*ru@<Dd(/5&X;O&;3@n7RotRD4?;%HAGk=G+fW.>tiHTqLp0W7=4
	1t\u)fWAJng`QIdQ"8TJr%$paau+6@''?G#H(RO^<AUs^^G[]\cSB@c5aI;=JigY9^3e#1T9SXPucg
	hq>mG`bOMiSe2FC2.Jjp@_T>`piIOWDnc;k%;&=gQn1M0p,[l:OIIe[!*"QkrNrEAXG*0N(r07]$fZ
	h/$5=fV3Tb,=$\psV/^EJ)4IFB]PEW'\qbg(SsMlA:JXaHWi@OR/f1s5k:MsaPoMc&J--#d&-rCGg1
	@0&:")(CjpXC94`bia)`#WJ(G?agO/a)!%!Za'1b>,JjlN'!=]&V5U;CI@Et9%o2-h+N"!1EAB5`,M
	Th&'lHW;8P&FJlPBUVCZ77C(9D;1qiXUW&&O5KD=a,V0/D%4B*&."qC)Xk?1%Zs:M/7mre"!%<ET2<
	bOD<cB%HGLYk/]p$:.Z,bn[7sj`?B9ZXXV6Rq]_Pti2gd\J3f(i:R&5_pm4KmDXm$aS/B^J!/^)#uG
	%6sfYult1cH[_1nRTfUip]H>d<$0>4r9NH8sWQ9)djkQAg3E#:]C\]o'uTN1rJBf7mE:cKPfJ<US@o
	sfC=1##U)g+pYUIm80gMI'&gcc'97IQ?8%%Ad+-[#D;.]AGGtPU1e&m.iUpnuW^=]Xm<&%d+jRgmR6
	q<!"K4)c%%V>s6.boU<k:W9@PN6o+0)@'G&kQ@q=8),*BN8CpR@_H@2O[8@=!9Ifs"n;A,h79HFe;'
	<AQ<<*SW3\4hYn'7c+!LCK<HgOtdE6\7T^B_C4`os.\g?L1-<OUon"8QFD=fRPcBo,tYs-%!5e<il-
	gK-hM%Q-;cW@=dI0o(g+V`I[7Hll^gmF1C8U`9;n:SDf?'4kXX)YA6CN6o]r]qT!s1+^3pK)B6pt_B
	a+O@`IRg8=:@XkJL"[Wg"k-TK%RqsK*5:)MTX360]U/4Wi@77;Jt3uP7<CJ.#Pn:q"VM]0-o&(8.o9
	`MEo2(5'MS@J+Rq@q<5kKI!A\?`c`\j5Xs.C`^\u^];Gr<!]0NL(T`^;0>7#+XNrGfbj/DFR`<:aKO
	an5L'f'H$C6<N=ieH_Ns:8r/-F>E>*(o2.ET1%BpgNq9:F_:'kIT8!)),C3GlcmYHU;j&0aK<:WMel
	3Ze-Om%!i`\)#_:DlKDdZeWg@P_C[O5M'iUB8>_-2HE;O1>jM;$8=V+SNHPXHb;/UA2:]pC+19D\Bd
	qtPsUXEa5qKga#B2SZ=.SRp%A!RdqL(!Ea7bt3ql@F;Uj=M08??L+[=OW75>HDQ5.GO:69br-505tC
	KaJC@jCMg**JRJQascSIH0iWNK&pUTkRi35A[F<CY2`i#$#_f\:6RcLI9_:V"&,4[]HN!OfQlP*Qtb
	VGkuA?F_!6F<)ocgU#D#V(':e98CFiHpC[p2PjB,D#;1";i6n,<g%nVGOf<>lBjHXs8BA(fD;DdgE&
	_+N0,P*1$jPnaB'W+c:JFR2daE`AbT2\$"\Atc30k=3]2,.R>E*Nf"c^j@=F?-EhKuZgDlI9;bg[c+
	#@$`/2$kB@MhsTDp>G]B0oZ#`%fgeAhHcB?i5($LInM,P9MS?gJ,auQDYK=UG;=]pX[t0`Ddn+h)@5
	*f*'#BK+[7+e+25ad[WOTm!ShS%o^pU.1GgqQgF=j%Y7Q;ZTcp"RlDZ'E)=kG_qYSr#Wb]AY@*-(nJ
	s#A#q"YFMfsgRh]Kt<,gI6=12lg#`?;TLp_*KtthTY]\gR%W:!I8"sroVaPFBo;RFjF5*7K$9'/M"a
	&=8b8<:r],W]a;6"MF%U=g2!m3l-^kmCMU]X>\[CWf<8QErql0Iq<+A?>3\a$'Y&&M_Vt+amGf@imo
	bQW3d]\44-GFK,M+U?MapjQn$rZ2MO]A366&(1N))Y5K\G-`9XF4l;%/:LK#,8h*dQfYG3mlOSIcZr
	>bLn*pC6ZP>8Kg\bG_@CKr2I%"\bg,9T7gnab8=Dm!=-WrDiH(kdbct`7o4FNN0!X<E0c>,]?+,R:L
	D]PZ0,$>?`&92Jr:c#b4?2.q.C==rdOGT-GEe&/PNlY926R6do>OS3)p0O\R3Y8&I`m-S_GCD(TPUp
	#Oh0$f?=CMoA(S7gE=*>mMVCq0YVL.YYcK,Y=`@\X=h:G[ec2^3h=YF;C/g`2VT*c?qXpKj]]U?cVq
	fC?DNujYDHgQ#<&Y/Z3l"'p#PjIED$6^p\*"iPGcpqYD$G(gq`=S8``85)IVK,7k,W='%mZ6N^%W9s
	ZH4Ib4'RZ77*WgpE7az8OZBBY!QNJ
	ASCII85End
end