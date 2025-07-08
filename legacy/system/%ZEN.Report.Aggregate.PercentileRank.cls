/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Aggregate for the percentile rank of a set of numerical data. 
Class %ZEN.Report.Aggregate.PercentileRank Extends %ZEN.Report.CustomAggregate [ Deprecated, System = 4 ]
{

/// Algorithm taken from Head First Statistics by Dawn Griffiths, page 99
/// XML namespace used for Zen Report definitions.
Parameter NAMESPACE = "http://www.intersystems.com/zen/report/definition";

Parameter XMLIGNORENULL = 1;

/// By setting this to 0, we disallow use of invalid attribute names in Zen Report XML documents.
Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

/// If XMLFORMAT="Literal", then only support for literal format import and export is generated.<br>
Parameter XMLFORMAT = "Literal";

Parameter XMLNAME = "percentilerank";

/// Array of processed values
Property RawValues [ MultiDimensional ];

/// Number of values processed
Property Count As %Integer [ InitialExpression = 0 ];

Property value As %ZEN.Datatype.float;

/// Processes each new Values.
Method ProcessValue(pValue As %Float) As %Status
{
	if pValue="" quit $$$OK
	Set pValue = ..%PreProcessValue(pValue, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	Set ..Count=..Count + 1
	Set ..RawValues(+pValue,..Count)=""
	
	Quit $$$OK
}

/// Returns the percentile rank. Returns 100% for an empty data set.
Method GetResult() As %String
{
	If ..Count=0 {
		Quit 100
	}
	// sort using $o
	Set B=0
	Set E=0
	Set i="" For { Set i=$o(..RawValues(i)) quit:i=""  
		Set j=""  For { Set j=$o(..RawValues(i,j)) quit:j=""
			if (i < ..value) Set B=B+1
			if (i = ..value) Set E=E+1
		}
	}
	Set result = (B + (0.5*E))*100/..Count
	Set result = ..%PostProcessValue(result,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)	
	Quit result
}

}
