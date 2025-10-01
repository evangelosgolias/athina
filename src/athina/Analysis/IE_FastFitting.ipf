#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma DefaultTab={3,20,4}
#pragma IgorVersion=8
#pragma version=1.01
#pragma ModuleName=FastFit

#include <WaveSelectorWidget>
#include "Baselines", optional // this is an add-on for baselines

// Project Updater header
static constant kProjectID=22409 // the project node on IgorExchange
static strconstant ksShortTitle="FastFitting" // the project short title on IgorExchange

static strconstant ksManTypes    = "constant;line;poly;gauss;lor;sin;sigmoid;"
#if IgorVersion() >= 9 // allow fit functions added in later versions
static strconstant ksMaskedTypes = "constant;line;poly;gauss;lor;voigt;sin;sigmoid;exp;dblexp;dblexp_peak;hillequation;power;log;lognormal;spline;Chebyshev;Chebyshev2;Planck;tangent;"
static strconstant ksAutoTypes   = "constant;line;poly;gauss;lor;voigt;sin;sigmoid;exp;dblexp;dblexp_peak;hillequation;power;log;lognormal;spline;Chebyshev;Chebyshev2;Planck;arc hull;hull spline;"
#else // use built-in fit functions available in Igor 7 and 8
static strconstant ksMaskedTypes = "constant;line;poly;gauss;lor;sin;sigmoid;exp;dblexp;hillequation;power;lognormal;spline;Chebyshev;Chebyshev2;Planck;tangent;"
static strconstant ksAutoTypes   = "constant;line;poly;gauss;lor;sin;sigmoid;exp;dblexp;hillequation;power;lognormal;spline;Chebyshev;Chebyshev2;Planck;arc hull;hull spline;"
#endif
static strconstant ksPackageName   = "FastFit"
static strconstant ksPrefsFileName = "acwFastFit.bin"
static constant    kPrefsVersion   = 004

static strconstant ksPanel = "ffPanel"
static strconstant ksFilterListbox = "lbSelector"

// Multithreaded baseline fitting for processing large numbers of waves, 
// or for baseline-correction of multidimensional hyperspectral datasets.
// This code is designed for large datasets. Doesn't have quite all of 
// the options in the baseline project.

// The fast fitting panel interfaces with the user interface of the 
// baselines project, see https: www.wavemetrics.com/project/Baselines 
// Supported settings for fitting can be read from the baselines panel, 
// and are retained after quitting. FastFitting should also work as a 
// stand-alone project.

// It is advisable to do some test fitting before selecting a very large 
// dataset. If fitting takes a long time, there is no easy way to abort 
// multithreaded processing, so you will have to wait for it to finish.

// If you are working with a multi-dimensional dataset, each time the 
// set-up fitting button is pressed, a new one-dimensional wave, 
// representing one of the spectra from the multi-dimensional wave, is 
// created and displayed in the baselines GUI. If you need to see more 
// spectra on the plot you will have to append these yourself.

// Requires Igor Pro 9 for full functionality. In Igor Pro 8, fit 
// functions that use FuncFit rather than CurveFit fail in multithreaded 
// execution. These include Chebyshev series and tangents. To 
// disable/enable multithreading (for testing) try
// SetIgorOption poundDefine=THREADING_DISABLED;SetIgorOption DisableThreadsafe=1
// SetIgorOption poundUnDefine=THREADING_DISABLED;SetIgorOption DisableThreadsafe=0

// The GUI can also be used for curve fitting: 'baseline' is synonymous 
// with 'fit', and 'subtracted' with 'residual'. Comment the 
// BaselineTerminology definition to switch to curve-fitting labels for 
// controls. Some of the functions and the auto-fitting algorithms are 
// specific to baseline fitting.

// Note that in order to use multithreading, each fitting thread works in
// its own free datafolder. If an error occurs during fitting that cannot
// be caught, the current datafolder may be annoyingly set to a free 
// data folder. If this happens, closing the fast fitting control panel 
// will reset the data folder to root:. The most likely reason for 
// encountering such an error is when 'debug on error' is set in the 
// procedure menu, and a curve-fitting error occurs. 


#define BaselineTerminology
//#define dev
// 
//menu "DataBrowserObjectsPopup"
//	"Fast Fit", /Q, FastFit#BrowserInit()
//end

//menu "Analysis"
//	"Fast Fitting...", /Q, FastFit#Initialise()
//end

static function BrowserInit()
	// get browser selection
	int i
	string strItem = "", strList = ""
	for (i=0;1;i++)
		strItem = GetBrowserSelection(i)
		if (!strlen(strItem))
			break
		endif
		
		if (exists(strItem) != 1)
			continue
		endif
		
		strList = AddListItem(strItem, strList)
	endfor
	wave/wave wwObjects = ListToWaveRefWave(strList, 1)
	if (!numpnts(wwObjects))
		return 0
	endif
	
	if (WaveDims(wwObjects[0])==3)
		Initialise(selection=strList, dims=3)
	elseif (WaveDims(wwObjects[0])==2)
		Initialise(selection=strList, dims=2)
	else
		Initialise(selection=strList, dims=1)
	endif
end

static function/DF GetPackageDFREF()
	DFREF dfr = root:Packages:FastFit
	if (DataFolderRefStatus(dfr) != 1 || WaveExists(dfr:w_ffstruct)==0)
		DFREF dfr = CreatePackageFolder()
	endif
	return dfr
end

static function/DF CreatePackageFolder()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:FastFit
	DFREF dfr = root:Packages:FastFit
	STRUCT ffstruct ffs
	InitialiseStructure(ffs)
	
	Make/O/N=0 dfr:w_ffstruct /wave=w_ffstruct
	StructPut ffs w_ffstruct
	
	Make/T/O/N=(0,2) dfr:coeflist
	Make/O/N=(0,2) dfr:coefsel
	return dfr
end

static function InitialiseStructure(STRUCT ffstruct &ffs)
		
	ffs.version = GetThisVersion()
	
	STRUCT PackagePrefs prefs
	PrefsLoad(prefs)

	ffs.sd         = 1
	ffs.smoothing  = 20
	ffs.hull       = 0
	ffs.polyorder  = 3
	ffs.peak       = 0
	ffs.wavelength = 1
	ffs.cheborder  = 5
	ffs.ffcoef[0]  = 0
	ffs.ffcoef[1]  = 0
	ffs.ffcoef[2]  = 0
	ffs.ffcoef[3]  = 0
	ffs.ffcoef[4]  = 0
	
	// load last-used settings from prefs, with some just-in-case sanity checks
    ffs.tab     = limit(prefs.tab, 0, 3)
    ffs.type[0] = limit(prefs.type[0], 0, ItemsInList(ksMaskedTypes)-1)
    ffs.type[1] = limit(prefs.type[1], 0, ItemsInList(ksManTypes)-1)
    ffs.type[2] = limit(prefs.type[2], 0, ItemsInList(ksAutoTypes)-1)
    ffs.blsuff  = SelectString(strlen(prefs.blSuff)>0, "_BL", prefs.blSuff)
    ffs.subsuff = SelectString(strlen(prefs.subSuff)>0, "_sub", prefs.subSuff)
    ffs.options = prefs.options // see PackagePrefs stucture definition for details
    ffs.base    = prefs.base
    ffs.dims    = limit(prefs.dims, 1, 3)
    ffs.datadim = limit(prefs.datadim, 0, 2)
	
	SetFitFunc(ffs) // sets ffs.fitfunc
end

static function FastFit()
	
	DFREF dfr = GetPackageDFREF()
	STRUCT ffstruct ffs
	StructGet ffs dfr:w_ffstruct
	
	// get selected waves
	#if IgorVersion() >= 9
	string strList = WS_SelectedObjectsList("ffPanel", "lbSelector", includeDFs=0)
	#else
	string strList = WS_SelectedObjectsList("ffPanel", "lbSelector")
	strList = CheckDimensions(ffs, strList)	
	#endif
	wave/wave wwObjects = ListToWaveRefWave(strList, 1)
	int numWaves = numpnts(wwObjects)
	if (!numWaves)
		DoAlert 0, "No waves selected"
		return 0
	endif
		
	ffs.error = 0
	int i
	string msg = ""
	
	if (ffs.dims > 1)
		for (i=0;i<numWaves;i++)
			FastHitHyperspectral(ffs, wwObjects[i])
		endfor
		if (ffs.error & 2)
			msg = "Not all spectra could be sucessfully fit. "
		endif
		if (ffs.error & 1)
			msg += "Output wave already exists, try overwriting."
		endif
		if (strlen(msg))
			DoAlert 0, msg
		endif
		return 1
	endif
	
	Make/free/N=(numpnts(wwObjects)) wPnts = numpnts(wwObjects[p])
	variable pnts = WaveMax(wPnts)
	if (WaveMin(wPnts) != pnts)
		DoAlert 0, "Selected waves don't all have the same number of points"
		return 0
	endif
	
	ffs.datalength = pnts
	
	ControlInfo/W=ffPanel svMask_tab0
	wave/Z wMask = $s_value
	if (ffs.tab == 0)
		if (!WaveExists(wMask))
			DoAlert 1, "No mask wave selected.\rA mask wave can be set up using the baselines user interface.\r\rDo you want to fit the function without a mask?"
			if (V_flag == 2)
				return 0
			endif
		elseif (numpnts(wMask)!=pnts)
			DoAlert 0, "Mask wave doesn't have the right number of points. Please set up the mask wave using the baselines user interface"
			return 0
		elseif (WaveMax(wMask)==0)
			DoAlert 0, "No mask regions have been selected. Please set up the mask wave using the baselines user interface"
			return 0
		endif
		
		if (cmpstr(ffs.fitfunc, "tangent") == 0)
			if (WaveExists(wMask) == 0)
				Duplicate/free wwObjects[0] wMask
				wMask = 1
			endif
			
			wave/Z wEdges = GetTangentEdges(wMask)
			if (WaveExists(wEdges)==0)
				DoAlert 0, "For tangent fits select either one or two fit regions"
				return 0
			endif
		endif
		
	endif
	
	ControlInfo/W=ffPanel svXwave
	wave/Z w_x = $s_value
	if (WaveExists(w_x) && numpnts(w_x)!=pnts)
		DoAlert 0, "Check that the X-wave has same number of points as waves to fit"
		return 0
	endif
	
	ffs.xy = WaveExists(w_x)
	
	Duplicate/free/wave wwObjects wwFits
	
	#ifdef dev
	tic()
	#endif
	if (ffs.tab == 0)
		multithread wwFits = ffMaskedWorker(ffs, wwObjects[p], wMask, w_x, edges=wEdges)
	elseif (ffs.tab == 1)
		multithread wwFits = ffManWorker(ffs, wwObjects[p], w_x)
	elseif (ffs.tab == 2)
		if (cmpstr(ffs.fitfunc, "arc hull") == 0 || cmpstr(ffs.fitfunc, "hull spline") == 0)
			multithread wwFits = ffArcHullWorker(ffs, wwObjects[p], w_x)
		else
			multithread wwFits = ffIterativeWorker(ffs, wwObjects[p], w_x)
		endif
	endif
	#ifdef dev	
	toc(ffs, wMask, dimsize(wwFits, 0))
	#endif

	
	FUNCREF FastFitExtensionPrototype ExtensionFunc = $CheckExtFunc()
	ffs.exfunc = !NumberByKey("ISPROTO", FuncRefInfo(ExtensionFunc))
	
	// wwFits now contains wave references for free waves holding the fit results
	if (ffs.options & 1)
		wwFits = MoveOutputWave(ffs, wwObjects[p], wwFits[p])
	endif
	
	if (ffs.exfunc || (ffs.options&2))
		wwFits = MakeSubWave(ffs, wwObjects[p], wwFits[p], ExtensionFunc)
	endif

	// the single-threaded functions MoveOutputWave and MakeBaselineWave are allowed to reset ffs.error
	if (ffs.error & 2)
		msg = "Not all spectra could be sucessfully fit. "
	endif
	if (ffs.error & 1)
		msg += "Output wave already exists, try overwriting."
	endif
	if (strlen(msg))
		DoAlert 0, msg
	endif

	WS_UpdateWaveSelectorWidget(ksPanel, ksFilterListbox)
end

