/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents a measure within a DeepSee subject area.<br/>
Class %DeepSee.Model.SubjectArea.measure Extends %DeepSee.Model.SubjectArea.node [ Inheritance = right, System = 3 ]
{

/// Subject area that this measure belongs to.
Relationship subjectArea As %DeepSee.Model.SubjectArea.subjectArea(XMLPROJECTION = "none") [ Cardinality = one, Inverse = measures ];

/// Optional format string to apply to this member.
Property formatString As %DeepSee.Datatype.string(MAXLEN = 100, XMLPROJECTION = "attribute");

/// Hidden flag. If true, then this member will be hidden (not part of the subject area model).
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

Property listingFilter As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

Property listingFilterOperator As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Test if this measure's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK
	Quit tSC
}

}
