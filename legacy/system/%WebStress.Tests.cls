/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Tests Extends (%Persistent, %XML.Adaptor, %ZEN.DataModel.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Index NameIndex On Name [ Unique ];

/// A unique name that identifies this test
Property Name As %String(TRUNCATE = 1);

Property DelayType As %String(DISPLAYLIST = ",No Delay,Random,User Recorded");

/// A list of the scripts that will be used in this test along with the associated generators, webservers etc
Relationship Parameters As %WebStress.Tests.Parameters [ Cardinality = children, Inverse = Test ];

/// The lower limit in seconds for a random delay period
Property RandomDelayMin As %Integer;

/// The upper limit in seconds for a random delay period
Property RandomDelayMax As %Integer;

/// The date when the test should start. Used for non-interactive starts. (YYYY-MM-DD)
Property StartDate As %Date(FORMAT = 3);

/// The date when the test should stop. Used for non-interactive starts (YYYY-MM-DD)
Property StopDate As %Date(FORMAT = 3);

/// The time when the test should start. Used for non-interactive starts (HH:MM)
Property StartTime As %Time(FORMAT = 2);

/// The time when the test should stop. Used for non-interactive starts (HH:MM)
Property StopTime As %Time(FORMAT = 2);

/// The number of minutes that the test should run for (in record mode, not warm up or cool down).
Property RunMinutes As %Integer;

/// The number of minutes that the test should run for before result recording starts
Property WarmUpMinutes As %Integer;

/// The number of minutes that the test should run for after result recording stops
Property CoolDownMinutes As %Integer;

/// The address of the proxy server that should be used
Property ProxyAddress As %String(TRUNCATE = 1);

/// The port on the proxy server that should be used
Property ProxyPort As %Integer;

/// Indicates whether the encryption flag should be changed on the application servers
Property SetAppEncrypt As %Boolean [ InitialExpression = 1 ];

/// Indicates whether the data and code should be sent to the remote generators
Property SendData As %Boolean;

/// Indicates whether the results should be transferred back from the other generators at the end of the run
Property TransferResults As %Boolean;

/// Indicates whether the application server statistics should be collected during the playback
/// The stats include license usage as well as global/routine references/seizes etc
Property CollectAppServerStats As %Boolean;

/// The period in seconds at which to collect the statistics from the application servers
Property CollectAppServerPeriod As %Integer [ InitialExpression = 5 ];

Property SavePageSource As %Boolean [ InitialExpression = 0 ];

Property SavePageSourceDir As %String(MAXLEN = 255);

Property SSLConfig As %String(MAXLEN = 255);

Property Timeout As %String [ InitialExpression = 30 ];

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	if ((..StartTime'="")&&(..StopTime'="")) {
		set ..RunMinutes=""
	}
	quit $$$OK
}

Storage Default
{
<Data name="TestsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DelayType</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>RandomDelayMax</Value>
</Value>
<Value name="5">
<Value>RandomDelayMin</Value>
</Value>
<Value name="6">
<Value>SavedDate</Value>
</Value>
<Value name="7">
<Value>SavedTime</Value>
</Value>
<Value name="8">
<Value>SyncSave</Value>
</Value>
<Value name="9">
<Value>Version</Value>
</Value>
<Value name="10">
<Value>StartDate</Value>
</Value>
<Value name="11">
<Value>StartTime</Value>
</Value>
<Value name="12">
<Value>StopDate</Value>
</Value>
<Value name="13">
<Value>StopTime</Value>
</Value>
<Value name="14">
<Value>CoolDownMins</Value>
</Value>
<Value name="15">
<Value>RunMinutes</Value>
</Value>
<Value name="16">
<Value>WarmUpMins</Value>
</Value>
<Value name="17">
<Value>CoolDownMinutes</Value>
</Value>
<Value name="18">
<Value>WarmUpMinutes</Value>
</Value>
<Value name="19">
<Value>ProxyAddress</Value>
</Value>
<Value name="20">
<Value>ProxyPort</Value>
</Value>
<Value name="21">
<Value>SetAppEncrypt</Value>
</Value>
<Value name="22">
<Value>SendData</Value>
</Value>
<Value name="23">
<Value>TransferResults</Value>
</Value>
<Value name="24">
<Value>ContainsCSPToken</Value>
</Value>
<Value name="25">
<Value>CollectAppServerStats</Value>
</Value>
<Value name="26">
<Value>CollectAppServerPeriod</Value>
</Value>
<Value name="27">
<Value>SavePageSource</Value>
</Value>
<Value name="28">
<Value>SavePageSourceDir</Value>
</Value>
<Value name="29">
<Value>SSLConfig</Value>
</Value>
<Value name="30">
<Value>Timeout</Value>
</Value>
</Data>
<DataLocation>^WebStress.TestsD</DataLocation>
<DefaultData>TestsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.TestsD</IdLocation>
<IndexLocation>^WebStress.TestsI</IndexLocation>
<StreamLocation>^WebStress.TestsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
