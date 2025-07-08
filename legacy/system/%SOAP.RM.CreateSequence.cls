/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// CreateSequence is used for request body in WS-ReliableMessaging 1.2.
Class %SOAP.RM.CreateSequence Extends %SOAP.RequestMessage [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-rx/wsrm/200702";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wsrm";

Parameter XMLIGNOREINVALIDTAG = 1;

Property AcksTo As %SOAP.RM.EndpointReference;

Property Expires As %xsd.duration;

Property Offer As %SOAP.RM.Offer;

Property SecurityTokenReference As %SOAP.Security.SecurityTokenReference(REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd", XMLREF = 1);

Property SCTIdentifier As %String(XMLPROJECTION = "none") [ Internal ];

/// The RM sequence which will be associated with the newly created sequence.
Property RMSession As %SYS.RMSession(XMLPROJECTION = "none") [ Internal ];

/// Create a RM sequence with Identifier set and the CreateSequence element for this sequence.
ClassMethod Create(addressingNamespace As %String, oneWay As %Boolean = 0, retryInterval As %Float = 1.0, maxRetryCount As %Integer = 8, expires As %xsd.duration, SSLSecurity As %Boolean = 0) As %SOAP.RM.CreateSequence
{
	Set cs=..%New()
	
	Set session=##class(%SYS.RMSession).%New()
	Set session.RetryInterval=retryInterval
	Set session.MaxRetryCount=maxRetryCount
	Set session.InOrder=1
	Set session.DeliveryAssurance="ExactlyOnce"
	Set session.SSLSecurity=SSLSecurity
	Set cs.RMSession=session
	
	Set namespace=$get(addressingNamespace,"http://www.w3.org/2005/08/addressing")
	Set anonymous=##class(%SOAP.RM.EndpointReference).GetAnonymousEPR(namespace)
	Set anonymous.%Namespace=namespace
	Set cs.AcksTo=anonymous
	Set cs.Expires=$get(expires)
	If 'oneWay {
		Set offer=##class(%SOAP.RM.Offer).%New()
		Set offer.Identifier="urn:uuid:"_$system.Util.CreateGUID()
		Set offer.Endpoint=anonymous
		Set offer.Expires=$get(expires)
		Set cs.Offer=offer
		Set session.ResponseIdentifier=offer.Identifier
	}
	
	Quit cs
}

/// Add reference to SecurityContextToken to CreateSequence
Method AddSTR(sct As %SOAP.WSSC.SecurityContextToken)
{
	Set ..SecurityTokenReference=##class(%SOAP.Security.SecurityTokenReference).GetSCTReference(sct)
	Set ..SCTIdentifier=sct.Identifier
}

}
