/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Atelier.v1.Utils.DocumentStreamAdapter Extends %RegisteredObject
{

Property Document As %ZEN.proxyObject;

/// This method  renders the document as a JSON object containing these fields :-
/// {
/// 	"content":"<?xml version=\"1.0\" ...",
/// 	"db":"USER",
/// 	"name":"User.Example.cls",
/// 	"status":"",
/// 	"ts":"2015-01-28 13:50:00.000",
/// 	"type":"CLS"
/// }}
/// 
/// content: Contains the content of the document. If an error has occurred, will be the empty string
/// db: This is the database from which the document was derived (from namespace mappings)
/// name: This is the name of the document
/// status: This contains the error status for this particular document only
/// ts: This is the server timestamp normalized to 3 decimal places
/// type: This is the type of the item. 
Method %ToJSON(pLevel As %Integer = 0, pFormat As %String = "aelotws") As %Status
{
    Quit ..Document.%ToJSON(pLevel,pFormat)
}

Method %OnNew(pStream As %Stream = {$$$NULLOREF}, pName As %String, pDocStatus As %String, pTimeStamp As %String) As %Status [ Private, ServerOnly = 1 ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tCount,tI As %Integer
	#dim tDatabase,tTimeStamp
	
	Try {

	    Set ..Document=##class(%ZEN.proxyObject).%New()

		#; fill in the documents name
	    Set ..Document.name=pName
	    
	    #; and type
	    Set ..Document.type=$ZCVT($Piece(pName,".",*),"U")
	    
	    If $$$ISOK(pDocStatus) {
	
		    Set ..Document.status=""
		    
	    	#; Get the database
			Set tDatabase=""
			Set tSC=##class(%Atelier.v1.Utils.General).GetDbForDoc(pName,.tDatabase)
			If $$$ISERR(tSC) Quit
				
			Set ..Document.db=tDatabase
				
			#; Set the timestamp
			Set ..Document.ts=pTimeStamp
			
			#; Finally the content
	   		Set ..Document.content=pStream
	   		
	    } else {
		    
		    Set ..Document.db="",..Document.ts="",..Document.content=""
		  	
		    #; And error
		    Set ..Document.status=$System.Status.GetErrorText(pDocStatus)
	    }
	  	
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
        
	Quit tSC
}

}
