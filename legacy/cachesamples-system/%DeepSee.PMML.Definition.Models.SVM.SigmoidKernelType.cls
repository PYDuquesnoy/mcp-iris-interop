/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SVM.SigmoidKernelType Extends KernelType [ System = 4 ]
{

Property gamma As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Property coef0 As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Method %GetKernelFormula(pSupportVector As VectorInstance, Output pFormula As %String) As %Status
{
	set tSC = $$$OK, pFormula = ""
	try {
		
		set tSC = pSupportVector.Array.ValuesAsArray(.tArray)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(tArray(i),1,tValue)
			quit:i=""
			
			set:pFormula'="" pFormula = pFormula _ "+"
			set pFormula = pFormula _ "(x("_i_")*"_tValue_")"
		}
		
		set pFormula = "(" _ $s(..gamma'=1:..gamma _ "*", 1:"") _ "("_pFormula_")" _ $s(..coef0:" + " _ ..coef0, 1:"") _ ")"
		
		// hyperbolic tangent
		set pFormula = "(1-$zexp(-2*"_pFormula_"))/(1+$zexp(-2*"_pFormula_"))"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
