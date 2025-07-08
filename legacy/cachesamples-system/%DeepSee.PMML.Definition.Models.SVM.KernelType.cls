/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SVM.KernelType Extends node [ Abstract, System = 4 ]
{

Property description As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Method %GetKernelFormula(pSupportVector As VectorInstance, Output pFormula As %String) As %Status [ Abstract ]
{
}

}
