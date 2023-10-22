#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma version=1.30
#pragma IgorVersion=8
#pragma IndependentModule=CalcPad

/// The code was posted from Tony Withers (tony) at Igor and it is included here as is.
/// For details you can check the following post at the Igor Exchange forum
/// https://www.wavemetrics.com/project/CalcPad

// Project Updater header
// http://www.igorexchange.com/project/Updater
static constant kProjectID=8033 // the project node on IgorExchange
static strconstant ksShortName="CalcPad" // the project short title on IgorExchange

// https://www.wavemetrics.com/user/tony

// Look under Analysis - Packages or use the shortcut "cmd-9/ctrl-9" to
// start CalcPad. CalcPad turns a notebook into a command-line type
// interface. Use up and down arrows to insert previously executed lines.
// Use shift-up/down to replace selection with previous answers.
// Execution environment is current data folder. Global variables
// v_CalcPad and s_CalcPad are created temporarily in the current data
// folder. Type ? and hit enter to change package preferences.

strconstant ksPackageName = "CalcPad"
strconstant ksPrefsFileName = "CalcPadPrefs.bin"
constant kPrefsVersion = 120

// 200 byte structure
Structure PackagePrefs
	uint32	 version	// Preferences structure version number. 100 means 1.00.
	uint32	 font_size
	uint32	 magnification
	STRUCT Rect win // window position and size, 8 bytes
	STRUCT RGBColor RGB_bg // 6 bytes
	STRUCT RGBColor RGB_txt
	STRUCT RGBColor RGB_ans
	STRUCT RGBColor RGB_hist
	uint16	 EnterCopy // allow enter key to copy selected history text to end of last line
	uint16	 InLine // answers on same line as input
	uint16 StringEval // allow fallback to string evaluation
	uint16 SigFigs // number of significant figures to display
	char shortcut
	char reserved[200 - 3*4 - 8 - 4*6 - 4*2 - 1]	// Reserved for future use
EndStructure

function PrefsSetDefaults(STRUCT PackagePrefs &prefs)
	prefs.version=kPrefsVersion
	prefs.font_size=14
	prefs.magnification=100
	prefs.win.left=0
	prefs.win.top=0
	prefs.win.right=350
	prefs.win.bottom=300
	prefs.RGB_bg.red=65535; prefs.RGB_bg.green=65535; prefs.RGB_bg.blue=65535
	prefs.RGB_txt.red=0; prefs.RGB_txt.green=0; prefs.RGB_txt.blue=0
	prefs.RGB_ans.red=0; prefs.RGB_ans.green=0; prefs.RGB_ans.blue=65280
	prefs.RGB_hist.red=43690; prefs.RGB_hist.green=43690; prefs.RGB_hist.blue=43690
	prefs.EnterCopy=1
	prefs.InLine=1
	prefs.StringEval=1
	prefs.SigFigs=12
	prefs.shortcut=char2num("9")
	SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs

	DoWindow CalcPadNB
	if (V_flag)
		Notebook CalcPadNB backRGB=(prefs.RGB_bg.red,prefs.RGB_bg.green,prefs.RGB_bg.blue)
	endif
end

function LoadPrefs(STRUCT PackagePrefs &prefs)
	LoadPackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
	if (V_flag!=0 || V_bytesRead==0 || prefs.version!=kPrefsVersion)
		PrefsSetDefaults(prefs)
	endif
end

menu "Analysis"
	submenu "Packages"
		CalcPad#MenuString(), /Q, CalcPad#CalcPad()
	end
end

function /S MenuString()
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	string s = num2char(prefs.shortcut)
	return SelectString(strlen(s)>0, "CalcPad", "CalcPad/"+s)
end

function CalcPad()
	DFREF dfr = getDFR() // create package folder
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	if (WaveExists(dfr:w_history)==0)
		Make /O/T/N=0 dfr:w_history, dfr:w_answers
		variable /G dfr:v_ans=0, dfr:v_hist=0
	endif
	DoWindow /F CalcPadNB
	if (V_flag == 0)
		NewNotebook /K=1 /F=1 /W=(prefs.win.left, prefs.win.top, prefs.win.right, prefs.win.bottom) /N=CalcPadNB  as "CalcPad"
		Notebook CalcPadNB showRuler=0, fSize=prefs.font_size, magnification=prefs.magnification
		Notebook CalcPadNB backRGB=(prefs.RGB_bg.red, prefs.RGB_bg.green, prefs.RGB_bg.blue)
		Notebook CalcPadNB textRGB=(prefs.RGB_txt.red, prefs.RGB_txt.green, prefs.RGB_txt.blue)
	endif
	string funcStr=GetIndependentModuleName()+"#CalcPadHook"
	SetWindow CalcPadNB, hook(hCalcPad)=$(funcStr)
	return 1
