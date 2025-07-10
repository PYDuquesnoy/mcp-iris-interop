/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A generic outbound adapter class intended for use where a Java proxy class will be constructed and InterSystems IRIS will communicate with it by sending and retrieving message objects or data streams in a call-and-response fashion.
/// 
/// This contrasts with the intended use of the JavaGateway AbstractOperation, which is intended to be subclassed with an adapterless Operation that invokes standard Java APIs directly.
/// 
/// This adapter can be used directly without subclassing if the Java proxy class implements the following methods:
/// 
/// .Connect(pJGClientConnectSpec,pTimeout,pInbound)
/// .Disconnect(pInbound)
/// .IsConnected(pInbound)
/// .getErrorText() [returns empty string if no error on previous method call]
/// .ReceiveMessage(pTimeout) [inbound only; pMsgIn return needs not be populated if timed out]
/// .SendResponse(pMsgOut) [inbound only, optional-needed if OnProcessInput will return an object]
/// .SendMessage(pMsgOut,pGetReply,pResponseTimeout) [outbound only; pMsgIn return needs not be populated if no responses are anticipated]
/// 
/// If a Java proxy cannot be constructed with this interface then you should subclass this adapter and the subclass can optionally override the following methods and call the Java proxy in whatever manner it must.
/// 
/// .OnConnectProxy(pTimeout As %Numeric, pInbound As %Boolean) As %Status
/// .OnDisconnectProxy(pInbound As %Boolean) As %Status
/// .OnIsConnectedProxy(pInbound As %Boolean) As %Status
/// .OnReceiveMessage(Output pMsgIn As %RegisteredObject) As %Status [inbound only]
/// .OnSendResponse(pMsgOut As %RegisteredObject) As %Status [inbound only]
/// .OnSendMessage(pMsgOut As %RegisteredObject, Output pMsgIn As %RegisteredObject) As %Status [outbound only]
/// 
Class EnsLib.JavaGateway.OutboundAdapter Extends (Ens.OutboundAdapter, EnsLib.JavaGateway.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

/* Override from Superclass to be Required */
/// Config Name of the Java Gateway service controlling the Java Gateway server this Operation will use.
Property JGService As %String(MAXLEN = 128) [ Required ];

/// If true, wait to read a reply message back before returning.
Property GetReply As %Boolean [ InitialExpression = 1 ];

/// Number of seconds to wait for a response to begin arriving back from the remote system after sending a request. Setting the timeout to -1 means wait forever.
Property ResponseTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 30 ];

Method OnInit() As %Status
{
	Set tSC=..initAdapterJG()  Quit:$$$ISERR(tSC) tSC
	Set tSC=##super() Quit:$$$ISERR(tSC) tSC
	Set:..StayConnected>0 ..KeepaliveInterval=..StayConnected
	If ..StayConnected<0 { Set tSC=..Connect(..ConnectTimeout,,..%JGConnectTimeout)  If $$$ISERR(tSC) $$$LOGWARNING($$$StatusDisplayString(tSC)) } // timeout is not fatal at this point, but do log it
	Else { $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC) }
	Quit $$$OK
}

Method SendMessage(pMsgOut As %RegisteredObject, Output pMsgIn As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Set $ZT="Trap"
	Do {
		Set tSC=..Connect(..ConnectTimeout,,..%JGConnectTimeout)  Quit:$$$ISERR(tSC)
		Set tSC=..OnSendMessage(pMsgOut,.pMsgIn)
		Set:'$D(pMsgIn) pMsgIn=$$$NULLOREF
	} While 0
Exit
	Quit ..handleErr(tSC)
Trap
	Set $ZT="", tSC=$S($ZE["<ZJGTW>":$$$ERROR($$$EnsErrGeneral,"Java Gateway error:"_$$$StatusDisplayString(%objlasterror)),1:$$$SystemError)
	GoTo Exit
}

/// Override this method to provide customized client send/receive handling
Method OnSendMessage(pMsgOut As %RegisteredObject, Output pMsgIn As %RegisteredObject) As %Status [ Internal ]
{
	Set pMsgIn=..%JGProxy.SendMessage(pMsgOut,..GetReply,$S(..ResponseTimeout=-1:2123456789,1:..ResponseTimeout)), tErrTxt=..%JGProxy.getErrorText()
	Quit:""'=tErrTxt $$$ERROR($$$EnsErrGeneral,"Java Gateway Client '"_..JGClientEnsClassname_".SendMessage("_pMsgOut_",.pMsgIn,"_..GetReply_","_..ResponseTimeout_")' failed with status "_tErrTxt)
	Quit $$$OK
}

Method handleErr(pSC As %Status) As %Status [ Internal ]
{
	If $$$ISERR(pSC) {
		Set tNetErr=..isNetErr($$$StatusText(pSC))
		Set:tNetErr pSC=$$$ERROR($$$EnsErrOutConnectionLost,"Java Gateway",..%IOAddr,$$$StatusDisplayString(pSC))
		If tNetErr || $$$StatusEquals(pSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed,$$$EnsErrOutConnectException) { ; retry on timeouts also
			Set ..BusinessHost.Retry=1
		}
		If tNetErr||('..StayConnected&&'..BusinessHost.Retry) { Do ..Disconnect() }
		ElseIf ..StayConnected { Do ..TestConnection() } ; calls Disconnect() if connection is down
	} ElseIf '..StayConnected { Do ..Disconnect() }
	Quit pSC
}

/*
	If $$$ISERR(tSC) {
		If ..isNetErr($$$StatusText(tSC)) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"Java Gateway",..%IOAddr,$$$StatusDisplayString(tSC))
			Set ..BusinessHost.Retry=1  Do ..Disconnect()
		} Else {
			If '..StayConnected { Do ..Disconnect() }
			Else { Do ..TestConnection() } ; calls Disconnect() if connection is down
		}
		$$$ASAVEIOLOGENTRY(tSC,"after JG SendMessage error on "_..%IOAddr,$$$NULLOREF)
		Quit tSC
	}
	Do:'..StayConnected&&'..BusinessHost.Retry ..Disconnect()

*/
}
