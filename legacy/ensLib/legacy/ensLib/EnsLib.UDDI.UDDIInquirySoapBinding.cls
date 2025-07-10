/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.UDDIInquirySoapBinding Extends %SOAP.WebClient [ ProcedureBlock, System = 4 ]
{

Method findbinding(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), findQualifiers As EnsLib.UDDI.uddi.findQualifiers(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), tModelBag As EnsLib.UDDI.uddi.tModelBag(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), findtModel As EnsLib.UDDI.uddi.findtModel(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="find_tModel",XMLREF=1), categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), maxRows As %xsd.int(XMLPROJECTION="attribute"), serviceKey As EnsLib.UDDI.uddi.serviceKey(XMLPROJECTION="attribute"), listHead As %xsd.int(XMLPROJECTION="attribute"), Output listDescription As EnsLib.UDDI.uddi.listDescription(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output bindingTemplate As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.bindingTemplate",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="bindingTemplate",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("find_binding")).Invoke(##this,"find_binding",.authInfo,.findQualifiers,.tModelBag,.findtModel,.categoryBag,.maxRows,.serviceKey,.listHead,.listDescription,.bindingTemplate,.truncated)
}

Method findbusiness(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), findQualifiers As EnsLib.UDDI.uddi.findQualifiers(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), name As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.name",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="name",XMLREF=1), identifierBag As EnsLib.UDDI.uddi.identifierBag(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), tModelBag As EnsLib.UDDI.uddi.tModelBag(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), findtModel As EnsLib.UDDI.uddi.findtModel(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="find_tModel",XMLREF=1), discoveryURLs As EnsLib.UDDI.uddi.discoveryURLs(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), findrelatedBusinesses As EnsLib.UDDI.uddi.findrelatedBusinesses(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="find_relatedBusinesses",XMLREF=1), maxRows As %xsd.int(XMLPROJECTION="attribute"), listHead As %xsd.int(XMLPROJECTION="attribute"), Output listDescription As EnsLib.UDDI.uddi.listDescription(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output businessInfos As EnsLib.UDDI.uddi.businessInfos(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("find_business")).Invoke(##this,"find_business",.authInfo,.findQualifiers,.name,.identifierBag,.categoryBag,.tModelBag,.findtModel,.discoveryURLs,.findrelatedBusinesses,.maxRows,.listHead,.listDescription,.businessInfos,.truncated)
}

Method findrelatedBusinesses(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), findQualifiers As EnsLib.UDDI.uddi.findQualifiers(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), ByRef businessKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), fromKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), toKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), keyedReference As EnsLib.UDDI.uddi.keyedReference(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), maxRows As %xsd.int(XMLPROJECTION="attribute"), listHead As %xsd.int(XMLPROJECTION="attribute"), Output listDescription As EnsLib.UDDI.uddi.listDescription(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output relatedBusinessInfos As EnsLib.UDDI.uddi.relatedBusinessInfos(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("find_relatedBusinesses")).Invoke(##this,"find_relatedBusinesses",.authInfo,.findQualifiers,.businessKey,.fromKey,.toKey,.keyedReference,.maxRows,.listHead,.listDescription,.relatedBusinessInfos,.truncated)
}

Method findservice(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), findQualifiers As EnsLib.UDDI.uddi.findQualifiers(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), name As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.name",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="name",XMLREF=1), categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), tModelBag As EnsLib.UDDI.uddi.tModelBag(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), findtModel As EnsLib.UDDI.uddi.findtModel(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="find_tModel",XMLREF=1), maxRows As %xsd.int(XMLPROJECTION="attribute"), businessKey As EnsLib.UDDI.uddi.businessKey(XMLPROJECTION="attribute"), listHead As %xsd.int(XMLPROJECTION="attribute"), Output listDescription As EnsLib.UDDI.uddi.listDescription(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output serviceInfos As EnsLib.UDDI.uddi.serviceInfos(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("find_service")).Invoke(##this,"find_service",.authInfo,.findQualifiers,.name,.categoryBag,.tModelBag,.findtModel,.maxRows,.businessKey,.listHead,.listDescription,.serviceInfos,.truncated)
}

Method findtModel(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), findQualifiers As EnsLib.UDDI.uddi.findQualifiers(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), name As EnsLib.UDDI.uddi.name(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), identifierBag As EnsLib.UDDI.uddi.identifierBag(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), maxRows As %xsd.int(XMLPROJECTION="attribute"), listHead As %xsd.int(XMLPROJECTION="attribute"), Output listDescription As EnsLib.UDDI.uddi.listDescription(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output tModelInfos As EnsLib.UDDI.uddi.tModelInfos(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("find_tModel")).Invoke(##this,"find_tModel",.authInfo,.findQualifiers,.name,.identifierBag,.categoryBag,.maxRows,.listHead,.listDescription,.tModelInfos,.truncated)
}

Method getbindingDetail(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), bindingKey As %ListOfDataTypes(ELEMENTTYPE="EnsLib.UDDI.uddi.bindingKey",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="bindingKey",XMLREF=1), Output listDescription As EnsLib.UDDI.uddi.listDescription(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output bindingTemplate As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.bindingTemplate",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="bindingTemplate",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("get_bindingDetail")).Invoke(##this,"get_bindingDetail",.authInfo,.bindingKey,.listDescription,.bindingTemplate,.truncated)
}

Method getbusinessDetail(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), businessKey As %ListOfDataTypes(ELEMENTTYPE="EnsLib.UDDI.uddi.businessKey",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="businessKey",XMLREF=1), Output businessEntity As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessEntity",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="businessEntity",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("get_businessDetail")).Invoke(##this,"get_businessDetail",.authInfo,.businessKey,.businessEntity,.truncated)
}

Method getoperationalInfo(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), entityKey As %ListOfDataTypes(ELEMENTTYPE="EnsLib.UDDI.uddi.uddiKey",XMLPROJECTION="element",XMLNAME="entityKey"), Output operationalInfo As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.operationalInfo",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="operationalInfo",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("get_operationalInfo")).Invoke(##this,"get_operationalInfo",.authInfo,.entityKey,.operationalInfo,.truncated)
}

Method getserviceDetail(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), serviceKey As %ListOfDataTypes(ELEMENTTYPE="EnsLib.UDDI.uddi.serviceKey",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="serviceKey",XMLREF=1), Output businessService As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessService",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="businessService",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("get_serviceDetail")).Invoke(##this,"get_serviceDetail",.authInfo,.serviceKey,.businessService,.truncated)
}

Method gettModelDetail(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), tModelKey As %ListOfDataTypes(ELEMENTTYPE="EnsLib.UDDI.uddi.tModelKey",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="tModelKey",XMLREF=1), Output tModel As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.tModel",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="tModel",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("get_tModelDetail")).Invoke(##this,"get_tModelDetail",.authInfo,.tModelKey,.tModel,.truncated)
}

/// This is the namespace used by the Service
Parameter NAMESPACE = "urn:uddi-org:api_v3_binding";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// This is the name of the Service
Parameter SERVICENAME = "UDDI_Inquiry_SoapBinding";

/// This is the SOAP version supported by the service.
Parameter SOAPVERSION = 1.1;

/// This is the namespace used for types by the Service
Parameter TYPENAMESPACE = "urn:uddi-org:api_v3";

}
