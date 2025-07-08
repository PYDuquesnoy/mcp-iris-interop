/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occJava

/// <p>
/// This class is maintained for backward compatibility only and it is deprecated. All users should convert their use 
/// of this class to the $system.external interface as soon as possible.
/// </p>
/// <p>
/// Object Gateway Server definitions.
/// </p>
Class %Net.Remote.ObjectGateway Extends %Persistent [ Deprecated, StorageStrategy = ObjectGatewayStorage, System = 3 ]
{

Index ID On Name [ IdKey ];

/// Lookup by Gateway name.
Query ByName(name As %String = "") As %Query(CONTAINID = 1, ROWSPEC = "ID,Name,Type,Server,Port,Interface") [ SqlProc ]
{
}

ClassMethod ByNameExecute(ByRef qHandle As %Binary, name As %String) As %Status [ Internal ]
{
	/*
 SELECT %ID, Name, %EXTERNAL(Type), Server, Port, AllowedIPAddresses AS Interface
 FROM ObjectGateway
 WHERE Name %STARTSWITH :name
 ORDER BY Name
 */
	#dim gateways as %Library.DynamicArray
	set tSC = $$$OK
	try {
		set gateways = $system.external.getServers()
		set restrict = $$$lcase(name)
		set restrictlen = $l(restrict)
		kill ^||gateways
		if $isobject(gateways) {
			set it = gateways.%GetIterator()
			while it.%GetNext(.k,.gatewayname) {
				if $extract($$$lcase(gatewayname),1,restrictlen) = restrict {
					set gateway = $system.external.getServer(gatewayname)
					set ^||gateways($$$ucase(gateway.Name)) = $listbuild(gateway.Name,gateway.Type,gateway.Server,gateway.Port,gateway.AllowedIPAddresses)
				}
			}
		}
	} catch {
		set tSC = $$$ERROR($$$GeneralError, $zerror)
	}
	set qHandle = $listbuild("")
	return tSC
}

ClassMethod ByNameFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetAllClassesExecute ]
{
	set index = $list(qHandle,1)
	set index = $order(^||gateways(index))
	if index="" {
		set Row = ""
		set AtEnd = 1
	} else {
		set Row = ^||gateways(index)
	}
	set qHandle = $listbuild(index)
	return $$$OK
}

ClassMethod ByNameClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetAllClassesExecute ]
{
	Set qHandle = ""
	Kill ^||gateways
	return $$$OK
}

/// Lookup all Gateways; include current state.
Query ByGateway() As %Query(ROWSPEC = "Name,Type,Server,Port,State,StateExt") [ SqlProc ]
{
}

ClassMethod ByGatewayExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	#dim gateways as %Library.DynamicArray
	set tSC = $$$OK
	try {
		set gateways = $system.external.getServers()
		kill ^||gateways
		if $isobject(gateways) {
			set it = gateways.%GetIterator()
			while it.%GetNext(.k,.gatewayname) {
				set gateway = $system.external.getServer(gatewayname)
				set ^||gateways($$$ucase(gateway.Name)) = $listbuild(gateway.Name,gateway.Type,gateway.Server,gateway.Port,gateway.Interface)
			}
		}
	} catch {
		set tSC = $$$ERROR($$$GeneralError, $zerror)
	}
	set qHandle = $listbuild("")
	return tSC
}

ClassMethod ByGatewayFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetAllClassesExecute ]
{
	set index = $list(qHandle,1)
	set index = $order(^||gateways(index))
	if index="" {
		set Row = ""
		set AtEnd = 1
	} else {
		set Row = ^||gateways(index)
		if ##class(%Net.Remote.Utility).IsServerLocal($list(Row,3)) {
			set interface = $select($list(Row,2)="Java":$list(Row,3),1:$list(Row,5))
			set stInt = ..GatewayState($list(Row,4),interface,$list(Row,3))
			set stExt = $case(stInt,0:"Inactive",1:"Active",:"")
		} else {
			set stInt = 2
			set stExt = "Remote"
		}
		set $list(Row,5) = stInt, $list(Row,6) = stExt // discard the "Interface" column
	}
	set qHandle = $listbuild(index)
	return $$$OK
}

ClassMethod ByGatewayClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetAllClassesExecute ]
{
	Set qHandle = ""
	Kill ^||gateways
	return $$$OK
}

