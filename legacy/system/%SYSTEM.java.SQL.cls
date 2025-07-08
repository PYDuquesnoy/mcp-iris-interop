/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %External.language

/// This class implements SQL functions to support %SYSTEM.java
Class %SYSTEM.java.SQL [ Language = objectscript, Owner = {%Manager}, System = 4 ]
{

/// Add a path to executables to the current java gateway path. 
/// For Java, this can be a folder or a jar URL.
ClassMethod addPath(path As %String) As %Integer [ SqlName = add_path, SqlProc ]
{
	if '$SYSTEM.Security.Check($$$AdminExternalLanguageServerEditResourceName,$$$PermUseName) {
		$$$ThrowStatus($$$ERROR($$$OperationRequires,$$$AdminExternalLanguageServerEditResourceName_":"_$$$PermUseName))
	}
	set java = $system.Context.SQL().getGateway($$$EXTERNALLANGUAGESERVERNAMEJAVA,$$$EXTERNALLANGUAGEJAVA)
	do java.addToPath(.path)
	return 1
}

/// Close the gateway connection to the External Java Server. 
ClassMethod closeGateway() As %Integer [ SqlName = close_gateway, SqlProc ]
{
	#dim java as %External.JavaGateway;
	if '$SYSTEM.Security.Check($$$AdminExternalLanguageServerEditResourceName,$$$PermUseName) {
		$$$ThrowStatus($$$ERROR($$$OperationRequires,$$$AdminExternalLanguageServerEditResourceName_":"_$$$PermUseName))
	}
	try {
		set gateway = $system.Context.SQL().getCachedGateway($$$EXTERNALLANGUAGESERVERNAMEJAVA)
		if $isobject(gateway) {
			do gateway.disconnect()
			return gateway.Closed
		}
	} catch exception {
	}
	return 0
}

}
