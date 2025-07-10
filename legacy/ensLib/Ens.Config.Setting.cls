/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Config.Setting Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter XMLIGNORENULL = 1;

Property Target As %String(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "Adapter" ];

Property Name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

Property Value As %String(MAXLEN = "", XMLPROJECTION = "CONTENT");

Method ValueSet(initval) As %Status
{
	Set i%Value=$ZSTrip(initval,"<>WC")
	Quit $$$OK
}

Storage Default
{
<Data name="SettingState">
<Subscript>"Ens.Config.Setting"</Subscript>
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Target</Value>
</Value>
<Value name="3">
<Value>Value</Value>
</Value>
</Data>
<State>SettingState</State>
<StreamLocation>^Ens.Conf.SettingS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
