/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Object returned by <class>%CSP.Mgr.GatewayMgr</class>.GetInfo() call.
Class %CSP.Mgr.GatewayInformation Extends (%RegisteredObject, %XML.Adaptor)
{

Parameter XMLIGNOREINVALIDTAG As BOOLEAN = 1;

/// Version of InterSystems IRIS
Property Version As %String;

/// The Gateway build number is made up of two numeric components. The first 
/// number indicates the version of InterSystems IRIS with which the Gateway
/// modules were supplied: e.g. 802 -> 2008.2</br >
/// The second number is the internal Gateway build number. This number is 
/// incremented every time a modification is made to the Gateway modules, and, 
/// because of this, is the critical factor in determining whether of not a 
/// particular feature is include in a particular version.
Property Build As %String;

/// Web Server Name
Property WebServerName As %String;

/// Web Server TCP Port
Property WebServerPort As %String;

/// Name and version of the Web server software responding to the request. 
/// Format: name/version
Property WebServerSoftware As %String(CONTENT = "MIXED");

/// Web Server interface used by the CSP Gateway
Property ActiveInterface As %String;

/// Path to the Gateway's configuration file (CSP.ini) 
Property Configuration As %String(CONTENT = "MIXED");

/// Path to the Gateway's Event Log file (CSP.log) 
Property EventLog As %String(CONTENT = "MIXED");

}
