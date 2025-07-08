/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SVM.VectorFields Extends node [ System = 4 ]
{

Property numberOfFields As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

Property FieldRefs As list Of %DeepSee.PMML.Definition.Util.FieldRef(XMLNAME = "FieldRef", XMLPROJECTION = "ELEMENT");

}
