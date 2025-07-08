/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %External.language

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.XSLT2.Transformer">Performing XSLT Transformations</a>.</p>
/// Implements an interface to the XSLT 2.0 Parser. XML contained in a file 
/// or binary stream may be transformed
Class %XML.XSLT2.Transformer Extends %RegisteredObject
{

/// This method starts a gateway if there's not already one started, connects to it, and returns the gateway by reference.
/// This method does not change the current device.
ClassMethod StartGateway(Output gateway As %Net.Remote.Gateway = {$$$NULLOREF}, useSharedMemoryIfPossible As %Boolean = 0) As %Status
{
	set status = $$$OK
	try {
		set gateway = $system.external.getXSLTGateway()
	} catch ex {
		set status = ex.AsStatus()
	}
	quit status
}

/// This method disconnects from the gateway.
/// It does not stop the gateway.
ClassMethod StopGateway(gateway As %Net.Remote.Gateway) As %Status
{
	set status = $$$OK
	try {
		set status = gateway.%Disconnect()
	} catch ex {
		set status = ex.AsStatus()
	}
	quit status
}

/// This method transforms a source file according to an XSL stylesheet and writes the output
/// to the specified output file. If errors occur during processing, callbacks will be made to
/// the supplied error handler. If an error handler is not supplied then the default is to use
/// a newly created instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
ClassMethod TransformFile(pSource As %String, pXSL As %String, pOutput As %String, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status = $$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Set paramList=..BuildParams(.pParams)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status = ##class(%Net.Remote.Java.XSLTGateway).TransformFileFile(pSource,pXSL,pOutput,pErrorHandler,pCallbackHandler,paramList,pResolver,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method transforms a source file according to an XSL stylesheet and writes the output
/// to the specified output file. If errors occur during processing, callbacks will be made to
/// the supplied error handler. If an error handler is not supplied then the default is to use
/// a newly created instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
ClassMethod TransformFileWithCompiledXSL(pSource As %String, pXSL As %XML.XSLT2.CompiledStyleSheet, pOutput As %String, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status = $$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Set paramList=..BuildParams(.pParams)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status = ##class(%Net.Remote.Java.XSLTGateway).TransformFileCompiled(pSource,pXSL,pOutput,pErrorHandler,pCallbackHandler,paramList,pResolver,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method transforms a source stream according to an XSL stylesheet and writes the output
/// to the supplied binary stream. If errors occur during processing, callbacks will be made to the 
/// supplied error handler. If an error handler is not supplied then the default is to use a newly created 
/// instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
/// Note that that the XSLT transform engine will produce a stream with line terminator $c(10),
/// regardless of the line terminator of the input stream.
/// If an existing output stream is passed to this method, its LineTerminator property will be set to $c(10),
/// so anything written to the stream before calling this method should also use $c(10) as its line terminator.
ClassMethod TransformStream(pSource As %Stream.Object, pXSL As %Stream.Object, ByRef pOutput As %BinaryStream = {$$$NULLOREF}, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		
		// For certain output streams we must manipulate the translate table
		Set translateTable=""
		Set status=..SetupOutput(.pOutput,.translateTable)
		Quit:$$$ISERR(status)

		Set paramList=..BuildParams(.pParams)
		
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).TransformStream(pSource,pXSL,pOutput,pErrorHandler,pCallbackHandler,paramList,pResolver,gateway)
		
		// Restore the translation table if necessary
		If translateTable'="" Set pOutput.TranslateTable=translateTable
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method transforms a source stream according to an XSL stylesheet and writes the output
/// to the supplied binary stream. If errors occur during processing, callbacks will be made to the 
/// supplied error handler. If an error handler is not supplied then the default is to use a newly created 
/// instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
/// Note that that the XSLT transform engine will produce a stream with line terminator $c(10),
/// regardless of the line terminator of the input stream.
/// If an existing output stream is passed to this method, its LineTerminator property will be set to $c(10),
/// so anything written to the stream before calling this method should also use $c(10) as its line terminator.
ClassMethod TransformStreamWithCompiledXSL(pSource As %Stream.Object, pXSL As %XML.XSLT2.CompiledStyleSheet, ByRef pOutput As %BinaryStream = {$$$NULLOREF}, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
				
		// For certain output streams we must manipulate the translate table
		Set translateTable=""
		Set status=..SetupOutput(.pOutput,.translateTable)
		Quit:$$$ISERR(status)
		
		Set paramList=..BuildParams(.pParams)
		
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).TransformStream(pSource,pXSL,pOutput,pErrorHandler,pCallbackHandler,paramList,pResolver,gateway)
		
		// Restore the translation table if necessary
		If translateTable'="" Set pOutput.TranslateTable=translateTable
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method transforms a source string according to an XSL stylesheet and returns the output
/// to the supplied string. If errors occur during processing, callbacks will be made to the 
/// supplied error handler. If an error handler is not supplied then the default is to use a newly created 
/// instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
ClassMethod TransformStringWithCompiledXSL(pSource As %String, pXSL As %XML.XSLT2.CompiledStyleSheet, ByRef pOutput As %String = "", pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Set paramList=..BuildParams(.pParams)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).TransformStringCompiled(pSource,pXSL,.pOutput,pErrorHandler,pCallbackHandler,paramList,pResolver,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

ClassMethod BuildParams(ByRef pParams) As %List [ Private ]
{
	#dim tParamList As %List
	#dim tKey As %String
	Set (tParamList,tKey) = ""
	Set isArrayObj = ($Isobject(pParams) && pParams.%Extends("%Library.ArrayOfDataTypes"))
	For {
		If isArrayObj {
			Set tValue = pParams.GetNext(.tKey)
			Quit:tKey=""
		} Else {
			Set tKey=$Order(pParams(tKey)) If tKey="" Quit
			Set tValue=$Get(pParams(tKey))
		}
		Set:tValue="" tValue = $c(0)
		Set tParamList=tParamList_$ListBuild(tKey,tValue)
	}
	Quit tParamList
}

ClassMethod SetupErrorHandler(ByRef errorHandler As %XML.XSLT.ErrorHandler) As %Status
{
	Set status=$$$OK
	If '$IsObject(errorHandler) {
		// If one has not been supplied, create an instance of an error handler
		Kill %objlasterror
		Set errorHandler=##class(%XML.XSLT.ErrorHandler).%New()
		If '$IsObject(errorHandler) {
			Set status=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.XSLT.ErrorHandler"))
		}
	} Else {
		// Ensure the the supplied error handler is a subclass of %XML.XSLT.ErrorHandler
		If errorHandler.%Extends("%XML.XSLT.ErrorHandler")=0 {
			Set status=$$$ERROR($$$InvalidErrorHandler)
		}
	}
	Quit status
}

ClassMethod SetupOutput(ByRef output As %BinaryStream, Output translateTable As %ObjectHandle) As %Status
{
	Set status=$$$OK
	If '$IsObject(output) {
		// If an output stream has not been supplied, create an instance of a global binary stream
		// and use that instead
		Kill %objlasterror
		Set output=##class(%Stream.GlobalBinary).%New()
		If '$IsObject(output) {
			Set status=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Stream.GlobalBinary"))
			Quit
		}	
	} else {
		// Special case for %FileCharacterStream
		If output.%IsA("%FileCharacterStream") {
			Set translateTable=output.TranslateTable,output.TranslateTable="RAW"
		}
	}
		
	// XML parser will always change all line endings into a single line feed character
	// https://www.w3.org/TR/REC-xml/#sec-line-ends
	Set output.LineTerminator = $c(10)

	Quit status
}

