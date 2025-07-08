/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %External.language

/// This class implements SQL functions to support %SYSTEM.external
Class %SYSTEM.external.SQL [ Language = objectscript, System = 4 ]
{

/// Add a path to executables to the current java gateway path. 
/// For Java, this can be a folder or a jar URL.
ClassMethod addPath(serverName As %String, path As %String) As %Integer [ SqlName = add_path, SqlProc ]
{
	try {
		set server = $system.external.getServer(serverName)
		set gateway = $system.Context.SQL().getGateway(serverName,server.Type)
		do gateway.addToPath(.path)
		return 1
	} catch exception {
	}
	return 0
}

ClassMethod closeGateway(serverName As %String) As %Integer [ SqlName = close_gateway, SqlProc ]
{
	#dim gateway as %External.Gateway;
	try {
		if '$isobject(serverName) {
			set server = $system.external.getServer(serverName)
		} else {
			set server = serverName
		}
		set gateway = $system.Context.SQL().getCachedGateway(serverName)
		if $isobject(gateway) {
			set resp = gateway.disconnect()
			return gateway.Closed
		}
	} catch exception {
	}
	return 0
}

}
