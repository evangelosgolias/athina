#pragma TextEncoding	= "UTF-8"
#pragma rtGlobals 		= 3
#pragma IgorVersion		= 9
#pragma ModuleName		= BackgroundRemover
#pragma version			= 1.51
#pragma DefaultTab		= {3,20,4}		// set default tab width in Igor Pro 9 and later

// Specta Background Remover was developed by Stephan Thuermer (user *chozo* in Igor Pro forums).
// It is adopted here with minor modifications to adjust to the MXP naming conversions, database and workflow.  
// Changes to the original code are indicated by a comment starting with "EG:".
// If you want to learn more about the package, and see a hot-to guide, visit:
// https://www.wavemetrics.com/node/21532


 static Constant kVersion = 1.51
 static StrConstant kVersionDate = "03/2022"

// --------------------- Project Updater header ----------------------
// If you're using Igor Pro 8 or later and have Project Updater
// installed, this package can check periodically for new releases.
// https://www.wavemetrics.com/project/Updater
// static Constant kProjectID = 21532 																// the project node on IgorExchange
// static StrConstant ksShortTitle = "Background Remover"											// the project short title on IgorExchange

//________________________________________________________________________________________________
//	Written by Stephan Thuermer - https://www.wavemetrics.com/user/chozo
//	Can be used to remove the "background" from spectra using various models.
//	
//	Constant:		A constant value.
//	Step:			Smooth step function which connects the two endpoints (using tanh()).
//	Linear:			Linear function through the two endpoints.
//	Exponential:	Normalized exponential function connecting the two endpoints.
//	Polynomial:		Polynomial function fitted within the selected range.
//	Total Sum:		Total sum inelastic scattering background after X. Li et al., J.Electron Spectrosc. Relat. Phenom. 63 (1993) 253-265
//	Shirley:		Iterative Shirley inelastic scattering background after A. Proctor and P. A. Sherwood, Anal. Chem. 54, 13-19 (1982)
//	Tougaard:		Three- and four-parameter universal scattering background after S. Tougaard, Surf. Interface Anal. 25: 137-154 (1997)
//	Tougaard Data:	Scattering background using scattering cross-section data after S. Tougaard, Surf. Interface Anal. 25: 137-154 (1997)
//
//	You can generate backgrounds in user code using the function:
//		String result_message = GenerateBackground(backstruct, datawave, backwave, [from, to])
//	
//	Populate the BackRemoveStruct with the desired parameters and provide both the original data (datawave) and a wave which
//	the background will be written to (backwave); both datawave and backwave need to have the same size and scaling.
//	The 'from' and 'to' optional parameters are for setting the start and end positions of the background calculation.
//	If these parameters are omitted then the first and last points of the input data are used (does not work with poly background).
//________________________________________________________________________________________________

//________________________________________________________________________________________________
// 2021-01-23 - ver. 1.30:	Initial public release.
// 2021-01-25 - ver. 1.31:	Fixed error when DataBroswer is not open & minor control size adjustments.
// 2021-02-04 - ver. 1.32:	Minor window and control size adjustments for an improved layout on Mac.
// 2021-05-16 - ver. 1.40:	Minor code refactoring.
//							Now background function settings are saved into the output's notes.
//							If multiple backgrounds are subtracted then each setting is recorded successively.
// 2021-05-17 - ver. 1.41:	The polynomial coefficients are now displayed in the legend and saved in the output.
//							Fixed several bugs with the polynomial background when called from user code without the GUI.
//							 - error because folder was not present.
//							 - error when selected range is close to the full data range.
//							 - error when polynomial degree is invalid.
// 2022-03-16 - ver. 1.50:	Fixed error on bad input to BackgroundSubtractGUI().
//							Previous settings are now loaded from saved background waves (ending "_bck").
//							Added setting for Tougaard band-gap (T0) smoothing and a link setting between parameters D and C.
//							Generated scattering CS data from the parametric Tougaard type will be exported as well (ending "_scs").
//							Output waves are now saved in the same folder as the input.
//							Smoothing of the step function can now be set in a wider range.
//							Now multiple instances of the tool can be opened at the same time.
//							Parameters will be written into background waves when calling GenerateBackground() in user code as well.
//							Rearranged control layout and added 'Plot after Export' function to create a graph of exported background data.
//							Added support for keyboard-shortcut (and other future) settings via external text file.
// 2022-07-14 - ver. 1.51:	Re-positioned some controls for consistency.
//							Follow Data checkbox has been added to the exponential and polynomial functions.
//							Minor bug-fixes and code improvements.
//________________________________________________________________________________________________

// EG: Changed from Background_Remover to BackgroundRemover
static StrConstant kWorkingDir = "BackgroundRemover"											// the name for the working dir
static StrConstant kSettingsFileName = "Spectra Tools settings.dat"								// just for keyboard shortcuts for now.
StrConstant kBackgroundTypes = "Constant;Step;Linear;Exponential;Polynomial;Total Sum;Shirley;Tougaard;Tougaard Data;"	// the various types of backgrounds used - non-static for backwards compatibility
static StrConstant kTougaardIniPara = "2866;1643;0;0;"											// initial parameters B,C,D and T0 for the universal Tougaard background (common metal)
//static StrConstant kTougaardIniPara = "325;542;275;5;"										// initial parameters B,C,D and T0 for SiO2
static Constant kTougaardSmoothStep = 0.5														// !only used if not set in the structure! - how much the insulator step for parameter T0 will be smoothed (should not be 0)
static Constant kMaxIterations		= 50														// iteration limit for Shirley background calculation
static Constant kConvergelimit		= 1e-6														// converge limit for Shirley background calculation

// EG: Moved the launcher to MAXPEEM>Analysis>XPS. See MXP_CustomIgorMenus.ipf in "MAXPEEM" menu.
// There you can find another was to launch the panel using the TracePopup menu (see MXP_LaunchRemoveXPSBackground())

// Menu "Spectra Tools"
//     BackgroundRemover#MenuEntry(),/Q, CreateBrowser; BackgroundSubtractGUI($GetBrowserSelection(0))
// End

//################################################################################################

