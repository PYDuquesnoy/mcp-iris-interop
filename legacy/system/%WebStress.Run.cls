/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Run Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Property Job As %String(TRUNCATE = 1);

Property RunName As %String(TRUNCATE = 1);

Property Test As %WebStress.Tests;

Property Script As %WebStress.Scripts;

Property WebServer As %String(TRUNCATE = 1);

Property Sessions As %Integer;

Property DelayType As %String(DISPLAYLIST = ",No Delay,Random,User Recorded", TRUNCATE = 1, VALUELIST = ",N,R,U");

Property RandomDelayMin As %Integer;

Property RandomDelayMax As %Integer;

Property StartDate As %Date(FORMAT = 3);

Property StopDate As %Date(FORMAT = 3);

Property StartTime As %Time(FORMAT = 2);

Property StopTime As %Time(FORMAT = 2);

Property RunMinutes As %Integer;

Property WarmUpMinutes As %Integer;

Property CoolDownMinutes As %Integer;

Property RunStartDate As %Date(FORMAT = 3);

Property RunStopDate As %Date(FORMAT = 3);

Property RecordStartDate As %Date(FORMAT = 3);

Property RecordStopDate As %Date(FORMAT = 3);

Property RunStartTime As %Time(FORMAT = 2);

Property RunStopTime As %Time(FORMAT = 2);

Property RecordStartTime As %Time(FORMAT = 2);

Property RecordStopTime As %Time(FORMAT = 2);

Property SystemIdentifier As %String(MAXLEN = 200);

Property Status As %String(DISPLAYLIST = ",Unknown,Preparing,Waiting,Warmup,Recording,Cooldown,Stopping,Stopped,Error", TRUNCATE = 1, VALUELIST = ",0,1,2,3,4,5,6,7,8") [ InitialExpression = 0 ];

Property Error As %String(TRUNCATE = 1);

Index Job On (SystemIdentifier, Job) [ IdKey, PrimaryKey, Unique ];

Storage Default
{
<Data name="RunDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Job</Value>
</Value>
<Value name="3">
<Value>Script</Value>
</Value>
<Value name="4">
<Value>Sessions</Value>
</Value>
<Value name="5">
<Value>StartDate</Value>
</Value>
<Value name="6">
<Value>StartTime</Value>
</Value>
<Value name="7">
<Value>Status</Value>
</Value>
<Value name="8">
<Value>StopDate</Value>
</Value>
<Value name="9">
<Value>StopTime</Value>
</Value>
<Value name="10">
<Value>Test</Value>
</Value>
<Value name="11">
<Value>WebServer</Value>
</Value>
<Value name="12">
<Value>Error</Value>
</Value>
<Value name="13">
<Value>CoolDownMinutes</Value>
</Value>
<Value name="14">
<Value>DelayType</Value>
</Value>
<Value name="15">
<Value>RandomDelayMax</Value>
</Value>
<Value name="16">
<Value>RandomDelayMin</Value>
</Value>
<Value name="17">
<Value>RunMinutes</Value>
</Value>
<Value name="18">
<Value>WarmUpMinutes</Value>
</Value>
<Value name="19">
<Value>RecordStartDate</Value>
</Value>
<Value name="20">
<Value>RecordStartTime</Value>
</Value>
<Value name="21">
<Value>RecordStopDate</Value>
</Value>
<Value name="22">
<Value>RecordStopTime</Value>
</Value>
<Value name="23">
<Value>RunStartDate</Value>
</Value>
<Value name="24">
<Value>RunStartTime</Value>
</Value>
<Value name="25">
<Value>RunStopDate</Value>
</Value>
<Value name="26">
<Value>RunStopTime</Value>
</Value>
<Value name="27">
<Value>RunName</Value>
</Value>
</Data>
<DataLocation>^WebStress.RunD</DataLocation>
<DefaultData>RunDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.RunD</IdLocation>
<IndexLocation>^WebStress.RunI</IndexLocation>
<StreamLocation>^WebStress.RunS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
