/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occXSQLTRACE

Class %XSQL.Log Extends %Library.RegisteredObject [ System = 2 ]
{

Property logFile As %String;

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
Method %OnNew(logFile As %RawString = "", initialize As %Boolean = 0) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	try {
		set ..logFile = $Select(logFile="":"xsql"_$j_".log",1:logFile)
		if '(##class(%Library.File).Exists(..logFile)) { set newFile = 1 }
		else {
			if 'initialize { set newFile = 0 }
			else {
				do ##class(%Library.File).Delete(logFile)
				set newFile = 1
			}
		}
		open ..logFile:$Select(newFile:"WNS",1:"WAS"):2
		if $Test {
			if newFile { do ..logHeader() }	else { set currDevice = $IO use ..logFile write !!,$$$TRACETIMESTAMP,"Log restarted",! use currDevice }
			set tSC = $$$OK
		}
		else {
			set tSC = $$$ERROR($$$GeneralError,"Cannot open log file: '" _ ..logFile _ "'")
		}
	}
	catch tException {
		set tSC = tException.AsStatus()
	}
	quit tSC
}

Method %OnClose() As %Status [ Private ]
{
	if ..logFile '= "" {
		set currDevice = $IO
		use ..logFile
		write !,$$$TRACETIMESTAMP,"Log stopped",!
		write $$$TRACETIMESTAMP,"------------------------------------------",!
		use currDevice
		close ..logFile
	}
	Quit $$$OK
}

/// write() - write a message to the current log file
Method write(message As %String(MAXLEN=""), linesBefore As %Integer = 0, linesAfter As %Integer = 1) As %Status
{
	set currDevice = $IO use ..logFile for ptr = 1:1:linesBefore { write ! } write message for ptr = 1:1:linesAfter { write ! }  use currDevice
	quit $$$OK
}

/// ActivateLog (also called as a procedure - CALL InSync_SYS.activate_log()) will set the trace switch
/// to begin logging. Messages logged using $$$TRACE macros will be written to the log file.
ClassMethod ActivateLog() As %Integer [ SqlName = activate_log, SqlProc ]
{
	quit $$$SETTRACE(1)
}

/// DeactivateLog (also callable as a procedure - CALL InSync_SYS.deactivate_log()) will turn of the trace
/// switch so that $$$TRACE macros will not longer be written to the log file. The log file is also closed.
ClassMethod DeactivateLog() As %Integer [ SqlName = deactivate_log, SqlProc ]
{
	kill %xsqlLog
	quit $$$SETTRACE(0)
}

/// <P> Report an error from a %SYSTEM.Error object
/// <P>
/// <UL>
///  <LI><P> pError	 - an instance of %SYSTEM.Error
/// </UL>
Method logError(pError As %SYSTEM.Error)
{
	set currDevice = $IO
	use ..logFile
	if $Isobject(pError) {
		do pError.getOdbcError(.sqlcode,.message)
		write $$$TRACETIMESTAMP,$Char(9),"ERROR: ",sqlcode," ",message,!
	}
	else { write $$$TRACETIMESTAMP,$Char(9),"Success",! }
	use currDevice
	quit $$$OK
}

Method logException(pException As %Exception.AbstractException, pPrefix As %String = {$Char(9,9)})
{
	set currDevice = $IO
	use ..logFile
	if $Isobject(pException) {
		set tSQLCODE = pException.AsSQLCODE(), tMessage = pException.AsSQLMessage()
		write $$$TRACETIMESTAMP,pPrefix,"EXCEPTION: ",tSQLCODE," ",$system.SQL.SQLCODE(tSQLCODE),!
		write:$g(tMessage)'="" $$$TRACETIMESTAMP,pPrefix,"           ",tMessage,!
	}
	else { write $$$TRACETIMESTAMP,pPrefix,"Success",! }
	use currDevice
	quit $$$OK
}

