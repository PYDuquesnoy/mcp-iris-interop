/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A simple RoutingEngine that populates a SearchTable entry for each message received
Class EnsLib.MsgRouter.RoutingEngineST Extends EnsLib.MsgRouter.RoutingEngine [ System = 4 ]
{

/// Store a set of searchable properties associated with each document processed. <br>
/// These records will be stored in the named SearchTable class, if any.
Property SearchTableClass As %String(MAXLEN = 100);

Parameter SETTINGS = "SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.MsgRouter.RoutingEngineST}";

/// Override this method to implement your own method for validating a Document
/// Return non-zero to prevent default validation of the message (if any);
/// return an error code in pStatus to indicate a validation failure.
Method OnValidate(pDoc As %Persistent, pValSpec As %String, Output pStatus As %Status = {$$$OK}) As %Boolean
{
	If ""'=..SearchTableClass {
		TRY {		
			Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",pDoc)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for message "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} CATCH errobj { $$$LOGWARNING("Failed to invoke SearchTable method "_..SearchTableClass_".IndexDoc() for message "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' : "_errobj.AsSystemError()) }
	}
	Quit 0
}

Storage Default
{
<Data name="RoutingEngineSTDefaultData">
<Subscript>"RoutingEngineST"</Subscript>
<Value name="1">
<Value>SearchTableClass</Value>
</Value>
</Data>
<DefaultData>RoutingEngineSTDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
