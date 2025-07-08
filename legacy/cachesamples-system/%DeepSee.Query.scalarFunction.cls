/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// This class defines the set of scalar functions allowed within DeepSee queries.<br/>
Class %DeepSee.Query.scalarFunction Extends %RegisteredObject [ System = 3 ]
{

/// Test if <var>pFunc</var> is a scalar function.
/// Return -1 if function is not a scalar function, otherwise 
/// return the number of arguments and (total number of) optional arguments (args:optargs) expected by the function.
ClassMethod %IsScalarFunction(pFunc As %String) As %String
{
	Quit $CASE($$$UPPER(pFunc),"SQRT":1,"LOG":1,"POWER":2,"LOOKUP":"2:4","ISNULL":2,"ROUND":"1:2",:-1)
}

/// Evaluate the given scalar function, <var>pFunc</var>, and return the result.
ClassMethod %EvaluateScalar(pFunc As %String, pValue1 As %String = "", pValue2 As %String = "", pValue3 As %String = "", pValue4 As %String = "") As %String
{
	Set tValue = "N/A"
	Try {
		// dispatch to method
		Set tValue = $Case($$$UPPER(pFunc),
			"SQRT":..SQRT(pValue1),
			"LOG":..LOG(pValue1),
			"LOOKUP":..LOOKUP(pValue1,pValue2,pValue3,pValue4),
			"POWER":..POWER(pValue1,pValue2),
			"ISNULL":..ISNULL(pValue1,pValue2),
			"ROUND":..ROUND(pValue1,pValue2),
			:"N/A")
	}
	Catch(ex) {
		Set tValue = $ZE
	}

	Quit tValue
}

/// Square root scalar function.
ClassMethod SQRT(pValue As %Double) As %Double
{
	Quit $ZSQR(pValue)
}

/// Log base 10 scalar function.
ClassMethod LOG(pValue As %Double) As %Double
{
	Quit $ZLOG(pValue)
}

/// Power scalar function.
ClassMethod POWER(pValue As %Double, pArg As %Double) As %Double
{
	Quit $ZPOWER(pValue,pArg)
}

/// Lookup a value in a term list.
ClassMethod LOOKUP(pTermList As %String, pKey As %String, pDefault As %String = "", pField As %String = "") As %String
{
	Quit ##class(%DeepSee.TermList).%Lookup(pTermList,pKey,pField,pDefault)
}

/// IsNull scalar function: If value is "", return replacment,
ClassMethod ISNULL(pValue As %Double, pReplacement As %Double) As %Double
{
	Quit $S(pValue="":pReplacement,1:pValue)
}

/// Round the given value to <var>pDigits</var> places.
ClassMethod ROUND(pValue As %Double, pDigits As %Integer = 0) As %Double
{
	Quit $FNUMBER(pValue,"",+pDigits)
}

}
