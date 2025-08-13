#pragma TextEncoding = "UTF-8"
#pragma rtGlobals = 3
#pragma ModuleName = ATH_Range
#pragma IgorVersion = 9
#pragma version = 1.2

/// *** The present code is a modified version of SIDAM project
/// see https://github.com/yuksk/SIDAM ***

// ------------------------------------------------------- //
// Copyright (c) 2024 Evangelos Golias.
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

// v1.2 Igor Pro 10 ready
#include <WMImageInfo>

StrConstant PRESTR_CMD = "•"			//	prefix character for regular commands in the history window
StrConstant PRESTR_CAUTION = "** "	//	prefix characters for cautions in the history window

StrConstant SIDAM_DF = "root:Packages:ATH_DataFolder"
Static Constant DEFALUT_BINS = 64			//	number of bins

//@
//	Set a range of a color scale used for a image(s).
//
//	## Parameters
//	grfName : string, default `WinName(0,1,1)`
//		The name of window.
//	imgList : string, default `ImageNameList(grfName,";")`
//		The list of images.
//	zminmode, zmaxmode : int {0 -- 4}, default 1
//		How to set the minimum and maximum of z range.
//		* 0: auto. Use the minimum or the maximum of the current area and plane.
// 			This is equivalent to `ModifyImage ctabAutoscale=3`.
//		* 1: fix. Use a fixed value. The value is given by `zmin` and `zmax`.
//		* 2: sigma. Use _n_&#963; below (`zminmode`) or above (`zmaxmode`) the average,
//			where &#963; is the standard deviation. The average and the standard deviation
//			are calculated for the current area and plane. _n_ is given by `zmin` and `zmax`.
//		* 3: cut. Use the value corresponding to _x_% of the cumulative histogram which
//			is calculated for the current area and plane. _x_ is given by `zmin` and `zmax`.
//		* 4: logsigma. Similar to `sigma`, but use logarithmic values of an image to
//			calculate the average and the standard deviation. This option is useful when
//			values in an image span in a wide range over a few orders like an FFT image.
//	zmin, zmax : variable
//		The minimum and maximum value of the range.
//		The meaning of value depends on `zminmode` and `zmaxmode`.
//@
static Function SIDAMRange([String grfName, String imgList, Variable zmin,
	Variable zmax, int zminmode, int zmaxmode])

	STRUCT paramStruct s
	s.grfName = SelectString(ParamIsDefault(grfName), grfName, WinName(0,1,1))
	s.imgList = SelectString(ParamIsDefault(imgList), imgList, ImageNameList(s.grfName,";"))
	s.zmin = ParamIsDefault(zmin) ? inf : zmin
	s.zmax = ParamIsDefault(zmax) ? inf : zmax
	s.zminmode = ParamIsDefault(zminmode) ? 1 : zminmode
	s.zmaxmode = ParamIsDefault(zmaxmode) ? 1 : zmaxmode

	if (validate(s))
		print s.errMsg
		return 1
	elseif (ParamIsDefault(zmin) && ParamIsDefault(zmax))
		pnl(s.grfName)
		return 0
	endif

	setZmodeValue(s.grfName, s.imgList, "m0", s.zminmode)
	setZmodeValue(s.grfName, s.imgList, "v0", s.zmin)
	setZmodeValue(s.grfName, s.imgList, "m1", s.zmaxmode)
	setZmodeValue(s.grfName, s.imgList, "v1", s.zmax)
	updateZRange(s.grfName)

	if (s.zminmode >= 2 || s.zmaxmode >= 2)
		SetWindow $s.grfName hook(SIDAMRange)=ATH_Range#pnlHookParent
	endif

	if (canZmodeBeDeleted(s.grfName))
		deleteZmodeValues(s.grfName)
		SetWindow $s.grfName hook(SIDAMRange)=$""
	endif
End

Static Function validate(STRUCT paramStruct &s)

	s.errMsg = PRESTR_CAUTION + "SIDAMRange gave error: "

	if (!strlen(s.grfName))
		s.errMsg += "graph not found."
		return 1
	elseif (!SIDAMWindowExists(s.grfName))
		s.errMsg += "an window named \"" + s.grfName + "\" is not found."
		return 1
	elseif (!strlen(ImageNameList(s.grfName,";")))
		s.errMsg += s.grfName + " has no image."
		return 1
	endif

	String list = ImageNameList(s.grfName,";")
	int i, n
	for (i = 0, n = ItemsInList(s.imgList); i < n; i++)
		if (WhichListItem(StringFromList(i,s.imgList),list) < 0)
			s.errMsg += "an image named \"" + StringFromList(i,s.imgList) + "\" is not found."
			return 1
		endif
	endfor

	if (numtype(s.zmin) == 1 && numtype(s.zmax) != 1)
		s.errMsg += "zmin must be given."
		return 1
	endif

	if (numtype(s.zmax) == 1 && numtype(s.zmin) != 1)
		s.errMsg += "zmax must be given."
		return 1
	endif

	if (s.zminmode < 0 || s.zminmode > 4)
		s.errMsg += "zminmode must be an integer between 0 and 4."
		return 1
	endif

	if (s.zmaxmode < 0 || s.zmaxmode > 4)
		s.errMsg += "zmaxmode must be an integer between 0 and 4."
		return 1
	endif

	return 0
End

Static Structure paramStruct
	String	grfName
	String	imgList
	Variable zmin
	Variable zmax
	uchar zminmode
	uchar zmaxmode
	String	errMsg
EndStructure

//******************************************************************************
//	Set first z and last z to an image
//	"auto" if zmin=NaN or zmax=NaN
//******************************************************************************
Static Function applyZRange(String grfName, String imgName, Variable zmin, Variable zmax)

	String ctab = SIDAM_ColorTableForImage(grfName, imgName)
	Variable rev = WM_ColorTableReversed(grfName, imgName)
	if (numtype(zmin)==2 && numtype(zmax)==2)
		ModifyImage/W=$grfName $imgName ctab={*,*,$ctab,rev}, ctabAutoscale=3
	elseif (numtype(zmin)==2)
		ModifyImage/W=$grfName $imgName ctab={*,zmax,$ctab,rev}, ctabAutoscale=3
	elseif (numtype(zmax)==2)
		ModifyImage/W=$grfName $imgName ctab={zmin,*,$ctab,rev}, ctabAutoscale=3
	else
		ModifyImage/W=$grfName $imgName ctab={zmin,zmax,$ctab,rev}
	endif
	DoUpdate/W=$grfName
End

//==============================================================================
//	Panel
//==============================================================================
Static Constant CTRLHEIGHT = 200
Static Constant BOTTOMHEIGHT = 30
Static Constant PNLHEIGHT = 363
Static Constant PNLWIDTH = 262

Static Constant BINS = 48		//	Number of bins of a histogram
Static StrConstant HIST = "ATH_Range_hist"			//	Name of a histogram wave
Static StrConstant HISTCLR = "ATH_Range_histclr"	//	Name of a color histogram wave
Static StrConstant PNAME = "ATH_Range"

