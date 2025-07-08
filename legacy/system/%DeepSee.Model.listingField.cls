/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents a listing field for a DeepSee cube.
/// This provides a way for users to create a customized listing by selecting one or
/// more listing fields.
Class %DeepSee.Model.listingField Extends %DeepSee.Model.node [ System = 3 ]
{

/// Cube that this listing field belongs to.
Relationship cube As %DeepSee.Model.cube(XMLPROJECTION = "none") [ Cardinality = one, Inverse = listingFields ];

/// This is the (SQL) expression that defines this listing field.<br/>
Property fieldExpression As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Optional. The resource needed to view this listing field:<br/>
/// If defined and the current user holds the USE privilege on this resource, then
/// the user may view this listing field.<br/>
Property resource As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Test if this listing field's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	If (..fieldExpression="") {
		Set tSC = $$$ERROR($$$GeneralError,"A listing field must specify a field expression:" _ ..name)
	}

	Quit tSC
}

}
