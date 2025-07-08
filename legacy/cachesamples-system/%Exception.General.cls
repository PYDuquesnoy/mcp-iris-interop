/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Simple exception class that can be throw in user code.
/// You can throw this with code similar to:
/// <EXAMPLE>
/// Throw ##class(%Exception.General).%New(name,numericCode,location,data)
/// </EXAMPLE>
/// The <var>name</var> is a string name for the exception, the <var>numericCode</var> is a numeric error code.
/// If the <var>location</var> field is blank and $$$envCallerErrorInfo is defined
/// then the system will attempt to fill in this location where the exception was thrown from automatically.
/// You can pass additional exception data in the <var>data</var> argument.
Class %Exception.General Extends AbstractException
{

Method %OnNew(pName As %String = "", pCode As %String = "", pLocation As %String = "", pData As %String = "", pInnerException As %Exception.AbstractException = {$$$NULLOREF}) As %Status [ Private ]
{
	Set pLocationerrorinfo=$$$envCallerErrorInfoGet
	If $get(pLocation)="",pLocationerrorinfo {
		For i=$zutil(41)-2:-1:1 Set pLocation=$piece($zutil(41,i),"^",2,3) Quit:pLocation'="^"&&(pLocation'["%Exception.General.")
		If pLocation="^" Set pLocation=""
		If pLocationerrorinfo=2 {
			For i=i-1:-1:1 {
				Set info=$piece($zutil(41,i),"^",2,3)
				If info'="^",info'="" Set pLocation=pLocation_" "_info
			}
			If $extract(pLocation,*)=" " Set pLocation=$extract(pLocation,1,*-1)
		}
	}

	Set i%Name=pName,i%Code=pCode,i%Location=pLocation,i%Data=pData,i%InnerException=pInnerException
	If pLocationerrorinfo=3 {
		Do LOG^%ETN(..DisplayString())
	}
	Quit $$$OK
}

Method OnAsStatus() As %Status [ CodeMode = expression, Private ]
{
$$$ERROR($$$GeneralException,i%Name,i%Code,i%Data,,,,,,,i%Location)
}

}
