/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %Api.Atelier.v6 provides version 6 APIs for Atelier
Class %Api.Atelier.v6 Extends %Api.Atelier.v5
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<!-- Run the debugger -->
<Route Url="/%SYS/debug"                        Method="GET" Call="RunDebugger"/>

<!-- Get a list of running jobs -->
<Route Url="/%SYS/jobs"                         Method="GET" Call="GetJobs"/>

<!-- Api for delivering meta data -->
<Route Url="/%SYS/metadata/:database"           Method="GET" Call="GetMetaData"/>

<!-- Get a list of defined csp apps -->
<Route Url="/%SYS/cspapps"                      Method="GET" Call="GetCSPApps"/>

<!-- Get a list of csp apps for a namespace -->
<Route Url="/%SYS/cspapps/:namespace"           Method="GET" Call="GetCSPApps"/>

<!-- Return informations about a specific namespace -->
<Route Url="/:namespace"                        Method="GET" Call="GetNamespace"/>

<!-- Apis to retrieve document meta data -->
<Route Url="/:namespace/docnames"               Method="GET"    Call="GetDocNames"/>
<Route Url="/:namespace/docnames/:cat"          Method="GET"    Call="GetDocNames"/>
<Route Url="/:namespace/docnames/:cat/"         Method="GET"    Call="GetDocNames"/>
<Route Url="/:namespace/docnames/:cat/:type"    Method="GET"    Call="GetDocNames"/>
 
<Route Url="/:namespace/modified/:type"         Method="POST"   Call="GetModifiedDocNames"/>

<!-- Apis to retrieve,save and delete individual documents -->
<Route Url="/:namespace/doc/(.*)"               Method="PUT"    Call="PutDoc"/> 
<Route Url="/:namespace/doc/(.*)"               Method="GET"    Call="GetDoc"/>
<Route Url="/:namespace/doc/(.*)"               Method="DELETE" Call="DeleteDoc"/>
<Route Url="/:namespace/doc/(.*)"               Method="HEAD"   Call="HeadDoc"/>

<!-- Apis to retrieve and delete list of documents -->
<Route Url="/:namespace/docs"                   Method="POST"   Call="GetDocs"/>
<Route Url="/:namespace/docs"                   Method="DELETE" Call="DeleteDocs"/>

<!-- Apis to compile documents -->
<Route Url="/:namespace/action/compile"         Method="POST"   Call="Compile"/>

<!-- index one or more classes -->
<Route Url="/:namespace/action/index"           Method="POST"   Call="Index"/>

<!-- run a query -->
<Route Url="/:namespace/action/query"           Method="POST"   Call="Query"/>

<!-- Apis to support long-running requests -->
<Route Url="/:namespace/work"                   Method="POST"   Call="QueueAsync"/>
<Route Url="/:namespace/work/:id"               Method="GET"    Call="PollAsync"/>
<Route Url="/:namespace/work/:id"               Method="DELETE" Call="CancelAsync"/>

<!-- Ensemble support -->
<Route Url="/:namespace/ens/classes/:type"      Method="GET" Call="GetEnsClassType"/>
<Route Url="/:namespace/ens/adapter/:name"      Method="GET" Call="GetAdpInputOutputClass"/>

<!-- Apis for conversion (Will Be Deprecated: Customers should not call from own code) -->
<Route Url="/:namespace/cvt/doc/xml"            Method="POST"   Call="CvtClientDocToXml"/>
<Route Url="/:namespace/cvt/xml/doc"            Method="POST"   Call="CvtXmlToClientDoc"/>

<!-- ******************************** v2 **********************************************-->

<!-- Get a debug id for debugging a csp application -->
<Route Url="/%SYS/cspdebugid" Method="GET" Call="GetCSPDebugId"/>

<!-- Get a list of macros for prompt after $$$ -->
<Route Url="/:namespace/action/getmacrolist" Method="POST" Call="GetMacroList"/>

<!-- Get the signature of a macro -->
<Route Url="/:namespace/action/getmacrosignature" Method="POST" Call="GetMacroSignature"/>

<!-- Get the location of a macro -->
<Route Url="/:namespace/action/getmacrolocation" Method="POST" Call="GetMacroLocation"/>

<!-- Get the definition of a macro -->
<Route Url="/:namespace/action/getmacrodefinition" Method="POST" Call="GetMacroDefinition"/>

<!-- Get the expansion of a macro with arguments -->
<Route Url="/:namespace/action/getmacroexpansion" Method="POST" Call="GetMacroExpansion"/>

<!-- Do a server find in files -->
<Route Url="/:namespace/action/search" Method="GET" Call="Search"/>