/// This method clears the evaluate cache.
/// If errors occur during processing, callbacks will be made to the supplied error handler.
/// If an error handler is not supplied then the default is to use a newly created instance of %XML.XSLT.ErrorHandler.
ClassMethod ClearEvaluateCache(pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).ClearEvaluateCache(pErrorHandler,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method sets the maximum size of the evaluate cache. The default size is 1000.
/// If errors occur during processing, callbacks will be made to the supplied error handler.
/// If an error handler is not supplied then the default is to use a newly created instance of %XML.XSLT.ErrorHandler.
ClassMethod SetEvaluateCacheSize(size As %Integer = 1000, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).SetEvaluateCacheSize(size,pErrorHandler,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method adds a function name to the evaluate cache filter list.
/// Note that this does not limit the cache size in any way. There may be any number of calls
/// to the same function, but with different arguments and return values. Each combination
/// of function name + arguments would be a separate entry in the cache.
/// If errors occur during processing, callbacks will be made to the supplied error handler.
/// If an error handler is not supplied then the default is to use a newly created instance of %XML.XSLT.ErrorHandler.
ClassMethod AddToEvaluateCacheFilterList(filterListEntry As %String = "", pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).AddToEvaluateCacheFilterList(filterListEntry,pErrorHandler,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method removes a function name from the evaluate cache filter list.
/// If errors occur during processing, callbacks will be made to the supplied error handler.
/// If an error handler is not supplied then the default is to use a newly created instance of %XML.XSLT.ErrorHandler.
ClassMethod RemoveFromEvaluateCacheFilterList(filterListEntry As %String = "", pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).RemoveFromEvaluateCacheFilterList(filterListEntry,pErrorHandler,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method clears the evaluate cache filter list.
/// If errors occur during processing, callbacks will be made to the supplied error handler.
/// If an error handler is not supplied then the default is to use a newly created instance of %XML.XSLT.ErrorHandler.
ClassMethod ClearEvaluateCacheFilterList(pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).ClearEvaluateCacheFilterList(pErrorHandler,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method sets the cache everything boolean for the evaluate cache.
/// This overrides the filter list and allows calls to all functions to be cached.
/// If errors occur during processing, callbacks will be made to the supplied error handler.
/// If an error handler is not supplied then the default is to use a newly created instance of %XML.XSLT.ErrorHandler.
ClassMethod SetCacheEverythingBoolean(cacheEverything As %Boolean = 0, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).SetCacheEverythingBoolean(cacheEverything,pErrorHandler,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method dumps the evaluate cache to a list, with the following format:
/// 		total number of cache entries
/// 		for each entry:
/// 			total number of evaluate arguments = function name + up to 9 arguments
/// 			all evaluate arguments
/// 			evaluate value
/// If errors occur during processing, callbacks will be made to the supplied error handler.
/// If an error handler is not supplied then the default is to use a newly created instance of %XML.XSLT.ErrorHandler.
ClassMethod DumpEvaluateCacheToList(Output evaluateCache As %List, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).DumpEvaluateCacheToList(.evaluateCache,pErrorHandler,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

/// This method loads (or pre-populates) the evaluate cache from a list, with the following format:
/// 		total number of cache entries
/// 		for each entry:
/// 			total number of evaluate arguments = function name + up to 9 arguments
/// 			all evaluate arguments
/// 			evaluate value
/// If errors occur during processing, callbacks will be made to the supplied error handler.
/// If an error handler is not supplied then the default is to use a newly created instance of %XML.XSLT.ErrorHandler.
ClassMethod LoadEvaluateCacheFromList(evaluateCache As %List = "", pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Set status=$$$OK
	Try {
		Set status=..SetupErrorHandler(.pErrorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).LoadEvaluateCacheFromList(evaluateCache,pErrorHandler,gateway)
	} Catch exception {
		Set status=##class(%Net.Remote.Java.XSLTGateway).%SetStatus(exception)
	}
	Use currentDevice
	Quit status
}

}
