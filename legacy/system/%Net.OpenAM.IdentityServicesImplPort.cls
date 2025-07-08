/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.OpenAM.IdentityServicesImplPort Extends %SOAP.WebClient [ System = 4 ]
{

Method attributes(attributeNames As %ListOfDataTypes(ELEMENTTYPE="%String",XMLPROJECTION="element",XMLNAME="attributeNames"), subject As %Net.OpenAM.tns.token) As %Net.OpenAM.tns.userDetails [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("attributes").Invoke($this,"",.attributeNames,.subject)
}

Method authenticate(username As %String, password As %String, uri As %String) As %Net.OpenAM.tns.token [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("authenticate").Invoke($this,"",.username,.password,.uri)
}

Method authorize(uri As %String, action As %String, subject As %Net.OpenAM.tns.token) As %Boolean [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("authorize").Invoke($this,"",.uri,.action,.subject)
}

Method create(identity As %Net.OpenAM.tns.identityDetails, admin As %Net.OpenAM.tns.token) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("create")).Invoke($this,"",.identity,.admin)
}

Method delete(identity As %Net.OpenAM.tns.identityDetails, admin As %Net.OpenAM.tns.token) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("delete")).Invoke($this,"",.identity,.admin)
}

Method getCookieNameForToken() As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("getCookieNameForToken").Invoke($this,"")
}

Method getCookieNamesToForward() As %ListOfDataTypes(ELEMENTTYPE="%String",XMLPROJECTION="element",XMLNAME="return") [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("getCookieNamesToForward").Invoke($this,"")
}

Method isTokenValid(token As %Net.OpenAM.tns.token) As %Boolean [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("isTokenValid").Invoke($this,"",.token)
}

Method log(app As %Net.OpenAM.tns.token, subject As %Net.OpenAM.tns.token, logName As %String, message As %String) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("log")).Invoke($this,"",.app,.subject,.logName,.message)
}

Method logout(subject As %Net.OpenAM.tns.token) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("logout")).Invoke($this,"",.subject)
}

Method read(name As %String, attributes As %ListOfObjects(ELEMENTTYPE="%Net.OpenAM.tns.attribute",XMLPROJECTION="element",XMLNAME="attributes"), admin As %Net.OpenAM.tns.token) As %Net.OpenAM.tns.identityDetails [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("read").Invoke($this,"",.name,.attributes,.admin)
}

Method search(filter As %String, attributes As %ListOfObjects(ELEMENTTYPE="%Net.OpenAM.tns.attribute",XMLPROJECTION="element",XMLNAME="attributes"), admin As %Net.OpenAM.tns.token) As %ListOfDataTypes(ELEMENTTYPE="%String",XMLPROJECTION="element",XMLNAME="return") [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("search").Invoke($this,"",.filter,.attributes,.admin)
}

Method update(identity As %Net.OpenAM.tns.identityDetails, admin As %Net.OpenAM.tns.token) [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Do (..WebMethod("update")).Invoke($this,"",.identity,.admin)
}

/// Non-default elementFormQualified for types XML namespace.
Parameter ELEMENTQUALIFIED = 0;

/// This is the URL used to access the web service.
Parameter LOCATION = "http://glassfish.iscinternal.com:9180/opensso/identityservices/IdentityServices";

/// This is the namespace used by the Service
Parameter NAMESPACE = "http://opensso.idsvcs.identity.sun.com/";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// This is the name of the Service
Parameter SERVICENAME = "IdentityServicesImplService";

/// This is the SOAP version supported by the service.
Parameter SOAPVERSION = 1.1;

}
