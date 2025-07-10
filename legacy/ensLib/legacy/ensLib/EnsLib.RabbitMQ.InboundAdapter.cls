/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.RabbitMQ.InboundAdapter Extends (EnsLib.Messaging.Common, EnsLib.RabbitMQ.Common, EnsLib.PEX.InboundAdapter) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// RabbitMQ queue name
Property QueueName As %String(MAXLEN = 100);

/// RabbitMQ exchange name
Property ExchangeName As %String(MAXLEN = 100);

/// RabbitMQ binding keys
Property BindingKeys As %String(MAXLEN = 1000);

/// Parameters to receive messages as JSON string 
Property ReceiveSettings As %String(MAXLEN = 300);

Parameter SETTINGS = "QueueName:RabbitMQ Settings,ExchangeName:RabbitMQ Settings,BindingKeys:RabbitMQ Settings,ReceiveSettings:RabbitMQ Settings";

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.enslib.rabbitmq.RabbitMQInboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetMessagingClientJARPaths()
	Quit ##super()
}

}