/// See method ##class(%Net.Remote.Service).IsGatewayRunning(pServer, pPort, pVerbose, .status, pPing, pInterface).
ClassMethod GatewayState(port As %String, interface As %String = "", server As %String = "127.0.0.1") As %Integer [ Internal ]
{
	If '$G(port) Quit 0
	
	Set tIsServerLocal = ##class(%Net.Remote.Utility).IsServerLocal(server)
	Set tTimeout = $S(tIsServerLocal:1,1:5)
	
	// This code opens a device bound to the appropriate interface,
	// does a ping and disconnect. It should be replaced with a single
	// call to %Net.Remote.Gateway > %Ping, once that is updated to
	// account for different interfaces. Then the code should look very
	// similar to that in %CSP.UI.Portal.XSLTGateway and JDBCGateway
	// pages, specificially GetGatewayState method.
	Set gwyDev = ##class(%Net.Remote.Gateway).%freeTCPDevice(port)
	Open gwyDev:(server:port:"AdS":/BINDTO=interface:::5):0
	Quit:'$test 0
	Use gwyDev:(::"-d"::32767:32767)
	If ##class(%Net.Remote.Utility).GetPassphrase(port,.tPhrase) {
		Write $C(0,0,0,0)_tPhrase_$C(0,0),*-3
	}

	Set tSC = ##class(%Net.Remote.Gateway).%Ping(server,port,tTimeout,1,.gwyDev)
	Set isRunning = $$$ISOK(tSC)
	
	Try {
		Use gwyDev
		Set x=$zobjexport(##class(%Net.Remote.Gateway).#DISCONNECT,8)
		Set msgid=$zobjexport(21),fun=$zobjexport(15)
		Close gwyDev
	} Catch ex {}

	Quit isRunning
}

/// Check if there exists a Gateway with a given name.
ClassMethod GatewayExists(name As %String) As %Boolean
{
	return $system.external.serverExists(name)
}

/// The Resource name that controls access to this gateway.<br>
/// If no resource is defined, then it is a public gateway which
/// anyone can use.<br>
Property Resource As %String(MAXLEN = 64, MINLEN = 0);

Property Type As %String(DISPLAYLIST = ",Java,.NET,Python", VALUELIST = ",1,2,3") [ Required ];

Property Name As %String [ Required ];

Property Server As %String [ InitialExpression = "127.0.0.1", Required ];

Property Port As %Integer(MAXVAL = 65535, MINVAL = 1) [ Required ];

Property LogFile As %String(MAXLEN = 1023);

Property HeartbeatInterval As %Integer(MAXVAL = 3600, MINVAL = 0) [ InitialExpression = 10 ];

Property HeartbeatFailureTimeout As %Integer(MAXVAL = 86400, MINVAL = 0) [ InitialExpression = 30 ];

Property HeartbeatFailureAction As %String(DISPLAYLIST = ",None,Restart,Alert,Restart and Alert", VALUELIST = ",N,R,A,RA") [ InitialExpression = "R" ];

Property HeartbeatFailureRetry As %Integer(MAXVAL = 86400, MINVAL = 0) [ InitialExpression = 300 ];

Property InitializationTimeout As %Integer(MAXVAL = 300, MINVAL = 2) [ InitialExpression = 5 ];

Property ConnectionTimeout As %Integer(MAXVAL = 300, MINVAL = 2) [ InitialExpression = 5 ];

Property UsePassphrase As %Boolean [ InitialExpression = 1 ];

Property passphraseList As %String [ Transient ];

Property JavaHome As %String(MAXLEN = 1023);

Property ClassPath As %String(MAXLEN = 32000);

Property JVMArgs As %String(MAXLEN = 32000);

Property MainClassName As %String [ InitialExpression = {$$$javaGatewayClass} ];

Property AllowedIPAddresses As %String [ InitialExpression = "127.0.0.1" ];

Property FilePath As %String(MAXLEN = 1023);

Property DotNetCorePath As %String(MAXLEN = 1023);

Property Exec32 As %Boolean [ InitialExpression = 1 ];

Property DotNetVersion As %String(DISPLAYLIST = ",F4.6.2,F3.5,N5.0,N6.0,N7.0,N8.0", VALUELIST = ",4.6.2,3.5,Net5.0,Net6.0,Net7.0,Net8.0") [ InitialExpression = "Net6.0" ];

Property PythonPath As %String(MAXLEN = 1023);

Property PyOptions As %String(MAXLEN = 32000);

Storage ObjectGatewayStorage
{
<StreamLocation>^%Net.Remote.ObjectGatewayS</StreamLocation>
<Type>%Library.CustomStorage</Type>
}

