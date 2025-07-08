/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Standard deviation ("sub population") Aggregate 
Class %ZEN.Report.Aggregate.StDev Extends %ZEN.Report.CustomAggregate [ Deprecated, System = 4 ]
{

/// Keeps a running count of values processed
Property Count As %Integer [ InitialExpression = 0 ];

/// Array of processed values
Property data As array Of %Integer;

Property preprocessValue As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property postprocessResult As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Processes each new value
Method ProcessValue(pValue As %Double) As %Status
{
	if pValue="" quit $$$OK
	Set pValue = ..%PreProcessValue(pValue, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	Set ..Count=..Count + 1
	Do ..data.SetAt(pValue,..Count)
	
	Quit $$$OK
}

/// Returns the variance of the values processed
/// Note we divide by n-1 since this is unbiased variance
Method GetResult() As %String
{
	// From Numerical Recipes, 3rd edition avoid round-off errors
	Set n =..Count
	If n>1 {
		Set s = 0
		Set ep = 0
		for j=1:1:n Set s = s + ..data.GetAt(j)
		Set ave=s/n
		Set var = 0
		for j=1:1:..Count {
			Set diff = ..data.GetAt(j)-ave
			Set ep = ep + diff
			Set var = var + (diff * diff)
			
		}
		Set var = (var - ((ep*ep)/n))/(n-1)
		Set result = $zsqr(var)
		Set result = ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)	
		Quit result
	} Else {
		Quit 0
	}
}

}
