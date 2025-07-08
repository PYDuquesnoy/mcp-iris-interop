/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Regression.NumericPredictor Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property name As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property exponent As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Property coefficient As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
