/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySite, %syTask, %sySystem)

/// 	Used to track events in the TASKMGR environment
/// When jobs are completed 
/// Deletion of tasks
/// Updates to Configuration data
/// Starting of the TASKMGR
/// Suspending/Resuming Tasks or TASKMGR
Class %SYS.Task.History Extends %Persistent [ System = 4 ]
{

Parameter DOMAIN = "%Utility";

/// Date the log entry is made
Property LogDate As %Date;

/// Time the log entry is made
Property LogTime As %Time;

/// Value of Status if ExecuteCode is Set Status=<br>
Property Status As %RawString [ InitialExpression = 0 ];

/// Code That was run
Property ExecuteCode As %String(MAXLEN = 32000);

/// $h Value of when the task was last started<br>
/// 0 - Never started
Property LastStarted As %String [ InitialExpression = 0 ];

/// $h Value of when the task was last finished<br>
/// 0 - Never finished
Property LastFinished As %String [ InitialExpression = 0 ];

/// Name of the task. Must be 16 characters or less, first character
/// must be a letter.
Property Name As %String(MAXLEN = 32000);

/// Calculated by the system
Property Number As %Integer [ InitialExpression = 0, Internal ];

/// Namespace the task ran in
Property NameSpace As %String(MAXLEN = 64) [ InitialExpression = "%SYS" ];

/// $lb(date,index) in %ER global on error
Property ER As %String(MAXLEN = 20);

/// Untrapped error from User task, or "Success"
Property Error As %String(MAXLEN = 1024);

/// $J value of the job which ran the task
Property RunningJobNumber As %String;

/// ID of Task
Property Task As %SYS.Task;

Property DisplayStarted As %String [ SqlComputeCode = { Set {DisplayStarted}=$s({LastStarted}=0:"",1:$zdatetime({LastStarted},3,2))}, SqlComputed, Transient ];

Property DisplayFinished As %String [ SqlComputeCode = { Set {DisplayFinished}=$s({LastFinished}=0:"",1:$zdatetime({LastFinished},3,2))}, SqlComputed, Transient ];

Property DisplayStatus As %String(MAXLEN = 1024) [ SqlComputeCode = {	Set {DisplayStatus}=$s({Status}=1:1,{Status}=0:"",1:$system.Status.GetErrorText({Status}))}, SqlComputed, Transient ];

Property DisplayErrorDate As %Date [ SqlComputeCode = { Set {DisplayErrorDate}=$s({ER}="":"",1:$lg({ER}))}, SqlComputed, Transient ];

Property DisplayErrorNumber As %String [ SqlComputeCode = {	Set {DisplayErrorNumber}=$s({ER}="":"",1:$lg({ER},2))}, SqlComputed, Transient ];

Property DisplayLogDate As %String(MAXLEN = 255) [ SqlComputeCode = { Set {DisplayLogDate}=$s({LogDate}=0:"",1:$zdate({LogDate},3))}, SqlComputed, Transient ];

Property Username As %Library.Username;

Index LogDate On LogDate;

Index Task On Task;

Method %OnBeforeSave(Insert As %Library.Boolean) As %Status
{
	If Insert {
		Set Now=$h
		Set ..LogDate=+Now
		Set ..LogTime=$p(Now,",",2)
	}
	Quit $$$OK
}

/// Purge Task History.
/// This method purges the task history. It will retain
/// Task history for the number of days set by the
/// $SYS.Task.HistoryPurgeSet class method.
ClassMethod PurgeHistory(days As %Integer) As %Status
{
	Set days=$G(days,##class(%SYS.Task).HistoryPurgeGet())
	Set:days<1 days=1
	Set days=$H-days
	&SQL(DELETE FROM %SYS_Task.History where LOGDATE<:days)
	If 'SQLCODE D ..WriteLog(1,"Success",$h,$h,$$$Text("TASKMGR Purge"),0,"%SYS","TASKMGR")
	Quit $$$OK
}

/// Formats a line for the TaskHistory query.
ClassMethod FormatTaskHistory(LastStarted As %String, Completed As %String, Name As %String, Status As %String, Result As %String) As %String
{
	q $$LJColumn(LastStarted,12)_$$LJColumn(Completed,12)_$$LJColumn(Name,16)_$$LJColumn(Status,10)_Result
LJColumn(Data,Size)	;
 	q Data_$j("",Size-$l(Data))_" "
}

/// Write an entry to the history log based on the passed values
ClassMethod WriteLog(Status As %Integer, Error As %String, LastStarted As %String, LastFinished As %String, Name As %String, Number As %String, NameSpace As %String, ExecuteCode As %String = "", ER As %String = "", Task As %Integer = "", PID As %String) As %Status [ Internal ]
{
	Set obj=..%New()
	Set obj.Status=Status
	Set obj.Error=Error
	Set obj.LastStarted=LastStarted
	Set obj.LastFinished=LastFinished
	Set obj.Name=Name
	Set obj.Number=Number
	Set obj.NameSpace=NameSpace
	Set obj.ExecuteCode=ExecuteCode
	Set obj.RunningJobNumber=$s($g(PID)]"":PID,1:$j)
	Set obj.ER=ER
	Do obj.TaskSetObjectId(Task)
	Set obj.Username=$username
	Set Status=obj.%Save()
	//// need to include message from status out to log
	If 'Status s s=$zu(9,"",$$$FormatText($$$Text("Error writing to Task History Global - Error (%1)"),##class(%SYS.Task).StatusAsText(Status)))
	Quit Status
}

/// Returns a Task's history.
/// <br>This query loops through the task history and returns information
/// concerning when the task was run
Query TaskHistory(NULL) As %SQLQuery(ROWSPEC = "Last Start:%String,Completed:%String,Task Name:%String,Status:%String,Result:%String,Task:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Username:%String,LogDate:%Date,LogTime:%Time")
{
	SELECT DisplayStarted,DisplayFinished,Name,DisplayStatus,Error,Task,Namespace,ExecuteCode,RunningJobNumber,DisplayErrorDate,DisplayErrorNumber,Username,DisplayLogDate,LogTime
	FROM %SYS_Task.History
}

Query TaskHistoryForDay(StartDate As %Date = {+$H}, EndDate As %Date = {+$H}) As %SQLQuery(ROWSPEC = "Last Start:%String,Completed:%String,Status:%String,Result:%String,Task:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Task Name:%String,Username:%String,LogDate:%Date,LogTime:%Time")
{
	SELECT DisplayStarted,DisplayFinished,DisplayStatus,Error,Task,Namespace,ExecuteCode,RunningJobNumber,DisplayErrorDate,DisplayErrorNumber,Name,Username,DisplayLogDate,LogTime
	FROM %SYS_Task.History
	Where LogDate>=:StartDate and LogDate<=:EndDate
}

Query TaskHistoryForTask(Task As %Integer) As %SQLQuery(ROWSPEC = "Last Start:%String,Completed:%String,Status:%String,Result:%String,Task:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Task Name:%String,Username:%String,LogDate:%Date,LogTime:%Time")
{
	SELECT DisplayStarted,DisplayFinished,DisplayStatus,Error,Task,Namespace,ExecuteCode,RunningJobNumber,DisplayErrorDate,DisplayErrorNumber,Name,Username,DisplayLogDate,LogTime
	FROM %SYS_Task.History
	Where Task=:Task
}

Query DescendingTaskHistoryForTask(Task As %Integer) As %SQLQuery(ROWSPEC = "Last Start:%String,Completed:%String,Status:%String,Result:%String,Task:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Task Name:%String,Username:%String,LogDate:%Date,LogTime:%Time")
{
	SELECT DisplayStarted,DisplayFinished,DisplayStatus,Error,Task,Namespace,ExecuteCode,RunningJobNumber,DisplayErrorDate,DisplayErrorNumber,Name,Username,DisplayLogDate,LogTime
	FROM %SYS_Task.History
	Where Task=:Task
	ORDER BY ID DESC
}

Query TaskHistoryForTaskForDay(Task As %Integer, StartDate As %Date = {+$H}, EndDate As %Date = {+$H}) As %SQLQuery(ROWSPEC = "Last Start:%String,Completed:%String,Status:%String,Result:%String,Task:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Task Name:%String,Username:%String,LogDate:%Date,LogTime:%Time")
{
	SELECT DisplayStarted,DisplayFinished,DisplayStatus,Error,Task,Namespace,ExecuteCode,RunningJobNumber,DisplayErrorDate,DisplayErrorNumber,Name,Username,DisplayLogDate,LogTime
	FROM %SYS_Task.History
	Where Task=:Task and LogDate>=:StartDate and LogDate<=:EndDate
}

Query TaskHistoryDetail(NULL) As %SQLQuery(ROWSPEC = "Last Start:%String,Completed:%String,Task Name:%String,Status:%String,Result:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Task:%String,Username:%String,LogDate:%Date,LogTime:%Time")
{
	SELECT DisplayStarted,DisplayFinished,Name,DisplayStatus,Error,Namespace,ExecuteCode,RunningJobNumber,DisplayErrorDate,DisplayErrorNumber,Task,Username,DisplayLogDate,LogTime
	FROM %SYS_Task.History
}

/// Returns all Task history in descending order.
Query DescendingTaskHistory(NULL) As %SQLQuery(ROWSPEC = "Last Start:%String,Completed:%String,Task Name:%String,Status:%String,Result:%String,Task:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Username:%String,LogDate:%Date,LogTime:%Time")
{
	SELECT DisplayStarted,DisplayFinished,Name,DisplayStatus,Error,Task,Namespace,ExecuteCode,RunningJobNumber,DisplayErrorDate,DisplayErrorNumber,Username,DisplayLogDate,LogTime
	FROM %SYS_Task.History ORDER BY ID DESC
}

/// Returns all non-system Task history in descending order.
Query DescendingTaskHistoryUser(NULL) As %SQLQuery(ROWSPEC = "Last Start:%String,Completed:%String,Task Name:%String,Status:%String,Result:%String,Task:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Username:%String,LogDate:%Date,LogTime:%Time")
{
	SELECT DisplayStarted,DisplayFinished,Name,DisplayStatus,Error,Task,Namespace,ExecuteCode,RunningJobNumber,DisplayErrorDate,DisplayErrorNumber,Username,DisplayLogDate,LogTime
	FROM %SYS_Task.History
	WHERE %internal(Task->Type) = 2  -- Type 0 is System tasks, Type 1 is Maintenance tasks, Type 2 is User tasks.   Type 0 and 1 are reserved for System Tasks
	ORDER BY ID DESC
}

Query DescendingTaskHistoryFilter(Filter As %String = "", UserOnly As %Boolean = 0) As %Query(ROWSPEC = "Last Start:%String,Completed:%String,Task Name:%String,Status:%String,Result:%String,Task:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Username:%String,LogDate:%Date,LogTime:%Time") [ Internal ]
{
}

ClassMethod DescendingTaskHistoryFilterExecute(ByRef qHandle As %Binary, Filter As %String = "", UserOnly As %Boolean = 0) As %Status [ Internal ]
{
	Set Index=$i($$$ISCQUERYTEMP)
	if 'UserOnly { Set rs=##class(%Library.ResultSet).%New("%SYS.Task.History:DescendingTaskHistory") }
	else         { Set rs=##class(%Library.ResultSet).%New("%SYS.Task.History:DescendingTaskHistoryUser") }
	Do rs.Execute()
	While (rs.Next()) {
		s Row=$lb(rs.Data("Last Start"),rs.Data("Completed"),rs.Data("Task Name"),rs.Data("Status"),rs.Data("Result"),rs.Data("Task"),rs.Data("NameSpace"),rs.Data("Routine"),rs.Data("Pid"),rs.Data("%ER Date"),rs.Data("%ER Error #"),rs.Data("Username"),rs.Data("LogDate"),rs.Data("LogTime"))
		i $zcvt($listtostring(Row,$c(13)),"U")[$zcvt(Filter,"U") Set $$$ISCQUERYTEMP(Index,$I(Index1))=Row
	}
	Set qHandle=Index_"^"
	Quit $$$OK
}

ClassMethod DescendingTaskHistoryFilterFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = DescendingTaskHistoryFilterExecute ]
{
 $$$DEFAULTFETCHPPG
	Quit $$$OK
}

ClassMethod DescendingTaskHistoryFilterClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = DescendingTaskHistoryFilterExecute ]
{
	Set Index=$p(qHandle,"^",1)
	Kill $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

Query DescendingTaskHistoryDays(StartDate As %Date = {+$H}, EndDate As %Date = {+$H}) As %SQLQuery(ROWSPEC = "Last Start:%String,Completed:%String,Task Name:%String,Status:%String,Result:%String,Task:%String,NameSpace:%String,Routine:%String,Pid:%String,%ER Date:%String,%ER Error #:%String,Username:%String,LogDate:%Date,LogTime:%Time")
{
	SELECT DisplayStarted,DisplayFinished,Name,DisplayStatus,Error,Task,Namespace,ExecuteCode,RunningJobNumber,DisplayErrorDate,DisplayErrorNumber,Username,DisplayLogDate,LogTime
	FROM %SYS_Task.History Where LogDate>=:StartDate and LogDate<=:EndDate ORDER BY ID DESC
}

Storage Default
{
<Data name="HistoryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ER</Value>
</Value>
<Value name="3">
<Value>Error</Value>
</Value>
<Value name="4">
<Value>ExecuteCode</Value>
</Value>
<Value name="5">
<Value>LastFinished</Value>
</Value>
<Value name="6">
<Value>LastStarted</Value>
</Value>
<Value name="7">
<Value>Name</Value>
</Value>
<Value name="8">
<Value>NameSpace</Value>
</Value>
<Value name="9">
<Value>Number</Value>
</Value>
<Value name="10">
<Value>RunningJobNumber</Value>
</Value>
<Value name="11">
<Value>Status</Value>
</Value>
<Value name="12">
<Value>Task</Value>
</Value>
<Value name="13">
<Value>LogDate</Value>
</Value>
<Value name="14">
<Value>LogTime</Value>
</Value>
<Value name="15">
<Value>Username</Value>
</Value>
</Data>
<DataLocation>^|"^^"_$ZU(12)|SYS("Task","HistoryD")</DataLocation>
<DefaultData>HistoryDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^|"^^"_$ZU(12)|SYS("Task","HistoryD")</IdLocation>
<IndexLocation>^|"^^"_$ZU(12)|SYS("Task","HistoryI")</IndexLocation>
<StreamLocation>^|"^^"_$ZU(12)|SYS("Task","HistoryS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
