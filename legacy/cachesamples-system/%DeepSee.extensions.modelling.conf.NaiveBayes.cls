/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.NaiveBayes Extends (%SerialObject, Operator) [ System = 4 ]
{

Parameter IMPLEMENTINGCLASS = "%DeepSee.extensions.modelling.NaiveBayes";

Property name As %String(XMLPROJECTION = "ATTRIBUTE");

Property PMMLClassName As %String;

Property verbose As %Boolean(XMLPROJECTION = "ATTRIBUTE");

Property ClassifierClass As %String;

Property Truncate As %Integer;

Property TrainingSetPredicate As %String(MAXLEN = 512) [ InitialExpression = "(c.%ID # 3) > 0" ];

Property TestSetPredicate As %String(MAXLEN = 512);

Property DimReduction As %EnumString(VALUELIST = ",none,pca") [ InitialExpression = "none" ];

Property Values As %String(MAXLEN = 1024);

Storage Default
{
<Data name="NaiveBayesState">
<Value name="1">
<Value>name</Value>
</Value>
<Value name="2">
<Value>verbose</Value>
</Value>
<Value name="3">
<Value>ClassifierClass</Value>
</Value>
<Value name="4">
<Value>EqualProbabilities</Value>
</Value>
<Value name="5">
<Value>TargetValue</Value>
</Value>
<Value name="6">
<Value>EffectiveDim</Value>
</Value>
<Value name="7">
<Value>TrainingSetPredicate</Value>
</Value>
<Value name="8">
<Value>DimReduction</Value>
</Value>
<Value name="9">
<Value>Values</Value>
</Value>
<Value name="10">
<Value>PMMLClassName</Value>
</Value>
<Value name="11">
<Value>Truncate</Value>
</Value>
<Value name="12">
<Value>TestSetPredicate</Value>
</Value>
<Value name="13">
<Value>SourceClass</Value>
</Value>
</Data>
<State>NaiveBayesState</State>
<StreamLocation>^%DeepSee.extensi59D.NaiveBayesS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
