/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents an actual code
Class EnsLib.EDI.SEF.Code Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the code value
Property Value As %String;

Method CreateCodes(pCompiler As EnsLib.EDI.SEF.Compiler, pKey As %Integer, pCreate As %Integer) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		If pCreate=1 
		{
			Set ^IRIS.Temp(pKey,..Value)=""
		} else {
			Kill ^IRIS.Temp(pKey)
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
