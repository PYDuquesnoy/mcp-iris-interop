/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class holds a collection of <compensationhandler> activities and should not be used directly in user code.
Class Ens.BPL.CompensationHandlerList Extends Ens.BPL.NodeList [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "Ens.BPL.CompensationHandler";

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push($Piece(..#ELEMENTTYPE,".",$Length(..#ELEMENTTYPE,"."))_"List")
	do {
		
		// Kill the compensation handlers
		Kill pCompiler.CompensationHandlers
		
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

}
