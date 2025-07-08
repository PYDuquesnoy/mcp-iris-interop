/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %Api.Atelier.v8 provides version 8 APIs for Atelier
Class %Api.Atelier.v8 Extends %Api.Atelier.v7
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

<!-- ******************************** v7 **********************************************-->

<!-- Run the terminal -->
<Route Url="/%SYS/terminal" Method="GET" Call="RunTerminal"/>

<!-- Apis to export and load legacy XML documents -->
<Route Url="/:namespace/action/xml/export" Method="POST" Call="ExportToXMLFile"/>
<Route Url="/:namespace/action/xml/load"   Method="POST" Call="LoadXMLFiles"/>
<Route Url="/:namespace/action/xml/list"   Method="POST" Call="ListDocumentsInXMLFiles"/>

<!-- ******************************** v8 **********************************************-->
<!-- There are no new entry points for v8 -->

</Routes>
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
        If ",compile,testrtn,search,unittest,"'[(","_tRequest.request_",") {
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
        } ElseIf tRequest.request="unittest" && (
            (tRequest.%GetTypeOf("tests")'="array") ||
            ((tRequest.%GetTypeOf("load")'="unassigned") && (tRequest.%GetTypeOf("load")'="array")) ||
            ((tRequest.%GetTypeOf("console")'="unassigned") && (tRequest.%GetTypeOf("console")'="boolean")) ||
            ((tRequest.%GetTypeOf("debug")'="unassigned") && (tRequest.%GetTypeOf("debug")'="boolean"))
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
        #; Serialize %request.Content stream into global to avoid <MAXSTRING>
        Set tSC = %request.Content.Rewind()
        If $$$ISERR(tSC) Quit
        While '%request.Content.AtEnd {
            Set ^IRIS.TempAtelierAsyncQueue(tID,"request",$INCREMENT(^IRIS.TempAtelierAsyncQueue(tID,"request"))) = %request.Content.Read()
        }
        Set ^IRIS.TempAtelierAsyncQueue(tID,"requesttype")=tRequest.request
        If ((tRequest.request="search") || (tRequest.request="unittest")) {
            Set ^IRIS.TempAtelierAsyncQueue(tID,"console")=tRequest.%Get("console",1)
            If tRequest.request="unittest", tRequest.%Get("debug",0) {
                #; Generate a CSP debug ID
                #; Adapted from %Api.Atelier.v2:GetCSPDebugId()
                For  Set tCSPDebugId = $ZLASCII($SYSTEM.Encryption.GenCryptRand(4))\2 Quit:'$DATA(^IRIS.TempCSP("Debug",tCSPDebugId))
                Set ^IRIS.TempCSP("Debug",tCSPDebugId) = "", ^IRIS.TempAtelierAsyncQueue(tID,"debugid") = tCSPDebugId
            }
        }
        
        #; Set up the console output queue counters
        Set ^IRIS.TempAtelierAsyncQueue(tID,"cout","i")=1
        Set ^IRIS.TempAtelierAsyncQueue(tID,"cout","o")=1

        #; Save the request start time
        Set ^IRIS.TempAtelierAsyncQueue(tID,"start")=$ZHOROLOG

        #; Queue the work
        Set tSC = tWQM.Queue("##class("_$CLASSNAME()_").ExecuteAsyncRequest",tID)
        If $$$ISERR(tSC) Quit

        #; Detach from the Work Queue Manager
        Set tSC = tWQM.Detach(.tWQMToken)
        If $$$ISERR(tSC) Quit

        #; Store the token in the global so the poll and cancel methods can access it
        Set ^IRIS.TempAtelierAsyncQueue(tID,"wqm") = tWQMToken
        
        #; Set the location to get results from
        Do %response.SetHeader("Location",tID)

        If $GET(^IRIS.TempAtelierAsyncQueue(tID,"debugid")) {
            #; Report the CSP debug ID to the client
            Set tResPart.content.debugId = ^IRIS.TempAtelierAsyncQueue(tID,"debugid")
        }
        
        Set %response.Status=..#HTTP202ACCEPTED
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    #; MUST close the redirect whatever happens
    If $DATA(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
    
    Return ..RenderResponseBody(tSC,tMsgArray,tResPart)
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

            If tRequestType = "unittest" {
                #; Clean up after the unit test run
                Do ..CleanUpAfterUnitTestRequest(pID)
            }
            
            #; Clean up the WQM object
            Kill tWQM
        }

        #; If request type is search or unittest, compute result JSON
        If $$$ISOK(tSC), ((tRequestType = "search") || (tRequestType = "unittest")) {
            #; It's safe to overwrite tResPart since the search and unittest code will never set it
            If tRequestType = "search" {
                #; Compute result JSON from console output
                Set tSC = ..SearchOutputToJSON(tMsgArray,.tResPart)
            } Else {
                If $GET(^IRIS.TempAtelierAsyncQueue(pID,"debugid")) '= "", $GET(^IRIS.TempAtelierAsyncQueue(pID,"debugready")) = 1 {
                    #; Tell the client that it can start debugging
                    #; It's safe to not check for results since 
                    #; "debugready" will only be 1 when the worker job
                    #; is ready to be debugged and before any tests are run
                    Kill ^IRIS.TempAtelierAsyncQueue(pID,"debugready")
                    Do tResPart.content.%Set("debugReady",1,"boolean")
                } Else {
                    #; Compute result JSON from global
                    Set tSC = ..UnitTestResultToJSON(pID,.tResPart)
                }
            }
            If $$$ISERR(tSC) {
                #; Restore the default value for tResPart
                Set tResPart = { "content":{} }
            }
            If 'tConsole {
                #; Caller requested that we don't send console output.
                #; VS Code will request this for "search" requests to avoid returning unused data.
                Set tMsgArray = []
            }
        }

        #; Clean up the global if request processing has finished
        If '$$$ERRORISTYPE(tWorkSC,$$$MultiTimeout) Kill ^IRIS.TempAtelierAsyncQueue(pID)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    #; Release the lock
    Lock -^IRIS.TempAtelierAsyncQueue("work",pID)
    
    Return ..RenderResponseBody(tSC,tMsgArray,tResPart)
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

        #; Kill the Work Queue Manager
        Kill tWQM

        If ^IRIS.TempAtelierAsyncQueue(pID,"requesttype") = "unittest" {
            #; Clean up after the unit test run
            Do ..CleanUpAfterUnitTestRequest(pID)
        }

        #; Kill the global
        Kill ^IRIS.TempAtelierAsyncQueue(pID)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }

    #; Release the lock
    Lock -^IRIS.TempAtelierAsyncQueue("work",pID)
    
    Return ..RenderResponseBody(tSC)
}

