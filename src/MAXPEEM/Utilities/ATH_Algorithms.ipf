#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function [variable p0, variable p1, variable q0, 
		  variable q1] ATH_GetCenterNonRotatedImageBoundaries(WAVE wRef, variable value)
	/// Function returns the boundaries of a region that is surrounded/bounded 
	/// by an area with value = value. Works with 2D waves and assumes a centered
	/// rectangular non-rotated image!
	
	variable wDims = WaveDims(wRef)
	if(wDims != 2)
		return 
	endif
		
	variable idxPMax = DimSize(wRef, 0)
	variable idxQMax = DimSize(wRef, 1), i, j, bypass = 1
	
	variable midQ = DimSize(wRef, 1)/2
	for(i = 1; i < idxPMax; i+=2)
		if(wRef[i-1][midQ] == value && wRef[i][midQ] == value)
			continue
		elseif(bypass)
			p0 = i
			bypass = 0
		else
			j = i
			p1 = j - 1
		endif
	endfor
	bypass = 1 // reset bypass switch
	variable midP = DimSize(wRef, 0)/2
	for(i = 1; i < idxQMax; i+=2)
		if(wRef[midP][i-1] == value && wRef[midP][i] == value)
			continue
		elseif(bypass)
			q0 = i
			bypass = 0
		else
			j = i
			q1 = j - 1
		endif
	endfor
	return [p0, p1, q0, q1]
End