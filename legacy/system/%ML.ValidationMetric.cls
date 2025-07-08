/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ML.ValidationMetric Extends %Persistent [ System = 4 ]
{

Property ValidationRun As ValidationRun [ Required ];

Property MetricName As %String(MAXLEN = 200);

Property MetricValue As %Numeric;

Property TargetValue As %String(MAXLEN = 2000);

Storage Default
{
<Data name="ValidationMetricDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ValidationRun</Value>
</Value>
<Value name="3">
<Value>MetricName</Value>
</Value>
<Value name="4">
<Value>MetricValue</Value>
</Value>
<Value name="5">
<Value>TargetValue</Value>
</Value>
</Data>
<DataLocation>^IRIS.ML.ValidationMetricD</DataLocation>
<DefaultData>ValidationMetricDefaultData</DefaultData>
<IdLocation>^IRIS.ML.ValidationMetricD</IdLocation>
<IndexLocation>^IRIS.ML.ValidationMetricI</IndexLocation>
<StreamLocation>^IRIS.ML.ValidationMetricS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
