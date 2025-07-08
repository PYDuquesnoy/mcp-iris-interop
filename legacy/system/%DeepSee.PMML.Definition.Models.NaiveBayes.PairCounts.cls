/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.NaiveBayes.PairCounts Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property TargetValueCounts As TargetValueCounts(XMLPROJECTION = "ELEMENT");

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
