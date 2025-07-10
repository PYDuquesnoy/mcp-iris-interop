/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.JMS.Common Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// URL for JMS Server
Property JMSServer As %String(MAXLEN = "");

/// Name for INITIAL_CONTEXT_FACTORY
Property JMSInitialContextFactory As %String(MAXLEN = "");

/// Name of QueueConnectionFactory
Property JMSFactory As %String(MAXLEN = "");

/// Name of Queue
Property JMSQueue As %String(MAXLEN = "");

/// ClientID to use for the connection
Property JMSClientID As %String(MAXLEN = "");

/// Log file name
Property JMSLogFileName As %String(MAXLEN = "");

/// This is the ID name of the set of credentials values (Username, Password) to be used to access the HTTP server
Property JMSCredentials As %String [ InitialExpression = "None" ];

/// JavaGateway Server
Property JavaGatewayHost As %String [ InitialExpression = "127.0.0.1", Internal ];

/// JavaGateway Port
Property JavaGatewayPort As %Integer [ InitialExpression = 55555, Internal ];

/// Number of seconds to wait on each attempt to connect to the Java Gateway
Property JavaGatewayTimeout As %Numeric(MAXVAL = 30000, MINVAL = 0) [ InitialExpression = 5 ];

/// JavaGateway Additional ClassPaths
Property JavaGatewayAdditionalClassPaths As %String(MAXLEN = "");

Parameter SETTINGS = "JavaGatewayHost,JavaGatewayPort,JavaGatewayTimeout,JavaGatewayAdditionalClassPaths,JMSServer,JMSInitialContextFactory,JMSFactory,JMSQueue,JMSClientID,JMSCredentials:Basic:credentialsSelector,JMSLogFileName";

/// The JavaGateway connection object
Property %JavaGateway As %Net.Remote.Gateway;

/// The proxy object for the JavaGateway connection
Property %JavaGatewayProxy As %RegisteredObject;

Parameter ISINBOUND As BOOLEAN = 0;

Method OnInit() As %Status
{
	set tSC = $$$OK
	try {
		Set tSC = ..Connect()
		if $$$ISERR(tSC) {
			$$$LOGERROR($system.Status.GetErrorText(tSC))
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"ERROR")
			set tSC = $$$OK
			quit
		}
	} catch ex {
		set tSC = ex.AsStatus()
		do ..CheckGatewayDisconnection()
	}
	quit tSC
}

Method OnTearDown() As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..Disconnect() quit:$$$ISERR(tSC)
	} catch ex {
		set tSC = ex.AsStatus()
		do ..CheckGatewayDisconnection()
	}
	quit tSC
}

Method Connect() As %Status
{
	set tSC = $$$OK
	try {
		if $isObject(..%JavaGateway)&&('..%JavaGateway.Closed) quit
		;
		$$$catTRACE("connwait","Connecting to JavaGateway: "_..JavaGatewayHost_":"_..JavaGatewayPort)
		;
		set ..%JavaGateway = ##class(%Net.Remote.Gateway).%New()
		set tSC = ..%JavaGateway.%Connect(..JavaGatewayHost,..JavaGatewayPort,$znspace,..JavaGatewayTimeout) quit:$$$ISERR(tSC)
		;
		set separator = $s($$$isWINDOWS:";",1:":")
		set classpaths = ##class(%ListOfDataTypes).%New()
		for i=1:1:$l(..JavaGatewayAdditionalClassPaths,separator) do classpaths.Insert($p(..JavaGatewayAdditionalClassPaths,separator,i))
		do ..%JavaGateway.%AddToCurrentClassPath(classpaths)
		;
		set clientID = ..JMSClientID
		if clientID="" set clientID = "Ensemble:"_##class(%SYS.System).GetUniqueInstanceName()_":"_$namespace_":"_..BusinessHost.%ConfigName
		set tSC = ##Class(Ens.Config.Credentials).GetCredentialsObj(.credentialsObj,$classname($this),"Ens.Config.Credentials",..JMSCredentials) quit:$$$ISERR(tSC)
		set clientConnectSpec = ..JMSServer_$c(10)_..JMSInitialContextFactory_$c(10)_..JMSFactory_$c(10)_..JMSQueue_$c(10)_clientID_$c(10)_credentialsObj.Username_$c(10)_credentialsObj.Password_$c(10)_..JMSLogFileName
		;
		set ..%JavaGatewayProxy = ##class(%Net.Remote.Object).%New(..%JavaGateway,"com.intersystems.enslib.jms.Manager")
		set errorText = ..%JavaGatewayProxy.Connect(clientConnectSpec,..#ISINBOUND)
		if errorText'="" set tSC = $$$ERROR($$$GeneralError,"JMS call Connect() failed with status: "_errorText) quit
	} catch ex {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) set (..%JavaGateway,..%JavaGatewayProxy) = $$$NULLOREF
	quit tSC
}

Method Disconnect() As %Status
{
	if $isObject(..%JavaGatewayProxy)=0 quit $$$OK
	if $isObject(..%JavaGateway)=0 quit $$$OK
	set errorText =  ..%JavaGatewayProxy.Disconnect(..#ISINBOUND)
	if errorText'="" set tSC = $$$ERROR($$$GeneralError,"JMS call Disconnect() failed with status: "_errorText)
	set (..%JavaGateway,..%JavaGatewayProxy) = $$$NULLOREF
	quit tSC
}

Method CheckGatewayDisconnection() As %Boolean
{
	set isConnected = 0
	try { set isConnected = $$$ISOK(..%JavaGateway.%Ping(,,,1,..%JavaGateway.GatewayDevice)) } catch {}
	if 'isConnected set (..%JavaGateway,..%JavaGatewayProxy) = $$$NULLOREF
	quit isConnected
}

Method CheckGatewayConnection() As %Status
{
	quit ..Connect()
}

}
