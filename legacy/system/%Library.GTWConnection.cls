/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.GTWConnection Extends %RegisteredObject [ System = 4 ]
{

Property dllhandle As %String;

Property hdbc As %String;

Property Name As %String;

Property Timeout As %String;

Property Legacy As %Integer;

Property LastUsed As %Integer [ Internal ];

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
	if ..dllhandle'="",..hdbc'="" { set res=$zf(-5,..dllhandle,6,..hdbc) }    // Disconnect
}

Method Connect(dll As %String, name As %String, timeout As %Integer, legacy As %Integer) As %Status
{
	new %msg
	set %msg=""
	
	set ..Name=name
	set ..Timeout=timeout
	set ..dllhandle=dll
	set ..Legacy=legacy
	set ..LastUsed=$zhorolog\1
	
	set sc = $$ConnectODDBCInternal^%apiGTW(..dllhandle, ..Name, ..Timeout, ..Legacy, .hdbc)
	
	if $$$ISOK(sc) {
		set ..hdbc = hdbc
	}
	
	quit sc
}

Method Reconnect() As %Status
{
 
	if ..dllhandle'="",..hdbc'="" { set rc=$zf(-5,..dllhandle,53,..hdbc) }    // RemoveConnection
	kill %SQLGateway(..Name)
	set ..hdbc=""
	QUIT ..Connect(..dllhandle,..Name, ..Timeout,..Legacy)
}

}