/// This method performs the long-running work that was queued by the POST /work (QueueAsync) endpoint
ClassMethod ExecuteAsyncRequest(pID As %Integer) [ Internal ]
{
    #Dim tRequest As %DynamicObject
    #Dim e As %Exception.AbstractException
    #Dim tSC As %Status = $$$OK
    #Dim tResult As %DynamicObject
        
    Try {

        If '$SYSTEM.WorkMgr.IsWorkerJob() {
            #; This ClassMethod must be run in a Work Queue Manager worker job
            Set tSC = $$$ERROR($$$AsyncRequestNotWorker) Quit
        }

        #; Load JSON object from global
        Set tRequestStrm = ##class(%Stream.TmpCharacter).%New()
        If '$ISOBJECT(tRequestStrm) Set tSC = %objlasterror Quit
        For tChunk=1:1:^IRIS.TempAtelierAsyncQueue(pID,"request") {
            Set tSC = tRequestStrm.Write(^IRIS.TempAtelierAsyncQueue(pID,"request",tChunk))
            If $$$ISERR(tSC) Quit
        }
        If $$$ISERR(tSC) Quit
        Set tRequest = ##class(%DynamicObject).%FromJSON(tRequestStrm)

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
        } ElseIf tRequest.request="unittest" {

            Try {

                Set tSC=..AsyncRequestBeginCapture(pID,.tCookie)
                If $$$ISERR(tSC) Quit

                #; Load any needed files. May be test classes to run or autoload documents.
                If tRequest.%IsDefined("load"), tRequest.load.%Size() {
                    #; Create a temporary directory to load from
                    Set tTempDir = ##class(%File).SubDirectoryName(##class(%SYS.System).TempDirectory(),"_unittest_"_pID)
                    If '##class(%File).CreateDirectory(tTempDir) {
                        Set tSC = $$$ERROR($$$DirectoryCannotCreate,tTempDir) Quit
                    }
                    Set ^IRIS.TempAtelierAsyncQueue(pID,"unittest","loaddir") = tTempDir
                    Set tLoadIter = tRequest.load.%GetIterator(), tTempFiles = "", tDisplayNames = "", tDigits = $LENGTH(tRequest.load.%Size())
                    While tLoadIter.%GetNext(.tLoadIdx,.tLoadObj) {
                        If (
                            '$ISOBJECT(tLoadObj) ||
                            'tLoadObj.%IsA("%DynamicObject") ||
                            (tLoadObj.%GetTypeOf("file") '= "string") ||
                            (";xml;cls;mac;int;inc;"'[(";"_$ZCONVERT($PIECE(tLoadObj.file,".",*),"l")_";")) ||
                            (tLoadObj.%GetTypeOf("content") '= "array") ||
                            (tLoadObj.content.%Size() = 0)
                        ) {
                            #; Each object in the "load" array must have a file path string
                            #; that is for an XML or UDL file and content string array
                            Continue
                        }
                        #; Generate the name of the temporary file using its index in the JSON array
                        #; Zero-pad file numbers so they sort in the correct order as subscripts in an array
                        Set tFileName = ##class(%File).NormalizeFilename($TRANSLATE($JUSTIFY(tLoadIdx,tDigits)," ",0)_"."_$ZCONVERT($PIECE(tLoadObj.file,".",*),"l"),tTempDir)
                        Set tTempFiles = tTempFiles_"*"_tFileName, tDisplayNames = tDisplayNames_"*"_tLoadObj.file
                        #; Write the content array to a temporary file
                        Set tFile = ##class(%Stream.FileCharacter).%New()
                        If '$ISOBJECT(tFile) Set tSC = %objlasterror Quit
                        Set tSC = tFile.LinkToFile(tFileName)
                        If $$$ISERR(tSC) Quit
                        Set tContentIter = tLoadObj.content.%GetIterator()
                        While tContentIter.%GetNext(,.tLine) {
                            Set tSC = tFile.WriteLine(tLine)
                            If $$$ISERR(tSC) Quit
                        }
                        If $$$ISERR(tSC) Quit
                        Set tSC = tFile.%Save()
                        If $$$ISERR(tSC) Quit
                    }
                    If $$$ISERR(tSC) Quit
                    Set $EXTRACT(tTempFiles) = "", $EXTRACT(tDisplayNames) = "" ##; Remove the leading *

                    If tTempFiles '= "" {
                        #; List the source code files we are loading
                        Kill tExistsList
                        Set tSC = $SYSTEM.OBJ.Load(tTempFiles,"-d",,.tExistsList,1)
                        If $$$ISERR(tSC) Quit
                        Set tDoc = $ORDER(tExistsList(""))
                        While tDoc '= "" {
                            #; Keep track of files that exist already
                            If '##class(%RoutineMgr).Exists(tDoc) Kill tExistsList(tDoc)
                            Set tDoc = $ORDER(tExistsList(tDoc))
                        }

                        #; Load the files
                        Kill tLoadedList
                        Set tSC = $SYSTEM.OBJ.Load(tTempFiles,"ckd/generatemap",,.tLoadedList,,,tDisplayNames)
                        Set tLoadedDoc = $ORDER(tLoadedList(""))
                        While tLoadedDoc '= "" {
                            If '$DATA(tExistsList(tLoadedDoc)) {
                                #; Store the names of the files we created so we can delete them later
                                Set ^IRIS.TempAtelierAsyncQueue(pID,"unittest","created",tLoadedDoc) = ""
                            }
                            Set tLoadedDoc = $ORDER(tLoadedList(tLoadedDoc))
                        }
                        If $$$ISERR(tSC) Quit
                    }
                }

                #; Check if a CSP debug ID is set
                Set tDebugId = $GET(^IRIS.TempAtelierAsyncQueue(pID,"debugid"))

                #; Build the testspec for all tests to run
                Set tTestsIter = tRequest.tests.%GetIterator(), tTestSpec = ""
                While tTestsIter.%GetNext(,.tTest) {
                    If (
                        '$ISOBJECT(tTest) ||
                        'tTest.%IsA("%DynamicObject") ||
                        (tTest.%GetTypeOf("class") '= "string") ||
                        '##class(%Dictionary.ClassDefinition).%ExistsId(tTest.class)
                    ) {
                        #; Each object in the "tests" array must have a class
                        #; string that is the name of a class that exists
                        Continue
                    }
                    #; Add an entry in the testspec for this test class
                    If tTest.%GetTypeOf("methods") = "array", tTest.methods.%Size() {
                        Set tTestMethodsIter = tTest.methods.%GetIterator()
                        While tTestMethodsIter.%GetNext(,.tTestMethod) {
                            Set tTestSpec = tTestSpec_";"_tTest.class_":Test"_tTestMethod
                        }
                    } Else {
                        Set tTestSpec = tTestSpec_";"_tTest.class
                    }
                    #; Re-compile this class if we didn't load and compile it already.
                    #; Always do this so we can be sure that we have generated INT
                    #; code and maps for debugging and resolving the source location of asserts.
                    If '$DATA(tLoadedList(tTest.class_".cls")) Set tCompileList(tTest.class_".cls") = ""
                }
                Set $EXTRACT(tTestSpec) = ":" ##; The leading ; must be a : (meaning "root" test suite)
                If tTestSpec = ":" Quit ##; No tests to run

                #; Compile any test classes that we need to
                If $DATA(tCompileList) = 10 {
                    Set tSC = $SYSTEM.OBJ.CompileList(.tCompileList,"ckd/generatemap")
                    If $$$ISERR(tSC) Quit
                }

                #; If a CSP debug ID, use it to wait for a debugger to attach
                If tDebugId '= "", $DATA(^IRIS.TempCSP("Debug",tDebugId)) {
                    #; Adapted from label Main in CSPDispatch^%SYS.cspServer()
                    #; Tell the other process who to attach to
                    Set ^IRIS.TempCSP("Debug",tDebugId) = $JOB, ^IRIS.TempCSP("Debug",tDebugId,"id") = ""
                    #; Wait for the attachment
                    Set ^IRIS.TempAtelierAsyncQueue(pID,"debugready") = 1, tDebug = ($SYSTEM.Event.Wait("",10) = 1)
                    Kill ^IRIS.TempCSP("Debug",tDebugId), ^IRIS.TempAtelierAsyncQueue(pID,"debugready")
                } Else {
                    Set tDebug = 0
                }

                #; Determine the TestInstance ID for this run
                Set ^IRIS.TempAtelierAsyncQueue(pID,"unittest","id") = $GET(^UnitTest.Result,0) + 1

                #; Run the tests. Explictly set all flags in case user has changed the defaults.
                #; Always pass /nodebug, even when the user wants to debug the tests, because
                #; we want all errors to be caught. Uncaught errors will cause the server to
                #; report a runtime error the next time it polls and any tests after the error will not be run.
                Set tSC = ##class(%UnitTest.Manager).RunTest(tTestSpec,"/norecursive/noload/run/nodelete/nocleanup/display/nodebug")
            } Catch (e) {
                Set tSC=e.AsStatus()
            }

            If $GET(tDebug) = 1, $ZUTIL(67,16,$JOB) '= 0 {
                #; The debugger was attached to this process and is still attached.
                #; Set a special variable that the client can put a
                #; watchpoint on so it can automatically detach its
                #; debugger now that the tests have finished running.
                Set QQQZZZDebugWatchpointTriggerVar = 1
            }

            #; Clean up whether we succeeded or not
            Do ..CleanUpAfterUnitTestRequest(pID)
            
            Do ..AsyncRequestEndCapture(.tCookie)
        } Else {
            Set tSC=$$$ERROR($$$UnknownRequestType,tRequest.request)
        }
        
    } Catch e {
        Set tSC=e.AsStatus()
    }
    
    Return tSC
}

