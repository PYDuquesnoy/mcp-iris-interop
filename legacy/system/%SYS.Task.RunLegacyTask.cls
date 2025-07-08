/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides a way for users of previous versions of Task Manager to 
/// easily migrate their tasks which were based on 'ExecuteCode'. It is shown as
/// a 'Task type' in the Task Scheduler Wizard so that users may enter their code there.
/// <br><br>
/// Note that all new user-defined tasks should be created by subclassing
/// %SYS.Task.Definition and editing the OnTask() method. See examples in the 
/// [SAMPLES]Sample.Task and Sample.Task* classes.
Class %SYS.Task.RunLegacyTask Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "RunLegacyTask";

/// The value of this property is used as the argument to an XECUTE command
/// when OnTask is run. The user may also set the value of the variable "Status"
/// to a return code if they wish.
/// <br><br>
/// Note that this is provided only for backwards compatibility. All new user-defined 
/// tasks should be created by subclassing %SYS.Task.Definition and editing the 
/// OnTask() method. 
Property ExecuteCode As %String(MAXLEN = "");

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "settings" for the task, and then
/// invokes this method to execute the task.<br>
/// The user's code may set the value of "Status" to return a status code.
Method OnTask() As %Status
{
	Quit ..executeCode(..ExecuteCode)
}

Method executeCode(code) [ ProcedureBlock = 0 ]
{
	Set $ZT="Error"
	Set Status=$$$OK
	X code
	Quit $g(Status,$$$OK)
Error	;
	Set $ZT=""
	Quit $$$ERROR($$$GeneralError,$ze)
}

}
