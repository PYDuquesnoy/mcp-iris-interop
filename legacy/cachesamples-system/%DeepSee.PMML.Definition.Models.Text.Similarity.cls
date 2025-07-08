/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Text.Similarity Extends %DeepSee.PMML.Definition.node [ System = 3 ]
{

Parameter XMLNAME = "TextModelSimilarity";

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property similarityType As %DeepSee.PMML.Datatype.String(VALUELIST = ",euclidian,cosine", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