/// Delete any files created for unit test request <b>pID</b> and restore the value of <b>^UnitTestRoot</b>.
ClassMethod CleanUpAfterUnitTestRequest(pID As %Integer) [ Internal, Private ]
{
    Try {
        #; Need to check for the existence of the nodes since we may have called this method already
        #; or the globals may have not been set before an error occurred or the operation was cancelled
        If $DATA(^IRIS.TempAtelierAsyncQueue(pID,"unittest","created")) = 10 {
            #; Delete all files that were created
            Set tDoc = $ORDER(^IRIS.TempAtelierAsyncQueue(pID,"unittest","created",""))
            While tDoc '= "" {
                Try {
                    #; We want to attempt to delete every created document,
                    #; even if one of them fails to delete and throws an error
                    Do ##class(%RoutineMgr).Delete(tDoc)
                } Catch {}
                #; Kill this node so we don't try to delete this document again
                Kill ^IRIS.TempAtelierAsyncQueue(pID,"unittest","created",tDoc)
                Set tDoc = $ORDER(^IRIS.TempAtelierAsyncQueue(pID,"unittest","created",tDoc))
            }
        }
        If $DATA(^IRIS.TempAtelierAsyncQueue(pID,"unittest","loaddir"),tTempDir) {
            #; Delete the temporary load directory and its contents
            Do ##class(%File).RemoveDirectoryTree(tTempDir)
            #; Kill this node so we don't try to delete the directory again
            Kill ^IRIS.TempAtelierAsyncQueue(pID,"unittest","loaddir")
        }
    } Catch {}
}

