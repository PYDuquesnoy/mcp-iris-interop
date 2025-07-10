/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Activity.Data.Days Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// Full instance name in format SystemName:InstanceName.
Property Instance As %String(MAXLEN = 128, TRUNCATE = 1) [ Required ];

/// Namespace name.
Property Namespace As %String(MAXLEN = 128, TRUNCATE = 1) [ Required ];

Property SiteDimension As %String(MAXLEN = 128, TRUNCATE = 1);

/// Business host type: 1=Service, 2=Process, 3=Operation.
Property HostType As %String;

/// Business host name (configuration item name).
Property HostName As %String(MAXLEN = 128, TRUNCATE = 1) [ Required ];

/// Timestamp corresponding to the beginning of the time slot, in source time.
Property TimeSlot As %TimeStamp [ Required ];

/// Timestamp corresponding to the beginning of the time slot, in UTC.
Property TimeSlotUTC As %TimeStamp [ Required ];

/// Total message count for the time slot.
Property TotalCount As %Integer;

/// Sum of the individual durations (processing times), for all messages within the time slot.
Property TotalDuration As %Numeric(SCALE = 3);

/// Sum of the squares of the individual durations (sum of duration**2), for all messages within the time slot.
Property TotalDurationSquare As %Numeric(SCALE = 6);

/// Sum of the time waiting in queue, for all messages within the time slot.
Property TotalQueueDuration As %Numeric(SCALE = 3);

Index i1 On (Instance, Namespace, SiteDimension, HostName, TimeSlot);

Index i2 On TimeSlot;

Index i3 On (Instance, Namespace, SiteDimension, HostName, TimeSlotUTC);

Index i4 On TimeSlotUTC;

Index i5 On SiteDimension;

Property Period As %Integer [ SqlComputeCode = {Set {*}=86400}, SqlComputed, Transient ];

ClassMethod Purge(pPeriodToKeep As %String = "", pClassScale As %String = "d") As %Status
{
	Quit ##class(Ens.Activity.Utils).Purge(pPeriodToKeep,pClassScale)
}

Storage Default
{
<Data name="DaysDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Instance</Value>
</Value>
<Value name="3">
<Value>Namespace</Value>
</Value>
<Value name="4">
<Value>SiteDimension</Value>
</Value>
<Value name="5">
<Value>HostType</Value>
</Value>
<Value name="6">
<Value>HostName</Value>
</Value>
<Value name="7">
<Value>TimeSlot</Value>
</Value>
<Value name="8">
<Value>TimeSlotUTC</Value>
</Value>
<Value name="9">
<Value>TotalCount</Value>
</Value>
<Value name="10">
<Value>TotalDuration</Value>
</Value>
<Value name="11">
<Value>TotalDurationSquare</Value>
</Value>
<Value name="12">
<Value>TotalQueueDuration</Value>
</Value>
</Data>
<DataLocation>^Ens.Activity.Data.DaysD</DataLocation>
<DefaultData>DaysDefaultData</DefaultData>
<IdLocation>^Ens.Activity.Data.DaysD</IdLocation>
<IndexLocation>^Ens.Activity.Data.DaysI</IndexLocation>
<StreamLocation>^Ens.Activity.Data.DaysS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
