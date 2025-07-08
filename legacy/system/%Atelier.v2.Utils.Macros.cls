/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Methods for handling macro information
Class %Atelier.v2.Utils.Macros Extends %Atelier.REST
{

/// Process the request arguments
/// Input is the %request object
ClassMethod ParseMacroRequest(Output pContent As %DynamicObject, Output pMacArg As %String) As %Status
{
    #dim tSC as %Status = $$$OK
    #dim tDocName as %String
    
    Try {
        
        #; Ensure we are only passed json
        If %request.ContentType'="application/json" {
            Set tSC='$$$OK
            Set %response.Status=..#HTTP415UNSUPPORTEDMEDIATYPE
            Quit
        }
        
        If '$IsObject(%request.Content) {
            Set tSC=$$$ERROR($$$PostedDataNoContent)
            Set %response.Status=..#HTTP400BADREQUEST
            Quit    
        }
        
        Set tSC=%request.Content.Rewind()
        If $$$ISERR(tSC) Quit
        
        Try {
            Set pContent=##class(%DynamicObject).%FromJSON(%request.Content)
        } Catch (e) {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set %response.Status=..#HTTP400BADREQUEST
        }
        If $$$ISERR(tSC) Quit

        If 'pContent.%IsA("%DynamicObject") {
            Set tSC=$$$ERROR($$$InvalidJSONContent)
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }

        #; Validate document name
        Set tDocName=pContent.docname
        If ##class(%Atelier.v1.Utils.General).ValidateDocName(tDocName,.tSC) = 0 {
            Set tSC='$$$OK
            Set %response.Status=..#HTTP400BADREQUEST
            Quit
        }
        
        #; Normalize
        Set tDocName=##class(%Atelier.v1.Utils.General).NormalizeDocName(tDocName)
        
        #; The macro api does not require the document to exist
        
        #; Build the argument list from the request
        Set pMacArg=..FormatMacroArgs(pContent,tDocName)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// Format arguments for the utility request
ClassMethod FormatMacroArgs(pRequest As %DynamicObject, pDocName As %String) As %String [ Internal ]
{
    #dim tArray As %DynamicArray
    #dim tI As %Integer
    #dim tInc,tIncGen,tSuper,tImport As %String
    
    #; The underlying api fails if a named include file does not exist, but the
    #; client doesn't know if it exists or not, and doesn't want to care. So we
    #; screen out any named include files that do not exist on the server.
    
    Set tInc=""
    Set tArray=pRequest.includes
    If $IsObject(tArray),tArray.%IsA("%DynamicArray") {
        For tI=0:1:tArray.%Size()-1 {
            Set incName=tArray.%Get(tI)
            If ##class(%Atelier.v1.Utils.General).ExistsDoc(incName_".INC") {
                Set tInc=tInc_tArray.%Get(tI)_","
            }
        }
        Set tInc=$Extract(tInc,1,*-1)
    }
    
    Set tIncGen=""
    Set tArray=pRequest.includegenerators
    If $IsObject(tArray),tArray.%IsA("%DynamicArray") {
        For tI=0:1:tArray.%Size()-1 {
            Set tIncGen=tIncGen_tArray.%Get(tI)_","
        }
        Set tIncGen=$Extract(tIncGen,1,*-1)
    }
    
    Set tSuper=""
    Set tArray=pRequest.superclasses
    If $IsObject(tArray),tArray.%IsA("%DynamicArray") {
        For tI=0:1:tArray.%Size()-1 {
            Set tSuper=tSuper_tArray.%Get(tI)_","
        }
        Set tSuper=$Extract(tSuper,1,*-1)
    }
    
    Set tImport=""
    Set tArray=pRequest.imports
    If $IsObject(tArray),tArray.%IsA("%DynamicArray") {
        For tI=0:1:tArray.%Size()-1 {
            Set tImport=tImport_tArray.%Get(tI)_","
        }
        Set tImport=$Extract(tImport,1,*-1)
    }
    
    Quit tSuper_":"_tInc_":"_tIncGen_":"_tImport_":"_pRequest.mode_":"_pDocName
}

}
