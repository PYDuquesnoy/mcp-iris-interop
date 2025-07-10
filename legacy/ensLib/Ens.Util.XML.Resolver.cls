/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Util.XML.Resolver Extends %XML.SAX.EntityResolver [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This records the ids of any entities that this resolver attempts to resolve
Property Entities As array Of %String;

/// This copies the entities to an output variable
Method GetEntities(Output pEntities As %String)
{
	Set tI=..Entities.Next(""),tCount=0
	while (tI'="") {
		Set tCount=tCount+1,pEntities(tCount)=tI
		Set tI=..Entities.Next(tI)
	}
	Set pEntities=tCount
}

Method resolveEntity(pPublicID As %String, pSystemID As %String) As %Library.Integer
{
	Set $ZT="Trap",tSC=$$$OK,tRet=$$$NULLOREF
	do {
		#; Pick out public or system ID
		If pPublicID]"" {
			Set tID=pPublicID
		} Else {  
 			Set tID=pSystemID
 		}
 	
 		#; Record the entity identifier
 		Do ..Entities.SetAt("",tID)
 		
 		#; Load the entity stream from the repository
 		Set tSC=##class(Ens.Util.XML.Entity).LoadEntity(tID,.tEntity)
 		If $$$ISERR(tSC) Quit
 		
 		Set tRet=tEntity.Stream
 		If '$IsObject(tRet) Quit
 
 		#; Wrap the returned stream
 		Set tRet=##class(%XML.SAX.StreamAdapter).%New(tRet)
 		If '$IsObject(tRet) Set tSC=%objlasterror Quit
 		
	} while (0)
Exit
	Quit tRet
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
