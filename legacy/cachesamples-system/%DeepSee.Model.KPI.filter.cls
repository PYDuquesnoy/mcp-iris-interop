/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a filter within a DeepSee KPI.
Class %DeepSee.Model.KPI.filter Extends node [ System = 3 ]
{

/// KPI that this property belongs to.
Relationship kpi As %DeepSee.Model.KPI.kpi(XMLPROJECTION = "none") [ Cardinality = one, Inverse = filters ];

/// Logical name of the property controlled by this filter.
Property filterProperty As %String(MAXLEN = 100, XMLPROJECTION = "attribute");

/// Default value to apply to this filter.
Property defaultValue As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Optional. SQL query executed to get list of possible values for this filter.
/// The first query column provides the value for the filter member.
/// The second query column provides the display name for the filter member.
/// If there is only one column, it is provides both value and display name.
/// This is ignored if <property>valueList</property> is defined.
Property sql As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Optional. List of possible values for this filter.
Property valueList As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Optional. List of possible display values for this filter.
Property displayList As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Optional. If true (the default) let the user select multiple values for this filter.
Property multiSelect As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Optional. If defined, this is the logical name of the controlling filter on which this filter depends.
/// In this case, the set of possible values for this filter will depend on the current value
/// of the controlling filter.
Property dependsOn As %String(XMLPROJECTION = "attribute");

/// Optional. If defined, this specified how this filter should be display by the DeepSee
/// searchBox control.
Property searchType As %String(VALUELIST = ",day", XMLPROJECTION = "attribute");

/// Test if this filter's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
