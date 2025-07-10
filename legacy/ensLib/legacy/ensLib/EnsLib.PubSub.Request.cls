/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Used by the Routing Operation to request routing information for a given message or topic.
Class EnsLib.PubSub.Request Extends Ens.Request [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Optional topic string; used for PubSub routing.
Property Topic As %String(MAXLEN = 1000);

/// Optional publish/subscriber domain name; used for PubSub routing.
Property DomainName As %String(MAXLEN = 100);

/// Optional message to be routed.
Property Message As Ens.Request;

Storage Default
{
<Data name="RequestDefaultData">
<Subscript>"Request"</Subscript>
<Value name="1">
<Value>Message</Value>
</Value>
<Value name="2">
<Value>Topic</Value>
</Value>
<Value name="3">
<Value>DomainName</Value>
</Value>
</Data>
<DefaultData>RequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