Structure BackRemoveStruct
	String FuncType		// Constant, Step, Linear, Exponential, Polynomial, Total Sum, Shirley, Tougaard, Tougaard Data
	Variable avgPercent	// y Values around range ends positions get averaged
	// function specific:
	Variable expScale	// Exponential
	Variable polyDegree	// Poly
	Variable fullLinear	// Line
	// for Step
	Variable stepPos	// x center position
	Variable stepSmooth	// smoothing value
	// for Tougaard (universal CS parameters)
	Variable TouB
	Variable TouC
	Variable TouD
	Variable TouT
	Variable TouSmooth	// how much the insulator step for parameter T0 will be smoothed (should not be 0)
	// Tougaard Data
	Variable CSscale	// scaling (default 1)
	String CSdata		// name of CS wave in current folder
	// Shirley and Total Sum
	Variable followData	// follow data outside range
	Variable smoothData	// integer between 3 and 20
EndStructure

Function BackRemoveInitialize(bs)
	STRUCT BackRemoveStruct &bs
	bs.FuncType		= "Constant"
	bs.avgPercent	= 0.5
	bs.expScale		= 1
	bs.polyDegree	= 2
	bs.fullLinear	= 0
	bs.stepPos		= 0
	bs.stepSmooth	= 1
	bs.TouB			= str2num(StringFromList(0,kTougaardIniPara))
	bs.TouC			= str2num(StringFromList(1,kTougaardIniPara))
	bs.TouD			= str2num(StringFromList(2,kTougaardIniPara))
	bs.TouT			= str2num(StringFromList(3,kTougaardIniPara))
	bs.TouSmooth	= 0.5
	bs.CSscale		= 1
	bs.CSdata		= "none"
	bs.followData	= 0
	bs.smoothData	= 5
	return 0
End

//################################################################################################

