/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.RabbitMQ.OutboundAdapter Extends (EnsLib.PEX.OutboundAdapter, EnsLib.RabbitMQ.Common, EnsLib.Messaging.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.enslib.rabbitmq.RabbitMQOutboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetMessagingClientJARPaths()
	Quit ##super()
}

Method SendMessage(message As EnsLib.RabbitMQ.Message) As %Status
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

Method CreateExchange(exchangeName As %String, exchangeType As %String, durable As %Boolean, autoDelete As %Boolean) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.CreateExchange(exchangeName, exchangeType, durable, autoDelete)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method CreateQueue(queueName As %String, durable As %Boolean, exclusive As %Boolean, autoDelete As %Boolean) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.CreateQueue(queueName, durable, exclusive, autoDelete)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method BindQueue(queueName As %String, exchangeName As %String, bindingKeys As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.BindQueue(queueName, exchangeName, bindingKeys)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