/// Convert unit test result global data into a JSON array.
ClassMethod UnitTestResultToJSON(pID As %Integer, ByRef pResult As %DynamicArray) As %Status [ Internal, Private ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    #Dim tMethodObj, tClassObj As %DynamicObject

    Try {
        Set pResult = []
        Set tTestID = $GET(^IRIS.TempAtelierAsyncQueue(pID,"unittest","id"),0)
        If $DATA(^UnitTest.Result(tTestID)) >= 10 {
            #; Scan the global for test methods and classes whose status can be sent to the client

            #; Determine the starting class and method subscripts for the global scan
            Set tClass = $ORDER(^IRIS.TempAtelierAsyncQueue(pID,"unittest","sent",""),-1) ##; Last class we started scanning
            If tClass = "" Set tClass = $ORDER(^UnitTest.Result(tTestID,"(root)","")) ##; Haven't scanned any classes yet, so start from the top
            If $DATA(^IRIS.TempAtelierAsyncQueue(pID,"unittest","sent",tClass))#2 {
                #; We sent the status of this class to the client already, so start scanning the next class
                Set tClass = $ORDER(^UnitTest.Result(tTestID,"(root)",tClass))
            }
            If tClass = "" Quit ##; Nothing to scan
            Set tMethod = $ORDER(^IRIS.TempAtelierAsyncQueue(pID,"unittest","sent",tClass,""),-1) ##; Last method sent in the class being scanned
            Set tMethod = $ORDER(^UnitTest.Result(tTestID,"(root)",tClass,tMethod)) ##; Find the next method to scan

            #; Scan the global
            Set tQuit = 0
            While tClass '= "" {
                While tMethod '= "" {
                    Set tMethodVal = $GET(^UnitTest.Result(tTestID,"(root)",tClass,tMethod))
                    If $LISTLENGTH(tMethodVal) < 2 {
                        #; This method isn't done yet
                        Set tQuit = 1
                        Quit
                    }
                    #; Build a JSON object to represent the status of this TestMethod
                    Set tMethodObj = {
                        "class": (tClass),
                        "method": ($EXTRACT(tMethod,5,*)), ##; VS Code cuts off the common prefix "Test"
                        "status": ($LIST(tMethodVal)),
                        "duration": ($LIST(tMethodVal,2) * 1000), ##; VS Code uses milliseconds
                        "failures": []
                    }
                    If $LIST(tMethodVal) = 0 {
                        #; Get the error and failure messages
                        If $LISTGET(tMethodVal,3) '= "", $LISTGET(tMethodVal,4) '= "" {
                            #; Only keep the top level message if it's an ERROR
                            #; and not the default "There are failed TestAsserts"
                            Set tMethodObj.error = $CASE(
                                $EXTRACT($LIST(tMethodVal,4)),
                                " ":$EXTRACT($LIST(tMethodVal,4),2,*),
                                :$LIST(tMethodVal,4)
                            )
                        }
                        Set tAssert = $ORDER(^UnitTest.Result(tTestID,"(root)",tClass,tMethod,""))
                        While tAssert '= "" {
                            Set tAssertVal = ^UnitTest.Result(tTestID,"(root)",tClass,tMethod,tAssert)
                            If $LISTLENGTH(tAssertVal) >= 3, $LIST(tAssertVal) = 0 {
                                Set tMethodFailure = { "message": ($LIST(tAssertVal,2)_": "_$LIST(tAssertVal,3)) }
                                If $LISTGET(tAssertVal,4) '= "" {
                                    #; Convert the location string to a JSON object
                                    Set tMethodFailure.location = {}
                                    Set tNsRtn = $PIECE($LIST(tAssertVal,4),"^",*), tLabelOffset = $PIECE($LIST(tAssertVal,4),"^",1,*-1)
                                    If tNsRtn["|" {
                                        #; Location has a namespace and routine
                                        Set tMethodFailure.location.namespace = $TRANSLATE($PIECE(tNsRtn,"|",2),"""")
                                        Set tMethodFailure.location.document = $PIECE(tNsRtn,"|",3,*)
                                    } Else {
                                        #; Location has no namespace
                                        Set tMethodFailure.location.document = tNsRtn
                                    }
                                    If tLabelOffset["+", $PIECE(tLabelOffset,"+",*)?1N.N {
                                        #; Location has label and offset
                                        Set tMethodFailure.location.offset = +$PIECE(tLabelOffset,"+",*)
                                        Set tMethodFailure.location.label = $PIECE(tLabelOffset,"+",1,*-1)
                                    } ElseIf tLabelOffset '= "" {
                                        #; Location has no offset
                                        Set tMethodFailure.location.label = tLabelOffset
                                    }
                                }
                                Do tMethodObj.failures.%Push(tMethodFailure)
                            }
                            Set tAssert = $ORDER(^UnitTest.Result(tTestID,"(root)",tClass,tMethod,tAssert))
                        }
                    }
                    Do pResult.%Push(tMethodObj)
                    Set ^IRIS.TempAtelierAsyncQueue(pID,"unittest","sent",tClass,tMethod) = ""
                    #; Move on to the next method
                    Set tMethod = $ORDER(^UnitTest.Result(tTestID,"(root)",tClass,tMethod))
                }
                If tQuit Quit
                Set tClassVal = $GET(^UnitTest.Result(tTestID,"(root)",tClass))
                If $LISTLENGTH(tClassVal) < 2 Quit ##; Class isn't finished
                #; Build a JSON object to represent the status of this TestCase
                Set tClassObj = {
                    "class": (tClass),
                    "status": ($LIST(tClassVal)),
                    "duration": ($LIST(tClassVal,2) * 1000),
                    "failures": []
                }
                If $LIST(tClassVal) = 0 {
                    #; Get the error and failure messages
                    If $LISTGET(tClassVal,3) '= "", $LISTGET(tClassVal,4) '= "" {
                        #; Only keep the top level message if it's an ERROR
                        #; and not the default "There are failed TestMethods"
                        Set tClassObj.error = $LIST(tClassVal,3)_":"_$CASE($EXTRACT($LIST(tClassVal,4))," ":"",:" ")_$LIST(tClassVal,4)
                    }
                    Set tMethod = $ORDER(^UnitTest.Result(tTestID,"(root)",tClass,""))
                    While tMethod '= "" {
                        Set tMethodVal = ^UnitTest.Result(tTestID,"(root)",tClass,tMethod)
                        If $LISTLENGTH(tMethodVal), $LIST(tMethodVal) = 0 {
                            Do tClassObj.failures.%Push({ "message": ($EXTRACT(tMethod,5,*)) })
                        }
                        Set tMethod = $ORDER(^UnitTest.Result(tTestID,"(root)",tClass,tMethod))
                    }
                }
                Do pResult.%Push(tClassObj)
                Set ^IRIS.TempAtelierAsyncQueue(pID,"unittest","sent",tClass) = ""
                #; Move on to the next class
                Set tClass = $ORDER(^UnitTest.Result(tTestID,"(root)",tClass))
                If tClass '= "" Set tMethod = $ORDER(^UnitTest.Result(tTestID,"(root)",tClass,""))
            }
        }
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Return tSC
}

}
