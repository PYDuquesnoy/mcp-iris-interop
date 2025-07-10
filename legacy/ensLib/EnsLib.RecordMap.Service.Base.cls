/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Base class for Business Services which process streams containing data mapped to RecordMaps
/// and/or batches of RecordMaps.
Class EnsLib.RecordMap.Service.Base Extends Ens.BusinessService [ Abstract, System = 4 ]
{

Parameter SETTINGS = "RecordMap:Basic:selector?context={Ens.ContextSearch/RecordMaps},TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},SynchronousSend";

/// Name of the RecordMap to use for processing the incoming data.
Property RecordMap As %String(MAXLEN = 220) [ Required ];

/// A comma-separated list of Configuration Items which should receive the parsed objects.
Property TargetConfigNames As %String(MAXLEN = "");

/// Control whether requests should be sent synchronously or asynchronously to the items 
/// listed in TargetConfigNames. The default is false.
Property SynchronousSend As %Boolean [ InitialExpression = 0 ];

/// Full classname of the RecordMap - the name may need to be normalized.
Property recordMapFull As %String(MAXLEN = 220) [ Private, Transient ];

/// Wrap the GetObject() method in the RecordMap class.
Method GetObject(pStream As %IO.DeviceStream, Output pObject As EnsLib.RecordMap.Base, pTimeout As %Numeric = -1, ByRef pLookAhead As %String = "", pLabelFound As %Boolean = 0) As %Status
{
	Try {
		Set tStatus = $classmethod(..recordMapFull, "GetObject", pStream, .pObject, pTimeout, .pLookAhead, pLabelFound)
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
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

/// Ensure that the RecordMap and the target class exist and are based on the RecordMap framework.
Method OnInit() As %Status
{
	Set tStatus = ..%ValidateObject()
	If $$$ISERR(tStatus) Quit tStatus
	
	If '##class(EnsLib.RecordMap.RecordMap).Exists(..RecordMap) Quit $$$ERROR($$$ClassDoesNotExist, ..RecordMap)
	
	Set ..recordMapFull = $$$NormalizeClassname(..RecordMap)
	
	Set tTargetClass = $$$comMemberKeyGet(..recordMapFull,$$$cCLASSparameter,"OBJECTNAME",$$$cPARAMdefault)
	If tTargetClass = "" Quit $$$ERROR($$$EnsRecordMapErrNoDefaultObject,..recordMapFull)
	
	If '##class(%Dictionary.CompiledClass).%ExistsId(tTargetClass) Quit $$$ERROR($$$ClassDoesNotExist, tTargetClass)
	
	If '$classmethod(tTargetClass, "%Extends", "EnsLib.RecordMap.Base") Quit $$$ERROR($$$EnsRecordMapErrInvalidClass, tTargetClass, "EnsLib.RecordMap.Base")
	
	Quit tStatus
}

/// Add connections from TargetConfigNames
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("TargetConfigNames",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
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
