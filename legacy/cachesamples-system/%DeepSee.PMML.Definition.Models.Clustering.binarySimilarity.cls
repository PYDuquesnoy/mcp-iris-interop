/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Clustering.binarySimilarity Extends ComparisonMetric [ System = 3 ]
{

Property c00 As %DeepSee.PMML.Datatype.Number(XMLNAME = "c00-parameter", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property c01 As %DeepSee.PMML.Datatype.Number(XMLNAME = "c01-parameter", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property c10 As %DeepSee.PMML.Datatype.Number(XMLNAME = "c10-parameter", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property c11 As %DeepSee.PMML.Datatype.Number(XMLNAME = "c11-parameter", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property d00 As %DeepSee.PMML.Datatype.Number(XMLNAME = "d00-parameter", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property d01 As %DeepSee.PMML.Datatype.Number(XMLNAME = "d01-parameter", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property d10 As %DeepSee.PMML.Datatype.Number(XMLNAME = "d10-parameter", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property d11 As %DeepSee.PMML.Datatype.Number(XMLNAME = "d11-parameter", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
