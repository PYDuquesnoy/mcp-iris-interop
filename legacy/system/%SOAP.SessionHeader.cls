/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SOAP session header.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.SessionHeader Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLNAME = "CSPCHD";

Parameter XMLTYPE = "CSPCHD";

Parameter NAMESPACE = "http://www.intersystems.com/SOAPheaders";

Property SessionCookie As %String(XMLNAME = "id") [ Required ];

Method ProcessService(service As %SOAP.WebService) As %Status
{
	Do service.HeadersIn.RemoveAt("CSPCHD")
	Do service.SessionCookieSetInternal(..SessionCookie)
	Quit $$$OK
}

Method ProcessClient(client As %SOAP.WebClient) As %Status
{
	Do client.HeadersIn.RemoveAt("CSPCHD")
	Do client.SessionCookieSetInternal(..SessionCookie)
	Quit $$$OK
}

}
