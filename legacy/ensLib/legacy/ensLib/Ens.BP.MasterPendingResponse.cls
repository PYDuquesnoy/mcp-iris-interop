/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.BP.MasterPendingResponse Extends %Persistent [ System = 4 ]
{

Method %OnNew(pRequestHeaderId As %String, pCompletionKey As %String, pIsTimer As %Boolean, pControlledCompletionKeys As %String) As %Status [ Private, ServerOnly = 1 ]
{
    Set ..RequestHeaderId = pRequestHeaderId
    Set ..CompletionKey = pCompletionKey
    Set ..IsTimer = pIsTimer
    Set ..ControlledCompletionKeys = pControlledCompletionKeys
    Return $$$OK
}

Property RequestHeaderId As %String;

Property CompletionKey As %String(MAXLEN = "");

Property IsTimer As %Boolean;

Property ControlledCompletionKeys As %String(MAXLEN = "");

Relationship %BusinessProcess As Ens.BusinessProcess [ Cardinality = parent, Inverse = %MasterPendingResponses ];

Index %MPRI On %BusinessProcess;

Index iH On RequestHeaderId;

Index iC On CompletionKey;

Index iT On IsTimer;

Storage Default
{
<Data name="MasterPendingResponseDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>RequestHeaderId</Value>
</Value>
<Value name="3">
<Value>CompletionKey</Value>
</Value>
<Value name="4">
<Value>IsTimer</Value>
</Value>
<Value name="5">
<Value>ControlledCompletionKeys</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("%MPR")</DataLocation>
<DefaultData>MasterPendingResponseDefaultData</DefaultData>
<IdLocation>^Ens.BusinessProcessC("%MPR")</IdLocation>
<IndexLocation>^Ens.BP.MasterPendingResponseI</IndexLocation>
<StreamLocation>^Ens.BP.MasterPendingResponseS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