Function/S GenerateBackground(s, inwave, backwave, [from, to])
	STRUCT BackRemoveStruct &s
	Wave, inwave, backwave
	Variable from, to
	
	if (!WaveExists(inwave) || !WaveExists(backwave))
		return "Input waves missing."
	endif
	if (WaveType(inwave,1) != 1 || WaveDims(inwave) > 1 || WaveType(backwave,1) != 1 || WaveDims(backwave) > 1)		// make sure to only load 1D waves
		return "This tool works only for numeric 1D waves."
	endif
	if (DimSize(inwave,0) != DimSize(backwave,0))
		return "Input waves need to have the same size and scaling."
	endif
	
	Variable rows	= DimSize(inwave,0)
	Variable delta	= DimDelta(inwave,0)
	Variable P1		= x2pnt(inwave,from)
	Variable P2		= x2pnt(inwave,to)
	if (ParamIsDefault(from))
		from = pnt2x(inwave,0)
		P1	 = 0
	endif
	if (ParamIsDefault(to))
		to = pnt2x(inwave,rows-1)
		P2 = rows-1
	endif
	
	Variable xRange	= s.avgPercent/100*abs(rightx(inwave)-leftx(inwave))						// define the averaging range
	Variable Up		= mean(inwave, from-xRange, from+xRange)									// upper y value to connect to
	Variable Down	= mean(inwave, to-xRange, to+xRange)										// lower y value
	
	if (P1 < 0 || P2 > (rows-1))
		return "Range input is outside data's x scaling."
	endif
	
	backwave[,P1] = Up																			// upper constant part of background	
	backwave[P2,] = Down																		// lower constant part of background
	
	String message = "", notestr = ""															// output text and wave notes
	Variable i = 0
	Strswitch(s.FuncType)
		case "Constant":																		// constant background just removes the baseline
			backwave = Down
		break
		case "Step":
			backwave = Down + (Up-Down)/2*(1-tanh(sign(delta)*(x-s.stepPos)/s.stepSmooth))		// tanh used to generate a smooth transition
			notestr += "\rstep position = "+num2str(s.stepPos)
			notestr += "\rstep smoothing = "+num2str(s.stepSmooth)
		break
		case "Linear":
			if (s.fullLinear)
				backwave[0, rows-1] = Up - (Up-Down)*(p-P1)/(P2-P1)
				notestr += "\rfull line = yes"
			else
				backwave[P1, P2] = Up - (Up-Down)*(p-P1)/(P2-P1)
				notestr += "\rfull line = no"
			endif
		break
		case "Exponential":
			backwave = s.expScale*(Up-Down)*(exp((P2-p)/(P2))-1)/(exp((P2-P1)/(P2))-1) + Down	// normalized exponential (is 1 at P1 and 0 at P2) which gets shifted and scaled
			notestr += "\rfollow data = "+SelectString(s.followData,"no","yes")
			notestr += "\rexp. scale = "+num2str(s.expScale)
		break
		case "Polynomial":
			if (s.polyDegree < 3 || s.polyDegree > 20)
				message += "Polynomial order outside valid range of 3 to 20."
				break
			endif
			if (P2-P1+s.polyDegree >= rows)
				if (rows > 50)																	// slightly adjust the range to make the fit work
					P1 += s.polyDegree
					P2 -= s.polyDegree
					message += "Increased data range by "+num2str(s.polyDegree*2)+" points. "
				else
					message += "Selected range incompatible with polynomial background.\rChoose proper start and end points within the data range."
					break
				endif
			endif
			
			DFREF saveDF = GetDataFolderDFR()
			SetDataFolder NewFreeDataFolder()
				Duplicate/Free inwave, FitWave, Mask
				Mask = 1; Mask[P1,P2] = 0														// the mask wave decides the fit range
				CurveFit/X=1/Q/L=(rows) poly s.polyDegree, FitWave /M=Mask 
				
				Wave result = W_coef
				Wave psigma = W_sigma
				backwave = poly(result,x)														// write result
				
				message += "Poly: "	+ num2str(result[0])										// output message writes all coefficients
				for (i = 1; i < numpnts(result);i += 1)
					message += " "+SelectString(result[i]<0,"+","")+ num2str(result[i]) + "*x"
					if (i>1)
						message += "^"+num2str(i)
					endif
					if (mod(i,5) == 0)															// add in occasional line breaks
						message += "\r"
					endif
				endfor
				
				notestr += "\rpoly. degree = "+num2str(s.polyDegree)
				for (i = 0; i < s.polyDegree; i += 1)
					notestr += "\rC"+num2str(i)+" = "+num2str(result[i])+" ± "+num2str(psigma[i])
				endfor
				notestr += "\rfollow data = "+SelectString(s.followData,"no","yes")
			SetDataFolder saveDF
		break
		case "Total Sum":
			Duplicate/Free inwave, temp; temp -= Down											// clean the data from the constant background first
			backwave[P1,P2] = Down+(Up-Down)*sum(temp,pnt2x(backwave,p),to)/sum(temp,from,to)	// Total background calculation
			
			notestr += "\rfollow data = "+SelectString(s.followData,"no","yes")
			notestr += "\rsmoothing = "+num2str(s.smoothData)
		break
		case "Shirley":
			Duplicate/Free backwave PrevShirley, Difference;	PrevShirley = Down
			do
				Difference = inwave - PrevShirley												// data minus constant background and previous Shirley iteration
				MatrixOP/O Difference = replaceNaNs(Difference,0)								// make sure there are no NaNs which disturb the sum later
				Variable KFactor = abs(Up-Down) / area(Difference,from,to)						// Shirley scale factor
				backwave[P1,P2] = KFactor*area(Difference,pnt2x(backwave,p),to)	+ Down			// Shirley background calculation
				MatrixOP/free Rest = abs(sum(PrevShirley - backwave))							// difference between the backgrounds before and after the current iteration
				i += 1
				if (i >= kMaxIterations)
					message +=  "Shirley calculation not converged. "
					backwave = NaN
					break
				endif
				PrevShirley = backwave															// save for next iteration
			while (Rest[0] > kConvergelimit*Up && i < kMaxIterations)
			message += "Iterations: "+ num2str(i)
			notestr += "\rfollow data = "+SelectString(s.followData,"no","yes")
			notestr += "\rsmoothing = "+num2str(s.smoothData)
		break
		case "Tougaard":
			DFREF inDir = GetWavesDataFolderDFR(inwave)
			Duplicate/O inwave, inDir:$(NameOfWave(inwave)+"_CS")								// prepare CS data wave
			Wave CS_Data = inDir:$(NameOfWave(inwave)+"_CS")
			SetScale/P x 0, abs(delta), CS_Data;	CS_Data = 0									// cross section data needs to be properly scaled from zero
			
			Variable Toutype = s.TouD > 0 ? -1 : 1												// see if parameter D is set; if yes the formula has to be changed in the denominator to minus
			CS_Data = (s.TouB * x) / ((s.TouC + Toutype * x^2)^2 + s.TouD * x^2)				// universal loss function
			if (numtype(s.TouSmooth) == 0 && s.TouSmooth > 0)
				CS_Data *= 0.5*(1+tanh((x-s.TouT)/s.TouSmooth))									// include band-gap parameter for insulators
			else
				CS_Data *= 0.5*(1+tanh((x-s.TouT)/kTougaardSmoothStep))							// default setting
			endif
			
			Duplicate/Free backwave Scatter;		Scatter = 0									// the scattering share per point
			backwave = 0																		// start with blank background
			for (i = 0; i < rows; i += 1)
				Scatter[0,rows-i-1] = CS_Data[p] * abs(delta) * (inwave[p+i]-Down)				// calculate the scattering from the current point on
				backwave[i] = sum(Scatter)														// sum up the current share
			endfor
			backwave += Down																	// add lower value
			
			notestr += "\rB = "+num2str(s.TouB)+"\rC = "+num2str(s.TouC)+"\rD = "+num2str(s.TouD)+"\rT0 = "+num2str(s.TouT)+"\rsmoothing = "+num2str(s.TouSmooth)
		break
		case "Tougaard Data":
			Duplicate/Free inwave, CS_Data														// prepare CS data wave
			SetScale/P x 0, abs(delta), CS_Data;	CS_Data = 0									// cross section data needs to be properly scaled from zero
			if (strlen(s.CSdata))
				Wave/Z CSWave = $s.CSdata
				if (WaveExists(CSWave))															// check if the wave and the scaling parameter are set
					CS_Data = 0
					P1 = ceil ((leftx(CSWave)-leftx(CS_Data))/deltax(CS_Data))					// start and end points for copying the provided data over
					P2 = trunc((leftx(CSWave)-leftx(CS_Data)+deltax(CSWave)*(numpnts(CSWave)-1))/deltax(CS_Data))		// boundary check
					P2 = P2 > rows-1 ? rows-1 : P2
					P1 = P1 < 0 ? 0 : P1														// protect against negative starting values
					
					if (P1 > P2)
						message += "No useful CS data found."
						backwave = NaN
						break
					endif
					if (P2 < rows - 1)
						message += "CS data range too short."
					endif
					
					CS_Data[P1,P2] = s.CSscale * CSWave(x)
				else
					backwave = NaN
					break
				endif
			endif
			
			Duplicate/Free backwave Scatter;	Scatter = 0										// the scattering share per point
			backwave = 0																		// start with blank background
			for (i = 0; i < rows; i += 1)
				Scatter[0,rows-i-1] = CS_Data[p] * abs(delta) * (inwave[p+i]-Down)				// calculate the scattering from the current point on
				backwave[i] = sum(Scatter)														// sum up the current share
			endfor
			backwave += Down																	// add lower value
			
			notestr += "\rCS wave = "+s.CSdata
			notestr += "\rCS scaling = "+num2str(s.CSscale)
		break
		default:
			message += "No such function type. Choose from: "+ReplaceString(";",RemoveEnding(kBackgroundTypes),", ")
		break
	Endswitch
	
	if (s.followData)
		Duplicate/Free inwave, temp
		if (s.smoothData > 0)
			Smooth limit(s.smoothData, 3, 20), temp
		endif
		backwave[0,P1]		= temp[p]
		backwave[P2,rows-1] = temp[p]
	endif
	
	if (strlen(notestr))																			// write notes into background wave
		notestr[0] = "\rsettings:"
	endif
	String noteheader = "function = " + s.FuncType
	noteheader += "\rstart = " + num2str(from) + " " + WaveUnits(inwave,0) + ", Y = " + num2str(Up)
	noteheader += "\rend = " + num2str(to)  + " " + WaveUnits(inwave,0) + ", Y = " + num2str(Down)
	Note/K backwave, noteheader+notestr
	
	return message
End

//################################################################################################
// EG: Not needed.
//static Function/S MenuEntry()
//	Variable fileID
//	String read = ""
//	Open/Z/R fileID as ParseFilePath(1, FunctionPath(""), ":", 1, 0)+kSettingsFileName
//	if (!V_flag)
//		do
//			FReadLine fileID, read
//		while (strlen(read) > 0 && !StringMatch(read, "start background remover*"))
//		read = ReplaceString("\t", ReplaceString(" ", read, ""), "")
//		read = StringByKey(ReplaceString(" ", "start background remover", ""),read,"=","\r")
//		Close fileID
//	endif
//	return "Background Subtraction ..."+SelectString(strlen(read),"","/"+read)
//End

//################################################################################################

