/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents a named set within a DeepSee subjectArea.<br/>
Class %DeepSee.Model.SubjectArea.namedSet Extends node [ System = 3 ]
{

/// Subject Area that this named set belongs to.
Relationship subjectArea As %DeepSee.Model.SubjectArea.subjectArea(XMLPROJECTION = "none") [ Cardinality = one, Inverse = namedSets ];

/// MDX expression that defines the members of this named set.
/// This expression must evaluate to a member or set of members:
/// e.g., "[City].Members" or "[City].[Boston]".
Property setExpression As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Hidden flag. If true, then this named set will be hidden (not part of the subject area model).
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Test if this named set's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK
	If ('..hidden&&(..setExpression="")) {
		Set tSC = $$$ERROR($$$GeneralError,"Named set must define a setExpression: " _ ..name)
	}

	Quit tSC
}

}
