/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an conditional formatting rule
/// within a <class>%DeepSee.Component.pivotTable</class> component.
Class %DeepSee.Component.pivotCondition Extends %ZEN.Component.object [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Range of cells for which this rule applies.
Property range As %ZEN.Datatype.string;

/// Condition operator.
Property operator As %ZEN.Datatype.string(VALUELIST = ",=,<>,>,<,>=,<=,BETWEEN,IN,IS NULL");

/// Value (or values) to test.
/// For IN and BETWEEN this is a comma-delimited list.
Property value As %ZEN.Datatype.csv;

/// CSS style to apply to cells that match this condition.
Property style As %ZEN.Datatype.style;

/// If defined, replace value with this text.
Property text As %ZEN.Datatype.string;

/// If defined, replace value with this icon.
Property icon As %ZEN.Datatype.uri;

/// If defined and <property>icon</property> is defined, replace value with this number of icons.
Property iconCount As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// Test if the given cell value matches this condition.
Method %EvaluateCondition(pRow As %Integer, pCol As %Integer, pValue As %String) As %Boolean
{
	If (..range'="") {
		Set tStartRow = $P(..range,",",1)
		Set tStartCol = $P(..range,",",2)
		Set tEndRow = $P(..range,",",3)
		Set tEndCol = $P(..range,",",4)

		Set:(tStartRow'="")&&(tEndRow="") tEndRow = tStartRow
		Set:(tStartCol'="")&&(tEndCol="") tEndCol = tStartCol
		
		If ((tStartRow'="")&&(pRow<+tStartRow)) Quit 0
		If ((tStartCol'="")&&(pCol<+tStartCol)) Quit 0
		If ((tEndRow'="")&&(pRow>+tEndRow)) Quit 0
		If ((tEndCol'="")&&(pCol>+tEndCol)) Quit 0
	}

	Set tTestValue = $P(..value,",",1)
	If (..operator="IN") {
		Set tTest = (","_..value_",")[(","_pValue_",")
	}
	ElseIf (..operator="IS NULL") {
		Set tTest = (pValue="")
	}
	Else {
		Set tTest = (tTestValue="") || $Case(..operator,
			"=":pValue=tTestValue,
			">":pValue>tTestValue,
			">=":pValue>=tTestValue,
			"<":pValue<tTestValue,
			"<=":pValue<=tTestValue,
			"<>":pValue'=tTestValue,
			"BETWEEN":(pValue>=tTestValue)&&(pValue<=$P(..value,",",2)),
			:1)
	}

	Quit tTest
}

}
