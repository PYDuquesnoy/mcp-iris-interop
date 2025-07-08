/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.Encrypt Extends %CSP.Page [ System = 4 ]
{

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
 Quit $system.Security.Check("%Development","USE")
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	&html<<HTML>
<HEAD></HEAD><BODY>>
	// Find out whether we're turning encryption on or off
	set status=%request.Get("status",1)
	if status {
		set ^%SYS("CSP","NoEncrypt")=1
	}
	else {
		kill ^%SYS("CSP","NoEncrypt")
	}
	w +$get(^%SYS("CSP","NoEncrypt"))
 &html<
</BODY>
</HTML>>
	Quit $$$OK
}

}
