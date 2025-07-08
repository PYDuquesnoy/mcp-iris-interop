/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This Task will purge errors (in the ^ERRORS global) that are older than the configured value.<br>
/// It also renames the messages.log file if it is larger than the configured maximum size.<br>
/// On a MultiValue system it also renames the mv.log file if it grows too large.<br>
/// This Task is normally run nightly.<br>
/// 
Class %SYS.Task.PurgeErrorsAndLogs Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "PurgeErrorsAndLogs";

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "settings" for the task, and then
/// invokes this method to execute the task.<br>
Method OnTask() As %Status
{
 d $zu(5,"%SYS")
 d ##Class(Config.Startup).SwitchConsoleLog()
 d ##Class(Config.Startup).ErrorPurge()
 Quit $$$OK
}

}
