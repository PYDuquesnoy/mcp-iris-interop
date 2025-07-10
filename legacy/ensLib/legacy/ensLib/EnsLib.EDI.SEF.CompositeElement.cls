/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.CompositeElement Extends EnsLib.EDI.SEF.CommonNode [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the ID
Property ID As %Integer;

/// This holds the Min length (if different from the underlying standard)
Property MinLength As %Integer;

/// Accessor for MinLength
Method MinLengthGet() As %Integer
{
	If i%MinLength'="" Quit i%MinLength
	Quit ..Element.MinLength
}

/// This holds the Max Length (if different from the underlying standard)
Property MaxLength As %Integer;

/// Accessor for MaxLength
Method MaxLengthGet() As %Integer
{
	If i%MaxLength'="" Quit i%MaxLength
	Quit ..Element.MaxLength
}

/// This holds the ordinal
Property Ordinal As %Integer;

/// This holds the Element itself
Property Element As EnsLib.EDI.SEF.Element;

/// This holds the Type
Property Type As %String;

/// Accessor for Type
Method TypeGet() As %String
{
	#; Type comes from the element definition itself
	Quit ..Element.Type
}

/// Accessor for RepeatCount
Method RepeatCountGet() As %String
{
	#; Repeat counts aren't used for composites, but return 1
	#; to pass generic validation in base EnsLib.EDI.SEF.CommonNode
	Quit 1
}

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
		If $$$StdSegRequirement'[("|"_i%StdRequirement_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,"StdRequirement",i%StdRequirement,$$$StdSegRequirement))
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeIdentification,..DisplayName()))
			
		}
		#; Usr requirement if specified, must be in the enumeration
		If i%UsrRequirement'="" {
			If $$$UsrRequirement'[("|"_i%UsrRequirement_"|") {
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,"UsrRequirement",$$$UsrRequirement,i%UsrRequirement))
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

Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		#; Generate Element descriptor first so any codes can be materialized
		Set tSC=..Element.GenerateDescriptor(pCompiler)
		If $$$ISERR(tSC) Quit
		
		#; Use the dictionary values
		Set tMinLength=..MinLength,tMaxLength=..MaxLength,tRepeatCount=1
		
		If (pCompiler.MaskActive) {
	
			If pCompiler.MaskStack.Empty()=1
			{
				#; Although Mask is active, no more mask items are
				#; available. This indicates that this item is unused
				#; so don't generate a descriptor
				Quit
			}
	
			Set tMask=pCompiler.MaskStack.Top()
			$$$ASSERTNOLOG($IsObject(tMask))
			
			#; Only apply mask if it is of the correct type
			If tMask.%IsA("EnsLib.EDI.SEF.CompositeElementMask")
			{
				#; Get the Mask as a string
				Set tSC=tMask.AsString(.tMaskString)
				If $$$ISERR(tSC) Quit
				
				If tMask.MaskType="." {
						
					#; Inherit requirement from the dictionary
					Set tActReq=..ActRequirement
					
				} elseif tMask.MaskType="+" || (tMask.MaskType="@") {
						
					#; Used, regardless of dictionary
					Set tActReq="M"
					
					#; Changes override
					If tMask.MinLength'="" Set tMinLength=tMask.MinLength
					If tMask.MaxLength'="" Set tMaxLength=tMask.MaxLength
					If tMask.RepeatCount'="" Set tRepeatCount=tMask.RepeatCount
						
				} elseif tMask.MaskType="#" {
						
					#; Not used, set requirement to not used
					Set tActReq="."
				} else {
						
					#; Ignore the other masks, we don't care if it's recommended
					#; or not-recommended, we will use whats in the dictionary for requirement
					#; and accept changes if specified
					Set tActReq=..ActRequirement
					
					#; Changes override
					If tMask.MinLength'="" Set tMinLength=tMask.MinLength
					If tMask.MaxLength'="" Set tMaxLength=tMask.MaxLength
					If tMask.RepeatCount'="" Set tRepeatCount=tMask.RepeatCount
				}
				
				#; Remove this item from the stack
				Do pCompiler.MaskStack.Pop()
				
			} else {
					
				#; Although we are a part of a composite, a composite mask is not active,
				#; test the SegmentMask to see if whole composite is suppressed			
				Set tMaskString=""
			
				If tMask.MaskType="#" {
					Set tActReq="."
				} else {
					Set tActReq=..ActRequirement
				}
				#; Use the dictionary values
				Set tMinLength=..MinLength,tMaxLength=..MaxLength,tRepeatCount=..RepeatCount
			}			
				
		} else {
			
			Set tMaskString=""
			
			#; Use the dictionary values
			Set tActReq=..ActRequirement,tMinLength=..MinLength,tMaxLength=..MaxLength,tRepeatCount=..RepeatCount
		}
		
		Set tStdReq=..StdRequirement,tUsrReq=i%UsrRequirement
		
		Set tOrdinalModifier=0
		If (pCompiler.CompositeModifierStack.Empty()=0)
		{
			Set tOrdinalModifier=pCompiler.CompositeModifierStack.Top()
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

}
