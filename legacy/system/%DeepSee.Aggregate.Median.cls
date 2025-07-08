/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.Aggregate.Median Extends aggregate [ System = 4 ]
{

/// Returns the median. Returns "" for an empty data set.
/// Uses a divide and conquer selection algorithm.
Method GetResult(Output pStatus As %Status) As %Double
{
    Set pStatus = $$$OK
    Set tResult = ""

    Try {
        Quit:(..Count=0)
        
		If ..Count # 2 {
			#; odd
			Set k = $number(..Count/2,0)
			Set tResult=..select(k, 1, ..Count)
			Set tResult = ..%PostProcessValue(tResult)	
		} Else {
			#; even, so average the two middle values
			Set lower = ..select(..Count/2, 1, ..Count)
			Set higher = ..select(..Count/2 + 1, 1, ..Count)
			Set tResult = (lower + higher) / 2
			Set tResult = ..%PostProcessValue(tResult)	
		}
    }
    Catch ex {
        Set pStatus = ex.As.Status()
        Set tResult = ""
    }

    Quit tResult
}

/// Selects the kth smallest element in the set of values
Method select(k, left, right) [ Private ]
{
	For {
		Set pivotIndex = ..partition(left,right,k)
		If k = pivotIndex {
			Set result = ..data.GetAt(k)
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
	Set pivotValue = ..data.GetAt(pivotIndex)
	Do ..swap(pivotIndex,right)
	Set storeIndex = left
	For i = left:1:right-1 {
		If ..data.GetAt(i) <= pivotValue {
			Do ..swap(storeIndex,i)
			Set storeIndex = storeIndex + 1
		}
	}
	Do ..swap(right,storeIndex)
	
	Quit storeIndex
}

Method swap(x, y) [ Private ]
{
	Set tmp = ..data.GetAt(x)
	Do ..data.SetAt(..data.GetAt(y),x)
	Do ..data.SetAt(tmp,y)
}

}
