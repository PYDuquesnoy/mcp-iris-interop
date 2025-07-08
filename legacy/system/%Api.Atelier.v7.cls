/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %Api.Atelier.v7 provides version 7 APIs for Atelier
Class %Api.Atelier.v7 Extends %Api.Atelier.v6
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

</Routes>
}

ClassMethod RunTerminal() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
   
    Try {
        
        Do ##class(%Library.Device).ReDirectIO(0)
        
        Set tSC = ##class(%Atelier.v7.TerminalAgent).Page(0)
       
    } Catch (e) {
        Set tSC = e.AsStatus()
    }
    Quit tSC
}

/// This method gets the text of one or more documents in a single legacy XML file.
/// <br/>
/// <br/>The method expects a content body to be encoded in JSON and contain an
/// <br/>array of items (document names) to be exported. Note that items may also 
/// <br/>use ? or * wild cards and if you wish to exclude items pass ' before the item name:
/// <pre>
/// [ "User.Test.cls", "abc*.mac" ]
/// </pre>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 200 if OK
/// <br/>HTTP 400 if the posted content is empty or not valid json
/// <br/>HTTP 415 if content type is not application/json
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// <br/>
/// <br/>Returned content is an array of lines of the legacy XML file:
/// <br/>
/// <pre>
/// {
///   "status": {
///     "errors": [],
///     "summary": ""
///   },
///   "console": [],
///   "result": {
///     "content": [
///       "&lt;?xml version="1.0" encoding="UTF-8"?&gt;",
///       ...
///     ]
///   }
/// }
/// </pre>
ClassMethod ExportToXMLFile(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tExportArray As %DynamicArray
    #dim tIter As %Iterator.Array
    #dim tXmlArray As %DynamicArray = []
    #dim tMsgArray As %DynamicArray = []

    Try {
        #; Ensure we are only passed json
        If %request.ContentType '= "application/json" {  
            Set %response.Status = ..#HTTP415UNSUPPORTEDMEDIATYPE
            Quit
        }
            
        If '$ISOBJECT(%request.Content) {
            Set tSC = $$$ERROR($$$PostedDataNoContent)
            Set %response.Status = ..#HTTP400BADREQUEST
            Quit
        }

        #; Parse the content (JSON array)
        Try {
            Set tExportArray = ##class(%DynamicArray).%FromJSON(%request.Content)
        } Catch (e) {
            Set tSC = $$$ERROR($$$InvalidJSONContent)
            Set %response.Status = ..#HTTP400BADREQUEST
        }
        If $$$ISERR(tSC) Quit

        If 'tExportArray.%IsA("%DynamicArray") {
            Set tSC = $$$ERROR($$$InvalidJSONContent)
            Set %response.Status = ..#HTTP400BADREQUEST
            Quit
        }

        Try {
            #; Capture output
            Set tSC = ##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
            If $$$ISERR(tSC) Quit

            #; Build the list of items to export
            Set tIter = tExportArray.%GetIterator()
            While tIter.%GetNext(,.tDocName) {
                Set tItems(tDocName) = ""
            }

            #; Export to a stream
            Set tStrm = ##class(%Stream.TmpCharacter).%New()
            Set tSC = $SYSTEM.OBJ.ExportToStream(.tItems,.tStrm)
            If $$$ISERR(tSC) Quit

            #; Convert the stream into a %DynamicArray of lines
            Set tSC = tStrm.Rewind()
            If $$$ISERR(tSC) Quit
            While 'tStrm.AtEnd {
                Set tLine = tStrm.ReadLine(,.tSC)
                If $$$ISERR(tSC) Quit
                Do tXmlArray.%Push(tLine)
            }
        } Catch (e) {
            Set tSC = e.AsStatus()
        }

        #; MUST close the redirect whatever happens
        If $DATA(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)

        #; NOW check error status
        If $$$ISERR(tSC) Set tXmlArray = []
    } Catch (e) {
        Set tSC = e.AsStatus()
    }

    #; Render the response body
    Set tContent = {}, tContent.content = tXmlArray
    Quit ..RenderResponseBody(tSC,tMsgArray,tContent)
}

