/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %Api.Atelier.v4 provides version 4 APIs for Atelier
Class %Api.Atelier.v4 Extends %Api.Atelier.v3
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

</Routes>
}

/// This method returns the text for the named document and namespace.
/// <br/>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 200 if OK
/// <br/>HTTP 304 if the document has not been modified (see https://en.wikipedia.org/wiki/HTTP_ETag)
/// <br/>HTTP 400 if the named resource is not a valid document name
/// <br/>HTTP 404 if the document does not exist
/// <br/>HTTP 500 if an unxpected error occurs (details will be in status error array)
/// <br/>
/// <br/>Return content will contain a document object.
/// <br/>Errors pertaining to the document will be in the status property of the document object.
/// If source control hooks are enabled for the namespace any console output generated by the hook
/// will be captured and returned as an array of lines in the 'console' array.
/// <br/>
/// <br/>The result contains the name of the requested document, the database where it is stored, its
/// timestamp and category (CLS - class, RTN - routine, CSP - csp, OTH - other), as well as
/// the document contents which are returned in an array. 
/// <br/>
/// <br/>For text documents this will be an array of strings and the 'enc' json field will be set to false.
/// <br/>For binary documents this will be an array of base64 encoded chunks and the 'enc' field will be set to true.
/// <br/>
/// <br/>The URL parameter ?binary=1 can be passed to force the document to be encoded as binary.
/// <br/>
/// <br/>The URL parameter ?storageOnly=1 can be passed to return only the storage portion of a class.
/// <br/>
/// <br/>The URL parameter ?format= can be passed to specify the source format. The choices are
/// "udl" (the default), "udl-multiline" or "xml". Specifying "udl-multiline" will format method 
/// arguments on multiple lines.
/// <br/>
/// <br/>If a 'soft' error occurs such as a 'document does not exist', additional information can be found in
/// the 'status' field of the result. Examples of other soft errors are 'file is locked' etc.
/// <br/>
/// <br/>Here is an example of the result of asking for %Activate.Enum.cls
/// <pre>
/// {
///   "status": {
///     "errors": [],
///     "summary": ""
///   },
///   "console": [],
///   "result": {
///     "name": "%Activate.Enum.cls",
///     "db": "IRISLIB",
///     "ts": "2016-01-04 14:00:04.000",
///     "cat": "CLS",
///     "status": "",
///     "enc": false,
///     "content": [
///       "/// This class is the superclass for all enumerated types generated from",
///       "/// a type library",
///       "Class %Activate.Enum Extends %Integer [ Not ProcedureBlock, System = 3 ]",
///       "{",
///       "",
///       "}",
///       ""
///     ]
///   }
/// }
/// </pre>
/// <br/>and here is the result with ?binary=1
/// <br/>
/// <pre>
/// {
///   "status": {
///     "errors": [],
///     "summary": ""
///   },
///   "console": [],
///   "result": {
///     "name": "%Activate.Enum.cls",
///     "db": "IRISLIB",
///     "ts": "2016-01-04 14:00:04.000",
///     "cat": "CLS",
///     "status": "",
///     "enc": true,
///     "content": [
///       "Ly8vIFRoaXMgY2xhc3MgaXMgdGhlIHN1cGVyY2xhc3MgZm9yIGFsbCBlbnVtZXJhdGVkIHR5cGVzIGdlbmVyYXRlZCBmcm9tCi8vLyBhIHR5cGUgbGlicmFyeQpDbGFzcyAlQWN0aXZhdGUuRW51bSBFeHRlbmRzICVJbnRlZ2VyIFsgTm90IFByb2NlZHVyZUJsb2NrLCBTeXN0ZW0gPSAzIF0KewoKfQo="
///     ]
///   }
/// }
/// </pre>
/// 
ClassMethod GetDoc(pNamespace As %String, pDocName As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tClientServerHash,tServerServerHash As %String = ""
    #dim tCookie,tTextArray As %String
    #dim tBinary As %Boolean = 0
    #dim tUpToDate As %Boolean 
    #dim tFlags As %Integer
    #dim tMsgArray As %DynamicArray = []
    
    #dim %SourceControl As %Studio.SourceControl.Base
    
    Try {
        
        #; Capture output
        Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
        If $$$ISERR(tSC) Quit

        #; Kill any previously existing instance of source control class
        Kill %SourceControl

        #; Create the source control class (if any)
        Set tSC=..CreateSourceControlClass()
        If $$$ISERR(tSC) Quit

        #; Validate
        If ##class(%Atelier.v1.Utils.General).ValidateDocName(pDocName,.tSC,,.tBinary) = 0 {
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }
        
        #; If force binary
        If +%request.Get("binary") Set tBinary=1
     
        #; Normalize
        Set pDocName=##class(%Atelier.v1.Utils.General).NormalizeDocName(pDocName)
        
        #; Exists?
        If '##class(%Atelier.v1.Utils.General).ExistsDoc(pDocName,.tSC) {
            Set %response.Status=..#HTTP404NOTFOUND
            Quit
        }
        
        #; Get the clients version of the server hash
        Set tClientServerHash=..GetClientServerHash()
        
        #; Now set the server hash (from the server)
        Set tServerServerHash=##class(%Atelier.v1.Utils.General).TS(pDocName,.tUpToDate)
     
        If tClientServerHash = tServerServerHash {
            
            If tServerServerHash = "" {
                Set %response.Status=..#HTTP404NOTFOUND
            }
            Else {
                Set %response.Status=..#HTTP304NOTMODIFIED
            }
            Quit
        }
        
        #; Check source format
        Set tFlags=%request.Get("format")
        If tFlags=""||(tFlags="udl") {
            Set tFlags=0
        } ElseIf tFlags="xml" {
            Set tFlags=1
        } ElseIf tFlags="%RO" {
            Set tFlags=2
        } ElseIf tFlags="udl-multiline" {
            Set tFlags=16
        } Else {
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }
     
        #; Check if storage only is required?
        If +%request.Get("storageOnly") Set tFlags=tFlags+8

        #; Get the document text
        Set tSC=##class(%Atelier.v2.Utils.TextServices).GetTextAsArray(pDocName,tFlags,.tTextArray,tBinary)
        If $$$ISERR(tSC) {
           If $Piece($System.Status.GetErrorCodes(tSC),",")=5920 {
               #; Should report a 404
               Set %response.Status=..#HTTP404NOTFOUND
           }
           Quit
        } 
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    #; MUST close the redirect whatever happens
    If $Data(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
    
    #; Serve the status and text
    Quit ..ServeDoc(pDocName,tSC,tMsgArray,.tTextArray,tServerServerHash,.tUpToDate)
}

