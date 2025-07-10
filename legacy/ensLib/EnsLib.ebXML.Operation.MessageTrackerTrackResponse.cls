/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.ebXML.Operation.MessageTrackerTrackResponse Extends Ens.Request [ System = 4 ]
{

/// Message we want to track
Property Request As EnsLib.ebXML.Message [ Required ];

Storage Default
{
<Data name="MessageTrackerTrackResponseDefaultData">
<Subscript>"MessageTrackerTrackResponse"</Subscript>
<Value name="1">
<Value>Request</Value>
</Value>
</Data>
<DefaultData>MessageTrackerTrackResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
