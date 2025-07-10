/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonSNS.OutboundAdapter Extends (EnsLib.PEX.OutboundAdapter, EnsLib.Amazon.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.cloud.amazonSNS.OutboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetCloudClientJARPaths()
	Quit ##super()
}

Method Publish(arnTopic As %String, message As %String, subject As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.publish(arnTopic, message, subject)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