end

function /DF getDFR()
	DFREF dfr = root:Packages:CalcPad
	if (DataFolderRefStatus(dfr) != 1)
		NewDataFolder /O root:Packages
		NewDataFolder /O root:Packages:CalcPad
	endif
	DFREF dfr = root:Packages:CalcPad
	return dfr
end

function CalcPadHook(STRUCT WMWinHookStruct &H_Struct)
	
	if (H_Struct.eventcode == 2) // kill window
		SaveWindow(H_Struct.WinName)
	endif
	
	if (H_Struct.eventcode==10 && cmpstr(H_Struct.menuItem, "Paste")==0) // menu event
		return PreventPaste()
	endif
	
	if (H_Struct.eventcode != 11) // keyboard event
		return 0
	endif
	
	if (H_Struct.keycode==28 || H_Struct.keycode==29) // left or right arrow
		return 0 // allow these for selecting text
	endif

	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)	
	
	// make sure that we're typing on the last line
	GetSelection Notebook, CalcPadNB, 1 // get current position in notebook
	// store position
	Make /free w={V_startParagraph, V_startPos, V_endParagraph, V_endPos}
	// find last paragraph
	Notebook CalcPadNB selection={endOfFile,endOfFile}
	GetSelection Notebook, CalcPadNB, 1
	if (V_startParagraph==w[0]) // we're writing on the last line
		// restore current position
		Notebook CalcPadNB selection={(w[0],w[1]), (w[2],w[3])}
	else
		if (prefs.EnterCopy && (H_Struct.keycode==13 || H_Struct.keycode==3)) // return or enter
			Notebook CalcPadNB selection={(w[0],w[1]), (w[2],w[3])}
			GetSelection Notebook, CalcPadNB, 2 // sets S_selection
			Notebook CalcPadNB selection={endOfFile,endOfFile}
			if (strlen(s_selection))
				Notebook CalcPadNB text=s_selection
			endif
		endif
		Notebook CalcPadNB findText={"",1} // jump to end of last line
		return 1
	endif
	// this allows select, copy within notebook
	// typing allowed on the last line only
	// trying to type elsewhere sends cursor to end of file
	
	if (H_Struct.keycode == 8) // delete
		GetSelection Notebook, CalcPadNB, 1 // get current position in notebook
		if (V_startPos==0 && V_endPos==0)
			// Don't delete the start of the last line
			return 1
		endif
	endif
	
	if (H_Struct.keycode == 9) // tab
		// jump to end
		Notebook CalcPadNB selection={endOfFile,endOfFile}
		return 1
	endif	
	
	DFREF dfr = root:Packages:CalcPad
	NVAR v_ans=dfr:v_ans, v_hist=dfr:v_hist
	wave /T w_hist=dfr:w_history, w_ans=dfr:w_answers
		
	if (H_Struct.keycode==30 || H_Struct.keycode==31) // up or down arrow
		string insertStr
		if (H_Struct.eventMod & 2) // shift key
			// replace currently highlighted text with a previous answer
			GetSelection Notebook, CalcPadNB, 1
			w={V_startParagraph, V_startPos, V_endParagraph, V_endPos}
			
			v_ans+=1-2*(H_Struct.keycode==30)
			v_ans=max(0, v_ans)
			if (v_ans<numpnts(w_ans))
				insertStr=w_ans[v_ans]
			else
				insertStr=""
			endif
			v_ans=min(v_ans, numpnts(w_ans))
			
			Notebook CalcPadNB text=insertStr
			Notebook CalcPadNB selection={(w[0],w[1]), (w[2],w[1]+strlen(insertStr))}, findText={"",1}
		else // replace last line with a previously executed command
			Notebook CalcPadNB selection={endOfFile,endofFile}
			Notebook CalcPadNB selection={startOfParagraph,endOfFile}
			
			v_hist+=1-2*(H_Struct.keycode==30)
			v_hist=max(0,v_hist)
			if (V_hist>numpnts(w_hist)-1)
				insertStr=""
			else
				insertStr=w_hist(v_hist)
			endif
			v_hist=min(v_hist, numpnts(w_hist))	
			Notebook CalcPadNB text=insertStr
			Notebook CalcPadNB selection={endOfFile,endOfFile}			
		endif
		return 1
	endif
	
	if (H_Struct.keycode==13 || H_Struct.keycode==3) // return or enter
		// select the last paragraph
		Notebook CalcPadNB selection={startOfParagraph, endOfChars}
		GetSelection Notebook, CalcPadNB, 2 // sets S_selection
		if (strlen(s_selection)==0)
			return 1
		endif
		
		if (stringmatch(S_selection, "?"))
			Notebook CalcPadNB text=""
			makePrefsPanel()
			return 1
		endif

		Notebook CalcPadNB textRGB=(prefs.RGB_hist.red, prefs.RGB_hist.green, prefs.RGB_hist.blue)
		Notebook CalcPadNB selection={endOfParagraph, endOfParagraph}
		
		w_hist[numpnts(w_hist)]={s_selection}
		v_hist=numpnts(w_hist)
		
		variable /G V_CalcPad=NaN
		
		// work with a global variable in the current data folder
		// so that we can be folder aware
		Execute /Z/Q "v_CalcPad = "+S_selection
		NVAR v_result=v_CalcPad

		string resultStr="", formatStr="%."+num2str(prefs.sigFigs)+"g"

		if (prefs.StringEval && numtype(v_result)!=0) // not a normal number, so try to evaluate as text
			string /G s_CalcPad=""
			Execute /Z/Q "s_CalcPad = "+S_selection
			if (strlen(s_CalcPad))
				sprintf resultStr, "\"%s\"", s_CalcPad
			else
				sprintf resultStr, formatStr, v_result
			endif
		else
			sprintf resultStr, formatStr, v_result
		endif
		
		w_ans[numpnts(w_ans)]={resultStr}
		v_ans=numpnts(w_ans)
	
		Notebook CalcPadNB textRGB=(prefs.RGB_ans.red,prefs.RGB_ans.green,prefs.RGB_ans.blue)
	
		if (prefs.InLine)
			Notebook CalcPadNB text=" = "
		else
			Notebook CalcPadNB text="\r\t"
		endif
		Notebook CalcPadNB text=resultStr+"\r"
		Notebook CalcPadNB textRGB=(prefs.RGB_txt.red,prefs.RGB_txt.green,prefs.RGB_txt.blue)
	
		KillVariables /Z v_result
		KillStrings /Z s_CalcPad
		return 1
	endif
	return 0
