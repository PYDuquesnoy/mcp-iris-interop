/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYS.Task.PurgeInteropUsageMetrics Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "Purge Interoperability Usage Metrics";

/// Number of months of active interoperability usage metrics data to keep. 
Property KeepActiveMonths As %Integer(MINVAL = 1) [ InitialExpression = 12 ];

/// Number of months of consolidated interoperability usage metrics data to keep. 
Property KeepConsolidatedMonths As %Integer(MINVAL = 1) [ InitialExpression = 24 ];

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "settings" for the task, and then
/// invokes this method to execute the task.<br>
/// In order to execute a real task, override this method in a subclass.
Method OnTask() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    Set tInTransaction = 0
    Try {
        TSTART
        Set tInTransaction=1
        Set tSC = ##class(SYS.Monitor.Interop.Interface.Utils).ConsolidateMetrics()
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(%SYS.Monitor.Interop.Messages.Utils).ConsolidateMetrics()
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(%SYS.Monitor.Interop.DatabaseImpact.Utils).ConsolidateMetrics()
        Quit:$$$ISERR(tSC)

        Set activePurgeDate=$SYSTEM.SQL.Functions.DATEADD("m",-..KeepActiveMonths,$ZDATETIME($ZTIMESTAMP,3))
        Set consolidatedPurgeDate=$SYSTEM.SQL.Functions.DATEADD("m",-..KeepConsolidatedMonths,$ZDATETIME($ZTIMESTAMP,3))
        Set tSC = ##class(SYS.Monitor.Interop.Interface.Utils).PurgeConsolidatedData(+$ZDATETIMEH(activePurgeDate,3))
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(%SYS.Monitor.Interop.Messages.Utils).PurgeConsolidatedData(+$ZDATETIMEH(activePurgeDate,3))
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(%SYS.Monitor.Interop.DatabaseImpact.Utils).PurgeConsolidatedData(activePurgeDate)
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(SYS.Monitor.Interop.ConsolidatedMetrics.Utils).Purge($PIECE(consolidatedPurgeDate,"-",1,2))
        Quit:$$$ISERR(tSC)

    } Catch e {
        Set tSC = e.AsStatus()
    }
    If $$$ISERR(tSC) {
        TROLLBACK:tInTransaction 1
        Set tInTransaction=0
    } Else {
        TCOMMIT:tInTransaction
        Set tInTransaction=0
    }
    Return tSC
}

}
