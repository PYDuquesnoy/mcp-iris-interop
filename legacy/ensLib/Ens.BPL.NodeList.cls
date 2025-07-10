/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for lists of homogeneous nodes
Class Ens.BPL.NodeList Extends (%ListOfObjects, Ens.BPL.Node) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 3 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "Ens.BPL.Node";

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push($Piece(..#ELEMENTTYPE,".",$Length(..#ELEMENTTYPE,"."))_"List")
	do {
		For tI=1:1:..Count() {
			Set tSC=..GetAt(tI).GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
		}
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		For tI=1:1:..Count() {
			Set tSC=..GetAt(tI).GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		For tI=1:1:..Count() {
			Set tSC=..GetAt(tI).Validate(.pStatus,pContext)
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