Static Function pnl(String grfName)
	String targetWin = StringFromList(0, grfName, "#")
	if (SIDAMWindowExists(targetWin+"#"+PNAME))
		return 0
	endif

	//	Acquire the z range of the top image
	String imgName = StringFromList(0,ImageNameList(grfName,";"))
	Variable zmin, zmax
	SIDAM_GetColorTableMinMax(grfName, imgName, zmin, zmax)

	String dfTmp = pnlInit(grfName, imgName, zmin, zmax)
	NewPanel/EXT=0/HOST=$targetWin/W=(0,0,PNLWIDTH,PNLHEIGHT)/N=$PNAME
	String pnlName = targetWin + "#" + PNAME
	
	//	Controls
	PopupMenu imageP title="image",pos={3,7},size={218,19},win=$pnlName
	PopupMenu imageP bodyWidth=180,fsize=13,win=$pnlName
	
	GroupBox zminG pos={4,30},size={128,141},win=$pnlName
	GroupBox zminG title="first Z",fColor=(65280,32768,32768),fsize=13,win=$pnlName

	CheckBox zminC      pos={9,53}, title="", win=$pnlName
	CheckBox zminAutoC  pos={9,76}, title="auto", win=$pnlName
	CheckBox zminSigmaC pos={9,99}, title="\u03bc +", win=$pnlName
	CheckBox zminCutC   pos={9,122},title="cut", win=$pnlName
	CheckBox zminLogsigmaC   pos={9,145}, title="log", win=$pnlName
	
	SetVariable zminV      pos={27,51},format="%g",win=$pnlName
	SetVariable zminSigmaV pos={47,98},value=_NUM:-3,limits={-inf,inf,0.1},win=$pnlName
	SetVariable zminCutV   pos={47,121},value=_NUM:0.5,limits={0,100,0.1},win=$pnlName
	SetVariable zminLogsigmaV pos={47,144},value=_NUM:-3,limits={-inf,inf,0.1},win=$pnlName
	
	TitleBox zminSigmaT pos={111,99}, title="\u03c3",win=$pnlName
	TitleBox zminCutT   pos={111,122},title="%",win=$pnlName
	TitleBox zminLogigmaT pos={111,145}, title="\u03c3",win=$pnlName

	GroupBox zmaxG pos={134,30},size={128,141},win=$pnlName
	GroupBox zmaxG title="last Z",fColor=(32768,40704,65280),fsize=13,win=$pnlName

	CheckBox zmaxC      pos={139,53}, title="", win=$pnlName
	CheckBox zmaxAutoC  pos={139,76}, title="auto",win=$pnlName
	CheckBox zmaxSigmaC pos={139,99}, title="\u03bc +",win=$pnlName
	CheckBox zmaxCutC   pos={139,122}, title="cut", win=$pnlName
	CheckBox zmaxLogsigmaC   pos={139,145}, title="log", win=$pnlName

	SetVariable zmaxV      pos={157,51},format="%g",win=$pnlName
	SetVariable zmaxSigmaV pos={177,98},value=_NUM:3,limits={-inf,inf,0.1},win=$pnlName
	SetVariable zmaxCutV   pos={177,121},value=_NUM:99.5,limits={0,100,0.1},win=$pnlName
	SetVariable zmaxLogsigmaV pos={177,144},value=_NUM:3,limits={-inf,inf,0.1},win=$pnlName
	
	TitleBox zmaxSigmaT pos={241,99},title="\u03c3",win=$pnlName
	TitleBox zmaxCutT   pos={241,122},title="%",win=$pnlName
	TitleBox zmaxLogigmaT pos={241,145},title="\u03c3",win=$pnlName

	TitleBox adjustT pos={5,(CTRLHEIGHT-23)},title="hist. range",fsize = 13,win=$pnlName
	Button presentRngB pos={90,(CTRLHEIGHT-25)}, size={100,20}, title="first Z - last Z", win=$pnlName
	Button fullRngB pos={200,(CTRLHEIGHT-25)}, size={45,20}, title="full", win=$pnlName
	
	Button doRngB pos={5,(PNLHEIGHT-25)}, size={65,20}, title="Apply", fcolor=(26205,52428,0), win=$pnlName
	Button cancelRngB pos={(PNLWIDTH-70),(PNLHEIGHT-25)}, size={65,20},win=$pnlName
	Button cancelRngB title="Cancel", fcolor=(65535,0,0),win=$pnlName
	Button refreshRngB pos={(PNLWIDTH-165),(PNLHEIGHT-25)},title="Refresh",win=$pnlName
	Button refreshRngB size={65,20}, fcolor=(65535,43690,0),win=$pnlName
	Button reverseColorsRngB, pos={230,6},size={25,20},title="Rc",fsize=13,win=$pnlName
	
	ModifyControlList ControlNameList(pnlName,";","zm*C") mode=1, proc=ATH_Range#pnlCheck, fsize=13, win=$pnlName
	ModifyControlList ControlNameList(pnlName,";","zm*V") size={60,18}, bodyWidth=60,proc=ATH_Range#pnlSetVar,fsize=13,win=$pnlName
	ModifyControlList "zminV;zmaxV" size={100,18}, bodyWidth=100, win=$pnlName
	ModifyControlList ControlNameList(pnlName,";","*T") frame=0,win=$pnlName
	ModifyControlList ControlNameList(pnlName,";","*RngB") proc=ATH_Range#pnlButton,win=$pnlName
	ModifyControlList ControlNameList(pnlName,";","*") focusRing=0, win=$pnlName

	// add some color to indicate a Reversed ColorMap
	
	string matchPattern = "(.)([0-9])}$", dump, cmapSwitchStr
	SplitString/E=matchPattern StringByKey("RECREATION",Imageinfo(targetWin,imgName,0)), dump, cmapSwitchStr
	
	if(str2num(cmapSwitchStr))
		Button reverseColorsRngB, fcolor=(0,65535,0),win=$pnlName
	else
		Button reverseColorsRngB, fcolor=(65535,0,0),win=$pnlName
	endif
	//
	
	//	Histogram
	DefineGuide/W=$pnlName SIDAMFT={FT, CTRLHEIGHT}
	DefineGuide/W=$pnlName SIDAMFB={FB, -BOTTOMHEIGHT}
	Display/FG=(FL,SIDAMFT,FR,SIDAMFB)/HOST=$pnlName
	String subGrfName = pnlName + "#" + S_name

	AppendToGraph/W=$subGrfName $(dfTmp+HIST)	//	One is for the color
	AppendToGraph/W=$subGrfName $(dfTmp+HIST)	//	The other is for the outline
	Cursor/C=(65280,32768,32768)/F/H=2/N=1/S=2/T=2/W=$subGrfName I $HIST zmin, 0
	Cursor/C=(32768,40704,65280)/F/H=2/N=1/S=2/T=2/W=$subGrfName J $HIST zmax, 0

	NewFreeAxis/B logAxis
	ModifyFreeAxis/W=$subGrfName logAxis, master=bottom, hook=ATH_Range#pnlAxHook
	
	ModifyGraph/W=$subGrfName margin(top)=8, margin(right)=12, margin(bottom)=32, margin(left)=40, gfSize=12
	ModifyGraph/W=$subGrfName tick=2, standoff=1, btlen=5, mirror=1, lblMargin=0, lblPosMode=1
	ModifyGraph/W=$subGrfName mode=6, lstyle=1, rgb=(0,0,0)
	ModifyGraph/W=$subGrfName prescaleExp(left)=2
	ModifyGraph/W=$subGrfName freePos(logAxis)={0,kwFraction}, log(logAxis)=1
	// JW WaveMetrics suppress any UI mouse clicks except the cursor clicks
	ModifyGraph/W=$subGrfName UIControl=(1+4+8+16+32+64+128+256+512+1024+2048)		// Leaves out 2 for the bit that disables clicks on the cursors
	Label/W=$subGrfName left "Intensity (arb. u.)"
	Label/W=$subGrfName bottom "z (\u\M)"
	Label/W=$subGrfName logAxis "z (\u\M)"
	
	SetActiveSubwindow ##

	//	Hook functions
	//	These must come after displaying the cursors because the hook function gives an error
	//	if the cursors are not shown
	SetWindow $grfName hook(ATH_RangeHook)=ATH_Range#pnlHookParent
	SetWindow $pnlName hook(self)=ATH_Range#pnlHook
	SetWindow $pnlName userData(grf)=grfName
	SetWindow $pnlName userData(dfTmp)=dfTmp
	SetWindow $pnlName userData(subGrfName)=subGrfName, activeChildFrame=0

	//	Save the initial z mode information to revert
	initializeZmodeValue(grfName)
	SetWindow $pnlName userData($MODEKEY)=GetUserData(grfName,"",MODEKEY)

	//	Items which must be here at the last after all things are done.
	String cmdStr = "PopupMenu imageP proc=ATH_Range#pnlPopup,mode=1,value="
	sprintf cmdStr, "%s#\"ImageNameList(\\\"%s\\\", \\\";\\\")\",win=%s", cmdStr, grfName, pnlName
	Execute/Q cmdStr
	resetPnlCtrls(pnlName)

	updatePnlAxis(pnlName)
	
	//SIDAMApplyHelp(pnlName, "[SIDAM_Range]") // EG

	SetActiveSubwindow $grfName
End

Static Function/S pnlInit(String grfName, String imgName, Variable zmin, Variable zmax)
	String dfTmp = SIDAMNewDF(StringFromList(0, grfName, "#"),"Range")
	Wave w0 = SIDAMImageNameToWaveRef(grfName, imgName=imgName, displayed=1)
	if (SIDAM_ColorTableLog(grfName, imgName))
		MatrixOP/FREE w = log(w0)
	else
		Wave w = w0
	endif

	Variable zmargin = (zmax - zmin) * 0.05
	Duplicate SIDAMHistogram(w, startz=zmin-zmargin, endz=zmax+zmargin, \
		bins=BINS, grfName=grfName) $(dfTmp+HIST)/WAVE=hw
	Duplicate hw $(dfTmp+HISTCLR)/WAVE=rangew
	rangew = x

	return dfTmp
End

//******************************************************************************
//	Hook functions
//******************************************************************************
//-------------------------------------------------------------
//	Hook function for the parent window
//
//	This is the function adjusting the range when a graph is
//	modified like changing the axis range or the layer.
//	This function works when
//	(1) the z range is changed from the Igor default dialog
//	(2) the layer of a 3D wave is changed
//	(3) the wave of an image is changed
//	(4) an image is removed
//-------------------------------------------------------------
Static Function pnlHookParent(STRUCT WMWinHookStruct &s)

	if (s.eventCode != 8)	//	modified only 
		return 0
	endif

	//	When the z range is changed from the panel, this function should not work.
	//	Actually, to prevent this function from working, an userdata "pauseHook"
	//	is set when the z range is changed from the panel. In this case, delete
	//	the userdata and finish.
	if (strlen(GetUserData(s.winName, "", "pauseHook")))
		SetWindow $s.winName userData(pauseHook)=""
		return 0
	endif

	String imgList = ImageNameList(s.winName,";"), imgName
	Variable recorded, present
	int i

	for (i = 0; i < ItemsInList(imgList); i++)
		imgName = StringFromList(i,imgList)

		//	(1) Check if the z range is changed from the Igor default dialog.
		//		If changed, update the z mode values to reflect the present status.
		pnlHookParentIgorDialog(s.winName, imgName)

		//	(2) Check if the layer is changed.
		//		If changed, update the z mode value to reflect the present layer
		pnlHookParentLayerChanged(s.winName, imgName)

		//	(3) Check if the wave is changed.
		//		If changed, update the z mode value to reflect the present modtime
		pnlHookParentWaveModified(s.winName, imgName)
	endfor

	//	(4) in case a image(s) is removed. If no image has been removed, do nothing.
	cleanZmodeValue(s.winName)

	updateZRange(s.winName, pause=1)

	//	When the panel is shown, reflect the present z mode values to the panel.
	//	(If not shown, do nothing)
	int isPanelShown = pnlHookParentUpdatePanel(s.winName)

	//	When the panel is not shown, check the z mode values.
	//	If they are 0 or 1 for all images, this hook function is no longer necessary.
	if(!isPanelShown && canZmodeBeDeleted(s.winName))
		deleteZmodeValues(s.winName)
		SetWindow $s.winName hook(SIDAMRange)=$""
	endif

	SetWindow $s.winName userData(pauseHook)=""
	return 0