/// This method loads and optionally compiles the selected documents within legacy XML files.
/// <br/>
/// <br/>The method expects a content body to be encoded in JSON and contain an
/// array of objects, one for each XML file. Each object must contain a string to identify the file 
/// (for example, its filesystem path) and a content array containing the lines of the file.
/// An array of specific documents to import may be provided. If omitted, all documents in the XML file are imported:
/// <pre>
/// [
///   {
///     "file": "/path/to/file.xml",
///     "content": [
///       "&lt;?xml version="1.0" encoding="UTF-8"?&gt;",
///       ...
///     ],
///     "selected": [
///       "User.Test.cls"
///     ]
///   }
/// [
/// </pre>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 200 if OK
/// <br/>HTTP 400 if the posted content is empty or not valid json
/// <br/>HTTP 415 if content type is not application/json
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// <br/>
/// <br/>The URL parameter ?flags=&lt;string&gt; can be passed to modify the load 
/// <br/>behavior. The list of supported flags or qualifiers can be displayed with 
/// <br/>'Do $system.OBJ.ShowQualifiers()' and 'Do $system.OBJ.ShowFlags()'.
/// <br/>
/// <br/>Return content is an array of objects, one per XML file. Each object contains 
/// the identifier of the XML file, an array containing the names of all documents 
/// from that file that were successfully imported, and a status string if an error occurred while importing it:
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
///         "file": "/path/to/file.xml",
///         "status": "",
///         "imported": [
///           "User.Test.cls"
///         ]
///       }
///     ]
///   }
/// }
/// </pre>
/// NOTE: If you are experiencing timeouts using this method, consider calling
/// method Load() in class <CLASS>%SYSTEM.OBJ</CLASS> from a terminal instead.
ClassMethod LoadXMLFiles(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tImportArray As %DynamicArray
    #dim tIter, tContentIter, tSelectedIter As %Iterator.Array
    #dim tResultArray As %DynamicArray = []
    #dim tMsgArray As %DynamicArray = []

    Try {
        #; Ensure we are only passed json
        If %request.ContentType '= "application/json" {  
            Set %response.Status = ..#HTTP415UNSUPPORTEDMEDIATYPE
            Quit
        }
            
        If '$ISOBJECT(%request.Content) {
            Set tSC = $$$ERROR($$$PostedDataNoContent)
            Set %response.Status = ..#HTTP400BADREQUEST
            Quit
        }

        #; Parse the content (JSON array)
        Try {
            Set tImportArray = ##class(%DynamicArray).%FromJSON(%request.Content)
        } Catch (e) {
            Set tSC = $$$ERROR($$$InvalidJSONContent)
            Set %response.Status = ..#HTTP400BADREQUEST
        }
        If $$$ISERR(tSC) Quit

        If 'tImportArray.%IsA("%DynamicArray") {
            Set tSC = $$$ERROR($$$InvalidJSONContent)
            Set %response.Status = ..#HTTP400BADREQUEST
            Quit
        }

        #; Get the compile flags
        Set tFlags = $GET(%request.Data("flags",1))

        Try {
            #; Capture output
            Set tSC = ##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
            If $$$ISERR(tSC) Quit

            #; For each document in the array
            Set tIter = tImportArray.%GetIterator()
            While tIter.%GetNext(,.tXmlDoc) {
                #; Initialize the result object
                Set tDocObj = {}
                Try {
                    Set tDocObj.file = tXmlDoc.file, tDocObj.imported = [], tDocObj.status = ""
                    #; Convert the line array into a stream
                    Set tStrm = ##class(%Stream.TmpCharacter).%New(), tStrm.LineTerminator = $CHAR(10), tContentIter = tXmlDoc.content.%GetIterator()
                    While tContentIter.%GetNext(,.tLine) {
                        Set tSC = tStrm.WriteLine(tLine)
                        If $$$ISERR(tSC) Quit
                    }
                    If $$$ISERR(tSC) Quit

                    #; Process the list of selected documents (if provided)
                    Set tSelectedArray = tXmlDoc.%Get("selected",[]), tSelectedIter = tSelectedArray.%GetIterator()
                    While tSelectedIter.%GetNext(,.tSelectedDoc) {
                        Set tSelectedList(tSelectedDoc) = ""
                    }

                    #; Perform the load
                    Set tSC = $SYSTEM.OBJ.LoadStream(tStrm,tFlags,,.tImportedList,,.tSelectedList,tXmlDoc.file)

                    #; Fill in the imported array
                    Set tDoc = $ORDER(tImportedList(""))
                    While tDoc '= "" {
                        Do tDocObj.imported.%Push(tDoc)
                        Set tDoc = $ORDER(tImportedList(tDoc))
                    }
                } Catch (e) {
                    Set tSC = e.AsStatus()
                }
                If $$$ISERR(tSC) {
                    #; Report the error
                    Set tDocObj.status = $SYSTEM.Status.GetErrorText(tSC)
                    #; Reset for the next document
                    Set tSC = $$$OK
                }
                Do tResultArray.%Push(tDocObj)
                Kill tImportedList, tSelectedList
            }
        } Catch (e) {
            Set tSC = e.AsStatus()
        }

        #; MUST close the redirect whatever happens
        If $DATA(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
    } Catch (e) {
        Set tSC = e.AsStatus()
    }

    #; Render the response body
    Set tContent = {}, tContent.content = tResultArray
    Quit ..RenderResponseBody(tSC,tMsgArray,tContent)
}