Function BackgroundSubtractGUI(inwave)
	Wave/Z inwave
	if (!WaveExists(inwave))
		return -1
	endif
	if (WaveType(inwave,1) != 1 || WaveDims(inwave) > 1)										// make sure to only load 1D waves
		Abort "This tool works only for numeric 1D waves."
	endif
	//+++++++++++++++++++++++++++++++++ generate working variables ++++++++++++++++++++++++++++++
	String gTitle = "Background Remover (ver. "+num2str(kVersion)+" - "+kVersionDate+"): Background of "
	String gName = UniqueName("InelasticBackDisplay", 6, 1)
	//EG: We use Igor Pro 9  or later, we can have longer names
	String workF = "BG"+ReplaceString("InelasticBackDisplay",gName,"")+"_"+CleanupName(NameOfWave(inwave),0)
//	String workF = "BG"+ReplaceString("InelasticBackDisplay",gName,"")+"_"+CleanupName(NameOfWave(inwave),0)[0,25]
	//EG: Change to our data folder structure under Packages:MXP_DataFolder
//	NewDataFolder/O	root:Packages
//	NewDataFolder/O	root:Packages:$(kWorkingDir)
//	NewDataFolder/O	root:Packages:$(kWorkingDir):$(workF)										// the folder for temporary stuff
//	DFREF strg = root:Packages:$(kWorkingDir):$(workF)
	DFREF strg = MXP_CreateDataFolderGetDFREF("root:Packages:MXP_DataFolder:" + kWorkingDir + ":" + workF)
	
	String/G strg:InwaveLocation = GetWavesDataFolder(inwave,2)									// save wave name and folder for later
	Duplicate/O inwave strg:Data_Orig, strg:Data_Net, strg:Data_Back, strg:NegResiduals			// make copies of the original wave for all needed stuff and work with these
	Wave/SDFR=strg Data_Orig, Data_Net, Data_Back, NegResiduals
	Data_Net = NaN; Data_Back = NaN; NegResiduals = NaN
	//+++++++++++++++++++++++++++++++++++ generate the panels +++++++++++++++++++++++++++++++++++
	Variable pix = 72/ScreenResolution
	//EG: changed /K flag, some users just close the window
	Display/W=(230*pix,50*pix,1115*pix,550*pix)/K=1/N=$gName Data_Orig as gTitle + NameOfWave(inwave)