End

Static Function pnlHookParentIgorDialog(String grfName, String imgName)

	//	Recorded z range
	Variable z0 = getZmodeValue(grfName, imgName, "z0")
	Variable z1 = getZmodeValue(grfName, imgName, "z1")

	//	Present z range
	Variable zmin, zmax
	SIDAM_GetColorTableMinMax(grfName, imgName, zmin, zmax) // Call be reference zmin, zmax. See SIDAM_GetColorTableMinMax definition.

	//	If "auto" is different, or the values are different,
	//	the z range has been modified from the Igor default dialog
	int isRecFirstAuto = getZmodeValue(grfName, imgName, "m0")==0
	int isRecLastAuto  = getZmodeValue(grfName, imgName, "m1")==0
	int isFirstAuto = isZAuto(grfname,imgName,0)
	int isLastAuto = isZAuto(grfname,imgName,1)
	int needUpdateFirst = (isRecFirstAuto %^ isFirstAuto) || (abs(zmin-z0) > 1e-13)
	int needUpdateLast  = (isRecLastAuto  %^ isLastAuto)  || (abs(zmax-z1) > 1e-13)

	if (needUpdateFirst)
		setZmodeValue(grfName, imgName, "m0", !isFirstAuto)
		setZmodeValue(grfName, imgName, "z0", zmin)
	endif

	if (needUpdateLast)
		setZmodeValue(grfName, imgName, "m1", !isLastAuto)
		setZmodeValue(grfName, imgName, "z1", zmax)
	endif

	return (needUpdateFirst || needUpdateLast)
End

//	Return if the z range is auto or not
//	minormax 0 for min, 1 for max
Static Function isZAuto(String grfName, String imgName, int minormax)
	String ctabInfo = WM_ImageColorTabInfo(grfName,imgName)
	return strlen(ctabInfo) ? Stringmatch("*", StringFromList(minormax,ctabInfo,",")) : 0
End

Static Function pnlHookParentLayerChanged(String grfName, String imgName)

	Variable recorded = getZmodeValue(grfName, imgName, "layer")	//	nan for no record
	Variable present = SIDAMGetLayerIndex(grfName)					//	nan for 2D
	if (!numtype(present) && recorded!=present)
		setZmodeValue(grfName, imgName, "layer", present)
		return 1
	else
		return 0
	endif
End

Static Function pnlHookParentWaveModified(String grfName, String imgName)
	Variable recorded = getZmodeValue(grfName, imgName, "modtime")		//	nan for no record
	Variable present = NumberByKey("MODTIME",WaveInfo(ImageNameToWaveRef(grfName,imgName),0))
	if (recorded != present)
		setZmodeValue(grfName, imgName, "modtime", present)
		return 1
	else
		return 0
	endif
End

Static Function pnlHookParentUpdatePanel(String grfName)

	String pnlName = grfName + "#" + PNAME
	if (!SIDAMWindowExists(pnlName))
		return 0
	endif

	//	If the wave selected in the panel is removed from the graph,
	//	select a new wave in the popupmenu.
	ControlInfo/W=$pnlName imageP
	String imgName = S_Value
	Wave/Z w = SIDAMImageNameToWaveRef(grfName, imgName=imgName)
	if (!WaveExists(w))
		//	This does not work correctly for the panel of Line Profile and
		//	Line Spectra. But the wave should not be removed from the panel,
		//	so ignore these cases.
		String cmdStr = "PopupMenu imageP proc=ATH_Range#pnlPopup,mode=1,value="
		sprintf cmdStr, "%s#\"ImageNameList(\\\"%s\\\", \\\";\\\")\",win=%s", cmdStr, grfName, pnlName
		Execute/Q cmdStr		
	endif
	
	updatePnlHistogram(pnlName, 0)
	updatePnlAxis(pnlName)
	resetPnlCtrls(pnlName)

	return 1
End

//----------------------------------------------------------------------
//	Hook function for the panel
//----------------------------------------------------------------------
Static Function pnlHook(STRUCT WMWinHookStruct &s)

	switch (s.eventCode)

		case 2:	//	kill
		case 14:	//	subwindowKill
			pnlHookClose(s.winName)
			break

// JW WaveMetrics As of Igor 10, this prevents mouse clicks on the cursors, too
//		case 3:	//	mousedown
//			//	suppress any click in the panel except dragging the cursors
//			return 1

		case 7:	//	cursor moved
			//	This is supposed to work when a cursor is moved by a user,
			//	and not to work when a cursor is moved by a certain function.
			int hasCallingFunction = strlen(GetRTStackInfo(2)) != 0
			if (!hasCallingFunction)
				pnlHookCursor(s)		//	s.winName = Graph0#Range#G0
			endif
			break

		case 11:	//	keyboard
			if (s.keycode == 27)		//	27: esc
				//	s.winName can be a subwindow of the range panel.
				String pnlName = StringFromList(0,s.winName,"#")+ "#" + PNAME
				pnlHookClose(pnlName)
				KillWindow $pnlName
			endif
			break

	endswitch
	return 0
End

//	Behavior when the panel is closed
Static Function pnlHookClose(String pnlName)

	String grfName = StringFromList(0, pnlName, "#")
	if (SIDAMWindowExists(grfName))
		if (!strlen(GetUserData(pnlName,"","norevert")))
			revertZmode(pnlName)
			updateZRange(grfName, pause=1)
		endif
	 	if (canZmodeBeDeleted(grfName))
			deleteZmodeValues(grfName)
			SetWindow $grfName hook(SIDAMRange)=$""
		endif
	endif

	SIDAMKillDataFolder($GetUserData(pnlName,"","dfTmp"))
End

//	Behavior when a cursor is moved by a user
Static Function pnlHookCursor(STRUCT WMWinHookStruct &s)

	//	s.winName = Graph0#Range#G0
	//	pnlName = Graph0#Range
	String pnlName = RemoveEnding(ParseFilePath(1, s.winName, "#", 1, 0))
	
	String grfName = GetUserData(pnlName,"","grf")
	ControlInfo/W=$pnlName imageP
	String imgName = S_Value
	
	//	Since the cursor value is given between 0 and 1. Therefore, the axis
	//	range is necessary to get an x value.
	String xAxis = StringByKey("XAXIS",TraceInfo(s.winName, s.traceName, 0))
	GetAxis/W=$s.winName/Q $xAxis
	Variable xmin = V_min, xmax = V_max
	Variable xvalue = xmin + (xmax-xmin)*s.pointNumber
	if (SIDAM_ColorTableLog(grfName, imgName))
		xvalue = 10^xvalue
	endif

	String checkBoxName = StringByKey(s.cursorName, "I:zminC;J:zmaxC;")
	updatePnlRadioBox(pnlName, checkBoxName)

	//	The value of SetVariable is change, but pnlSetVar is NOT called here
	//	by this change
	String setVarName = StringByKey(s.cursorName, "I:zminV;J:zmaxV;")
	SetVariable $setVarName value=_NUM:xvalue, win=$pnlName

	updatePnlColor(pnlName)

	updateZmode(pnlName)
	updateZRange(GetUserData(pnlName,"","grf"), pause=1)
End

Static Function pnlAxHook(STRUCT WMAxisHookStruct &s)
	GetAxis/Q/W=$s.win $s.mastName
	s.min = 10^V_min
	s.max = 10^V_max
	return 0
End

//******************************************************************************
//	Controls
//******************************************************************************
//	SetVariable
Static Function pnlSetVar(STRUCT WMSetVariableAction &s)

	//	Handle either mouse up, enter key, or begin edit
	if (!(s.eventCode == 1 || s.eventCode == 2 || s.eventCode == 7))
		return 1
	endif

	if (!CmpStr(s.ctrlName,"zminV") || !CmpStr(s.ctrlName,"zmaxV"))
		SetVariable $s.ctrlName limits={-inf,inf,10^(floor(log(abs(s.dval)))-1)}, win=$s.win
	endif

	String checkBoxName = (s.ctrlName)[0,strlen(s.ctrlName)-2]+"C"
	updatePnlRadioBox(s.win, checkBoxName)

	updateZmode(s.win)
	updateZRange(GetUserData(s.win,"","grf"), pause=1)

	updatePnlCursorsPos(s.win)
	updatePnlColor(s.win)
	updatePnlPresentValues(s.win)

	return 0
End

//	PopupMenu
Static Function pnlPopup(STRUCT WMPopupAction &s)

	if (s.eventCode != 2)
		return 0
	endif

	strswitch (s.ctrlName)
		case "imageP":
			//	The histogram has to be updated before the initilization.
			//	Otherwise, the cursor position may be wrong.
			updatePnlHistogram(s.win, 0)
			updatePnlAxis(s.win)
			resetPnlCtrls(s.win)
			break
	endswitch
	return 0
