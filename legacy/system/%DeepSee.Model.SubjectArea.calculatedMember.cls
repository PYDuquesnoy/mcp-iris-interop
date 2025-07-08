/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents a calculated member within a DeepSee subjectArea.<br/>
Class %DeepSee.Model.SubjectArea.calculatedMember Extends node [ System = 3 ]
{

/// Subject Area that this calculated member belongs to.
Relationship subjectArea As %DeepSee.Model.SubjectArea.subjectArea(XMLPROJECTION = "none") [ Cardinality = one, Inverse = calculatedMembers ];

/// Name of the dimension this calculated member belongs to.
/// This does not have to be an existing dimension.
Property dimension As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// MDX expression that defines the value of this calculated member.
Property valueExpression As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// Optional format string to apply to this member.
Property formatString As %DeepSee.Datatype.string(MAXLEN = 100, XMLPROJECTION = "attribute");

/// Optional. Units applied to this member (if it is a measure).<br/>
/// This is not currently used.
Property units As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Hidden flag. If true, then this calculated member will be hidden (not part of the subject area model).
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

Property listingFilter As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Test if this member's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK
	If (..dimension="") {
		Set tSC = $$$ERROR($$$GeneralError,"Calculated member must define a dimension name: " _ ..name)
	}
	Quit tSC
}

}
