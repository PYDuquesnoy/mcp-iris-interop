/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %CSP defines the endpoint URL for making a CSP or SOAP request<br>
/// 
Class %CSP.Endpoint Extends %RegisteredObject [ System = 4 ]
{

/// The address of the host
Property Host As %String;

/// The port for the URL
Property Port As %String;

/// The CSP prefix for the URL
Property Prefix As %String;

/// The CSP application used for the web service without trailing /.
Property CSPApplication As %String;

/// The name of the web service class or CSP page class
Property ServiceClass As %String(MAXLEN = 256);

/// The server porion of Locarion
Method GetServerURL(UseSSL As %Boolean = 0) As %String
{
	Set port=$select(..Port="":$select(UseSSL:443,1:80),1:..Port)
	Quit $select(UseSSL:"https",1:"http")_"://"_##class(%Library.NetworkAddress).FormatForHttp(..Host_"|"_port)_$select(..Prefix="":"",1:"/"_..Prefix)
}

/// Get the location URL
Method GetLocation(UseSSL As %Boolean = 0) As %String
{
	Set port=$select(..Port="":$select(UseSSL:443,1:80),1:..Port)
	Quit ..GetServerURL(UseSSL)_..CSPApplication_"/"_..ServiceClass_".cls"
}

}
