/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for ALL SOAP headers
Class EnsLib.ebXML.SOAPHeader Extends (%SerialObject, %SOAP.Header) [ System = 4 ]
{

Parameter SCHEMAPACKAGE As %String = "EnsLib.ebXML.schema";

/// Override XMLNew to allow for deserializing arrays of SOAP headers.  This is to overcome problems with the XML Import of
/// array properties that contain polymorphic objects (i.e. any non-homogenous array).
ClassMethod XMLNew(document As %XML.Document, node As %Integer, containerOref As %RegisteredObject = "") As EnsLib.ebXML.SOAPHeader
{
	#dim tmpnode As %XML.Node
	#dim header  As %String
	
	// Grab the XML node element (that'll be the <Array> tag)
	Set tmpnode=document.GetNode(node)
	
	// The <Array> tag has a key attribute that should be the message header name
	Set header=tmpnode.GetAttributeValue("HeadersKey")
	
	Quit $CASE(header,
				"":$$$NULLOREF,
				  :$CLASSMETHOD(..#SCHEMAPACKAGE_".msg."_header,"%New"))
}

Storage Default
{
<Data name="SOAPHeaderState">
<Value name="1">
<Value>Fault</Value>
</Value>
<Value name="2">
<Value>actor</Value>
</Value>
<Value name="3">
<Value>mustUnderstand</Value>
</Value>
<Value name="4">
<Value>%headerId</Value>
</Value>
<Value name="5">
<Value>XmlId</Value>
</Value>
<Value name="6">
<Value>HeaderBufferIndex</Value>
</Value>
<Value name="7">
<Value>rewriteTag</Value>
</Value>
<Value name="8">
<Value>rewriteFmt</Value>
</Value>
<Value name="9">
<Value>rewriteNamespaces</Value>
</Value>
<Value name="10">
<Value>rewriteMimeAttachments</Value>
</Value>
</Data>
<State>SOAPHeaderState</State>
<StreamLocation>^EnsLib.ebXML.SOAPHeaderS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
