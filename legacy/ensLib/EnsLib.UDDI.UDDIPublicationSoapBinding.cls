/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.UDDIPublicationSoapBinding Extends %SOAP.WebClient [ ProcedureBlock, System = 4 ]
{

Method addpublisherAssertions(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), publisherAssertion As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.publisherAssertion",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="publisherAssertion",XMLREF=1)) As %SOAP.OneWay [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("add_publisherAssertions")).Invoke(##this,"add_publisherAssertions",.authInfo,.publisherAssertion)
}

Method deletebinding(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), bindingKey As %ListOfDataTypes(ELEMENTTYPE="EnsLib.UDDI.uddi.bindingKey",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="bindingKey",XMLREF=1)) As %SOAP.OneWay [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("delete_binding")).Invoke(##this,"delete_binding",.authInfo,.bindingKey)
}

Method deletebusiness(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), businessKey As %ListOfDataTypes(ELEMENTTYPE="EnsLib.UDDI.uddi.businessKey",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="businessKey",XMLREF=1)) As %SOAP.OneWay [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("delete_business")).Invoke(##this,"delete_business",.authInfo,.businessKey)
}

Method deletepublisherAssertions(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), publisherAssertion As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.publisherAssertion",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="publisherAssertion",XMLREF=1)) As %SOAP.OneWay [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("delete_publisherAssertions")).Invoke(##this,"delete_publisherAssertions",.authInfo,.publisherAssertion)
}

Method deleteservice(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), serviceKey As %ListOfDataTypes(ELEMENTTYPE="EnsLib.UDDI.uddi.serviceKey",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="serviceKey",XMLREF=1)) As %SOAP.OneWay [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("delete_service")).Invoke(##this,"delete_service",.authInfo,.serviceKey)
}

Method deletetModel(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), tModelKey As %ListOfDataTypes(ELEMENTTYPE="EnsLib.UDDI.uddi.tModelKey",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="tModelKey",XMLREF=1)) As %SOAP.OneWay [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("delete_tModel")).Invoke(##this,"delete_tModel",.authInfo,.tModelKey)
}

Method getassertionStatusReport(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), completionStatus As EnsLib.UDDI.uddi.completionStatus(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1)) As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.assertionStatusItem",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="assertionStatusItem",XMLREF=1) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("get_assertionStatusReport").Invoke(##this,"get_assertionStatusReport",.authInfo,.completionStatus)
}

Method getpublisherAssertions(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1)) As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.publisherAssertion",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="publisherAssertion",XMLREF=1) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("get_publisherAssertions").Invoke(##this,"get_publisherAssertions",.authInfo)
}

Method getregisteredInfo(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), infoSelection As EnsLib.UDDI.uddi.infoSelection(XMLPROJECTION="attribute"), Output businessInfos As EnsLib.UDDI.uddi.businessInfos(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output tModelInfos As EnsLib.UDDI.uddi.tModelInfos(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("get_registeredInfo")).Invoke(##this,"get_registeredInfo",.authInfo,.infoSelection,.businessInfos,.tModelInfos,.truncated)
}

Method savebinding(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), ByRef bindingTemplate As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.bindingTemplate",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="bindingTemplate",XMLREF=1), Output listDescription As EnsLib.UDDI.uddi.listDescription(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("save_binding")).Invoke(##this,"save_binding",.authInfo,.bindingTemplate,.listDescription,.truncated)
}

Method savebusiness(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), ByRef businessEntity As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessEntity",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="businessEntity",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("save_business")).Invoke(##this,"save_business",.authInfo,.businessEntity,.truncated)
}

Method saveservice(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), ByRef businessService As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessService",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="businessService",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("save_service")).Invoke(##this,"save_service",.authInfo,.businessService,.truncated)
}

Method savetModel(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), ByRef tModel As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.tModel",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="tModel",XMLREF=1), Output truncated As EnsLib.UDDI.uddi.truncated(XMLPROJECTION="attribute")) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("save_tModel")).Invoke(##this,"save_tModel",.authInfo,.tModel,.truncated)
}

Method setpublisherAssertions(authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLREF=1), ByRef publisherAssertion As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.publisherAssertion",XMLPROJECTION="element",REFELEMENTQUALIFIED=1,REFNAMESPACE="urn:uddi-org:api_v3",XMLNAME="publisherAssertion",XMLREF=1)) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("set_publisherAssertions")).Invoke(##this,"set_publisherAssertions",.authInfo,.publisherAssertion)
}

/// This is the namespace used by the Service
Parameter NAMESPACE = "urn:uddi-org:api_v3_binding";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// This is the name of the Service
Parameter SERVICENAME = "UDDI_Publication_SoapBinding";

/// This is the SOAP version supported by the service.
Parameter SOAPVERSION = 1.1;

/// This is the namespace used for types by the Service
Parameter TYPENAMESPACE = "urn:uddi-org:api_v3";

}
