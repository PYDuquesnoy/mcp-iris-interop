/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Aggregate for the percentile of a set of numerical data. 
Class %ZEN.Report.Aggregate.Percentile Extends %ZEN.Report.CustomAggregate [ Deprecated, System = 4 ]
{

/// Algorithm taken from Head First Statistics by Dawn Griffiths, page 99
/// XML namespace used for Zen Report definitions.
Parameter NAMESPACE = "http://www.intersystems.com/zen/report/definition";

Parameter XMLIGNORENULL = 1;

/// By setting this to 0, we disallow use of invalid attribute names in Zen Report XML documents.
Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

/// If XMLFORMAT="Literal", then only support for literal format import and export is generated.<br>
Parameter XMLFORMAT = "Literal";

Parameter XMLNAME = "percentile";

/// Array of processed values
Property RawValues [ MultiDimensional ];

Property Values As array Of %Integer;

/// Number of values processed
Property Count As %Integer [ InitialExpression = 0 ];

Property percentile As %ZEN.Datatype.float;

/// Processes each new Values.
Method ProcessValue(pValue As %Float) As %Status
{
	if pValue="" quit $$$OK
	Set pValue = ..%PreProcessValue(pValue, $s(..preprocessValue'="":..preprocessValue,1:1), ..runtimeMode, ..ignoreNLS)
	Set ..Count=..Count + 1
	Set ..RawValues(+pValue,..Count)=""
	
	Quit $$$OK
}

/// Returns the percentile. Returns "" for an empty data set.
Method GetResult() As %String
{
	If ..Count=0 {
		Quit ""
	}
	// sort using $o
	Set k=1
	Set i="" For { Set i=$o(..RawValues(i)) quit:i=""  
		Set j=""  For { Set j=$o(..RawValues(i,j)) quit:j=""
			//!!!Do ..Values.SetAt(i,k)
			Set tValues(k) = i
			Set k=k+1
		}
	}
	
	set PercentilePosition =  (..Count / 100) * ..percentile
	if $P(PercentilePosition,".")=PercentilePosition {
		Set Position = PercentilePosition
		Set Average=1
	} else {
		Set Position = +$P(PercentilePosition+0.5,".")
		Set Average=0
	}
	if (Position > 0) && (Position < ..Count) {
		if (Average) {
			//!!!Set Percentile=(..Values.GetAt(Position)+..Values.GetAt(Position+1))/2
			Set Percentile=(tValues(Position)+tValues(Position+1))/2
		} else {
			//!!!Set Percentile=..Values.GetAt(Position)
			Set Percentile=tValues(Position)
		}
	} elseif (Position = 0) {
		Set Percentile="" ; not a valid percentile
	} elseif (Position = ..Count) {
		//!!! Set Percentile=..Values.GetAt(Position)
		Set Percentile=tValues(Position)
	}
	Set Percentile = ..%PostProcessValue(Percentile,$s(..postprocessResult'="":..postprocessResult,1:1),..runtimeMode,..ignoreNLS)		
	Quit Percentile
}

}
