/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.ManagerQuery [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// This method is deprecated.
ClassMethod GetHomePageValue(pKeyword = "") As %String
{
	quit ""
}

ClassMethod GetSqlResultSet(Output pResultSet, pSqlStatement, pArg1, pArg2, pArg3, pArg4, pArg5, pArg6, pArg7, pArg8) As %Status
{
	set pResultSet=##class(%ResultSet).%New()
	set tSC=pResultSet.Prepare(pSqlStatement) quit:$$$ISERR(tSC) tSC
	set tSC=pResultSet.Execute(.pArg1,.pArg2,.pArg3,.pArg4,.pArg5,.pArg6,.pArg7,.pArg8)
	quit tSC
}

}