/// This method is normally generated by the storage class for persistent classes using
/// <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>. Persistent
/// classes using some other storage class, such as <class>%Library.CustomStorage</class> must override this
/// method.
ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	try {
		do $system.external.deleteServer(id)
		set status = $$$OK
	} catch exc {
		set status = exc.AsStatus()
	}
	return status
}

/// %LoadData() - loads an object from storage. This method is
/// implemented by the storage class.
Method %LoadData(id As %String) As %Status [ Private, ServerOnly = 1 ]
{
	try {
		set ..ClassPath = ""
		set ..DotNetCorePath = ""
		set ..FilePath = ""
		set ..JVMArgs = ""
		set ..JavaHome = ""
		set ..MainClassName = ""
		set ..PyOptions = ""
		set ..PythonPath = ""
		set ..passphraseList = ""

		do ..fromDao($system.external.getServer(id))
		set status = $$$OK
	} catch exc {
		set status = exc.AsStatus()
	}
	return status
}

/// %SaveData() - saves an object to disk, checks uniqueness and referential
/// integrity constraints, and maintains index structures. This method is
/// implemented by the storage class.
Method %SaveData(id As %String) As %Status [ Private, ServerOnly = 1 ]
{
	try {
		set dao = ..toDao()
		if $system.external.serverExists(..Name) {
			set saved = $system.external.modifyServer(dao)
		} else {
			set saved = $system.external.createServer(dao)
		}
		set id = saved.Name
		set status = $$$OK
	} catch exc {
		set status = exc.AsStatus()
	}
	return status
}

Method toDao() As %Library.DynamicObject
{
	set response = {
		"Name":(..Name),
		"FullName":($zu(131,1)_":"_..Name),
		"Type":(..TypeLogicalToDisplay(..Type)),
		"Port":(..Port),
		"LogFile":(..LogFile),
		"AllowedIPAddresses":(..AllowedIPAddresses),
		"ConnectionTimeout":(..ConnectionTimeout),
		"InitializationTimeout":(..InitializationTimeout),
		"passphraseList":(..passphraseList),
		"SSLConfigurationServer":(""),
		"SSLConfigurationClient":("")
	}
	if ..Type = 2 {
		do response.%Set("DotNetVersion",..DotNetVersionLogicalToDisplay(..DotNetVersion))
		do response.%Set("FilePath", ..FilePath)
		set response.Exec32 = ..Exec32
	} elseif ..Type = 1 {
		do response.%Set("JVMArgs",..JVMArgs)
		do response.%Set("JavaHome",..JavaHome)
		do response.%Set("ClassPath",..ClassPath)
	} elseif ..Type = 3 {
		do response.%Set("PythonOptions",..PyOptions)
		do response.%Set("PythonPath",..PythonPath)
	} else {
		// What?
	}
	return response
}

Method fromDao(dao As %Library.DynamicObject)
{
	set ..Name = dao.Name
	set ..Type = ..TypeDisplayToLogical(dao.Type)
	set ..Server = dao.AllowedIPAddresses
	set ..Port = dao.Port
	set ..LogFile = dao.LogFile
	set ..AllowedIPAddresses = dao.AllowedIPAddresses
	set ..ConnectionTimeout = dao.ConnectionTimeout
	set ..InitializationTimeout = dao.InitializationTimeout
	set ..passphraseList = dao.passphraseList

	set type = $$$ucase(..TypeLogicalToDisplay(..Type))
	if type = ".NET" {
		set ..DotNetVersion = ..DotNetVersionDisplayToLogical(dao.DotNetVersion)
		set ..FilePath = dao.FilePath
		set ..Exec32 = dao.Exec32
	} elseif $find("JAVA|XSLT|JDBC|ML", type) {
		set ..JavaHome = dao.JavaHome
		set ..JVMArgs = dao.JVMArgs
		set ..ClassPath = dao.ClassPath
	} elseif type = "PYTHON" {
		set ..PyOptions = dao.PyOptions
		set ..PythonPath = dao.PythonPath
	} else {
		// What?
	}
}

/// Checks to see if the object identified by the ID <var>id</var> exists in the extent.
/// 
/// <p>Returns <CLASS>%Boolean</CLASS> TRUE is it exists, FALSE if it does not.
ClassMethod %ExistsId(id As %String) As %Boolean [ ServerOnly = 0 ]
{
	return $system.external.serverExists(id)
}

}
