/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.Kafka.InboundAdapter Extends (EnsLib.Messaging.Common, EnsLib.Kafka.Common, EnsLib.PEX.InboundAdapter) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Topic that the messages are read from.
Property Topic As %String(MAXLEN = 100);

/// Kafka consumer group ID. Within the same group, each message is only read once.
Property GroupID As %String(MAXLEN = 100);

/// Parameters to receive messages as JSON string 
Property ReceiveSettings As %String(MAXLEN = 300);

Parameter SETTINGS = "Topic:Kafka Settings,GroupID:Kafka Settings,ReceiveSettings:Kafka Settings";

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.enslib.kafka.KafkaInboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetMessagingClientJARPaths()
	Quit ##super()
}

}
