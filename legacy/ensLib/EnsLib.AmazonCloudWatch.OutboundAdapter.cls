/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonCloudWatch.OutboundAdapter Extends (EnsLib.PEX.OutboundAdapter, EnsLib.Amazon.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.cloud.amazonCW.OutboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetCloudClientJARPaths()
	Quit ##super()
}

Method PutMetricData(namespace As %String, metricName As %String, metricValue As %Numeric, metricUnit As %String, dims As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.putMetricData(namespace, metricName, metricValue, metricUnit, dims)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method PutMetricAlarm(namespace As %String, alarmName As %String, metricName As %String, alarmDescription As %String, comparisonOperator As %String, statistic As %String, unit As %String, evaluationPeriods As %Integer, period As %Integer, threshold As %Double, actionEnabled As %Boolean, dims As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.putMetricAlarm(namespace, alarmName, metricName, alarmDescription,
				comparisonOperator, statistic, unit, 
				evaluationPeriods, period, threshold, actionEnabled,
				dims)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
