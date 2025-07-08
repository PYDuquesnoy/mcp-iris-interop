/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.SQL.xDBC Extends %SYSTEM.Help [ Abstract, Not ProcedureBlock, System = 4 ]
{

/// Display server-side ODBC/JDBC logs that were enabled by $SYSTEM.SQL.xDBC.SetServerLog()
/// <br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>pid</i>
/// <dd>Process id of the log to display.  If not specified, the user will be given a list of PIDs that have logs defined to choose from.
/// <p>Examples:
/// <ul>
/// <li>Do $SYSTEM.SQL.xDBC.DisplayServerLogs()    // Displays a list of PIDs with server logs the user can choose from to display</li>
/// <li>Do $SYSTEM.SQL.xDBC.PurgeServerLogs(3245)  // Displays server log for process id 3245 in this namespace</li>
/// </ul>
ClassMethod DisplayServerLogs(pid As %Library.String = "") As %Status [ Internal, ProcedureBlock = 1 ]
{
	try {
		do ##class(%SYS.DBSRV).dumplog(pid)
		RETURN $$$OK
	} catch  {
		RETURN $$$ERROR($$$GeneralError,"Unexpected error in $SYSTEM.SQL.xDBC.DisplayServerLog: "_$ze)
	}
}

/// Delete server-side ODBC/JDBC logs that were enabled by $SYSTEM.SQL.xDBC.SetServerLog()
/// <br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>pid</i>
/// <dd>Process id of the log global to purge.  "*" is the default, which means purge all logs for this namespace
/// <p>Examples:
/// <ul>
/// <li>Do $SYSTEM.SQL.xDBC.PurgeServerLogs()      // Purges all server logs in this namespace</li>
/// <li>Do $SYSTEM.SQL.xDBC.PurgeServerLogs("*")   // Purges all server logs in this namespace</li>
/// <li>Do $SYSTEM.SQL.xDBC.PurgeServerLogs(3245)  // Purges server log for process id 3245 in this namespace</li>
/// </ul>
ClassMethod PurgeServerLogs(pid As %Library.String = "*") As %Status [ Internal, ProcedureBlock = 1 ]
{
	try {
		do ##class(%SYS.DBSRV).purgelog(pid)
		RETURN $$$OK
	} catch  {
		RETURN $$$ERROR($$$GeneralError,"Unexpected error in $SYSTEM.SQL.xDBC.PurgeServerLogs: "_$ze)
	}
}

/// Define the condition that determines if IRIS performs xDBC server-side logging.
/// <br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>condition</i>
/// <dd>An ObjectScript expresion that determines if an ODBC/JDBC server process performs server-side logging.
/// This should only be used at the direction of InterSystems Support personell for debugging purposes.
/// Call with <i>condition=""</i> or <i>undefined</i> to turn logging off.
/// <dt><i>systemWide</i>
/// <dd>1/0 flag that determines if the logging condition specified in <i>condition</i> applies to just this namespace, or system wide.  The default is 0, the condition applies to just this namespace.
/// </dl>
/// <p>Examples:
/// <ul>
/// <li>Do $SYSTEM.SQL.xDBC.SetServerLog("1")  // Turns logging on for all xDBC connections to this namespace</li>
/// <li>Do $SYSTEM.SQL.xDBC.SetServerLog("$username=""BOBW""",1)  // Turns logging on for all connections on this system when the username is BOBW.</li>
/// <li>Do $SYSTEM.SQL.xDBC.SetServerLog("$Get(^log)=1,0)  // Turns logging on for all connections to this namespace if the ^log=1.</li>
/// <li>Do $SYSTEM.SQL.xDBC.SetServerLog("",0)  // Turns logging off for all connections to this namespace.</li>
/// <li>Do $SYSTEM.SQL.xDBC.SetServerLog("",1)  // Turns logging off for all connections to this server.</li>
/// </ul>
ClassMethod SetServerLog(condition As %Library.String = "", systemWide As %Boolean = 0) As %Status [ Internal, ProcedureBlock = 1 ]
{
	try {
		if systemWide { set ^%SYS("sql","server","logging")=condition }
		else          { set ^%SYS("sql","server","logging",$namespace)=condition }
		RETURN $$$OK
	} catch  {
		RETURN $$$ERROR($$$GeneralError,"Unexpected error in $SYSTEM.SQL.xDBC.SetServerLog: "_$ze)
	}
}

}