static function FastHitHyperspectral(STRUCT ffstruct &ffs, wave wData)
	
	int pnts = DimSize(wData, ffs.datadim)
		
	ControlInfo/W=ffPanel svMask_tab0
	wave/Z wMask = $s_value
	if (ffs.tab == 0)
		if (!WaveExists(wMask))
			DoAlert 1, "No mask wave selected.\rA mask wave can be set up using the baselines user interface.\r\rDo you want to fit the function without a mask?"
			if (V_flag == 2)
				return 0
			endif
		elseif (numpnts(wMask) != pnts)
			DoAlert 0, "Mask wave doesn't have the right number of points. Please set up the mask wave using the baselines user interface"
			return 0
		elseif (WaveMax(wMask) == 0)
			DoAlert 0, "No mask regions have been selected. Please set up the mask wave using the baselines user interface"
			return 0
		endif
		
		if (cmpstr(ffs.fitfunc, "tangent") == 0)
			if (WaveExists(wMask) == 0)
				Make/free/N=(pnts) wMask
				wMask = 1
			endif
			
			wave/Z wEdges = GetTangentEdges(wMask)
			if (WaveExists(wEdges) == 0)
				DoAlert 0, "For tangent fits select either one or two fit regions"
				return 0
			endif
		endif
		
	endif
	
	ControlInfo/W=ffPanel svXwave
	wave/Z w_x = $s_value
	if (WaveExists(w_x) && numpnts(w_x)!=pnts)
		DoAlert 0, "check that the X-wave has same number of points as waves to fit"
		return 0
	endif
	
	if (WaveExists(w_x))
		ffs.xy = 1
	endif
	
	variable rows   = max(1, DimSize(wData, 0))
	variable cols   = max(1, DimSize(wData, 1))
	variable layers = max(1, DimSize(wData, 2))
	// for 2D datawaves, layers=1 and the 2D wave reference wave will have one column.
	switch (ffs.datadim)
		case 0:
			Make/free/N=(cols,layers)/wave wwFits // row and col of wwFits refer to column and layer of datawave
			ffs.datalength = rows
			break
		case 1:
			Make/free/N=(rows,layers)/wave wwFits // row and col of wwFits refer to row and layer of datawave
			ffs.datalength = cols
			break
		case 2:
			Make/free/N=(rows,cols)/wave wwFits // row and col of wwFits refer to row and column of datawave
			ffs.datalength = layers
			break
	endswitch
	
	#ifdef dev
	tic()
	#endif
	
	if (ffs.tab == 0)
		multithread wwFits = ffMaskedWorker(ffs, wData, wMask, w_x, row=p, col=q, edges=wEdges)
	elseif (ffs.tab == 1)
		multithread wwFits = ffManWorker(ffs, wData, w_x, row=p, col=q)
	elseif (ffs.tab == 2)
		if (cmpstr(ffs.fitfunc, "arc hull") == 0 || cmpstr(ffs.fitfunc, "hull spline") == 0)
			multithread wwFits = ffArcHullWorker(ffs, wData, w_x, row=p, col=q)
		else
			multithread wwFits = ffIterativeWorker(ffs, wData, w_x, row=p, col=q)
		endif
	endif
	
	#ifdef dev	
	toc(ffs, wMask, dimsize(wwFits, 0) * dimsize(wwFits, 1))
	#endif
	
	int i, j

	FUNCREF FastFitExtensionPrototype ExtensionFunc = $CheckExtFunc()
	ffs.exfunc = !NumberByKey("ISPROTO", FuncRefInfo(ExtensionFunc))
	
	if (ffs.options & 16) // use current DF
		DFREF df = GetDataFolderDFR()
	else // use source DF
		DFREF df = GetWavesDataFolderDFR(wData)
	endif
	
	// we need to create a baseline wave if we are saving baselines, subs, or calling an external function
	// if baselines are not being saved, wave will be free
	if ((ffs.options&3) || ffs.exfunc)
		if (ffs.options & 1) // we want to save baselines
			wave/Z wBase = df:$NameOfWave(wData)+ffs.blsuff
			if ((ffs.options&4) || !WaveExists(wBase))
				Duplicate/O wData df:$NameOfWave(wData)+ffs.blsuff/wave=wBase
			else
				ffs.error = ffs.error | 1
				Duplicate/free wData wBase
			endif
		else
			Duplicate/free wData wBase
		endif
		
		for (i=DimSize(wwFits, 0)-1;i>=0;i--)
			for (j=DimSize(wwFits, 1)-1;j>=0;j--)
				wave/Z w = wwFits[i][j]
				switch (ffs.datadim)
					case 0:
						if (WaveExists(w))
							if (ffs.dims == 2)
								wBase[][i] = w[p]
							else
								wBase[][i][j] = w[p]
							endif
						else
							if (ffs.dims == 2)
								wBase[][i] = NaN
							else
								wBase[][i][j] = NaN
							endif
							ffs.error = ffs.error | 2
						endif
						break
					case 1:
						if (WaveExists(w))
							if (ffs.dims == 2)
								wBase[i][] = w[q]
							else
								wBase[i][][j] = w[q]
							endif
						else
							if (ffs.dims == 2)
								wBase[i][] = NaN
							else
								wBase[i][][j] = NaN
							endif
							ffs.error = ffs.error | 2
						endif
						break
					case 2:
						if (WaveExists(w))
							wBase[i][j][] = w[r]
						else
							wBase[i][j][] = NaN
							ffs.error = ffs.error | 2
						endif
						break
				endswitch
			endfor
		endfor
	endif	
	
	variable v0 = ffs.base
	
	if (ffs.options & 2) // save subs
		string subName = NameOfWave(wData)+ffs.subsuff
		wave/Z wSub = df:$subName
		if ((ffs.options&4) || !WaveExists(wSub))
			Duplicate/O wData df:$subName/wave=wSub
			MatrixOP/O df:$subName = wData - wBase + v0
			wave wSub = df:$subName
			CopyScales wData wSub
		else
			ffs.error = ffs.error | 1
		endif
	elseif (ffs.exfunc)
		MatrixOP/O/free wSub = wData - wBase + v0
		CopyScales wData wSub
	endif
	
	if (ffs.exfunc)
		ExtensionFunc(wData, wBase, wSub)
	endif
	
	WS_UpdateWaveSelectorWidget(ksPanel, ksFilterListbox)
	
	return ffs.error & 2
end

// returns name of valid extension function as string, else ""
static function/S CheckExtFunc()
	ControlInfo/W=ffPanel popExtension
	FUNCREF FastFitExtensionPrototype ExtensionFunc = $S_Value
	if (NumberByKey("ISPROTO", FuncRefInfo(ExtensionFunc)))
		PopupMenu popExtension win=ffPanel, mode=1
//		Button btnEdit, win=ffPanel, title="New"
		Button btnEdit, win=ffPanel, disable=2
		return ""
	endif
	Button btnEdit, win=ffPanel, title="Edit", disable=0
	return s_value
end

static function/S CheckDimensions(STRUCT ffstruct &ffs, string strList)
	int i
	for (i=ItemsInList(strList);i>=0;i--)
		wave/Z w = $StringFromList(i, strList)
		if (!WaveExists(w) || WaveDims(w)!=ffs.dims)
			strlist = RemoveListItem(i, strList)
		endif
	endfor
	return strList
end

// creates a 1D baseline-subtracted wave
static function/wave MakeSubWave(STRUCT ffstruct &ffs, wave wData, wave wBase, FUNCREF FastFitExtensionPrototype ExtensionFunc)
	if (!WaveExists(wBase))
		ffs.error = ffs.error | 2
		return $""
	endif
		
	if (!(ffs.options&2))
		Duplicate/free wData wSub
	else
		if (ffs.options & 16) // use current DF
			DFREF df = GetDataFolderDFR()
		else // use source DF
			DFREF df = GetWavesDataFolderDFR(wData)
		endif
	
		string strName = NameOfWave(wData) + ffs.subsuff
		if (!(ffs.options&4) && WaveExists(df:$strName))
			ffs.error = 1
			return $""
		endif
		Duplicate/O wData df:$strName /wave=wSub
	endif
	
	FastOp wSub = wData - wBase + (ffs.base)
	
	if (!NumberByKey("ISPROTO", FuncRefInfo(ExtensionFunc)))
		ExtensionFunc(wData, wBase, wSub)
	endif
		
	return wSub
end

// *** threadsafe worker functions ***

// row and col are the row and column of the wave ref wave folding the fits.
// this function may be called with a 1D wave as input during a
// multithreaded fit of a multidimensional wave, so don't rely on ffs.dims
threadsafe static function/wave ffMaskedWorker(STRUCT ffstruct &ffs, wave w, wave/Z wMask, wave/Z w_x
	[variable row, variable col, int dofit, wave/Z/D w_coef, int ReturnWave, wave/Z edges])
	
	variable V_FitError = 0, V_fitOptions = 4
	dofit = ParamIsDefault(dofit) ? 1 : dofit
	ReturnWave = ParamIsDefault(ReturnWave) ? 0 : ReturnWave
	if (!dofit && WaveExists(w_coef)==0)
		wave/D w_coef
	endif
		
	DFREF dfSav= GetDataFolderDFR()
	DFREF dfFree = NewFreeDataFolder()
	SetDataFolder dfFree // work in free data folder so that operations that create global output can work safely
	
	// use this rather than ffs.dims in case we are doing iterative fitting of a 1D wave extracted from a multidimensional data wave
	int dims = WaveDims(w)	
	if (dims > 1) // in this case ffs.datadim and ffs.dims apply to the input wave w.
		Make/N=(DimSize(w, ffs.datadim)) wData
		SetScale/P x, DimOffset(w, ffs.datadim), DimDelta(w, ffs.datadim), wData
		switch (ffs.datadim)
			case 0:
				// for a two dimensional input wave col = 0 and w has no layers	
				if (ffs.dims == 3)
					wData = w[p][row][col]
				else
					wData = w[p][row]
				endif
				break
			case 1:			
				if (ffs.dims == 3)
					wData = w[row][p][col]
				else
					wData = w[row][p]
				endif
				break
			case 2:
				wData = w[row][col][p]
				break
		endswitch
	else // input is 1D, regardless of ffs.dims
		wave wData = w
	endif
		
	Duplicate wData dfFree:$NameOfWave(wData) + ffs.blsuff /wave=wBase

	int ChebyshevType = 1
	variable CFerror = 0
	
//	try
	strswitch (ffs.fitfunc)
		case "constant" :
			if (dofit)
				Make/O/D w_coef = {0,0}
				CurveFit/Q/N/H="01" line, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
			endif
			// the wave assignment
			FastOp wBase = (w_coef[0])
			w_coef = {w_coef[0]}
			break
		case "line" :
			if (dofit)
				CurveFit/Q/N line, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave w_coef
			endif
			if (WaveExists(w_x))
				FastOp wBase = (w_coef[0]) + (w_coef[1]) * w_x
			else
				wBase = w_coef[0] + w_coef[1] * x
			endif
			break
		case "poly" :
			if (dofit)
				CurveFit/Q/N poly ffs.polyorder, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave w_coef
			endif
			if (WaveExists(w_x))
				wBase = poly(w_coef, w_x)
			else
				wBase = poly(w_coef, x)
			endif
			break
		case "gauss" :
			if (dofit)
				CurveFit/Q/N Gauss, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="1000" Gauss, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = w_coef[0] + w_coef[1] * exp(-((w_x - w_coef[2])/w_coef[3])^2)
			else
				wBase = w_coef[0] + w_coef[1] * exp(-((x - w_coef[2])/w_coef[3])^2)
			endif
			break
		case "lor" :
			if (dofit)
				CurveFit/Q/N lor, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="1000" lor, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = w_coef[0] + w_coef[1]/((w_x - w_coef[2])^2 + w_coef[3])
			else
				wBase = w_coef[0] + w_coef[1]/((x - w_coef[2])^2 + w_coef[3])
			endif
			break
			#if IgorVersion() >= 9
		case "voigt" :
			if (dofit)
				CurveFit/Q/N voigt, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="10000" voigt, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = VoigtPeak(w_coef, w_x)
			else
				wBase = VoigtPeak(w_coef, x)
			endif
			break
			#endif
		case "sin" :
			if (dofit)
				CurveFit/Q/N sin, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="1000" sin, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = w_coef[0] + w_coef[1]*sin(w_coef[2]*w_x + w_coef[3])
			else
				wBase = w_coef[0] + w_coef[1]*sin(w_coef[2]*x + w_coef[3])
			endif
			break
		case "sigmoid" :
			if (dofit)
				CurveFit/Q/N sigmoid, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="1000" sigmoid, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = w_coef[0] + w_coef[1]/(1+exp(-(w_x - w_coef[2])/w_coef[3]))
			else
				wBase = w_coef[0] + w_coef[1]/(1+exp(-(x - w_coef[2])/w_coef[3]))
			endif
			break
		case "exp" :
			if (dofit)
				CurveFit/Q/N exp, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="100" exp, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif

			endif
			if (WaveExists(w_x))
				wBase = w_coef[0] + w_coef[1]*exp(-w_coef[2]*w_x)
			else
				wBase = w_coef[0] + w_coef[1]*exp(-w_coef[2]*x)
			endif
			break
		case "dblexp" :
			if (dofit)
				CurveFit/Q/N dblexp, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="10000" exp, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = w_coef[0]+w_coef[1]*exp(-w_coef[2]*w_x)+w_coef[3]*exp(-w_coef[4]*w_x)
			else
				wBase = w_coef[0]+w_coef[1]*exp(-w_coef[2]*x)+w_coef[3]*exp(-w_coef[4]*x)
			endif
			break
			#if IgorVersion() >= 9
		case "dblexp_peak" :
			if (dofit)
				CurveFit/Q/N dblexp_peak, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="10000" dblexp_peak, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = W_coef[0]+W_coef[1]*(-exp(-(w_x-W_coef[4])/W_coef[2])+exp(-(w_x-W_coef[4])/W_coef[3]))
			else
				wBase = W_coef[0]+W_coef[1]*(-exp(-(x-W_coef[4])/W_coef[2])+exp(-(x-W_coef[4])/W_coef[3]))
			endif
			break
			#endif
		case "hillequation" :
			if (dofit)
				CurveFit/Q/N hillequation, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="1000" hillequation, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = w_coef[0]+(w_coef[1]-w_coef[0])*(w_x^w_coef[2]/(1+(w_x^w_coef[2]+w_coef[3]^w_coef[2])))
			else
				wBase = w_coef[0]+(w_coef[1]-w_coef[0])*(x^w_coef[2]/(1+(x^w_coef[2]+w_coef[3]^w_coef[2])))
			endif
			break
		case "power" :
			if (dofit)
				CurveFit/Q/N power, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="100" power, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = w_coef[0] + w_coef[1]*w_x^w_coef[2]
			else
				wBase = w_coef[0] + w_coef[1]*x^w_coef[2]
			endif
			break
			#if IgorVersion() >= 9
		case "log" :
			if (dofit)
				CurveFit/Q/N log, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="10" log, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = w_coef[0] + w_coef[1]*log(w_x)
			else
				wBase = w_coef[0] + w_coef[1]*log(x)
			endif
			break
			#endif
		case "lognormal" :
			if (dofit)
				CurveFit/Q/N lognormal, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				if (ffs.peak)
					w_coef[0] = ffs.base
					CurveFit/Q/N/H="1000" lognormal, kwCWave=w_coef, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endif
			endif
			if (WaveExists(w_x))
				wBase = w_coef[0] + w_coef[1]*exp(-(ln(w_x/w_coef[2])/w_coef[3])^2)
			else
				wBase = w_coef[0] + w_coef[1]*exp(-(ln(x/w_coef[2])/w_coef[3])^2)
			endif
			break
		case "Chebyshev2":
			ChebyshevType = 2
		case "Chebyshev": // either of the Chebyshev functions
			Duplicate/free wData w_relx
			variable xmin = WaveExists(w_x) ? w_x[0] : leftx(wData)
			variable xmax = WaveExists(w_x) ? w_x[numpnts(w_x)-1] : pnt2x(wData,numpnts(wData)-1)
			w_relx = 2*((WaveExists(w_x) ? w_x : x) - xmin)/(xmax-xmin) - 1

			int numCoef = ffs.cheborder + 1
			numCoef = min(WaveExists(wMask)? sum(wMask) : numpnts(wData), numCoef)

			Make/O/D/N=(numCoef) w_coef = 1 / (x+1)
			if (ChebyshevType == 2)
				if (dofit)
					FuncFit/Q/N FastFit#ChebyshevSeries2 w_coef wData /M=wMask/X=w_relx/NWOK; CFerror = GetRTError(1)
				endif
				ChebyshevSeries2(w_coef, wBase, w_relx)
			else
				if (dofit)
					FuncFit/Q/N FastFit#ChebyshevSeries w_coef wData /M=wMask/X=w_relx/NWOK; CFerror = GetRTError(1)
				endif
				ChebyshevSeries(w_coef, wBase, w_relx)
			endif
			break
		case "spline" :
			Duplicate/free wData w_masked
			if (WaveExists(wMask))
				FastOp w_masked = wData / wMask
			endif
			WaveStats/Q/M=1 w_masked
			if (V_npnts < 4)
				FastOp wBase = (NaN)
				return wBase
			endif

			if (WaveExists(w_x))
				#if (IgorVersion() < 9)
				Duplicate/free w_x w_x2 // source and destination must be different
				Interpolate2/T=3/I=3/F=1/S=(ffs.sd)/X=w_x2/Y=wBase w_x, w_masked
				#else
				Interpolate2/T=3/I=3/F=1/S=(ffs.sd)/X=w_x/Y=wBase w_x, w_masked
				#endif
			else
				Interpolate2/T=3/I=3/F=1/S=(ffs.sd)/Y=wBase w_masked
			endif
			break
		case "Planck":
			if (dofit)
				CurveFit/Q/N Gauss, wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				wave/D w_coef
				W_coef = {5000,(w_coef[0]+w_coef[1])/3e13}

				// FuncFit won't work with the funcref
				switch (ffs.wavelength)
					case 2:
						FuncFit/Q/N FastFit#PlanckmuM w_coef wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
						break
					case 3:
						FuncFit/Q/N FastFit#PlanckWN w_coef wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
						break
					case 4:
						FuncFit/Q/N FastFit#PlanckAngstrom w_coef wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
						break
					default:
						FuncFit/Q/N FastFit#Planck w_coef wData /M=wMask/X=w_x/NWOK; CFerror = GetRTError(1)
				endswitch
			endif
			if (WaveExists(w_x))
				wBase = planck(w_coef, wl2nm(ffs, w_x))
			else
				wBase = planck(w_coef, wl2nm(ffs, x))
			endif
			break
		case "tangent":
			wave/Z w_coef = GetTangentCoefs(ffs, wData, w_x, wMask, edges)
			if (!WaveExists(w_coef))
				FastOp wBase = (NaN)
				Make/D/O w_coef = {NaN}
				break
			elseif (numpnts(w_coef) == 1)
				FastOp wBase = (w_coef[0])
			else
				wBase = w_coef[0] + w_coef[1]*x
			endif
			break
		default:
			SetDataFolder dfSav
			return $""
	endswitch
