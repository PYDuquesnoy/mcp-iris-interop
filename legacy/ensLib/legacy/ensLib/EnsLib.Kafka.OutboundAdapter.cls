/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.Kafka.OutboundAdapter Extends (EnsLib.Messaging.Common, EnsLib.Kafka.Common, EnsLib.PEX.OutboundAdapter) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Kafka producer client ID.
Property ClientID As %String(MAXLEN = 100) [ InitialExpression = "KafkaProduction" ];

Parameter SETTINGS = "ClientID:Kafka Settings";

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.enslib.kafka.KafkaOutboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetMessagingClientJARPaths()
	Quit ##super()
}

Method SendMessage(message As EnsLib.Kafka.Message) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.SendMessage(message)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