<!-- Get the specified SA Schema definition -->
<Route Url="/:namespace/saschema/(.*)" Method="GET" Call="GetSASchemaDefinition"/>

<!-- ******************************** v3 **********************************************-->
<!-- There are no new entry points for v3, only correction for QueueAsync -->

<!-- ******************************** v4 **********************************************-->
<!-- There are no new entry points for v4 -->

<!-- ******************************** v5 **********************************************-->
<!-- There are no new entry points for v5, only debugger changes -->

<!-- ******************************** v6 **********************************************-->
<!-- There are no new entry points for v6 -->

</Routes>
}

/// This method returns the results of running the specified query in the specified namespace.
/// <br/>The request body is simply a JSON object which specifies the query:
/// <pre>
/// {
///   "query": "SELECT TOP 1 Name FROM %Dictionary.ClassDefinition",
///   "parameters" : []
/// }
/// </pre>
/// <br/>The URL parameter ?max= can be passed to specify the maximum number of rows to return. 
/// The value must be a positive integer or the default behavior (return all rows) will be used.
/// <br/>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 200 if OK
/// <br/>HTTP 415 if the we are not passed application/json as the content type
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// <br/>
/// <br/>If the URL parameter ?positional=1 is passed, the return object key will contain an array of objects,
/// one for each result set, that contains the column metadata and the values for each row in separate arrays:
/// <pre>
/// {
///   "status": {
///     "errors": [],
///     "summary": ""
///   },
///   "console": [],
///   "result": [
///      {
///        "columns": [
///          {
///            "name": "Name",
///            "type": "VARCHAR(4096)"
///          }
///        ],
///        "content": [
///          [
///            "%Api.Atelier"
///          ]
///        ]
///      }
///   ]
/// }
/// </pre>
/// <br/>If the positional URL parameter is not passed or the value is not 1, the return content will be an array of objects.
/// <br/>The objects contain information relating to each row returned by the query:
/// <pre>
/// {
///   "status": {
///     "errors": [],
///     "summary": ""
///   },
///   "console": [],
///   "result": {
///     "content": [
///       {
///         "Name": "%Api.Atelier"
///       }
///     ]
///   }
/// }
/// </pre>
ClassMethod Query(pNamespace As %String) As %Status
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    
    #Dim tCookie,tValue,tParams As %String
    #Dim tQuery,tResPart As %DynamicObject
    #Dim tResult,tInnerResult As %SQL.StatementResult
    #Dim tArray As %DynamicArray
    #Dim tMsgArray As %DynamicArray = []
    #Dim tIterator
    #Dim tI As %Integer
    #Dim tParamIter
    
    Try {
     
        #; Ensure we are only passed json
        If %request.ContentType'="application/json" {  
            Set %response.Status=..#HTTP415UNSUPPORTEDMEDIATYPE
            Quit
        }
            
        If '$ISOBJECT(%request.Content) {
            Set tSC=$$$ERROR($$$PostedDataNoContent)
            Set %response.Status=..#HTTP400BADREQUEST
            Quit    
        }
        
        #; Parse the query spec into a JSON object
        Try {
            Set tQuery=##class(%DynamicObject).%FromJSON(%request.Content)
        } Catch (e) {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set %response.Status=..#HTTP400BADREQUEST
        }
        If $$$ISERR(tSC) Quit

        If 'tQuery.%IsA("%DynamicObject") {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }

        #; Get the values of query parameters
        Set tMax = $NUMBER(+$GET(%request.Data("max",1)),"I",1)
        If tMax = "" Set tMax = -1
        Set tPositional = (+$GET(%request.Data("positional",1)) = 1)
        
        Try {
            
            #; Capture output
            Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
            If $$$ISERR(tSC) Quit
        
            #; Previously used document database; perhaps could again in the future
            #; to keep things simple. For now, some duplication of what it will do.
            Set tStmt=##class(%SQL.Statement).%New()
            If (tQuery.%GetTypeOf("parameters") = "array") {
                Set tParamIter = tQuery.parameters.%GetIterator()
                While tParamIter.%GetNext(,.tValue) {
                    Set tParams($INCREMENT(tParams)) = tValue
                }
            }
            Set tSC=tStmt.%Prepare(tQuery.query,0)
            If $$$ISERR(tSC) Quit
            
            Set tResult=tStmt.%Execute(tParams...)
            
            Set tArray=[]
            
            If (tResult.%SQLCODE < 0) {
                Throw ##class(%Exception.SQL).CreateFromSQLCODE(tResult.%SQLCODE,tResult.%Message)
            }
            
            If (tResult.%StatementType = 1) {
                #; SELECT ...
                Set tSC = ..AppendResultSet(tArray,tResult,tMax,tPositional)
            } ElseIf (tResult.%StatementType = 45) {
                #; CALL ...
                Set tInnerResult=tResult.%NextResult()
                While (tInnerResult '= "") {
                    Set tSC = ..AppendResultSet(tArray,tInnerResult,tMax,tPositional)
                    If $$$ISERR(tSC) Quit
                    Set tInnerResult=tResult.%NextResult()
                }
            }
            If $$$ISERR(tSC) Quit
            
            If tPositional {
                Set tResPart = tArray
            } Else {
                Set tResPart={},tResPart.content=tArray
            }
        
        } Catch (e) {
            Set tSC=e.AsStatus()
        }
        
        #; MUST close the redirect whatever happens
        If $DATA(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    #; Render the response body
    Quit ..RenderResponseBody(tSC,tMsgArray,.tResPart)
}

