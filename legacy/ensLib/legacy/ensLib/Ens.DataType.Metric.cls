/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Represents a value within a Business Metric class
Class Ens.DataType.Metric Extends %Float [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

/// Units used by this metric (e.g., Dollars, Percentage, etc.)<br>
/// This is used solely for documentation purposes
Parameter UNITS As STRING;

/// Specfies a default URL to provide drill down information for this metric.<br>
/// This is used by the Dashboard to provide a drill down page for any meters connected to this metric.
Parameter LINK As STRING;

/// Default value for RangeLower for a metric
Parameter RANGELOWER As NUMBER = 0;

/// Default value for RangeUpper for a metric
Parameter RANGEUPPER As NUMBER = 100;

/// Default value for ThresholdLower for a metric
Parameter THRESHOLDLOWER As NUMBER = 0;

/// Default value for ThresholdUpper for a metric
Parameter THRESHOLDUPPER As NUMBER = 100;

/// For multidimensional metrics: if this is set to a non-zero
/// value, then the Metric class will automatically maintain a history
/// of values for this property. The author of the OnCalculate method
/// needs only set to the current value for the metric into the top
/// (non-subscripted) node of the property.<br>
/// The number of values maintained is specified by the value 
/// of this parameter.
Parameter AUTOHISTORY As NUMBER = 0;

/// Default number of points for a chart based on this property.
ClassMethod Points() As %String
{
	Quit ..#AUTOHISTORY
}

ClassMethod Units() As %String
{
	Quit ..#UNITS
}

ClassMethod Link() As %String
{
	Quit ..#LINK
}

ClassMethod RangeLower() As %String
{
	Quit ..#RANGELOWER
}

ClassMethod RangeUpper() As %String
{
	Quit ..#RANGEUPPER
}

ClassMethod ThresholdLower() As %String
{
	Quit ..#THRESHOLDLOWER
}

ClassMethod ThresholdUpper() As %String
{
	Quit ..#THRESHOLDUPPER
}

}
