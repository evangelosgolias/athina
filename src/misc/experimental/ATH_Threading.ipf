#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_Threads

ThreadSafe Function/WAVE DriftCorrelation_Worker(WAVE w3D, WAVE w3dPart,
					WAVE w3dPartRef, variable refP, 
					variable refQ, variable plane, [int subPixel])
	subPixel = ParamIsDefault(subPixel) ? 0 : !!subPixel
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	
	// Extract the plane from the input wave into M_ImagePlane.
	// M_ImagePlane is created in the current data folder
	// which is a free data folder. 

	ImageTransform/P=(plane) getPlane w3dPart
	Wave M_ImagePlane		// Created by ImageTransform getPlane
	MatrixOP/O/FREE correlationW = correlate(w3dPartRef, M_ImagePlane, 0)
	WaveStats/M=1/Q/P correlationW
	variable pD = V_maxRowLoc
	variable qD = V_maxColLoc
	variable driftP = refP - pD
	variable driftQ = refQ - qD

	if(!subPixel) // round to the nearest pixel
		driftP = round(driftP)
		driftQ = round(driftQ)
	endif
	
	ImageTransform/P=(plane) getPlane w3D
	Wave M_ImagePlane
	ImageInterpolate/APRM={1,0,driftP,0,1,driftQ,1,0} Affine2D M_ImagePlane
	WAVE M_Affine
	// Restore the current data folder
	SetDataFolder dfSav

	// Since the only reference to the free data folder created above
	// was the current data folder, there are now no references it.
	// Therefore, Igor has automatically deleted it.
	// Since there IS a reference to the M_ImagePlane wave in the free
	// data folder, M_ImagePlane is not deleted but becomes a free wave.

	return M_Affine		// Return a reference to the free M_Affine wave
End

Function MultiThreadCorrelationDriftCorrection(WAVE w3D, 
	 	 WAVE w3dPart, variable ref, [int subPixel])
	// Create a 3D wave and fill it with data
	//Make/O/N=(2048,2048,numPlanes) srcData= (p==(2*r))*(q==(2*r))
	
	// Create a wave to hold data folder references returned by Worker.
	// /WAVE specifies the data type of the wave as "wave reference".
	variable numPlanes = DimSize(w3d,2)
	Make/WAVE/N=(numPlanes) ww

	variable timerRefNum = StartMSTimer
	// Get reference stuff ready.
	ImageTransform/P=(ref) getPlane w3dPart
	Wave M_ImagePlane
	MatrixOP/FREE correlationW = correlate(M_ImagePlane, M_ImagePlane, 0)
	WaveStats/M=1/Q/P correlationW	
	variable refP = V_maxRowLoc
	variable refQ = V_maxColLoc
	KillWaves M_ImagePlane
	// Done
	
	// Release the threads.
	MultiThread ww = DriftCorrelation_Worker(w3D, w3dPart, M_ImagePlane, refP, refQ, p)

	Variable elapsedTime = StopMSTimer(timerRefNum) / 1E6
	
	Printf "Statement took %g seconds for %d planes\r", elapsedTime, numPlanes
	
	// At this point, ww holds wave references to 50 M_ImagePlane free waves
	// created by Worker. Each M_ImagePlane holds the extracted and filtered
	// data for one plane of the source 3D wave.

	// Create an output wave named out3D by cloning the first filtered plane
//	WAVE w= ww[0]
//	Duplicate/O w, w3D
//	
//	// Concatenate the remaining filtered planes onto out3D
//	Variable i
//	for(i=1;i<numPlanes;i+=1)
//		WAVE w= ww[i]
//		Concatenate {w}, out3D
//	endfor
	
	// Create a 3D output wave by concatenating the filtered planes
	Concatenate/O {ww}, w3D
	
	// ww holds references to the free waves. By killing ww, we kill
	// the last reference to the free waves which causes them to be
	// automatically deleted.
	KillWaves ww
End