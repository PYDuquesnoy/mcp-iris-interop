/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.LDA Extends (%SerialObject, Operator) [ System = 4 ]
{

Parameter IMPLEMENTINGCLASS = "%DeepSee.extensions.modelling.LDA";

Property name As %String(XMLPROJECTION = "ATTRIBUTE");

Property verbose As %Boolean(XMLPROJECTION = "ATTRIBUTE");

Property ClassifierClass As %String;

Property UseMahalanobisDistance As %Boolean;

Property EqualProbabilities As %Boolean [ InitialExpression = 0 ];

Property TargetValue As %String;

Property EffectiveDim As %Integer;

Property TrainingSetPredicate As %String(MAXLEN = 512) [ InitialExpression = "(c.%ID # 3) > 0" ];

Property DimReduction As %EnumString(VALUELIST = ",none,pca") [ InitialExpression = "none" ];

Property Values As %String(MAXLEN = 1024);

Storage Default
{
<Data name="LDAState">
<Value name="1">
<Value>ClassifierClass</Value>
</Value>
<Value name="2">
<Value>UseMahalanobisDistance</Value>
</Value>
<Value name="3">
<Value>EqualProbabilities</Value>
</Value>
<Value name="4">
<Value>TargetValue</Value>
</Value>
<Value name="5">
<Value>TrainingSetPredicate</Value>
</Value>
<Value name="6">
<Value>DimReduction</Value>
</Value>
<Value name="7">
<Value>Values</Value>
</Value>
<Value name="8">
<Value>name</Value>
</Value>
<Value name="9">
<Value>verbose</Value>
</Value>
<Value name="10">
<Value>EffectiveDim</Value>
</Value>
<Value name="11">
<Value>SourceClass</Value>
</Value>
</Data>
<State>LDAState</State>
<StreamLocation>^%DeepSee.extensions.mod59D.LDAS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
