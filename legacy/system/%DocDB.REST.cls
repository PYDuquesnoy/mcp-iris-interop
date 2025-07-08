/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occErrors

/// This class implements a custom response format and serves as the basis for all
/// DocDB REST APIs
Class %DocDB.REST Extends %CSP.REST
{

Parameter DOMAIN = "%DOCDB";

/// Use our special format Http500 handler
ClassMethod Http500(pE As %Exception.AbstractException) As %Status
{
	return ..ReportHttpStatusCode(..#HTTP500INTERNALSERVERERROR,pE.AsStatus())
}

/// User our special format handler for other status codes
ClassMethod ReportHttpStatusCode(httpStatus, status As %Status = {$$$OK}) As %Status
{
	set %response.Status = httpStatus
	set sc = ..StatusToJSON(status,.statusDoc)
	do ..RenderResponseBody(httpStatus,statusDoc)
	quit sc
}

/// Render the three-part Response Body which contains an status, console, and a result part
ClassMethod RenderResponseBody(httpStatus As %String = "", error As %DynamicAbstractObject = "", content As %DynamicAbstractObject = "") As %Status
{
	try {
			// Default to 200
		set %response.Status = $select(httpStatus'="":httpStatus,1:..#HTTP200OK)
		write "{"
			#; Create the part for the error
		if $isObject(error) {
			write """status"":"
			do error.%ToJSON()
			write ","
		}
		write """content"":"
		if $isObject(content) {
			do content.%ToJSON()
		} else {
			write "null"
		}
		write "}"
		set sc = $$$OK
	} catch (e) {
		set sc = e.AsStatus()
	}
	quit sc
}

/// Get the clients version of the server hash
ClassMethod GetClientServerHash() As %String [ CodeMode = expression, Internal ]
{
$Get(%request.CgiEnvs("HTTP_IF_NONE_MATCH"))
}

/// Set the clients version of the server hash
ClassMethod SetClientServerHash(pHash As %String)
{
    Do %response.SetHeader("ETag",pHash)
}

/// This private helper method server wraps the message and document and returns it to the caller
ClassMethod ServeXml(pDocName As %String, pStatus As %Status, pMsgArray As %DynamicArray, pStream As %Stream, pTimeStamp As %String = "") As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    #dim tI As %Integer
    
    #dim tHash As %String   
  /*
    Try {
                
        #; Normalize output name
        Set $Piece(pDocName,".",*)=$zcvt($Piece(pDocName,".",*),"l")
        
        #; Get the latest timestamp for hash
        Set tHash=##class(%DocDB.v1.Utils.General).TS(pDocName)
        
        #; Set the header
        Do ..SetClientServerHash(tHash)
        
        #; Result part
        Kill %objlasterror
        Set tResPart=##class(%DocDB.v1.Utils.DocumentStreamAdapter).%New(pStream,pDocName,pStatus,pTimeStamp)
        If '$IsObject(tResPart) Set tSC=%objlasterror Quit
        
        #; Render the response body
        Set tSC=..RenderResponseBody($$$OK,pMsgArray,tResPart)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    */
    Quit tSC
}

/// Sets the response's localization domain (something that %CSP.REST should do, in theory) and then invokes default super class behavior
ClassMethod Page(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 0 ]
{
    #dim %response As %CSP.Response
    Set %response.Domain = ..#DOMAIN
    Quit ##super(skipheader)
}

ClassMethod getRequestBody() As %DynamicAbstractObject
{
	try {
		if %request.ContentType = ..#CONTENTTYPEJSON {
			if ($Isobject(%request.Content)) && (%request.Content.Size > 0) {
				set requestBody = ##class(%DynamicAbstractObject).%FromJSON(%request.Content)
			} else {
				set requestBody = {}
			}
		} elseif %request.ContentType = "" {
				// Standard default is plain text. Check for content and if not null, this is an error
			if (%request.Content = "") || (($Isobject(%request.Content)) && (%request.Content.Size '> 0)) {
				set requestBody = ""
			} else {
				$$$ThrowStatus($$$ERROR($$$DocDBInvalidContentType,%request.ContentType))
			}
		} else {
			$$$ThrowStatus($$$ERROR($$$DocDBInvalidContentType,%request.ContentType))
		}
	} catch exception {
		set requestBody = ""
		throw exception
	}
	return requestBody
}

/// This method returneds a list of accessible namespaces</Description>
ClassMethod AccessibleNamespaces()
{
		// Get the list of namespaces
	set response = []
	do List^%SYS.NAMESPACE(.tList)
	set tNS=""
	for  {
		set tNS = $order(tList(tNS),1,tValue) if tNS="" quit
			// Only want namespaces which are enabled and are not remote
		if $list(tValue,1) = 1 {
			do response.%Push(tNS)
		}
	}
	return response
}

/// 	set status = exception.AsStatus()
/// 	do ..StatusToJSON(status,.statusObject)
/// All exceptions can have an inner exception
/// Status exceptions can also have NextException, forming a linked list structure
/// This can be normalized by converting the exception to a dynamic object and then we process the dynamic object
ClassMethod exceptionToHttpResponse(exception As %Exception.AbstractException) As %String
{
	set httpResponse = {}
	set errors = []
		// Each exception can form a linked list of exceptions using the forward pointer 'NextException'
	set httpStatus = ..exceptionToHttpStatus(exception)
	set httpResponse.httpStatus = $select(httpStatus'="":httpStatus,1:..#HTTP500INTERNALSERVERERROR)
	set status = exception.AsStatus()
	do ..StatusToJSON(status,.statusObject)
	set httpResponse.status = statusObject
	return httpResponse
}

/// Map an exception graph to an http status code
ClassMethod exceptionToHttpStatus(exception As %Exception.AbstractException) As %Library.DynamicAbstractObject
{
		// 
	if exception.%IsA("%Exception.StatusException") {
		set httpStatus = $case(exception.Code,
						// Resource Not Found errors
								$$$DocumentDatabaseDoesNotExist		: ..#HTTP404NOTFOUND,
								$$$ClassDoesNotExist				: ..#HTTP404NOTFOUND,
								$$$MethodDoesNotExist				: ..#HTTP404NOTFOUND,
								$$$DocDBDoesNotExist				: ..#HTTP404NOTFOUND,

								$$$KeyValueNotFoundOpen				: ..#HTTP404NOTFOUND,
								$$$LoadObjectNotFound				: ..#HTTP404NOTFOUND,
								$$$DeleteObjectNotFound				: ..#HTTP404NOTFOUND,
								$$$KeyValueNotFoundDelete			: ..#HTTP404NOTFOUND,

								$$$KeyNotFound						: ..#HTTP404NOTFOUND,
								$$$NotAnInstanceError				: ..#HTTP404NOTFOUND,
								$$$QueryDoesNotExist				: ..#HTTP404NOTFOUND,
										

						// Validation (e.g. bad request) issues
								$$$DocumentDatabaseKeyNotExist		: ..#HTTP400BADREQUEST,
								$$$InvalidArgument					: ..#HTTP400BADREQUEST,
								$$$DatatypeValidationFailed			: ..#HTTP400BADREQUEST,
								$$$DTValueList						: ..#HTTP400BADREQUEST,
								$$$PropertyRequired					: ..#HTTP400BADREQUEST,
								$$$DocumentDatabasePropertyNotValid	: ..#HTTP400BADREQUEST,
								$$$PropertyDoesNotExist				: ..#HTTP400BADREQUEST,

						// Constraint failures
								$$$DocumentDatabaseAlreadyExists	: ..#HTTP409CONFLICT,
								$$$DocDBAlreadyExists				: ..#HTTP409CONFLICT,
								$$$IDKeyNotUnique					: ..#HTTP400BADREQUEST,
								$$$KeyNotUnique						: ..#HTTP400BADREQUEST,

						// Authorization
						
								$$$OperationRequires				: ..#HTTP403FORBIDDEN,
								$$$OperationRequiresOneOfTwo		: ..#HTTP403FORBIDDEN,
						// Permissions
								$$$DocDBRestricted					: ..#HTTP403FORBIDDEN,
						// Other misc. codes
								$$$ServiceDisabled					: ..#HTTP403FORBIDDEN,
								$$$DocDBDisabled					: ..#HTTP403FORBIDDEN,
								$$$ServiceLoginsDisabled			: "503 Service Unavailable",
								$$$ServiceSystemStartupInProgress	: "503 Service Unavailable",
								$$$ServiceSystemShutdown			: "503 Service Unavailable",
								$$$DocDBInvalidContentType			: ..#HTTP406NOTACCEPTABLE,

						// No mapping ...

																: ""
				)
			// Depth first - the strongest affiliation is with InnerException
		if (httpStatus = "") && ($isObject(exception.InnerException)) {
			set httpStatus = ..exceptionToHttpStatus(exception.InnerException)
		}
			// Only StatusException has the forward pointer to another status - coincidental exceptions
		if (httpStatus = "") && ($isObject(exception.NextException)) {
			set httpStatus = ..exceptionToHttpStatus(exception.NextException)
		}

	} elseif exception.%IsA("%Exception.SQL") {
		set httpStatus = ..SQLCODEToHttpStatus(exception.Code)
		if (httpStatus = "") && ($isObject(exception.InnerException)) {
			set httpStatus = ..exceptionToHttpStatus(exception.InnerException)
		}

	} elseif exception.%IsA("%Exception.SystemException") {
		set httpStatus = $case(exception.Name,
										"<NAMESPACE>"			: ..#HTTP404NOTFOUND,
										"<PROTECT>"				: ..#HTTP403FORBIDDEN,
																: ""
				)
		if (httpStatus = "") && ($isObject(exception.InnerException)) {
			set httpStatus = ..exceptionToHttpStatus(exception.InnerException)
		}
	} else {
		set httpStatus = ""
	}
	return httpStatus
}

ClassMethod SQLCODEToHttpStatus(SQLCODE As %Integer) As %String
{
	if SQLCODE = 0 {
		return ..#HTTP200OK
	} elseif SQLCODE = 100 {
		return ..#HTTP204NOCONTENT
	} elseif $find("|-402|-459|","|"_SQLCODE_"|") {
		return ..#HTTP401UNAUTHORIZED
	} elseif  $find("|-98|-99|-112|-417|","|"_SQLCODE_"|") {
		return ..#HTTP403FORBIDDEN
	} elseif $find("|-110|-114|-119|-120|-121|-122|-123|-124|-125|-127|-139|-361|","|"_SQLCODE_"|") {
		return ..#HTTP409CONFLICT
	} elseif $find("|-350|-375|-400|-401|-405|-406|-407|-408|-409|-410|-412|-413|-415|-425|-426|-430|-451|-452|-453|-454|-460|-461|-462|-478|-499|","|"_SQLCODE_"|") {
		return ..#HTTP500INTERNALSERVERERROR
	} elseif $find("|-358|-364|-365|","|"_SQLCODE_"|") {
		return ..#HTTP409CONFLICT
	} elseif SQLCODE < 0 {
		return ..#HTTP400BADREQUEST
	}
	return ""
}

}