//	Display/W=(230*pix,50*pix,1115*pix,550*pix)/K=1/N=$gName Data_Orig as gTitle + NameOfWave(inwave)
	AppendToGraph/C=(0,0,65280) 							Data_Back							// the calculated background
	AppendToGraph/C=(0,39168,0) 							Data_Net							// the spectrum with subtracted background
	AppendToGraph/C=(0,0,0)/L=Lresid 						NegResiduals						// negative values of the net spectrum recalculated for display
	
	ModifyGraph mirror(left)=1, mirror(bottom)=2, standoff=0, ZisZ=1, notation(left)=1, axisOnTop=1, zero(left)=4	// make the graph nice
	ModifyGraph axisEnab(left)={0.12,1},axisEnab(Lresid)={0,0.08}													// modify axis size
	ModifyGraph freePos(Lresid)=0,mode(NegResiduals) = 1, mirror(Lresid)=1,	lblPosMode(Lresid)=1					// bar display for residuals
	SetAxis/A/E=1 Lresid
	SetAxis/A/N=1 left																			// round counts to nice values
	//++++++++++++++++++++++++++++++++++++++++ controls +++++++++++++++++++++++++++++++++++++++++
	SetWindow $gName userdata(workFolder)=workF													// save work folder location
	SetWindow $gName userdata(procVersion)=num2str(kVersion)									// save procedure version
	ControlBar 60																				// add controls
	
	Button BMinus				,pos={10,4}		,size={65,23}		,title="Subtract"			,help={"Remove current background from the data."}
	Button BUndo				,pos={10,31}	,size={65,23}		,title="Undo All"			,help={"Revert to the original data."}
	PopUpMenu BackSelect		,pos={85,6}		,size={140,20}		,title="Type:"				,help={"Select the type of background to fit."}
	SetVariable ValA			,pos={85,35}	,size={140,23}		,title="Left Cursor:"		,help={"Set the left cursor position."}
	SetVariable ValB			,pos={240,35}	,size={140,23}		,title="Right Cursor:"		,help={"Set the right cursor position."}
	SetVariable averageCurloc	,pos={240,8}	,size={140,23}		,title="Fuzzy Range:"		,help={"Percentage of total x range is used to take the average intensity as start and end."}
	Button BSave				,pos={390,4}	,size={125,23}		,title="Export Background"	,help={"Save the current background (blue) and residuals (green) next to the original data without subtracting."}
	Button BStop				,pos={390,31}	,size={125,23}		,title="Overwrite & Quit"	,help={"Overwrites the original data and close the window."}
	CheckBox cPlotOutput		,pos={525,8}	,size={143,23}		,title="Plot after Export"	,help={"Creates a plot of the exported background data together with the input."}
	
	//+++++++++++++++++++++++++++++++ individual background controls ++++++++++++++++++++++++++++	
	SetVariable VarStepPos		,pos={575,35}	,size={95,23}		,title="Step Position:"		,help={"The position of the background step."}
	SetVariable VarStepSmooth	,pos={725,35}	,size={95,23}		,title="Smoothness:"		,help={"The smoothness of the background step."}
	SetVariable VarSmoothData	,pos={575,35}	,size={95,23}		,title="Smoothing:"			,help={"The smoothness of the data outside the cursor range."}
	
	SetVariable VarPolyDegree	,pos={575,35}	,size={95,23}		,title="Poly Degree:"		,help={"Set the degree of the polynomial fit."}
	
	CheckBox VarFullLinear		,pos={525,37}	,size={143,23}		,title="Calculate over Full Range"		,help={"Calculate the linear background for the full spectrum width."}
	CheckBox VarFollowData		,pos={695,37}	,size={168,23}		,title="Follow Data outside Range: "	,help={"Makes the background identical with the smoothed original data outside the selected range."}
	
	SetVariable VarTougaardB	,pos={510,35}	,size={95,23}		,title="B:"					,help={"Parameter B (~ height) of the Tougaard universal CS."}
	SetVariable VarTougaardC	,pos={600,35}	,size={95,23}		,title="C:"					,help={"Parameter C (~ position of the maximum) of the Tougaard universal CS."}
	SetVariable VarTougaardD	,pos={690,35}	,size={95,23}		,title="D:"					,help={"Parameter D used for semi-conductors."}
	SetVariable VarTougaardCtoD	,pos={655,8}	,size={85,23}		,title="(D-4xC):"			,help={"The influence of parameter D is removed if D = 4*C."}
	SetVariable VarTougaardT	,pos={780,35}	,size={95,23}		,title="T\B0\M:"			,help={"Parameter T0 (band-gap size) used additionally for insulators."}
	SetVariable VarTouSmooth	,pos={780,8}	,size={95,23}		,title="T\B0\M Smooth:"		,help={"The smoothness of the band-gap step."}
	
	SetVariable VarCSScale		,pos={575,35}	,size={95,23}		,title="CS Scaling:"		,help={"Scales the cross section data to match the spectrum."}
	SetVariable VarExpScale		,pos={575,35}	,size={95,23}		,title="Scale Result:"		,help={"Scales the exponential function to match the spectrum."}
	PopUpMenu VarCSData			,pos={735,35}	,size={140,20}		,title="CS Data:"			,help={"Select a wave with correct cross section data for the material."}
	//+++++++++++++++++++++++++++++++++++ control modifiers ++++++++++++++++++++++++++++++++++++		
	ModifyControlList ControlNameList(gName,";","B*")							,proc=BackRem_ButtonAction
	PopUpMenu BackSelect		,bodywidth=110	,value=kBackgroundTypes			,proc=BackRem_ModeSelect
	PopUpMenu VarCSData			,bodywidth=140	,value=BackRem_CSWaveList()		,proc=BackRem_CSWaveSelect
	
	STRUCT BackRemoveStruct bs
	BackRem_InitLoadSettings(bs, inwave, gName)													// loads default settings or settings from a previous file and sets initial cursors
	
	Variable flip	= sign(DimDelta(Data_Orig,0)) == -1
	Variable left	= flip ? pnt2x(Data_Orig,numpnts(Data_Orig)-1) : Dimoffset(Data_Orig,0)		// parameters for cursor placement
	Variable right	= flip ? Dimoffset(Data_Orig,0) : pnt2x(Data_Orig,numpnts(Data_Orig)-1)		// for negative delta waves invert everything
	Variable inset	= (right-left)/100															// 1% of the wave range
	String unit = WaveUnits(Data_Orig,0)
	unit[0] = SelectString(strlen(unit),""," ")
	
	if (CmpStr(IgorInfo(2), "Macintosh") == 0)
		ModifyControlList ControlNameList(gName,";","*") fsize=10
	endif
	
	SetVariable ValA			,bodywidth=75	,limits={left,right,inset}		,format="%g" + unit	,proc=BackRem_VarChange		,disable=2*(1-flip)
	SetVariable ValB			,bodywidth=75	,limits={left,right,inset}		,format="%g" + unit	,proc=BackRem_VarChange		,disable=2*(flip)
	SetVariable averageCurloc	,bodywidth=75	,limits={0,50,0.1}				,format="%g %"		,proc=BackRem_VarChange		,value=_NUM:bs.avgPercent
	SetVariable VarStepPos		,bodywidth=65	,limits={0.1,50,0.1}			,format="%g" + unit	,proc=BackRem_VarChange		,value=_NUM:bs.stepPos
	SetVariable VarStepSmooth	,bodywidth=65	,limits={0.01,inset*50,inset}	,format="%g" + unit	,proc=BackRem_VarChange		,value=_NUM:bs.stepSmooth
	SetVariable VarSmoothData	,bodywidth=65	,limits={0,500,1}				,format="%g"		,proc=BackRem_VarChange		,value=_NUM:bs.smoothData
	SetVariable VarTougaardB	,bodywidth=65	,limits={1,inf,10}				,format="%g"		,proc=BackRem_VarChange		,value=_NUM:bs.TouB
	SetVariable VarTougaardC	,bodywidth=65	,limits={1,inf,10}				,format="%g"		,proc=BackRem_VarChange		,value=_NUM:bs.TouC
	SetVariable VarTougaardD	,bodywidth=65	,limits={0,inf,10}				,format="%g"		,proc=BackRem_VarChange		,value=_NUM:bs.TouD
	SetVariable VarTougaardCtoD	,bodywidth=55	,limits={0,inf,10}				,format="%g"		,proc=BackRem_VarChange		,value=_NUM:0			,fColor=(30000,30000,30000) ,valueColor=(30000,30000,30000)
	SetVariable VarTougaardT	,bodywidth=65	,limits={0,100,1}				,format="%g"		,proc=BackRem_VarChange		,value=_NUM:bs.TouT
	SetVariable VarTouSmooth	,bodywidth=65	,limits={0.0001,100,0.1}		,format="%g" + unit	,proc=BackRem_VarChange		,value=_NUM:bs.TouSmooth
	SetVariable VarCSScale		,bodywidth=65	,limits={0.001,inf,0.05}		,format="%g"		,proc=BackRem_VarChange		,value=_NUM:bs.CSscale
	SetVariable VarExpScale		,bodywidth=65	,limits={0.05,inf,0.05}			,format="%g"		,proc=BackRem_VarChange		,value=_NUM:bs.expScale
	SetVariable VarPolyDegree	,bodywidth=65	,limits={2,19,1}				,format="%g"		,proc=BackRem_VarChange		,value=_NUM:bs.polyDegree
	CheckBox VarFullLinear																			,proc=BackRem_CheckAction	,value=bs.fullLinear
	CheckBox VarFollowData														,side=1				,proc=BackRem_CheckAction	,value=bs.followData

	ModifyControlList ControlNameList(gName,";","Var*")		,disable=1							// hide all controls special controls
	BackRem_SwitchModeControls(bs.FuncType, gName)
	PopUpMenu BackSelect		,popmatch=bs.FuncType
	PopUpMenu VarCSData			,popmatch=bs.CSdata
	
	SetWindow $gName hook(BackCalcAction)=BackRem_WindowHook									// link the function call to the window (after the cursors has been set; otherwise eventCode == 7 will trigger)
	BackRem_BackCalc(gName)																		// initial background calculation
	DoWindow/F $gName
	return 0
End
//################################################################################################
static Function/DF getWorkFolder(gName)															// grab current working folder from graph info
	String gName
	String folder = ""
	if (strlen(gName))
		folder = GetUserData(gName,"","workFolder")
	endif
	if (strlen(folder))
	//EG: : Change to our data folder structure under Packages:MXP_DataFolder
		return root:Packages:MXP_DataFolder:$(kWorkingDir):$(folder)
	else	
		return root:Packages:MXP_DataFolder:$(kWorkingDir) 												// backwards compatibility with older sessions
	endif
