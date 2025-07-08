/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %External.language

/// This class implements SQL functions to support %SYSTEM.python
Class %SYSTEM.python.SQL [ Language = objectscript, Owner = {%Manager}, System = 4 ]
{

/// Add a path to executables to the current python gateway path. 
/// For Python, this can be a folder representing a package or a .py file URL.
ClassMethod addPath(path As %String) As %Integer [ SqlName = add_path, SqlProc ]
{
	if '$SYSTEM.Security.Check($$$AdminExternalLanguageServerEditResourceName,$$$PermUseName) {
		$$$ThrowStatus($$$ERROR($$$OperationRequires,$$$AdminExternalLanguageServerEditResourceName_":"_$$$PermUseName))
	}
	set python = $system.Context.SQL().getGateway($$$EXTERNALLANGUAGESERVERNAMEPYTHON,$$$EXTERNALLANGUAGEPYTHON)
	do python.addToPath(.path)
	return 1
}

/// Close the gateway connection to the External Python Server. 
ClassMethod closeGateway() As %Integer [ SqlName = close_gateway, SqlProc ]
{
	#dim gateway as %External.Gateway;
	if '$SYSTEM.Security.Check($$$AdminExternalLanguageServerEditResourceName,$$$PermUseName) {
		$$$ThrowStatus($$$ERROR($$$OperationRequires,$$$AdminExternalLanguageServerEditResourceName_":"_$$$PermUseName))
	}
	try {
		set gateway = $system.Context.SQL().getCachedGateway($$$EXTERNALLANGUAGESERVERNAMEPYTHON)
		if $isobject(gateway) {
			set resp = gateway.disconnect()
			return gateway.Closed
		}
	} catch exception {
	}
	return 0
}

}
