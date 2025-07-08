/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.Call Extends (%SerialObject, Operator) [ System = 4 ]
{

Parameter IMPLEMENTINGCLASS = "%DeepSee.extensions.modelling.Call";

Property className As %String(XMLPROJECTION = "ATTRIBUTE");

Property method As %String(XMLPROJECTION = "ATTRIBUTE");

Property parameters As list Of %String(XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

Storage Default
{
<Data name="CallState">
<Value name="1">
<Value>className</Value>
</Value>
<Value name="2">
<Value>method</Value>
</Value>
<Value name="3">
<Value>parameters</Value>
</Value>
<Value name="4">
<Value>SourceClass</Value>
</Value>
</Data>
<State>CallState</State>
<StreamLocation>^%DeepSee.extensions.mo59D.CallS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
