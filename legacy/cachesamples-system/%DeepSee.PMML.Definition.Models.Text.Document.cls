/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Text.Document Extends %DeepSee.PMML.Definition.node [ System = 3 ]
{

Parameter XMLNAME = "TextDocument";

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property id As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property name As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property length As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

Property file As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

}
