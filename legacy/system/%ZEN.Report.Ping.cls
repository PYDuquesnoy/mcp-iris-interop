/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Ping Extends %RegisteredObject [ Deprecated, System = 4 ]
{

ClassMethod ping(port As %String, timeout As %Integer = 5, ByRef mainport, ByRef servertype, ByRef memMax As %Integer, ByRef memCommitted As %Integer, ByRef memUse As %Integer, ByRef runtimeName) As %Status
{
		set tSC=$$$OK
		try {
			; use TCP/IP to contact Hot JVM Ping Server and verify Hot JVM server still alive
			Set tio=$io
			set data="A"
			Set dev="|TCP|1"
			if '$D(port) Set tSC=$$$ERROR($$$GeneralError,"port must be defined") quit
			if '$D(timeout) Set tSC=$$$ERROR($$$GeneralError,"timeout must be defined") quit
			open dev:("127.0.0.1":port:"S":$C(10)):timeout
			if $test=0 {
				close dev use tio set tSC=$$$ERROR($$$GeneralError,"Open failure on Ping of HotJVM server")
			}
			Set mainport=""
			Set servertype=""
			use dev
			write data
			write !
			read done:timeout
			if $test=0 {
				close dev use tio set tSC=$$$ERROR($$$GeneralError,"Timeout on Ping of HotJVM server")
			}
			Set mainport=$P(done,",",1)
			Set servertype=$P(done,",",2)
			Set memMax=$P(done,",",3)
			Set memCommitted=$P(done,",",4)
			Set memUse=$P(done,",",5)
			Set runtimeName=$P(done,",",6)
		} 
		catch(ex){
		}
		if $$$ISERR(tSC) quit tSC
		close dev
		use tio
		quit tSC
}

ClassMethod shutdown(port As %String, timeout As %Integer = 5, ByRef mainport, ByRef servertype) As %Status
{
	
		If '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) { 
			Quit $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
		}

		; use TCP/IP to contact Hot JVM Ping Server and verify Hot JVM server still alive and shut it down
		Set tio=$io
		set data="X" ; exit from program
		Set dev="|TCP|1"
		open dev:("127.0.0.1":port:"S":$C(10)):timeout
		if $test=0 {
			close dev use tio quit $$$ERROR($$$GeneralError,"Open failure on Ping of HotJVM server")
		}
		Set mainport=""
		Set servertype=""
		use dev
		write data
		write !
		read done:timeout
		if $test=0 {
			close dev use tio quit $$$ERROR($$$GeneralError,"Timeout on Ping of HotJVM server")
		}
		Set mainport=$P(done,",",1)
		Set servertype=$P(done,",",2)
		close dev
		use tio
		quit $$$OK
}

}
