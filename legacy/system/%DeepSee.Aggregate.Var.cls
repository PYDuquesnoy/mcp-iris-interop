/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.Aggregate.Var Extends aggregate [ System = 4 ]
{

/// Returns the variance of the values processed
/// Note we divide by n-1 since this is unbiased variance
Method GetResult(Output pStatus As %Status) As %Double
{
	// From Numerical Recipes, 3rd edition avoid round-off errors
	Set pStatus = $$$OK
    Set tResult = 0
    
    Try {
        Quit:'(..Count>1)
		
        Set s = 0
		Set ep = 0
		For j=1:1:..Count {
            Set s = s + ..data.GetAt(j)
        }

		Set ave=s/..Count
		Set var = 0
		For j=1:1:..Count {
			Set diff = ..data.GetAt(j)-ave
			Set ep = ep + diff
			Set var = var + (diff * diff)
		}

		Set var = (var - ((ep*ep)/..Count))/(..Count-1)
		Set tResult = ..%PostProcessValue(var)
    }
    Catch ex {
        Set pStatus = ex.AsStatus()
        Set tResult = ""
    }

    Quit tResult
}

}
