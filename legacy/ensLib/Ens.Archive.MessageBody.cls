/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Archive.MessageBody Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, System = 4 ]
{

Property OriginalMessageNamespace As %String(MAXLEN = "");

Property OriginalMessageBodyClassname As %String(MAXLEN = "");

Property OriginalMessageBodyId As %String(MAXLEN = "");

Property OriginalMessageBodyStream As %Stream.GlobalCharacter;

Storage Default
{
<Data name="MessageBodyDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>OriginalMessageNamespace</Value>
</Value>
<Value name="3">
<Value>OriginalMessageBodyClassname</Value>
</Value>
<Value name="4">
<Value>OriginalMessageBodyId</Value>
</Value>
<Value name="5">
<Value>OriginalMessageBodyStream</Value>
</Value>
</Data>
<DataLocation>^Ens.Archive.MessageBodyD</DataLocation>
<DefaultData>MessageBodyDefaultData</DefaultData>
<IdLocation>^Ens.Archive.MessageBodyD</IdLocation>
<IndexLocation>^Ens.Archive.MessageBodyI</IndexLocation>
<StreamLocation>^Ens.Archive.MessageBodyS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
