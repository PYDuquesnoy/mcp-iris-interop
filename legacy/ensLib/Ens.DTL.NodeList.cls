/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for lists of homogeneous nodes
Class Ens.DTL.NodeList Extends (%ListOfObjects, Ens.DTL.Node) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 3 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "Ens.DTL.Node";

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		For tI=1:1:..Count() {
			Set tSC=..GetAt(tI).GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream, language As %String = "") As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		For tI=1:1:..Count() {
			Set actionName = $p($CLASSNAME(..GetAt(tI)),".",*)
			Set trueActions = $lb("Code", "If","ForEach","Switch","Group", "Case" , "Default")
			If $LISTFIND(trueActions,actionName) '= 0 
			{
				Set tSC=..GetAt(tI).GenerateXML(pStream,language)
			}
			Else {
				Set tSC=..GetAt(tI).GenerateXML(pStream)
			}
			If $$$ISERR(tSC) Quit
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
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