//	catch
//
//		// Clear the error silently.
//		variable CFerror = GetRTError(1)	// 1 to clear the error
//		FastOp wBase = (NaN)
//
//	endtry
		
	SetDataFolder dfSav
	
	string strNote = ""
	int i
	
	if (CFerror)
		wave/Z wOut = $""
	elseif (ReturnWave == 0)
		wave/Z wOut =  wBase
		
		if (ffs.dims == 1)
			// only need to do this if we have ext func
			wfprintf strNote, "", w_coef
			note/K wBase, strNote
		endif
		
	elseif (ReturnWave == 1)
		wave/Z wOut = w_coef
	elseif (ReturnWave == 2)
		Duplicate wData dfFree:$NameOfWave(wData) + ffs.subsuff /wave=wSub
		FastOp wSub = wData - wBase + (ffs.base)
		wave/Z wOut = wSub
	endif
	// wOut becomes free wave when free data folder goes out of scope
	return wOut
end

threadsafe static function/wave ffIterativeWorker(STRUCT ffstruct &ffs, wave w, wave/Z w_x, [variable row, variable col, int ReturnWave])

	ReturnWave = ParamIsDefault(ReturnWave) ? 0 : ReturnWave // default is fit result
		
	DFREF dfSav= GetDataFolderDFR()
	DFREF dfFree = NewFreeDataFolder()
	SetDataFolder dfFree // work in free data folder so that operations that create global output can work safely

		
	if (ffs.dims > 1) // data wave is 2D or 3D
		Make/N=(DimSize(w, ffs.datadim)) wData
		SetScale/P x, DimOffset(w, ffs.datadim), DimDelta(w, ffs.datadim), wData
		switch (ffs.datadim)
			case 0:
				// for a two dimensional input wave col = 0 and w has no layers	
				if (ffs.dims == 3)
					wData = w[p][row][col]
				else
					wData = w[p][row]
				endif
				break
			case 1:			
				if (ffs.dims == 3)
					wData = w[row][p][col]
				else
					wData = w[row][p]
				endif
				break
			case 2:
				wData = w[row][col][p]
				break
			default:
				SetDataFolder dfSav
				return $""
		endswitch
	else // data wave is 1D
		wave wData = w
	endif
		
	Duplicate wData w1, w2, wTest
	if (ffs.smoothing)
		Smooth ffs.smoothing, w1
	endif
	variable conv = Inf
	int i
	
	variable offset, factor
	
	for (i=0;i<100;i+=1)
		
		if (mod(i,2))
            wave wIn  = w2
            wave wOut = w1
        else
            wave wIn  = w1
            wave wOut = w2
		endif
		
		if (i==0 && ffs.hull)
			DoHalfHull(ffs, wIn, w_x)
			wave w_XHull, w_YHull
			wave/D w_coef = ffMaskedWorker(ffs, w_YHull, $"", w_XHull, ReturnWave=1)
			wave wBase = ffMaskedWorker(ffs, wData, $"", w_x, dofit=0, w_coef=w_coef)
		else
			wave wBase = ffMaskedWorker(ffs, wIn, $"", w_x)
		endif
		
		if (WaveExists(wBase) == 0)
			break
		endif
	
		offset = 0
		// don't remove points too aggressively for the first few iterations
		if (i < 8)
			factor = 0.5
			if (i==0 && ffs.hull)
				factor = 0.1
			endif

			FastOp wTest = wIn - wBase
					
			if (ffs.options & 8)
				offset = max(0, -factor * WaveMin(wTest))
			else
				offset = max(0, factor * WaveMax(wTest))
			endif
		endif
		
		if (ffs.options & 8)
			wOut = (wIn+offset < wBase) ? wBase : wIn
		else
			wOut = (wIn-offset > wBase) ? wBase : wIn
		endif
		
		if (i < 10) // make at least 10 iterations
			continue
		endif
		
		// convergence test - get a count of the number of fit points changed in this iteration
		FastOp wTest = wOut - wIn
		FastOp wTest = 1 / wTest
		WaveStats/Q/M=1 wTest
		
		if (i>20 && v_npnts<=conv) // converged
			break
		elseif (i>20 && (abs(v_npnts-conv)/conv) < 0.005) // less than 0.5% difference in number of changed points
			break
		else
			conv = v_npnts
		endif
	endfor
	
	SetDataFolder dfSav
	
	if (WaveExists(wBase) == 0)
		return $""
	endif
		
	if (ReturnWave == 0)
		return wBase
	elseif (ReturnWave == 1)
		return w_coef
	elseif (ReturnWave == 2)
		Duplicate wData dfFree:$NameOfWave(wData) + ffs.subsuff /wave=wSub
		FastOp wSub = wData - wBase + (ffs.base)
		return wSub // wSub becomes free wave when free data folder goes out of scope
	endif
	
	return $""
end

threadsafe static function/wave ffManWorker(STRUCT ffstruct &ffs, wave w, wave/Z w_x, [variable row, variable col, int ReturnWave])

	ReturnWave = ParamIsDefault(ReturnWave) ? 0 : ReturnWave
		
	DFREF dfSav= GetDataFolderDFR()
	DFREF dfFree = NewFreeDataFolder()
	SetDataFolder dfFree // work in free data folder so that operations that create global output can work safely
	
	if (ffs.dims > 1)
		Make/N=(DimSize(w, ffs.datadim)) wData
		SetScale/P x, DimOffset(w, ffs.datadim), DimDelta(w, ffs.datadim), wData
		switch (ffs.datadim)
			case 0:
				// for a two dimensional input wave col = 0 and w has no layers	
				if (ffs.dims == 3)
					wData = w[p][row][col]
				else
					wData = w[p][row]
				endif
				break
			case 1:			
				if (ffs.dims == 3)
					wData = w[row][p][col]
				else
					wData = w[row][p]
				endif
				break
			case 2:
				wData = w[row][col][p]
				break
		endswitch
	else
		wave wData = w
	endif
		
	Duplicate wData dfFree:$NameOfWave(wData) + ffs.blsuff /wave=wBase
	
	strswitch (ffs.fitfunc)
		case "constant":
			wBase = ffs.ffcoef[0]
			break
		case "line":
			if (WaveExists(w_x))
				wBase = ffs.ffcoef[0] + ffs.ffcoef[1] * w_x[p]
			else
				wBase = ffs.ffcoef[0] + ffs.ffcoef[1] * x
			endif
			break
		case "poly":
			Make/free/D/N=(ffs.polyorder) coef
			coef = ffs.ffcoef[p]
			if (WaveExists(w_x))
				wBase = poly(coef, w_x)
			else
				wBase = poly(coef, x)
			endif
			break
		case "gauss":
			if (WaveExists(w_x))
				wBase = ffs.ffcoef[0] + ffs.ffcoef[1] * exp(-((w_x - ffs.ffcoef[2])/ffs.ffcoef[3])^2)
			else
				wBase = ffs.ffcoef[0] + ffs.ffcoef[1] * exp(-((x - ffs.ffcoef[2])/ffs.ffcoef[3])^2)
			endif
			break
		case "lor":
			if (WaveExists(w_x))
				wBase = ffs.ffcoef[0]+ffs.ffcoef[1]/(((w_x-ffs.ffcoef[2])^2)+ffs.ffcoef[3])
			else
				wBase = ffs.ffcoef[0]+ffs.ffcoef[1]/(((x-ffs.ffcoef[2])^2)+ffs.ffcoef[3])
			endif
			break
		case "sin":
			if (WaveExists(w_x))
				wBase = ffs.ffcoef[0] + ffs.ffcoef[1]*sin(ffs.ffcoef[2]*w_x + ffs.ffcoef[3])
			else
				wBase = ffs.ffcoef[0] + ffs.ffcoef[1]*sin(ffs.ffcoef[2]*x + ffs.ffcoef[3])
			endif
			break
		case "sigmoid":
			if (WaveExists(w_x))
				wBase = ffs.ffcoef[0] + ffs.ffcoef[1]/(1+exp(-(w_x[p]-ffs.ffcoef[2])/ffs.ffcoef[3]))
			else
				wBase = ffs.ffcoef[0] + ffs.ffcoef[1]/(1+exp(-(x-ffs.ffcoef[2])/ffs.ffcoef[3]))
			endif
			break
		default:
			SetDataFolder dfSav
			return $""
	endswitch
	
	SetDataFolder dfSav
	
	if (ReturnWave == 0)
		return wBase
	elseif (ReturnWave == 2)
		Duplicate wData dfFree:$NameOfWave(wData) + ffs.subsuff /wave=wSub
		FastOp wSub = wData - wBase + (ffs.base)
		return wSub
	endif
	
	return $""
end

// populates wBase with archull/hullspline baseline calculated from wData
// the supplied waves may be free waves representing a subrange of the data
threadsafe static function/wave ffArcHullWorker(STRUCT ffstruct &ffs, wave w, wave/Z w_x, [variable row, variable col, int ReturnWave])

	ReturnWave = ParamIsDefault(ReturnWave) ? 0 : ReturnWave
	
	DFREF dfSav= GetDataFolderDFR()
	DFREF dfFree = NewFreeDataFolder()
	SetDataFolder dfFree // work in free data folder so that operations that create global output can work safely
	
	if (ffs.dims > 1)
		Make/N=(DimSize(w, ffs.datadim)) wData
		SetScale/P x, DimOffset(w, ffs.datadim), DimDelta(w, ffs.datadim), wData
		switch (ffs.datadim)
			case 0:
				if (ffs.dims == 3)
					wData = w[p][row][col]
				else
					wData = w[p][row]
				endif
				break
			case 1:
				if (ffs.dims == 3)
					wData = w[row][p][col]
				else
					wData = w[row][p]
				endif
				break
			case 2:
				wData = w[row][col][p]
				break
		endswitch
	else
		wave wData = w
	endif
	
	if (numpnts(wData) < 4)
		SetDataFolder dfSav
		return $""
	endif
	
	// make a copy of the (possibly smoothed) data wave
	Duplicate/free wData wSmoothed, wArc
		
	Duplicate wData dfFree:$NameOfWave(wData) + ffs.blsuff /wave=wBase
		
	if (ffs.smoothing > 0)
		Smooth ffs.smoothing, wSmoothed
	endif
	FastOp wBase = wSmoothed

	// calculate arc hull based on (possibly smoothed) data
	
	if (ffs.xy == 0)
		Duplicate/free wBase w_x
		// redimension to make sure we don't get hull vertices
		// outside the range of w_x owing to difference in precision
		// of output from ConvexHull
		Redimension/D w_x
		w_x = x
	endif

	// add concave function
	variable radius
	if (ffs.xy)
		radius = (WaveMax(w_x) - WaveMin(w_x)) / 2
		wArc = ffs.depth * (w_x[p] - w_x[0])^2 / radius^2
	else
		variable x1 = leftx(wBase), x2 = pnt2x(wBase, numpnts(wBase) - 1)
		radius = abs(x2 - x1) / 2
		wArc = ffs.depth * (x-x1)^2 / radius^2
	endif
	
	FastOp wBase = wBase + wArc
	ConvexHull/Z w_x, wBase
	wave/Z w_XHull, w_YHull
	
	if (ffs.xy == 0)
		wave/Z w_x = $""
	endif

	if (!(ffs.options & 8))
		Reverse/P w_XHull, w_YHull
	endif
	// negative depth will subtract top part of convex hull
	// an offset will likely need to be applied
	
	WaveStats/Q/M=1 w_XHull
	Rotate -v_minloc, w_XHull, w_YHull
	SetScale/P x, 0, 1, w_XHull, w_YHull
	WaveStats/Q/M=1 w_XHull
	DeletePoints v_maxloc+1, numpnts(w_XHull)-v_maxloc-1, w_XHull, w_YHull
		
	if (cmpstr(ffs.fitfunc, "hull spline") == 0) // hull spline - prepare nodes
		if (ffs.XY)
			w_YHull = GetYfromWavePair(w_XHull, wSmoothed, w_x)
		else
			w_YHull = wSmoothed(w_XHull)
		endif
		
		if (numpnts(w_XHull) > 3)
			DoInterpolation(2, wBase, w_x, w_YHull, w_XHull)
		else
			FastOp wBase = (NaN)
		endif
	else // normal archull calculation
		DoInterpolation(1, wBase, w_x, w_YHull, w_XHull)
		FastOp wBase = wBase - wArc
	endif
	
	SetDataFolder dfSav
	
	if (ReturnWave == 0)
		return wBase
	elseif (ReturnWave == 2)
		Duplicate wData dfFree:$NameOfWave(wData) + ffs.subsuff /wave=wSub
		FastOp wSub = wData - wBase + (ffs.base)
		return wSub
	endif
	
	return $""
