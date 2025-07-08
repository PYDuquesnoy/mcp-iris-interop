/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.Operation Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Property name As %String(XMLPROJECTION = "ATTRIBUTE");

Property type As %String(XMLPROJECTION = "ATTRIBUTE");

Property id As %String(XMLPROJECTION = "ATTRIBUTE");

Property control As %String(XMLPROJECTION = "ATTRIBUTE");

Property args As %Integer(XMLPROJECTION = "ATTRIBUTE");

Property perform As %String(XMLPROJECTION = "ATTRIBUTE");

Property Operations As array Of Operation(XMLKEYNAME = "order");

Method GetOpId() As %String
{
	if (..id '= "") {
		Quit ..id
	} 
	
	if (..name '= "") {
		Quit ..name
	}
	
	Quit ""
}

Method GetType() As %String
{
	if (..type '= "") {
		Quit ..type
	} 
	
	Quit ..GetOpId()
}

Storage Default
{
<Data name="OperationState">
<Value name="2">
<Value>name</Value>
</Value>
<Value name="3">
<Value>type</Value>
</Value>
<Value name="4">
<Value>Operator</Value>
</Value>
<Value name="5">
<Value>id</Value>
</Value>
<Value name="6">
<Value>perform</Value>
</Value>
<Value name="7">
<Value>Operations</Value>
</Value>
<Value name="8">
<Value>action</Value>
</Value>
<Value name="9">
<Value>args</Value>
</Value>
<Value name="10">
<Value>control</Value>
</Value>
</Data>
<State>OperationState</State>
<StreamLocation>^%DeepSee.extensiD866.OperationS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
