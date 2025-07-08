/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %SYS.WhitelistUtils code contains the core global access methods
/// that require privilege escalation to support the the more general
/// %CSP.WhitelistUtils library
Class %SYS.WhitelistUtils Extends %RegisteredObject
{

/// Test to see if whitelist checking is enabled for the current namespace
ClassMethod IsWhitelistEnabled() As %Boolean
{
	$$$AddAllRoleTemporary
	Set flag = 0
	Try {
		If ($Data(^ISCMethodWhitelist)=0) Set ^ISCMethodWhitelist = 0
		Set flag = ^ISCMethodWhitelist
	} Catch ex { // if that failed DB must be RO
		Set flag = 0
	}
	Quit flag
}

/// Test to see if the given method call should be allowed under the 
/// current whitelist policy 
ClassMethod IsMethodEnabled(pClass As %String, pMethod As %String) As %Boolean
{
	$$$AddAllRoleTemporary

	Set okay = 0
	Try {
		If ($Data(^ISCMethodWhitelist)=0) Set ^ISCMethodWhitelist = 0
		If (^ISCMethodWhitelist=1) {
			Set okay = ^ISCMethodWhitelist(pClass, pMethod)
		}
		Else { // whitelist checking not enabled, all calls allowed
			Set okay = 1
		}
	} Catch Ex { // Above code bombs if database RO and never been used with Zen
		Set okay=1
	}
	Quit okay
}

}
