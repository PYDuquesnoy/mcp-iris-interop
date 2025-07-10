/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// SQL database client adapter. Executes queries against a remote database via an ODBC- or JDBC- defined DSN (Data Source Name) and retrieves resultsets and/or Stored Procedure return values and output parameters..
Class EnsLib.SQL.OutboundAdapter Extends (Ens.OutboundAdapter, EnsLib.SQL.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Method OnInit() As %Status
{
	#; Create an instance of the SQLGateway object
	Set tSC=##super() Quit:$$$ISERR(tSC) tSC
	Set tSC=..init()  Quit:$$$ISERR(tSC) tSC
	Set:..StayConnected>0 ..KeepaliveInterval=..StayConnected
	If ..StayConnected<0 { Set tSC=..Connect(..ConnectTimeout)  If $$$ISERR(tSC) $$$LOGWARNING($$$StatusDisplayString(tSC)) } // timeout is not fatal at this point, but do log it
	Else { $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC) }
	Do ..deleteRuntimeAppData()
	Quit $$$OK
}

}
