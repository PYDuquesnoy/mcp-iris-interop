/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.Sequence Extends (%SerialObject, Operator) [ System = 4 ]
{

Parameter IMPLEMENTINGCLASS = "%DeepSee.extensions.modelling.ReadSequence";

Parameter APPLYMETHOD = "populate";

Property type As %EnumString(VALUELIST = ",ResultSet,table,array,sql", XMLPROJECTION = "ATTRIBUTE");

Property InstanceIdColumn As %String;

Property AttributeValuesColumn As %String;

Property IgnoreInvalidAttributes As %Boolean [ InitialExpression = 0 ];

Property CorrespondenceColumn As %String [ InitialExpression = "Contribution" ];

Property CorrespondenceType As %String(VALUELIST = ",frequency,spread,contrib,value") [ InitialExpression = "spread" ];

Property OutcomeColumn As %String;

Property InputTable As %String;

Property OutputClass As %String;

Property SQL As %String(MAXLEN = 1024);

/// If <property>InsertOnly</property> is true, the sequence operation will insert new records
/// without checking if one already exists for the Instance ID in the retrieved resultset. This
/// requires the resultset to be sorted by Instance ID !
Property InsertOnly As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Storage Default
{
<Data name="SequenceState">
<Value name="1">
<Value>type</Value>
</Value>
<Value name="2">
<Value>InstanceIdColumn</Value>
</Value>
<Value name="3">
<Value>AttributeValuesColumn</Value>
</Value>
<Value name="4">
<Value>CorrespondenceColumn</Value>
</Value>
<Value name="5">
<Value>CorrespondenceType</Value>
</Value>
<Value name="6">
<Value>OutcomeColumn</Value>
</Value>
<Value name="7">
<Value>OutcomeType</Value>
</Value>
<Value name="8">
<Value>InputTable</Value>
</Value>
<Value name="9">
<Value>OutputClass</Value>
</Value>
<Value name="10">
<Value>SQL</Value>
</Value>
<Value name="11">
<Value>IgnoreInvalidAttributes</Value>
</Value>
<Value name="12">
<Value>SourceClass</Value>
</Value>
<Value name="13">
<Value>InsertOnly</Value>
</Value>
</Data>
<State>SequenceState</State>
<StreamLocation>^%DeepSee.extension59D.SequenceS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
