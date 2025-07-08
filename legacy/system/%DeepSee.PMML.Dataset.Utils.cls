/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Dataset.Utils [ System = 4 ]
{

/// Calculates the Pearson chi-squared test for the two-dimensional contingency table defined by
/// <var>pField1</var> and <var>pField2</var>. If the probability of this value is low (&lt;0.05),
/// <var>pField1</var> and <var>pField2</var> can be considered independent of one another.
/// http://en.wikipedia.org/wiki/Pearson%27s_chi-squared_test
ClassMethod GetChiSquared(pDataset As %DeepSee.PMML.Dataset, pField1 As %String, pField2 As %String, Output pChiSquared As %Numeric, Output pProbability As %Numeric, ByRef pFilters, pYatesCorrection As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		for tField = pField1, pField2 {
			if (pDataset.Fields.GetAt(tField).OpType = "continuous") {
				set tSC = $$$ERROR($$$GeneralError, "only supported for categorical / ordinal fields")
				quit
			}
		}
		
		set tSC = pDataset.GetXDDistribution($lb(pField1, pField2), .tDistribution, .pFilters)
		quit:$$$ISERR(tSC)
		
		set pChiSquared = 0
		set tTotalCount = tDistribution("total")
		set i = ""
		for {
			set i = $order(tDistribution(i))
			quit:i=""
			continue:'i // skip "total" and "value" subscripts
			
			set tTotalI = tDistribution("total",1,i)
			
			set j = ""
			for {
				set j = $order(tDistribution(i,j),1,tCount)
				quit:j=""
				
				set tTotalJ = tDistribution("total",2,j)
				
				set tExpectedCount = tTotalJ * tTotalI / tTotalCount
				set tDifference = (tCount - tExpectedCount)
				set:pYatesCorrection tDifference = $zabs(tDifference) - 0.5
				set pChiSquared = pChiSquared + ((tDifference ** 2) / tExpectedCount)
			}
		}
		
		// now calculate probability
		set tNumValuesI = $o(tDistribution("total",1,""),-1)
		set tNumValuesJ = $o(tDistribution("total",2,""),-1)
		set tDegFreedom = (tNumValuesI-1) * (tNumValuesJ-1)
		
		// dodgy approximation function
		// http://www.jstor.org/discover/10.2307/2348373?uid=3737592&uid=2&uid=4&sid=21101671656727
		set tZ = $zsqr(pChiSquared) - $zsqr(tDegFreedom)
		if (tZ <= 0) {
			set pProbability = 1 - (0.5 * $zexp((0.8055*tZ)+(-0.9911*(tZ**2))))
		} else {
			set pProbability = 0.5 * $zexp((-1.2451*tZ)+(-0.6763*(tZ**2)))
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
