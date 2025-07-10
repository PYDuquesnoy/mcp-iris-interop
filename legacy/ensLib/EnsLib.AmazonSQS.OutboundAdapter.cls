/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonSQS.OutboundAdapter Extends (EnsLib.PEX.OutboundAdapter, EnsLib.Amazon.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.enslib.sqs.SQSOutboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetMessagingClientJARPaths()
	Quit ##super()
}

Method SendMessage(msg As EnsLib.AmazonSQS.Message) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.SendMessage(msg)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
