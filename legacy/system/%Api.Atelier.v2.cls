/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %Api.Atelier.v2 provides version 2 APIs for Atelier
Class %Api.Atelier.v2 Extends %Api.Atelier.v1
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

</Routes>
}

/// This method returns an id for use with CSP debugging
/// <br/>
/// <br/>GET http://localhost:57772/api/atelier/v2/%25SYS/cspdebugid
/// <br/>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 200 if OK
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// <br/>
/// <br/>Returned content is an integer debug identifier
/// <br/>
/// {
///   "status": {
///     "errors": [],
///     "summary": ""
///   },
///   "console": [],
///   "result": {
///     "content": { id: NNNNNN }
///   }
/// }
/// 
ClassMethod GetCSPDebugId() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tResult As %DynamicObject = {}
    #dim tId As %Numeric
    
    #; This code is adapted from %Studio.Debugger:GetCSPAttachID()
    #; The original code cannot be used because in exceptional circumstances it
    #; writes a non standard error message to the current device
    Try {
        For  Set tId=$zla($system.Encryption.GenCryptRand(4))\2 Quit:'$Data(^IRIS.TempCSP("Debug",tId))
        Set ^IRIS.TempCSP("Debug",tId)=""
        Set tResult.content=tId
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit ..RenderResponseBody(tSC,,tResult)
}

ClassMethod RunDebugger() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
   
    Try {
        
        Do ##class(%Library.Device).ReDirectIO(0)
        
        Set tSC=##class(%Atelier.v2.XDebugAgent).Page(0)
       
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
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
/// "udl" (the default) or "xml".
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
        } Else {
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }
     
        #; Check if storage only is required?
        If +%request.Get("storageOnly") Set tFlags=tFlags+8
        
        #; Kill any previously existing instance of source control class
        Kill %SourceControl

        #; Create the source control class (if any)
        Set tSC=..CreateSourceControlClass()
        If $$$ISERR(tSC) Quit

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

