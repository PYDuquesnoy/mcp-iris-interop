/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occSAX)

Class Ens.Util.XML.Extractor [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This method is takes the file/path of an XML file to be processed and a dictionary of element 'paths'.
/// An element path consists of a list of element names seperated by the '/' character e.g A/B/C. The 'path'
/// specifies the element for which the value is to be extracted. The XML is examined for matches on the 
/// specified element paths. When a match is made the value of the element is extracted and recorded in the
/// pValues array. Set the pTrace parameter to display the 'path' hierarchy found in the document 
/// If the Method returns $$$OK then the XML was processed successfully.
ClassMethod ExtractFile(pTargetFile As %String, pElements As %String, Output pValues As %String, pTrace As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Initially there are NO extracted values
		Kill pValues Set pValues=0

		#; Read specified file, but do not validate
		Set tReader=$$$NULLOREF,tSC=##class(%XML.TextReader).ParseFile(pTargetFile,.tReader,,$$$SAXNOVALIDATION)  Quit:$$$ISERR(tSC)

		#; If the Reader object has not been created then return 
		If tReader=$$$NULLOREF { Set tSC=$$$ERROR($$$FailedToCreateClass,"%XML.TextReader") Quit }

		Set tSC=..Extract(tReader,.pElements,.pValues,.tErrors,pTrace)
	
	} while (0)
	
	For tI=1:1:$Get(tErrors) {
		Set tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrXMLValidation,tErrors(tI)))
	}
Exit 
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method is takes a stream of XML  to be processed and a dictionary of element 'paths'.
/// An element path consists of a list of element names seperated by the '/' character e.g A/B/C. The 'path'
/// specifies the element for which the value is to be extracted. The XML is examined for matches on the 
/// specified element paths. When a match is made the value of the element is extracted and recorded in the
/// pValues array. Set the pTrace parameter to display the 'path' hierarchy found in the document 
/// If the Method returns $$$OK then the XML was processed successfully.
ClassMethod ExtractStream(pTargetStream As %BinaryStream, pResolver As Ens.Util.XML.Resolver, pElements As %String, Output pValues As %String, pTrace As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Initially there are NO extracted values
		Kill pValues Set pValues=0

		#; Read specified file, but do not validate
		Set tReader=$$$NULLOREF,tSC=##class(%XML.TextReader).ParseStream(pTargetStream,.tReader,pResolver,$$$SAXNOVALIDATION)  Quit:$$$ISERR(tSC)

		#; If the Reader object has not been created then return 
		If tReader=$$$NULLOREF { Set tSC=$$$ERROR($$$FailedToCreateClass,"%XML.TextReader")	Quit }

		Set tSC=..Extract(tReader,.pElements,.pValues,.tErrors,pTrace)
		
	} while (0)
	
	For tI=1:1:$Get(tErrors) {
		Set tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrXMLValidation,tErrors(tI)))
	}
Exit 
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod Extract(pReader As %XML.TextReader, pElements As %String, Output pValues As %String, Output pErrors As %String, pTrace As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Now walk the file and extract the elements
		While(pReader.Read()) {
			
			If ((pReader.NodeType="error")||(pReader.NodeType="fatalerror")) {

				#; Record the error information
				Set pErrors($Increment(pErrors))=pReader.NodeType_" - "_pReader.Value
				
			} elseif pReader.NodeType="element" {
				
				#; Walk the list of 'paths' and perform matching and extraction
				Set tPath=$Order(pElements(""))
				While (tPath'="") {

					#; If Traces is on, display the current path
					If pTrace=1 {
						Write !,pReader.Path
					}
					
					If pReader.Path = tPath {
						
						#; Found a match, move to the content	
						if (pReader.Read() = 0) {
							Set tSC=$$$ERROR($$$EnsErrNoElementContent)
							Set pErrors($Increment(pErrors))=$$$StatusText(tSC)
							Quit
						}
						Set tResult=pReader.MoveToContent()
						If (tResult=0) {
							Set tSC=$$$ERROR($$$EnsErrNoElementContent)
							Set pErrors($Increment(pErrors))=$$$StatusText(tSC)
							Quit
						}

						#; Record the value						
						Set pValues(tPath,$Increment(pValues(tPath)))=pReader.Value
										
					}
					Set tPath=$Order(pElements(tPath))
				}
			}
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
