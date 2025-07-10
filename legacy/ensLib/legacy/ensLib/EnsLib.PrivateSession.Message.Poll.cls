/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is a DICOM framework class
Class EnsLib.PrivateSession.Message.Poll Extends (%Persistent, Ens.Util.MessageBodyMethods) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter DOMAIN = "EnsDICOM";

/// From 'Ens.Util.MessageBodyMethods'
Method %ShowContents(pZenOutput As %Boolean = 0)
{
	Write $$$Text("(poll-data)")
}

Storage Default
{
<Data name="PollDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^EnsLib.PrivateSessionBD8E.PollD</DataLocation>
<DefaultData>PollDefaultData</DefaultData>
<IdLocation>^EnsLib.PrivateSessionBD8E.PollD</IdLocation>
<IndexLocation>^EnsLib.PrivateSessionBD8E.PollI</IndexLocation>
<StreamLocation>^EnsLib.PrivateSessionBD8E.PollS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
