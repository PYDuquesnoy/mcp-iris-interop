/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CPT.TimeScope Extends %RegisteredObject
{

Property ClientName As %String [ Internal, Private ];

Property StartTime As %Numeric [ Internal, Private ];

Method %OnNew(ClientName As %String) As %Status
{
	Set ..ClientName=ClientName
	Set ..StartTime=$ZH
	
	Quit $$$OK
}

Method %OnClose() As %Status
{
	#Dim elapsed,key
	
	Set elapsed=$ZH-..StartTime
	If $I(^||%cpttimers(..ClientName),elapsed)
	
	Quit $$$OK
}

}