End

//	Button
Static Function pnlButton(STRUCT WMButtonAction &s)

	if (s.eventCode != 2)
		return 0
	endif

	strswitch (s.ctrlName)
		case "doRngB": // Apply
			SetWindow $s.win userData(norevert)="1"
			//*** FALLTHROUGH ***
		case "cancelRngB":
			KillWindow $s.win
			break
		case "refreshRngB":
			// ------ EG ---- //
			updateZmode(s.win)
			updateZRange(GetUserData(s.win,"","grf"), pause=1)

			updatePnlCursorsPos(s.win)
			updatePnlColor(s.win)
			updatePnlPresentValues(s.win)
			break
		case "presentRngB":
		case "fullRngB":
			updatePnlHistogram(s.win, NumberByKey(s.ctrlName, "presentRngB:0;fullRngB:1"))
			updatePnlCursorsPos(s.win)
			updatePnlColor(s.win)
			break
		case "reverseColorsRngB":
			string matchPattern = "(.)([0-9])}$", dump, cmapSwitchStr
			ControlInfo/W=$s.win imageP
			string imgNameStr = S_Value
			SplitString/E=matchPattern StringByKey("RECREATION",Imageinfo("",imgNameStr,0)), dump, cmapSwitchStr
			variable RcmapQ = !str2num(cmapSwitchStr) // Flip it here
			ModifyImage/W=$GetUserData(s.win,"","grf") $imgNameStr ctab={,,,RcmapQ}	
			if(RcmapQ)
				Button reverseColorsRngB,fcolor=(0,65535,0),win=$s.win
			else
				Button reverseColorsRngB,fcolor=(65535,0,0),win=$s.win
			endif			
				break
			endswitch
	return 0
End

//	Checkbox
Static Function pnlCheck(STRUCT WMCheckboxAction &s)

	if (s.eventCode != 2)
		return 0
	endif
	
	updatePnlRadioBox(s.win, s.ctrlName)

	updateZmode(s.win)
	updateZRange(GetUserData(s.win,"","grf"), pause=1)

	updatePnlCursorsPos(s.win)
	updatePnlColor(s.win)
	updatePnlPresentValues(s.win)

	return 0
End

//******************************************************************************
//	Helper functions of controls
//******************************************************************************
Static Function revertZmode(String pnlName)

	String grfName = GetUserData(pnlName,"","grf")
	String initialZmode = GetUserData(pnlName,"",MODEKEY), valueStr
	String imgName
	int i

	for (i = 0; i < ItemsInList(initialZmode); i++)
		imgName = StringFromList(0,StringFromList(i,initialZmode),":")
		valueStr = StringFromList(1,StringFromList(i,initialZmode),":")
		setZmodeValue(grfName, imgName, "m0", NumberByKey("m0",valueStr,"=",","))
		setZmodeValue(grfName, imgName, "m1", NumberByKey("m1",valueStr,"=",","))
		setZmodeValue(grfName, imgName, "v0", NumberByKey("v0",valueStr,"=",","))
		setZmodeValue(grfName, imgName, "v1", NumberByKey("v1",valueStr,"=",","))
	endfor
End

//	Put the present z range to zminV and zmaxV
Static Function updatePnlPresentValues(String pnlName)

	String grfName = GetUserData(pnlName,"","grf")
	ControlInfo/W=$pnlName imageP
	Variable zmin, zmax
	SIDAM_GetColorTableMinMax(grfName, S_Value, zmin, zmax)
	SetVariable zminV value=_NUM:zmin,limits={-inf,inf,10^(floor(log(abs(zmin)))-1)}, win=$pnlName
	SetVariable zmaxV value=_NUM:zmax,limits={-inf,inf,10^(floor(log(abs(zmax)))-1)}, win=$pnlName
End

//	Reset the controls of the panel
//	This is called:
//		after the panel is created (pnl)
//		when a target wave is changed from the popupmenu (pnlPopup)
//		when the parent window is modified, e.g., displayed layer (pnlHookParent)
Static Function resetPnlCtrls(String pnlName)

	String grfName = GetUserData(pnlName,"","grf")
	ControlInfo/W=$pnlName imageP
	String imgName = S_Value

	updatePnlPresentValues(pnlName)

	//	Select ratioboxes corresonding to the selected Z mode
	int m0 = getZmodeValue(grfName, imgName, "m0")
	int m1 = getZmodeValue(grfName, imgName, "m1")
	updatePnlRadioBox(pnlName, StringFromList(m0,"zminAutoC;zminC;zminSigmaC;zminCutC;zminLogsigmaC"))
	updatePnlRadioBox(pnlName, StringFromList(m1,"zmaxAutoC;zmaxC;zmaxSigmaC;zmaxCutC;zmaxLogsigmaC"))

	//	If the Z mode is sigma or cut, put the value to the corresponding SetVariable
	if (m0 >= 2)
		Variable v0 = getZmodeValue(grfName, imgName, "v0")
		SetVariable $StringFromList(m0-2,"zminSigmaV;zminCutV;zminLogsigmaV") value=_NUM:v0, win=$pnlName
	endif

	if (m1 >= 2)
		Variable v1 = getZmodeValue(grfName, imgName, "v1")
		SetVariable $StringFromList(m1-2,"zmaxSigmaV;zmaxCutV;zmaxLogsigmaV") value=_NUM:v1, win=$pnlName
	endif

	DoUpdate/W=$pnlName		//	to ensure the modifications above are correctly reflected
	updatePnlCursorsPos(pnlName)
	updatePnlColor(pnlName)
End

//	Check the selected ratiobox and uncheck the others in the same group
Static Function updatePnlRadioBox(String pnlName, String ctrlName)

	String minOrMax = (ctrlName)[0,3]
	String ctrlList = ControlNameList(pnlName, ";", minOrMax+"*C")
	ctrlList = RemoveFromList(ctrlName, ctrlList)
	int i
	for (i = 0; i < ItemsInList(ctrlList); i++)
		CheckBox $StringFromList(i,ctrlList) value=0, win=$pnlName
	endfor
	CheckBox $ctrlName value=1, win=$pnlName
End

//	Update the cursor positions to reflect the present values of the range
Static Function updatePnlCursorsPos(String pnlName)

	String grfName = GetUserData(pnlName, "", "grf")
	String subGrfName = GetUserData(pnlName, "", "subGrfName")
	ControlInfo/W=$pnlName imageP
	String imgName = S_value
	Variable zmin, zmax
	SIDAM_GetColorTableMinMax(grfName, imgName, zmin, zmax)
	int isLog = SIDAM_ColorTableLog(grfName, imgName)

	Cursor/F/W=$subGrfName I $HIST isLog ? log(zmin) : zmin, 0
	Cursor/F/W=$subGrfName J $HIST isLog ? log(zmax) : zmax, 0
End

//	Update the color histogram to reflect the present values of the range
Static Function updatePnlColor(String pnlName)

	String grfName = GetUserData(pnlName, "", "grf")
	String subGrfName = GetUserData(pnlName, "", "subGrfName")

	ControlInfo/W=$pnlName imageP
	String imgName = S_Value
	Variable zmin, zmax
	SIDAM_GetColorTableMinMax(grfName, imgName, zmin, zmax)
	if (SIDAM_ColorTableLog(grfName, imgName))
		zmin = log(zmin)
		zmax = log(zmax)
	endif
	
	String dfTmp = GetUserData(pnlName, "", "dfTmp")
	Wave/SDFR=$dfTmp clrw = $HISTCLR
	int reversed = WM_ColorTableReversed(grfName,imgName)
	String tableName = SIDAM_ColorTableForImage(grfName,imgName)
	
	ModifyGraph/W=$subGrfName mode($HIST)=5, hbFill($HIST)=2
	ModifyGraph/W=$subGrfName zColorMax($HIST)=NaN, zColorMin($HIST)=NaN
	if (WaveExists($tableName))
		ModifyGraph/W=$subGrfName zColor($HIST)={clrw,zmin,zmax,ctableRGB,reversed,$tableName}
	else
		ModifyGraph/W=$subGrfName zColor($HIST)={clrw,zmin,zmax,$tableName,reversed}
	endif
End

//	Update the histogram wave shown in the panel
//	The mode determines the range of the histogram
//	mode 0: the range larger than the present one by 5%
//	mode 1: the range between the min and the max of the displayed area
Static Function updatePnlHistogram(String pnlName, int mode)

	ControlInfo/W=$pnlName imageP
	String imgName = S_Value
	String grfName = GetUserData(pnlName, "", "grf")
	Wave w = SIDAMImageNameToWaveRef(grfName, imgName=imgName, displayed=1)
	int isLog = SIDAM_ColorTableLog(grfName, imgName)

		
	Variable z0, z1, zmin, zmax
	if ( mode == 0 )
		SIDAM_GetColorTableMinMax(grfName, imgName, zmin, zmax)
		z0 = isLog ? log(zmin)-log(zmax/zmin)*0.05 : zmin - (zmax - zmin) * 0.05
		z1 = isLog ? log(zmax)+log(zmax/zmin)*0.05 : zmax + (zmax - zmin) * 0.05
	else
		z0 = WaveMin(w)
		z1 = WaveMax(w)
	endif

	DFREF dfrTmp = $GetUserData(pnlName, "", "dfTmp")
	Duplicate/O SIDAMHistogram(w, startz=z0, endz=z1, bins=BINS, grfName=grfName) dfrTmp:$HIST/WAVE=hw
	Duplicate/O hw dfrTmp:$HISTCLR/WAVE=clrw
	clrw = x

	DoUpdate/W=$pnlName
