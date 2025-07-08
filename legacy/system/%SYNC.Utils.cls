/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYNC.Utils Extends %RegisteredObject
{

ClassMethod setSyncGUID(GUID As %String = "") As %Status
{
	if GUID="" {
		quit $$$ERROR($$$GeneralError,"GUID cannot be empty ")
	}
	s ^SYS("syncGUID")=GUID
	quit $$$OK
}

ClassMethod getSyncGUID() As %String
{
	
		if $g(^SYS("syncGUID"))'="" quit ^SYS("syncGUID")
		if $SYSTEM.Mirror.IsNamespaceMirrored($namespace) quit $SYSTEM.Mirror.GetInfo(8)
		quit ##class(%SYS.System).InstanceGUID()
}

}
