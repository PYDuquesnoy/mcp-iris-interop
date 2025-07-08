/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides a SAX Entity resolver for a named class. Use this class when you want to define a 
/// named entity (typically an XML Schema) in an XDATA block.
Class %XML.SAX.XDataEntityResolver Extends %XML.SAX.EntityResolver [ System = 3 ]
{

/// This holds the name of the class in which to resove XDATA blocks
Property TargetClassName As %String [ Private, ReadOnly ];

/// This is the method used by the SAX parser to actually resolve the entity
Method resolveEntity(pPublicID As %String, pSystemID As %String) As %Library.Integer
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tStream As %Stream.TmpCharacter = $$$NULLOREF
	#dim tID As %String

	Try {
		
		#; Pick out public or system ID
		If pPublicID]"" {
			Set tID=pPublicID
		} Else {  
 			Set tID=pSystemID
 		}
 		
 		#; Load the entity stream from the repository
 		Set tSC=..EntityFromXDATA(.tStream,..TargetClassName,tID)
 		If $$$ISERR(tSC) Quit
 		
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	
	If tStream'=$$$NULLOREF {
		
		#; Create a Stream Adapter
 		Set tStream=##class(%XML.SAX.StreamAdapter).%New(tStream)
 		If '$IsObject(tStream) Set tSC=%objlasterror
 		
	}
	Quit tStream
}

/// This is a helper method which will retrieve a named XDATA block from the named class
ClassMethod EntityFromXDATA(Output pStream As %BinaryStream, pClassName As %String, pXDATAName As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tClass As %Dictionary.ClassDefinition
	#dim tIndex As %Integer
	
	Try {
		
		#; Open up the class definition for the named class
		Set tClass=##class(%Dictionary.ClassDefinition).%OpenId(pClassName,0,.tSC)
		If $$$ISERR(tSC) Quit

		#; Attempt to find the named XDATA block
		Set pStream=$$$NULLOREF		
		Set tIndex = tClass.XDatas.FindObjectId(pClassName_"||"_pXDATAName)
		If tIndex'="" {
			
			#; Get XDATA as stream
			Set pStream = tClass.XDatas.GetAt(tIndex).Data
			
			#; Found it
			If $IsObject(pStream) Quit
		}
		
		#; If not found in ClassDefinition, try in CompiledClass		
		Set tClass=##class(%Dictionary.CompiledClass).%OpenId(pClassName,0,.tSC)
		If $$$ISERR(tSC) Quit
		
		Set tIndex = tClass.XDatas.FindObjectId(pClassName_"||"_pXDATAName)
		If tIndex'="" {
			
			#; Get XDATA as stream
			Set pStream = tClass.XDatas.GetAt(tIndex).Data
			
			#; Found it
			If $IsObject(pStream) Quit
		}
		
		Set tSC=$$$ERROR($$$XDataBlockMissing,pClassName,pXDATAName)
		
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set i%TargetClassName=initvalue
	Quit $$$OK
}

}