/// This method saves the supplied document
/// <br/>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 201 if created
/// <br/>HTTP 400 if the resource name is an invalid document name
/// <br/>HTTP 404 if the resource is not found
/// <br/>HTTP 409 if a conflict between server and client versions is detected
/// <br/>HTTP 415 if not passed text/plain as content type
/// <br/>HTTP 425 if the document is locked and cannot be written to
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// <br/>
/// <br/>Return content will be a document object.
/// <br/>Errors pertaining to the document will be in the status property of the document object.
/// <br/>
/// <br/>The URL parameter ?ignoreConflict=1 can be passed to bypass ETAG checking (see reference
/// <br/>above in 'GetDoc') and force the document to be written on the server.
/// <br/>
/// <br/>Note that if the text on the server is changed during the save process (for example
/// <br/>by a source control hook) the new text will be returned in the content array
/// <br/>of the returned document.
/// <br/>
/// <br/>Here is an example of a PUT for the document xyz.mac
/// <br/>
/// <pre>
/// {
///  "enc": false,
///  "content": [
///    "ROUTINE xyz",
///    "xyz ;",
///    "   w \"hello\""
///    ]
/// }
/// </pre>
/// <br/>
/// <br/>and the corresponding response :-
/// <br/>
/// <pre>
/// {
///   "status": {
///     "errors": [],
///     "summary": ""
///   },
///   "console": [
///   ],
///   "result": {
///     "name": "xyz.mac",
///     "db": "IRISSYS",
///     "ts": "2016-01-12 17:18:29.332",
///     "cat": "RTN",
///     "status": "",
///     "enc": false,
///     "content": []
///   }
/// }
/// </pre>
ClassMethod PutDoc(pNamespace As %String, pDocName As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tCookie,tKeywords,tTextArray,tCategory As %String
    #dim tMsgArray As %DynamicArray = []
    
    #dim %SourceControl As %Studio.SourceControl.Base

    #dim tJsonObj As %DynamicObject
    #dim tJsonArray As %DynamicArray
    #dim tBinary,tEnc As %Boolean
    #dim tUpToDate As %Boolean 
    #dim tI As %Integer = 0
    #dim tExists As %Boolean = 0
    #dim tFlags As %Integer
    #dim tLocked As %Integer = -1
    #dim tResponseStatus As %String
    
    #; Hashes
    #dim tPreSaveHash,tPostSaveHash,tClientServerHash,tServerServerHash As %String = ""
    
    #; Assume the worst
    Set tResponseStatus=..#HTTP500INTERNALSERVERERROR
    
    Try {

        Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
        If $$$ISERR(tSC) Quit

        #; Kill any previously existing instance of source control class
        Kill %SourceControl
        
        #; Create the source control class (if any)
        Set tSC=..CreateSourceControlClass()
        If $$$ISERR(tSC) Quit
        
        #; Indicate that we want to know about source modifications
        If $IsObject($Get(%SourceControl)) {
            Kill %SourceControl.Modified
            Set %SourceControl.Modified=1
        }
            
        #; Validate the type of content
        If %request.ContentType'="application/json" {
            Set tResponseStatus=..#HTTP415UNSUPPORTEDMEDIATYPE
            Quit
        }
            
        #; Need to make sure that we have some content
        If '$IsObject(%request.Content) {
            Set tSC=$$$ERROR($$$PostedDataNoContent)
            Set tResponseStatus=..#HTTP400BADREQUEST
            Quit
        }
        
        #; Validate
        If ##class(%Atelier.v1.Utils.General).ValidateDocName(pDocName,.tSC,.tCategory,.tBinary)=0 {
            Set tResponseStatus=..#HTTP400BADREQUEST
            Quit
        }
        
        #; Ensure we are at the begining of the stream and read in the document
        Set tSC=%request.Content.Rewind()
        If $$$ISERR(tSC) Quit
        
        Try {
            Set tJsonObj=##class(%DynamicObject).%FromJSON(%request.Content)
        } Catch (e) {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set tResponseStatus=..#HTTP400BADREQUEST
        }
        If $$$ISERR(tSC) Quit
        
        If 'tJsonObj.%IsA("%DynamicObject") {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set tResponseStatus=..#HTTP400BADREQUEST
            Quit
        }
        
        Set tEnc=tJsonObj.enc
        If (tEnc="false")||(tEnc=0) {
            Set tBinary=0
        } ElseIf (tEnc="true")||(tEnc=1) {
            Set tBinary=1
        } Else {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set tResponseStatus=..#HTTP400BADREQUEST
            Quit
        }
        
        Set tJsonArray=tJsonObj.content
        If '$IsObject(tJsonArray) || 'tJsonArray.%IsA("%DynamicArray") {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set tResponseStatus=..#HTTP400BADREQUEST
            Quit
        }
        
        For tI=1:1:tJsonArray.%Size() Set tTextArray(tI)=tJsonArray.%Get(tI-1)
        If $Data(tTextArray) Set tTextArray(0)=tI
        Kill tJsonArray
    
        #; Optimistically set HTTP code according to pre-existing document
        If ##class(%Atelier.v1.Utils.General).ExistsDoc(pDocName) {
            
            #; Set the exists flag
            Set tExists=1
            
            #; If it already exists then we are replacing the contents
            Set tResponseStatus=..#HTTP200OK
            
        } else {
            
            #; Otherwise we are creating the contents
            Set tResponseStatus=..#HTTP201CREATED
        }
    
        #; Lock the item
        Set tSC=##class(%RoutineMgr).LockItem(pDocName)
        
        If $$$ISERR(tSC) {
            #; Must check for actually being locked
            If $Piece($System.Status.GetErrorCodes(tSC),",")=5864 {
                Set tResponseStatus=..#HTTP423LOCKED
                Quit
            } ElseIf tCategory="OTH" &&
                    (tSC["<METHOD DOES NOT EXIST>") &&
                    (tSC["*Lock,") {
                #; User type might not support Lock
                Set tLocked=0
            } Else {
                
                #; Need to mark as a bad request
                Set tResponseStatus=..#HTTP400BADREQUEST
                Quit
            }
        }
        
        #; Note the document has been locked, unless there was no Lock method
        Set:tLocked<0 tLocked=1
        
        #; Get the overwrite flag
        If +%request.Get("ignoreConflict") {
            
            #; Check if source control allows the save
            If $IsObject($Get(%SourceControl)) {
                Set tSC=..CheckSourceControlEdit(pDocName)
                If $$$ISERR(tSC) {
                    Set tResponseStatus=..#HTTP200OK
                    Quit
                }
            }
            
            Set tSC=##class(%Atelier.v2.Utils.TextServices).SetTextFromArray(.tTextArray,0,pDocName,tCategory,tBinary,.tKeywords)
            If $$$ISERR(tSC) {
                Set tResponseStatus=..#HTTP200OK
                Quit
            }
            
            #; Now get the updated server hash
            Set tServerServerHash=##class(%Atelier.v1.Utils.General).TS(pDocName,.tUpToDate)
            
        } else {
            
            #; Get the server hash (from the client)
            Set tClientServerHash=..GetClientServerHash()
            
            #; Now get the server hash (from the server)
            Set tServerServerHash=##class(%Atelier.v1.Utils.General).TS(pDocName,.tUpToDate)
            
            #; If the server document doesn't exist (could have been manually deleted)
            #; or the hashes match then the text can be saved
            If (tExists=0 || (tClientServerHash=tServerServerHash)) {
            
                #; Yes, we concur on the document we are replacing, save it
                
                #; But first check whether source control allows it
                If $IsObject($Get(%SourceControl)) {
                    Set tSC=..CheckSourceControlEdit(pDocName)
                    If $$$ISERR(tSC) {
                        Set tResponseStatus=..#HTTP200OK
                        Quit
                    }
                }
                
                Set tSC=##class(%Atelier.v2.Utils.TextServices).SetTextFromArray(.tTextArray,0,pDocName,tCategory,tBinary,.tKeywords)
                If $$$ISERR(tSC) {
                    #; We will give status OK because it was a valid request, but the
                    #; client will see the error condition in tSC.
                    Set tResponseStatus=..#HTTP200OK
                    Quit
                }
                
                #; Now get the updated server hash
                Set tServerServerHash=##class(%Atelier.v1.Utils.General).TS(pDocName,.tUpToDate)
                
            } else {
                
                #; Return a conflict HTTP status
                Set tResponseStatus=..#HTTP409CONFLICT
                
                #; Get the conflicted source
                #; Return same format as the input
                Set tSC=$$GetMetaDataFromDocArray^%apiSRC(.tTextArray,,.tKeywords)
                Set tFlags=$Case($Get(tKeywords("format"),"udl"),"udl":0,"xml":1,"%RO":2,:0)

                Kill tTextArray
                Set tSC=##class(%Atelier.v2.Utils.TextServices).GetTextAsArray(pDocName,tFlags,.tTextArray,tBinary)
                
                Quit
            }
        }
        
        If $$$ISERR(tSC) Quit
        
        Set tExtensionContent = ""
        
        #; Only bother to add source control output if there's a source control class configured.
        If $IsObject($Get(%SourceControl)) {
            Set tExtensionContent = []
            If 'tExists {
                #; User has created a new document and saved it (successfully) for the first time.
                #; Fire both "User has created a new document" and
                #; "User has saved a new document for the first time"
                For tActionName = 1,7 {
                    Set tSC = ##class(%Atelier.v1.Utils.Extension).UserActionExecute(.tExtensionItem,1,tActionName,pDocName,"")
                    If $$$ISERR(tSC) Quit
                    If $IsObject(tExtensionItem) {
                        Do tExtensionContent.%Push(tExtensionItem)
                    }
                }
            }
            If $$$ISERR(tSC) Quit
        }
        
        #; Don't need the input any more
        Kill tTextArray
        
        #; Need to check the modified indicator
        #; Source control uses upper case extension
        If $IsObject($Get(%SourceControl)) &&
            ($Get(%SourceControl.Modified($Piece(pDocName,".",1,*-1)_"."_$zcvt($Piece(pDocName,".",*),"U")))=1) {
            
            #; Source was modified by source control hook, need to return to client
            Set tFlags=$Case($Get(tKeywords("format"),"udl"),"udl":0,"xml":1,"%RO":2,:0)
            Set tSC=##class(%Atelier.v2.Utils.TextServices).GetTextAsArray(pDocName,tFlags,.tTextArray,tBinary)
            If $$$ISERR(tSC) {
                Quit
            }
            
            #; Need to get the updated timestamp too
            Set tServerServerHash=##class(%Atelier.v1.Utils.General).TS(pDocName,.tUpToDate)
            
        }
        
        If $IsObject($Get(%SourceControl)) {
            Kill %SourceControl.Modified
        }
        
        #; For a persistent class, always return the Storage definition. The user may have done
        #; some bad things that were corrected by the serialization. We can not determine if that
        #; happens, so always send it back so the client can sort it out.
        If tCategory="CLS",'$Data(tTextArray) {
            Set tSC=##class(%Atelier.v2.Utils.TextServices).GetTextAsArray(pDocName,8,.tTextArray)
            If $$$ISERR(tSC) Quit
            If $Get(tTextArray(0))>1 {
                Set tTextArray("flags")=1 ; text is Storage only
            } Else {
                #; The class has no Storage
                Kill tTextArray
            }
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    #; No matter what happened we want to unlock here (if we locked)
    If tLocked>0 Do ##class(%RoutineMgr).LockItem(pDocName,0)
    
    Set %response.Status=tResponseStatus
    
    #; MUST close the redirect whatever happens
    If $Data(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
    
    #; Serve the doc
    Quit ..ServeDoc(pDocName,tSC,tMsgArray,.tTextArray,tServerServerHash,.tUpToDate,.tExtensionContent)
}

ClassMethod CheckSourceControlEdit(pName As %String) As %Status [ Internal ]
{
    #; code copied from %RoutineMgr.Lock()
    Set edit=0,isinsourcecontrol=0,ischeckedout=0,user="",name=##class(%Studio.SourceControl.Interface).normalizeName(pName)
    Set tmp=%SourceControl New %SourceControl
    If tmp.IsReadOnly(name) {
        Set tSC=$$$ERROR($$$RoutineSourceRO,name)
    } Else {
        Set tSC=tmp.GetStatus(name,.isinsourcecontrol,.edit,.ischeckedout,.user)
        If $$$ISOK(tSC),'edit Set tSC=##class(%RoutineMgr).ConstructEditError(name,isinsourcecontrol,ischeckedout,user)
    }
    Quit tSC
}

/// Input request:
/// <pre>
/// {
///   "docname": "MyClass.cls",
///   "hash": "XXXX",
///   "cursor": "XXX",
///   "superclasses": ["class1",...],
///   "includes": ["include1",...],
///   "includegenerators": ["generator1",...],
///   "imports": ["package1",...],
///   "mode": "generator" or ""
/// }
/// </pre>
///   "hash" is a null string or the value returned from a previous call for this document.
///   If the server contents have not changed, the result will be this same hash value
///   and nothing else.<br/>
///   "cursor" is a null string or the value returned from the previous call.<br/>
/// <br/>Returned content:
/// <pre>
/// {
///   "status": { "errors": [],  "summary": "" },
///   "console": [],
///   "result": {
///     "content": {
///       "hash": "XXXX",
///       "cursor": "XXXX",
///       "macros": ["macro1",...]
///     }
///   }
/// }
/// </pre>
///   "hash" is a value indicating the current contents of the server. If this value
///   is passed in the next request for this document and the server contents have
///   not changed, nothing needs to be returned.<br/>
///   "cursor" will be the null string if the macro list is complete. If it is not
///   null, another call should be made, passing this cursor value, to get the next part
///   of the macro list.
/// 
ClassMethod GetMacroList(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException  
    #dim tMsgArray as %DynamicArray
    #dim tRequest As %DynamicObject
    #dim tResPart As %DynamicObject
    
    #dim tArray As %DynamicArray
    #dim tContent As %DynamicObject
    #dim tI As %Integer
    #dim tArg As %String
    #dim tResult As %String
    
    Try {
        
        Set tSC=##class(%Atelier.v2.Utils.Macros).ParseMacroRequest(.tRequest,.tArg)
        If tSC='$$$OK {
            #; A bad %response, but not an "error"
            Set tSC=$$$OK
            Quit
        }
        If $$$ISERR(tSC) Quit
        
        #; Get the macro list
        Set tResult=$$GetMacroList^%qccServer(tArg,tRequest.hash,tRequest.cursor)

        If 'tResult {
            #; DecomposeStatus^%apiOBJ(status,.errorlist)
            #; Quit $$$FAILURE_$g(errorlist(1))
            Set tMsgArray = [ ($Extract(tResult,3,*)) ]
            Set tSC=$$$ERROR($$$GeneralError,"Utility failed")
            Quit
        }
        
        #; Build the response
        Set tContent = { "hash": ($Piece($Extract(tResult,3,*),":",1)),
                         "cursor": ($Piece(tResult,":",2)) }
        Set tResult=$Piece(tResult,":",3), tArray = []
        For tI=1:1:$Length(tResult,",") Do tArray.%Set(tI-1,$Piece(tResult,",",tI))
        Set tContent.macros=tArray
        Set tResPart = { "content": (tContent) }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
        
    Quit ..RenderResponseBody(tSC,.tMsgArray,.tResPart)
}

