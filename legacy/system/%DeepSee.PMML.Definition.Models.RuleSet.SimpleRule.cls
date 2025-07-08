/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.RuleSet.SimpleRule Extends Rule [ System = 3 ]
{

Property ScoreDistributions As list Of %DeepSee.PMML.Definition.Models.Trees.ScoreDistribution(XMLNAME = "ScoreDistribution", XMLPROJECTION = "ELEMENT");

Property id As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property score As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property recordCount As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Property nbCorrect As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Property confidence As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Property weight As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

}
