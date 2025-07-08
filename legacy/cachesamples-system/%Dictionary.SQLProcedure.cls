/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.SQLProcedure [ Abstract, System = 4 ]
{

ClassMethod GetParameterValue(parameters, param) As %String [ SqlName = GetParameterValue, SqlProc ]
{
	set value=""
	for i=1:1:$ll(parameters) {
		if $li($li(parameters,i),1)=param set value=$li($li(parameters,i),2) quit
	}
	quit value
}

}