end

static function/wave MoveOutputWave(STRUCT ffstruct &ffs, wave wData, wave wBase)
	
	if (!WaveExists(wBase))
		ffs.error = ffs.error | 2
		return $""
	endif
	
	if (ffs.options & 16) // use current DF
		DFREF df = GetDataFolderDFR()
	else // use source DF
		DFREF df = GetWavesDataFolderDFR(wData)
	endif
	
	string strName = NameOfWave(wData) + ffs.blsuff
	
	if (ffs.options & 4)
		KillWaves/Z df:$strName
	endif
	
	wave/Z w = df:$strName
	if (WaveExists(w))
		if (ffs.options & 4)
			Duplicate/O wBase w
			wave wBase = w
		else
			ffs.error = ffs.error | 1
		endif
	else
		MoveWave wBase df:$strName
	endif
		
	return wBase
end

threadsafe static function DoHalfHull(STRUCT ffstruct &ffs, wave wData, wave/Z w_x)
	if (ffs.xy == 0)
		Duplicate/free wData w_x
		// redimension to make sure we don't get hull vertices
		// outside the range of w_x owing to difference in precision
		// of output from ConvexHull
		Redimension/D w_x
		w_x = x
	endif

	ConvexHull/Z w_x, wData
	wave w_XHull, w_YHull
	if (!(ffs.options&8))
		Reverse/P w_XHull, w_YHull
	endif
	WaveStats/Q w_XHull
	Rotate -v_minloc, w_XHull, w_YHull
	SetScale/P x, 0, 1, w_XHull, w_YHull
	WaveStats/Q w_XHull
	DeletePoints v_maxloc+1, numpnts(w_XHull)-v_maxloc-1, w_XHull, w_YHull
end

threadsafe static function/wave GetTangentEdges(wave wMask)
	// make sure we have one or two regions to fit
	FindLevels/Q/EDGE=1/P wMask, 1
	int numRegions = V_LevelsFound + (wMask[0]==1)
	if (numRegions<1 || numRegions>2)
		return $""
	endif
	
	// find the points at edges of fit regions
	Make/free/N=(2*numRegions) wEdgesP
	
	int pnt = 0, j = 0
	do
		if (pnt==0 && wMask[pnt]==1)
			wEdgesP[j] = pnt
			j += 1
		elseif (pnt==numpnts(wMask)-1 && wMask[pnt]==1)
			wEdgesP[j] = pnt
			j += 1
		elseif (pnt>0 && wMask[pnt]!=wMask[pnt-1])
			wEdgesP[j] = pnt - wMask[pnt-1]
			j += 1
		endif
		pnt += 1
	while (j<(2*numRegions) && pnt<numpnts(wMask))
	if (!(j==2 || j==4))
		return $""
	endif
	
	Sort wEdgesP, wEdgesP
	return wEdgesP
end

// return coefficient wave
threadsafe static function/wave GetTangentCoefs(STRUCT ffstruct &ffs, wave wData, wave/Z w_x, wave wMask, wave/Z wEdgesP)
		
	if (!WaveExists(wEdgesP))
		wave/Z wEdgesP = GetTangentEdges(wMask)
		if (!WaveExists(wEdgesP))
			return $""
		endif
	endif

	if (numpnts(wEdgesP) == 4)
		return GetCommonTangentCoefs(wEdgesP, wData, w_x)
	else //if (abs(wEdgesP[1]-wEdgesP[0]) >= 4) // fit horizontal tangent
		return GetHorizontalTangentCoefs(ffs, wEdgesP, wData, w_x)
	endif
	
end

// for threadsafe use must be run in a free data folder
threadsafe static function/wave GetCommonTangentCoefs(wave wEdgesP, wave wData, wave/Z w_x)
	
	Duplicate/free wEdgesP, wEdgesX
	wEdgesX = (WaveExists(w_x)) ? w_x[wEdgesP] : pnt2x(wData, wEdgesP)
	
	Make/D/N=2/free coef = {NaN,NaN}
	Make/D/free/N=9 w_9coef = 0
	// w_9coef[0,3],[4,7] are coefficients for first and second poly, respectively
	
	variable V_FitError = 0
	CurveFit/Q poly 4, wData[wEdgesP[0],wEdgesP[1]] /X=w_x/NWOK
	wave/D w_coef = w_coef
	w_9coef[0,3] = w_coef
	
	V_FitError = 0
	CurveFit/Q poly 4, wData[wEdgesP[2],wEdgesP[3]] /X=w_x/NWOK
	w_9coef[4,7] = w_coef[p-4]
	
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
			return $"" // no crossings
		else // one crossing
			crossingX = crossing2
		endif
	elseif (numtype(crossing2))
		crossingX = crossing1
	else // two crossings, choose the one closest to midpoint
		crossingX = (abs(crossing1 - xmid) < abs(crossing2 - xmid)) ? crossing1 : crossing2
	endif
				
	variable delta = 2 * abs(deltax(w_deltaY))
		
	// this fails in igor 8 when multithreading is enabled
	// error: The function (not available) has the wrong parameter types or the wrong number of parameters.
	FindRoots/H=(crossingX+delta)/L=(crossingX-delta)/Q FastFit#TangentDistance, w_9coef
	if (V_flag)
		return $""
	endif
	
	if (V_root != limit(V_root, xmin, xmax))
		return $"" // found a tangent beyond the x-range of first region
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
		return $""
	endif
	
	coef = {intercept, grad}
	return coef
end

threadsafe static function/wave GetHorizontalTangentCoefs(STRUCT ffstruct &ffs, wave wEdgesP, wave wData, wave/Z w_x)
	
	Make/D/N=2 coef={NaN, NaN}
	
	Duplicate wEdgesP, wEdgesX
	wEdgesX = (WaveExists(w_x)) ? w_x[wEdgesP] : pnt2x(wData, wEdgesP)
	variable midX = wEdgesX[0] + (wEdgesX[1] - wEdgesX[0])/2
	variable xmin = min(wEdgesX[0], wEdgesX[1])
	variable xmax = max(wEdgesX[0], wEdgesX[1])
		
	variable V_FitError = 0
	CurveFit/Q poly 4, wData[wEdgesP[0],wEdgesP[1]] /X=w_x/NWOK
	if (V_FitError)
		return $""
	endif
	
	wave/D w_coef = w_coef
	
	// differentiate and look for roots in range
	// figure out tangent point
	variable a, b, c, root1, root2
	a = 3*w_coef[3]
	b = 2*w_coef[2]
	c = w_coef[1]
	
	root1 = (-b + sqrt(b^2 -4 * a * c)) / (2 * a)
	root2 = (-b - sqrt(b^2 -4 * a * c)) / (2 * a)
	
	Make/free wRoots = {root1,root2}
	wRoots = wRoots==limit(wRoots, xmin, xmax) ? wRoots : NaN
	
	if (ffs.options & 8)
		wRoots = 6*w_coef[3]*wRoots + 2*w_coef[2] < 0 ? wRoots : NaN
	else
		wRoots = 6*w_coef[3]*wRoots + 2*w_coef[2] > 0 ? wRoots : NaN
	endif
	
	wRoots = poly(w_coef, wRoots) // put Y value(s) in wRoots
	
	if (numtype(wRoots[0]) == 0)
		coef = {wRoots[0]}
	elseif (numtype(wRoots[1]) == 0)
		coef = {wRoots[1]}
	else
		return $""
	endif

	return coef
end

// *** FF Panel ***
static function Initialise([string selection, int dims])
	
	variable left = 50
	variable top = 100
	if (WinType("ffPanel") == 7)
		GetWindow/Z ffPanel wsizeRM
		left = v_left
		top = v_top
	else
		STRUCT point screenOrigin
		getScreenOrigin(screenOrigin)
		left = screenOrigin.h + 200
		top = screenOrigin.v + 100
	endif
	int i
	
	KillWindow/Z ffPanel
		
	DFREF dfr = GetPackageDFREF() // ffstruct now exists.
	STRUCT ffstruct ffs
	StructGet ffs dfr:w_ffstruct
	
	ffs.base = 0
	ffs.xy = 0
	ffs.tab = limit(ffs.tab, 0, 2)
	if (!ParamIsDefault(dims))
		ffs.dims = limit(dims, 1, 3)
	endif
	StructPut ffs dfr:w_ffstruct
		
	wave/SDFR=dfr/T coeflist
	wave/SDFR=dfr coefsel
	
	variable fs = 12
	int isWin = 0
	#ifdef WINDOWS
	isWin = 1
	#endif
	
	int blfit = 0
	#ifdef BaselineTerminology
	blfit = 1
	#endif
	
	variable width = 430
	variable height = 470
	NewPanel/K=1/W=(left,top,left+width,top+height)/N=ffPanel as "Fast Fitting"
	ModifyPanel/W=ffPanel fixedSize=1, noEdit=1
	
	string strTitle, strHelp
	
	variable x0 = 10, y0 = 10
	PopupMenu popDims, win=ffPanel, pos={x0,y0}, size={50,20}, title="", value="1D;2D;3D;", mode=ffs.dims, fsize=fs, Proc=FastFit#ffPopups
	PopupMenu popDims, win=ffPanel, help={"Select from one-, two- or three-dimensional input waves"}
	string strValue = SelectString(ffs.dims - 2, "\"Rows;\"", "\"Rows;Columns;\"", "\"Rows;Columns;Layers;\"")
	
	PopupMenu popDataDim, win=ffPanel, pos={70,y0}, size={200,20}, title="dimension", value=#strValue, mode=ffs.dims, fsize=fs, Proc=FastFit#ffPopups //, disable=2*(!(ffs.options & 32))
	PopupMenu popDataDim, win=ffPanel, help={"Select the wave dimension for fitting"}
	y0 += 25
	
	variable selectorheight = 317
	InsertWaveSelectorWidget(ffs, x0, y0, 200, selectorheight)
	if (ParamIsDefault(selection) == 0)
		// open all the data folders for our wave selection
		DFREF dfOld = $""
		wave/wave wwObjects = ListToWaveRefWave(selection, 1)
		for(i=numpnts(wwObjects)-1;i>=0;i--)
			DFREF dfNew = GetWavesDataFolderDFR(wwObjects[i])
			if (!DataFolderRefsEqual(dfNew , dfOld))
				WS_OpenAFolderFully(ksPanel, ksFilterListbox, GetWavesDataFolder(wwObjects[i], 1))
			endif
			DFREF dfOld = dfNew
		endfor
		// select the waves
		WS_SelectObjectList("ffPanel", "lbSelector", selection)
	endif
	y0 += selectorheight + 59
	
	SetVariable svXwave,pos={x0,y0},size={200,14},title="X wave",value=_STR:"", fsize=fs, Proc=FastFit#ffSetvars
	SetVariable svXwave, help={"For X-Y fitting, select an X-wave with the same number of points as the data waves/data dimension"}
		

	// column 2
	x0 = 220
	y0 = 10
	
	Button btnHelp, pos={x0+190,5}, size={15,15}, title="", Picture=FastFit#pHelp, labelBack=0
	Button btnHelp, help={"Click for help"}, focusRing=0, Proc=FastFit#ffButtons//, disable=2
	
	Button btnInfo, pos={x0+170,5}, size={15,15}, Proc=FastFit#ffButtons, title=""
	Button btnInfo, help={"Show Info"}, Picture=updater#pInfo
	
//	Button btnSettings, pos={x0+185,y0}, size={15,15}, title="", Picture=FastFit#pCog, labelBack=0
//	Button btnSettings, help={"Change Settings"}, focusRing=0 // , Proc=
	
	
//	// buttons at the top
//	strHelp = "Plots the selected waves in a graph window and opens baselines GUI"
//	#if exists("baselines#initialise") != 6
//	strHelp += "\r       *** Requires baselines.ipf ***"
//	#endif
//	Button btnSetup, pos={x0+5,y0}, size={195,20}, title="Set Up Fit in Baselines Panel", Proc=FastFit#ffButtons
//	Button btnSetup, help={strHelp}
//	y0 += 25
//	strHelp = "Import the fitting settings for ALL tabs from the baselines GUI"
//	#if exists("baselines#initialise") != 6
//	strHelp += "\r       *** Requires baselines.ipf ***"
//	#endif
//	Button btnRead, pos={x0+5,y0}, size={195,20}, title="Read Values from Baselines UI", Proc=FastFit#ffButtons
//	Button btnRead, help={strHelp}
//	y0 += 30
	
	// leave space for buttons
	y0 += 20 
		
	// tabs
	int tabsY0 = y0
	TabControl tabs,pos={x0,tabsY0},size={205,160},Proc=FastFit#ffTabs
	TabControl tabs,labelBack=(61166,61166,61166),tabLabel(0)="Mask"
	TabControl tabs,tabLabel(1)="Man",tabLabel(2)="Auto",value=ffs.tab	
	y0 += 30
	
	
	strTitle = SelectString(blfit, "Fit function", "Baseline type")
	GroupBox groupType, win=ffPanel, pos={x0+10,y0}, size={186,50}, title=strTitle, fSize=fs//, frame=0	
	y0 += 23
	strTitle = SelectString(blfit, "Select fit function", "Select baseline type")
	PopupMenu popType, win=ffPanel, pos={x0+20,y0}, size={100,20}, title="", fSize=fs
	PopupMenu popType, win=ffPanel, help={strTitle}, Proc=FastFit#ffPopups	
