/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SVM.VectorDictionary Extends node [ System = 4 ]
{

Property numberOfVectors As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

Property Fields As VectorFields(XMLNAME = "VectorFields", XMLPROJECTION = "ELEMENT");

Property Instances As list Of VectorInstance(XMLNAME = "VectorInstance", XMLPROJECTION = "ELEMENT");

}
