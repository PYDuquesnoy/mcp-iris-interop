/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implements the Assign Action for SubRules.
Class Ens.Rule.SubAssign Extends Ens.Rule.SubAction [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// To have xsi:type="Assign" instead of "SubAssign".
Parameter XMLTYPE = "Assign";

/// Name of context Property to assign value into.
Property Property As %String(MAXLEN = 128, XMLNAME = "property", XMLPROJECTION = "ATTRIBUTE");

/// Value that is to be assigned.
Property Value As %String(MAXLEN = 128, XMLNAME = "value", XMLPROJECTION = "ATTRIBUTE") [ SqlFieldName = AssignValue ];

/// Generate code for this SubAssign Action.
Method GenerateCode(pCompiler As Compiler, pActionNo As %Integer, pPad As %String = " ") As %Status
{
	Quit ##class(Assign).GenerateCodeInt($this, pCompiler, pActionNo, pPad)
}

Storage Default
{
<Data name="SubAssignDefaultData">
<Subscript>"SubAssign"</Subscript>
<Value name="1">
<Value>Property</Value>
</Value>
<Value name="2">
<Value>Value</Value>
</Value>
</Data>
<DefaultData>SubAssignDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
