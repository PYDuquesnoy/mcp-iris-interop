/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Web Service to use for responding to Issue and Cancel WS-SecureConversation requests
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %SOAP.WSSC.Service Extends %SOAP.WebService [ System = 4 ]
{

/// Name of the WebService.
Parameter SERVICENAME = "WSSecureConversation";

/// SOAP Namespace for the WebService
Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512";

/// Namespaces of referenced classes will be used in the WSDL.
Parameter USECLASSNAMESPACES = 1;

Parameter ARGUMENTSTYLE = "message";

Parameter OUTPUTTYPEATTRIBUTE = 0;

/// RequestSecurityToken
Method RequestSecurityToken(RequestSecurityToken As %SOAP.WST.RequestSecurityToken) As %SOAP.WST.RequestSecurityTokenResponseCollection(XMLNAME="RequestSecurityTokenResponseCollection") [ Final, WebMethod ]
{
	If %cspsoapservice.Action=$$$SOAPWSSCTokenRequest {
		Set response=%cspsoapservice.OnStartSecureConversation(RequestSecurityToken)
		If $isobject(response) {
			Set %cspsoapservice.AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultResponseProperties(%cspsoapservice.AddressingIn,$$$SOAPWSSCTokenResponse)
			For i=1:1:response.RequestSecurityTokenResponse.Count() {
				Set token=response.RequestSecurityTokenResponse.GetAt(i).RequestedSecurityToken.token
				If $isobject(token) Do token.Save()
			}
		}

	} ElseIf %cspsoapservice.Action=$$$SOAPWSSCTokenCancelRequest {
		Set response=%cspsoapservice.OnCancelSecureConversation(RequestSecurityToken)
		If $isobject(response) {
			Set %cspsoapservice.AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultResponseProperties(%cspsoapservice.AddressingIn,$$$SOAPWSSCTokenCancelResponse)
		}

	} Else {
		Set response=""
	}
	
	Quit response
}

}
