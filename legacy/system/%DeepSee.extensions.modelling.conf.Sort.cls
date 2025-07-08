/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.Sort Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Property order As %EnumString(VALUELIST = ",desc,asc", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "desc" ];

Property column As %String(XMLPROJECTION = "ATTRIBUTE");

Method toSQL() As %String
{
	Quit ..column_" "_..order
}

Storage Default
{
<Data name="SortState">
<Value name="1">
<Value>order</Value>
</Value>
<Value name="2">
<Value>column</Value>
</Value>
</Data>
<State>SortState</State>
<StreamLocation>^%DeepSee.extensions.cD866.SortS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
