/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.AbstractExpression Extends %DeepSee.PMML.Definition.node [ Abstract, System = 3 ]
{

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		// verify field name usage
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Returns the COS code to compute this expression. Sets <var>pInline</var> to 1 if the returned
/// string can simply be nested in an enclosing expression. If <var>pInline</var> = 0, the code
/// returned is assumed to populate a variable <var>tValue</var>, with each line prepended with
/// appropriate whitespace to allow simple compilation.</p>
/// <p>If the expression can evaluate to anything other than valid values, an additional variable
/// <var>tStatus</var> should be populated with the appropriate status (which will likely result in
/// <var>pInline</var> being 0)</p>
/// <p>If <var>pOverrideSource</var> is set, it should be used rather than the expected "input"
/// for this expression (ie: ..field)</p>
Method %GetComputeCode(Output pInline As %Boolean = 0, pOverrideSource As %String = "", pThis As %String = ".", pArrayFormat As %Boolean = 0) As %String [ Abstract ]
{
	quit ""
}

/// Returns the names of the fields used by this expression.
/// This method is called recursively on nested expressions so that all fields are appended.
Method %GetInputFields(ByRef pFields) As %Status [ Internal ]
{
	quit $$$OK
}

}
