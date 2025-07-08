/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Trees.ScoreDistribution Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property value As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property recordCount As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property confidence As %DeepSee.PMML.Datatype.ProbNumber(XMLPROJECTION = "ATTRIBUTE");

Property probability As %DeepSee.PMML.Datatype.ProbNumber(XMLPROJECTION = "ATTRIBUTE");

}
