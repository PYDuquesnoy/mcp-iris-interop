/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Tests.Parameters Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Parameter FileTimestamp = "60219,33101";

Relationship Test As %WebStress.Tests [ Cardinality = parent, Inverse = Parameters ];

/// The script that should be included as part of this test
Property Script As %WebStress.Scripts;

/// The generator that should generate the traffic for this script
Property Generator As %WebStress.Machines.Generators;

/// The web server that the generator should use to access the application
Property WebServer As %WebStress.Machines.WebServers;

/// The port to be used on the webserver. Defaults to 80
Property WebServerPort As %Integer [ InitialExpression = 80 ];

/// The number of processes that should be used to generate the traffic
Property Processes As %Integer(MINVAL = 1);

/// The number of sessions per process
Property Sessions As %Integer(MINVAL = 1);

/// The required number of transactions per minute
Property Target As %Numeric(SCALE = 1);

/// Number of seconds to pause at the end of each script
Property ScriptPause As %Integer;

/// This indicates that the script will loop back to the URL indicated by this number
Property LoopBackNumber As %Integer;

/// This the the percentage of times that the loop back will occur
Property LoopBackPercent As %Integer;

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called before 
/// any data is written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnBeforeSave(insert As %Boolean) As %Status [ Private ]
{
	if ..Sessions<1 set ..Sessions=1
	quit $$$OK
}

Storage Default
{
<Data name="ParametersDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Generator</Value>
</Value>
<Value name="3">
<Value>Processes</Value>
</Value>
<Value name="4">
<Value>Sessions</Value>
</Value>
<Value name="5">
<Value>WebServer</Value>
</Value>
<Value name="6">
<Value>Script</Value>
</Value>
<Value name="7">
<Value>Target</Value>
</Value>
<Value name="8">
<Value>SavedDate</Value>
</Value>
<Value name="9">
<Value>SavedTime</Value>
</Value>
<Value name="10">
<Value>SyncSave</Value>
</Value>
<Value name="11">
<Value>Version</Value>
</Value>
<Value name="12">
<Value>ScriptPause</Value>
</Value>
<Value name="13">
<Value>LoopBackNumber</Value>
</Value>
<Value name="14">
<Value>LoopBackPercent</Value>
</Value>
<Value name="15">
<Value>WebServerPort</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Parameters")</DataLocation>
<DefaultData>ParametersDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.TestsC("Parameters")</IdLocation>
<IndexLocation>^WebStress.Tests.ParametersI</IndexLocation>
<StreamLocation>^WebStress.Tests.ParametersS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
