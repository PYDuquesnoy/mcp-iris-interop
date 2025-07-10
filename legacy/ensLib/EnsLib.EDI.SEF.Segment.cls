/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// This represents a segment definition from the SEGS section of the SEF file
Class EnsLib.EDI.SEF.Segment Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the name of the Segment
Property Name As %String;

/// This holds the contents of the Segment, these may be elements, composites
/// or SegmentItemGroups
Property Nodes As EnsLib.EDI.SEF.NodeList;

/// This holds the optional Relation
Property Relations As EnsLib.EDI.SEF.NodeList;

/// This holds the optional mask list
Property Masks As EnsLib.EDI.SEF.SegmentMaskList;

/// This holds the table number
Property Table As %Integer;

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Name MUST be non-empty string
		If ..Name="" {
			Set pStatus=$$$ERROR($$$EnsEDISEFNodeValidation,"Name",..Name,..DisplayName())
		}
		
		If ..Nodes.Count()'>0 {
			Set pStatus=$$$ERROR($$$EnsEDISEFNodeValidation,"Nodes (count)",..Nodes.Count(),..DisplayName())
		}
		
		Set tSC=..Nodes.Validate(.pStatus)
		If $$$ISERR(tSC) Quit
		
		#; If Relation is defined, then validate
		If $IsObject(..Relations) {
			Set tSC=..Relations.Validate(.pStatus)
			If $$$ISERR(tSC) Quit
		}
		
		#; If Mask is defined, then validate
		If $IsObject(..Masks)
		{
			Set tSC=..Masks.Validate(.pStatus)
			If $$$ISERR(tSC) Quit
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status
{
	Set ..Nodes=##class(EnsLib.EDI.SEF.NodeList).%New()
	$$$ASSERTNOLOG($IsObject(..Nodes))
	Quit $$$OK
}

/// Return the in-use mask as indicated by SetSegment definition. If no mask
/// is in use, return nulloref
Method Mask() As EnsLib.EDI.SEF.SegmentMask
{
	If ..Parent.Mask'="" {
		Quit ..Masks.GetAt(..Parent.Mask)
	}
	Quit $$$NULLOREF
}

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set tMask=..Mask() 
		
		If $IsObject(tMask)
		{
			#; Set the Mask Active Flag
			Set pCompiler.MaskActive=1
			
			#; We have a mask which must be applied to each item
			#; push them onto the stack in reverse order
			For tI=tMask.ItemMasks.Count():-1:1
			{
				Do pCompiler.MaskStack.Push(tMask.ItemMasks.GetAt(tI))
			}
			
			Set tSC=..Nodes.GenerateDescriptor(pCompiler)
			
			#; Reset the Mask Active Flag
			Set pCompiler.MaskActive=0
			
		} else {
		
			#; No masks, just generate descriptor
			Set tSC=..Nodes.GenerateDescriptor(pCompiler)
		}
		If $$$ISERR(tSC) Quit
		
		If $IsObject(..Relations) Set tSC=..Relations.GenerateDescriptor(pCompiler)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