/// <P> Report a named value
/// <P>
/// <UL>
///  <LI><P> pName	 - the name of the value, for example, 'pFormal1' as the name of a formal argument
///  <LI><P> pValue	 - the value
/// </UL>
Method logValue(pName As %String(MAXLEN="") = "", pValue As %String(MAXLEN="") = "")
{
	set currDevice = $IO
	use ..logFile
	write $$$TRACETIMESTAMP,$Char(9),pName," = ",$Select(+pValue'=pValue:$zu(144,1,pValue),1:pValue),!
	use currDevice
	quit $$$OK
}

/// <P> Report a function and its return value.
/// <P>
/// <UL>
///  <LI><P> pName	 - the name of the value, for example, 'pFormal1' as the name of a formal argument
///  <LI><P> pValue	 - the value
/// </UL>
Method logFunction(pName As %String(MAXLEN="") = "", pValue As %String(MAXLEN="") = "")
{
	set currDevice = $IO
	use ..logFile
	if $Get(%xsqlCall) { write $$$TRACETIMESTAMP,%xsqlCall(1) for tPtr = 2:1:%xsqlCall { write "->",%xsqlCall(tPtr) } write ! }
	write $$$TRACETIMESTAMP,$Char(9),"User Function call: ",pName," returned: ",$Select(+pValue'=pValue:$zu(144,1,pValue),1:pValue),!
	use currDevice
	quit $$$OK
}

/// <P> Copy the contents of a stream to the log
/// <P>
/// <UL>
///  <LI><P> stream - stream to copy to the file.
/// </UL>
Method logStream(stream As %Stream.Object, pNumbered As %Integer = 0)
{
	set currDevice = $IO
	use ..logFile
	write $$$TRACETIMESTAMP,"Stream content: "
	do stream.Rewind()
	set tLine = 0
	while 'stream.AtEnd { do ..write($select('pNumbered:"",1:$Justify($Increment(tLine),4)_". ")_stream.ReadLine()) }
	use currDevice
	quit $$$OK
}

/// <P> Report a status message from a trace
/// <P>
/// <UL>
///  <LI><P> sc - pass as status code
///  <LI><P> message - pass a message to be written both to the current device and to the log (or "") (optional)
///  <LI><P> outcome - pass an array of stats (optional)
/// </UL>
Method logStatus(StatusCode As %Status, Message As %String, ByRef Outcome) As %Integer
{
	set currDevice = $IO
	use ..logFile
	write $$$TRACETIMESTAMP,"-----",!
	If $Get(Message)'="" {
		write Message,!
	}
	Kill errorlist
	Do DecomposeStatus^%apiOBJ(StatusCode,.errorlist)
	For i=1:1:$Get(errorlist) { write $$$TRACETIMESTAMP,errorlist(i),! }
	If $Data(Outcome)\10 { write $$$TRACETIMESTAMP,"["_##class(%XSQL.Format).Flatten(.Outcome)_"]",! }
	write $$$TRACETIMESTAMP,"-----",!
	use currDevice
	quit $Get(errorlist)
}

Method logHeader() As %Status
{
	set currDevice = $IO
	use ..logFile
	write "XSQL Log, created ",$zdt($h)," by process ",$j," in namespace ",$namespace,!
	write $c(9),"Version: ",$zv,!
	write $c(9),"   User: ",$username,!!
	use currDevice
	quit $$$OK
}

/// Log the contents of a %SQL.StatementResult object
Method logStatementResult(pResult As %SQL.StatementResult) As %Status
{
	#dim tException as %Exception.AbstractException
	set tStatus = $$$OK
	try {
		set currDevice = $IO
		use ..logFile
		write $$$TRACETIMESTAMP,"Statement result:",!
		do pResult.%Display()
		use currDevice
	}
	catch tException { set tStatus = tException.AsStatus() }
	quit tStatus
}

