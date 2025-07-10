/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A generic inbound adapter class intended for use where a Java proxy class will be constructed and InterSystems IRIS will communicate with it by sending and retrieving message objects or data streams in a call-and-response fashion.
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
Class EnsLib.JavaGateway.InboundAdapter Extends (Ens.InboundAdapter, EnsLib.JavaGateway.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

/* Override from Superclass to be Required */
/// Config Name of the Java Gateway service controlling the Java Gateway server this Operation will use.
Property JGService As %String(MAXLEN = 128) [ Required ];

Method OnInit() As %Status
{
	Set tSC=..initAdapterJG()  Quit:$$$ISERR(tSC) tSC
	Set:..StayConnected>0&&(..StayConnected<..CallInterval) ..KeepaliveInterval=..StayConnected
	
	If ..StayConnected { Set tSC=..Connect(..ConnectTimeout,1,..%JGConnectTimeout)  If $$$ISERR(tSC) $$$LOGWARNING($$$StatusDisplayString(tSC)) } // timeout is not fatal at this point, but do log it
	Else { $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC) }
	Quit $$$OK
}

Method OnTask() As %Status
{
	Set tSC=..Connect(..ConnectTimeout,1,..%JGConnectTimeout)  Quit:$$$ISERR(tSC) tSC
	Set $ZT="TrapR", tSC=..OnReceiveMessage(.tMsgIn)
	Set $ZT=""
ExitR
	If $$$ISERR(tSC) Do:..isNetErr($$$StatusText(tSC)) ..Disconnect(1)  Quit tSC
	If '$IsObject(tMsgIn) {
		Do:'..StayConnected ..Disconnect(1)
		Quit $$$OK
	}
	Set tSC=..BusinessHost.ProcessInput(tMsgIn,.tMsgOut)  Quit:$$$ISERR(tSC) tSC
	If $$$IsdefObject(tMsgOut) {
		Set $ZT="TrapS", tSC=..OnSendResponse(.tMsgOut)
		Set $ZT=""
ExitS
		If $$$ISERR(tSC) Do:..isNetErr($$$StatusText(tSC)) ..Disconnect(1)  Quit tSC
	}
	Quit tSC
TrapR
	Set $ZT="", tSC=$S($ZE["<ZJGTW>":$$$ERROR($$$EnsErrGeneral,"Java Gateway error:"_$$$StatusDisplayString(%objlasterror)),1:$$$SystemError)
	GoTo ExitR
TrapS
	Set $ZT="", tSC=$S($ZE["<ZJGTW>":$$$ERROR($$$EnsErrGeneral,"Java Gateway error:"_$$$StatusDisplayString(%objlasterror)),1:$$$SystemError)
	GoTo ExitS
}

/// Override this method to provide customized client send/receive handling
Method OnReceiveMessage(Output pMsgIn As %RegisteredObject) As %Status [ Internal ]
{
    Set pMsgIn=..%JGProxy.ReceiveMessage(..CallInterval), tErrTxt=..%JGProxy.getErrorText()
    Quit:""'=tErrTxt $$$ERROR($$$EnsErrGeneral,"Java Gateway Client '"_..JGClientEnsClassname_".ReceiveMessage("_..CallInterval_")' failed with status "_tErrTxt)
    Quit $$$OK
}

/// Override this method to provide customized client send/receive handling
Method OnSendResponse(pMsgOut As %RegisteredObject) As %Status [ Internal ]
{
    Do ..%JGProxy.SendResponse(pMsgOut)  Set tErrTxt=..%JGProxy.getErrorText()
    Quit:""'=tErrTxt $$$ERROR($$$EnsErrGeneral,"Java Gateway Client '"_..JGClientEnsClassname_".SendResponse("_pMsgOut_")' failed with status "_tErrTxt)
    Quit $$$OK
}

Method OnTearDown() As %Status [ Internal ]
{
	Do ..Disconnect(1)
	Quit $$$OK
}

}
