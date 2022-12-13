#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// ------------------------------------------------------- //
// Developed by Evangelos Golias.
// Contact: evangelos.golias@gmail.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, IN CONNECTION WITH THE USE OF SOFTWARE.
// ------------------------------------------------------- //

Function/S WMExecuteShellCommand(uCommand, printCommandInHistory, printResultInHistory [, asAdmin])
	String uCommand					// Unix command to execute
	Variable printCommandInHistory
	Variable printResultInHistory
	Variable asAdmin					// Optional - defaults to 0

	if (ParamIsDefault(asAdmin))
		asAdmin = 0
	endif

	if (printCommandInHistory)
		Printf "Unix command: %s\r", uCommand
	endif

	String cmd
	sprintf cmd, "do shell script \"%s\"", uCommand
	if (asAdmin)
		cmd += " with administrator privileges"
	endif
	ExecuteScriptText/UNQ/Z cmd 	// /UNQ removes quotes surrounding reply

	if (printResultInHistory)
		Print S_value
	endif

	return S_value
End