end

function PreventPaste()
	GetSelection Notebook, CalcPadNB, 1 // get current position in notebook
	// store position
	Make /free w={V_startParagraph, V_startPos, V_endParagraph, V_endPos}
	// find last paragraph
	Notebook CalcPadNB selection={endOfFile,endOfFile}
	GetSelection Notebook, CalcPadNB, 1
	if (V_startParagraph==w[0]) // we're writing on the last line
		// restore current position
		Notebook CalcPadNB selection={(w[0],w[1]), (w[2],w[3])}
		return 0
	endif
	// trying to paste somewhere else
	return 1
end

// record some settings and clean up when notebook is closed
function SaveWindow(string strWin)
	DFREF dfr = root:Packages:CalcPad
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	string recreation=WinRecreation(strWin, 0)
	variable index, top, left, bottom, right, mag
	// save window position
	index=strsearch(recreation, "/W=(", 0)
	if (index>0)
		sscanf recreation[index,Inf], "/W=(%g,%g,%g,%g)", left, top, right, bottom
		prefs.win.top=top
		prefs.win.left=left
		prefs.win.bottom=bottom
		prefs.win.right=right
	endif
	// save window magnification
	index=strsearch(recreation, "magnification=", 0)
	if (index>0)
		sscanf recreation[index,Inf], "magnification=%g", mag
		prefs.magnification=mag
	endif
	SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
	KillDataFolder /Z dfr
end

