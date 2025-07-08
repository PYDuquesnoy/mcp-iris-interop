/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Machines.ApplicationServers Extends (%Persistent, %XML.Adaptor, %WebStress.Utils.Version) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Parameter FileTimestamp = "60212,85655";

/// A unique name for the application server
Property Name As %String(TRUNCATE = 1) [ Required ];

/// The address of the web server that can be used to communicate with this application server
/// Examples: 192.168.1.12, MYWEBSERVER
Property WebSrvAddress As %String(TRUNCATE = 1) [ Required ];

/// The port that should be used to communicate with the. This will default to 80 web server
Property WebSrvPort As %Integer [ InitialExpression = 80 ];

/// The URL that will allow communication with the application server for setting/un-setting the encryption flag
/// Example: /csp/webstress/
Property URL As %String(MAXLEN = 255, TRUNCATE = 1) [ Required ];

Property CacheUserName As %String;

Property CachePassword As %String;

Property SecurityCheck As %Boolean [ InitialExpression = 0 ];

Index URL On (WebSrvAddress, WebSrvPort, URL) [ Unique ];

Storage Default
{
<Data name="ApplicationServersDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>URL</Value>
</Value>
<Value name="4">
<Value>WebSrvAddress</Value>
</Value>
<Value name="5">
<Value>WebSrvPort</Value>
</Value>
<Value name="6">
<Value>SavedDate</Value>
</Value>
<Value name="7">
<Value>SavedTime</Value>
</Value>
<Value name="8">
<Value>Version</Value>
</Value>
<Value name="9">
<Value>CacheUserName</Value>
</Value>
<Value name="10">
<Value>CachePassword</Value>
</Value>
<Value name="11">
<Value>SecurityCheck</Value>
</Value>
</Data>
<DataLocation>^WebStress.Machines.AppSrvD</DataLocation>
<DefaultData>ApplicationServersDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Machines.AppSrvD</IdLocation>
<IndexLocation>^WebStress.Machines.AppSrvI</IndexLocation>
<StreamLocation>^WebStress.Machines.AppSrvS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
