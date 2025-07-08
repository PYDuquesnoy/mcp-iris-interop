/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SQL.Diag.Result Extends %Library.Persistent [ Final, StorageStrategy = diagStorage, System = 4 ]
{

Parameter USEEXTENTSET = 1;

Parameter DEFAULTGLOBAL = "^IRIS.sql.diag.result";

Parameter SQLPUBLICSECURITY = "{""Result"":""S"",""add_diag_result"":""E"",""add_diag_message"":""E""}";

Property resultId As %Library.Integer [ Identity, SqlColumnNumber = 2 ];

Property user As %String [ SqlColumnNumber = 6 ];

Property processId As %String [ SqlColumnNumber = 5 ];

Property namespace As %String [ SqlColumnNumber = 4 ];

Property createTime As %PosixTime [ ReadOnly, SqlColumnNumber = 3, SqlComputeCode = { set {*}=##class(%PosixTime).CurrentUTCTimeStamp()}, SqlComputed, SqlComputeOnChange = %%INSERT ];

Property sqlcode As %Integer [ SqlColumnNumber = 7 ];

Property inputRecordCount As %Integer [ SqlColumnNumber = 8 ];

Property errorCount As %Integer [ SqlColumnNumber = 9 ];

Property maxErrorCount As %Integer [ SqlColumnNumber = 10 ];

Property status As %String(MAXLEN = 30) [ SqlColumnNumber = 11 ];

Property statement As %String(MAXLEN = 32768) [ SqlColumnNumber = 12 ];

ClassMethod addDiagResult(maxErrorCount As %Integer = 0) As %Integer [ SqlName = add_diag_result, SqlProc ]
{
	try {
		$$$SuspendAllTrans(transSuspended)
		set concurrency = $system.OBJ.SetConcurrencyMode(0)
		set result = ..%New()
		set result.maxErrorCount = +maxErrorCount
		set result.user = $username
		set result.processId = $JOB
		set result.namespace = $namespace
		set result.status = "In Progress"
		$$$ThrowOnError(result.%Save())
		set ^||iris.sql.diag = result.%Id()
		do finally
		return result.%Id()
	} catch exception {
		do finally
		throw exception
	}
	return
finally
	if $data(concurrency) {
		do $system.OBJ.SetConcurrencyMode(concurrency)
	}
	if $data(transSuspended) {
		$$$ResumeAllTrans(transSuspended)
	}
	return
}

///    SEVERITY_COMPLETED = 0;
///    SEVERITY_INFO = 1;
///    SEVERITY_WARNING = 2;
///    SEVERITY_ERROR = 3;
///    SEVERITY_ABORT = 4;
ClassMethod addDiagMessage(resultId As %Integer, actor As %String, sqlcode As %Integer, message As %String(MAXLEN=""), severity As %Integer) [ SqlName = add_diag_message, SqlProc ]
{
	try {
		$$$SuspendAllTrans(transSuspended)
		set concurrency = $system.OBJ.SetConcurrencyMode(0)
		$$$ThrowOnError(..%LockId(resultId))
		set locked = 1
		set result = ..%OpenId(resultId,,.status)
		if $$$ISERR(status) {
			$$$ThrowStatus(status)
		}
		if severity > 2 {
			set result.errorCount = result.errorCount + 1
			$$$ThrowOnError(result.%Save())
			if (result.maxErrorCount > 0) && (result.errorCount > result.maxErrorCount) {
				if $g(%0SQLLoadError)="loadData" {
					set %0SQLLoadError("SQLCODE")=-400
					set %0SQLLoadError("%msg")="LOAD DATA stopped because the maximum number of errors ("_result.maxErrorCount_") was exceeded.  Execute 'SELECT * FROM %SQL_Diag.Message WHERE diagResult="_resultId_"' for error details"
				}
				$$$ThrowStatus($$$ERROR($$$GeneralError,"%SQL.Diag.Result - maximum error count exceeded"))
			}
		}
		set msg = ##class(%SQL.Diag.Message).%New()
		set msg.diagResult = result
		set msg.actor = actor
		set msg.sqlcode = sqlcode
		set msg.message = message
		set msg.severity = severity
		$$$ThrowOnError(msg.%Save())
		do finally
	} catch exception {
		do finally
		throw exception
	}
	return
finally
	if $data(locked) && locked {
		do ..%UnlockId(resultId,0,1)
	}
	if $data(concurrency) {
		do $system.OBJ.SetConcurrencyMode(concurrency)
	}
	if $data(transSuspended) {
		$$$ResumeAllTrans(transSuspended)
	}
	return
}

ClassMethod updateInputCount(resultId As %Integer, inputCount As %Integer)
{
	try {
		$$$SuspendAllTrans(transSuspended)
		set commitmode=$zu(115,1,0)	// commitmode=none
		&sql(update %sql_diag.result set inputRecordCount = :inputCount where %ID = :resultId)
		if SQLCODE < 0 {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,$get(%msg))
		} elseif SQLCODE = 100 {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LoadObjectNotFound))
		}
		do finally
	} catch exception {
		do finally
		throw exception
	}
	return
finally
	if $data(transSuspended) { $$$ResumeAllTrans(transSuspended) }
	if $d(commitmode) { do $zu(115,1,commitmode) }
	return
}