function makePrefsPanel()
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	DoWindow /K CalcPadPrefsPanel
	
	variable WL=150, WT=100 // window coordinates
	GetWindow /Z CalcPadNB wsize
	if (v_flag==0)
		WL=V_right; WT=V_top
	endif
		
	NewPanel /K=1/N=CalcPadPrefsPanel/W=(WL,WT,WL+217,WT+295) // set width and height here
	ModifyPanel /W=CalcPadPrefsPanel, fixedSize=1, noEdit=1
	variable left=15, i=0
	
	i+=0.5
	GroupBox group0,pos={left-10,5},size={210,115},title="Colours",fSize=12
	i+=1
	PopupMenu popupBG,win=CalcPadPrefsPanel,pos={left,i*20},size={100,23},title="Window", Proc=$(GetIndependentModuleName()+"#PopMenuProc")
	PopupMenu popupBG,win=CalcPadPrefsPanel,fSize=12,mode=1,popColor= (prefs.RGB_bg.red,prefs.RGB_bg.green,prefs.RGB_bg.blue),value= #"\"*COLORPOP*\"", bodyWidth=50
	i+=1
	PopupMenu popupTXT,win=CalcPadPrefsPanel,pos={left,i*20},size={100,23},title="Text",fSize=12, Proc=$(GetIndependentModuleName()+"#PopMenuProc")
	PopupMenu popupTXT,win=CalcPadPrefsPanel,mode=1,popColor= (prefs.RGB_txt.red,prefs.RGB_txt.green,prefs.RGB_txt.blue),value= #"\"*COLORPOP*\"", bodyWidth=50
	i+=1
	PopupMenu popupANS,win=CalcPadPrefsPanel,pos={left,i*20},size={100,23},title="Answers", Proc=$(GetIndependentModuleName()+"#PopMenuProc")
	PopupMenu popupANS,win=CalcPadPrefsPanel,fSize=12,mode=1,popColor= (prefs.RGB_ans.red,prefs.RGB_ans.green,prefs.RGB_ans.blue),value= #"\"*COLORPOP*\"", bodyWidth=50
	i+=1
	PopupMenu popupHIST,win=CalcPadPrefsPanel,pos={left,i*20},size={100,23},title="History", Proc=$(GetIndependentModuleName()+"#PopMenuProc")
	PopupMenu popupHIST,win=CalcPadPrefsPanel,fSize=12,mode=1,popColor= (prefs.RGB_hist.red,prefs.RGB_hist.green,prefs.RGB_hist.blue),value= #"\"*COLORPOP*\"", bodyWidth=50
	
	i+=2
	GroupBox group1,win=CalcPadPrefsPanel,pos={left-10,i*20},size={210,130},title="Options",fSize=12
	i+=1
	CheckBox checkEnter,win=CalcPadPrefsPanel,pos={left,i*20},size={141,16},title="Use enter key to copy-paste"
	CheckBox checkEnter,win=CalcPadPrefsPanel,fSize=12,value= prefs.EnterCopy, Proc=$(GetIndependentModuleName()+"#CheckProc")
	i+=1
	CheckBox checkString,win=CalcPadPrefsPanel,pos={left,i*20},size={179,16},title="Fall back to string evaluation"
	CheckBox checkString,win=CalcPadPrefsPanel,fSize=12,value= prefs.StringEval, Proc=$(GetIndependentModuleName()+"#CheckProc")
	i+=1
	CheckBox checkInline,win=CalcPadPrefsPanel,pos={left,i*20},size={168,16},title="Print answers on same line"
	CheckBox checkInline,win=CalcPadPrefsPanel,fSize=12,value= prefs.InLine, Proc=$(GetIndependentModuleName()+"#CheckProc")
	i+=1
	SetVariable setSigFigs, win=CalcPadPrefsPanel,pos={left,i*20},size={168,16},title="Significant Figures"
	SetVariable setSigFigs, win=CalcPadPrefsPanel, fSize=12,value=_NUM:prefs.SigFigs, Proc=$(GetIndependentModuleName()+"#SetvarProc")
	i+=1
	string strTitle="Menu Shortcut: "
	#ifdef WINDOWS
		strTitle += "ctrl-"
	#else
		strTitle += "⌘-"
	#endif
	PopupMenu popupShortcut,win=CalcPadPrefsPanel,pos={left,i*20},size={101,23},title=strTitle, Proc=$(GetIndependentModuleName()+"#PopMenuProc")
	PopupMenu popupShortcut,win=CalcPadPrefsPanel,fSize=12,mode=1,popValue=num2char(prefs.shortcut),value="1;2;3;4;5;6;7;8;9;0;"
	i+=2

	Button buttonReset,win=CalcPadPrefsPanel,pos={left,i*20},size={100,20},title="Set to defaults", Proc=$(GetIndependentModuleName()+"#ButtonProc")
	
	PauseForUser CalcPadPrefsPanel
