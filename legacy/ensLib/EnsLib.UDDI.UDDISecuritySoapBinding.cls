/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.UDDISecuritySoapBinding Extends %SOAP.WebClient [ ProcedureBlock, System = 4 ]
{

Method discardauthToken(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1)) As %SOAP.OneWay [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("discard_authToken")).Invoke(##this,"discard_authToken",.authInfo)
}

Method getauthToken(userID As %String(XMLPROJECTION="attribute"), cred As %String(XMLPROJECTION="attribute")) As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("get_authToken").Invoke(##this,"get_authToken",.userID,.cred)
}

/// This is the namespace used by the Service
Parameter NAMESPACE = "urn:uddi-org:api_v3_binding";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// This is the name of the Service
Parameter SERVICENAME = "UDDI_Security_SoapBinding";

/// This is the SOAP version supported by the service.
Parameter SOAPVERSION = 1.1;

/// This is the namespace used for types by the Service
Parameter TYPENAMESPACE = "urn:uddi-org:api_v3";

}
