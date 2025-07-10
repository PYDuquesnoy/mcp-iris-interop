/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Transport contents of a SOAP request or response
Class EnsLib.SOAP.GenericMessage Extends EnsLib.HTTP.GenericMessage [ System = 4 ]
{

Parameter XMLTYPE = "SOAPMessage";

Parameter XMLNAME = "SOAPMessage";

Property EnvelopeStream As %GlobalCharacterStream;

/// If both EnvelopeStream and EnvelopeDoc exist, EnvelopeStream is definitive for output
Property EnvelopeDoc As EnsLib.EDI.XML.Document(XMLPROJECTION = "NONE");

/// If both Stream and Doc exist, Stream is definitive for output
Property Doc As EnsLib.EDI.XML.Document(XMLPROJECTION = "NONE");

/// An array of strings containing any HTTP header values
Property HTTPHeaders As array Of %String(MAXLEN = "");

Method %OnNew(pBodyStream As %RawString = {$$$NULLOREF}, pAttributes As %Collection.ArrayOfDT = {$$$NULLOREF}, pHTTPHeaders As %Collection.ArrayOfDT = {$$$NULLOREF}, pEnvelopeStream As %AbstractStream = {$$$NULLOREF}, pBodyDoc = {$$$NULLOREF}, pEnvelopeDoc = {$$$NULLOREF}) As %Status
{
	Set tSC=##super(pBodyStream,.pAttributes,.pHTTPHeaders)  Quit:$$$ISERR(tSC) tSC
	Set ..EnvelopeStream = pEnvelopeStream
	Set ..EnvelopeDoc = pEnvelopeDoc
	Set ..Doc = pBodyDoc
	Quit $$$OK
}

/// Need to clean up EnvelopeDoc & Doc
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private ]
{
	New %tID  Set %tID=$$$oidPrimary(oid)
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	Try { 
		Set tEnvelopeDoc = $PROPERTY($CLASSMETHOD($CLASSNAME(),"%OpenId",%tID),"EnvelopeDoc")
		If $IsObject(tEnvelopeDoc),(tEnvelopeDoc.%Id()'="") {Set tEnvDocId = tEnvelopeDoc.%Id(), tEnvDocClass = $classname(tEnvelopeDoc),tEnvelopeDoc="", tSC = $CLASSMETHOD(tEnvDocClass,"%DeleteId",tEnvDocId) }
		Set tDoc = $PROPERTY($CLASSMETHOD($CLASSNAME(),"%OpenId",%tID),"Doc")
		If $IsObject(tDoc),(tDoc.%Id()'="") {Set tDocId = tDoc.%Id(), tDocClass = $classname(tDoc),tDoc="", tSC = $CLASSMETHOD(tDocClass,"%DeleteId",tDocId) }
	} Catch e {}
	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	New %tID  Set %tID={%%ID}
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	Try { 
		Set tEnvelopeDoc = $PROPERTY($CLASSMETHOD($CLASSNAME(),"%OpenId",%tID),"EnvelopeDoc")
		If $IsObject(tEnvelopeDoc),(tEnvelopeDoc.%Id()'="") {Set tEnvDocId = tEnvelopeDoc.%Id(), tEnvDocClass = $classname(tEnvelopeDoc),tEnvelopeDoc="", tSC = $CLASSMETHOD(tEnvDocClass,"%DeleteId",tEnvDocId) }
		Set tDoc = $PROPERTY($CLASSMETHOD($CLASSNAME(),"%OpenId",%tID),"Doc")
		If $IsObject(tDoc),(tDoc.%Id()'="") {Set tDocId = tDoc.%Id(), tDocClass = $classname(tDoc),tDoc="", tSC = $CLASSMETHOD(tDocClass,"%DeleteId",tDocId) }
	} Catch e {}
	Quit
}

Storage Default
{
<Data name="GenericMessageDefaultData">
<Subscript>"GenericMessage"</Subscript>
<Value name="1">
<Value>EnvelopeStream</Value>
</Value>
<Value name="2">
<Value>EnvelopeDoc</Value>
</Value>
<Value name="3">
<Value>Doc</Value>
</Value>
</Data>
<Data name="HTTPHeaders">
<Attribute>HTTPHeaders</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.SOAP.GenericMessage.HTTPHeaders"</Subscript>
</Data>
<DefaultData>GenericMessageDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
