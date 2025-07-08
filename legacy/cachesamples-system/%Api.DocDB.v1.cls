/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %Api.DocDB.v1 provides version 1 APIs for DocDB
/// 
/// 	<p>
/// 		<h4>Http/Rest Calls</h4><br>
/// 		<table border="1" title="Http/Rest Calls">
/// 			<tr>
/// 				<th>API</th><th>URI</th><th>HTTP Method</th><th>Content</th><th>Description</th><th>Role/Permission</th>
/// 			</tr>
/// 			<tr>
/// 					<td>GetAllDatabases</td>
/// 					<td>/<var>namespaceName</var></td>
/// 					<td>GET</td>
/// 					<td>none</td>
/// 					<td>Return the name of each Database defined in the namespaceName Namespace. </td>
/// 					<td>%DocDB_Admin/USE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>DropAllDatabases</td>
/// 					<td>/<var>namespaceName</var></td>
/// 					<td>DELETE</td>
/// 					<td>none</td>
/// 					<td>Delete all of the databases defined in the namespaceName namespace. </td>
/// 					<td>%DocDB_Admin/USE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>CreateDatabase</td>
/// 					<td>/<var>namespaceName</var>/db/<var>databaseName</var>  ?type= <var>documentType</var>& resource= <var>databaseResource</var> </td>
/// 					<td>POST</td>
/// 					<td>none</td>
/// 					<td>Create a new Database in the <var>namespaceName</var> namespace. </td>
/// 					<td>%DocDB_Admin/USE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>DropDatabase</td>
/// 					<td>/<var>namespaceName</var>/db/ <var>databaseName</var></td>
/// 					<td>DELETE</td>
/// 					<td>none</td>
/// 					<td>Drop the databaseName database from namespaceName namespace. </td>
/// 					<td>%DocDB_Admin/USE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>GetDatabase</td>
/// 					<td> /<var>namespaceName</var>/db/ <var>databaseName</var></td>
/// 					<td>GET</td>
/// 					<td>none</td>
/// 					<td>Return the <var>databaseName</var> database definition. This function is also sufficient for DatabaseExists. </td>
/// 					<td>defined resource/USE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>CreateProperty</td>
/// 					<td>/<var>namespaceName</var>/ prop/<var>databaseName</var>/ <var>propertyName</var>?type= <var>propertyType</var>& path= <var>propertyPath</var>& unique=<var>propertyUnique</var> </td>
/// 					<td>POST</td>
/// 					<td>none </td>
/// 					<td>Create a new property or replace an existing property in databaseName. The property is defined by URL parameters and not Content. All parameters are optional. </td>
/// 					<td>%DocDB_Admin/USE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>DropProperty</td>
/// 					<td>/<var>namespaceName</var>/prop/ <var>databaseName</var> /<var>propertyName</var> </td>
/// 					<td>DELETE</td>
/// 					<td>none</td>
/// 					<td>Remove a property definition from databaseName. </td>
/// 					<td>%DocDB_Admin/USE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>GetProperty</td>
/// 					<td>/<var>namespaceName</var>/prop/ <var>databaseName</var>/ <var>propertyName</var></td>
/// 					<td>GET</td>
/// 					<td>none</td>
/// 					<td>Return the property definition from databaseName.</td>
/// 					<td>defined resource/USE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>SaveDocument</td>
/// 					<td>/<var>namespaceName</var>/doc/<var>databaseName</var>/</td>
/// 					<td>POST</td>
/// 					<td>JSON object or array</td>
/// 					<td>Insert a new document into databaseName.</td>
/// 					<td>defined resource/WRITE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>SaveDocument</td>
/// 					<td>/<var>namespaceName</var>/doc/ <var>databaseName</var>/<var>id</var></td>
/// 					<td>PUT</td>
/// 					<td>JSON object or array</td>
/// 					<td>Replace an existing document in databaseName.</td>
/// 					<td>defined resource/WRITE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>SaveDocumentByKey</td>
/// 					<td>/<var>namespaceName</var>/doc/ <var>databaseName</var>/<var>keyPropertyName</var>/<var>keyValue</var></td>
/// 					<td>PUT</td>
/// 					<td>JSON object or array</td>
/// 					<td>Replace an existing document in <var>databaseName</var>. </td>
/// 					<td>defined resource/WRITE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>DeleteDocument</td>
/// 					<td>/<var>namespaceName</var>/doc/ <var>databaseName</var>/<var>id</var></td>
/// 					<td>DELETE</td>
/// 					<td>none</td>
/// 					<td>Delete the document from the database.</td>
/// 					<td>defined resource/WRITE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>DeleteDocumentByKey</td>
/// 					<td>/<var>namespaceName</var>/doc/ <var>databaseName</var>/<var>keyPropertyName</var>/<var>keyValue</var></td>
/// 					<td>DELETE</td>
/// 					<td>none</td>
/// 					<td>Delete the document from the database.</td>
/// 					<td>defined resource/WRITE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>FindDocuments</td>
/// 					<td>/<var>namespaceName</var>/ find/<var>databaseName</var>? wrapped=true|false</td>
/// 					<td>POST</td>
/// 					<td>JSON object</td>
/// 					<td>Find all documents in databaseName matching the query specification.</td>
/// 					<td>defined resource/USE</td>
/// 			</tr>
/// 			<tr>
/// 					<td>GetDocument</td>
/// 					<td>/<var>namespaceName</var>/doc/ <var>databaseName</var>/<var>id</var>? wrapped=true|false</td>
/// 					<td>GET</td>
/// 					<td>none</td>
/// 					<td>Return the requested document.</td>
/// 					<td>defined resource/READ</td>
/// 			</tr>
/// 			<tr>
/// 					<td>GetDocumentByKey</td>
/// 					<td>/<var>namespaceName</var>/doc/ <var>databaseName</var> /<var>keyPropertyName </var>/<var>keyValue </var></td>
/// 					<td>POST</td>
/// 					<td>None</td>
/// 					<td>Retrieve a document by a property defined as a unique key.</td>
/// 					<td>defined resource/READ</td>
/// 			</tr>
/// 		</table>
/// 	</p>
Class %Api.DocDB.v1 Extends %DocDB.REST
{

/// Specifies the default character set for the page.  This can be overriden using the
/// &lt;CSP:CONTENT CHARSET=&gt; tag, or by setting the <b>%response</b>.CharSet property
/// in the <method>OnPreHTTP</method> method.  If this parameter is not specified, then
/// for the default charset is utf-8.
Parameter CHARSET = "utf-8";

/// Specifies if input %request.Content or %request.MimeData values are converted from their
/// original character set on input. By default (0) we do not modify these and receive them
/// as a binary stream which may need to be converted manually later. If 1 then if there
/// is a 'charset' value in the request Content-Type or mime section we will convert from this
/// charset when the input data is text based. For either json or xml data with no charset
/// this will convert from utf-8 or honor the BOM if one is present.
Parameter CONVERTINPUTSTREAM = 1;

/// Specifies the default content type for the page.  This can be overriden using the
/// &lt;CSP:CONTENT TYPE=&gt; tag, or by setting the <b>%response</b>.ContentType property
/// in the <method>OnPreHTTP</method> method.  The default value if this parameter is
/// not set is text/html.
Parameter CONTENTTYPE = "application/json";

/// This parameter influences the CORS support. The default is an empty string meaning 'not specified'.
/// If set to true (1) then CORS processing is ON. If set to false (0) then CORS processing is OFF.
/// If left unset "" then the decision to process CORS is delegated to the setting on the URL map route.
Parameter HandleCorsRequest = 1;

/// This parameter controls the CSP session support. By default the CSP session will be
/// ended after each request in accordance with the spirit of REST. However this CAN be
/// overridden by the user. To use a session, it's necessary to manage the CSPSESSION cookie.
/// Browsers do this automatically but command line tools such as CURL require the setting of
/// options.<p>
/// Note that if you choose to use a session then this will use a CSP license until the session
/// is ended or expires and the grace period has been satisfied. If you use the default of no
/// session then this will be the same behavior as SOAP requests of holding a license for ten
/// seconds.
Parameter UseSession As Integer = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/"                                        Method="POST"   Call="httpPostServer"/>

<!-- Apis for namespace -->
<Route Url="/:namespace"                              Method="GET"    Call="httpGetNamespace"/>
<Route Url="/:namespace"                              Method="DELETE" Call="httpDeleteNamespace"/>
<!-- Apis for Database -->
<Route Url="/:namespace/db/:database"                 Method="GET"    Call="httpGetDatabase"/>

<Route Url="/:namespace/db/:database"                 Method="DELETE" Call="httpDeleteDatabase"/>

<Route Url="/:namespace/db/:database"           	  Method="POST"   Call="httpPostDatabase"/>

<!-- Apis to manage properties -->
<Route Url="/:namespace/prop/:database/:property"     Method="GET"    Call="httpGetProperty"/>

<Route Url="/:namespace/prop/:database/:property"     Method="DELETE" Call="httpDeleteProperty"/>

<Route Url="/:namespace/prop/:database/:property"     Method="POST"   Call="httpPostProperty"/>

<!-- Apis for Documents -->
<Route Url="/:namespace/doc/:database/"                     Method="POST"   Call="httpPostDocument"/>
<Route Url="/:namespace/doc/:database/:docID"               Method="PUT"    Call="httpPutDocument"/> 
<Route Url="/:namespace/doc/:database/:keyName/:keyValue"   Method="PUT"    Call="httpPutDocumentByKey"/> 
<Route Url="/:namespace/doc/:database/:docID"               Method="GET"    Call="httpGetDocument"/>
<Route Url="/:namespace/doc/:database/:keyName/:keyValue"   Method="GET"    Call="httpGetDocumentByKey"/>
<Route Url="/:namespace/doc/:database/:docID"               Method="DELETE" Call="httpDeleteDocument"/>
<Route Url="/:namespace/doc/:database/:keyName/:keyValue"   Method="DELETE" Call="httpDeleteDocumentByKey"/>

<Route Url="/:namespace/find/:database"                     Method="POST"   Call="httpPostFind"/>
</Routes>
}

