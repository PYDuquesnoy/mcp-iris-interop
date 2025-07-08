/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for an element within a group definition within a DeepSee Quality Measure.
Class %DeepSee.Model.QualityMeasure.element Extends node [ System = 3 ]
{

/// Group that this element belongs to.
Relationship group As %DeepSee.Model.QualityMeasure.group(XMLPROJECTION = "none") [ Cardinality = one, Inverse = elements ];

/// MDX expression used to compute this measure. This is an mdx expression based on
/// this quality measure's subject area.
Property mdx As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// Test if this element's definition is valid.
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
