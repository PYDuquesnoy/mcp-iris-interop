/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.ResultSet Extends %Library.ResultSet [ Deprecated, System = 4 ]
{

Method %Get(name As %String) As %String [ ProcedureBlock = 1 ]
{
	if (name '= "") && ($Data(i%Data(name))) { set rReturnValue = $get(i%Data(name)) }
	else  {
		s rReturnValue=""
	}
	quit rReturnValue
}

}