End
//################################################################################################
Function BackRem_WindowHook(s)																	// main window hook
	STRUCT WMWinHookStruct &s
	Variable HookTakeover = 0, Objects = 1
	
	DFREF stg = getWorkFolder(s.winName)
	DFREF pkroot = getWorkFolder("")
	//EG: Change to our data folder structure under Packages:MXP_DataFolder
	DFREF pkg = root:Packages:MXP_DataFolder:
	Switch (s.EventCode)
		case 7:																					// cursor position was modified
			BackRem_BackCalc(s.winName)
		break
		case 8:		// graph was modified (probably axis zoom)
			HookTakeover = 1
			Wave/SDFR=stg Data_Orig
			ControlInfo/W=$s.winName ValA;	Variable Left = V_Value
			ControlInfo/W=$s.winName ValB;	Variable Right = V_Value
			Cursor/F/W=$s.winName A  Data_Orig Left,  Data_Orig(Left)							// reset the cursors to their previous x value
			Cursor/F/W=$s.winName B  Data_Orig Right, Data_Orig(Right)
		break
		case 17:	// window close button
			HookTakeover = 1
			KillWindow $s.winName
			if (CountObjectsDFR(stg, 4) == 0)													// backwards compatibility - makes sure to not kill the root folder with other open instances
				KillDataFolder/Z stg
			endif
			Objects = CountObjectsDFR(pkroot, 1)+CountObjectsDFR(pkroot, 2)+CountObjectsDFR(pkroot, 3)+CountObjectsDFR(pkroot, 4)
			if (Objects == 0 && DataFolderRefStatus(pkroot) != 0)
				KillDataFolder pkroot
			endif
			Objects = CountObjectsDFR(pkg, 1)+CountObjectsDFR(pkg, 2)+CountObjectsDFR(pkg, 3)+CountObjectsDFR(pkg, 4)
			if (Objects == 0)																	// clean up Packages folder if empty
				KillDataFolder pkg
			endif
		break
	EndSwitch
	
	return HookTakeover
End
//################################################################################################
static Function BackRem_InitLoadSettings(bs, inwave, gName)
	STRUCT BackRemoveStruct &bs
	Wave inwave
	String gName
	Wave/Z backwave = $(GetWavesDataFolder(inwave,1)+PossiblyQuoteName(NameOfWave(inwave)+"_bck"))
	
	//+++++++++++++++++++++++++++++++++ initialize parameters ++++++++++++++++++++++++++++++++++++
	BackRemoveInitialize(bs)
	Variable flip	= sign(DimDelta(inwave,0)) == -1
	Variable left	= flip ? pnt2x(inwave,numpnts(inwave)-1) : Dimoffset(inwave,0)				// parameters for cursor placement
	Variable right	= flip ? Dimoffset(inwave,0) : pnt2x(inwave,numpnts(inwave)-1)				// for negative delta waves invert everything
	Variable inset	= (right-left)/100															// 1% of the wave range
	WaveStats/Q/R = (left+10*inset,right-10*inset) inwave;		bs.stepPos = V_maxloc			// initial step position for step function
	//+++++++++++++++++++++++++++++++++ load previous settings +++++++++++++++++++++++++++++++++++
	String settings = ""
	if (WaveExists(backwave))
		settings = ReplaceString("\r",ReplaceString(" = ",note(backwave),"="),";")
	endif
	String funcType = StringByKey("function", settings, "=")
	if (strlen(funcType))
		bs.FuncType = funcType
	endif

	Variable startCur = str2num(StringByKey("start", settings, "="))
	Variable stopCur = str2num(StringByKey("end", settings, "="))
		
	if (abs(startCur-left) < 10^-3*abs(DimDelta(inwave,0)))										// start point may be slightly out-of-range because of rounding errors
		startCur = left
	endif
	if (abs(stopCur-right) < 10^-3*abs(DimDelta(inwave,0)))
		stopCur = right
	endif
	
	DoUpdate																					// update graph before placing cursors
	if (numtype(startCur) == 0 && (startCur <= right && startCur >= left))
		Cursor/F/H=2/N=1/W=$gName A  $("Data_Orig") startCur,  inwave(startCur)					// set the first cursor on the graph
	else
		Cursor/F/H=2/N=1/W=$gName A  $("Data_Orig") (left+10*inset),  inwave(left+10*inset)
	endif
	if (numtype(stopCur) == 0 && (stopCur <= right && stopCur >= left))
		Cursor/F/H=2/N=1/W=$gName B  $("Data_Orig") stopCur, inwave(stopCur)					// set the second cursor on the graph
	else
		Cursor/F/H=2/N=1/W=$gName B  $("Data_Orig") (right-10*inset), inwave(right-10*inset)
	endif
	
	String strVal = ""
	Variable numVal = NaN
	strVal = StringByKey("full line", settings, "=");				bs.fullLinear = strlen(strVal) > 0 ? StringMatch(strVal, "yes") : bs.fullLinear
	numVal = str2num(StringByKey("step position", settings, "="));	bs.stepPos = numtype(numVal) == 0 ? numVal : bs.stepPos
	numVal = str2num(StringByKey("step smoothing", settings, "="));	bs.stepSmooth = numtype(numVal) == 0 ? numVal : bs.stepSmooth
	numVal = str2num(StringByKey("exp. scale", settings, "="));		bs.expScale = numtype(numVal) == 0 ? numVal : bs.expScale
	numVal = str2num(StringByKey("poly. degree", settings, "="));	bs.polyDegree = numtype(numVal) == 0 ? numVal : bs.polyDegree
	numVal = str2num(StringByKey("B", settings, "="));				bs.TouB = numtype(numVal) == 0 ? numVal : bs.TouB
	numVal = str2num(StringByKey("C", settings, "="));				bs.TouC = numtype(numVal) == 0 ? numVal : bs.TouC
	numVal = str2num(StringByKey("D", settings, "="));				bs.TouD = numtype(numVal) == 0 ? numVal : bs.TouD
	numVal = str2num(StringByKey("T0", settings, "="));				bs.TouT = numtype(numVal) == 0 ? numVal : bs.TouT
	numVal = str2num(StringByKey("smoothing", settings, "="));		bs.TouSmooth  = numtype(numVal) == 0 && CmpStr(bs.FuncType,"Tougaard") == 0 ? numVal : bs.TouSmooth
																	bs.smoothData = numtype(numVal) == 0 && CmpStr(bs.FuncType,"Tougaard") != 0 ? numVal : bs.smoothData
	numVal = str2num(StringByKey("CS scaling", settings, "="));		bs.CSscale = numtype(numVal) == 0 ? numVal : bs.CSscale
	strVal = StringByKey("CS wave", settings, "=");					bs.CSdata = SelectString(strlen(strVal), bs.CSdata, strVal)
	strVal = StringByKey("follow data", settings, "=");				bs.followData = strlen(strVal) > 0 ? StringMatch(strVal, "yes") : bs.followData
	return 0
