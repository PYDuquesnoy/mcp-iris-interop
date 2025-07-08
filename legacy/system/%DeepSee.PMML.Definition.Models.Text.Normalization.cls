/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Text.Normalization Extends %DeepSee.PMML.Definition.node [ System = 3 ]
{

Parameter XMLNAME = "TextModelNormalization";

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property localTermWeights As %DeepSee.PMML.Datatype.String(VALUELIST = ",termFrequency,binary,logarithmic,augmentedNormalizedTermFrequency", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "termFrequency" ];

Property globalTermWeights As %DeepSee.PMML.Datatype.String(VALUELIST = ",inverseDocumentFrequency,none,GFIDF,normal,probabilisticInverse", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "inverseDocumentFrequency" ];

Property documentNormalization As %DeepSee.PMML.Datatype.String(VALUELIST = ",none,cosine", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "none" ];

}
