/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.SegmentComposite Extends EnsLib.EDI.SEF.CommonNode [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the Name
Property Name As %String;

/// This holds the composite definition
Property Composite As EnsLib.EDI.SEF.Composite;

/// This holds the ordinal
Property Ordinal As %Integer;

/// This holds the ordinal spec
Property OrdinalSpec As %String;

/// The MASK rules are very complicated and seem to be self-contradictory in places, this
/// code is best guess. TO DO: Peer review required
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		If pCompiler.MaskActive {
			
			If pCompiler.MaskStack.Empty()=1
			{
				#; Although Mask is active, no more mask items are
				#; available. This indicates that this item is unused
				#; so don't generate a descriptor
				Quit
			}
			
			#; Get the Mask
			Set tMask=pCompiler.MaskStack.Top()
			
			$$$ASSERTNOLOG($IsObject(tMask))
			
			#; Make sure the mask is of the expected type
			$$$ASSERTNOLOG(tMask.%IsA("EnsLib.EDI.SEF.SegmentItemMask"))
			
			If tMask.MaskType="." {
				
				#; Inherit requirement from the dictionary
				Set tRequirement=..ActRequirement
			} elseif tMask.MaskType="+" || (tMask.MaskType="@") {
					
				#; Used, regardless of dictionary
				Set tRequirement="M"
						
			} elseif tMask.MaskType="#" {
					
				#; Not used, set requirement to not used
				Set tRequirement="."
			} else {
					
				#; Ignore the other masks, we don't care if it's recommended
				#; or not-recommended, we will use whats in the dictionary for requirement
				#; and accept changes if specified
				Set tRequirement=..ActRequirement
			}
			
		} else {
			
			#; Use the dictionary
			Set tRequirement=..ActRequirement
		}
		
		Set pCompiler.CurrentRequirement=tRequirement
		
		Set tSC=..Composite.GenerateDescriptor(pCompiler)
		If $$$ISERR(tSC) Quit
		
		Set pCompiler.CurrentRequirement=""
		
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
		
		#; Name is mandatory
		If ..Name="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"ID",..Name,..DisplayName()))
		}
		
		#; Std Requirement must be in the enumeration
		If $$$StdSegRequirement'[("|"_..StdRequirement_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,..StdRequirement,"StdRequirement",$$$StdSegRequirement))
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeIdentification,..DisplayName()))
		}
		
		#; Usr requirement if specified, must be in the enumeration
		If i%UsrRequirement'="" {
			If $$$UsrRequirement'[("|"_i%UsrRequirement_"|") {
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,i%UsrRequirement,"UsrRequirement",$$$UsrRequirement))
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
		
		#; Validate the contained composite itself
		Set tSC=..Composite.Validate(.pStatus)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
