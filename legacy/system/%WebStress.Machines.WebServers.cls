/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Machines.WebServers Extends (%Persistent, %XML.Adaptor, %WebStress.Utils.Version) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Parameter FileTimestamp = "60212,85655";

/// A text description of this web server
Property Name As %String(TRUNCATE = 1) [ Required ];

/// Either its physical address or its DNS name
Property Address As %String(TRUNCATE = 1) [ Required ];

/// The port number to use on this webserver (Defaults to 80)
Property Port As %Integer [ InitialExpression = 80 ];

Index Name On Name [ Unique ];

Index Address On (Address, Port) [ Unique ];

Storage Default
{
<Data name="WebServersDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Address</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>Port</Value>
</Value>
<Value name="5">
<Value>SavedDate</Value>
</Value>
<Value name="6">
<Value>SavedTime</Value>
</Value>
<Value name="7">
<Value>Version</Value>
</Value>
</Data>
<DataLocation>^WebStress.Machines.WebServersD</DataLocation>
<DefaultData>WebServersDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Machines.WebServersD</IdLocation>
<IndexLocation>^WebStress.Machines.WebServersI</IndexLocation>
<StreamLocation>^WebStress.Machines.WebServersS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
