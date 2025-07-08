/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Document.Model.Schema.index Extends node [ System = 3 ]
{

/// Thing that this property belongs to.
Relationship collection As collection(XMLPROJECTION = "none") [ Cardinality = one, Inverse = indexes ];

Property key As %String(MAXLEN = 500, XMLPROJECTION = "attribute");

Property constraint As %String(MAXLEN = 10, XMLCHOICELIST = "idkey,primarykey,unique", XMLPROJECTION = "attribute");

/// Specifies a list of properties whose values are to be stored within this index.
Property data As %String(MAXLEN = 500, XMLPROJECTION = "attribute");

/// Specifies the type of the index.
Property type As %String(MAXLEN = 500, XMLCHOICELIST = "standard,bitmap,bitmapextent,bitslice", XMLPROJECTION = "attribute");

/// Test if this definition is valid.
Method %Validate() As %Status
{
	try {
		if (..name = "") {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Index must have a name"))
		}
		set tSC = $$$OK
	}
	Catch(ex) {
		set tSC = ex.AsStatus()
	}

	quit tSC
}

}