/// 	This method returns a list of namespaces for this server
/// 	HTTP Codes returned:-
/// 	
/// 	HTTP 200 if OK
/// 	HTTP 500 if an error occurs (details will be in status error array)
/// 	
/// 	returned content is an array of namespaces</Description>
ClassMethod httpPostServer() As %Status
{
	try {
		return ..RenderResponseBody(..#HTTP200OK,,..AccessibleNamespaces())
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpGetNamespace(namespaceName As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAdmin^%SYS.DOCDB(,namespaceName))
		return ..RenderResponseBody(..#HTTP200OK,,##class(%DocDB.Database).%GetAllDatabases())
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpDeleteNamespace(namespaceName As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAdmin^%SYS.DOCDB(,namespaceName))
		return ..RenderResponseBody(..#HTTP200OK,,$$dropAllDatabases^%DocDB.Document(1))
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpDeleteDatabase(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAdmin^%SYS.DOCDB(databaseName,namespaceName))
		if ##class(%DocDB.Database).xNExists(databaseName,.databaseID) {
			$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"W"))
			tstart
			set inTransaction = 1
			do dropDatabase^%DocDB.Document(databaseName)
			tcommit
			set inTransaction = 0
			set dropped = 1
		} else {
			set dropped = 0
		}
		set response = {"database":(databaseName)}
		do response.%Set("dropped",dropped,"boolean")
		return ..RenderResponseBody(..#HTTP200OK,"",response)
	} catch exception {
		if $get(inTransaction) {
			trollback
		}
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpGetDatabase(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"U"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			return ..RenderResponseBody(..#HTTP200OK,,database.%GetDatabaseDefinition())
		} else {
				// Database doesn't exist - should have been handled by an exception
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpPostDatabase(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN="")) As %Status
{
	try {
			// To create a database, the user must have some level of access.
		$$$THROWONERROR(status,$$CheckAdmin^%SYS.DOCDB(databaseName,namespaceName))
		set documentType = $get(%request.Data("type",1),"")
		set resource = $get(%request.Data("resource",1),"")
		if $$$ucase(documentType) = "JSON" {
			set documentType = "%Library.DynamicAbstractObject"
		}
		set database = $system.DocDB.CreateDatabase(databaseName,documentType,resource)
		if $isObject(database) {
			return ..RenderResponseBody(..#HTTP201CREATED,,database.%GetDatabaseDefinition())
		} else {
				// Database wasn't created? - should have thrown an exception, report a general failure here.
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpDeleteProperty(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN=""), propertyName As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAdmin^%SYS.DOCDB(databaseName,namespaceName))
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"W"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			set property = database.%DropProperty(propertyName)
			return ..RenderResponseBody(..#HTTP200OK,,database.%GetDatabaseDefinition())
		} else {
				// Property doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpGetProperty(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN=""), propertyName As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"U"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			return ..RenderResponseBody(..#HTTP200OK,,database.%GetPropertyDefinition(propertyName))
		} else {
				// Property doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpPostProperty(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN=""), propertyName As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAdmin^%SYS.DOCDB(databaseName,namespaceName))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"W"))
			set propertyType = $get(%request.Data("type",1),"%String")
			set propertyPath = $get(%request.Data("path",1),"")
			set propertyUnique = $get(%request.Data("unique",1),"")
			set property = database.%CreateProperty(propertyName,propertyType,propertyPath,propertyUnique)
			return ..RenderResponseBody(..#HTTP201CREATED,,database.%GetPropertyDefinition(propertyName))
		} else {
				// Database wasn't created?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpDeleteDocument(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN=""), documentID As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"W"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			set document = database.%DeleteDocument(documentID)
			return ..RenderResponseBody(..#HTTP200OK,,document)
		} else {
				// Database doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpDeleteDocumentByKey(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN=""), keyName As %String(MAXLEN=""), keyValue As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"W"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			set document = database.%DeleteDocumentByKey(keyName,keyValue)
			return ..RenderResponseBody(..#HTTP200OK,,document)
		} else {
				// Database doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpGetDocument(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN=""), documentID As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"R"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			set document = database.%GetDocument(documentID)
			return ..RenderResponseBody(..#HTTP200OK,,document)
		} else {
				// Database doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpGetDocumentByKey(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN=""), keyName As %String(MAXLEN=""), keyValue As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"R"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			set document = database.%GetDocumentByKey(keyName,keyValue)
			return ..RenderResponseBody(..#HTTP200OK,,document)
		} else {
				// Database doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpPutDocument(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN=""), documentID As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"W"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			set requestBody = ..getRequestBody()
			set document = database.%SaveDocument(requestBody,documentID)
			return ..RenderResponseBody(..#HTTP200OK,,{"_documentID":(document.%Id()),"content":(document.%Doc)})
		} else {
				// Database doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpPutDocumentByKey(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN=""), keyName As %String(MAXLEN=""), keyValue As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"W"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			set requestBody = ..getRequestBody()
			set document = database.%SaveDocumentByKey(requestBody,keyName,keyValue)
			return ..RenderResponseBody(..#HTTP200OK,,{"_documentID":(document.%Id()),"content":(document.%Doc)})
		} else {
				// Database doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpPostDocument(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"W"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			set requestBody = ..getRequestBody()
			set document = database.%SaveDocument(requestBody)
			return ..RenderResponseBody(..#HTTP201CREATED,,{"_documentID":(document.%Id()),"content":(document.%Doc)})
		} else {
				// Database doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
}

ClassMethod httpPostFind(namespaceName As %String(MAXLEN=""), databaseName As %String(MAXLEN="")) As %Status
{
	try {
		$$$THROWONERROR(status,$$CheckAccess^%SYS.DOCDB(databaseName,,"U"))
		set database = $system.DocDB.GetDatabase(databaseName)
		if $isObject(database) {
			set requestBody = ..getRequestBody()
			if $isObject(requestBody) {
				set result = database.%FindDocuments(requestBody.restriction,requestBody.projection,requestBody.options)
			} else {
				set result = database.%FindDocuments()
			}
			return ..RenderResponseBody(..#HTTP200OK,,result)
		} else {
				// Database doesn't exist?
		}
	} catch exception {
		set httpResponse = ..exceptionToHttpResponse(exception)
		return ..RenderResponseBody(httpResponse.httpStatus,httpResponse.status)
	}
	return $$$OK
}

}
