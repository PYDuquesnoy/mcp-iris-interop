/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.GeneralRegression.PPCell Extends node [ System = 3 ]
{

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property predictorName As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property parameterName As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property targetCategory As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

}
