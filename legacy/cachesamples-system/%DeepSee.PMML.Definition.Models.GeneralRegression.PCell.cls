/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.GeneralRegression.PCell Extends node [ System = 3 ]
{

Property targetCategory As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property parameterName As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property beta As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property df As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE");

}