/// Helper method for Query
/// Appends result set (%SQL.StatementResult) to an array.
/// Largely copied from %DataModel.Document.Server.SQL.Query
/// If <var>pMax</var> is -1 (the default), return all rows. Else, returns <var>pMax</var> rows.
/// If <var>pPositional</var> is 1, create an object with column metadata and the values for each row returned as an array.
/// Else (the default), use the same return format as versions 1-5.
ClassMethod AppendResultSet(pArray As %DynamicArray, pResult As %SQL.StatementResult, pMax As %Integer = -1, pPositional As %Boolean = 0) As %Status [ Internal, Private ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e,setException As %Exception.AbstractException
    
    #Dim tRSMD As %SQL.StatementMetadata
    #Dim tColObj As %SQL.StatementColumn
    #Dim tJSONValue As %DynamicObject
    #Dim tColumns,tCellVal
    #Dim tCol As %Integer

    Set tCount = 0
    If pPositional {
        Set tRSObj = {
            "columns": [],
            "content": []
        }
    }
    Try {
        #; Get statement metadata
        #; From %DataModel.Document.Server.SQL.Query:$fromResultSet
        #; See that method for more information on datatype numbers.
        Set tRSMD=pResult.%GetMetadata()
        Set tColumns=tRSMD.columns.Count()
        For tCol=1:1:tColumns {
            Set tColObj = tRSMD.columns.GetAt(tCol)
            Set tColumns(tCol) = tColObj.colName
            
            //All date/time types are formatted as strings.
            Set tColumns(tCol,1) = $CASE(tColObj.clientType,
                2   : "datetime",
                3   : "number",
                4   : "oref",
                5   : "number",
                14  : "number",
                15  : "number",
                16  : "boolean",
                18  : "number",
                21  : "number",
                    : "string"
            )

            If pPositional {
                #; Append the column metadata to the columns array
                Do tRSObj.columns.%Push({
                    "name": (tColObj.colName),
                    "type": ($$GetODBCTypeString^%ourODBC(tColObj.ODBCType,tColObj.precision,tColObj.precision,tColObj.scale))
                })
            }
        }
        
        While pResult.%Next(.tSC) {
            If $$$ISERR(tSC) Quit
            
            If pPositional {
                Set tRow = []
            } Else {
                Set tRow = {}
            }
            For tCol=1:1:tColumns {
                Set tCellVal = pResult.%GetData(tCol)
                If (tCellVal '= "") && (tColumns(tCol,1) = "string") && ($FIND("{[",$EXTRACT(tCellVal))) {
                    Try {
                        Set tJSONValue = ##class(%DynamicAbstractObject).%FromJSON(tCellVal)
                        If pPositional {
                            Do tRow.%Push(tJSONValue)
                        } Else {
                            Do tRow.%Set(tColumns(tCol),tJSONValue)
                        }
                    } Catch parseException {
                        #; Couldn't parse string into a %DynamicAbstractObject, so just return the string
                        If pPositional {
                            Do tRow.%Push(tCellVal,"string")
                        } Else {
                            Do tRow.%Set(tColumns(tCol),tCellVal,"string")
                        }
                    }
                } Else {
                    Try {
                        If pPositional {
                            Do tRow.%Push(tCellVal,tColumns(tCol,1))
                        } Else {
                            Do tRow.%Set(tColumns(tCol),tCellVal,tColumns(tCol,1))
                        }
                    } Catch setException {
                        If setException.Name = "<ILLEGAL VALUE>" {
                            If pPositional {
                                Do tRow.%Push(tCellVal,"string")
                            } Else {
                                Do tRow.%Set(tColumns(tCol),tCellVal,"string")
                            }
                        } Else {
                            Throw setException
                        }
                    }
                }
            }

            If pPositional {
                Do tRSObj.content.%Push(tRow)
            } Else {
                Do pArray.%Push(tRow)
            }
            Set tCount = tCount + 1
            If pMax '= -1, tCount >= pMax Quit
        }
    } Catch (e) {
        Set tSC = e.AsStatus()
    }
    If pPositional, $$$ISOK(tSC) {
        Do pArray.%Push(tRSObj)
    }
    Quit tSC
}

