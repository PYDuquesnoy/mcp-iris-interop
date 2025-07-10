/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.SEF.CodeTransactionSet Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the Transaction Set ID
Property ID As %String;

/// This holds the ordinal number of the segment that uses the code set
Property SegmentOrdinal As %Integer;

/// This holds the ordinal number of the element or composite that uses the code set
Property ItemOrdinal As %Integer;

/// This holds the ordinal number of the sub-element that uses the code set
Property SubElementOrdinal As %Integer;

/// CodeTransactionSets Determine where within a transaction set particular code sets
/// apply and are stored in $$$vaSchemaGbl("IMP"). The data is a two piece value.
/// The first "|" delmited piece is the position (code set number) in use and the second "|" delimited
/// piece is the SubElementOrdinal if the Element/Composite ordinal is actually a composite
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; No need to generate if doesn't apply to this transaction set
		If ..ID'=pCompiler.SetName Quit
		
		/// Element ID is at 2 levels up the ancestor chain
		If ..SubElementOrdinal="" {	
			Set $$$vaSchemaGbl(pCompiler.DocKey,pCompiler.SetName,"c",..Parent.Parent.ElementID,"l",..SegmentOrdinal,..ItemOrdinal)=..Parent.Position
		} else {
			Set $$$vaSchemaGbl(pCompiler.DocKey,pCompiler.SetName,"c",..Parent.Parent.ElementID,"l",..SegmentOrdinal,..ItemOrdinal,..SubElementOrdinal)=..Parent.Position
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
