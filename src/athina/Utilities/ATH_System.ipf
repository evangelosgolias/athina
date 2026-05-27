#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma IgorVersion  = 9
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#pragma ModuleName = ATH_System

/// @module ATH_System
/// @brief Module ATH_System.
/// @details
/// This module belongs to the ATH Igor Pro toolkit and contains procedures
/// related to ATH System functionality.


/// @brief Return the amount of free memory in GB
///
/// @function GetFreeMemory
/// @brief Description of GetFreeMemory.
/// @details
/// Auto-generated documentation stub for function `GetFreeMemory`.
/// @returns Variable Return value.
static Function GetFreeMemory()
    variable freeMem
 
#if defined(IGOR64)
    freeMem = NumberByKey("PHYSMEM", IgorInfo(0)) - NumberByKey("USEDPHYSMEM", IgorInfo(0))
#else
    freeMem = NumberByKey("FREEMEM", IgorInfo(0))
#endif
 
    return freeMem / 1024 / 1024 / 1024
End