end

function ButtonProc(STRUCT WMButtonAction &s)
	if (s.eventCode !=2 )
		return 0
	endif
	STRUCT PackagePrefs prefs
	PrefsSetDefaults(prefs)
	// reset controls
	PopupMenu /Z popupBG,win=$s.win,popColor=(prefs.RGB_bg.red,prefs.RGB_bg.green,prefs.RGB_bg.blue),value=#"\"*COLORPOP*\""
	PopupMenu /Z popupTXT,win=$s.win,popColor=(prefs.RGB_txt.red,prefs.RGB_txt.green,prefs.RGB_txt.blue),value=#"\"*COLORPOP*\""
	PopupMenu /Z popupANS,win=$s.win,popColor=(prefs.RGB_ans.red,prefs.RGB_ans.green,prefs.RGB_ans.blue),value=#"\"*COLORPOP*\""
	PopupMenu /Z popupHIST,win=$s.win,popColor=(prefs.RGB_hist.red,prefs.RGB_hist.green,prefs.RGB_hist.blue),value=#"\"*COLORPOP*\""
	CheckBox /Z checkEnter,win=$s.win,value=prefs.EnterCopy
	CheckBox /Z checkString,win=$s.win,value=prefs.InLine
	CheckBox /Z checkInline,win=$s.win,value=prefs.StringEval
	SetVariable /Z setSigFigs,win=$s.win,value=_NUM:prefs.SigFigs
	PopupMenu /Z popupShortcut,win=CalcPadPrefsPanel,popmatch=num2char(prefs.shortcut)
	DoWindow CalcPadNB
	if (V_flag)
		Notebook CalcPadNB backRGB=(prefs.RGB_bg.red,prefs.RGB_bg.green,prefs.RGB_bg.blue)
	endif
	return 0
end

function CheckProc(STRUCT WMCheckboxAction &cba)
	if (cba.eventCode != 2)
		return 0
	endif
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	strswitch(cba.ctrlName)
		case "checkEnter":
			prefs.EnterCopy = cba.checked
			break
		case "checkInline":
			prefs.InLine = cba.checked
			break
		case "checkString":
			prefs.StringEval = cba.checked
			break
	endswitch
	SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
	return 0
end

function SetVarProc(STRUCT WMSetVariableAction &sva)
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // enter key
		case 3: // Live update
			STRUCT PackagePrefs prefs
			LoadPrefs(prefs)
			prefs.sigFigs=sva.dval
			SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
			break
	endswitch
	return 0
end

function PopMenuProc(STRUCT WMPopupAction &pa)
	if (pa.eventCode != 2)
		return 0
	endif
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	ControlInfo $pa.ctrlName
	strswitch(pa.ctrlName)
		case "popupBG":
			prefs.RGB_bg.red=V_red; prefs.RGB_bg.green=V_green; prefs.RGB_bg.blue=V_blue
			DoWindow CalcPadNB
			if (V_flag)
				Notebook CalcPadNB backRGB=(V_red, V_green, V_blue)
			endif
			break
		case "popupTXT":
			prefs.RGB_txt.red=V_red; prefs.RGB_txt.green=V_green; prefs.RGB_txt.blue=V_blue
			break
		case "popupANS":
			prefs.RGB_ans.red=V_red; prefs.RGB_ans.green=V_green; prefs.RGB_ans.blue=V_blue
			break
		case "popupHIST":
			prefs.RGB_hist.red=V_red; prefs.RGB_hist.green=V_green; prefs.RGB_hist.blue=V_blue
			break
		case "popupShortcut":
			prefs.shortcut=char2num(pa.popStr)
			break
	endswitch
	SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
	BuildMenu "Analysis"
	return 0
end