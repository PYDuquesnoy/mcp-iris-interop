/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occJava, %External.language)

Class %Net.Remote.Java.XSLTGateway Extends %Net.Remote.Gateway [ StorageStrategy = "" ]
{

Parameter XSLTREQUEST [ Final ] = "YX";

Parameter DONE [ Final ] = 1;

Parameter COMPILEFILE [ Final ] = 2;

Parameter COMPILESTREAM [ Final ] = 3;

Parameter INVOKECALLBACK [ Final ] = 4;

Parameter RESOLVEENTITY [ Final ] = 5;

Parameter WARNING [ Final ] = 6;

Parameter ERROR [ Final ] = 7;

Parameter FATALERROR [ Final ] = 8;

Parameter TRANSFORMFILEFILEFILE [ Final ] = 9;

Parameter TRANSFORMFILECOMPILEDFILE [ Final ] = 10;

Parameter TRANSFORMSTREAMSTREAMSTREAM [ Final ] = 11;

Parameter TRANSFORMSTREAMCOMPILEDSTREAM [ Final ] = 12;

Parameter TRANSFORMSTRINGCOMPILEDSTRING [ Final ] = 13;

Parameter RELEASECOMPILEDXSLT [ Final ] = 14;

Parameter CLEAREVALUATECACHE [ Final ] = 15;

Parameter SETEVALUATECACHESIZE [ Final ] = 16;

Parameter ADDTOEVALUATECACHEFILTERLIST [ Final ] = 17;

Parameter REMOVEFROMEVALUATECACHEFILTERLIST [ Final ] = 18;

Parameter CLEAREVALUATECACHEFILTERLIST [ Final ] = 19;

Parameter SETCACHEEVERYTHINGBOOLEAN [ Final ] = 20;

Parameter DUMPEVALUATECACHETOLIST [ Final ] = 21;

Parameter LOADEVALUATECACHEFROMLIST [ Final ] = 22;

Parameter XSLT3REQUEST [ Final ] = "YO";

Parameter COMPILEPACKAGEFILE = 23;

Parameter COMPILEPACKAGESTREAM = 24;

Parameter RELEASECOMPILEDXSLTPACKAGE = 25;

Parameter MESSAGE [ Final ] = 26;

/// Default host
Parameter Host = "127.0.0.1";

/// Default port is Superserver port + 3000 if it does not exceed 65535, otherwise 54773
Parameter Port As COSEXPRESSION = "$S($ZU(172,0)<=62535:$ZU(172,0)+3000,1:54773)";

/// Default log file
Parameter LogFile;

/// Default JavaHome directory
Parameter JavaHome;

/// Default additional JVM arguments
Parameter JVMArgs;

ClassMethod TransformStream(source As %Stream.Object, xslt As %ObjectHandle, target As %Stream.Object, errorHandler As %ObjectHandle, callbackHandler As %ObjectHandle, parameters As %ObjectHandle, entityResolver As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status [ Final ]
{
	Try {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.ErrorHandler = errorHandler
		Set requestObj.CallbackHandler = callbackHandler
		Set requestObj.Parameters = parameters
		Set requestObj.EntityResolver = entityResolver
		Set requestObj.XSLTRequestType = ..#XSLTREQUEST

		If (xslt.%Extends("%Stream.Object")) {
			Set requestObj.RequestType = ..#TRANSFORMSTREAMSTREAMSTREAM
			Set requestObj.XMLStream = source
			Set requestObj.XSLTStream = xslt
			Set status = ..SendRequestToGateway(requestObj,gateway,.target)
		} ElseIf (xslt.%IsA("%XML.XSLT2.CompiledStyleSheet")) {
			Set requestObj.RequestType = ..#TRANSFORMSTREAMCOMPILEDSTREAM
			Set requestObj.XMLStream = source
			Set requestObj.CompiledStylesheet = xslt
			Set status = ..SendRequestToGateway(requestObj,gateway,.target)
		} Else {
			Set status=$$$ERROR($$$XSLTError,"Unknown stylesheet type")
		}
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Quit status
}

ClassMethod TransformFileFile(source As %String, xslt As %String, target As %String, errorHandler As %ObjectHandle, callbackHandler As %ObjectHandle, parameters As %ObjectHandle, entityResolver As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.CallbackHandler = callbackHandler
	Set requestObj.Parameters = parameters
	Set requestObj.EntityResolver = entityResolver
	Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	
	Set requestObj.RequestType = ..#TRANSFORMFILEFILEFILE
	Set requestObj.XMLFilePath = source
	Set requestObj.XSLTFilePath = xslt
	Set requestObj.TargetFilePath = target
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod TransformFileCompiled(source As %String, xslt As %XML.XSLT2.CompiledStyleSheet, target As %String, errorHandler As %ObjectHandle, callbackHandler As %ObjectHandle, parameters As %ObjectHandle, entityResolver As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.CallbackHandler = callbackHandler
	Set requestObj.Parameters = parameters
	Set requestObj.EntityResolver = entityResolver
	Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	
	Set requestObj.RequestType = ..#TRANSFORMFILECOMPILEDFILE
	Set requestObj.XMLFilePath = source
	Set requestObj.CompiledStylesheet = xslt
	Set requestObj.TargetFilePath = target
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod TransformStringCompiled(source As %String, xslt As %XML.XSLT2.CompiledStyleSheet, ByRef target As %String, errorHandler As %ObjectHandle, callbackHandler As %ObjectHandle, parameters As %ObjectHandle, entityResolver As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.CallbackHandler = callbackHandler
	Set requestObj.Parameters = parameters
	Set requestObj.EntityResolver = entityResolver
	Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	
	Set requestObj.RequestType = ..#TRANSFORMSTRINGCOMPILEDSTRING
	Set requestObj.XMLString = source
	Set requestObj.CompiledStylesheet = xslt
	Quit ..SendRequestToGateway(requestObj,gateway,,.target)
}

ClassMethod CompileXSLFile(xslt As %String, compiledStyleSheet As %XML.XSLT2.CompiledStyleSheet, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.RequestType = ..#COMPILEFILE
	Set requestObj.XSLTFilePath = xslt
	
	Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	Set requestObj.CompiledStylesheet = compiledStyleSheet
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod ReleaseCompiledXSLT(compiledStyleSheet As %XML.XSLT2.CompiledStyleSheet, errorHandler As %ObjectHandle = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.RequestType = ..#RELEASECOMPILEDXSLT
	Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	Set requestObj.CompiledStylesheet = compiledStyleSheet
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod CompileXSLStream(xslt As %Stream.Object, compiledStyleSheet As %XML.XSLT2.CompiledStyleSheet, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.RequestType = ..#COMPILESTREAM
	Set requestObj.XSLTStream = xslt
	Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	Set requestObj.CompiledStylesheet = compiledStyleSheet
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod ClearEvaluateCache(errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status
{
	if ('$ISOBJECT(requestObj)) {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	} else {
		Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	}
	
	Set requestObj.ErrorHandler = errorHandler
	
	Set requestObj.RequestType = ..#CLEAREVALUATECACHE
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod SetEvaluateCacheSize(size As %Integer, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status
{
	Quit:(size<1) $$$ERROR($$$XSLTError,"Evaluate cache size must be >=1.")
	
	if ('$ISOBJECT(requestObj)) {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	} else {
		Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	}
	
	Set requestObj.ErrorHandler = errorHandler
	
	Set requestObj.RequestType = ..#SETEVALUATECACHESIZE
	Set requestObj.NewEvaluateCacheSize = size
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod AddToEvaluateCacheFilterList(filterListEntry As %String, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status
{
	Quit:(filterListEntry="") $$$ERROR($$$XSLTError,"Evaluate cache filter list entry cannot be the empty string, since this is not a valid function call.")

	if ('$ISOBJECT(requestObj)) {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	} else {
		Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	}
	
	Set requestObj.ErrorHandler = errorHandler
	
	Set requestObj.RequestType = ..#ADDTOEVALUATECACHEFILTERLIST
	Set requestObj.FilterListFunctionCall = filterListEntry
	Set requestObj.FilterListArgs = $Listbuild()
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod RemoveFromEvaluateCacheFilterList(filterListEntry As %String, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status
{
	Quit:(filterListEntry="") $$$ERROR($$$XSLTError,"Evaluate cache filter list entry cannot be the empty string, since this is not a valid function call.")

	if ('$ISOBJECT(requestObj)) {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	} else {
		Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	}
	Set requestObj.ErrorHandler = errorHandler
	
	Set requestObj.RequestType = ..#REMOVEFROMEVALUATECACHEFILTERLIST
	Set requestObj.FilterListFunctionCall = filterListEntry
	Set requestObj.FilterListArgs = $Listbuild()
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod ClearEvaluateCacheFilterList(errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status
{
	if ('$ISOBJECT(requestObj)) {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	} else {
		Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	}
	Set requestObj.ErrorHandler = errorHandler
	
	Set requestObj.RequestType = ..#CLEAREVALUATECACHEFILTERLIST
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod SetCacheEverythingBoolean(cacheEverything As %Boolean, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status
{
	if ('$ISOBJECT(requestObj)) {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	} else {
		Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	}
	Set requestObj.ErrorHandler = errorHandler
	
	Set requestObj.RequestType = ..#SETCACHEEVERYTHINGBOOLEAN
	Set requestObj.NewCacheEverythingBoolean = cacheEverything
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod DumpEvaluateCacheToList(Output evaluateCache As %List, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status
{
	if ('$ISOBJECT(requestObj)) {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	} else {
		Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	}
	Set requestObj.ErrorHandler = errorHandler
	
	Set requestObj.RequestType = ..#DUMPEVALUATECACHETOLIST
	Quit ..SendRequestToGateway(requestObj,gateway,,,.evaluateCache)
}

ClassMethod LoadEvaluateCacheFromList(evaluateCache As %List, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status
{
	if ('$ISOBJECT(requestObj)) {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.XSLTRequestType = ..#XSLTREQUEST
	} else {
		Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	}
	Set requestObj.ErrorHandler = errorHandler
	
	Set requestObj.RequestType = ..#LOADEVALUATECACHEFROMLIST
	Set requestObj.EvaluateCacheToLoad = evaluateCache
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod ProcessCallback(gateway As %Net.Remote.Gateway, msgid As %Integer, fun As %String)
{
	Set callback=$zobjref($zobjexport(12)),arg=$zobjexport(12)
	For i=1:1:arg {
		Set arg(i)=$zobjexport(12)
		// Java gateway distinguishes between the empty string, which is sent to Cache as $c(0), and null, which is sent to Cache as the empty string.
		// XSLT will never have to make this distinction because the ASCII null character is not allowed in XML documents
		// and XPath does not allow two commas with nothing in between them as arguments to a function.
		Set:arg(i)=$c(0) arg(i)=""
	}
	Set retValue=$method(callback,"evaluate",arg...)
	Use gateway.GatewayDevice
	Set x=$zobjexport(retValue,18)
	Set x=$zobjexport(msgid,1)
	if (fun="YX"){
		Set x=$zobjexport(..#XSLTREQUEST,8)
	} else {
		Set x=$zobjexport(..#XSLT3REQUEST,8)
	}
}

ClassMethod SendRequestToGateway(requestObj As %Net.Remote.Java.XSLTGatewayRequest, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, Output targetStream As %Stream.Object, Output targetString As %String, Output evaluateCache As %List) As %Status [ Final ]
{
		Try {
		Set manageGatewayHere = '$ISOBJECT(gateway)
		If manageGatewayHere {
			Set gateway=..StartGateway(.status)
			If $$$ISERR(status) Quit
		}
		use gateway.GatewayDevice

		// FIRST MESSAGE contains stream sizes, filepaths, compiled stylesheet
		// This message will be sent for all request types
		Set X = $zobjexport(requestObj.RequestType,2) // set header bytes 9-12 to code for XSLT request type
		Set X = $zobjexport(requestObj.CallbackHandler,18)
		Set X = $zobjexport(requestObj.EntityResolver,18)
		Set X = $zobjexport(requestObj.Parameters,18)
		Set X = $zobjexport(requestObj.ErrorHandler,18)
		Set X = $zobjexport(requestObj.Options,18)
		
		// request types 1-14 && 23-25: compile stylesheets, transform documents
		Set xmlStreamSize = $select($isobject(requestObj.XMLStream):requestObj.XMLStream.Size,1:0)
		Set xsltStreamSize = $select($isobject(requestObj.XSLTStream):requestObj.XSLTStream.Size,1:0)
		If (requestObj.RequestType < 15 || requestObj.RequestType > 22 && requestObj.RequestType < 26) {
			Set X = $zobjexport($listbuild(xmlStreamSize,xsltStreamSize),5)
			Set X = $zobjexport(requestObj.XMLFilePath,18)
			Set X = $zobjexport(requestObj.XSLTFilePath,18)
			Set X = $zobjexport(requestObj.TargetFilePath,18)
			Set X = $zobjexport(requestObj.CompiledStylesheet,18)
			Set X = $zobjexport(requestObj.CompiledXSLT3Stylesheet,18)
			Set X = $zobjexport(requestObj.XMLString,18)
			Set X = $zobjexport(requestObj.CompiledPackage, 18)
			Set X = $zobjexport(requestObj.CompiledPackages, 18)
			Set X = $zobjexport(requestObj.EnableStreaming, 18)
			Set X = $zobjexport(requestObj.XMLBaseDir,18)
			Set X = $zobjexport(requestObj.XSLBaseDir,18)
		}
		// request types 15-22 : cache evaluate calls
		Else {
			Set X = $zobjexport(requestObj.NewEvaluateCacheSize,18)
			Set X = $zobjexport(requestObj.NewCacheEverythingBoolean,18)

			Set X = $zobjexport(requestObj.FilterListFunctionCall,18)
			Set filterListNumArgs = $Listlength(requestObj.FilterListArgs)
			Set X = $zobjexport(filterListNumArgs,18)
			For ctr=1:1:filterListNumArgs {
				Set X = $zobjexport($List(requestObj.FilterListArgs,ctr),18)
			}
			
			// load evaluate cache from list
			Set numEntries = $Listlength(requestObj.EvaluateCacheToLoad)
			Set X = $zobjexport(numEntries,18)
			For entryCtr=1:1:numEntries {
				Set argsList = $List(requestObj.EvaluateCacheToLoad,entryCtr)
				Set numArgs = $ListLength(argsList)-1 // list length -1 because last list entry is cached return value of function call
				Set X = $zobjexport(numArgs,18)
				For argCtr=1:1:(numArgs+1) {
					Set X = $zobjexport($List(argsList,argCtr),18)
				}
			}
		}
		Set x=$zobjexport($i(gateway.SequenceNumber,2),1)
		Set X = $zobjexport(requestObj.XSLTRequestType,8) // set header bytes 13-14 to code for java gateway request type, then flush buffer
		
		// remember initial column water mark (determines when to flush the zobjexport buffer)
		Set initialWatermark = $zobjexport(0,53)
		Set watermarkChanged = 0

		// NEXT MESSAGE contains XSLT stream contents, added to buffer in chunks of [max string length]
		// This message will only be sent for request types that include an xslt stream
		Set maxStrLength = $SYSTEM.SYS.MaxLocalLength()
		If $isobject(requestObj.XSLTStream) && (requestObj.XSLTStream.Size>0) {
			Set X = $zobjexport(requestObj.RequestType,2) // set header bytes 9-12 to code for xml stream, xsl stream
			Set toRead = requestObj.XSLTStream.Size
			Do requestObj.XSLTStream.Rewind() // need to rewind because used stream.size
			Set X = $zobjexport(toRead,53)
			Set X = $zobjexport(toRead,57)
			While toRead>0 {
				Set toRead = $zobjexport(requestObj.XSLTStream.Read(maxStrLength),59)
			}
			Set watermarkChanged = 1
		}
		
		// NEXT MESSAGE contains XML stream contents, added to buffer in chunks of [max string length]
		// This message will only be sent for request types that include an xml stream
		If $isobject(requestObj.XMLStream) && (requestObj.XMLStream.Size>0) {
			Set X = $zobjexport(requestObj.RequestType,2) // set header bytes 9-12 to code for xml stream, xsl stream
			Set toRead = requestObj.XMLStream.Size // need to rewind because used stream.size
			Do requestObj.XMLStream.Rewind() // need to rewind because used stream.size
			Set X = $zobjexport(toRead,53)
			Set X = $zobjexport(toRead,57)
			While toRead>0 {
				Set toRead = $zobjexport(requestObj.XMLStream.Read(maxStrLength),59)
			}
			Set watermarkChanged = 1
		}
		// restore initial column water mark
		Set:(watermarkChanged=1) X = $zobjexport(initialWatermark,53)

		Set status = ..WaitForResponse(gateway,.targetStream,.targetString,.evaluateCache,requestObj)
		Quit:$$$ISERR(status)
		Set:manageGatewayHere status = ..StopGateway(gateway)
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Quit status
}

ClassMethod WaitForResponse(gateway As %Net.Remote.Gateway, ByRef outputStream As %Stream.Object = {$$$NULLOREF}, ByRef outputString As %String = "", ByRef evaluateCache As %List = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest) As %Status [ Final, Private ]
{
	Set status=$$$OK
Loop Set msgid=$zobjexport(21),type=$zobjexport(10),fun=$zobjexport(15)
	If (fun=##class(%Net.Remote.Gateway).#EXCEPTIONRAISED) {
		Set error=$zobjexport(12)
		Quit $$$ERROR($$$RemoteGatewayError,error)
	} elseif (fun="GI")||(fun="LÂ") {
		set device = gateway.GatewayDevice
		do ##class(%SYS.DBSRV).GWExecuteSingle(msgid_"@"_device,type_"@"_device,fun)
		goto Loop
	} ElseIf (fun'="YX") && (fun'="YO") {
		Quit $$$ERROR($$$XSLTError,"Invalid XSLT request: "_fun)
	}
	If (type=..#TRANSFORMFILEFILEFILE)||(type=..#TRANSFORMFILECOMPILEDFILE)||(type=..#DONE)||(type=..#COMPILEFILE)||(type=..#COMPILESTREAM)||(type=..#RELEASECOMPILEDXSLT)
		||(type=..#CLEAREVALUATECACHE)||(type=..#SETEVALUATECACHESIZE)||(type=..#ADDTOEVALUATECACHEFILTERLIST)||(type=..#REMOVEFROMEVALUATECACHEFILTERLIST)
		||(type=..#CLEAREVALUATECACHEFILTERLIST)||(type=..#SETCACHEEVERYTHINGBOOLEAN)||(type=..#LOADEVALUATECACHEFROMLIST)
		||(type=..#COMPILEPACKAGEFILE)||(type=..#COMPILEPACKAGESTREAM)||(type=..#RELEASECOMPILEDXSLTPACKAGE){
		Quit status
	} ElseIf (type=..#TRANSFORMSTREAMSTREAMSTREAM)||(type=..#TRANSFORMSTREAMCOMPILEDSTREAM) {
		If outputStream'="" {
			Set streamSize=$zobjexport(12)
			Set maxStrLength = $SYSTEM.SYS.MaxLocalLength()
			While streamSize>0 {
				Set chunkLength = $select(streamSize>maxStrLength:maxStrLength,1:streamSize)
				Set chunk = $zobjexport(chunkLength,13)
				Do outputStream.Write(chunk)
				Set streamSize = streamSize - chunkLength
			}
		}
		Quit status
	} ElseIf (type=..#TRANSFORMSTRINGCOMPILEDSTRING) {
		Set stringSize=$zobjexport(12)
		Set maxStrLength = $SYSTEM.SYS.MaxLocalLength()
		If (stringSize > maxStrLength) {
			// Stop reading the current message and reset, because the return data will not be returned to the user.
			Set x = $zobjexport(14)

			Set status=$$$ERROR($$$XSLTError,"Result longer than max string length")
			If requestObj.ErrorHandler {
				Use gateway.CurrentDevice
				Do requestObj.ErrorHandler.error("Result longer than max string length")
			}
		} Else {
			Set outputString=$zobjexport(12)
		}
		Quit status
	} ElseIf (type=..#DUMPEVALUATECACHETOLIST) {
		Set evaluateCache = ""
		Set numEntries = $zobjexport(12)
		For entryCtr=1:1:numEntries {
			Set argsList = ""
			Set numArgs = $zobjexport(12)
			For argCtr=1:1:(numArgs+1) { // numArgs +1 because last list entry is cached return value of function call
				Set argsList = argsList_$Listbuild($zobjexport(12))
			}
			Set evaluateCache = evaluateCache_$Listbuild(argsList)
		}
		Quit status
	} ElseIf type=..#INVOKECALLBACK {
		Do ..ProcessCallback(gateway,msgid,fun)
	} ElseIf (type=..#WARNING)||(type=..#ERROR)||(type=..#FATALERROR)||(type=..#MESSAGE) {
		Set errorText = ..ProcessError(gateway,type)
		Quit:type=..#FATALERROR $$$ERROR($$$XSLTError,errorText)
	}
	Goto Loop
}

ClassMethod ProcessError(gateway As %Net.Remote.Gateway, type As %Integer)
{
	Set errorHandler=$zobjref($zobjexport(12))
	Set errorText=$zobjexport(12)
	Use gateway.CurrentDevice
	If (type=..#WARNING) {
		Do $zobjmethod(errorHandler,"warning",errorText)
	} ElseIf (type=..#ERROR) {
		Do $zobjmethod(errorHandler,"error",errorText)
	} ElseIf (type=..#FATALERROR) {
		Do $zobjmethod(errorHandler,"fatalError",errorText)
	} ElseIf (type=..#MESSAGE) {
		Do $zobjmethod(errorHandler,"message",errorText)
	}
	Use gateway.GatewayDevice
	Quit errorText
}

/// Start a Gateway for XSLT 2.0 if not already started, and return a gateway connection
/// This method is deprecated, please call $system.external.getXSLTGateway() instead.
/// All the arguments to override Gateway definition will be ignored.
/// This method will only start Gateway Server "%XSLT Server"
ClassMethod StartGateway(Output status As %Status, port As %String, host As %String, jdk As %String, javahome As %String, logfile As %String, jvmargs As %String, resource As %String, useSharedMemoryIfPossible As %Boolean = 0) As %Net.Remote.Gateway [ Deprecated ]
{
	set gateway = $$$NULLOREF
	set status = $$$OK
	try {
		set gateway = $system.external.getXSLTGateway()
	} catch exception {
		set status = exception.AsStatus()
	}
	quit gateway
}

/// Disconnect
ClassMethod StopGateway(gateway As %Net.Remote.Gateway) As %Status
{
	set status = $$$OK
	try {
		set status = gateway.%Disconnect()
		kill gateway
	} catch exception {
		set status = exception.AsStatus()
	}
	quit status
}

/// Shutdown the gateway
/// All arguments will be ignored.
/// This method will only shutdown Gateway Server "%XSLT Server"
ClassMethod ShutdownGateway(port As %String, host As %String) As %Status
{
	quit ##class(%Net.Remote.Service).StopGateway("%XSLT Server")
}

ClassMethod CompileXSLT3File(xslt As %String, compiledStyleSheet As %XML.XSLT3.CompiledStyleSheet, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.RequestType = ..#COMPILEFILE
	Set requestObj.XSLTFilePath = xslt
	
	Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	Set requestObj.CompiledXSLT3Stylesheet = compiledStyleSheet
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod CompileXSLT3XSLStream(xslt As %Stream.Object, compiledStyleSheet As %XML.XSLT3.CompiledStyleSheet, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, XSLBaseDir As %String) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.RequestType = ..#COMPILESTREAM
	Set requestObj.XSLTStream = xslt
	Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	Set requestObj.CompiledXSLT3Stylesheet = compiledStyleSheet
	Set requestObj.XSLBaseDir = XSLBaseDir
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod ReleaseCompiledXSLT3(compiledStyleSheet As %XML.XSLT3.CompiledStyleSheet, errorHandler As %ObjectHandle = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.RequestType = ..#RELEASECOMPILEDXSLT
	Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	Set requestObj.CompiledXSLT3Stylesheet = compiledStyleSheet
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod CompileXSLPackageFile(xslt As %String, compiledPackage As %XML.XSLT3.CompiledPackage, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	Set requestObj.RequestType = ..#COMPILEPACKAGEFILE
	Set requestObj.XSLTFilePath = xslt
	Set requestObj.CompiledPackage = compiledPackage
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod CompileXSLPackageStream(xslt As %Stream.Object, compiledPackage As %XML.XSLT3.CompiledPackage, errorHandler As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, XSLBaseDir As %String) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	Set requestObj.RequestType = ..#COMPILEPACKAGESTREAM
	Set requestObj.XSLTStream = xslt
	Set requestObj.CompiledPackage = compiledPackage
	Set requestObj.XSLBaseDir = XSLBaseDir
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod ReleaseCompiledXSLT3Package(compiledPackage As %XML.XSLT3.CompiledPackage, errorHandler As %ObjectHandle = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, requestObj As %Net.Remote.Java.XSLTGatewayRequest = {$$$NULLOREF}) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.RequestType = ..#RELEASECOMPILEDXSLTPACKAGE
	Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	Set requestObj.CompiledPackage = compiledPackage
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod XSLT3TransformFileFile(source As %String, xslt As %String, target As %String, enableStreaming As %Boolean = 0, compiledPackages As %List = {$$$NULLOREF}, errorHandler As %ObjectHandle, callbackHandler As %ObjectHandle, parameters As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, options As %ObjectHandle) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.CallbackHandler = callbackHandler
	Set requestObj.Parameters = parameters
	Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	
	Set requestObj.RequestType = ..#TRANSFORMFILEFILEFILE
	Set requestObj.XMLFilePath = source
	Set requestObj.XSLTFilePath = xslt
	Set requestObj.TargetFilePath = target
	Set requestObj.EnableStreaming = enableStreaming
	Set requestObj.Options = options
	if ($ListValid(compiledPackages)) {
		Set requestObj.CompiledPackages = compiledPackages
	}
	
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod XSLT3TransformFileCompiled(source As %String, xslt As %XML.XSLT3.CompiledStyleSheet, target As %String, enableStreaming As %Boolean = 0, errorHandler As %ObjectHandle, callbackHandler As %ObjectHandle, parameters As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, options As %ObjectHandle) As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.CallbackHandler = callbackHandler
	Set requestObj.Parameters = parameters
	Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	Set requestObj.RequestType = ..#TRANSFORMFILECOMPILEDFILE
	Set requestObj.XMLFilePath = source
	Set requestObj.CompiledXSLT3Stylesheet = xslt
	Set requestObj.TargetFilePath = target
	Set requestObj.EnableStreaming = enableStreaming
	Set requestObj.Options = options
	
	Quit ..SendRequestToGateway(requestObj,gateway)
}

ClassMethod XSLT3TransformStream(source As %Stream.Object, xslt As %ObjectHandle, target As %Stream.Object, compiledPackages As %List, errorHandler As %ObjectHandle, callbackHandler As %ObjectHandle, parameters As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, options As %ObjectHandle, XMLBaseDir As %String, XSLBaseDir As %String) As %Status [ Final ]
{

	Try {
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set requestObj.ErrorHandler = errorHandler
		Set requestObj.CallbackHandler = callbackHandler
		Set requestObj.Parameters = parameters
		Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
		Set requestObj.Options = options
		set requestObj.XMLBaseDir = XMLBaseDir
		
		If (xslt.%Extends("%Stream.Object")) {
			Set requestObj.RequestType = ..#TRANSFORMSTREAMSTREAMSTREAM
			Set requestObj.XMLStream = source
			Set requestObj.XSLTStream = xslt
			set requestObj.XSLBaseDir = XSLBaseDir
			if ($ListValid(compiledPackages)) {
				Set requestObj.CompiledPackages = compiledPackages
			}
			Set status = ..SendRequestToGateway(requestObj,gateway,.target)
			
		} ElseIf (xslt.%IsA("%XML.XSLT3.CompiledStyleSheet")) {
			Set requestObj.RequestType = ..#TRANSFORMSTREAMCOMPILEDSTREAM
			Set requestObj.XMLStream = source
			Set requestObj.CompiledXSLT3Stylesheet = xslt
			Set status = ..SendRequestToGateway(requestObj,gateway,.target)
		} Else {
			Set status=$$$ERROR($$$XSLTError,"Unknown stylesheet type")
		}
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Quit status
}

ClassMethod XSLT3TransformStringCompiled(source As %String, xslt As %XML.XSLT3.CompiledStyleSheet, ByRef target As %String, errorHandler As %ObjectHandle, callbackHandler As %ObjectHandle, parameters As %ObjectHandle, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, options As %ObjectHandle, XMLBaseDir As %String = "") As %Status [ Final ]
{
	Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
	Set requestObj.ErrorHandler = errorHandler
	Set requestObj.CallbackHandler = callbackHandler
	Set requestObj.Parameters = parameters
	Set requestObj.XSLTRequestType = ..#XSLT3REQUEST
	
	Set requestObj.RequestType = ..#TRANSFORMSTRINGCOMPILEDSTRING
	Set requestObj.XMLString = source
	Set requestObj.CompiledXSLT3Stylesheet = xslt 
	Set requestObj.Options = options
	Set requestObj.XMLBaseDir = XMLBaseDir
	Quit ..SendRequestToGateway(requestObj,gateway,,.target)
}

ClassMethod %SetStatus(exception As %Exception.StatusException) As %Status
{
	Quit $$$ERROR($$$XSLTError,exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
}

/// This method is no longer used internally by this class.
ClassMethod Transform(gateway As %Net.Remote.Gateway, errorHandler As %ObjectHandle, callbackHandler As %ObjectHandle, parameters As %ObjectHandle, entityResolver As %ObjectHandle, ByRef outputStream As %Stream.Object = {$$$NULLOREF}) As %Status [ Deprecated, Final ]
{
	Set x=$zobjexport(callbackHandler,18)
	Set x=$zobjexport(entityResolver,18)
	Set x=$zobjexport(parameters,18)
	Set status=..CallXSLTProcessor(gateway,errorHandler,.outputStream)
	Do ..StopGateway(gateway)
	Quit status
}

/// This method is no longer used internally by this class.
ClassMethod CallXSLTProcessor(gateway As %Net.Remote.Gateway, errorHandler As %ObjectHandle = {$$$NULLOREF}, ByRef outputStream As %Stream.Object = {$$$NULLOREF}) As %Status [ Deprecated, Final ]
{
	Set x=$zobjexport(errorHandler,18)
	Set x=$zobjexport(..#XSLTREQUEST,8)
	Quit ..WaitForResponse(gateway,.outputStream)
}

}
