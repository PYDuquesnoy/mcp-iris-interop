/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.SEF.Composite Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the name
Property Name As %String;

/// This holds the consituent elements
Property Elements As EnsLib.EDI.SEF.CompositeElementList;

/// This holds the optional Relation
Property Relations As EnsLib.EDI.SEF.NodeList;

/// This method is override by subclases to generate the textual representation
/// of this node
Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write(..Name_"=")
		Set tSC=..Elements.GenerateText(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Relations'="" {
			Do pStream.Write("+")
			Set tSC=..Relations.GenerateText(pStream)
			If $$$ISERR(tSC) Quit
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This holds the optional mask list
Property Masks As EnsLib.EDI.SEF.CompositeMaskList;

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Name MUST be non-empty string
		If ..Name="" {
			Set pStatus=$$$ERROR($$$EnsEDISEFNodeValidation,"Name",..Name,..DisplayName())
		}
		
		If ..Elements.Count()'>0 {
			Set pStatus=$$$ERROR($$$EnsEDISEFNodeValidation,"Nodes (count)",..Elements.Count,..DisplayName())
		}
		
		Set tSC=..Elements.Validate(.pStatus)
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
	Set ..Elements=##class(EnsLib.EDI.SEF.CompositeElementList).%New()
	$$$ASSERTNOLOG($IsObject(..Elements))
	Quit $$$OK
}

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		#; This is the requirement of the Composite itself
		Set tRequirement=pCompiler.CurrentRequirement
		
		#; Get the ordinal
		Set tOrdinalModifier=0
		If pCompiler.SegmentModifierStack.Empty()=0
		{
			Set tOrdinalModifier=pCompiler.SegmentModifierStack.Top()
		}
		Set tOrdinal=..Parent.Ordinal+tOrdinalModifier
		
		If pCompiler.MaskActive
		{
			Set tMask=pCompiler.MaskStack.Top()
			$$$ASSERTNOLOG($IsObject(tMask))
			
			#; Make sure the mask is of the expected type
			$$$ASSERTNOLOG(tMask.%IsA("EnsLib.EDI.SEF.SegmentItemMask"))
				
			If tMask.CompositeMaskIndex'=""
			{	
				#; Use the CompositeMask index to retrieve the compositemask
				Set tCompositeMask=..Masks.GetAt(tMask.CompositeMaskIndex)
				$$$ASSERTNOLOG($IsObject(tCompositeMask))
				
				#; Make sure its the correct type
				$$$ASSERTNOLOG(tCompositeMask.%IsA("EnsLib.EDI.SEF.CompositeMask"))
				
				Do pCompiler.AddDescriptor("cb",..Name_"|"_tRequirement_"|"_tOrdinal_"|"_..Parent.StdRequirement_"|"_..Parent.RepeatCount)
			
				#; Push the available masks onto the stack in reverse order
				For tI=tCompositeMask.CompositeElementMasks.Count():-1:1
				{
					Do pCompiler.MaskStack.Push(tCompositeMask.CompositeElementMasks.GetAt(tI))
				}
				
				Set tSC=..Elements.GenerateDescriptor(pCompiler)
				If $$$ISERR(tSC) Quit
				
				Do pCompiler.AddDescriptor("ce",..Name)
				
			} else {
				
				#; The Mask is modifying the requirement of the Composite itself, not
				#; the sub-elements therein
				Do pCompiler.AddDescriptor("cb",..Name_"|"_tRequirement_"|"_tOrdinal_"|"_..Parent.StdRequirement_"|"_..Parent.RepeatCount)
		
				Set tSC=..Elements.GenerateDescriptor(pCompiler)
				If $$$ISERR(tSC) Quit
			
				Do pCompiler.AddDescriptor("ce",..Name)
			}
			
			#; Pop Mask
			Do pCompiler.MaskStack.Pop()
			
		} else {
		
			#; No Masks to manage
			Do pCompiler.AddDescriptor("cb",..Name_"|"_tRequirement_"|"_tOrdinal)
			
			Set tSC=..Elements.GenerateDescriptor(pCompiler)
			If $$$ISERR(tSC) Quit
			
			Do pCompiler.AddDescriptor("ce",..Name)
		}
		
		If $IsObject(..Relations) Set tSC=..Relations.GenerateDescriptor(pCompiler)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