/// Input request:
/// <pre>
/// {
///   "docname": "MyClass.cls",
///   "macroname": "mymac",
///   "superclasses": ["class1",...],
///   "includes": ["include1",...],
///   "includegenerators": ["generator1",...],
///   "imports": ["package1",...],
///   "mode": "generator" or ""
/// }
/// </pre>
/// Returned content:
/// <pre>
/// {
///   "status": { "errors": [],  "summary": "" },
///   "console": [],
///   "result": {
///     "content": {
///       "signature": "(arg1,arg2)"
///     }
///   }
/// }
/// </pre>
/// 
ClassMethod GetMacroSignature(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException  
    #dim tMsgArray as %DynamicArray
    #dim tRequest As %DynamicObject
    #dim tResPart As %DynamicObject
    
    #dim tContent As %DynamicObject
    #dim tI As %Integer
    #dim tArg,tDocName As %String
    #dim tResult As %String
    
    Try {
        
        Set tSC=##class(%Atelier.v2.Utils.Macros).ParseMacroRequest(.tRequest,.tArg)
        If tSC='$$$OK {
            #; A bad %response, but not an "error"
            Set tSC=$$$OK
            Quit
        }
        If $$$ISERR(tSC) Quit
        
        #; Get the macro signature
        Set tResult=$$GetMacroSignature^%qccServer(tArg,tRequest.macroname)

        If 'tResult {
            #; DecomposeStatus^%apiOBJ(status,.errorlist)
            #; Quit $$$FAILURE_$g(errorlist(1))
            Set tMsgArray = [ ($Extract(tResult,3,*)) ]
            Set tSC=$$$ERROR($$$GeneralError,"Utility failed")
            Quit
        }
        
        #; Build the response
        Set tContent = { "signature": ($Extract(tResult,3,*)) }
        Set tResPart = { "content": (tContent) }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
        
    Quit ..RenderResponseBody(tSC,.tMsgArray,.tResPart)
}

