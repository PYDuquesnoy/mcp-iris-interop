/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.PEX.OutboundAdapter Extends (Ens.OutboundAdapter, EnsLib.PEX.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SETTINGS = "%remoteClassname:Remote OutboundAdapter,%gatewayName:Remote OutboundAdapter:ExternalLanguageServerSelector?Types=.NET;Java;Python,%remoteSettings:Remote OutboundAdapter,%useHostConnection:Alternative AdapterConnection1,%gatewayHost:Alternative AdapterConnection2,%gatewayPort:Alternative AdapterConnection2,%gatewayTimeout:Alternative AdapterConnection2,%gatewayExtraClasspaths:Remote OutboundAdapter:classpathsTable";

/// Use Host Connection. If set to true, this adapter will use the connection from the Business Operation.
/// If true, this supersedes both the External Language Server and any specified Gateway Host and Port.
Property %useHostConnection As %Boolean [ Internal ];

/// External Language Server Name. Once specified, it supersedes the settings in Gateway Host and Gateway Port.
/// Using External Language Server is preferred over Gateway Host and Gateway Port.
/// However, if <property>%useHostConnection</property> is specified, the Business Operation connection supersedes the value selected here.
Property %gatewayName As %String;

Method %DispatchMethod(method As %String, args...) As %ObjectHandle
{
	if $quit {
		quit $method($this.%gatewayProxy,method,args...)
	} else {
		do $method($this.%gatewayProxy,method,args...)
		quit
	}
}

}
