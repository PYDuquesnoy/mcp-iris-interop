/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Studio.SourceControl.ItemSetWS Extends %SOAP.WebClient [ System = 4 ]
{

/// This Parameter should be updated when synced from Perforce
Parameter SrcVer = "$Id: //iris/2025.1.0/databases/sys/cls/Studio/SourceControl/ItemSetWS.xml#1 $";

/// Revision number of this class when compiled as part of the //custom_ccrs/_common/config/... branch.  
/// This version will not be updated (by design) when the class is integrated to other branches.
/// This allows the user to tell what version of the Studio client tools are in use.
Parameter Version = 18;

/// This is the URL used to access the web service.
Parameter LOCATION = "https://ccr.intersystems.com/ccr/CCR.ItemSet.WebService.cls";

/// This is the namespace used by the Service
Parameter NAMESPACE = "http://www.intersystems.com/ccr/v1";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// This is the name of the Service
Parameter SERVICENAME = "CCRItemSetWS";

/// Use PPG Memory as opposed to process memory for XML reader
Parameter USEPPGHANDLER = 1;

Property APIKey As %String(TRUNCATE = 1) [ Private ];

Property APISecret As %String(TRUNCATE = 1) [ Private ];

Method GetAPICredentials(ByRef pAPIKey As %String)
{
}

ClassMethod SetAPICredentials(pUsername As %String, pAPIKey As %String, pSecret As %String)
{
}

Method InvokeWebMethod(pAction As %String = "", pJob As %String = "", pEnv As %String = "", pToken As %String = "", ByRef pStr1 As %String = "", ByRef pStr2 As %String = "", ByRef pFile As %FileCharacterStream = "", ByRef pDataSet As %XML.DataSet = "") As %xsd.base64Binary [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
}

/// Handles fetching the override Location if it exists
Method CalcLocation() As %String
{
}

/// Handles all compile-time logic for this class
/// [Previously private]
ClassMethod OnToolsCompile() [ CodeMode = objectgenerator, Internal ]
{
}

Method GetDate() As %String [ Private ]
{
}

/// This method is a callback which will be invoked before invoking transport.DoSOAPRequest() method
/// to make the actual SOAP request.  This method may be override by the user's web client class.
/// DoSOAPRequest is the transport method which is responsible for sending the SOAP request and receiving the response.
/// The default DoSOAPRequest is included in %SOAP.WebClient and uses HTTP for request/response.<br><br>
/// 
/// The mode argument specifies the type of SOAP request "SOAP" or "binary".<br>
/// The client argument is the oref of the web client class.<br>
/// The action argument contains the value of the SOAPAction.<br>
/// The oneWay argument is true if no body is to be sent.
/// The method argument is the name of the WebMethod that is being invoked<br>
/// The requestStream argument contains the SOAP request message in a stream.
/// requestStream may =0 as an optimization to improve SOAP performance.
/// requestStream=0 means that the stream is kept in memory as much as possible with overflow to a global.
/// requestStream may be accessed by using $$$XMLRewind and $$$XMLRead macros.<br>
Method %OnSOAPRequest(mode As %String, client As %SOAP.WebClient, action As %String, oneWay As %Boolean, method As %String, requestStream As %BinaryStream)
{
}

}