End

Static Function updatePnlAxis(String pnlName)
	ControlInfo/W=$pnlName imageP
	int isLog = SIDAM_ColorTableLog(GetUserData(pnlName, "", "grf"), S_Value)
	String subGrfName = GetUserData(pnlName, "", "subGrfName")
	ModifyGraph/W=$subGrfName noLabel(bottom)=isLog*2,axThick(bottom)=!isLog
	ModifyGraph/W=$subGrfName noLabel(logAxis)=!isLog*2,axThick(logAxis)=isLog
End

//	Update the Z mode values of the parent window based on
//	the selected values in the panel
Static Function updateZmode(String pnlName)

	//	z mode of first Z and last Z
	int m0, m1
	[m0, m1] = findSelectedMode(pnlName)

	//	z mode value of first Z, 0 for auto
	Wave minValuew = SIDAMGetCtrlValues(pnlName, "zminV;zminSigmaV;zminCutV;zminLogsigmaV")
	Variable v0 = m0 ? minValuew[m0-1] : 0

	//	z mode value of last Z, 0 for auto
	Wave maxValuew = SIDAMGetCtrlValues(pnlName, "zmaxV;zmaxSigmaV;zmaxCutV;zmaxLogsigmaV")
	Variable v1 = m1 ? maxValuew[m1-1] : 0

	String grfName = GetUserData(pnlName,"","grf")
	String imgNameList = ImageNameList(grfName,";")

	setZmodeValue(grfName, imgNameList, "m0", m0)
	setZmodeValue(grfName, imgNameList, "v0", v0)
	setZmodeValue(grfName, imgNameList, "m1", m1)
	setZmodeValue(grfName, imgNameList, "v1", v1)
End

//	0: auto; 1: fix; 2: sigma; 3: cut, 4: logsigma
Static Function [int m0, int m1] findSelectedMode(String pnlName)
	Wave minw = SIDAMGetCtrlValues(pnlName, "zminAutoC;zminC;zminSigmaC;zminCutC;zminLogsigmaC")
	Wave maxw = SIDAMGetCtrlValues(pnlName, "zmaxAutoC;zmaxC;zmaxSigmaC;zmaxCutC;zmaxLogsigmaC")
	minw *= p
	maxw *= p
	m0 = sum(minw)
	m1 = sum(maxw)
End

//	Set the z range based on the z mode
Static Function updateZRange(String grfName, [int pause])

	String listStr = ImageNameList(grfName,";"), imgName
	int i, n, m0, m1
	Variable v0, v1

	if (!ParamIsDefault(pause) && pause)
		//	Prevent recurrence calling by the hook function of the parent graph
		SetWindow $grfName userData(pauseHook)="1"
	endif

	for (i = 0, n = ItemsInList(listStr); i < n; i++)
		imgName = StringFromList(i,listStr)

		m0 = getZmodeValue(grfName, imgName, "m0")
		v0 = getZmodeValue(grfName, imgName, "v0")
		m1 = getZmodeValue(grfName, imgName, "m1")
		v1 = getZmodeValue(grfName, imgName, "v1")

		Wave zw = updateZRange_getValues(grfName, imgName, m0, v0, m1, v1)
		applyZRange(grfName, imgName, zw[0], zw[1])
		
		//	Record the present values so that any changes from the Igor default dialog
		//	can be detected later
		setZmodeValue(grfName, imgName, "z0", zw[0])
		setZmodeValue(grfName, imgName, "z1", zw[1])
	endfor
End

Static Function/WAVE updateZRange_getValues(String grfName, String imgName,
	int m0, Variable v0, int m1, Variable v1)
	//EG edit to work with Marquee
	variable plane, flag, left, right, top, bottom, minV, maxV
	[flag, left, right, top, bottom] = GetMarqueeToIndex(grfName=grfName)
	if (m0 >= 2 || m1 >= 2)		//	sigma, cut, logsigma
		//EG edit to work with Marquee. Wave is partitioned here if zoomed!!
		Wave tw = SIDAMImageNameToWaveRef(grfName, imgName=imgName, displayed=1)
		if(WaveDims(tw)==3)
			string infoStr = ImageInfo(grfName, imgName, 0)
			plane = NumberByKey("plane", infoStr, "=")
		else
			plane = 0
		endif
		if (m0 == 2 || m1 == 2)	//	sigma
			if(flag)
				WaveStats/Q/RMD=[left, right][top,bottom][plane] tw
			else
				WaveStats/Q tw
			endif
			Variable avg = V_avg, sdev = V_sdev
		endif
		if (m0 == 3 || m1 == 3)	//	cut
			Wave hw = SIDAMHistogram(tw,bins=256,cumulative=1,normalize=1,grfName=grfName)
		endif
		if (m0 == 4 || m1 == 4)	//	logsimga
			MatrixOP/FREE tw2 = log(tw)
			if(flag)
				WaveStats/Q/RMD=[left, right][top,bottom][plane] tw2
			else
				WaveStats/Q tw2
			endif
			Variable logavg = V_avg, logsdev = V_sdev
		endif
	endif

	Variable zmin, zmax
	//	When tw contains only NaN, WaveMin and WaveMax return NaN.
	//	To disinguish this from the case of m0==0 or m1==0, use +-inf.
	Variable defaultmin = numtype(WaveMin(tw)) ? -inf : WaveMin(tw)
	Variable defaultmax = numtype(WaveMax(tw)) ? inf : WaveMax(tw)

	switch (m0)
		case 0:	//	auto
			if(flag)
				Wave tw = SIDAMImageNameToWaveRef(grfName, imgName=imgName, displayed=1)
				WaveStats/Q/RMD=[left, right][top,bottom][plane] tw
				zmin = V_min
			else
				zmin = NaN
			endif
			break
		case 2:	//	sigma
			zmin = numtype(avg) || numtype(sdev) ? defaultmin : avg + sdev * v0
			break
		case 3:	//	cut
			FindLevel/Q hw, v0/100
			zmin = V_flag ? defaultmin : V_LevelX
			break
		case 4:	//	logsigma
			zmin = numtype(logavg) || numtype(logsdev) ? defaultmin : 10^(logavg+logsdev*v0)
			break
		default:	//	1 (fix)
			zmin = v0
	endswitch

	switch (m1)
		case 0:	//	auto
			if(flag)
				Wave tw = SIDAMImageNameToWaveRef(grfName, imgName=imgName, displayed=1)
				WaveStats/Q/RMD=[left, right][top,bottom][plane] tw
				zmax = V_max
			else
				zmax = NaN
			endif
			break
		case 2:	//	sigma
			zmax = numtype(avg) || numtype(sdev) ? defaultmax : avg + sdev * v1
			break
		case 3:	//	cut
			FindLevel/Q hw, v1/100
			zmax = V_flag ? defaultmax : V_LevelX
			break
		case 4:	//	logsigma
			zmax = numtype(logavg) || numtype(logsdev) ? defaultmax : 10^(logavg+logsdev*v1)
			break
		default:	//	1 (fix)
			zmax = v1
	endswitch
	Make/D/N=2/FREE rtnw = {zmin, zmax}
	return rtnw
End

//=====================================================================================================
//	z mode functions
//=====================================================================================================
//	The z mode information is stored as a string like
//	imgName:m0=xxx,v0=xxx,z0=xxx,m1=xxx,v1=xxx,z1=xxx;layer=xxx;modtime=xxx
//	This string is repeated for each image.
//	m0 and m1 are the mode (0: auto, 1:fix, 2:sigma, 3:cut, -1:manual)
//	v0 and v1 are the value (e.g. 3sigma of 3)
//	z0 and z1 are values actually used for the image
Static StrConstant MODEKEY = "SIDAMRangeSettings"

//	If a graph has no z mode information, write the present status to revert
//	when the cancel button of the panel is pressed.
Static Function initializeZmodeValue(String grfName)
	int hasRecord = strlen(GetUserData(grfName, "", MODEKEY)) > 0
	if (hasRecord)
		return 0
	endif

	String imgList = ImageNameList(grfName,";"), imgName
	Variable zmin, zmax
	int i
	for (i = 0; i < ItemsInList(imgList); i++)
		imgName = StringFromList(i,imgList)
		setZmodeValue(grfName, imgList, "m0", !isZAuto(grfName, imgName, 0))
		setZmodeValue(grfName, imgList, "m1", !isZAuto(grfName, imgName, 1))
		SIDAM_GetColorTableMinMax(grfName, imgName, zmin, zmax)
		setZmodeValue(grfName, imgList, "v0", zmin)
		setZmodeValue(grfName, imgList, "v1", zmax)
	endfor
End

Static Function setZmodeValue(String grfName, String imgList, String key, Variable var)

	String allImagesSettings = GetUserData(grfName, "", MODEKEY)
	String formatStr = SelectString(!CmpStr(key,"m0")||!CmpStr(key,"m1"),"%.14e","%d")
	String imgName, setting, str
	int i, n

	for (i = 0, n = ItemsInList(imgList); i < n; i++)
		imgName = StringFromList(i,imgList)
		setting = StringByKey(imgName, allImagesSettings)
		Sprintf str formatStr, var
		setting = ReplaceStringByKey(key,setting,str,"=",",")
		allImagesSettings = ReplaceStringByKey(imgName,allImagesSettings,setting)
	endfor

	SetWindow $grfName userData($MODEKEY)=allImagesSettings
