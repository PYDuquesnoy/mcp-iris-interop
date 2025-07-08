/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents an error in OAuth 2.0
Class %OAuth2.Error Extends %SerialObject [ System = 4 ]
{

/// The error type.
Property Error As %String(MAXLEN = 1024);

/// The optional long error description.
Property ErrorDescription As %String(MAXLEN = 2048);

/// The optional URI for more error detail.
Property ErrorUri As %String(MAXLEN = 1024);

Method %OnNew(error As %String, desc As %String, uri As %String) As %Status [ Internal, Private ]
{
	Set ..Error=$get(error)
	Set ..ErrorDescription=$get(desc)
	Set ..ErrorUri=$get(uri)
	Quit $$$OK
}

/// Return a string representing this object
Method AsString() As %String
{
	Set errorText="error="_..Error
	If ..ErrorDescription'="" {
		Set errorText=errorText_", error_description="_..ErrorDescription
	}
	If ..ErrorUri'="" {
		Set errorText=errorText_", error_uri="_..ErrorUri
	}
	Quit errorText
}

Storage Default
{
<Data name="ErrorState">
<Value name="1">
<Value>Error</Value>
</Value>
<Value name="2">
<Value>ErrorDescription</Value>
</Value>
<Value name="3">
<Value>ErrorUri</Value>
</Value>
</Data>
<State>ErrorState</State>
<StreamLocation>^%OAuth2.ErrorS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
