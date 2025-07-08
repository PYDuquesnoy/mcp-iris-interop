/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.Aggregate.VarP Extends aggregate [ System = 4 ]
{

Property SUMX As %Double [ InitialExpression = 0 ];

Property SUMX2 As %Double [ InitialExpression = 0 ];

Method ProcessValue(pValue As %Double) As %Status
{
    // Full population variance may simply use running tallies for X and X^2 rather than 
    // storing the individual data points
	Quit:(pValue="") $$$OK

	Set pValue = ..%PreProcessValue(pValue)
	Set ..Count = ..Count+1 
	Set ..SUMX = ..SUMX + pValue
	Set ..SUMX2 = ..SUMX2 + (pValue*pValue)

	Quit $$$OK
}

/// Returns the variance - biased, works if sample is whole populations
Method GetResult(Output pStatus As %Status) As %Double
{
    Set pStatus = $$$OK
    Set tResult = 0

    Try {
	    Quit:'(..Count>1)

        Set AvgX = ..SUMX/..Count
        Set AvgX2 = ..SUMX2/..Count
        Set tResult =  AvgX2 - (AvgX*AvgX)
        Set tResult = ..%PostProcessValue(tResult)	
    }
    Catch ex {
        Set pStatus = ex.AsStatus()
        Set tResult = ""
    }

    Quit tResult
}

}
