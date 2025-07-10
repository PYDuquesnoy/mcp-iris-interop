/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonCloudWatch.MetricAlarmOperation Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Parameter ADAPTER = "EnsLib.AmazonCloudWatch.OutboundAdapter";

Property Adapter As EnsLib.AmazonCloudWatch.OutboundAdapter;

XData MessageMap
{
<MapItems>
  <MapItem MessageType="EnsLib.AmazonCloudWatch.PutMetricAlarmRequest">
    <Method>PutMetricAlarm</Method>
  </MapItem>
</MapItems>
}

Method PutMetricAlarm(request As EnsLib.AmazonCloudWatch.PutMetricAlarmRequest, Output response As Ens.Response) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..Adapter.PutMetricAlarm(request.Namespace, request.AlarmName, request.MetricName, request.AlarmDescription,
		request.ComparisonOperator, request.Statistic, request.Unit,
		request.EvaluationPeriods, request.Period, request.Threshold, request.ActionEnabled,
		request.Dims)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
