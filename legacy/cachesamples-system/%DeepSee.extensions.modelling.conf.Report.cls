/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.Report Extends (%SerialObject, Operator) [ System = 4 ]
{

Parameter IMPLEMENTINGCLASS = "%DeepSee.extensions.modelling.ContributionReport";

Property type As %EnumString(VALUELIST = ",text,html,csv", XMLPROJECTION = "ATTRIBUTE");

Property classifierType As %EnumString(VALUELIST = ",lda,pca", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property classifierName As %String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property strict As %Boolean(XMLPROJECTION = "ATTRIBUTE");

Property ClassifierClass As %String [ Required ];

Property File As %String;

Property Margin As %Double [ InitialExpression = 0.9 ];

Property TargetValue As %String [ Required ];

Property TargetValue2 As %String;

Method getType() As %String
{
	if (..type '= "") {
		Quit ..type
	}
	
	if ($e(..File,*-4,*) = ".html") {
		Quit "html"
	}
	
	if ($e(..File,*-3,*) = ".csv") {
		Quit "csv"
	}
	
	Quit "text"
}

Storage Default
{
<Data name="ReportState">
<Value name="1">
<Value>type</Value>
</Value>
<Value name="2">
<Value>classifierType</Value>
</Value>
<Value name="3">
<Value>classifierName</Value>
</Value>
<Value name="4">
<Value>strict</Value>
</Value>
<Value name="5">
<Value>ClassifierClass</Value>
</Value>
<Value name="6">
<Value>File</Value>
</Value>
<Value name="7">
<Value>Margin</Value>
</Value>
<Value name="8">
<Value>Target</Value>
</Value>
<Value name="9">
<Value>Target2</Value>
</Value>
<Value name="10">
<Value>TargetValue</Value>
</Value>
<Value name="11">
<Value>TargetValue2</Value>
</Value>
<Value name="12">
<Value>SourceClass</Value>
</Value>
</Data>
<State>ReportState</State>
<StreamLocation>^%DeepSee.extensions59D.ReportS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
