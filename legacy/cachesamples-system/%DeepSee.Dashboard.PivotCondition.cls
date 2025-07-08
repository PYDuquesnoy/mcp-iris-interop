/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a formatting condition within a DeepSee saved pivot.<br/>
/// This is used to fill in the values of a pivotCondition within a DeepSee pivot table.
Class %DeepSee.Dashboard.PivotCondition Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLNAME = "formatRule";

Parameter XMLIGNORENULL = 1;

/// Range of cells for which this rule applies.
/// This is comma-seperated list of integers. The list is of the form:<br/>
/// startRow,startCol,endRow,endCol<br/>
/// For now, only the start values are used.
Property range As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Condition operator.
Property operator As %ZEN.Datatype.string(VALUELIST = ",=,<>,>,<,>=,<=,BETWEEN,IN,IS NULL", XMLPROJECTION = "attribute");

/// Value (or values) to test.
/// For IN and BETWEEN this is a comma-delimited list.
Property value As %ZEN.Datatype.csv(XMLPROJECTION = "attribute");

/// CSS style to apply to cells that match this condition.
Property style As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// If defined, replace value with this text.
Property text As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// If defined, replace value with this icon.
Property icon As %ZEN.Datatype.uri(XMLPROJECTION = "attribute");

/// If defined and <property>icon</property> is defined, replace value with this number of icons.
Property iconCount As %ZEN.Datatype.integer(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Copy the contents of this pivot condition definition to pivot table condition <var>pCondition</var>.
Method %CopyToComponent(pCondition As %DeepSee.Component.pivotCondition) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pCondition.range = ..range
		Set pCondition.operator = ..operator
		Set pCondition.value = ..value
		Set pCondition.style = ..style
		Set pCondition.text = ..text
		Set pCondition.icon = ..icon
		Set pCondition.iconCount = ..iconCount
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set the contents of this pivot condition definition from pivot table condition <var>pCondition</var>.
Method %CopyFromComponent(pCondition As %DeepSee.Component.pivotCondition) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set ..range = pCondition.range
		Set ..operator = pCondition.operator
		Set ..value = pCondition.value
		Set ..style = pCondition.style
		Set ..text = pCondition.text
		Set ..icon = pCondition.icon
		Set ..iconCount = pCondition.iconCount
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Storage Default
{
<Data name="PivotConditionState">
<Value name="1">
<Value>range</Value>
</Value>
<Value name="2">
<Value>operator</Value>
</Value>
<Value name="3">
<Value>value</Value>
</Value>
<Value name="4">
<Value>style</Value>
</Value>
<Value name="5">
<Value>text</Value>
</Value>
<Value name="6">
<Value>icon</Value>
</Value>
<Value name="7">
<Value>iconCount</Value>
</Value>
</Data>
<State>PivotConditionState</State>
<StreamLocation>^%DeepSee.Da3E8F.PivotConditionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
