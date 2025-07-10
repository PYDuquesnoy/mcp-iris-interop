/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.CodeSetList Extends EnsLib.EDI.SEF.NodeList [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "EnsLib.EDI.SEF.CodeSet";

Method CreateCodes(pCompiler As EnsLib.EDI.SEF.Compiler, pDictionaryKey As %Integer, pCreate As %Integer) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		For tI=1:1:..Count() {
			Set tSC=..GetAt(tI).CreateCodes(pCompiler,pDictionaryKey,pCreate)
			If $$$ISERR(tSC) Quit
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
