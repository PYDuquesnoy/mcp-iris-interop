/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is a DICOM framework class
Class EnsLib.PrivateSession.Message.Start Extends (%Persistent, Ens.Util.MessageBodyMethods) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter DOMAIN = "EnsDICOM";

/// From 'Ens.Util.MessageBodyMethods'
Method %ShowContents(pZenOutput As %Boolean = 0)
{
	Write $$$Text("(session-start)")
}

Storage Default
{
<Data name="StartDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^EnsLib.PrivateSessioBD8E.StartD</DataLocation>
<DefaultData>StartDefaultData</DefaultData>
<IdLocation>^EnsLib.PrivateSessioBD8E.StartD</IdLocation>
<IndexLocation>^EnsLib.PrivateSessioBD8E.StartI</IndexLocation>
<StreamLocation>^EnsLib.PrivateSessioBD8E.StartS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
