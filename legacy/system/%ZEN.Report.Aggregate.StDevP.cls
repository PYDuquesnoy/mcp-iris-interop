/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Standard deviation ("whole population") Aggregate 
Class %ZEN.Report.Aggregate.StDevP Extends %ZEN.Report.CustomAggregate [ Deprecated, System = 4 ]
{

/// Number of values processed
Property Count As %Integer [ InitialExpression = 0 ];

Property SUMX As %Double [ InitialExpression = 0 ];

Property SUMX2 As %Double [ InitialExpression = 0 ];

Property preprocessValue As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property postprocessResult As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Method ProcessValue(pValue As %Double) As %Status
{
	if pValue="" quit $$$OK
	Set pValue = ..%PreProcessValue(pValue, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	Set ..Count=..Count+1 
	Set ..SUMX = pValue+..SUMX
	Set ..SUMX2 = pValue*pValue+..SUMX2
	Quit $$$OK
}

/// Returns the standard deviation - biased, works if sample is whole populations
Method GetResult() As %String
{
	if ..Count=0 quit ""
	Set n=..Count
	Set AvgX = ..SUMX/n
	Set AvgX2 = ..SUMX2/n
	Set n = ..Count
	Set result = $zsqr(AvgX2 - (AvgX*AvgX))
	Set result = ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)	
	Quit result
}

}
