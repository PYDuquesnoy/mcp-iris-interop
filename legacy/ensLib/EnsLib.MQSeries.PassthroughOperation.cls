/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Accepts objects of type Ens.StreamContainer and saves the encapsulated stream data to a queue using the MQSeries OutboundAdapter.
Class EnsLib.MQSeries.PassthroughOperation Extends Ens.BusinessOperation [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.MQSeries.OutboundAdapter";

Method OnMessage(pRequest As Ens.StreamContainer, Output pResponse As %Persistent) As %Status
{
	Quit:'$IsObject(pRequest.Stream) $$$ERROR($$$EnsErrGeneral,"No Stream contained in StreamContainer Request")
	If pRequest.Stream.%Extends("%AbstractStream")&&(""=$G(pRequest.Stream.Attributes("Source"))) {
		Set tSource=pRequest.Attributes.GetAt("Source")
		Set:""=tSource tSource=$G(pRequest.Stream.Attributes("Filename"))
		Set:""=tSource tSource=pRequest.Attributes.GetAt("Filename")
		Set pRequest.Stream.Attributes("Source")=tSource
	}
	Set tSC=..Adapter.SendMessage(pRequest.Stream)
	Quit tSC
}

}