End
//################################################################################################
static Function BackRem_SwitchModeControls(mode, gName)
	String mode, gName

	DFREF stg = getWorkFolder(gName)
	Wave/SDFR=stg Data_Orig
	Wave/Z/SDFR=stg Data_Orig_CS
	
	if (WaveExists(Data_Orig_CS))																// clean up possible CS wave from parametric Tougaard
		KillWaves/Z Data_Orig_CS
	endif

	Variable onlyOneCursor = 0, chkver = str2num(GetUserData(gName, "", "procVersion"))			// make sure feature changes only appear in newer versions
	chkver = numtype(chkver) != 0 ? 0 : chkver
	String list = ""
	Strswitch(mode)
		case "Step":
			list = "VarStepPos;VarStepSmooth;"
		break
		case "Linear":
			list = "VarFullLinear;"
		break
		case "Exponential":
			list = SelectString(chkver>0,"","VarFollowData;")+"VarExpScale;"
		break
		case "Polynomial":
			list = SelectString(chkver>0,"","VarFollowData;")+"VarPolyDegree;"
		break
		case "Shirley":
		case "Total Sum":
			list = "VarFollowData;VarSmoothData;"
		break
		case "Constant":
			onlyOneCursor = 1
		break
		case "Tougaard":
			onlyOneCursor = 1
			list = ControlNameList(gName,";","VarTou*")
		break
		case "Tougaard Data":
			onlyOneCursor = 1
			list = "VarCSScale;VarCSData;"
		break
	Endswitch
	
	list += "ValA;ValB;"
	ModifyControlList ControlNameList(gName,";","Var*") ,win=$gName ,disable=1					// hide all controls
	ModifyControlList list ,win=$gName ,disable=0												// enable relevant controls
	
	if (onlyOneCursor)
		if (sign(DimDelta(Data_Orig,0)) == -1)
			SetVariable ValB ,win=$gName	,disable=2											// disable unused cursor (cosmetic change)
		else
			SetVariable ValA ,win=$gName	,disable=2
		endif
	endif
	return 0
End
//################################################################################################
Function BackRem_ModeSelect(s) : PopupMenuControl
	STRUCT WMPopupAction &s
	if (s.eventCode == 2)
		BackRem_SwitchModeControls(s.popStr, s.win)
		BackRem_BackCalc(s.win)
	endif
	return 0
End
//################################################################################################
Function BackRem_CheckAction (s) : CheckBoxControl
	STRUCT WMCheckboxAction &s
	if (s.eventCode == 2)
		BackRem_BackCalc(s.win)
	endif
	return 0
End
//################################################################################################
Function BackRem_CSWaveSelect(s) : PopupMenuControl
	STRUCT WMPopupAction &s
	if (s.eventCode == 2)
		BackRem_BackCalc(s.win)
	endif
	return 0
End
//+++++++++++++++++++++++++++++++++++++ popup help functions +++++++++++++++++++++++++++++++++++++
Function/S BackRem_CSWaveList()																	// create wave list for the drop down menu
	String list = "none;" + WaveList("*",";", "DIMS:1")
	return list
End
//################################################################################################
Function BackRem_ButtonAction(s) : ButtonControl
	STRUCT WMButtonAction &s
	if (s.eventCode != 2)
		return 0
	endif
	
	DFREF stg = getWorkFolder(s.win)
	Wave/SDFR=stg Data_Orig, Data_Back, Data_Net
	SVAR inwaveLoc = stg:InwaveLocation
	Wave inwave = $inwaveLoc
	DFREF inwaveDF = GetWavesDataFolderDFR(inwave)
	
	String NewNote = "Background was removed!\r"
	String AddNote = note(Data_Back)
	String inwName = NameOfWave(inwave)
	
	if (strlen(note(inwave)))
		NewNote[0] = "\r"																		// add a bit of space
	endif
	
	Strswitch(s.ctrlName)
		case "BMinus":
			Data_Orig -= Data_Back
			Note Data_Orig, NewNote+AddNote														// write the latest background info into the wave note
			Note Data_Net, NewNote+AddNote
			BackRem_BackCalc(s.win)
		break
		case "BUndo":
			Duplicate/O inwave stg:Data_Orig
			BackRem_BackCalc(s.win)
		break
		case "BSave":
			Duplicate/O stg:Data_Net  inwaveDF:$(inwName+"_net")
			Duplicate/O stg:Data_Back inwaveDF:$(inwName+"_bck")
			Note inwaveDF:$(inwName+"_net"), NewNote+AddNote
			Wave/Z CSwave = stg:Data_Orig_CS
			if(WaveExists(CSwave))
				Duplicate/O CSwave inwaveDF:$(inwName+"_scs")									// if available, copy generated Tougaard cs wave
				Note/K inwaveDF:$(inwName+"_scs"), AddNote
			endif
			
			ControlInfo/W=$s.win cPlotOutput
			if (V_Flag == 2 && V_Value == 1)													// additionally plot the output
				Wave back = inwaveDF:$(inwName+"_bck")
				Wave wnet = inwaveDF:$(inwName+"_net")
				Display/K=1/W=(200,50,700,300) inwave as "Background for " + inwName			// display the results
				AppendToGraph/C=(0,0,65280) back
				AppendToGraph/C=(0,39168,0) wnet
				ModifyGraph mirror(left)=1, mirror(bottom)=2, minor=1, standoff=0, ZisZ=1, notation(left)=1
				
				Legend/C/N=text0/B=1/F=0/A=LT													// add a legend with the settings
				String settings = ReplaceString("\r",ReplaceString(" = ",AddNote,"="),";")
				String funcType = StringByKey("function", settings, "=")
				AppendText/N=text0 funcType+" background"
				Variable split = strsearch(AddNote,"settings:",0)
				if (split > -1)
					AppendText/N=text0/NOCR ":"
					settings = AddNote[split+strlen("settings:")+1,inf]
					AppendText/N=text0 ReplaceString("\r",settings,", ")
				endif
			endif
		break
		case "BStop":
			if (!EqualWaves(Data_Orig, inwave,-1))												// compare if the wave was changed
				Duplicate/O stg:Data_Orig inwave
				Note inwave, NewNote+AddNote
			endif
			KillWindow $s.win
		break
	Endswitch
	return 0