/// Log SQL statement source
Method logStatementSource(pBatchNumber As %Library.Integer, ByRef pSource As %Library.String(MAXLEN=""), pLinesBefore As %Integer = 0, pLinesAfter As %Integer = 1) As %Status
{
	#dim tException as %Exception.AbstractException
	try {
		set tStatus = $$$OK
		set currDevice = $IO
		use ..logFile
		write $$$TRACETIMESTAMP,"Statement source:",!
		set $Piece(tDashes,"-",80) = ""
		do ..write(tDashes,2,pLinesBefore)
		do ..write("-- Statement batch #"_pBatchNumber_":",1,1)
		if pSource {
			for tLinePtr = 1:1:pSource-1 { do ..write($Char(9)_$Justify(tLinePtr,4)_". "_pSource(tLinePtr)) }
			do ..write($Char(9)_$Justify(pSource,4)_". "_pSource(pSource),,pLinesAfter)
		}
		use currDevice
	}
	catch tException { set tStatus = tException.AsStatus() }
	quit tStatus
}

Method logResults(context As %Library.ProcedureContext) As %Status
{
	#dim tException as %Exception.AbstractException
	set tStatus = $$$OK
	try {
		set currDevice = $IO
		use ..logFile
		if context.Error '= $$$NULLOREF { do ..logError(context.Error) }
		if (context.%SQLCODE) && ( context.%SQLCODE '= 100) { write $$$TRACETIMESTAMP,$Char(9),"SQLCODE = ",context.%SQLCODE,$Select(context.Message'="":" "_context.Message,1:"") }
		do context.DumpResults()
		use currDevice
	}
	catch tException { set tStatus = tException.AsStatus() }
	quit tStatus
}

