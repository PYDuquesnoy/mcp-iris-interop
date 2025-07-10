/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.UDDIValueSetValidationSoapBinding Extends %SOAP.WebClient [ System = 4 ]
{

Method validatevalues(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), businessEntity As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessEntity",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="businessEntity",XMLREF=1), businessService As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessService",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="businessService",XMLREF=1), bindingTemplate As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.bindingTemplate",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="bindingTemplate",XMLREF=1), tModel As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.tModel",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="tModel",XMLREF=1), publisherAssertion As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.publisherAssertion",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="publisherAssertion",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.result",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="result",XMLREF=1) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("validate_values").Invoke(##this,"validate_values",.authInfo,.businessEntity,.businessService,.bindingTemplate,.tModel,.publisherAssertion,.truncated)
}

/// Non-default elementFormQualified for types XML namespace.
Parameter ELEMENTQUALIFIED = 0;

/// This is the namespace used by the Service
Parameter NAMESPACE = "urn:uddi-org:vs_v3_binding";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// This is the name of the Service
Parameter SERVICENAME = "UDDI_ValueSetValidation_SoapBinding";

/// This is the SOAP version supported by the service.
Parameter SOAPVERSION = 1.1;

/// This is the namespace used for types by the Service
Parameter TYPENAMESPACE = "urn:uddi-org:vs_v3";

}
