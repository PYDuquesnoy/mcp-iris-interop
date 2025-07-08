/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Clustering.minkowsky Extends ComparisonMetric [ System = 3 ]
{

Property p As %DeepSee.PMML.Datatype.Number(XMLNAME = "p-parameter", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
