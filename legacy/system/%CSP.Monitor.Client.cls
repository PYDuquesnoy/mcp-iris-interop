/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// This is the client side class for the SOAP Monitor Service.
/// Users must initiate the object, set the Location property before calling the GetMatrix method.
/// Here is an example of invoking this WebService to monitor information from a remote system
/// 
/// set wsclient=##class(%CSP.Monitor.Client).%New()
/// set wsclient.Location="http://www.intersystems.com/csp/enslib/_CSP.Monitor.Server.cls"
/// set matrix=wsclient.GetMatrix("AppStats")
/// 
/// After this, 'matrix' is an object of %CSP.Monitor.Matrix containing the information returned from the server.
/// 
Class %CSP.Monitor.Client Extends %SOAP.WebClient [ System = 4 ]
{

/// This is the namespace used by the Service
Parameter NAMESPACE = "http://tempuri.org";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// This is the name of the Service
Parameter SERVICENAME = "SOAPMonitor";

Method GetMatrix(Type As %String, Parameter As %String = "") As %CSP.Monitor.Matrix [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("GetMatrix").Invoke($this,"http://tempuri.org/%CSP.Monitor.Server.GetMatrix",.Type,.Parameter)
}

Method MessageSearch(FilterObjStr As %Stream.GlobalCharacter, Timeout As %Numeric = -1, NextId As %Integer = 0, Type As %String = "SEARCH") As %XML.DataSet [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("MessageSearch").Invoke($this,"http://tempuri.org/%CSP.Monitor.Server.MessageSearch",.FilterObjStr,.Timeout,.NextId,.Type)
}

Method ResendDuplicatedMessage(OriginalHeaderId As %String, OriginalHeader As %Stream.GlobalBinary, NewTarget As %String = "", NewBody As %Stream.GlobalBinary = {$$$NULLOREF}, NewSource As %String = "", HeadOfQueue As %Boolean = 0, pBodyUseOriginalNode As %String = "") As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("ResendDuplicatedMessage").Invoke($this,"http://tempuri.org/%CSP.Monitor.Server.ResendDuplicatedMessage",OriginalHeaderId,OriginalHeader,NewTarget,NewBody,NewSource,HeadOfQueue,pBodyUseOriginalNode)
}

}
