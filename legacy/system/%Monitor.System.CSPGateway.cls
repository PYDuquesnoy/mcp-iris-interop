/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Monitor.System.CSPGateway Extends %Monitor.System.Adaptor [ System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CSPGateway";

Parameter INDEX [ Internal ] = "GatewayName";

/// Name of dataset
Property GatewayName As %Monitor.String;

Property GWNumber As %Monitor.Integer;

Property GWVersion As %Monitor.String;

Property Activity As %Monitor.String;

Property MaxConnections As %Monitor.Integer;

Property ActualConnections As %Monitor.Integer;

Property InUseConnections As %Monitor.Integer;

Property PrivateConnections As %Monitor.Integer;

Property GWRegistry As %CSP.Mgr.GatewayRegistry;

Property GWList As %Library.ListOfObjects;

/// Initialize Gateway metrics.
Method Initialize() As %Status
{
	Set $ZTrap="InitializeError"
	Set ..GWRegistry = $system.CSP.GetGatewayRegistry()
	Set ..GWList = ..GWRegistry.GetGatewayMgrs()
	Set ..GWNumber = 0
	For GWN=1:1:..GWList.Count() {
		Set gateway = ..GWList.GetAt(GWN)
	}
	Quit $$$OK
InitializeError // Error
	Quit 0
}

/// Interrogate the Gateway to obtain metrics
/// <br><br>
/// A return code of $$$OK indicates there is a new Gateway instance.<br>
/// A return code of 0 indicates there is no Gateway instance.
Method GetSample() As %Status
{
	Set $ZTrap="GetSampleError"
	Set ..GWNumber = ..GWNumber + 1
	If ..GWNumber>..GWList.Count() Quit 0
	Set gateway = ..GWList.GetAt(..GWNumber)
	Do gateway.GetSystemMetrics(.metrics)
	Set ..GatewayName = gateway.IPAddress_":"_gateway.Port
	Set ..GWVersion = gateway.Version
	Set ..Activity=$Get(metrics("Activity"))+0
	Set ..MaxConnections=$Get(metrics("MaxConnections"))+0
	Set ..ActualConnections=$Get(metrics("ActualConnections"))+0
	Set ..InUseConnections=$Get(metrics("InUseConnections"))+0
	Set ..PrivateConnections=$Get(metrics("PrivateConnections"))+0
 	Q $$$OK
GetSampleError // Error
	Quit 0
}

ClassMethod SetAlert(Minimum As %Integer) As %Integer
{
	Quit 0
}

}