/// Input request:
/// <pre>
/// {
///   "docname": "MyClass.cls",
///   "macroname": "mymac",
///   "superclasses": ["class1",...],
///   "includes": ["include1",...],
///   "includegenerators": ["generator1",...],
///   "imports": ["package1",...],
///   "mode": "generator" or ""
/// }
/// </pre>
/// Returned content:
/// <pre>
/// {
///   "status": { "errors": [],  "summary": "" },
///   "console": [],
///   "result": {
///     "content": {
///       "document": "name.inc",
///       "line": lineno
///     }
///   }
/// }
/// </pre>
/// 
ClassMethod GetMacroLocation(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException  
    #dim tMsgArray as %DynamicArray
    #dim tRequest As %DynamicObject
    #dim tResPart As %DynamicObject
    
    #dim tContent As %DynamicObject
    #dim tI As %Integer
    #dim tArg,tDocName As %String
    #dim tResult As %String
    
    Try {
        
        Set tSC=##class(%Atelier.v2.Utils.Macros).ParseMacroRequest(.tRequest,.tArg)
        If tSC='$$$OK {
            #; A bad %response, but not an "error"
            Set tSC=$$$OK
            Quit
        }
        If $$$ISERR(tSC) Quit
        
        #; Get the macro location
        Set tResult=$$GetMacroLocation^%qccServer(tArg,tRequest.macroname)

        If 'tResult {
            #; DecomposeStatus^%apiOBJ(status,.errorlist)
            #; Quit $$$FAILURE_$g(errorlist(1))
            Set tMsgArray = [ ($Extract(tResult,3,*)) ]
            Set tSC=$$$ERROR($$$GeneralError,"Utility failed")
            Quit
        }
        
        #; Build the response
        Set tI=$Find(tResult,"(")
        If tI {
            Set tContent = { "document": ($Extract(tResult,3,tI-2)), "line": (+$Extract(tResult,tI,*)) }
        } Else {
            Set tContent = { "document": ($Extract(tResult,3,*)), "line":"" }
        }
        Set tResPart = { "content": (tContent) }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
        
    Quit ..RenderResponseBody(tSC,.tMsgArray,.tResPart)
}