End
//################################################################################################
Function BackRem_VarChange(s) : SetVariableControl
	STRUCT WMSetVariableAction &s
	
	if (s.eventCode == 1 || s.eventCode == 2)
		DFREF storage = getWorkFolder(s.win)
		Wave/SDFR=storage Data_Orig
		String CsrName = ""
		Strswitch(s.ctrlName)
			case "ValA":
				CsrName = SelectString(hcsr(A,s.win) > hcsr(B,s.win) , "A", "B")
			break
			case "ValB":
				CsrName = SelectString(hcsr(A,s.win) > hcsr(B,s.win) , "B", "A")
			break
			default:
				if (CmpStr(s.ctrlName,"VarTougaardCtoD") == 0)
					ControlInfo/W=$s.win VarTougaardC
					SetVariable VarTougaardD ,win=$s.win ,value=_NUM:(4*V_Value+s.dval)
				endif
				BackRem_BackCalc(s.win)
		EndSwitch
		If (strlen(CsrName))
			Cursor/F/W=$s.win $CsrName  Data_Orig s.dval, Data_Orig(s.dval)
		endif
	endif
	
	return 0
End
//################################################################################################
static Function BackRem_UpdateCursorControls(mainCur, subCur, gName)							// write cursor locations into the GUI controls
	Variable mainCur, subCur
	String gName
	Variable low  = mainCur < subCur ? mainCur : subCur
	Variable high = mainCur > subCur ? mainCur : subCur
	SetVariable VarStepPos	,win=$gName ,limits={low,high,abs(high-low)*0.01}					// set limits of step control
	SetVariable ValA 		,win=$gName ,value=_NUM:low
	SetVariable ValB 		,win=$gName ,value=_NUM:high
	return 0
End
//################################################################################################
static Function BackRem_ReadAllPanelSettings(info, gName)										// read all GUI controls
	STRUCT BackRemoveStruct &info
	String gName
	ControlInfo/W=$gName ValA;				Variable low  = V_Value
	ControlInfo/W=$gName ValB;				Variable high = V_Value
	ControlInfo/W=$gName BackSelect;		info.FuncType = S_Value
	ControlInfo/W=$gName averageCurloc;		info.avgPercent = V_Value
	ControlInfo/W=$gName VarSmoothData;		info.smoothData = V_Value
	ControlInfo/W=$gName VarStepPos;		info.stepPos = limit(V_Value, low, high)			// apply limits to the parameter
	ControlInfo/W=$gName VarStepSmooth;		info.stepSmooth = V_Value
	ControlInfo/W=$gName VarTougaardB;		info.TouB = V_Value
	ControlInfo/W=$gName VarTougaardC;		info.TouC = V_Value
	ControlInfo/W=$gName VarTougaardD;		info.TouD = V_Value
	ControlInfo/W=$gName VarTougaardT;		info.TouT = V_Value
	ControlInfo/W=$gName VarTouSmooth;		info.TouSmooth = abs(V_flag) == 5 ? V_Value : 0.5
	ControlInfo/W=$gName VarCSScale;		info.CSscale = V_Value
	ControlInfo/W=$gName VarExpScale;		info.expScale = V_Value
	ControlInfo/W=$gName VarPolyDegree;		info.polyDegree = limit(V_Value+1,3,20)				// limit the poly degree between the possible 3 and 20
	ControlInfo/W=$gName VarCSData;			info.CSdata = SelectString(!V_Disable, "", S_Value)	// get the wave to use for Tougaard calculation
	ControlInfo/W=$gName VarFollowData;		info.followData = V_Value && !V_Disable				// visible and active
	ControlInfo/W=$gName VarFullLinear;		info.fullLinear= V_Value
	ControlInfo/W=$gName VarTougaardCtoD														// added variable to control C to D relation
	if(abs(V_flag) == 5)
		SetVariable VarTougaardCtoD ,win=$gName ,value=_NUM:(info.TouD-4*info.TouC) ,limits={-4*info.TouC,inf,10}
	endif
	return 0
End
//################################################################################################
static Function BackRem_BackCalc(gName)
	String gName

	Variable mainCur, subCur
	STRUCT BackRemoveStruct bs
	GetCursorLoc(mainCur,subCur, gName)															// grab the latest cursor location and update controls
	BackRem_UpdateCursorControls(mainCur, subCur, gName)
	BackRem_ReadAllPanelSettings(bs, gName)														// read control settings into structure

	DFREF storage = getWorkFolder(gName)
	Wave/SDFR=storage Data_Orig, Data_Net, Data_Back, NegResiduals
	
	String GraphText = "\Z10\\s(Data_Orig) current spectrum"
	GraphText += "\r\\s(Data_Back) background"
	GraphText += "\r\\s(Data_Net) net spectrum"
	GraphText += "\r\\s(NegResiduals) negative values (%)"
	GraphText += "\K(65280,0,0)"																// add color to the following text
	
	GraphText += "\r" + GenerateBackground(bs, Data_Orig, Data_Back, from=mainCur, to=subCur)	// background calculation generates status messages
	Variable i
	for (i = 2; i < bs.polyDegree; i += 1)
		GraphText = ReplaceString("*x^"+num2str(i),GraphText,"x\S"+num2str(i)+"\M")				// poly background: stylize exponent
	endfor
	GraphText = ReplaceString("*x",GraphText,"x")
	
	Data_Net = Data_Orig - Data_Back															// subtract background
	NegResiduals = (Data_Net < 0) ? abs(Data_Net*100/Data_Orig) : NaN							// calculate residuals below zero
	Legend/C/N=GraphInfoBox/J/B=1/F=0/A=LT/W=$gName GraphText									// update legend box
	return 0
End
//################################################################################################
static Function GetCursorLoc(mainCur,subCur, gName)												// updates the current cursor location and gets the position
	Variable &mainCur, &subCur
	String gName
	DFREF storage = getWorkFolder(gName)
	Wave/SDFR=storage Data_Orig
	
	mainCur	= hcsr(A,gName)
	subCur	= hcsr(B,gName)
	Variable flip = sign(DimDelta(Data_Orig,0))
	if (flip*mainCur > flip*subCur)
		mainCur	= hcsr(B,gName)
		subCur	= hcsr(A,gName)
	endif
	Variable lbound  = DimOffset(Data_Orig,0)
	Variable hbound = lbound + (DimSize(Data_Orig,0)-1)*DimDelta(Data_Orig,0)
	mainCur	= flip*mainCur < flip*lbound ? lbound : mainCur
	subCur	= flip*subCur  > flip*hbound ? hbound : subCur
	return 0
End