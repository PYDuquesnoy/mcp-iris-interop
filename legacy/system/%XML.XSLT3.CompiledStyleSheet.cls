/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implements an interface to the XSLT3 CompiledStyleSheet. %XML.XSLT3.CompiledStyleSheet should never be
/// created directly with %New(), but via the CreateFromFile() or CreateFromStream() factory methods
Class %XML.XSLT3.CompiledStyleSheet Extends %RegisteredObject
{

Property ReleaseOnClose As %Boolean [ InitialExpression = 1 ];

/// Use this method a create an instance of an %XML.XSLT3.CompiledStyleSheet from a file path name
ClassMethod CreateFromFile(source As %String, Output compiledStyleSheet As %XML.XSLT3.CompiledStyleSheet, errorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Try {
		Kill compiledStyleSheet Set compiledStyleSheet=$$$NULLOREF
		Set status=##class(%XML.XSLT3.Transformer).SetupErrorHandler(.errorHandler)
		Quit:$$$ISERR(status)
		
		// Parse the source
		Set compiledStyleSheet=##class(%XML.XSLT3.CompiledStyleSheet).%New()
		Set compiledStyleSheet.ReleaseOnClose = '$Isobject(gateway)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).CompileXSLT3File(source,compiledStyleSheet,errorHandler,gateway)
	} Catch exception {
		Set status=$$$ERROR($$$XSLTError,exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
	}
	Use currentDevice
	Quit status
}

/// Use this method to create an instance of an %XML.XSLT3.CompiledStyleSheet from a binary stream
ClassMethod CreateFromStream(stream As %Stream.Object, Output compiledStyleSheet As %XML.XSLT3.CompiledStyleSheet, errorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, XSLBaseDir As %String = "") As %Status
{
	#dim currentDevice As %String = $IO
	Try {
		
		Set status=##class(%XML.XSLT3.Transformer).SetupErrorHandler(.errorHandler)
		Quit:$$$ISERR(status)
		
		
		Kill compiledStyleSheet Set compiledStyleSheet=$$$NULLOREF
		Set compiledStyleSheet=##class(%XML.XSLT3.CompiledStyleSheet).%New()
		Set compiledStyleSheet.ReleaseOnClose = '$Isobject(gateway)
		
		// Parse the source
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).CompileXSLT3XSLStream(stream,compiledStyleSheet,errorHandler,gateway,XSLBaseDir) 
 		Kill %objlasterror 		
	} Catch exception {
		Set status=$$$ERROR($$$XSLTError,exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
	}
	Use currentDevice
	Quit status
}

ClassMethod ReleaseFromServer(compiledStyleSheet As %XML.XSLT3.CompiledStyleSheet, errorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Try {
		Set status=##class(%XML.XSLT3.Transformer).SetupErrorHandler(.errorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).ReleaseCompiledXSLT3(compiledStyleSheet,errorHandler,gateway)
	} Catch exception {
		Set status=$$$ERROR($$$XSLTError,exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
	}
	Use currentDevice
	Quit status
}

Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{

 	Quit:..ReleaseOnClose ..ReleaseFromServer(##this)
}

}
