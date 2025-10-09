#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_System
/// @brief Return the amount of free memory in GB
///
static Function GetFreeMemory()
    variable freeMem
 
#if defined(IGOR64)
    freeMem = NumberByKey("PHYSMEM", IgorInfo(0)) - NumberByKey("USEDPHYSMEM", IgorInfo(0))
#else
    freeMem = NumberByKey("FREEMEM", IgorInfo(0))
#endif
 
    return freeMem / 1024 / 1024 / 1024
End