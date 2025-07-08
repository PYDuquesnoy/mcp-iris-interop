/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Aggregate for the median of a set of numerical data. The median is
/// a number with half of the data set of greater value than it, and half
/// of lesser value. For a data set with an odd size, the median is
/// a member of the data set. For a data set with an even size, the median
/// is half-way between two members of the data set.
Class %ZEN.Report.Aggregate.Median Extends %ZEN.Report.CustomAggregate [ Deprecated, System = 4 ]
{

/// Array of processed values
Property Values As array Of %Integer;

/// Number of values processed
Property Count As %Integer [ InitialExpression = 0 ];

/// Processes each new value.
Method ProcessValue(pValue As %Float) As %Status
{
	if pValue="" quit $$$OK
	Set pValue = ..%PreProcessValue(pValue, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	Set ..Count=..Count + 1
	Do ..Values.SetAt(pValue,..Count)
	
	Quit $$$OK
}

/// Returns the median. Returns "" for an empty data set.
/// Uses a divide and conquer selection algorithm.
Method GetResult() As %String
{
	If ..Count=0 {
		Quit ""
	} Else {
		If ..Count # 2 {
			#; odd
			Set k = $number(..Count/2,0)
			Set result=..select(k, 1, ..Count)
			Set result = ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)	
		} Else {
			#; even, so average the two middle values
			Set lower = ..select(..Count/2, 1, ..Count)
			Set higher = ..select(..Count/2 + 1, 1, ..Count)
			Set result = (lower + higher) / 2
			Set result = ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)	
		}
		Quit result
	}
}

/// Select's the kth smallest element in Values
Method select(k, left, right) [ Private ]
{
	While 1 {
		Set pivotIndex = ..partition(left,right,k)
		If k = pivotIndex {
			Set result = ..Values.GetAt(k)
			Quit
		} ElseIf k < pivotIndex {
			Set right = pivotIndex - 1
		} Else {
			Set left = pivotIndex + 1
		}
	}
	Quit result
}

/// Finds the partition point
Method partition(left, right, pivotIndex) [ Private ]
{
	Set pivotValue = ..Values.GetAt(pivotIndex)
	Do ..swap(pivotIndex,right)
	Set storeIndex = left
	For i = left:1:right-1 {
		If ..Values.GetAt(i) <= pivotValue {
			Do ..swap(storeIndex,i)
			Set storeIndex = storeIndex + 1
		}
	}
	Do ..swap(right,storeIndex)
	
	Quit storeIndex
}

Method swap(x, y) [ Private ]
{
	Set tmp = ..Values.GetAt(x)
	Do ..Values.SetAt(..Values.GetAt(y),x)
	Do ..Values.SetAt(tmp,y)
}

}
