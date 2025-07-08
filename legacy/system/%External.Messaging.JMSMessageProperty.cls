/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.JMSMessageProperty Extends (%SerialObject, %JSON.Adaptor)
{

/// Property key
Property key As %String;

/// Property type: String, Boolean, Byte, Short, Integer, Long, Float, Double
Property type As %String;

/// String representation of value
Property value As %String(MAXLEN = "");

Storage Default
{
<Data name="JMSMessagePropertyState">
<Value name="1">
<Value>key</Value>
</Value>
<Value name="2">
<Value>type</Value>
</Value>
<Value name="3">
<Value>value</Value>
</Value>
</Data>
<State>JMSMessagePropertyState</State>
<StreamLocation>^%External7CA2.JMSMessagePrD60S</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
