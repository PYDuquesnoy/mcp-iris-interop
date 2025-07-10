/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.CompositeElementMask Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the mask type
Property MaskType As %String;

/// This holds the StdRequirement
Property StdRequirement As %String;

/// This holds the min length
Property MinLength As %Integer;

/// This holds the max length
Property MaxLength As %Integer;

/// This holds the repeat count
Property RepeatCount As %Integer;

/// This method is override by subclases to generate the textual representation
/// of this node
Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write(..MaskType)
		
		If (..StdRequirement'="") {
			Do pStream.Write(..StdRequirement)
		}
		
		If ((..MinLength'="")||(..MaxLength'="")||(..RepeatCount'=""))
		{
			Do pStream.Write("[")
			Do pStream.Write(..MinLength)
			If ((..MaxLength'="")||(..RepeatCount'=""))
			{
				Do pStream.Write(",")
				Do pStream.Write(..MaxLength)
				
				If ..RepeatCount'="" {
					Do pStream.Write(",")
					Do pStream.Write(..RepeatCount)
				}
			}
			Do pStream.Write("]")
		}
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
		If $$$MaskType'[("|"_..MaskType_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,"MaskType",..MaskType,$$$MaskType))
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeIdentification,..DisplayName()))
		}
		
		#; StdRequirement must be in the enumeration
		If $$$StdSegRequirement'[("|"_i%StdRequirement_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,"StdRequirement",i%StdRequirement,$$$StdSegRequirement))
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeIdentification,..DisplayName()))
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
