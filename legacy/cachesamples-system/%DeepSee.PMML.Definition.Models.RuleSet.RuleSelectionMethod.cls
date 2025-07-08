/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.RuleSet.RuleSelectionMethod Extends %DeepSee.PMML.Definition.node [ System = 3 ]
{

Property criterion As %DeepSee.PMML.Datatype.String(VALUELIST = ",weightedSum,weightedMax,firstHit", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
