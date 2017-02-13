; axlFunctions - Skill Functions for ADEXL
; Author: Curtis Mayberry
;
;axlPutVarList
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