/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMSPEX.OutboundAdapter Extends (EnsLib.PEX.OutboundAdapter, EnsLib.JMSPEX.Common, EnsLib.Messaging.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.enslib.jmspex.JMSOutboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetMessagingClientJARPaths()
	Quit ##super()
}

Method SendMessage(message As EnsLib.JMSPEX.Message) As %Status
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
