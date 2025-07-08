/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SVM.SupportVectorMachine Extends node [ System = 4 ]
{

Property targetCategory As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property alternateTargetCategory As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property threshold As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property SupportVectors As SupportVectors(XMLPROJECTION = "ELEMENT");

Property Coefficients As Coefficients(XMLPROJECTION = "ELEMENT");

}