/// Input request:
/// <pre>
/// {
///   "docname": "MyClass.cls",
///   "macroname": "mymac",
///   "superclasses": ["class1",...],
///   "includes": ["include1",...],
///   "includegenerators": ["generator1",...],
///   "imports": ["package1",...],
///   "mode": "generator" or ""
/// }
/// </pre>
/// Returned content:
/// <pre>
/// {
///   "status": { "errors": [],  "summary": "" },
///   "console": [],
///   "result": {
///     "content": {
///       "definition": ["line1","line2",...]
///     }
///   }
/// }
/// </pre>
/// 
ClassMethod GetMacroDefinition(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException  
    #dim tMsgArray as %DynamicArray
    #dim tRequest As %DynamicObject
    #dim tResPart As %DynamicObject
    
    #dim tArray As %DynamicArray
    #dim tContent As %DynamicObject
    #dim tI As %Integer
    #dim tArg,tDocName As %String
    #dim tResult As %String
    
    Try {
        
        Set tSC=##class(%Atelier.v2.Utils.Macros).ParseMacroRequest(.tRequest,.tArg)
        If tSC='$$$OK {
            #; A bad %response, but not an "error"
            Set tSC=$$$OK
            Quit
        }
        If $$$ISERR(tSC) Quit
        
        #; Get the macro definition
        Set tResult=$$GetMacroDefinition^%qccServer(tArg,tRequest.macroname)

        If 'tResult {
            #; DecomposeStatus^%apiOBJ(status,.errorlist)
            #; Quit $$$FAILURE_$g(errorlist(1))
            Set tMsgArray = [ ($Extract(tResult,3,*)) ]
            Set tSC=$$$ERROR($$$GeneralError,"Utility failed")
            Quit
        }
        
        #; Build the response
        Set tResult=$Extract(tResult,3,*), tArray = []
        If tResult'="" For tI=1:1:$Length(tResult,$C(13,10)) Do tArray.%Set(tI-1,$Piece(tResult,$C(13,10),tI))
        Set tContent = { "definition": (tArray) }
        Set tResPart = { "content": (tContent) }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
        
    Quit ..RenderResponseBody(tSC,.tMsgArray,.tResPart)
}

