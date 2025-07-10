/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.SegmentElement Extends EnsLib.EDI.SEF.CommonNode [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the ID
Property ID As %Integer;

/// This holds the Type
Property Type As %String;

/// Accessor for Type
Method TypeGet() As %String
{
	#; Type comes from the element definition itself
	Quit ..Element.Type
}

/// This holds the Min length
Property MinLength As %Integer;

/// Accessor for MinLength
Method MinLengthGet() As %Integer
{
	If i%MinLength'="" {
		Quit i%MinLength
	}
	#; If not overriden in segment defintion, get from element definition
	Quit ..Element.MinLength
}

/// This holds the Max Length
Property MaxLength As %Integer;

/// Accessor for MaxLength
Method MaxLengthGet() As %Integer
{
	If i%MaxLength'="" {
		Quit i%MaxLength
	}
	#; If not overriden in segment defintion, get from element definition
	Quit ..Element.MaxLength
}

/// This holds the ordinal
Property Ordinal As %Integer;

/// This holds the Element itself
Property Element As EnsLib.EDI.SEF.Element;

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Ordinal must be > 0
		If ..Ordinal'>0 {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"Ordinal",..Ordinal,..DisplayName()))
		}
		
		#; Std Requirement must be in the enumeration
		If $$$StdSegRequirement'[("|"_..StdRequirement_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,"StdRequirement",..StdRequirement,$$$StdSegRequirement))
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeIdentification,..DisplayName()))
		}
		#; Usr requirement if specified, must be in the enumeration
		If i%UsrRequirement'="" {
			If $$$UsrRequirement'[("|"_i%UsrRequirement_"|") {
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,"UsrRequirement",i%UsrRequirement,$$$UsrRequirement))
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeIdentification,..DisplayName()))
			}
		}
		
		#; Repeat Count must be a number between 1 and 999999 or the string ">1"
		If (..RepeatCount?1.N)
		{
			if ((..RepeatCount<1)||(..RepeatCount>999999)) {
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"RepeatCount",..RepeatCount,..DisplayName()))
			}
		} else {
		
			if (..RepeatCount'=">1") {
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"RepeatCount",..RepeatCount,..DisplayName()))
			}
		}
		
		Set tSC=..Element.Validate(.pStatus)
		
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
		
		Do pStream.Write("[")
		
		If i%UsrRequirement'="" {
			Do pStream.Write(i%UsrRequirement)
		}
		
		Do pStream.Write(..ID)
		
		// TO DO: Complete Implementation
		
		Do pStream.Write("]")
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// The MASK rules are very complicated and seem to be self-contradictory in places, this
/// code is best guess. TO DO: Peer review required
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Generate Element descriptor first so any codes can be materialized
		Set tSC=..Element.GenerateDescriptor(pCompiler)
		If $$$ISERR(tSC) Quit
		
		If (pCompiler.MaskActive) {
	
			If pCompiler.MaskStack.Empty()=1
			{
				#; Although Mask is active, no more mask items are
				#; available. This indicates that this item is unused
				#; so don't generate a descriptor
				Quit
			}
			
			#; Get the Current Mask
			Set tMask = pCompiler.MaskStack.Top()
			$$$ASSERTNOLOG($IsObject(tMask))
			
			#; Mask sure the mask is of the expected type
			$$$ASSERTNOLOG(tMask.%IsA("EnsLib.EDI.SEF.SegmentItemMask"))
			
			#; And that it doesn't point to a composite mask
			$$$ASSERTNOLOG(tMask.CompositeMaskIndex="")
			
			#; Get the Mask String
			Set tSC=tMask.AsString(.tMaskString)
			If $$$ISERR(tSC) Quit
			
			#; Apply the Mask
			Set tSC=..ApplyMask(tMask,.tActReq,.tMinLength,.tMaxLength,.tRepeatCount)
			If $$$ISERR(tSC) Quit
			
			#; Remove this item from the stack
			Do pCompiler.MaskStack.Pop()
		} else {
			
			Set tMaskString=""
			
			#; Use the dictionary values
			Set tActReq=..ActRequirement,tMinLength=..MinLength,tMaxLength=..MaxLength,tRepeatCount=..RepeatCount
		}
		
		Set tStdReq=..StdRequirement,tUsrReq=i%UsrRequirement
		
		Set tOrdinalModifier=0
		If (pCompiler.SegmentModifierStack.Empty()=0)
		{
			Set tOrdinalModifier=pCompiler.SegmentModifierStack.Top()
		}
	
		Set tOrdinal=..Ordinal+tOrdinalModifier
		
		Do pCompiler.AddDescriptor("e",..ID_"|"_tOrdinal_"|"_tUsrReq_"|"_tStdReq_"|"_tActReq_"|"_..Type_"|"_tMinLength_"|"_tMaxLength_"|"_tRepeatCount_"|"_tMaskString)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ApplyMask(pMask As EnsLib.EDI.SEF.SegmentItemMask, Output pRequirement As %String, Output pMinLength As %Integer, Output pMaxLength As %Integer, Output pRepeatCount As %Integer) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Initially, Use the dictionary values
		Set pMinLength=..MinLength,pMaxLength=..MaxLength,pRepeatCount=..RepeatCount
		
		If pMask.MaskType="." {
				
			#; Inherit requirement from the dictionary
			Set pRequirement=..ActRequirement
			
		} elseif pMask.MaskType="+" || (pMask.MaskType="@") {
				
			#; Used, regardless of dictionary
			Set pRequirement="M"
			
			#; Changes override
			If pMask.MinLength'="" Set pMinLength=pMask.MinLength
			If pMask.MaxLength'="" Set pMaxLength=pMask.MaxLength
			If pMask.RepeatCount'="" Set pRepeatCount=pMask.RepeatCount
				
		} elseif pMask.MaskType="#" {
				
			#; Not used, set requirement to not used
			Set pRequirement="."
		} else {
				
			#; Ignore the other masks, we don't care if it's recommended
			#; or not-recommended, we will use whats in the dictionary for requirement
			#; and accept changes if specified
			Set pRequirement=..ActRequirement
			
			#; Changes override
			If pMask.MinLength'="" Set pMinLength=pMask.MinLength
			If pMask.MaxLength'="" Set pMaxLength=pMask.MaxLength
			If pMask.RepeatCount'="" Set pRepeatCount=pMask.RepeatCount
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
