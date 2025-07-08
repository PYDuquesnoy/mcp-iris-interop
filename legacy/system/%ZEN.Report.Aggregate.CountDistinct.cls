/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Aggregate for counting the number of distinct values in a set of data
Class %ZEN.Report.Aggregate.CountDistinct Extends %ZEN.Report.CustomAggregate [ Deprecated, System = 4 ]
{

/// Array of values processed
Property Values As array Of %String;

/// Running count of distinct values processed
Property Count As %Integer [ InitialExpression = 0 ];

/// Processes each new value
Method ProcessValue(pValue As %String) As %Status
{
	if pValue="" quit $$$OK
	//Set pValue = ..%PreProcessValue(pValue, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	If ..Values.GetAt(pValue) {
		#; seen it already
	} Else {
		Do ..Values.SetAt(1,pValue)
		Set ..Count=..Count+1
	}
	
	Quit $$$OK
}

/// Return the count of distinct values processsed
Method GetResult() As %String
{
	Set result=..Count
	Quit ..%PostProcessValue(result,1,..runtimeMode,..ignoreNLS)
}

}
