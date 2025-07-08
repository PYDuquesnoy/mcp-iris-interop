/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Calculate linear regression information about X,Y data set return as %List
/// Base class for MDX Linear Regression Functions
Class %ZEN.Report.Aggregate.LinearRegression Extends %ZEN.Report.CustomAggregate [ Not Abstract, Deprecated, System = 4 ]
{

/// Keeps a running total of the sum of the squares of the processed items
Property SumOfX As %Double [ InitialExpression = 0 ];

Property SumOfY As %Double [ InitialExpression = 0 ];

Property SumOfXY As %Double [ InitialExpression = 0 ];

Property SumOfXSquared As %Double [ InitialExpression = 0 ];

/// Keeps a running count of values processed
Property Count As %Integer [ InitialExpression = 0 ];

/// Processes each new value (x,y) pair in %List
Method ProcessValue(pValue As %List) As %Status
{
	if pValue="" quit $$$OK
	Set x = $LI(pValue,1)
	Set y = $LI(pValue,2)
	
	Set x = ..%PreProcessValue(x, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	Set y = ..%PreProcessValue(y, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	Set ..Count=..Count + 1
	Set ..SumOfX=..SumOfX + x
	Set ..SumOfY=..SumOfY + y
	Set ..SumOfXSquared = ..SumOfXSquared + (x*x)
	Set ..SumOfXY = ..SumOfXY + (x*y)
	
	Quit $$$OK
}

/// Returns $LB(a,b) where y = a * x + b
/// Returns null if denominator will be zero
Method GetResultList() As %String
{
	// From page 288-289 of Data Preparation for Data Mining by Dorian Pyle
	// calculating a,b in y = a*x + b 
	Set n=..Count
	Set denominator=(n*..SumOfXSquared-(..SumOfX*..SumOfX))
	if denominator=0 quit ""
	Set a = ((n*..SumOfXY) - (..SumOfX*..SumOfY))/denominator
	Set b = (..SumOfY/n)-((a*..SumOfX)/n)
	Set a = ..%PostProcessValue(a,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)
	Set b = ..%PostProcessValue(b,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)
	quit $LB(a,b)
}

}
