/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Common class for request/response specifications
Class Ens.BPL.Message Extends Ens.BPL.Node [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the type of the target of the assignments
Property Type As %String;

/// This holds the (restricted) Activities
Property Activities As Ens.BPL.ActivityList;

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set ..Activities=##class(Ens.BPL.ActivityList).%New()
		$$$ASSERT($IsObject(..Activities))
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
