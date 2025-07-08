/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Machines.Generators Extends (%Persistent, %XML.Adaptor, %WebStress.Utils.Version) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Parameter FileTimestamp = "60212,85655";

/// A text description of this machine
Property Name As %String(TRUNCATE = 1) [ Required ];

/// This is the address of the web server that will give access to this generator
/// 

Property Address As %String(TRUNCATE = 1) [ Required ];

/// The virtual directory which is bound to the WebStress application
/// Examples: /webstress/
///           /csp/webstress/
Property WebStressDir As %String(MAXLEN = 255, TRUNCATE = 1);

/// This should be used if talking directly to the generator rather than through a web server
Property DirectPort As %Integer;

Property CacheUserName As %String;

Property CachePassword As %String;

ClassMethod GetCredentials(arg As %String, ByRef Username As %String, ByRef Password As %String) As %Status
{
	set stat=0
	set machine=##class(%WebStress.Machines.Generators).%OpenId(arg)
	if machine="" {
		set machine=##class(%WebStress.Machines.Generators).NameOpen(arg)
	}
	if $IsObject(machine) {
		set Username=machine.CacheUserName
		set Password=machine.CachePassword
		set stat=$$$OK
	}
	quit stat
}

Index Name On Name [ Unique ];

Storage Default
{
<Data name="GeneratorsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Address</Value>
</Value>
<Value name="3">
<Value>DirectPort</Value>
</Value>
<Value name="4">
<Value>Name</Value>
</Value>
<Value name="5">
<Value>WebStressDir</Value>
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
<DataLocation>^WebStress.Machines.GeneratorsD</DataLocation>
<DefaultData>GeneratorsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Machines.GeneratorsD</IdLocation>
<IndexLocation>^WebStress.Machines.GeneratorsI</IndexLocation>
<StreamLocation>^WebStress.Machines.GeneratorsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
