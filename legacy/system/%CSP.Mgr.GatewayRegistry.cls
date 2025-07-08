/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <class>%CSP.Mgr.GatewayRegistry</class> is a registry of gateways which 
/// provide gateway management functionality. 
/// <p>There are two types of gateway entries: <i>active</i> and <i>inactive</i>. 
/// Active gateway entries on gateways currently attached to the currently-running instance of InterSystems IRIS. 
/// Each active gateway is entered in to the historic list, where it is kept for a  month. As such the 
/// historic list contains both active and inactive gateways, i.e., those not currently attached to 
/// the currently running instance of InterSystems IRIS. 
/// </p>
Class %CSP.Mgr.GatewayRegistry [ Abstract, System = 4 ]
{

/// <p><method>GetGatewayMgrs</method> returns a set of managers for known gateways.</p>
/// <p>See class description for explanation of gateway types.</p> 
/// <p><i>type</i> indicates the type of gateways desired. <p>
/// <ul><li>a - active gateways.</li><li>i - inactive gateways</li>
/// <li>b - both inactive and inactive.</li></ul></p>
/// <p><i>return</i>A list of gateway managers: one for each selected gateway entry. Each object will have 
/// the following properties:
/// <ul><li>Server</li>
/// <li>Port</li><li>Version</li><li>IsActive</li><li>LastConnectTime</li></p>
/// <p><b>Security:</b> You must have Use permissions on the "%Admin_Manage" resource to call this method.</p>
Method GetGatewayMgrs(type As %String = "a") As %ListOfObjects
{
}

/// <p><method>RemoveFilesFromCaches</method> removes files from a set of gateways.</p>
/// <p><i>listOfFilenames</i> is a list filenames (%String) to be removed from the specified gateways.
/// A file name may contain a 
/// wildcard, '*'. Use of the wildcard indicates that all files matching the string will 
/// be deleted, e.g., "/csp/myapp/*". An empty list indicates that the entire cache will be cleared.
/// See documentation for <class>%CSP.Mgr.GatewayMgr</class>.<method>ClearCache</method> for a longer explanation of permissible file names.
/// </p>
/// <p><i>type</i> indicates the type of gateways targeted. <p>
/// <ul><li>a - active gateways.</li><li>i - inactive gateways</li>
/// <li>b - both inactive.</li></ul></p>
/// <p><b>Security:</b> You must have Use permissions on the "%Admin_Manage" resource to call this method.</p>
Method RemoveFilesFromCaches(listOfFilenames As %List = "", type As %String = "a") As %Status
{
}

}
