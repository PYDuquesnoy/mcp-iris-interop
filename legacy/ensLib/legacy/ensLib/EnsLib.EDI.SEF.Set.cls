/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// Represents the transaction set
Class EnsLib.EDI.SEF.Set Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the name ( or number ) of the transaction set
Property Name As %String;

/// This holds the list of nodes for this set definition, this can consist
/// of Table, SetSegment and SetItemGroup definitions
Property Nodes As EnsLib.EDI.SEF.NodeList;

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
	
		#; Set the current SetName
		Set pCompiler.SetName=..Name,pCompiler.StructureIndex=0
		
		#; Delete old definitions
		Kill $$$vaSchemaGbl(pCompiler.DocKey,pCompiler.SetName)
		Set $$$vaSchemaGbl(pCompiler.DocKey,pCompiler.SetName)=$P($$$vaSchemaGbl(pCompiler.DocKey),"|",4) // !!! get per-set description if available
		
		Set tSC=..Nodes.GenerateDescriptor(pCompiler)
		
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

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	Quit "Set Definition"
}

/// This method is override by subclases to generate the textual representation
/// of this node
Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write(..Name_"=")
		
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
		#; Name MUST be non-empty string
		If ..Name="" {
			Set pStatus=$$$ERROR($$$EnsEDISEFNodeValidation,"Name",..Name,..DisplayName())
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
