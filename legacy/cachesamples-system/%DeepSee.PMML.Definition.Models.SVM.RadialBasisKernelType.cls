/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SVM.RadialBasisKernelType Extends KernelType [ System = 4 ]
{

Property gamma As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Method %GetKernelFormula(pSupportVector As VectorInstance, Output pFormula As %String) As %Status
{
	set tSC = $$$OK, pFormula = ""
	try {
		
		set tSC = pSupportVector.Array.ValuesAsArray(.tArray)
		quit:$$$ISERR(tSC)
		
		for i = 1:1:tArray {
			set:i>1 pFormula = pFormula _ "+"
			set pFormula = pFormula _ "((x("_i_")-"_$g(tArray(i),0)_")**2)"
		}
		 
		set pFormula = "$zexp(-"_..gamma _ " * (" _ pFormula_"))"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
