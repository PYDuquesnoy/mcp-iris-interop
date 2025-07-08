/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a relationship within a DeepSee subject area.
Class %DeepSee.Model.SubjectArea.relationship Extends node [ System = 3 ]
{

/// Subject Area that this relationship belongs to.
Relationship subjectArea As %DeepSee.Model.SubjectArea.subjectArea(XMLPROJECTION = "none") [ Cardinality = one, Inverse = relationships ];

/// Hidden flag. If true, then this relationship will be hidden.
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Test if this relationship's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
