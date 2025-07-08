/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.Table Extends (%SerialObject, Operator) [ System = 4 ]
{

Property ClassName As %String;

Property hasOutcome As %Boolean(XMLPROJECTION = "ATTRIBUTE");

Property InstanceType As %String [ InitialExpression = "%String" ];

Property OutcomeColumn As %String [ InitialExpression = "Outcome" ];

Property OutcomeType As %String [ InitialExpression = "%String" ];

Property MaxPC As %Integer [ InitialExpression = 0 ];

Property Attributes As Attributes;

Parameter IMPLEMENTINGCLASS = "%DeepSee.extensions.modelling.TableGenerator";

Storage Default
{
<Data name="TableState">
<Value name="1">
<Value>className</Value>
</Value>
<Value name="2">
<Value>hasOutcome</Value>
</Value>
<Value name="3">
<Value>InstanceType</Value>
</Value>
<Value name="4">
<Value>OutcomeColumn</Value>
</Value>
<Value name="5">
<Value>OutcomeType</Value>
</Value>
<Value name="6">
<Value>MaxPC</Value>
</Value>
<Value name="7">
<Value>Attributes</Value>
</Value>
<Value name="8">
<Value>ClassName</Value>
</Value>
<Value name="9">
<Value>SourceClass</Value>
</Value>
</Data>
<State>TableState</State>
<StreamLocation>^%DeepSee.extensionsD866.TableS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
