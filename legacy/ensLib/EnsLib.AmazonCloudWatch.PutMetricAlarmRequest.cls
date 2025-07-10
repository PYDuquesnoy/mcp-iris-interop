/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonCloudWatch.PutMetricAlarmRequest Extends Ens.Request
{

/// The namespace for the metric associated specified in MetricName.
Property Namespace As %String(MAXLEN = 100);

/// The name for the alarm. This name must be unique within the Region.
Property AlarmName As %String(MAXLEN = 100);

/// The name for the metric associated with the alarm.
Property MetricName As %String(MAXLEN = 100);

/// The description for the alarm.
Property AlarmDescription As %String(MAXLEN = 1000);

/// The arithmetic operation to use when comparing the specified statistic and threshold. The possible values are:
/// GreaterThanOrEqualToThreshold 
/// GreaterThanThreshold 
/// GreaterThanUpperThreshold 
/// LessThanLowerOrGreaterThanUpperThreshold 
/// LessThanLowerThreshold 
/// LessThanOrEqualToThreshold 
/// LessThanThreshold 
Property ComparisonOperator As %String(MAXLEN = 100);

/// The statistic for the metric specified in MetricName. The possible values are:
/// Average 
/// Maximum 
/// Minimum 
/// SampleCount 
/// Sum 
Property Statistic As %String(MAXLEN = 100);

/// The unit of measure for the statistic. The possible values are:
/// Bits 
/// BitsSecond 
/// Bytes 
/// BytesSecond 
/// Count 
/// CountSecond 
/// Gigabits 
/// GigabitsSecond 
/// Gigabytes 
/// GigabytesSecond 
/// Kilobits 
/// KilobitsSecond 
/// Kilobytes 
/// KilobytesSecond 
/// Megabits 
/// MegabitsSecond 
/// Megabytes 
/// MegabytesSecond 
/// Microseconds 
/// Milliseconds 
/// None 
/// Percent 
/// Seconds 
/// Terabits 
/// TerabitsSecond 
/// Terabytes 
/// TerabytesSecond 
Property Unit As %String(MAXLEN = 100);

/// The number of periods over which data is compared to the specified threshold.
Property EvaluationPeriods As %Integer;

/// The length, in seconds, used each time the metric specified in MetricName is evaluated.
Property Period As %Integer;

/// The value against which the specified statistic is compared.
Property Threshold As %Double;

/// Indicates whether actions should be executed during any changes to the alarm state.
Property ActionEnabled As %Boolean;

/// /// Metric dimensions. An array of name value pairs in json format.
/// For example, [{"Name":"StorageType","Value":"StandardStorage"},{"Name":"BucketName","Value":"test-fhir"}]
Property Dims As %String(MAXLEN = 1000);

Storage Default
{
<Data name="PutMetricAlarmRequestDefaultData">
<Subscript>"PutMetricAlarmRequest"</Subscript>
<Value name="1">
<Value>Namespace</Value>
</Value>
<Value name="2">
<Value>AlarmName</Value>
</Value>
<Value name="3">
<Value>MetricName</Value>
</Value>
<Value name="4">
<Value>AlarmDescription</Value>
</Value>
<Value name="5">
<Value>ComparisonOperator</Value>
</Value>
<Value name="6">
<Value>Statistic</Value>
</Value>
<Value name="7">
<Value>Unit</Value>
</Value>
<Value name="8">
<Value>EvaluationPeriods</Value>
</Value>
<Value name="9">
<Value>Period</Value>
</Value>
<Value name="10">
<Value>Threshold</Value>
</Value>
<Value name="11">
<Value>ActionEnabled</Value>
</Value>
<Value name="12">
<Value>Dims</Value>
</Value>
</Data>
<DefaultData>PutMetricAlarmRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
