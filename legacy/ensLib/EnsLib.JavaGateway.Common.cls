/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Common base class for JavaGateway Inbound and Outbound Adapters including the SQL adapters in their use of JDBC.
Class EnsLib.JavaGateway.Common Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Info the JavaGateway Client class can use to connect to the intended target system
Property JGClientConnectSpec As %String(MAXLEN = 500);

/// InterSystems IRIS classname of the Java Gateway proxy class that serves as this Config Item's interface to its associated Java code
Property JGClientEnsClassname As %String(MAXLEN = 128);

/* note: not marked Required because some subclasses do not require it (e.g. SQL Adapter)  */
/// Config Name of the Java Gateway service controlling the Java Gateway server this Operation will use.
Property JGService As %String(MAXLEN = 128);

/// Is the JGService Setting for this Adapter (subclass) required? If so and it's empty, we will return an error from initialization.
Parameter REQUIREJGSERVICE As %Boolean = 1;

/// Controls whether Service specific classpath jars are loaded per process "1" (the default) or by thread context "0"
/// Recomended defaulting this to "1" as some thirdparty ODBC JARs show thread and memory leaking when loaded by thread context
Parameter USEPROCESSLOADER As %Boolean = 1;

/// One or more Java Classpaths (separated by '|' character) needed in addition to the ones configured in the Java Gateway Service
/// in order to execute the Java code for this Config Item
Property ExtraJGClasspaths As %String(MAXLEN = 1000);

/// If non-zero, stay connected to the remote system between handling Requests until idle for this number of seconds. A value of -1 means never disconnect.
Property StayConnected As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

Parameter SETTINGS As %String = "JGClientConnectSpec,JGClientEnsClassname,JGService,ExtraJGClasspaths,StayConnected";

/* Expose this property as a Setting in your subclass if you need to control the timeout of a Java Client connecting to its target service */
/// Number of seconds to wait on each attempt to connect from the Java Gateway to the ultimate Java client
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 15 ];

/// How frequently should be check whether a StayConnected connection is still up
Property KeepaliveInterval As %Numeric [ InitialExpression = 1 ];

/// Are we currently connected to the Java Gateway and does the Proxy object exist and is it connected to its remote system
Property Connected As %Boolean [ InitialExpression = 0 ];

/// Local flag controlling logging of connection and disconnection events
Property %logConnections As %Boolean [ InitialExpression = 1 ];

/// String naming JavaGateway TCP/IP address:port, and local port if applicable
Property %IOAddr As %String [ ReadOnly ];

/// The JavaGateway connection object
Property %JavaGateway As %Net.Remote.Java.JavaGateway;

/// The Proxy for the Java connector object
Property %JGProxy As %RegisteredObject;

Property %JGgatewayName As %String [ Internal ];

Property %JGServer As %String [ InitialExpression = "127.0.0.1", Internal ];

Property %JGPort As %Integer [ InitialExpression = 55555, Internal ];

/// Number of seconds to wait on each attempt to connect to the Java Gateway
Property %JGConnectTimeout As %Numeric(MAXVAL = 30000, MINVAL = 0) [ InitialExpression = 5 ];

Property %JGSSLConfig As %String [ Internal ];

Property %ClientIOAddr As %String;

Method initJG() As %Status
{
	Set ..%JavaGateway = ##class(%Net.Remote.Java.JavaGateway).%New()
	If ""'=..JGService {
		Set tItem=##class(Ens.Host).GetShadowInstance(..JGService,.tSC)  Quit:$$$ISERR(tSC) tSC
		Set ..%JGgatewayName = tItem.%gatewayName
		Set ..%JGServer=tItem.Server
		Set ..%JGPort=tItem.Port
		//Set ..%JGConnectTimeout=tItem.ConnectTimeout
		//Set ..%JGSSLConfig=tItem.SSLConfig
	} ElseIf ..#REQUIREJGSERVICE {
		Quit $$$ERROR($$$EnsErrGeneral,"In order to work this Adapter requires the JGService setting to be configured")
	}
	Quit $$$OK
}

Method initAdapterJG() As %Status
{
	Set tSC=..initJG()  Quit:$$$ISERR(tSC) tSC
	If 0=..BusinessHost.%GetParameter("LOGCONNECTIONS") Set ..%logConnections=0
	Quit $$$OK
}

Method ConnectedSet(pValue As %Boolean) As %Status
{
	If i%Connected'=pValue {
		Set i%Connected=pValue
		$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,pValue_"|"_$$$timeUTC_"|"_..%IOAddr)
	}
	Quit $$$OK
}

