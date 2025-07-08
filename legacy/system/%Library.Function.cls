/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syINET

/// Language independent accessors for selected system variables
Class %Library.Function Extends %RegisteredObject [ Final, System = 4 ]
{

/// Contains the current date and time as integer counters. 
ClassMethod Horolog() As %String
{
	Quit $Horolog
}

/// Contains the ID of the current process. 
ClassMethod ProcessID() As %Integer
{
	Quit $Job
}

/// Contains the current namespace name. 
ClassMethod NameSpace() As %String
{
	Quit $namespace
}

/// Contains the current date and time in Coordinated Universal Time format. 
ClassMethod TimeStamp() As %String
{
	Quit $ZTimeStamp
}

/// Contains the time zone offset from GMT 
ClassMethod TimeZone() As %String
{
	Quit $ZTimeZone
}

/// Return current host name
ClassMethod HostName() As %String
{
 	q $zu(54,0)
}

/// Returns specified host IPs (comma separated)
/// 
/// Note: it returns configured IPs not necessarily the actual NIC IPs
/// 
/// If host name is not specified returns current host IPs.
ClassMethod IPAddresses(HName As %String) As %String
{
	If '$D(HName) set HName=..HostName()

#;SML994+
	I '$$$USEIPV6 q $ZU(54,25,HName)
	s a=$SYSTEM.INetInfo.HostNameToAddrMulti(HName)
	q:a="" ""
	s r=""
	f i=1:1:$LISTLENGTH(a) s r=r_$li(a,i)_","
	q $e(r,1,*-1)
#;SML994-
}

Storage Default
{
<Data name="FunctionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%Library.FunctionD</DataLocation>
<DefaultData>SYSDefaultData</DefaultData>
<IdLocation>^Library.FunctionD</IdLocation>
<IndexLocation>^Library.FunctionI</IndexLocation>
<StreamLocation>^Library.FunctionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
