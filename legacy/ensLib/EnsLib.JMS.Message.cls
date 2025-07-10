/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMS.Message Extends Ens.Request
{

/// Contains the contents of a TextMessage. Can also be set for a BytesMessage, and will be encoded if <PROPERTY>bytes</PROPERTY>
/// is empty. <CLASS>EnsLib.JMS.Service</CLASS> will set this property to the decoded contents of a received BytesMessage 
/// as long as it's length is less than the max string length.
Property text As %String(MAXLEN = "");

/// Stores contents for a BytesMessage. If this is empty and <PROPERTY>type</PROPERTY> is BytesMessage, the contents of <PROPERTY>text</PROPERTY> will be 
/// encoded to bytes using the system's default encoding scheme
Property bytes As %Stream.GlobalBinary;

Property type As %String(VALUELIST = ",TextMessage,BytesMessage") [ InitialExpression = "TextMessage" ];

Property messageId As %String(MAXLEN = "");

Property properties As array Of EnsLib.JMS.Property(XMLITEMNAME = "property", XMLKEYNAME = "key", XMLPROJECTION = "COLLECTION");

Method getNextPropertyKey(previousKey As %String = "") As %String
{
	quit ..properties.Next(previousKey)
}

Method getPropertyType(key As %String) As %String
{
	quit ..properties.GetAt(key).type
}

Method getProperty(key As %String) As %String
{
	quit ..properties.GetAt(key).value
}

Method getByteProperty(key As %String) As %String
{
	quit ..properties.GetAt(key).value
}

Method getBooleanProperty(key As %String) As %Boolean
{
	quit ..properties.GetAt(key).value
}

Method getShortProperty(key As %String) As %Integer
{
	quit ..properties.GetAt(key).value
}

Method getIntProperty(key As %String) As %Integer
{
	quit ..properties.GetAt(key).value
}

Method getIntegerProperty(key As %String) As %Integer
{
	quit ..properties.GetAt(key).value
}

Method getLongProperty(key As %String) As %Integer
{
	quit ..properties.GetAt(key).value
}

Method getFloatProperty(key As %String) As %Double
{
	quit ..properties.GetAt(key).value
}

Method getDoubleProperty(key As %String) As %Double
{
	quit ..properties.GetAt(key).value
}

Method getStringProperty(key As %String) As %String
{
	quit ..properties.GetAt(key).value
}

Method setProperty(key As %String, value As %String, type As %String = "String") As %Status
{
	do ..properties.SetAt(##class(EnsLib.JMS.Property).%New(value,type),key)
	quit $$$OK
}

Method setByteProperty(key As %String, value As %String) As %Status
{
	quit ..setProperty(key,value,"Byte")
}

Method setBooleanProperty(key As %String, value As %Boolean) As %Status
{
	quit ..setProperty(key,value,"Boolean")
}

Method setShortProperty(key As %String, value As %Integer) As %Status
{
	quit ..setProperty(key,value,"Short")
}

Method setIntProperty(key As %String, value As %Integer) As %Status
{
	quit ..setProperty(key,value,"Integer")
}

Method setIntegerProperty(key As %String, value As %Integer) As %Status
{
	quit ..setProperty(key,value,"Integer")
}

Method setLongProperty(key As %String, value As %Integer) As %Status
{
	quit ..setProperty(key,value,"Long")
}

Method setFloatProperty(key As %String, value As %Double) As %Status
{
	quit ..setProperty(key,value,"Float")
}

Method setDoubleProperty(key As %String, value As %Double) As %Status
{
	quit ..setProperty(key,value,"Double")
}

Method setStringProperty(key As %String, value As %String) As %Status
{
	quit ..setProperty(key,value,"String")
}

Storage Default
{
<Data name="MessageDefaultData">
<Subscript>"Message"</Subscript>
<Value name="1">
<Value>text</Value>
</Value>
<Value name="2">
<Value>type</Value>
</Value>
<Value name="3">
<Value>messageId</Value>
</Value>
<Value name="4">
<Value>bytes</Value>
</Value>
</Data>
<Data name="properties">
<Attribute>properties</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.JMS.Message.properties"</Subscript>
</Data>
<DefaultData>MessageDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
