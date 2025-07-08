/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.Aggregate.Percentile Extends aggregate [ System = 4 ]
{

Property percentile As %Double;

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

/// Returns the percentile. Returns "" for an empty data set.
Method GetResult(Output pStatus As %Status) As %Double
{
    Set pStatus = $$$OK
    Set tPercentileValue = ""

    Try {
        Quit:(..Count=0)

        // Assign a position k to all sorted values using $Order over the randomly accumulated SortedValues array
        Set pos=0
        Set val="" 
        For { 
            Set val=$O(..SortedValues(val)) 
            Quit:(val="")  
            
            Set count=""  
            For { 
                Set count=$O(..SortedValues(val,count)) 
                Quit:(count="")
                
                Set tValues($I(pos)) = val
            }
        }
        
        // Determine what position in the ordered set represents the requested percentile. If the PercentilePosition
        // lands exactly on an integer, interpolate the percentile using the average of values at that poistion and the next. 
        Set PercentilePosition =  (..Count / 100) * ..percentile
        If $P(PercentilePosition,".")=PercentilePosition {
            Set Position = PercentilePosition
            Set UseAverage=1
        } 
        Else {
            Set Position = +$P(PercentilePosition+0.5,".")
            Set UseAverage=0
        }

        // Fetch the actual value
        If (Position > 0) && (Position < ..Count) {
            If (UseAverage) {
                Set tPercentileValue = (tValues(Position)+tValues(Position+1))/2
            } 
            Else {
                Set tPercentileValue = tValues(Position)
            }
        } 
        ElseIf (Position = 0) {
            Set tPercentileValue = "" ; not a valid percentile
        } 
        ElseIf (Position = ..Count) {
            Set tPercentileValue = tValues(Position)
        }

        Set tPercentileValue = ..%PostProcessValue(tPercentileValue)
    }
    Catch ex {
        Set pStatus = ex.AsStatus()
        Set tPercentileValue = ""
    }

	Quit tPercentileValue
}

}
