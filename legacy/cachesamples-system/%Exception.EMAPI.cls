/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ems

/// An EMAPI exception is instantiated and thrown when the Enterprise Manager remote API wishes to return an error.
Class %Exception.EMAPI Extends %Exception.AbstractException
{

ClassMethod Create(name As %String = "", data As %String = "") As %Exception.EMAPI [ Internal ]
{
	Set location=""
	Set callererrorinfo=$$$envCallerErrorInfoGet
	If callererrorinfo {
		Try {
			For i=$zutil(41)-2:-1:1 Set location=$piece($zutil(41,i),"^",2,3) Quit:location'="^"&&(location'["%Exception.EMAPI")
			If location="^" Set location=""
		} Catch {
			Set location=""
		}
	}
	If callererrorinfo=2 {
		Try {
			For i=i-1:-1:1 {
				Set info=$piece($zutil(41,i),"^",2,3)
				If info'="^",info'="" Set location=location_" "_info
			}
			If $extract(location,*)=" " Set location=$extract(location,1,*-1)
		} Catch {
		}
	}

	Set exception=..%New(name,"",location,data)
	If callererrorinfo=3 {
		Do LOG^%ETN(exception.DisplayString())
	}
	Quit exception
}

ClassMethod CreateFromFault(fault As %SOAP.Fault) As %Exception.EMAPI [ Internal ]
{
	Quit ..Create(fault.faultstring,fault.detail)
}

ClassMethod ClientError(text As %String) As %Exception.EMAPI [ Internal ]
{
	Quit ..Create($$$EMSAPICallerError,text)
}

ClassMethod EMError(text As %String) As %Exception.EMAPI [ Internal ]
{
	Quit ..Create($$$EMSAPIError,text)
}

Method OnAsStatus() As %Status [ CodeMode = expression, Private ]
{
$$$ERROR($$$EMSAPIException,..Name,..Data,,,,,,,,..Location)
}

}
