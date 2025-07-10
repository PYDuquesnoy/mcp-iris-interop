/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Used in conjunction with the EnsLib.Testing.Service to wrap a test request for 
/// dispatch to a testing target.
Class EnsLib.Testing.Request Extends Ens.Request [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Name of Host (Business Operation or Business Process)
/// to send the Request to.
Property Target As %String(MAXLEN = 128);

/// A Request object to send to the target.
Property Request As Ens.Request;

/// Should the test Request be sent Synchronously or Asynchronously?
Property SyncCall As %Boolean [ InitialExpression = 0 ];

/// Classname of Request object to send to the target ( Populated automatically in Testing Service )
Property %requestClassname As %String(MAXLEN = 128) [ ReadOnly ];

/// Database Id of Request object to send to the target ( Populated automatically in Testing Service )
Property %requestId As %String(COLLATION = "EXACT", MAXLEN = "") [ ReadOnly ];

Method setRequestProps()
{
	Set tSC=$$$OK
	If '$IsObject(..Request) {
		Set i%%requestClassname=""
		Set i%%requestId=..Request
		Quit:""=..Request $$$ERROR($$$EnsErrGeneral,"No Request property set in Testing Request")
	} Else {
		Set i%%requestClassname=$classname(..Request)
		If ..Request.%IsA("%Library.Persistent")||..Request.%IsA("%Stream.Object") Set tSC=..Request.%Save()
		If $$$ISOK(tSC) Set tSC=..Request.%GetSwizzleObject(0,.tOID)
		Set:'..Request.%IsA("Ens.Request") ..Request=$$$NULLOREF
		If $$$ISERR(tSC) Set i%%requestId=""  Quit tSC
		Set i%%requestId=$$$oidPrimary(tOID)
	}
	Quit tSC
}

Storage Default
{
<Data name="TestingRequestDefaultData">
<Subscript>"TestingRequest"</Subscript>
<Value name="1">
<Value>Request</Value>
</Value>
<Value name="2">
<Value>Target</Value>
</Value>
<Value name="3">
<Value>SyncCall</Value>
</Value>
<Value name="4">
<Value>%requestClassname</Value>
</Value>
<Value name="5">
<Value>%requestId</Value>
</Value>
</Data>
<DefaultData>TestingRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
