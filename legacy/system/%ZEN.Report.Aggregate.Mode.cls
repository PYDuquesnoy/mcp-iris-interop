/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Aggregate for computing the statistical mode (most frequent observation)
/// of a set of data
Class %ZEN.Report.Aggregate.Mode Extends %ZEN.Report.CustomAggregate [ Deprecated, System = 4 ]
{

/// Number of observations indexed by value
Property Counts As array Of %Integer [ InitialExpression = 0 ];

/// Largest count seen so far
Property MaxCount As %Integer [ InitialExpression = 0 ];

/// List of values that have occured <property>MaxCount</property> times.
Property MaxCountValues As %String;

/// Processes each new value
Method ProcessValue(pValue As %String) As %Status
{
	if pValue="" quit $$$OK
	Set newcount = ..Counts.GetAt(pValue) + 1
	If newcount > ..MaxCount {
		Set ..MaxCount = newcount
		Set ..MaxCountValues = $lb(pValue)
	} ElseIf newcount = ..MaxCount {
		Set ..MaxCountValues = ..MaxCountValues_$lb(pValue)
	}
	Do ..Counts.SetAt(newcount,pValue)

	Quit $$$OK
}

/// Returns the mode of the data set.  If the data set was empty, "" is returned.
/// If there is no unique mode, the number of values occurring most frequently is
/// returned, as well as how many times these values occurred.
Method GetResult() As %String
{
	If $ll(..MaxCountValues)=0 {
		Quit ""
	} ElseIf $ll(..MaxCountValues)=1 {
		Quit $lg(..MaxCountValues)
	} Else {
		#; No unique value
		Quit $ll(..MaxCountValues)_" @ "_..MaxCount
	}
}

ClassMethod %PostProcessValue(result As %String, postprocessResult As %Boolean, runtimeMode As %Integer, ignoreNLS As %Boolean)
{
	Quit result
}

}
