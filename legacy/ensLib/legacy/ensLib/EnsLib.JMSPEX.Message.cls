/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMSPEX.Message Extends (Ens.Request, %External.Messaging.JMSMessage)
{

Storage Default
{
<Data name="MessageDefaultData">
<Subscript>"Message"</Subscript>
<Value name="1">
<Value>destination</Value>
</Value>
<Value name="2">
<Value>type</Value>
</Value>
<Value name="3">
<Value>textBody</Value>
</Value>
<Value name="4">
<Value>bytesBody</Value>
</Value>
<Value name="5">
<Value>properties</Value>
</Value>
</Data>
<DefaultData>MessageDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
