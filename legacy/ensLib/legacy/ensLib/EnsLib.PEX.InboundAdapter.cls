/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.PEX.InboundAdapter Extends (Ens.InboundAdapter, EnsLib.PEX.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SETTINGS = "%remoteClassname:Remote InboundAdapter,%gatewayName:Remote InboundAdapter:ExternalLanguageServerSelector?Types=.NET;Java;Python,%remoteSettings:Remote InboundAdapter,%useHostConnection:Alternative AdapterConnection1,%gatewayHost:Alternative AdapterConnection2,%gatewayPort:Alternative AdapterConnection2,%gatewayTimeout:Alternative AdapterConnection2,%gatewayExtraClasspaths:Remote InboundAdapter:classpathsTable";

/// Use Host Connection. If set to true, this adapter will use the connection from the Business Service.
/// If true, this supersedes both the External Language Server and any specified Gateway Host and Port.
Property %useHostConnection As %Boolean [ Internal ];

/// External Language Server Name. Once specified, it supersedes the settings in Gateway Host and Gateway Port.
/// Using External Language Server is preferred over Gateway Host and Gateway Port.
/// However, if <property>%useHostConnection</property> is specified, the Business Service connection supersedes the value selected here.
Property %gatewayName As %String;

Method OnTask() As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..CheckGatewayConnection() quit:$$$ISERR(tSC)
		do ..%gatewayProxy.OnTask()
	} catch ex {
		set tSC = ex.AsStatus()
		do ..CheckGatewayDisconnection()
	}
	quit tSC
}

}
