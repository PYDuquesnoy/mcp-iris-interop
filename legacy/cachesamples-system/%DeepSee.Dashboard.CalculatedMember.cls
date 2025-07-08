/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a CalculatedMember within a DeepSee saved pivot.<br/>
/// This defines a calculated member that is local to the saved pivot (it is automatically
/// added to the MDX query used for the pivot).
Class %DeepSee.Dashboard.CalculatedMember Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLNAME = "calculatedMember";

Parameter XMLIGNORENULL = 1;

/// Name of the dimension this calculated member belongs to.
/// This does not have to be an existing dimension.
Property dimension As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Name of the calculated member.
Property memberName As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// MDX expression that defines the value of this calculated member.
Property valueExpression As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// Optional format string to apply to this member.
Property formatString As %DeepSee.Datatype.string(MAXLEN = 100, XMLPROJECTION = "attribute");

/// Optional solveOrder to apply to this member.
Property solveOrder As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Copy the contents of this pivot level definition to pivot table level <var>pLevel</var>.
Method %CopyToComponent(pCalcMbr As %DeepSee.Component.calculatedMember) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pCalcMbr.memberName = ..memberName
		Set pCalcMbr.dimension = ..dimension
		Set pCalcMbr.valueExpression = ..valueExpression
		Set pCalcMbr.formatString = ..formatString
		Set pCalcMbr.solveOrder = ..solveOrder
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set the contents of this pivot level definition from pivot table level <var>pLevel</var>.
Method %CopyFromComponent(pCalcMbr As %DeepSee.Component.calculatedMember) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set ..memberName = pCalcMbr.memberName
		Set ..dimension = pCalcMbr.dimension
		Set ..valueExpression = pCalcMbr.valueExpression
		Set ..formatString = pCalcMbr.formatString
		Set ..solveOrder = pCalcMbr.solveOrder
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Storage Default
{
<Data name="CalculatedMemberState">
<Value name="1">
<Value>dimension</Value>
</Value>
<Value name="2">
<Value>memberName</Value>
</Value>
<Value name="3">
<Value>valueExpression</Value>
</Value>
<Value name="4">
<Value>formatString</Value>
</Value>
<Value name="5">
<Value>solveOrder</Value>
</Value>
</Data>
<State>CalculatedMemberState</State>
<StreamLocation>^%DeepSee.D3E8F.CalculatedM7E07S</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
