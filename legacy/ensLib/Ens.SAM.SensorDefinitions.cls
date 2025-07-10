/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.SAM.SensorDefinitions Extends %RegisteredObject [ Language = objectscript, System = 4 ]
{

/// namespace will be the id label
XData EnsMonitorService [ MimeType = application/json ]
{
{
		"sensorClass":"Ens.SAM.SensorSampler",
		"sensors":[
			{
				"sensorName":"InteropHosts",
				"sensorType":"Gauge",
				"sensorUnit":"",
				"sensorDescription":"Count of host items by Status",
				"sensorLabels" : [
									"production",
									"status",
									"host"
								]
			},
			{
				"sensorName":"InteropQueued",
				"sensorType":"Gauge",
				"sensorUnit":"",
				"sensorDescription":"Count of queued messages for hosts with Queue Count Alert value",
				"sensorLabels": [
									"production",
									"host"
								]
			},
			{
				"sensorName":"InteropAlertDelay",
				"sensorType":"Gauge",
				"sensorUnit":"",
				"sensorDescription":"Count of Host Items that have triggered Alert for Message processing Delay",
				"sensorLabels": [
									"production",
									"host"
								]
			},
			{
				"sensorName":"InteropMessages",
				"sensorType":"CounterWithPerSec",
				"sensorUnit":"",
				"sensorDescription":"Count of Messages processed since production started",
				"sensorLabels": [
									"production",
									"host"
								]
			}
		]
	}
}

XData EnsMonitorServiceDaily [ MimeType = application/json ]
{
{
		"sensorClass":"Ens.SAM.SensorSampler",
		"sensors":[
			{
				"sensorName":"InteropOldestMessageHeaderDays",
				"sensorType":"Gauge",
				"sensorUnit":"days",
				"sensorDescription":"This is a per-production metric showing the age of the oldest message header in days",
				"sensorLabels": [
									"production"
								]
			},
			{
				"sensorName":"InteropOldestMessageHeaderCount",
				"sensorType":"Gauge",
				"sensorUnit":"",
				"sensorDescription":"This is a per-production metric showing counts of message headers for oldest day (iris_interop_oldest_message_header_days)",
				"sensorLabels": [
									"production"
								]
			},
			{
				"sensorName":"InteropHeaderCountOlderThan",
				"sensorType":"Gauge",
				"sensorUnit":"",
				"sensorDescription":"This is a per-production metric showing counts of message headers older than given by label 'days'",
				"sensorLabels": [
									"production",
									"days"
								]
			},
			{
				"sensorName":"InteropSessionCount",
				"sensorType":"Gauge",
				"sensorUnit":"",
				"sensorDescription":"This is a per-production metric showing Count of Unique Sesssions",
				"sensorLabels": [
									"production"
								]
			},
			{
				"sensorName":"InteropNamespaceStorageMB",
				"sensorType":"Gauge",
				"sensorUnit":"megabytes",
				"sensorDescription":"This is a per-production metric showing storage in MB used by namespace in sole use databases",
				"sensorLabels": [
									"production"
								]
			},
			{
				"sensorName":"InteropSessionStorageKB",
				"sensorType":"Gauge",
				"sensorUnit":"kilobytes",
				"sensorDescription":"This is a per-production metric showing average storage in Kb used by a session",
				"sensorLabels": [
									"production"
								]
			}
		]
	}
}

/// sensorDescription and sensorLabels for information
XData EnsActivityOperationBase [ MimeType = application/json ]
{
{
		"sensorClass":"Ens.SAM.SensorSampler",
		"sensors":[
			{
				"sensorName":"InteropSampleCount",
				"sensorType":"GaugeWithPerSec",
				"sensorUnit":"",
				"sensorDescription":"Activity Count of Host Items within the sampling window",
				"sensorLabels" : [
									"production",
									"hosttype",
									"host",
									"messagetype"
								]
			},
			{
				"sensorName":"InteropAvgProcessingTime",
				"sensorType":"Gauge",
				"sensorUnit":"seconds",
				"sensorValueAverageBy":"InteropSampleCount",
				"sensorDescription":"Average time message was being processed by host items",
				"sensorLabels" : [
									"production",
									"hosttype",
									"host",
									"messagetype"
								]
			},
			{
				"sensorName":"InteropAvgQueueingTime",
				"sensorType":"Gauge",
				"sensorUnit":"seconds",
				"sensorValueAverageBy":"InteropSampleCount",
				"sensorDescription":"Average time message was queued before being processed by a host item",
				"sensorLabels" : [
									"production",
									"hosttype",
									"host",
									"messagetype"
								]
			}
		]
	}
}

/// sensorDescription and sensorLabels for information
XData EnsHTTPRequest [ MimeType = application/json ]
{
{
		"sensorClass":"Ens.SAM.SensorSampler",
		"sensors":[
			{
				"sensorName":"InteropHttpSampleCount",
				"sensorType":"GaugeWithPerSec",
				"sensorUnit":"",
				"sensorDescription":"Activity Count of HTTP transmissions within the sampling window",
				"sensorLabels" : [
									"production",
									"host"
								]
			},
			{
				"sensorName":"InteropAvgHttpTtfc",
				"sensorType":"Gauge",
				"sensorUnit":"seconds",
				"sensorValueAverageBy":"InteropHttpSampleCount",
				"sensorDescription":"Average time since start of request to first character of response",
				"sensorLabels" : [
									"production",
									"host"
								]
			},
			{
				"sensorName":"InteropAvgHttpTtlc",
				"sensorType":"Gauge",
				"sensorUnit":"seconds",
				"sensorValueAverageBy":"InteropHttpSampleCount",
				"sensorDescription":"Average time since start of request to last character of response",
				"sensorLabels" : [
									"production",
									"host"
								]
			},
			{
				"sensorName":"InteropAvgHttpSentChars",
				"sensorType":"Gauge",
				"sensorUnit":"",
				"sensorValueAverageBy":"InteropHttpSampleCount",
				"sensorDescription":"Average sent characters per SOAP request",
				"sensorLabels" : [
									"production",
									"host"
								]
			},
			{
				"sensorName":"InteropAvgHttpReceivedChars",
				"sensorType":"Gauge",
				"sensorUnit":"",
				"sensorValueAverageBy":"InteropHttpSampleCount",
				"sensorDescription":"Average received characters per SOAP response",
				"sensorLabels" : [
									"production",
									"host"
								]
			}
		]
	}
}

}
