/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each xDBC server process currently running on this instance
/// <br>
/// <br><b>Column Descriptions:</b>
/// <ul>
/// <br>		<b><i>Pid</i></b> - Process ID.  Process ID ($J) given to the process by the O/S, decimal form on all platforms.
/// <br><br>	<b><i>Username</i></b> - $Username of process.
/// <br><br>	<b><i>Roles</i></b> - Roles a process currently has.
/// <br><br>	<b><i>LoginRoles</i></b> - Roles a process has when it initially logs in.
/// <br><br>	<b><i>Routine</i></b> - Name of the routine which the process is currently executing.
/// <br><br>	<b><i>InTransaction</i></b> - In a transaction. If 0, the process is not in a transaction. If >0, the process has executed a tstart command, is in a transaction, and the value is the offset in the journal file where the transaction has started.
/// <br><br>	<b><i>ClientNodeName</i></b> - Node name of the client which initiated the connection.  It is passed down to the process as part of the initial connection message.  This property may be set by the end-user if they are managing their own connections.
/// <br><br>	<b><i>ClientIPAddress</i></b> - IP address of the client which initiated the connection.  It is passed down to the process as part of the initial connection message. This property may be set by the end-user if they are managing their own connections.
/// <br><br>	<b><i>ClientExecutableName</i></b> - The name of the Executable or DLL on the client which initiated the connection.  It is passed down to the process as part of the initial connection message. This property may be set by the end-user if they are managing their own connections.
/// <br><br>	<b><i>MemoryAllocated</i></b> - Maximum amount of memory in KB that the process is allowed to use.  This property requires a mailbox message to be sent to the process being examined.
/// <br><br>	<b><i>MemoryUsed</i></b> - Memory used in KB (Current $s). Current amount of memory the process has used in KB. This property requires a mailbox message to be sent to the process being examined.
/// <br><br>	<b><i>MemoryPeak</i></b> - Peak memory allocated in KB.  This property requires a mailbox message to be sent to the process being examined.
/// <br><br>	<b><i>StatementId</i></b> - Statement hash ID from the SQL Statement Index (if the process is currently executing an SQL Statement)
/// <br><br>	<b><i>Statement</i></b> - SQL Statement Text currently being executed (if the caller has permission for this statement).
/// </ul>
Class INFORMATION.SCHEMA.CURRENTCONNECTIONS [ ClassType = view, CompileAfter = %SYS.ProcessQuery, Final, Owner = {_PUBLIC}, SqlTableName = CURRENT_CONNECTIONS, System = 4, ViewQuery = { 
	SELECT pq2.Pid, 
		   pq2.NameSpace, 
		   pq2.UserName, 
		   pq2.Roles, 
		   pq2.LoginRoles, 
		   pq2.Routine, 
		   pq2.InTransaction, 
		   pq2.ClientNodeName, 
		   pq2.ClientIPAddress, 
		   pq2.ClientExecutableName, 
		   pq2.MemoryAllocated, 
		   pq2.MemoryUsed, 
		   pq2.MemoryPeak, 
		   pq2.StatementId,
		   information_schema.getStatement(pq2.StatementId,pq2.NameSpace) as Statement
	FROM (select Pid,
			     NameSpace, 
			     UserName, 
			     Roles, 
			     LoginRoles, 
			     Routine, 
			     InTransaction, 
			     ClientNodeName, 
			     ClientIPAddress, 
			     ClientExecutableName, 
			     MemoryAllocated, 
			     MemoryUsed, 
			     MemoryPeak,
			     cast($listget($listget(AppFrameInfo),4) as varchar(32)) as StatementId 
			FROM %SYS.ProcessQuery pq1
			WHERE JobType = 28
		) pq2
} ]
{

Parameter READONLY = 1;

/// Given an SQL Statement Hash and a namespace, return the SQL Statement Text
ClassMethod GetStatement(statementHash As %String, namespace As %String) As %String(MAXLEN=262144) [ Internal, SqlName = GetStatement, SqlProc ]
{
}

}

