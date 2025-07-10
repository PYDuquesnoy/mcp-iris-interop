/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMS.Property Extends (%SerialObject, %XML.Adaptor)
{

Property value As %String(MAXLEN = "", XMLPROJECTION = "CONTENT");

Property type As %String(XMLPROJECTION = "ATTRIBUTE");

Method %OnNew(value As %String = "", type As %String = "String") As %Status [ Private, ServerOnly = 1 ]
{
	set ..value = value
	set ..type = type
	Quit $$$OK
}

Storage Default
{
<Data name="PropertyState">
<Value name="1">
<Value>value</Value>
</Value>
<Value name="2">
<Value>type</Value>
</Value>
</Data>
<State>PropertyState</State>
<StreamLocation>^EnsLib.JMS.PropertyS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
