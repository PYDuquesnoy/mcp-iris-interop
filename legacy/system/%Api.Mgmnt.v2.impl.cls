/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The API Management API manages the APIs which are defined using a RESTSpec.
/// In addition limited supported for legacy REST applications based on direct subclassing of %CSP.REST is included.<br/>
/// Business logic class defined by OpenAPI in %Api.Mgmnt.v2.spec<br/>
/// Updated Feb 13, 2025 16:17:54
Class %Api.Mgmnt.v2.impl Extends %REST.Impl [ System = 4 ]
{

/// If ExposeServerExceptions is true, then details of internal errors will be exposed.
Parameter ExposeServerExceptions = 1;

/// This request returns a list of all REST applications in all namespaces as a JSON array.
ClassMethod GetAllRESTApps() As %DynamicObject
{
	// Run in %SYS namespace if possible.
	New $namespace
	If '..%AdjustNamespace("%SYS",0) Quit ""

	// Get all REST application	
	Set sc=##class(%REST.API).GetAllRESTApps(.appList)
	
	// Return error or array of application descriptions
	If $$$ISOK(sc) Set sc=##class(%REST.API).ListToArray(appList,.response)
	If $$$ISERR(sc) {
		Do ..%ReportRESTError($parameter("%CSP.REST","HTTP500INTERNALSERVERERROR"),sc,..#ExposeServerExceptions)
		Set response=""
	}
	
	Quit response
}

/// This request returns a list of all REST applications in the specified namespace as a JSON array.<br/>
/// The method arguments hold values for:<br/>
///     namespace, The IRIS namespace in which to perform the requested operation.<br/>
ClassMethod GetRESTApps(namespace As %String) As %DynamicObject
{
	// Run in appropriate namespace.
	New $namespace
	If '..%AdjustNamespace(namespace,0) Quit ""

	// Get all REST application	
	Set sc=##class(%REST.API).GetRESTApps(namespace,.appList)
	
	// Return error or array of application descriptions
	If $$$ISOK(sc) Set sc=##class(%REST.API).ListToArray(appList,.response)
	If $$$ISERR(sc) {
		Do ..%ReportRESTError($parameter("%CSP.REST","HTTP500INTERNALSERVERERROR"),sc,..#ExposeServerExceptions)
		Set response=""
	}
	
	Quit response
}

/// This request returns the OpenAPI 2.0 swagger description of this application as a JSON object.<br/>
/// The method arguments hold values for:<br/>
///     namespace, The IRIS namespace in which to perform the requested operation.<br/>
///     applicationName, The name of the REST application which is the package name for the classes defining and implementing the application.<br/>
ClassMethod GetApplication(namespace As %String, applicationName As %String) As %DynamicObject
{
	// Run in appropriate namespace.
	New $namespace
	Set namespace=$zcvt(namespace,"U")
	If '..%AdjustNamespace(namespace,0) Quit ""
	
	Set sc=$$$OK
	If namespace="%SYS",namespace'=$namespace,$extract(applicationName,1)'="%" {
		Set sc=$$$ERROR($$$RESTNoApplication,applicationName)
	}
	If $EXTRACT(applicationName,1,19)="%Api.InteropEditors" {
		#; Hide the spec for the Interop Editors API
		Set sc=$$$ERROR($$$RESTNoApplication,applicationName)
	}
	
	// Create the OpenAPI 2.0 swagger
	If $$$ISOK(sc) {
		Set sc=##class(%REST.API).GetApplication(applicationName,.response)
	}
	If $$$ISOK(sc) {
    	Do ..%SetContentType("application/json")
	}

	// Set statusCode and report errors.
	If $$$ISOK(sc) {
		Do ..%SetStatusCode($parameter("%CSP.REST","HTTP200OK"))
	} Else {
		If $$$GETERRORCODE(sc)=$$$ERRORCODE($$$RESTNoApplication) {
			Set statusCode=$parameter("%CSP.REST","HTTP404NOTFOUND")
		} Else {
			Set statusCode=$parameter("%CSP.REST","HTTP400BADREQUEST")
		}
		Do ..%ReportRESTError(statusCode,sc)
		Set response=""
	}
	
	// Return the body
	Quit response
}

/// This request replaces an existing REST application or creates a new REST application.
/// The request body may specify an OpenAPI 2.0 swagger description which is used to replace/create the application.
/// If the request body is empty, then the RESTSpec and dispatch classes are replaced with any empty application.<br/>
/// The method arguments hold values for:<br/>
///     namespace, The IRIS namespace in which to perform the requested operation.<br/>
///     applicationName, The name of the REST application which is the package name for the classes defining and implementing the application.<br/>
///     swagger, The body is a JSON object containing the swagger definition for this application.<br/>
///     strict, If strict is false, then only the swagger properties which are needed for code generation are checked.  If strict is true, then all swagger properties are checked.  The value of the strict parameter defaults to true.<br/>
ClassMethod CreateApplication(namespace As %String, applicationName As %String, swagger As %DynamicObject, strict As %Boolean) As %DynamicObject
{
	// Run in appropriate namespace.
	New $namespace
	If '..%AdjustNamespace(namespace,1) Quit ""
	
	// Handle strict parameter
	If $data(strict) {
		Set features("strict")=strict
	}
	
	// Create the application
	Set sc=##class(%REST.API).CreateApplication(applicationName,$get(swagger),.features,.newApplication,.internalError)

	// Create response
	If $$$ISOK(sc) {
		If newApplication {
			Set statusCode=$parameter("%CSP.REST","HTTP201CREATED")
			Set msg="New application "_applicationName_" created"
		} Else {
			Set statusCode=$parameter("%CSP.REST","HTTP200OK")
			Set msg="Application "_applicationName_" updated"
		}
		Do ..%SetStatusCode(statusCode)
		Set response={"msg":(msg)}

	} Else {
		If internalError {
			Set statusCode=$parameter("%CSP.REST","HTTP500INTERNALSERVERERROR")
		} ElseIf ($$$GETERRORCODE(sc)=$$$ERRORCODE($$$RESTBadName)) || ##class(%Dictionary.ClassDefinition).%Exists(applicationName_".spec") {
			Set statusCode=$parameter("%CSP.REST","HTTP400BADREQUEST")
		} Else {
			Set statusCode=$parameter("%CSP.REST","HTTP404NOTFOUND")
		}
		Do ..%ReportRESTError(statusCode,sc,..#ExposeServerExceptions)
		Set response=""
	}

	Quit response
}

/// This request deletes an application by deleting the specification class and the dispatch class that represent the application.  The implementation class is not deleted.<br/>
/// The method arguments hold values for:<br/>
///     namespace, The IRIS namespace in which to perform the requested operation.<br/>
///     applicationName, The name of the REST application which is the package name for the classes defining and implementing the application.<br/>
ClassMethod DeleteApplication(namespace As %String, applicationName As %String) As %DynamicObject
{
	// Run in appropriate namespace.
	New $namespace
	If '..%AdjustNamespace(namespace,1) Quit ""
	
	// Delete the application.
	Do ##class(%REST.API).DeleteApplication(applicationName)

	// Always return success.
	Do ..%SetStatusCode($parameter("%CSP.REST","HTTP200OK"))
	Set msg="Application "_applicationName_" deleted"
	Quit {"msg":(msg)}
}

/// This request returns a list of all %CSP.REST based REST applications in all namespaces as a JSON array.
ClassMethod GetAllWebRESTApps() As %DynamicObject
{
	// Run in %SYS namespace if possible.
	New $namespace
	If '..%AdjustNamespace("%SYS",0) Quit ""

	// Get all REST application	
	Set sc=##class(%REST.API).GetAllWebRESTApps(.appList)
	
	// Return error or array of application descriptions
	If $$$ISOK(sc) Set sc=##class(%REST.API).ListToArray(appList,.response)
	If $$$ISERR(sc) {
		Do ..%ReportRESTError($parameter("%CSP.REST","HTTP500INTERNALSERVERERROR"),sc,..#ExposeServerExceptions)
		Set response=""
	}
	
	Quit response
}

/// This request returns a list of all %CSP.REST based REST applications in the specified namespace as a JSON array.<br/>
/// The method arguments hold values for:<br/>
///     namespace, The IRIS namespace in which to perform the requested operation.<br/>
ClassMethod GetWebRESTApps(namespace As %String) As %DynamicObject
{
	// Run in appropriate namespace.
	New $namespace
	If '..%AdjustNamespace(namespace,0) Quit ""

	// Get all REST application	
	Set sc=##class(%REST.API).GetWebRESTApps(namespace,.appList)
	
	// Return error or array of application descriptions
	If $$$ISOK(sc) Set sc=##class(%REST.API).ListToArray(appList,.response)
	If $$$ISERR(sc) {
		Do ..%ReportRESTError($parameter("%CSP.REST","HTTP500INTERNALSERVERERROR"),sc,..#ExposeServerExceptions)
		Set response=""
	}
	
	Quit response
}

/// This request returns the OpenAPI 2.0 swagger description based on the UrlMap of %CSP.REST subclass for this REST application.  The namespace parameter defaults to the web application's namespace.<br/>
/// The method arguments hold values for:<br/>
///     namespace, The IRIS namespace in which to perform the requested operation.<br/>
///     webApplication, The name of the web application which to which this %CSP.REST based application is deployed.<br/>
ClassMethod GetWebRESTApplication(namespace As %String, webApplication As %String) As %DynamicObject
{
	// Run in appropriate namespace.
	New $namespace
	Set namespace=$zcvt(namespace,"U")
	If '..%AdjustNamespace(namespace,0) Quit ""
	
	// Create the swagger
	If $extract(webApplication)'="/" Set webApplication="/"_webApplication
	Set sc=##class(%REST.API).GetWebRESTApplication(namespace,webApplication,.swagger)
	If webApplication="/api/interop-editors" {
		#; Don't generate a spec for the Interop Editors API
		Set sc=$$$ERROR($$$RESTNoWebApp,webApplication),swagger=""
	}

	// Set statusCode and report errors.
	If $$$ISOK(sc) {
		Do ..%SetStatusCode($parameter("%CSP.REST","HTTP200OK"))
	} Else {
		If swagger="" {
			Set statusCode=$parameter("%CSP.REST","HTTP404NOTFOUND")
		} Else {
			Set statusCode=$parameter("%CSP.REST","HTTP400BADREQUEST")
		}
		Do ..%ReportRESTError(statusCode,sc)
		Set swagger=""
	}
	
	// Return the body
	Quit swagger
}

/// Override %ReportRESTError in order to format error responses as we require.
ClassMethod %ReportRESTError(statusCode As %String, sc As %Status, exposeServerExceptions As %Boolean = 0) [ Internal ]
{
	// Set Http status code for response
	Do ..%SetStatusCode(statusCode)
	
	// Log error and write response body for error.
	Set err=$system.Status.GetErrorText(sc)
	Do ..%LogError("[%Api.Mgmnt.v2.impl:Error]","statusCode "_statusCode_": "_err)
	// Hide internal errors if requested.
	If +statusCode>=500,'exposeServerExceptions {
		Set err="Internal Error"
	}
	Do ..%WriteResponse({"msg":($ZCONVERT(err,"O","HTML"))})
}

/// Change to run in specified namespace.
ClassMethod %AdjustNamespace(namespace As %String, updateRequired As %Boolean) As %Boolean [ Internal ]
{
    // If namespace is %SYS and we do not have %DB_IRISSYS:R resource, then run in a user namespace.
    // The default user namespace is USER which can be overridden by ^%SYS("REST","UserNamespace")
    Set namespace=$zcvt(namespace,"U")
    If 'updateRequired,namespace="%SYS",'$System.Security.Check("%DB_IRISSYS","READ") {
		Set namespace=$get(^%SYS("REST","UserNamespace"))
		If namespace="" Set namespace="USER"
    }
    
    // Make sure that we are running in an accessible namespace.
    Try {
       	// Need to change to appropriate namespace here
       	If $namespace'=namespace Set $namespace=namespace
       	Set sc=$$$OK
    } Catch ex {
        Do ##class(%REST.Utils).LogError("[%Api.Mgmnt.v2,impl:%AdjustNamespace]","Unable to change namespace. namespace="_namespace_", $namespace="_$namespace_", $roles="_$roles)
        Set sc=$$$ERROR($$$RESTBadNamespace,namespace)
        Do ..%ReportRESTError($parameter("%CSP.REST","HTTP403FORBIDDEN"),sc)
    }

	Quit $$$ISOK(sc)
}

}
