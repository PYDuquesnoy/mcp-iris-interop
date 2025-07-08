/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for custom aggregates in ZEN report data.
Class %ZEN.Report.CustomAggregate Extends aggregate [ Abstract, Deprecated, System = 4 ]
{

Property type As %ZEN.Datatype.string [ InitialExpression = "CUSTOM" ];

Property class As %ZEN.Datatype.className [ InitialExpression = {..%ClassName(1)} ];

/// ProcessValue is called sequentially on each record returned by the
/// report query or queries.
Method ProcessValue() As %Status
{
	Quit $$$OK
}

/// GetResult is invoked after every record has been processed to return
/// the final value of the aggregate.
Method GetResult() As %String
{
	Quit $$$Text("No GetResult method defined","%ZEN")
}

}
