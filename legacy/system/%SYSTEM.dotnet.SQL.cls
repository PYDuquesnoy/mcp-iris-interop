/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %External.language

/// This class implements SQL functions to support %SYSTEM.dotnet
Class %SYSTEM.dotnet.SQL [ Language = objectscript, Owner = {%Manager}, System = 4 ]
{

/// Add a path to executables to the current dotnet gateway path. 
ClassMethod addPath(path As %String) As %Integer [ SqlName = add_path, SqlProc ]
{
	if '$SYSTEM.Security.Check($$$AdminExternalLanguageServerEditResourceName,$$$PermUseName) {
		$$$ThrowStatus($$$ERROR($$$OperationRequires,$$$AdminExternalLanguageServerEditResourceName_":"_$$$PermUseName))
	}
	set dotnet = $system.Context.SQL().getGateway($$$EXTERNALLANGUAGESERVERNAMEDOTNET,$$$EXTERNALLANGUAGEDOTNET)
	do dotnet.addToPath(.path)
	return 1
}

/// Close the gateway connection to the External DotNet Server. 
ClassMethod closeGateway() As %Integer [ SqlName = close_gateway, SqlProc ]
{
	#dim gateway as %External.DotNetGateway;
	if '$SYSTEM.Security.Check($$$AdminExternalLanguageServerEditResourceName,$$$PermUseName) {
		$$$ThrowStatus($$$ERROR($$$OperationRequires,$$$AdminExternalLanguageServerEditResourceName_":"_$$$PermUseName))
	}
	try {
		set gateway = $system.Context.SQL().getCachedGateway($$$EXTERNALLANGUAGESERVERNAMEDOTNET)
		if $isobject(gateway) {
			do gateway.disconnect()
			return gateway.Closed
		}
	} catch exception {
	}
	return 0
}

}
