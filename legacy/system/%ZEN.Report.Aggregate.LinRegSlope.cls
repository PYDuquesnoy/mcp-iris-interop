/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Aggregate.LinRegSlope Extends %ZEN.Report.Aggregate.LinearRegression [ Deprecated, System = 4 ]
{

Method GetResult() As %String
{
		Set abpair=..GetResultList()
		if abpair="" quit ""
		Set result = $LI(abpair,1)
		Set result = ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)
		Quit result
}

}
