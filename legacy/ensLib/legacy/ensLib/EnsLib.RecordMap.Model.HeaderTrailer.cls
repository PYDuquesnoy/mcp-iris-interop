/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for Header and Trailer records used in a Complex Map.
Class EnsLib.RecordMap.Model.HeaderTrailer Extends (%Library.RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/Ensemble/RecordMap";

Parameter XMLSEQUENCE = 1;

/// The name of the Header or Trailer.
Property name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// The name of the RecordMap to use.
Property recordMap As %String(MAXLEN = 220, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Comments for the Header or Trailer.
Property annotation As %String(MAXLEN = 1024);

/// Validate <property>name</property> is a valid property name, and that <property>recordMap</property>
/// refers to a RecordMap that exists.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	Set tStatus = ##class(EnsLib.RecordMap.Model.ComplexBatch).validatePropertyName(..name)
	If $$$ISERR(tStatus) Quit tStatus
	If '##class(EnsLib.RecordMap.Model.Record).Exists(..recordMap) Quit $$$ERROR($$$ClassDoesNotExist,..recordMap)
	Quit $$$OK
}

}
