/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements various utility functions for HTTP. 
Class %Net.Http [ Abstract ]
{

/// <p>
/// GetJson() is a utility function that accepts a URL and an optional request object. 
/// If a request object is supplied then it is expected to be either JSON or an oref. 
/// The properties of the request object will be used to populate the HttpRequest before submitting the 
/// request. The response is expected to be encoded as JSON. 
/// </p>
/// <p>
/// If <var>request</var> is passed then it must either be valid JSON or an oref of type <class>%Library.DynamicAbstractObject</class>. The properties contained in 
/// <var>request</var> must be named the same as a property in <class>%Net.HttpRequest</class>. The exception is the <var>url</var> property. 
/// Any other property contained in <var>request</var> that is not named the same as a property in <class>%Net.HttpRequest</class> will trigger an exception: 
/// <p>
/// If <var>requestURL</var> is not passed or is passed as null then the <var>request</var>.<var>url</var> property is used as the URL.
/// </p>
/// <p>
/// This method is projected as an SQL function and can be invoked in SQL as %Net.GetJson(). 
/// </p>
/// This method returns a dynamic object that includes the following properties:
/// <ul>
/// <li>httpStatus - HTTP return code.</li>
/// <li>message - HTTP status line. This is the first line of the response and signals
/// if the request was successful or if there was a problem.</li>
/// <li>content - Dynamic object returned by the actual REST call.</li>
/// </ul>
ClassMethod GetJson(requestURL As %RawString = "", request As %String(MAXLEN="") = "") As %DynamicAbstractObject [ SqlName = GetJson, SqlProc ]
{
#dim exception as %Exception.AbstractException
#dim method as %String
#dim requestComponent as %String // array of url pieces, returned by %Net.URLParser.Parse()
#dim requestObject as %Library.DynamicAbstractObject
#dim response as %Library.DynamicAbstractObject
#dim scheme as %String
#dim status as %Status
	try {
		if request '= "" {
			if '$Isobject(request) {
				set requestObject = ##class(%DynamicAbstractObject).%FromJSON(request)
				if '$Isobject(requestObject) {
					set %sqlcontext.%SQLCODE = -400
					set %sqlcontext.%Message = "GetJson() request object is not valid"
					throw ##class(%Exception.SQL).CreateFromSQLCODE(%sqlcontext.%SQLCODE,%sqlcontext.%Message)
				}
			} else {
					// We don't want local changes to the request object to be visible to the caller. 
				set requestObject = request // unfortunately, %Clone() was removed....so  request.%Clone() is not used and local changes will be visible
			}
		} else {
			set requestObject = {}
		}
		if (requestURL '= "") {
			do ##class(%Net.URLParser).Parse(requestURL,.requestComponent)
		} elseif requestObject.%Get("url") '= "" {
			do ##class(%Net.URLParser).Parse(requestObject.%Get("url"),.requestComponent)
			do requestObject.%Remove("url")
		}
		set scheme = $Get(requestComponent("scheme"))
		if $Extract(scheme,1,4) = "http" {
				// Thanks to DMC
			set httprequest = ##class(%Net.HttpRequest).%New()
			set httprequest.Server = requestComponent("host")
			if $Data(requestComponent("port")) {
				set httprequest.Port = requestComponent("port")
			}
			do httprequest.SetHeader("Accept","application/json")
			do httprequest.SetHeader("ContentType","application/json")
			if $Data(requestComponent("username")) {
				set httprequest.Username = requestComponent("username")
			} else {
				set httprequest.Username = requestObject.Username
			}
			if $Data(requestComponent("password")) {
				set httprequest.Password = requestComponent("password")
			} else {
				set httprequest.Password = requestObject.Password
			}
			if (scheme = "https") {
				set httprequest.Https = 1
				set httprequest.SSLConfiguration = requestObject.SSLConfiguration
			}
			if $isObject(requestObject.body) {
				set body = ##class(%Stream.GlobalCharacter).%New()
				do requestObject.body.%ToJSON(body)
				set httprequest.EntityBody = body
			}
			set method = $$$ucase(requestObject.httpMethod)
			if (method = "") || (method = "GET") {
				set status = httprequest.Get($Get(requestComponent("path"))_$Select($Get(requestComponent("query"))="":"",1:"?"_requestComponent("query"))_$Select($Get(requestComponent("params"))="":"",1:";"_requestComponent("params")))
			} elseif method = "POST" {
				set status = httprequest.Post($Get(requestComponent("path"))_$Select($Get(requestComponent("query"))="":"",1:"?"_requestComponent("query"))_$Select($Get(requestComponent("params"))="":"",1:";"_requestComponent("params")))
			} elseif method = "PUT" {
				set status = httprequest.Put($Get(requestComponent("path"))_$Select($Get(requestComponent("query"))="":"",1:"?"_requestComponent("query"))_$Select($Get(requestComponent("params"))="":"",1:";"_requestComponent("params")))
			} elseif method = "DELETE" {
				set status = httprequest.Send("DELETE",$Get(requestComponent("path"))_$Select($Get(requestComponent("query"))="":"",1:"?"_requestComponent("query"))_$Select($Get(requestComponent("params"))="":"",1:";"_requestComponent("params")))
			}
			if $$$ISERR(status) {
				$$$ThrowStatus(status)
			}
				// A non-2xx code doesn't indicate null response. Build it up.
			set response = {"httpStatus":(httprequest.HttpResponse.StatusCode),"message":(httprequest.HttpResponse.StatusLine)}
			try {
				set response.content = ##class(%DynamicAbstractObject).%FromJSON(httprequest.HttpResponse.Data)
			} catch jsonParserError {
				// we have to do this because the JSON parser can't parse an empty JSON string
				set response.content = ""
			}
		} elseif scheme = "file" {
				// file - is this always local?
			set response = $$$NULLOREF
		} else {
				// unsupported scheme or no default scheme defined (this is presently the case)
			set response = $$$NULLOREF
		}
	} catch exception {
		set response = $$$NULLOREF
		throw exception
	}
	return response
}

ClassMethod %DispatchClassMethod(class As %String, method As %String, args...) As %ObjectHandle
{
	if $$$ucase(method) = "GETJSON" {
		return ..GetJson(args...)
	}
	do $system.Process.ThrowError(148)
}

}