End

Static Function getZmodeValue(String grfName, String imgName, String key)

	//	no graph or no image
	if (WhichListItem(imgName, ImageNameList(grfName,";")) == -1)
		return NaN
	endif

	String allImagesSettings = GetUserData(grfName, "", MODEKEY)
	String setting = StringByKey(imgName, allImagesSettings)
	Variable num = NumberByKey(key, setting, "=" , ",")		//	nan for no record

	//	If there is a record, return it
	if (!numtype(num))
		return num
	endif

	Variable zmin, zmax
	strswitch (key)
		case "m0":
			//	If there is no record, the z mode is not used.
			//	An actual value or auto is set.
			return !isZAuto(grfName, imgName, 0)

		case "m1":
			//	If there is no record, the z mode is not used.
			//	An actual value or auto is set.
			return !isZAuto(grfName, imgName, 0)

		case "v0":
		case "z0":
			SIDAM_GetColorTableMinMax(grfName,imgName,zmin,zmax)
			return zmin

		case "v1":
		case "z1":
			SIDAM_GetColorTableMinMax(grfName,imgName,zmin,zmax)
			return zmax
	endswitch
End

//	Delete the z mode info about deleted (not included in the graph) images
Static Function cleanZmodeValue(String grfName)

	String allImagesSettings = GetUserData(grfName, "", MODEKEY)
	String imgList = ImageNameList(grfName,";")
	int i, n0 = ItemsInList(allImagesSettings)

	for (i = ItemsInList(allImagesSettings)-1; i >= 0; i--)
		String setting = StringFromList(i, allImagesSettings)
		String imgName = StringFromList(0, setting, ":")
		if (WhichListItem(imgName,imgList) == -1)
			allImagesSettings = RemoveByKey(imgName,allImagesSettings)
		endif
	endfor

	SetWindow $grfName userData($MODEKEY)=allImagesSettings

	return n0 > ItemsInList(allImagesSettings)		//	true if there is a deleted image
End

//	Delete all the information about the z mode
Static Function deleteZmodeValues(String grfName)
	SetWindow $grfName userdata($MODEKEY)=""
End

//	Return 1 if all the images have the z mode values of 0 or 1
Static Function canZmodeBeDeleted(String grfName)

	cleanZmodeValue(grfName)

	String allImagesSettings = GetUserData(grfName, "", MODEKEY)
	int i
	for (i = 0; i < ItemsInList(allImagesSettings); i++)
		String setting = StringFromList(1,StringFromList(i, allImagesSettings),":")
		Variable m0 = NumberByKey("m0", setting, "=" , ",")		//	nan for no record
		Variable m1 = NumberByKey("m1", setting, "=" , ",")		//	nan for no record
		if (m0 >= 2 || m0 < 0 || m1 >= 2 || m1 < 0)
			return 0
		endif
	endfor

	return 1
End

// ---- Added required SIDAM function //

//@
//	Returns a non-zero value if specified graph or panel exist,
//	and 0 otherwise.
//
//	## Parameters
//	pnlName : string
//		The name of graph or panel. This can be a subwindow.
//
//	## Returns
//	variable
//		* 0: The window does not exists
//		* !0: Otherwise.
//@
static Function SIDAMWindowExists(String pnlName)
	if (!strlen(pnlName))
		return 0
	endif

	int hasChild = strsearch(pnlName, "#", 0) != -1
	if (!hasChild)
		DoWindow $pnlName
		return V_flag
	endif

	String hostName = RemoveEnding(ParseFilePath(1,pnlName,"#",1,0),"#")
	String subName = ParseFilePath(0,pnlName,"#",1,0)

	//	listStr is empty if "hostName" does not exist or
	//	"hostName" does not have a child window
	String listStr = ChildWindowList(hostName)

	//	if listStr is empty, the following WhichListItem returns -1
	return WhichListItem(subName, listStr) != -1
End

//  Extension of WMImageInfo

//@
//	Extension of `WM_ColorTableForImage`.
//
//	## Parameters
//	grfName : string
//		The name of window.
//	imgName : string
//		The name of an image.
//
//	## Returns
//	string
//		Name of a color table or absolute path to a color table wave.
//		Empty When the image is not found.
//@
static Function/S SIDAM_ColorTableForImage(String grfName, String imgName)
	String str = WM_ColorTableForImage(grfName,imgName)
	if (GetRTError(1) || !strlen(str))
		return ""
	elseif (WhichListItem(str,CTabList()) >= 0)	//	color table
		return str
	else
		return GetWavesDataFolder($str,2)
	endif
End

//@
//	Extension of `WM_GetColorTableMinMax`.
//
//	## Parameters
//	grfName : string
//		The name of window
//	imgName : string
//		The name of an image.
//	zmin, zmax : variable
//		The minimum and maximum values of ctab are returned.
//	allowNaN : int {0 or !0}, default 0
//		When `allowNaN` = 0, `zmin` and `zmax` are always numeric as
//		`WM_GetColorTableMinMax`. When !0, `zmin` and `zmax` are NaN if they
//		are auto.
//
//	## Returns
//	int
//		* 0: Normal exit
//		* 1: Any error
//@
static Function SIDAM_GetColorTableMinMax(String grfName, String imgName,
	Variable &zmin, Variable &zmax, [int allowNaN])
	
	String ctabInfo = WM_ImageColorTabInfo(grfName,imgName)
	if (GetRTError(1) || !strlen(ctabInfo))
		return 1
	endif

	Variable flag = WM_GetColorTableMinMax(grfName,imgName,zmin,zmax)
	if (GetRTError(1) || !flag)
		return 1
	endif
	
	allowNaN = ParamIsDefault(allowNaN) ? 0 : allowNaN
	int isMinAuto = !CmpStr(StringFromList(0,ctabInfo,","),"*")
	int isMaxAuto = !CmpStr(StringFromList(1,ctabInfo,","),"*")
	
	if (isMinAuto && allowNaN)
		zmin = NaN
	endif

	if (isMaxAuto && allowNaN)
		zmax = NaN
	endif
	
	return 0
End

//******************************************************************************
//	Create SIDAM temporary folder root:Packages:ATH_DataFolder:Range:grfName and
//	return a string containing the path.
//******************************************************************************
static Function/S SIDAMNewDF(String grfName, String procName)
	String path = SIDAM_DF+":"
	if (strlen(procName))
		path += procName+":"
		if (strlen(grfName))
			path += grfName
		endif
	endif
	
	DFREF dfrSav = GetDataFolderDFR()
	SetDataFolder root:
	int i
	for (i = 1; i < ItemsInList(path,":"); i++)
		NewDataFolder/O/S $StringFromList(i,path,":")
	endfor
	String dfTmp = GetDataFolder(1)
	SetDataFolder dfrSav
	return dfTmp
End

//@
//	Extension of `ImageNameToWaveRef()`
//
//	## Parameters
//	grfName : string
//		Name of a window.
//	imgName : string, default `StringFromList(0, ImageNameList(grfName, ";"))`
//		Name of an image. The default is the top image in the window.
//		If this is given, this function works as `ImageNameToWaveRef()`. 
//	displayed : int {0, !0}
//		Set !0 to return a 2D free wave of the displaye area, plane, and imCmplxMode.
//
//	## Returns
//	wave
//		A wave reference to an image in the window, or a free wave which is
//		a part of a wave shown in the window.
//@
static Function/WAVE SIDAMImageNameToWaveRef(String grfName, [String imgName, int displayed])
	if (ParamIsDefault(imgName))
		imgName = StringFromList(0, ImageNameList(grfName, ";"))
	endif

	if (!strlen(imgName))
		return $""
	endif

	Wave/Z w = ImageNameToWaveRef(grfName, imgName)
	if (!WaveExists(w))
		return $""
	elseif (ParamIsDefault(displayed) || !displayed)
		return w
	endif

	int isCmplx = WaveType(w) & 0x01
	int is3D = WaveDims(w) == 3
	String infoStr = ImageInfo(grfName, imgName, 0)
	Variable plane = NumberByKey("plane", infoStr, "=")
	int mode = NumberByKey("imCmplxMode", infoStr, "=")

	if (is3D)
		MatrixOP/FREE tw0 = layer(w, plane)
	else
		//	If "Wave tw0 = w" is used, pnlHookParent in SIDAM_range.ipf is called
		//	repeately for real 2D waves, and causes a trouble.
		MatrixOP/FREE tw0 = w
	endif
	
	if (isCmplx)
		switch (mode)
			case 0:	//	magnitude
				MatrixOP/FREE tw1 = mag(tw0) // Default with /C and NewImg
				break
			case 1:	//	real
				MatrixOP/FREE tw1 = real(tw0)
				break
			case 2:	//	imaginary
				MatrixOP/FREE tw1 = imag(tw0)
				break
			case 3:	//	phase
				MatrixOP/FREE tw1 = phase(tw0)
				break
		endswitch
	else
		Wave tw1 = tw0
	endif
	CopyScales w tw1

	GetAxis/W=$grfName/Q $StringByKey("XAXIS", infoStr)
	Variable xmin = V_min, xmax = V_max
	GetAxis/W=$grfName/Q $StringByKey("YAXIS", infoStr)
	Variable ymin = V_min, ymax = V_max
	Duplicate/R=(xmin,xmax)(ymin,ymax)/FREE tw1 tw2

	return tw2
