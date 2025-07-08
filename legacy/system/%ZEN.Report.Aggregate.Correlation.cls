/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Aggregate.Correlation Extends %ZEN.Report.CustomAggregate [ Deprecated, System = 4 ]
{

/// Number of values processed
Property Count As %Integer [ InitialExpression = 0 ];

Property SUMPRODXY As %Double [ InitialExpression = 0 ];

Property SUMX As %Double [ InitialExpression = 0 ];

Property SUMY As %Double [ InitialExpression = 0 ];

Property SUMX2 As %Double [ InitialExpression = 0 ];

Property SUMY2 As %Double [ InitialExpression = 0 ];

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
	Set ..SUMX2 = x*x+..SUMX2
	Set ..SUMY2 = y*y+..SUMY2
	Quit $$$OK
}

/// Returns the correlation coefficient. Returns "" if the denominator would be zero
Method GetResult() As %String
{
	if ..Count=0 quit ""
	Set n=..Count
	Set AvgXY = ..SUMPRODXY/n
	Set AvgX = ..SUMX/n
	Set AvgY = ..SUMY/n
	Set AvgX2 = ..SUMX2/n
	Set AvgY2 = ..SUMY2/n
	Set n = ..Count
	Set stddevx = $zsqr(AvgX2 - (AvgX*AvgX))
	Set stddevy = $zsqr(AvgY2 - (AvgY*AvgY))
	if (stddevx=0)||(stddevy=0) quit ""  ; denominator must not be zero
	Set numerator = AvgXY - (AvgX*AvgY)
	Set denominator = stddevx * stddevy
	Set result=numerator / denominator
	Quit ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)
}

}
