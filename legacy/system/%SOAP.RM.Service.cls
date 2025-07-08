/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Web Service to use for responding to CreateSequence, CloseSequence and TerminateSequence WS-ReliableMessaging requests
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %SOAP.RM.Service Extends %SOAP.WebService [ System = 4 ]
{

/// Name of the WebService.
Parameter SERVICENAME = "WSReliableMessaging";

/// SOAP Namespace for the WebService
Parameter NAMESPACE = "http://docs.oasis-open.org/ws-rx/wsrm/200702";

/// Namespaces of referenced classes will be used in the WSDL.
Parameter USECLASSNAMESPACES = 1;

Parameter ARGUMENTSTYLE = "message";

Parameter OUTPUTTYPEATTRIBUTE = 0;

/// CreateSequence
Method CreateSequence(CreateSequence As %SOAP.RM.CreateSequence) As %SOAP.RM.CreateSequenceResponse [ Final, SoapAction = "http://docs.oasis-open.org/ws-rx/wsrm/200702/CreateSequence", WebMethod ]
{
	If %cspsoapservice.Action'=($$$SOAPWSRMns_"/CreateSequence") Quit ""

	// Only anonymous sequence supported	
	Set namespace=%cspsoapservice.AddressingIn.Namespace()
	If namespace="" Set namespace="http://www.w3.org/2005/08/addressing"
	Set anonymous=##class(%SOAP.RM.EndpointReference).GetAnonymousEPR(namespace)
	Set anonymous.%Namespace=namespace
	If ($isobject(anonymous)&&(CreateSequence.AcksTo.Address'=anonymous.Address)) || ('$isobject(anonymous)&&(CreateSequence.AcksTo.Address'["anonymous")) {
		Do %cspsoapservice.ReturnFault(##class(%SOAP.RM.SequenceFault).MakeFault(%cspsoapservice,1,$$$FAULTClient,"CreateSequenceRefused","Only anonymous AcksTo supported"))
	}
	
	// Use response sequence if offered
	Set discardFollowingFirstGap=0
	Set offer=CreateSequence.Offer
	Set (offerExpires,offerExpiresInSeconds,offerIdentifier)=""
	If offer'="" {
		If ($isobject(anonymous)&&(offer.Endpoint.Address'=anonymous.Address)) || ('$isobject(anonymous)&&(offer.Endpoint.Address'["anonymous")) {
			Do %cspsoapservice.ReturnFault(##class(%SOAP.RM.SequenceFault).MakeFault(%cspsoapservice,1,$$$FAULTClient,"CreateSequenceRefused","Only anonymous Offer Endpoint supported"))
		}
		If $case(offer.IncompleteSequenceBehavior,"":0,"NoDiscard":0,"DiscardFollowingFirstGap":0,:1) {
			Do %cspsoapservice.ReturnFault(##class(%SOAP.RM.SequenceFault).MakeFault(%cspsoapservice,1,$$$FAULTClient,"CreateSequenceRefused","Only NoDiscard supported for IncompleteSequenceBehavior: "_offer.IncompleteSequenceBehavior))
		} ElseIf offer.IncompleteSequenceBehavior="DiscardFollowingFirstGap" {
			Set discardFollowingFirstGap=1
		}

		Set offerExpires=offer.Expires
		If offerExpires'="" {
			Set offerExpiresInSeconds=$zdth(##class(%XML.Implementation).AddDuration($ztimestamp,offerExpires),3)
			Set offerExpiresInSeconds=$piece(offerExpiresInSeconds,",")*86400+($piece(offerExpiresInSeconds,",",2)\1)
		}
		Set offerIdentifier=offer.Identifier
	}
	
	// Validate SecurityContextToken if present
	Set sct=""
	If $isobject(CreateSequence.SecurityTokenReference) {
		Set error=CreateSequence.SecurityTokenReference.ValidateTokenRef("",.tokenType,.sct)
		If (error'="") || (tokenType'=$$$SOAPWSSCToken) || '$isobject(sct) {
			Do %cspsoapservice.ReturnFault(%cspsoapservice.SoapFault=##class(%SOAP.RM.SequenceFault).MakeFault(%cspsoapservice,1,$$$FAULTClient,"CreateSequenceRefused","Invalid reference to SecurityContextToken"))
		}
		Set messageSCT=%cspsoapservice.SecurityContextToken
		If '$isobject(messageSCT) || (messageSCT.Identifier'=sct.Identifier) {
			Do %cspsoapservice.ReturnFault(##class(%SOAP.RM.SequenceFault).MakeFault(%cspsoapservice,1,$$$FAULTClient,"CreateSequenceRefused","SecurityContextToken with id="_sct.Identifier_"was not used in Security header"))
		}
	}
	
	// Create RMSession object
	Set session=##class(%SYS.RMSession).%New()
	Set session.RequestIdentifier="urn:uuid:"_$system.Util.CreateGUID()
	Set session.ResponseIdentifier=offerIdentifier
	Set expires=CreateSequence.Expires
	If expires'="" {
		Set expiresInSeconds=$zdth(##class(%XML.Implementation).AddDuration($ztimestamp,expires),3)
		Set expiresInSeconds=$piece(expiresInSeconds,",")*86400+($piece(expiresInSeconds,",",2)\1)
	}
	If (expires="") || ((offerExpires'="") && (offerExpiresInSeconds<expiresInSeconds)) {
		Set expiresInSeconds=offerExpiresInSeconds
		Set expires=offerExpires
	}
	Set session.ExpiresInSeconds=expiresInSeconds
	Set session.InactivityTimeout=$parameter(%cspsoapservice,"RMINACTIVITYTIMEOUT")
	Set session.AppliesTo=$classname(%cspsoapservice)
	Set session.InOrder=$parameter(%cspsoapservice,"RMINORDER")
	Set session.DeliveryAssurance=$parameter(%cspsoapservice,"RMDELIVERYASSURANCE")
	If discardFollowingFirstGap Set session.DiscardFollowingFirstGap=1
	If $isobject(sct) {
		Set session.SCTIdentifier=sct.Identifier
	}
	
	// Update session based on policy
	If $data(%cspsoapservice.policyAlternative) {
		Merge alternative=%cspsoapservice.policyAlternative
		Do ##class(%SOAP.RM.Policy).UpdateRMSession(session,.alternative,.expires)
	}
	
	// Save the RM session
	Do session.Save()
	
	// Create response
	Set response=##class(%SOAP.RM.CreateSequenceResponse).%New()
	Set response.Identifier=session.RequestIdentifier
	Set response.Expires=expires
	If offer'="" {
		Set accept=##class(%SOAP.RM.Accept).%New()
		Set response.Accept=accept
		Set accept.AcksTo=anonymous
	}
		
	// WS-Addressing Action header required
	If '$isobject(%cspsoapservice.AddressingOut),$isobject(%cspsoapservice.AddressingIn) {
		Set %cspsoapservice.AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultResponseProperties(%cspsoapservice.AddressingIn,$$$SOAPWSRMns_"/CreateSequenceResponse")
	}
	
	// Invoke callback to allow the Security header to be setup by web service implementer.
	Do %cspsoapservice.%OnCreateRMSession(response)

	Quit response
}

/// CloseSequence
Method CloseSequence(CloseSequence As %SOAP.RM.CloseSequence) As %SOAP.RM.CloseSequenceResponse [ Final, SoapAction = "http://docs.oasis-open.org/ws-rx/wsrm/200702/CloseSequence", WebMethod ]
{
	If %cspsoapservice.Action'=($$$SOAPWSRMns_"/CloseSequence") Quit ""
	
	Set identifier=CloseSequence.Identifier
	Set session=##class(%SYS.RMSession).Open(identifier)
	If '$isobject(session) {
		Do %cspsoapservice.ReturnFault(##class(%SOAP.RM.SequenceFault).MakeFault(%cspsoapservice,0,$$$FAULTServer,"UnknownSequence",identifier))
	}
	If 'session.CheckSCT(%cspsoapservice) {
		Do %cspsoapservice.ReturnFault(##class(%SOAP.RM.SequenceFault).MakeFault(%cspsoapservice,0,$$$FAULTServer,"UnknownSequence",identifier_":"_session.SCTIdentifier))
	}
	Set session.Terminated=1
	Do session.Save()
	
	Set ack=##class(%SOAP.RM.SequenceAcknowledgement).%New()
	Set ack.Identifier=session.RequestIdentifier
	Do session.GetRange(ack.AcknowledgementRange)
	If ack.AcknowledgementRange.Count()=0 {
		Set ack.None=$c(0)
	}
	Set ack.Final=$c(0)
	Do %cspsoapservice.HeadersOut.SetAt(ack,"SequenceAcknowledgement")
	
	Set response=##class(%SOAP.RM.CloseSequenceResponse).%New()
	Set response.Identifier=session.RequestIdentifier
		
	// WS-Addressing Action header required
	If '$isobject(%cspsoapservice.AddressingOut),$isobject(%cspsoapservice.AddressingIn) {
		Set %cspsoapservice.AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultResponseProperties(%cspsoapservice.AddressingIn,$$$SOAPWSRMns_"/CloseSequenceResponse")
	}

	Quit response
}

/// TerminateSequence
Method TerminateSequence(TerminateSequence As %SOAP.RM.TerminateSequence) As %SOAP.RM.TerminateSequenceResponse [ Final, SoapAction = "http://docs.oasis-open.org/ws-rx/wsrm/200702/TerminateSequence", WebMethod ]
{
	If %cspsoapservice.Action'=($$$SOAPWSRMns_"/TerminateSequence") Quit ""
	
	Set identifier=TerminateSequence.Identifier
	Set session=##class(%SYS.RMSession).Open(identifier)
	If '$isobject(session) {
		Do %cspsoapservice.ReturnFault(##class(%SOAP.RM.SequenceFault).MakeFault(%cspsoapservice,0,$$$FAULTServer,"UnknownSequence",identifier))
	}
	If 'session.CheckSCT(%cspsoapservice) {
		Do %cspsoapservice.ReturnFault(##class(%SOAP.RM.SequenceFault).MakeFault(%cspsoapservice,0,$$$FAULTServer,"UnknownSequence",identifier_":"_session.SCTIdentifier))
	}
	Set session.Terminated=1
	Do session.Save()
	
	Set ack=##class(%SOAP.RM.SequenceAcknowledgement).%New()
	Set ack.Identifier=session.RequestIdentifier
	Do session.GetRange(ack.AcknowledgementRange)
	If ack.AcknowledgementRange.Count()=0 {
		Set ack.None=$c(0)
	}
	Set ack.Final=$c(0)
	Do %cspsoapservice.HeadersOut.SetAt(ack,"SequenceAcknowledgement")
	
	Set response=##class(%SOAP.RM.TerminateSequenceResponse).%New()
	Set response.Identifier=session.RequestIdentifier
		
	// WS-Addressing Action header required
	If '$isobject(%cspsoapservice.AddressingOut),$isobject(%cspsoapservice.AddressingIn) {
		Set %cspsoapservice.AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultResponseProperties(%cspsoapservice.AddressingIn,$$$SOAPWSRMns_"/TerminateSequenceResponse")
	}

	Quit response
}

}
