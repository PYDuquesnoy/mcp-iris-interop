/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.PCA Extends (%SerialObject, Operator) [ System = 4 ]
{

Parameter IMPLEMENTINGCLASS = "%DeepSee.extensions.modelling.PCA";

Property DimReductionMargin As %Double [ InitialExpression = 0.9 ];

Property ClassifierClass As %String;

Property NumberOfPC As %Integer;

Property ErrorOnMaxPC As %Integer [ InitialExpression = 1 ];

Storage Default
{
<Data name="PCAState">
<Value name="1">
<Value>DimReductionMargin</Value>
</Value>
<Value name="2">
<Value>ClassifierTable</Value>
</Value>
<Value name="3">
<Value>ClassifierClass</Value>
</Value>
<Value name="4">
<Value>NumberOfPC</Value>
</Value>
<Value name="5">
<Value>ErrorOnMaxPC</Value>
</Value>
<Value name="6">
<Value>SourceClass</Value>
</Value>
</Data>
<State>PCAState</State>
<StreamLocation>^%DeepSee.extensions.clD866.PCAS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