//	y0 += 37
	
	
	y0 +=1
	// tabs 0 and 2
	SetVariable svSD, win=ffPanel, pos={x0+65,y0}, size={120,16}, title="SD", fSize=fs, focusring=0
	SetVariable svSD, win=ffPanel, limits={0,Inf,1}, value=_NUM:ffs.sd, bodyWidth=60
	string strModifiers
	#ifdef WINDOWS
	strModifiers = "\rHold shift/alt to increase/decrease increment"
	#else
	strModifiers = "\rHold shift/option to increase/decrease increment"
	#endif
	SetVariable svSD, win=ffPanel, help={"Estimate of noise for smoothing spline" + strModifiers}, Proc=FastFit#ffSetvars

	SetVariable svDepth_tab2, win=ffPanel, pos={x0+120,y0}, size={65,16}, title="", fSize=fs, focusring=0
	SetVariable svDepth_tab2, win=ffPanel, limits={-Inf,Inf,abs(ffs.depth/10)+(ffs.depth==0)}, value=_NUM:ffs.depth
	SetVariable svDepth_tab2, win=ffPanel, help={"Depth of arc" + strModifiers}, Proc=FastFit#ffSetvars
	
	// appears in tabs 0, 1, 2
	SetVariable svPoly, win=ffPanel, pos={x0+85,y0}, size={100,16}, bodyWidth=40, title="Order", fSize=fs, focusring=0
	SetVariable svPoly, win=ffPanel, value=_NUM:ffs.polyorder
	#if igorversion() >= 9
	SetVariable svPoly, win=ffPanel, textAlign=1
	#endif
	SetVariable svPoly, win=ffPanel, help={"Polynomial order"}, Proc=FastFit#ffSetvars
	
	// appears in tabs 0, 2
	SetVariable svChebOrder, win=ffPanel, pos={x0+85,y0}, size={100,16}, bodyWidth=40, title="", fSize=fs
	SetVariable svChebOrder, win=ffPanel, limits={0,30,1}, value=_NUM:ffs.cheborder, focusring=0
	#if igorversion() >= 9
	SetVariable svChebOrder, win=ffPanel, textAlign=1
	#endif
	SetVariable svChebOrder, win=ffPanel, help={"Maximum polynomial order in Chebyshev series"}, Proc=FastFit#ffSetvars
	
	// appears in tabs 0 and 2
	CheckBox chkPeak, win=ffPanel, pos={x0+135,y0+2*isWin}, title="Peak", fSize=fs, Proc=FastFit#ffCheckboxes
	CheckBox chkPeak, win=ffPanel, help={"Peak function with vertical offset tabsY0 fixed at baseline zero value"}, value=ffs.peak
	
	// appears in tabs 0 and 2
	PopupMenu popPlanck, win=ffPanel, pos={x0+115,y0}, title="", fSize=fs, Proc=FastFit#ffPopups
	PopupMenu popPlanck, win=ffPanel, help={"select wavelength units"}, mode=ffs.wavelength, value="nm;μm;cm^-1;Å;"
	
		
	y0 = tabsY0 + 90
	// tab 0
	SetVariable svMask_tab0,pos={x0+15,y0},size={180,14},title="Mask",value=_STR:"", fsize=fs, Proc=FastFit#ffSetvars
	
	// tab 1
	ResetCoefListwave(ffs)
	wave/T/SDFR=dfr coeflist
	wave/SDFR=dfr coefsel
	ListBox listCoef_tab1, pos={x0+30,y0}, size={150,55}
	ListBox listCoef_tab1, fSize=9, focusRing=0, widths={10,20}, listwave=coeflist, selwave=coefsel, Proc=FastFit#ffListbox
	

	y0 = tabsY0+85	
	// tab 2, auto
	SetVariable svSmooth_tab2, win=ffPanel, pos={x0+25,y0}, size={130,16}, title="Pre-smooth", fSize=fs, focusring=0
	SetVariable svSmooth_tab2, win=ffPanel, limits={0,32767,1}, value=_NUM:ffs.smoothing
	SetVariable svSmooth_tab2, win=ffPanel, help={"Binomial pre-smoothing factor for baseline calculation"}, Proc=FastFit#ffSetvars
	y0 += 25
	CheckBox chkNeg_tab2, win=ffPanel, pos={x0+25,y0+2*isWin}, title="Negative peaks", fSize=fs, Proc=FastFit#ffCheckboxes
	CheckBox chkNeg_tab2, win=ffPanel, help={"Fit baseline to top of spectrum"}, value=ffs.options&8
	y0 += 20
	CheckBox chkHull_tab2, win=ffPanel, pos={x0+25,y0+2*isWin}, title="Use convex hull at start", fSize=fs, Proc=FastFit#ffCheckboxes
	CheckBox chkHull_tab2, win=ffPanel, help={"Use convex hull for first iteration"}, value=ffs.hull
	
	ShowTab(ffs)		
	y0 = tabsY0 + 165
	
	
	// group for buttons to interact with baselines GUI
	GroupBox groupGUI, win=ffPanel, pos={x0,y0}, size={205,55}, title="Baselines user interface", fSize=fs//, frame=0
	y0 += 25
	strHelp = "Plot the selected waves in a graph window and open baselines GUI"
	#if exists("baselines#initialise") != 6
	strHelp += "\r       *** Requires baselines.ipf ***"
	#endif
	Button btnSetup, pos={x0+17,y0}, size={75,20}, title="Set Up Fit", Proc=FastFit#ffButtons
	Button btnSetup, help={strHelp}
	strHelp = "Import the fitting settings displayed in the baselines GUI"
	#if exists("baselines#initialise") != 6
	strHelp += "\r       *** Requires baselines.ipf ***"
	#endif
	Button btnRead, pos={x0+102,y0}, size={85,20}, title="Read Values", Proc=FastFit#ffButtons
	Button btnRead, help={strHelp}		
	y0 += 33
		
	
	// output options
	GroupBox grpOutput,pos={x0,y0},size={205,130},title="Output"
	GroupBox grpOutput,fSize=fs
	y0 += 25
	strTitle = SelectString(blfit, "Fits", "Baselines")
	CheckBox chkBL,pos={230,y0},size={100,50}, title=strTitle, fsize=fs, value=ffs.options&1, Proc=FastFit#ffCheckboxes
	SetVariable svBLsuff,pos={320,y0},size={80,14},title="Suffix:",value=_STR:ffs.blsuff, fsize=fs, Proc=FastFit#ffSetvars
	strHelp = "Suffix is appended to output fit wave names"
	if (blfit)
		strHelp = "Suffix is appended to output baseline wave names"
	endif
	SetVariable svBLsuff, help={strHelp}
	y0 += 20	
	strTitle = SelectString(blfit, "Residuals", "Subtracted")
	CheckBox chkSub,pos={230,y0},size={100,50}, title=strTitle, fsize=fs, value=ffs.options&2, Proc=FastFit#ffCheckboxes
	SetVariable svSubsuff,pos={320,y0},size={80,14},title="Suffix:",value=_STR:ffs.subsuff, fsize=fs, Proc=FastFit#ffSetvars
	strHelp = "Suffix is appended to residual wave names"
	if (blfit)
		strHelp = "Suffix is appended to output baseline-subtracted wave names"
	endif
	SetVariable svSubsuff, help={strHelp}
	y0 += 20		
	CheckBox chkOverwrite,pos={230,y0},size={100,50}, title="Overwrite", fsize=fs, value=ffs.options&4, Proc=FastFit#ffCheckboxes
	strHelp = "Overwrite fit and residual waves without warning"
	if (blfit)
		strHelp = "Overwrite baseline and baseline-subtracted waves without warning"
	endif
	CheckBox chkOverwrite, help={strHelp}
	y0 += 20	
	TitleBox tbOutput, title="Output Data Folder:", pos={x0+10, y0}, fSize=fs, frame=0
	y0 += 20	
	CheckBox chkCurrentDF, pos={x0+10, y0}, title="Current", mode=1, fSize=fs, Proc=FastFit#ffCheckboxes, value=ffs.options&256
	CheckBox chkSourceDF, pos={x0+75, y0}, title="Same as Source", mode=1, fSize=fs, Proc=FastFit#ffCheckboxes, value=!(ffs.options&256)	
	y0 += 30
	
	// extension function selection
	GroupBox grpExt,pos={x0,y0},size={205,50},title="Post-fit user function"
	GroupBox grpExt,fSize=fs, help={"User functions extend functionality by operating on output waves"}
	y0 += 22
	PopupMenu popExtension, win=ffPanel, pos={230,y0}, size={140,20}, title="", bodywidth=140, mode=1, value=fastfit#fList(), fsize=fs, Proc=FastFit#ffPopups
	strHelp = "User functions must take three waves (data, fit, and residual) as parameters."
	if (blfit)
		strHelp = "User functions must take three waves (input,\rbaseline, and subtracted) as parameters. They\r"
	endif
	strHelp += "can be used to create additional output waves."
	PopupMenu popExtension, win=ffPanel, help={"Select function for extended analysis.\r" + strHelp}
	
	Button btnEdit, pos={x0+155,y0}, size={40,18}, Proc=FastFit#ffButtons
	Button btnEdit, help={"Open the procedure window to edit the selected function"}
	Button btnEdit, title="Edit", disable=2
	//	Button btnEdit, title="New"
	y0+=33
	

	Button btnDoIt, pos={370,y0}, size={50,20}, title="Do It", Proc=FastFit#ffButtons
	Button btnDoIt, help={"Fit the selected waves"}
	
	if (!blfit)
		TabControl tabs, disable=1
		ffs.tab = 0
		ShowTab(ffs)
		StructPut ffs dfr:w_ffstruct
	endif
		
	SetWindow ffPanel hook(hCleanup)=FastFit#hookCleanup
end

static function/S fList()
	string strList = ""
	#if IgorVersion() >= 9
	strList = FunctionList("!*prototype", ";", "KIND:2,NPARAMS:3,PARAM_0_TYPE:-2,PARAM_1_TYPE:-2,PARAM_2_TYPE:-2")
	#else
	strList = FunctionList("!*prototype", ";", "KIND:2,NPARAMS:3,VALTYPE:1")
	int i
	variable param1, param2, param3, pos
	string strInfo = ""
	for (i=ItemsInList(strList);i>=0;i--)
		strInfo = FunctionInfo(StringFromList(i, strList))
		pos = max(0, strsearch(strInfo, "PARAM_0_TYPE", 0))	
		sscanf strInfo[pos,Inf], "PARAM_0_TYPE:%d;PARAM_1_TYPE:%d;PARAM_2_TYPE:%d;", param1, param2, param3
		if ((param1&16386)!=16386 || (param2&16386)!=16386 || (param3&16386)!=16386)
			strList = RemoveListItem(i, strList)
		endif
	endfor
	#endif
	strList = " ;" + strList + "\\M1-;Create new template function...;"
	return strList
end

static function ResetPanel(STRUCT ffstruct &ffs)
	
	SetFitFunc(ffs)
	
//	SetVariable svBase,win=ffPanel,value=_NUM:ffs.base
	SetVariable svSD, win=ffPanel, value=_NUM:ffs.sd
	SetVariable svDepth_tab2, win=ffPanel, value=_NUM:ffs.depth
	SetVariable svPoly, win=ffPanel, value=_NUM:ffs.polyorder
	SetVariable svChebOrder, win=ffPanel, value=_NUM:ffs.cheborder
	CheckBox chkPeak, win=ffPanel, value=ffs.peak
	PopupMenu popPlanck, win=ffPanel, mode=ffs.wavelength
	SetVariable svSmooth_tab2, win=ffPanel,value=_NUM:ffs.smoothing
	CheckBox chkNeg_tab2, win=ffPanel, value=ffs.options&8
	CheckBox chkHull_tab2, win=ffPanel, value=ffs.hull
	
	ResetCoefListwave(ffs)
	ffs.tab = limit(ffs.tab, 0, 2)
	TabControl tabs, win=ffPanel, value=ffs.tab
	ShowTab(ffs)
	
	CheckBox chkBL, win=ffPanel, value=ffs.options&1
	SetVariable svBLsuff, win=ffPanel, value=_STR:ffs.blsuff
	CheckBox chkSub, win=ffPanel, value=ffs.options&2
	SetVariable svSubsuff, win=ffPanel, value=_STR:ffs.subsuff
	CheckBox chkOverwrite, win=ffPanel, value=ffs.options&4
	CheckBox chkCurrentDF, win=ffPanel, value=ffs.options&256
	CheckBox chkSourceDF, win=ffPanel, value=!(ffs.options&256)	
end

// sync listbox with coefficient values from ffstruct
static function ResetCoefListwave(STRUCT ffstruct &ffs)
	DFREF dfr = GetPackageDFREF()
	wave/SDFR=dfr/T coeflist
	wave/SDFR=dfr coefsel
	
	int numcoef
	strswitch (ffs.fitfunc)
		case "constant":
			numcoef = 1
			break
		case "line":
			numcoef = 2
			break
		case "poly":
			numcoef = min(5, ffs.polyorder)
			break
		case "gauss":
		case "lor":
		case "sin":
		case "sigmoid":
			numcoef = 4
			break
	endswitch
	Redimension/N=(numcoef, 2) coeflist, coefsel
	coeflist[][1] = num2str(numtype(ffs.ffcoef[p]) ? 0 : ffs.ffcoef[p])
	coeflist[][0] = "coef[" + num2str(p) + "]"
	coefsel[][0] = 0
	coefsel[][1] = 2
	
	DoUpdate/W=FFpanel // helps to ensure listbox is redrawn properly
end

static function ffListbox(STRUCT WMListboxAction &s) : ListBoxControl
	
	if (s.eventcode == 7)
		wave/SDFR=GetPackageDFREF() w_ffstruct
		STRUCT ffstruct ffs
		StructGet ffs w_ffstruct
		ffs.ffcoef[s.row] = str2num(s.listwave[s.row][1])
		s.listwave[s.row][1] = num2str(ffs.ffcoef[s.row])
		StructPut ffs w_ffstruct
	endif
		
	return 0
end

static function ffButtons(STRUCT WMButtonAction &s) : ButtonControl

	if (s.eventcode != 2) // mouseup
		return 0
	elseif (CheckUpdated(1))
		return 0
	endif
	
	// if we have encountered an error that leaves us in a free data
	// folder this will improve the situation for the user
	if (DataFolderRefStatus(GetDataFolderDFR()) != 1)
		SetDataFolder root:
	endif
	
	strswitch(s.ctrlName)
		case "btnSetup" :
			SetUpFit()
			break
		case "btnRead" :
			ReadValuesFromBaselinePanel()
			break
		case "btnDoIt" :
			FastFit()
			break
		case "btnEdit" :
			EditExtensionFunc()
			break
		case "btnHelp" :
			OpenHelp/INT=0/Z ParseFilePath(1, FunctionPath(""), ":", 1, 0) + "Fast Fitting Help.ihf"
			DisplayHelpTopic/K=1/Z "How to use Fast Fitting"
			break
		case "btnInfo" :
			InfoMenu()
			break
	endswitch
	
	return 0
end

static function ffTabs(STRUCT WMTabControlAction &s)
	
	wave/SDFR=GetPackageDFREF() w_ffstruct
	STRUCT ffstruct ffs
	StructGet ffs w_ffstruct
		
	if (s.eventCode == 2) // tab selection
	
		if (CheckUpdated(1))
			return 0
		endif

		ffs.tab = s.tab
		SetFitFunc(ffs)
		ShowTab(ffs)
		StructPut ffs w_ffstruct
	endif
		
	return 0
