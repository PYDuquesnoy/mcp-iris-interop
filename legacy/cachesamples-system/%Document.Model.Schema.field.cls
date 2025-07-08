/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Document.Model.Schema.field Extends node [ System = 3 ]
{

/// Thing that this property belongs to.
Relationship collection As collection(XMLPROJECTION = "none") [ Cardinality = one, Inverse = fields ];

Property derived As %ZEN.Datatype.boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

Property expression As %String(MAXLEN = 4000, XMLPROJECTION = "ELEMENT");

Property required As %ZEN.Datatype.boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

Property fieldType As %String(MAXLEN = 255, XMLCHOICELIST = "dynamic,static", XMLPROJECTION = "attribute");

Property type As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Test if this definition is valid.
Method %Validate() As %Status
{
	try {
		if (..name = "") {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Field must have a name"))
		}
		set tSC = $$$OK
	}
	Catch(ex) {
		set tSC = ex.AsStatus()
	}

	quit tSC
}

}
