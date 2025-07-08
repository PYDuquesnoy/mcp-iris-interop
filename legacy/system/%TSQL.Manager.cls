/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %apiXSQL

/// <p><b>%TSQL.Manager is deprecated</b>. Use $system.SQL.TSQL(), $system.SQL.Shell() with dialect set to either Sybase or MSSQL, or 
/// $system.SQL.DDLImport() instead. The simplest method for importing a file containing T/SQL statements is to use the SQL 
/// Shell with the dialect set to Sybase or MSSQL. $system.SQL.TSQL() is a simple shortcut to launch the SQL shell using the 
/// default dialect as defined in the system configuration. In the SQL Shell simply execute the RUN command with the name of 
/// the file to be executed. This will initiate a dialog to set various RUN options and then the statements in the file will be 
/// executed. 
/// </p>
/// <p>%TSQL.Manager implements several utility methods for importing and executing files/streams containing TSQL statements. </p>
Class %TSQL.Manager [ Abstract, Deprecated, System = 4 ]
{

/// Import a file of TSQL statement batches. This should be called 'Load' but for PPCF we need to maintain the 'load' method interface and 'Load' is a name conflict.
/// 	Parameters:
/// 
/// 	pDialect	- The dialect of TSQL contained in the input file. Values are MSSQL or Sybase, Sybase is the default;
/// 	pInputFile	- The name of the TSQL source file;
/// pLogFile	- The name of the log file. Input source statements and the result of execution are logged;
/// pRunMode	- The SQL Statement runtime mode;
/// 					0 - Logical (default)
/// 					1 - ODBC
/// 					2 - Display
/// pErrorPause	- The number of seconds to pause after encountering an error. Not all errors will pause. Default is 5 seconds. Specifying 0 will disable all pauses.
/// pQSpec		- Runtime options and flags. The only option relevant to TSQL import is 'displaylog'. If it is false, no logging will be done.
ClassMethod Import(pDialect As %String, pInputFile As %RawString = "", pLogFile As %RawString = "", pRunMode As %Integer, pErrorPause As %Integer, ByRef pQSpec As %RawString) As %Status
{
	set $ZTrap = "Catch"
	set tSC = $$$qualifierParse("Compiler",.pQSpec,.qstruct)
	if $$$ISERR(tSC) { goto Exit }
	if '$$$GetDelimitedIds {
		write !,"Support for delimited identifiers is currently turned off."
		write !,"If any Statements in this script file contain delimited"
		write !,"(quoted or bracketed) identifiers, the statements will not compile"
		write !!,"Continue anyway?  Y=> " read tResponse set:tResponse="" tResponse="Y" set tResponse=$zconvert(tResponse,"U")
		if $Extract(tResponse) '= "Y" { goto Exit }
	}
	set tDialect = $Get(^%SYS("tsql","DIALECT"),"Sybase")
	if $Get(pDialect) = "" { write !!,"Enter the DDL statement dialect (MSSQL or Sybase)?   (" _ tDialect _ ") => " read pDialect set:pDialect="" pDialect = tDialect }
	if pInputFile = "" {
			#;  Prompt for and Open the input file
		write !,"Enter TSQL File Name to Import: "
		read pInputFile
	}
	if ($$$qualifierGetValue(qstruct,"displaylog")) && (pLogFile = "") {
			#;  Prompt for and Open the log file
		write !,"Enter the name of the log file: "
		read pLogFile
	}
	if $Get(pRunMode) = "" { write !!,"Enter the SQL statement mode (0 - logical, 1 - ODBC, 2 - display)? (0) => " read pRunMode set:pRunMode="" pRunMode=0 }
	if $Get(pErrorPause) = "" { write !!,"Pause how many seconds after error ( 0 means no pause)?   5 => " read pErrorPause set:pErrorPause="" pErrorPause=5 }
	set tStatementBatch = ##class(%XSQL.StatementBatch).%New()
	set tStatementBatch.inputStream = ##class(%FileCharacterStream).%New()
	set tSC = tStatementBatch.inputStream.LinkToFile(pInputFile)
	if $$$ISERR(tSC) { goto Exit }
		#; make sure that the base node of settings is defined
	set tStatementBatch.settings = ""
	merge tStatementBatch.settings = ^%SYS("tsql")
	set tStatementBatch.dialect = pDialect, tStatementBatch.runtimeMode = pRunMode, tStatementBatch.errorPause = pErrorPause
	;set tStatementBatch.package = $$GetPackage^%apiDDL($$$DefaultSchema,1) _ "."
	set displayLog=0
	if $$$qualifierGetValue(qstruct,"displaylog") {
		set tStatementBatch.log = ##class(%TSQL.sys.log).%New(pLogFile,1)
		set displayLog = 1
		do tStatementBatch.log.write("++++++  Processing SQL script file: " _ pInputFile _"  +++++       "_$ZDateTime($Horolog),1,2)
	}
	set tSC = tStatementBatch.execute(.qstruct)
	if displayLog {
		do tStatementBatch.log.write("Batches executed: "_tStatementBatch.executeCount,2)
		do tStatementBatch.log.write(" Errors reported: "_tStatementBatch.errorCount)
		do tStatementBatch.log.logStream(tStatementBatch.errors)
			#; Put summary reporting here
	}
Exit	quit tSC
Catch	set $ZTrap = ""
	set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	if $Get(displayLog) { if $IsObject(tStatementBatch.log) { do tStatementBatch.log.logStatus(tSC) } else { do ##class(%TSQL.sys.log).logStatus(tSC) } }
	QUIT tSC
}

/// load()
/// 
/// 		This method loads and executes TSQL statements from a file. Execution of individuals batches
/// 		of statements is triggered when a "GO" statement is processed.
/// arguments:
/// 
/// 		DDLMode		- The dialect of the source statements. Supported dialects are Sybase and MSSQL
/// 		scriptFile	- the file containing SQL statements to be executed;
/// 		logFile		- the file to log executed statements and results;
/// 		runtimeMode	- the mode in which SQL statements are to be executed. "" means use the default, 0 is logical, 1 is ODBC and 2 is DISPLAY
/// 		qspec		- option flags and qualifiers
ClassMethod load(DDLMode As %RawString = "Sybase", scriptFile As %RawString, logFile As %RawString = "", runtimeMode As %Integer, ByRef qspec As %RawString) As %Status
{
	quit ..Import(DDLMode,.scriptFile,.logFile,.runtimeMode,,.qspec)
}

/// interactive()
/// 
/// 		DDLMode		- The dialect of the source statements. Supported dialects are Sybase and MSSQL
/// 		logFile 	- the name of a file to send log output to
/// 		runtimeMode	- the mode in which SQL statements are to be executed. "" means use the default, 0 is logical, 1 is ODBC and 2 is DISPLAY
/// 		qspec		- flags and options. If displayLog is true then all output is routed to logFile.
/// 
/// 	This method reads source from the principle device. Execution of individual batches of statements
/// 	is triggered when a "GO" statement is processed. CREATE PROCEDURE|FUNCTION|TRIGGER will also trigger execution of previously entered lines.
ClassMethod interactive(DDLMode As %RawString = "Sybase", logFile As %RawString = "", runtimeMode As %Integer, ByRef qspec As %RawString) As %Status
{
	set $ZTrap = "Catch"
	set status = $$$qualifierParse("Compiler",.qspec,.qstruct)
	if $$$ISERR(status) { goto Exit }
	merge settings = ^%SYS("tsql")
	if $$$qualifierGetValue(qstruct,"displaylog") {
		set log = ##class(%TSQL.sys.log).%New(logFile,1)
		set displayLog = 1
		do log.write("++++++  Processing Interactive TSQL  +++++       "_$ZDateTime($Horolog),1,2)
	}
	else { set log = $$$NULLOREF }
	set batchCount = 0, cachedLine = "", exitShell = 0
	write #,"Cache TSQL ",$zv
		#; read the first input stream. cachedLine is just for input management and we need to keep it but do nothing else with it. exitShell indicates that the input device sent us an 'exit'
	set inputStream = ..readInteractive(.cachedLine,.exitShell)
	while $isobject(inputStream) {
		do inputStream.Rewind()
		set batch = ##class(%XSQL.StatementBatch).%New()
		set batch.inputStream = inputStream, batch.dialect = DDLMode, batch.runtimeMode = $Get(runtimeMode), batch.log = log, batch.errorPause = 5
			#; make sure that the base node of settings is defined
		set batch.settings = ""
		merge batch.settings = ^%SYS("tsql")
			; set batch.package = $$GetPackage^%apiDDL($$$DefaultSchema,1) _ "."
		set return = batch.execute(.qstruct)
		set batchCount = batchCount + 1
		if 'exitShell { set inputStream = ..readInteractive(.cachedLine,.exitShell) } else { set inputStream = $$$NULLOREF }
	}
	if $isobject(log) {
		do log.write("Batches executed: "_batch.executeCount,2)
		do log.write(" Errors reported: "_batch.errorCount)
		do log.logStream(batch.errors)
			#; Put summary reporting here
	}
Exit	quit $$$OK
Catch	set $ZTrap = ""
	set status = $$$ERROR($$$ObjectScriptError,$ZE)
	if $Get(displayLog) { if $IsObject($Get(log)) { do log.logStatus(status) } else { do ##class(%TSQL.sys.log).logStatus(status) } }
	QUIT status
}

ClassMethod readInteractive(ByRef cachedLine As %String(MAXLEN="") = "", ByRef exitShell As %Integer = 0) As %Stream.Object
{
		#; read from the current device and write it into a stream
	set stream = ##class(%Stream.GlobalCharacter).%New()
	set stream.LineTerminator = $Char(10)
	if cachedLine '= "" { set lineCount = 1 }
	else { set lineCount = 0 }
	set sourceCount = lineCount
		#; Read the first line
	do ReadLine(.sourceCount,.line,.exitShell)
	set atEnd = exitShell
		#; write separator lines to log
	while 'atEnd {
		set line = $ZStrip($Translate(line,$Char(9)," "), "*C", $C(254)_$C(255))
			#; input line uppercased
		set uline=$ZCVT(line,"U")
			#; procLine is TRUE when we are entering a procedure or a trigger. It implies a 'GO'
		set procLine = 0
			#; procLine is only recognized as a terminator if it isn't the first line
		if sourceCount > 1 { if uline?." "1"CREATE"1." "1(1"PROC",1"FUNCTION").E { set procLine = 1 } elseif uline?." "1"CREATE"1." "1"TRIGGER".E { set procLine = 2 } }
			#; does the line begin with GO? That means execute the statements. A procedure or trigger is an implied GO...
		if '((uline?." "1"GO".1(1(1"--",1" ").E)) || (procLine)) { do stream.WriteLine(line) if $Length(line) { set lineCount = lineCount + 1 } do ReadLine(.sourceCount,.line,.exitShell) if exitShell { set atEnd = 1 } }
		elseif procLine { set cachedLine = line, atEnd = 1 }
		else { set atEnd = 1 }
	}
	if 'sourceCount && exitShell { set stream = $$$NULLOREF }
	quit stream
ReadLine(sourceCount,line,atEnd)
	set atEnd = 0
			#; Prompt
	write !,$namespace," ",sourceCount + 1,">>"
	read line
	if line = "" { do ReadLine(.sourceCount,.line,.atEnd) }
		#; process commands here
	elseif $Case($Extract(line,1),"#":1,"?":1,:0) { set command = $$$UPPER($Extract(line,2,4)) if $Case(command,"EXI":1,"BYE":1,:0) { set atEnd = 1 } }
		#; must be a source line
	else { set sourceCount = sourceCount + 1 }
	QUIT
}

}