end

static function ffPopups(STRUCT WMPopupAction &s)
	
	if (s.eventCode != 2) // mouseup
		return 0
	elseif (CheckUpdated(0))
		return 0
	endif
		
	wave/SDFR=GetPackageDFREF() w_ffstruct
	STRUCT ffstruct ffs
	StructGet ffs w_ffstruct
		
	strswitch (s.ctrlName)
		case "popDims" :
			ffs.dims = s.popNum
			ControlInfo/W=$s.win popDataDim
			string strValue = SelectString(ffs.dims - 2, "\"Rows;\"", "\"Rows;Columns;\"", "\"Rows;Columns;Layers;\"")
			ffs.datadim = ffs.dims == 3 ? 2 : 0
			PopupMenu popDataDim, win=$s.win, mode=ffs.datadim+1, value=#strValue
			string options = SelectString(ffs.dims - 2, "DIMS:1", "DIMS:2", "DIMS:3")
			#if IgorVersion() >= 9
			WS_SetListOptionsStr("ffPanel", "lbSelector", options)
			#else
			StructPut ffs w_ffstruct
			WS_UpdateWaveSelectorWidget(ksPanel, ksFilterListbox)
			#endif
			break
		case "popDataDim" :
			ffs.datadim = s.popNum - 1
			if (ffs.datadim > ffs.dims-1)
				ffs.datadim = ffs.dims-1
				PopupMenu popDataDim, win=$s.win, mode=ffs.dims
			endif
			break
		case "popType" :
			ffs.type[ffs.tab] = s.popNum - 1
			ffs.fitfunc = s.popstr
			ResetPanelForType(ffs)
			break
		case "popPlanck" :
			ffs.wavelength = s.popNum
			break
		case "popExtension" :
			if (cmpstr(s.popStr, "Create new template function...") == 0)
				EditExtensionFunc()
				PopupMenu $s.ctrlName, win=$s.win, mode=1
				GetMouse
				MoveWindow/P=Procedure v_left, v_top-400, v_left+800, v_top+400
			endif
			CheckExtFunc()
			break
	endswitch
	
	StructPut ffs w_ffstruct
	return 0
end

static function ffCheckboxes(STRUCT WMCheckboxAction &s)
	
	if (s.eventCode != 2)
		return 0
	elseif (CheckUpdated(1))
		return 0
	endif
	
	DFREF dfr = GetPackageDFREF()
	STRUCT ffstruct ffs
	StructGet ffs dfr:w_ffstruct
	
	strswitch (s.ctrlName)
		case "chkPeak":
			ffs.peak = s.checked
			break
		case "chkNeg_tab2" :
			ffs.options = (ffs.options&~8) | 8*s.checked
			ffs.depth = -ffs.depth
			SetVariable svDepth_tab2, win=$s.win, value=_NUM:ffs.depth
			break
		case "chkHull_tab2" :
			ffs.hull = s.checked
			break
		case "chkBL" :
			ffs.options = (ffs.options&~1) | 1*s.checked
			break
		case "chkSub" :
			ffs.options = (ffs.options&~2) | 2*s.checked
			break
		case "chkOverwrite" :
			ffs.options = (ffs.options&~4) | 4*s.checked
			break
		case "chkCurrentDF" :
			CheckBox chkSourceDF win=$s.win, value=!s.checked
			ffs.options = (ffs.options&~256) | 256*s.checked
			break
		case "chkSourceDF" :
			CheckBox chkCurrentDF win=$s.win, value=!s.checked
			ffs.options = (ffs.options&~256) | 256*(!s.checked)
			break
	endswitch
	StructPut ffs dfr:w_ffstruct
end

static function ffSetvars(STRUCT WMSetVariableAction &s)
	
	STRUCT ffstruct ffs
	
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

		case 8 : // update
		case 1 : // mouseup
			wave/SDFR=GetPackageDFREF() w_ffstruct
			StructGet ffs w_ffstruct
			if (CheckUpdated(1))
				return 0
			endif
			
			strswitch (s.ctrlName)
				case "svBase" :
					ffs.base = s.dval
					break
				case "svPoly" :
					ffs.polyorder = s.dval // ensure that displayed value is an integer
					SetVariable svPoly win=$s.win, value=_NUM:ffs.polyorder
					ResetCoefListwave(ffs)
					break
				case "svSD" :
					#if IgorVersion() < 9
					SetvarPercentageIncrement(s, DefaultIncrement, SlowIncrement, FastIncrement) // resets control value and s.dval
					SetVariable $s.ctrlName win=$s.win, userdata=num2str(s.dval) // keep track of value, however it is changed
					#endif
					ffs.sd = s.dval
					break
				case "svChebOrder" :
					ffs.cheborder = s.dval
					SetVariable $s.ctrlName win=$s.win, value=_NUM:ffs.cheborder
					break
				case "svDepth_tab2" :
					#if IgorVersion() < 9
					SetvarPercentageIncrement(s, DefaultIncrement, SlowIncrement, FastIncrement) // resets control value and s.dval
					SetVariable $s.ctrlName win=$s.win, userdata=num2str(s.dval)
					#endif
					ffs.depth = s.dval
					break
				case "svSmooth_tab2" :
					ffs.smoothing = s.dval
					SetVariable $s.ctrlName win=$s.win,value=_NUM:ffs.smoothing // set to integer value
					break
				case "svBLsuff" :
					if (strlen(s.sval)) // don't allow an empty string value
						ffs.blsuff = s.sval
					endif
					SetVariable $s.ctrlName, win=$s.win, value=_STR:ffs.blsuff
					break
				case "svsubsuff" :
					if (strlen(s.sval))
						ffs.subsuff = s.sval
					endif
					SetVariable $s.ctrlName, win=$s.win, value=_STR:ffs.subsuff
					break
			endswitch
			StructPut ffs w_ffstruct
			// end of events 1 and 8
			break
		case 7 : // begin edit
			wave/SDFR=GetPackageDFREF() w_ffstruct
			StructGet ffs w_ffstruct
			if (CheckUpdated(1))
				return 0
			endif
			if (cmpstr(s.ctrlName, "svXwave") == 0 || cmpstr(s.ctrlName, "svMask_tab0") == 0 )
				CreateBrowser/M Prompt="Select Wave"
				ModifyBrowser/M showWaves=1, showVars=0, showStrs=0
				ModifyBrowser/M ShowInfo=0, showPlot=0
				ModifyBrowser/M clearSelection
				if (strlen(s.sval))
					ModifyBrowser/M selectList=s.sval
				elseif (cmpstr(s.ctrlName, "svMask_tab0") == 0)
					// if the baselines package is initialised this will find the folder containing the mask wave
					ModifyBrowser/M selectList="root:Packages:Baselines:w_base"
					ModifyBrowser/M clearSelection
					ModifyBrowser/M startLine=0 // if we're in root, this has no effect.
//					// if we're in a datafolder below the packages folder in the list, startline has no effect
//					if (datafolderexists("root:Packages:Baselines:"))
//						ModifyBrowser/M startLine=0, find="root:Packages:Baselines:"
//					endif
				endif
				ModifyBrowser/M showModalBrowser
				if (V_Flag == 0)
					// allow manual editing after cancel
//					ControlUpdate/W=$s.win $s.ctrlname
					return 0
				endif
				SetVariable $s.ctrlName win=$s.win, value=_STR:""
				if (ItemsInList(S_BrowserList) == 1)
					wave/Z wSel = $StringFromList(0, S_BrowserList)
					if (WaveExists(wSel))
						SetVariable $s.ctrlName win=$s.win, value=_STR:StringFromList(0, S_BrowserList)
					endif
				endif
				if (cmpstr(s.ctrlName, "svXwave") == 0 )
					ffs.xy = WaveExists(wSel)
					StructPut ffs w_ffstruct
				endif
				ControlUpdate/W=$s.win $s.ctrlname
				break
			endif
	endswitch
	
	return 0
end

static function InfoMenu()
	string cmd = "(Version: " + num2str(GetThisVersion()/100) + ";"
	cmd += "Visit web page;Email the developer;"
	PopupContextualMenu cmd
	if (V_flag == 2)
		BrowseURL /Z "https://www.wavemetrics.com/node/" + num2str(kProjectID)
	elseif (V_flag == 3)
		Make/T/free/N=5 wtFREE = "mail"
		string newline = "\r\n"
//		#ifdef WINDOWS
//		newline = "\n"
//		#endif
		wtFREE[3] = "subject=" + URLEncode(ksShortTitle + " Package for Igor Pro")
		wtFREE[4] = "Type your message here" + newline + newline
		wtFREE[4] += "PROJECT VERSION:" + num2str(GetThisVersion()) + newline
		wtFREE[4] += ReplaceString(";", IgorInfo(3), newline) + newline
		wtFREE[4] = "body=" + URLEncode(wtFREE[4])
		wtFREE[1] = "tony withers"
		wtFREE[2] = "uni-bayreuth de"
		sprintf cmd, "%sto:%s%%%d%s?%s&%s" wtFREE[0], wtFREE[1], 40, wtFREE[2], wtFREE[3], wtFREE[4]
		BrowseURL/Z ReplaceString(" ", cmd, ".")
	endif
end

static function EditExtensionFunc()
	
	ControlInfo/W=ffPanel popExtension
	FUNCREF FastFitExtensionPrototype ExtensionFunc = $S_Value
	string strInfo = FuncRefInfo(ExtensionFunc)
	if (NumberByKey("ISPROTO", strInfo))
		string strFName = "FastFitExtension"
		if (CheckName("FastFitExtension", 1))
			strFName = UniqueName("FastFitExtension", 1, 1)
		endif
		DisplayProcedure/W=Procedure/L=1e9
		string strFuncText="\r\r// This is an example fast-fitting extension function\r"
		strFuncText += "function " + strFName + "(wave wData, wave wBase, wave wSub)\r"
		strFuncText += "	String NewName = GetWavesDataFolder(wData,2) + \"_Norm\"\r"
		strFuncText += "	MatrixOp/O $NewName = wData / wBase\r"
		strFuncText += "	CopyScales wData $NewName\r"
		strFuncText += "	return 0\r"
		strFuncText += "end\r"
		PutScrapText strFuncText
		Execute/P/Q "DoIgorMenu \"Edit\", \"Paste\""
	else
		DisplayProcedure S_Value
	endif
end

static function ReadValuesFromBaselinePanel()
	wave/Z w_struct = root:Packages:Baselines:w_struct
	if (WaveExists(w_struct))
		DFREF dfr = GetPackageDFREF()
		wave/Z w_ffstruct = dfr:w_ffstruct
		STRUCT BLstruct bls
		STRUCT ffstruct ffs
		StructGet bls w_struct
		StructGet ffs w_ffstruct
		// bls2ffs(bls, ffs, tab=ffs.tab) will read values for tab displayed in fast fitting panel
		// bls2ffs(bls, ffs, tab=bls.tab) will reset tab and read values for tab displayed in baselines panel
		// bls2ffs(bls, ffs) will read values for all tabs and reset tab to match baselines panel
		bls2ffs(bls, ffs, tab=bls.tab)
		StructPut ffs w_ffstruct
		ResetPanel(ffs)
	else
		DoAlert 0, "Cannot find baselines GUI\rFirst set up fitting in the baselines panel."
	endif
	wave/Z wMask = root:Packages:Baselines:w_mask
	if (WaveExists(wMask))
		SetVariable svMask_tab0, win=ffPanel, value=_STR:GetWavesDataFolder(wMask, 2)
	endif
end

static function SetUpFit()
	
	if (exists("baselines#initialise") != 6)
		string msg = "The baselines project need to be installed and loaded if you want to set up fitting using the GUI"
		DoAlert 0, msg
		return 0
	endif
	
	int i, numwaves
	#if IgorVersion() >= 9
	string strList = WS_SelectedObjectsList("ffPanel", "lbSelector", includeDFs=0)
	#else
	string strList = WS_SelectedObjectsList("ffPanel", "lbSelector")
	#endif
	numwaves = ItemsInList(strList)
	if (!numwaves)
		DoAlert 0, "No waves selected in fast fitting panel"
		return 0
	endif
	
	wave/SDFR=GetPackageDFREF() w_ffstruct
	STRUCT ffstruct ffs
	StructGet ffs w_ffstruct
	
	ControlInfo/W=ffPanel svXwave
	wave/Z wx = $S_Value
	
	GetMouse
	Display/K=1/W=(v_left+100, v_top-100, v_left+600, v_top+250)	
	DoIgorMenu "control", "retrieve window"
	
	if (ffs.dims > 1)
		wave/Z w = $StringFromList(0, strList)
		Make/O/N=(DimSize(w, ffs.datadim)) $UniqueName("FastFittingSetupWave", 1, 0) /wave=w1D
		SetScale/P x, DimOffset(w, ffs.datadim), DimDelta(w, ffs.datadim), w1D
		switch (ffs.datadim)
			case 0:
				if (ffs.dims == 3)
					w1D = w[p][0][0]
				elseif (ffs.dims == 2)
					w1D = w[p][0]
				else
					abort "Unsupported wave"
				endif
				break
			case 1:
				if (ffs.dims == 3)
					w1D = w[0][p][0]
				elseif (ffs.dims == 2)
					w1D = w[0][p]
				else
					abort "Unsupported wave"
				endif
				break
			case 2:
				w1D = w[0][0][p]
				break
		endswitch

		if (WaveExists(wx))
			AppendToGraph w1D vs wx
		else
			AppendToGraph w1D
		endif
		
	else
		
		for(i=0;i<numwaves;i++)
			wave/Z w = $StringFromList(i, strList)
			if (WaveExists(w))
				if (WaveExists(wx))
					AppendToGraph w vs wx
				else
					AppendToGraph w
				endif
			endif
		endfor
		
	endif
	DoUpdate
	
	string cmd = ""
	sprintf cmd, "baselines#initialise(tab=%d,type=%d)", ffs.tab, ffs.type[ffs.tab]
	Execute cmd
	
	if (ffs.tab == 0)
		wave/Z wMask = root:Packages:Baselines:w_mask
		if (WaveExists(wMask))
			SetVariable svMask_tab0, win=ffPanel, value=_STR:GetWavesDataFolder(wMask, 2)
		endif
	endif
end