End

//@
//	Returns if a logarithmically-spaced color is set.
//	(log version of `WM_ColorTableReversed`)
//
//	## Parameters
//	grfName : string
//		The name of window
//	imgName : string
//		The name of an image.
//
//	## Returns
//	int
//		* 0: a linearly-spaced color.
//		* 1: a logarithmically-spaced color.
//		* -1: any error.
//@
static Function SIDAM_ColorTableLog(String grfName, String imgName)
	String info = ImageInfo(grfName, imgName, 0)
	if (GetRTError(1))
		return -1
	endif
	return str2num(TrimString(WMGetRECREATIONInfoByKey("log",info)))
End


// EG: Modified Hist Functions as param Structures are the same across different files in SIDAM //

//@
//	Generate a histogram of the input wave.
//	When the input wave is 3D, the histogram is generated layer by layer.
//
//	## Parameters
//	w : wave
//		The input wave, 2D or 3D.
//	startz : variable, default `WaveMin(w)`
//		The start value of a histogram.
//	endz : variable, default `WaveMax(w)`
//		The end value of a histogram.
//	deltaz : variable
//		The width of a bin. Unless given, `endz` is used.
//	bins : int, default 64
//		The number of bins.
//	cumulative : int {0 or !0}, default 0
//		Set !0 for a cumulative histogram.
//	normalize : int {0 or !0}, default 1
//		Set !0 to normalize a histogram.
//	cmplxmode : int {0 -- 3}, default 0
//		Select a mode for a complex input wave.
//		* 0: Amplitude
//		* 1: Real
//		* 2: Imaginary
//		* 3: Phase.
//
//	## Returns
//	wave
//		Histogram wave.
//@
static Function/WAVE SIDAMHistogram(Wave/Z w, [variable startz, variable endz,
	variable deltaz, int bins, int cumulative, int normalize, int cmplxmode, string grfName])

	STRUCT paramStructHist s

	// EG: My code injection to use range with marquee. Added string grfName as an optional argument
	// Original code:
	// Wave/Z s.w = w
	// Also remove the optional argument from all calls of the function in file
	variable plane, flag, left, right, top, bottom
	[flag, left, right, top, bottom] = GetMarqueeToIndex(grfName=grfName)
	
	if(flag)
		if(WaveDims(w)==3)
			string infoStr = ImageInfo(grfName, NameOfWave(w), 0)
			plane = NumberByKey("plane", infoStr, "=")
			Duplicate/FREE/RMD=[left, right][top,bottom][plane] w, wRMD
		else
			Duplicate/FREE/RMD=[left, right][top,bottom] w, wRMD
		endif
		Wave/Z s.w = wRMD
	else
		Wave/Z s.w = w
	endif
	// end of interjection.
	s.bins = ParamIsDefault(bins) ? DEFALUT_BINS : bins
	s.startz = ParamIsDefault(startz) ? NaN : startz
	s.endz = ParamIsDefault(endz) ? NaN : endz
	s.deltaz = ParamIsDefault(deltaz) ? NaN : deltaz
	s.cumulative = ParamIsDefault(cumulative) ? 0 : cumulative
	s.normalize = ParamIsDefault(normalize) ? 1 : normalize
	s.cmplxmode = ParamIsDefault(cmplxmode) ? 0 : cmplxmode

	if (validateHist(s))
		print s.errMsg
		Make/FREE rtnw = {1}
		return rtnw
	endif

	if (WaveDims(w) == 2)
		return histogramFrom2D(s)
	elseif (WaveDims(w) == 3)
		return histogramFrom3D(s)
	endif
End

Static Function validateHist(STRUCT paramStructHist &s)
	
	s.errMsg = PRESTR_CAUTION + "SIDAMHistogram gave error: "
	
	if (WaveExists(s.w))
		if (WaveDims(s.w) != 2 && WaveDims(s.w) != 3)
			s.errMsg += "dimension of input wave must be 2 or 3."
			return 1
		endif
	else
		s.errMsg += "wave not found."
		return 1
	endif
	
	if (s.cmplxmode < 0 || s.cmplxmode > 3)
		s.errMsg += "invalid cmplxmode."
		return 1
	endif
		
	s.initialz = (numtype(s.startz) == 2) ? WaveMin(s.w) : s.startz
	
	//	if both of endz and deltaz are given, return an error.
	//	if neither of them is given, use the default value of endz
	if (!numtype(s.endz) && !numtype(s.deltaz))	//	both
		s.errMsg += "either endz or deltaz should be chosen."
		return 1
	elseif (!numtype(s.deltaz))	//	deltaz is given
		s.finalz = s.deltaz
		s.mode = 1
	elseif (!numtype(s.endz))		//	endz is given
		s.finalz = s.endz
		s.mode = 0
	else								//	none
		Wave minmaxw = getMinMax(s.w,"",cmplxmode=s.cmplxmode)
		s.finalz = minmaxw[1]
		s.mode = 0
	endif
	
	s.cumulative = s.cumulative ? 1 : 0
	s.normalize = s.normalize ? 1 : 0
	
	return 0
End


// --- End of modified histogram ---//


//@
//	Get the index of a 3D wave shown in a window.
//
//	## Parameters
//	grfName : string
//		The name of window
//	w : wave, default wave of the top image
//		The 3D wave to get the index.
//
//	## Returns
//	variable
//		The index of displayed layer. If no 3D wave is shown,
//		nan is returned.
//@
static Function SIDAMGetLayerIndex(String grfName, [Wave/Z w])
	if (ParamIsDefault(w))
		Wave/Z w =  SIDAMImageNameToWaveRef(grfName)
	endif
	if (!WaveExists(w) || WaveDims(w) != 3)
		return NaN
	endif
	
	return NumberByKey("plane", ImageInfo(grfName, NameOfWave(w), 0), "=")
End

//******************************************************************************
///	Kill a datafolder (dfr). This function is intended for killing the temporary
///	datafolder of SIDAM.
///	Kill waves in the datafolder and subfolders at first. If the waves are in
///	use, remove them from graphs and then kill them. If the waves are used as
///	color table waves, preserve them.
///	After killing waves as much as possible, the datafolder is kill if it has no
///	wave.
///	If the datafolder is killed, its parent is recursively kill if the parent
///	does not have either a wave nor a datafolder which is a sibling of the datafolder.
///
///	@param dfr	datafolder
///	@return	1 for dfr is invalid, otherwise 0
//******************************************************************************
static Function SIDAMKillDataFolder(DFREF dfr) // Recursion here
	if (!DataFolderRefStatus(dfr))
		return 0
	elseif (DataFolderRefsEqual(dfr,root:Packages:ATH_DataFolder:)) // EG 11.03.2025: just stop and do not delete the root:Packages:ATH_DataFolder
		return 1
	endif

	int recursive = !CmpStr(GetRTStackInfo(1),GetRTStackInfo(2))
	int hasWave, hasDF
	if (recursive)
		hasWave = CountObjectsDFR(dfr,1)
		hasDF = CountObjectsDFR(dfr,4)
		if (hasWave || hasDf)
			return 2
		endif
	else
		killDependence(dfr)
		hasWave = killWaveDataFolder(dfr)
		if (hasWave)
			return 3
		endif
	endif

	DFREF pdfr = $ParseFilePath(1, GetDataFolder(1,dfr), ":", 1, 0)
	KillDataFolder dfr
	return SIDAMKillDataFolder(pdfr)
End

//******************************************************************************
//	Run "To cmd line" or "To clip"
//******************************************************************************
static Function SIDAMPopupTo(STRUCT WMPopupAction &s, String paramStr)
	switch (s.popNum)
		case 1:
			ToCommandLine paramStr
			break
		case 2:
			PutScrapText paramStr
			break
	endswitch
End

//******************************************************************************
//	Retern a wave containing values of controls in a graph/panel
//******************************************************************************
//	Return a numeric wave containing number values of controls in a graph/panel.
static Function/WAVE SIDAMGetCtrlValues(String win, String ctrlList)

	Make/D/N=(ItemsInList(ctrlList))/FREE resw
	String ctrlName
	int i, n

	for (i = 0, n = ItemsInList(ctrlList); i < n; i++)
		ctrlName = StringFromList(i, ctrlList)
		SetDimLabel 0, i, $ctrlName, resw
		ControlInfo/W=$win $ctrlName
		switch (abs(V_Flag))
			case 0:	//	not found
			case 9:	//	Groupbox
			case 10:	//	TitleBox
				resw[i] = nan
				break

			case 5:	//	SetVariable
				switch (valueType(S_recreation))
					case 0:
					case 1:
						resw[i] = V_Value
						break
					case 2:
						resw[i] = eval(S_Value)
						break
					case 3:
						SVAR/SDFR=$S_DataFolder str = $S_value
						resw[i] = eval(str)
						break
					default:
						resw[i] = NaN
				endswitch
				break

			default:
				//	1: Button
				//	2: CheckBox
				//	3: PopupMenu
				//	4: ValDisplay
				//	6: Chart
				//	7: Slider
				//	8: TabControl
				//	11:	 ListBox
				//	12:	 CustomControl
				resw[i] = V_Value
		endswitch
	endfor

	return resw
End

Static Structure paramStructHist
	//	input
	Wave	w
	uint16	bins
	double	startz
	double	endz
	double	deltaz
	uchar	cumulative
	uchar	normalize
	uchar	cmplxmode
	String result
	//	output
	String	errMsg
	uchar	mode	//  0: endz, 1: deltaz
	double	initialz
	double	finalz
