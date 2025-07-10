/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Delegate for routing outbound ebXML messages
Class EnsLib.ebXML.Operation.AbstractOperationDelegate Extends Ens.AbstractDelegate [ Abstract, System = 4 ]
{

/// TODO: Override this method to determine the Target (i.e. URL) and Action when sending this message
Method RouteMessageToTargetMHS(pSender As %RegisteredObject, ByRef pRequest As EnsLib.ebXML.Message, ByRef pTargetUrl As %String, ByRef pSOAPAction As %String) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// TODO: Override this method to customize the handling of the response from the remote MHS.
/// NOTE: It is valid, if not normal for pResponse to be null (unless SyncReply is set in the request)
Method ProcessTargetMHSResponse(pSender As %RegisteredObject, pRequest As EnsLib.ebXML.Message, ByRef pResponse As EnsLib.ebXML.Message) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

}
