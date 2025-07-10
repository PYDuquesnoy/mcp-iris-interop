/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This task is used to run the method that collects general
/// Interoperability monitor metrics that include Message
/// Retention Metrics outside of a production host item.
Class Ens.Util.Tasks.MonitorMetrics Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "Collect Interoperability Message Retention Metrics";

/// Comma separated list of number of days to show counts of message headers
/// as old and older than each day specified. <br>
/// Exclude oldest and 0. The default value is the same as in Ens.SAM.GeneralMetrics.
Property DayBoundariesForCounts As %String [ InitialExpression = "56, 28, 14, 7, 1" ];

Method OnTask() As %Status
{
    Return ##class(Ens.SAM.GeneralMetrics).Collect(..DayBoundariesForCounts)
}

}
