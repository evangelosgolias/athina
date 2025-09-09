#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma IgorVersion = 9
#pragma ModuleName = ATH_Doctor
#pragma version = 1.0

static Function ReplaceWMSliders()
	// As of 07.10.2024 the WM sliders and relateds hooks, routines
	// are not used. Run this function to replace the old sliders 
	// with new ones in existing experiments.
	string allwindows = WinList("*",";","WIN:1"), grfName
	variable n = ItemsInList(allwindows, ";"), i
	
	for(i = 0;i < n; i++)
		grfName = StringFromList(i, allwindows)
		ControlInfo/W=$grfName WM3DAxis
		if(V_flag)
			string getSpacetagStr =GetUserData(grfName, "", "ATH_SpacesTag")
			WAVE/Z w = ATH_Graph#TopImageToWaveRef(grfName=grfName)
			KillWindow $grfName
			ATH_Display#NewImg(w,grfName=grfName)
			SetWindow $grfName userdata(ATH_SpacesTag) = getSpacetagStr
		endif
	endfor
	KillDataFolder "root:Packages:WM3DImageSlider:"
End