Method Connect(pClientTimeout As %Numeric = 15, pInbound As %Boolean = 0, pJGTimeout As %Numeric = 5) As %Status
{
	If ..Connected { Do ..TestConnection(pInbound)  Quit:..Connected $$$OK }

	Set tSC=..ConnectJG(pJGTimeout,pInbound)  Quit:$$$ISERR(tSC) tSC
	Quit:..%JavaGateway.Closed $$$ERROR($$$EnsErrGeneral,"Failed to open connection to Java Gateway '"_..JGService_"' ("_..%IOAddr_")")
	
	Set %objlasterror=$$$OK
 	Set ..%JGProxy=$zobjclassmethod(..JGClientEnsClassname,"%New",..%JavaGateway)
	If '$IsObject(..%JGProxy) { Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to instantiate Java Gateway Client class '"_..JGClientEnsClassname_"' "_$$$StatusDisplayString(%objlasterror)) }
	Else {
		Set $ZT="Trap"
		Set tSC=..OnConnectProxy(pClientTimeout,pInbound)
		If $$$ISOK(tSC)  {
			If ..%JGgatewayName'="" {
				Set i%%IOAddr=..%JGgatewayName_$S(""=..%JGSSLConfig:"",1:"/SSL="_..%JGSSLConfig)_"+"_..JGClientEnsClassname_":"_..%ClientIOAddr
			} Else {
				Set i%%IOAddr=..%JGServer_":"_..%JGPort_$S(""=..%JGSSLConfig:"",1:"/SSL="_..%JGSSLConfig)_"+"_..JGClientEnsClassname_":"_..%ClientIOAddr
			}
			Set ..Connected=1, tTxt="Opened JG connection to "_..%IOAddr
			If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
			If $ZStrip(..BusinessHost.%LastReportedError,"*W") [ "JavaGateway" {
				Set ..BusinessHost.%LastReportedError=""
				$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
			}
			Quit $$$OK
		}
	}
Exit
	Set ..%JGProxy=$$$NULLOREF
	Do ..DisconnectJG(pInbound)
	Quit tSC
Trap
	Set $ZT="", tSC=$S($ZE["<ZJGTW>":$$$ERROR($$$EnsErrGeneral,"Java Gateway error:"_$$$StatusDisplayString(%objlasterror)),1:$$$SystemError)
	GoTo Exit
}

/// Override this method to provide customized client connection handling
Method OnConnectProxy(pTimeout As %Numeric, pInbound As %Boolean) As %Status [ Internal ]
{
	Do ..%JGProxy.Connect(..JGClientConnectSpec,pTimeout,pInbound)  Set tErrTxt=..%JGProxy.getErrorText()
	Quit:""'=tErrTxt $$$ERROR($$$EnsErrGeneral,"Java Gateway Client '"_..JGClientEnsClassname_".Connect("_..JGClientConnectSpec_","_pTimeout_","_pInbound_")' failed with status "_tErrTxt)
	Set ..%ClientIOAddr=..JGClientConnectSpec
	Quit $$$OK
}

Method ConnectJG(pTimeout As %Numeric = 30, pInbound As %Boolean = 0) As %Status [ Internal ]
{
	Quit:'..%JavaGateway.Closed $$$OK
	$$$catTRACE("connwait","Connecting to JavaGateway: "_$S(..%JGgatewayName'="":..%JGgatewayName,1:(..%JGServer_":"_..%JGPort))_$S(""=..%JGSSLConfig:"",1:"/SSL="_..%JGSSLConfig)_"+"_..JGClientEnsClassname_":"_..%ClientIOAddr)
	If ..%JGgatewayName'="" {
		Set tSC=..%JavaGateway.%Connect("",..%JGgatewayName,$ZNSpace,pTimeout,,,,0)
	} Else {
		Set tSC=..%JavaGateway.%Connect(..%JGServer,..%JGPort,$ZNSpace,pTimeout,,,,0)
	}
	// If sucessfully connected, now add classpaths if relevant
	If $$$ISOK(tSC),$Length(..ExtraJGClasspaths) {
		#dim tClasspaths as %ListOfDataTypes=##class(%ListOfDataTypes).%New()
		For i=1:1:$Length(..ExtraJGClasspaths,"|") { 
			Set tPath=$Piece(..ExtraJGClasspaths,"|",i)
			Continue:""=tPath
			Do tClasspaths.Insert(tPath)
		}
		If tClasspaths.Count()>0 {
			$$$catTRACE("connwait","Loading Classpaths on new connection with ProcessLoader: "_..ExtraJGClasspaths)
			Set tSC=..%JavaGateway.%AddToCurrentClassPath(tClasspaths,..#USEPROCESSLOADER)
		}
	}
	Quit tSC
}

/// Disconnect from the Java Gateway Client
Method Disconnect(pInbound As %Boolean = 0)
{
	Quit:'..Connected
	Set tSC=$$$OK, tTxt="Disconnecting from "_..%IOAddr
	If ..StayConnected<0 { $$$LOGINFO(tTxt) }
	Else {
		If pInbound&&'..StayConnected { $$$catTRACE("connwait",tTxt) }
		ElseIf ..%logConnections { $$$LOGINFO(tTxt) }
		Else { $$$sysTRACE(tTxt) }
	}
	If '..%JavaGateway.Closed && $IsObject(..%JGProxy) {
		Set $ZT="Trap"
		Set tSC=..OnDisconnectProxy(pInbound)
	}
Exit
	If $$$ISERR(tSC) $$$sysTRACE($$$StatusText(tSC)) ; log it here because nobody will return the error to the calling BP or BS
	Set ..%JGProxy=$$$NULLOREF, ..%ClientIOAddr=""
	Do ..DisconnectJG(pInbound)
	Set ..Connected=0
	Quit
Trap
	Set $ZT="", tSC=$S($ZE["<ZJGTW>":$$$ERROR($$$EnsErrGeneral,"Java Gateway error:"_$$$StatusDisplayString(%objlasterror)),1:$$$SystemError)
	GoTo Exit
}

/// Override this method to provide customized client connection handling
Method OnDisconnectProxy(pInbound As %Boolean) As %Status [ Internal ]
{
	Do ..%JGProxy.Disconnect(pInbound)  Set tErrTxt=..%JGProxy.getErrorText()
	Quit:""=tErrTxt $$$OK
	Quit $$$ERROR($$$EnsErrGeneral,"Java Gateway Client '"_..JGClientEnsClassname_".Disconnect("_pInbound_")' failed with status "_tErrTxt)
}

/// Disconnect from the Java Gateway
Method DisconnectJG(pInbound As %Boolean = 0) [ Internal ]
{
	If $IsObject(..%JavaGateway) {
		Do ..%JavaGateway.%Disconnect()
	}
	Quit $$$OK
}

Method TestConnection(pInbound As %Boolean = 0)
{
	If '..Connected Set ..%JGProxy=$$$NULLOREF  Do:'..%JavaGateway.Closed ..%JavaGateway.%Disconnect()  Quit ; force JG class into sync in case it made a mistake
	$$$catTRACE("connwait","Testing Connection to "_..%IOAddr)
	If '..%JavaGateway.Closed && $IsObject(..%JGProxy) {
		Set $ZT="Trap"
		Set ..Connected=..OnIsConnectedProxy(pInbound)
	}
	Quit:..Connected

	Set tTxt=$$$StatusText($$$ERROR($S(pInbound:$$$EnsErrInConnectionLost,1:$$$EnsErrOutConnectionLost),"JG", ..%IOAddr, "..%JGProxy.IsConnected("_pInbound_")"))
	If ..StayConnected<0 { $$$LOGWARNING(tTxt) } Else { If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) } }
	Do ..Disconnect()
Trap  ; if it doesn't support isConnected then we just have to assume it still is connected
	Set $ZT="", tSC=$S($ZE["<ZJGTW>":$$$ERROR($$$EnsErrGeneral,"Java Gateway error:"_$$$StatusDisplayString(%objlasterror)),1:$$$SystemError)
	Set ..Connected=1
	Quit
}

/// Override this method to provide customized client connection test
Method OnIsConnectedProxy(pInbound As %Boolean) As %Boolean [ Internal ]
{
	Set tConnected=..%JGProxy.IsConnected(pInbound)  Set tErrTxt=..%JGProxy.getErrorText()
	Quit:""=tErrTxt tConnected
	$$$LOGWARNING("Java Gateway Client '"_..JGClientEnsClassname_".IsConnected("_pInbound_")' failed with status "_tErrTxt)
	Quit 1
}

Method OnTearDown() As %Status [ Internal ]
{
	Do ..Disconnect()
	Quit $$$OK
}

ClassMethod isNetErr(pErrorText As %String) As %Boolean [ Internal ]
{
	Quit 0
}

Method OnKeepalive() As %Status
{
	If ..Connected && (..StayConnected>0) && ($ZH-..BusinessHost.%LastHandledTime>=..StayConnected) {
		$$$sysTRACE("Disconnecting on expiration of idle interval StayConnected="_..StayConnected)
		Do ..Disconnect()
	}
	//Quit ##super($$$OK)
	Quit ##class(Ens.Adapter)$this.OnKeepalive($$$OK)
}

}
