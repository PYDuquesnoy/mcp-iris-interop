/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonSQS.Message Extends (Ens.Request, %External.Messaging.SQSMessage)
{

Storage Default
{
<Data name="MessageDefaultData">
<Subscript>"Message"</Subscript>
<Value name="1">
<Value>queue</Value>
</Value>
<Value name="2">
<Value>body</Value>
</Value>
<Value name="3">
<Value>groupID</Value>
</Value>
<Value name="4">
<Value>deduplicationID</Value>
</Value>
<Value name="5">
<Value>receiptHandle</Value>
</Value>
<Value name="6">
<Value>messageID</Value>
</Value>
<Value name="7">
<Value>messageAttributes</Value>
</Value>
</Data>
<DefaultData>MessageDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
