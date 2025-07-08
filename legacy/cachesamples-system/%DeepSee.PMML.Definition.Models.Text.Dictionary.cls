/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Text.Dictionary Extends %DeepSee.PMML.Definition.node [ System = 3 ]
{

Parameter XMLNAME = "TextDictionary";

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property Taxonomy As %DeepSee.PMML.Definition.Taxonomy(XMLPROJECTION = "ELEMENT");

Property Terms As %DeepSee.PMML.Definition.Util.Array(XMLNAME = "Array");

}
