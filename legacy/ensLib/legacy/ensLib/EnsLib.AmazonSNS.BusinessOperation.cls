/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonSNS.BusinessOperation Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Parameter ADAPTER = "EnsLib.AmazonSNS.OutboundAdapter";

Property Adapter As EnsLib.AmazonSNS.OutboundAdapter;

/// SNS topic arn
Property ARNTopic As %String(MAXLEN = 1000);

/// SNS subject
Property Subject As %String(MAXLEN = 1000);

Parameter SETTINGS = "ARNTopic:SNS, Subject:SNS";

XData MessageMap
{
<MapItems>
  <MapItem MessageType="EnsLib.AmazonSNS.PublishRequest">
    <Method>Publish</Method>
  </MapItem>
</MapItems>
}

Method Publish(request As EnsLib.AmazonSNS.PublishRequest, Output response As Ens.Response) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..Adapter.Publish(..ARNTopic, request.Message, ..Subject)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
