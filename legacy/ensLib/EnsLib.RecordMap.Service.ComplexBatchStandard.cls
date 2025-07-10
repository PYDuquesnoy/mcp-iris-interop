/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Base class for Business Services which process streams containing ComplexBatch data.
Class EnsLib.RecordMap.Service.ComplexBatchStandard Extends Ens.BusinessService [ Abstract, System = 4 ]
{

Parameter SETTINGS = "ComplexMap:Basic:selector?context={/Classes?super=EnsLib.RecordMap.ComplexMap&hideAbstract=1},TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},SynchronousSend";

/// Name of the Complex RecordMap to use for processing the incoming data.
Property ComplexMap As %String(MAXLEN = 220) [ Required ];

/// A comma-separated list of Configuration Items which should receive the parsed objects.
Property TargetConfigNames As %String(MAXLEN = "");

/// Control whether requests should be sent synchronously or asynchronously to the items 
/// listed in TargetConfigNames. The default is false.
Property SynchronousSend As %Boolean [ InitialExpression = 0 ];

/// Full classname of the Complex RecordMap - the name may need to be normalized.
Property complexMapFull As %String(MAXLEN = 220) [ Private, Transient ];

/// Wrap the GetBatch() method in the ComplexMap class.
Method GetBatch(pStream As %IO.DeviceStream, Output pBatch As EnsLib.RecordMap.ComplexBatch, pTimeout As %Numeric = -1, ByRef pLookAhead As %String = "") As %Status
{
	Try {
		New %EnsRecordMap
		Set %EnsRecordMap("StrictValidation") = 1
		Set tStatus = $classmethod(..complexMapFull,"GetBatch",pStream,pTimeout,.pBatch,.pLookAhead)
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..OnBatchComplete(pBatch)
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Callback which is invoked immediately after successful parsing of a batch. Users may
/// wish to override this method to allow for extra validation and or initial processing.
/// Note that this callback is invoked before the Batch is first saved to disk.
Method OnBatchComplete(pBatch As EnsLib.RecordMap.ComplexBatch) As %Status
{
	Quit $$$OK
}

/// Send the generated object to the requested targets.
Method SendRequest(pRequest As %Persistent, pAsync As %Boolean = 1, Output pResponses As %ListOfObjects) As %Status
{
	Set tStatus = $$$OK
	Set pResponses = ##class(%ListOfObjects).%New()
	For i=1:1:$length(..TargetConfigNames,",") {
		If i>1 Set pAsync = 1
		If pAsync {
			Set tStatus = ..SendRequestAsync($piece(..TargetConfigNames,",", i), pRequest)
			If $$$ISERR(tStatus) Quit
		}
		Else {
			Set tStatus = ..SendRequestSync($piece(..TargetConfigNames, ",", i), pRequest, .tResponse)
			If $$$ISERR(tStatus) Quit
			Set tStatus = pResponses.InsertAt(tResponse, i)
			If $$$ISERR(tStatus) Quit
		}
	}
	Quit tStatus
}

/// Ensure that the ComplexMap and the target class exist and are based on the RecordMap framework.
Method OnInit() As %Status
{
	Set tStatus = ..%ValidateObject()
	If $$$ISERR(tStatus) Quit tStatus
	
	If '##class(EnsLib.RecordMap.Model.ComplexBatch).Exists(..ComplexMap) Quit $$$ERROR($$$ClassDoesNotExist, ..ComplexMap)
	
	Set ..complexMapFull = $$$NormalizeClassname(..ComplexMap)
	
	Set tTargetClass = $$$comMemberKeyGet(..complexMapFull,$$$cCLASSparameter,"BATCHCLASS",$$$cPARAMdefault)
	If tTargetClass = "" Quit $$$ERROR($$$EnsRecordMapErrNoDefaultObject,..complexMapFull)
	
	If '##class(%Dictionary.CompiledClass).%ExistsId(tTargetClass) Quit $$$ERROR($$$ClassDoesNotExist,tTargetClass)
	If '$classmethod(tTargetClass,"%Extends","EnsLib.RecordMap.ComplexBatch") Quit $$$ERROR($$$EnsRecordMapErrInvalidClass,tTargetClass,"EnsLib.RecordMap.ComplexBatch")
	
	Quit tStatus
}

/// Add connections from TargetConfigNames
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("TargetConfigNames",.tValue) && (tValue '= "") {
		Do ..makeConnections(tValue,.pArray)
	}
}

/// Get the filename from an incoming stream object.
Method GetFileName(pStream As %Stream.Object) As %String [ Internal, Private ]
{
	Set tSourceFile = ""
	If pStream.%Extends("%Library.AbstractStream") {
		Set tSourceFile = $get(pStream.Attributes("Filename"))
	}
	If (tSourceFile = "") && (pStream.%Extends("%Library.FileStreamAdaptor") || pStream.%Extends("%Stream.FileBinary")) {
		Set tSourceFile = pStream.Filename
	}
	Quit tSourceFile
}

}