/// This method returns the indices for the all the specified documents in the namespace.
/// <br/>A list of documents to be indexed is passed in the body of the http request.
/// <br/>The request body is simply a JSON array of names of documents you want to index [ "%Activate.Enum.cls", ... ]
/// <br/>
/// <br/>An optional label+offset location can be included at the end of a document name, delimited by a colon: [ "%Activate.Enum.cls:method+5", ... ]
/// <br/>If a location is provided for a document, the values in the "others" array in the response object will contain the
/// <br/>document name followed by a ':' and then the offset corresponding to the location in the requested document.
/// <br/>
/// <br/>NOTE: Currently we only support the indexing of classes
/// <br/>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 200 if OK
/// <br/>HTTP 415 if the we are not passed application/json as the content type
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// <br/>
/// <br/>Return content will be an array of index document objects. Errors pertaining to a document
/// <br/>will be in the status property of each document object. The index contains information relating
/// <br/>to the structure and documentation of documents on the server and will vary by the category to
/// <br/>which the document belongs. Below is an example for a class.
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
///         "name": "%Activate.GenericObject.cls",
///         "db": "IRISLIB",
///         "ts": "2016-01-04 14:00:04.000",
///         "gen": false,
///         "others": [
///           "%Activate.GenericObject.1.INT"
///         ],
///         "cat": "CLS",
///         "content": {
///           "desc": "This class provides functionality to create an ActiveX object, invoke its methods\nand Get/Set its properties by name.",
///           "depl": false,
///           "depr": false,
///           "final": false,
///           "hidden": false,
///           "super": [
///             "%Activate.IDispatch"
///           ],
///           "methods": [
///             {
///               "name": "CreateObject",
///               "desc": "This method is used to create a generic object given only its progid. If the object\ncannot be found an exception is thrown. The return value should be tested against\n$$$NULLOREF  in the usual manner to ensure that the object has been successfully\ncreated",
///               "depr": false,
///               "final": true,
///               "internal": false,
///               "private": false,
///               "scope": "class",
///               "returntype": "%Library.RegisteredObject",
///               "args": [
///                 {
///                   "name": "Progid",
///                   "type": "%Library.String"
///                 }
///               ]
///             },
///             {
///               "name": "GetObject",
///               "desc": "This method is used to create a generic object from a moniker. If the object\ncannot be found an exception is thrown. The return value should be tested against\n$$$NULLOREF  in the usual manner to ensure that the object has been successfully\ncreated.",
///               "depr": false,
///               "final": true,
///               "internal": false,
///               "private": false,
///               "scope": "class",
///               "returntype": "%Library.RegisteredObject",
///               "args": [
///                 {
///                   "name": "Moniker",
///                   "type": "%Library.String"
///                 }
///               ]
///             }
///           ],
///           "parameters": [],
///           "properties": []
///         },
///         "status": ""
///       }
///     ]
///   }
/// }
/// </pre>
ClassMethod Index(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tCookie,tRenderList As %String
    #dim tDocNameArray As %DynamicArray
    #dim tResPart As %DynamicObject
    #dim tMsgArray As %DynamicArray = []
    
    #; Document atributes
    #dim tDB,tName,tTS,tGen,tOne,tOth,tTemp,tCat As %String = ""
    #dim tUpToDate As %Boolean
    
    #dim tI As %Integer
    #dim tDocStatus As %Status
    
    #dim tRoutineMgr As %RoutineMgr
    
    Try {
     
        #; Ensure we are only passed json
        If %request.ContentType'="application/json" {  
            Set %response.Status=..#HTTP415UNSUPPORTEDMEDIATYPE
            Quit
        }
            
        If '$IsObject(%request.Content) {
            Set tSC=$$$ERROR($$$PostedDataNoContent)
            Set %response.Status=..#HTTP400BADREQUEST
            Quit    
        }

        #; Parse the content (JSON array)
        Try {
            Set tDocNameArray=##class(%DynamicArray).%FromJSON(%request.Content)
        } Catch (e) {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set %response.Status=..#HTTP400BADREQUEST
        }
        If $$$ISERR(tSC) Quit

        If 'tDocNameArray.%IsA("%DynamicArray") {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }
        
        Try {
            
            #; Need an instance of routine mgr
            Set tRoutineMgr=##class(%RoutineMgr).%New()
             
            #; Capture output
            Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
            If $$$ISERR(tSC) Quit
        
            #; For each document
            For tI=0:1:tDocNameArray.%Size()-1 {
                
                #; Get the name
                Set tName=tDocNameArray.%Get(tI)

                #; Split the location from the name if a location was provided
                Set tLoc = ""
                If $FIND(tName,":") Set tLoc = $PIECE(tName,":",2,*), tName = $PIECE(tName,":")
                
                #; We don't know the database or the timestamp yet
                Set (tDB,tTS,tUpToDate)="",tDocStatus=$$$OK
                    
                #; Validate Name (hard error if not valid)
                If ##class(%Atelier.v1.Utils.General).ValidateDocName(tName,.tDocStatus,.tCat) {
                
                    #; Normalize
                    Set tName=##class(%Atelier.v1.Utils.General).NormalizeDocName(tName)
                    
                    #; Exists?
                    If ##class(%Atelier.v1.Utils.General).ExistsDoc(tName,.tDocStatus) {
                       
                        #; Get the database
                        Set tDB=""
                        Set tSC=##class(%Atelier.v1.Utils.General).GetDbForDoc(tName,.tDB)
                        If $$$ISERR(tSC) Quit
                        
                        #; Get the timestamp
                        Set tTS=##class(%Atelier.v1.Utils.General).TS(tName,.tUpToDate)
                        
                        #; Get the generated flag
                        Set tGen=+tRoutineMgr.IsGenerated(tName)
                        
                        #; We will use an array to eliminate duplicates
                        Kill tTemp
                        
                        #; Get the 'others' array (both descendents and ancestors)
                        Set tOth=tRoutineMgr.GetOther($Piece(tName,".",1,*-1),$Piece(tName,".",*),1,tLoc)
                        If tOth'="" {
                            For tOne=1:1:$Length(tOth,",") Set tTemp($Piece(tOth,",",tOne))=""
                        }
                        Set tOth=tRoutineMgr.GetOther($Piece(tName,".",1,*-1),$Piece(tName,".",*),-1,tLoc)
                        If tOth'="" {
                            For tOne=1:1:$Length(tOth,",") Set tTemp($Piece(tOth,",",tOne))=""
                        }
                        
                        #; Must eliminate duplicates, reconstruct string
                        #; and normalize the type to lower case because that is what
                        #; all our other apis do
                        Set (tOth,tOne)="" For {
                            Set tOne=$Order(tTemp(tOne)) If tOne="" Quit
                            If $FIND(tOne,":") {
                                Set tOth=tOth_$Piece($PIECE(tOne,":"),".",1,*-1)_"."_$zcvt($Piece($PIECE(tOne,":"),".",*),"l")_":"_$PIECE(tOne,":",2,*)_","
                            }
                            Else {
                                Set tOth=tOth_$Piece(tOne,".",1,*-1)_"."_$zcvt($Piece(tOne,".",*),"l")_","
                            }
                        }
                        
                        #; Remove final ','
                        If tOth'="" Set $Extract(tOth,$Length(tOth))=""
                    }
                }
                   
                #; Add to the RenderList
                Set tRenderList(tName)=##class(%Atelier.v1.Utils.LazyIndex).%New(tName,tDB,tTS,tDocStatus,tCat,tGen,tOth,tUpToDate)
            }
        
        } Catch (e) {
            Set tSC=e.AsStatus()
        }
        
        #; MUST close the redirect whatever happens
        If $Data(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
        
        #; NOW check error status
        If $$$ISERR(tSC) Quit
            
        #; Create a collection of documents
        Set tResPart=##class(%Atelier.v1.Utils.General).CreateDocumentCollection(.tRenderList)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    #; Render the response body
    Quit ..RenderResponseBody(tSC,tMsgArray,.tResPart)
}