/// Input request:
/// <pre>
/// {
///   "docname": "MyClass.cls",
///   "macroname": "mymac",
///   "arguments": "(arg1,arg2,...)",
///   "superclasses": ["class1",...],
///   "includes": ["include1",...],
///   "includegenerators": ["generator1",...],
///   "imports": ["package1",...],
///   "mode": "generator" or ""
/// }
/// </pre>
/// Returned content:
/// <pre>
/// {
///   "status": { "errors": [],  "summary": "" },
///   "console": [],
///   "result": {
///     "content": {
///       "expansion": ["line1","line2",...]
///     }
///   }
/// }
/// </pre>
/// 
ClassMethod GetMacroExpansion(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException  
    #dim tMsgArray as %DynamicArray
    #dim tRequest As %DynamicObject
    #dim tResPart As %DynamicObject
    
    #dim tArray As %DynamicArray
    #dim tContent As %DynamicObject
    #dim tI As %Integer
    #dim tArg,tDocName As %String
    #dim tResult As %String
    
    Try {
        
        Set tSC=##class(%Atelier.v2.Utils.Macros).ParseMacroRequest(.tRequest,.tArg)
        If tSC='$$$OK {
            #; A bad %response, but not an "error"
            Set tSC=$$$OK
            Quit
        }
        If $$$ISERR(tSC) Quit
        
        #; Get the macro expansion
        Set tResult=$$GetMacroExpansion^%qccServer(tArg,tRequest.macroname,tRequest.arguments)

        If 'tResult {
            #; DecomposeStatus^%apiOBJ(status,.errorlist)
            #; Quit $$$FAILURE_$g(errorlist(1))
            Set tMsgArray = [ ($Extract(tResult,3,*)) ]
            Set tSC=$$$ERROR($$$GeneralError,"Utility failed")
            Quit
        }
        
        #; Build the response
        Set tResult=$Extract(tResult,3,*), tArray = []
        If tResult'="" For tI=1:1:$Length(tResult,$C(13,10)) Do tArray.%Set(tI-1,$Piece(tResult,$C(13,10),tI))
        Set tContent = { "expansion": (tArray) }
        Set tResPart = { "content": (tContent) }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
        
    Quit ..RenderResponseBody(tSC,.tMsgArray,.tResPart)
}

