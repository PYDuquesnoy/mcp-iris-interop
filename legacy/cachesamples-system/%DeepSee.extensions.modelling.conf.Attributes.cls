/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.Attributes Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Property input As %EnumString(VALUELIST = ",ResultSet,table,array,sql,$list", XMLPROJECTION = "ATTRIBUTE");

Property dim As %Integer(XMLPROJECTION = "ATTRIBUTE");

Property InputTable As %String;

Property SQL As %String(MAXLEN = 2048);

Property ValueList As %String(MAXLEN = 2048);

Property DisplayList As %String(MAXLEN = 2048);

Property Type As %String [ InitialExpression = "%Integer" ];

Property IdColumn As %String;

Property ValueColumn As %String;

Property TypeColumn As %String;

Property Sort As Sort;

Storage Default
{
<Data name="AttributesState">
<Value name="1">
<Value>input</Value>
</Value>
<Value name="2">
<Value>dim</Value>
</Value>
<Value name="3">
<Value>InputTable</Value>
</Value>
<Value name="4">
<Value>Sort</Value>
</Value>
<Value name="5">
<Value>IdColumn</Value>
</Value>
<Value name="6">
<Value>ValueColumn</Value>
</Value>
<Value name="7">
<Value>SQL</Value>
</Value>
<Value name="8">
<Value>Type</Value>
</Value>
<Value name="9">
<Value>ValueList</Value>
</Value>
<Value name="10">
<Value>DisplayList</Value>
</Value>
<Value name="11">
<Value>TypeColumn</Value>
</Value>
</Data>
<State>AttributesState</State>
<StreamLocation>^%DeepSee.extensD866.AttributesS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