/// <br/> This call queues an item for work. On success it returns 202 and sets the 'Location' header
/// <br/> to indicate where the results can be retrieved from with an HTTP GET.
/// <br/>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 202 if Accepted
/// <br/>HTTP 404 if the request type does not exist
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// 
ClassMethod QueueAsync(pNameSpace As %String) As %Status [ Internal ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    
    #Dim %request As %CSP.Request
    #Dim %response As %CSP.Response
    
    #Dim tMsgArray As %DynamicArray = []
    #Dim tCookie As %String
    #Dim tID,tJob As %Integer
    #Dim tRequest,tResPart As %DynamicObject
    #Dim tWQM As %SYSTEM.WorkMgr
    
    #; Initialize
    Set tResPart={},tResPart.content={}
     
    Try {
        
        Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
        If $$$ISERR(tSC) Quit
        
        #; Validate the type of content
        If %request.ContentType'="application/json" {
            Set %response.Status=..#HTTP415UNSUPPORTEDMEDIATYPE
            Quit
        }
        
        #; Need to make sure that we have some content
        If '$ISOBJECT(%request.Content) {
            Set tSC=$$$ERROR($$$PostedDataNoContent)
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }
        
        Set tSC=%request.Content.Rewind()
        If $$$ISERR(tSC) Quit
        
        Try {
            Set tRequest=##class(%DynamicObject).%FromJSON(%request.Content)
        } Catch (e) {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set %response.Status=..#HTTP400BADREQUEST
        }
        If $$$ISERR(tSC) Quit

        If 'tRequest.%IsA("%DynamicObject") {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }
        
        #; Validate the request type
        If tRequest.request'="compile",tRequest.request'="testrtn",tRequest.request'="search" {
            Set tSC=$$$ERROR($$$UnknownRequestType,tRequest.request)
            Set %response.Status=..#HTTP404NOTFOUND
            Quit
        }

        #; Validate the request arguments
        If tRequest.request="compile" && (
            (tRequest.%GetTypeOf("documents")'="array") ||
            ((tRequest.%GetTypeOf("flags")'="unassigned") && (tRequest.%GetTypeOf("flags")'="string")) ||
            ((tRequest.%GetTypeOf("source")'="unassigned") && (tRequest.%GetTypeOf("source")'="boolean"))
        ) {
            Set tSC = $$$ERROR($$$InvalidJSONContent)
            Set %response.Status = ..#HTTP400BADREQUEST
            Quit
        } ElseIf tRequest.request="search" && (
            (tRequest.%GetTypeOf("query")'="string") ||
            ((tRequest.%IsDefined("documents")) && (tRequest.%IsDefined("project"))) ||
            (('tRequest.%IsDefined("documents")) && ('tRequest.%IsDefined("project"))) ||
            ((tRequest.%GetTypeOf("system")'="unassigned") && (tRequest.%GetTypeOf("system")'="boolean")) ||
            ((tRequest.%GetTypeOf("generated")'="unassigned") && (tRequest.%GetTypeOf("generated")'="boolean")) ||
            ((tRequest.%GetTypeOf("regex")'="unassigned") && (tRequest.%GetTypeOf("regex")'="boolean")) ||
            ((tRequest.%GetTypeOf("max")'="unassigned") && (tRequest.%GetTypeOf("max")'="number")) ||
            ((tRequest.%GetTypeOf("word")'="unassigned") && (tRequest.%GetTypeOf("word")'="boolean")) ||
            ((tRequest.%GetTypeOf("case")'="unassigned") && (tRequest.%GetTypeOf("case")'="boolean")) ||
            ((tRequest.%GetTypeOf("wild")'="unassigned") && (tRequest.%GetTypeOf("wild")'="boolean")) ||
            ((tRequest.%GetTypeOf("mapped")'="unassigned") && (tRequest.%GetTypeOf("mapped")'="boolean")) ||
            ((tRequest.%GetTypeOf("include")'="unassigned") && (tRequest.%GetTypeOf("include")'="string")) ||
            ((tRequest.%GetTypeOf("exclude")'="unassigned") && (tRequest.%GetTypeOf("exclude")'="string")) ||
            ((tRequest.%GetTypeOf("console")'="unassigned") && (tRequest.%GetTypeOf("console")'="boolean"))
        ) {
            Set tSC = $$$ERROR($$$InvalidJSONContent)
            Set %response.Status = ..#HTTP400BADREQUEST
            Quit
        }
        
        #; Create a Work Queue Manager
        Set tWQM = $SYSTEM.WorkMgr.%New(,1)
        If '$ISOBJECT(tWQM) Set tSC = %objlasterror Quit

        #; Generate a new ID
        Set tID=+$SYSTEM.Encryption.GenCryptToken()
        
        #; Save the request
        Set ^IRIS.TempAtelierAsyncQueue(tID,"request")=tRequest.%ToJSON()
        Set ^IRIS.TempAtelierAsyncQueue(tID,"requesttype")=tRequest.request
        If tRequest.request="search" {
            Set ^IRIS.TempAtelierAsyncQueue(tID,"console")=tRequest.%Get("console",1)
        }
        
        #; Set up the console output queue counters
        Set ^IRIS.TempAtelierAsyncQueue(tID,"cout","i")=1
        Set ^IRIS.TempAtelierAsyncQueue(tID,"cout","o")=1

        #; Save the request start time
        Set ^IRIS.TempAtelierAsyncQueue(tID,"start")=$ZHOROLOG

        #; Queue the work
        Set tSC = tWQM.Queue("##class(%Api.Atelier.v6).ExecuteAsyncRequest",tID)
        If $$$ISERR(tSC) Quit

        #; Detach from the Work Queue Manager
        Set tSC = tWQM.Detach(.tWQMToken)
        If $$$ISERR(tSC) Quit

        #; Store the token in the global so the poll and cancel methods can access it
        Set ^IRIS.TempAtelierAsyncQueue(tID,"wqm") = tWQMToken
        
        #; Set the location to get results from
        Do %response.SetHeader("Location",tID)
        
        Set %response.Status=..#HTTP202ACCEPTED
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    #; MUST close the redirect whatever happens
    If $DATA(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
    
    Quit ..RenderResponseBody(tSC,tMsgArray,tResPart)
}

/// <br/> This call polls a queued item for console output and results. On success it returns 200. 
/// <br/> Console output and results are found in the standard locations for Atelier REST APIs.
/// <br/> If there is more output expected the server will set the 'Retry-After' header. The client
/// <br/> should read this header to determine if another call should be made.
/// <br/> When the result of processing is available (or the work is finished) a GET to this API 
/// <br/> will return any results in the 'content' field and (crucially) will NOT set the 'Retry-After'
/// <br/> header. This is an indication that processing is finished.
/// <br/>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 200 if Accepted
/// <br/>HTTP 404 if the request ID does not exist
/// <br/>HTTP 423 if the global node is locked
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// 
ClassMethod PollAsync(pNameSpace As %String, pID As %Integer) As %Status [ Internal ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    
    #Dim %request As %CSP.Request
    #Dim %response As %CSP.Response
    
    #Dim tI,tIn,tOut As %Integer
    #Dim tResult As %String
    #Dim tMsgArray As %DynamicArray = []
    #Dim tResPart As %DynamicObject
    #Dim tWQM As %SYSTEM.WorkMgr
    
    Set tResPart = { "content":{} }
    
    Try {
        
        #; Lock this global node
        Lock +^IRIS.TempAtelierAsyncQueue("work",pID):1
        Else  Set %response.Status=..#HTTP423LOCKED Quit
        
        #; Exists?
        If '$DATA(^IRIS.TempAtelierAsyncQueue(pID,"request")) {
            Set %response.Status=..#HTTP404NOTFOUND
            Quit
        }
        
        #; Response should be ok
        Set %response.Status=..#HTTP200OK

        #; Store the request type and console log value in case the global gets killed
        Set tRequestType = ^IRIS.TempAtelierAsyncQueue(pID,"requesttype")
        Set tConsole = $GET(^IRIS.TempAtelierAsyncQueue(pID,"console"),1)

        #; Re-attach to the Work Queue Manager
        Set tWQM = $SYSTEM.WorkMgr.Attach(^IRIS.TempAtelierAsyncQueue(pID,"wqm"),.tSC)
        If $$$ISERR(tSC) Quit

        #; Wait with no timeout to see if request is still being processed
        Do tWQM.WaitOne(0,.tWorkSC)

        #; Capture console output
        Set tIn=^IRIS.TempAtelierAsyncQueue(pID,"cout","i"),tOut=^IRIS.TempAtelierAsyncQueue(pID,"cout","o")
        While tOut<tIn {
            Do tMsgArray.%Push($GET(^IRIS.TempAtelierAsyncQueue(pID,"cout",tOut)))
            Set tOut=tOut+1
        }
        Set ^IRIS.TempAtelierAsyncQueue(pID,"cout","o")=tOut

        If $$$ERRORISTYPE(tWorkSC,$$$MultiTimeout) {
            #; Request is still being processed

            #; Client needs to ask again (arbitrary wait time)
            Do %response.SetHeader("Retry-After",3)

            #; Detach from the Work Queue Manager
            Set tSC = tWQM.Detach(.tWQMToken)
            If $$$ISERR(tSC) Quit

            #; Store the token in the global
            Set ^IRIS.TempAtelierAsyncQueue(pID,"wqm") = tWQMToken
            
        } Else {
            #; Request processing has finished
            
            #; Is a result present?
            If $DATA(^IRIS.TempAtelierAsyncQueue(pID,"result"),tResult)#2 {
                Set tResPart=##class(%DynamicObject).%FromJSON(tResult)
            }
            
            #; Copy the returned status value into tSC
            Set tSC = tWorkSC
            
            #; Clean it all, it's an error to ask again
            Kill ^IRIS.TempAtelierAsyncQueue(pID), tWQM

        }

        #; If request type is search, compute result JSON from console output
        If $$$ISOK(tSC), tRequestType = "search" {
            #; It's safe to overwrite tResPart since the search code will never set it
            Set tSC = ..SearchOutputToJSON(tMsgArray,.tResPart)
            If $$$ISERR(tSC) {
                #; Restore the default value for tResPart
                Set tResPart = { "content":{} }
            }
            If 'tConsole {
                #; Caller requested that we don't send console output.
                #; VS Code will request this to avoid returning unused data.
                Set tMsgArray = []
            }
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    #; Release the lock
    Lock -^IRIS.TempAtelierAsyncQueue("work",pID)
    
    Quit ..RenderResponseBody(tSC,tMsgArray,tResPart)
}

/// <br/> This call cancels a work request that has been previously queued.
/// <br/>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 200 if Cancelled
/// <br/>HTTP 404 if the request ID does not exist
/// <br/>HTTP 423 if the global node is locked
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// 
ClassMethod CancelAsync(pNameSpace As %String, pID As %Integer) As %Status [ Internal ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    #Dim tWQM As %SYSTEM.WorkMgr
    
    Try {

        #; Lock this global node
        Lock +^IRIS.TempAtelierAsyncQueue("work",pID):1
        Else  Set %response.Status=..#HTTP423LOCKED Quit

        #; Exists?
        If '$DATA(^IRIS.TempAtelierAsyncQueue(pID,"request")) {
            Set %response.Status=..#HTTP404NOTFOUND
            Quit
        }
        
        #; Response should be ok
        Set %response.Status=..#HTTP200OK

        #; Re-attach to the Work Queue Manager
        Set tWQM = $SYSTEM.WorkMgr.Attach(^IRIS.TempAtelierAsyncQueue(pID,"wqm"),.tSC)

        #; Kill the global and Work Queue Manager
        Kill ^IRIS.TempAtelierAsyncQueue(pID), tWQM
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }

    #; Release the lock
    Lock -^IRIS.TempAtelierAsyncQueue("work",pID)
    
    Quit ..RenderResponseBody(tSC)
}

