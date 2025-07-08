/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SVM.LinearKernelType Extends KernelType [ System = 4 ]
{

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
		 
		set pFormula = "("_pFormula_")"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
