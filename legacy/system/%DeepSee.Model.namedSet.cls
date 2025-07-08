/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents a named set within a DeepSee cube.<br/>
/// At query processing time, references to a named set are replaced with the
/// <property>setExpression</property> that defines the set.
Class %DeepSee.Model.namedSet Extends %DeepSee.Model.node [ System = 3 ]
{

/// Cube that this named set belongs to.
Relationship cube As %DeepSee.Model.cube(XMLPROJECTION = "none") [ Cardinality = one, Inverse = namedSets ];

/// MDX expression that defines the members of this named set.
/// This expression must evaluate to a member or set of members:
/// e.g., "[City].Members" or "[City].[Boston]".
Property setExpression As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// Test if this named set's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK
	If (..setExpression="") {
		Set tSC = $$$ERROR($$$GeneralError,"Named set must define a setExpression: " _ ..name)
	}

	Quit tSC
}

}
