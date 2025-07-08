/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.NaiveBayes.BayesInput Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property DerivedField As %DeepSee.PMML.Definition.DerivedField(XMLPROJECTION = "ELEMENT");

Property PairCounts As list Of PairCounts(XMLPROJECTION = "ELEMENT");

Property fieldName As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property TargetValueStats As list Of TargetValueStat(XMLNAME = "TargetValueStats", XMLPROJECTION = "WRAPPED");

}