/// Convert find in files console output into a JSON array.
/// Extracted from the end of <CLASS>%Api.Atelier.v2</CLASS>::Search().
ClassMethod SearchOutputToJSON(pMsgArray As %DynamicArray, ByRef pResult As %DynamicArray) As %Status [ Internal, Private ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException

    Try {
        Set pResult=[],odoc="",docobj="",docmatarr=[],startmsg=$$$GetSimpleMessage("%Compiler","SearchFor")_"'"
        For tI=0:1:pMsgArray.%Size()-1 {
            Set line=pMsgArray.%Get(tI)
            If (
                (line = "") ||
                (line = $$$GetSimpleMessage("%Compiler","SearchNotFound")) ||
                ((($FIND(line,startmsg) = ($LENGTH(startmsg) + 1)) && (line[("'"_$$$GetSimpleMessage("%Compiler","SearchIn"))))) ||
                ((line[$$$GetSimpleMessage("%Compiler","SearchFound")) && (line[$$$GetSimpleMessage("%Compiler","SearchOccurrences")) && (line[$$$GetSimpleMessage("%Compiler","SearchFiles")))
            ) {
                #; Skip blank and metadata lines
                Continue
            }
            Set p1=$FIND(line,"(")
            If 'p1 {
                Set p1=$FIND(line,":")
                If p1<3 Continue ; Very strange
                #; Must be a match on routine name
                Set doc=$EXTRACT(line,1,p1-2)
                #; Mark name as line 0
                Set $EXTRACT(line,p1-1)="(0):"
            } Else {
                Set doc=$PIECE(line,"(")
            }
            If doc'=odoc {
                If docobj'="" {
                    Do docobj.%Set("matches",docmatarr)
                    Do pResult.%Push(docobj)
                }
                Set docobj={"doc":(doc)}, docmatarr=[]
                Set odoc=doc
            }
            Set p2=$FIND(line,")",p1)
            Set loc=$EXTRACT(line,p1,p2-2)
            If loc=+loc {
                #; Just a line number, must be a routine
                If loc=0 {
                    #; If match on the name, report no line at all
                    Set matobj={}
                } Else {
                    Set matobj={"line":(loc)}
                }
                Set p2=$FIND(line,":")
            } Else {
                If loc'="" {
                    Set p1=$FIND(loc,"+")
                    Set matobj={"member":($PIECE(loc,"+"))}
                    If p1 Do matobj.%Set("line",(+$EXTRACT(loc,p1,*)))
                } Else {
                    Set matobj={}
                }
                Set p1=$FIND(line,"["),p2=$FIND(line,":")
                If p1,p1<p2 {
                    Set attr=$EXTRACT(line,p1,$FIND(line,"]",p1)-2)
                    Set p1=$FIND(attr,"+")
                    If p1 {
                        Set loc=$EXTRACT(attr,p1,*),attr=$EXTRACT(attr,1,p1-2)
                    } Else {
                        Set loc=$SELECT(attr="Description":1,1:"")
                    }
                    Do matobj.%Set("attr",(attr))
                    If loc'="" Do matobj.%Set("attrline",(+loc))
                } ElseIf 'p1,loc="" {
                    #; Neither location nor attribute, must be just the name
                    Do matobj.%Set("attr","Name")
                }
            }
            Do matobj.%Set("text",($EXTRACT(line,p2+1,*)))
            Do docmatarr.%Push(matobj)
        }
        If docobj'="" {
            Do docobj.%Set("matches",docmatarr)
            Do pResult.%Push(docobj)
        }
    } Catch (e) {
        Set tSC=e.AsStatus()
    }

    Quit tSC
}

