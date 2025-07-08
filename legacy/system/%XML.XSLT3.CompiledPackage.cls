/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implements an interface to the XSLT3 CompiledPackage. %XML.XSLT3.CompiledPackage should never be
/// created directly with %New(), but via the CreateFromFile() or CreateFromStream() factory methods
Class %XML.XSLT3.CompiledPackage Extends %RegisteredObject
{

Property ReleaseOnClose As %Boolean [ InitialExpression = 1 ];

/// Use this method a create an instance of an %XML.XSLT3.CompiledPackage from a file path name
ClassMethod CreateFromFile(source As %String, Output compiledPackage As %XML.XSLT3.CompiledPackage, errorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Try {
		Kill compiledPackage Set compiledPackage=$$$NULLOREF
		Set status=##class(%XML.XSLT3.Transformer).SetupErrorHandler(.errorHandler)
		Quit:$$$ISERR(status)
		
		// Parse the source
		Set compiledPackage=##class(%XML.XSLT3.CompiledPackage).%New()
		Set compiledPackage.ReleaseOnClose = '$Isobject(gateway)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).CompileXSLPackageFile(source,compiledPackage,errorHandler,gateway)
	} Catch exception {
		Set status=$$$ERROR($$$XSLTError,exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
	}
	Use currentDevice
	Quit status
}

/// Use this method to create an instance of an %XML.XSLT3.CompiledPackage from a binary stream
ClassMethod CreateFromStream(stream As %Stream.Object, Output compiledPackage As %XML.XSLT3.CompiledPackage, errorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}, XSLBaseDir As %String = "") As %Status
{
	#dim currentDevice As %String = $IO
	Try {
		Set status=##class(%XML.XSLT3.Transformer).SetupErrorHandler(.errorHandler)
		Quit:$$$ISERR(status)
		
		Kill compiledPackage Set compiledPackage=$$$NULLOREF
		Set compiledPackage=##class(%XML.XSLT3.CompiledPackage).%New()
		Set compiledPackage.ReleaseOnClose = '$Isobject(gateway)
		
		// Parse the source
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set status=##class(%Net.Remote.Java.XSLTGateway).CompileXSLPackageStream(stream,compiledPackage,errorHandler,gateway,XSLBaseDir) 
 		Kill %objlasterror 		
	} Catch exception {
		Set status=$$$ERROR($$$XSLTError,exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
	}
	Use currentDevice
	Quit status
}

ClassMethod ReleaseFromServer(compiledPackage As %XML.XSLT3.CompiledPackage, errorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, gateway As %Net.Remote.Gateway = {$$$NULLOREF}) As %Status
{
	#dim currentDevice As %String = $IO
	Try {
		Set status=##class(%XML.XSLT3.Transformer).SetupErrorHandler(.errorHandler)
		Quit:$$$ISERR(status)
		Use:$Isobject(gateway) gateway.GatewayDevice
		Set requestObj = ##class(%Net.Remote.Java.XSLTGatewayRequest).%New()
		Set status=##class(%Net.Remote.Java.XSLTGateway).ReleaseCompiledXSLT3Package(compiledPackage,errorHandler,gateway, requestObj)
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

Storage Default
{
<Data name="CompiledPackageDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ReleaseOnClose</Value>
</Value>
</Data>
<DataLocation>^%XML.XSLT3.CompiledPackageD</DataLocation>
<DefaultData>CompiledPackageDefaultData</DefaultData>
<IdLocation>^%XML.XSLT3.CompiledPackageD</IdLocation>
<IndexLocation>^%XML.XSLT3.CompiledPackageI</IndexLocation>
<StreamLocation>^%XML.XSLT3.CompiledPackageS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
