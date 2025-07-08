/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Regression.PredictorTerm Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property FieldRefs As list Of %DeepSee.PMML.Definition.Util.FieldRef(XMLNAME = "FieldRef", XMLPROJECTION = "ELEMENT");

Property name As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property coefficient As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
