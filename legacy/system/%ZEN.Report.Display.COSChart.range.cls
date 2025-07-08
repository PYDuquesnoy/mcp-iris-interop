/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.range Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property minValue As %Double;

Property maxValue As %Double;

Property minValue2 As %Double;

Property maxValue2 As %Double;

Storage Default
{
<Data name="rangeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>minValue</Value>
</Value>
<Value name="3">
<Value>maxValue</Value>
</Value>
<Value name="4">
<Value>minValue2</Value>
</Value>
<Value name="5">
<Value>maxValue2</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Display2E79.rangeD</DataLocation>
<DefaultData>rangeDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%ZEN.Report.Display2E79.rangeD</IdLocation>
<IndexLocation>^%ZEN.Report.Display2E79.rangeI</IndexLocation>
<StreamLocation>^%ZEN.Report.Display2E79.rangeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
