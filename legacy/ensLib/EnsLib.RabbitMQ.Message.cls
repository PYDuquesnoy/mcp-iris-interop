/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.RabbitMQ.Message Extends (Ens.Request, %External.Messaging.RabbitMQMessage)
{

Storage Default
{
<Data name="MessageDefaultData">
<Subscript>"Message"</Subscript>
<Value name="1">
<Value>exchange</Value>
</Value>
<Value name="2">
<Value>routingKey</Value>
</Value>
<Value name="3">
<Value>encodedContent</Value>
</Value>
<Value name="4">
<Value>contentType</Value>
</Value>
<Value name="5">
<Value>contentEncoding</Value>
</Value>
<Value name="6">
<Value>deliveryMode</Value>
</Value>
<Value name="7">
<Value>priority</Value>
</Value>
<Value name="8">
<Value>correlationId</Value>
</Value>
<Value name="9">
<Value>replyTo</Value>
</Value>
<Value name="10">
<Value>expiration</Value>
</Value>
<Value name="11">
<Value>messageId</Value>
</Value>
<Value name="12">
<Value>timestamp</Value>
</Value>
<Value name="13">
<Value>type</Value>
</Value>
<Value name="14">
<Value>userId</Value>
</Value>
<Value name="15">
<Value>appId</Value>
</Value>
<Value name="16">
<Value>clusterId</Value>
</Value>
</Data>
<Data name="headers">
<Attribute>headers</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.RabbitMQ.Message.headers"</Subscript>
</Data>
<DefaultData>MessageDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
