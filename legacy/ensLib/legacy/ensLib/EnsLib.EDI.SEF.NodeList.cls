/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.NodeList Extends (%ListOfObjects, EnsLib.EDI.SEF.Node) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "EnsLib.EDI.SEF.Node";

Parameter TEXTDELIMITER;

/// In general, nodes are NOT groups
Method IsGroup() As %Boolean
{
	Quit 0
}

Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		For tI=1:1:..Count() {
			Set tSC=..GetAt(tI).GenerateDescriptor(pCompiler)
			If $$$ISERR(tSC) Quit
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set tCount=..Count()
		For tI=1:1:tCount {
			Set tSC=..GetAt(tI).GenerateText(pStream)
			If $$$ISERR(tSC) Quit
			
			If tI'=tCount {
				Do pStream.Write(..#TEXTDELIMITER)
			}
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GetSegment(pTable As %Integer, pOrdinal As %Integer, pSegName As %String, Output pSegment As EnsLib.EDI.SEF.Segment) As %String
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		For tI=1:1:..Count() {
			Set tSC=..GetAt(tI).GetSegment(pTable,pOrdinal,pSegName,.pSegment)
			If $$$ISERR(tSC) Quit
			
			If $IsObject(pSegment) Quit
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method Validate(ByRef pStatus As %Status) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		For tI=1:1:..Count() {
			Set tSC=..GetAt(tI).Validate(.pStatus)
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