static function ShowTab(STRUCT ffstruct &ffs)
	ModifyControlList/Z ControlNameList("ffPanel",";","*_tab0"), win=ffPanel, disable=(ffs.tab!=0)
	ModifyControlList/Z ControlNameList("ffPanel",";","*_tab1"), win=ffPanel, disable=(ffs.tab!=1)
	ModifyControlList/Z ControlNameList("ffPanel",";","*_tab2"), win=ffPanel, disable=(ffs.tab!=2)
		
	string types = ""
	switch (ffs.tab)
		case 0:
			types = ksMaskedTypes
			break
		case 1:
			types = ksManTypes
			break
		case 2:
			types = ksAutoTypes
			break
	endswitch
	PopupMenu popType, win=ffPanel, value=#("\"" + types + "\"")
	PopupMenu popType, win=ffPanel, popmatch=StringFromList(ffs.type[ffs.tab], types)
	
	ResetPanelForType(ffs)
end

// type specific settings - disable controls depending on type selesction
static function ResetPanelForType(STRUCT ffstruct &ffs)
	string panelStr = "ffPanel"
	
	// deal with controls that appear in one tab
	switch (ffs.tab)
		case 0:
		case 1:
			ResetCoefListwave(ffs)
			break
		case 2:
			int isArcHull = (cmpstr(ffs.fitfunc, "arc hull")==0 || cmpstr(ffs.fitfunc, "hull spline")==0)
			SetVariable svDepth_tab2, win=$panelStr, disable=!isArcHull
			CheckBox chkHull_tab2, win=$panelStr, disable=2*isArcHull
			CheckBox chkNeg_tab2, win=$panelStr, disable=0
			SetVariable svSmooth_tab2, win=$panelStr, disable=0
			break
	endswitch
	
	// deal with controls that appear in multiple tabs
	if (cmpstr(ffs.fitfunc, "poly") != 0)
		SetVariable svPoly, win=$panelStr, disable=1
	elseif (ffs.tab == 1) // limit poly order to 5
		ffs.polyorder = min(5, ffs.polyorder)
		SetVariable svPoly, win=$panelStr, disable=0, limits={3, 5, 1}, value=_NUM:ffs.polyorder
	else
		SetVariable svPoly, win=$panelStr, disable=0, limits={3, 20, 1}
	endif
	
	SetVariable svChebOrder, win=$panelStr, disable=(cmpstr((ffs.fitfunc)[0,4], "Cheby")!=0)//, value=_NUM:ffs.cheborder
		
	if (ffs.tab == 0 || ffs.tab == 2)
		strswitch (ffs.fitfunc)
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
		PopupMenu popPlanck, win=$panelStr, disable=(cmpstr(ffs.fitfunc, "Planck") != 0)
		SetVariable svSD, win=$panelStr, disable=(cmpstr(ffs.fitfunc, "spline") != 0)
	else
		CheckBox chkPeak, win=$panelStr, disable=1
		PopupMenu popPlanck, win=$panelStr, disable=1
		SetVariable svSD, win=$panelStr, disable=1
	endif
	
end

static function hookCleanup(STRUCT WMWinHookStruct &s)
	if (s.eventCode == 2)
		// if we have encountered an error that leaves us in a free data
		// folder this will improve the situation for the user
		if (DataFolderRefStatus(GetDataFolderDFR()) != 1)
			SetDataFolder root:
		endif
		DFREF dfr = GetPackageDFREF()
		wave/SDFR=dfr w_ffstruct
		STRUCT ffstruct ffs
		StructGet ffs w_ffstruct
		PrefsSave(ffs)
		KillDataFolder/Z dfr
		return 0
	endif
	if (s.eventCode == 0) // activate
		CheckExtFunc()
	endif
	return 0
end

//static function ResetEditButton()
//	ControlInfo/W=ffPanel popExtension
//	FUNCREF FastFitExtensionPrototype ExtensionFunc = $S_Value
//	Button btnEdit, win=ffPanel, disable = 2*(NumberByKey("ISPROTO", FuncRefInfo(ExtensionFunc)))
//end

//static function ResetEditButton(int funcSelected)
//	Button btnEdit, win=ffPanel, title=selectstring(funcSelected, "New", "Edit")
//end

// returns truth that this procedure file has been updated since initialisation
static function CheckUpdated(int restart)
	int version = GetThisVersion()
	
	wave/SDFR=GetPackageDFREF() w_ffstruct
	STRUCT ffstruct ffs
	StructGet ffs w_ffstruct
	
	if (ffs.version != version)
		if (restart)
			DoAlert 0, "You have updated the fast fitting package since this panel was created.\r\rThe package will restart to update the control panel."
			KillWindow/Z ffPanel
			Initialise()
		else
			DoAlert 0, "You have updated the fast fitting package since this panel was created.\r\rPlease restart to continue."
		endif
		return 1
	endif
	return 0
end

// this is the prototype fast-fitting extension function
function FastFitExtensionPrototype(wave yw, wave base, wave sub)
//function FastFitExtensionPrototype(wave yw, wave base, wave sub, wave coef, STRUCT FastFit#ffstruct &s)
// do not edit this function.
// copy this function into another procedure window and edit to
// create your own extension function.
end

// *** ffs structure ***
// structure definition should not be altered except by extension.
static structure ffstruct
	
	int16 version // this will be set to procedure file version at time of initialisation
	
	int16 options // see PackagePrefs stucture definition for details
	char dims
	char datadim
	
	// information about trace
	int32 datalength
	char xy
		
	char tab
	char type[3]     // selection number for type popup
	char FitFunc[32] // the name of the selected fitting function defined by type[tab]
	
	// preferences
	char blsuff[20]
	char subsuff[20]
		
	float base		// for non-zero baseline, currently no UI control for this
	float depth		// for arc hull
	float sd		// for smoothing spline
	float ffcoef[5]	// manually fixed coefficients
		
	char peak		// use 'peak' functions with no y0 offset
	char polyorder
	char hull		// pre-fit to hull
	char wavelength	// for Planck function
	int16 smoothing	// binomial pre-smoothing iterations
	int16 cheborder	// maximum order of Chebshev polynomial in Chebyshev series
	
	char error
	char exfunc
	
endstructure

// transfers settings from baselines bls structure to fast-fitting ffs structure
static function bls2ffs(STRUCT BLstruct &bls, STRUCT ffstruct &ffs, [int tab])
	
	ffs.version = GetThisVersion()
	
	tab = ParamIsDefault(tab) ? -1 : limit(tab, 0, 2)
	int i
			
 //   ffs.tab     = tab // limit(bls.tab, 0, 2)
    
    switch(tab)
    	case -1:
    		
    		ffs.tab     = limit(bls.tab, 0, 2)
    		
			ffs.type[0] = limit(bls.type[0], 0, ItemsInList(ksMaskedTypes)-1)
			ffs.type[1] = limit(bls.type[1], 0, ItemsInList(ksManTypes)-1)
			ffs.type[2] = limit(bls.type[2], 0, ItemsInList(ksAutoTypes)-1)
			SetFitFunc(ffs)
    		
    		// collect options for all tabs
    		ffs.sd         = bls.sd
    	    ffs.peak       = bls.peak
		    ffs.polyorder  = bls.polyorder
		    ffs.wavelength = bls.wavelength
		    ffs.smoothing  = bls.smoothing
		    ffs.cheborder  = bls.cheborder
		    ffs.depth      = bls.depth
		    ffs.hull       = bls.hull
		    wave coef = GetManCoefsFromBaselines(bls)
			for (i=0;i<5;i++)
				ffs.ffcoef[i] = i < numpnts(coef) ? coef[i] : NaN
			endfor
			// sync negative peaks option for auto baselines
    		ffs.options = (ffs.options & ~8) | (bls.options & 8)    		
    		break
    		
    	case 0:
    		ffs.tab = 0
    		ffs.type[0] = limit(bls.type[0], 0, ItemsInList(ksMaskedTypes)-1)
    		SetFitFunc(ffs)

    		ffs.sd         = bls.sd
    	    ffs.peak       = bls.peak
		    ffs.polyorder  = bls.polyorder
		    ffs.wavelength = bls.wavelength
		    ffs.smoothing  = bls.smoothing
		    ffs.cheborder  = bls.cheborder	
    		
    		break
    	case 1:
    		ffs.tab = 1
    		ffs.type[1] = limit(bls.type[1], 0, ItemsInList(ksManTypes)-1)
    		SetFitFunc(ffs)
    		
    		wave coef = GetManCoefsFromBaselines(bls)
			
			for (i=0;i<5;i++)
				ffs.ffcoef[i] = i < numpnts(coef) ? coef[i] : NaN
			endfor
    		
    		break
    	case 2:
    		ffs.tab = 2
    		ffs.type[2] = limit(bls.type[2], 0, ItemsInList(ksAutoTypes)-1)
    		SetFitFunc(ffs)
    		
    		// sync negative peaks option for auto baselines
    		ffs.options = (ffs.options & ~8) | (bls.options & 8)

    		ffs.depth      = bls.depth
    		ffs.sd         = bls.sd
    	    ffs.peak       = bls.peak
		    ffs.polyorder  = bls.polyorder
		    ffs.hull       = bls.hull
		    ffs.wavelength = bls.wavelength
		    ffs.smoothing  = bls.smoothing
		    ffs.cheborder  = bls.cheborder	
    		break
    endswitch

//    ffs.type[0] = limit(bls.type[0], 0, ItemsInList(ksMaskedTypes)-1)
//    ffs.type[1] = limit(bls.type[1], 0, ItemsInList(ksManTypes)-1)
//    ffs.type[2] = limit(bls.type[2], 0, ItemsInList(ksAutoTypes)-1)
//    SetFitFunc(ffs)
//    
//    // sync negative peaks option for auto baselines
//    ffs.options = (ffs.options & ~8) | (bls.options & 8)
//  
////	don't import other options like overwrite etc
////	ffs.blsuff  = bls.blsuff
////	ffs.subsuff = bls.subsuff
//        
////	ffs.base    = bls.base
//
//
//    ffs.depth   = bls.depth
//    ffs.sd      = bls.sd
	
//	wave coef = GetManCoefsFromBaselines(bls)
//	int i
//	for (i=0;i<5;i++)
//		ffs.ffcoef[i] = i < numpnts(coef) ? coef[i] : NaN
//	endfor
//		
//    ffs.peak       = bls.peak
//    ffs.polyorder  = bls.polyorder
//    ffs.hull       = bls.hull
//    ffs.wavelength = bls.wavelength
//    ffs.smoothing  = bls.smoothing
//    ffs.cheborder  = bls.cheborder
end

static function SetFitFunc(STRUCT ffstruct &ffs)
	switch (ffs.tab)
		case 0:
			ffs.fitfunc = StringFromList(ffs.type[ffs.tab], ksMaskedTypes)
			break
		case 1:
			ffs.fitfunc = StringFromList(ffs.type[ffs.tab], ksManTypes)
			break
		case 2:
			ffs.fitfunc = StringFromList(ffs.type[ffs.tab], ksAutoTypes)
			break
	endswitch
	return 1
end

// ProcedureVersion("") doesn't work for independent modules!
// extract procedure version from this file
static function GetThisVersion()

	variable procVersion
	// try the quick way
	#if exists("ProcedureVersion") == 3
	procVersion = ProcedureVersion("")
	if (procVersion)
		return 100 * procVersion
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

	return 100 * ProcVersion
end


static function/wave GetManCoefsFromBaselines(STRUCT BLstruct &bls)
	
	variable mult = (bls.muloffset.y != 0) ? bls.muloffset.y : 1
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
			break
		case "line":
			w_coef = {y1-x1*(y2-y1)/(x2-x1), (y2-y1)/(x2-x1)}
			break
		case "poly":
			Make/free/D coordinates={{x1,x2,x3,x4,x5},{y1,y2,y3,y4,y5}}
			Redimension/N=(min(5,bls.polyorder),-1) coordinates, w_coef // if we are in a different tab, polyorder could be wrong!
			wave polyCoef = PolyCoefficients(coordinates)
			w_coef = polyCoef
			break
		case "gauss":
			w_coef = {y1, y2-y1, x2, abs(x2-x1)/2}
			break
		case "lor":
			w_coef = {y1, (y2-y1)*(x2-x1)^2/16, x2, (x2-x1)^2/16}
			break
		case "sin":
			x2 = x1 + (x2-x1)/(2*(bls.cycles+1)-1)
			w_coef = {(y1+y2)/2, (y2-y1)/2, Pi/(x2-x1), -Pi/2*(x1+x2)/(x2-x1)}
			break
		case "sigmoid":
			if (x2 >= x1)
				w_coef = {y1, y2-y1, (x1+x2)/2, abs(x1-x2)/10}
			else
				w_coef = {y2, y1-y2, (x1+x2)/2, abs(x2-x1)/10}
			endif
			break
		default:
			w_coef = {NaN}
	endswitch
	return w_coef
end

static structure PackagePrefs
	uint32 version
	char blsuff[20]  // suffix for saved baselines
	char subsuff[20] // suffix for saved baseline-subtracted waves
	char tab         // last used tab
	char type[3]     // selection number for type popup
	int16 options
	// 1: create baseline wave(s), 2: create sub wave(s), 4: overwrite
	// 8: negative peaks, 16: output to current DF

	float base // option for non-zero baseline reference level
	char dims
	char datadim
	char reserved[128 - 4 - 44 - 2 - 4 - 2]
endstructure

// set prefs structure to default values
// default values for bls in prefs button function should match these
static function PrefsSetDefaults(STRUCT PackagePrefs &prefs)
    prefs.version   = kPrefsVersion
    prefs.blsuff    = "_BL"
    prefs.subsuff   = "_sub"
    prefs.tab       = 0
    prefs.type[0]   = 0
    prefs.type[1]   = 0
    prefs.type[2]   = WhichListItem("arc hull", ksAutoTypes)
    prefs.options   = 2
    prefs.base      = 0
    prefs.dims      = 1
    prefs.datadim   = 0
	int i
	for(i=0;i<(128-56);i+=1)
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
	if (prefs.version < 010)
		PrefsSetDefaults(prefs)
	elseif (prefs.version < kPrefsVersion)
		prefs.version = kPrefsVersion
		prefs.dims = limit(prefs.dims, 1, 3)
		prefs.datadim = limit(prefs.datadim, 0, 2)
		// updates go here
	endif
end

static function PrefsSave(STRUCT ffstruct &ffs)
	int version = GetThisVersion()
	if (ffs.version != version)
		// if the definition of ffs has changed, avoid writing to prefs
		return 0
	endif
	
	STRUCT PackagePrefs prefs
	PrefsLoad(prefs)
	
    prefs.tab       = ffs.tab
    prefs.type[0]   = ffs.type[0]
    prefs.type[1]   = ffs.type[1]
    prefs.type[2]   = ffs.type[2]
    prefs.blsuff    = ffs.blsuff
    prefs.subsuff   = ffs.subsuff
    prefs.options   = ffs.options
    prefs.base      = ffs.base
    prefs.dims      = ffs.dims
    prefs.datadim   = ffs.datadim
	SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
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