Method logResultSet(pContext As %Library.ProcedureContext, pResultSet As %Library.IResultSet) As %Status
{
	#dim tException as %Exception.AbstractException
	set tStatus = $$$OK
	try {
		set currDevice = $IO
		use ..logFile
		if $Get(%xsqlCall) { write $$$TRACETIMESTAMP,%xsqlCall(1) for tPtr = 2:1:%xsqlCall { write "->",%xsqlCall(tPtr) } write ": " }
		write "(Result set added to context object)",!
		if pResultSet.%SQLCODE { write $$$TRACETIMESTAMP,$Char(9),"SQLCODE = ",pResultSet.%SQLCODE,$Select(pResultSet.Message'="":" "_pResultSet.Message,1:"") }
		#dim tResultSet as %ResultSet.Static
		set tResultSet = ##class(%ResultSet.Static).%Prepare(pResultSet)
		set tRow = 0
			#; Display up to 10 rows from the result set.
		set tRSMD = tResultSet.%GetMetaData()
		if $Isobject(tRSMD) {
			set tCount = tRSMD.columns.Count()
			write $Char(9,9),"COLS/ROWS ",tRSMD.columns.GetAt(1).colName
			for tColumn = 2:1:tCount {
				set tColumn = tRSMD.columns.GetAt(tColumn)
				write $Char(9),tColumn.colName
			}
		}
		while (tResultSet.%Next()) && (tRow < 10) { write !,$Char(9,9),$Justify($Increment(tRow),9),". " do tResultSet.%Print($Char(9)) }
		do tResultSet.%SetIterator()
		write !,$Char(9),tResultSet.%ROWCOUNT," Row(s) affected",!!
			#; substitute the static (rewound) result for the original (now consumed) result
		do pContext.ReplaceResultSet(tResultSet)
		use currDevice
	}
	catch tException { set tStatus = tException.AsStatus() }
	quit tStatus
}

Method logEnterProcedure(pProcedureName As %Library.String, ByRef pArguments As %Library.String) As %Status
{
	#dim tException as %Exception.AbstractException
	set tStatus = $$$OK
	try {
		set currDevice = $IO
		use ..logFile
		write $$$TRACETIMESTAMP,"Entering procedure: ",pProcedureName,!
		if $Get(%xsqlCall) { write $$$TRACETIMESTAMP,%xsqlCall(1) for tPtr = 2:1:%xsqlCall { write "->",%xsqlCall(tPtr) } write ! }
		elseif $system.Process.CallingRoutine()'="" { write $$$TRACETIMESTAMP," called from '"_$system.Process.CallingRoutine()_"'",! }
		if $g(pArguments) {
			write $$$TRACETIMESTAMP,$c(9),"Arguments:",!
			for tPtr=1:1:pArguments set tData=$g(pArguments(tPtr)) if $listvalid(tData),tData'="" w $$$TRACETIMESTAMP,$c(9,9),$lg(tData)," = ",$lg(tData,2),!
		}
		use currDevice
	}
	catch tException { set tStatus = tException.AsStatus() }
	quit tStatus
}

Method logEmbeddedSQL(pStatement As %Library.String, pSQLCODE As %Library.Integer, pMsg As %Library.String, pROWCOUNT As %Library.Integer, pTime As %Library.Numeric, ByRef pArguments As %Library.String) As %Status
{
	#dim tException as %Exception.AbstractException
	set tStatus = $$$OK
	try {
		set currDevice = $IO
		use ..logFile
		write $$$TRACETIMESTAMP,"Execution of embedded/deferred SQL Code in procedure: ",$Select($get(%xsqlCall):$g(%xsqlCall(%xsqlCall)),1:"unknown"),!
		write $$$TRACETIMESTAMP,$c(9),"Statement:",!,$c(9),pStatement,!
		if $g(pArguments) {
			write $$$TRACETIMESTAMP,$c(9),"Arguments:",!
			for tPtr=1:1:pArguments set tData=$g(pArguments(tPtr)) if $listvalid(tData),tData'="" w $$$TRACETIMESTAMP,$c(9,9),$lg(tData)," = ",$lg(tData,2),!
		}
		write:$g(pSQLCODE)'="" $$$TRACETIMESTAMP,$Char(9),"SQLCODE = ",pSQLCODE,!
		write:$g(pMsg)'="" $$$TRACETIMESTAMP,$c(9),"%msg = ",pMsg,!
		write:$g(pROWCOUNT)'="" $$$TRACETIMESTAMP,$Char(9),"%ROWCOUNT = ",pROWCOUNT,!
		write:$d(pTime) $$$TRACETIMESTAMP,$Char(9),"Elapsed Time = ",pTime,!
		use currDevice
	}
	catch tException { set tStatus = tException.AsStatus() }
	quit tStatus
}

/// <P>Log an SQLCODE and %msg value</P>
/// <P>
/// <UL>
/// <LI><P>pSQLCODE	- the SQLCODE value</P>
/// 	<LI><P>pMessage	- the %msg value</P>
/// <LI><P>pPrefix	- the prefix to use when writing the log content, defaults to two tab characters.</P>
/// </UL>
/// </P>
Method logSQLCODE(pSQLCODE As %Library.Integer = 0, pMessage As %String(MAXLEN="") = "", pPrefix As %String = {$Char(9,9)}) As %Status
{
	set currDevice = $IO
	use ..logFile
	if pSQLCODE {
		write $$$TRACETIMESTAMP,pPrefix,"SQLCODE: ",pSQLCODE," ",$system.SQL.SQLCODE(pSQLCODE),!
	}
	else { write pPrefix,"Success",! }
	write:$g(pMessage)'="" $$$TRACETIMESTAMP,pPrefix,"         ",pMessage,!
	use currDevice
	quit $$$OK
}

ClassMethod prepareLog()
{
#dim %xsqlLog as %XSQL.Log
	if $Isobject($Get(%xsqlLog)) {
		if '(%xsqlLog.%IsA("%XSQL.Log")) {
			set tLogFile = %xsqlLog.logFile
			do %xsqlLog.stopLog()
			kill %xsqlLog
			do ..startLog(tLogFile)
			do %xsqlLog.write("Log restarted as %XSQL.Log",1)
		}
	}
	else { do ..startLog() }
	quit
}

ClassMethod startLog(logFile As %RawString = "", initialize As %Boolean = 0) As %Status
{
	set %xsqlLog = ..%New(.logFile,.initialize)
	quit $$$OK
}

ClassMethod stopLog() As %Status
{
	kill %xsqlLog
	quit $$$OK
}

ClassMethod traceMessage(message As %String(MAXLEN=""), linesBefore As %Integer = 0, linesAfter As %Integer = 1) As %Status
{
	do ..prepareLog()
	set currDevice = $IO
	use %xsqlLog.logFile
	for ptr = 1:1:linesBefore { write ! }
	if $Get(%xsqlCall) { write $$$TRACETIMESTAMP,%xsqlCall(1) for tPtr = 2:1:%xsqlCall { write "->",%xsqlCall(tPtr) } write ":",! }
	write $$$TRACETIMESTAMP,message
	for ptr = 1:1:linesAfter { write ! }
	use currDevice
	quit $$$OK
}

ClassMethod traceDeferredStatement(statementType, ByRef sql As %String(MAXLEN="") = "", ByRef %args As %String(MAXLEN="") = "") As %Status
{
	do ..prepareLog()
	set currDevice = $IO
	use %xsqlLog.logFile
	if $Get(%xsqlCall) { write %xsqlCall(1) for tPtr = 2:1:%xsqlCall { write "->",%xsqlCall(tPtr) } write ":",! }
	write $$$TRACETIMESTAMP,$Char(9),$justify("PREPARE "_statementType_": ",16),$Select(sql:sql(1),1:sql),!
	if sql { for line = 2:1:sql { write $$$TRACETIMESTAMP,$Char(9,9),sql(line),! } }
	if %args { for tPtr = 1:1:%args { write $$$TRACETIMESTAMP,?16,"?(",tPtr,") = ",$Get(%args(tPtr))," " } write ! }
	use currDevice
	quit $$$OK
}

ClassMethod traceContext(context As %Library.ProcedureContext) As %Status
{
	do ..prepareLog()
	set currDevice = $IO
	use %xsqlLog.logFile
	write $$$TRACETIMESTAMP,$c(9),"context object: "_context,!
	write $$$TRACETIMESTAMP,$c(9,9),"",!
	write $$$TRACETIMESTAMP,$c(9,9),"",!
	if '$Isobject(context.Error) { write $$$TRACETIMESTAMP,$c(9,9),"Context status is OK",!! } else { write $$$TRACETIMESTAMP,$c(9,9),"      Error: " do $system.OBJ.DisplayError(context.Error.Status) write !,$$$TRACETIMESTAMP,! }
	use currDevice
	quit $$$OK
}

/// <P> Report an exception from a trace
/// <P>
/// <UL>
///  <LI><P> pException - pass as an exception oref
/// </UL>
ClassMethod traceException(pException As %Exception.AbstractException, pPrefix As %Library.String = {$Char(9)}) [ ProcedureBlock = 1 ]
{
#dim %xsqlLog as %XSQL.Log
	do ..prepareLog()
	quit %xsqlLog.logException(pException,pPrefix)
}

/// <P> Report a status message from a trace
/// <P>
/// <UL>
///  <LI><P> sc - pass as status code
///  <LI><P> message - pass a message to be written both to the current device and to the log (or "") (optional)
///  <LI><P> outcome - pass an array of stats (optional)
/// </UL>
ClassMethod traceStatus(StatusCode As %Status, Message As %String, ByRef Outcome)
{
#dim %xsqlLog as %XSQL.Log
	do ..prepareLog()
	set currDevice = $IO
	use %xsqlLog.logFile
	Do %xsqlLog.traceMessage("-----")
	If $Get(Message)'="" {
		Do %xsqlLog.traceMessage(Message)
	}
	Kill errorlist
	Do DecomposeStatus^%apiOBJ(StatusCode,.errorlist)
	For i=1:1:$Get(errorlist) {Do %xsqlLog.traceMessage(errorlist(i))}
	If $Data(Outcome)\10 {Do %xsqlLog.traceMessage("["_##class(%XSQL.Format).Flatten(.Outcome)_"]")}
	Do %xsqlLog.traceMessage("-----")
	use currDevice
	quit $$$OK
}

/// <P> Report an error from a %SYSTEM.Error object
/// <P>
/// <UL>
///  <LI><P> error	 - an instance of %SYSTEM.Error
/// </UL>
ClassMethod traceError(pError As %SYSTEM.Error) As %Status
{
	do ..prepareLog()
	quit %xsqlLog.logError(.pError)
}

/// <P> Report a named value
/// <P>
/// <UL>
///  <LI><P> pName	 - the name of the value, for example, 'pFormal1' as the name of a formal argument
///  <LI><P> pValue	 - the value
/// </UL>
ClassMethod traceValue(pName As %String(MAXLEN="") = "", pValue As %String(MAXLEN="") = "")
{
	do ..prepareLog()
	quit %xsqlLog.logValue(pName,pValue)
}

/// <P> Report a function and its return value.
/// <P>
/// <UL>
///  <LI><P> pName	 - the name of the function method
///  <LI><P> pValue	 - the return value
/// </UL>
ClassMethod traceFunction(pName As %String(MAXLEN="") = "", pValue As %String(MAXLEN="") = "")
{
	do ..prepareLog()
	quit %xsqlLog.logFunction(pName,pValue)
}

ClassMethod traceResult(pContext As %Library.ProcedureContext) As %Status
{
	do ..prepareLog()
	quit %xsqlLog.logResults(.pContext)
}

ClassMethod traceResultSet(pContext As %Library.ProcedureContext, pResultSet As %Library.IResultSet) As %Status
{
	do ..prepareLog()
	quit %xsqlLog.logResultSet(.pContext,.pResultSet)
}

/// <P> Report a execution of embedded/deferred SQL, its arguments, and status.
/// <P>
/// <UL>
///  <LI><P> pStatement	 - the text of the SQL Statement executed
///  <LI><P> pArguments	 - the Arguments and their values
///  <LI><P> pSQLCODE	 - the resulting SQLCODE
///  <LI><P> pMsg	 - the resuting %msg (if any)
///  <LI><P> pROWCOUNT	 - the resulting %ROWCOUNT (if any)
///  <LI><P> pTime	 - the execution time (if any)
/// </UL>
ClassMethod traceEmbeddedSQL(pStatement As %Library.String, pSQLCODE As %Library.Integer, pMsg As %Library.String, pROWCOUNT As %Library.Integer, pTime As %Library.Numeric, pArguments... As %Library.String) As %Status
{
	do ..prepareLog()
	quit %xsqlLog.logEmbeddedSQL(.pStatement,.pSQLCODE,.pMsg,.pROWCOUNT,.pTime,.pArguments)
}

/// <P>Log an SQLCODE and %msg value</P>
/// <P>
/// <UL>
/// <LI><P>pSQLCODE	- the SQLCODE value</P>
/// 	<LI><P>pMessage	- the %msg value</P>
/// <LI><P>pPrefix	- the prefix to use when writing the log content, defaults to two tab characters.</P>
/// </UL>
/// </P>
ClassMethod traceSQLCODE(pSQLCODE As %Library.Integer = 0, pMessage As %String(MAXLEN="") = "", pPrefix As %String = {$Char(9,9)}) As %Status
{
	do ..prepareLog()
	quit %xsqlLog.logSQLCODE(pSQLCODE,pMessage,pPrefix)
}

ClassMethod traceEnterProcedure(pProcedureName As %String, pArguments... As %Library.String) As %Status
{
	do ..prepareLog()
	set %xsqlCall($Increment(%xsqlCall)) = pProcedureName
	quit %xsqlLog.logEnterProcedure(pProcedureName,.pArguments)
}

ClassMethod traceEnterFunction(pProcedureName As %String, pArguments... As %Library.String) As %Status
{
	do ..prepareLog()
	quit %xsqlLog.logEnterProcedure(pProcedureName,.pArguments)
}

ClassMethod traceExitProcedure() As %Status
{
	if $Get(%xsqlCall) { kill %xsqlCall(%xsqlCall) set %xsqlCall = %xsqlCall - 1 }
	quit $$$OK
}

}
