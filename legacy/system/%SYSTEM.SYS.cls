/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Language independent accessors for selected system variables
Class %SYSTEM.SYS Extends Help [ Final, System = 4 ]
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

/// Contains the UTC time in $H format.
ClassMethod TimeStamp() As %String
{
	Quit $ZTimeStamp
}

/// Contains the time zone offset from GMT 
ClassMethod TimeZone() As %String
{
	Quit $ZTimeZone
}

/// Contains the maximum local string length of the current job. 
ClassMethod MaxLocalLength() As %Integer
{
	Quit $zutil(96,39)
}

}
