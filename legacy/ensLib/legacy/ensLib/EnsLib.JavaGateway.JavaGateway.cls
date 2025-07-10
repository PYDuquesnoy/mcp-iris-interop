/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JavaGateway.JavaGateway Extends %Net.Remote.Java.JavaGateway [ System = 4 ]
{

Storage Default
{
<Data name="JavaGatewayDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Context</Value>
</Value>
<Value name="3">
<Value>Device</Value>
</Value>
<Value name="4">
<Value>Error</Value>
</Value>
<Value name="5">
<Value>Protocol</Value>
</Value>
</Data>
<DataLocation>^User.JavaGatewayD</DataLocation>
<DefaultData>JavaGatewayDefaultData</DefaultData>
<IdLocation>^User.JavaGatewayD</IdLocation>
<IndexLocation>^User.JavaGatewayI</IndexLocation>
<StreamLocation>^User.JavaGatewayS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
