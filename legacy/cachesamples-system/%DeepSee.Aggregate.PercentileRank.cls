/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.Aggregate.PercentileRank Extends aggregate [ System = 4 ]
{

/// Target value 
Property value As %Double;

/// Sorted array of processed values
Property SortedValues [ MultiDimensional ];

/// ProcessValue is called sequentially on each value in a target set. This sorts the values by filing them into the SortedValues array
/// with the incoming value as the first subscript.
Method ProcessValue(pValue As %Double) As %Status
{
	Quit:(pValue="") $$$OK

	Set pValue = ..%PreProcessValue(pValue)
	Set ..Count = ..Count + 1
	Set ..SortedValues(+pValue,..Count)=""
	
	Quit $$$OK
}

/// Returns the percentile rank. Returns 100% for an empty data set.
Method GetResult(Output pStatus As %Status) As %Double
{
    Set pStatus = $$$OK
    Set tResult = ""

    Try {
        If (..Count=0) {
            Set tResult = 100
            Quit
        }

        // Count members in the SortedValues until everything less than or equal to the target value has been counted
        Set CF=0        // Cumulative Frequency of all values less than the target value
        Set F=0         // Frequency of the target value
        Set val="" 
        For { 
            Set val = $O(..SortedValues(val))
            Quit:(val="")||(val>..value)
            
            Set count=""  
            For {
                Set count = $O(..SortedValues(val,count)) 
                Quit:(count="")

                Set:(val<..value) CF=CF+1
                Set:(val=..value) F=F+1
            }
        }
        
        Set tResult = (CF + (0.5*F))*100/..Count
        Set tResult = ..%PostProcessValue(tResult)	
    }
    Catch ex {
        Set pStatus = ex.AsStatus()
        Set tResult = ""
    }
    
    Quit tResult
}

}
