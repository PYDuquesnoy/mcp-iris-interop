/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonCloudWatch.PutMetricDataRequest Extends Ens.Request
{

/// Metric name space
Property Namespace As %String(MAXLEN = 100);

/// Metric name
Property MetricName As %String(MAXLEN = 100);

/// Metric value
Property MetricValue As %Numeric;

/// Metric unit.
/// For possible units, please refer to https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/cloudwatch/model/StandardUnit.html
Property MetricUnit As %String(MAXLEN = 100);

/// Metric dimensions. An array of name value pairs in json format.
/// For example, [{"Name":"StorageType","Value":"StandardStorage"},{"Name":"BucketName","Value":"test-fhir"}]
Property Dimensions As %String(MAXLEN = 1000);

Storage Default
{
<Data name="PutMetricDataRequestDefaultData">
<Subscript>"PutMetricDataRequest"</Subscript>
<Value name="1">
<Value>Namespace</Value>
</Value>
<Value name="2">
<Value>MetricName</Value>
</Value>
<Value name="3">
<Value>MetricValue</Value>
</Value>
<Value name="4">
<Value>MetricUnit</Value>
</Value>
<Value name="5">
<Value>Dimensions</Value>
</Value>
</Data>
<DefaultData>PutMetricDataRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
