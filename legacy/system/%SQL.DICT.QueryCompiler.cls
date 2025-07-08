/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SQL.DICT.QueryCompiler [ Abstract, System = 3 ]
{

ClassMethod CompileQuery(className, queryName) As %Status
{
	try {
		set status = $$$OK
		$$$comMemberKeyGetLvar(ocFormal,className,$$$cCLASSmethod,"%OpenCursor",$$$cMETHformalspecparsed)
			#; Reset the formal list to the query declaration:
		$$$comMemberKeyGetLvar(formal,className,$$$cCLASSquery,queryName,$$$cQUERYformalspecparsed)
		set exformal = formal_ocFormal
		$$$comMemberKeySet(className,$$$cCLASSquery,queryName,$$$cQUERYformalspecparsed,exformal)
		$$$THROWONERROR(status,$$rebuildFormal^%occName(exformal,.formalspec))
		$$$comMemberKeySet(className,$$$cCLASSquery,queryName,$$$cQUERYformalspec,formalspec)
	} catch exception {
		set status = exception.AsStatus()
	}
	return status
}

}