/// This method searches a set of documents using a Regular Expression or a text string.<br>
/// <br>HTTP Codes returned:-
/// <br>
/// <br>HTTP 200 if request is OK
/// <br>HTTP 400 if there are missing arguments
/// <br><br>
/// Input request:
/// <pre>
/// GET localhost:57772/api/atelier/v2/:namespace/action/search?query=expr&documents=list&sys=1&gen=1&amp;regex=1&max=200
/// </pre>
/// Required arguments are:<br>
/// query = the search expression, a regular expression or a plain text string<br>
/// documents = a comma-separated list of documents or masks with the * wild card<br>
/// <br>
/// Optional arguments are:<br>
/// regex = 0 or 1 (default 1) whether the query string is a regular expression or not<br>
/// sys = 0 or 1 (default 0) include sytem documents in the search<br>
/// gen = 0 or 1 (default 0) include generated documents in the search<br>
/// max = nnn (default 200) maxinum number of results to return<br>
/// <br>
/// The result is returned as the console output of the search and as a JSON array.<br>
/// <br>
/// Example input to search for the word Email in all classes and MAC routines:
/// <pre>
/// GET localhost:57772/api/atelier/v2/SAMPLES/action/search?query=.*\bEmail\b.*&documents=*.cls,*.mac
/// </pre>
/// Returned content (some is omitted here):
/// <pre>
/// {
///   "status": { "errors": [],  "summary": "" },
///   "console": [
///     "",
///     "Searching for '.*\\bEmail\\b.*' in '*.cls,*.mac'",
///     "Cinema.Utils.cls(SendEmail+28): Quit \"Email confirmation has been sent to \" _ Addr",
///     "Wasabi.Data.Employee.cls(Email)[Type]: Wasabi.Common.DT.Email",
///     "Wasabi.Data.Employee.cls(CopyFrom+26): set ..Email = employee.Email",
///     "ZAUTHENTICATE.mac(175): Properties(\"EmailAddress\") - Email address",
///     "Found 11 occurrence/s in 7 file/s."
///   ],
///   "result": [
///     {
///       "doc": "Cinema.Utils.cls",
///       "matches": [
///         {
///          "member": "SendEmail",
///          "line": 28,
///          "text": "Quit \"Email confirmation has been sent to \" _ Addr"
///         }
///       ]
///     },
///     {
///       "doc": "Wasabi.Data.Employee.cls",
///       "matches": [
///         {
///          "member": "Email",
///          "attr": "Type",
///          "text": "Wasabi.Common.DT.Email"
///         },
///         {
///          "member": "CopyFrom",
///          "line": 26,
///          "text": "set ..Email = employee.Email"
///         }
///       ]
///     },
///     {
///       "doc": "ZAUTHENTICATE.mac",
///       "matches": [
///         {
///          "line": "175",
///          "text": "Properties(\"EmailAddress\") - Email address"
///         }
///       ]
///     }
///   ]
/// }
ClassMethod Search(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tMsgArray,tResult As %DynamicArray
    #dim docobj,matobj As %DynamicObject
    #dim docmatarr As %DynamicArray
    #dim tCookie,tContent As %String
    #dim tSearch As %String
    
    Set tMsgArray = []
    
    Try {
     
        Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
        If $$$ISERR(tSC) Quit
        
        Set tSearch=%request.Get("query")
        If tSearch="" {
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }
        
        Set doclist=%request.Get("documents")
        
        If doclist="" Set doclist=%request.Get("files") ; temporary
        
        If doclist="" {
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }
        
        Set system=+%request.Get("sys")
        Set generated=+%request.Get("gen")
        Set isRegex=%request.Get("regex")
        Set:isRegex="" isRegex=1
        Set max=%request.Get("max")
        Set:max="" max=200
        Set wholeword=+%request.Get("word")
        Set casesensitive=%request.Get("case")
        Set:casesensitive="" casesensitive=1
        Set wildcards=+%request.Get("wild")
        
        If isRegex {
            
            Set tSC=##class(%Studio.Project).FindInFilesRegex(
                tSearch,
                doclist,
                system,
                generated,
                max
            )
            
        } Else {
            
            Set tSC=##class(%Studio.Project).FindInFiles(
                tSearch,
                doclist,
                system,
                wholeword,
                casesensitive,
                max,
                "",
                wildcards,
                generated
            )
            
        }

    } Catch (e) {
        Set tSC=e.AsStatus()
    }

    #; MUST close the redirect whatever happens
    If $Data(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
    
    #; If no success at this point, quit
    If $$$ISERR(tSC) Quit ..RenderResponseBody(tSC,tMsgArray)
    
    #; Parse the console output into the JSON result
    Try {
        
        Set tResult=[],odoc="",docobj="",docmatarr=[]
        For tI=2:1:tMsgArray.%Size()-2 {
            Set line=tMsgArray.%Get(tI)
            Set p1=$Find(line,"(")
            If 'p1 {
                Set p1=$Find(line,":")
                If p1<3 Continue ; Very strange
                #; Must be a match on routine name
                Set doc=$Extract(line,1,p1-2)
                #; Mark name as line 0
                Set $Extract(line,p1-1)="(0):"
            } Else {
                Set doc=$Piece(line,"(")
            }
            If doc'=odoc {
                If docobj'="" {
                    Do docobj.%Set("matches",docmatarr)
                    Do tResult.%Push(docobj)
                }
                Set docobj={"doc":(doc)}, docmatarr=[]
                Set odoc=doc
            }
            Set p2=$Find(line,")",p1)
            Set loc=$Extract(line,p1,p2-2)
            If loc=+loc {
                #; Just a line number, must be a routine
                If loc=0 {
                    #; If match on the name, report no line at all
                    Set matobj={}
                } Else {
                    Set matobj={"line":(loc)}
                }
                Set p2=$Find(line,":")
            } Else {
                If loc'="" {
                    Set p1=$Find(loc,"+")
                    Set matobj={"member":($Piece(loc,"+"))}
                    If p1 Do matobj.%Set("line",(+$Extract(loc,p1,*)))
                } Else {
                    Set matobj={}
                }
                Set p1=$Find(line,"["),p2=$Find(line,":")
                If p1,p1<p2 {
                    Set attr=$Extract(line,p1,$Find(line,"]",p1)-2)
                    Set p1=$Find(attr,"+")
                    If p1 {
                        Set loc=$Extract(attr,p1,*),attr=$Extract(attr,1,p1-2)
                    } Else {
                        Set loc=$Select(attr="Description":1,1:"")
                    }
                    Do matobj.%Set("attr",(attr))
                    If loc'="" Do matobj.%Set("attrline",(+loc))
                } ElseIf 'p1,loc="" {
                    #; Neither location nor attribute, must be just the name
                    Do matobj.%Set("attr","Name")
                }
            }
            Do matobj.%Set("text",($Extract(line,p2+1,*)))
            Do docmatarr.%Push(matobj)
        }
        If docobj'="" {
            Do docobj.%Set("matches",docmatarr)
            Do tResult.%Push(docobj)
        }

    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit ..RenderResponseBody(tSC,tMsgArray,tResult)
}

