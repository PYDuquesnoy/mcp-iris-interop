/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.CompositeElementGroup Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the repeat RepeatCount
Property RepeatCount As %Integer;

/// This holds the contents of the group, may be elements or nested Composite Item Groups
Property Nodes As EnsLib.EDI.SEF.NodeList;

/// This method is override by subclases to generate the textual representation
/// of this node
Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("{"_..RepeatCount)
		
		Set tSC=..Nodes.GenerateText(pStream)
		If $$$ISERR(tSC) Quit
		
		Do pStream.Write("}")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set tNodes=..Nodes.Count() For tI=1:1:..RepeatCount
		{
			Do pCompiler.CompositeModifierStack.Push((tI-1)*tNodes)
			
			Set tSC=..Nodes.GenerateDescriptor(pCompiler)
			If $$$ISERR(tSC) Quit
			
			Do pCompiler.CompositeModifierStack.Pop()
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..Nodes=##class(EnsLib.EDI.SEF.NodeList).%New()
	$$$ASSERTNOLOG($IsObject(..Nodes))
	Quit $$$OK
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; RepeatCount must be > 0
		If ..RepeatCount'>0 {
			Set pStatus=$$$ERROR($$$EnsEDISEFNodeValidation,"RepeatCount",..DisplayName())
		}
		
		#; Must have at least 1 node
		If ..Nodes.Count()'>0 {
			Set pStatus=$$$ERROR($$$EnsEDISEFNodeValidation,"Nodes (Count)",..DisplayName())
		}
		
		Set tSC=..Nodes.Validate(.pStatus)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
