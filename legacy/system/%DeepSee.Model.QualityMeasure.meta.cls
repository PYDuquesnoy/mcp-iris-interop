/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for addition meta-data within a DeepSee Quality Measure. (Don't think too hard about it).
Class %DeepSee.Model.QualityMeasure.meta Extends node [ System = 3 ]
{

/// Quality measure that this meta element belongs to.
Relationship qualityMeasure As %DeepSee.Model.QualityMeasure.qualityMeasure(XMLPROJECTION = "none") [ Cardinality = one, Inverse = metas ];

/// Section name for this meta element. This is used to organize the display of meta elements.
Property section As %DeepSee.Datatype.string(MAXLEN = 512, XMLPROJECTION = "attribute");

/// Content to display for this meta element.
Property content As %ZEN.Datatype.html(CONTENT = "MIXED", ESCAPE = "HTML", XMLPROJECTION = "content");

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
