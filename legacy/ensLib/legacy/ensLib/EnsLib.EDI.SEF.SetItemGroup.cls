/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// This represents a Group found within a SET definition, groups consist
/// of either SetSegments or SetItemGroups
Class EnsLib.EDI.SEF.SetItemGroup Extends EnsLib.EDI.SEF.CommonNode [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the group identifier
Property Name As %String;

/// This holds the ordinal. It will be used if the standard has the ',LS' record
Property Ordinal As %Integer;

/// This holds the OrdinalSpec. It can be used to modify the Ordinal Sequence when
/// a group has been inserted into a pre-existing SET definiton
Property OrdinalSpec As %Integer;

/// This holds the calculated position number within
/// the SET definition. It will be used if the standard has the ',LS' record
Property Position As %Integer;

/// This holds the position modifier. It can be used to modify the Position Sequence when
/// a group has been inserted into a pre-existing SET definiton
Property PositionModifier As %String;

/// This holds the Trigger Segment Definition
Property TriggerSegment As EnsLib.EDI.SEF.SetSegment;

/// This holds the nodes contained within the table (SetSegments or nested SetItemGroups)
Property Nodes As EnsLib.EDI.SEF.NodeList;

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; RULE: The Requirement for the First Segment ( group trigger )
		#; is AlWAYS assumed to be 'M'. The group triggers Requirement property
		#; refers to the Group AS A WHOLE
		#; 
		#; RULE: The Modifier for the First Segment ( group trigger) refers
		#; to the Group AS A WHOLE
		Set tLoopRequirement=..TriggerSegment.ActRequirement
		
		#; Transform according to rules
		Set tLoopRequirement=$Case(tLoopRequirement,"!":"M","$":"O","-":"O","&":"O",:tLoopRequirement)
		
		#; Add a loop begin descriptor 
		Do pCompiler.AddDescriptor("lb",..Name_"|"_..Ordinal_"|"_tLoopRequirement_"|"_..RepeatCount_"|"_..Position_"|"_..TriggerSegment.Name,.tLBDescriptorIndex)
		
		Set tSC=..TriggerSegment.GenerateDescriptor(pCompiler)
		If $$$ISERR(tSC) Quit
		
		Set tSC=..Nodes.GenerateDescriptor(pCompiler)
		If $$$ISERR(tSC) Quit
		
		#; Add a loop end descriptor
		Do pCompiler.AddDescriptor("le",..Name_"|"_tLBDescriptorIndex,.tLEDescriptorIndex)
		
		Do pCompiler.UpdateDescriptor(tLBDescriptorIndex,8,tLEDescriptorIndex+1)
		
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
		
		#; If Ordinal is present then it must be a number > 0
		If ..Ordinal'="",(..Ordinal'>0) {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"Ordinal",..Ordinal,..DisplayName()))
		}
		
		#; If OrdinalSpec is present then it must be a number > 0
		If ..OrdinalSpec'="",(..OrdinalSpec'>0) {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"OrdinalSpec",..OrdinalSpec,..DisplayName()))
		}
		
		#; If Position is present then it must be a number > 0
		If ..Position'="",(..Position'>0) {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"Position",..Position,..DisplayName()))
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
		
		#; Repeat Count must be a number between 1 and 9999999 or the string ">1"
		If (..RepeatCount?1.N)
		{
			if ((..RepeatCount<1)||(..RepeatCount>9999999)) {
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"RepeatCount",..RepeatCount,..DisplayName()))
			}
		} else {
		
			if (..RepeatCount'=">1") {
				Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"RepeatCount",..RepeatCount,..DisplayName()))
			}
		}
			
		Set tSC=..TriggerSegment.Validate(.pStatus)
		If $$$ISERR(tSC) Quit
		
		Set tSC=..Nodes.Validate(.pStatus)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This is the accessor for the groups Name
Method NameGet() As %String
{
	#; The name for a group is derived from the 
	#; name of the first (trigger) segment IF the name
	#; has NOT been overriden in the SEF file loop definition
	If i%Name="" {
		$$$ASSERTNOLOG($IsObject(..TriggerSegment))
		Quit ..TriggerSegment.Name
	}
	Quit i%Name
}

/// This is the accessor for the groups requirement
Method StdRequirementGet() As %String
{
 
	#; The requirement for a group is derived from the 
	#; requirement for the first segment
	$$$ASSERTNOLOG($IsObject(..TriggerSegment))
	Quit ..TriggerSegment.StdRequirement
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
		
		If ..OrdinalSpec'="" {
			Do pStream.Write("@",..OrdinalSpec)
		}
		
		Do pStream.Write("{")
		
		If ..Name'="" Do pStream.Write(..Name)
		
		If ..RepeatCount'="" Do pStream.Write(":"_..RepeatCount)
		
		Set tSC=..TriggerSegment.GenerateText(pStream)
		If $$$ISERR(tSC) Quit
		
		Set tSC=..Nodes.GenerateText(pStream)
		If $$$ISERR(tSC) Quit
		
		Do pStream.Write("}")
		
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
