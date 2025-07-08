/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides a lazy rendering of a document. For performance reasons, it's best to
/// render one document at a time.
Class %Atelier.v1.Utils.LazyDocument Extends %RegisteredObject
{

Property Args As %String;

Method %OnNew(pName As %String, pDB As %String, pTS As %String, pSC As %Status, pCat As %String, pBinary As %Boolean, pUpToDate As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
    Set ..Args=$ListBuild(pName,pDB,pTS,pSC,pCat,pBinary,pUpToDate)
    Quit $$$OK
}

Method %ToJSON(Output outstr) As %String
{
    #dim tSC As %Status
    #dim e As %Exception.AbstractException
    
    #dim tCount,tI As %Integer
    #dim tBinary As %Boolean
    #dim tCookie,tSub,tType,tName,tKeywords,tHeader As %String
    #dim tDocArray As %String
    #dim tMsgArray As %DynamicArray = []
    #dim tContent As %DynamicObject
    #dim tDoc As %DynamicObject = {}
    
    #; Fill in the name, database, timestamp and type
    Set tDoc.name=$List(..Args,1), tDoc.db=$List(..Args,2)
    Set tDoc.ts=$List(..Args,3)
    If $List(..Args,7)'="" Do tDoc.%Set("upd",+$List(..Args,7),"boolean")
    Set tDoc.cat=$List(..Args,5)
    Set tBinary=$List(..Args,6)
    
    #; Fill in the status according to error status
    Set tSC=$List(..Args,4)
    Set tDoc.status=$Select($$$ISERR(tSC):$System.Status.GetOneErrorText(tSC),1:"")
    Do tDoc.%Set("enc",0,"boolean") Set tDoc.content=""

    If tDoc.status="" {
            
        #; Load is deferred until render time
        Try {
            
            #; Capture output (mainly for SAMPLES .TST example code)
            Set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)
            If $$$ISERR(tSC) Quit
            
            #; May be temporary routine source from CvtXmlToClientDoc
            If (tDoc.cat = "RTN" && $Data(^||%oddDEF("#"_$zcvt($Piece(tDoc.name,".",*),"U"),$Piece(tDoc.name,".",1,*-1)))) {
                
                Set tName=$Piece(tDoc.name,".",1,*-1),tType=$zcvt($Piece(tDoc.name,".",*),"U")
                Set tSub="#"_tType
                Set tHeader="ROUTINE "_tName,tKeywords=""
                If tType'="MAC" Set tKeywords=tKeywords_",Type="_tType
                If $Get(^||%oddDEF(tSub,tName,0,"LANG"),0)>0 {
                    Set tKeywords=tKeywords_",LanguageMode="_^||%oddDEF(tSub,tName,0,"LANG")
                }
                If $Get(^||%oddDEF(tSub,tName,0,"GEN")) {
                    Set tKeywords=tKeywords_",Generated"
                }
                If tKeywords'="" Set tHeader=tHeader_" ["_$Extract(tKeywords,2,*)_"]"
                
                Set tContent = []
                Do tContent.%Push(tHeader)
                For tI=1:1:^||%oddDEF(tSub,tName,0,0) {
                    Do tContent.%Push(^||%oddDEF(tSub,tName,0,tI))
                }
                
            } Else {
            
                #; Load the array from the document source
                Set tSC=##class(%Atelier.v1.Utils.TextServices).GetTextAsArray(tDoc.name,0,.tDocArray,tBinary)
                If $$$ISERR(tSC) Quit
                
                If $Get(tDocArray("bin")) {
                    Do tDoc.%Set("enc",1,"boolean")
                } Else {
                    Do tDoc.%Set("enc",0,"boolean")
                }
                Set tContent = []
                For tI=1:1:+$Get(tDocArray(0)) {
                    Do tContent.%Push(tDocArray(tI))
                }
            }
            
            Set tDoc.content=tContent
                            
        } Catch (e) {
            Set tSC=e.AsStatus()
        }
        
        #; MUST close the redirect whatever happens
        Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.tMsgArray)
   
        #; Record the console output
        Set tDoc.console=tMsgArray
        
        If $$$ISERR(tSC) {
            Set tDoc.status=$System.Status.GetErrorText(tSC)
        }
    }

    If $Quit {
        Quit tDoc.%ToJSON(.outstr)
    } Else {
        Do tDoc.%ToJSON(.outstr)
    }
}

}
