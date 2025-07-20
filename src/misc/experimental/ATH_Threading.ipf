#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

ThreadSafe Function/WAVE Worker(w3DIn, plane)
	WAVE w3DIn
	variable plane
	
	DFREF dfSav= GetDataFolderDFR()

	// Create a free data folder and set it as the current data folder
	SetDataFolder NewFreeDataFolder()
	
	// Extract the plane from the input wave into M_ImagePlane.
	// M_ImagePlane is created in the current data folder
	// which is a free data folder. 
	ImageTransform/P=(plane) getPlane, w3DIn
	Wave M_ImagePlane		// Created by ImageTransform getPlane

	// Filter the plane
	WAVE wOut= M_ImagePlane
	MatrixFilter/N=21 gauss,wOut
	
	// Restore the current data folder
	SetDataFolder dfSav

	// Since the only reference to the free data folder created above
	// was the current data folder, there are now no references it.
	// Therefore, Igor has automatically deleted it.
	// Since there IS a reference to the M_ImagePlane wave in the free
	// data folder, M_ImagePlane is not deleted but becomes a free wave.

	return wOut		// Return a reference to the free M_ImagePlane wave
End

Function Demo(numPlanes)
	Variable numPlanes

	// Create a 3D wave and fill it with data
	Make/O/N=(200,200,numPlanes) srcData= (p==(2*r))*(q==(2*r))
	
	// Create a wave to hold data folder references returned by Worker.
	// /WAVE specifies the data type of the wave as "wave reference".
	Make/WAVE/N=(numPlanes) ww

	Variable timerRefNum = StartMSTimer

	MultiThread ww= Worker(srcData,p)

	Variable elapsedTime = StopMSTimer(timerRefNum) / 1E6
	
	Printf "Statement took %g seconds for %d planes\r", elapsedTime, numPlanes
	
	// At this point, ww holds wave references to 50 M_ImagePlane free waves
	// created by Worker. Each M_ImagePlane holds the extracted and filtered
	// data for one plane of the source 3D wave.

	// Create an output wave named out3D by cloning the first filtered plane
	WAVE w= ww[0]
	Duplicate/O w, out3D
	
	// Concatenate the remaining filtered planes onto out3D
	Variable i
	for(i=1;i<numPlanes;i+=1)
		WAVE w= ww[i]
		Concatenate {w}, out3D
	endfor
	
	// Create a 3D output wave by concatenating the filtered planes
	Concatenate/O {ww}, out3D
	
	// ww holds references to the free waves. By killing ww, we kill
	// the last reference to the free waves which causes them to be
	// automatically deleted.
	KillWaves ww
End