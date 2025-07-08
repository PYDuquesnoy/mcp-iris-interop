/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents an additional expression variable within the fact table for a DeepSee cube.<br/>
/// No facts are generated for an expression; this is simply a way to define a reusable subexpression when building
/// a cube.
Class %DeepSee.Model.expression Extends (%DeepSee.Model.node, %DeepSee.Model.source) [ System = 3 ]
{

/// Cube that this expression belongs to.
Relationship cube As %DeepSee.Model.cube(XMLPROJECTION = "none") [ Cardinality = one, Inverse = expressions ];

/// Test if this index's definition is valid.
Method %Validate() As %Status
{
	// detect obvious errors
	If (..factName'="") {
		Quit $$$ERROR($$$GeneralError,"factName is not allowed for expression")
	}
	If (..displayName'="") {
		Quit $$$ERROR($$$GeneralError,"displayName is not allowed for expression")
	}
	If (..linkClass'="") {
		Quit $$$ERROR($$$GeneralError,"linkClass is not allowed for expression")
	}
	If (..linkProperty'="") {
		Quit $$$ERROR($$$GeneralError,"linkProperty is not allowed for expression")
	}
	If (..name[".") {
		// DP-403240 - Reject names that contain the '.' character to support object references
		// to expression output.
		Quit $$$ERROR($$$GeneralError,"expression name may not contain '.'")
	}

	Set tSC = $$$OK
	Quit tSC
}

}
