/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// Represents a Segment referenced in a SET
Class EnsLib.EDI.SEF.SetSegment Extends EnsLib.EDI.SEF.CommonNode [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the position modifier
Property PositionModifier As %String;

/// This holds the segment name
Property Name As %String;

/// This is the optional mask spec
Property Mask As %Integer;

/// This holds the GroupTrigger flag
Property GroupTrigger As %Boolean [ InitialExpression = 0 ];

/// This holds the ordinal spec
Property OrdinalSpec As %String;

/// This holds the calculated ordinal number within
/// the SET definition
Property Ordinal As %Integer;

/// This holds the calculated position number within
/// the SET definition
Property Position As %Integer;

/// This holds the the Segment parsed from the corresponding segment definition
/// from the .SEGS section of the SEF file
Property Segment As EnsLib.EDI.SEF.Segment;

/// Accessor for RepeatCount. The repeat count for the first segment in a loop or group 
/// (group trigger) is always 1, regardless of what is specified in the maximum field in the
/// SEF file. If the repeat count for such a segment is ommitted, or coded as something else, 
/// it should nevertheless be interpreted as 1
Method RepeatCountGet() As %String
{
	If ..GroupTrigger=1 Quit 1
	Quit i%RepeatCount
}

/// This method is override by subclases to generate the textual representation
/// of this node
Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Optional PositionModifier
		If ..PositionModifier'=""
		{
			If ..PositionModifier'<0 {
				Do pStream.Write("+"_..PositionModifier)
			} else {
				Do pStream.Write(..PositionModifier)
			}
		}
		Do pStream.Write("[")
		
		If ..UsrRequirement'="" Do pStream.Write(..UsrRequirement)
		
		#; Name is mandatory
		Do pStream.Write(..Name)
		
		#; Mask
		If ..Mask'="" Do pStream.Write("*"_..Mask)
		
		#; Ordinal spec
		If ..OrdinalSpec'="" Do pStream.Write("@"_..OrdinalSpec)
		
		If ..StdRequirement'="" {
			Do pStream.Write(","_..StdRequirement)
		}
		
		If i%RepeatCount'="" {
			
			If ..StdRequirement="" {
				Do pStream.Write(",,"_i%RepeatCount)
			} else {
				Do pStream.Write(","_i%RepeatCount)
			}
		}
		
		Do pStream.Write("]")
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
	
		#; Record the name,ordinal,requirement and repeat count
		if (..GroupTrigger=1) {
			Set tActRequirement="M"
		} else {
			Set tActRequirement=..ActRequirement
		}
		Set tDescriptor=..Name_"|"_..Ordinal_"|"_..Position_"|"_i%UsrRequirement_"|"_..StdRequirement_"|"_tActRequirement_"|"_..RepeatCount
		
		#; If the segment is binary record where the binary section and the length is
		If ..Name="BIN" {
			Set $Piece(tDescriptor,"|",9)=1 // element containing length, data follows
		} elseif ..Name="BDS" {
			Set $Piece(tDescriptor,"|",9)=2 // element containing length, data follows
		}
		Do pCompiler.AddDescriptor("s",tDescriptor)
		
		Set tSC=..Segment.GenerateDescriptor(pCompiler)
		
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
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"Name",..Name,..DisplayName()))
		}
		
		#; Mask must be empty string or an integer
		If ..Mask'="",..Mask'?1.N {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"Mask",..Mask,..DisplayName()))
		}
		
		#; Ordinal must be a number > 0
		If ..Ordinal'>0 {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"Ordinal",..Ordinal,..DisplayName()))
		}
		
		#; Position must be a number > 0
		If ..Position'="",(..Position'>0) {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"Position",..Position,..DisplayName()))
		}
		
		#; Std Requirement must be in the enumeration
		If $$$StdSetRequirement'[("|"_..StdRequirement_"|") {
			
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,"StdRequirement",..StdRequirement,$$$StdSetRequirement))
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
		
		Set tSC=..Segment.Validate(.pStatus)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
