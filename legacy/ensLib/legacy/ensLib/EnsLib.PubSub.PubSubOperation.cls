/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized routing operation that performs a Publish / Subscribe lookup.
Class EnsLib.PubSub.PubSubOperation Extends EnsLib.PubSub.RoutingOperation [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Users can specify these values in the Configuration Editor
Parameter SETTINGS As %String = "DomainName";

/// This is the Publish/Subscribe domain name to use to find interested subscribers.
Property DomainName As %String(MAXLEN = 100);

/// Look up the given topic in the configured PubSub subscription table.
Method OnRoutingRequest(pRequest As EnsLib.PubSub.Request, Output pResponse As EnsLib.PubSub.Response) As %Status
{
	Set tSC = $$$OK
	
	Do {
		If (pRequest.DomainName '= "") {
			// request has a specific domain name
			Set tDomain = pRequest.DomainName
		}
		Else {
			// use configured Domain Name
			Set tDomain = ..DomainName
		}

		// Find list of interested subscribers		
		Set tSC = ##class(EnsLib.PubSub.Subscription).FindSubscribers(tDomain,pRequest.Topic,.tSubscribers)
		If $$$ISERR(tSC) Quit

		// construct routing response
		Set pResponse = ##class(EnsLib.PubSub.Response).%New()
		
		// add subscriber IDs to list of targets
		Set tSub = $O(tSubscribers(""))
		While (tSub '= "") {
			Do pResponse.TargetList.InsertObjectId(tSub)
			Set tSub = $O(tSubscribers(tSub))
		}

	} While(0)

	Quit tSC
}

}
