/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract superclass for REST implementation classes generated from OpenAPI specifications.
Class %REST.Impl Extends %RegisteredObject [ System = 4 ]
{

/// If ExposeServerExceptions is overridden as true, then details of internal errors will be exposed.
Parameter ExposeServerExceptions = 0;

/// The HTTP Status code to be sent back in the response.  The HTTP status codes are defined
/// in RFC 2068.<br>
/// <br>
/// <A HREF="http://www.faqs.org/rfcs/rfc2068.html">http://www.faqs.org/rfcs/rfc2068.html</A>
/// <br>
ClassMethod %SetStatusCode(statusCode As %String)
{
	Set %response.Status=statusCode
}

/// Set the content-type header of the response
ClassMethod %SetContentType(contentType As %String)
{
	Set %response.ContentType=contentType
}

/// Get the content-type header of the request
ClassMethod %GetContentType()
{
	Quit %request.ContentType
}

/// Sets a custom HTTP header into the reply.
/// If you set the same header twice it will append the information
/// to the first with a ',' between them.  Note that <var>name</var> is not case sensitive, however we will
/// remember the case of the header when sending this to the client.
ClassMethod %SetHeader(name As %String, value As %String)
{
	Do %response.SetHeader(name,value)
}

/// Sets a custom HTTP Cookie into the reply.
/// Takes the value of a Set-Cookie header as a String and parses out its properties.
/// These include name,value,expires,path,etc...
/// Created for use with WSGI.
/// 
ClassMethod %SetCookieFromHeader(cookie As %String)
{
	
	set list = $LISTFROMSTRING(cookie,";")
	set (name,value,expires,path,domain,samesite) = ""
	set (secure,httponly) = 0
	set listlen = $LISTLENGTH(list)
	set namePair = $LIST(list,1) //We make the assumption that the name-value pair is the first pair in the Set-Cookie 
	set name = $PIECE(namePair,"=") //Including the space after the "=" sign in the cookie
	set value = $PIECE(namePair,"=",2)
	for i=2:1:listlen {
		set prop=$LIST(list,i)
		set key = $REPLACE($ZCONVERT($PIECE(prop,"="), "L"), " ", "")
		set val = $PIECE(prop,"=",2)
		if key = "expires" {
			set expires = val
		} elseif key = "path" {
			set path = val
		} elseif key = "domain" {
			set domain = val
		} elseif key = "httponly" {
			set httponly = 1
		} elseif key = "secure" {
			set secure = 1
		} elseif key = "samesite" {
			set samesite = val
		}
	}
	set message = "Val = " _ cookie
	do ##class(%SYS.System).WriteToConsoleLog(message, 0, 2)
	Do %response.SetCookie(name,value,expires,path,domain,secure,httponly,samesite)
}

/// Helper method that sets a header if it is currently empty, if it already has a value it does nothing.
/// Returns true if the header was set and false if it did nothing.
ClassMethod %SetHeaderIfEmpty(name As %String, value As %String) As %Boolean
{
	Quit %response.SetHeaderIfEmpty(name,value)
}

/// Return the value of the <PARAMETER>name</PARAMETER> request header.
/// Note that <var>name</var> is not case sensitive
ClassMethod %GetHeader(name As %String) As %String
{
	Quit $get(%request.CgiEnvs("HTTP_"_$zcvt($tr(name,"-","_"),"U")))
}

/// Remove a header from the response. Note that <var>name</var> is not case sensitive
ClassMethod %DeleteHeader(name As %String)
{
	Do %response.DeleteHeader(name)
}

/// Report an error when processing a request.
/// The implementation class may contain an override of %ReportRESTError in
/// order to format the error response as required by the REST application.
/// The override should use the %WriteResponse method to return the error response.
ClassMethod %ReportRESTError(statusCode As %String, sc As %Status, exposeServerExceptions As %Boolean = 0)
{
	If $get(statusCode)="" Set statusCode=$parameter("%CSP.REST","HTTP400BADREQUEST")
	Set err=$system.Status.GetErrorText(sc)
	If +statusCode>=500,'exposeServerExceptions {
		Set sc=$$$ERROR($$$InternalError)
	}
	Do ..%LogError("[%REST.Impl:Error]","status "_statusCode_": "_err_", sc="_$system.Status.GetErrorText(sc))
	Do ##class(%CSP.REST).ReportHttpStatusCode(statusCode,sc)
}

/// Check that the ACCEPT request header is included in the produces list.
ClassMethod %CheckAccepts(produces As %String) As %Boolean
{
	If produces="" Quit 1
	
	Set acceptFound=0
	For i=1:1:$length(produces,",") {
		If ##class(%CSP.REST).AcceptsContentType($piece(produces,",",i)) {
			Set acceptFound=1
			Quit
		}
	}
	
	Quit acceptFound
}

/// %WriteResponse is used by the dispatch class to write the response to this request.
ClassMethod %WriteResponse(response)
{
	// Force response ot be always output
    Set %response.IgnoreRESTOutput=0
    
    // Write the response.
    If $isobject(response) {
        If response.%IsA("%DynamicAbstractObject") {
            Do response.%ToJSON()
        } Else {
            Do response.OutputToDevice()
        }
    } Else {
        Write response 
    }
}

/// Log an API Management error
ClassMethod %LogError(methodName As %String, error As %String, data As %String)
{
	$$$SysLog(1,"apimgmnt",methodName_" Error: "_error,.data)
}

/// Check that all items of an array are unique.
ClassMethod %CheckUniqueArray(array As %ListOfDataTypes) As %Boolean [ Internal ]
{
	For i=1:1:array.Count() {
		For j=i+1:1:array.Count() {
			If array.GetAt(i) = array.GetAt(j) Return 0
		}
	}

	Quit 1
}

}