/// This is a background job that monitors the queue for work to do
ClassMethod ExecuteAsyncRequest(pID As %Integer) [ Internal ]
{
    #Dim tRequest As %DynamicObject
    #Dim e As %Exception.AbstractException
    #Dim tSC As %Status = $$$OK
    #Dim tFlags,tGetSource,tItemArray,tI
    #Dim tResult As %DynamicObject
        
    Try {

        If '$SYSTEM.WorkMgr.IsWorkerJob() {
            #; This ClassMethod must be run in a Work Queue Manager worker job
            Set tSC = $$$ERROR($$$AsyncRequestNotWorker) Quit
        }
        
        Set tRequest=##class(%DynamicObject).%FromJSON(^IRIS.TempAtelierAsyncQueue(pID,"request"))
        
        If tRequest.request="compile" {
            
            Set tFlags = tRequest.%Get("flags","cuk")
            Set tGetSource = tRequest.%Get("source",1)
            Kill tItemArray
            For tI=0:1:tRequest.documents.%Size()-1 {
                Set tItemArray(tRequest.documents.%Get(tI))=""
            }
            
            Try {
                
                Set tSC=..AsyncRequestBeginCapture(pID,.tCookie)
                If $$$ISERR(tSC) Quit
                
                Set tResult = {}
                Set tSC=##class(%Atelier.v1.Utils.General).Compile(.tItemArray,tFlags,tGetSource,.tResult)
                
            } Catch (e) {
                Set tSC=e.AsStatus()
                Set:'$DATA(tResult) tResult = {}
            }
            
            Do ..AsyncRequestEndCapture(.tCookie)
            
            Set ^IRIS.TempAtelierAsyncQueue(pID,"result")=tResult.%ToJSON()
            
        } ElseIf tRequest.request="testrtn" {
            
            If tRequest.%IsDefined("tag") {
                Set tFlags=tRequest.tag
            } Else {
                Set tSC=$$$ERROR($$$GeneralError,"No Entry Point tag")
                Quit
            }
            If tRequest.%IsDefined("routine") {
                Set tI=tRequest.routine
            } Else {
                Set tSC=$$$ERROR($$$GeneralError,"No Entry Point routine")
                Quit
            }
            
            Try {
                
                Set tSC=..AsyncRequestBeginCapture(pID,.tCookie)
                If $$$ISERR(tSC) Quit
                
                Set tSC=$$@(tFlags)^@(tI)(.tResult)
            
            } Catch (e) {
                Set tSC=e.AsStatus()
            }
            
            Set:'$DATA(tResult) tResult = {}
            Do ..AsyncRequestEndCapture(.tCookie)
            
            Set ^IRIS.TempAtelierAsyncQueue(pID,"result")=tResult.%ToJSON()
            
        } ElseIf tRequest.request="search" {
            
            Try {
                
                Set tSC=..AsyncRequestBeginCapture(pID,.tCookie)
                If $$$ISERR(tSC) Quit
                
                Set tSC=##class(%Studio.Project).FindInFilesAtelierv6(
                    tRequest.query,
                    tRequest.%Get("regex",0),
                    tRequest.%Get("word",0),
                    tRequest.%Get("case",1),
                    tRequest.%Get("wild",1),
                    tRequest.%Get("max",200),
                    tRequest.%Get("project"),
                    tRequest.%Get("documents"),
                    tRequest.%Get("system",0),
                    tRequest.%Get("generated",0),
                    tRequest.%Get("mapped",1),
                    tRequest.%Get("include"),
                    tRequest.%Get("exclude")
                )
                
            } Catch (e) {
                Set tSC=e.AsStatus()
            }
            
            Do ..AsyncRequestEndCapture(.tCookie)
        } Else {
            Set tSC=$$$ERROR($$$UnknownRequestType,tRequest.request)
        }
        
    } Catch e {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

ClassMethod AsyncRequestBeginCapture(pID As %Integer, Output pCookie As %String) As %Status [ Internal, ProcedureBlock = 0 ]
{
    New tSC,e

    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    
    Try {
        #; Save the current status
		Set pCookie = $LISTBUILD(##class(%Device).ReDirectIO(),$ZUTIL(96,12))

        #; Use this routine for redirection
        Use $IO::("^"_$ZNAME)
        
        #; Set the node
        Set ^||ISC.AsyncQueueNode=pID

        #; Switch redirection on
        Do ##class(%Device).ReDirectIO(1)

    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
    
rstr(sz,to) [rt] public {
    New rt Set vr="rt"
    Set rd=##class(%Device).ReDirectIO(0)
    Set:$DATA(sz) vr=vr_"#"_sz Set:$DATA(to) vr=vr_":"_to
    Read @vr
    Do:$DATA(to) $SYSTEM.Process.IODollarTest($TEST)
    Do ##class(%Device).ReDirectIO(rd)
    Quit rt
}
wchr(s) Do write($CHAR(s)) Quit
wff() Do write($CHAR(12)) Quit
wnl() Do write($CHAR(10)) Quit
wstr(s) Do write(s) Quit
wtab(s) Do write($JUSTIFY("",s-$X)) Quit
write(s) public {
    Set tZR=$ZREFERENCE
    Set tID=^||ISC.AsyncQueueNode
    Set lf=$FIND(s,$CHAR(10))
    If lf {
        Do {
            Do write($EXTRACT(s,1,lf-2))
            Set i=$INCREMENT(^IRIS.TempAtelierAsyncQueue(tID,"cout","i"))
            Set s=$EXTRACT(s,lf,*)
            Set lf=$FIND(s,$CHAR(10))
        } While lf
        If s="" Quit
    }
    Set lno=$GET(^IRIS.TempAtelierAsyncQueue(tID,"cout","i")) Set:lno="" lno=1,^IRIS.TempAtelierAsyncQueue(tID,"cout","i")=1
    Set curr=$GET(^IRIS.TempAtelierAsyncQueue(tID,"cout",lno))
    Set ^IRIS.TempAtelierAsyncQueue(tID,"cout",lno)=curr_$TRANSLATE(s,$CHAR(13))
    Set $ZREFERENCE=tZR
}
}

ClassMethod AsyncRequestEndCapture(pCookie As %String) As %Status [ Internal ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    
    Try {
        If pCookie '= "", $LISTVALID(pCookie) {
            #; Restore the original redirection state and routine
            Use $IO::("^"_$LIST(pCookie,2))
            Do ##class(%Device).ReDirectIO($LIST(pCookie,1))
        } Else {
            #; Otherwise switch redirection off
            Do ##class(%Device).ReDirectIO(0)
        }
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Purge the ^IRIS.TempAtelierAsyncQueue global of any request data that is over a day old.
/// Theoretically there should be nothing to clean up but this is needed in case
/// some error occurs and request data is left behind.
ClassMethod PurgeAsyncQueue() As %Status [ Internal ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    
    Try {
        #; Loop through the global looking for requests to clean up
        Set tID = $ORDER(^IRIS.TempAtelierAsyncQueue(""))
        While tID '= "" {
            If ($ZHOROLOG - $GET(^IRIS.TempAtelierAsyncQueue(tID,"start"),0)) >= 86400 {
                #; This request is over a day old so clean it up
                Kill ^IRIS.TempAtelierAsyncQueue(tID)
            }
            Set tID = $ORDER(^IRIS.TempAtelierAsyncQueue(tID))
        }
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

}