static function tic()
	variable/G tictoc = StartMSTimer
end

static function toc(STRUCT ffstruct &ffs, wave/Z wMask, variable numSpectra)
		
	NVAR/Z tictoc
	variable ttTime = StopMSTimer(tictoc)
	KillVariables/Z tictoc
	
	string ffunc = ffs.fitfunc
	//if (grepstring("apoly", "(?i)^poly|^cheb"))
	if (grepstring(ffs.fitfunc, "(?i)^poly"))
		ffunc += " " + num2str(ffs.polyorder)
	elseif (grepstring(ffs.fitfunc, "(?i)^cheb"))
		ffunc += " " + num2str(ffs.cheborder)
	endif
	string type = ""
	if (ffs.tab == 0 && waveexists(wMask))
		type = "masked "
	elseif (ffs.tab == 2 && !grepstring(ffs.fitfunc, "hull"))
		type = "iterative "
	endif
	printf "Function = %s, %d %sfits with %d datapoints, Fitting time = %g s\r", ffunc, numSpectra, type, ffs.datalength, ttTime/1e6
	return ttTime
end


// *** wave selector widget with filter ***
// start of code that adds real-time filtering to wave selector widget
// need to set up guides, search and replace module name.

static function InsertWaveSelectorWidget(STRUCT ffstruct &ffs, variable left, variable top, variable width, variable height)
	// wave selector widget with quick filter
	int isWin = 0
	#ifdef WINDOWS
	isWin = 1 // this will be used to fix the positioning of controls for Windows
	#endif
	
	// insert a notebook subwindow to be used for filtering lists
	DefineGuide/W=$ksPanel gV={FL,0.25,FR}
	DefineGuide/W=$ksPanel gV={FL,0.25,FR}
	DefineGuide/W=$ksPanel fgl={FL,left}, fgt={FT,top+height+5}, fgr={FL,left + width - 18}, fgb={fgT, 20},
	NewNotebook/F=1/N=nbFilter/HOST=$ksPanel/W=(10,500,5200,1000)/FG=(fgl,fgt,fgr,fgb)/OPTS=3
	Notebook $ksPanel+"#nbFilter" fSize=12-3*isWin, showRuler=0
	Notebook $ksPanel+"#nbFilter" spacing={2, 0, 0}
	Notebook $ksPanel+"#nbFilter" margins={0,0,1000}
	SetWindow $ksPanel+"#nbFilter" activeChildFrame=0
	ClearText(1) // sets notebook to its default appearance
	SetActiveSubwindow $ksPanel
	
	// make a Button for clearing text in notebook subwindow
	Button ButtonClear, win=$ksPanel, pos={left+width-16,top+height+7}, size={15,15}, title=""
	Button ButtonClear, win=$ksPanel, Picture=FastFit#ClearTextPicture, Proc=FastFit#filterButtonProc, disable=1
	
	// insert a listbox for wave selector widget
	// filter will apply to this listbox
	ListBox $ksFilterListbox, win=$ksPanel, pos={left,top}, size={width,height}, focusRing=0
	MakeListIntoWaveSelector(ksPanel, ksFilterListbox, content=WMWS_Waves, selectionmode=WMWS_SelectionNonContiguous, nameFilterProc="FastFit#FilterForWaveSelector")
	WS_SetNotificationProc(ksPanel, ksFilterListbox, "FastFit#WS_NotificationProc")
	WS_OpenAFolderFully(ksPanel, ksFilterListbox, GetDataFolder(1))
	
	string options = SelectString(ffs.dims - 2, "DIMS:1", "DIMS:2", "DIMS:3")
	#if IgorVersion() >= 9
	WS_SetListOptionsStr(ksPanel, ksFilterListbox, options)
	#endif

	PopupMenu popSortOrder, win=$ksPanel, pos={left,top+height+30}, size={100,30}, mode=1, title="Sort order"
	MakePopupIntoWaveSelectorSort(ksPanel, ksFilterListbox, "popSortOrder")
		
	SetWindow $ksPanel hook(hFilterNB)=FastFit#hookFilterNB
end

// function used by WaveSelectorWidget
static function FilterForWaveSelector(string aName, variable contents)
	
	#if IgorVersion() < 9
	
	wave/Z w = $aName
	if (!waveexists(w))
		return 0
	endif
	
	DFREF dfr = GetPackageDFREF()
	STRUCT ffstruct ffs
	StructGet ffs dfr:w_ffstruct
	
	if (wavedims(w) != ffs.dims)
		return 0
	endif
	
	#endif
	
	
	string nb = ksPanel + "#nbFilter"
	string strFilter = GetUserData(nb, "", "filter")
	
	string leafName = ParseFilePath(0, aName, ":", 1, 0)
	int vFilter = 0, err = 0
	vFilter = GrepString(leafName, "(?i)" + strFilter); err = GetRTError(1)
	// on RTE GrepString returns an error code, so vFilter will be non-zero
	return vFilter
end

static function ClearText(int doIt)
	if (doIt) // clear filter widget
		string nb = ksPanel + "#nbFilter"
		Notebook $nb selection={startOfFile,endofFile}, textRGB=(50000,50000,50000), text="Filter"
		Notebook $nb selection={startOfFile,startOfFile}
		Button buttonClear, win=$ksPanel, disable=3
		SetWindow $nb UserData(filter) = ""
	endif
end

// intercept and deal with keyboard events in notebook subwindow
static function hookFilterNB(STRUCT WMWinHookStruct &s)
	
	if (s.eventcode == 4) // mousemoved
		return 0
	endif
	
	string nb = ksPanel + "#nbFilter"
		
	GetWindow/Z $ksPanel activeSW
	if (cmpstr(s_value, nb))
		return 0
	endif
	
	if (s.eventCode == 22 && cmpstr(s.WinName, nb)==0) // don't allow scrolling
		return 1
	endif
	
	string strFilter = GetUserData(nb, "", "filter")
	int vLength = strlen(strFilter)
	
	if (s.eventcode==3 && vLength==0) // mousedown
		return 1 // don't allow mousedown when we have 'filter' displayed in nb
	endif
		
	if (s.eventcode == 10) // menu
		strswitch (s.menuItem)
			case "Paste":
				string strScrap = GetScrapText()
				strScrap = ReplaceString("\r", strScrap, "")
				strScrap = ReplaceString("\n", strScrap, "")
				strScrap = ReplaceString("\t", strScrap, "")
				
				GetSelection Notebook, $nb, 1 // get current position in notebook
				if(vLength == 0)
					Notebook $nb selection={startOfFile,endOfFile}, text=strScrap
				else
					Notebook $nb selection={(0,V_startPos),(0,V_endPos)}, text=strScrap
				endif
				vLength += strlen(strScrap) - abs(V_endPos - V_startPos)
				s.eventcode = 11
				// pretend this was a keyboard event to allow execution to continue
				break
			case "Cut":
				GetSelection Notebook, $nb, 3 // get current position in notebook
				PutScrapText s_selection
				Notebook $nb selection={(0,V_startPos),(0,V_endPos)}, text=""
				vLength -= strlen(s_selection)
				s.eventcode = 11
				break
			case "Clear":
				GetSelection Notebook, $nb, 3 // get current position in notebook
				Notebook $nb selection={(0,V_startPos),(0,V_endPos)}, text="" // clear text
				vLength -= strlen(s_selection)
				s.eventcode = 11
				break
		endswitch
		Button buttonClear, win=$ksPanel, disable=3*(vLength == 0)
		ClearText((vLength == 0))
	endif
				
	if (s.eventcode!=11)
		return 0
	endif
	
	if (vLength == 0) // Remove "Filter" text before starting to deal with keyboard activity
		Notebook $nb selection={startOfFile,endofFile}, text=""
	endif
	
	// deal with some non-printing characters
	switch(s.keycode)
		case 9:	// tab: jump to end
		case 3:
		case 13: // enter or return: jump to end
			Notebook $nb selection={endOfFile,endofFile}
			break
		case 28: // left arrow
		case 29: // right arrow
			ClearText((vLength == 0)); return (vLength == 0)
		case 8:
		case 127: // delete or forward delete
			GetSelection Notebook, $nb, 1
			if(V_startPos == V_endPos)
				V_startPos -= (s.keycode == 8)
				V_endPos += (s.keycode == 127)
			endif
			V_startPos = min(vLength,V_startPos); V_endPos = min(vLength,V_endPos)
			V_startPos = max(0, V_startPos); V_endPos = max(0, V_endPos)
			Notebook $nb selection={(0,V_startPos),(0,V_endPos)}, text=""
			vLength -= abs(V_endPos - V_startPos)
			break
	endswitch
		
	// find and save current position
	GetSelection Notebook, $nb, 1
	int selEnd = V_endPos
		
	if (strlen(s.keyText) == 1) // a one-byte printing character
		// insert character into current selection
		Notebook $nb text=s.keyText, textRGB=(0,0,0)
		vLength += 1 - abs(V_endPos - V_startPos)
		// find out where we want to leave cursor
		GetSelection Notebook, $nb, 1
		selEnd = V_endPos
	endif
	
	// select and format text
	Notebook $nb selection={startOfFile,endOfFile}, textRGB=(0,0,0)
	// put text into global filter string
	GetSelection Notebook, $nb, 3
	strFilter = s_selection
	Notebook $nb selection={(0,selEnd),(0,selEnd)}, findText={"",1}
	
	Button buttonClear, win=$ksPanel, disable=3*(vLength==0)
	ClearText((vLength == 0))
		
	SetWindow $nb UserData(filter) = strFilter
	
	int savlen = strlen(WS_SelectedObjectsList(ksPanel, ksFilterListbox))
	WS_UpdateWaveSelectorWidget(ksPanel, ksFilterListbox)
			
	return 1 // tell Igor we've handled all keyboard events
end

static function FilterButtonProc(STRUCT WMButtonAction &s)
	if (s.eventCode!=2)
		return 0
	endif
	ClearText(1)
	WS_UpdateWaveSelectorWidget(ksPanel, ksFilterListbox)
	return 0
end

// PNG: width= 90, height= 30
static Picture ClearTextPicture
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"&!!!!?#R18/!3BT8GQ7^D&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"$&q@5u_NKm@(_/W^%DU?TFO*%Pm('G1+?)0-OWfgsSqYDhC]>ST`Z)0"D)K8@Ncp@>C,GnA#([A
	Jb0q`hu`4_P;#bpi`?T]j@medQ0%eKjbh8pO.^'LcCD,L*6P)3#odh%+r"J\$n:)LVlTrTIOm/oL'r
	#E&ce=k6Fiu8aXm1/:;hm?p#L^qI6J;D8?ZBMB_D14&ANkg9GMLR*Xs"/?@4VWUdJ,1MBB0[bECn33
	KZ1__A<"/u9(o<Sf@<$^stNom5GmA@5SIJ$^\D=(p8G;&!HNh)6lgYLfW6>#jE3aT_'W?L>Xr73'A#
	m<7:2<I)2%%Jk$'i-7@>Ml+rPk4?-&B7ph6*MjH9&DV+Uo=D(4f6)f(Z9"SdCXSlj^V?0?8][X1#pG
	[0-Dbk^rVg[Rc^PBH/8U_8QFCWdi&3#DT?k^_gU>S_]F^9g'7.>5F'hcYV%X?$[g4KPRF0=NW^$Z(L
	G'1aoAKLpqS!ei0kB29iHZJgJ(_`LbUX%/C@J6!+"mVIs6V)A,gbdt$K*g_X+Um(2\?XI=m'*tR%i"
	,kQIh51]UETI+HBA)DV:t/sl4<N*#^^=N.<B%00/$P>lNVlic"'Jc$p^ou^SLA\BS?`$Jla/$38;!#
	Q+K;T6T_?\3*d?$+27Ri'PYY-u]-gEMR^<d.ElNUY$#A@tX-ULd\IU&bfX]^T)a;<u7HgR!i2]GBpt
	SiZ1;JHl$jf3!k*jJlX$(ZroR:&!&8D[<-`g,)N96+6gSFVi$$Gr%h:1ioG%bZgmgbcp;2_&rF/[l"
	Qr^V@O-"j&UsEk)HgI'9`W31Wh"3^O,KrI/W'chm_@T!!^1"Y*Hknod`FiW&N@PIluYQdKILa)RK=W
	Ub4(Y)ao_5hG\K-+^73&AnBNQ+'D,6!KY/`F@6)`,V<qS#*-t?,F98]@h"8Y7Kj.%``Q=h4.L(m=Nd
	,%6Vs`ptRkJNBdbpk]$\>hR4"[5SF8$^:q=W([+TB`,%?4h7'ET[Y6F!KJ3fH"9BpILuUI#GoI.rl(
	_DAn[OiS_GkcL7QT`\p%Sos;F.W#_'g]3!!!!j78?7R6=>B
	ASCII85End
end

// end of filter code


// *** copies of functions from baselines.ipf ***

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

// convert wavelength units to nm for planck function
threadsafe static function wl2nm(STRUCT ffstruct &ffs, variable wl)
	switch (ffs.wavelength)
		case 2: // micron
			return wl * 1000
		case 3: // wavenumber
			return 1e7 / wl
		case 4: // angstrom
			return wl / 10
	endswitch
	return wl
end

// returns, as a free wave, the coefficients for the polynomial that
// passes through the unique points in the 2D coordinates wave
threadsafe static function/wave PolyCoefficients(wave coordinates)
	int numP = DimSize(coordinates, 0)

	if (numP > 5)
		Make/free/N=(numP,numP)/D MA
		MA = coordinates[p][0]^q
		Make/free/N=(numP)/D w = coordinates[p][1]
		variable error
		MatrixLinearSolve/O MA, w; error = GetRTError(1)
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

#if exists("baselines#initialise") != 6

// structure definition should not be altered except by extension.
// not static so that determined users can access internal parameters.
static structure blstruct
	
	char trace[255] // trace name
	char Graph[255] // graph name
	char tab
	char type[4]   // selection number for type popup
	char multi     // set this for all-in-one fitting - a temporary flag not a setting, see fitall below
		
	// information about trace
	int32 datalength
	STRUCT coordinates offset
	char xy
	
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
	int16 options // see PackagePrefs stucture definition in baselines.ipf for details
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
#endif

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

// *** proc pics ***

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