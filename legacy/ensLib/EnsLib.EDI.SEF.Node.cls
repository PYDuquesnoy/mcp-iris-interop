/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// Represents a node in the parse tree
Class EnsLib.EDI.SEF.Node Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds a reference to the parent node of this node. Only the root
/// node of the parse tree will have no parent
Property Parent As EnsLib.EDI.SEF.Node;

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		$$$ASSERTNOLOG("0:Subclass Responsibility")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method is override by subclases to generate the textual representation
/// of this node
Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		$$$ASSERTNOLOG("0:Subclass Responsibility")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		// Nothing to do
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	Quit $classname()
}

Method IsGroup() As %Boolean
{
	Quit 0
}

Method OutputTextToDevice() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set tStream=##class(%GlobalCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		Set tSC=..GenerateText(tStream)
		If $$$ISERR(tSC) Quit
		
		Do tStream.OutputToDevice()
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method AsString(Output pString) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set tStream=##class(%GlobalCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		Set tSC=..GenerateText(tStream)
		If $$$ISERR(tSC) Quit
		
		Set pString=tStream.Read(32767)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method Ancestor(pType As %String) As EnsLib.EDI.SEF.Node
{
	Set tNode=$this,tFound=0
	While ($IsObject(tNode.Parent))
	{
		Set tNode=tNode.Parent
		If tNode.%IsA(pType) Set tFound=1 Quit
	}
	Quit $Select(tFound:tNode,1:$$$NULLOREF)
}

}
