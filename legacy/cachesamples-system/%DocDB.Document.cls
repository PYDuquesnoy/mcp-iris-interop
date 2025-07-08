/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DocDB.Document Extends %Persistent [ Abstract, NoExtent ]
{

Parameter USEEXTENTSET = 1;

Property %DocumentId As %Integer(MINVAL = 1) [ Identity ];

/// This property holds the document state. Serialization is JSON. 
Property %Doc As %Library.DynamicAbstractObject;

Property %LastModified As %Library.UTC [ SqlComputeCode = { set {*} = ##class(%Library.UTC).NowUTC() }, SqlComputed, SqlComputeOnChange = (%%INSERT, %%UPDATE) ];

Index IDKEY On %DocumentId [ IdKey ];

ClassMethod %Size() As %Integer [ CodeMode = objectgenerator ]
{
	if '%compiledclass.NoExtent {
		do %code.WriteLine("	&sql(select count(*) into :csize from "_%compiledclass.SqlQualifiedNameQ _ ")")
		do %code.WriteLine("	return $select(SQLCODE'<0:csize,1:0)")
	}
	return $$$OK
}

}
