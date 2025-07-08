/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %Atelier

/// This class provides a lazy rendering of the modified documents in a database.
/// It is tightly tied to the execution style of the GetModified api.
Class %Atelier.v1.Utils.LazyModifiedDb Extends %RegisteredObject
{

Property Args As %String;

Method %OnNew(pGbl As %String, pDB As %String, pHash As %String, pCrHash As %String) As %Status
{
    Set ..Args=$ListBuild(pGbl,pDB,pHash,pCrHash)
    Quit $$$OK
}

Method %ToJSON(Output outstr) As %String
{
    #dim tGbl,tDb,tType,tName As %String
    
    If $Quit || $Data(outstr) {
        #; Should never happen. We can't handle it.
        throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Invalid $toJSON usage"))
    }
    
    Write "{"
    Write """dbname"":"""_$List(..Args,2)_""","
    Write """dbhash"":"""_$List(..Args,3)_""","
    Write """crhash"":"""_$List(..Args,4)_""","
    Write """dbsys"":"_$$$jsonIsSysDB($List(..Args,2))_","
    Write """docs"":["
    
    #; Walk the documents in this db
    Set tGbl=$List(..Args,1)
    Set tDb=$List(..Args,2)
    
    Set tType="" For {
        Set tType=$Order(@tGbl@(tDb,tType)) If tType="" Quit
        
        Set tName="" For {
            Set tName=$Order(@tGbl@(tDb,tType,tName)) If tName="" Quit
            
            If $Data(tDoc) {
                #; Not the first one
                Write ","
            }
            Set tDoc = {}
            
            #; Fill in the details
            Set tDoc.name=tName_"."_tType
            Set tDoc.ts=@tGbl@(tDb,tType,tName,"ts")
            Do tDoc.%Set("gen",@tGbl@(tDb,tType,tName,"gen"),"boolean")
            Do tDoc.%Set("depl",@tGbl@(tDb,tType,tName,"depl"),"boolean")
            
            #; Write it
            Do tDoc.%ToJSON()
        }
    }
    
    Write "]}"
}

}
