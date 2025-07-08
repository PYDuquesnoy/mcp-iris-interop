/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object for a DeepSee KPI.<br/>
Class %DeepSee.Model.KPI.kpi Extends node [ System = 3 ]
{

/// Specify how the data for this KPI is provided.<br/>
Property sourceType As %DeepSee.Datatype.string(VALUELIST = ",mdx,sql,manual", XMLPROJECTION = "attribute");

/// This is used as the caption text for this KPI.
Property caption As %DeepSee.Datatype.string(MAXLEN = 250, XMLPROJECTION = "attribute");

/// SQL statement used if sourceType is "sql"
Property sql As %DeepSee.Datatype.string(MAXLEN = 4000, XMLPROJECTION = "attribute");

/// MDX statement used if sourceType is "mdx"
Property mdx As %DeepSee.Datatype.string(MAXLEN = 4000, XMLPROJECTION = "attribute");

/// Represents the lower value for meters connected to this KPI.
Property rangeLower As %ZEN.Datatype.float;

/// Represents the upper value for meters connected to this KPI.
Property rangeUpper As %ZEN.Datatype.float;

/// Represents the lower threshold level for meters connected to this KPI.
Property thresholdLower As %ZEN.Datatype.float;

/// Represents the upper threshold level for meters connected to this KPI.
Property thresholdUpper As %ZEN.Datatype.float;

/// Properties defined for this KPI.
Relationship properties As %DeepSee.Model.KPI.property(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = kpi ];

/// Actions defined for this KPI.
Relationship actions As %DeepSee.Model.KPI.action(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = kpi ];

/// Filters defined for this KPI.
Relationship filters As %DeepSee.Model.KPI.filter(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = kpi ];

/// Optional. Name of an additional DeepSee KPI class that provides additional Dashboard Actions for this kpi.<br/>
Property actionClass As %DeepSee.Datatype.className(XMLPROJECTION = "attribute");

/// Validate this model for logical errors.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
		If (..disabled) {
			Quit
		}

		If (..name = "") {
			Set tSC = $$$ERROR($$$GeneralError,"KPI must have a name")
			Quit
		}

		// properties
		Set tPropCount = ..properties.Count()
		For p = 1:1:tPropCount {
			Set tProp = ..properties.GetAt(p)
			If (tProp.disabled) {
				Continue
			}
			Set tName = $$$UPPER(tProp.name)
			If (tName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Property must have a name: " _ p)
				Quit
			}
			ElseIf ($D(tPropNames(tName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Property with duplicate name: " _ tProp.name)
				Quit
			}
			Else {
				Set tPropNames(tName) = ""
			}
			Set tSC = tProp.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// filters
		Set tFilterCount = ..filters.Count()
		For f = 1:1:tFilterCount {
			Set tFilter = ..filters.GetAt(f)
			If (tFilter.disabled) {
				Continue
			}
			Set tName = $$$UPPER(tFilter.name)
			If (tName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Filter must have a name: " _ f)
				Quit
			}
			ElseIf ($D(tFilterNames(tName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Filter with duplicate name: " _ tFilter.name)
				Quit
			}
			Else {
				Set tFilterNames(tName) = ""
			}
			Set tSC = tFilter.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// actions
		Set tActionCount = ..actions.Count()
		For f = 1:1:tActionCount {
			Set tAction = ..actions.GetAt(f)
			If (tAction.disabled) {
				Continue
			}
			Set tName = $$$UPPER(tAction.name)
			If (tName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Action must have a name: " _ f)
				Quit
			}
			ElseIf ($D(tActionNames(tName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Action with duplicate name: " _ tAction.name)
				Quit
			}
			Else {
				Set tActionNames(tName) = ""
			}
			Set tSC = tAction.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
