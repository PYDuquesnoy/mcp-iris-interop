/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.ModelVerificationField Extends extendableNode [ System = 3 ]
{

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property column As %String(XMLPROJECTION = "ATTRIBUTE");

Property precision As %Double(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = {1E-6} ];

Property zeroThreshold As %Double(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = {1E-16} ];

}
