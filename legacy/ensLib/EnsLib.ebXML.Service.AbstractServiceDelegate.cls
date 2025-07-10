/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Delegate for customizing the processing of inbound ebXML messages
Class EnsLib.ebXML.Service.AbstractServiceDelegate Extends Ens.AbstractDelegate [ Abstract, System = 4 ]
{

/// TODO: Override this method to determine the Target (i.e. URL) and Action when sending this message
Method RouteMessageToTargetProcessWithTimeout(pSender As %RegisteredObject, ByRef pMessage As EnsLib.ebXML.Message, pHint As %String, ByRef pTarget As %String, ByRef pTimeout As %Integer) As %Status [ Abstract ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// TODO: Override this method to customize the handling of the response to be sent to the remote MHS (if any)
Method ProcessResponseToRemoteMHS(pSender As %RegisteredObject, pRequest As EnsLib.ebXML.Message, ByRef pResponse As EnsLib.ebXML.Message, ByRef pStatus As %Status) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

}