/// This method returns the textual definition of a Studio Assist Schema.
/// Pass the url of the schema namespace to retrieve the definition.<br>
/// If the definition does not exist an HTTP 404 Not Found will be returned.<br>
/// If the definition does exist but needs to be recalculated, HTTP 202 Acepted will be returned and the location
/// header will point to the url which should be called in the future to retrieve the value.<br>
/// If the definition checksum matches the value passed in the IF_NONE_MATCH header, an
/// HTTP 304 Not Modified will be returned.<br>
/// If the definition is up to date it will be returned as an array of lines in the result and
/// the ETAG header will be set with the current checksum.
/// <br><br>
/// Input request:
/// <pre>
/// GET localhost:57772/api/atelier/v2/%SYS/saschema/http://www.intersystems.com/urlmap
/// </pre>
/// 
/// Returned content:
/// <pre>
/// {
///   "status": { "errors": [],  "summary": "" },
///   "console": [],
///   "result": [...]
/// }
/// </pre>
/// 
ClassMethod GetSASchemaDefinition(pNamespace As %String, pUrl As %String) As %Status [ Internal ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tMsgArray,tResult As %DynamicObject
    #dim tCookie,tContent,tLine,tSchema,tSchemaChunk,tUrl As %String
    #dim tReload As %Boolean
    #dim tI,tJ As %Integer
    
    Set tMsgArray = [], tResult= []
        
    Try {
        #; Must have a non-null schema url
        if pUrl="" {
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }

        Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
        If $$$ISERR(tSC) Quit

        #; Check to see if schema actually exists
        Set tSC=##class(%Studio.SASchemaUtil).getSchemaMoniker(pUrl)
        If $$$ISERR(tSC) {
            #; Check if doesn't exist
            If $Piece($System.Status.GetErrorCodes(tSC),",")=6311 {
                Set %response.Status=..#HTTP404NOTFOUND,tSC=$$$OK
            }
            Quit
        }
       
        #; Need to check if has schema or should come back later
        Set tSC=##class(%Studio.SASchemaUtil).getSchemaDefinition(pUrl,.tSchema)
        If $$$ISERR(tSC) Quit
        
        If '$Data(tSchema) {
            
            #; Doesn't exist just yet, but maybe later
 
            #; Set the location to get results from
            Do %response.SetHeader("Location",%request.URL)
            
            #; Refer to named item
            Set %response.Status=..#HTTP202ACCEPTED
            
            Quit
        }
        
        Set tClientCheckSum=$Get(%request.CgiEnvs("HTTP_IF_NONE_MATCH"))
        
        #; For each 'chunk'
        For tI=1:1:tSchema {
            
            #; Get the a chunk and strip CR
            Set tSchemaChunk=$Translate(tSchema(tI),$Char(13))
            
            #; For each line (delimited by NL)
            For tJ=1:1:$Length(tSchemaChunk,$Char(10)) {
                
                #; Get the line
                Set tLine=$Piece(tSchemaChunk,$Char(10),tJ)
                
                #; Only add to the result if it's not a blank line
                If tLine'="" {
                   
                    #; Check CheckSum
                    If $Piece(tLine,":")="!checksum" {
                       
                        Set tServerCheckSum=$Piece(tLine,":",2)
                       
                        If (tServerCheckSum'="")&&(tClientCheckSum=tServerCheckSum) {
                            Set %response.Status=..#HTTP304NOTMODIFIED,tResult=[]
                            Quit
                        } else {
                             Do %response.SetHeader("ETag",tServerCheckSum)
                        }
                    }
                    Do tResult.%Push(tLine)
                }
            }
        }

    } Catch (e) {
        Set tSC=e.AsStatus()
    }

    #; MUST close the redirect whatever happens
    If $Data(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
    
    Quit ..RenderResponseBody(tSC,tMsgArray,tResult)
}

}
