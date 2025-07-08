/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.GeneralRegression.FactorList Extends node [ System = 3 ]
{

Property Predictors As list Of Predictor(XMLNAME = "Predictor", XMLPROJECTION = "ELEMENT");

}
