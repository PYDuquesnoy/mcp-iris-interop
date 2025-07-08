/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a group definition within a DeepSee Quality Measure.
Class %DeepSee.Model.QualityMeasure.group Extends node [ System = 3 ]
{

/// Quality measure that this group belongs to.
Relationship qualityMeasure As %DeepSee.Model.QualityMeasure.qualityMeasure(XMLPROJECTION = "none") [ Cardinality = one, Inverse = groups ];

/// Additional descriptive text.
Property description As %DeepSee.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Set of elements defined for this group. These define what is in and out of the group.
Relationship elements As %DeepSee.Model.QualityMeasure.element(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = group ];

/// Test if this element's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
		// elements
		Set tElementCount = ..elements.Count()
		For p = 1:1:tElementCount {
			Set tElement = ..elements.GetAt(p)
			If (tElement.disabled) {
				Continue
			}
			Set tName = $$$UPPER(tElement.name)
			If (tName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Element must have a name: " _ p)
				Quit
			}
			ElseIf ($D(tElementNames(tName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Element with duplicate name: " _ tElement.name)
				Quit
			}
			Else {
				Set tElementNames(tName) = ""
			}
			Set tSC = tElement.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
