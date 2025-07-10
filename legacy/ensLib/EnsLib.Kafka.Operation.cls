/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.Kafka.Operation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.Kafka.OutboundAdapter";

Property Adapter As EnsLib.Kafka.OutboundAdapter;

Parameter INVOCATION = "Queue";

/// OnMessage returns a bad status when the adapter fails to send the outgoing Kafka message
Method OnMessage(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent) As %Status
{
	Quit ..Adapter.SendMessage(pRequest)
}

}
