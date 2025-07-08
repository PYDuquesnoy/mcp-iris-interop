/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Aggregate.LinRegR2 Extends %ZEN.Report.Aggregate.LinRegWithStorage [ Deprecated, System = 4 ]
{

Method GetResult() As %String
{
	Set abpair=..GetResultList()
	if abpair="" quit ""
	Set n=..Count
	Set a = $LI(abpair,1)
	Set b = $LI(abpair,2)
	Set SumDiffModelSquared=0
	for i=1:1:n {
		Set diff = a * ..x.GetAt(i) + b - ..y.GetAt(i)
		Set SumDiffModelSquared = SumDiffModelSquared + (diff*diff)
	}
	Set AvgY=..SumOfY/n
	Set SumDiffSquared=0
	for i=1:1:n {
		Set diff = ..y.GetAt(i) - AvgY
		Set SumDiffSquared = SumDiffSquared + (diff*diff)
	}

	Set result = 1 - (SumDiffModelSquared/SumDiffSquared)
	Set result = ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)
	Quit result
}

}
