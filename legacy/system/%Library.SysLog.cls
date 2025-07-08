/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provide a %Library.SysLog class to allow logging of events while programs are running in a consistent fashion.
/// The advantage of using this is that we can use standard utilities to manage and display this log. Also all
/// log entries automatically get the current namespace, date/time, routine name and process Id logged.<p>
/// To make logging easier there are three macros defined in <b>%occDiagnostics.inc</b>. This file is included automatically
/// when compiling any class and so you only need to include it manually if you are compiling a MAC file. The macros are:
/// <ul>
/// <li><b>$$$SysLog(level,category,message,data)</b> - If the logging level is greater or equal to 'level' this calls
/// Log^%SYS.ISCLOG with the same parameters except 'routine' is set to $ZNAME. If 'data' is an array
/// then pass it by reference</li>
/// <li><b>$$$SysLogError(category,message)</b> - If the logging level is greater than zero it will call LogError^%SYS.ISCLOG
/// with the same parameters except 'routine' is set to $ZNAME.</li>
/// <li><b>$$$SysLogUser</b> - If the logging level is greater than 1 it calls
/// LogUserInfo^%SYS.ISCLOG with 'routine' set to $ZNAME and the other parameters coming from $ZU(67)</li>
/// </ul></p>
/// <p>
/// One of the advantages of these macros is that they check the logging level before calling the <METHOD>Log</METHOD>
/// method and so if logging is not turned on at this level then the log macro takes almost no time to execute.</p>
Class %Library.SysLog [ System = 3 ]
{

/// Log an event to the system log if the system logging level is greater or equal to the level passed in.
/// You must specify a <var>level</var> to log this event at, the choice being:
/// <ul>
/// <li>0 - No logging</li>
/// <li>1 - Exceptional events logged, e.g. error messages</li>
/// <li>2 - Detailed event log information, e.g. 'method ABC invoked with parameters X,Y,Z and returned 1234'</li>
/// <li>3 - Raw information logging, e.g. the byte contents of the TCP/IP request sent from the client</li>
/// </ul>
/// The <var>category</var> is a text field that allows you to subdivide the log entries into various types
/// you normally pick a name for each application such as 'HTTP' for the in build web server in InterSystems IRIS or 'IMT' for
/// the InterSystems Message Transport application. The <var>message</var> is any text message that you wish to be recorded,
/// <var>data</var> is any extra data you wish to log. <var>routine</var> is optional and is the routine name you called from.
/// Note that <var>data</var> can be passed by reference and if done it will merge all this information into
/// a subscript of the log global so you can store large quantities of information if needed.
/// The return value of this function is the node number where this data is logged or 0 if no log entry was written
/// typically because the system log level was not set to log an event of the level passed in.<p>
/// So if you wish to log a problem with a Http request because the Type is wrong while reading it into
/// the local variable 'request' you could call:
/// <EXAMPLE>
/// Do ##class(%Library.SysLog).Log(1,"HTTP","Invalid Http request type. Type="_type,request)
/// </EXAMPLE>
/// Besides the information you pass to the Log method it will automatically log the current date and time
/// along with the process Id the calling routine name and the current namespace.
ClassMethod Log(level As %Integer = 2, category As %String = "", message As %String, ByRef data As %String, routine As %String) As %Integer
{
 If routine="" Set routine=$P($P($Stack($Stack-1,"PLACE")," "),"^",2)
 Quit $$Log^%SYS.ISCLOG(routine,level,category,message,.data)
}

/// Call this to log an unexpected ObjectScript error. Pass in the <var>category</var> to log this
/// error under, the <var>message</var> you want reported and the <var>routine</var> that you are logging the
/// error from (this is optional). The level of detail the error is logged at is determined by the system wide setting, see
/// <METHOD>ErrorDetailGet</METHOD> and <METHOD>ErrorDetailSet</METHOD> to set/get this value. The choices are:
/// <ul>
/// <li>0 - Just log the message and the value of $ZE and $ZU(56,5)</li>
/// <li>1 - Log the message, the value of $ZE and $ZU(56,5) and the call stack</li>
/// <li>2 - Log the local symbol table $ZE, $ZU(56,5) and the call stack</li>
/// </ul>
ClassMethod LogError(category As %String = "ERROR", message As %String, routine As %String) As %Integer
{
 #; Note that we should look at how ^%STACK works and modify this to use that dump
 #; in the future, for now this is fine however.
 New %data
 If routine="" Set routine=$P($P($Stack($Stack-1,"PLACE")," "),"^",2)
 Set %data("$ZE")=$ZE,%data("$ZU(56,5)")=$ZU(56,5),%data("$ZU(56,2)")=$ZU(56,2)
 #; Use new syntax to avoid creating another stack level (as we are saving the stack)
 If ..ErrorDetailGet()>0 {
 Set %data("$Stack")=$Stack
 Set %data("$Stack(-1)")=$Stack(-1)
 For stack=1:1:$STACK(-1) Set %data("$Stack("_stack_")")=$Stack(stack),%data("$Stack("_stack_",""PLACE"")")=$Stack(stack,"PLACE"),%data("$Stack("_stack_",""MCODE"")")=$Stack(stack,"MCODE")
}
 If ..ErrorDetailGet()>1 Do
 . If $D(%) Merge %data("Vars","%")=%
 . New %
 . Set %="%" For  Set %=$O(@%) Quit:%i=""  Do
 . . If %'="%data" Merge %data("Vars",%)=@%

 Quit $$Log^%SYS.ISCLOG(routine,1,category,message_" $ZE="_$ZE,.%data)
}

/// Log the user information at log level 2 (operational) to category 'UserInfo'. If any of <var>username</var>
/// or <var>machinename</var> or <var>exename</var> or <var>IPaddress</var> are blank or missing then they
/// default to the values setup in the partition in $ZU(67,n,$J). You normally call without any parameters
/// at the start of your application to log the person using this job, but you can override the value from $ZU(67)
/// is you need to. If <var>category</var> is blank it defaults to "UserInfo". <var>routine</var> is the optional
/// routine you are logging this from, if not specified it defaults to the value found from $Stack($Stack-1,"PLACE").
ClassMethod LogUserInfo(category As %String, username As %String, machinename As %String, exename As %String, IPaddress As %String, routine As %String) As %Integer
{
 If routine="" Set routine=$P($P($Stack($Stack-1,"PLACE")," "),"^",2)
 Quit $$LogUserInfo^%SYS.ISCLOG(routine,category,username,machinename,exename,IPaddress)
}

/// If there are more than <METHOD>MaxLogEntriesGet</METHOD> in the log then remove any old entries that
/// we no longer need. This is called automatically by <METHOD>Log</METHOD> and <METHOD>LogUserInfo</METHOD> every
/// 10 entries and so you do not normally need to call this manually.
ClassMethod RemoveOldEntries()
{
 Do RemoveOldEntries^%SYS.ISCLOG
 Quit
}

/// Return the current setting for the maximum number of entries before old ones are killed off.
ClassMethod MaxLogEntriesGet() As %Library.Integer
{
 Quit $G(^%ISCLOG("MaxLogEntries"),10000)
}

/// Set the maximum number of entries that this log will hold. If this is not set it defaults to 5,000 entries before
/// it starts removing old entries.
ClassMethod MaxLogEntriesSet(entries As %Library.Integer)
{
 Set ^%ISCLOG("MaxLogEntries")=entries
 Quit
}

/// Reset the entire log, removing all previous entries. It does preserve setup information.
ClassMethod ClearLog()
{
 Kill ^|"%SYS"|ISCLOG("Data")
 Quit
}

/// Set the logging level to one of the following
/// <ul>
/// <li>0 - No logging</li>
/// <li>1 - Exceptional events logged, e.g. error messages</li>
/// <li>2 - Detailed event log information, e.g. 'method ABC invoked with parameters X,Y,Z and returned 1234'</li>
/// <li>3 - Raw information logging, e.g. the bytes comming from the Http request</li>
/// </ul>
ClassMethod LogLevelSet(level As %Integer) As %Status
{
 If level<0!(level>3) Quit $$$ERROR($$$CSPSysLogLevel,level)
 Set ^%ISCLOG=level
 Quit $$$OK
}

ClassMethod LogLevelGet() As %Integer [ CodeMode = expression ]
{
$G(^%ISCLOG,1)
}

/// Set the level to log any <METHOD>LogError</METHOD> events with. See
/// <METHOD>LogError</METHOD> for a description of the levels.
ClassMethod ErrorDetailSet(level As %Integer)
{
 If level<0!(level>2) Set level=1
 Set ^%ISCLOG("ErrorDetail")=level
 Quit
}

/// Return the level to log any <METHOD>LogError</METHOD> events with. See
/// <METHOD>LogError</METHOD> for a description of the levels.
ClassMethod ErrorDetailGet() As %Integer [ CodeMode = expression ]
{
$G(^%ISCLOG("ErrorDetail"),1)
}

/// Comma separated list of categories that we log or null to log all categories.
ClassMethod CategorySet(category As %String)
{
 Kill ^%ISCLOG("Category")
 For i=1:1:$length(category,",") Set:$piece(category,",",i)'="" ^%ISCLOG("Category",$piece(category,",",i))=""
 Quit
}

/// Return the comma separated list of categories that we log.
ClassMethod CategoryGet() As %String
{
 Set list="",i=""
 For  Set i=$order(^%ISCLOG("Category",i)) Quit:i=""  Set list=list_i_","
 Quit $extract(list,1,$length(list)-1)
}

/// Comma separated list of job numbers that we log or null to log all jobs.
ClassMethod JobSet(job As %String)
{
 Kill ^%ISCLOG("Job")
 For i=1:1:$length(job,",") Set:$piece(job,",",i)'="" ^%ISCLOG("Job",$piece(job,",",i))=""
 Quit
}

/// Return the comma separated list of jobs that we log.
ClassMethod JobGet() As %String
{
 Set list="",i=""
 For  Set i=$order(^%ISCLOG("Job",i)) Quit:i=""  Set list=list_i_","
 Quit $extract(list,1,$length(list)-1)
}

}
