/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// This is a container class for other nodes
Class EnsLib.EDI.SEF.Table Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the number (position) of the table as it appears in the SET
Property Number As %Integer;

/// This holds the nodes contained within the table, either SetSegments or SetItemGroups
/// Tables cannot be nested and therefore cannot appear in the nodelist
Property Nodes As EnsLib.EDI.SEF.NodeList;

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Table number is used for the ordinal
		Do pCompiler.AddDescriptor("t",..Number)
		
		Set tSC=..Nodes.GenerateDescriptor(pCompiler)
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
		Do pStream.Write("^")
		
		Set tSC=..Nodes.GenerateText(pStream)
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
		
		If ..Number'>0 {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"Number",..Number,..DisplayName()))
		}
		
		Set tSC=..Nodes.Validate(.pStatus)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set ..Nodes=##class(EnsLib.EDI.SEF.NodeList).%New()
		$$$ASSERTNOLOG($IsObject(..Nodes))
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
