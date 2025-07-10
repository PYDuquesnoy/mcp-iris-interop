/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonCloudWatch.MetricDataOperation Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Parameter ADAPTER = "EnsLib.AmazonCloudWatch.OutboundAdapter";

Property Adapter As EnsLib.AmazonCloudWatch.OutboundAdapter;

XData MessageMap
{
<MapItems>
  <MapItem MessageType="EnsLib.AmazonCloudWatch.PutMetricDataRequest">
    <Method>PutMetricData</Method>
  </MapItem>
</MapItems>
}

Method PutMetricData(request As EnsLib.AmazonCloudWatch.PutMetricDataRequest, Output response As Ens.Response) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..Adapter.PutMetricData(request.Namespace, request.MetricName, request.MetricValue, request.MetricUnit, request.Dimensions)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
