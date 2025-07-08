/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%assert, %callout)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.XSLT.CompiledStyleSheet">Performing XSLT Transformations</a>.</p>
/// Implements an interface to the XSLT CompiledStyleSheet. %XML.XSLT.CompiledStyleSheet should never be
/// created directly with %New(), but via the CreateFromFile() or CreateFromStream() factory methods
Class %XML.XSLT.CompiledStyleSheet Extends %RegisteredObject [ System = 3 ]
{

/// This property holds a handle to the parsed source
Property ParsedSourceHandle As %Integer;

/// Use this method a create an instance of an %XML.XSLT.CompiledStyleSheet from a file path name.
ClassMethod CreateFromFile(pSource As %String, Output pCompiledStyleSheet As %XML.XSLT.CompiledStyleSheet, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,tHandle=-1
	do {
		#; Initialize the output
		Kill pCompiledStyleSheet Set pCompiledStyleSheet=$$$NULLOREF
		
		If '$IsObject(pErrorHandler) {
			
			#; If one has not been supplied, create an instance of an error handler
			Kill %objlasterror
			Set pErrorHandler=##class(%XML.XSLT.ErrorHandler).%New()
			If '$IsObject(pErrorHandler) {
				Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.XSLT.ErrorHandler"))
				Quit
			}
		} else {
			#; Ensure the the supplied error handler is a subclass of %XML.XSLT.ErrorHandler
			If pErrorHandler.%Extends("%XML.XSLT.ErrorHandler")=0 {
				Set tSC=$$$ERROR($$$InvalidErrorHandler)
				Quit
			}
		}
		
		#; Parse the source
		Set tRetVal=$ZF(-6,$$$XSLTLibrary,7,$ListBuild($$$objOrefToInt(pErrorHandler),pSource))
		
		#; Test for error condition
 		If $List(tRetVal,1)'=0 Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2)) Quit
 		
 		#; Retrieve source handle
 		Set tHandle=$List(tRetVal,2)
 		
 		#; Create an instance of this class
 		Set pCompiledStyleSheet=##class(%XML.XSLT.CompiledStyleSheet).%New(tHandle)
 		If '$IsObject(pCompiledStyleSheet) {
	 		
	 		#; Failed, report error
	 		Set tSC=%objlasterror
	 			
	 		#; Release compiled stylesheet
	 		If $ZF(-6,$$$XSLTLibrary,9,$ListBuild(tHandle))
 		}
 		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Use this method to create an instance of an %XML.XSLT.CompiledStyleSheet from a binary stream
ClassMethod CreateFromStream(pStream As %AbstractStream, Output pCompiledStyleSheet As %XML.XSLT.CompiledStyleSheet, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,tHandle=-1
	do {
		
		#; Create a Stream Adapter
 		Set tStream=##class(%XML.SAX.StreamAdapter).%New(pStream)
 		If '$IsObject(tStream) Set tSC=%objlasterror Quit
 		
		#; Initialize the output
		Kill pCompiledStyleSheet Set pCompiledStyleSheet=$$$NULLOREF
		
		If '$IsObject(pErrorHandler) {
			
			#; If one has not been supplied, create an instance of an error handler
			Kill %objlasterror
			Set pErrorHandler=##class(%XML.XSLT.ErrorHandler).%New()
			If '$IsObject(pErrorHandler) {
				Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.XSLT.ErrorHandler"))
				Quit
			}
		} else {
			#; Ensure the the supplied error handler is a subclass of %XML.XSLT.ErrorHandler
			If pErrorHandler.%Extends("%XML.XSLT.ErrorHandler")=0 {
				Set tSC=$$$ERROR($$$InvalidErrorHandler)
				Quit
			}
		}
		
		#; Parse the source
		Set tRetVal=$ZF(-6,$$$XSLTLibrary,8,$ListBuild($$$objOrefToInt(pErrorHandler),$$$objOrefToInt(tStream)))
		
		#; Test for error condition
 		If $List(tRetVal,1)'=0 Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2)) Quit
 		
 		#; Retrieve source handle
 		Set tHandle=$List(tRetVal,2)
 		
 		#; Create an instance of this class
 		Kill %objlasterror
 		Set pCompiledStyleSheet=##class(%XML.XSLT.CompiledStyleSheet).%New(tHandle)
 		If '$IsObject(pCompiledStyleSheet) {
	 		
	 		#; Failed, report error
	 		Set tSC=%objlasterror
	 
	 		#; Release parsed source
	 		If $ZF(-6,$$$XSLTLibrary,9,$ListBuild(tHandle))
 		}
 		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// For this class, client code should NOT call this method directly via %New()
/// but should use the 'CreateFromFile()' or 'CreateFromStream()' factory methods
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	If $Get(initvalue)="" Quit $$$ERROR($$$UseFactoryMethods)
	
	#; Retain the handle for the parsed source
	Set ..ParsedSourceHandle=initvalue
	Quit $$$OK
}

Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
	Set $ZT="Trap",tSC=$$$OK
	
	do {
		
		Set tRetVal=$ZF(-6,$$$XSLTLibrary,9,$ListBuild(..ParsedSourceHandle))
		
		#; Test for error condition
 		If $List(tRetVal,1)'=0 Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2))
 		
	} while(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This accesses the parsed source handle which xalan uses to identify the previously
/// parsed source document
Method ParsedSourceHandleGet()
{
	Quit i%ParsedSourceHandle
}

}
