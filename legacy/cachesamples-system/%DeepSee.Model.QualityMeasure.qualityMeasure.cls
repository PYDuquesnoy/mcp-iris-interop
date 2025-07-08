/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object for a DeepSee Quality Measure.<br/>
Class %DeepSee.Model.QualityMeasure.qualityMeasure Extends (node, %CSP.Portal.AbstractPortalModel) [ System = 3 ]
{

/// Name of catalog this quality measure belongs to.
Property catalog As %DeepSee.Datatype.string(MAXLEN = 250, XMLPROJECTION = "attribute") [ Required ];

/// Name of the measure set (within a catalog) this quality measure belongs to.
Property set As %DeepSee.Datatype.string(MAXLEN = 250, XMLPROJECTION = "attribute") [ Required ];

/// Id of this quality measure belongs to. Must be unique within the catalog and set.
Property id As %DeepSee.Datatype.string(MAXLEN = 250, XMLPROJECTION = "attribute") [ Required ];

/// Optional. If this is defined, then this is the full name (with no extension) 
/// of a master quality measure that this measure is <b>linked</b> to. 
/// In this case, the definition of this measure is completely specified
/// by the definition of the master quality measure.
Property linkedTo As %DeepSee.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Name of SubjectArea this quality measure is based on.
Property subjectArea As %DeepSee.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute") [ Required ];

/// Expression used to compute this measure. This is an abstract expression based on
/// groups within this quality measure.
Property expression As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute") [ Required ];

/// Optional URL of site with additional information.
Property href As %ZEN.Datatype.uri(XMLPROJECTION = "attribute");

/// True if this quality measure is published (visible to DeepSee).
Property published As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Format string to apply to this measure.
Property format As %String(XMLPROJECTION = "attribute");

/// Set of groups defined for this quality measure. These are used within the general expression
/// computed by this measure.
Relationship groups As %DeepSee.Model.QualityMeasure.group(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = qualityMeasure ];

/// Set of meta-data elements defined for this quality measure. These provide documentation for the measure.
Relationship metas As %DeepSee.Model.QualityMeasure.meta(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = qualityMeasure ];

/// Brief description of the quality measure.
Property description As %ZEN.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Override name property
Method nameGet() As %String
{
	Quit ..catalog_"/"_..set_"/"_..id
}

/// Validate this model for logical errors.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
		If (..disabled) {
			Quit
		}

		If (..catalog = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Quality Measure must have a catalog name")
			Quit
		}
		If (..set = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Quality Measure must have a measure set name")
			Quit
		}
		If (..id = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Quality Measure must have an id")
			Quit
		}

		If (..catalog["/") {
			Set tSC = $$$ERROR($$$GeneralError,"Catalog name cannot contain '/'.")
			Quit
		}
		If (..set["/") {
			Set tSC = $$$ERROR($$$GeneralError,"Measure Set name cannot contain '/'.")
			Quit
		}
		If (..id["/") {
			Set tSC = $$$ERROR($$$GeneralError,"Measure Id name cannot contain '/'.")
			Quit
		}

		If (..name = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Quality Measure must have a name")
			Quit
		}

		// groups
		Set tGroupCount = ..groups.Count()
		For p = 1:1:tGroupCount {
			Set tGroup = ..groups.GetAt(p)
			If (tGroup.disabled) {
				Continue
			}
			Set tName = $$$UPPER(tGroup.name)
			If (tName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Group must have a name: " _ p)
				Quit
			}
			ElseIf ($D(tGroupNames(tName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Group with duplicate name: " _ tGroup.name)
				Quit
			}
			Else {
				Set tGroupNames(tName) = ""
			}
			Set tSC = tGroup.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// metas
		Set tMetaCount = ..metas.Count()
		For p = 1:1:tMetaCount {
			Set tMeta = ..metas.GetAt(p)
			If (tMeta.disabled) {
				Continue
			}
			Set tName = $$$UPPER(tMeta.name)
			If (tName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Meta must have a name: " _ p)
				Quit
			}
			ElseIf ($D(tMetaNames(tName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Meta with duplicate name: " _ tMeta.name)
				Quit
			}
			Else {
				Set tMetaNames(tName) = ""
			}
			Set tSC = tMeta.%Validate()
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