ClassMethod updateStatus(resultId As %Integer, status As %String)
{
	try {
		$$$SuspendAllTrans(transSuspended)
		set commitmode=$zu(115,1,0)	// commitmode=none
		&sql(update %sql_diag.result set status = :status where %ID = :resultId)
		if SQLCODE < 0 {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,$get(%msg))
		} elseif SQLCODE = 100 {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LoadObjectNotFound))
		}
		do finally
	} catch exception {
		do finally
		throw exception
	}
	return
finally
	if $data(transSuspended) { $$$ResumeAllTrans(transSuspended) }
	if $d(commitmode) { do $zu(115,1,commitmode) }
	return
}

ClassMethod updateStatement(resultId As %Integer, ByRef statement As %String(MAXLEN=32768))
{
	try {
		$$$SuspendAllTrans(transSuspended)
		set commitmode=$zu(115,1,0)	// commitmode=none
		&sql(update %sql_diag.result set statement = :statement where %ID = :resultId)
		if SQLCODE < 0 {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,$get(%msg))
		} elseif SQLCODE = 100 {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LoadObjectNotFound))
		}
		do finally
	} catch exception {
		do finally
		throw exception
	}
	return
finally
	if $data(transSuspended) { $$$ResumeAllTrans(transSuspended) }
	if $d(commitmode) { do $zu(115,1,commitmode) }
	return
}

ClassMethod updateResult(resultId As %Integer, inputCount As %Integer, sqlcode As %Integer)
{
	try {
		$$$SuspendAllTrans(transSuspended)
		set commitmode=$zu(115,1,0)	// commitmode=none
		&sql(update %sql_diag.result
				set inputRecordCount = :inputCount,
					sqlcode = :sqlcode
			where %ID = :resultId)
		if SQLCODE < 0 {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,$get(%msg))
		} elseif SQLCODE = 100 {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LoadObjectNotFound))
		}
		do finally
	} catch exception {
		do finally
		throw exception
	}
	return
finally
	if $data(transSuspended) { $$$ResumeAllTrans(transSuspended) }
	if $d(commitmode) { do $zu(115,1,commitmode) }
	return
}

ClassMethod getLastResultId() As %SQL.Diag.Result [ SqlName = get_last_result_id, SqlProc ]
{
	set lastId = $order(^IRIS.sql.diag.result.1(""), -1)
	while ('(..%ExistsId(lastId))) && (lastId > 0) {
		set lastId = $order(^IRIS.sql.diag.result.1(lastId), -1)
	}
	return lastId
}

Method %ToJSON() As %String(MAXLEN="")
{
	set dao = {}
	set dao.ROWID = ..%Id()
	set dao.createtime = ..createTime
	set dao.SQLCODE = ..sqlcode
	set dao.inputRecordCount = ..inputRecordCount
	set dao.errorCount = ..errorCount
	return dao.%ToJSON()
}

Storage diagStorage
{
<Data name="ResultDefaultData">
<Value name="1">
<Value>user</Value>
</Value>
<Value name="2">
<Value>processId</Value>
</Value>
<Value name="3">
<Value>namespace</Value>
</Value>
<Value name="4">
<Value>createTime</Value>
</Value>
<Value name="5">
<Value>sqlcode</Value>
</Value>
<Value name="6">
<Value>inputRecordCount</Value>
</Value>
<Value name="7">
<Value>errorCount</Value>
</Value>
<Value name="8">
<Value>maxErrorCount</Value>
</Value>
<Value name="9">
<Value>loadStatement</Value>
</Value>
<Value name="10">
<Value>statement</Value>
</Value>
<Value name="11">
<Value>status</Value>
</Value>
</Data>
<DataLocation>^IRIS.sql.diag.result.1</DataLocation>
<DefaultData>ResultDefaultData</DefaultData>
<ExtentLocation>^IRIS.sql.diag.result</ExtentLocation>
<IdLocation>^IRIS.sql.diag.result.1</IdLocation>
<Index name="IDKEY">
<Location>^IRIS.sql.diag.result.1</Location>
</Index>
<IndexLocation>^IRIS.sql.diag.result.I</IndexLocation>
<StreamLocation>^IRIS.sql.diag.result.S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
