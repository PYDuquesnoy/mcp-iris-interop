/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a custom response format and serves as the basis for all
/// Atelier REST APIs
Class %Atelier.REST Extends %CSP.REST
{

/// %Atelier.REST classes are unlikely to actually define messages with $$$Text
/// %Utility seems like a catch-all, and should have all languages defined,
/// so the %session/%response language can be set properly.
Parameter DOMAIN = "%Utility";

/// Use our special format Http500 handler
ClassMethod Http500(pE As %Exception.AbstractException) As %Status
{
    #; Set up for an HTTP status
    Set %response.Status=..#HTTP500INTERNALSERVERERROR
    
    #; We want to render a response if we can
    Do ..RenderResponseBody(pE.AsStatus())
        
    Quit $$$OK
}

/// User our special format handler for other status codes
ClassMethod ReportHttpStatusCode(pHttpStatus, pSC As %Status = {$$$OK}) As %Status
{
    Set %response.Status=pHttpStatus
    
    Do ..RenderResponseBody(pSC)
        
    Quit $$$OK
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
ClassMethod ServeDoc(pDocName As %String, pStatus As %Status, pMsgArray As %DynamicArray, ByRef pResArray As %String, pTimeStamp As %String = "", pUpToDate As %Boolean, pExtensionContent As %DynamicObject) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    #dim tI As %Integer
    
    #dim tHash,tDatabase As %String = ""
    #dim tResPart As %DynamicObject
    
    Try {
    
        If '$Data(pTimeStamp) {
            
            #; Normalize output name
            Set $Piece(pDocName,".",*)=$zcvt($Piece(pDocName,".",*),"l")
            
            #; Get the latest timestamp for hash
            Set tHash=##class(%Atelier.v1.Utils.General).TS(pDocName)
            
        } else {
            
            Set tHash=pTimeStamp
        }
        
        #; Set the header
        Do ..SetClientServerHash(tHash)
         
        #; Result part
        Set tSC=##class(%Atelier.v1.Utils.General).CreateDocumentObject(.tResPart,.pResArray,pDocName,pStatus,pTimeStamp,.pUpToDate)
        If $$$ISERR(tSC) Quit
        
        If $IsObject($Get(pExtensionContent)) {
	        Set tResPart.ext = pExtensionContent
        }
        
        #; Render the response body
        Set tSC=..RenderResponseBody($$$OK,pMsgArray,tResPart)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// This private helper method server wraps the message and document and returns it to the caller
ClassMethod ServeXml(pDocName As %String, pStatus As %Status, pMsgArray As %DynamicArray, pStream As %Stream, pTimeStamp As %String = "") As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    #dim tI As %Integer
    
    #dim tHash As %String   
  
    Try {
                
        #; Normalize output name
        Set $Piece(pDocName,".",*)=$zcvt($Piece(pDocName,".",*),"l")
        
        #; Get the latest timestamp for hash
        Set tHash=##class(%Atelier.v1.Utils.General).TS(pDocName)
        
        #; Set the header
        Do ..SetClientServerHash(tHash)
        
        #; Result part
        Kill %objlasterror
        Set tResPart=##class(%Atelier.v1.Utils.DocumentStreamAdapter).%New(pStream,pDocName,pStatus,pTimeStamp)
        If '$IsObject(tResPart) Set tSC=%objlasterror Quit
        
        #; Render the response body
        Set tSC=..RenderResponseBody($$$OK,pMsgArray,tResPart)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// Render the three-part Response Body which contains an status, console, and a result part
ClassMethod RenderResponseBody(pStatus As %Status, pMsgPart As %DynamicArray, pResPart As %DynamicObject) As %Status
{
    
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tStatusPart As %DynamicObject
    
    Try {
        
        #; Defaults
        If '$IsObject($Get(pMsgPart)) Set pMsgPart = []
        If '$IsObject($Get(pResPart)) Set pResPart = {}
            
        #; Create the part for the error
        Set tSC = ..StatusToJSON(pStatus,.tStatusPart)
        If $$$ISERR(tSC) Quit
        
        Write "{""status"":"
        
        Do tStatusPart.%ToJSON()
                
        Write ",""console"":"
        
        Do pMsgPart.%ToJSON()
        
        Write ",""result"":"
        
        If pResPart.%IsA("%Atelier.v1.Utils.DocumentStreamAdapter") {
            Set tSC=pResPart.%ToJSON()
        } Else {
            Do pResPart.%ToJSON()
        }
        
        Write "}"
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Sets the response's localization domain (something that %CSP.REST should do, in theory) and then invokes default super class behavior
ClassMethod Page(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 0 ]
{
    #dim %response As %CSP.Response
    Set %response.Domain = ..#DOMAIN
    Quit ##super(skipheader)
}

}
