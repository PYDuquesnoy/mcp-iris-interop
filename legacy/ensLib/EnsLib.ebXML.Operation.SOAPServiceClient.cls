/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsebXML

/// SOAP Service for ebXML
Class EnsLib.ebXML.Operation.SOAPServiceClient Extends %SOAP.WebClient [ ProcedureBlock, System = 4 ]
{

/// This is the URL used to access the web service.
Parameter LOCATION;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter SERVICENAME = "ebXML";

Parameter SOAPHEADERS = "AckRequested:EnsLib.ebXML.schema.msg.AckRequested,Acknowledgment:EnsLib.ebXML.schema.msg.Acknowledgment,ErrorList:EnsLib.ebXML.schema.msg.ErrorList,MessageHeader:EnsLib.ebXML.schema.msg.MessageHeader,MessageOrder:EnsLib.ebXML.schema.msg.MessageOrder,StatusRequest:EnsLib.ebXML.schema.msg.StatusRequest,StatusResponse:EnsLib.ebXML.schema.msg.StatusResponse,SyncReply:EnsLib.ebXML.schema.msg.SyncReply";

Parameter ARGUMENTSTYLE = "message";

/// Custom SOAPAction header
Property CustomSOAPAction As %String(MAXLEN = 512) [ InitialExpression = {$$$EnsebXMLSOAPAction} ];

/// WebMethod to invoke a SOAP service with an ebXML Manifest.
Method Manifest(pManifest As EnsLib.ebXML.schema.msg.Manifest(XMLNAME="Manifest")) As EnsLib.ebXML.schema.msg.Manifest(XMLNAME="Manifest") [ Final, WebMethod ]
{
	Set:'$IsObject(pManifest) ..WriteSOAPBodyMethod = "outputNoBody"
	Quit ..WebMethod("Manifest").Invoke($this,..CustomSOAPAction,.pManifest)
}

Method outputNoBody(pProxy As %SOAP.Descriptor, pTag As %String) As %Status
{
	Quit $$$OK
}

}
