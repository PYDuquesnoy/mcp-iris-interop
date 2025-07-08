/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An SQL exception is instantiated using SQLCODE and %msg. It provides a convenient
/// mechanism for reporting SQLCODE errors using exceptions. The resulting exception
/// can be processed as a %Status value using the AsStatus() method or the original
/// SQLCODE value along with the %msg value can be retrieved as Code and Data respectively.
/// Authors of catch tException { } can test for an SQL exception using
/// tException.%IsA("%Exception.SQL") to perform error handling and reporting
/// specific to SQL.
Class %Exception.SQL Extends %Exception.AbstractException
{

/// Instantiate an exception from SQLCODE and %msg.
ClassMethod CreateFromSQLCODE(pSQLCODE As %Integer, pMessage As %String(MAXLEN="")) As %Exception.SQL
{
	#dim tException As %Exception.SQL
	try {
		Set callererrorinfo=$$$envCallerErrorInfoGet
		Set caller=""
		If callererrorinfo {
			for i=$zutil(41)-2:-1:1 set caller=$piece($zutil(41,i),"^",2,3) quit:caller'="^"&&(caller'["%SYSTEM.Status")&&(caller'["^%apiOBJ")
			if caller="^" set caller=""
			if callererrorinfo=2 {
				for i=i-1:-1:1 {
					set info=$piece($zutil(41,i),"^",2,3)
					if info'="^",info'="" set caller=caller_" "_info
				}
				if $extract(caller,*)=" " set caller=$extract(caller,1,*-1)
			}
		}
	} catch {
		set caller=""
	}
	if pSQLCODE { set tException = ..%New(pSQLCODE,pSQLCODE,caller,pMessage) }
	else { set tException = $$$NULLOREF }
	Quit tException
}

/// Override this method to provide a custom conversion of an exception to a status
/// SQL exceptions are converted to %Status values using $$$SQLCode as the status
/// message id.
Method OnAsStatus() As %Status [ CodeMode = expression, Private ]
{
$$$ERROR($$$SQLCode,..Code,..Data,,,,,,,,..Location)
}

/// Override this method to provide a custom conversion of an exception to an SQLCODE value
Method OnAsSQLCODE() As %Integer [ CodeMode = expression, Private ]
{
..Code
}

/// This returns a string that represents the SQL %msg string. Users should feel free
/// to modify the format and content in subclasses
Method SQLMessageString(pLevel As %Integer = 0) As %String
{
	Quit ..Data
}

}
