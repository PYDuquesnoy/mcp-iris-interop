/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is a DICOM framework class
Class EnsLib.PrivateSession.Message.Ack Extends (%Persistent, Ens.Util.MessageBodyMethods) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter DOMAIN = "EnsDICOM";

/// From 'Ens.Util.MessageBodyMethods'
Method %ShowContents(pZenOutput As %Boolean = 0)
{
	Write $$$Text("(session-ack)")
}

Storage Default
{
<Data name="AckDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^EnsLib.PrivateSessionBD8E.AckD</DataLocation>
<DefaultData>AckDefaultData</DefaultData>
<IdLocation>^EnsLib.PrivateSessionBD8E.AckD</IdLocation>
<IndexLocation>^EnsLib.PrivateSessionBD8E.AckI</IndexLocation>
<StreamLocation>^EnsLib.PrivateSessionBD8E.AckS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
