/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Aggregate.Covariance Extends %ZEN.Report.CustomAggregate [ Deprecated, System = 4 ]
{

/// Number of values processed
Property Count As %Integer [ InitialExpression = 0 ];

Property SUMPRODXY As %Double [ InitialExpression = 0 ];

Property SUMX As %Double [ InitialExpression = 0 ];

Property SUMY As %Double [ InitialExpression = 0 ];

Method ProcessValue(pValue As %List) As %Status
{
	if pValue="" quit $$$OK
	Set x = $LI(pValue,1)
	Set y = $LI(pValue,2)
	
	Set x = ..%PreProcessValue(x, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	Set y = ..%PreProcessValue(y, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	Set ..Count=..Count+1 
	Set ..SUMPRODXY = x*y+..SUMPRODXY
	Set ..SUMX = x+..SUMX
	Set ..SUMY = y+..SUMY
	Quit $$$OK
}

/// Returns the covariance. Returns 0 if the count is zero
Method GetResult() As %String
{
	if ..Count=0 quit 0
	Set n=..Count
	Set AvgXY = ..SUMPRODXY/n
	Set AvgX = ..SUMX/n
	Set AvgY = ..SUMY/n
	Set AvgXY = AvgXY / n
	Set AvgX = AvgX / n
	Set AvgY = AvgY / n
	Set result = AvgXY - (AvgX*AvgY)
	Quit ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)
}

}
