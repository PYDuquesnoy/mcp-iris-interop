/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonSNS.PublishRequest Extends Ens.Request
{

Property Message As %String(MAXLEN = "");

Storage Default
{
<Data name="PublishRequestDefaultData">
<Subscript>"PublishRequest"</Subscript>
<Value name="1">
<Value>Message</Value>
</Value>
</Data>
<DefaultData>PublishRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
