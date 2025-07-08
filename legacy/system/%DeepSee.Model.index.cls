/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents an additional index within the fact table for a DeepSee cube.<br/>
/// The DeepSee engine does not make use of such indices, but an application may have need of extra indices.
Class %DeepSee.Model.index Extends %DeepSee.Model.node [ System = 3 ]
{

/// Cube that this index belongs to.
Relationship cube As %DeepSee.Model.cube(XMLPROJECTION = "none") [ Cardinality = one, Inverse = indices ];

/// Property list for the index.
Property properties As %DeepSee.Datatype.string(MAXLEN = 500, XMLPROJECTION = "attribute");

/// Type of index.
Property type As %DeepSee.Datatype.string(VALUELIST = ",bitmap,bitslice,index,key", XMLPROJECTION = "attribute");

/// Test if this index's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK
	If (..properties="") {
		Set tSC = $$$ERROR($$$GeneralError,"index must specify properties: " _ ..name)
	}
	Quit tSC
}

}