EndStructure

//******************************************************************************
//	Make a histogram from a 2D wave
//******************************************************************************
Static Function/WAVE histogramFrom2D(STRUCT paramStructHist &s)
	
	if (WaveType(s.w) & 0x01)
		switch (s.cmplxmode)
		case 0:	//	magnitude
			MatrixOP/FREE tw = mag(s.w)
			break
		case 1:	//	real
			MatrixOP/FREE tw = real(s.w)
			break
		case 2:	//	imaginary
			MatrixOP/FREE tw = imag(s.w)
			break
		case 3:	//	phase
			MatrixOP/FREE tw = phase(s.w)
			break
		endswitch
	else
		Wave tw = s.w
	endif
	
	Make/N=(s.bins)/FREE hw
	if (s.mode)
		SetScale/P x s.initialz, s.finalz, StringByKey("DUNITS", WaveInfo(s.w,0)), hw
	else
		SetScale/I x s.initialz, s.finalz, StringByKey("DUNITS", WaveInfo(s.w,0)), hw
	endif
	
	if (s.cumulative)
		Histogram/B=2/CUM tw hw
	else
		Histogram/B=2 tw hw
	endif
	
	if (s.normalize)
		hw /= numpnts(s.w)
	endif
	
	return hw
End

//******************************************************************************
//	Make a histogram from a 3D wave
//	Repeat the 2D function for each layer
//******************************************************************************
Static Function/WAVE histogramFrom3D(STRUCT paramStructHist &s)

	Make/N=(s.bins,DimSize(s.w,2))/FREE hw
	if (s.mode)
		SetScale/P x s.initialz, s.finalz, StringByKey("DUNITS", WaveInfo(s.w,0)), hw
	else
		SetScale/I x s.initialz, s.finalz, StringByKey("DUNITS", WaveInfo(s.w,0)), hw
	endif
	SetScale/P y DimOffset(s.w,2), DimDelta(s.w,2), WaveUnits(s.w,2), hw

	STRUCT paramStructHist s1
	s1 = s

	variable i
	for (i = 0; i < DimSize(s.w,2); i++)
		MatrixOP/FREE tw1 = layer(s.w, i)
		Wave s1.w = tw1
		Wave tw2 = histogramFrom2D(s1)
		hw[][i] = tw2[p]
	endfor
	
	return hw
End

//	returns the minimum and the maximum values of the wave
Static Function/WAVE getMinMax(Wave w, String grfName, [int cmplxmode])
	Make/D/N=2/FREE rtnw

	int isComplex = WaveType(w) & 0x01
	if (isComplex)
		cmplxmode = ParamIsDefault(cmplxmode) ? NumberByKey("imCmplxMode", ImageInfo(grfName,"",0),"=") : cmplxmode
		if (strlen(grfName) || !ParamIsDefault(cmplxmode))
			switch (cmplxmode)
			case 0:	//	magnitude
				MatrixOP/FREE tw = mag(w)
				break
			case 1:	//	real
				MatrixOP/FREE tw = real(w)
				break
			case 2:	//	imaginary
				MatrixOP/FREE tw = imag(w)
				break
			case 3:
				MatrixOP/FREE tw = phase(w)
				break
			endswitch
		else
			MatrixOP/FREE tw = mag(w)
		endif
		rtnw = {WaveMin(tw), WaveMax(tw)}
	else
		rtnw = {WaveMin(w), WaveMax(w)}
	endif
	
	return rtnw
End

//	Kill dependence to all waves, variables, and strings in a datafolder
//	@param dfr	Datafolder
Static Function killDependence(DFREF dfr)
	int type, i, n
	for (type = 1; type <= 3; type++)
		for (i = 0, n = CountObjectsDFR(dfr, type); i < n; i++)
			SetFormula dfr:$GetIndexedObjNameDFR(dfr, type, i), ""
		endfor
	endfor
End

//	Kill waves in a datafolder and also in subfolders.
//	If waves are in use and unless they are color table waves, kill after removing
//	them from graphs. Kill a subfolder if it's empty after killing waves
//	@param dfr	Datafolder
//	@return		Number of waves remaining in the datafolder without being killed
Static Function killWaveDataFolder(DFREF dfr)	//	tested
	int i, n, count = 0
	DFREF dfrSav = GetDataFolderDFR()
	SetDataFolder dfr

	//	Kill datafolders in the current datafolder, if possible
	for (i = CountObjectsDFR(dfr,4)-1; i >= 0; i--)
		KillDataFolder/Z $GetIndexedObjNameDFR(dfr,4,i)
	endfor

	//	Call recursively this function for remaining datafolders
	for (i = 0, n = CountObjectsDFR(dfr,4); i < n; i++)
		count += killWaveDataFolder($GetIndexedObjNameDFR(dfr,4,i))
	endfor

	removeImageTrace(dfr)
	KillWaves/A/Z
	count += CountObjectsDFR(dfr,1)

	if (DataFolderRefStatus(dfrSav))
		SetDataFolder dfrSav
	else
		SetDataFolder root:
	endif

	return count
End

//	Return type of variable used for a SetVariable control
Static Function valueType(String recreationStr)
	Variable n0 = strsearch(recreationStr, "value=", 0)
	Variable n1 = strsearch(recreationStr, ",", n0)
	Variable n2 = strsearch(recreationStr, "\r", n0)
	Variable n3 = (n1 == -1) ? n2 : min(n1, n2)
	String valueStr = recreationStr[n0+6,n3-1]

	NVAR/Z npath = $valueStr
	SVAR/Z spath = $valueStr
	if (strsearch(valueStr, "_NUM:", 0) != -1)
		return 0		//	internal number
	elseif (NVAR_Exists(npath))
		return 1		//	external number
	elseif (strsearch(valueStr, "_STR:", 0) != -1)
		return 2		//	internal string
	elseif (SVAR_Exists(spath))
		return 3		//	external string
	else
		return -1		//	?
	endif
End

Static Function eval(String str)
	DFREF dfrSav = GetDataFolderDFR(), dfrTmp = NewFreeDataFolder()
	SetDataFolder dfrTmp
	Execute/Q/Z "Variable/G v=" + str
	SetDataFolder dfrSav

	if (V_flag)
		return NaN
	else
		NVAR/SDFR=dfrTmp v
		return v
	endif
End

//	Remove traces and images of waves in a datafolder from all displayed graphs
//	Color table waves are not removed.
//	@param dfr	DataFolder
Static Function removeImageTrace(DFREF dfr)	//	tested
	//	Not only graphs but also panels are included in the list because
	//	panels may contain graphs in subwindows
	String grfList = WinList("*",";","WIN:65")
	int i, n
	for (i = 0, n = ItemsInList(grfList); i < n; i++)
		removeImageTraceHelper(dfr, StringFromList(i,grfList))
	endfor
End

Static Function removeImageTraceHelper(DFREF dfr, String grfName)
	int i, j, n
	String imgList, imgName, trcList, trcName

	String chdList = ChildWindowList(grfName)
	for (i = 0, n = ItemsInList(chdList); i < n; i++)
		removeImageTraceHelper(dfr, grfName+"#"+StringFromList(i,chdList))
	endfor

	if (WinType(grfName) != 1)	//	not graph
		return 0
	endif

	for (i = 0, n = CountObjectsDFR(dfr,1); i < n; i++)
		Wave/SDFR=dfr w = $GetIndexedObjNameDFR(dfr,1,i)
		CheckDisplayed/W=$grfName w
		if (!V_flag)
			continue
		endif

		imgList = ImageNameList(grfName,";")
		for (j = ItemsInList(imgList)-1; j >= 0; j--)
			imgName = StringFromList(j,imgList)
			if (WaveRefsEqual(w,ImageNameToWaveRef(grfName,imgName)))
				RemoveImage/W=$grfName $imgName
			endif
		endfor

		trcList = TraceNameList(grfName,";",1)
		for (j = ItemsInList(trcList)-1; j >= 0; j--)
			trcName = StringFromList(j,trcList)
			Wave yw = TraceNameToWaveRef(grfName,trcName)
			Wave/Z xw = XWaveRefFromTrace(grfName,trcName)
			if (WaveRefsEqual(w,yw) || WaveRefsEqual(w,xw))
				RemoveFromGraph/W=$grfName $trcName
			endif
		endfor
	endfor
End


static Function [variable flag, variable leftR, variable rightR, variable topR, variable bottomR] GetMarqueeToIndex([string grfName])
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName)
	string axisX, axisY
	[axisX, axisY] = ATH_Graph#GetAxes(grfName=grfName)
	variable errCode
	
	WAVE wRef = TopImageToWaveRef(grfName=grfName)
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

static Function/WAVE TopImageToWaveRef([string grfName])
	// Return a wave reference from the top graph
	
	grfName = SelectString(ParamIsDefault(grfName) ? 0: 1, WinName(0, 1, 1), grfName) // Empty case will be handled below
	string imgNameTopGraphStr = StringFromList(0, ImageNameList(grfName, ";"),";")
	// if there is no image in the top graph strlen(imgNameTopGraphStr) = 0
	if(strlen(imgNameTopGraphStr))
		WAVE wRef = ImageNameToWaveRef(grfName, imgNameTopGraphStr) // full path of wave
		return wRef
	else 
		return $""
	endif
End