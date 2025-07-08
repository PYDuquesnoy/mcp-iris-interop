/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.Destroyer Extends %RegisteredObject [ System = 4 ]
{

Property targetOid As %Binary;

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
	if ..targetOref'="" {
		
		d ..targetOref.%Delete(..targetOref.%Oid())
	}
	Quit $$$OK
}

Property targetOref As %Binary;

}
