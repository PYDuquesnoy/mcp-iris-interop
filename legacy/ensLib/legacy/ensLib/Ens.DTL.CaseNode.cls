/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Common superclass for nodes which can be direct children of switch statement
Class Ens.DTL.CaseNode Extends Ens.DTL.Action [ Abstract, ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the activities to be performed for this case
Property Actions As Ens.DTL.ActionList;

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Set tSC=..Actions.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Set ..Actions=##class(Ens.DTL.ActionList).%New()
		$$$ASSERT($IsObject(..Actions))

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
