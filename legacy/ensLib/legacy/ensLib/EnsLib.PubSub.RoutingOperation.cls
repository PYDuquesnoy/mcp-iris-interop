/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for message routing operations
Class EnsLib.PubSub.RoutingOperation Extends Ens.BusinessOperation [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter INVOCATION = "InProc";

XData MessageMap
{
<MapItems>
	<MapItem MessageType="EnsLib.PubSub.Request"> 
		<Method>RoutingHandler</Method>
	</MapItem>
</MapItems>
}

/// Process an incoming RoutingRequest
Method RoutingHandler(pRequest As EnsLib.PubSub.Request, Output pResponse As EnsLib.PubSub.Response) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		// dispatch to user callback
		Set tSC = ..OnRoutingRequest(pRequest, .pResponse)
	} While (0)

Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method is implemented by a subclass to process the actual
/// message routing request.<br>
/// The code to return a message looks like this:
/// <example>
/// 	// construct routing response
/// 	Set pResponse = ##class(EnsLib.PubSub.Response).%New()
/// 	
/// 	Set pTarget = ##class(EnsLib.PubSub.Target).%New(pResponse)
/// 	Set pTarget.Target = "Operation1"
/// 	Do pResponse.TargetList.Insert(pTarget)
/// </example>
Method OnRoutingRequest(pRequest As EnsLib.PubSub.Request, Output pResponse As EnsLib.PubSub.Response) As %Status
{
	// override this in a subclass
	Quit $$$ERROR($$$NotImplemented)
}

}
