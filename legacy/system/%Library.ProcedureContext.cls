/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Stored procedure context
Class %Library.ProcedureContext Extends %Library.IProcedureContext [ System = 2 ]
{

/// %LTT is an array of temporary table storage indexes subscripted by temp table name.
Property %LTT As %RawString [ Internal, MultiDimensional ];

/// PTT is an array of private temporary table orefs subscripted by temp table name.
/// Private Temporary Table to OREF index.
Property PTT As %RawString [ Internal, MultiDimensional ];

/// TTNI is an array of private temporary table names subscripted by UPPERCASE source language temporary tablename. This property is used to resolve a source language table reference to a private temporary table name.
/// TTNI = temporary table name index
Property TTNI As %RawString [ Internal, MultiDimensional ];

/// Same list as TTNI for private temporary tables in a sharded environment where we use a real table and not a LTT.  This list is not copied into other contexts, but only set in the main context where a PTT is created
/// This array allows us to clean up (delete) the IRIS_Temp.LTT# tables in %OnClose()
Property LTTCleanup As %RawString [ Internal, MultiDimensional ];

/// This array allows us to clean up (delete) globals from temp files we want cleaned up in %OnClose()
/// Only globals that begin with ^IRIS.Temp are deleted
Property TempGlobalCleanup As %RawString [ Internal, MultiDimensional ];

/// Results is a MD-style collection of result objects. This repository is
/// private and not meant for direct access. It is exposed through the interface.
/// A result can be added by calling AddResultSet or AddContext. The %CurrentResult
/// property is set to the result currently available to the client. The next result
/// becomes the current result by calling %NextResult().
Property Results As %RawString [ Internal, MultiDimensional, Private ];

/// cursors is a multidimensional array of cursor objects, subscripted by cursor name (case sensitive)
/// The value of the cursor is the cursor object reference (oref).
Property cursors As %String(MAXLEN = "") [ Internal, MultiDimensional ];

Property context As %RawString [ Private ];

Property static As %Boolean [ InitialExpression = 0 ];

/// AddPrivateTable()
/// 		This method will register a temporary table object. Only registered table objects are usable by dSQL.
/// 		The TTNI property is the <source_language_tablename> to <actual_tablename> index and is not set up here
/// 		since the actual table (referenced by pTable) has no clue as to the source language table name. That must
/// 		be done by the source language.
Method AddPrivateTable(pTable As %XSQL.DS.TempTable)
{
	set context = $this
	if $Get(pTable.%dsd("%GlobalScope"),0) { if '$IsObject($Get(%processcontext)) { set %processcontext = ..%New() } set context = %processcontext }
		#; Storage offset
	set context.%LTT($Piece(pTable.%dsd("%TABLENAME"),".",2,999)) = pTable.%dsd("%STOFF")
	set context.PTT(pTable.%dsd("%TABLENAME")) = pTable
	quit
}

/// RemovePrivateTable() will remove the private table name from the current context object or the process context
/// object. The storage offset information remains to that any existing result sets will still be valid. However,
/// If another instance of a private table with the same name is created any result sets against the prior private
/// table may become invalid.
Method RemovePrivateTable(pTableName As %String(MAXLEN=""))
{
	set tTable = $Get(..PTT(pTableName))
	if ($Isobject(tTable)) { set context = $this }
	elseif ($IsObject($Get(%processcontext))) {
		set tTable = $Get(%processcontext.PTT(pTableName))
		if $IsObject(tTable) { set context = %processcontext } else { set context = $$$NULLOREF }
	}
	else { set context = $$$NULLOREF }
	if $Isobject(context) {
		if $ZUtil(115,14) { do ##class(%XSQL.Log).traceDeferredStatement("DROP TEMP TABLE "_pTableName) }
			#; There are three places in the context object where we hold information about a temporary table - PTT, %LTT, and TTNI.
		kill context.PTT(pTableName)
			#; GLOBAL PRIVATE tables remove themselves on destruct, LOCAL PRIVATE tables leave the storage offset intact but allow
			#; recreate. GLOBAL PRIVATE tables cannot be recreated after DROP until all instances of the table go out of scope.
		if 'tTable.%dsd("%GlobalScope") {
			if $Get(tTable.%dsd("%SOURCENAME")) '= "" { kill context.TTNI($$$UPPER(tTable.%dsd("%SOURCENAME"))) }
				#; Leave %LTT because some result sets might still be accessing it. If we could tell now then we could also remove %LTT.
			if 0 { kill context.%LTT($Piece(pTable.%dsd("%TABLENAME"),".",2,999)) }
		}
	}
	quit
}

/// ResolveTableName will locate a temporary table registered in either the current object (usually equates to
/// %sqlcontext) or in the process context object (%processcontext). The temporary table name passed into this
/// method is the host language name such as #my_temp in TSQL or a normal temporary table name in Informix. This
/// name is the one bound to the actual name in the TTNI (temporary table name index) by the host language procedure.
/// If the table name is not found in TTNI, either local(current object) or global (%processcontext) then the name
/// submitted is returned an no context is returned in the byref pContext argument.
Method ResolveTableName(pTableName As %String(MAXLEN=""), ByRef pContext As %Library.ProcedureContext = "", pDDLFlag As %Integer = 0) As %String
{
	set tTable = $Get(..TTNI($$$UPPER(pTableName)))
	if tTable '= "" { set pContext = $this }
	if $isobject($Get(%processcontext)) { set tTable = $Get(%processcontext.TTNI($$$UPPER(pTableName))) if tTable '= "" { set pContext = %processcontext } }
	if '$isobject(pContext) { quit pTableName }
	if (tTable = -1) && ('pDDLFlag) {
		merge tDDL = pContext.TTNI($$$UPPER(pTableName))
		set tDDL = tDDL(0)
		kill tDDL(0)
		set tTableHandle = ##class(%XSQL.DSI.GlobalPrivateTable).%Prepare(.tDDL) set %sqlcontext.Error= tTableHandle.%Get("%ERROR")
		if '$Isobject(%sqlcontext.Error) { set tTable = tTableHandle.%dsd("%TABLENAME"),pContext.TTNI($$$UPPER(pTableName)) = tTable, tTableHandle.%dsd("%SOURCENAME") = pTableName }
			#; Someday, I hope that %sqlcontext.Error is an exception and we won't have to cast it as an exception.
		else { throw %sqlcontext.Error.AsException() }
	}
	quit tTable
}

Method Reset() As %Status
{
	Kill ..%LTT,..PTT,..Results
	Set ..context="",..%SQLCODE=0,..%Message="",..%CurrentResult="",..%ROWCOUNT=0,..Error=""
	Quit $$$OK
}

/// AddResultSet() - add a new result object to the context object. Results are
/// accessible by callers of the procedure through the %NextResult/%CurrentResult
/// interface.
Method AddResultSet(rs As %Library.IResultSet)
{
	If $isobject(rs) {
		if $ZUtil(115,14) { do ##class(%XSQL.Log).traceMessage("Adding result set to context object") }
		if '..static { Set ..Results($order(..Results(""),-1)+1)=rs }
		else {
			set srs = ##class(%ResultSet.Static).%New(rs)
			set ..Results($order(..Results(""),-1)+1) = srs
		}
	}
	Quit $$$OK
}

/// AddContext() is for nesting procedure context objects. If one procedure invokes another procedure and the results
/// of calling the nested procedure are to be returned to the caller of the outer procedure then simply invoke
/// AddContext on the context object of the outer procedure, passing the context object of the inner procedure as
/// an argument, <var>pContext</var>. If the <var>propagateerror</var> argument is true then any error encountered by the nested procedure
/// will be reported as an error to the caller of the outer procedure.
Method AddContext(pContext As %Library.IProcedureContext, propagateerror As %Boolean = 1) As %Library.Status
{
	If $isobject(pContext) {
		if $ZUtil(115,14) { do ##class(%XSQL.Log).traceMessage("Embedding context object in context object") }
		Set currpos=$order(..Results(""),-1)+1
		Set ..Results(currpos)=pContext,..Results(currpos,1)=""
		If propagateerror {
			If $isobject(pContext.Error),'$isobject(..Error) Set ..Error=pContext.Error
			If pContext.%SQLCODE'=0,pContext.%SQLCODE'=100,..%SQLCODE=0 Set ..%SQLCODE=pContext.%SQLCODE,..%Message=pContext.%Message
		}
	}
	Quit $$$OK
}

/// Used internally only, do not call directly.
Method Prepare(sqlquery As %String(MAXLEN=""), args...) As %Library.IResultSet [ Internal ]
{
	Set cls = $$%RSPrepare^%SYS.ResultSet(sqlquery,.returnError,args...)
	If $isobject($get(returnError)) Set ..%SQLCODE = returnError.SQLCode, ..%Message = returnError.Message
	Quit cls
}

/// Used internally only, do not call directly.
Method NewResultSet(rs As %Library.IResultSet, error As %SYSTEM.Error) [ Internal ]
{
	If $isobject($get(error)) {
		If $isobject(rs) {
			Set rs.%SQLCODE=error.SQLCode,rs.%Message=error.Message
		} Else {
			Set rs=##class(%ResultSet.Result).%New(error.SQLCode,error.Message)
		}
	}
	If $isobject(rs) {
		if '..static { Set ..Results($order(..Results(""),-1)+1)=rs }
		else {
			set srs = ##class(%ResultSet.Static).%New(rs)
			set ..Results($order(..Results(""),-1)+1) = srs
		}
	}
}

/// Used internally only, do not call directly.
Method ReplaceResultSet(pResultSet As %Library.IResultSet = "") [ Internal ]
{
	If $isobject(pResultSet) { set ..Results($order(..Results(""),-1)) = pResultSet }
}

/// Called to return the next resultset object.
/// This also removes the reference to the existing object so it can cleanup and close itself
Method NextResult() As %RegisteredObject [ CodeMode = expression ]
{
..%NextResult()
}

/// Called to return the next resultset object.
/// This also removes the reference to the existing object so it can cleanup and close itself
Method %NextResult() As %RegisteredObject
{
loop	If $isobject(..context) {
		Set ..%CurrentResult=..context.%NextResult()
		If $isobject(..%CurrentResult) do initializeContext Quit ..%CurrentResult
	}
	Set data=$$$NULLOREF,currpos=$order(..Results(""),1,data)
	If currpos'="" {
		Set iscontext=$data(..Results(currpos,1))
		Kill ..Results(currpos)
		If iscontext Set ..context=data	Goto loop
	}
	Set ..%CurrentResult=data,..context=$$$NULLOREF
	if ($isobject(data)) && (data.%ResultColumnCount > 0) { do initializeContext }
	Quit ..%CurrentResult
initializeContext
		#; Ask the new result set guest to make itself comfortable in this context
		#; Presumably this is limited to making sure temporary table objects are properly set up in %LTT
		#; We might want to throw an exception here if this context isn't suitable to our new guest.
	// %CurrentResult is not guaranteed to be a %SQL.IResultSet, so check
	if ..%CurrentResult.%IsA("%SQL.IResultSet") { 
		set tableName = "", tempTable = ..%CurrentResult.%PrivateTables.GetNext(.tableName)
		while tableName '= "" {
			set tableNameNS = $Piece(tableName,".",2,999)
			if 'tempTable.%Get("%GlobalScope") {
				if '$Data(..%LTT(tableNameNS)) { set ..%LTT(tableNameNS) = tempTable.%dsd("%STOFF") }
			}
			else {
				if '$isobject($get(%processcontext)) { set %processcontext = ..%New() }
				if '$Data(%processcontext.%LTT(tableNameNS)) { set %processcontext.%LTT(tableNameNS) = tempTable.%dsd("%STOFF") }
			}
			set tempTable = ..%CurrentResult.%PrivateTables.GetNext(.tableName)
		}
	}
	quit
}

/// Close the current resultset object, used to allow the cleanup code to run and the cursor to close
Method CloseCurrentResult() As %Status
{
	If $isobject(..context) {
		Do ..context.CloseCurrentResult()
	}
	Set ..%CurrentResult = $$$NULLOREF
	Quit $$$OK
}

/// DumpResults()
/// This method writes all of the results to the current device. The <var>pDelimiter</var> parameter
/// is passed to the result set's %Print() method.
Method DumpResults(pDelimiter As %String = " ")
{
	do ..%Display(pDelimiter)
	quit
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	new %msg
	if $d(..LTTCleanup) {
		set table=""
		for  {
			set table=$o(..LTTCleanup(table),1,realtable) quit:table=""
			do DropTable^%apiSQL(table,1,.SQLCODE,.%msg)
			// Should I report an error here if the DROP TABLE fails?
		}
	}
	if $d(..TempGlobalCleanup) {
		set glo=""
		for  {
			set glo=$o(..TempGlobalCleanup(glo)) quit:glo=""
			if $e(glo,1,10)="^IRIS.Temp",$d(@glo) { kill @glo }
		}
	}
	Quit $$$OK
}

}
