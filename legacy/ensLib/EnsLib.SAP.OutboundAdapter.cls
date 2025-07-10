/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Deprecated: iWay-based SAP adapter
Class EnsLib.SAP.OutboundAdapter Extends EnsLib.IWay.OutboundAdapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Time the last pool job should wait for its turn to log in to SAP
Property PoolLoginTimeout As %Numeric [ InitialExpression = 60 ];

Parameter SETTINGS = "PoolLoginTimeout";

Property LoggingIn As %Boolean;

Method RFCRequest(pRequest As Ens.Request, Output pResponse As Ens.Response) As %Status [ CodeMode = expression ]
{
..IWayRequest(.pRequest, .pResponse)
}

Method BAPIRequest(pRequest As Ens.Request, Output pResponse As Ens.Response) As %Status [ CodeMode = expression ]
{
..IWayRequest(.pRequest, .pResponse)
}

Method IDOCRequest(pRequest As Ens.Request, Output pResponse As Ens.Response) As %Status [ CodeMode = expression ]
{
..IWayRequest(.pRequest, .pResponse)
}

Method Connect(pTimeout As %Numeric) As %Status
{
	Do:..Connected ..TestConnection()  Set tConnected=..Connected
	Set tSC = $S(..Connected:$$$OK,1:##super(pTimeout))
	if 'tConnected && $$$ISOK(tSC) && ..StayConnected && '..LoggingIn {
		$$$sysTRACE("CALLED super, calling SAP login")
		Set ..LoggingIn = 1
		$$$ASSERT(..Connected)
		Set tReq=##class(EnsLib.SAP.RFCPING).%New()

		Lock +$$$EnsRuntimeAppData($$$CurrentClass):..PoolLoginTimeout Else  Goto NoLock
		Set tSC1=..IWayRequest(tReq,.tResp), ..BusinessHost.Retry = 0
		Lock -$$$EnsRuntimeAppData($$$CurrentClass)
		Set ..LoggingIn = 0

		if $$$ISOK(tSC1) $$$LOGINFO("Login to SAP system successful")
		#; Normally we don't retry on a READ error from an Outbound adapter, but in this case we should:
		else   $$$LOGWARNING("Login to SAP system failed with error "_$$$StatusDisplayString(tSC1)_"; disconnecting...")  Do ..Disconnect() Set tSC=tSC1,..BusinessHost.Retry = 1
		$$$sysTRACE("Returning from SAP login")
	}
	Quit tSC
NoLock
	Quit $$$EnsError($$$EnsErrIWay,"Timed out ("_..PoolLoginTimeout_") waiting for lock to do SAP connect")
}

}
