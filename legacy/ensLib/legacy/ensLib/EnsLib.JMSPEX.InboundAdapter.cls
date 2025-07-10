/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMSPEX.InboundAdapter Extends (EnsLib.Messaging.Common, EnsLib.JMSPEX.Common, EnsLib.PEX.InboundAdapter) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// JMS queue or topic name
Property QueueOrTopicName As %String(MAXLEN = 100);

/// Parameters to receive messages as JSON string 
Property ReceiveSettings As %String(MAXLEN = 300);

Parameter SETTINGS = "QueueOrTopicName:JMS Settings,ReceiveSettings:JMS Settings";

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.enslib.jmspex.JMSInboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetMessagingClientJARPaths()
	Quit ##super()
}

}
