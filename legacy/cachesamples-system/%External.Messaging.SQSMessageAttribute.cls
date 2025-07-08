/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.SQSMessageAttribute Extends (%SerialObject, %JSON.Adaptor)
{

/// Key of the attribute
Property key As %String;

/// Data type. Possible values are String, Number and Binary
Property dataType As %String;

/// String value of type String and Number
Property stringValue As %String(MAXLEN = "");

/// Binary value of type Binary
Property binaryValue As %GlobalBinaryStream;

Storage Default
{
<Data name="SQSMessageAttributeState">
<Value name="1">
<Value>key</Value>
</Value>
<Value name="2">
<Value>dataType</Value>
</Value>
<Value name="3">
<Value>stringValue</Value>
</Value>
<Value name="4">
<Value>binaryValue</Value>
</Value>
</Data>
<State>SQSMessageAttributeState</State>
<StreamLocation>^%External7CA2.SQSMessageAC3BAS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
