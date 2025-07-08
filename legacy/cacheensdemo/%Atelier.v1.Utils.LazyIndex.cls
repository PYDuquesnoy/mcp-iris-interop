/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides a lazy rendering of a document. For performance reasons, it's best to
/// render one document at a time.
Class %Atelier.v1.Utils.LazyIndex Extends %RegisteredObject
{

Property Args As %String;

Method %OnNew(pName As %String, pDB As %String, pTS As %String, pSC As %Status, pCat As %String, pGen As %String, pOth As %String, pUpToDate As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
    #; Just stash these for rendering later
    Set i%Args=$ListBuild(pName,pDB,pTS,pSC,pCat,pGen,pOth,pUpToDate)
    Quit $$$OK
}

Method %ToJSON(Output outstr) As %String
{
    #dim tSC,tDocStatus As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim result,tOthers As %String
    #dim tI As %Integer
    #dim tDoc As %DynamicObject = {}
    #dim tIndex As %DynamicObject
    
    Try {
        
        #; Name, DB, TS, GEN
        Set tDoc.name=$List(..Args,1),tDoc.db=$List(..Args,2)
        Set tDoc.ts=$List(..Args,3)
        If $List(..Args,8)'="" Do tDoc.%Set("upd",+$List(..Args,8),"boolean")
        Set tDoc.cat=$List(..Args,5)
        Do tDoc.%Set("gen",+$List(..Args,6),"boolean")
        
        #; Add the list of others
        Set tDoc.others = []
        Set tOthers=$List(..Args,7)
        If tOthers'="" {
            For tI=1:1:$Length(tOthers,",") Do tDoc.others.%Push($Piece(tOthers,",",tI))
        }
       
        Set tDoc.status=""
        Set tDoc.content={}
        
        #; Test the document status
        Set tDocStatus=$List(..Args,4)
        
        #; If an error is already indicated
        If $$$ISERR(tDocStatus) {
            
            #; Just report it
            Set tDoc.status=$System.Status.GetOneErrorText(tDocStatus)
            
        } else {
            
            #; Otherwise, perform the index
            Set tSC=##class(%Atelier.v1.Utils.Indexer).Index(tDoc.name,tDoc.cat,.tIndex)
            If $$$ISERR(tSC) Set tDoc.status=$System.Status.GetOneErrorText(tSC)
            Set tDoc.content=tIndex
        }
        
        #; Do the Render
        If $Quit {
            Set result=tDoc.%ToJSON(.outstr)
        } Else {
            Do tDoc.%ToJSON(.outstr)
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    If $Quit Quit $Get(result)
}

}