/// Helper method for Query
/// Appends result set (%SQL.StatementResult) to an array.
/// Largely copied from %DataModel.Document.Server.SQL.Query
ClassMethod AppendResultSet(pArray As %DynamicArray, pResult As %SQL.StatementResult) As %Status [ Internal, Private ]
{
    #dim tSC As %Status
    #dim e,setException As %Exception.AbstractException
    
    #dim tRSMD As %SQL.StatementMetadata
    #dim tColObj As %SQL.StatementColumn
    #dim tRow,tJSONValue As %DynamicObject
    #dim tColumns,tCellVal
    #dim tCol As %Integer

    Set tSC = $$$OK
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
            Set tColumns(tCol,1) = $Case(tColObj.clientType,
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
        }
        
        While pResult.%Next(.tSC) {
            If $$$ISERR(tSC) Quit
            
            Set tRow = {}
            For tCol=1:1:tColumns {
                Set tCellVal = pResult.%GetData(tCol)
                If (tCellVal '= "") && (tColumns(tCol,1) = "string") && ($Find("{[",$Extract(tCellVal))) {
                    Try {
                        Set tJSONValue = ##class(%DynamicAbstractObject).%FromJSON(tCellVal)
                        Do tRow.%Set(tColumns(tCol),tJSONValue)
                    } Catch parseException {
                        #; Couldn't parse string into a %DynamicAbstractObject, so just return the string
                        Do tRow.%Set(tColumns(tCol),tCellVal,"string")
                    }
                } Else {
                    Try {
                        Do tRow.%Set(tColumns(tCol),tCellVal,tColumns(tCol,1))
                    } Catch setException {
                        If setException.Name = "<ILLEGAL VALUE>" {
                            Do tRow.%Set(tColumns(tCol),tCellVal,"string")
                        } Else {
                            Throw setException
                        }
                    }
                }
            }
                            
            Do pArray.%Push(tRow)
        }
    } Catch (e) {
        Set tSC = e.AsStatus()
    }
    Quit tSC
}

}
