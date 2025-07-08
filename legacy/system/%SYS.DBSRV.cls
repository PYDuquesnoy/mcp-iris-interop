/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%callout, %SYS.DBSRV, %msql, %syAudit, %sySt, %syPidtab, %BigData.ShardingManager, %BigData.ShardedSQL)

/// IRIS xDBC Server
/// This code used to be in %SYS.DBSRV.mac prior to DPV6458
Class %SYS.DBSRV Extends %RegisteredObject
{

/// Flag which determings if we are performing xDBC query auditing or not
Property Auditing As %Integer [ InitialExpression = 0 ];

/// Flag which determings if we are performing xDBC DML auditing or not, relevant to fast insert auditing specifically
Property AuditingDML As %Integer [ InitialExpression = 0 ];

/// Maximum number of seconds this server should be allowed to remain idle for (no message from client)
Property ClientMaxIdleTime As %Integer;

/// Maximum number of xDBC connection we can allow for this server
Property ConnectionLimit As %String;

/// TCP/Shared Memory device for the connection
Property Device As %String;

/// Memory to hold the Devices pushed/popped on the stack for gateway re-entrancy
Property DeviceStack As %String [ InitialExpression = 0, MultiDimensional ];

/// Array which holds the server functions permitted by this connection
Property Dispatch As %Integer [ MultiDimensional ];

/// Name of the class that has transaction callmack methods %OnTranCommit and %OnTranRollback
Property EventClass As %String;

/// Timeout from the client to be used to place a time limit (in seconds) on a function's execution
Property FunctionTimeout As %Integer [ InitialExpression = 0 ];

/// Flag used to tell the server this was called from gatewat Re-Entrancy
Property GatewayReentry As %Integer [ InitialExpression = 0 ];

/// This flag is true if the header was read within the generated SQL code
Property HeaderReadInSQL As %Integer;

/// TCP input buffer size
Property InBufSize As %Integer;

/// Flag used to tell the server it has been called from Light C Binding
Property LCBmode As %Integer [ InitialExpression = 0 ];

/// Flag for if we are performing server logging or not
Property Logging As %Integer [ InitialExpression = 0 ];

/// ObjectCaache holds the orefs for cached cached query objects
Property ObjectCache As %String [ MultiDimensional ];

Property ObjectCacheHead As %String;

Property ObjectCacheSize As %Integer [ InitialExpression = 0 ];

Property ObjectCacheTail As %String;

Property ObjectCacheMaxSize As %Integer [ InitialExpression = 0 ];

/// TCP Output buffer size
Property OutBufSize As %Integer;

/// Array used to keep track of Start/Stop output redirection for each device
Property RedirectionStack As %String [ InitialExpression = 0, MultiDimensional ];

/// Hash of the login roles for this user
Property RHash As %String;

/// Roles that might have been added by CheckBindingsAccess
Property RolesAdded As %String;

/// Options supported for this connection after handshake with client
Property ServerOptions As %Integer [ MultiDimensional ];

/// Used to determine which types of functions are privileged for this user
/// Multidimentional because I need to set $e on the value.
Property ServiceType As %String [ MultiDimensional ];

/// Holds the $SYSTEM.Context.SQLCompile settings at the time of connection
Property SQLCompileContext As %SYSTEM.Context.SQLCompile;

/// Hash for the username
Property UHash As %String;

/// Watermark level to flush fetch results for first buffer
Property WaterMark1 As %Integer;

/// Watermark level to flush fetch results for second through Nth buffer
Property WaterMark2 As %Integer;

/// Build the local array for looking up client functions to the dispatch number
/// The functions allows for this server process are based on the resources the process has
/// We also define ..ServiceType here.  This is a string with:
/// 	position 1 ON: User has %Service_SQL
/// 	position 2 ON: User has %Service_Object
/// 	position 3 ON: User has %Service_DirectLoad (XEP)
Method BuildDispatch()
{
}

ClassMethod SuperConnect(protocol, msgid, acn, io, %qport)
{
}

/// Setup TCP/IP device specific options, the device must be the current device
Method SetupDevice(io)
{
}

/// Setup SharedMemory device specific options, the device must be the current device
ClassMethod SetupShmDevice(ByRef shmIO, shmConnect, returnStatus = 0, ByRef statusCode, currentDevice = "", setQdev = 0)
{
}

/// Generic Init SharedMemory device 
ClassMethod InitSHM(ByRef shmIO, dollarJ, shmSize, shmName, shmWaitFlag, openTimeout, returnStatus = 0, ByRef statusCode, currentDevice = "", setQdev = 0)
{
}

///  ; send Super Server error message (called from %SYS.SERVER)
ClassMethod SuperError(msgid, acn, rc)
{
}

/// Support connecting via ccallin-based SPC device, for Light C++ Binding.
/// Called from LCB to process first message from SendLogonMessage()
ClassMethod LCBSuperConnect1(protocol, msgid, acn, io)
{
}

/// Support connecting via ccallin-based SPC device, for Light C++ Binding.
/// Called from LCB to process second message from SendLogonMessage()
ClassMethod LCBSuperConnect2(io)
{
}

ClassMethod Logon(ns, brokerToken = "") [ Private ]
{
}

/// Count the current number of xDBC server processes
ClassMethod GetServerProcessCount()
{
}

ClassMethod AuthenticationError(text, status, ns = "")
{
}

ClassMethod GWExecuteSingle(%qmsgid, %qacn, %qfun) [ PublicList = (i, nparm, oref, x) ]
{
}

/// This entry point is called from the gateway re-entrance code to cleanup
/// RETURNs nothing
ClassMethod GWDisconnect(device)
{
}

ClassMethod Server(jumpToMain As %Integer = 0)
{
}

ClassMethod startSYSIOLoop()
{
}

ClassMethod XDCall()
{
}

/// Called by PP, DQ (Direct Query), DU (Direct Update), DX (Direct Static Cursor)
ClassMethod Prepare()
{
}

/// Called from srvDS (Direct Stored procedure) and srvSP (Prepare Stored Procedure)
/// if returnmeta=1, do not write the metadata to the zobjexport buffer here.  This means it is a "DS" call and we need to 
/// wait and wrie the metadata after SP execution.  This is needed in case the SP execution performs re-entrancy, the metadata
/// written to the buffer will be lost
ClassMethod SPPrepare(ByRef returnmeta)
{
}

/// if procmeta is defined, this was a DS call and we need to write the metadata on the wire after the proc execution
ClassMethod SPFunction(procmeta)
{
}

/// Called from srvDS (Direct Stored procedure), srvSQ (Stored Procedure Query Execute), srvUNK for catalog queries
/// if procmeta is defined, this was a DS call and we need to write the metadata on the wire after the proc execution
ClassMethod SPQuery(ByRef procmeta, catalogQuery = 0) [ PublicList = rc ]
{
}

/// Called from srvSF (Stored Procedure Fetch Data) and SPQuery
/// directcall=1 means this is an srvSF call
ClassMethod SPFetch(directcall, %qHandle)
{
}

/// Called from SPFetch
ClassMethod SPClose(%qHandle)
{
}

/// Called from srvMS (Multiple Result Set)
ClassMethod SPExecute()
{
}

/// Called from SPExecute, srvMR (Get More Results), and DirectDialect
/// directcall = 1 when called from srvMR, otherwise 0.
ClassMethod SPMoreResults(directcall)
{
}

/// Called from srvMD (Multiple Result Sets Fetch Data)
ClassMethod SPMoreData()
{
}

ClassMethod AuditSP(parameters)
{
}

ClassMethod StaticCursorExecute()
{
}

ClassMethod ExecuteBatch()
{
}

ClassMethod ExecuteBatchError(i, cnt)
{
}

ClassMethod ReadQueryParameters()
{
}

ClassMethod SPReadParameters(parameters)
{
}

ClassMethod SPReadParametersDP(parameters)
{
}

ClassMethod SPWriteParameters(parameters)
{
}

ClassMethod SPWriteParametersDP(parameters)
{
}

ClassMethod SetCompileMode()
{
}

/// called from srvFR
ClassMethod CacheResultSetFetch()
{
}

ClassMethod GatewayIn()
{
}

ClassMethod Transact(ttype)
{
}

/// resets/cleans up the connection so that it can be reused in a pooled env
ClassMethod ResetConnection()
{
}

ClassMethod FlushError(tag, ns = "")
{
}

/// The process received an <EXTERNAL INTERRUPT> error, deal with it...
ClassMethod ProcessExternalInterrupt(pCloseCurrentStatement = 1)
{
}

/// Record the error on the server. Like FlushError, but send nothing to the client
ClassMethod RecordError(tag)
{
}

/// Get/set server process's isolation level
/// Called from srvIL
/// We support READ_COMMITED (0), READ_COMMITTED (1), and READ_VERIFIED (3)
/// The client mapping for these values is:
/// 0 on server, 1 on client	// uncommitted
/// 1 on server, 2 on client	// committed
/// 3 on server, 32 on client	// verified
/// if level=0, the client is simply asking what the current isolation level is.
ClassMethod IsolationLevel()
{
}

ClassMethod CloseUp(atend = 0, nocache = 0)
{
}

ClassMethod CloseAllStatements()
{
}

/// Structure of linked list FIFO $$$srv.ObjectCache:
/// 
/// $$$srv.ObjectCache(%qacn)=oref
/// $$$srv.ObjectCache(%qacn,0)=forward pointer towards the head of the queue
/// $$$srv.ObjectCache(%qacn,1)=back pointer towards the tail of the queue
/// 
/// $$$srv.ObjectCacheHead=head of the queue (%qacn value)
/// $$$srv.ObjectCacheTail=tail of the queue (%qacn value)
/// $$$srv.ObjectCacheSize=size of the queue
/// See if we have this oref in the cache, if so return it and if not then %new the class we want and return this
ClassMethod CreateOref(discard = 0)
{
}

/// called from srvCU, Prepare, SPPrepare
ClassMethod CloseStatement(%qacn)
{
}

/// process Catalog Queries
ClassMethod Catalog(query)
{
}

/// JPAQuery() implements the QQ message processor
ClassMethod JPAQuery()
{
}

/// ISCProcAll takes a procedure and schema and checks to see if this is a class from CACHELIB with no owner.
/// if it is, privileges do not need to be checked on this procedure and everyone can run it.
/// This preserves behavior we had prior to DPV4707 where privileges were not checked on hidden procedures
/// Returns:
/// 	1 - if this procedure is from CACHELIB and there is no owner - no privilege checking needed
///     0 - otherwise
ClassMethod ISCProcAll(SCHEMA, PROC)
{
}

ClassMethod DirectDialect()
{
}

/// DIRECT_EXECUTE_DIALECT_PARAM (DP)
/// 	Field Name					Description
/// 	-----------------------		------------------------------------------------------
/// 	SQL Dialect					SQL Dialect (DEFAULT = 0, MSSQL  = 1, SYBASE = 2)
/// 	SQL Text					SQL statement
/// 	isStatic					isStatic - unused
/// 	Statement Timeout			Statement Timeout (protocol>=42)
/// 	Parameter Sets				Number of Parameter Sets (Ignored)
/// 	Parameter Count				Number of Parameters
/// 	...Type						Parameter Type
/// 	...Precision				Parameter Precision
/// 	...Scale					Parameter Scale
/// 	...Nullable					Parameter Nullable
/// 	...Name						Parameter Name
/// 	...Mode						Parameter Mode
/// 	Parameter List				$LB(par1,...,parCount)
/// 
ClassMethod DirectParameter()
{
}

/// Called from %SYS.SERVER to get available namespaces.
ClassMethod CacheInfo(io, uplen)
{
}

/// Called from SQLVer^SystemCheck
ClassMethod GetVersion()
{
}

ClassMethod setupLogging(ns)
{
}

/// log something
/// log file format is:                   1         2     3           4              5         6                7                  8           9       10
/// ^%sqlcq(namespace,"log",pid,id) = $lb(timestamp,text, message id, cursor number, function, isolation level, transaction level, error code, message,rowcount,%lasterr)
/// ^%sqlcq(namespace,"log",pid,id,"sql") = array of sql text
/// ^%sqlcq(namespace,"log",pid,id,"vartype") = array of metadata for %sqlHVarTypes
/// ^%sqlcq(namespace,"log",pid,id,"info") = # of info lines
/// ^%sqlcq(namespace,"log",pid,id,"info",1..n) = Additional information for this entry
ClassMethod log(text = "", sameid = 0, ByRef sql, ByRef vartypes, ns = "")
{
}

/// Add info to the current log entry
ClassMethod logappend(info = "", ns = "")
{
}

ClassMethod dumplog(pid = "")
{
}

ClassMethod dumponelog(pid)
{
}

ClassMethod timings(outlierPerc = 500, pqpulimit = 1)
{
}

Method delta(t1, t2)
{
}

Method median(ByRefstatements, sid, fun)
{
}

ClassMethod purgelog(pid = "*")
{
}

ClassMethod sqlcode(code)
{
}

}
