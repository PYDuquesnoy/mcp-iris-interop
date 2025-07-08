/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.NaiveBayes.TargetValueCounts Extends %DeepSee.PMML.Definition.extendableNode [ System = 4 ]
{

Property Counts As list Of TargetValueCount(XMLNAME = "TargetValueCount", XMLPROJECTION = "ELEMENT");

}
