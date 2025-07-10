/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonSQS.InboundAdapter Extends (EnsLib.Amazon.Common, EnsLib.PEX.InboundAdapter) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Queue name
Property Queue As %String(MAXLEN = 100) [ Required ];

/// Delete message on server after receive
Property DeleteAfterReceive As %Boolean [ InitialExpression = 1 ];

/// Parameters to receive messages as JSON string 
Property ReceiveSettings As %String(MAXLEN = 300);

Parameter SETTINGS = "Queue:Amazon SQS,DeleteAfterReceive:Amazon SQS,ReceiveSettings:Amazon SQS";

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.enslib.sqs.SQSInboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetMessagingClientJARPaths()
	Quit ##super()
}

}
