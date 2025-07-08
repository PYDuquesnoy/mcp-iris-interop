/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SVM.Coefficients Extends node [ System = 4 ]
{

Property numberOfCoefficients As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

Property absoluteValue As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

Property Coefficients As list Of Coefficient(XMLNAME = "Coefficient", XMLPROJECTION = "ELEMENT");

}
