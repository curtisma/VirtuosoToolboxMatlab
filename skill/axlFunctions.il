; axlFunctions - Skill Functions for ADEXL
; Author: Curtis Mayberry
;
;axlPutVarList
; Adds a list of variables to an element
; Arguments
;  x_element - Handle to the database element, which can be the setup database, a corner, or a history checkpoint.
;  l_var - A list of variable name-value lists
;   e.g. for 2 variables: l_var = '(("VarName1" "VarValue1") ("VarName2" "VarValue2"))
; See Also: axlPutVar
procedure(axlPutVarList(x_element l_var "xl") 
	for(varNum 0 (length(l_var)-1)
		axlPutVar(x_element xCoord(nth(varNum l_var)) yCoord(nth(varNum l_var)))
	)
)
;axlSetCornerTestListEnabled
; Sets the enable status of a corner for a list of tests
; Arguments
;  x_cornerHandle - Handle to the corner
;  l_testNames - List of test names
;  g_enableFlag - Enable or disable status
; See Also: axlSetCornerTestEnabled
procedure(axlSetCornerTestListEnabled(x_cornerHandle l_testNames g_enableFlag "xlg") 
	for(testNum 0 (length(l_testNames)-1)
		axlSetCornerTestEnabled(x_cornerHandle nth(testNum l_testNames) g_enableFlag)
	) 
)
;axlSetCornerListTestEnabled
; Sets the enable status of a list of corners for a test
; Arguments
;  l_cornerHandle - List of handles to the corners
;  t_testName - Name of the test
;  g_enableFlag - Enable or disable status
; See Also: axlSetCornerTestEnabled
procedure(axlSetCornerListTestEnabled(l_cornerHandle t_testName g_enableFlag "ltg") 
	for(cornerNum 0 (length(l_cornerHandle)-1)
		axlSetCornerTestEnabled(nth(cornerNum l_cornerHandle) t_testName g_enableFlag)
	)
)
;axlSetAllCornerTestEnabled
; Sets the enable status of a test for all corners
; Arguments
;  x_mainSDB - Setup database handle
;  t_testName - Name of the test
;  g_enableFlag - Enable or disable status
; See Also: axlSetCornerTestEnabled
procedure(axlSetAllCornerTestEnabled(x_mainSDB t_testName g_enableFlag "xtg") 
	let((cornersList cornerH)
		cornersList = yCoord(axlGetCorners(x_mainSDB))
		for(cornerNum 0 (length(cornersList)-1)
			cornerH = axlGetCorner(x_mainSDB nth(cornerNum cornersList))
			axlSetCornerTestEnabled(cornerH t_testName g_enableFlag)
		)
	)
)
;axlSetEnabledList
; Arguments
;  l_element - list of setup database element handles. (such as a list of test and variable handles)
;  g_enable - Enable or disable status flag (disabled = nil, enabled = any other value)
;procedure(axlSetEnabledList(l_element g_enable "lg")
;	for(elementNum 0 (length(globalVars)-1)
;	axlSetEnabled(nth(elementNum l_element))
;	)
;)
;axlSetVarEnabledList
; Disables each of the global variables so that each variable is enabled/disabled rather than global variables as a whole being enabled/disabled
; Arguments
;  x_mainSDB - Setup database handle
;  l_vars - List of variable names to be enabled/disabled
;  g_enableFlag - Enable or disable status (disable = nil, enable = t or any other value)
procedure(axlSetVarEnabledList(x_mainSDB l_vars g_enableFlag "xlg")
	foreach( param l_vars
        axlSetEnabled( axlGetVar( x_mainSDB param ) g_enableFlag ))
)
;axlSetEachVarEnabled
; Disables each of the global variables so that each variable is enabled/disabled rather than global variables as a whole being enabled/disabled
; Arguments
;  x_mainSDB - Setup database handle
;  g_enableFlag - Enable or disable status (disable = nil, enable = t or any other value)
procedure(axlSetEachVarEnabled(x_mainSDB g_enableFlag "xg")
	foreach( param cadr( axlGetVars( x_mainSDB ) )
        axlSetEnabled( axlGetVar( x_mainSDB param ) g_enableFlag ))
)