/// This method gets the names and timestamps of documents contained in legacy XML files.
/// <br/>
/// <br/>The method expects a content body to be encoded in JSON and contain an
/// array of objects, one for each XML file. Each object must contain a string to identify the file 
/// (for example, its filesystem path) and a content array containing the lines of the file:
/// <pre>
/// [
///   {
///     "file": "/path/to/file.xml",
///     "content": [
///       "&lt;?xml version="1.0" encoding="UTF-8"?&gt;",
///       ...
///     ]
///   }
/// [
/// </pre>
/// <br/>HTTP Codes returned:-
/// <br/>
/// <br/>HTTP 200 if OK
/// <br/>HTTP 400 if the posted content is empty or not valid json
/// <br/>HTTP 415 if content type is not application/json
/// <br/>HTTP 500 if an error occurs (details will be in status error array)
/// <br/>
/// <br/>Return content is an array of objects, one per XML file. Each object contains 
/// the identifier of the XML file, an array containing the names and timestamps of the 
/// documents, and a status string if an error occurred while processing it:
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
///         "file": "/path/to/file.xml",
///         "status": "",
///         "documents": [
///           {
///             "name": "User.Test.cls",
///             "ts": "2016-01-04 14:00:04.000"
///           }
///         ]
///       }
///     ]
///   }
/// }
/// </pre>
/// NOTE: If you are experiencing timeouts using this method, consider calling
/// method Load() in class <CLASS>%SYSTEM.OBJ</CLASS> from a terminal instead.
ClassMethod ListDocumentsInXMLFiles(pNamespace As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tAnalyzeArray As %DynamicArray
    #dim tIter, tContentIter As %Iterator.Array
    #dim tResultArray As %DynamicArray = []
    #dim tMsgArray As %DynamicArray = []

    Try {
        #; Ensure we are only passed json
        If %request.ContentType '= "application/json" {  
            Set %response.Status = ..#HTTP415UNSUPPORTEDMEDIATYPE
            Quit
        }
            
        If '$ISOBJECT(%request.Content) {
            Set tSC = $$$ERROR($$$PostedDataNoContent)
            Set %response.Status = ..#HTTP400BADREQUEST
            Quit
        }

        #; Parse the content (JSON array)
        Try {
            Set tAnalyzeArray = ##class(%DynamicArray).%FromJSON(%request.Content)
        } Catch (e) {
            Set tSC = $$$ERROR($$$InvalidJSONContent)
            Set %response.Status = ..#HTTP400BADREQUEST
        }
        If $$$ISERR(tSC) Quit

        If 'tAnalyzeArray.%IsA("%DynamicArray") {
            Set tSC = $$$ERROR($$$InvalidJSONContent)
            Set %response.Status = ..#HTTP400BADREQUEST
            Quit
        }

        Try {
            #; Capture output
            Set tSC = ##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
            If $$$ISERR(tSC) Quit

            #; For each document in the array
            Set tIter = tAnalyzeArray.%GetIterator()
            While tIter.%GetNext(,.tXmlDoc) {
                #; Initialize the result object
                Set tDocObj = {}, tDocObj.file = tXmlDoc.file, tDocObj.documents = [], tDocObj.status = ""
                Try {
                    #; Convert the line array into a stream
                    Set tStrm = ##class(%Stream.TmpCharacter).%New(), tStrm.LineTerminator = $CHAR(10), tContentIter = tXmlDoc.content.%GetIterator()
                    While tContentIter.%GetNext(,.tLine) {
                        Set tSC = tStrm.WriteLine(tLine)
                        If $$$ISERR(tSC) Quit
                    }
                    If $$$ISERR(tSC) Quit

                    #; Get the list of documents
                    Set tSC = $SYSTEM.OBJ.LoadStream(tStrm,"/nodisplay",,.tDocList,1)
                    If $$$ISERR(tSC) Quit

                    #; Get the timestamps for the documents
                    Set tDoc = $ORDER(tDocList(""))
                    While tDoc '= "" {
                        Do tDocObj.documents.%Push({
                            "name": (tDoc),
                            "ts": (##class(%RoutineMgr).GetDate(tDoc))
                        })
                        Set tDoc = $ORDER(tDocList(tDoc))
                    }
                } Catch (e) {
                    Set tSC = e.AsStatus()
                }
                If $$$ISERR(tSC) {
                    #; Report the error
                    Set tDocObj.documents = [], tDocObj.status = $SYSTEM.Status.GetErrorText(tSC)
                    #; Reset for the next document
                    Set tSC = $$$OK
                }
                Do tResultArray.%Push(tDocObj)
                Kill tDocList
            }
        } Catch (e) {
            Set tSC = e.AsStatus()
        }

        #; MUST close the redirect whatever happens
        If $DATA(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
    } Catch (e) {
        Set tSC = e.AsStatus()
    }

    #; Render the response body
    Set tContent = {}, tContent.content = tResultArray
    Quit ..RenderResponseBody(tSC,tMsgArray,tContent)
}

}
