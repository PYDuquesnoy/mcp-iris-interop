/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Regression.RegressionTable Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property NumericPredictors As list Of %DeepSee.PMML.Definition.Models.Regression.NumericPredictor(XMLNAME = "NumericPredictor", XMLPROJECTION = "ELEMENT");

Property CategoricalPredictors As list Of %DeepSee.PMML.Definition.Models.Regression.CategoricalPredictor(XMLNAME = "CategoricalPredictor", XMLPROJECTION = "ELEMENT");

Property PredictorTerms As list Of %DeepSee.PMML.Definition.Models.Regression.PredictorTerm(XMLNAME = "PredictorTerm", XMLPROJECTION = "ELEMENT");

Property intercept As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property targetCategory As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

}
