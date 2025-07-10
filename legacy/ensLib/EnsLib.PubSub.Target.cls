/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a target for a publish/subscribe message routing request.
Class EnsLib.PubSub.Target Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter XMLIGNORENULL = 1;

Parameter XMLSUMMARY = "Name";

/// (Optional) Name of this target
Property Name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// Target to which message should be sent. This is the name of 
/// a configured Business Process or Operation within the current production.
Property Target As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// (optional) External address used to send the message. (For example, an e-mail address).
Property Address As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// (internal) This is set for target objects that are to be 
/// deleted when their corresponding response object is deleted.
Property %CorrespondingResponse As EnsLib.PubSub.Response(XMLPROJECTION = "NONE");

Method %OnNew(pResponse As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	// Set up corresponding response
	Set ..%CorrespondingResponse = pResponse

	Quit $$$OK
}

Storage Default
{
<Data name="TargetDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%CorrespondingResponse</Value>
</Value>
<Value name="3">
<Value>Channel</Value>
</Value>
<Value name="4">
<Value>Name</Value>
</Value>
<Value name="5">
<Value>Target</Value>
</Value>
<Value name="6">
<Value>Transform</Value>
</Value>
<Value name="7">
<Value>Address</Value>
</Value>
</Data>
<DataLocation>^EnsLib.PubSub.TargetD</DataLocation>
<DefaultData>TargetDefaultData</DefaultData>
<IdLocation>^EnsLib.PubSub.TargetD</IdLocation>
<IndexLocation>^EnsLib.PubSub.TargetI</IndexLocation>
<StreamLocation>^EnsLib.PubSub.TargetS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
