/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.MQTT.Operation.Passthrough Extends Ens.BusinessOperation [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.MQTT.Adapter.Outbound";

Parameter SETTINGS As %String = "-SendSuperSession";

/// Keep sending
Property FailureTimeout As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

Method OnMessage(pRequest As EnsLib.MQTT.Message, Output pResponse As %Library.Persistent) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		Set tSC=..Adapter.Send(pRequest.Topic,pRequest.StringValue)
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

}
