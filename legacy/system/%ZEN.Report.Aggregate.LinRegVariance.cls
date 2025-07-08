/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Aggregate.LinRegVariance Extends %ZEN.Report.Aggregate.LinRegWithStorage [ Deprecated, System = 4 ]
{

Method GetResult() As %String
{
	Set abpair=..GetResultList()
	if abpair="" quit ""
	Set n=..Count
	if n < 3 quit 0 ; no variance between expected and actual if one or two points
	Set a = $LI(abpair,1)
	Set b = $LI(abpair,2)
	Set SumDiffSquared=0
	for i=1:1:n {
		Set diff = a * ..x.GetAt(i) + b - ..y.GetAt(i)
		Set SumDiffSquared = SumDiffSquared + (diff*diff)
	}
	Set result = SumDiffSquared/(n-2)
	Set result = ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)
	Quit result
}

}
